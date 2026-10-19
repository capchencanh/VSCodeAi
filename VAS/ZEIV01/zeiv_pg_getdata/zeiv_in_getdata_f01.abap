*&---------------------------------------------------------------------*
*& Include          ZEIV_IN_GETDATA_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form CHECK_CONDITION
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_CONDITION .
  CALL FUNCTION 'ZCORE_AUTHORIZATION_BUKRS'
    EXPORTING
      I_BUKRS = P_BUKRS.

*  IF SY-TCODE = 'ZEIV01'.
*    "Bắt buộc nếu người dùng chọn “Consignment Sales”
**    IF R_CS EQ 'X' AND S_KUNNR[] IS INITIAL.
**      MESSAGE 'Fill out customer field' TYPE 'E'.
**    ENDIF.
*
*    " Bắt buộc nếu người dùng chọn “Return to Vendor”
*    IF R_MM EQ 'X' AND S_LIFNR[] IS INITIAL.
*      MESSAGE 'Fill out vendor field' TYPE 'E'.
*    ENDIF.
*
*    " Bắt buộc nếu người dùng chọn tham số “FI Document”
*    IF R_FI EQ 'X' AND S_BLART[] IS INITIAL.
*      MESSAGE 'Fill out document type field' TYPE 'E'.
*    ENDIF.
*  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DATA .


  " Get all data from ACDOCA
  PERFORM GET_ACDOCA.

  IF S_KUNNR IS NOT INITIAL.
    PERFORM CHECK_INPUT_KUNNR.
  ENDIF.

  IF S_LIFNR IS NOT INITIAL.
    PERFORM CHECK_INPUT_LIFNR.
  ENDIF.

  PERFORM GET_CUSTOMER_CS.

  " Check history print
  PERFORM CHECK_HISTORY.
  " Get all detail
  PERFORM GET_ALL_DETAIL.
ENDFORM.

FORM GET_ACDOCA.
  DATA: LR_BLART TYPE RANGE OF BLART WITH HEADER LINE.

  LR_BLART-OPTION = 'EQ'.
  LR_BLART-SIGN   = 'I'.

  IF R_SD EQ 'X'. "OR R_CS EQ 'X'. "SD
    LR_BLART-LOW = 'RV'.
    APPEND LR_BLART.
  ELSEIF R_MM EQ 'X'. "MM
    LR_BLART-LOW = 'RE'.
    APPEND LR_BLART.
  ELSE. "FI " DG', 'AB', 'RE', 'KR', 'KG'
    LR_BLART-LOW = 'DG'.
    APPEND LR_BLART.

    LR_BLART-LOW = 'AB'.
    APPEND LR_BLART.

    LR_BLART-LOW = 'RE'.
    APPEND LR_BLART.

    LR_BLART-LOW = 'KR'.
    APPEND LR_BLART.

    LR_BLART-LOW = 'KG'.
    APPEND LR_BLART.

    LR_BLART-LOW = 'DR'.
    APPEND LR_BLART.

    IF R_FI EQ ABAP_TRUE. "24.09.23: tuan.nguyen4
      LR_BLART-LOW = 'ZG'.
      APPEND LR_BLART.
    ENDIF.
  ENDIF.

  " START --> 30.01.24: tuan.nguyen4
  IF SY-BATCH IS NOT INITIAL.
    S_BUDAT-OPTION = 'BT'.
    S_BUDAT-HIGH   = SY-DATUM.

    READ TABLE S_BUDAT[] ASSIGNING FIELD-SYMBOL(<LFS_BUDAT>) INDEX 1.
    IF SY-SUBRC EQ 0.
      <LFS_BUDAT>-OPTION = 'BT'.
      <LFS_BUDAT>-HIGH   = SY-DATUM.
    ENDIF.
  ENDIF.
  " END   --> 30.01.24: tuan.nguyen4

  SELECT
     ACDOCA~RBUKRS AS BUKRS, "Company code
     ACDOCA~BELNR, "Document Number
     ACDOCA~GJAHR, "Fiscal year
     ACDOCA~AWREF AS AWKEY,"Document link
     ACDOCA~USNAM, "User name
     ACDOCA~BLART, "Document Type
     ACDOCA~BLDAT, "Document date
     ACDOCA~BUDAT, "Posting date
     ACDOCA~KUNNR,
     ACDOCA~LIFNR,
     BKPF~XREF1_HD, "Reference 1
     BKPF~XREF2_HD, "Reference 2
*    ACDOCA~AWKEY   "Document link
     ACDOCA~AWTYP,
     BKPF~WAERS,
     BKPF~KURSF AS KURRF,
     BKPF~KURSF,
     BKPF~CPUDT,
     BKPF~BKTXT,
     VBRK~FKDAT,
     VBRK~FKART
*     LOG~PISID,
*     LOG~REQUEST
   FROM ACDOCA
   INNER JOIN BKPF ON BKPF~BUKRS  EQ ACDOCA~RBUKRS AND
                      BKPF~BELNR  EQ ACDOCA~BELNR  AND
                      BKPF~GJAHR  EQ ACDOCA~GJAHR
*   LEFT  JOIN ZEINV_TB_LOG AS LOG ON CONCAT( ACDOCA~RBUKRS,
*                                        CONCAT( '@', CONCAT( ACDOCA~GJAHR,
*                                            CONCAT( '@', ACDOCA~BELNR ) ) ) ) = LOG~PISID
   LEFT  JOIN VBRK ON VBRK~VBELN EQ ACDOCA~AWREF
   WHERE ACDOCA~RBUKRS EQ @P_BUKRS
     AND ACDOCA~BELNR  IN @S_BELNR
     AND ACDOCA~GJAHR  IN @S_GJAHR
     AND ACDOCA~BLART  IN @S_BLART
     AND ACDOCA~BLART  IN @LR_BLART
     AND ACDOCA~BUDAT  IN @S_BUDAT
     AND ACDOCA~BUDAT  IN @S_BUDAT
*     AND XBLNR IN S_XBLNR
     AND BKPF~STBLG EQ @SPACE " C005: không lấy cặp chứng từ Reverse
     AND BKPF~XREVERSING EQ ''
     AND ACDOCA~AWREF IN @S_VBELN
     AND BKPF~BUDAT >= '20191007'
   INTO CORRESPONDING FIELDS OF TABLE @GT_HEADER.

  SORT GT_HEADER.
*  DELETE GT_HEADER WHERE KUNNR IS INITIAL AND LIFNR IS INITIAL.
  IF GT_HEADER IS INITIAL.
    MESSAGE 'NO DATA' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_INPUT_KUNNR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_INPUT_KUNNR .
  DELETE GT_HEADER WHERE KUNNR NOT IN S_KUNNR.
  IF GT_HEADER IS INITIAL.
    MESSAGE 'NO DATA' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_INPUT_LIFNR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_INPUT_LIFNR .
  DELETE GT_HEADER WHERE LIFNR NOT IN S_LIFNR.
  IF GT_HEADER IS INITIAL.
    MESSAGE 'NO DATA' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_HISTORY
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_HISTORY.
  SORT GT_HEADER BY BUKRS GJAHR BELNR KUNNR DESCENDING LIFNR DESCENDING.
  DELETE ADJACENT DUPLICATES FROM GT_HEADER COMPARING BUKRS GJAHR BELNR.

  " Get data eInvoice
  IF GT_HEADER[] IS NOT INITIAL.
    IF P_NEW EQ 'X'.
      SELECT *
      INTO CORRESPONDING FIELDS OF TABLE GT_EIV_HD
      FROM ZTB_EB_HEADER
      FOR ALL ENTRIES IN GT_HEADER
      WHERE BUKRS   EQ GT_HEADER-BUKRS AND
            GJAHR   EQ GT_HEADER-GJAHR AND
            BELNR   EQ GT_HEADER-BELNR AND
            PHASE   NE 1.
      LOOP AT GT_HEADER INTO GS_HEADER.
        READ TABLE GT_EIV_HD INTO GS_EIV_HD WITH KEY BUKRS = GS_HEADER-BUKRS
                                                     GJAHR = GS_HEADER-GJAHR
                                                     BELNR = GS_HEADER-BELNR.
        IF SY-SUBRC = 0.
          DELETE GT_HEADER WHERE BUKRS  = GS_HEADER-BUKRS AND
                                 GJAHR  = GS_HEADER-GJAHR  AND
                                 BELNR  = GS_HEADER-BELNR.
        ENDIF.
      ENDLOOP.
    ELSE.
      SELECT *
      INTO CORRESPONDING FIELDS OF TABLE GT_EIV_HD
      FROM ZTB_EB_HEADER
      FOR ALL ENTRIES IN GT_HEADER
      WHERE BUKRS = GT_HEADER-BUKRS
        AND BELNR = GT_HEADER-BELNR
        AND GJAHR = GT_HEADER-GJAHR
        AND PHASE = '2'.
      LOOP AT GT_HEADER INTO GS_HEADER.
        READ TABLE GT_EIV_HD INTO GS_EIV_HD WITH KEY BUKRS = GS_HEADER-BUKRS
                                                     GJAHR = GS_HEADER-GJAHR
                                                     BELNR = GS_HEADER-BELNR.
        IF SY-SUBRC NE 0.
          DELETE GT_HEADER WHERE BUKRS  = GS_HEADER-BUKRS AND
                                 GJAHR  = GS_HEADER-GJAHR  AND
                                 BELNR  = GS_HEADER-BELNR.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.



  IF GT_HEADER IS INITIAL.
    MESSAGE 'NO DATA' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_HEADER
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_ALL_DETAIL.
  DATA: LW_WAERS TYPE WAERS.

  SELECT SINGLE WAERS
  INTO LW_WAERS
  FROM T001
  WHERE BUKRS = P_BUKRS.

  SELECT DISTINCT
    ZTB_EB_MAP_PAYME~BUKRS,
    ZTB_EB_MAP_PAYME~ZTERM,
    ZTB_EB_MAP_PAYME~THANH_TOAN
    FROM ZTB_EB_MAP_PAYME
    INTO TABLE @DATA(LT_MAP_PAYME).
  SORT LT_MAP_PAYME BY BUKRS ZTERM.

  "KhoaLD add begin 23.12.2025 15:08:29
  "Mapping ZEIV07
  SELECT
    DATA~BUKRS,
    DATA~FKART,
    DATA~GJAHR,
    ZEINV_TB_KY_HIEU~MAU_SO,
    ZEINV_TB_KY_HIEU~KY_HIEU
  FROM ZEINV_TB_KY_HIEU
    INNER JOIN @GT_HEADER AS DATA
                          ON DATA~BUKRS = ZEINV_TB_KY_HIEU~BUKRS
                         AND DATA~FKART = ZEINV_TB_KY_HIEU~FKART
                         AND DATA~GJAHR = ZEINV_TB_KY_HIEU~GJAHR
  ORDER BY DATA~BUKRS, DATA~FKART, DATA~GJAHR
  INTO TABLE @DATA(LT_KY_HIEU).
  "KhoaLD add end 23.12.2025 15:08:29

  LOOP AT GT_HEADER INTO GS_HEADER.
    GS_HEADER-WAERS = LW_WAERS.
    GS_HEADER-JSON_REQ = ICON_XML_DOC.

    IF GS_HEADER-BUKRS EQ '2000'
    OR GS_HEADER-BUKRS EQ 'A000'. "KhoaLD change 17.12.2025
      PERFORM GET_LONG_TEXT_TEN_TAU USING GS_HEADER.
    ENDIF.
    PERFORM GET_EMAIL.
    CASE 'X'.
      WHEN R_SD ."OR R_CS.
        PERFORM GET_HEADER_SD.
        " hoá đơn hk lấy lên
        IF GS_HEADER-ZDEL EQ 'X'.
        ELSE.
          PERFORM GET_DETAIL_SD.
        ENDIF.

      WHEN R_FI.
        PERFORM GET_HEADER_FI.
        PERFORM GET_DETAIL_FI.
      WHEN R_MM.
        PERFORM GET_HEADER_MM.
        PERFORM GET_DETAIL_MM.
      WHEN OTHERS.
    ENDCASE.
    " Ti gia
    IF GS_HEADER-KURRF = 0.
      GS_HEADER-KURRF = 1.
    ELSE.
      GS_HEADER-KURRF = GS_HEADER-KURRF * 1000.
      GS_HEADER-KURRF = GS_HEADER-KURSF * 1000.
    ENDIF.

    "sangvt add begin 04.02.2025 13:15:09
    IF GS_HEADER-ZTERM IS NOT INITIAL .
      READ TABLE LT_MAP_PAYME INTO DATA(LS_MAP_PAYME)
       WITH KEY
       BUKRS = GS_HEADER-BUKRS
       ZTERM = GS_HEADER-ZTERM
       BINARY SEARCH.
      IF SY-SUBRC = 0.
        GS_HEADER-ZTERM_TXT = LS_MAP_PAYME-THANH_TOAN.
        CONDENSE GS_HEADER-ZTERM_TXT.
      ENDIF.
    ENDIF.
    "sangvt add end 04.02.2025 13:15:09

*    "KhoaLD add begin 23.12.2025 15:13:32
    READ TABLE LT_KY_HIEU REFERENCE INTO DATA(LR_KY_HIEU) WITH KEY BUKRS = GS_HEADER-BUKRS
                                                                   FKART = GS_HEADER-FKART
                                                                   GJAHR = GS_HEADER-GJAHR BINARY SEARCH.
    IF SY-SUBRC = 0.
      GS_HEADER-IFORM   = LR_KY_HIEU->MAU_SO.
      GS_HEADER-ISERIAL = LR_KY_HIEU->KY_HIEU.
    ENDIF.
*    "KhoaLD add end 23.12.2025 15:13:32

    MODIFY GT_HEADER FROM GS_HEADER.
  ENDLOOP.

  DELETE GT_HEADER WHERE ZDEL EQ 'X'.
  LOOP AT GT_HEADER INTO GS_HEADER.
    READ TABLE GT_DETAIL_ALL INTO GS_DETAIL_ALL WITH KEY BUKRS = GS_HEADER-BUKRS
                                                         GJAHR = GS_HEADER-GJAHR
                                                         BELNR = GS_HEADER-BELNR.
    IF SY-SUBRC NE 0.
      DELETE GT_HEADER WHERE  BUKRS = GS_HEADER-BUKRS AND
                              GJAHR = GS_HEADER-GJAHR AND
                              BELNR = GS_HEADER-BELNR.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DETAIL_SD
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DETAIL_SD .
  DATA:
    LW_FLAG     TYPE INT2,
    LW_COUNT    TYPE INT2,
    LW_CHAR6    TYPE CHAR6,
    LW_STT      TYPE INT4,
    LW_INT      TYPE INT1,
    LW_MENGE    TYPE MENGE_D,
    LW_LGORT    TYPE LGORT_D,
    LW_VGBEL    TYPE VGBEL,
    LW_KURSK    TYPE KURSK,
    LW_VGPOS    TYPE VGPOS,
    LW_NUMBER   TYPE CHAR10,
    LW_TDOBNAME TYPE TDOBNAME,
    LW_TDNAME   TYPE TDOBNAME,
    LW_Z020     TYPE CHAR255,
    LW_CHAR255  TYPE CHAR255,
    LW_SO       TYPE VBELN,
    LW_SOLINE   TYPE POSNR,
    LW_OD       TYPE VBELN,
    LW_BSTKD    TYPE BSTKD,
    LW_FINO     TYPE BELNR_D.
  DATA:
    LW_FKART     TYPE FKART,
    LW_VTWEG     TYPE VTWEG,
    LW_KNUMV     TYPE KNUMV,
    LW_AMOUNT    TYPE BSPL_REPVAL,
    LS_TAX       TYPE PRCD_ELEMENTS,
    LW_WAERK     TYPE WAERK,
    LT_TAX       TYPE TABLE OF PRCD_ELEMENTS,
    LW_READ      TYPE CHAR255,
    LW_DIS       TYPE CHAR1,
    LW_VKORG     TYPE VKORG,
    LW_BEZEI     TYPE TVM2T-BEZEI,
    LW_ZZAUGRU   TYPE AUGRU,
    LW_ZZAUGRU_T TYPE AUGRU,
    LW_BUZEI     TYPE BSEG-BUZEI,
    LW_INQUIRY   TYPE CHAR1,
    LW_ZLSCH     TYPE VBRK-ZLSCH,
    LW_PSTYV     TYPE VBRP-PSTYV.
  " #ZEIV01 • [CS]_DanhDH - Add Line - 16/10/2026
  DATA LW_KZWI1 TYPE VBRP-KZWI1.

  DATA: LT_TEMP   LIKE GT_DETAIL,
        LS_TEMP   LIKE GS_DETAIL,
        LT_DT_TMP LIKE GT_DETAIL,
        LS_DT_TMP LIKE GS_DETAIL.

  FIELD-SYMBOLS: <FS_DATA> TYPE ZEB_ST_DETAIL.

  SELECT SINGLE KNUMV WAERK FKART VTWEG VKORG ZLSCH ZTERM
    INTO ( LW_KNUMV , LW_WAERK , LW_FKART, LW_VTWEG, LW_VKORG, LW_ZLSCH, GS_HEADER-ZTERM )
    FROM VBRK
    WHERE VBELN = GS_HEADER-AWKEY(10).

*  IF LW_ZLSCH EQ 'C'.                                " Tien mat
*    GS_HEADER-PAYID = 1.
*  ELSEIF LW_ZLSCH EQ 'B'.                               " Chuyen khoan
*    GS_HEADER-PAYID = 2.
*  ELSEIF LW_ZLSCH EQ 'F'.
*    GS_HEADER-PAYID = 6.
*  ENDIF.
*&---------------------------------------------------------------------*
  "htpham added on 27.10.2022
  IF LW_ZLSCH IS NOT INITIAL.
    SELECT SINGLE
    PAYID
    FROM ZTB_PMT_MAPPING
    INTO GS_HEADER-PAYID
    WHERE ZLSCH EQ   LW_ZLSCH
    .
  ENDIF.
*&---------------------------------------------------------------------*


  IF GS_HEADER-PAYID IS INITIAL.                            " NghiaNT.Citek 17.10.2017 12:04:40 Mặc định là Chuyen khoan
    GS_HEADER-PAYID = 2.
  ENDIF.
  " #ZEIV01 • [CS]_DanhDH - Add Start - 16/10/2026
  " Billing Type ZFA: PayMethodID = 5
  IF LW_FKART = 'ZFA'.
    GS_HEADER-PAYID = 5.
  ENDIF.
  " #ZEIV01 • [CS]_DanhDH - Add End - 16/10/2026
*  IF SY-UNAME EQ 'CT.ABAP'.
*    LW_FKART = 'ZF4'.
*  ENDIF.
  " START --> 17.01.24: tuan.nguyen4 comment code lai
*  IF LW_FKART EQ 'ZRE1' AND P_BUKRS EQ '5000'.
*    DELETE GT_HEADER WHERE BUKRS = GS_HEADER-BUKRS AND
*                           GJAHR = GS_HEADER-GJAHR AND
*                           BELNR = GS_HEADER-BELNR.
*    EXIT.
*  ENDIF.
  " END  --> 17.01.24: tuan.nguyen4 comment code lai


  SELECT
      POSNR
      MATNR
      ARKTX
      VRKME
      FKIMG
      NETWR
      LGORT
      KURSK
      VGBEL
      AUBEL
      AUPOS
      AUGRU_AUFT
      PSTYV
    " #ZEIV01 • [CS]_DanhDH - Add Line - 16/10/2026
      KZWI1
    INTO (GS_DETAIL-POSNR, GS_DETAIL-MATNR, GS_DETAIL-ARKTX, GS_DETAIL-MEINS,
          GS_DETAIL-MENGE, GS_DETAIL-DMBTR, LW_LGORT, LW_KURSK, LW_OD, LW_SO, LW_SOLINE, LW_ZZAUGRU, LW_PSTYV,
          " #ZEIV01 • [CS]_DanhDH - Add Line - 16/10/2026
          LW_KZWI1)
    FROM VBRP
    WHERE VBELN = GS_HEADER-AWKEY(10) AND
         ( FKIMG NE 0 OR
           NETWR NE 0 ).

    "Ti giá
    GS_DETAIL-KURRF = LW_KURSK.
    IF GS_HEADER-KURRF IS INITIAL AND LW_KURSK IS NOT INITIAL.
      GS_HEADER-KURRF = LW_KURSK.
      CLEAR LW_KURSK.
    ENDIF.
    "get currency
    GS_DETAIL-WAERK = LW_WAERK.
    GS_HEADER-WAERK = LW_WAERK.
    GS_DETAIL-WAERS = GS_HEADER-WAERS.

    IF P_BUKRS EQ '5000'.
      CONCATENATE GS_HEADER-AWKEY(10) GS_DETAIL-POSNR INTO LW_TDNAME.
      CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
        EXPORTING
          I_TDOBJECT  = 'VBBP'
          I_TDNAME    = LW_TDNAME
          I_TDID      = '0001'
          I_TDSPRAS   = 'E'
        IMPORTING
          E_LONG_TEXT = LW_CHAR255.

      IF LW_CHAR255 IS NOT INITIAL.
        GS_DETAIL-INAME = LW_CHAR255.
        CLEAR LW_CHAR255.
      ELSE.
        " START --> 14.12.23: tuan.nguyen4
        " Bo sung lay tu Item Description
        CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
          EXPORTING
            I_TDOBJECT  = 'VBBP'
            I_TDNAME    = LW_TDNAME
            I_TDID      = 'Z012'
            I_TDSPRAS   = 'E'
          IMPORTING
            E_LONG_TEXT = LW_CHAR255.

        IF LW_CHAR255 IS NOT INITIAL.
          GS_DETAIL-INAME = LW_CHAR255.
          CLEAR LW_CHAR255.
        ELSE.
          " END   --> 14.12.23: tuan.nguyen4


          LW_TDNAME = GS_DETAIL-MATNR.
          CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
            EXPORTING
              I_TDOBJECT  = 'MATERIAL'
              I_TDNAME    = LW_TDNAME
              I_TDID      = 'GRUN'
              I_TDSPRAS   = 'E'
            IMPORTING
              E_LONG_TEXT = LW_CHAR255.
          IF LW_CHAR255 IS NOT INITIAL.
            GS_DETAIL-INAME = LW_CHAR255.
            CLEAR LW_CHAR255.
          ELSE.
*            SELECT SINGLE BEZEI
*              INTO LW_BEZEI
*              FROM TVM2T
*              INNER JOIN MVKE ON MVKE~MVGR2 EQ TVM2T~MVGR2
*              WHERE MATNR EQ GS_DETAIL-MATNR AND
*                    VKORG EQ LW_VKORG AND
*                    VTWEG EQ LW_VTWEG.
*
*            IF LW_BEZEI IS NOT INITIAL.
*              CONCATENATE LW_BEZEI ` ` GS_DETAIL-ARKTX INTO GS_DETAIL-INAME.
*            ELSE.
            GS_DETAIL-INAME = GS_DETAIL-ARKTX.
*            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ELSE.
      CONCATENATE GS_HEADER-AWKEY(10) GS_DETAIL-POSNR INTO LW_TDNAME.
      CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
        EXPORTING
          I_TDOBJECT  = 'VBBP'
          I_TDNAME    = LW_TDNAME
          I_TDID      = '0001'
          I_TDSPRAS   = 'E'
        IMPORTING
          E_LONG_TEXT = LW_CHAR255.

      IF LW_CHAR255 IS NOT INITIAL.
        GS_DETAIL-INAME = LW_CHAR255.
        CLEAR LW_CHAR255.
      ELSE.
        " START --> 14.12.23: tuan.nguyen4
        " Bo sung lay tu Item Description
        CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
          EXPORTING
            I_TDOBJECT  = 'VBBP'
            I_TDNAME    = LW_TDNAME
            I_TDID      = 'Z012'
            I_TDSPRAS   = 'E'
          IMPORTING
            E_LONG_TEXT = LW_CHAR255.

        IF LW_CHAR255 IS NOT INITIAL.
          GS_DETAIL-INAME = LW_CHAR255.
          CLEAR LW_CHAR255.
          " END   --> 14.12.23: tuan.nguyen4
        ELSE.
*          SELECT SINGLE bezei
*            INTO lw_bezei
*            FROM tvm2t
*            INNER JOIN mvke ON mvke~mvgr2 EQ tvm2t~mvgr2
*            WHERE matnr EQ gs_detail-matnr AND
*                  vkorg EQ lw_vkorg AND
*                  vtweg EQ lw_vtweg.
*
*          IF lw_bezei IS NOT INITIAL.
*            CONCATENATE lw_bezei ` ` gs_detail-arktx INTO gs_detail-iname.
*          ELSE.
          GS_DETAIL-INAME = GS_DETAIL-ARKTX.
*        ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF P_KG EQ 'X' AND GS_DETAIL-MATNR IS NOT INITIAL.
      CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
        EXPORTING
          I_MATNR              = GS_DETAIL-MATNR
          I_IN_ME              = GS_DETAIL-MEINS
          I_OUT_ME             = 'KG'
          I_MENGE              = GS_DETAIL-MENGE
        IMPORTING
          E_MENGE              = GS_DETAIL-MENGE
        EXCEPTIONS
          ERROR_IN_APPLICATION = 1
          ERROR                = 2
          OTHERS               = 3.
      IF SY-SUBRC = 0.
        GS_DETAIL-MEINS = 'KG'.
      ENDIF.
    ENDIF.

    "dvt
    SELECT SINGLE
      MSEHT
      INTO @GS_DETAIL-UNIT
      FROM T006A
      WHERE MSEHI = @GS_DETAIL-MEINS
        AND SPRAS EQ @SY-LANGU.
*        AND spras EQ 'E'.

    IF LW_PSTYV = 'ZTAX'
      AND GS_HEADER-NOTE IS INITIAL.
      GS_DETAIL-ISDISCOUNT = 1.
    ELSE.
      GS_DETAIL-ISDISCOUNT = 0.
    ENDIF.

    "tax
    IF LW_KNUMV IS NOT INITIAL.
      SELECT *
        INTO TABLE LT_TAX
        FROM PRCD_ELEMENTS
        WHERE KNUMV = LW_KNUMV
          AND KPOSN = GS_DETAIL-POSNR.
      LOOP AT LT_TAX INTO LS_TAX WHERE KSCHL = 'MWST'."thue
        CASE LS_TAX-MWSK1.
          WHEN 'A0' OR 'A3' OR 'B0' OR 'B3' OR 'C0' OR 'C3' OR 'D0' OR 'D3' OR 'O0'. " 0%
            GS_DETAIL-TAX = 1.
          WHEN 'A1' OR 'A4' OR 'B1' OR 'B4' OR 'C1' OR 'C4' OR 'D1' OR 'D4' OR 'O1'. " 5%
            GS_DETAIL-TAX = 2.
          WHEN 'A2' OR 'A5' OR 'B2' OR 'B6' OR 'C2' OR 'C5' OR 'D2' OR 'D5' OR 'O2'. " 10%
            GS_DETAIL-TAX = 3.
          WHEN 'O4'.
            GS_DETAIL-TAX = 9.
          WHEN OTHERS.
            GS_DETAIL-TAX = 4.
        ENDCASE.
        GS_DETAIL-TAMOUNT = LS_TAX-KWERT.
      ENDLOOP.
    ENDIF.
    IF GS_DETAIL-TAX IS INITIAL.
      GS_DETAIL-TAX = '4'.
    ENDIF.


    IF GS_DETAIL-MENGE IS NOT INITIAL AND GS_DETAIL-MENGE <> 0.
      GS_DETAIL-PRICE = GS_DETAIL-DMBTR / GS_DETAIL-MENGE.
    ELSE.
      GS_DETAIL-PRICE = 0.
    ENDIF.

    " #ZEIV01 • [CS]_DanhDH - Add Start - 16/10/2026
    " Billing Type ZFA: Đơn giá = Subtotal 1 (VBRP-KZWI1) của line item / Số lượng
    IF LW_FKART = 'ZFA'.
      IF GS_DETAIL-MENGE IS NOT INITIAL.
        GS_DETAIL-PRICE = LW_KZWI1 / GS_DETAIL-MENGE.
      ELSE.
        GS_DETAIL-PRICE = 0.
      ENDIF.
      " Net của dòng (DMBTR) = Subtotal 1 -> Net ở header và số tiền lưu/gửi BKAV cũng theo Subtotal 1
      GS_DETAIL-DMBTR = LW_KZWI1.
    ENDIF.
    " #ZEIV01 • [CS]_DanhDH - Add End - 16/10/2026

    IF LW_PSTYV = 'ZGN3'. " -> phat hanh hoa don binh thuong va IsDiscount = true
*      GS_HEADER-NOTE = '122-'.
      "KhoaLD modify begin 10.10.2026 10:18:59
      "Xét Header Text của Billing "Số chứng gốc thay thế" - Text ID - XXXX
      "Nếu rỗng thì truyền CMD Type 100 với Is Discount <> null
      "Nếu có data thì truyền CMD Type 123 với Is Discount <> null
      IF GS_HEADER-NOTE = '123+'.
        GS_HEADER-CHECK_REPLACE = 'X'.
      ELSE.
        GS_HEADER-NOTE  = ''.
      ENDIF.
      "KhoaLD modify end 10.10.2026 10:18:59
      GS_DETAIL-ISDISCOUNT = 1.
*      CLEAR  GS_DETAIL-MEINS.
*      CLEAR  GS_DETAIL-MENGE.
*      CLEAR  GS_DETAIL-UNIT.
    ENDIF.

    GS_DETAIL-GROSS_AMOUNT    = GS_DETAIL-DMBTR + GS_DETAIL-TAMOUNT.
    " #ZEIV01 • [CS]_DanhDH - Add Start - 16/10/2026
    " Billing Type ZFA: Gross = Subtotal 1 (VBRP-KZWI1) + Tax theo từng billing line
    IF LW_FKART = 'ZFA'.
      GS_DETAIL-GROSS_AMOUNT = LW_KZWI1 + GS_DETAIL-TAMOUNT.
    ENDIF.
    " #ZEIV01 • [CS]_DanhDH - Add End - 16/10/2026

    IF LW_WAERK NE 'VND'.
      GS_DETAIL-GROSS_AMOUNT_LC = GS_DETAIL-GROSS_AMOUNT * GS_DETAIL-KURRF * 10.
    ELSE.
      GS_DETAIL-GROSS_AMOUNT_LC = GS_DETAIL-GROSS_AMOUNT.
    ENDIF.
    GS_DETAIL-NET_AMOUNT      = GS_DETAIL-MENGE * GS_DETAIL-PRICE.


    GS_HEADER-GROSS_AMOUNT_LC = GS_HEADER-GROSS_AMOUNT_LC + GS_DETAIL-GROSS_AMOUNT_LC.
    GS_HEADER-GROSS_AMOUNT    = GS_HEADER-GROSS_AMOUNT    + GS_DETAIL-GROSS_AMOUNT.
    GS_HEADER-AMOUNT          = GS_HEADER-AMOUNT          + GS_DETAIL-DMBTR.
    GS_HEADER-TAMOUNT         = GS_HEADER-TAMOUNT         + GS_DETAIL-TAMOUNT.

    GS_DETAIL-BUKRS = GS_HEADER-BUKRS.
    GS_DETAIL-GJAHR = GS_HEADER-GJAHR.
    GS_DETAIL-BELNR = GS_HEADER-BELNR.

    " Gom dong neu cung ten, unit, don gia
    READ TABLE LT_DT_TMP ASSIGNING <FS_DATA> WITH KEY INAME = GS_DETAIL-INAME
                                                      MEINS = GS_DETAIL-MEINS
                                                      PRICE = GS_DETAIL-PRICE
                                                      TAX   = GS_DETAIL-TAX.
    IF SY-SUBRC = 0.
      <FS_DATA>-DMBTR             = <FS_DATA>-DMBTR   + GS_DETAIL-DMBTR.
      <FS_DATA>-MENGE             = <FS_DATA>-MENGE   + GS_DETAIL-MENGE.
      <FS_DATA>-TAMOUNT           = <FS_DATA>-TAMOUNT       + GS_DETAIL-TAMOUNT.
      <FS_DATA>-GROSS_AMOUNT      = <FS_DATA>-GROSS_AMOUNT  + GS_DETAIL-GROSS_AMOUNT.
      <FS_DATA>-NET_AMOUNT        = <FS_DATA>-NET_AMOUNT    + GS_DETAIL-NET_AMOUNT.
      <FS_DATA>-GROSS_AMOUNT_LC   = <FS_DATA>-GROSS_AMOUNT_LC    + GS_DETAIL-GROSS_AMOUNT_LC.
    ELSE.
      LW_STT = LW_STT + 1.
      GS_DETAIL-BUZEI = LW_STT.
      APPEND GS_DETAIL TO LT_DT_TMP.
    ENDIF.

    CLEAR GS_DETAIL.
  ENDSELECT.
  "_htpham added on 01.05.2023 / Quoc te Lao Dong
  IF P_BUKRS EQ '5000'.
    SORT LT_DT_TMP BY ISDISCOUNT INAME .
  ELSE.
    SORT LT_DT_TMP BY POSNR.
  ENDIF.

*  Xét header text, nếu text type Z031 Ghi chú hoá đơn có giá trị
*  --> Lấy text lên và thể hiện thành 1 dòng ghi chú trên hóa đơn, với TextTypeID = 4 (có thể hiện line ghi chú này trên ZEIV01 chỗ item luôn nhé ạ)
  DATA: LV_TDNAME       TYPE TDOBNAME,
        LV_LINE_GHI_CHU TYPE STRING.

  CLEAR: LV_LINE_GHI_CHU, LV_TDNAME.

  LV_TDNAME = GS_HEADER-AWKEY(10).
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT = 'VBBK'
      I_TDNAME   = LV_TDNAME
      I_TDID     = 'Z031'
    IMPORTING
      E_TEXT_STR = LV_LINE_GHI_CHU.

  IF LV_LINE_GHI_CHU IS NOT INITIAL.

    LW_STT = LW_STT + 1.
    GS_DETAIL-BUZEI = LW_STT.
    GS_DETAIL-BUKRS = GS_HEADER-BUKRS.
    GS_DETAIL-BELNR = GS_HEADER-BELNR.
    GS_DETAIL-GJAHR = GS_HEADER-GJAHR.

    GS_DETAIL-POSNR = 9999.
    GS_DETAIL-INAME = LV_LINE_GHI_CHU.
    GS_DETAIL-ITEMTYPEID = '4'.
    APPEND GS_DETAIL TO LT_DT_TMP.
    CLEAR GS_DETAIL.
  ENDIF.

  "_htpham deleted on 01.05.2023 / Quoc te Lao Dong
*  IF P_BUKRS EQ 5000.
*    SORT LT_DT_TMP BY ISDISCOUNT INAME .
*  ELSE.
*    SORT LT_DT_TMP BY POSNR.
*  ENDIF.

  LW_STT = 0.
  LOOP AT LT_DT_TMP ASSIGNING <FS_DATA>.
    LW_STT = LW_STT + 1.
    <FS_DATA>-BUZEI = LW_STT.
  ENDLOOP.
*  LT_TEMP[] = LT_DT_TMP[].
*  CLEAR: LT_DT_TMP[].
*  SORT LT_TEMP[] BY INAME MEINS PRICE DESCENDING MENGE DESCENDING.
*
*  CLEAR LW_STT.
*  LOOP AT LT_TEMP INTO LS_TEMP.
*    IF LS_TEMP-INAME NE LS_DT_TMP-INAME OR
*       LS_TEMP-MEINS NE LS_DT_TMP-MEINS OR
*       LS_TEMP-PRICE NE LS_DT_TMP-PRICE.
*
*      LS_DT_TMP-INAME = LS_TEMP-INAME.
*      LS_DT_TMP-MEINS = LS_TEMP-MEINS.
*      LS_DT_TMP-PRICE = LS_TEMP-PRICE.
*
*
*      LS_TEMP-BUZEI = LW_STT.
*      APPEND LS_TEMP TO LT_DT_TMP.
*    ELSE.
*      READ TABLE LT_DT_TMP ASSIGNING <FS_DETAIL> WITH KEY INAME = LS_TEMP-INAME
*                                                      MEINS = LS_TEMP-MEINS
*                                                      PRICE = LS_TEMP-PRICE.
*      IF SY-SUBRC EQ 0.
*        <FS_DETAIL>-MENGE      = <FS_DETAIL>-MENGE      + LS_TEMP-MENGE.
*        <FS_DETAIL>-DMBTR      = <FS_DETAIL>-DMBTR      + LS_TEMP-DMBTR.
*        <FS_DETAIL>-TAMOUNT    = <FS_DETAIL>-TAMOUNT    + LS_TEMP-TAMOUNT.
**        <FS_DETAIL>-CHIETKHAU  = <FS_DETAIL>-CHIETKHAU  + LS_TEMP-CHIETKHAU.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.

*  " remark for billing
*  LW_TDNAME = GS_HEADER-AWKEY(10).
*  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
*    EXPORTING
*      I_TDOBJECT  = 'VBBK'
*      I_TDNAME    = LW_TDNAME
*      I_TDID      = 'Z005'
*    IMPORTING
*      E_LONG_TEXT = LW_CHAR255.
*  IF LW_CHAR255 IS NOT INITIAL.
*    CLEAR GS_DETAIL.
*    GS_DETAIL-BUKRS = GS_HEADER-BUKRS.
*    GS_DETAIL-GJAHR = GS_HEADER-GJAHR.
*    GS_DETAIL-BELNR = GS_HEADER-BELNR.
*    GS_DETAIL-INAME = LW_CHAR255.
*    GS_DETAIL-BUZEI = LW_BUZEI.
**    LW_BUZEI        = LW_BUZEI + 1.
*    APPEND GS_DETAIL TO LT_DT_TMP.
*  ENDIF.

  APPEND LINES OF LT_DT_TMP TO GT_DETAIL_ALL.
  CLEAR: LW_TDNAME, GS_DETAIL,LT_TAX.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DETAIL_FI
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DETAIL_FI.
  DATA: LW_TDNAME TYPE TDOBNAME,
        LW_MWSKZ  TYPE MWSKZ.
  DATA: LT_TEMP   LIKE GT_DETAIL,
        LS_TEMP   LIKE GS_DETAIL,
        LT_DT_TMP LIKE GT_DETAIL,
        LS_DT_TMP LIKE GS_DETAIL.
  DATA: LS_TAX    TYPE BSET.
  DATA: LT_FTAXP    TYPE TABLE OF FTAXP WITH HEADER LINE.

  SELECT
    BUZEI MENGE MEINS MATNR WRBTR DMBTR H_WAERS SGTXT MWSKZ TXGRP
  INTO ( GS_DETAIL-BUZEI, GS_DETAIL-MENGE, GS_DETAIL-MEINS, GS_DETAIL-MATNR, GS_DETAIL-DMBTR,  GS_DETAIL-DMBTR, GS_DETAIL-WAERK, GS_DETAIL-SGTXT,
         LW_MWSKZ, GS_DETAIL-TXGRP )
  FROM BSEG
  WHERE BUKRS = GS_HEADER-BUKRS AND
        GJAHR = GS_HEADER-GJAHR AND
        BELNR = GS_HEADER-BELNR AND
        KOART = 'S' AND
        MWART NE 'A'.
*     (  HKONT LIKE '0007%' OR HKONT LIKE '0005%' ).
*      ( KOART <> 'D' AND KOART <> 'K') AND MWSKZ = '' AND MWART = '' AND ( BSCHL EQ '40' OR BSCHL EQ '50' ).

    GS_DETAIL-BUKRS = GS_HEADER-BUKRS.
    GS_DETAIL-GJAHR = GS_HEADER-GJAHR.
    GS_DETAIL-BELNR = GS_HEADER-BELNR.

    IF P_BUKRS EQ '1000' OR P_BUKRS EQ '2000'.
      CONCATENATE GS_DETAIL-BUKRS GS_DETAIL-BELNR GS_DETAIL-GJAHR GS_DETAIL-BUZEI INTO LW_TDNAME.
      "Get Long Item Text
      CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
        EXPORTING
          I_TDOBJECT  = 'DOC_ITEM'
          I_TDNAME    = LW_TDNAME
          I_TDID      = '0002'
          I_TDSPRAS   = 'E'
        IMPORTING
          E_LONG_TEXT = GS_DETAIL-INAME.

      IF GS_DETAIL-INAME IS INITIAL.
        "Get Long Item Text
        CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
          EXPORTING
            I_TDOBJECT  = 'DOC_ITEM'
            I_TDNAME    = LW_TDNAME
            I_TDID      = '0001'
            I_TDSPRAS   = 'E'
          IMPORTING
            E_LONG_TEXT = GS_DETAIL-INAME.
      ENDIF.

      IF GS_DETAIL-INAME IS INITIAL.
        GS_DETAIL-INAME = GS_DETAIL-SGTXT.
      ENDIF.
      IF GS_DETAIL-INAME IS INITIAL.
        SELECT SINGLE MAKTX
        INTO GS_DETAIL-INAME
        FROM MAKT
        WHERE MATNR = GS_DETAIL-MATNR AND
              SPRAS = 'EN'.
      ENDIF.
    ELSE.
      GS_DETAIL-INAME = GS_DETAIL-SGTXT.
    ENDIF.

    IF P_KG EQ 'X' AND GS_DETAIL-MATNR IS NOT INITIAL.
      CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
        EXPORTING
          I_MATNR              = GS_DETAIL-MATNR
          I_IN_ME              = GS_DETAIL-MEINS
          I_OUT_ME             = 'KG'
          I_MENGE              = GS_DETAIL-MENGE
        IMPORTING
          E_MENGE              = GS_DETAIL-MENGE
        EXCEPTIONS
          ERROR_IN_APPLICATION = 1
          ERROR                = 2
          OTHERS               = 3.
      IF SY-SUBRC = 0.
        GS_DETAIL-MEINS = 'KG'.
      ENDIF.
    ENDIF.


    "dvt
    SELECT SINGLE
      MSEHT
      INTO GS_DETAIL-UNIT
      FROM T006A
      WHERE MSEHI = GS_DETAIL-MEINS
        AND SPRAS EQ 'E'.

    IF GS_DETAIL-MENGE IS NOT INITIAL AND GS_DETAIL-MENGE <> 0.
      GS_DETAIL-PRICE = GS_DETAIL-DMBTR / GS_DETAIL-MENGE.
    ELSE.
      GS_DETAIL-PRICE = 0.
    ENDIF.

    " NghiaNT.Citek 31.10.2017 09:54:16 Tính tiền thuế
    IF GS_HEADER-BUKRS = '2000'.
      CALL FUNCTION 'GET_TAX_PERCENTAGE'
        EXPORTING
          ALAND   = 'VN'
          DATAB   = GS_HEADER-BUDAT
          MWSKZ   = LW_MWSKZ
          TXJCD   = ''
        TABLES
          T_FTAXP = LT_FTAXP.
      IF SY-SUBRC = 0.
        READ TABLE LT_FTAXP INDEX 1.
        IF SY-SUBRC = 0.
          GS_DETAIL-TAMOUNT = ( LT_FTAXP-KBETR / 1000 ) * GS_DETAIL-DMBTR.
        ENDIF.
      ENDIF.
    ENDIF.

    CASE LW_MWSKZ.
      WHEN 'A0' OR 'A3' OR 'B0' OR 'B3' OR 'C0' OR 'C3' OR 'D0' OR 'D3' OR 'O0'. " 0%
        GS_DETAIL-TAX = 1.
      WHEN 'A1' OR 'A4' OR 'B1' OR 'B4' OR 'C1' OR 'C4' OR 'D1' OR 'D4' OR 'O1'. " 5%
        GS_DETAIL-TAX = 2.
      WHEN 'A2' OR 'A5' OR 'B2' OR 'B6' OR 'C2' OR 'C5' OR 'D2' OR 'D5' OR 'O2'. " 10%
        GS_DETAIL-TAX = 3.
      WHEN 'O4'.
        GS_DETAIL-TAX = 9.
      WHEN OTHERS.
        GS_DETAIL-TAX = 4.
    ENDCASE.

    GS_DETAIL-GROSS_AMOUNT    = GS_DETAIL-DMBTR .
    GS_DETAIL-GROSS_AMOUNT_LC = GS_DETAIL-DMBTR  .
    GS_DETAIL-WAERS           = GS_HEADER-WAERS.
    GS_DETAIL-NET_AMOUNT      = GS_DETAIL-MENGE * GS_DETAIL-PRICE.

    GS_HEADER-GROSS_AMOUNT_LC = GS_HEADER-GROSS_AMOUNT_LC + GS_DETAIL-GROSS_AMOUNT_LC.
    GS_HEADER-GROSS_AMOUNT    = GS_HEADER-GROSS_AMOUNT    + GS_DETAIL-GROSS_AMOUNT.
    GS_HEADER-AMOUNT          = GS_HEADER-AMOUNT          + GS_DETAIL-DMBTR.
    GS_HEADER-TAMOUNT         = GS_HEADER-TAMOUNT         + GS_DETAIL-TAMOUNT.
    GS_HEADER-WAERK           = GS_DETAIL-WAERK.
    APPEND GS_DETAIL TO LT_DT_TMP.

    CLEAR GS_DETAIL.
  ENDSELECT.

  " START --> 29.09.23: tuan.nguyen4
  " Chi rieng doi voi Doc.type = ZG
  IF GS_HEADER-BLART EQ 'ZG'.
    " Bo sung logic TH ko có matnr thi vao profit segment cua G/L account = 632* de field Product
    TYPES: BEGIN OF LTY_PAOBJNR,
             BELNR   TYPE BSEG-BELNR,
             BUKRS   TYPE BSEG-BUKRS,
             GJAHR   TYPE BSEG-GJAHR,
             PAOBJNR TYPE BSEG-PAOBJNR,
             MATNR   TYPE MATNR,
             MAKTX   TYPE MAKTX,
           END OF LTY_PAOBJNR.
    DATA:
          LS_PAOBJNR TYPE LTY_PAOBJNR.

    SELECT
      BELNR
      BUKRS
      GJAHR
      PAOBJNR
    INTO ( LS_PAOBJNR-BELNR, LS_PAOBJNR-BUKRS, LS_PAOBJNR-GJAHR, LS_PAOBJNR-PAOBJNR )
    FROM BSEG
    WHERE BELNR = GS_HEADER-BELNR
      AND BUKRS = GS_HEADER-BUKRS
      AND GJAHR = GS_HEADER-GJAHR
      AND HKONT LIKE '632%'.
    ENDSELECT.

    IF LS_PAOBJNR IS NOT INITIAL.
      DATA: LT_SEGMENT TYPE KEAK_YT_IPV_FIELD.
      CALL FUNCTION 'RKE_GET_CHARS_FOR_PAOBJNR'
        EXPORTING
          I_BUKRS     = GS_HEADER-BUKRS
          I_PAOBJNR   = LS_PAOBJNR-PAOBJNR
          I_MODE      = 'C'
        TABLES
          T_CE4_CHARS = LT_SEGMENT.
      IF SY-SUBRC <> 0.
*    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.

      READ TABLE LT_SEGMENT INTO DATA(LS_SEGMENT) WITH KEY FIELDNAME = 'ARTNR'.
      IF SY-SUBRC EQ 0.
        LS_PAOBJNR-MATNR = LS_SEGMENT-FIELDVAL.
      ENDIF.

      SELECT
        MAKTX
      INTO ( LS_PAOBJNR-MAKTX )
      FROM MAKT WHERE MATNR EQ LS_PAOBJNR-MATNR
                  AND SPRAS EQ SY-LANGU.
      ENDSELECT.

      DATA(LW_INDEX) = 0.
      LOOP AT LT_DT_TMP ASSIGNING FIELD-SYMBOL(<LFS_DT_TMP>).
        LW_INDEX = LW_INDEX + 1.
        IF <LFS_DT_TMP>-BELNR EQ LS_PAOBJNR-BELNR AND
           <LFS_DT_TMP>-BUKRS EQ LS_PAOBJNR-BUKRS AND
           <LFS_DT_TMP>-GJAHR EQ LS_PAOBJNR-GJAHR AND
           <LFS_DT_TMP>-MATNR IS INITIAL.

          <LFS_DT_TMP>-MATNR = LS_PAOBJNR-MATNR.
          <LFS_DT_TMP>-INAME = LS_PAOBJNR-MAKTX.
        ENDIF.

        "Dong cuoi cung la thue nen ko lay material
        IF LW_INDEX EQ LINES( LT_DT_TMP ).
          CLEAR: <LFS_DT_TMP>-MATNR, <LFS_DT_TMP>-INAME.
        ENDIF.
      ENDLOOP.

    ENDIF.
  ENDIF.
  " END  --> 29.09.23: tuan.nguyen4

  " Tinh thue dong dau tien
  "tax
  IF GS_HEADER-BUKRS NE '2000'.
    READ TABLE LT_DT_TMP ASSIGNING <FS_DETAIL> INDEX 1.
    IF SY-SUBRC = 0.
      IF <FS_DETAIL>-TXGRP IS NOT INITIAL.
        SELECT SINGLE *
          INTO LS_TAX
          FROM BSET
          WHERE BELNR EQ <FS_DETAIL>-BELNR
            AND BUKRS EQ <FS_DETAIL>-BUKRS
            AND GJAHR EQ <FS_DETAIL>-GJAHR
            AND TXGRP =  <FS_DETAIL>-TXGRP.
        IF SY-SUBRC EQ 0 .
          <FS_DETAIL>-TAMOUNT = LS_TAX-FWSTE.

          <FS_DETAIL>-GROSS_AMOUNT    = <FS_DETAIL>-GROSS_AMOUNT      + LS_TAX-FWSTE.
          <FS_DETAIL>-GROSS_AMOUNT_LC = <FS_DETAIL>-GROSS_AMOUNT_LC   + LS_TAX-HWSTE.

          GS_HEADER-GROSS_AMOUNT    = GS_HEADER-GROSS_AMOUNT    + LS_TAX-FWSTE.
          GS_HEADER-GROSS_AMOUNT_LC = GS_HEADER-GROSS_AMOUNT_LC + LS_TAX-HWSTE.

          GS_HEADER-TAMOUNT         = LS_TAX-FWSTE.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
  APPEND LINES OF LT_DT_TMP TO GT_DETAIL_ALL.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DETAIL_MM
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DETAIL_MM .
  DATA: LW_MM_BELNR TYPE RE_BELNR,
        LW_MM_GJAHR TYPE GJAHR,
        LW_MM_MWSKZ TYPE MWSKZ_MRM1,
        LW_KBETR    TYPE KBETR,
        LS_TAX      TYPE BSET,
        LW_INT      TYPE INT1,
        LW_MWSKZ    TYPE MWSKZ.
  DATA: LT_TEMP   LIKE GT_DETAIL,
        LS_TEMP   LIKE GS_DETAIL,
        LT_DT_TMP LIKE GT_DETAIL,
        LS_DT_TMP LIKE GS_DETAIL,
        LW_SGTXT  TYPE RSEG-SGTXT,
        LW_TDNAME TYPE TDOBNAME,
        LW_LTEXT  TYPE CHAR255.

  LW_MM_BELNR = GS_HEADER-AWKEY(10).
  LW_MM_GJAHR = GS_HEADER-GJAHR.

  SELECT SINGLE WAERS KURSF RMWWR WMWST1
  INTO ( GS_HEADER-WAERK, GS_HEADER-KURRF, GS_HEADER-GROSS_AMOUNT, GS_HEADER-TAMOUNT )
  FROM RBKP
  WHERE BELNR = LW_MM_BELNR AND
        GJAHR = LW_MM_GJAHR AND
        STBLG = ''.
  IF SY-SUBRC NE 0.
    DELETE GT_HEADER WHERE BUKRS = GS_HEADER-BUKRS AND
                           GJAHR = GS_HEADER-GJAHR AND
                           BELNR = GS_HEADER-BELNR.
    EXIT.
  ENDIF.
  " STBLG
*----- Lấy quantity trực tiếp ở MIRO ko link qua PO -------------------------------
  SELECT
     RSEG~BUZEI
     EKPO~TXZ01       "PO Text : tieu chi 9
     RSEG~SGTXT
     RSEG~BSTME       "UOM     : tieu chi 10
     RSEG~MENGE       "Quantity: tieu chi 11
     RSEG~WRBTR       "Amount  : tieu chi 11
     RSEG~MWSKZ
     RSEG~MATNR
  INTO (GS_DETAIL-BUZEI, GS_DETAIL-INAME, LW_SGTXT, GS_DETAIL-MEINS, GS_DETAIL-MENGE,
        GS_DETAIL-DMBTR, LW_MWSKZ, GS_DETAIL-MATNR)
  FROM RSEG INNER JOIN EKPO ON RSEG~EBELN = EKPO~EBELN AND RSEG~EBELP = EKPO~EBELP
  WHERE RSEG~BELNR = LW_MM_BELNR
    AND RSEG~GJAHR = LW_MM_GJAHR.
*---------------------- End -------------------------------------------------------------------------------------------

    GS_DETAIL-BUKRS = GS_HEADER-BUKRS.
    GS_DETAIL-GJAHR = GS_HEADER-GJAHR.
    GS_DETAIL-BELNR = GS_HEADER-BELNR.

    IF LW_SGTXT IS NOT INITIAL.
      GS_DETAIL-INAME = LW_SGTXT.
    ENDIF.


    IF P_KG EQ 'X' AND GS_DETAIL-MATNR IS NOT INITIAL.
      CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
        EXPORTING
          I_MATNR              = GS_DETAIL-MATNR
          I_IN_ME              = GS_DETAIL-MEINS
          I_OUT_ME             = 'KG'
          I_MENGE              = GS_DETAIL-MENGE
        IMPORTING
          E_MENGE              = GS_DETAIL-MENGE
        EXCEPTIONS
          ERROR_IN_APPLICATION = 1
          ERROR                = 2
          OTHERS               = 3.
      IF SY-SUBRC = 0.
        GS_DETAIL-MEINS = 'KG'.
      ENDIF.
    ENDIF.


    " 21.04.2017 16:34:20 NghiaNT.Citek Lấy lên đơn vị tính
    "dvt
    SELECT SINGLE
      MSEHT
      INTO GS_DETAIL-UNIT
      FROM T006A
      WHERE MSEHI = GS_DETAIL-MEINS
        AND SPRAS EQ 'E'.

    GS_DETAIL-WAERK = GS_HEADER-WAERK.
    GS_DETAIL-WAERS = GS_HEADER-WAERS.

    IF GS_DETAIL-MENGE IS NOT INITIAL AND GS_DETAIL-MENGE <> 0.
      GS_DETAIL-PRICE = GS_DETAIL-DMBTR / GS_DETAIL-MENGE.
    ELSE.
      GS_DETAIL-PRICE = 0.
    ENDIF.

    "GT_HEADER-ZZTOTALNOTAX = GT_HEADER-ZZTOTALNOTAX + GT_DETAIL_TIENHANG_FINAL-ZZAMOUNT.

    CASE LW_MWSKZ.
      WHEN 'A0' OR 'A3' OR 'B0' OR 'B3' OR 'C0' OR 'C3' OR 'D0' OR 'D3' OR 'O0'. " 0%
        GS_DETAIL-TAX = 1.
      WHEN 'A1' OR 'A4' OR 'B1' OR 'B4' OR 'C1' OR 'C4' OR 'D1' OR 'D4' OR 'O1'. " 5%
        GS_DETAIL-TAX = 2.
      WHEN 'A2' OR 'A5' OR 'B2' OR 'B6' OR 'C2' OR 'C5' OR 'D2' OR 'D5' OR 'O2'. " 10%
        GS_DETAIL-TAX = 3.
      WHEN 'O4'.
        GS_DETAIL-TAX = 9.
      WHEN OTHERS.
        GS_DETAIL-TAX = 4.
    ENDCASE.


    GS_DETAIL-GROSS_AMOUNT    = GS_DETAIL-DMBTR .
    GS_DETAIL-GROSS_AMOUNT_LC = GS_DETAIL-DMBTR * GS_HEADER-KURRF * 10.
    GS_DETAIL-NET_AMOUNT      = GS_DETAIL-MENGE * GS_DETAIL-PRICE.

    GS_HEADER-AMOUNT          = GS_HEADER-AMOUNT       + GS_DETAIL-DMBTR .

    GS_HEADER-GROSS_AMOUNT_LC = GS_HEADER-GROSS_AMOUNT_LC + GS_DETAIL-GROSS_AMOUNT_LC .
    APPEND GS_DETAIL TO LT_DT_TMP.

    CLEAR: GS_DETAIL, LW_SGTXT.
  ENDSELECT.

  READ TABLE LT_DT_TMP ASSIGNING <FS_DETAIL> INDEX 1.
  IF SY-SUBRC = 0.
    " day tong thue vao line dau tien
    <FS_DETAIL>-TAMOUNT = GS_HEADER-TAMOUNT.

    " tinh toan lai tong gia tri line dau tien
    <FS_DETAIL>-GROSS_AMOUNT    = <FS_DETAIL>-GROSS_AMOUNT + <FS_DETAIL>-TAMOUNT.

    <FS_DETAIL>-GROSS_AMOUNT_LC = <FS_DETAIL>-GROSS_AMOUNT  * GS_HEADER-KURRF * 10.

    GS_HEADER-GROSS_AMOUNT_LC   = GS_HEADER-GROSS_AMOUNT    * GS_HEADER-KURRF * 10.
  ENDIF.

  " Longtext
  CONCATENATE LW_MM_BELNR LW_MM_GJAHR INTO LW_TDNAME.
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'RBKP'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '0001'
    IMPORTING
      E_LONG_TEXT = LW_LTEXT.
  IF LW_LTEXT IS NOT INITIAL.
    CLEAR GS_DETAIL.
    GS_DETAIL-BUKRS = GS_HEADER-BUKRS.
    GS_DETAIL-GJAHR = GS_HEADER-GJAHR.
    GS_DETAIL-BELNR = GS_HEADER-BELNR.
    GS_DETAIL-BUZEI = 999.
    GS_DETAIL-INAME = LW_LTEXT.
    GS_DETAIL-ITEMTYPEID = '4'.
    CASE LW_MWSKZ.
      WHEN 'A0' OR 'A3' OR 'B0' OR 'B3' OR 'C0' OR 'C3' OR 'D0' OR 'D3' OR 'O0'. " 0%
        GS_DETAIL-TAX = 1.
      WHEN 'A1' OR 'A4' OR 'B1' OR 'B4' OR 'C1' OR 'C4' OR 'D1' OR 'D4' OR 'O1'. " 5%
        GS_DETAIL-TAX = 2.
      WHEN 'A2' OR 'A5' OR 'B2' OR 'B6' OR 'C2' OR 'C5' OR 'D2' OR 'D5' OR 'O2'. " 10%
        GS_DETAIL-TAX = 3.
      WHEN 'O4'.
        GS_DETAIL-TAX = 9.
      WHEN OTHERS.
        GS_DETAIL-TAX = 4.
    ENDCASE.
    APPEND GS_DETAIL TO LT_DT_TMP.
  ENDIF.

  APPEND LINES OF LT_DT_TMP TO GT_DETAIL_ALL.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SEND_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SEND_DATA .
  DATA:
    LW_PRINT_OK TYPE CHAR2,
    LW_VSTEL    TYPE VSTEL,
    LT_MESSAGE  TYPE TABLE OF ZEIV_ST_MESSAGE,
    LS_MESSAGE  TYPE ZEIV_ST_MESSAGE,
    LT_FCAT     TYPE LVC_T_FCAT,
    LS_FCAT     TYPE LVC_S_FCAT.

  " Call webservice
  DATA : REQUTEXT    LIKE  SY-LISEL,
         ECHOTEXT    LIKE  SY-LISEL,
         RESPTEXT    LIKE  SY-LISEL,
         LW_COMPUTER TYPE CHAR255,
         LW_TDOBNAME TYPE TDOBNAME,
         LW_TYPE     TYPE CHAR2.
  DATA: LT_HD TYPE TABLE OF ZTB_EB_HEADER,
        LS_HD TYPE ZTB_EB_HEADER,
        LT_DT TYPE TABLE OF ZTB_EB_DETAIL,
        LS_DT TYPE ZTB_EB_DETAIL.

  CASE 'X'.
    WHEN R_SD.
      LW_TYPE = 'SD'.
    WHEN R_FI.
      LW_TYPE = 'FI'.
    WHEN R_MM.
      LW_TYPE = 'MM'.
*    WHEN R_CS.
*      LW_TYPE = 'CS'.
    WHEN OTHERS.
  ENDCASE.

*  IF R_CS EQ ''.
  PERFORM CHECK_DATA_NONCS.
  LOOP AT GT_HEADER INTO GS_HEADER WHERE CHECK = 'X'.
*
    " Luu thong tin
    MOVE-CORRESPONDING GS_HEADER TO LS_HD.

    " Insert xuong database
    IF P_NEW EQ 'X'.
      LS_HD-PHASE = '1'.
    ELSE.
      LS_HD-PHASE = '2'.
    ENDIF.
    LS_HD-RTYID = '1'.
    "28.07.2023: đổi lấy từ ngày hiện tại -> Billing date đổi với option Billing
    LS_HD-IDATE = COND #( WHEN R_SD IS NOT INITIAL THEN GS_HEADER-FKDAT ELSE SY-DATUM ).
    LS_HD-ERNAM = SY-UNAME.
    LS_HD-ERDAT = SY-DATUM.
    LS_HD-INVOICETYPEID = '1'.
    LS_HD-PAYID = GS_HEADER-PAYID.

    "sangvt add begin 04.02.2025 14:08:18
    LS_HD-THANH_TOAN = GS_HEADER-ZTERM_TXT.
    "sangvt add end 04.02.2025 14:08:18

    LS_HD-BILLD = GS_HEADER-AWKEY.
    IF GS_HEADER-KUNNR IS INITIAL.
      LS_HD-KUNNR = GS_HEADER-LIFNR.
    ENDIF.
    CONCATENATE LS_HD-BUKRS '@' LS_HD-GJAHR '@' LS_HD-BELNR INTO LS_HD-PISID.
    IF LS_HD-WAERK EQ 'VND'.
      LS_HD-KURRF = 1.
    ENDIF.
    MODIFY ZTB_EB_HEADER FROM LS_HD.

    DELETE FROM ZTB_EB_DETAIL WHERE BUKRS = GS_HEADER-BUKRS AND
                                    GJAHR = GS_HEADER-GJAHR AND
                                    BELNR = GS_HEADER-BELNR.

    LOOP AT GT_DETAIL_ALL INTO GS_DETAIL_ALL WHERE BUKRS = GS_HEADER-BUKRS AND
                                                   GJAHR = GS_HEADER-GJAHR AND
                                                   BELNR = GS_HEADER-BELNR.
      MOVE-CORRESPONDING GS_DETAIL_ALL TO LS_DT.
*      IF GS_DETAIL_ALL-BUZEI >= '100'.
*        LS_DT-ITEMTYPEID = '4'.
*      ELSE.
      IF LS_DT-ITEMTYPEID IS INITIAL.
        LS_DT-ITEMTYPEID = '0'.
      ENDIF.
*      ENDIF.
      MODIFY ZTB_EB_DETAIL FROM LS_DT.
    ENDLOOP.

    LW_COMPUTER = 'ADMIN'.
    IF P_NEW EQ 'X'.
      CONCATENATE 'VAT' '@' 'NEW' '@' GS_HEADER-BUKRS '@' GS_HEADER-GJAHR '@' GS_HEADER-BELNR '@' SY-UNAME '@' INTO REQUTEXT.
    ELSE.
      CONCATENATE 'VAT' '@' 'UDP' '@' GS_HEADER-BUKRS '@' GS_HEADER-GJAHR '@' GS_HEADER-BELNR '@' SY-UNAME '@' INTO REQUTEXT.
    ENDIF.

    TRY.
        CALL FUNCTION 'STFC_CONNECTION' DESTINATION LW_COMPUTER
          EXPORTING
            REQUTEXT              = REQUTEXT
          IMPORTING
            ECHOTEXT              = ECHOTEXT
            RESPTEXT              = RESPTEXT
          EXCEPTIONS "ADD CATCH EXCEPTION
            SYSTEM_FAILURE        = 1
            COMMUNICATION_FAILURE = 2.
        IF SY-SUBRC EQ 1 OR SY-SUBRC EQ 2.
          MESSAGE 'Chưa chạy chương trình SAPtoBKAV hoặc cấu hình sai, liên hệ IT' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      CATCH CX_ROOT .
        MESSAGE 'Cấu hình RFC SM59 theo computer name sai, liên hệ IT' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.
    IF RESPTEXT+0(2) NE 'OK'.
      MESSAGE RESPTEXT TYPE 'S' DISPLAY LIKE 'E'.
*      RETURN.
    ELSE.
      " Thanh cong
      SPLIT RESPTEXT AT '_' INTO TABLE GT_RESULT.
*        PERFORM UPDATE_DATABASE.
      MESSAGE RESPTEXT TYPE 'S' DISPLAY LIKE 'S'.

      LS_MESSAGE-BUKRS   = GS_HEADER-BUKRS.
      LS_MESSAGE-GJAHR   = GS_HEADER-GJAHR.
      LS_MESSAGE-BELNR   = GS_HEADER-BELNR.
      IF GS_HEADER-BLART EQ 'RV'.
        LS_MESSAGE-VBELN   = GS_HEADER-AWKEY+0(10).
*        PERFORM WRITE_TEXT USING GS_HEADER RESPTEXT.
      ENDIF.

      LS_MESSAGE-ZRESULT = RESPTEXT.
      APPEND LS_MESSAGE TO LT_MESSAGE.

      DELETE GT_HEADER
        WHERE BUKRS = GS_HEADER-BUKRS
          AND GJAHR = GS_HEADER-GJAHR
          AND BELNR = GS_HEADER-BELNR.
    ENDIF.
  ENDLOOP.

*  ELSE.

*  PERFORM CHECK_DATA_CS.
*
*  " Lay id tuong ung
*  CALL FUNCTION 'NUMBER_GET_NEXT'
*    EXPORTING
*      NR_RANGE_NR             = '01'
*      OBJECT                  = 'ZNR_ZEIV'
*      QUANTITY                = '1'
*    IMPORTING
*      NUMBER                  = LS_MAP_CS-ID
*    EXCEPTIONS
*      INTERVAL_NOT_FOUND      = 1
*      NUMBER_RANGE_NOT_INTERN = 2
*      OBJECT_NOT_FOUND        = 3
*      QUANTITY_IS_0           = 4
*      QUANTITY_IS_NOT_1       = 5
*      INTERVAL_OVERFLOW       = 6
*      BUFFER_OVERFLOW         = 7
*      OTHERS                  = 8.
*
*  IF SY-SUBRC = 0.
*    LOOP AT GT_HEADER INTO GS_HEADER WHERE CHECK = 'X'.
*      LS_MAP_CS-BELNR = GS_HEADER-BELNR.
*      LS_MAP_CS-BUKRS = GS_HEADER-BUKRS.
*      LS_MAP_CS-GJAHR = GS_HEADER-GJAHR.
*
*      INSERT ZEIV_TB_MAP_CS FROM LS_MAP_CS.
*    ENDLOOP.
*
*    LW_COMPUTER = 'ADMIN'.
*    CONCATENATE GS_HEADER-BUKRS '@' GS_HEADER-GJAHR '@' LS_MAP_CS-ID '@' SY-UNAME '@' LW_TYPE INTO REQUTEXT.
*    TRY.
*        CALL FUNCTION 'STFC_CONNECTION' DESTINATION LW_COMPUTER
*          EXPORTING
*            REQUTEXT              = REQUTEXT
*          IMPORTING
*            ECHOTEXT              = ECHOTEXT
*            RESPTEXT              = RESPTEXT
*          EXCEPTIONS "ADD CATCH EXCEPTION
*            SYSTEM_FAILURE        = 1
*            COMMUNICATION_FAILURE = 2.
*        IF SY-SUBRC EQ 1 OR SY-SUBRC EQ 2.
*          MESSAGE 'Chưa chạy chương trình SAPtoBKAV hoặc cấu hình sai, liên hệ IT' TYPE 'S' DISPLAY LIKE 'E'.
*          RETURN.
*        ENDIF.
*      CATCH CX_ROOT .
*        MESSAGE 'Cấu hình RFC SM59 theo computer name sai, liên hệ IT' TYPE 'S' DISPLAY LIKE 'E'.
*        RETURN.
*    ENDTRY.
*    IF RESPTEXT+0(2) NE 'OK'.
*      MESSAGE RESPTEXT TYPE 'S' DISPLAY LIKE 'E'.
*      RETURN.
*    ELSE.
*      " Thanh cong
*      SPLIT RESPTEXT AT '_' INTO TABLE GT_RESULT.
**        PERFORM UPDATE_DATABASE.
*      MESSAGE RESPTEXT TYPE 'S' DISPLAY LIKE 'S'.
*
*      LOOP AT GT_HEADER INTO GS_HEADER WHERE CHECK = 'X'.
*        LS_MESSAGE-BUKRS   = GS_HEADER-BUKRS.
*        LS_MESSAGE-GJAHR   = GS_HEADER-GJAHR.
*        LS_MESSAGE-BELNR   = GS_HEADER-BELNR.
*        IF GS_HEADER-BLART EQ 'RV'.
*          LS_MESSAGE-VBELN   = GS_HEADER-AWKEY+0(10).
*          PERFORM WRITE_TEXT USING GS_HEADER RESPTEXT.
*        ENDIF.
*
*        LS_MESSAGE-ZRESULT = RESPTEXT.
*        APPEND LS_MESSAGE TO LT_MESSAGE.
*      ENDLOOP.
*      DELETE GT_HEADER WHERE CHECK = 'X'.
*    ENDIF.
*  ENDIF.
*  ENDIF.
  IF  LT_MESSAGE IS NOT INITIAL
  AND P_SUBMIT   IS INITIAL
  AND SY-BATCH   IS INITIAL..
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        I_STRUCTURE_NAME       = 'ZEIV_ST_MESSAGE'
      CHANGING
        CT_FIELDCAT            = LT_FCAT[]
      EXCEPTIONS
        INCONSISTENT_INTERFACE = 1
        PROGRAM_ERROR          = 2
        OTHERS                 = 3.
    LOOP AT LT_FCAT INTO LS_FCAT.
      CASE LS_FCAT-FIELDNAME.
        WHEN 'BUKRS'.
          LS_FCAT-OUTPUTLEN = '7'.
        WHEN 'ZRESULT'.
          LS_FCAT-OUTPUTLEN = '100'.
        WHEN OTHERS.
      ENDCASE.
      MODIFY LT_FCAT FROM LS_FCAT.
    ENDLOOP.

    CALL FUNCTION 'UA_SM1_POPUP_WITH_ALV_GRID'
      EXPORTING
        I_STRUCTURE_NAME = 'ZEIV_ST_MESSAGE'
        IT_FIELDCATALOG  = LT_FCAT
      TABLES
        IT_OUTTAB        = LT_MESSAGE.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_HEADER_SD
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_HEADER_SD .
  DATA: LW_VBELN  TYPE VBELN,
        LW_TAX    TYPE CHAR255,
        LW_TITLE  TYPE TEXT15,
        LW_TDNAME TYPE TDOBNAME,
        LW_LTEXT  TYPE CHAR255,
        LW_AUARV  TYPE AUART_VON,
        LW_MATNR  TYPE MATNR,
        LW_TEXT   TYPE CHAR255.
  DATA: LT_DATA_TEMP TYPE TABLE OF VBRP,
        LW_I         TYPE I.

  LW_VBELN = GS_HEADER-AWKEY+0(10).
  CALL FUNCTION 'ZCORE_FM_GET_PROFILE_SD'
    EXPORTING
      I_NUMBER  = GS_HEADER-KUNNR
      I_VBELN   = LW_VBELN
      I_TYPE    = 'RE'
    IMPORTING
      E_NAME    = GS_HEADER-BNAME
      E_ADDRESS = GS_HEADER-BADDR
      E_TITLE   = LW_TITLE
      E_TAX     = LW_TAX.

  GS_HEADER-BCODE =  LW_TAX.
  REPLACE 'VN' IN GS_HEADER-BCODE WITH ''.

  IF LW_TITLE EQ 'Company' OR LW_TITLE EQ '0003'.
    GS_HEADER-BUNAM = GS_HEADER-BNAME.
    CLEAR GS_HEADER-BNAME.
  ENDIF.

  LW_TDNAME = LW_VBELN.
  " lây thông tin taxt không xuất HĐ
  CLEAR LW_LTEXT.
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'VBBK'
      I_TDNAME    = LW_TDNAME
      I_TDID      = 'Z030'
*     I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = LW_LTEXT.
  IF LW_LTEXT IS NOT INITIAL.
    GS_HEADER-ZDEL = 'X'.
  ENDIF.
  CHECK GS_HEADER-ZDEL IS INITIAL.
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'VBBK'
      I_TDNAME    = LW_TDNAME
      I_TDID      = 'Y001'
*     I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = LW_LTEXT.

  IF LW_LTEXT IS INITIAL.
    SELECT SINGLE NAME1
    INTO LW_LTEXT
    FROM KNVK
    WHERE KUNNR = GS_HEADER-KUNNR.
  ENDIF.

  IF LW_LTEXT IS NOT INITIAL.
    GS_HEADER-BNAME = LW_LTEXT.
  ENDIF.

  IF GS_HEADER-BNAME EQ '.'.
    GS_HEADER-BNAME = ''.
  ENDIF.

  SELECT SINGLE BANKN
  INTO GS_HEADER-BBACC
  FROM KNBK
  WHERE KUNNR EQ GS_HEADER-KUNNR AND
        BANKS EQ 'VN'.

  " Lay longtext
***  CONCATENATE GS_HEADER-BUKRS GS_HEADER-BELNR GS_HEADER-GJAHR INTO LW_TDNAME.


  "PhatTT add begin 20.05.2026 22:01:18
  LW_TDNAME = GS_HEADER-AWKEY .
  "PhatTT add end 20.05.2026 22:01:20


  " Hóa đơn thay thế
****  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
****    EXPORTING
****      i_tdobject  = 'BELEG'
****      i_tdname    = lw_tdname
****      i_tdid      = '035'
****    IMPORTING
****      e_long_text = lw_text.


  "PhatTT add begin 21.05.2026 09:14:54
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'VBBK'
      I_TDNAME    = LW_TDNAME
      I_TDID      = 'Z037'
    IMPORTING
      E_LONG_TEXT = LW_TEXT.
  "PhatTT add end 21.05.2026 09:14:58

  GS_HEADER-ORIGINALINVOICE = LW_TEXT.
  IF GS_HEADER-ORIGINALINVOICE IS NOT INITIAL.
    GS_HEADER-NOTE = '123+'.
  ELSE.
****    CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
****      EXPORTING
****        I_TDOBJECT  = 'BELEG'
****        I_TDNAME    = LW_TDNAME
****        I_TDID      = '034'
****      IMPORTING
****        E_LONG_TEXT = LW_TEXT.

    "PhatTT add begin 20.05.2026 22:00:08
    CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
      EXPORTING
        I_TDOBJECT  = 'VBBK'
        I_TDNAME    = LW_TDNAME
        I_TDID      = 'Z036'
      IMPORTING
        E_LONG_TEXT = LW_TEXT.
    "PhatTT add end 20.05.2026 22:00:16


    GS_HEADER-ORIGINALINVOICE = LW_TEXT.
    " Lay sales order type
    SELECT SINGLE VBAK~AUART VBRP~MATNR
    INTO (LW_AUARV, LW_MATNR)
    FROM VBAK
    INNER JOIN VBRP ON VBRP~AUBEL EQ VBAK~VBELN
    WHERE VBRP~VBELN EQ LW_VBELN.

    IF LW_AUARV EQ 'ZCR' OR LW_AUARV EQ 'ZCR1' OR LW_AUARV EQ 'ZRE4' OR LW_AUARV EQ 'ZCR3'
      OR GS_HEADER-FKART = 'ZRE1'
      OR GS_HEADER-FKART = 'ZRE2'
      OR GS_HEADER-FKART = 'ZIG'
      OR GS_HEADER-FKART = 'ZIGC'
      .
      IF LW_TEXT IS NOT INITIAL.
        " 121 và giam cong no
        GS_HEADER-NOTE = '121-'.
      ELSE.
        " 122 va giam cong no.
        GS_HEADER-NOTE = '122-'.
      ENDIF.
    ELSEIF LW_AUARV EQ 'ZDR' OR LW_AUARV EQ 'ZDR1' OR LW_AUARV EQ 'ZDR3'.
      IF LW_TEXT IS NOT INITIAL.
        " 121 và tang cong no
        GS_HEADER-NOTE = '121+'.
      ELSE.
        " 122 va tang cong no.
        GS_HEADER-NOTE = '121+'. " BKAV recommended dùng 121+ và ko truyền hóa dơn gốc
      ENDIF.
    ENDIF.

    SELECT *
    INTO TABLE LT_DATA_TEMP
    FROM VBRP
    WHERE VBRP~VBELN EQ LW_VBELN.

    DESCRIBE TABLE LT_DATA_TEMP LINES LW_I.

*  IF LW_I = 1.
    IF LW_I > 0.

      DATA: LT_CK_ITEM TYPE TABLE OF ZEB_ST_DETAIL WITH HEADER LINE.
      DATA: LT_CK     TYPE TABLE OF ZEIV_TB_CK WITH HEADER LINE.
      DATA: LW_FLAG     TYPE CHECKBOX.
      CLEAR LT_CK_ITEM.
      SELECT
          POSNR
          MATNR
          ARKTX
          VRKME
          FKIMG
          NETWR
          LGORT
          KURSK
          VGBEL
          AUBEL
          AUPOS
          AUGRU_AUFT
          PSTYV
        INTO CORRESPONDING FIELDS OF TABLE LT_CK_ITEM
        FROM VBRP
        WHERE VBELN = LW_VBELN AND
             ( FKIMG NE 0 OR
               NETWR NE 0 ).

      SORT LT_CK_ITEM BY MATNR.
      DELETE ADJACENT DUPLICATES FROM LT_CK_ITEM COMPARING MATNR.



      SELECT *
      FROM ZEIV_TB_CK
        INTO CORRESPONDING FIELDS OF TABLE LT_CK
        FOR ALL ENTRIES IN LT_CK_ITEM
      WHERE BUKRS = GS_HEADER-BUKRS AND
            MATNR = LT_CK_ITEM-MATNR.
      LW_FLAG = 'X'.
      LOOP AT LT_CK_ITEM.
        READ TABLE LT_CK WITH KEY BUKRS = GS_HEADER-BUKRS
                                  MATNR = LT_CK_ITEM-MATNR.
        IF SY-SUBRC NE 0.
          CLEAR LW_FLAG.
          LW_FLAG = ''.
        ENDIF.
      ENDLOOP.
      IF LW_FLAG EQ 'X'.
        GS_HEADER-NOTE  = '122-'.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_HEADER_FI
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_HEADER_FI .
  DATA: LW_NUMBER TYPE CHAR10,
        LW_TAX    TYPE CHAR255,
        LW_TDNAME TYPE CHAR70,
        LW_LTEXT  TYPE CHAR255,
        LW_TITLE  TYPE TEXT15,
        LW_ZLSCH  TYPE DZLSCH,
        LW_TEXT   TYPE CHAR255.

  IF GS_HEADER-KUNNR IS NOT INITIAL.
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        I_NUMBER  = GS_HEADER-KUNNR
        I_KIND    = 'D'
        I_BUKRS   = GS_HEADER-BUKRS
        I_BELNR   = GS_HEADER-BELNR
        I_GJAHR   = GS_HEADER-GJAHR
      IMPORTING
        E_NAME    = GS_HEADER-BNAME
        E_ADDRESS = GS_HEADER-BADDR
        E_TITLE   = LW_TITLE
        E_TAX     = LW_TAX.
    GS_HEADER-BCODE =  LW_TAX.

    SELECT SINGLE BANKN
    INTO GS_HEADER-BBACC
    FROM KNBK
    WHERE KUNNR EQ GS_HEADER-KUNNR AND
          BANKS EQ 'VN'.

  ELSEIF GS_HEADER-LIFNR IS NOT INITIAL.
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        I_NUMBER  = GS_HEADER-LIFNR
        I_KIND    = 'K'
        I_BUKRS   = GS_HEADER-BUKRS
        I_BELNR   = GS_HEADER-BELNR
        I_GJAHR   = GS_HEADER-GJAHR
      IMPORTING
        E_NAME    = GS_HEADER-BNAME
        E_ADDRESS = GS_HEADER-BADDR
        E_TITLE   = LW_TITLE
        E_TAX     = LW_TAX.
    GS_HEADER-BCODE =  LW_TAX.

    SELECT SINGLE BANKN
    INTO GS_HEADER-BBACC
    FROM LFBK
    WHERE LIFNR EQ GS_HEADER-LIFNR AND
          BANKS EQ 'VN'.
  ELSE.

  ENDIF.
  CLEAR LW_LTEXT.
  LW_TDNAME = GS_HEADER-BUKRS && GS_HEADER-BELNR && GS_HEADER-GJAHR .
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '018'
*     I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = LW_LTEXT.



  REPLACE 'VN' IN GS_HEADER-BCODE WITH ''.
  IF LW_TITLE EQ 'Company' OR LW_TITLE EQ '0003'.
    GS_HEADER-BUNAM = GS_HEADER-BNAME.
    CLEAR GS_HEADER-BNAME.
    IF LW_LTEXT IS NOT INITIAL.
      GS_HEADER-BNAME = LW_LTEXT.
    ENDIF.
  ELSE.
    IF LW_LTEXT IS NOT INITIAL.
      GS_HEADER-BNAME = LW_LTEXT.
    ENDIF.
  ENDIF.

  SELECT SINGLE ZLSCH ZTERM
  INTO ( LW_ZLSCH, GS_HEADER-ZTERM )
  FROM BSEG
  WHERE GJAHR = GS_HEADER-GJAHR AND
        BELNR = GS_HEADER-BELNR AND
        BUKRS = GS_HEADER-BUKRS AND
        HKONT LIKE '131%'.

  IF LW_ZLSCH EQ 'C'.                                " Tien mat
    GS_HEADER-PAYID = 1.
  ELSEIF LW_ZLSCH EQ 'B'.                               " Chuyen khoan
    GS_HEADER-PAYID = 2.
  ELSEIF LW_ZLSCH EQ 'F'.
    GS_HEADER-PAYID = 6.
  ENDIF.

  IF GS_HEADER-PAYID IS INITIAL.                            " NghiaNT.Citek 17.10.2017 12:04:40 Mặc định là Chuyen khoan
    GS_HEADER-PAYID = 2.
  ENDIF.

  " Hóa đơn thay thế
  CONCATENATE GS_HEADER-BUKRS GS_HEADER-BELNR GS_HEADER-GJAHR INTO LW_TDNAME.
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '035'
    IMPORTING
      E_LONG_TEXT = LW_TEXT.
  GS_HEADER-ORIGINALINVOICE = LW_TEXT.
  IF GS_HEADER-ORIGINALINVOICE IS NOT INITIAL.
    GS_HEADER-NOTE = '123+'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_HEADER_MM
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_HEADER_MM .
  DATA: LW_NUMBER TYPE CHAR10,
        LW_TAX    TYPE CHAR255,
        LW_TITLE  TYPE TEXT15,
        LW_ZLSCH  TYPE DZLSCH,
        LW_TEXT   TYPE CHAR255,
        LW_TDNAME TYPE TDOBNAME.

  IF GS_HEADER-KUNNR IS NOT INITIAL.
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        I_NUMBER  = GS_HEADER-KUNNR
        I_KIND    = 'D'
        I_BUKRS   = GS_HEADER-BUKRS
        I_BELNR   = GS_HEADER-BELNR
        I_GJAHR   = GS_HEADER-GJAHR
      IMPORTING
        E_NAME    = GS_HEADER-BNAME
        E_ADDRESS = GS_HEADER-BADDR
        E_TITLE   = LW_TITLE
        E_TAX     = LW_TAX.
    GS_HEADER-BCODE =  LW_TAX.
  ELSEIF GS_HEADER-LIFNR IS NOT INITIAL.
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        I_NUMBER  = GS_HEADER-LIFNR
        I_KIND    = 'K'
        I_BUKRS   = GS_HEADER-BUKRS
        I_BELNR   = GS_HEADER-BELNR
        I_GJAHR   = GS_HEADER-GJAHR
      IMPORTING
        E_NAME    = GS_HEADER-BNAME
        E_ADDRESS = GS_HEADER-BADDR
        E_TITLE   = LW_TITLE
        E_TAX     = LW_TAX.
    GS_HEADER-BCODE =  LW_TAX.
  ENDIF.
  REPLACE 'VN' IN GS_HEADER-BCODE WITH ''.
  IF LW_TITLE EQ 'Company' OR LW_TITLE EQ '0003'.
    GS_HEADER-BUNAM = GS_HEADER-BNAME.
    CLEAR GS_HEADER-BNAME.
  ENDIF.

  SELECT SINGLE ZLSCH ZTERM
  INTO ( LW_ZLSCH, GS_HEADER-ZTERM )
  FROM BSEG
  WHERE GJAHR = GS_HEADER-GJAHR AND
        BELNR = GS_HEADER-BELNR AND
        BUKRS = GS_HEADER-BUKRS AND
        HKONT LIKE '131%'.

  IF LW_ZLSCH EQ 'C'.                                " Tien mat
    GS_HEADER-PAYID = 1.
  ELSEIF LW_ZLSCH EQ 'B'.                               " Chuyen khoan
    GS_HEADER-PAYID = 2.
  ELSEIF LW_ZLSCH EQ 'F'.
    GS_HEADER-PAYID = 6.
  ENDIF.

  IF GS_HEADER-PAYID IS INITIAL.                            " NghiaNT.Citek 17.10.2017 12:04:40 Mặc định là Chuyen khoan
    GS_HEADER-PAYID = 2.
  ENDIF.

  " Hóa đơn thay thế
  CONCATENATE GS_HEADER-BUKRS GS_HEADER-BELNR GS_HEADER-GJAHR INTO LW_TDNAME.
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '035'
    IMPORTING
      E_LONG_TEXT = LW_TEXT.
  GS_HEADER-ORIGINALINVOICE = LW_TEXT.
  IF GS_HEADER-ORIGINALINVOICE IS NOT INITIAL.
    GS_HEADER-NOTE = '123+'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form WRITE_TEXT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*      -->P_GS_HEADER  text
*      -->P_RESPTEXT  text
*&---------------------------------------------------------------------*
FORM WRITE_TEXT  USING    P_GS_HEADER LIKE GS_HEADER
                          P_RESPTEXT TYPE SY-LISEL.
  DATA: LT_RESULT  TYPE TABLE OF STRING,
        LS_RESULT  TYPE STRING,
        LW_FORM    TYPE ZDE_IFORM,
        LW_SERI    TYPE ZDE_ISERIAL,
        LW_INUM    TYPE ZDE_INUMBER,
        LW_7CHAR   TYPE CHAR7,
        LW_CHAR255 TYPE CHAR255,
        LW_TDNAME  TYPE TDOBNAME.

  SPLIT P_RESPTEXT AT '_' INTO TABLE LT_RESULT.

  LOOP AT LT_RESULT INTO LS_RESULT.
    CASE SY-TABIX.
      WHEN 2.
        LW_FORM = LS_RESULT.
      WHEN 3.
        LW_SERI = LS_RESULT.
      WHEN 4.
        LW_INUM = LS_RESULT.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.

  LW_7CHAR = LW_INUM.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      INPUT  = LW_7CHAR
    IMPORTING
      OUTPUT = LW_7CHAR.

  CONCATENATE LW_FORM '_' LW_SERI '.' LW_7CHAR INTO LW_CHAR255.
  P_RESPTEXT = LW_CHAR255.
  LW_TDNAME = P_GS_HEADER-AWKEY+0(10).

  CALL FUNCTION 'ZCORE_FM_SAVE_LONG_TEXT'
    EXPORTING
      I_TDOBJECT = 'VBBK'
      I_TDNAME   = LW_TDNAME
      I_TDID     = '0002'
      I_LONGTEXT = LW_CHAR255
    EXCEPTIONS
      ID         = 1
      LANGUAGE   = 2
      NAME       = 3
      OBJECT     = 4
      OTHERS     = 5.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_EMAIL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_EMAIL .
  DATA:
    LT_ADR6 TYPE TABLE OF ADR6 WITH HEADER LINE,
    LT_ADRT TYPE TABLE OF ADRT WITH HEADER LINE.
  DATA: LW_ADRNR_VBPA   TYPE VBPA-ADRNR,
        LW_ADRNR_KNA1   TYPE VBPA-ADRNR,
        LW_ADRNR        TYPE VBPA-ADRNR,
        LW_PARTNER_GUID TYPE CVI_CUST_LINK-PARTNER_GUID,
        LW_PARTNER      TYPE BUT020-PARTNER,
        LW_TDNAME       TYPE TDOBNAME.

  CONCATENATE GS_HEADER-BUKRS GS_HEADER-BELNR GS_HEADER-GJAHR INTO LW_TDNAME.
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '019'
      I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = GS_HEADER-EMAIL.
  IF GS_HEADER-EMAIL IS INITIAL.


    " Xu ly email cua customer
    IF GS_HEADER-KUNNR IS NOT INITIAL.
      " Lay address tu VBPA
      SELECT SINGLE ADRNR
      INTO LW_ADRNR_VBPA
      FROM VBPA
      WHERE VBELN EQ GS_HEADER-AWKEY+0(10) AND
            PARVW EQ 'RE'.

      " Lay address tu KNA1
      SELECT SINGLE ADRNR
      INTO LW_ADRNR_KNA1
      FROM KNA1
      WHERE KUNNR EQ GS_HEADER-KUNNR.

      " So sanh 2 address
      IF LW_ADRNR_VBPA IS NOT INITIAL.
        IF LW_ADRNR_VBPA NE LW_ADRNR_KNA1.
          LW_ADRNR = LW_ADRNR_VBPA.
        ENDIF.
      ENDIF.

      " Link sang BP lay address tu BP
      IF LW_ADRNR IS INITIAL.
        SELECT SINGLE PARTNER_GUID
        INTO LW_PARTNER_GUID
        FROM CVI_CUST_LINK
        WHERE CUSTOMER = GS_HEADER-KUNNR.

        SELECT SINGLE PARTNER
        INTO LW_PARTNER
        FROM BUT000
        WHERE PARTNER_GUID = LW_PARTNER_GUID.

        SELECT SINGLE ADDRNUMBER
        INTO LW_ADRNR
        FROM BUT020
        WHERE PARTNER = LW_PARTNER.
      ENDIF.

      " NghiaNT.Citek 17.10.2017 14:57:20 ReceiverEmail
      SELECT  *
      INTO CORRESPONDING FIELDS OF TABLE LT_ADR6
      FROM ADR6
      WHERE ADDRNUMBER EQ LW_ADRNR AND
            PERSNUMBER EQ ''.

    ELSEIF  GS_HEADER-LIFNR IS NOT INITIAL.
      " NghiaNT.Citek 05.02.2018 11:54:26 Lấy từ master data vendor
      SELECT  *
      INTO CORRESPONDING FIELDS OF TABLE LT_ADR6
      FROM ADR6
      INNER JOIN LFA1 ON LFA1~ADRNR EQ ADR6~ADDRNUMBER
      WHERE LIFNR EQ GS_HEADER-LIFNR.

    ENDIF.

    IF LT_ADR6[] IS NOT INITIAL.
      " NghiaNT.Citek 07.02.2018 09:39:15 Lấy note email
      SELECT *
      INTO CORRESPONDING FIELDS OF TABLE LT_ADRT
      FROM ADRT
      FOR ALL ENTRIES IN LT_ADR6
      WHERE ADDRNUMBER = LT_ADR6-ADDRNUMBER AND
            PERSNUMBER = LT_ADR6-PERSNUMBER.
    ELSE.
      " NghiaNT.Citek 07.02.2018 09:39:15 Lấy note email
      SELECT *
      INTO CORRESPONDING FIELDS OF TABLE LT_ADRT
      FROM ADRT
      INNER JOIN KNA1 ON KNA1~ADRNR EQ ADRT~ADDRNUMBER
      WHERE KUNNR EQ GS_HEADER-KUNNR.
      IF SY-SUBRC NE 0 AND GS_HEADER-LIFNR IS NOT INITIAL.
        SELECT *
        INTO CORRESPONDING FIELDS OF TABLE LT_ADRT
        FROM ADRT
        INNER JOIN LFA1 ON LFA1~ADRNR EQ ADRT~ADDRNUMBER
        WHERE LIFNR EQ GS_HEADER-LIFNR.
      ENDIF.
    ENDIF.


    " NghiaNT.Citek 07.02.2018 09:54:49 Trường hợp có ghi note
    IF LT_ADRT[] IS NOT INITIAL.
      LOOP AT LT_ADR6.
        READ TABLE LT_ADRT WITH KEY ADDRNUMBER = LT_ADR6-ADDRNUMBER
                                    PERSNUMBER = LT_ADR6-PERSNUMBER
                                    CONSNUMBER = LT_ADR6-CONSNUMBER.
        IF SY-SUBRC = 0.
          " NghiaNT.Citek 07.02.2018 11:29:50 Nếu có remark thì so sánh với company code
          IF LT_ADRT-REMARK IS NOT INITIAL.
            IF LT_ADRT-REMARK = GS_HEADER-BUKRS.
              IF GS_HEADER-EMAIL IS INITIAL.
                GS_HEADER-EMAIL = LT_ADR6-SMTP_ADDR.
              ELSE.
                CONCATENATE GS_HEADER-EMAIL LT_ADR6-SMTP_ADDR INTO GS_HEADER-EMAIL SEPARATED BY ';'.
              ENDIF.
            ENDIF.
            " NghiaNT.Citek 07.02.2018 11:30:10 Ko có thì ko cần so sánh
          ELSE.
            IF GS_HEADER-EMAIL IS INITIAL.
              GS_HEADER-EMAIL = LT_ADR6-SMTP_ADDR.
            ELSE.
              CONCATENATE GS_HEADER-EMAIL LT_ADR6-SMTP_ADDR INTO GS_HEADER-EMAIL SEPARATED BY ';'.
            ENDIF.
          ENDIF.
        ELSE.
          " NghiaNT.Citek 07.02.2018 11:30:10 Ko có thì ko cần so sánh
          IF GS_HEADER-EMAIL IS INITIAL.
            GS_HEADER-EMAIL = LT_ADR6-SMTP_ADDR.
          ELSE.
            CONCATENATE GS_HEADER-EMAIL LT_ADR6-SMTP_ADDR INTO GS_HEADER-EMAIL SEPARATED BY ';'.
          ENDIF.
        ENDIF.

      ENDLOOP.
      " NghiaNT.Citek 07.02.2018 09:54:59 Trường hợp không ghi note
    ELSE.
      LOOP AT LT_ADR6.
        IF GS_HEADER-EMAIL IS INITIAL.
          GS_HEADER-EMAIL = LT_ADR6-SMTP_ADDR.
        ELSE.
          CONCATENATE GS_HEADER-EMAIL LT_ADR6-SMTP_ADDR INTO GS_HEADER-EMAIL SEPARATED BY ';'.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SUMBIT_PROGRAM
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SUMBIT_PROGRAM .
  SORT GT_HEADER BY FKDAT BUKRS BELNR GJAHR.

  IF P_CAL EQ 'X'.
    EXPORT GT_HEADERS FROM GT_HEADER TO MEMORY ID 'GT_HEADER_HDDT'.
    EXPORT GT_DETAILS FROM GT_DETAIL_ALL TO MEMORY ID 'GT_DETAIL_HDDT'.
    LEAVE PROGRAM.
  ELSEIF P_SUBMIT EQ 'X' OR SY-BATCH IS NOT INITIAL.

    " START --> 30.01.24: tuan.nguyen4
    IF SY-BATCH IS NOT INITIAL.
      SORT GT_HEADER BY BUDAT FKDAT BUKRS BELNR GJAHR.
    ENDIF.
    " END  --> 30.01.24: tuan.nguyen4
    LOOP AT GT_HEADER ASSIGNING <FS_HEADER>.
      <FS_HEADER>-CHECK = 'X'.
    ENDLOOP.
*    PERFORM send_data. "tri.nguyen2 cmt 26.11.2025
    PERFORM SEND_DATA_INV.
    LEAVE PROGRAM.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_CUSTOMER_CS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_CUSTOMER_CS .
*  SELECT *
*  INTO CORRESPONDING FIELDS OF TABLE GT_CS
*  FROM ZEIV_TB_CS
*  WHERE BUKRS EQ P_BUKRS AND
*        GLTGV <= SY-DATUM AND
*        GLTGB >= SY-DATUM.
*
*  IF SY-SUBRC = 0.
*    LOOP AT GT_CS INTO GS_CS.
*      GR_KUNNR-LOW = GS_CS-KUNNR.
*      GR_KUNNR-OPTION = 'EQ'.
*      GR_KUNNR-SIGN   = 'I'.
*      APPEND GR_KUNNR.
*    ENDLOOP.
*
*    IF R_SD EQ 'X'.
*      DELETE GT_HEADER WHERE KUNNR IN GR_KUNNR.
**    ELSEIF R_CS EQ 'X'.
**      DELETE GT_HEADER WHERE KUNNR NOT IN GR_KUNNR.
*    ENDIF.
*  ENDIF.
  IF P_SUBMIT EQ 'X' AND GT_HEADER IS INITIAL.
    LEAVE PROGRAM.
  ELSEIF GT_HEADER IS INITIAL.
    MESSAGE 'NO DATA' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_DATA_CS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_DATA_CS .
  DATA: LW_KUNNR TYPE KUNNR.

  READ TABLE GT_HEADER INTO GS_HEADER WITH KEY CHECK = 'X'.
  IF SY-SUBRC NE 0.
    MESSAGE 'Vui lòng chọn ít nhất 1 dòng' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ELSE.
    LW_KUNNR = GS_HEADER-KUNNR.
  ENDIF.

  LOOP AT GT_HEADER INTO GS_HEADER WHERE CHECK = 'X'.
    IF LW_KUNNR NE GS_HEADER-KUNNR.
      MESSAGE 'Không được chọn nhiều mã khách hàng' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_DATA_NONCS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_DATA_NONCS .
  READ TABLE GT_HEADER INTO GS_HEADER WITH KEY CHECK = 'X'.
  IF SY-SUBRC NE 0.
    MESSAGE 'Vui lòng chọn ít nhất 1 dòng' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form DATA_CHANGED_PROC_DETAIL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*      -->P_E_MODIFIED  text
*      -->P_ET_GOOD_CELLS  text
*&---------------------------------------------------------------------*
FORM DATA_CHANGED_PROC_DETAIL
  USING E_MODIFIED    TYPE  CHAR01
        ET_GOOD_CELLS TYPE  LVC_T_MODI.
  DATA: LS_GOOD   TYPE LVC_S_MODI.
  CHECK E_MODIFIED EQ 'X'.

*  LOOP AT ET_GOOD_CELLS INTO LS_GOOD.
*    CASE LS_GOOD-FIELDNAME.
*      WHEN 'EXT_MEINS'.
*        READ TABLE GT_DETAIL ASSIGNING <FS_DETAIL> INDEX LS_GOOD-ROW_ID.
*        IF SY-SUBRC = 0.
*          SELECT SINGLE
*            MSEHT
*            INTO <FS_DETAIL>-EXT_UNIT
*            FROM T006A
*            WHERE MSEHI = <FS_DETAIL>-EXT_MEINS
*              AND SPRAS EQ 'E'.
*          IF SY-SUBRC NE 0.
*            CLEAR <FS_DETAIL>-EXT_UNIT.
*          ENDIF.
*        ENDIF.
*      WHEN OTHERS.
*    ENDCASE.
*  ENDLOOP.
*
*  LOOP AT GT_DETAIL INTO GS_DETAIL.
*    READ TABLE GT_DETAIL_ALL ASSIGNING <FS_DETAIL> WITH KEY BUKRS = GS_DETAIL-BUKRS
*                                                            BELNR = GS_DETAIL-BELNR
*                                                            GJAHR = GS_DETAIL-GJAHR
*                                                            BUZEI = GS_DETAIL-BUZEI.
*    IF SY-SUBRC = 0.
*      <FS_DETAIL> = GS_DETAIL.
*    ENDIF.
*  ENDLOOP.
*
*  CALL METHOD ALV_GRID_DETAIL->REFRESH_TABLE_DISPLAY
*    EXPORTING
*      IS_STABLE = G_STATE.
*  IF SY-SUBRC <> 0.
*  ENDIF.
*
*  IF SY-SUBRC <> 0.
*  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_LONG_TEXT_TEN_TAU
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_HEADER
*&---------------------------------------------------------------------*
FORM GET_LONG_TEXT_TEN_TAU  USING    P_GS_HEADER TYPE ZEIV_ST_GETDATA.
  DATA: LW_TDNAME TYPE TDOBNAME,
        LW_PRCTR  TYPE BSEG-PRCTR,
        LW_MATNR  TYPE BSEG-MATNR.

  CONCATENATE P_GS_HEADER-BUKRS P_GS_HEADER-BELNR P_GS_HEADER-GJAHR INTO LW_TDNAME.
  "TEN TAU
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '011'
      I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = P_GS_HEADER-TEN_TAU.

  "QUOC TICH
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '012'
      I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = P_GS_HEADER-QUOC_TICH.

  "TRONG TAI
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '013'
      I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = P_GS_HEADER-TRONG_TAI.

  "NGAY DEN
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '014'
      I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = P_GS_HEADER-NGAY_DEN.

  "NGAY DI
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '015'
      I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = P_GS_HEADER-NGAY_DI.

  "NOI DAU
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'BELEG'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '016'
      I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = P_GS_HEADER-NOI_DAU.

  CONCATENATE P_GS_HEADER-BUKRS P_GS_HEADER-BELNR P_GS_HEADER-GJAHR '002' INTO LW_TDNAME.
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      I_TDOBJECT  = 'DOC_ITEM'
      I_TDNAME    = LW_TDNAME
      I_TDID      = '0001'
      I_TDSPRAS   = 'E'
    IMPORTING
      E_LONG_TEXT = P_GS_HEADER-CAN_CU.

  " Loai hang
  SELECT SINGLE PRCTR MATNR
  INTO ( LW_PRCTR, LW_MATNR )
  FROM BSEG
  WHERE BUKRS = P_GS_HEADER-BUKRS AND
        GJAHR = P_GS_HEADER-GJAHR AND
        BELNR = P_GS_HEADER-BELNR AND
        BSCHL = '50'           AND
        PRCTR NE ''.

  IF LW_PRCTR+6(4) EQ '6202'.
    SELECT SINGLE MAKTX
    INTO P_GS_HEADER-LOAI_HANG
    FROM MAKT
    WHERE MATNR EQ LW_MATNR AND
          SPRAS EQ 'EN'.
  ENDIF.

  " START --> 22.12.23: tuan.nguyen4
  IF P_GS_HEADER-BUKRS EQ '2000'.
    CLEAR P_GS_HEADER-LOAI_HANG.
  ENDIF.
  " END   --> 22.12.23: tuan.nguyen4
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SEND_DATA_INV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SEND_DATA_INV.
  "tri.nguyen2 add begin 27.11.2025 17:11:57
* Bỏ app trung gian
  "# • [CS]_Phat.Tran - Add Start - 20.07.2026 14:48:05
  TYPES: BEGIN OF LTY_SUCCESS,
           BUKRS TYPE BKPF-BUKRS,
           BELNR TYPE BKPF-BELNR,
           GJAHR TYPE BKPF-GJAHR,
           AWKEY TYPE BKPF-AWKEY,
         END OF LTY_SUCCESS.
  DATA: LT_SUCCESS_DOCS TYPE TABLE OF LTY_SUCCESS,
        LT_ACCCHG       TYPE TABLE OF ACCCHG,
        LS_ACCCHG       TYPE ACCCHG.
  "# • [CS]_Phat.Tran - Add End - 20.07.2026 14:48:05

  DATA: LT_MESSAGE TYPE TABLE OF ZEIV_ST_MESSAGE,
        LT_FCAT    TYPE TABLE OF LVC_S_FCAT,
        LT_DETAIL  LIKE GT_DETAIL_ALL,
        LV_PHASE   TYPE INT1.

  IF NOT LINE_EXISTS( GT_HEADER[ CHECK = ABAP_TRUE ] ).
    MESSAGE 'Please select at least 1 line data!' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT GT_HEADER REFERENCE INTO DATA(LR_HEADER)
       WHERE CHECK = 'X'.

    IF P_NEW EQ 'X'.
      LV_PHASE = '1'.
    ELSE.
      LV_PHASE = '2'.
    ENDIF.

    LT_DETAIL = VALUE #( FOR LS_DET IN GT_DETAIL_ALL
                                    WHERE ( BUKRS = LR_HEADER->BUKRS
                                      AND   GJAHR = LR_HEADER->GJAHR
                                      AND   BELNR = LR_HEADER->BELNR )
                                          ( LS_DET ) ).

    NEW ZCL_EINV( )->CREATE_INV( EXPORTING  IV_PHASE           = LV_PHASE
                                            IS_DATA            = LR_HEADER->*
                                            IT_DETAIL          = LT_DETAIL
                                 IMPORTING  ES_RETURN          = DATA(LS_RETURN)
                                 EXCEPTIONS MISSING_CONFIG     = 1
                                            SYSTEM_FAULT_OCCUR = 2 ).
    IF SY-SUBRC <> 0.
      CL_RMSL_MESSAGE=>DISPLAY( LS_RETURN-MESSAGE ).
      RETURN.
    ENDIF.

    APPEND VALUE #( BUKRS   = LR_HEADER->BUKRS
                    GJAHR   = LR_HEADER->GJAHR
                    BELNR   = LR_HEADER->BELNR
                    VBELN   = COND #( WHEN LR_HEADER->BLART = 'RV' THEN LR_HEADER->AWKEY+0(10) )
                    ZRESULT = LS_RETURN-MESS_LOG   )
           TO LT_MESSAGE.

    IF LS_RETURN-ERROR = ''.
      "# • [CS]_Phat.Tran - Add Start - 20.07.2026 14:51:18
      APPEND VALUE #( BUKRS = LR_HEADER->BUKRS
                      BELNR = LR_HEADER->BELNR
                      GJAHR = LR_HEADER->GJAHR
                      AWKEY = LR_HEADER->AWKEY ) TO LT_SUCCESS_DOCS.
      "# • [CS]_Phat.Tran - Add End - 20.07.2026 14:51:18
      DELETE GT_HEADER WHERE BUKRS = LR_HEADER->BUKRS
                         AND GJAHR = LR_HEADER->GJAHR
                         AND BELNR = LR_HEADER->BELNR.
    ENDIF.
  ENDLOOP.

  "# • [CS]_Phat.Tran - Add Start - 20.07.2026 14:51:51
  IF LT_SUCCESS_DOCS IS NOT INITIAL.
    SELECT BUKRS,
           BELNR,
           GJAHR,
           XBLNR
      FROM BKPF
      INTO TABLE @DATA(LT_BKPF)
      FOR ALL ENTRIES IN @LT_SUCCESS_DOCS
      WHERE BUKRS = @LT_SUCCESS_DOCS-BUKRS
        AND BELNR = @LT_SUCCESS_DOCS-BELNR
        AND GJAHR = @LT_SUCCESS_DOCS-GJAHR.
    SORT LT_BKPF BY BUKRS BELNR GJAHR.
    SELECT BUKRS,
           BELNR,
           GJAHR,
           BUZEI
      FROM BSEG
      INTO TABLE @DATA(LT_BSEG)
      FOR ALL ENTRIES IN @LT_SUCCESS_DOCS
      WHERE BUKRS = @LT_SUCCESS_DOCS-BUKRS
        AND BELNR = @LT_SUCCESS_DOCS-BELNR
        AND GJAHR = @LT_SUCCESS_DOCS-GJAHR
        AND KOART = 'D'.
    SORT LT_BSEG BY BUKRS BELNR GJAHR.
    LOOP AT LT_SUCCESS_DOCS INTO DATA(LS_DOC).
      READ TABLE LT_BKPF INTO DATA(LS_BKPF) WITH KEY BUKRS = LS_DOC-BUKRS
                                                     BELNR = LS_DOC-BELNR
                                                     GJAHR = LS_DOC-GJAHR
                                                     BINARY SEARCH.
      CHECK SY-SUBRC = 0 AND LS_BKPF-XBLNR IS NOT INITIAL.
      READ TABLE LT_BSEG INTO DATA(LS_BSEG) WITH KEY BUKRS = LS_DOC-BUKRS
                                                     BELNR = LS_DOC-BELNR
                                                     GJAHR = LS_DOC-GJAHR
                                                     BINARY SEARCH.
      CHECK SY-SUBRC = 0.
      UPDATE BSEG
         SET XREF3 = @LS_BKPF-XBLNR
       WHERE BUKRS = @LS_DOC-BUKRS
         AND BELNR = @LS_DOC-BELNR
         AND GJAHR = @LS_DOC-GJAHR.
    ENDLOOP.

    COMMIT WORK AND WAIT.
  ENDIF.
  "# • [CS]_Phat.Tran - Add End - 20.07.2026 14:51:51

  IF SY-BATCH IS NOT INITIAL.
    RETURN.
  ENDIF.

  IF LT_MESSAGE IS NOT INITIAL.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        I_STRUCTURE_NAME       = 'ZEIV_ST_MESSAGE'
      CHANGING
        CT_FIELDCAT            = LT_FCAT[]
      EXCEPTIONS
        INCONSISTENT_INTERFACE = 1
        PROGRAM_ERROR          = 2
        OTHERS                 = 3.

    LOOP AT LT_FCAT REFERENCE INTO DATA(LR_FCAT).
      CASE LR_FCAT->FIELDNAME.
        WHEN 'BUKRS'.
          LR_FCAT->OUTPUTLEN = '7'.
        WHEN 'ZRESULT'.
          LR_FCAT->OUTPUTLEN = '100'.
        WHEN OTHERS.
      ENDCASE.
    ENDLOOP.

    CALL FUNCTION 'UA_SM1_POPUP_WITH_ALV_GRID'
      EXPORTING
        I_STRUCTURE_NAME = 'ZEIV_ST_MESSAGE'
        IT_FIELDCATALOG  = LT_FCAT
      TABLES
        IT_OUTTAB        = LT_MESSAGE.
  ENDIF.
  "tri.nguyen2 add end 27.11.2025 17:11:57
ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_INVOICE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_INVOICE .
  LOOP AT GT_HEADER REFERENCE INTO DATA(LR_HEADER)
       WHERE CHECK = 'X'.

    NEW ZCL_EINV( )->GET_INVOICE_VAT( EXPORTING  IS_HEADER          = LR_HEADER->*
                                      IMPORTING  ES_RETURN          = DATA(LS_RETURN)
                                      EXCEPTIONS MISSING_CONFIG     = 1
                                                 SYSTEM_FAULT_OCCUR = 2 ).
    IF SY-SUBRC <> 0 OR LS_RETURN-MESSAGE IS NOT INITIAL.
      CL_RMSL_MESSAGE=>DISPLAY( LS_RETURN-MESSAGE ).
      RETURN.
    ENDIF.
  ENDLOOP.
  MESSAGE S010(ZMC_EINV).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form handle_hotspot_click
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM HANDLE_HOTSPOT_CLICK USING LPV_FIELDNAME
                                LPV_INDEX.
  CASE LPV_FIELDNAME.
    WHEN 'JSON_REQ'.
      READ TABLE GT_HEADER REFERENCE INTO DATA(LR_HEADER) INDEX LPV_INDEX.
      IF SY-SUBRC = 0.
        DATA LT_DETAIL LIKE GT_DETAIL_ALL.
        LT_DETAIL = VALUE #( FOR LS_DET IN GT_DETAIL_ALL
                                    WHERE ( BUKRS = LR_HEADER->BUKRS
                                      AND   GJAHR = LR_HEADER->GJAHR
                                      AND   BELNR = LR_HEADER->BELNR )
                                          ( LS_DET ) ).

        DATA LV_PHASE TYPE INT1.
        IF P_NEW EQ 'X'.
          LV_PHASE = '1'.
        ELSE.
          LV_PHASE = '2'.
        ENDIF.

        DATA(LV_DRAFT) = 'X'.
        NEW ZCL_EINV( )->CREATE_INV( EXPORTING  IV_PHASE           = LV_PHASE
                                                IV_DRAFT           = LV_DRAFT
                                                IS_DATA            = LR_HEADER->*
                                                IT_DETAIL          = LT_DETAIL
                                     IMPORTING  ES_RETURN          = DATA(LS_RETURN)
                                     EXCEPTIONS MISSING_CONFIG     = 1
                                                SYSTEM_FAULT_OCCUR = 2 ).

        NEW ZCL_EINV( )->SHOW_JSON( SECTION = 'REQUEST'
                                    JSON    = CL_BCS_CONVERT=>STRING_TO_XSTRING( IV_STRING = LS_RETURN-JSON_REQUEST ) ).

      ENDIF.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.

*
*
