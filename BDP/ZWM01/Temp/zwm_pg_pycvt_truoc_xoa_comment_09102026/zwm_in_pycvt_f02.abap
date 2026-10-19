*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PYCVT_F02
*&---------------------------------------------------------------------*
* Kiểm tra sự sẵn sàng của vật tư (màn hình trung gian), nhật ký in,
* bảng tham số ZTWM01_PARAM
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  READ_PARAM
*&---------------------------------------------------------------------*
*       Bảng tham số: Storage Type PSA theo Warehouse, mã biểu mẫu GMP theo Plant
*----------------------------------------------------------------------*
FORM READ_PARAM.

  SELECT PARAM_ID, KEY1, KEY2, PVALUE
    FROM ZTWM01_PARAM
    INTO TABLE @GT_PARAM.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  EXCLUDE_PRINTED_SUPP
*&---------------------------------------------------------------------*
*       Phiếu bổ sung: bỏ dòng đã từng in ở phiếu bổ sung theo nhật ký in
*----------------------------------------------------------------------*
FORM EXCLUDE_PRINTED_SUPP.

  TYPES: BEGIN OF LTY_KEY,
           OBJ_KEY TYPE ZEWM_DE_OBJ_KEY,
         END OF LTY_KEY.
  DATA: LT_KEY  TYPE STANDARD TABLE OF LTY_KEY WITH EMPTY KEY,
        LT_DONE TYPE HASHED TABLE OF ZEWM_DE_OBJ_KEY WITH UNIQUE KEY TABLE_LINE,
        LV_KEY  TYPE ZEWM_DE_OBJ_KEY.

  CHECK GT_PREDATA IS NOT INITIAL.

  LT_KEY = VALUE #( FOR LS_P IN GT_PREDATA ( OBJ_KEY = |{ LS_P-RSNUM }-{ LS_P-RSPOS }| ) ).

  SELECT L~OBJ_KEY
    FROM ZTWM_PRTLOG AS L
    INNER JOIN @LT_KEY AS K ON K~OBJ_KEY = L~OBJ_KEY
    WHERE L~TCODE    = @GC_TCODE
      AND L~FORMNAME = @GC_FORMNAME
      AND L~RPT_OPT  = @GC_TYPE_SUPP
    INTO TABLE @LT_DONE.
  CHECK LT_DONE IS NOT INITIAL.

  LOOP AT GT_PREDATA INTO DATA(LS_DATA).
    LV_KEY = |{ LS_DATA-RSNUM }-{ LS_DATA-RSPOS }|.
    IF LINE_EXISTS( LT_DONE[ TABLE_LINE = LV_KEY ] ).
      DELETE GT_PREDATA.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  READ_PRTLOG_COUNT
*&---------------------------------------------------------------------*
*       Số lần đã in của từng phiếu (Reservation)
*----------------------------------------------------------------------*
FORM READ_PRTLOG_COUNT CHANGING CT_CNT TYPE GTT_PRTLOG.

  TYPES: BEGIN OF LTY_KEY,
           OBJ_KEY TYPE ZEWM_DE_OBJ_KEY,
         END OF LTY_KEY.
  DATA LT_KEY TYPE STANDARD TABLE OF LTY_KEY WITH EMPTY KEY.

  CLEAR CT_CNT.
  CHECK GT_HEADER IS NOT INITIAL.

  LT_KEY = VALUE #( FOR LS_H IN GT_HEADER ( OBJ_KEY = LS_H-RSNUM ) ).

  SELECT L~*
    FROM ZTWM_PRTLOG AS L
    INNER JOIN @LT_KEY AS K ON K~OBJ_KEY = L~OBJ_KEY
    WHERE L~TCODE    = @GC_TCODE
      AND L~FORMNAME = @GC_FORMNAME
    INTO TABLE @CT_CNT.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  WRITE_PRTLOG
*&---------------------------------------------------------------------*
*       Ghi nhật ký in: mỗi phiếu một dòng (khóa = số Reservation);
*       phiếu bổ sung ghi thêm từng dòng vật tư (khóa = Reservation-Item)
*----------------------------------------------------------------------*
FORM WRITE_PRTLOG USING IT_CNT TYPE GTT_PRTLOG.

  TYPES: BEGIN OF LTY_KEY,
           OBJ_KEY TYPE ZEWM_DE_OBJ_KEY,
         END OF LTY_KEY.
  DATA: LT_LOG  TYPE STANDARD TABLE OF ZTWM_PRTLOG,
        LS_LOG  TYPE ZTWM_PRTLOG,
        LT_ITEM TYPE GTT_PRTLOG,
        LT_KEY  TYPE STANDARD TABLE OF LTY_KEY WITH EMPTY KEY,
        LV_KEY  TYPE ZEWM_DE_OBJ_KEY.

  GET TIME.

  LOOP AT GT_HEADER INTO DATA(LS_H).
    CLEAR LS_LOG.
    LV_KEY = LS_H-RSNUM.
    READ TABLE IT_CNT INTO LS_LOG WITH TABLE KEY OBJ_KEY = LV_KEY.
    IF SY-SUBRC <> 0.
      LS_LOG-TCODE      = GC_TCODE.
      LS_LOG-FORMNAME   = GC_FORMNAME.
      LS_LOG-OBJ_KEY    = LV_KEY.
      LS_LOG-FIRST_DATE = SY-DATUM.
      LS_LOG-FIRST_TIME = SY-UZEIT.
      LS_LOG-FIRST_USER = SY-UNAME.
    ENDIF.
    LS_LOG-RPT_OPT   = GV_DOC_TYPE.
    LS_LOG-WERKS     = LS_H-WERKS.
    LS_LOG-LGORT     = LS_H-LGORT.
    LS_LOG-PRT_COUNT = LS_LOG-PRT_COUNT + 1.
    LS_LOG-LAST_DATE = SY-DATUM.
    LS_LOG-LAST_TIME = SY-UZEIT.
    LS_LOG-LAST_USER = SY-UNAME.
    APPEND LS_LOG TO LT_LOG.
  ENDLOOP.

  IF GV_DOC_TYPE = GC_TYPE_SUPP.
    LT_KEY = VALUE #( FOR LS_P IN GT_PRINT ( OBJ_KEY = |{ LS_P-RSNUM }-{ LS_P-RSPOS }| ) ).
    SELECT L~*
      FROM ZTWM_PRTLOG AS L
      INNER JOIN @LT_KEY AS K ON K~OBJ_KEY = L~OBJ_KEY
      WHERE L~TCODE    = @GC_TCODE
        AND L~FORMNAME = @GC_FORMNAME
      INTO TABLE @LT_ITEM.

    LOOP AT GT_PRINT INTO DATA(LS_PRT).
      CLEAR LS_LOG.
      LV_KEY = |{ LS_PRT-RSNUM }-{ LS_PRT-RSPOS }|.
      READ TABLE LT_ITEM INTO LS_LOG WITH TABLE KEY OBJ_KEY = LV_KEY.
      IF SY-SUBRC <> 0.
        LS_LOG-TCODE      = GC_TCODE.
        LS_LOG-FORMNAME   = GC_FORMNAME.
        LS_LOG-OBJ_KEY    = LV_KEY.
        LS_LOG-FIRST_DATE = SY-DATUM.
        LS_LOG-FIRST_TIME = SY-UZEIT.
        LS_LOG-FIRST_USER = SY-UNAME.
      ENDIF.
      LS_LOG-RPT_OPT   = GV_DOC_TYPE.
      LS_LOG-WERKS     = LS_PRT-WERKS.
      LS_LOG-LGORT     = LS_PRT-LGORT.
      LS_LOG-PRT_COUNT = LS_LOG-PRT_COUNT + 1.
      LS_LOG-LAST_DATE = SY-DATUM.
      LS_LOG-LAST_TIME = SY-UZEIT.
      LS_LOG-LAST_USER = SY-UNAME.
      APPEND LS_LOG TO LT_LOG.
    ENDLOOP.
  ENDIF.

  IF LT_LOG IS NOT INITIAL.
    MODIFY ZTWM_PRTLOG FROM TABLE @LT_LOG.
    COMMIT WORK.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  GET_WAREHOUSE
*&---------------------------------------------------------------------*
*       Warehouse EWM của Plant/SLoc theo cấu hình ánh xạ chuẩn ERP - EWM.
*       SLoc không quản lý bằng EWM: trả về trống.
*----------------------------------------------------------------------*
FORM GET_WAREHOUSE USING    IV_WERKS TYPE WERKS_D
                            IV_LGORT TYPE LGORT_D
                   CHANGING CV_LGNUM TYPE /SCWM/LGNUM.

  CLEAR CV_LGNUM.
  CHECK IV_WERKS IS NOT INITIAL AND IV_LGORT IS NOT INITIAL.

  READ TABLE GT_WHS INTO DATA(LS_WHS) WITH TABLE KEY WERKS = IV_WERKS LGORT = IV_LGORT.
  IF SY-SUBRC = 0.
    CV_LGNUM = LS_WHS-LGNUM.
    RETURN.
  ENDIF.

  IF GV_LOGSYS IS INITIAL.
    CALL FUNCTION 'OWN_LOGICAL_SYSTEM_GET'
      IMPORTING
        OWN_LOGICAL_SYSTEM = GV_LOGSYS
      EXCEPTIONS
        OTHERS             = 1.
  ENDIF.

  PERFORM GET_MAP_INSTANCE.
  IF GO_MAP IS BOUND.
    TRY.
        GO_MAP->GET_WME_ORG_BY_ERP_LOC( EXPORTING IV_ERP_PLANT  = IV_WERKS
                                                  IV_ERP_STLOC  = IV_LGORT
                                                  IV_ERP_LOGSYS = GV_LOGSYS
                                        IMPORTING EV_LGNUM      = CV_LGNUM ).
      CATCH /SCWM/CX_STOCKID_MAP.
        CLEAR CV_LGNUM.
    ENDTRY.
  ENDIF.

  INSERT VALUE #( WERKS = IV_WERKS LGORT = IV_LGORT LGNUM = CV_LGNUM ) INTO TABLE GT_WHS.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  GET_MAP_INSTANCE
*&---------------------------------------------------------------------*
FORM GET_MAP_INSTANCE.

  IF GO_MAP IS NOT BOUND.
    CALL FUNCTION '/SCWM/GET_STOCKID_MAP_INSTANCE'
      IMPORTING
        EIF_STOCKID_MAPPING = GO_MAP.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  GET_ERP_LOC
*&---------------------------------------------------------------------*
*       Plant/SLoc/loại tồn ERP của tồn EWM (Party entitled + Stock Type), đọc 1 lần mỗi cặp
*----------------------------------------------------------------------*
FORM GET_ERP_LOC USING    IV_LGNUM    TYPE /SCWM/LGNUM
                          IV_ENTITLED TYPE /SCWM/DE_ENTITLED
                          IV_CAT      TYPE /SCWM/DE_CAT
                 CHANGING CV_WERKS    TYPE WERKS_D
                          CV_LGORT    TYPE LGORT_D
                          CV_BESTQ    TYPE BESTQ.

  CLEAR: CV_WERKS, CV_LGORT, CV_BESTQ.

  READ TABLE GT_MAPL INTO DATA(LS_MAPL)
       WITH TABLE KEY LGNUM = IV_LGNUM ENTITLED = IV_ENTITLED CAT = IV_CAT.
  IF SY-SUBRC <> 0.
    CLEAR LS_MAPL.
    LS_MAPL-LGNUM    = IV_LGNUM.
    LS_MAPL-ENTITLED = IV_ENTITLED.
    LS_MAPL-CAT      = IV_CAT.
    PERFORM GET_MAP_INSTANCE.
    IF GO_MAP IS BOUND.
      TRY.
          GO_MAP->GET_ERP_STLOC( EXPORTING IV_LGNUM         = IV_LGNUM
                                           IV_ENTITLED      = IV_ENTITLED
                                           IV_CAT           = IV_CAT
                                 IMPORTING EV_ERP_PLANT     = LS_MAPL-WERKS
                                           EV_ERP_STLOC     = LS_MAPL-LGORT
                                           EV_ERP_STOCK_CAT = LS_MAPL-BESTQ ).
        CATCH /SCWM/CX_STOCKID_MAP.
          CLEAR: LS_MAPL-WERKS, LS_MAPL-LGORT, LS_MAPL-BESTQ.
      ENDTRY.
    ENDIF.
    INSERT LS_MAPL INTO TABLE GT_MAPL.
  ENDIF.

  CV_WERKS = LS_MAPL-WERKS.
  CV_LGORT = LS_MAPL-LGORT.
  CV_BESTQ = LS_MAPL-BESTQ.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  CHECK_READINESS
*&---------------------------------------------------------------------*
*       Dữ liệu màn hình trung gian: tồn IM, tồn vật lý/khả dụng eWM,
*       tồn tại PSA, lượng đang giữ cho yêu cầu khác, SL cần điều chuyển, đèn.
*       Mọi số lượng theo ĐVT cơ bản.
*----------------------------------------------------------------------*
FORM CHECK_READINESS.

  DATA: LR_MATNR TYPE GTT_R_MATNR,
        LR_WERKS TYPE GTT_R_WERKS,
        LR_LGNUM TYPE GTT_R_LGNUM.

  GT_ALV = GT_PREDATA.
  CLEAR GV_NOPSA.

  LOOP AT GT_ALV ASSIGNING FIELD-SYMBOL(<LFS_A>).
    PERFORM GET_WAREHOUSE USING <LFS_A>-WERKS <LFS_A>-LGORT CHANGING <LFS_A>-LGNUM.
    <LFS_A>-ERFME = <LFS_A>-MEINS.
    IF NOT LINE_EXISTS( LR_MATNR[ LOW = <LFS_A>-MATNR ] ).
      APPEND VALUE #( SIGN = 'I' OPTION = 'EQ' LOW = <LFS_A>-MATNR ) TO LR_MATNR.
    ENDIF.
    IF NOT LINE_EXISTS( LR_WERKS[ LOW = <LFS_A>-WERKS ] ).
      APPEND VALUE #( SIGN = 'I' OPTION = 'EQ' LOW = <LFS_A>-WERKS ) TO LR_WERKS.
    ENDIF.
    IF <LFS_A>-LGNUM IS NOT INITIAL AND NOT LINE_EXISTS( LR_LGNUM[ LOW = <LFS_A>-LGNUM ] ).
      APPEND VALUE #( SIGN = 'I' OPTION = 'EQ' LOW = <LFS_A>-LGNUM ) TO LR_LGNUM.
      IF GV_NOPSA IS INITIAL
         AND NOT LINE_EXISTS( GT_PARAM[ PARAM_ID = GC_PAR_PSA KEY1 = <LFS_A>-LGNUM ] ).
        GV_NOPSA = <LFS_A>-LGNUM.
      ENDIF.
    ENDIF.
  ENDLOOP.

  PERFORM READ_IM_STOCK USING LR_MATNR LR_WERKS.
  PERFORM READ_EWM_STOCK USING LR_MATNR LR_LGNUM.
  PERFORM READ_HOLD USING LR_MATNR LR_WERKS.

  LOOP AT GT_ALV ASSIGNING <LFS_A>.
    PERFORM EVAL_LINE CHANGING <LFS_A>.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  READ_IM_STOCK
*&---------------------------------------------------------------------*
*       Tồn unrestricted hiện hành tại SLoc (theo Batch: NSDM_E_MCHB; không Batch: NSDM_E_MARD)
*----------------------------------------------------------------------*
FORM READ_IM_STOCK USING IR_MATNR TYPE GTT_R_MATNR
                         IR_WERKS TYPE GTT_R_WERKS.

  CLEAR GT_IM.
  CHECK IR_MATNR IS NOT INITIAL.

  SELECT MATNR, WERKS, LGORT, CHARG, CLABS AS QUAN
    FROM NSDM_E_MCHB
    WHERE MATNR IN @IR_MATNR
      AND WERKS IN @IR_WERKS
      AND CLABS <> 0
    INTO CORRESPONDING FIELDS OF TABLE @GT_IM.

  SELECT MATNR, WERKS, LGORT, LABST AS QUAN
    FROM NSDM_E_MARD
    WHERE MATNR IN @IR_MATNR
      AND WERKS IN @IR_WERKS
      AND LABST <> 0
    APPENDING CORRESPONDING FIELDS OF TABLE @GT_IM.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  READ_EWM_STOCK
*&---------------------------------------------------------------------*
*       Quant eWM và Warehouse Task chưa xác nhận của các vật tư cần kiểm tra
*----------------------------------------------------------------------*
FORM READ_EWM_STOCK USING IR_MATNR TYPE GTT_R_MATNR
                          IR_LGNUM TYPE GTT_R_LGNUM.

  DATA: LV_REST TYPE BDMNG,
        LV_FREE TYPE BDMNG.

  CLEAR: GT_EWM, GT_WT.
  CHECK IR_MATNR IS NOT INITIAL AND IR_LGNUM IS NOT INITIAL.

  TRY.
      SELECT S~EWMWAREHOUSE                AS LGNUM,
             S~EWMSTORAGETYPE              AS LGTYP,
             S~EWMSTORAGEBIN               AS LGPLA,
             S~HANDLINGUNITNUMBER          AS HUID,
             S~PRODUCT                     AS MATNR,
             S~BATCH                       AS CHARG,
             S~ENTITLEDTODISPOSEPARTY      AS ENTITLED,
             S~EWMSTOCKTYPE                AS CAT,
             T~EWMSTOCKTYPENAME            AS CAT_TXT,
             S~EWMSTOCKQUANTITYINBASEUNIT  AS QUAN,
             S~EWMSTOCKQUANTITYBASEUNIT    AS MEINS
        FROM I_EWM_PHYSSTOCKPROD AS S
        LEFT OUTER JOIN I_EWM_STOCKTYPETEXT_2 AS T
          ON  T~EWMWAREHOUSE = S~EWMWAREHOUSE
          AND T~EWMSTOCKTYPE = S~EWMSTOCKTYPE
          AND T~LANGUAGE     = @SY-LANGU
        WHERE S~EWMWAREHOUSE IN @IR_LGNUM
          AND S~PRODUCT      IN @IR_MATNR
        INTO CORRESPONDING FIELDS OF TABLE @GT_EWM.

      SELECT W~ISHANDLINGUNITWAREHOUSETASK AS FLG_HU,
             W~EWMWAREHOUSE                AS LGNUM,
             W~PRODUCTNAME                 AS MATNR,
             W~BATCH                       AS CHARG,
             W~ENTITLEDTODISPOSEPARTY      AS ENTITLED,
             W~EWMSTOCKTYPE                AS CAT,
             W~SOURCESTORAGEBIN            AS SRC_BIN,
             W~SOURCEHANDLINGUNIT          AS SRC_HU,
             W~TARGETQUANTITYINBASEUNIT    AS QTY
        FROM I_EWM_OPENWAREHOUSETASKS_2 AS W
        WHERE W~EWMWAREHOUSE        IN @IR_LGNUM
          AND W~WAREHOUSETASKSTATUS <> 'A'
          AND W~WAREHOUSETASKSTATUS <> 'C'
          AND ( W~PRODUCTNAME IN @IR_MATNR OR W~ISHANDLINGUNITWAREHOUSETASK = @ABAP_TRUE )
        INTO CORRESPONDING FIELDS OF TABLE @GT_WT.

    CATCH CX_SY_OPEN_SQL_DB INTO DATA(LX_SQL).
      DATA(LV_ERR) = LX_SQL->GET_TEXT( ).
      MESSAGE S006(ZWM01) WITH '' LV_ERR DISPLAY LIKE 'W'.
      CLEAR: GT_EWM, GT_WT.
      RETURN.
  ENDTRY.

  " Plant/SLoc ERP và cờ PSA của từng quant
  LOOP AT GT_EWM ASSIGNING FIELD-SYMBOL(<LFS_E>).
    PERFORM GET_ERP_LOC USING    <LFS_E>-LGNUM <LFS_E>-ENTITLED <LFS_E>-CAT
                        CHANGING <LFS_E>-WERKS <LFS_E>-LGORT <LFS_E>-BESTQ.
    IF LINE_EXISTS( GT_PARAM[ PARAM_ID = GC_PAR_PSA KEY1 = <LFS_E>-LGNUM KEY2 = <LFS_E>-LGTYP ] ).
      <LFS_E>-PSA = ABAP_TRUE.
    ENDIF.
  ENDLOOP.

  " Lượng đã gán cho Warehouse Task mở (lấy hàng từ Bin nguồn)
  LOOP AT GT_WT INTO DATA(LS_WT) WHERE SRC_BIN IS NOT INITIAL.
    IF LS_WT-FLG_HU = ABAP_TRUE.
      " WT theo HU: cả HU được lấy đi
      CHECK LS_WT-SRC_HU IS NOT INITIAL.
      LOOP AT GT_EWM ASSIGNING <LFS_E> WHERE LGNUM = LS_WT-LGNUM AND HUID = LS_WT-SRC_HU.
        <LFS_E>-PICK = <LFS_E>-QUAN.
      ENDLOOP.
    ELSE.
      LV_REST = LS_WT-QTY.
      LOOP AT GT_EWM ASSIGNING <LFS_E> WHERE LGNUM    = LS_WT-LGNUM
                                         AND LGPLA    = LS_WT-SRC_BIN
                                         AND MATNR    = LS_WT-MATNR
                                         AND CHARG    = LS_WT-CHARG
                                         AND ENTITLED = LS_WT-ENTITLED
                                         AND CAT      = LS_WT-CAT.
        IF LV_REST <= 0.
          EXIT.
        ENDIF.
        IF LS_WT-SRC_HU IS NOT INITIAL AND <LFS_E>-HUID <> LS_WT-SRC_HU.
          CONTINUE.
        ENDIF.
        LV_FREE = <LFS_E>-QUAN - <LFS_E>-PICK.
        IF LV_FREE <= 0.
          CONTINUE.
        ENDIF.
        IF LV_FREE >= LV_REST.
          <LFS_E>-PICK = <LFS_E>-PICK + LV_REST.
          CLEAR LV_REST.
        ELSE.
          <LFS_E>-PICK = <LFS_E>-QUAN.
          LV_REST = LV_REST - LV_FREE.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  READ_HOLD
*&---------------------------------------------------------------------*
*       Dòng Reservation/LSX còn mở của các vật tư cần kiểm tra (để tính lượng đang giữ)
*----------------------------------------------------------------------*
FORM READ_HOLD USING IR_MATNR TYPE GTT_R_MATNR
                     IR_WERKS TYPE GTT_R_WERKS.

  DATA LS_HOLD TYPE GTY_HOLD.

  CLEAR GT_HOLD.
  CHECK IR_MATNR IS NOT INITIAL.

  SELECT R~RSNUM, R~RSPOS, R~AUFNR, R~BDTER, R~BDMNG, R~ENMNG, R~MEINS,
         K~USNAM, R~MATNR, R~WERKS, R~LGORT, R~CHARG, A~AUTYP
    FROM RESB AS R
    INNER JOIN RKPF AS K ON K~RSNUM = R~RSNUM
    LEFT OUTER JOIN AUFK AS A ON A~AUFNR = R~AUFNR
    WHERE R~MATNR IN @IR_MATNR
      AND R~WERKS IN @IR_WERKS
      AND R~XLOEK <> 'X'
      AND R~KZEAR <> 'X'
      AND R~POSTP <> 'N'
      AND R~ENMNG <  R~BDMNG
    INTO TABLE @DATA(LT_RESB).

  LOOP AT LT_RESB INTO DATA(LS_RESB).
    CLEAR LS_HOLD.
    MOVE-CORRESPONDING LS_RESB TO LS_HOLD.
    LS_HOLD-OPEN_QTY = LS_RESB-BDMNG - LS_RESB-ENMNG.
    IF LS_RESB-AUFNR IS INITIAL.
      LS_HOLD-LOAI = 'Reservation'.                                   "#EC NOTEXT
    ELSEIF LS_RESB-AUTYP = '10' OR LS_RESB-AUTYP = '40'.
      LS_HOLD-LOAI = 'Lệnh sản xuất'.                                 "#EC NOTEXT
    ELSE.
      LS_HOLD-LOAI = 'Lệnh khác'.                                     "#EC NOTEXT
    ENDIF.
    INSERT LS_HOLD INTO TABLE GT_HOLD.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  IS_HOLDING
*&---------------------------------------------------------------------*
*       Dòng yêu cầu khác có đang giữ tồn so với dòng đang xét không:
*       cùng Material + Plant + SLoc (+ Batch), ngày yêu cầu sớm hơn hoặc bằng
*----------------------------------------------------------------------*
FORM IS_HOLDING USING    IS_LINE TYPE ZWM_ST_PYCVT
                         IS_HOLD TYPE GTY_HOLD
                CHANGING CV_YES  TYPE ABAP_BOOL.

  CV_YES = ABAP_FALSE.
  IF IS_HOLD-RSNUM = IS_LINE-RSNUM AND IS_HOLD-RSPOS = IS_LINE-RSPOS.
    RETURN.
  ENDIF.
  IF IS_LINE-CHARG IS NOT INITIAL AND IS_HOLD-CHARG <> IS_LINE-CHARG.
    RETURN.
  ENDIF.
  IF IS_HOLD-BDTER > IS_LINE-BDTER.
    RETURN.
  ENDIF.
  CV_YES = ABAP_TRUE.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  EVAL_LINE
*&---------------------------------------------------------------------*
*       Tính các cột tồn và đèn tình trạng của một dòng
*----------------------------------------------------------------------*
FORM EVAL_LINE CHANGING CS_LINE TYPE ZWM_ST_PYCVT.

  DATA: LV_IM    TYPE LABST,
        LV_PHYS  TYPE BDMNG,
        LV_AVAIL TYPE BDMNG,
        LV_PSA   TYPE BDMNG,
        LV_HOLD  TYPE BDMNG,
        LV_N     TYPE BDMNG,
        LV_K     TYPE BDMNG,
        LV_P     TYPE BDMNG,
        LV_SHORT TYPE BDMNG,
        LV_YES   TYPE ABAP_BOOL.

  " Tồn IM tại SLoc
  LOOP AT GT_IM INTO DATA(LS_IM) WHERE MATNR = CS_LINE-MATNR
                                   AND WERKS = CS_LINE-WERKS
                                   AND LGORT = CS_LINE-LGORT
                                   AND CHARG = CS_LINE-CHARG.
    LV_IM = LV_IM + LS_IM-QUAN.
  ENDLOOP.

  " Tồn eWM của Warehouse gắn với Plant/SLoc, chỉ tồn unrestricted
  IF CS_LINE-LGNUM IS NOT INITIAL.
    LOOP AT GT_EWM INTO DATA(LS_E) WHERE LGNUM = CS_LINE-LGNUM
                                     AND MATNR = CS_LINE-MATNR
                                     AND WERKS = CS_LINE-WERKS
                                     AND BESTQ IS INITIAL.
      IF CS_LINE-CHARG IS NOT INITIAL AND LS_E-CHARG <> CS_LINE-CHARG.
        CONTINUE.
      ENDIF.
      IF LS_E-PSA = ABAP_TRUE.
        LV_PSA = LV_PSA + LS_E-QUAN.
      ELSEIF LS_E-LGORT = CS_LINE-LGORT.
        LV_PHYS = LV_PHYS + LS_E-QUAN.
        IF LS_E-QUAN > LS_E-PICK.
          LV_AVAIL = LV_AVAIL + LS_E-QUAN - LS_E-PICK.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

  " Đang giữ cho yêu cầu khác
  LOOP AT GT_HOLD INTO DATA(LS_H) WHERE MATNR = CS_LINE-MATNR
                                    AND WERKS = CS_LINE-WERKS
                                    AND LGORT = CS_LINE-LGORT.
    PERFORM IS_HOLDING USING CS_LINE LS_H CHANGING LV_YES.
    IF LV_YES = ABAP_TRUE.
      LV_HOLD = LV_HOLD + LS_H-OPEN_QTY.
    ENDIF.
  ENDLOOP.

  CS_LINE-IM_STOCK  = LV_IM.
  CS_LINE-OTHER_REQ = LV_HOLD.
  IF CS_LINE-LGNUM IS NOT INITIAL.
    CS_LINE-EWM_PHYS  = LV_PHYS.
    CS_LINE-EWM_AVAIL = LV_AVAIL.
    CS_LINE-PSA_STOCK = LV_PSA.
  ENDIF.

  " SL cần điều chuyển = max(0; SL còn yêu cầu - Tồn tại PSA)
  IF CS_LINE-OPEN_QTY > LV_PSA.
    CS_LINE-TRANSFER_QTY = CS_LINE-OPEN_QTY - LV_PSA.
  ELSE.
    CLEAR CS_LINE-TRANSFER_QTY.
  ENDIF.

  " Phiếu Lệnh SX / bổ sung chưa có Batch: không cho in
  IF CS_LINE-CHARG IS INITIAL AND GV_DOC_TYPE <> GC_TYPE_OTHER.
    CS_LINE-LIGHT       = ICON_LIGHT_OUT.
    CS_LINE-STATUS_TEXT = 'Chưa chỉ định Batch – không cho in'.              "#EC NOTEXT
    CLEAR CS_LINE-SEL.
    RETURN.
  ENDIF.

  CS_LINE-SEL = ABAP_TRUE.

  IF CS_LINE-OPEN_QTY <= 0.
    CS_LINE-LIGHT       = ICON_GREEN_LIGHT.
    CS_LINE-STATUS_TEXT = 'Đã xuất đủ'.                                      "#EC NOTEXT
  ELSEIF LV_PSA >= CS_LINE-OPEN_QTY.
    CS_LINE-LIGHT       = ICON_MESSAGE_INFORMATION.
    CS_LINE-STATUS_TEXT = 'Đủ tại PSA – không cần điều chuyển'.             "#EC NOTEXT
  ELSE.
    LV_N = CS_LINE-OPEN_QTY - LV_PSA.
    " SLoc không quản lý bằng EWM: đánh giá theo tồn IM
    IF CS_LINE-LGNUM IS NOT INITIAL.
      LV_K = LV_AVAIL - LV_HOLD.
      LV_P = LV_PHYS.
    ELSE.
      LV_K = LV_IM - LV_HOLD.
      LV_P = LV_IM.
    ENDIF.
    IF LV_K >= LV_N.
      CS_LINE-LIGHT       = ICON_GREEN_LIGHT.
      CS_LINE-STATUS_TEXT = 'Đủ'.                                            "#EC NOTEXT
    ELSEIF LV_P >= LV_N.
      CS_LINE-LIGHT       = ICON_YELLOW_LIGHT.
      CS_LINE-STATUS_TEXT = 'Đủ vật lý – đang giữ cho YC khác'.              "#EC NOTEXT
    ELSE.
      LV_SHORT = LV_N - LV_K.
      CS_LINE-LIGHT       = ICON_RED_LIGHT.
      CS_LINE-STATUS_TEXT = |Thiếu { LV_SHORT NUMBER = USER }|.              "#EC NOTEXT
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  CREATE_ALV
*&---------------------------------------------------------------------*
*       Màn hình trung gian: ALV trong custom control CC_MAIN của screen 0100
*----------------------------------------------------------------------*
FORM CREATE_ALV.

  DATA LV_HEAD TYPE LVC_TITLE.

  CREATE OBJECT GO_CONT
    EXPORTING
      CONTAINER_NAME = GC_CONT_NAME
    EXCEPTIONS
      OTHERS         = 1.
  IF SY-SUBRC <> 0.
    MESSAGE 'Không tạo được vùng hiển thị CC_MAIN của screen 0100' TYPE 'S' DISPLAY LIKE 'E'. "#EC NOTEXT
    RETURN.
  ENDIF.

  TRY.
      CL_SALV_TABLE=>FACTORY( EXPORTING R_CONTAINER  = GO_CONT
                              IMPORTING R_SALV_TABLE = GO_SALV
                              CHANGING  T_TABLE      = GT_ALV ).

      DATA(LO_FUNC) = GO_SALV->GET_FUNCTIONS( ).
      LO_FUNC->SET_ALL( ABAP_TRUE ).
      LO_FUNC->ADD_FUNCTION( NAME     = 'ZPREV'
                             ICON     = CONV #( ICON_LAYOUT_CONTROL )
                             TEXT     = 'Xem trước bản in'                         "#EC NOTEXT
                             TOOLTIP  = 'Xem trước bản in các dòng được chọn'      "#EC NOTEXT
                             POSITION = IF_SALV_C_FUNCTION_POSITION=>LEFT_OF_SALV_FUNCTIONS ).
      LO_FUNC->ADD_FUNCTION( NAME     = 'ZPRINT'
                             ICON     = CONV #( ICON_PRINT )
                             TEXT     = 'In phiếu'                                 "#EC NOTEXT
                             TOOLTIP  = 'In phiếu ra máy in mặc định'              "#EC NOTEXT
                             POSITION = IF_SALV_C_FUNCTION_POSITION=>LEFT_OF_SALV_FUNCTIONS ).
      LO_FUNC->ADD_FUNCTION( NAME     = 'ZHOLD'
                             ICON     = CONV #( ICON_DETAIL )
                             TEXT     = 'Chi tiết giữ tồn'                         "#EC NOTEXT
                             TOOLTIP  = 'Reservation/LSX đang giữ tồn và tồn theo Bin' "#EC NOTEXT
                             POSITION = IF_SALV_C_FUNCTION_POSITION=>LEFT_OF_SALV_FUNCTIONS ).
      LO_FUNC->ADD_FUNCTION( NAME     = 'ZSTOCK'
                             ICON     = CONV #( ICON_STOCK )
                             TEXT     = 'Tồn theo Storage Type'                    "#EC NOTEXT
                             TOOLTIP  = 'Tồn eWM theo Storage Type/Bin'            "#EC NOTEXT
                             POSITION = IF_SALV_C_FUNCTION_POSITION=>LEFT_OF_SALV_FUNCTIONS ).
      LO_FUNC->ADD_FUNCTION( NAME     = 'ZREFR'
                             ICON     = CONV #( ICON_REFRESH )
                             TEXT     = 'Làm mới'                                  "#EC NOTEXT
                             TOOLTIP  = 'Đọc lại tồn kho'                          "#EC NOTEXT
                             POSITION = IF_SALV_C_FUNCTION_POSITION=>LEFT_OF_SALV_FUNCTIONS ).
      LO_FUNC->ADD_FUNCTION( NAME     = 'ZSALL'
                             ICON     = CONV #( ICON_SELECT_ALL )
                             TEXT     = 'Chọn tất cả'                              "#EC NOTEXT
                             TOOLTIP  = 'Chọn tất cả dòng hợp lệ'                  "#EC NOTEXT
                             POSITION = IF_SALV_C_FUNCTION_POSITION=>LEFT_OF_SALV_FUNCTIONS ).
      LO_FUNC->ADD_FUNCTION( NAME     = 'ZDALL'
                             ICON     = CONV #( ICON_DESELECT_ALL )
                             TEXT     = 'Bỏ chọn'                                  "#EC NOTEXT
                             TOOLTIP  = 'Bỏ chọn tất cả'                           "#EC NOTEXT
                             POSITION = IF_SALV_C_FUNCTION_POSITION=>LEFT_OF_SALV_FUNCTIONS ).

      GO_SALV->GET_SELECTIONS( )->SET_SELECTION_MODE( IF_SALV_C_SELECTION_MODE=>SINGLE ).
      PERFORM FORMAT_ALV.

      PERFORM BUILD_HEADER CHANGING LV_HEAD.
      GO_SALV->GET_DISPLAY_SETTINGS( )->SET_LIST_HEADER( LV_HEAD ).
      GO_SALV->GET_DISPLAY_SETTINGS( )->SET_STRIPED_PATTERN( ABAP_TRUE ).

      DATA(LO_LAYOUT) = GO_SALV->GET_LAYOUT( ).
      LO_LAYOUT->SET_KEY( VALUE #( REPORT = SY-REPID ) ).
      LO_LAYOUT->SET_SAVE_RESTRICTION( IF_SALV_C_LAYOUT=>RESTRICT_NONE ).

      DATA(LO_EVT) = GO_SALV->GET_EVENT( ).
      SET HANDLER LCL_EVT=>ON_FUNC FOR LO_EVT.
      SET HANDLER LCL_EVT=>ON_LINK FOR LO_EVT.

      GO_SALV->DISPLAY( ).

    CATCH CX_SALV_ERROR INTO DATA(LX_SALV).
      MESSAGE LX_SALV->GET_TEXT( ) TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FORMAT_ALV
*&---------------------------------------------------------------------*
*       Cột theo thứ tự mô tả của màn hình trung gian
*----------------------------------------------------------------------*
FORM FORMAT_ALV.

  TYPES: BEGIN OF LTY_COL,
           NAME TYPE LVC_FNAME,
           TEXT TYPE SCRTEXT_L,
         END OF LTY_COL,
         LTT_COL TYPE STANDARD TABLE OF LTY_COL WITH EMPTY KEY.

  DATA: LO_COL TYPE REF TO CL_SALV_COLUMN_TABLE,
        LV_POS TYPE I.

  DATA(LT_COL) = VALUE LTT_COL(
    ( NAME = 'SEL'          TEXT = 'Chọn' )
    ( NAME = 'LIGHT'        TEXT = 'Đèn' )
    ( NAME = 'RSNUM'        TEXT = 'Reservation' )
    ( NAME = 'RSPOS'        TEXT = 'Item' )
    ( NAME = 'AUFNR'        TEXT = 'Lệnh SX' )
    ( NAME = 'MATNR'        TEXT = 'Mã hàng' )
    ( NAME = 'MAKTX'        TEXT = 'Tên hàng' )
    ( NAME = 'EMATN'        TEXT = 'Mã NSX (MPN)' )
    ( NAME = 'CHARG'        TEXT = 'Batch' )
    ( NAME = 'OPEN_QTY'     TEXT = 'SL còn yêu cầu' )
    ( NAME = 'ERFME'        TEXT = 'ĐVT' )
    ( NAME = 'LGORT'        TEXT = 'Kho xuất' )
    ( NAME = 'IM_STOCK'     TEXT = 'Tồn IM (SLoc)' )
    ( NAME = 'EWM_PHYS'     TEXT = 'Tồn vật lý eWM' )
    ( NAME = 'EWM_AVAIL'    TEXT = 'Tồn khả dụng eWM' )
    ( NAME = 'PSA_STOCK'    TEXT = 'Tồn tại PSA' )
    ( NAME = 'OTHER_REQ'    TEXT = 'Đang giữ cho YC khác' )
    ( NAME = 'TRANSFER_QTY' TEXT = 'SL cần điều chuyển' )
    ( NAME = 'STATUS_TEXT'  TEXT = 'Tình trạng' )
    ( NAME = 'LGNUM'        TEXT = 'Warehouse' ) ).                          "#EC NOTEXT

  DATA(LO_COLS) = GO_SALV->GET_COLUMNS( ).
  LO_COLS->SET_OPTIMIZE( ABAP_TRUE ).

  TRY.
      LOOP AT LO_COLS->GET( ) INTO DATA(LS_REF).
        LS_REF-R_COLUMN->SET_VISIBLE( ABAP_FALSE ).
      ENDLOOP.

      LOOP AT LT_COL INTO DATA(LS_COL).
        LV_POS = LV_POS + 1.
        LO_COL ?= LO_COLS->GET_COLUMN( LS_COL-NAME ).
        LO_COL->SET_VISIBLE( ABAP_TRUE ).
        LO_COL->SET_LONG_TEXT( LS_COL-TEXT ).
        LO_COL->SET_MEDIUM_TEXT( CONV SCRTEXT_M( LS_COL-TEXT ) ).
        LO_COL->SET_SHORT_TEXT( CONV SCRTEXT_S( LS_COL-TEXT ) ).
        LO_COLS->SET_COLUMN_POSITION( COLUMNNAME = LS_COL-NAME POSITION = LV_POS ).
      ENDLOOP.

      LO_COL ?= LO_COLS->GET_COLUMN( 'SEL' ).
      LO_COL->SET_CELL_TYPE( IF_SALV_C_CELL_TYPE=>CHECKBOX_HOTSPOT ).
      LO_COL ?= LO_COLS->GET_COLUMN( 'LIGHT' ).
      LO_COL->SET_ICON( IF_SALV_C_BOOL_SAP=>TRUE ).
      " Warehouse đã có ở dòng tiêu đề, để trong layout
      LO_COL ?= LO_COLS->GET_COLUMN( 'LGNUM' ).
      LO_COL->SET_VISIBLE( ABAP_FALSE ).

    CATCH CX_SALV_NOT_FOUND.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BUILD_HEADER
*&---------------------------------------------------------------------*
*       Dòng thông tin đầu màn hình: loại phiếu | Plant | Warehouse | Lệnh
*----------------------------------------------------------------------*
FORM BUILD_HEADER CHANGING CV_HEAD TYPE LVC_TITLE.

  DATA: LV_TXT   TYPE STRING,
        LV_AUFNR TYPE AUFNR.

  LV_TXT = SWITCH STRING( GV_DOC_TYPE
             WHEN GC_TYPE_PROD THEN '(1) Lệnh sản xuất'
             WHEN GC_TYPE_SUPP THEN '(2) Bổ sung cho sản xuất'
             ELSE '(3) Bộ phận khác' ).                                     "#EC NOTEXT
  LV_TXT = |Loại phiếu: { LV_TXT }|.                                        "#EC NOTEXT

  READ TABLE GT_ALV INTO DATA(LS_FIRST) INDEX 1.
  CHECK SY-SUBRC = 0.

  DATA(LV_ONE_PLANT) = ABAP_TRUE.
  DATA(LV_ONE_WH)    = ABAP_TRUE.
  DATA(LV_ONE_ORD)   = ABAP_TRUE.
  LOOP AT GT_ALV INTO DATA(LS_A).
    IF LS_A-WERKS <> LS_FIRST-WERKS.
      LV_ONE_PLANT = ABAP_FALSE.
    ENDIF.
    IF LS_A-LGNUM <> LS_FIRST-LGNUM.
      LV_ONE_WH = ABAP_FALSE.
    ENDIF.
    IF LS_A-AUFNR <> LS_FIRST-AUFNR.
      LV_ONE_ORD = ABAP_FALSE.
    ENDIF.
  ENDLOOP.

  IF LV_ONE_PLANT = ABAP_TRUE.
    LV_TXT = |{ LV_TXT } \| Plant { LS_FIRST-WERKS }|.                       "#EC NOTEXT
  ENDIF.
  IF LV_ONE_WH = ABAP_TRUE AND LS_FIRST-LGNUM IS NOT INITIAL.
    LV_TXT = |{ LV_TXT } \| Warehouse { LS_FIRST-LGNUM }|.                   "#EC NOTEXT
  ENDIF.
  IF LV_ONE_ORD = ABAP_TRUE AND LS_FIRST-AUFNR IS NOT INITIAL.
    LV_AUFNR = LS_FIRST-AUFNR.
    SHIFT LV_AUFNR LEFT DELETING LEADING '0'.
    LV_TXT = |{ LV_TXT } \| Lệnh { LV_AUFNR }|.                              "#EC NOTEXT
    READ TABLE GT_AFPO INTO DATA(LS_AFPO) WITH TABLE KEY AUFNR = LS_FIRST-AUFNR.
    IF SY-SUBRC = 0.
      LV_TXT = |{ LV_TXT } – { LS_AFPO-MAKTX } (Lô TP { LS_AFPO-CHARG })|.   "#EC NOTEXT
    ENDIF.
  ENDIF.

  CV_HEAD = LV_TXT.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SHOW_START_MESSAGE
*&---------------------------------------------------------------------*
*       Thông báo khi mở màn hình trung gian
*----------------------------------------------------------------------*
FORM SHOW_START_MESSAGE.

  IF GV_NOPSA IS NOT INITIAL.
    MESSAGE S007(ZWM01) WITH 'Storage Type PSA' GV_NOPSA DISPLAY LIKE 'W'.  "#EC NOTEXT
  ENDIF.

  READ TABLE GT_ALV INTO DATA(LS_A) WITH KEY LIGHT = ICON_LIGHT_OUT.
  IF SY-SUBRC = 0.
    MESSAGE S003(ZWM01) WITH LS_A-RSNUM LS_A-RSPOS LS_A-MATNR DISPLAY LIKE 'W'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FREE_CONTROLS
*&---------------------------------------------------------------------*
FORM FREE_CONTROLS.

  IF GO_DLG IS BOUND.
    GO_DLG->FREE( EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  IF GO_CONT IS BOUND.
    GO_CONT->FREE( EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  CLEAR: GO_DLG, GO_SALV_1, GO_SALV_2, GO_SALV, GO_CONT.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  HANDLE_LINK
*&---------------------------------------------------------------------*
*       Nhấp ô Chọn: đổi chọn / bỏ chọn; dòng đèn xám không cho chọn
*----------------------------------------------------------------------*
FORM HANDLE_LINK USING IV_ROW    TYPE SALV_DE_ROW
                       IV_COLUMN TYPE SALV_DE_COLUMN.

  CHECK IV_COLUMN = 'SEL'.
  READ TABLE GT_ALV ASSIGNING FIELD-SYMBOL(<LFS_A>) INDEX IV_ROW.
  CHECK SY-SUBRC = 0.

  IF <LFS_A>-LIGHT = ICON_LIGHT_OUT.
    MESSAGE S003(ZWM01) WITH <LFS_A>-RSNUM <LFS_A>-RSPOS <LFS_A>-MATNR DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  IF <LFS_A>-SEL = ABAP_TRUE.
    CLEAR <LFS_A>-SEL.
  ELSE.
    <LFS_A>-SEL = ABAP_TRUE.
  ENDIF.
  GO_SALV->REFRESH( ).

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  HANDLE_FUNCTION
*&---------------------------------------------------------------------*
*       Nút trên màn hình trung gian
*----------------------------------------------------------------------*
FORM HANDLE_FUNCTION USING IV_FUNC TYPE SALV_DE_FUNCTION.

  DATA LV_PREVIEW TYPE ABAP_BOOL.

  CASE IV_FUNC.
    WHEN 'ZPREV' OR 'ZPRINT'.
      PERFORM COLLECT_SELECTED.
      IF GT_PRINT IS INITIAL.
        MESSAGE S004(ZWM01) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
      IF IV_FUNC = 'ZPREV'.
        LV_PREVIEW = ABAP_TRUE.
      ENDIF.
      PERFORM EXPORT_DATA USING LV_PREVIEW.

    WHEN 'ZHOLD'.
      PERFORM SHOW_HOLD_DETAIL.

    WHEN 'ZSTOCK'.
      PERFORM SHOW_STOCK_BY_TYPE.

    WHEN 'ZREFR'.
      PERFORM CHECK_READINESS.
      GO_SALV->REFRESH( ).

    WHEN 'ZSALL'.
      LOOP AT GT_ALV ASSIGNING FIELD-SYMBOL(<LFS_A>) WHERE LIGHT <> ICON_LIGHT_OUT.
        <LFS_A>-SEL = ABAP_TRUE.
      ENDLOOP.
      GO_SALV->REFRESH( ).

    WHEN 'ZDALL'.
      LOOP AT GT_ALV ASSIGNING <LFS_A>.
        CLEAR <LFS_A>-SEL.
      ENDLOOP.
      GO_SALV->REFRESH( ).
  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  COLLECT_SELECTED
*&---------------------------------------------------------------------*
*       Dòng được chọn ở màn hình trung gian (số lượng in theo ĐVT nhập liệu)
*----------------------------------------------------------------------*
FORM COLLECT_SELECTED.

  CLEAR GT_PRINT.
  LOOP AT GT_ALV INTO DATA(LS_A) WHERE SEL = ABAP_TRUE AND LIGHT <> ICON_LIGHT_OUT.
    READ TABLE GT_PREDATA INTO DATA(LS_P) WITH KEY RSNUM = LS_A-RSNUM
                                                   RSPOS = LS_A-RSPOS.
    IF SY-SUBRC = 0.
      APPEND LS_P TO GT_PRINT.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  GET_CURRENT_ROW
*&---------------------------------------------------------------------*
FORM GET_CURRENT_ROW CHANGING CV_ROW TYPE I.

  CLEAR CV_ROW.
  DATA(LO_SEL) = GO_SALV->GET_SELECTIONS( ).
  DATA(LT_ROWS) = LO_SEL->GET_SELECTED_ROWS( ).
  IF LT_ROWS IS NOT INITIAL.
    CV_ROW = LT_ROWS[ 1 ].
  ELSE.
    CV_ROW = LO_SEL->GET_CURRENT_CELL( )-ROW.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BUILD_BIN_LIST
*&---------------------------------------------------------------------*
*       Tồn eWM theo Storage Type / Bin của vật tư (theo Batch nếu dòng có Batch)
*----------------------------------------------------------------------*
FORM BUILD_BIN_LIST USING IS_LINE TYPE ZWM_ST_PYCVT.

  DATA LS_BIN TYPE GTY_BIN.

  CLEAR GT_BIN_D.
  CHECK IS_LINE-LGNUM IS NOT INITIAL.

  LOOP AT GT_EWM INTO DATA(LS_E) WHERE LGNUM = IS_LINE-LGNUM
                                   AND MATNR = IS_LINE-MATNR.
    IF IS_LINE-CHARG IS NOT INITIAL AND LS_E-CHARG <> IS_LINE-CHARG.
      CONTINUE.
    ENDIF.
    CLEAR LS_BIN.
    LS_BIN-LGNUM   = LS_E-LGNUM.
    LS_BIN-LGTYP   = LS_E-LGTYP.
    LS_BIN-LGPLA   = LS_E-LGPLA.
    LS_BIN-CHARG   = LS_E-CHARG.
    LS_BIN-CAT     = LS_E-CAT.
    LS_BIN-CAT_TXT = |{ LS_E-CAT } – { LS_E-CAT_TXT }|.
    LS_BIN-PHYS    = LS_E-QUAN.
    IF LS_E-QUAN > LS_E-PICK.
      LS_BIN-AVAIL = LS_E-QUAN - LS_E-PICK.
    ENDIF.
    LS_BIN-MEINS   = LS_E-MEINS.
    APPEND LS_BIN TO GT_BIN_D.
  ENDLOOP.
  SORT GT_BIN_D BY LGTYP LGPLA CHARG.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SHOW_HOLD_DETAIL
*&---------------------------------------------------------------------*
*       Popup: Reservation/LSX đang giữ tồn (có dòng tổng) và tồn theo Bin
*----------------------------------------------------------------------*
FORM SHOW_HOLD_DETAIL.

  DATA: LV_ROW     TYPE I,
        LV_YES     TYPE ABAP_BOOL,
        LV_CAPTION TYPE C LENGTH 150.

  PERFORM GET_CURRENT_ROW CHANGING LV_ROW.
  READ TABLE GT_ALV INTO DATA(LS_A) INDEX LV_ROW.
  IF SY-SUBRC <> 0.
    MESSAGE 'Vui lòng chọn một dòng' TYPE 'S' DISPLAY LIKE 'E'.             "#EC NOTEXT
    RETURN.
  ENDIF.

  CLEAR GT_HOLD_D.
  LOOP AT GT_HOLD INTO DATA(LS_H) WHERE MATNR = LS_A-MATNR
                                    AND WERKS = LS_A-WERKS
                                    AND LGORT = LS_A-LGORT.
    PERFORM IS_HOLDING USING LS_A LS_H CHANGING LV_YES.
    IF LV_YES = ABAP_TRUE.
      APPEND LS_H TO GT_HOLD_D.
    ENDIF.
  ENDLOOP.
  SORT GT_HOLD_D BY BDTER RSNUM RSPOS.

  PERFORM BUILD_BIN_LIST USING LS_A.

  LV_CAPTION = |Chi tiết tồn kho đang được giữ – { LS_A-MATNR ALPHA = OUT } { LS_A-MAKTX }|. "#EC NOTEXT
  IF LS_A-CHARG IS NOT INITIAL.
    LV_CAPTION = |{ LV_CAPTION } / Batch { LS_A-CHARG }|.                   "#EC NOTEXT
  ENDIF.
  LV_CAPTION = |{ LV_CAPTION } / Plant { LS_A-WERKS } – SLoc { LS_A-LGORT }|. "#EC NOTEXT

  IF GO_DLG IS BOUND.
    GO_DLG->FREE( EXCEPTIONS OTHERS = 1 ).
    CLEAR: GO_DLG, GO_SALV_1, GO_SALV_2.
  ENDIF.

  CREATE OBJECT GO_DLG
    EXPORTING
      WIDTH   = 1100
      HEIGHT  = 380
      TOP     = 60
      LEFT    = 60
      CAPTION = LV_CAPTION
    EXCEPTIONS
      OTHERS  = 1.
  IF SY-SUBRC <> 0.
    RETURN.
  ENDIF.
  SET HANDLER LCL_EVT=>ON_CLOSE FOR GO_DLG.

  DATA(LO_SPLIT) = NEW CL_GUI_SPLITTER_CONTAINER( PARENT  = GO_DLG
                                                  ROWS    = 2
                                                  COLUMNS = 1 ).

  TRY.
      CL_SALV_TABLE=>FACTORY( EXPORTING R_CONTAINER  = LO_SPLIT->GET_CONTAINER( ROW = 1 COLUMN = 1 )
                              IMPORTING R_SALV_TABLE = GO_SALV_1
                              CHANGING  T_TABLE      = GT_HOLD_D ).
      PERFORM FORMAT_HOLD_ALV USING GO_SALV_1.
      GO_SALV_1->DISPLAY( ).

      CL_SALV_TABLE=>FACTORY( EXPORTING R_CONTAINER  = LO_SPLIT->GET_CONTAINER( ROW = 2 COLUMN = 1 )
                              IMPORTING R_SALV_TABLE = GO_SALV_2
                              CHANGING  T_TABLE      = GT_BIN_D ).
      PERFORM FORMAT_BIN_ALV USING GO_SALV_2.
      GO_SALV_2->DISPLAY( ).

    CATCH CX_SALV_ERROR INTO DATA(LX_SALV).
      MESSAGE LX_SALV->GET_TEXT( ) TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SHOW_STOCK_BY_TYPE
*&---------------------------------------------------------------------*
*       Popup: tồn eWM theo Storage Type / Bin, có dòng tổng theo Storage Type
*----------------------------------------------------------------------*
FORM SHOW_STOCK_BY_TYPE.

  DATA: LV_ROW  TYPE I,
        LO_POP  TYPE REF TO CL_SALV_TABLE,
        LV_HEAD TYPE LVC_TITLE.

  PERFORM GET_CURRENT_ROW CHANGING LV_ROW.
  READ TABLE GT_ALV INTO DATA(LS_A) INDEX LV_ROW.
  IF SY-SUBRC <> 0.
    MESSAGE 'Vui lòng chọn một dòng' TYPE 'S' DISPLAY LIKE 'E'.             "#EC NOTEXT
    RETURN.
  ENDIF.

  PERFORM BUILD_BIN_LIST USING LS_A.
  IF GT_BIN_D IS INITIAL.
    MESSAGE 'Không có tồn eWM của vật tư này' TYPE 'S' DISPLAY LIKE 'W'.    "#EC NOTEXT
    RETURN.
  ENDIF.

  LV_HEAD = |Tồn theo Storage Type – { LS_A-MATNR ALPHA = OUT } { LS_A-MAKTX }|. "#EC NOTEXT

  TRY.
      CL_SALV_TABLE=>FACTORY( IMPORTING R_SALV_TABLE = LO_POP
                              CHANGING  T_TABLE      = GT_BIN_D ).
      PERFORM FORMAT_BIN_ALV USING LO_POP.
      LO_POP->GET_SORTS( )->ADD_SORT( COLUMNNAME = 'LGTYP' SUBTOTAL = ABAP_TRUE ).
      LO_POP->GET_AGGREGATIONS( )->ADD_AGGREGATION( COLUMNNAME = 'PHYS' ).
      LO_POP->GET_AGGREGATIONS( )->ADD_AGGREGATION( COLUMNNAME = 'AVAIL' ).
      LO_POP->GET_DISPLAY_SETTINGS( )->SET_LIST_HEADER( LV_HEAD ).
      LO_POP->SET_SCREEN_POPUP( START_COLUMN = 5
                                END_COLUMN   = 150
                                START_LINE   = 3
                                END_LINE     = 20 ).
      LO_POP->DISPLAY( ).
    CATCH CX_SALV_ERROR INTO DATA(LX_SALV).
      MESSAGE LX_SALV->GET_TEXT( ) TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FORMAT_HOLD_ALV
*&---------------------------------------------------------------------*
FORM FORMAT_HOLD_ALV USING IO_SALV TYPE REF TO CL_SALV_TABLE.

  DATA LO_COL TYPE REF TO CL_SALV_COLUMN_TABLE.

  IO_SALV->GET_FUNCTIONS( )->SET_ALL( ABAP_FALSE ).
  DATA(LO_COLS) = IO_SALV->GET_COLUMNS( ).
  LO_COLS->SET_OPTIMIZE( ABAP_TRUE ).

  TRY.
      LO_COLS->GET_COLUMN( 'MATNR' )->SET_VISIBLE( ABAP_FALSE ).
      LO_COLS->GET_COLUMN( 'WERKS' )->SET_VISIBLE( ABAP_FALSE ).
      LO_COLS->GET_COLUMN( 'LGORT' )->SET_VISIBLE( ABAP_FALSE ).
      LO_COLS->GET_COLUMN( 'CHARG' )->SET_VISIBLE( ABAP_FALSE ).
      LO_COLS->GET_COLUMN( 'AUTYP' )->SET_VISIBLE( ABAP_FALSE ).

      LO_COLS->GET_COLUMN( 'AUFNR' )->SET_LONG_TEXT( 'Lệnh SX' ).            "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'AUFNR' )->SET_MEDIUM_TEXT( 'Lệnh SX' ).          "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'AUFNR' )->SET_SHORT_TEXT( 'Lệnh SX' ).           "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'LOAI' )->SET_LONG_TEXT( 'Loại' ).                "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'LOAI' )->SET_MEDIUM_TEXT( 'Loại' ).              "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'LOAI' )->SET_SHORT_TEXT( 'Loại' ).               "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'BDTER' )->SET_LONG_TEXT( 'Ngày yêu cầu' ).       "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'BDTER' )->SET_MEDIUM_TEXT( 'Ngày yêu cầu' ).     "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'BDTER' )->SET_SHORT_TEXT( 'Ngày YC' ).           "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'USNAM' )->SET_LONG_TEXT( 'Người tạo' ).          "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'USNAM' )->SET_MEDIUM_TEXT( 'Người tạo' ).        "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'USNAM' )->SET_SHORT_TEXT( 'Người tạo' ).         "#EC NOTEXT

      LO_COL ?= LO_COLS->GET_COLUMN( 'OPEN_QTY' ).
      LO_COL->SET_LONG_TEXT( 'SL còn giữ' ).                                 "#EC NOTEXT
      LO_COL->SET_MEDIUM_TEXT( 'SL còn giữ' ).                               "#EC NOTEXT
      LO_COL->SET_SHORT_TEXT( 'SL còn giữ' ).                                "#EC NOTEXT
      LO_COL->SET_QUANTITY_COLUMN( 'MEINS' ).

      IO_SALV->GET_AGGREGATIONS( )->ADD_AGGREGATION( COLUMNNAME = 'OPEN_QTY' ).
    CATCH CX_SALV_ERROR.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FORMAT_BIN_ALV
*&---------------------------------------------------------------------*
FORM FORMAT_BIN_ALV USING IO_SALV TYPE REF TO CL_SALV_TABLE.

  DATA LO_COL TYPE REF TO CL_SALV_COLUMN_TABLE.

  DATA(LO_COLS) = IO_SALV->GET_COLUMNS( ).
  LO_COLS->SET_OPTIMIZE( ABAP_TRUE ).

  TRY.
      LO_COLS->GET_COLUMN( 'CAT' )->SET_VISIBLE( ABAP_FALSE ).
      LO_COLS->GET_COLUMN( 'CAT_TXT' )->SET_LONG_TEXT( 'Stock Type' ).       "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'CAT_TXT' )->SET_MEDIUM_TEXT( 'Stock Type' ).     "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'CAT_TXT' )->SET_SHORT_TEXT( 'StockType' ).       "#EC NOTEXT

      LO_COL ?= LO_COLS->GET_COLUMN( 'PHYS' ).
      LO_COL->SET_LONG_TEXT( 'Tồn vật lý' ).                                 "#EC NOTEXT
      LO_COL->SET_MEDIUM_TEXT( 'Tồn vật lý' ).                               "#EC NOTEXT
      LO_COL->SET_SHORT_TEXT( 'Tồn VL' ).                                    "#EC NOTEXT
      LO_COL->SET_QUANTITY_COLUMN( 'MEINS' ).

      LO_COL ?= LO_COLS->GET_COLUMN( 'AVAIL' ).
      LO_COL->SET_LONG_TEXT( 'Tồn khả dụng' ).                               "#EC NOTEXT
      LO_COL->SET_MEDIUM_TEXT( 'Tồn khả dụng' ).                             "#EC NOTEXT
      LO_COL->SET_SHORT_TEXT( 'Khả dụng' ).                                  "#EC NOTEXT
      LO_COL->SET_QUANTITY_COLUMN( 'MEINS' ).
    CATCH CX_SALV_NOT_FOUND CX_SALV_DATA_ERROR.
  ENDTRY.

ENDFORM.
