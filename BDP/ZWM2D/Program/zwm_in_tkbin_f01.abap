*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_TKBIN_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form INIT_SCREEN
*&---------------------------------------------------------------------*
FORM INIT_SCREEN.

  GV_T1 = 'Điều kiện chọn'.                                   "#EC NOTEXT
  GV_T2 = 'Chức năng'.                                        "#EC NOTEXT
  GV_T3 = 'Tùy chọn hiển thị'.                                "#EC NOTEXT

  %_P_LGNUM_%_APP_%-TEXT = 'Warehouse'.                       "#EC NOTEXT
  %_S_LGTYP_%_APP_%-TEXT = 'Storage Type'.                    "#EC NOTEXT
  %_S_LGBER_%_APP_%-TEXT = 'Storage Section'.                 "#EC NOTEXT
  %_S_LGPLA_%_APP_%-TEXT = 'Storage Bin'.                     "#EC NOTEXT
  %_S_MATNR_%_APP_%-TEXT = 'Vật tư'.                          "#EC NOTEXT
  %_S_CHARG_%_APP_%-TEXT = 'Lô'.                              "#EC NOTEXT
  %_S_CAT_%_APP_%-TEXT   = 'Stock Type'.                      "#EC NOTEXT
  %_S_WERKS_%_APP_%-TEXT = 'Plant'.                           "#EC NOTEXT
  %_S_LGORT_%_APP_%-TEXT = 'Storage Location'.                "#EC NOTEXT
  %_S_HUID_%_APP_%-TEXT  = 'Handling Unit'.                   "#EC NOTEXT
  %_S_WDATU_%_APP_%-TEXT = 'Ngày nhập kho'.                   "#EC NOTEXT
  %_S_VFDAT_%_APP_%-TEXT = 'Hạn dùng'.                        "#EC NOTEXT
  %_P_LIST_%_APP_%-TEXT  = 'Danh sách tồn kho'.               "#EC NOTEXT
  %_P_MAP_%_APP_%-TEXT   = 'Sơ đồ kho'.                       "#EC NOTEXT
  %_P_EXINT_%_APP_%-TEXT = 'Loại trừ ST trung gian'.            "#EC NOTEXT
  %_P_EMPTY_%_APP_%-TEXT = 'Hiển thị Bin trống'.              "#EC NOTEXT
  %_P_LOCK_%_APP_%-TEXT  = 'Chỉ Bin đang bị khóa'.            "#EC NOTEXT
  %_P_BATCH_%_APP_%-TEXT = 'Hiển thị thuộc tính lô'.          "#EC NOTEXT
  %_P_CONV_%_APP_%-TEXT  = 'Xem tồn kho theo ĐVT quy đổi'.    "#EC NOTEXT
  %_P_MEINS_%_APP_%-TEXT = 'ĐVT quy đổi'.                     "#EC NOTEXT
  %_P_VARI_%_APP_%-TEXT  = 'Layout ALV'.                      "#EC NOTEXT

  TXT_SB  = 'Storage Bin'.                                    "#EC NOTEXT
  TXT_SM  = 'Vật tư'.                                         "#EC NOTEXT
  TXT_SD  = 'Mô tả'.                                          "#EC NOTEXT
  TXT_SL  = 'Lô'.                                             "#EC NOTEXT
  TXT_SS  = 'E / B'.                                          "#EC NOTEXT
  TXT_SU  = 'ĐVT quy đổi'.                                    "#EC NOTEXT
  B_FIND  = 'Tìm'.                                            "#EC NOTEXT
  B_REFR  = 'Làm mới'.                                        "#EC NOTEXT
  B_SWST  = 'Chuyển Storage Type'.                            "#EC NOTEXT
  B_LIST  = 'Danh sách tồn kho'.                              "#EC NOTEXT

  GET PARAMETER ID '/SCWM/LGN' FIELD P_LGNUM.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F4_VARIANT
*&---------------------------------------------------------------------*
FORM F4_VARIANT.

  DATA: LS_VARIANT TYPE DISVARIANT,
        LS_RETURN  TYPE DISVARIANT.

  LS_VARIANT-REPORT = SY-REPID.

  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      IS_VARIANT = LS_VARIANT
      I_SAVE     = 'A'
    IMPORTING
      ES_VARIANT = LS_RETURN
    EXCEPTIONS
      NOT_FOUND  = 1
      OTHERS     = 2.
  IF SY-SUBRC = 0.
    P_VARI = LS_RETURN-VARIANT.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_SCREEN_FIELD
*&---------------------------------------------------------------------*
* Gia tri dang nhap tren man hinh chon (F4 chay truoc khi bien duoc cap nhat)
FORM READ_SCREEN_FIELD USING    IV_FIELD TYPE CLIKE
                       CHANGING CV_VALUE TYPE CLIKE.

  DATA LT_DYN TYPE STANDARD TABLE OF DYNPREAD WITH EMPTY KEY.

  CLEAR CV_VALUE.
  LT_DYN = VALUE #( ( FIELDNAME = IV_FIELD ) ).

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      DYNAME             = SY-REPID
      DYNUMB             = SY-DYNNR
      TRANSLATE_TO_UPPER = ABAP_TRUE
    TABLES
      DYNPFIELDS         = LT_DYN
    EXCEPTIONS
      OTHERS             = 1.
  IF SY-SUBRC = 0 AND LT_DYN IS NOT INITIAL.
    CV_VALUE = LT_DYN[ 1 ]-FIELDVALUE.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F4_CAT
*&---------------------------------------------------------------------*
* Search help Stock Type: theo Warehouse dang nhap
FORM F4_CAT USING IV_FIELD TYPE CLIKE.

  TYPES: BEGIN OF LTY_VAL,
           CAT TYPE I_EWM_STOCKTYPETEXT_2-EWMSTOCKTYPE,
           TXT TYPE I_EWM_STOCKTYPETEXT_2-EWMSTOCKTYPENAME,
         END OF LTY_VAL.

  DATA: LV_LGNUM TYPE /SCWM/LGNUM,
        LR_LGNUM TYPE RANGE OF /SCWM/LGNUM,
        LT_VAL   TYPE STANDARD TABLE OF LTY_VAL WITH EMPTY KEY.

  PERFORM READ_SCREEN_FIELD USING 'P_LGNUM' CHANGING LV_LGNUM.
  IF LV_LGNUM IS NOT INITIAL.
    LR_LGNUM = VALUE #( ( SIGN = 'I' OPTION = 'EQ' LOW = LV_LGNUM ) ).
  ENDIF.

  SELECT EWMSTOCKTYPE     AS CAT,
         EWMSTOCKTYPENAME AS TXT,
         LANGUAGE         AS LANG
    FROM I_EWM_STOCKTYPETEXT_2
    WHERE EWMWAREHOUSE IN @LR_LGNUM
    INTO TABLE @DATA(LT_TXT).

* Ten theo ngon ngu dang nhap, thieu thi lay ngon ngu khac
  LOOP AT LT_TXT ASSIGNING FIELD-SYMBOL(<LFS_T>).
    READ TABLE LT_VAL ASSIGNING FIELD-SYMBOL(<LFS_V>) WITH KEY CAT = <LFS_T>-CAT.
    IF SY-SUBRC <> 0.
      APPEND VALUE #( CAT = <LFS_T>-CAT TXT = <LFS_T>-TXT ) TO LT_VAL.
    ELSEIF <LFS_T>-LANG = SY-LANGU.
      <LFS_V>-TXT = <LFS_T>-TXT.
    ENDIF.
  ENDLOOP.
  CHECK LT_VAL IS NOT INITIAL.
  SORT LT_VAL BY CAT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      RETFIELD    = 'CAT'
      DYNPPROG    = SY-REPID
      DYNPNR      = SY-DYNNR
      DYNPROFIELD = IV_FIELD
      VALUE_ORG   = 'S'
    TABLES
      VALUE_TAB   = LT_VAL
    EXCEPTIONS
      OTHERS      = 0.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F4_LGORT
*&---------------------------------------------------------------------*
* Search help Storage Location: theo Plant dang nhap (neu co)
FORM F4_LGORT USING IV_FIELD TYPE CLIKE.

  TYPES: BEGIN OF LTY_SL,
           WERKS TYPE WERKS_D,
           LGORT TYPE LGORT_D,
           LGOBE TYPE LGOBE,
         END OF LTY_SL.

  DATA: LV_WERKS TYPE WERKS_D,
        LR_WERKS TYPE RANGE OF WERKS_D,
        LT_SL    TYPE STANDARD TABLE OF LTY_SL WITH EMPTY KEY.

  PERFORM READ_SCREEN_FIELD USING 'S_WERKS-LOW' CHANGING LV_WERKS.
  IF LV_WERKS IS NOT INITIAL.
    LR_WERKS = VALUE #( ( SIGN = 'I' OPTION = 'EQ' LOW = LV_WERKS ) ).
  ENDIF.

  SELECT PLANT               AS WERKS,
         STORAGELOCATION     AS LGORT,
         STORAGELOCATIONNAME AS LGOBE
    FROM I_STORAGELOCATION
    WHERE PLANT IN @LR_WERKS
    ORDER BY PLANT, STORAGELOCATION
    INTO TABLE @LT_SL.
  CHECK LT_SL IS NOT INITIAL.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      RETFIELD    = 'LGORT'
      DYNPPROG    = SY-REPID
      DYNPNR      = SY-DYNNR
      DYNPROFIELD = IV_FIELD
      VALUE_ORG   = 'S'
    TABLES
      VALUE_TAB   = LT_SL
    EXCEPTIONS
      OTHERS      = 0.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F4_HU
*&---------------------------------------------------------------------*
* Search help Handling Unit chuan cua EWM, gioi han theo Warehouse dang nhap
FORM F4_HU USING IV_FIELD TYPE CLIKE.

  DATA: LS_SHLP  TYPE SHLP_DESCR,
        LT_RET   TYPE STANDARD TABLE OF DDSHRETVAL WITH EMPTY KEY,
        LT_DYN   TYPE STANDARD TABLE OF DYNPREAD WITH EMPTY KEY,
        LV_LGNUM TYPE /SCWM/LGNUM,
        LV_RC    TYPE SY-SUBRC.

  PERFORM READ_SCREEN_FIELD USING 'P_LGNUM' CHANGING LV_LGNUM.

  CALL FUNCTION 'F4IF_GET_SHLP_DESCR'
    EXPORTING
      SHLPNAME = '/SCWM/SH_HU'
    IMPORTING
      SHLP     = LS_SHLP.

  IF LV_LGNUM IS NOT INITIAL.
    APPEND VALUE #( SHLPNAME  = LS_SHLP-SHLPNAME
                    SHLPFIELD = 'LGNUM'
                    SIGN      = 'I'
                    OPTION    = 'EQ'
                    LOW       = LV_LGNUM ) TO LS_SHLP-SELOPT.
  ENDIF.

  LOOP AT LS_SHLP-INTERFACE ASSIGNING FIELD-SYMBOL(<LFS_IF>) WHERE SHLPFIELD = 'HUIDENT'.
    <LFS_IF>-F4FIELD = ABAP_TRUE.
  ENDLOOP.

  CALL FUNCTION 'F4IF_START_VALUE_REQUEST'
    EXPORTING
      SHLP          = LS_SHLP
    IMPORTING
      RC            = LV_RC
    TABLES
      RETURN_VALUES = LT_RET.
  CHECK LV_RC = 0 AND LT_RET IS NOT INITIAL.

  LT_DYN = VALUE #( ( FIELDNAME = IV_FIELD FIELDVALUE = LT_RET[ 1 ]-FIELDVAL ) ).
  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      DYNAME     = SY-REPID
      DYNUMB     = SY-DYNNR
    TABLES
      DYNPFIELDS = LT_DYN
    EXCEPTIONS
      OTHERS     = 0.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form MODIFY_SCREEN
*&---------------------------------------------------------------------*
FORM MODIFY_SCREEN.

  LOOP AT SCREEN.
    IF SCREEN-GROUP1 = 'CNV' AND P_CONV IS INITIAL.
      SCREEN-ACTIVE = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_INPUT
*&---------------------------------------------------------------------*
FORM CHECK_INPUT.

  DATA: LV_LGTYP TYPE /SCWM/LGTYP,
        LV_MSEHI TYPE T006-MSEHI,
        LV_OK    TYPE ABAP_BOOL.

  CHECK GV_MAP_ACTIVE IS INITIAL AND SY-UCOMM = 'ONLI'.

  AUTHORITY-CHECK OBJECT '/SCWM/LG'
           ID '/SCWM/LGNU' FIELD P_LGNUM
           ID '/SCWM/LGTY' DUMMY
           ID 'ACTVT'      FIELD '03'.
  IF SY-SUBRC <> 0.
    MESSAGE E001 WITH P_LGNUM.
  ENDIF.

  IF P_CONV = ABAP_TRUE.
    IF P_MEINS IS INITIAL.
      MESSAGE E009.
    ENDIF.
    SELECT SINGLE MSEHI FROM T006 WHERE MSEHI = @P_MEINS INTO @LV_MSEHI.
    IF SY-SUBRC <> 0.
      MESSAGE E010 WITH P_MEINS.
    ENDIF.
  ENDIF.

  IF P_LIST = ABAP_TRUE.
    IF S_LGTYP[] IS INITIAL AND S_LGPLA[] IS INITIAL AND S_MATNR[] IS INITIAL
       AND S_CHARG[] IS INITIAL AND S_HUID[] IS INITIAL.
      MESSAGE E002.
    ENDIF.
  ELSE.
*   So do: dung 1 Storage Type va Storage Type do phai co 1 trong 2 nguon cau truc ma Bin
    IF LINES( S_LGTYP[] ) <> 1 OR S_LGTYP[ 1 ]-SIGN <> 'I' OR S_LGTYP[ 1 ]-OPTION <> 'EQ'.
      MESSAGE E005.
    ENDIF.
    LV_LGTYP = S_LGTYP[ 1 ]-LOW.
    PERFORM HAS_STRUCTURE USING LV_LGTYP CHANGING LV_OK.
    IF LV_OK = ABAP_FALSE.
      MESSAGE E005.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form HAS_STRUCTURE
*&---------------------------------------------------------------------*
* Storage Type duoc dung so do khi co 1 trong 2 nguon cau truc ma Bin:
* Bin tao tu cau truc ma Bin (Aisle / Stack / Level / Bin Section / Depth
* da co gia tri) hoac co dong cau hinh trong ZTWM_BIN_LAYOUT
FORM HAS_STRUCTURE USING    IV_LGTYP TYPE /SCWM/LGTYP
                   CHANGING CV_OK    TYPE ABAP_BOOL.

  DATA: LV_LGTYP TYPE /SCWM/LGTYP,
        LV_BIN   TYPE /SCWM/LGPLA.

  CLEAR CV_OK.

  SELECT SINGLE LGTYP FROM ZTWM_BIN_LAYOUT
    WHERE LGNUM = @P_LGNUM AND LGTYP = @IV_LGTYP
    INTO @LV_LGTYP.
  IF SY-SUBRC = 0.
    CV_OK = ABAP_TRUE.
    RETURN.
  ENDIF.

  SELECT SINGLE EWMSTORAGEBIN FROM I_EWM_STORAGEBIN_2
    WHERE EWMWAREHOUSE                   = @P_LGNUM
      AND EWMSTORAGETYPE                 = @IV_LGTYP
      AND EWMSTORBINFREEDEFINEDAISLETEXT <> ''
      AND EWMSTORBINFREEDEFINEDSTACKTEXT <> ''
      AND EWMSTORBINFREEDEFINEDLEVELTEXT <> ''
      AND EWMSTORBINFREEDFNDSECTIONTEXT  <> ''
      AND EWMSTORAGEBINFREEDFNDDEPTHTEXT <> ''
    INTO @LV_BIN.
  IF SY-SUBRC = 0.
    CV_OK = ABAP_TRUE.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form MAIN
*&---------------------------------------------------------------------*
FORM MAIN.

  PERFORM READ_CONFIG.

  IF P_MAP = ABAP_TRUE.
    PERFORM RUN_MAP.
  ELSE.
    GV_UNIT_CV = COND #( WHEN P_CONV = ABAP_TRUE THEN P_MEINS ).
    PERFORM RUN_LIST.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_CONFIG
*&---------------------------------------------------------------------*
* Cau hinh tach ma Bin, Storage Type trung gian va mui gio cua Warehouse
FORM READ_CONFIG.

  CLEAR: GT_LAY, GR_EXCL, GV_TZ.

  SELECT LGNUM, LGTYP, AISLE_OFF, AISLE_LEN, STACK_OFF, STACK_LEN,
         LEVEL_OFF, LEVEL_LEN, CELL_OFF, CELL_LEN, SLOT_OFF, SLOT_LEN,
         SEP_CHAR, SEP_OFF, LEVEL_DESC, SLOTS_PER_CELL
    FROM ZTWM_BIN_LAYOUT
    WHERE LGNUM = @P_LGNUM
    INTO CORRESPONDING FIELDS OF TABLE @GT_LAY.

  IF P_EXINT = ABAP_TRUE.
    SELECT 'I' AS SIGN, 'EQ' AS OPTION, LGTYP AS LOW
      FROM ZTWM_2D_PARAM
      WHERE LGNUM = @P_LGNUM
      INTO CORRESPONDING FIELDS OF TABLE @GR_EXCL.
  ENDIF.

  SELECT SINGLE TIMEZONEID FROM I_EWM_WAREHOUSENUMBER_2
    WHERE EWMWAREHOUSE = @P_LGNUM
    INTO @GV_TZ.
  IF GV_TZ IS INITIAL.
    GV_TZ = SY-ZONLO.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form RUN_LIST
*&---------------------------------------------------------------------*
* Danh sach ton kho tai Bin
FORM RUN_LIST.

  CLEAR GT_LIST.

  PERFORM LOAD_DATA USING ABAP_FALSE CHANGING GT_LIST.
  PERFORM ENRICH_BASIC CHANGING GT_LIST.

  IF S_WDATU[] IS NOT INITIAL.
    DELETE GT_LIST WHERE WDATE NOT IN S_WDATU.
  ENDIF.
  IF P_LOCK = ABAP_TRUE.
    DELETE GT_LIST WHERE SKZUE <> ABAP_TRUE AND SKZUA <> ABAP_TRUE AND SKZSI <> ABAP_TRUE.
  ENDIF.

  PERFORM ADD_PLANT_SLOC CHANGING GT_LIST.
  IF S_WERKS[] IS NOT INITIAL OR S_LGORT[] IS NOT INITIAL.
    DELETE GT_LIST WHERE WERKS NOT IN S_WERKS OR LGORT NOT IN S_LGORT.
  ENDIF.

  IF GT_LIST IS INITIAL.
    MESSAGE S003.
    RETURN.
  ENDIF.

  PERFORM ENRICH_EXTRA CHANGING GT_LIST.
  SORT GT_LIST BY LGTYP LGPLA MATNR CHARG.

  IF GV_NOT_CONV > 0.
    MESSAGE S006 WITH GV_NOT_CONV GV_UNIT_CV DISPLAY LIKE 'W'.
  ENDIF.

  PERFORM SHOW_LIST.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOAD_DATA
*&---------------------------------------------------------------------*
* Doc ton vat ly (quant) va Bin tu CDS EWM chuan.
* IV_MAP = X: toan bo ton + toan bo Bin cua 1 Storage Type (cho so do);
* IV_MAP = space: theo cac dieu kien tren man hinh chon (cho danh sach).
FORM LOAD_DATA USING    IV_MAP TYPE ABAP_BOOL
               CHANGING CT_OUT TYPE GTT_OUT.

  DATA: LR_LGTYP TYPE GTT_LGTYP,
        LR_MATNR LIKE S_MATNR[],
        LR_CHARG LIKE S_CHARG[],
        LR_CAT   LIKE S_CAT[],
        LR_HUID  LIKE S_HUID[],
        LR_VFDAT LIKE S_VFDAT[],
        LT_KEY   TYPE GTT_KEY,
        LT_HAS   TYPE GTT_KEY.

  CLEAR: CT_OUT, GT_BIN, GT_WT, GT_HUC.

  IF IV_MAP = ABAP_TRUE.
    LR_LGTYP = VALUE #( ( SIGN = 'I' OPTION = 'EQ' LOW = GV_LGTYP_MAP ) ).
  ELSE.
    LR_LGTYP = S_LGTYP[].
    LR_MATNR = S_MATNR[].
    LR_CHARG = S_CHARG[].
    LR_CAT   = S_CAT[].
    LR_HUID  = S_HUID[].
    LR_VFDAT = S_VFDAT[].
  ENDIF.

  SELECT S~EWMSTORAGETYPE                AS LGTYP,
         S~EWMSTORAGESECTION             AS LGBER,
         S~EWMSTORAGEBIN                 AS LGPLA,
         S~HANDLINGUNITNUMBER            AS HUID,
         S~EWMHGHSTLVLHANDLINGUNITNUMBER AS HU_TOP,
         S~STOCKITEMUUID                 AS STOCK_ID,
         S~PRODUCT                       AS MATNR,
         M~MAKTX                         AS MAKTX,
         S~ENTITLEDTODISPOSEPARTY        AS ENTITLED,
         S~EWMSTOCKTYPE                  AS CAT,
         T~EWMSTOCKTYPENAME              AS CAT_TXT,
         CASE WHEN S~STOCKDOCUMENTCATEGORY = 'SOS' THEN 'E'
              WHEN S~STOCKDOCUMENTCATEGORY = 'PJS' THEN 'Q'
              WHEN S~EWMSTOCKOWNER <> ' ' AND S~EWMSTOCKOWNER <> S~ENTITLEDTODISPOSEPARTY THEN 'B'
              ELSE ' ' END               AS STK_USG,
         S~EXTERNALSTOCKDOCUMENTNUMBER   AS STK_NO,
         S~EWMSTOCKOWNER                 AS OWNER,
         S~BATCH                         AS CHARG,
         S~EWMGOODSRECEIPTDATETIME       AS WDATU_TS,
         S~SHELFLIFEEXPIRATIONDATE       AS VFDAT,
         S~EWMSTOCKQUANTITYINBASEUNIT    AS QUAN,
         S~EWMSTOCKQUANTITYBASEUNIT      AS MEINS,
         S~EWMSTORBINISBLOCKEDFORPUTAWAY AS SKZUE,
         S~EWMSTORBINISBLOCKEDFORREMOVAL AS SKZUA,
         S~EWMSTORBINISBLOCKEDDUETOPINV  AS SKZSI
    FROM I_EWM_PHYSSTOCKPROD AS S
    LEFT OUTER JOIN MAKT AS M
      ON  M~MATNR = S~PRODUCT
      AND M~SPRAS = @SY-LANGU
    LEFT OUTER JOIN I_EWM_STOCKTYPETEXT_2 AS T
      ON  T~EWMWAREHOUSE = S~EWMWAREHOUSE
      AND T~EWMSTOCKTYPE = S~EWMSTOCKTYPE
      AND T~LANGUAGE     = @SY-LANGU
    WHERE S~EWMWAREHOUSE            = @P_LGNUM
      AND S~EWMSTORAGETYPE          IN @LR_LGTYP
      AND S~EWMSTORAGETYPE          NOT IN @GR_EXCL
      AND S~EWMSTORAGESECTION       IN @S_LGBER
      AND S~EWMSTORAGEBIN           IN @S_LGPLA
      AND S~PRODUCT                 IN @LR_MATNR
      AND S~BATCH                   IN @LR_CHARG
      AND S~EWMSTOCKTYPE            IN @LR_CAT
      AND S~HANDLINGUNITNUMBER      IN @LR_HUID
      AND S~SHELFLIFEEXPIRATIONDATE IN @LR_VFDAT
    INTO CORRESPONDING FIELDS OF TABLE @CT_OUT.

  IF IV_MAP = ABAP_TRUE.
    PERFORM READ_BINS USING LR_LGTYP.

  ELSEIF P_EMPTY = ABAP_TRUE AND S_MATNR[] IS INITIAL AND S_CHARG[] IS INITIAL
     AND S_CAT[] IS INITIAL AND S_HUID[] IS INITIAL AND S_VFDAT[] IS INITIAL
     AND S_WDATU[] IS INITIAL.
*   Them 1 dong cho moi Bin khong co ton
    PERFORM READ_BINS USING LR_LGTYP.
    LOOP AT CT_OUT ASSIGNING FIELD-SYMBOL(<LFS_O>).
      INSERT VALUE #( LGPLA = <LFS_O>-LGPLA ) INTO TABLE LT_HAS.
    ENDLOOP.
    LOOP AT GT_BIN ASSIGNING FIELD-SYMBOL(<LFS_B>).
      IF NOT LINE_EXISTS( LT_HAS[ LGPLA = <LFS_B>-LGPLA ] ).
        APPEND VALUE #( LGTYP = <LFS_B>-LGTYP
                        LGBER = <LFS_B>-LGBER
                        LGPLA = <LFS_B>-LGPLA ) TO CT_OUT.
      ENDIF.
    ENDLOOP.

  ELSE.
*   Chi doc thuoc tinh cua cac Bin dang co ton
    LOOP AT CT_OUT ASSIGNING <LFS_O>.
      INSERT VALUE #( LGPLA = <LFS_O>-LGPLA ) INTO TABLE LT_KEY.
    ENDLOOP.
    IF LT_KEY IS NOT INITIAL.
      PERFORM READ_BINS_KEYED USING LT_KEY.
    ENDIF.
  ENDIF.

  PERFORM PARSE_BINS.
  PERFORM READ_OPEN_WT USING LR_LGTYP.
  IF IV_MAP = ABAP_TRUE.
    PERFORM READ_HU_CONTENT.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_BINS
*&---------------------------------------------------------------------*
* Doc Bin theo Storage Type / Section / Bin da chon
FORM READ_BINS USING IR_LGTYP TYPE GTT_LGTYP.

  SELECT B~EWMSTORAGEBIN                   AS LGPLA,
         B~EWMSTORAGETYPE                  AS LGTYP,
         B~EWMSTORAGESECTION               AS LGBER,
         B~EWMSTORAGEBINTYPE               AS LPTYP,
         B~EWMSTORBINISBLOCKEDFORPUTAWAY   AS SKZUE,
         B~EWMSTORBINISBLOCKEDFORREMOVAL   AS SKZUA,
         B~EWMSTORBINISBLOCKEDDUETOPINV    AS SKZSI,
         B~EWMSTORAGEBINLASTWAREHOUSETASK  AS BTANR,
         B~EWMSTORAGEBINLASTMVTDATETIME    AS MOVED_AT,
         B~PINVCOUNTEDUTCDATETIME          AS IDATU,
         B~PHYSICALINVENTORYDOCNUMBER      AS PI_DOC,
         B~EWMSTORAGEBINLASTCHANGEDBYUSER  AS CHG_USER,
         B~EWMSTORAGEBINLASTCHGDATETIME    AS CHG_AT,
         B~EWMSTORBINAVAILCAPACITYVALUE    AS CAPA,
         B~EWMSTORBINFREEDEFINEDAISLETEXT  AS AISLE_S,
         B~EWMSTORBINFREEDEFINEDSTACKTEXT  AS STACK_S,
         B~EWMSTORBINFREEDEFINEDLEVELTEXT  AS LEVEL_S,
         B~EWMSTORBINFREEDFNDSECTIONTEXT   AS CELL_S,
         B~EWMSTORAGEBINFREEDFNDDEPTHTEXT  AS SLOT_S
    FROM I_EWM_STORAGEBIN_2 AS B
    WHERE B~EWMWAREHOUSE      = @P_LGNUM
      AND B~EWMSTORAGETYPE    IN @IR_LGTYP
      AND B~EWMSTORAGETYPE    NOT IN @GR_EXCL
      AND B~EWMSTORAGESECTION IN @S_LGBER
      AND B~EWMSTORAGEBIN     IN @S_LGPLA
    INTO CORRESPONDING FIELDS OF TABLE @GT_BIN.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_BINS_KEYED
*&---------------------------------------------------------------------*
* Doc Bin cua cac Bin da co trong ket qua
FORM READ_BINS_KEYED USING IT_KEY TYPE GTT_KEY.

  SELECT B~EWMSTORAGEBIN                   AS LGPLA,
         B~EWMSTORAGETYPE                  AS LGTYP,
         B~EWMSTORAGESECTION               AS LGBER,
         B~EWMSTORAGEBINTYPE               AS LPTYP,
         B~EWMSTORBINISBLOCKEDFORPUTAWAY   AS SKZUE,
         B~EWMSTORBINISBLOCKEDFORREMOVAL   AS SKZUA,
         B~EWMSTORBINISBLOCKEDDUETOPINV    AS SKZSI,
         B~EWMSTORAGEBINLASTWAREHOUSETASK  AS BTANR,
         B~EWMSTORAGEBINLASTMVTDATETIME    AS MOVED_AT,
         B~PINVCOUNTEDUTCDATETIME          AS IDATU,
         B~PHYSICALINVENTORYDOCNUMBER      AS PI_DOC,
         B~EWMSTORAGEBINLASTCHANGEDBYUSER  AS CHG_USER,
         B~EWMSTORAGEBINLASTCHGDATETIME    AS CHG_AT,
         B~EWMSTORBINAVAILCAPACITYVALUE    AS CAPA,
         B~EWMSTORBINFREEDEFINEDAISLETEXT  AS AISLE_S,
         B~EWMSTORBINFREEDEFINEDSTACKTEXT  AS STACK_S,
         B~EWMSTORBINFREEDEFINEDLEVELTEXT  AS LEVEL_S,
         B~EWMSTORBINFREEDFNDSECTIONTEXT   AS CELL_S,
         B~EWMSTORAGEBINFREEDFNDDEPTHTEXT  AS SLOT_S
    FROM @IT_KEY AS K
    INNER JOIN I_EWM_STORAGEBIN_2 AS B
      ON  B~EWMWAREHOUSE  = @P_LGNUM
      AND B~EWMSTORAGEBIN = K~LGPLA
    INTO CORRESPONDING FIELDS OF TABLE @GT_BIN.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PARSE_BINS
*&---------------------------------------------------------------------*
* Dat Day / Ke / Tang / O / Vi tri cho tung Bin: uu tien cac truong chuan cua
* Storage Bin, neu thieu thi tach ma Bin theo cau hinh Storage Type
FORM PARSE_BINS.

  LOOP AT GT_BIN ASSIGNING FIELD-SYMBOL(<LFS_B>).
    PERFORM PARSE_STD_BIN CHANGING <LFS_B>.
    IF <LFS_B>-PLACED = ABAP_FALSE.
      READ TABLE GT_LAY ASSIGNING FIELD-SYMBOL(<LFS_L>)
           WITH TABLE KEY LGNUM = P_LGNUM LGTYP = <LFS_B>-LGTYP.
      IF SY-SUBRC = 0.
        PERFORM PARSE_ONE_BIN USING <LFS_L> CHANGING <LFS_B>.
      ENDIF.
    ENDIF.
    PERFORM LOCK_DESC CHANGING <LFS_B>.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PARSE_STD_BIN
*&---------------------------------------------------------------------*
* Doc vi tri tu cac truong chuan Aisle / Stack / Level / Bin Section / Depth.
* Thieu truong nao, hoac Tang / O / Vi tri khong phai so: de PLACED rong
FORM PARSE_STD_BIN CHANGING CS_BIN TYPE GTY_BIN.

  DATA: LV_AISLE TYPE STRING,
        LV_STACK TYPE STRING,
        LV_LEVEL TYPE STRING,
        LV_CELL  TYPE STRING,
        LV_SLOT  TYPE STRING.

  LV_AISLE = CS_BIN-AISLE_S.
  LV_STACK = CS_BIN-STACK_S.
  LV_LEVEL = CS_BIN-LEVEL_S.
  LV_CELL  = CS_BIN-CELL_S.
  LV_SLOT  = CS_BIN-SLOT_S.
  CONDENSE: LV_AISLE, LV_STACK, LV_LEVEL, LV_CELL, LV_SLOT.

  IF LV_AISLE IS INITIAL OR LV_STACK IS INITIAL OR LV_LEVEL IS INITIAL
     OR LV_CELL IS INITIAL OR LV_SLOT IS INITIAL.
    RETURN.
  ENDIF.
  IF LV_LEVEL CN '0123456789' OR LV_CELL CN '0123456789' OR LV_SLOT CN '0123456789'.
    RETURN.
  ENDIF.
  IF STRLEN( LV_AISLE ) > 8 OR STRLEN( LV_STACK ) > 8
     OR STRLEN( LV_LEVEL ) > 3 OR STRLEN( LV_CELL ) > 3 OR STRLEN( LV_SLOT ) > 3.
    RETURN.
  ENDIF.

  CS_BIN-AISLE  = LV_AISLE.
  CS_BIN-STACK  = LV_STACK.
  CS_BIN-BLOCK  = |{ LV_AISLE }{ LV_STACK }|.
  CS_BIN-LEVEL  = LV_LEVEL.
  CS_BIN-CELL   = LV_CELL.
  CS_BIN-SLOT   = LV_SLOT.
  CS_BIN-PLACED = ABAP_TRUE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOCK_DESC
*&---------------------------------------------------------------------*
* Dien giai khoa cua Bin: sinh tu cac co khoa (chuan EWM khong luu ly do),
* kem nguoi va thoi diem thay doi gan nhat cua Bin
FORM LOCK_DESC CHANGING CS_BIN TYPE GTY_BIN.

  DATA LV_TXT TYPE STRING.

  IF CS_BIN-CHG_AT IS NOT INITIAL.
    CONVERT TIME STAMP CS_BIN-CHG_AT TIME ZONE GV_TZ
            INTO DATE CS_BIN-CHG_DATE TIME CS_BIN-CHG_TIME.
  ENDIF.

  PERFORM LOCK_PHRASE USING CS_BIN-SKZUE CS_BIN-SKZUA CS_BIN-SKZSI CS_BIN-PI_DOC
                      CHANGING LV_TXT.
  CHECK LV_TXT IS NOT INITIAL.

  IF CS_BIN-CHG_USER IS NOT INITIAL.
    LV_TXT = |{ LV_TXT } - { CS_BIN-CHG_USER }|.
    IF CS_BIN-CHG_DATE IS NOT INITIAL.
      LV_TXT = |{ LV_TXT } { CS_BIN-CHG_DATE DATE = USER } { CS_BIN-CHG_TIME TIME = USER }|.
    ENDIF.
  ENDIF.

  CS_BIN-LOCK_TXT = LV_TXT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PARSE_ONE_BIN
*&---------------------------------------------------------------------*
* Ma khong dung cau truc: de PLACED rong, Bin khong len so do
FORM PARSE_ONE_BIN USING    IS_LAY TYPE ZTWM_BIN_LAYOUT
                   CHANGING CS_BIN TYPE GTY_BIN.

* Vi tri bat dau cua Ke nhap chu (khong phai so) thi khong tach duoc ma Bin
  IF IS_LAY-STACK_OFF CN ' 0123456789'.
    RETURN.
  ENDIF.

  DATA(LV_AISLE) = LCL_UTIL=>PART( IV_BIN = CS_BIN-LGPLA IV_OFF = CONV #( IS_LAY-AISLE_OFF ) IV_LEN = CONV #( IS_LAY-AISLE_LEN ) ).
  DATA(LV_STACK) = LCL_UTIL=>PART( IV_BIN = CS_BIN-LGPLA IV_OFF = CONV #( IS_LAY-STACK_OFF ) IV_LEN = CONV #( IS_LAY-STACK_LEN ) ).
  DATA(LV_LEVEL) = LCL_UTIL=>PART( IV_BIN = CS_BIN-LGPLA IV_OFF = CONV #( IS_LAY-LEVEL_OFF ) IV_LEN = CONV #( IS_LAY-LEVEL_LEN ) ).
  DATA(LV_CELL)  = LCL_UTIL=>PART( IV_BIN = CS_BIN-LGPLA IV_OFF = CONV #( IS_LAY-CELL_OFF )  IV_LEN = CONV #( IS_LAY-CELL_LEN ) ).
  DATA(LV_SLOT)  = LCL_UTIL=>PART( IV_BIN = CS_BIN-LGPLA IV_OFF = CONV #( IS_LAY-SLOT_OFF )  IV_LEN = CONV #( IS_LAY-SLOT_LEN ) ).

  IF LV_AISLE IS INITIAL OR LV_STACK IS INITIAL OR LV_LEVEL IS INITIAL
     OR LV_CELL IS INITIAL OR LV_SLOT IS INITIAL.
    RETURN.
  ENDIF.
  IF LV_LEVEL CN '0123456789' OR LV_CELL CN '0123456789' OR LV_SLOT CN '0123456789'.
    RETURN.
  ENDIF.

* Ky tu phan cach phai dung vi tri khai bao
  IF IS_LAY-SEP_CHAR IS NOT INITIAL AND IS_LAY-SEP_OFF > 0.
    IF LCL_UTIL=>PART( IV_BIN = CS_BIN-LGPLA IV_OFF = CONV #( IS_LAY-SEP_OFF ) IV_LEN = 1 )
       <> CONV string( IS_LAY-SEP_CHAR ).
      RETURN.
    ENDIF.
  ENDIF.

  CS_BIN-AISLE  = LV_AISLE.
  CS_BIN-STACK  = LV_STACK.
  CS_BIN-BLOCK  = |{ LV_AISLE }{ LV_STACK }|.
  CS_BIN-LEVEL  = LV_LEVEL.
  CS_BIN-CELL   = LV_CELL.
  CS_BIN-SLOT   = LV_SLOT.
  CS_BIN-PLACED = ABAP_TRUE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ENRICH_BASIC
*&---------------------------------------------------------------------*
* Bo sung thuoc tinh Bin, ngay gio theo mui gio Warehouse, den trang thai,
* SL dang pick / Cho putaway / Kha dung tu Warehouse Task dang mo
FORM ENRICH_BASIC CHANGING CT_OUT TYPE GTT_OUT.

  LOOP AT CT_OUT ASSIGNING FIELD-SYMBOL(<LFS_O>).
    PERFORM ENRICH_ROW CHANGING <LFS_O>.
  ENDLOOP.

  PERFORM APPLY_WT CHANGING CT_OUT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ENRICH_ROW
*&---------------------------------------------------------------------*
FORM ENRICH_ROW CHANGING CS_OUT TYPE GTY_OUT.

  READ TABLE GT_BIN ASSIGNING FIELD-SYMBOL(<LFS_B>) WITH TABLE KEY LGPLA = CS_OUT-LGPLA.
  IF SY-SUBRC = 0.
    CS_OUT-LPTYP    = <LFS_B>-LPTYP.
    CS_OUT-CAPA     = <LFS_B>-CAPA.
    CS_OUT-AISLE    = <LFS_B>-AISLE.
    CS_OUT-STACK    = <LFS_B>-STACK.
    CS_OUT-LEVEL    = <LFS_B>-LEVEL.
    CS_OUT-CELL     = <LFS_B>-CELL.
    CS_OUT-SLOT     = <LFS_B>-SLOT.
    CS_OUT-SKZUE    = <LFS_B>-SKZUE.
    CS_OUT-SKZUA    = <LFS_B>-SKZUA.
    CS_OUT-SKZSI    = <LFS_B>-SKZSI.
    CS_OUT-LOCK_TXT = <LFS_B>-LOCK_TXT.
    CS_OUT-CHG_USER = <LFS_B>-CHG_USER.
    CS_OUT-CHG_DATE = <LFS_B>-CHG_DATE.
    CS_OUT-CHG_TIME = <LFS_B>-CHG_TIME.
    CS_OUT-BTANR    = <LFS_B>-BTANR.
    IF <LFS_B>-IDATU IS NOT INITIAL.
      CONVERT TIME STAMP <LFS_B>-IDATU TIME ZONE GV_TZ INTO DATE CS_OUT-IDATE.
    ENDIF.
    IF <LFS_B>-MOVED_AT IS NOT INITIAL.
      CONVERT TIME STAMP <LFS_B>-MOVED_AT TIME ZONE GV_TZ
              INTO DATE CS_OUT-MV_DATE TIME CS_OUT-MV_TIME.
    ENDIF.
  ENDIF.

  IF CS_OUT-WDATU_TS IS NOT INITIAL.
    CONVERT TIME STAMP CS_OUT-WDATU_TS TIME ZONE GV_TZ INTO DATE CS_OUT-WDATE.
    CS_OUT-AGE = SY-DATUM - CS_OUT-WDATE.
  ENDIF.

* Den: do = khoa nhap/xuat, vang = khoa kiem ke, xanh = co ton, xam = trong
  IF CS_OUT-SKZUE = ABAP_TRUE OR CS_OUT-SKZUA = ABAP_TRUE.
    CS_OUT-ICON = ICON_RED_LIGHT.
  ELSEIF CS_OUT-SKZSI = ABAP_TRUE.
    CS_OUT-ICON = ICON_YELLOW_LIGHT.
  ELSEIF CS_OUT-MATNR IS NOT INITIAL.
    CS_OUT-ICON = ICON_GREEN_LIGHT.
  ELSE.
    CS_OUT-ICON = ICON_LIGHT_OUT.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_OPEN_WT
*&---------------------------------------------------------------------*
* Warehouse Task chua xac nhan co Bin nguon hoac Bin dich thuoc pham vi:
* dung tinh SL dang pick (Bin nguon) va Cho putaway (Bin dich)
FORM READ_OPEN_WT USING IR_LGTYP TYPE GTT_LGTYP.

  CLEAR GT_WT.

  SELECT W~ISHANDLINGUNITWAREHOUSETASK AS FLG_HU,
         W~STOCKITEMUUID               AS STOCK_ID,
         W~PRODUCTNAME                 AS MATNR,
         M~MAKTX                       AS MAKTX,
         W~BATCH                       AS CHARG,
         W~ENTITLEDTODISPOSEPARTY      AS ENTITLED,
         W~EWMSTOCKTYPE                AS CAT,
         T~EWMSTOCKTYPENAME            AS CAT_TXT,
         CASE WHEN W~STOCKDOCUMENTCATEGORY = 'SOS' THEN 'E'
              WHEN W~STOCKDOCUMENTCATEGORY = 'PJS' THEN 'Q'
              WHEN W~EWMSTOCKOWNER <> ' ' AND W~EWMSTOCKOWNER <> W~ENTITLEDTODISPOSEPARTY THEN 'B'
              ELSE ' ' END               AS STK_USG,
         W~EWMSTOCKOWNER               AS OWNER,
         W~SOURCESTORAGEBIN            AS SRC_BIN,
         W~SOURCEHANDLINGUNIT          AS SRC_HU,
         W~DESTINATIONSTORAGEBIN       AS DST_BIN,
         W~DESTINATIONHANDLINGUNIT     AS DST_HU,
         W~TARGETQUANTITYINBASEUNIT    AS QTY,
         W~BASEUNIT                    AS MEINS
    FROM I_EWM_OPENWAREHOUSETASKS_2 AS W
    LEFT OUTER JOIN MAKT AS M
      ON  M~MATNR = W~PRODUCTNAME
      AND M~SPRAS = @SY-LANGU
    LEFT OUTER JOIN I_EWM_STOCKTYPETEXT_2 AS T
      ON  T~EWMWAREHOUSE = W~EWMWAREHOUSE
      AND T~EWMSTOCKTYPE = W~EWMSTOCKTYPE
      AND T~LANGUAGE     = @SY-LANGU
    WHERE W~EWMWAREHOUSE        = @P_LGNUM
      AND W~WAREHOUSETASKSTATUS <> 'A'
      AND W~WAREHOUSETASKSTATUS <> 'C'
      AND ( W~SOURCESTORAGETYPE      IN @IR_LGTYP
         OR W~DESTINATIONSTORAGETYPE IN @IR_LGTYP )
    INTO CORRESPONDING FIELDS OF TABLE @GT_WT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form READ_HU_CONTENT
*&---------------------------------------------------------------------*
* WT theo HU khong mang thong tin ton: doc noi dung cua cac HU dang ve Bin
* cua Storage Type dang xem (HU dang nam o Bin khac)
FORM READ_HU_CONTENT.

  TYPES: BEGIN OF LTY_HU,
           HUID TYPE I_EWM_PHYSSTOCKPROD-HANDLINGUNITNUMBER,
         END OF LTY_HU.

  DATA: LT_HU TYPE SORTED TABLE OF LTY_HU WITH UNIQUE KEY HUID,
        LR_HU TYPE RANGE OF I_EWM_PHYSSTOCKPROD-HANDLINGUNITNUMBER,
        LV_HU TYPE I_EWM_PHYSSTOCKPROD-HANDLINGUNITNUMBER.

  CLEAR GT_HUC.

  LOOP AT GT_WT ASSIGNING FIELD-SYMBOL(<LFS_W>)
       WHERE FLG_HU = ABAP_TRUE AND DST_BIN IS NOT INITIAL.
    CHECK LINE_EXISTS( GT_BIN[ LGPLA = <LFS_W>-DST_BIN ] ).
    LV_HU = COND #( WHEN <LFS_W>-DST_HU IS NOT INITIAL THEN <LFS_W>-DST_HU ELSE <LFS_W>-SRC_HU ).
    CHECK LV_HU IS NOT INITIAL.
    INSERT VALUE #( HUID = LV_HU ) INTO TABLE LT_HU.
  ENDLOOP.
  CHECK LT_HU IS NOT INITIAL.

  LR_HU = VALUE #( FOR LS_HU IN LT_HU ( SIGN = 'I' OPTION = 'EQ' LOW = LS_HU-HUID ) ).

  SELECT S~HANDLINGUNITNUMBER            AS HUID,
         S~EWMHGHSTLVLHANDLINGUNITNUMBER AS HU_TOP,
         S~STOCKITEMUUID                 AS STOCK_ID,
         S~PRODUCT                       AS MATNR,
         M~MAKTX                         AS MAKTX,
         S~ENTITLEDTODISPOSEPARTY        AS ENTITLED,
         S~EWMSTOCKTYPE                  AS CAT,
         T~EWMSTOCKTYPENAME              AS CAT_TXT,
         CASE WHEN S~STOCKDOCUMENTCATEGORY = 'SOS' THEN 'E'
              WHEN S~STOCKDOCUMENTCATEGORY = 'PJS' THEN 'Q'
              WHEN S~EWMSTOCKOWNER <> ' ' AND S~EWMSTOCKOWNER <> S~ENTITLEDTODISPOSEPARTY THEN 'B'
              ELSE ' ' END               AS STK_USG,
         S~EXTERNALSTOCKDOCUMENTNUMBER   AS STK_NO,
         S~EWMSTOCKOWNER                 AS OWNER,
         S~BATCH                         AS CHARG,
         S~SHELFLIFEEXPIRATIONDATE       AS VFDAT,
         S~EWMSTOCKQUANTITYINBASEUNIT    AS QUAN,
         S~EWMSTOCKQUANTITYBASEUNIT      AS MEINS
    FROM I_EWM_PHYSSTOCKPROD AS S
    LEFT OUTER JOIN MAKT AS M
      ON  M~MATNR = S~PRODUCT
      AND M~SPRAS = @SY-LANGU
    LEFT OUTER JOIN I_EWM_STOCKTYPETEXT_2 AS T
      ON  T~EWMWAREHOUSE = S~EWMWAREHOUSE
      AND T~EWMSTOCKTYPE = S~EWMSTOCKTYPE
      AND T~LANGUAGE     = @SY-LANGU
    WHERE S~EWMWAREHOUSE = @P_LGNUM
      AND ( S~HANDLINGUNITNUMBER            IN @LR_HU
         OR S~EWMHGHSTLVLHANDLINGUNITNUMBER IN @LR_HU )
    INTO CORRESPONDING FIELDS OF TABLE @GT_HUC.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form APPLY_WT
*&---------------------------------------------------------------------*
* Cong WT dang mo vao dong ton: SL dang pick (Bin nguon, giu cho lenh xuat),
* Cho putaway (Bin dich, chua nam trong ton vat ly nen khong cong vao Tong ton),
* Kha dung = Tong ton - SL dang pick.
* WT theo vat tu khop theo (Bin, ton, HU); WT theo HU lay ca HU (khong co SL rieng)
FORM APPLY_WT CHANGING CT_OUT TYPE GTT_OUT.

  LOOP AT GT_WT ASSIGNING FIELD-SYMBOL(<LFS_W>).

*   WT theo vat tu ma khong co ma ton (stock item) thi khong khop duoc dong ton nao
    IF <LFS_W>-FLG_HU = ABAP_FALSE AND <LFS_W>-STOCK_ID IS INITIAL.
      CONTINUE.
    ENDIF.

    IF <LFS_W>-SRC_BIN IS NOT INITIAL.
      LOOP AT CT_OUT ASSIGNING FIELD-SYMBOL(<LFS_R>) USING KEY K_BIN
           WHERE LGPLA = <LFS_W>-SRC_BIN.
        IF <LFS_W>-FLG_HU = ABAP_FALSE.
          CHECK <LFS_R>-STOCK_ID = <LFS_W>-STOCK_ID AND <LFS_R>-HUID = <LFS_W>-SRC_HU.
          <LFS_R>-PICK_QTY = <LFS_R>-PICK_QTY + <LFS_W>-QTY.
        ELSEIF <LFS_W>-SRC_HU IS NOT INITIAL.
          CHECK <LFS_R>-HUID = <LFS_W>-SRC_HU OR <LFS_R>-HU_TOP = <LFS_W>-SRC_HU.
          <LFS_R>-PICK_QTY = <LFS_R>-PICK_QTY + <LFS_R>-QUAN.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF <LFS_W>-DST_BIN IS NOT INITIAL AND <LFS_W>-FLG_HU = ABAP_FALSE.
      LOOP AT CT_OUT ASSIGNING <LFS_R> USING KEY K_BIN
           WHERE LGPLA = <LFS_W>-DST_BIN.
        CHECK <LFS_R>-STOCK_ID = <LFS_W>-STOCK_ID AND <LFS_R>-HUID = <LFS_W>-DST_HU.
        <LFS_R>-WAIT_IN = <LFS_R>-WAIT_IN + <LFS_W>-QTY.
      ENDLOOP.
    ENDIF.

  ENDLOOP.

  LOOP AT CT_OUT ASSIGNING <LFS_R>.
    <LFS_R>-AVAIL = <LFS_R>-QUAN - <LFS_R>-PICK_QTY.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_PENDING_ROWS
*&---------------------------------------------------------------------*
* Hang dang ve Bin nay (WT chua xac nhan) ma chua co dong ton khop:
* them dong rieng (Tong ton = 0, chi co Cho putaway) vao ALV o dang chon
FORM ADD_PENDING_ROWS USING    IV_BIN  TYPE /SCWM/LGPLA
                      CHANGING CT_VIEW TYPE GTT_OUT.

  DATA: LS_ROW TYPE GTY_OUT,
        LV_HU  TYPE I_EWM_PHYSSTOCKPROD-HANDLINGUNITNUMBER.

  READ TABLE GT_CELL ASSIGNING FIELD-SYMBOL(<LFS_C>) WITH TABLE KEY LGPLA = IV_BIN.
  CHECK SY-SUBRC = 0.
  READ TABLE GT_BIN ASSIGNING FIELD-SYMBOL(<LFS_B>) WITH TABLE KEY LGPLA = IV_BIN.
  CHECK SY-SUBRC = 0.

  LOOP AT GT_WT ASSIGNING FIELD-SYMBOL(<LFS_W>) WHERE DST_BIN = IV_BIN.

    IF <LFS_W>-FLG_HU = ABAP_FALSE.
*     Da co dong ton khop (Bin, ton, HU): APPLY_WT da cong; dong cho da them thi cong don
      READ TABLE CT_VIEW ASSIGNING FIELD-SYMBOL(<LFS_V>)
           WITH KEY STOCK_ID = <LFS_W>-STOCK_ID HUID = <LFS_W>-DST_HU.
      IF SY-SUBRC = 0.
        IF <LFS_V>-QUAN = 0.
          <LFS_V>-WAIT_IN = <LFS_V>-WAIT_IN + <LFS_W>-QTY.
        ENDIF.
        CONTINUE.
      ENDIF.

      CLEAR LS_ROW.
      LS_ROW-HUID     = <LFS_W>-DST_HU.
      LS_ROW-STOCK_ID = <LFS_W>-STOCK_ID.
      LS_ROW-MATNR    = <LFS_W>-MATNR.
      LS_ROW-MAKTX    = <LFS_W>-MAKTX.
      LS_ROW-ENTITLED = <LFS_W>-ENTITLED.
      LS_ROW-CAT      = <LFS_W>-CAT.
      LS_ROW-CAT_TXT  = <LFS_W>-CAT_TXT.
      LS_ROW-STK_USG  = <LFS_W>-STK_USG.
      LS_ROW-OWNER    = <LFS_W>-OWNER.
      LS_ROW-CHARG    = <LFS_W>-CHARG.
      LS_ROW-MEINS    = <LFS_W>-MEINS.
      LS_ROW-WAIT_IN  = <LFS_W>-QTY.
      PERFORM FINISH_PENDING USING <LFS_B> <LFS_C> CHANGING LS_ROW.
      APPEND LS_ROW TO CT_VIEW.

    ELSE.
      LV_HU = COND #( WHEN <LFS_W>-DST_HU IS NOT INITIAL THEN <LFS_W>-DST_HU ELSE <LFS_W>-SRC_HU ).
      CHECK LV_HU IS NOT INITIAL.

      LOOP AT GT_HUC ASSIGNING FIELD-SYMBOL(<LFS_H>) WHERE HUID = LV_HU OR HU_TOP = LV_HU.
        READ TABLE CT_VIEW ASSIGNING <LFS_V>
             WITH KEY STOCK_ID = <LFS_H>-STOCK_ID HUID = <LFS_H>-HUID.
        IF SY-SUBRC = 0.
          IF <LFS_V>-QUAN = 0.
            <LFS_V>-WAIT_IN = <LFS_V>-WAIT_IN + <LFS_H>-QUAN.
          ENDIF.
          CONTINUE.
        ENDIF.

        CLEAR LS_ROW.
        LS_ROW-HUID     = <LFS_H>-HUID.
        LS_ROW-STOCK_ID = <LFS_H>-STOCK_ID.
        LS_ROW-MATNR    = <LFS_H>-MATNR.
        LS_ROW-MAKTX    = <LFS_H>-MAKTX.
        LS_ROW-ENTITLED = <LFS_H>-ENTITLED.
        LS_ROW-CAT      = <LFS_H>-CAT.
        LS_ROW-CAT_TXT  = <LFS_H>-CAT_TXT.
        LS_ROW-STK_USG  = <LFS_H>-STK_USG.
        LS_ROW-STK_NO   = <LFS_H>-STK_NO.
        LS_ROW-OWNER    = <LFS_H>-OWNER.
        LS_ROW-CHARG    = <LFS_H>-CHARG.
        LS_ROW-VFDAT    = <LFS_H>-VFDAT.
        LS_ROW-MEINS    = <LFS_H>-MEINS.
        LS_ROW-WAIT_IN  = <LFS_H>-QUAN.
        PERFORM FINISH_PENDING USING <LFS_B> <LFS_C> CHANGING LS_ROW.
        APPEND LS_ROW TO CT_VIEW.
      ENDLOOP.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FINISH_PENDING
*&---------------------------------------------------------------------*
* Gan Bin, thuoc tinh Bin va den trang thai cho dong "dang ve"
FORM FINISH_PENDING USING    IS_BIN  TYPE GTY_BIN
                             IS_CELL TYPE GTY_CELL
                    CHANGING CS_ROW  TYPE GTY_OUT.

  DATA LV_ST TYPE C LENGTH 1.

  CS_ROW-LGTYP = IS_BIN-LGTYP.
  CS_ROW-LGBER = IS_BIN-LGBER.
  CS_ROW-LGPLA = IS_BIN-LGPLA.
  PERFORM ENRICH_ROW CHANGING CS_ROW.

  PERFORM CELL_STATUS USING IS_CELL CHANGING LV_ST.
  CS_ROW-ICON = SWITCH #( LV_ST WHEN 'L' THEN ICON_RED_LIGHT
                                WHEN 'K' THEN ICON_YELLOW_LIGHT
                                WHEN 'F' THEN ICON_GREEN_LIGHT
                                ELSE ICON_LIGHT_OUT ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_PLANT_SLOC
*&---------------------------------------------------------------------*
* Plant / SLoc cua dong ton: dung API chuan cua EWM (khong tu doc bang cau hinh),
* tu Warehouse + Party entitled + Stock Type. Moi cap chi goi 1 lan; khong ra
* ket qua (chua cau hinh anh xa ERP - EWM) thi de trong
FORM ADD_PLANT_SLOC CHANGING CT_OUT TYPE GTT_OUT.

  DATA: LO_MAP   TYPE REF TO /SCWM/IF_STOCKID_MAPPING,
        LV_ENT   TYPE /SCWM/DE_ENTITLED,
        LV_CAT   TYPE /SCWM/DE_CAT,
        LV_PLANT TYPE WERKS_D,
        LV_SLOC  TYPE LGORT_D,
        LV_BESTQ TYPE BESTQ.

  LOOP AT CT_OUT ASSIGNING FIELD-SYMBOL(<LFS_O>)
       WHERE ENTITLED IS NOT INITIAL AND CAT IS NOT INITIAL.

    READ TABLE GT_PLSL ASSIGNING FIELD-SYMBOL(<LFS_P>)
         WITH TABLE KEY LGNUM = P_LGNUM ENTITLED = <LFS_O>-ENTITLED CAT = <LFS_O>-CAT.
    IF SY-SUBRC <> 0.
      IF LO_MAP IS NOT BOUND.
        CALL FUNCTION '/SCWM/GET_STOCKID_MAP_INSTANCE'
          IMPORTING
            EIF_STOCKID_MAPPING = LO_MAP.
      ENDIF.

      CLEAR: LV_PLANT, LV_SLOC, LV_BESTQ.
      IF LO_MAP IS BOUND.
        LV_ENT = <LFS_O>-ENTITLED.
        LV_CAT = <LFS_O>-CAT.
        TRY.
            LO_MAP->GET_ERP_STLOC( EXPORTING IV_LGNUM         = P_LGNUM
                                             IV_ENTITLED      = LV_ENT
                                             IV_CAT           = LV_CAT
                                   IMPORTING EV_ERP_PLANT     = LV_PLANT
                                             EV_ERP_STLOC     = LV_SLOC
                                             EV_ERP_STOCK_CAT = LV_BESTQ ).
          CATCH /SCWM/CX_STOCKID_MAP.
            CLEAR: LV_PLANT, LV_SLOC.
        ENDTRY.
      ENDIF.

      INSERT VALUE #( LGNUM    = P_LGNUM
                      ENTITLED = <LFS_O>-ENTITLED
                      CAT      = <LFS_O>-CAT
                      WERKS    = LV_PLANT
                      LGORT    = LV_SLOC ) INTO TABLE GT_PLSL ASSIGNING <LFS_P>.
    ENDIF.

    <LFS_O>-WERKS = <LFS_P>-WERKS.
    <LFS_O>-LGORT = <LFS_P>-LGORT.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ENRICH_EXTRA
*&---------------------------------------------------------------------*
* Phan ton kem hon, chi lam cho tap dong se hien thi
FORM ENRICH_EXTRA CHANGING CT_OUT TYPE GTT_OUT.

  IF P_BATCH = ABAP_TRUE.
    PERFORM ADD_BATCH_ATTR CHANGING CT_OUT.
  ENDIF.
  PERFORM ADD_UOM_CONV CHANGING CT_OUT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_BATCH_ATTR
*&---------------------------------------------------------------------*
* Ngay kiem nghiem lai, so lo NSX (Z_BATCH_NSX, trong thi lay LICHA), NSX (Z_NSX)
FORM ADD_BATCH_ATTR CHANGING CT_OUT TYPE GTT_OUT.

  DATA: LT_NEW   TYPE GTT_BKEY,
        LT_MCHA  TYPE STANDARD TABLE OF GTY_BATCH WITH EMPTY KEY,
        LT_ATNAM TYPE STANDARD TABLE OF ZCORE_ST_RSELOPTION_ATNAM,
        LS_ATNAM TYPE ZCORE_ST_RSELOPTION_ATNAM,
        LT_CHAR  TYPE STANDARD TABLE OF BAPI1003_ALLOC_VALUES_CHAR,
        LS_CHAR  TYPE BAPI1003_ALLOC_VALUES_CHAR,
        LS_BATCH TYPE GTY_BATCH,
        LV_NUM   TYPE CHAR10,
        LV_NAME  TYPE CHAR255.

* Cac lo chua co trong bo nho dem
  LOOP AT CT_OUT ASSIGNING FIELD-SYMBOL(<LFS_O>) WHERE CHARG IS NOT INITIAL.
    IF NOT LINE_EXISTS( GT_BATCH[ MATNR = <LFS_O>-MATNR CHARG = <LFS_O>-CHARG ] ).
      INSERT VALUE #( MATNR = <LFS_O>-MATNR CHARG = <LFS_O>-CHARG ) INTO TABLE LT_NEW.
    ENDIF.
  ENDLOOP.

  IF LT_NEW IS NOT INITIAL.
    SELECT K~MATNR, K~CHARG,
           MIN( C~WERKS ) AS WERKS,
           MIN( C~QNDAT ) AS QNDAT,
           MIN( C~LICHA ) AS LICHA
      FROM @LT_NEW AS K
      INNER JOIN MCHA AS C ON C~MATNR = K~MATNR AND C~CHARG = K~CHARG
      GROUP BY K~MATNR, K~CHARG
      INTO CORRESPONDING FIELDS OF TABLE @LT_MCHA.

    LS_ATNAM-SIGN   = 'I'.
    LS_ATNAM-OPTION = 'EQ'.
    LS_ATNAM-LOW    = 'Z_NSX'.
    APPEND LS_ATNAM TO LT_ATNAM.
    LS_ATNAM-LOW    = 'Z_BATCH_NSX'.
    APPEND LS_ATNAM TO LT_ATNAM.

    LOOP AT LT_NEW ASSIGNING FIELD-SYMBOL(<LFS_K>).
      CLEAR: LS_BATCH, LT_CHAR.
      LS_BATCH-MATNR = <LFS_K>-MATNR.
      LS_BATCH-CHARG = <LFS_K>-CHARG.
      READ TABLE LT_MCHA ASSIGNING FIELD-SYMBOL(<LFS_M>)
           WITH KEY MATNR = <LFS_K>-MATNR CHARG = <LFS_K>-CHARG.
      IF SY-SUBRC = 0.
        LS_BATCH-WERKS = <LFS_M>-WERKS.
        LS_BATCH-QNDAT = <LFS_M>-QNDAT.
        LS_BATCH-LICHA = <LFS_M>-LICHA.
      ENDIF.

      IF LS_BATCH-WERKS IS NOT INITIAL.
        CALL FUNCTION 'ZCORE_FM_GET_CRTRT_MULTIVAL'
          EXPORTING
            I_MATNR    = LS_BATCH-MATNR
            I_CHARG    = LS_BATCH-CHARG
            I_WERKS    = LS_BATCH-WERKS
            I_KLART    = '023'
          TABLES
            IT_ATNAM   = LT_ATNAM
            IT_CHARACT = LT_CHAR.

        READ TABLE LT_CHAR INTO LS_CHAR WITH KEY CHARACT = 'Z_BATCH_NSX'.
        IF SY-SUBRC = 0.
          LS_BATCH-NSX_LOT = LS_CHAR-VALUE_CHAR.
        ENDIF.
        READ TABLE LT_CHAR INTO LS_CHAR WITH KEY CHARACT = 'Z_NSX'.
        IF SY-SUBRC = 0.
          LS_BATCH-NSX = LS_CHAR-VALUE_CHAR.
*         Gia tri la ma nha cung cap: doi sang ten
          IF LS_BATCH-NSX IS NOT INITIAL AND LS_BATCH-NSX CO '0123456789 '.
            LV_NUM = LS_BATCH-NSX.
            SHIFT LV_NUM RIGHT DELETING TRAILING SPACE.
            TRANSLATE LV_NUM USING ' 0'.
            CLEAR LV_NAME.
            CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
              EXPORTING
                I_NUMBER = LV_NUM
                I_KIND   = 'K'
              IMPORTING
                E_NAME   = LV_NAME.
            IF LV_NAME IS NOT INITIAL.
              LS_BATCH-NSX = LV_NAME.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      IF LS_BATCH-NSX_LOT IS INITIAL.
        LS_BATCH-NSX_LOT = LS_BATCH-LICHA.
      ENDIF.
      INSERT LS_BATCH INTO TABLE GT_BATCH.
    ENDLOOP.
  ENDIF.

  LOOP AT CT_OUT ASSIGNING <LFS_O> WHERE CHARG IS NOT INITIAL.
    READ TABLE GT_BATCH ASSIGNING FIELD-SYMBOL(<LFS_BA>)
         WITH TABLE KEY MATNR = <LFS_O>-MATNR CHARG = <LFS_O>-CHARG.
    IF SY-SUBRC = 0.
      <LFS_O>-QNDAT   = <LFS_BA>-QNDAT.
      <LFS_O>-NSX_LOT = <LFS_BA>-NSX_LOT.
      <LFS_O>-NSX     = <LFS_BA>-NSX.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_UOM_CONV
*&---------------------------------------------------------------------*
* Quy doi so luong sang DVT quy doi (GV_UNIT_CV). Vat tu khong khai bao
* DVT nay de trong, dem so vat tu de bao cuoi lan chay.
FORM ADD_UOM_CONV CHANGING CT_OUT TYPE GTT_OUT.

  DATA: LT_ITEM TYPE ZCL_WM_UOM_CONVERT=>TT_ITEM,
        LT_MISS TYPE SORTED TABLE OF MATNR WITH UNIQUE KEY TABLE_LINE,
        LV_IDX  TYPE I.

  GV_NOT_CONV = 0.
  CHECK GV_UNIT_CV IS NOT INITIAL AND CT_OUT IS NOT INITIAL.

  LOOP AT CT_OUT ASSIGNING FIELD-SYMBOL(<LFS_O>).
    APPEND VALUE #( MATNR = <LFS_O>-MATNR MEINS = <LFS_O>-MEINS MENGE = <LFS_O>-QUAN ) TO LT_ITEM.
  ENDLOOP.

  ZCL_WM_UOM_CONVERT=>CONVERT_ITEMS( EXPORTING IV_UNIT_TO = GV_UNIT_CV
                                     CHANGING  CT_ITEMS   = LT_ITEM ).

  LOOP AT CT_OUT ASSIGNING <LFS_O>.
    LV_IDX = SY-TABIX.
    READ TABLE LT_ITEM ASSIGNING FIELD-SYMBOL(<LFS_I>) INDEX LV_IDX.
    CHECK SY-SUBRC = 0.
    IF <LFS_I>-FOUND = ABAP_TRUE.
      <LFS_O>-QUAN_CV  = <LFS_I>-MENGE_CV.
      <LFS_O>-MEINS_CV = GV_UNIT_CV.
    ELSEIF <LFS_O>-MATNR IS NOT INITIAL.
      INSERT <LFS_O>-MATNR INTO TABLE LT_MISS.
    ENDIF.
  ENDLOOP.

  GV_NOT_CONV = LINES( LT_MISS ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form RUN_MAP
*&---------------------------------------------------------------------*
* So do kho 2D cua 1 Storage Type
FORM RUN_MAP.

  GV_LGTYP_MAP = S_LGTYP[ 1 ]-LOW.
  GV_UNIT_CV   = COND #( WHEN P_CONV = ABAP_TRUE THEN P_MEINS ).
  P_SMEINS     = GV_UNIT_CV.

  PERFORM LOAD_MAP.
  IF GT_CELL IS INITIAL.
    MESSAGE S003.
    RETURN.
  ENDIF.

  GV_MAP_ACTIVE = ABAP_TRUE.
  CALL SCREEN 0100.
  CLEAR GV_MAP_ACTIVE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOAD_MAP
*&---------------------------------------------------------------------*
* Doc lai du lieu cua Storage Type dang xem (giu nguyen dieu kien tim)
FORM LOAD_MAP.

  CLEAR: GT_STK, GT_CELL, GT_VIEW, GV_SEL_LGPLA.

  PERFORM LOAD_DATA USING ABAP_TRUE CHANGING GT_STK.
  PERFORM ENRICH_BASIC CHANGING GT_STK.
  PERFORM BUILD_CELLS.

  GV_DIRTY_MAP  = ABAP_TRUE.
  GV_DIRTY_STAT = ABAP_TRUE.
  GV_DIRTY_VIEW = ABAP_TRUE.

  IF GT_CELL IS NOT INITIAL.
    PERFORM SHOW_UNPLACED.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_CELLS
*&---------------------------------------------------------------------*
* Moi Bin la 1 o: trang thai co hang / khoa tinh tu ton va co khoa cua Bin
FORM BUILD_CELLS.

  LOOP AT GT_BIN ASSIGNING FIELD-SYMBOL(<LFS_B>).
    INSERT VALUE #( LGPLA  = <LFS_B>-LGPLA
                    BLOCK  = <LFS_B>-BLOCK
                    LEVEL  = <LFS_B>-LEVEL
                    CELL   = <LFS_B>-CELL
                    SLOT   = <LFS_B>-SLOT
                    PLACED = <LFS_B>-PLACED
                    SKZUE  = <LFS_B>-SKZUE
                    SKZUA  = <LFS_B>-SKZUA
                    SKZSI  = <LFS_B>-SKZSI ) INTO TABLE GT_CELL.
  ENDLOOP.

  LOOP AT GT_STK ASSIGNING FIELD-SYMBOL(<LFS_O>) WHERE MATNR IS NOT INITIAL.
    READ TABLE GT_CELL ASSIGNING FIELD-SYMBOL(<LFS_C>) WITH TABLE KEY LGPLA = <LFS_O>-LGPLA.
    IF SY-SUBRC = 0.
      <LFS_C>-LINES     = <LFS_C>-LINES + 1.
      <LFS_C>-HAS_STOCK = ABAP_TRUE.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DO_SEARCH
*&---------------------------------------------------------------------*
* Tim tren du lieu da doc (khong truy van lai DB), cac dieu kien ket hop AND
FORM DO_SEARCH.

  DATA: LT_HIT   TYPE GTT_KEY,
        LT_MATCH TYPE GTT_OUT,
        LV_STK   TYPE ABAP_BOOL,
        LV_PAT   TYPE STRING,
        LV_N     TYPE I.

  LOOP AT GT_CELL ASSIGNING FIELD-SYMBOL(<LFS_C>).
    CLEAR <LFS_C>-FOUND.
  ENDLOOP.
  CLEAR: GV_FOUND_QTY, GV_FOUND_UOM, GV_FOUND_ONE.
  GV_DIRTY_MAP  = ABAP_TRUE.
  GV_DIRTY_STAT = ABAP_TRUE.

  TRANSLATE P_SSTK TO UPPER CASE.
  IF P_SSTK <> 'E' AND P_SSTK <> 'B'.
    CLEAR P_SSTK.
  ENDIF.

  IF P_SMATNR IS NOT INITIAL OR P_SDESC IS NOT INITIAL OR P_SCHARG IS NOT INITIAL OR P_SSTK IS NOT INITIAL.
    LV_STK = ABAP_TRUE.
  ENDIF.
  IF P_SBIN IS INITIAL AND LV_STK = ABAP_FALSE.
    RETURN.
  ENDIF.

  IF P_SDOC IS NOT INITIAL.
    LV_PAT = COND #( WHEN P_SDOC CA '*' THEN P_SDOC ELSE |*{ P_SDOC }| ).
  ENDIF.

* Dong ton thoa dieu kien ve vat tu / lo / ton dac biet
  IF LV_STK = ABAP_TRUE.
    LOOP AT GT_STK ASSIGNING FIELD-SYMBOL(<LFS_O>) WHERE MATNR IS NOT INITIAL.
      IF P_SMATNR IS NOT INITIAL AND <LFS_O>-MATNR <> P_SMATNR.
        CONTINUE.
      ENDIF.
      IF P_SDESC IS NOT INITIAL AND <LFS_O>-MAKTX NS P_SDESC.
        CONTINUE.
      ENDIF.
      IF P_SCHARG IS NOT INITIAL AND <LFS_O>-CHARG NP P_SCHARG.
        CONTINUE.
      ENDIF.
      IF P_SSTK IS NOT INITIAL.
        IF <LFS_O>-STK_USG <> P_SSTK.
          CONTINUE.
        ENDIF.
        IF LV_PAT IS NOT INITIAL.
*         E: so Sales Document; B: so khach hang (chu so huu ton)
          IF P_SSTK = 'E' AND <LFS_O>-STK_NO NP LV_PAT.
            CONTINUE.
          ENDIF.
          IF P_SSTK = 'B' AND <LFS_O>-OWNER NP LV_PAT.
            CONTINUE.
          ENDIF.
        ENDIF.
      ENDIF.
      INSERT VALUE #( LGPLA = <LFS_O>-LGPLA ) INTO TABLE LT_HIT.
      APPEND <LFS_O> TO LT_MATCH.
    ENDLOOP.
  ENDIF.

  LOOP AT GT_CELL ASSIGNING <LFS_C>.
    CHECK <LFS_C>-PLACED = ABAP_TRUE.
    IF P_SBIN IS NOT INITIAL AND <LFS_C>-LGPLA NP P_SBIN.
      CONTINUE.
    ENDIF.
    IF LV_STK = ABAP_TRUE AND NOT LINE_EXISTS( LT_HIT[ LGPLA = <LFS_C>-LGPLA ] ).
      CONTINUE.
    ENDIF.
    <LFS_C>-FOUND = ABAP_TRUE.
    LV_N = LV_N + 1.
  ENDLOOP.

* Tong ton chi co nghia khi tim theo dung 1 vat tu
  IF P_SMATNR IS NOT INITIAL AND LV_N > 0.
    GV_FOUND_ONE = ABAP_TRUE.
    LOOP AT LT_MATCH ASSIGNING <LFS_O>.
      READ TABLE GT_CELL ASSIGNING <LFS_C> WITH TABLE KEY LGPLA = <LFS_O>-LGPLA.
      IF SY-SUBRC = 0 AND <LFS_C>-FOUND = ABAP_TRUE.
        GV_FOUND_QTY = GV_FOUND_QTY + <LFS_O>-QUAN.
        GV_FOUND_UOM = <LFS_O>-MEINS.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF LV_N = 0.
    MESSAGE S007 DISPLAY LIKE 'I'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form HANDLE_COMMAND
*&---------------------------------------------------------------------*
FORM HANDLE_COMMAND USING IV_OK TYPE SY-UCOMM.

  DATA LV_LGTYP TYPE /SCWM/LGTYP.

* Nhap 1 o tren so do chi chon o, khong chay lai tim (giu nguyen vi tri cuon)
  IF GV_CLICKED = ABAP_TRUE.
    CLEAR GV_CLICKED.
    IF IV_OK IS INITIAL.
      RETURN.
    ENDIF.
  ENDIF.

* Doi DVT quy doi o thanh tim: tinh lai ALV ton cua o dang chon
  IF P_SMEINS <> GV_UNIT_VIEW.
    GV_DIRTY_VIEW = ABAP_TRUE.
  ENDIF.

  IF IV_OK IS INITIAL OR IV_OK = 'FIND'.
    PERFORM DO_SEARCH.

  ELSEIF IV_OK = 'REFR'.
    PERFORM LOAD_MAP.
    PERFORM DO_SEARCH.

  ELSEIF IV_OK = 'SWST'.
    PERFORM PICK_STORAGE_TYPE CHANGING LV_LGTYP.
    IF LV_LGTYP IS NOT INITIAL AND LV_LGTYP <> GV_LGTYP_MAP.
      GV_LGTYP_MAP = LV_LGTYP.
      CLEAR: P_SBIN, P_SMATNR, P_SDESC, P_SCHARG, P_SSTK, P_SDOC.
      CLEAR: GV_FOUND_QTY, GV_FOUND_UOM, GV_FOUND_ONE.
      PERFORM LOAD_MAP.
    ENDIF.

  ELSEIF IV_OK = 'LIST'.
    PERFORM LIST_FROM_MAP.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PICK_STORAGE_TYPE
*&---------------------------------------------------------------------*
* Popup cac Storage Type cua Warehouse co cau truc ma Bin: cau hinh ZTWM_BIN_LAYOUT
* hoac Bin tao tu cau truc ma Bin (co san Aisle / Stack / Level / Bin Section / Depth)
FORM PICK_STORAGE_TYPE CHANGING CV_LGTYP TYPE /SCWM/LGTYP.

  DATA: LT_VAL TYPE STANDARD TABLE OF /SCWM/LGTYP,
        LT_STD TYPE STANDARD TABLE OF /SCWM/LGTYP,
        LT_RET TYPE STANDARD TABLE OF DDSHRETVAL.

  CLEAR CV_LGTYP.

  LOOP AT GT_LAY ASSIGNING FIELD-SYMBOL(<LFS_L>).
    APPEND <LFS_L>-LGTYP TO LT_VAL.
  ENDLOOP.

  SELECT DISTINCT EWMSTORAGETYPE FROM I_EWM_STORAGEBIN_2
    WHERE EWMWAREHOUSE                   = @P_LGNUM
      AND EWMSTORBINFREEDEFINEDAISLETEXT <> ''
      AND EWMSTORBINFREEDEFINEDSTACKTEXT <> ''
      AND EWMSTORBINFREEDEFINEDLEVELTEXT <> ''
      AND EWMSTORBINFREEDFNDSECTIONTEXT  <> ''
      AND EWMSTORAGEBINFREEDFNDDEPTHTEXT <> ''
    INTO TABLE @LT_STD.
  APPEND LINES OF LT_STD TO LT_VAL.
  SORT LT_VAL.
  DELETE ADJACENT DUPLICATES FROM LT_VAL.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      RETFIELD    = 'LGTYP'
      VALUE_ORG   = 'S'
      WINDOW_TITLE = 'Storage Type'                           "#EC NOTEXT
    TABLES
      VALUE_TAB   = LT_VAL
      RETURN_TAB  = LT_RET
    EXCEPTIONS
      OTHERS      = 1.
  IF SY-SUBRC = 0.
    READ TABLE LT_RET ASSIGNING FIELD-SYMBOL(<LFS_R>) INDEX 1.
    IF SY-SUBRC = 0.
      CV_LGTYP = <LFS_R>-FIELDVAL.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form LIST_FROM_MAP
*&---------------------------------------------------------------------*
* Tu so do chuyen sang danh sach ton cua Storage Type dang xem
FORM LIST_FROM_MAP.

  DATA: LT_BIN TYPE GTT_BIN,
        LT_WT  TYPE GTT_WT,
        LT_HUC TYPE GTT_OUT.

* Danh sach doc lai du lieu: giu du lieu cua so do de quay lai khong phai doc lai
  LT_BIN = GT_BIN.
  LT_WT  = GT_WT.
  LT_HUC = GT_HUC.

  S_LGTYP[]  = VALUE #( ( SIGN = 'I' OPTION = 'EQ' LOW = GV_LGTYP_MAP ) ).
  GV_UNIT_CV = P_SMEINS.
  PERFORM RUN_LIST.

  GT_BIN = LT_BIN.
  GT_WT  = LT_WT.
  GT_HUC = LT_HUC.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form HANDLE_SAPEVENT
*&---------------------------------------------------------------------*
* Nhap 1 o tren so do: GETDATA la so thu tu o trong GT_CELL
FORM HANDLE_SAPEVENT USING IV_ACTION TYPE CLIKE
                           IV_DATA   TYPE CLIKE.

  DATA LV_IDX TYPE I.

  CHECK IV_ACTION = 'CELL'.

  GV_CLICKED = ABAP_TRUE.
  LV_IDX = IV_DATA.
  READ TABLE GT_CELL ASSIGNING FIELD-SYMBOL(<LFS_C>) INDEX LV_IDX.
  IF SY-SUBRC = 0.
    GV_SEL_LGPLA  = <LFS_C>-LGPLA.
    GV_DIRTY_STAT = ABAP_TRUE.
    GV_DIRTY_VIEW = ABAP_TRUE.
  ENDIF.

ENDFORM.
