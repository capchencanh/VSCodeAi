*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_TDTHGT_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form INIT_SCREEN
*&---------------------------------------------------------------------*
* Nhan man hinh chon + gia tri mac dinh la thang lien truoc thang hien tai
FORM INIT_SCREEN.

  DATA LV_DATE TYPE D.

  GV_BL1 = 'Kỳ báo cáo'.                       "#EC NOTEXT
  GV_BL2 = 'Hợp đồng'.                         "#EC NOTEXT
  GV_BL3 = 'Chiều phân tích'.                  "#EC NOTEXT
  GV_BL4 = 'Tùy chọn hiển thị'.                "#EC NOTEXT
  GV_BL5 = 'Trạng thái thực hiện'.             "#EC NOTEXT
  GV_BL6 = 'Dạng hiển thị'.                    "#EC NOTEXT

  %_P_MONTH_%_APP_%-TEXT = 'Tháng báo cáo (MM.YYYY)'.        "#EC NOTEXT
  %_S_VKORG_%_APP_%-TEXT = 'Tổ chức bán hàng'.               "#EC NOTEXT
  %_S_VTWEG_%_APP_%-TEXT = 'Kênh bán hàng'.                  "#EC NOTEXT
  %_S_AUART_%_APP_%-TEXT = 'Loại chứng từ hợp đồng'.         "#EC NOTEXT
  %_S_VBEL1_%_APP_%-TEXT = 'Số hợp đồng cấp 1'.              "#EC NOTEXT
  %_S_VBELN_%_APP_%-TEXT = 'Số hợp đồng cấp 2'.              "#EC NOTEXT
  %_S_PLTYP_%_APP_%-TEXT = 'Loại hợp đồng'.                  "#EC NOTEXT
  %_S_KUNN1_%_APP_%-TEXT = 'Mã đơn vị mời thầu'.             "#EC NOTEXT
  %_S_KUNNR_%_APP_%-TEXT = 'Mã khách hàng'.                  "#EC NOTEXT
  %_S_MATNR_%_APP_%-TEXT = 'Mã hàng hóa'.                    "#EC NOTEXT
  %_S_VKGRP_%_APP_%-TEXT = 'Khu vực'.                        "#EC NOTEXT
  %_S_VKBUR_%_APP_%-TEXT = 'Chi nhánh'.                      "#EC NOTEXT
  %_S_KVGR1_%_APP_%-TEXT = 'Tỉnh thành'.                     "#EC NOTEXT
  %_S_PERNR_%_APP_%-TEXT = 'Mã trình dược viên'.             "#EC NOTEXT
  %_S_ASM_%_APP_%-TEXT   = 'Mã ASM'.                         "#EC NOTEXT
  %_P_ALL_%_APP_%-TEXT   = 'Tất cả'.                         "#EC NOTEXT
  %_P_REM_%_APP_%-TEXT   = 'Còn số lượng chưa thực hiện'.    "#EC NOTEXT
  %_P_DONE_%_APP_%-TEXT  = 'Đã thực hiện hết'.               "#EC NOTEXT
  %_P_ALV_%_APP_%-TEXT   = 'ALV'.                            "#EC NOTEXT
  %_P_XLS_%_APP_%-TEXT   = 'Bảng tính'.                      "#EC NOTEXT

  LV_DATE = SY-DATUM.
  LV_DATE+6(2) = '01'.
  LV_DATE = LV_DATE - 1.
  P_MONTH = |{ LV_DATE+4(2) }.{ LV_DATE(4) }|.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_INPUT
*&---------------------------------------------------------------------*
FORM CHECK_INPUT.

  IF P_MONTH+2(1) <> '.'
     OR P_MONTH(2) CN '0123456789'
     OR P_MONTH+3(4) CN '0123456789'
     OR P_MONTH(2) < '01'
     OR P_MONTH(2) > '12'
     OR P_MONTH+3(4) < '2000'.
    MESSAGE E001(ZMC_SD) WITH 'Tháng báo cáo phải đúng dạng MM.YYYY,'
                              'ví dụ 07.2026'. "#EC NOTEXT
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CALC_DATES
*&---------------------------------------------------------------------*
* Ngay dau/cuoi thang bao cao
FORM CALC_DATES.

  GV_YEAR  = P_MONTH+3(4).
  GV_MONTH = P_MONTH(2).
  GV_YEAR_PREV = GV_YEAR - 1.

  GV_DATE_FR = |{ GV_YEAR }{ GV_MONTH }01|.

  GV_DATE_TO = GV_DATE_FR.
  GV_DATE_TO = GV_DATE_TO + 31.
  GV_DATE_TO+6(2) = '01'.
  GV_DATE_TO = GV_DATE_TO - 1.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F4_CONTRACT_L1
*&---------------------------------------------------------------------*
* Search help hop dong cap 1: chi hien hop dong loai ZCQ1
FORM F4_CONTRACT_L1 USING IV_FIELD TYPE CLIKE.

  TYPES: BEGIN OF LTY_F4,
           VBELN TYPE VBAK-VBELN,
           KUNNR TYPE VBAK-KUNNR,
           GUEBG TYPE VBAK-GUEBG,
           GUEEN TYPE VBAK-GUEEN,
           BSTNK TYPE VBAK-BSTNK,
         END OF LTY_F4.

  DATA: LT_F4  TYPE STANDARD TABLE OF LTY_F4 WITH EMPTY KEY,
        LT_RET TYPE STANDARD TABLE OF DDSHRETVAL WITH EMPTY KEY.

  SELECT VBELN, KUNNR, GUEBG, GUEEN, BSTNK
    FROM VBAK
   WHERE VBTYP = @GC_VBTYP_CONTRACT
     AND AUART = @GC_AUART_L1
   ORDER BY VBELN DESCENDING
    INTO TABLE @LT_F4
    UP TO 500 ROWS.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      RETFIELD        = 'VBELN'
      DYNPPROG        = SY-REPID
      DYNPNR          = SY-DYNNR
      DYNPROFIELD     = IV_FIELD
      VALUE_ORG       = 'S'
    TABLES
      VALUE_TAB       = LT_F4
      RETURN_TAB      = LT_RET
    EXCEPTIONS
      PARAMETER_ERROR = 1
      NO_VALUES_FOUND = 2
      OTHERS          = 3.
  IF SY-SUBRC <> 0.
    RETURN.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
FORM GET_DATA.

  PERFORM GET_AUTH_SCOPE.
  CHECK GT_AUTH IS NOT INITIAL.

  PERFORM GET_CONTRACT.
  CHECK GT_ITEM IS NOT INITIAL.

  PERFORM GET_BILLING.
  PERFORM BUILD_MONTHLY.
  PERFORM GET_MASTER.
  PERFORM BUILD_COLUMNS.
  PERFORM BUILD_STRUCTURE.
  PERFORM FILL_OUTPUT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_AUTH_SCOPE
*&---------------------------------------------------------------------*
* Chi giu lai to hop (to chuc ban hang, kenh, nganh hang, loai chung tu)
* ma user duoc phep xem
FORM GET_AUTH_SCOPE.

  DATA LT_CMB TYPE GTT_AUTH.

  CLEAR GT_AUTH.

  SELECT DISTINCT K~VKORG, K~VTWEG, K~SPART, K~AUART
    FROM VBAK AS K
   WHERE K~VBTYP  = @GC_VBTYP_CONTRACT
     AND K~AUART <> @GC_AUART_L1
     AND K~GUEBG <= @GV_DATE_TO
     AND K~GUEEN >= @GV_DATE_FR
     AND K~VKORG IN @S_VKORG
     AND K~VTWEG IN @S_VTWEG
     AND K~AUART IN @S_AUART
     AND K~VKGRP IN @S_VKGRP
     AND K~VKBUR IN @S_VKBUR
    INTO TABLE @LT_CMB.

  LOOP AT LT_CMB ASSIGNING FIELD-SYMBOL(<LFS_CMB>).

    AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
             ID 'VKORG' FIELD <LFS_CMB>-VKORG
             ID 'VTWEG' FIELD <LFS_CMB>-VTWEG
             ID 'SPART' FIELD <LFS_CMB>-SPART
             ID 'ACTVT' FIELD '03'.
    CHECK SY-SUBRC = 0.

    AUTHORITY-CHECK OBJECT 'V_VBAK_AAT'
             ID 'AUART' FIELD <LFS_CMB>-AUART
             ID 'ACTVT' FIELD '03'.
    CHECK SY-SUBRC = 0.

    APPEND <LFS_CMB> TO GT_AUTH.

  ENDLOOP.

  IF LT_CMB IS NOT INITIAL AND GT_AUTH IS INITIAL.
    MESSAGE 'Không có quyền xem hợp đồng theo điều kiện đã chọn' TYPE 'S'
            DISPLAY LIKE 'E'. "#EC NOTEXT
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_CONTRACT
*&---------------------------------------------------------------------*
* Dong hop dong cap 2 con hieu luc trong thang bao cao, kem hop dong cap 1,
* doi tac, nhom khach hang va dien giai
FORM GET_CONTRACT.

  CLEAR: GT_ITEM, GT_KEY.

  SELECT K~VBELN, I~POSNR, K~VKORG, K~VTWEG, K~SPART, K~AUART, K~VKGRP,
         PA~KUNNR,
         K~GUEBG, K~GUEEN, K~ERDAT, K~BSTNK, K~VGBEL, K~VGTYP, K~WAERK,
         I~MATNR, I~ARKTX, I~ZMENG, I~ZIEME, I~VRKME, I~NETPR, I~KPEIN,
         I~NETWR,
         MR~PRDHA,
         K1~VBELN AS VBELN1, K1~BSTNK AS BSTNK1, K1~KUNNR AS KUNNR1,
         K1~VGBEL AS VGBEL1, K1~VGTYP AS VGTYP1,
         H~PLTYP, K~KVGR1,
         PE~PERNR AS PERNR_TDV, PM~PERNR AS PERNR_ASM,
         G~BEZEI AS VKGRP_TX, O~VTEXT AS VKORG_TX, T~PTEXT AS PLTYP_TX,
         V~BEZEI AS KVGR1_TX, W~WGBEZ, P~VTEXT AS PRDHA_TX
    FROM VBAK AS K
    INNER JOIN @GT_AUTH AS Z
            ON Z~VKORG = K~VKORG AND Z~VTWEG = K~VTWEG
           AND Z~SPART = K~SPART AND Z~AUART = K~AUART
    INNER JOIN VBAP AS I ON I~VBELN = K~VBELN
    LEFT OUTER JOIN VBAK AS K1
           ON K1~VBELN = I~VGBEL AND K1~AUART = @GC_AUART_L1
    LEFT OUTER JOIN VBKD AS H
           ON H~VBELN = K~VBELN AND H~POSNR = @GC_POSNR_HDR
    LEFT OUTER JOIN VBPA AS PA
           ON PA~VBELN = K~VBELN AND PA~POSNR = @GC_POSNR_HDR
          AND PA~PARVW = @GC_PARVW_SOLD
    LEFT OUTER JOIN VBPA AS PE
           ON PE~VBELN = K~VBELN AND PE~POSNR = @GC_POSNR_HDR
          AND PE~PARVW = @GC_PARVW_TDV
    LEFT OUTER JOIN VBPA AS PM
           ON PM~VBELN = K~VBELN AND PM~POSNR = @GC_POSNR_HDR
          AND PM~PARVW = @GC_PARVW_ASM
    LEFT OUTER JOIN MARA AS MR ON MR~MATNR = I~MATNR
    LEFT OUTER JOIN TVGRT AS G ON G~VKGRP = K~VKGRP AND G~SPRAS = @SY-LANGU
    LEFT OUTER JOIN TVKOT AS O ON O~VKORG = K~VKORG AND O~SPRAS = @SY-LANGU
    LEFT OUTER JOIN T189T AS T ON T~PLTYP = H~PLTYP AND T~SPRAS = @SY-LANGU
    LEFT OUTER JOIN TVV1T AS V ON V~KVGR1 = K~KVGR1 AND V~SPRAS = @SY-LANGU
    LEFT OUTER JOIN T023T AS W ON W~MATKL = MR~MATKL AND W~SPRAS = @SY-LANGU
    LEFT OUTER JOIN T179T AS P ON P~PRODH = MR~PRDHA AND P~SPRAS = @SY-LANGU
   WHERE K~VBTYP  = @GC_VBTYP_CONTRACT
     AND K~AUART <> @GC_AUART_L1
     AND K~GUEBG <= @GV_DATE_TO
     AND K~GUEEN >= @GV_DATE_FR
     AND K~VKORG IN @S_VKORG
     AND K~VTWEG IN @S_VTWEG
     AND K~AUART IN @S_AUART
     AND K~VBELN IN @S_VBELN
     AND K~VKGRP IN @S_VKGRP
     AND K~VKBUR IN @S_VKBUR
     AND I~MATNR IN @S_MATNR
     AND K1~VBELN IN @S_VBEL1
     AND K1~KUNNR IN @S_KUNN1
     AND PA~KUNNR IN @S_KUNNR
     AND PE~PERNR IN @S_PERNR
     AND PM~PERNR IN @S_ASM
     AND H~PLTYP  IN @S_PLTYP
     AND K~KVGR1  IN @S_KVGR1
   ORDER BY K~VKGRP, K~VKORG, K~VBELN, I~POSNR
    INTO CORRESPONDING FIELDS OF TABLE @GT_ITEM. "#EC CI_BUFFJOIN

  CHECK GT_ITEM IS NOT INITIAL.

  GT_KEY = CORRESPONDING #( GT_ITEM ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_BILLING
*&---------------------------------------------------------------------*
* Hoa don ban hang (+) va hoa don hang ban tra lai (-) den het ngay cuoi
* thang bao cao, gop theo dong hop dong + thang hoa don.
* Hoa don ban: hoa don -> don hang -> dong hop dong.
* Hoa don tra lai: hoa don tra -> don tra -> hoa don ban goc -> don hang
* -> dong hop dong. Hoa don da huy (VBRK-FKSTO) va chung tu huy bi loai.
FORM GET_BILLING.

  DATA LT_RET TYPE GTT_BILL.

  CLEAR GT_BILL.

  SELECT C~VBELN, C~POSNR, SUBSTRING( K~FKDAT, 1, 6 ) AS YM, P~VRKME,
         SUM( P~FKIMG ) AS FKIMG, SUM( P~NETWR ) AS NETWR
    FROM VBAP AS S
    INNER JOIN @GT_KEY AS C ON C~VBELN = S~VGBEL AND C~POSNR = S~VGPOS
    INNER JOIN VBRP AS P ON P~AUBEL = S~VBELN AND P~AUPOS = S~POSNR
    INNER JOIN VBRK AS K ON K~VBELN = P~VBELN
   WHERE S~VGTYP = @GC_VGTYP_CONTRACT
     AND K~VBTYP = @GC_VBTYP_INV
     AND K~FKSTO <> @ABAP_TRUE
     AND K~FKDAT <= @GV_DATE_TO
   GROUP BY C~VBELN, C~POSNR, SUBSTRING( K~FKDAT, 1, 6 ), P~VRKME
    INTO CORRESPONDING FIELDS OF TABLE @GT_BILL.

  SELECT C~VBELN, C~POSNR, SUBSTRING( K~FKDAT, 1, 6 ) AS YM, P~VRKME,
         SUM( P~FKIMG ) AS FKIMG, SUM( P~NETWR ) AS NETWR
    FROM VBAP AS S
    INNER JOIN @GT_KEY AS C ON C~VBELN = S~VGBEL AND C~POSNR = S~VGPOS
    INNER JOIN VBRP AS V ON V~AUBEL = S~VBELN AND V~AUPOS = S~POSNR
    INNER JOIN VBAP AS R ON R~VGBEL = V~VBELN AND R~VGPOS = V~POSNR
    INNER JOIN VBRP AS P ON P~AUBEL = R~VBELN AND P~AUPOS = R~POSNR
    INNER JOIN VBRK AS K ON K~VBELN = P~VBELN
   WHERE S~VGTYP = @GC_VGTYP_CONTRACT
     AND R~VGTYP = @GC_VGTYP_INVOICE
     AND K~VBTYP = @GC_VBTYP_RET
     AND K~FKSTO <> @ABAP_TRUE
     AND K~FKDAT <= @GV_DATE_TO
   GROUP BY C~VBELN, C~POSNR, SUBSTRING( K~FKDAT, 1, 6 ), P~VRKME
    INTO CORRESPONDING FIELDS OF TABLE @LT_RET.

  LOOP AT LT_RET ASSIGNING FIELD-SYMBOL(<LFS_R>).
    <LFS_R>-FKIMG = <LFS_R>-FKIMG * -1.
    <LFS_R>-NETWR = <LFS_R>-NETWR * -1.
  ENDLOOP.

  APPEND LINES OF LT_RET TO GT_BILL.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_MONTHLY
*&---------------------------------------------------------------------*
* Quy doi so luong hoa don ve don vi tinh cua dong hop dong, gop theo thang
FORM BUILD_MONTHLY.

  DATA: LS_MON  TYPE GTY_MON,
        LV_UNIT TYPE VBAP-ZIEME,
        LV_QTY  TYPE EKPO-MENGE.

  CLEAR GT_MON.

  LOOP AT GT_BILL ASSIGNING FIELD-SYMBOL(<LFS_B>).

    READ TABLE GT_ITEM ASSIGNING FIELD-SYMBOL(<LFS_I>)
         WITH TABLE KEY K_ITEM COMPONENTS VBELN = <LFS_B>-VBELN
                                          POSNR = <LFS_B>-POSNR.
    CHECK SY-SUBRC = 0.

    IF <LFS_I>-ZIEME IS NOT INITIAL.
      LV_UNIT = <LFS_I>-ZIEME.
    ELSE.
      LV_UNIT = <LFS_I>-VRKME.
    ENDIF.

    LV_QTY = <LFS_B>-FKIMG.

    IF <LFS_B>-VRKME <> LV_UNIT.
      CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
        EXPORTING
          I_MATNR              = <LFS_I>-MATNR
          I_IN_ME              = <LFS_B>-VRKME
          I_OUT_ME             = LV_UNIT
          I_MENGE              = <LFS_B>-FKIMG
        IMPORTING
          E_MENGE              = LV_QTY
        EXCEPTIONS
          ERROR_IN_APPLICATION = 1
          ERROR                = 2
          OTHERS               = 3.
      IF SY-SUBRC <> 0.
        LV_QTY = <LFS_B>-FKIMG.
      ENDIF.
    ENDIF.

    CLEAR LS_MON.
    LS_MON-VBELN = <LFS_B>-VBELN.
    LS_MON-POSNR = <LFS_B>-POSNR.
    LS_MON-YM    = <LFS_B>-YM.
    LS_MON-QTY   = LV_QTY.
    LS_MON-VAL   = <LFS_B>-NETWR.
    COLLECT LS_MON INTO GT_MON.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_MASTER
*&---------------------------------------------------------------------*
* Doc 1 lan: khach hang (ten, tinh), nhan vien (ten), dac tinh SPCL cua
* vat tu, so PO cua bao gia
FORM GET_MASTER.

  DATA: LT_KUNNR TYPE GTT_KUNNR,
        LT_PERNR TYPE GTT_PERNR,
        LT_OBJEK TYPE GTT_OBJEK,
        LT_BGNR  TYPE GTT_VBELN.

  LOOP AT GT_ITEM ASSIGNING FIELD-SYMBOL(<LFS_I>).

*   Bang khoa SORTED/UNIQUE: INSERT trung khoa tu bo qua nen khong can SORT + DELETE
    IF <LFS_I>-KUNNR IS NOT INITIAL.
      INSERT VALUE #( KUNNR = <LFS_I>-KUNNR ) INTO TABLE LT_KUNNR.
    ENDIF.
    IF <LFS_I>-KUNNR1 IS NOT INITIAL.
      INSERT VALUE #( KUNNR = <LFS_I>-KUNNR1 ) INTO TABLE LT_KUNNR.
    ENDIF.
    IF <LFS_I>-PERNR_TDV IS NOT INITIAL.
      INSERT VALUE #( PERNR = <LFS_I>-PERNR_TDV ) INTO TABLE LT_PERNR.
    ENDIF.
    IF <LFS_I>-PERNR_ASM IS NOT INITIAL.
      INSERT VALUE #( PERNR = <LFS_I>-PERNR_ASM ) INTO TABLE LT_PERNR.
    ENDIF.
    IF <LFS_I>-MATNR IS NOT INITIAL.
      INSERT VALUE #( OBJEK = <LFS_I>-MATNR ) INTO TABLE LT_OBJEK.
    ENDIF.
    IF <LFS_I>-VGTYP = GC_VGTYP_QUOT.
      INSERT VALUE #( VBELN = <LFS_I>-VGBEL ) INTO TABLE LT_BGNR.
    ELSEIF <LFS_I>-VGTYP1 = GC_VGTYP_QUOT.
      INSERT VALUE #( VBELN = <LFS_I>-VGBEL1 ) INTO TABLE LT_BGNR.
    ENDIF.

  ENDLOOP.

  SELECT K~KUNNR, A~NAME1, A~NAME2, A~NAME3, R~BEZEI AS REGION_TX
    FROM KNA1 AS K
    INNER JOIN @LT_KUNNR AS T ON T~KUNNR = K~KUNNR
    LEFT OUTER JOIN ADRC AS A
           ON A~ADDRNUMBER = K~ADRNR AND A~DATE_FROM = '00010101'
          AND A~NATION = @SPACE
    LEFT OUTER JOIN T005U AS R
           ON R~SPRAS = @SY-LANGU AND R~LAND1 = A~COUNTRY
          AND R~BLAND = A~REGION
    INTO CORRESPONDING FIELDS OF TABLE @GT_CUST. "#EC CI_BUFFJOIN

  SELECT P~PERNR, MAX( P~ENAME ) AS ENAME
    FROM PA0001 AS P
    INNER JOIN @LT_PERNR AS T ON T~PERNR = P~PERNR
   WHERE P~BEGDA <= @GV_DATE_TO
     AND P~ENDDA >= @GV_DATE_TO
   GROUP BY P~PERNR
    INTO CORRESPONDING FIELDS OF TABLE @GT_EMP.

  SELECT A~OBJEK, MAX( A~ATWRT ) AS ATWRT
    FROM AUSP AS A
    INNER JOIN CABN AS C ON C~ATINN = A~ATINN
    INNER JOIN @LT_OBJEK AS T ON T~OBJEK = A~OBJEK
   WHERE C~ATNAM = @GC_ATNAM_SPCL
     AND A~KLART = @GC_KLART_MAT
     AND A~MAFID = @GC_MAFID_OBJ
   GROUP BY A~OBJEK
    INTO CORRESPONDING FIELDS OF TABLE @GT_SPCL. "#EC CI_BUFFJOIN

  SELECT V~VBELN, V~BSTNK
    FROM VBAK AS V
    INNER JOIN @LT_BGNR AS T ON T~VBELN = V~VBELN
    INTO CORRESPONDING FIELDS OF TABLE @GT_BG.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_COLUMNS
*&---------------------------------------------------------------------*
* Danh sach cot nam/quy/thang theo thang bao cao:
* cac nam cu (tong nam), nam lien truoc (12 thang + 4 quy + tong nam),
* nam bao cao (tu thang 1 den thang bao cao, quy chi hien khi du quy)
FORM BUILD_COLUMNS.

  DATA: LV_MIN  TYPE GTY_YEAR,
        LV_Y    TYPE GTY_YEAR,
        LV_MAXM TYPE GTY_MM.

  CLEAR GT_DCOL.

  LV_MIN = GV_YEAR.
  LOOP AT GT_MON ASSIGNING FIELD-SYMBOL(<LFS_M>).
    IF <LFS_M>-YM(4) < LV_MIN.
      LV_MIN = <LFS_M>-YM(4).
    ENDIF.
  ENDLOOP.

  LV_Y = LV_MIN.
  WHILE LV_Y < GV_YEAR_PREV.
    APPEND VALUE #( NAME = |YQ_{ LV_Y }| TEXT = |Số lượng năm { LV_Y }|
                    KIND = 'Q' ) TO GT_DCOL.
    APPEND VALUE #( NAME = |YV_{ LV_Y }| TEXT = |Thành tiền năm { LV_Y }|
                    KIND = 'V' ) TO GT_DCOL.
    LV_Y = LV_Y + 1.
  ENDWHILE.

  LV_Y    = GV_YEAR_PREV.
  LV_MAXM = 12.
  PERFORM ADD_YEAR_BLOCK USING LV_Y LV_MAXM ABAP_TRUE.

  LV_Y    = GV_YEAR.
  LV_MAXM = GV_MONTH.
  PERFORM ADD_YEAR_BLOCK USING LV_Y LV_MAXM ABAP_FALSE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_YEAR_BLOCK
*&---------------------------------------------------------------------*
FORM ADD_YEAR_BLOCK USING IV_Y     TYPE GTY_YEAR
                          IV_MAXM  TYPE GTY_MM
                          IV_TOTAL TYPE ABAP_BOOL.

  DATA: LV_M TYPE GTY_MM,
        LV_Q TYPE N LENGTH 1.

  DO IV_MAXM TIMES.

    LV_M = SY-INDEX.

    APPEND VALUE #( NAME = |MQ_{ IV_Y }{ LV_M }|
                    TEXT = |Số lượng tháng { LV_M ALPHA = OUT }/{ IV_Y }|
                    KIND = 'Q' ) TO GT_DCOL.
    APPEND VALUE #( NAME = |MV_{ IV_Y }{ LV_M }|
                    TEXT = |Thành tiền tháng { LV_M ALPHA = OUT }/{ IV_Y }|
                    KIND = 'V' ) TO GT_DCOL.

    IF LV_M MOD 3 = 0.
      LV_Q = LV_M / 3.
      APPEND VALUE #( NAME = |QQ_{ IV_Y }_{ LV_Q }|
                      TEXT = |Số lượng quý { LV_Q }/{ IV_Y }|
                      KIND = 'Q' ) TO GT_DCOL.
      APPEND VALUE #( NAME = |QV_{ IV_Y }_{ LV_Q }|
                      TEXT = |Thành tiền quý { LV_Q }/{ IV_Y }|
                      KIND = 'V' ) TO GT_DCOL.
    ENDIF.

  ENDDO.

  IF IV_TOTAL = ABAP_TRUE.
    APPEND VALUE #( NAME = |YQ_{ IV_Y }| TEXT = |Số lượng năm { IV_Y }|
                    KIND = 'Q' ) TO GT_DCOL.
    APPEND VALUE #( NAME = |YV_{ IV_Y }| TEXT = |Thành tiền năm { IV_Y }|
                    KIND = 'V' ) TO GT_DCOL.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FILL_OUTPUT
*&---------------------------------------------------------------------*
* Moi dong hop dong -> 1 dong ket qua: cot co dinh + so lieu theo thang/quy/nam
FORM FILL_OUTPUT.

  DATA: LS_FIX   TYPE GTY_FIX,
        LR_LINE  TYPE REF TO DATA,
        LV_NAME  TYPE C LENGTH 30,
        LV_OBJEK TYPE AUSP-OBJEK,
        LV_Y     TYPE GTY_YEAR,
        LV_M     TYPE GTY_MM,
        LV_Q     TYPE N LENGTH 1,
        LV_CUM_Q TYPE VBAP-ZMENG,
        LV_CUM_V TYPE VBAP-NETWR,
        LV_VAL   TYPE VBAP-NETWR.

  FIELD-SYMBOLS: <LFS_LINE> TYPE ANY,
                 <LFS_CUST> TYPE GTY_CUST,
                 <LFS_EMP>  TYPE GTY_EMP,
                 <LFS_SPCL> TYPE GTY_SPCL,
                 <LFS_BG>   TYPE GTY_BG.

  CLEAR: GV_SUM_WIN, GV_SUM_CUM.

  LOOP AT GT_ITEM ASSIGNING FIELD-SYMBOL(<LFS_I>).

    CREATE DATA LR_LINE TYPE HANDLE GO_STRUCT.
    ASSIGN LR_LINE->* TO <LFS_LINE>.

    CLEAR: LS_FIX, LV_CUM_Q, LV_CUM_V.

*   Thong tin hop dong / hang hoa
    LS_FIX-VKORG     = <LFS_I>-VKORG.
    LS_FIX-VKGRP_TX  = <LFS_I>-VKGRP_TX.
    LS_FIX-VKORG_TX  = <LFS_I>-VKORG_TX.
    LS_FIX-KVGR1_TX  = <LFS_I>-KVGR1_TX.
    LS_FIX-KUNNR1    = <LFS_I>-KUNNR1.
    LS_FIX-KUNNR     = <LFS_I>-KUNNR.
    LS_FIX-PLTYP_TX  = <LFS_I>-PLTYP_TX.
    LS_FIX-VBELN1    = <LFS_I>-VBELN1.
    LS_FIX-VBELN     = <LFS_I>-VBELN.
    LS_FIX-GUEBG     = <LFS_I>-GUEBG.
    LS_FIX-GUEEN     = <LFS_I>-GUEEN.
    LS_FIX-REP_DATE  = GV_DATE_TO.
    LS_FIX-MATNR     = <LFS_I>-MATNR.
    LS_FIX-ARKTX     = <LFS_I>-ARKTX.
    LS_FIX-ZIEME     = COND #( WHEN <LFS_I>-ZIEME IS NOT INITIAL
                               THEN <LFS_I>-ZIEME ELSE <LFS_I>-VRKME ).
    LS_FIX-QTY_WIN   = <LFS_I>-ZMENG.
    LS_FIX-VAL_WIN   = <LFS_I>-NETWR.
    LS_FIX-BSTNK     = <LFS_I>-BSTNK.
    LS_FIX-ERDAT     = <LFS_I>-ERDAT.
    LS_FIX-WGBEZ     = <LFS_I>-WGBEZ.
    LS_FIX-PRDHA_TX  = <LFS_I>-PRDHA_TX.
    LS_FIX-PERNR_TDV = <LFS_I>-PERNR_TDV.
    LS_FIX-PERNR_ASM = <LFS_I>-PERNR_ASM.
    LS_FIX-POSNR     = <LFS_I>-POSNR.
    LS_FIX-VKGRP     = <LFS_I>-VKGRP.
    LS_FIX-WAERS     = <LFS_I>-WAERK.

    LS_FIX-COMBO = |{ <LFS_I>-VBELN ALPHA = OUT }{ <LFS_I>-KUNNR ALPHA = OUT }| &&
                   |{ <LFS_I>-MATNR ALPHA = OUT }|.

    IF <LFS_I>-KPEIN <> 0.
      LS_FIX-PRICE = <LFS_I>-NETPR / <LFS_I>-KPEIN.
    ELSE.
      LS_FIX-PRICE = <LFS_I>-NETPR.
    ENDIF.

*   Bao gia: tren hop dong cap 2, neu khong co thi lay tu hop dong cap 1
    IF <LFS_I>-VGTYP = GC_VGTYP_QUOT.
      LS_FIX-VBELN_BG = <LFS_I>-VGBEL.
    ELSEIF <LFS_I>-VGTYP1 = GC_VGTYP_QUOT.
      LS_FIX-VBELN_BG = <LFS_I>-VGBEL1.
    ENDIF.

*   PO hop dong cap 1; neu khong co thi lay PO cua bao gia
    LS_FIX-BSTNK1_BG = <LFS_I>-BSTNK1.
    IF LS_FIX-BSTNK1_BG IS INITIAL AND LS_FIX-VBELN_BG IS NOT INITIAL.
      READ TABLE GT_BG ASSIGNING <LFS_BG>
           WITH TABLE KEY VBELN = LS_FIX-VBELN_BG.
      IF SY-SUBRC = 0.
        LS_FIX-BSTNK1_BG = <LFS_BG>-BSTNK.
      ENDIF.
    ENDIF.

*   Khach hang ky hop dong cap 2: ten, tinh
    READ TABLE GT_CUST ASSIGNING <LFS_CUST>
         WITH TABLE KEY KUNNR = <LFS_I>-KUNNR.
    IF SY-SUBRC = 0.
      LS_FIX-NAME_KH = |{ <LFS_CUST>-NAME1 } { <LFS_CUST>-NAME2 } { <LFS_CUST>-NAME3 }|.
      CONDENSE LS_FIX-NAME_KH.
      LS_FIX-TINH = <LFS_CUST>-REGION_TX.
    ENDIF.

*   Don vi moi thau (khach hang hop dong cap 1)
    READ TABLE GT_CUST ASSIGNING <LFS_CUST>
         WITH TABLE KEY KUNNR = <LFS_I>-KUNNR1.
    IF SY-SUBRC = 0.
      LS_FIX-NAME1_L1 = |{ <LFS_CUST>-NAME1 } { <LFS_CUST>-NAME2 } { <LFS_CUST>-NAME3 }|.
      CONDENSE LS_FIX-NAME1_L1.
    ENDIF.

*   Trinh duoc vien, ASM
    READ TABLE GT_EMP ASSIGNING <LFS_EMP>
         WITH TABLE KEY PERNR = <LFS_I>-PERNR_TDV.
    IF SY-SUBRC = 0.
      LS_FIX-NAME_TDV = <LFS_EMP>-ENAME.
    ENDIF.
    READ TABLE GT_EMP ASSIGNING <LFS_EMP>
         WITH TABLE KEY PERNR = <LFS_I>-PERNR_ASM.
    IF SY-SUBRC = 0.
      LS_FIX-NAME_ASM = <LFS_EMP>-ENAME.
    ENDIF.

*   Nhom san pham phan tich cua vat tu
    LV_OBJEK = <LFS_I>-MATNR.
    READ TABLE GT_SPCL ASSIGNING <LFS_SPCL>
         WITH TABLE KEY OBJEK = LV_OBJEK.
    IF SY-SUBRC = 0.
      LS_FIX-SPCL = <LFS_SPCL>-ATWRT.
    ENDIF.

*   Thoi han hop dong
    LS_FIX-DAYS_LEFT = <LFS_I>-GUEEN - SY-DATUM.
    LS_FIX-GUEEN_MM  = <LFS_I>-GUEEN+4(2).
    LS_FIX-GUEEN_YY  = <LFS_I>-GUEEN(4).
    PERFORM FULL_MONTHS USING <LFS_I>-GUEBG <LFS_I>-GUEEN
                        CHANGING LS_FIX-MON_TOTAL.
    PERFORM FULL_MONTHS USING <LFS_I>-GUEBG GV_DATE_TO
                        CHANGING LS_FIX-MON_DONE.
    IF LS_FIX-MON_DONE > LS_FIX-MON_TOTAL.
      LS_FIX-MON_DONE = LS_FIX-MON_TOTAL.
    ENDIF.
    LS_FIX-MON_LEFT = LS_FIX-MON_TOTAL - LS_FIX-MON_DONE.

*   So lieu thuc hien theo thang -> quy / nam
    LOOP AT GT_MON ASSIGNING FIELD-SYMBOL(<LFS_M>)
         WHERE VBELN = <LFS_I>-VBELN AND POSNR = <LFS_I>-POSNR.

      LV_Y = <LFS_M>-YM(4).
      LV_M = <LFS_M>-YM+4(2).
      LV_CUM_Q = LV_CUM_Q + <LFS_M>-QTY.
      LV_CUM_V = LV_CUM_V + <LFS_M>-VAL.

      IF LV_Y >= GV_YEAR_PREV.

        LV_NAME = |MQ_{ <LFS_M>-YM }|.
        PERFORM ADD_TO_FIELD USING LV_NAME <LFS_M>-QTY CHANGING <LFS_LINE>.
        LV_NAME = |MV_{ <LFS_M>-YM }|.
        PERFORM ADD_TO_FIELD USING LV_NAME <LFS_M>-VAL CHANGING <LFS_LINE>.

        LV_Q = ( LV_M + 2 ) DIV 3.
        LV_NAME = |QQ_{ LV_Y }_{ LV_Q }|.
        PERFORM ADD_TO_FIELD USING LV_NAME <LFS_M>-QTY CHANGING <LFS_LINE>.
        LV_NAME = |QV_{ LV_Y }_{ LV_Q }|.
        PERFORM ADD_TO_FIELD USING LV_NAME <LFS_M>-VAL CHANGING <LFS_LINE>.

        IF LV_Y = GV_YEAR_PREV.
          LV_NAME = |YQ_{ LV_Y }|.
          PERFORM ADD_TO_FIELD USING LV_NAME <LFS_M>-QTY CHANGING <LFS_LINE>.
          LV_NAME = |YV_{ LV_Y }|.
          PERFORM ADD_TO_FIELD USING LV_NAME <LFS_M>-VAL CHANGING <LFS_LINE>.
        ENDIF.

      ELSE.

*       Nam cu: chi cong so luong, thanh tien = so luong x gia trung thau
        LV_NAME = |YQ_{ LV_Y }|.
        PERFORM ADD_TO_FIELD USING LV_NAME <LFS_M>-QTY CHANGING <LFS_LINE>.
        LV_VAL = <LFS_M>-QTY * LS_FIX-PRICE.
        LV_NAME = |YV_{ LV_Y }|.
        PERFORM ADD_TO_FIELD USING LV_NAME LV_VAL CHANGING <LFS_LINE>.

      ENDIF.

    ENDLOOP.

    LS_FIX-CUM_Q = LV_CUM_Q.
    LS_FIX-CUM_V = LV_CUM_V.
    LS_FIX-REM_Q = LS_FIX-QTY_WIN - LV_CUM_Q.
    LS_FIX-REM_V = LS_FIX-VAL_WIN - LV_CUM_V.

*   Loc theo trang thai thuc hien
    CASE ABAP_TRUE.
      WHEN P_REM.
        CHECK LS_FIX-REM_Q > 0.
      WHEN P_DONE.
        CHECK LS_FIX-REM_Q <= 0.
    ENDCASE.

    MOVE-CORRESPONDING LS_FIX TO <LFS_LINE>.
    APPEND <LFS_LINE> TO <GFS_OUT>.

    GV_SUM_WIN = GV_SUM_WIN + LS_FIX-VAL_WIN.
    GV_SUM_CUM = GV_SUM_CUM + LS_FIX-CUM_V.

  ENDLOOP.

  IF GV_SUM_WIN <> 0.
    GV_RATE = GV_SUM_CUM / GV_SUM_WIN * 100.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_TO_FIELD
*&---------------------------------------------------------------------*
* Cong gia tri vao cot theo ten; cot khong ton tai (vd quy chua du) thi bo qua
FORM ADD_TO_FIELD USING IV_NAME TYPE CLIKE
                        IV_VAL  TYPE P
                  CHANGING CS_LINE TYPE ANY.

  FIELD-SYMBOLS <LFS_FLD> TYPE ANY.

  ASSIGN COMPONENT IV_NAME OF STRUCTURE CS_LINE TO <LFS_FLD>.
  IF SY-SUBRC = 0.
    <LFS_FLD> = <LFS_FLD> + IV_VAL.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FULL_MONTHS
*&---------------------------------------------------------------------*
* So thang tron giua 2 ngay (tinh ca ngay cuoi); den < tu thi bang 0
FORM FULL_MONTHS USING IV_FROM TYPE D
                       IV_TO   TYPE D
                 CHANGING CV_MON TYPE I.

  DATA LV_NEXT TYPE D.

  CV_MON = 0.
  CHECK IV_TO >= IV_FROM.

  LV_NEXT = IV_TO + 1.
  CV_MON  = ( LV_NEXT(4) - IV_FROM(4) ) * 12
          + ( LV_NEXT+4(2) - IV_FROM+4(2) ).
  IF LV_NEXT+6(2) < IV_FROM+6(2).
    CV_MON = CV_MON - 1.
  ENDIF.

ENDFORM.
