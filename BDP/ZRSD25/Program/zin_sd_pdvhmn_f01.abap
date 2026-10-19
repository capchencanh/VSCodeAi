*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_PDVHMN_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form SET_DEFAULT_DATE
*&---------------------------------------------------------------------*
FORM SET_DEFAULT_DATE.

  CLEAR S_AUDAT.
  S_AUDAT-SIGN     = 'I'.
  S_AUDAT-OPTION   = 'BT'.
  S_AUDAT-LOW      = SY-DATUM.
  S_AUDAT-LOW+6(2) = '01'.
  S_AUDAT-HIGH     = SY-DATUM.
  APPEND S_AUDAT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_AUTHORITY
*&---------------------------------------------------------------------*
FORM CHECK_AUTHORITY.

  SELECT DISTINCT VKORG, VTWEG, SPART
    FROM VBAK
   WHERE VKORG IN @S_VKORG
     AND VTWEG IN @S_VTWEG
     AND AUDAT IN @S_AUDAT
    INTO TABLE @DATA(LT_ORG).

  LOOP AT LT_ORG ASSIGNING FIELD-SYMBOL(<LFS_ORG>).
    AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
             ID 'VKORG' FIELD <LFS_ORG>-VKORG
             ID 'VTWEG' FIELD <LFS_ORG>-VTWEG
             ID 'SPART' FIELD <LFS_ORG>-SPART
             ID 'ACTVT' FIELD '03'.
    IF SY-SUBRC <> 0.
      MESSAGE E001(ZMC_SD) WITH 'Khong co quyen voi to chuc ban hang'
                                <LFS_ORG>-VKORG.            "#EC NOTEXT
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
FORM GET_DATA.

  PERFORM GET_ORDER.
  CHECK GT_ORDER IS NOT INITIAL.

  PERFORM BUILD_ALV_DATA.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_ORDER
*&---------------------------------------------------------------------*
FORM GET_ORDER.
  WITH
    +EXPO AS (
      SELECT PARTNER, CREDIT_SGMNT, SUM( AMOUNT ) AS EXPOSURE
        FROM UKM_TOTALS
       GROUP BY PARTNER, CREDIT_SGMNT )
  SELECT A~VBELN, A~AUDAT, A~NETWR, A~WAERK, A~VKBUR, A~KUNNR, A~KKBER,
         A~CMGST, A~CMFRE, A~AMTBL,
         O~BEZEI AS VKBUR_TX,
         V~KDGRP, G~KTEXT AS KDGRP_TX,
         E~PERNR, T~ENAME AS PERNR_TX,
         CASE WHEN K~XCPDK = @ABAP_TRUE OR K~ADRNR = @SPACE
              THEN AV~NAME1 ELSE AK~NAME1 END AS NAME1,
         CASE WHEN K~XCPDK = @ABAP_TRUE OR K~ADRNR = @SPACE
              THEN AV~NAME2 ELSE AK~NAME2 END AS NAME2,
         CASE WHEN K~XCPDK = @ABAP_TRUE OR K~ADRNR = @SPACE
              THEN AV~NAME3 ELSE AK~NAME3 END AS NAME3,
         CASE WHEN K~XCPDK = @ABAP_TRUE OR K~ADRNR = @SPACE
              THEN AV~NAME4 ELSE AK~NAME4 END AS NAME4,
         S~CREDIT_SGMNT, M~CREDIT_LIMIT, X~EXPOSURE
    FROM VBAK AS A
    LEFT OUTER JOIN TVKBT AS O
           ON O~SPRAS = @SY-LANGU AND O~VKBUR = A~VKBUR
    LEFT OUTER JOIN VBPA AS P
           ON P~VBELN = A~VBELN AND P~POSNR = @GC_POSNR_HD AND P~PARVW = @GC_PARVW_AG
    LEFT OUTER JOIN VBPA AS E
           ON E~VBELN = A~VBELN AND E~POSNR = @GC_POSNR_HD AND E~PARVW = @GC_PARVW_VE
* Ten TDV hieu luc tai ngay dat hang
    LEFT OUTER JOIN PA0001 AS T
           ON T~PERNR = E~PERNR
          AND T~BEGDA <= A~AUDAT AND T~ENDDA >= A~AUDAT
    LEFT OUTER JOIN KNA1 AS K ON K~KUNNR = A~KUNNR
    LEFT OUTER JOIN KNVV AS V
           ON V~KUNNR = A~KUNNR AND V~VKORG = A~VKORG
          AND V~VTWEG = A~VTWEG AND V~SPART = A~SPART
    LEFT OUTER JOIN T151T AS G ON G~SPRAS = @SY-LANGU AND G~KDGRP = V~KDGRP
    LEFT OUTER JOIN ADRC AS AK
           ON AK~ADDRNUMBER = K~ADRNR AND AK~DATE_FROM <= @SY-DATUM
          AND AK~DATE_TO >= @SY-DATUM AND AK~NATION = @SPACE
    LEFT OUTER JOIN ADRC AS AV
           ON AV~ADDRNUMBER = P~ADRNR AND AV~DATE_FROM <= @SY-DATUM
          AND AV~DATE_TO >= @SY-DATUM AND AV~NATION = @SPACE
    LEFT OUTER JOIN CVI_CUST_LINK AS L ON L~CUSTOMER = A~KUNNR
    LEFT OUTER JOIN BUT000 AS B ON B~PARTNER_GUID = L~PARTNER_GUID
    LEFT OUTER JOIN UKM_KKBER2SGM AS S ON S~KKBER = A~KKBER
    LEFT OUTER JOIN UKMBP_CMS_SGM AS M
           ON M~PARTNER = B~PARTNER AND M~CREDIT_SGMNT = S~CREDIT_SGMNT
    LEFT OUTER JOIN +EXPO AS X
           ON X~PARTNER = B~PARTNER AND X~CREDIT_SGMNT = S~CREDIT_SGMNT
   WHERE A~VKORG IN @S_VKORG
     AND A~VTWEG IN @S_VTWEG
     AND A~VKBUR IN @S_VKBUR
     AND A~AUDAT IN @S_AUDAT
     AND A~VBELN IN @S_VBELN
     AND A~AUART IN @S_AUART
     AND A~KUNNR IN @S_KUNNR
     AND A~KKBER IN @S_KKBER
     AND A~CMFRE IN @S_CMFRE
     AND A~CMGST IN @S_CMGST
     AND A~WAERK  = @GC_WAERK_VND
     AND A~CMGST IN ( @GC_CMGST_BLOCK, @GC_CMGST_PART, @GC_CMGST_REL )
     AND V~KDGRP IN @S_KDGRP
     AND E~PERNR IN @S_PERNR
     AND EXISTS ( SELECT I~VBELN FROM VBAP AS I
                   WHERE I~VBELN = A~VBELN AND I~ABGRU = @SPACE )
   ORDER BY A~VKBUR, A~KUNNR, A~AUDAT, A~VBELN
    INTO CORRESPONDING FIELDS OF TABLE @GT_ORDER.      "#EC CI_BUFFJOIN


ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_ALV_DATA
*&---------------------------------------------------------------------*
FORM BUILD_ALV_DATA.

  DATA: LT_BILL   TYPE GTT_BILL,
        LT_CHG    TYPE GTT_CHG,
        LT_OVD    TYPE GTT_OVERDUE,
        LV_REASON TYPE GTY_ALV-REASON.

  PERFORM GET_BILLING   CHANGING LT_BILL.
  PERFORM GET_CHANGELOG CHANGING LT_CHG.
  PERFORM GET_OVERDUE   CHANGING LT_OVD.

  LOOP AT GT_ORDER ASSIGNING FIELD-SYMBOL(<LFS_ORD>).

    DATA(LV_LIMIT) = <LFS_ORD>-CREDIT_LIMIT.
    DATA(LV_EXPOS) = <LFS_ORD>-EXPOSURE.


    IF <LFS_ORD>-CREDIT_SGMNT IS NOT INITIAL.
      AUTHORITY-CHECK OBJECT 'F_UKM_SGMT'
               ID 'UKM_SGMNT' FIELD <LFS_ORD>-CREDIT_SGMNT
               ID 'ACTVT'     FIELD '03'.
      IF SY-SUBRC <> 0.
        CLEAR: LV_LIMIT, LV_EXPOS.
      ENDIF.
    ENDIF.

    DATA(LV_OVERDUE) = VALUE VBAK-NETWR( LT_OVD[ KUNNR = <LFS_ORD>-KUNNR ]-AMOUNT OPTIONAL ).

    DATA(LV_OVER) = XSDBOOL( LV_EXPOS + <LFS_ORD>-NETWR > LV_LIMIT ).
    DATA(LV_LATE) = XSDBOOL( LV_OVERDUE > 0 ).

    LV_REASON = COND #(
      WHEN LV_OVER = ABAP_TRUE AND LV_LATE = ABAP_TRUE THEN TEXT-R03
      WHEN LV_OVER = ABAP_TRUE                         THEN TEXT-R01
      WHEN LV_LATE = ABAP_TRUE                         THEN TEXT-R02
      ELSE SPACE ).
    CHECK LV_REASON IN S_REASON.

    DATA(LS_CHG) = VALUE GTY_CHG( LT_CHG[ VBELN = <LFS_ORD>-VBELN ] OPTIONAL ).


    DATA(LV_NAME) = COND STRING(
      WHEN <LFS_ORD>-NAME2 IS INITIAL AND <LFS_ORD>-NAME3 IS INITIAL
                                      AND <LFS_ORD>-NAME4 IS INITIAL
      THEN <LFS_ORD>-NAME1
      ELSE CONDENSE( |{ <LFS_ORD>-NAME2 } { <LFS_ORD>-NAME3 } { <LFS_ORD>-NAME4 }| ) ).

    APPEND VALUE #(
      STT      = LINES( GT_ALV ) + 1
      VKBUR    = <LFS_ORD>-VKBUR
      VKBUR_TX = <LFS_ORD>-VKBUR_TX
      KUNNR    = <LFS_ORD>-KUNNR
      KUNNR_TX = LV_NAME
      KDGRP    = <LFS_ORD>-KDGRP
      KDGRP_TX = <LFS_ORD>-KDGRP_TX
      VBELN    = <LFS_ORD>-VBELN
      VBELN_VF = VALUE #( LT_BILL[ VBELN = <LFS_ORD>-VBELN ]-BILLLIST OPTIONAL )
      CHANGENR = LS_CHG-CHANGENR
      AUDAT    = <LFS_ORD>-AUDAT
      NETWR    = <LFS_ORD>-NETWR
      PERNR    = <LFS_ORD>-PERNR
      PERNR_TX = <LFS_ORD>-PERNR_TX
      REASON   = LV_REASON
      CRLIMIT  = LV_LIMIT
      CREXPOS  = LV_EXPOS
      OVERDUE  = LV_OVERDUE
      STATUS   = SWITCH #( <LFS_ORD>-CMGST
                   WHEN GC_CMGST_BLOCK THEN TEXT-S01
                   WHEN GC_CMGST_PART  THEN TEXT-S02
                   WHEN GC_CMGST_REL   THEN TEXT-S03
                   ELSE SPACE )
      APPROVER = LS_CHG-APPROVER
* Ngay phe duyet: uu tien CMFRE, trong thi lay ngay ghi nhat ky
      APPDATE  = COND #( WHEN <LFS_ORD>-CMFRE IS NOT INITIAL
                         THEN <LFS_ORD>-CMFRE ELSE LS_CHG-UDATE )
      AMTBL    = <LFS_ORD>-AMTBL
      WAERK    = <LFS_ORD>-WAERK ) TO GT_ALV.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_BILLING
*&---------------------------------------------------------------------*
FORM GET_BILLING CHANGING CT_BILL TYPE GTT_BILL.

  DATA LR_VBELN TYPE RANGE OF VBAK-VBELN.

  LR_VBELN = VALUE #( FOR LS_O IN GT_ORDER
                      ( SIGN = 'I' OPTION = 'EQ' LOW = LS_O-VBELN ) ).

* Gop so hoa don (khong trung) cua tung don hang ngay tren HANA
  WITH
    +FLOW AS (
      SELECT DISTINCT F~VBELV, F~VBELN
        FROM VBFA AS F
        INNER JOIN VBRK AS R ON R~VBELN = F~VBELN
       WHERE F~VBELV   IN @LR_VBELN
         AND F~VBTYP_N IN ( 'M', 'O', 'P' )
         AND R~FKSTO   <> @ABAP_TRUE )
  SELECT VBELV AS VBELN,
         STRING_AGG( VBELN, ', ' ORDER BY VBELN ) AS BILLLIST
    FROM +FLOW
   GROUP BY VBELV
    INTO TABLE @CT_BILL.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_CHANGELOG
*&---------------------------------------------------------------------*
FORM GET_CHANGELOG CHANGING CT_CHG TYPE GTT_CHG.

  DATA LR_OBJID TYPE RANGE OF CDHDR-OBJECTID.

  LR_OBJID = VALUE #( FOR LS_O IN GT_ORDER
                      ( SIGN = 'I' OPTION = 'EQ' LOW = LS_O-VBELN ) ).

  SELECT H~OBJECTID, H~CHANGENR, H~USERNAME, H~UDATE, A~NAME_TEXT
    FROM CDHDR AS H
    INNER JOIN CDPOS AS P
           ON P~OBJECTCLAS = H~OBJECTCLAS
          AND P~OBJECTID   = H~OBJECTID
          AND P~CHANGENR   = H~CHANGENR
    LEFT OUTER JOIN USR21 AS U ON U~BNAME = H~USERNAME
    LEFT OUTER JOIN ADRP AS A
           ON A~PERSNUMBER = U~PERSNUMBER AND A~DATE_FROM <= @SY-DATUM
          AND A~DATE_TO >= @SY-DATUM AND A~NATION = @SPACE
   WHERE H~OBJECTCLAS = @GC_OBJCLAS
     AND H~OBJECTID  IN @LR_OBJID
     AND P~TABNAME    = @GC_TABNAME_CD
     AND P~FNAME      = @GC_FNAME_CD
   ORDER BY H~OBJECTID, H~UDATE DESCENDING, H~UTIME DESCENDING,
            H~CHANGENR DESCENDING
    INTO TABLE @DATA(LT_CDHDR).

* Moi don lay ban ghi moi nhat
  DELETE ADJACENT DUPLICATES FROM LT_CDHDR COMPARING OBJECTID.

  CT_CHG = VALUE #(
    FOR LS_H IN LT_CDHDR
    ( VBELN    = LS_H-OBJECTID
      CHANGENR = LS_H-CHANGENR
      UDATE    = LS_H-UDATE
      APPROVER = COND #( WHEN LS_H-NAME_TEXT IS NOT INITIAL
                         THEN |{ LS_H-USERNAME } - { LS_H-NAME_TEXT }|
                         ELSE LS_H-USERNAME ) ) ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_OVERDUE
*&---------------------------------------------------------------------*
FORM GET_OVERDUE CHANGING CT_OVERDUE TYPE GTT_OVERDUE.

  DATA LR_KUNNR TYPE RANGE OF VBAK-KUNNR.

  LR_KUNNR = VALUE #( FOR GROUPS LS_G OF LS_O IN GT_ORDER
                      GROUP BY LS_O-KUNNR
                      ( SIGN = 'I' OPTION = 'EQ' LOW = LS_G ) ).

* [FS THIEU] chua loc company code
* Den han = ZFBDT + ZBD1T; ghi co (SHKZG = H) lam giam no qua han
  SELECT KUNNR,
         SUM( CASE WHEN SHKZG = 'H'
                   THEN CAST( DMBTR AS DEC( 17, 2 ) ) * -1
                   ELSE CAST( DMBTR AS DEC( 17, 2 ) ) END ) AS AMOUNT
    FROM BSID_VIEW
   WHERE KUNNR IN @LR_KUNNR
     AND DATS_ADD_DAYS( ZFBDT, CAST( ZBD1T AS INT4 ) ) < @SY-DATUM
   GROUP BY KUNNR
    INTO TABLE @CT_OVERDUE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F4_REASON
*&---------------------------------------------------------------------*
FORM F4_REASON.

  TYPES: BEGIN OF LTY_R,
           REASON TYPE C LENGTH 30,
         END OF LTY_R.

  DATA LT_R TYPE STANDARD TABLE OF LTY_R WITH EMPTY KEY.

  LT_R = VALUE #( ( REASON = TEXT-R01 )
                  ( REASON = TEXT-R02 )
                  ( REASON = TEXT-R03 ) ).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      RETFIELD    = 'REASON'
      DYNPPROG    = SY-REPID
      DYNPNR      = SY-DYNNR
      DYNPROFIELD = 'S_REASON-LOW'
      VALUE_ORG   = 'S'
    TABLES
      VALUE_TAB   = LT_R
    EXCEPTIONS
      OTHERS      = 1.

ENDFORM.