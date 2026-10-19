*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_THCPVC_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form SET_DEFAULT_DATE
*&---------------------------------------------------------------------*
FORM SET_DEFAULT_DATE.

  GV_BL1 = 'Hóa đơn bán hàng'. "#EC NOTEXT
  GV_BL2 = 'Chiều phân tích'. "#EC NOTEXT

  CLEAR S_FKDAT.
  S_FKDAT-SIGN     = 'I'.
  S_FKDAT-OPTION   = 'BT'.
  S_FKDAT-LOW      = SY-DATUM.
  S_FKDAT-LOW+6(2) = '01'.
  S_FKDAT-HIGH     = SY-DATUM.
  APPEND S_FKDAT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_AUTHORITY
*&---------------------------------------------------------------------*
FORM CHECK_AUTHORITY.

  SELECT DISTINCT VKORG, VTWEG
    FROM VBRK
   WHERE FKDAT IN @S_FKDAT
     AND FKART IN @S_FKART
     AND VKORG IN @S_VKORG
     AND VTWEG IN @S_VTWEG
    INTO TABLE @DATA(LT_ORG).

  LOOP AT LT_ORG ASSIGNING FIELD-SYMBOL(<LFS_ORG>).

    AUTHORITY-CHECK OBJECT 'V_VBRK_VKO'
             ID 'VKORG' FIELD <LFS_ORG>-VKORG
             ID 'ACTVT' FIELD '03'.
    IF SY-SUBRC <> 0.
      MESSAGE E001(ZMC_SD) WITH 'Khong co quyen voi to chuc ban hang'
                                <LFS_ORG>-VKORG. "#EC NOTEXT
    ENDIF.


    AUTHORITY-CHECK OBJECT 'M_IS_VTWEG'
             ID 'MCINF' DUMMY
             ID 'VTWEG' FIELD <LFS_ORG>-VTWEG.
    IF SY-SUBRC <> 0.
      MESSAGE E001(ZMC_SD) WITH 'Khong co quyen voi kenh ban hang'
                                <LFS_ORG>-VTWEG. "#EC NOTEXT
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
FORM GET_DATA.

  WITH
    +FR AS (
      SELECT E~KNUMV, E~KPOSN,
             SUM( CASE WHEN E~KSCHL = @GC_KSCHL_FR1 THEN E~KWERT END ) AS FR1,
             SUM( CASE WHEN E~KSCHL = @GC_KSCHL_FR2 THEN E~KWERT END ) AS FR2
        FROM PRCD_ELEMENTS AS E
        INNER JOIN VBRK AS K ON K~KNUMV = E~KNUMV
       WHERE E~KSCHL IN ( @GC_KSCHL_FR1, @GC_KSCHL_FR2 )
         AND K~FKDAT IN @S_FKDAT
         AND K~FKART IN @S_FKART
       GROUP BY E~KNUMV, E~KPOSN )
  SELECT P~VKGRP, G~BEZEI AS VKGRP_TX,
         P~VKBUR, B~BEZEI AS VKBUR_TX,
         P~KVGR2, V~BEZEI AS KVGR2_TX,
         C~MFRGR, M~BEZEI AS MFRGR_TX,
         K~VTWEG, T~VTEXT AS VTWEG_TX,
         K~WAERK,
         SUM( CASE WHEN K~VBTYP = @GC_VBTYP_RET
                   THEN P~NETWR * -1 ELSE P~NETWR END ) AS NETWR,
         SUM( CASE WHEN K~VBTYP = @GC_VBTYP_RET
                   THEN F~FR1 * -1 ELSE F~FR1 END ) AS FREIGHT1,
         SUM( CASE WHEN K~VBTYP = @GC_VBTYP_RET
                   THEN F~FR2 * -1 ELSE F~FR2 END ) AS FREIGHT2,
         SUM( CASE WHEN K~VBTYP = @GC_VBTYP_RET
                   THEN P~KZWI4 * -1 ELSE P~KZWI4 END ) AS KZWI4
    FROM VBRP AS P
    INNER JOIN VBRK AS K ON K~VBELN = P~VBELN
    LEFT OUTER JOIN NSDM_E_MARC AS C
           ON C~MATNR = P~MATNR AND C~WERKS = P~WERKS
    LEFT OUTER JOIN +FR AS F
           ON F~KNUMV = K~KNUMV AND F~KPOSN = P~POSNR
    LEFT OUTER JOIN TVGRT AS G ON G~VKGRP = P~VKGRP AND G~SPRAS = @SY-LANGU
    LEFT OUTER JOIN TVKBT AS B ON B~VKBUR = P~VKBUR AND B~SPRAS = @SY-LANGU
    LEFT OUTER JOIN TVV2T AS V ON V~KVGR2 = P~KVGR2 AND V~SPRAS = @SY-LANGU
    LEFT OUTER JOIN TMFGT AS M ON M~MFRGR = C~MFRGR AND M~SPRAS = @SY-LANGU
    LEFT OUTER JOIN TVTWT AS T ON T~VTWEG = K~VTWEG AND T~SPRAS = @SY-LANGU
   WHERE K~FKDAT IN @S_FKDAT
     AND K~FKART IN @S_FKART
     AND K~VKORG IN @S_VKORG
     AND K~VTWEG IN @S_VTWEG
     AND K~KUNAG IN @S_KUNAG
     AND K~FKSTO <> @ABAP_TRUE
     AND P~VKGRP IN @S_VKGRP
     AND P~VKBUR IN @S_VKBUR
     AND P~KVGR2 IN @S_KVGR2
     AND C~MFRGR IN @S_MFRGR
   GROUP BY P~VKGRP, G~BEZEI, P~VKBUR, B~BEZEI, P~KVGR2, V~BEZEI,
            C~MFRGR, M~BEZEI, K~VTWEG, T~VTEXT, K~WAERK
   ORDER BY P~VKGRP, P~VKBUR, P~KVGR2, C~MFRGR, K~VTWEG
    INTO CORRESPONDING FIELDS OF TABLE @GT_ALV.

  CHECK GT_ALV IS NOT INITIAL.

* (11)(12) Tu ngay/Den ngay = From/To cua tham so (1), khong phai min/max thuc te
  LOOP AT GT_ALV ASSIGNING FIELD-SYMBOL(<LFS_A>).
    <LFS_A>-DATE_FR = S_FKDAT-LOW.
    <LFS_A>-DATE_TO = S_FKDAT-HIGH.
    PERFORM FORMAT_RATE USING <LFS_A>-FREIGHT1 <LFS_A>-NETWR CHANGING <LFS_A>-RATE1.
    PERFORM FORMAT_RATE USING <LFS_A>-FREIGHT2 <LFS_A>-NETWR CHANGING <LFS_A>-RATE2.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FORMAT_RATE
*&---------------------------------------------------------------------*
* Ty le % = so tien / doanh so * 100, de trong khi doanh so = 0
FORM FORMAT_RATE USING    IV_AMOUNT TYPE VBRP-NETWR
                          IV_BASE   TYPE VBRP-NETWR
                 CHANGING CV_RATE   TYPE GTY_ALV-RATE1.

  DATA LV_RATE TYPE DECFLOAT34.

  CLEAR CV_RATE.
  CHECK IV_BASE <> 0.

  LV_RATE = IV_AMOUNT / IV_BASE * 100.
  CV_RATE = |{ LV_RATE DECIMALS = 3 NUMBER = USER }%|.

ENDFORM.