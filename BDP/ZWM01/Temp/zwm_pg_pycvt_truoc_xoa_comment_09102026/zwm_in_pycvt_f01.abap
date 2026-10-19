*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PYCVT_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  INIT_SELECTION
*&---------------------------------------------------------------------*
*       Plant mặc định theo parameter ID WRK
*----------------------------------------------------------------------*
FORM INIT_SELECTION .
  DATA LV_WERKS TYPE WERKS_D.

  " Nhãn màn hình chọn
  GV_T01  = 'Loại phiếu'.                                                          "#EC NOTEXT
  GV_T02  = 'Điều kiện chọn dữ liệu'.                                              "#EC NOTEXT
  GV_T03  = 'Trạng thái dòng yêu cầu'.                                             "#EC NOTEXT
  GV_T04  = 'Tùy chọn'.                                                            "#EC NOTEXT
  GV_C_T1 = '(1) Yêu cầu vật tư cho Lệnh sản xuất - Bắt buộc có Batch'.            "#EC NOTEXT
  GV_C_T2 = '(2) Yêu cầu vật tư bổ sung cho SX (ngoài BOM) - Bắt buộc có Batch'.   "#EC NOTEXT
  GV_C_T3 = '(3) Yêu cầu vật tư cho bộ phận khác (Reservation) - Không cần Batch'.   "#EC NOTEXT
  GV_C_OP = 'Đang mở (còn số lượng chưa xuất)'.                                    "#EC NOTEXT
  GV_C_DO = 'Đã hoàn tất'.                                                         "#EC NOTEXT
  GV_C_AL = 'Tất cả'.                                                              "#EC NOTEXT
  GV_C_KT = 'Kiểm tra sự sẵn sàng của vật tư (hiển thị màn hình trung gian)'.      "#EC NOTEXT
  GV_C_MP = 'Chi tiết theo Nhà sản xuất (MPN) nếu Lệnh sản xuất có thông tin'.     "#EC NOTEXT
  GV_C_SN = 'In song ngữ (Việt - Anh)'.                                            "#EC NOTEXT
  %_S_WERKS_%_APP_%-TEXT = 'Plant'.                                                "#EC NOTEXT
  %_S_RSNUM_%_APP_%-TEXT = 'Số phiếu yêu cầu (Reservation)'.                       "#EC NOTEXT
  %_S_AUFNR_%_APP_%-TEXT = 'Lệnh sản xuất (loại 1, 2)'.                            "#EC NOTEXT
  %_S_AUART_%_APP_%-TEXT = 'Loại lệnh (Order Type)'.                               "#EC NOTEXT
  %_S_LGORT_%_APP_%-TEXT = 'Kho xuất (Storage Location)'.                          "#EC NOTEXT
  %_S_BWART_%_APP_%-TEXT = 'Movement Type'.                                        "#EC NOTEXT
  %_S_BDTER_%_APP_%-TEXT = 'Ngày yêu cầu'.                                         "#EC NOTEXT
  %_S_KOSTL_%_APP_%-TEXT = 'Cost Center nhận (loại 3)'.                            "#EC NOTEXT
  %_S_USNAM_%_APP_%-TEXT = 'Người tạo'.                                            "#EC NOTEXT

  GET PARAMETER ID 'WRK' FIELD LV_WERKS.
  IF LV_WERKS IS NOT INITIAL AND S_WERKS[] IS INITIAL.
    S_WERKS-SIGN   = 'I'.
    S_WERKS-OPTION = 'EQ'.
    S_WERKS-LOW    = LV_WERKS.
    APPEND S_WERKS.
  ENDIF.
ENDFORM.                    " INIT_SELECTION

*&---------------------------------------------------------------------*
*&      Form  MODIFY_SCREEN
*&---------------------------------------------------------------------*
*       Lệnh SX / Loại lệnh chỉ dùng cho phiếu theo Lệnh SX và phiếu bổ sung; Cost Center chỉ cho phiếu bộ phận khác
*----------------------------------------------------------------------*
*FORM MODIFY_SCREEN .
*  LOOP AT SCREEN.
*    CASE SCREEN-GROUP1.
*      WHEN 'PRD'.
*        IF P_T3 = ABAP_TRUE.
*          SCREEN-ACTIVE = 0.
*        ELSE.
*          SCREEN-ACTIVE = 1.
*        ENDIF.
*      WHEN 'OTH'.
*        IF P_T3 = ABAP_TRUE.
*          SCREEN-ACTIVE = 1.
*        ELSE.
*          SCREEN-ACTIVE = 0.
*        ENDIF.
*    ENDCASE.
*    MODIFY SCREEN.
*  ENDLOOP.
*ENDFORM.                    " MODIFY_SCREEN

*&---------------------------------------------------------------------*
*&      Form  VALIDATE_SELECTION
*&---------------------------------------------------------------------*
*       phải nhập ít nhất một trong Số phiếu / Lệnh SX / Ngày yêu cầu
*       báo lỗi nếu nhập Cost Center mà không phải phiếu bộ phận khác
*----------------------------------------------------------------------*
FORM VALIDATE_SELECTION .
  CHECK SY-UCOMM = 'ONLI'.

  IF S_RSNUM[] IS INITIAL AND S_AUFNR[] IS INITIAL AND S_BDTER[] IS INITIAL.
    MESSAGE E001(ZWM01).
  ENDIF.

  IF P_T3 IS INITIAL AND S_KOSTL[] IS NOT INITIAL.
    MESSAGE E398(00) WITH 'Cost Center chỉ áp dụng cho phiếu cho bộ phận khác' '' '' ''.
  ENDIF.
ENDFORM.                    " VALIDATE_SELECTION

*&---------------------------------------------------------------------*
*&      Form  DETERMINE_DOC_TYPE
*&---------------------------------------------------------------------*
FORM DETERMINE_DOC_TYPE .
  IF P_T2 = ABAP_TRUE.
    GV_DOC_TYPE = GC_TYPE_SUPP.
  ELSEIF P_T3 = ABAP_TRUE.
    GV_DOC_TYPE = GC_TYPE_OTHER.
  ELSE.
    GV_DOC_TYPE = GC_TYPE_PROD.
  ENDIF.
ENDFORM.                    " DETERMINE_DOC_TYPE

*&---------------------------------------------------------------------*
*&      Form  FILL_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_DATA .
*  Check Authentication
*RANGES: LSU_WERKS  FOR RESB-WERKS.
*DATA: LW_TABIX Like sy-tabix.
***Authentication data checking
*  SELECT
*    T001W~WERKS AS LOW
*    INTO CORRESPONDING FIELDS OF TABLE LSU_WERKS
*  FROM
*    T001W.
*
*  LOOP AT LSU_WERKS.
*    LW_TABIX = sy-tabix.
*    AUTHORITY-CHECK OBJECT 'M_MRES_WWA'
*                ID 'ACTVT' FIELD '03'
*                ID 'WERKS' FIELD LSU_WERKS-LOW.
*    IF SY-SUBRC <> 0.
*      DELETE LSU_WERKS[] INDEX LW_TABIX.
*    ELSE.
*      AUTHORITY-CHECK OBJECT 'M_MSEG_WMB'
*                  ID 'ACTVT' FIELD '03'
*                  ID 'WERKS' FIELD LSU_WERKS-LOW.
*      IF SY-SUBRC <> 0.
*        DELETE LSU_WERKS[] INDEX LW_TABIX.
*      ELSE.
*        LSU_WERKS-SIGN   = 'I'.
*        LSU_WERKS-OPTION = 'EQ'.
*        MODIFY LSU_WERKS INDEX LW_TABIX.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.

*  SELECT
*    RESB~WERKS  "PLANT
*    RESB~RSNUM  "Number of Reservation/Dependent Requirement
*    RKPF~RSDAT  "NGAY YEU CAU
*    RKPF~KUNNR  "DON VI NHAN 1
*    RKPF~KOSTL  "DON VI NHAN 2
*    CSKT~LTEXT  "DON VI NHAN 3
*    RKPF~ANLN1  "DON VI NHAN 4
*    RKPF~AUFNR  "DON VI NHAN 5
*    RESB~UMLGO  "Đơn vị nhận 6
*    RESB~LGORT  "Đơn vị xuất
*    T001L~LGOBE "DIEN GIAI KHO
*    RKPF~WEMPF  "NGUOI YEU CAU 1
*    RKPF~USNAM  "NGUOI YEU CAU 2
*    RESB~SGTXT  "DIEN GIAI
*    RESB~MATNR  "Material Number
*    MAKT~MAKTX  "Material Description
**    RESB~MEINS  "DON VI TINH
*    RESB~ERFME
*    RESB~BDMNG  "Requirement Quantity
*    RESB~RSPOS  "STT
*    RESB~ABLAD  "UPLOADING POINT
*    AFIH~EQUNR  "THIET BI
*    RESB~BWART  "MOVEMENT TYPE
*    RESB~SOBKZ  "PHAN CHU CUA MOVEMENT TYPE
*    RESB~ENMNG  "SO LUONG THUC XUAT
*    RESB~ERFMG
*    MARA~MTART
*  INTO CORRESPONDING FIELDS OF TABLE GT_PREDATA
*  FROM RESB
*      LEFT  JOIN T001L ON T001L~WERKS = RESB~WERKS AND T001L~LGORT = RESB~LGORT
*      INNER JOIN RKPF  ON RESB~RSNUM  = RKPF~RSNUM
*      INNER JOIN MARA  ON MARA~MATNR  = RESB~MATNR
*      INNER JOIN MAKT  ON MAKT~MATNR  = RESB~MATNR AND MAKT~SPRAS = 'E'
*      LEFT  JOIN AFIH  ON RESB~AUFNR  = AFIH~AUFNR
*      LEFT  JOIN CSKT  ON CSKT~KOKRS  = 'BDFC' AND CSKT~KOSTL = RKPF~KOSTL AND CSKT~DATBI GE SY-DATUM AND CSKT~SPRAS = SY-LANGU
*  WHERE RESB~RSNUM IN S_RSNUM
*    AND RESB~XLOEK NE 'X'
**    AND RESB~KZEAR NE 'X'
*    AND RESB~POSTP NE 'N'.
**    AND RESB~WERKS IN LSU_WERKS.
*
*  IF SY-SUBRC <> 0.
*    MESSAGE 'No data found' TYPE 'I'.
*    STOP.
*  ENDIF.

  " Đọc Reservation: lọc theo loại phiếu (Order Category 10/40 = lệnh PP/PP-PI),
  " trạng thái dòng (KZEAR/ENMNG), loại trừ dòng xóa và dòng non-stock.
  " AUFNR lấy từ RESB; RKPF-AUFNR không dùng nữa.
  SELECT RESB~WERKS, RESB~RSNUM, RKPF~RSDAT, RKPF~KUNNR, RKPF~KOSTL, CSKT~LTEXT,
         RKPF~ANLN1, RESB~AUFNR, AUFK~AUART, RESB~UMLGO, RESB~LGORT, T001L~LGOBE,
         RKPF~WEMPF, RKPF~USNAM, RESB~SGTXT, RESB~MATNR, MAKT~MAKTX, RESB~MEINS,
         RESB~ERFME, RESB~BDMNG, RESB~RSPOS, RESB~ABLAD, AFIH~EQUNR, RESB~BWART,
         RESB~SOBKZ, RESB~ENMNG, RESB~ERFMG, MARA~MTART, RESB~CHARG,
         RESB~STLNR, RESB~STLKN, RESB~BDTER, RESB~POSTP, RESB~XLOEK
    FROM RESB
    LEFT OUTER JOIN T001L ON T001L~WERKS = RESB~WERKS
                         AND T001L~LGORT = RESB~LGORT
    INNER JOIN RKPF ON RESB~RSNUM = RKPF~RSNUM
    INNER JOIN MARA ON MARA~MATNR = RESB~MATNR
    INNER JOIN MAKT ON MAKT~MATNR = RESB~MATNR
                   AND MAKT~SPRAS = 'E'
    LEFT OUTER JOIN AFIH ON RESB~AUFNR = AFIH~AUFNR
    LEFT OUTER JOIN AUFK ON AUFK~AUFNR = RESB~AUFNR
    LEFT OUTER JOIN CSKT ON CSKT~KOKRS = 'BDFC'
                        AND CSKT~KOSTL = RKPF~KOSTL
                        AND CSKT~DATBI >= @SY-DATUM
                        AND CSKT~SPRAS = @SY-LANGU
    WHERE RESB~WERKS IN @S_WERKS
      AND RESB~RSNUM IN @S_RSNUM
      AND RESB~AUFNR IN @S_AUFNR
      AND RESB~LGORT IN @S_LGORT
      AND RESB~BWART IN @S_BWART
      AND RESB~BDTER IN @S_BDTER
      AND RKPF~KOSTL IN @S_KOSTL
      AND RKPF~USNAM IN @S_USNAM
      AND AUFK~AUART IN @S_AUART
      AND RESB~XLOEK <> 'X'
      AND RESB~POSTP <> 'N'
      AND ( ( @GV_DOC_TYPE = @GC_TYPE_OTHER
              AND ( AUFK~AUTYP IS NULL OR AUFK~AUTYP NOT IN ( '10', '40' ) ) )
         OR ( @GV_DOC_TYPE <> @GC_TYPE_OTHER
              AND AUFK~AUTYP IN ( '10', '40' ) ) )
      AND ( ( @P_OPEN = @ABAP_TRUE
              AND RESB~KZEAR <> 'X' AND RESB~ENMNG < RESB~BDMNG )
         OR ( @P_DONE = @ABAP_TRUE
              AND ( RESB~KZEAR = 'X' OR RESB~ENMNG >= RESB~BDMNG ) )
         OR @P_ALL = @ABAP_TRUE )
    INTO CORRESPONDING FIELDS OF TABLE @GT_PREDATA. "#EC CI_BUFFJOIN

  IF GT_PREDATA IS INITIAL.
    MESSAGE S002(ZWM01) DISPLAY LIKE 'E'.
    STOP.
  ENDIF.

  PERFORM READ_PARAM.
  PERFORM CHECK_AUTHORITY.
  PERFORM FILTER_BY_DOC_TYPE.

  IF GT_PREDATA IS INITIAL.
    MESSAGE S002(ZWM01) DISPLAY LIKE 'E'.
    STOP.
  ENDIF.

*  "PHAN QUYEN
*  TYPES:  BEGIN OF GTY_WERKS,
*            WERKS TYPE MSEG-WERKS,
*          END OF GTY_WERKS.
*
*  DATA: GT_WERKSA TYPE TABLE OF GTY_WERKS,
*        GS_WERKSA TYPE          GTY_WERKS,
*
*        GT_WERKSB TYPE TABLE OF GTY_WERKS,
*        GS_WERKSB TYPE          GTY_WERKS.
*
*  MOVE-CORRESPONDING GT_PREDATA TO GT_WERKSA .
*  MOVE-CORRESPONDING GT_PREDATA TO GT_WERKSB .
*
*  SORT GT_WERKSA BY WERKS .
*  DELETE ADJACENT DUPLICATES FROM GT_WERKSA COMPARING WERKS.
*
*  SORT GT_WERKSB BY WERKS .
*  DELETE ADJACENT DUPLICATES FROM GT_WERKSB COMPARING WERKS.
*
*  LOOP AT GT_WERKSB INTO GS_WERKSB.
*    AUTHORITY-CHECK OBJECT 'M_MSEG_WMB'
*      ID 'WERKS' FIELD GS_WERKSB-WERKS
*      ID 'ACTVT' FIELD '03'.
*    IF SY-SUBRC <> 0.
*      DELETE GT_PREDATA WHERE WERKS = GS_WERKSB-WERKS .
*    ENDIF.
*  ENDLOOP.
*
*  LOOP AT GT_WERKSA INTO GS_WERKSA.
*    AUTHORITY-CHECK OBJECT 'M_MRES_WWA'
*      ID 'WERKS' FIELD GS_WERKSA-WERKS
*      ID 'ACTVT' FIELD '03'.
*    IF SY-SUBRC <> 0.
*      DELETE GT_PREDATA WHERE WERKS = GS_WERKSB-WERKS .
*    ENDIF.
*  ENDLOOP.
*
*  IF GT_PREDATA IS INITIAL.
*    MESSAGE 'No Authentication' TYPE 'I'.
*    STOP.
*  ENDIF.
*  "END PHAN QUYEN

  " Khóa rút gọn để JOIN với internal table (thay cho FOR ALL ENTRIES)
  DATA: LT_KEY_EQ TYPE STANDARD TABLE OF GTY_KEY_EQ WITH EMPTY KEY,
        LT_KEY_SL TYPE STANDARD TABLE OF GTY_KEY_SL WITH EMPTY KEY,
        LT_KEY_AN TYPE STANDARD TABLE OF GTY_KEY_AN WITH EMPTY KEY,
        LT_KEY_AU TYPE STANDARD TABLE OF GTY_KEY_AU WITH EMPTY KEY,
        LT_KEY_US TYPE STANDARD TABLE OF GTY_KEY_US WITH EMPTY KEY.

  LT_KEY_EQ = VALUE #( FOR LS_P IN GT_PREDATA ( EQUNR = LS_P-EQUNR ) ).
  LT_KEY_SL = VALUE #( FOR LS_P IN GT_PREDATA ( WERKS = LS_P-WERKS UMLGO = LS_P-UMLGO ) ).
  LT_KEY_AN = VALUE #( FOR LS_P IN GT_PREDATA ( ANLN1 = LS_P-ANLN1 ) ).
  LT_KEY_AU = VALUE #( FOR LS_P IN GT_PREDATA ( AUFNR = LS_P-AUFNR ) ).
  LT_KEY_US = VALUE #( FOR LS_P IN GT_PREDATA ( USNAM = LS_P-USNAM ) ).

  DELETE LT_KEY_EQ WHERE EQUNR IS INITIAL.
  DELETE LT_KEY_AN WHERE ANLN1 IS INITIAL.
  DELETE LT_KEY_AU WHERE AUFNR IS INITIAL.
  SORT LT_KEY_EQ BY EQUNR.
  SORT LT_KEY_SL BY WERKS UMLGO.
  SORT LT_KEY_AN BY ANLN1.
  SORT LT_KEY_AU BY AUFNR.
  SORT LT_KEY_US BY USNAM.
  DELETE ADJACENT DUPLICATES FROM LT_KEY_EQ COMPARING EQUNR.
  DELETE ADJACENT DUPLICATES FROM LT_KEY_SL COMPARING WERKS UMLGO.
  DELETE ADJACENT DUPLICATES FROM LT_KEY_AN COMPARING ANLN1.
  DELETE ADJACENT DUPLICATES FROM LT_KEY_AU COMPARING AUFNR.
  DELETE ADJACENT DUPLICATES FROM LT_KEY_US COMPARING USNAM.

  "LAY THONG TIN DIEN GIAI THIET BI
*  SELECT
*    EQUNR
*    EQKTX
*  INTO TABLE GT_EQKT
*  FROM EQKT
*  FOR ALL ENTRIES IN GT_PREDATA
*  WHERE EQUNR EQ GT_PREDATA-EQUNR
*    AND SPRAS EQ SY-LANGU.
  SELECT EQKT~EQUNR, EQKT~EQKTX
    FROM EQKT
    INNER JOIN @LT_KEY_EQ AS K ON K~EQUNR = EQKT~EQUNR
    WHERE EQKT~SPRAS = @SY-LANGU
    INTO TABLE @GT_EQKT.

*  SELECT
*    LGORT
*    LGOBE
*  INTO TABLE GT_T001L
*  FROM T001L
*  FOR ALL ENTRIES IN GT_PREDATA
*  WHERE LGORT EQ GT_PREDATA-UMLGO
*    AND WERKS EQ GT_PREDATA-WERKS.
  SELECT T001L~LGORT, T001L~LGOBE
    FROM T001L
    INNER JOIN @LT_KEY_SL AS K ON K~WERKS = T001L~WERKS
                              AND K~UMLGO = T001L~LGORT
    INTO TABLE @GT_T001L.

  "LAY THONG TIN DON VI NHAN TRUONG HOP ASSET
  DATA: GS_TMP   TYPE ZWM_ST_PYCVT,
        LW_BUKRS TYPE BUKRS.
  READ TABLE GT_PREDATA INTO GS_TMP INDEX 1.

  CALL FUNCTION 'ZCORE_FM_GET_COMCODE'
    EXPORTING
      I_KIND   = 'P'
      I_NUMBER = GS_TMP-WERKS
    IMPORTING
      E_BUKRS  = LW_BUKRS.

*  SELECT
*    BUKRS
*    ANLN1
*    TXT50
*  INTO TABLE GT_ANLA
*  FROM ANLA
*  FOR ALL ENTRIES IN GT_PREDATA
*  WHERE ANLN1 EQ GT_PREDATA-ANLN1
*    AND BUKRS EQ LW_BUKRS.
  SELECT ANLA~BUKRS, ANLA~ANLN1, ANLA~TXT50
    FROM ANLA
    INNER JOIN @LT_KEY_AN AS K ON K~ANLN1 = ANLA~ANLN1
    WHERE ANLA~BUKRS = @LW_BUKRS
    INTO TABLE @GT_ANLA.

  " Thành phẩm của lệnh sản xuất: mô tả + lô thành phẩm
  SELECT AFPO~AUFNR, AFPO~MATNR, AFPO~CHARG, MAKT~MAKTX
    FROM AFPO
    INNER JOIN @LT_KEY_AU AS K ON K~AUFNR = AFPO~AUFNR
    LEFT OUTER JOIN MAKT ON MAKT~MATNR = AFPO~MATNR
                        AND MAKT~SPRAS = 'E'
    WHERE AFPO~POSNR = '0001'
    INTO TABLE @GT_AFPO.

  " Họ tên người tạo
  SELECT DISTINCT USR21~BNAME AS USNAM, ADRP~NAME_TEXT
    FROM USR21
    INNER JOIN ADRP ON ADRP~PERSNUMBER = USR21~PERSNUMBER
    INNER JOIN @LT_KEY_US AS K ON K~USNAM = USR21~BNAME
    INTO TABLE @GT_USER.

  " Số lô NSX, nhà sản xuất
  PERFORM GET_BATCH_INFO.

*  IF P_KTNVL IS NOT INITIAL.
*    PERFORM CHECK_TK.
*  ENDIF.
*
*
*  "Lay CT chuyen kho theo PYC
*  PERFORM GET_PCK.
  " Phiếu in không còn so sánh tồn; kiểm tra sẵn sàng làm ở CHECK_READINESS

ENDFORM.             " FILL_DATA
*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITY
*&---------------------------------------------------------------------*
*       Quyền Plant và quyền Order Type (C_AFKO_AWK)
*----------------------------------------------------------------------*
FORM CHECK_AUTHORITY .
  TYPES: BEGIN OF LTY_ORD,
           WERKS TYPE WERKS_D,
           AUART TYPE AUFK-AUART,
         END OF LTY_ORD.

  DATA: LT_WERKS TYPE SORTED TABLE OF WERKS_D WITH UNIQUE KEY TABLE_LINE,
        LT_ORD   TYPE SORTED TABLE OF LTY_ORD WITH UNIQUE KEY WERKS AUART,
        LS_ORD   TYPE LTY_ORD,
        LT_BWART TYPE SORTED TABLE OF BWART WITH UNIQUE KEY TABLE_LINE.

  LOOP AT GT_PREDATA ASSIGNING FIELD-SYMBOL(<LF_AUTH>).
    INSERT <LF_AUTH>-WERKS INTO TABLE LT_WERKS.
    IF <LF_AUTH>-BWART IS NOT INITIAL.
      INSERT <LF_AUTH>-BWART INTO TABLE LT_BWART.
    ENDIF.
    IF <LF_AUTH>-AUFNR IS NOT INITIAL AND <LF_AUTH>-AUART IS NOT INITIAL.
      LS_ORD-WERKS = <LF_AUTH>-WERKS.
      LS_ORD-AUART = <LF_AUTH>-AUART.
      INSERT LS_ORD INTO TABLE LT_ORD.
    ENDIF.
  ENDLOOP.

  LOOP AT LT_WERKS INTO DATA(LV_WERKS).
    AUTHORITY-CHECK OBJECT 'M_MRES_WWA'
      ID 'ACTVT' FIELD '03'
      ID 'WERKS' FIELD LV_WERKS.
    IF SY-SUBRC <> 0.
      MESSAGE E000(ZWM01) WITH LV_WERKS.
    ENDIF.

    AUTHORITY-CHECK OBJECT 'M_MSEG_WMB'
      ID 'ACTVT' FIELD '03'
      ID 'WERKS' FIELD LV_WERKS.
    IF SY-SUBRC <> 0.
      MESSAGE E000(ZWM01) WITH LV_WERKS.
    ENDIF.
  ENDLOOP.

  LOOP AT LT_ORD INTO LS_ORD.
    AUTHORITY-CHECK OBJECT 'C_AFKO_AWK'
      ID 'WERKS'  FIELD LS_ORD-WERKS
      ID 'AUFART' FIELD LS_ORD-AUART.
    IF SY-SUBRC <> 0.
      MESSAGE E398(00) WITH 'Bạn không có quyền với Order Type' LS_ORD-AUART 'tại Plant' LS_ORD-WERKS.
    ENDIF.
  ENDLOOP.

  " Quyền theo Movement Type của Reservation
  LOOP AT LT_BWART INTO DATA(LV_BWART).
    AUTHORITY-CHECK OBJECT 'M_MRES_BWA'
      ID 'ACTVT' FIELD '03'
      ID 'BWART' FIELD LV_BWART.
    IF SY-SUBRC <> 0.
      MESSAGE E398(00) WITH 'Bạn không có quyền với Movement Type' LV_BWART '' ''.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " CHECK_AUTHORITY
*&---------------------------------------------------------------------*
*&      Form  FILTER_BY_DOC_TYPE
*&---------------------------------------------------------------------*
*       Phiếu bổ sung: chỉ component không thuộc BOM (RESB-STLNR/STLKN trống)
*       và chưa từng in ở phiếu bổ sung theo nhật ký in ZTWM_PRTLOG.
*       Phiếu theo Lệnh SX và phiếu bổ sung: bắt buộc có Batch. Dòng chưa có Batch:
*       - không kiểm tra sẵn sàng: bị loại và hiển thị danh sách;
*       - có kiểm tra sẵn sàng: giữ lại ở màn hình trung gian, đèn xám, không cho chọn in.
*----------------------------------------------------------------------*
FORM FILTER_BY_DOC_TYPE .
  DATA LV_TEXT TYPE CHAR100.

  IF GV_DOC_TYPE = GC_TYPE_SUPP.
    DELETE GT_PREDATA WHERE STLNR IS NOT INITIAL
                         OR STLKN IS NOT INITIAL.
    PERFORM EXCLUDE_PRINTED_SUPP.
  ENDIF.

  IF GV_DOC_TYPE <> GC_TYPE_OTHER.
    CLEAR GT_EXCL.
    LOOP AT GT_PREDATA ASSIGNING FIELD-SYMBOL(<LF_NB>) WHERE CHARG IS INITIAL.
      MESSAGE S003(ZWM01) WITH <LF_NB>-RSNUM <LF_NB>-RSPOS <LF_NB>-MATNR INTO LV_TEXT.
      APPEND VALUE #( RSNUM = <LF_NB>-RSNUM
                      RSPOS = <LF_NB>-RSPOS
                      MATNR = <LF_NB>-MATNR
                      TEXT  = LV_TEXT ) TO GT_EXCL.
    ENDLOOP.
*    DELETE GT_PREDATA WHERE CHARG IS INITIAL.
*    PERFORM SHOW_EXCLUDED.
    IF P_KTNVL IS INITIAL.
      DELETE GT_PREDATA WHERE CHARG IS INITIAL.
      PERFORM SHOW_EXCLUDED.
    ENDIF.
  ENDIF.
ENDFORM.                    " FILTER_BY_DOC_TYPE
*&---------------------------------------------------------------------*
*&      Form  SHOW_EXCLUDED
*&---------------------------------------------------------------------*
*       Danh sách dòng bị loại vì chưa có Batch
*----------------------------------------------------------------------*
FORM SHOW_EXCLUDED .
  DATA: LO_ALV TYPE REF TO CL_SALV_TABLE,
        LO_COL TYPE REF TO CL_SALV_COLUMN.

  CHECK GT_EXCL IS NOT INITIAL.

  TRY.
      CL_SALV_TABLE=>FACTORY(
        IMPORTING R_SALV_TABLE = LO_ALV
        CHANGING  T_TABLE      = GT_EXCL ).
      LO_ALV->SET_SCREEN_POPUP( START_COLUMN = 5
                                END_COLUMN   = 120
                                START_LINE   = 5
                                END_LINE     = 20 ).
      LO_COL = LO_ALV->GET_COLUMNS( )->GET_COLUMN( 'TEXT' ).
      LO_COL->SET_LONG_TEXT( 'Dòng bị loại khỏi phiếu' ).
      LO_ALV->GET_COLUMNS( )->SET_OPTIMIZE( ABAP_TRUE ).
      LO_ALV->DISPLAY( ).
    CATCH CX_SALV_MSG CX_SALV_NOT_FOUND.
      MESSAGE S003(ZWM01) WITH GT_EXCL[ 1 ]-RSNUM GT_EXCL[ 1 ]-RSPOS GT_EXCL[ 1 ]-MATNR
              DISPLAY LIKE 'W'.
  ENDTRY.
ENDFORM.                    " SHOW_EXCLUDED
*&---------------------------------------------------------------------*
*&      Form  GET_BATCH_INFO
*&---------------------------------------------------------------------*
*       Số lô NSX = Z_BATCH_NSX của lô, nếu trống lấy MCHA-LICHA
*       Nhà sản xuất = Z_NSX của lô (giá trị là mã NCC, đổi sang tên).
*           Bước "nếu trống lấy NSX của mã MPN" chưa làm: chờ BA chốt cách xác định MPN.
*----------------------------------------------------------------------*
FORM GET_BATCH_INFO .
  DATA: LT_ATNAM TYPE STANDARD TABLE OF ZCORE_ST_RSELOPTION_ATNAM,
        LS_ATNAM TYPE ZCORE_ST_RSELOPTION_ATNAM,
        LT_CHAR  TYPE STANDARD TABLE OF BAPI1003_ALLOC_VALUES_CHAR,
        LS_CHAR  TYPE BAPI1003_ALLOC_VALUES_CHAR,
        LS_BATCH TYPE GTY_BATCH,
        LV_NUM   TYPE CHAR10,
        LV_NAME  TYPE CHAR255.

  LS_ATNAM-SIGN   = 'I'.
  LS_ATNAM-OPTION = 'EQ'.
  LS_ATNAM-LOW    = 'Z_NSX'.
  APPEND LS_ATNAM TO LT_ATNAM.
  LS_ATNAM-LOW    = 'Z_BATCH_NSX'.
  APPEND LS_ATNAM TO LT_ATNAM.

  LOOP AT GT_PREDATA ASSIGNING FIELD-SYMBOL(<LF_BAT>) WHERE CHARG IS NOT INITIAL.
    READ TABLE GT_BATCH INTO LS_BATCH
         WITH TABLE KEY MATNR = <LF_BAT>-MATNR
                        WERKS = <LF_BAT>-WERKS
                        CHARG = <LF_BAT>-CHARG.
    IF SY-SUBRC <> 0.
      CLEAR: LS_BATCH, LT_CHAR.
      LS_BATCH-MATNR = <LF_BAT>-MATNR.
      LS_BATCH-WERKS = <LF_BAT>-WERKS.
      LS_BATCH-CHARG = <LF_BAT>-CHARG.

      CALL FUNCTION 'ZCORE_FM_GET_CRTRT_MULTIVAL'
        EXPORTING
          I_MATNR     = <LF_BAT>-MATNR
          I_CHARG     = <LF_BAT>-CHARG
          I_WERKS     = <LF_BAT>-WERKS
          I_KLART     = '023'
        TABLES
          IT_ATNAM    = LT_ATNAM
          IT_CHARACT  = LT_CHAR.

      READ TABLE LT_CHAR INTO LS_CHAR WITH KEY CHARACT = 'Z_BATCH_NSX'.
      IF SY-SUBRC = 0.
        LS_BATCH-Z_BATCH_NSX = LS_CHAR-VALUE_CHAR.
      ENDIF.
      IF LS_BATCH-Z_BATCH_NSX IS INITIAL.
        SELECT SINGLE LICHA FROM MCHA
          WHERE MATNR = @<LF_BAT>-MATNR
            AND WERKS = @<LF_BAT>-WERKS
            AND CHARG = @<LF_BAT>-CHARG
          INTO @LS_BATCH-Z_BATCH_NSX.
      ENDIF.

      READ TABLE LT_CHAR INTO LS_CHAR WITH KEY CHARACT = 'Z_NSX'.
      IF SY-SUBRC = 0.
        LS_BATCH-Z_NSX = LS_CHAR-VALUE_CHAR.
        IF LS_BATCH-Z_NSX IS NOT INITIAL AND LS_BATCH-Z_NSX CO '0123456789 '.
          LV_NUM = LS_BATCH-Z_NSX.
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
            LS_BATCH-Z_NSX = LV_NAME.
          ENDIF.
        ENDIF.
      ENDIF.

      INSERT LS_BATCH INTO TABLE GT_BATCH.
    ENDIF.

    <LF_BAT>-Z_NSX       = LS_BATCH-Z_NSX.
    <LF_BAT>-Z_BATCH_NSX = LS_BATCH-Z_BATCH_NSX.
  ENDLOOP.
ENDFORM.                    " GET_BATCH_INFO
*&---------------------------------------------------------------------*
*&      Form  DATA_PROCESSING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DATA_PROCESSING .

  DATA:
    GW_LINEEND   TYPE CHAR10,
    GW_LINESTART TYPE CHAR10,
    LW_THIEU     LIKE GS_MB5B-ENDMENGE,
    LRT_LGORT    TYPE RANGE OF LGORT_D WITH HEADER LINE,
    LW_SL_CK     TYPE MSEG-MENGE,
    LW_SL_CL     TYPE MSEG-MENGE.

  DATA: LV_FIRST  TYPE ABAP_BOOL VALUE ABAP_TRUE,
        LV_PRSNUM TYPE RSNUM,
        LV_PLGORT TYPE LGORT_D,
        LV_PTABIX TYPE SY-TABIX,
        LV_REMAIN TYPE BDMNG,
        LV_CONV   TYPE ERFMG.

*  SORT GT_PREDATA BY RSNUM LGORT RSPOS.
  " Mỗi Reservation một phiếu: gom phiếu theo RSNUM khi in (EXPORT_DATA)
  SORT GT_PREDATA BY RSNUM RSPOS.

*  LOOP AT GT_PREDATA INTO GS_DATA.
*  LOOP AT GT_PREDATA ASSIGNING FIELD-SYMBOL(<LF_DATA>).
**    GS_DATA = <LF_DATA>.
*    GW_LINEEND = SY-TABIX.
**    AT NEW LGORT.
**      GW_LINESTART = SY-TABIX.
**    ENDAT.
*    " AT NEW phụ thuộc thứ tự cột của structure ZWM_ST_PYCVT (RSPOS, BDTER... nằm trước LGORT)
*    " nên đổi sang so sánh khóa nhóm RSNUM + LGORT tường minh.
*    IF LV_FIRST = ABAP_TRUE
*       OR <LF_DATA>-RSNUM <> LV_PRSNUM
*       OR <LF_DATA>-LGORT <> LV_PLGORT.
*      IF LV_FIRST = ABAP_FALSE.
*        GS_HEADER-LINEEND   = LV_PTABIX.
*        GS_HEADER-LINESTART = GW_LINESTART.
*        APPEND GS_HEADER TO GT_HEADER.
*        CLEAR GS_HEADER.
*      ENDIF.
*      GW_LINESTART = SY-TABIX.
*      LV_FIRST     = ABAP_FALSE.
*    ENDIF.
*    LV_PRSNUM = <LF_DATA>-RSNUM.
*    LV_PLGORT = <LF_DATA>-LGORT.
*    LV_PTABIX = SY-TABIX.
*
*    IF <LF_DATA>-ERFMG > 0.
*      "Check Phieu chuyen kho
*      CLEAR LW_SL_CK.
*      LOOP AT GT_PCK INTO DATA(LS_PCK) WHERE RSNUM = <LF_DATA>-RSNUM
*                                         AND RSPOS = <LF_DATA>-RSPOS.
*        LW_SL_CK = LW_SL_CK + LS_PCK-ERFMG.
*      ENDLOOP.
*
*      LW_SL_CL = <LF_DATA>-ERFMG - LW_SL_CK.
*
*      IF LW_SL_CL = 0.
*        <LF_DATA>-SS_TK = 'Đã xuất đủ'.
*      ELSEIF LW_SL_CL > 0.
*
*        IF <LF_DATA>-MTART = 'B101' OR <LF_DATA>-MTART = 'B102'.
*          LRT_LGORT-SIGN = 'I'.
*          LRT_LGORT-OPTION = 'EQ'.
*          LRT_LGORT-LOW = 'B101'.
*          APPEND LRT_LGORT.
*
*          LRT_LGORT-SIGN = 'I'.
*          LRT_LGORT-OPTION = 'EQ'.
*          LRT_LGORT-LOW = 'B102'.
*          APPEND LRT_LGORT.
*        ELSEIF <LF_DATA>-MTART = 'B106' OR <LF_DATA>-MTART = 'B112'.
*          LRT_LGORT-SIGN = 'I'.
*          LRT_LGORT-OPTION = 'EQ'.
*          LRT_LGORT-LOW = 'B106'.
*          APPEND LRT_LGORT.
*
*          LRT_LGORT-SIGN = 'I'.
*          LRT_LGORT-OPTION = 'EQ'.
*          LRT_LGORT-LOW = 'B112'.
*          APPEND LRT_LGORT.
*        ENDIF.
*
*        LOOP AT GT_MB5B INTO GS_MB5B WHERE WERKS = <LF_DATA>-WERKS
*                                       AND MATNR = <LF_DATA>-MATNR
*                                       AND LGORT IN LRT_LGORT[].
*          <LF_DATA>-ENDMENGE = <LF_DATA>-ENDMENGE + GS_MB5B-ENDMENGE.
*        ENDLOOP.
*
*        LW_THIEU = <LF_DATA>-ENDMENGE - <LF_DATA>-ERFMG.
*        IF LW_THIEU >= 0.
*          <LF_DATA>-SS_TK = 'Đủ'.
*        ELSE.
*          LW_THIEU = ABS( LW_THIEU ).
*          WRITE LW_THIEU TO <LF_DATA>-SS_TK UNIT <LF_DATA>-ERFME.
**      <LF_DATA>-SS_TK = ABS( LW_THIEU ).
*          CONDENSE <LF_DATA>-SS_TK NO-GAPS.
*          CONCATENATE 'Thiếu' '-' <LF_DATA>-SS_TK INTO <LF_DATA>-SS_TK SEPARATED BY SPACE.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*
**    IF GS_PARAMETER-HEADER13 IS INITIAL.
**      GS_PARAMETER-HEADER13 = <LF_DATA>-SGTXT.
**    ENDIF.
*    " HEADER13 (Diễn giải) tính theo từng phiếu trong EXPORT_DATA, không dùng chung cả lần chạy.
*
*    GS_HEADER = <LF_DATA>.
**    GS_HEADER = GS_DATA.
**    AT END OF LGORT.
**      GS_HEADER-LINEEND = GW_LINEEND.
**      GS_HEADER-LINESTART = GW_LINESTART.
**      APPEND GS_HEADER TO GT_HEADER.
**      CLEAR GS_HEADER.
**    ENDAT.
*  ENDLOOP.
*
*  IF GT_PREDATA IS NOT INITIAL.
*    GS_HEADER-LINEEND   = LV_PTABIX.
*    GS_HEADER-LINESTART = GW_LINESTART.
*    APPEND GS_HEADER TO GT_HEADER.
*    CLEAR GS_HEADER.
*  ENDIF.

  " ĐVT: trống thì lấy đơn vị cơ bản.
  " SL yêu cầu: trạng thái "Đang mở" in SL còn lại quy đổi về ĐVT nhập liệu.
  " SL còn yêu cầu theo ĐVT cơ bản (dùng cho kiểm tra sẵn sàng).
  LOOP AT GT_PREDATA ASSIGNING FIELD-SYMBOL(<LF_DATA>).
    IF <LF_DATA>-ERFME IS INITIAL.
      <LF_DATA>-ERFME = <LF_DATA>-MEINS.
    ENDIF.

    <LF_DATA>-OPEN_QTY = <LF_DATA>-BDMNG - <LF_DATA>-ENMNG.
    IF <LF_DATA>-OPEN_QTY < 0.
      CLEAR <LF_DATA>-OPEN_QTY.
    ENDIF.

*    IF P_OPEN = ABAP_TRUE AND P_KTNVL IS INITIAL.
    IF P_OPEN = ABAP_TRUE.
      LV_REMAIN = <LF_DATA>-BDMNG - <LF_DATA>-ENMNG.
      IF LV_REMAIN < 0.
        CLEAR LV_REMAIN.
      ENDIF.
      IF <LF_DATA>-ERFME = <LF_DATA>-MEINS.
        <LF_DATA>-ERFMG = LV_REMAIN.
      ELSE.
        CLEAR LV_CONV.
        CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
          EXPORTING
            I_MATNR              = <LF_DATA>-MATNR
            I_IN_ME              = <LF_DATA>-MEINS
            I_OUT_ME             = <LF_DATA>-ERFME
            I_MENGE              = LV_REMAIN
          IMPORTING
            E_MENGE              = LV_CONV
          EXCEPTIONS
            ERROR_IN_APPLICATION = 1
            ERROR                = 2
            OTHERS               = 3.
        IF SY-SUBRC = 0.
          <LF_DATA>-ERFMG = LV_CONV.
        ELSE.
          <LF_DATA>-ERFMG = LV_REMAIN.
          <LF_DATA>-ERFME = <LF_DATA>-MEINS.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " DATA_PROCESSING
*&---------------------------------------------------------------------*
*&      Form  GET_PARAMETER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_PARAMETER.

*  GS_PARAMETER-PARAMETER01 = 'STT'.
*  GS_PARAMETER-PARAMETER02 = 'Mã hàng'.
*  GS_PARAMETER-PARAMETER03 = 'Tên hàng'.
*  GS_PARAMETER-PARAMETER04 = 'ĐVT'.
*  GS_PARAMETER-PARAMETER05 = 'Số lượng yêu cầu'.
*  GS_PARAMETER-PARAMETER06 = 'Số lô'.
*  GS_PARAMETER-PARAMETER07 = 'Số lượng thực xuất'.
*  IF P_KTNVL IS NOT INITIAL.
*    GS_PARAMETER-PARAMETER06 = 'Thiếu/ đủ so với SL yêu cầu'.
*    GS_PARAMETER-PARAMETER07 =  'Tồn kho sẵn sàng'.
*  ENDIF.
*  GS_PARAMETER-PARAMETER08 = 'Ghi chú'.
*
*  IF P_INSN IS INITIAL.
*    GS_PARAMETER-HEADER04 = 'Số Reservation:'.
*    GS_PARAMETER-HEADER06 = 'Đơn vị nhận:'.
*    GS_PARAMETER-HEADER08 = 'Đơn vị xuất:'.
*    GS_PARAMETER-HEADER10 = 'Người yêu cầu:'.
*    GS_PARAMETER-HEADER12 = 'Diễn giải:'.
*
*    GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU VẬT TƯ'.
*    GS_PARAMETER-FOOTER01 = 'Trưởng bộ phận'.
*    GS_PARAMETER-FOOTER03 = 'Người nhận'.
*    GS_PARAMETER-FOOTER04 = 'Người lập'.
*    GS_PARAMETER-FOOTER02 = 'Người giao'.
*    GS_PARAMETER-FOOTER05 = 'Ngày …… Tháng …… Năm ………'.
*    GS_PARAMETER-FOOTER06 = 'Trang'.
*  ELSE.
*    GS_PARAMETER-PARAMETER06 = 'Số lô sản xuất'.
*
*    GS_PARAMETER-HEADER04 = 'Số yêu cầu/ Reservation No.:'.
*    GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU VẬT TƯ/ MATERIAL REQUISITION SLIP'.
*    GS_PARAMETER-HEADER06 = 'Đơn vị nhận/ Recipient unit:'.
*    GS_PARAMETER-HEADER08 = 'Đơn vị xuất/ Export unit:'.
*    GS_PARAMETER-HEADER10 = 'Người yêu cầu/ Requester:'.
*    GS_PARAMETER-HEADER12 = 'Diễn giải/ Description:'.
*
*    GS_PARAMETER-PARAMETER11 = 'No.'.
*    GS_PARAMETER-PARAMETER12 = 'Goods code'.
*    GS_PARAMETER-PARAMETER13 = 'Goods name'.
*    GS_PARAMETER-PARAMETER14 = 'Unit'.
*    GS_PARAMETER-PARAMETER15 = 'Required quantity'.
*    GS_PARAMETER-PARAMETER16 = 'Batch number'.
*    GS_PARAMETER-PARAMETER17 = 'Actual quantity'.
*    GS_PARAMETER-PARAMETER18 = 'Remark'.
*
*    GS_PARAMETER-FOOTER05 = 'Ngày/ Date …… tháng/ month …… năm/ year ………'.
*    GS_PARAMETER-FOOTER06 = 'Trang/ Page'.
*
*    IF R_1 IS NOT INITIAL.
*      GS_PARAMETER-FOOTER01 = 'Người nhận/ Receiver'.
*      GS_PARAMETER-FOOTER02 = 'Trưởng phòng QA/ QA Head'.
*      GS_PARAMETER-FOOTER03 = 'Trưởng bộ phận/ Department Head'.
*      GS_PARAMETER-FOOTER04 = 'Người lập/ Initiator'.
*    ELSE.
*      GS_PARAMETER-FOOTER01 = 'Nhân viên kho'.
*      GS_PARAMETER-FOOTER02 = 'Trưởng phòng QA'.
*      GS_PARAMETER-FOOTER03 = 'Trưởng bộ phận'.
*      GS_PARAMETER-FOOTER04 = 'Người lập'.
*
*      GS_PARAMETER-SIGN01 = 'Warehouse staff'.
*      GS_PARAMETER-SIGN02 = 'QA Head'.
*      GS_PARAMETER-SIGN03 = 'Department Head'.
*      GS_PARAMETER-SIGN04 = 'Initiator'.
*    ENDIF.
*
*  ENDIF.

  " Tiêu đề cột; PARAMETER11..20 là bản tiếng Anh khi in song ngữ.
  GS_PARAMETER-PARAMETER01 = 'STT'.
  GS_PARAMETER-PARAMETER02 = 'Mã hàng'.
  GS_PARAMETER-PARAMETER03 = 'Tên hàng'.
  GS_PARAMETER-PARAMETER04 = 'ĐVT'.
  GS_PARAMETER-PARAMETER05 = 'SL yêu cầu'.
  GS_PARAMETER-PARAMETER06 = 'Số lô SAP'.
  GS_PARAMETER-PARAMETER07 = 'SL thực xuất'.
  GS_PARAMETER-PARAMETER08 = 'Ghi chú'.
  GS_PARAMETER-PARAMETER09 = 'Số lô NSX'.
  GS_PARAMETER-PARAMETER10 = 'Nhà sản xuất'.

*  " Form in kèm tồn kho (ZWM_SF_PYCVT_TK) dùng lại cột 6, 7 cho Thiếu/đủ và Tồn kho sẵn sàng
*  IF P_KTNVL IS NOT INITIAL AND P_INSN IS INITIAL.
*    GS_PARAMETER-PARAMETER06 = 'Thiếu/ đủ so với SL yêu cầu'.
*    GS_PARAMETER-PARAMETER07 = 'Tồn kho sẵn sàng'.
*  ENDIF.
  " Phiếu in không in thông tin so sánh tồn nên không đổi tiêu đề cột

  IF P_INSN IS INITIAL.
    GS_PARAMETER-HEADER04 = 'Số phiếu yêu cầu:'.
    GS_PARAMETER-HEADER14 = 'Ngày yêu cầu:'.
    GS_PARAMETER-HEADER06 = 'Đơn vị nhận:'.
    GS_PARAMETER-HEADER08 = 'Đơn vị xuất:'.
    GS_PARAMETER-HEADER10 = 'Người yêu cầu:'.
    GS_PARAMETER-HEADER12 = 'Diễn giải:'.

    IF GV_DOC_TYPE = GC_TYPE_SUPP.
      GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU VẬT TƯ BỔ SUNG'.
      GS_PARAMETER-FOOTER01 = 'Nhân viên kho'.
      GS_PARAMETER-FOOTER02 = 'Trưởng phòng QA'.
      GS_PARAMETER-FOOTER03 = 'Trưởng bộ phận'.
      GS_PARAMETER-FOOTER04 = 'Người lập'.
    ELSE.
      GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU VẬT TƯ'.
      GS_PARAMETER-FOOTER01 = 'Trưởng bộ phận'.
      GS_PARAMETER-FOOTER02 = 'Người giao'.
      GS_PARAMETER-FOOTER03 = 'Người nhận'.
      GS_PARAMETER-FOOTER04 = 'Người lập'.
    ENDIF.
    GS_PARAMETER-FOOTER05 = 'Ngày …… Tháng …… Năm ………'.
    GS_PARAMETER-FOOTER06 = 'Trang'.
  ELSE.
    GS_PARAMETER-HEADER04 = 'Số phiếu yêu cầu/ Reservation No.:'.
    GS_PARAMETER-HEADER14 = 'Ngày yêu cầu/ Request date:'.
    GS_PARAMETER-HEADER06 = 'Đơn vị nhận/ Recipient unit:'.
    GS_PARAMETER-HEADER08 = 'Đơn vị xuất/ Issuing unit:'.
    GS_PARAMETER-HEADER10 = 'Người yêu cầu/ Requester:'.
    GS_PARAMETER-HEADER12 = 'Diễn giải/ Description:'.

    IF GV_DOC_TYPE = GC_TYPE_SUPP.
      GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU VẬT TƯ BỔ SUNG/ MATERIAL REQUISITION SLIP'.
      GS_PARAMETER-FOOTER01 = 'Nhân viên kho/ Warehouse staff'.
      GS_PARAMETER-FOOTER02 = 'Trưởng phòng QA/ QA Head'.
      GS_PARAMETER-FOOTER03 = 'Trưởng bộ phận/ Department Head'.
      GS_PARAMETER-FOOTER04 = 'Người lập/ Initiator'.
    ELSE.
      GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU VẬT TƯ/ MATERIAL REQUISITION SLIP'.
      GS_PARAMETER-FOOTER01 = 'Trưởng bộ phận/ Department Head'.
      GS_PARAMETER-FOOTER02 = 'Người giao/ Deliverer'.
      GS_PARAMETER-FOOTER03 = 'Người nhận/ Receiver'.
      GS_PARAMETER-FOOTER04 = 'Người lập/ Initiator'.
    ENDIF.

    GS_PARAMETER-PARAMETER11 = 'No.'.
    GS_PARAMETER-PARAMETER12 = 'Goods code'.
    GS_PARAMETER-PARAMETER13 = 'Goods name'.
    GS_PARAMETER-PARAMETER14 = 'Unit'.
    GS_PARAMETER-PARAMETER15 = 'Required quantity'.
    GS_PARAMETER-PARAMETER16 = 'SAP batch'.
    GS_PARAMETER-PARAMETER17 = 'Actual quantity'.
    GS_PARAMETER-PARAMETER18 = 'Remark'.
    GS_PARAMETER-PARAMETER19 = 'Mfr. batch'.
    GS_PARAMETER-PARAMETER20 = 'Manufacturer'.

    GS_PARAMETER-FOOTER05 = 'Ngày/ Date …… tháng/ month …… năm/ year ………'.
    GS_PARAMETER-FOOTER06 = 'Trang/ Page'.
  ENDIF.

  " HEADER18 (mã biểu mẫu GMP) và HEADER19 (lần in) gán theo từng phiếu trong EXPORT_DATA.

ENDFORM.                    " GET_PARAMETER
*&---------------------------------------------------------------------*
*&      Form  EXPORT_DATA
*&---------------------------------------------------------------------*
*       In các dòng trong GT_PRINT, mỗi Reservation một phiếu.
*       IV_PREVIEW = X: xem trước; trống: in ra máy in mặc định của user.
*       Chỉ ghi nhật ký in khi phiếu thực sự được in (kể cả in từ màn hình xem trước).
*----------------------------------------------------------------------*
FORM EXPORT_DATA USING IV_PREVIEW TYPE ABAP_BOOL.
  DATA: P_FORM  TYPE TDSFNAME,
        FM_NAME TYPE RS38L_FNAM.
  DATA: WA_CPARAM TYPE SSFCTRLOP,
        WA_OUTPUT TYPE SSFCOMPOP.
  DATA: LT_CNT   TYPE GTT_PRTLOG,
        LV_COUNT TYPE I,
        LV_SPLD  TYPE USR01-SPLD,
        LV_KHO   TYPE STRING,
        LV_LGNUM TYPE /SCWM/LGNUM.

  CHECK GT_PRINT IS NOT INITIAL.

  " Mỗi Reservation một phiếu
  SORT GT_PRINT BY RSNUM RSPOS.
  CLEAR: GT_HEADER, GS_HEADER.
  LOOP AT GT_PRINT INTO GS_DATA.
    IF GS_HEADER-RSNUM <> GS_DATA-RSNUM.
      IF GS_HEADER IS NOT INITIAL.
        APPEND GS_HEADER TO GT_HEADER.
      ENDIF.
      GS_HEADER = GS_DATA.
      GS_HEADER-LINESTART = SY-TABIX.
    ENDIF.
    GS_HEADER-LINEEND = SY-TABIX.
  ENDLOOP.
  APPEND GS_HEADER TO GT_HEADER.
  CLEAR GS_HEADER.

  PERFORM READ_PRTLOG_COUNT CHANGING LT_CNT.

*  IF P_INSN IS INITIAL.
*    P_FORM = 'ZWM_SF_PYCVT'.
*    IF P_KTNVL IS NOT INITIAL.
*      P_FORM = 'ZWM_SF_PYCVT_TK'.
*    ENDIF.
*  ELSE.
**    P_FORM = 'ZWM_SF_PYCVT_EN'.
*    P_FORM = 'ZWM_SF_PYCVT'.   " một form dùng chung, song ngữ theo GW_FLAG
*  ENDIF.
  " Một form dùng chung cho 3 loại phiếu, song ngữ theo GW_FLAG; không in so sánh tồn
  P_FORM = GC_FORMNAME.

*  WA_CPARAM-NO_DIALOG = 'X'.
*  WA_CPARAM-PREVIEW   = 'X'.
*  WA_OUTPUT-TDDEST    = 'LP01'.
*  WA_OUTPUT-TDNOPREV  = 'X'.
*  WA_OUTPUT-TDIMMED   = 'X'.
*  WA_OUTPUT-TDDELETE  = 'X'.
  " Máy in mặc định của user; chưa khai báo thì hiện hộp thoại chọn máy in
  SELECT SINGLE SPLD FROM USR01 WHERE BNAME = @SY-UNAME INTO @LV_SPLD.
  IF IV_PREVIEW = ABAP_TRUE.
    WA_CPARAM-NO_DIALOG = 'X'.
    WA_CPARAM-PREVIEW   = 'X'.
    WA_OUTPUT-TDDEST    = COND #( WHEN LV_SPLD IS NOT INITIAL THEN LV_SPLD ELSE 'LP01' ).
  ELSE.
    IF LV_SPLD IS NOT INITIAL.
      WA_CPARAM-NO_DIALOG = 'X'.
      WA_OUTPUT-TDDEST    = LV_SPLD.
    ENDIF.
    WA_OUTPUT-TDIMMED = 'X'.
    WA_OUTPUT-TDNEWID = 'X'.
  ENDIF.

  CALL FUNCTION 'SSF_OPEN'
    EXPORTING
      CONTROL_PARAMETERS = WA_CPARAM
      OUTPUT_OPTIONS     = WA_OUTPUT
      USER_SETTINGS      = SPACE
    EXCEPTIONS
      FORMATTING_ERROR   = 1
      INTERNAL_ERROR     = 2
      SEND_ERROR         = 3
      USER_CANCELED      = 4
      OTHERS             = 5.

  IF SY-SUBRC <> 0.
*    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    " Báo lỗi trên thanh trạng thái để không thoát màn hình trung gian
    IF SY-MSGID IS NOT INITIAL.
      MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 DISPLAY LIKE 'E'.
    ENDIF.
    RETURN.
  ENDIF.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME           = P_FORM
    IMPORTING
      FM_NAME            = FM_NAME
    EXCEPTIONS
      NO_FORM            = 1
      NO_FUNCTION_MODULE = 2
      OTHERS             = 3.
  IF SY-SUBRC <> 0.
*    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*    EXIT.
    MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 DISPLAY LIKE 'E'.
    CALL FUNCTION 'SSF_CLOSE'
      EXCEPTIONS
        OTHERS = 1.
    RETURN.
  ENDIF.
  WA_CPARAM-NO_OPEN       = 'X'.
  WA_CPARAM-NO_CLOSE      = 'X'.

  DATA LW_MOVETYPE TYPE CHAR5.
  DATA: LS_AFPO  TYPE GTY_AFPO,
        LS_USER  TYPE GTY_USER,
        LV_AUFNR TYPE AUFNR.

  LOOP AT GT_HEADER INTO GS_HEADER.
    "LAY THONG TIN THIET BI
*    CONCATENATE GS_HEADER-BWART GS_HEADER-SOBKZ INTO LW_MOVETYPE.
*
*    IF LW_MOVETYPE EQ 'Z11'.
*      IF P_INSN IS INITIAL.
*        GS_PARAMETER-HEADER16 = 'Thiết bị:'.
*      ELSE.
*        GS_PARAMETER-HEADER16 = 'Thiết bị/ Equipment:'.
*      ENDIF.
*      READ TABLE GT_EQKT INTO GS_EQKT WITH KEY EQUNR = GS_HEADER-EQUNR.
*      SHIFT GS_HEADER-EQUNR LEFT DELETING LEADING '0'.
*      CONCATENATE GS_HEADER-EQUNR '-' GS_EQKT-EQKTX INTO GS_PARAMETER-HEADER17 SEPARATED BY SPACE.
*    ENDIF.
    " có Equipment khi Reservation gắn Maintenance Order
    CLEAR: GS_PARAMETER-HEADER16, GS_PARAMETER-HEADER17.
    IF GS_HEADER-EQUNR IS NOT INITIAL.
      IF P_INSN IS INITIAL.
        GS_PARAMETER-HEADER16 = 'Thiết bị:'.
      ELSE.
        GS_PARAMETER-HEADER16 = 'Thiết bị/ Equipment:'.
      ENDIF.
      READ TABLE GT_EQKT INTO GS_EQKT WITH KEY EQUNR = GS_HEADER-EQUNR.
      SHIFT GS_HEADER-EQUNR LEFT DELETING LEADING '0'.
      CONCATENATE GS_HEADER-EQUNR '-' GS_EQKT-EQKTX INTO GS_PARAMETER-HEADER17 SEPARATED BY SPACE.
    ENDIF.

    "LAY THONG TIN SO RESERVATION

    GS_PARAMETER-HEADER15 = GS_HEADER-RSNUM.
    SHIFT GS_PARAMETER-HEADER15 LEFT DELETING LEADING '0'.

    "LAY DIEN GIAI KHO XUAT
    READ TABLE GT_T001L INTO GS_T001L WITH KEY LGORT = GS_HEADER-UMLGO.
    GW_LGOBE = GS_T001L-LGOBE.

    GW_NUMBER = GS_HEADER-WERKS.
*    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
*      EXPORTING
*        I_NUMBER       = GW_NUMBER
*        I_KIND         = 'P'
*      IMPORTING
*        E_NAME         = GS_PARAMETER-HEADER02
*        E_ADDRESS      = GS_PARAMETER-HEADER03
*        E_NAME_N_TITLE = GS_PARAMETER-NAME
*        E_ADDRESS_EN   = GS_PARAMETER-ADDRESS
*        E_TAX          = GS_PARAMETER-TAX
*        E_TEL_NUMBER   = GS_PARAMETER-TEL_NUMBER
*        E_FAX_NUMBER   = GS_PARAMETER-FAX_NUMBER.
    " FM ZCORE_FM_GET_PROFILE không có E_NAME_N_TITLE, E_ADDRESS_EN nên bỏ 2 tham số.
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        I_NUMBER     = GW_NUMBER
        I_KIND       = 'P'
      IMPORTING
        E_NAME       = GS_PARAMETER-HEADER02
        E_ADDRESS    = GS_PARAMETER-HEADER03
        E_TAX        = GS_PARAMETER-TAX
        E_TEL_NUMBER = GS_PARAMETER-TEL_NUMBER
        E_FAX_NUMBER = GS_PARAMETER-FAX_NUMBER.

    " Song ngữ: tên, địa chỉ tiếng Anh lấy phiên bản địa chỉ quốc tế (NATION = I) của Plant, nếu có
    CLEAR: GS_PARAMETER-NAME, GS_PARAMETER-ADDRESS.
    IF P_INSN IS NOT INITIAL.
      CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
        EXPORTING
          I_NUMBER  = GW_NUMBER
          I_KIND    = 'P'
          I_NATION  = 'I'
        IMPORTING
          E_NAME    = GS_PARAMETER-NAME
          E_ADDRESS = GS_PARAMETER-ADDRESS.
      IF GS_PARAMETER-NAME = GS_PARAMETER-HEADER02.
        CLEAR GS_PARAMETER-NAME.
      ENDIF.
      IF GS_PARAMETER-ADDRESS = GS_PARAMETER-HEADER03.
        CLEAR GS_PARAMETER-ADDRESS.
      ENDIF.
      TRANSLATE GS_PARAMETER-NAME TO UPPER CASE.
    ENDIF.

    CLEAR GW_NUMBER.
    TRANSLATE GS_PARAMETER-HEADER02 TO UPPER CASE.

    CONCATENATE 'Điện thoại/ Tel:' GS_PARAMETER-TEL_NUMBER INTO GS_PARAMETER-TEL_NUMBER SEPARATED BY SPACE.
    CONCATENATE 'Fax:'        GS_PARAMETER-FAX_NUMBER INTO GS_PARAMETER-FAX_NUMBER SEPARATED BY SPACE.
    CONCATENATE 'MST/ TIN:'    GS_PARAMETER-TAX INTO GS_PARAMETER-TAX SEPARATED BY SPACE.

*    IF GS_HEADER-UMLGO(02) EQ 'BX'.
*      GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU XUẤT HÀNG'.
*    ELSE.
*      GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU NHẬP HÀNG VỀ KHO TỔNG'.
*    ENDIF.

*    IF GS_HEADER-RSDAT IS NOT INITIAL.
*      IF P_INSN IS INITIAL.
*        CONCATENATE 'Ngày' GS_HEADER-RSDAT+06(02) 'tháng' GS_HEADER-RSDAT+04(02) 'năm' GS_HEADER-RSDAT(04) INTO GS_PARAMETER-HEADER05 SEPARATED BY SPACE.
*      ELSE.
*        CONCATENATE 'Ngày/ Date' GS_HEADER-RSDAT+06(02) 'tháng/ month' GS_HEADER-RSDAT+04(02) 'năm/ year' GS_HEADER-RSDAT(04) INTO GS_PARAMETER-HEADER05 SEPARATED BY SPACE.
*      ENDIF.
*    ENDIF.
    " Ngày yêu cầu hiển thị dd/mm/yyyy sau nhãn "Ngày yêu cầu:" (theo mẫu form)
    CLEAR GS_PARAMETER-HEADER05.
    IF GS_HEADER-RSDAT IS NOT INITIAL.
      CONCATENATE GS_HEADER-RSDAT+06(02) GS_HEADER-RSDAT+04(02) GS_HEADER-RSDAT(04)
             INTO GS_PARAMETER-HEADER05 SEPARATED BY '/'.
    ENDIF.

    "LAY THONG TIN DON VI NHAN
*    IF GS_HEADER-KUNNR IS NOT INITIAL.
*      GW_NUMBER = GS_HEADER-KUNNR.
*
*      CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
*        EXPORTING
*          I_KIND   = 'D'
*          I_NUMBER = GW_NUMBER
*        IMPORTING
*          E_NAME   = GS_PARAMETER-HEADER07.
*
*      SHIFT GW_NUMBER LEFT DELETING LEADING '0'.
*      CONCATENATE GW_NUMBER '-' GS_PARAMETER-HEADER07 INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
*
*      CLEAR GW_NUMBER.
*    ELSEIF GS_HEADER-KOSTL IS NOT INITIAL.
*      CONCATENATE GS_HEADER-KOSTL '-' GS_HEADER-LTEXT INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
*    ELSEIF GS_HEADER-ANLN1 IS NOT INITIAL.
*      READ TABLE GT_ANLA INTO GS_ANLA WITH KEY ANLN1 = GS_HEADER-ANLN1.
*      CONCATENATE GS_HEADER-ANLN1 '-' GS_ANLA-TXT50 INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
*    ELSEIF GS_HEADER-AUFNR IS NOT INITIAL.
*      SHIFT GS_HEADER-AUFNR LEFT DELETING LEADING '0'.
*      IF P_INSN IS INITIAL.
*        CONCATENATE 'Lệnh' GS_HEADER-AUFNR INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
*      ELSE.
*        CONCATENATE 'Lệnh/ Order No.' GS_HEADER-AUFNR INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
*      ENDIF.
*    ELSE.
*      CONCATENATE GS_HEADER-UMLGO GW_LGOBE INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
*    ENDIF.
    " Đơn vị nhận, thứ tự ưu tiên
    " Lệnh SX + thành phẩm + Lô TP, rồi Cost Center, Tài sản, Khách hàng, SLoc nhận
    CLEAR GS_PARAMETER-HEADER07.
    CLEAR LS_AFPO.
    IF GS_HEADER-AUFNR IS NOT INITIAL.
      READ TABLE GT_AFPO INTO LS_AFPO WITH TABLE KEY AUFNR = GS_HEADER-AUFNR.
    ENDIF.

    IF LS_AFPO-AUFNR IS NOT INITIAL.
      LV_AUFNR = GS_HEADER-AUFNR.
      SHIFT LV_AUFNR LEFT DELETING LEADING '0'.
      CONCATENATE 'Lệnh sản xuất' LV_AUFNR '–' LS_AFPO-MAKTX '– Lô TP' LS_AFPO-CHARG
             INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
    ELSEIF GS_HEADER-KOSTL IS NOT INITIAL.
      CONCATENATE GS_HEADER-KOSTL '-' GS_HEADER-LTEXT INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
    ELSEIF GS_HEADER-ANLN1 IS NOT INITIAL.
      READ TABLE GT_ANLA INTO GS_ANLA WITH KEY ANLN1 = GS_HEADER-ANLN1.
      CONCATENATE GS_HEADER-ANLN1 '-' GS_ANLA-TXT50 INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
    ELSEIF GS_HEADER-KUNNR IS NOT INITIAL.
      GW_NUMBER = GS_HEADER-KUNNR.

      CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
        EXPORTING
          I_KIND   = 'D'
          I_NUMBER = GW_NUMBER
        IMPORTING
          E_NAME   = GS_PARAMETER-HEADER07.

      SHIFT GW_NUMBER LEFT DELETING LEADING '0'.
      CONCATENATE GW_NUMBER '-' GS_PARAMETER-HEADER07 INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.

      CLEAR GW_NUMBER.
    ELSEIF GS_HEADER-AUFNR IS NOT INITIAL.
      " Lệnh không phải lệnh sản xuất (ví dụ lệnh bảo trì): giữ cách hiển thị cũ
      LV_AUFNR = GS_HEADER-AUFNR.
      SHIFT LV_AUFNR LEFT DELETING LEADING '0'.
      IF P_INSN IS INITIAL.
        CONCATENATE 'Lệnh' LV_AUFNR INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
      ELSE.
        CONCATENATE 'Lệnh/ Order No.' LV_AUFNR INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
      ENDIF.
    ELSE.
      CONCATENATE GS_HEADER-UMLGO GW_LGOBE INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
    ENDIF.

    "LAY THONG TIN DON VI XUAT
*    CONCATENATE GS_HEADER-LGORT GS_HEADER-LGOBE INTO GS_PARAMETER-HEADER09 SEPARATED BY SPACE.
    " SLoc + tên kho, SLoc quản lý bằng EWM thì thêm mã Warehouse; phiếu có nhiều kho thì liệt kê đủ
    CLEAR GS_PARAMETER-HEADER09.
    LOOP AT GT_PRINT INTO GS_DATA FROM GS_HEADER-LINESTART TO GS_HEADER-LINEEND.
      PERFORM GET_WAREHOUSE USING GS_DATA-WERKS GS_DATA-LGORT CHANGING LV_LGNUM.
      LV_KHO = |{ GS_DATA-LGORT } – { GS_DATA-LGOBE }|.
      IF LV_LGNUM IS NOT INITIAL.
        LV_KHO = |{ LV_KHO } ({ LV_LGNUM })|.
      ENDIF.
      IF GS_PARAMETER-HEADER09 IS INITIAL.
        GS_PARAMETER-HEADER09 = LV_KHO.
      ELSEIF GS_PARAMETER-HEADER09 NS LV_KHO.
        GS_PARAMETER-HEADER09 = |{ GS_PARAMETER-HEADER09 }; { LV_KHO }|.
      ENDIF.
    ENDLOOP.

    "LAY THONG TIN NGUOI YEU CAU
*    IF GS_HEADER-WEMPF IS NOT INITIAL.
*      GS_PARAMETER-HEADER11 = GS_HEADER-WEMPF.
*    ELSE.
*      GS_PARAMETER-HEADER11 = GS_HEADER-USNAM.
*    ENDIF.
    " RKPF-WEMPF, nếu trống thì họ tên người tạo (ADRP), không có thì user ID
    IF GS_HEADER-WEMPF IS NOT INITIAL.
      GS_PARAMETER-HEADER11 = GS_HEADER-WEMPF.
    ELSE.
      CLEAR LS_USER.
      READ TABLE GT_USER INTO LS_USER WITH KEY USNAM = GS_HEADER-USNAM.
      IF LS_USER-NAME_TEXT IS NOT INITIAL.
        GS_PARAMETER-HEADER11 = LS_USER-NAME_TEXT.
      ELSE.
        GS_PARAMETER-HEADER11 = GS_HEADER-USNAM.
      ENDIF.
    ENDIF.

    " Diễn giải = Item text đầu tiên có giá trị của chính phiếu này
    CLEAR GS_PARAMETER-HEADER13.
    LOOP AT GT_PRINT ASSIGNING FIELD-SYMBOL(<LF_SGTXT>)
         FROM GS_HEADER-LINESTART TO GS_HEADER-LINEEND
         WHERE SGTXT IS NOT INITIAL.
      GS_PARAMETER-HEADER13 = <LF_SGTXT>-SGTXT.
      EXIT.
    ENDLOOP.

    CLEAR GT_DATA.
*    APPEND LINES OF GT_PREDATA FROM GS_HEADER-LINESTART TO GS_HEADER-LINEEND TO GT_DATA.
    APPEND LINES OF GT_PRINT FROM GS_HEADER-LINESTART TO GS_HEADER-LINEEND TO GT_DATA.

    " Mã biểu mẫu GMP theo Plant (bảng tham số)
    CLEAR GS_PARAMETER-HEADER18.
    READ TABLE GT_PARAM INTO DATA(LS_FORM) WITH KEY PARAM_ID = GC_PAR_FORM
                                                     KEY1     = GS_HEADER-WERKS.
    IF SY-SUBRC = 0 AND LS_FORM-PVALUE IS NOT INITIAL.
      GS_PARAMETER-HEADER18 = COND #( WHEN P_INSN IS INITIAL THEN |Mã biểu mẫu: { LS_FORM-PVALUE }|
                                      ELSE |Mã biểu mẫu/ Form code: { LS_FORM-PVALUE }| ).
    ENDIF.

    " Lần in theo nhật ký in; từ lần 2 là bản in lại
    CLEAR LV_COUNT.
    READ TABLE LT_CNT INTO DATA(LS_CNT) WITH TABLE KEY OBJ_KEY = CONV ZEWM_DE_OBJ_KEY( GS_HEADER-RSNUM ).
    IF SY-SUBRC = 0.
      LV_COUNT = LS_CNT-PRT_COUNT.
    ENDIF.
    IF LV_COUNT = 0.
      GS_PARAMETER-HEADER19 = |Lần in: 1|.
    ELSE.
      GS_PARAMETER-HEADER19 = |Bản in lại – lần { LV_COUNT + 1 }|.
      IF IV_PREVIEW = ABAP_FALSE.
        MESSAGE I005(ZWM01) WITH GS_PARAMETER-HEADER15 LV_COUNT.
      ENDIF.
    ENDIF.

    CALL FUNCTION FM_NAME
      EXPORTING
        CONTROL_PARAMETERS = WA_CPARAM
        OUTPUT_OPTIONS     = WA_OUTPUT
        USER_SETTINGS      = SPACE
        GS_PARAMETER       = GS_PARAMETER
*        GW_FLAG            = R_1
        GW_FLAG            = P_INSN
      TABLES
        GT_DATA            = GT_DATA
      EXCEPTIONS
        FORMATTING_ERROR   = 1
        INTERNAL_ERROR     = 2
        SEND_ERROR         = 3
        USER_CANCELED      = 4
        OTHERS             = 5.
    IF SY-SUBRC <> 0.
*      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      IF SY-MSGID IS NOT INITIAL.
        MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 DISPLAY LIKE 'E'.
      ENDIF.
      EXIT.
    ENDIF.
    REFRESH GT_DATA.
  ENDLOOP.

  DATA WA_JOB_OUTPUT_INFO  TYPE SSFCRESCL.
  CALL FUNCTION 'SSF_CLOSE'
    IMPORTING
      JOB_OUTPUT_INFO  = WA_JOB_OUTPUT_INFO
    EXCEPTIONS
      FORMATTING_ERROR = 1
      INTERNAL_ERROR   = 2
      SEND_ERROR       = 3
      OTHERS           = 4.

  IF SY-SUBRC <> 0.
*    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    IF SY-MSGID IS NOT INITIAL.
      MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 DISPLAY LIKE 'E'.
    ENDIF.
    RETURN.
  ENDIF.

  " Ghi nhật ký in khi đã in ra máy in
  IF WA_JOB_OUTPUT_INFO-OUTPUTDONE = ABAP_TRUE.
    PERFORM WRITE_PRTLOG USING LT_CNT.
  ENDIF.
ENDFORM.                    " EXPORT_DATA
*&---------------------------------------------------------------------*
*&      Form  F4_HELP_RSNUM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F4_HELP_RSNUM_LOW.
  LW_HILFE = 'HLPR'.
  CALL FUNCTION 'MB_SELECT_RESERVATION'
    EXPORTING
      HILFE = LW_HILFE
    IMPORTING
      RSNUM = S_RSNUM-LOW
      RSPOS = RM07M-RSPOS.
ENDFORM.                    " F4_HELP_RSNUM
*&---------------------------------------------------------------------*
*&      Form  F4_HELP_RSNUM_HIGH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F4_HELP_RSNUM_HIGH .
  LW_HILFE = 'HLPR'.
  CALL FUNCTION 'MB_SELECT_RESERVATION'
    EXPORTING
      HILFE = LW_HILFE
    IMPORTING
      RSNUM = S_RSNUM-HIGH
      RSPOS = RM07M-RSPOS.
ENDFORM.                    " F4_HELP_RSNUM_HIGH

*&---------------------------------------------------------------------*
*&      Form  CHECK_TK
*&---------------------------------------------------------------------*
*       Tồn kho sẵn sàng theo Plant/SLoc/Material (không theo Batch).
*       Trước đây lấy bằng SUBMIT ZSAP_PG_RM07MLBD, nay đọc trực tiếp tồn unrestricted.
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
  " CHECK_TK, GET_PCK không còn dùng: phiếu in không so sánh tồn
*FORM CHECK_TK .

*  DATA:
*    LRT_LGORT      TYPE RANGE OF LGORT_D,
*    LRT_LGORT_S    TYPE RANGE OF LGORT_D WITH HEADER LINE,
*    LRT_MATNR      TYPE RANGE OF MATNR,
*    LRT_WERKS      TYPE RANGE OF T001W-WERKS.
**    LRT_DATUM      TYPE RANGE OF MKPF-BUDAT WITH HEADER LINE,
**    LT_TOTAL_BATCH TYPE TABLE OF GTY_TOTAL_BATCH WITH HEADER LINE.

*  LRT_MATNR = VALUE #( FOR LS_DATA IN GT_PREDATA
*                  ( SIGN = 'I'
*                    OPTION = 'EQ'
*                    LOW = LS_DATA-MATNR )
*                  ).
*  SORT LRT_MATNR BY LOW.
*  DELETE ADJACENT DUPLICATES FROM LRT_MATNR COMPARING LOW.

*  LRT_WERKS = VALUE #( FOR LS_DATA IN GT_PREDATA
*                  ( SIGN = 'I'
*                    OPTION = 'EQ'
*                    LOW = LS_DATA-WERKS )
*                  ).
*  SORT LRT_WERKS BY LOW.
*  DELETE ADJACENT DUPLICATES FROM LRT_WERKS COMPARING LOW.

*  LRT_LGORT = VALUE #( FOR LS_DATA IN GT_PREDATA
*                  ( SIGN = 'I'
*                    OPTION = 'EQ'
*                    LOW = LS_DATA-LGORT )
*                  ).
*  LRT_LGORT_S[] = LRT_LGORT[].

*  LRT_LGORT_S-SIGN = 'I'.
*  LRT_LGORT_S-OPTION = 'EQ'.
*  LRT_LGORT_S-LOW = 'B101'.
*  APPEND LRT_LGORT_S.
*  LRT_LGORT_S-SIGN = 'I'.
*  LRT_LGORT_S-OPTION = 'EQ'.
*  LRT_LGORT_S-LOW = 'B102'.
*  APPEND LRT_LGORT_S.

*  LRT_LGORT_S-SIGN = 'I'.
*  LRT_LGORT_S-OPTION = 'EQ'.
*  LRT_LGORT_S-LOW = 'B106'.
*  APPEND LRT_LGORT_S.
*  LRT_LGORT_S-SIGN = 'I'.
*  LRT_LGORT_S-OPTION = 'EQ'.
*  LRT_LGORT_S-LOW = 'B112'.
*  APPEND LRT_LGORT_S.

*  SORT LRT_LGORT_S BY LOW.
*  DELETE ADJACENT DUPLICATES FROM LRT_LGORT_S COMPARING LOW.



**  LRT_DATUM-SIGN = 'I'.
**  LRT_DATUM-OPTION = 'EQ'.
**  LRT_DATUM-LOW = SY-DATUM.
**  APPEND LRT_DATUM.
**
**  SUBMIT ZSAP_PG_RM07MLBD USING SELECTION-SCREEN '1000'
**        WITH MATNR    IN LRT_MATNR[]
**        WITH WERKS    IN LRT_WERKS[]
**        WITH LGORT    IN LRT_LGORT_S[]
**        WITH DATUM    IN LRT_DATUM[]
***        WITH CHARG    IN GR_CHARG[]
**        WITH LGBST    EQ 'X'    "Storage Loc./Batch Stock
**        WITH BWBST    EQ ''     "Valuated Stock
**        WITH SBBST    EQ ''     "Special Stock
**        WITH XSUM     EQ ''     "Totals Only - Hierarchical Representation
**        WITH PA_SUMFL EQ 'X'    "Totals Only - Non-Hierarchical Representation
**        WITH XCHAR    EQ ''     "Only Matls Handled in Batches
**        WITH XNOMCHB  EQ ''     "Also Batches w/o Stock Segment
**        WITH NOSTO    EQ ''    "No Reversal Movement, check no X
**        WITH PA_WDZER EQ 'X'    "Without Opening Stock; Without Closing Stock
**        WITH PA_WDZEW EQ 'X'    "Without Opening Stock; With Closing Stock
**        WITH PA_WDWIZ EQ 'X'    "With Opening Stock; Without Closing Stock
**        WITH PA_WDWUW EQ 'X'    "With Opening Stock; With Closing Stock; Changed
**        WITH PA_WDWEW EQ 'X'    "With Opening Stock; With Closing Stock; Unchanged
**        WITH PA_NDZER EQ ''     "Without Openning Stock; Without Closing Stock
**        WITH PA_NDSTO EQ 'X'    "With Openning Stock; With Closing Stock; Unchanged
**        WITH P_SUBMIT EQ 'X'
**        AND RETURN.
**  IMPORT BESTAND TO LT_TOTAL_BATCH FROM MEMORY ID 'ZSAP_PG_RM07MLBD'.
**  FREE MEMORY ID 'ZSAP_PG_RM07MLBD'.
**
**  LOOP AT LT_TOTAL_BATCH INTO GS_MB5B.
**    CLEAR: GS_MB5B-CHARG.
**
**    COLLECT GS_MB5B INTO GT_MB5B.
**    CLEAR GS_MB5B.
**  ENDLOOP.
**  SORT GT_MB5B BY WERKS LGORT MATNR.
**
**  CLEAR LT_TOTAL_BATCH[].

*  SELECT WERKS, LGORT, MATNR, SUM( LABST ) AS ENDMENGE
*    FROM NSDM_E_MARD
*    WHERE MATNR IN @LRT_MATNR
*      AND WERKS IN @LRT_WERKS
*      AND LGORT IN @LRT_LGORT_S[]
*    GROUP BY WERKS, LGORT, MATNR
*    INTO CORRESPONDING FIELDS OF TABLE @GT_MB5B.
*  SORT GT_MB5B BY WERKS LGORT MATNR.

*ENDFORM.                    " CHECK_TK

**&---------------------------------------------------------------------*
**&      Form  GET_PCK
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**----------------------------------------------------------------------*
*FORM GET_PCK .

**  SELECT
**         MSEG~MBLNR
**         MSEG~MJAHR
**         MSEG~RSNUM
**         MSEG~RSPOS
**         MSEG~ERFMG
**         MSEG~ERFME
**         MSEG~SMBLN
**         MSEG~SJAHR
**   FROM MSEG
**   INTO TABLE GT_PCK
**   FOR ALL ENTRIES IN GT_PREDATA
** WHERE MSEG~XAUTO NE 'X'
**   AND MSEG~RSNUM = GT_PREDATA-RSNUM.

*  DATA LT_KEY_RS TYPE STANDARD TABLE OF GTY_KEY_RS.

*  LT_KEY_RS = VALUE #( FOR LS_P IN GT_PREDATA ( RSNUM = LS_P-RSNUM ) ).
*  SORT LT_KEY_RS BY RSNUM.
*  DELETE ADJACENT DUPLICATES FROM LT_KEY_RS COMPARING RSNUM.

*  SELECT MSEG~MBLNR, MSEG~MJAHR, MSEG~RSNUM, MSEG~RSPOS,
*         MSEG~ERFMG, MSEG~ERFME, MSEG~SMBLN, MSEG~SJAHR
*    FROM MSEG
*    INNER JOIN @LT_KEY_RS AS K ON K~RSNUM = MSEG~RSNUM
*    WHERE MSEG~XAUTO <> 'X'
*    INTO TABLE @GT_PCK.

*  DATA(LT_PCK) = GT_PCK[].

*  DELETE GT_PCK WHERE SMBLN IS NOT INITIAL.
*  DELETE LT_PCK WHERE SMBLN IS INITIAL.
*  SORT LT_PCK BY SMBLN SJAHR.
*  LOOP AT GT_PCK INTO DATA(LS_PCK).
*    READ TABLE LT_PCK TRANSPORTING NO FIELDS
*      WITH KEY SMBLN = LS_PCK-MBLNR
*               SJAHR = LS_PCK-MJAHR
*      BINARY SEARCH.
*    IF SY-SUBRC IS INITIAL.
*      DELETE TABLE GT_PCK FROM LS_PCK.
*    ENDIF.
*  ENDLOOP.

*  SORT GT_PCK BY RSNUM RSPOS.

*ENDFORM.                    " GET_PCK

*
*
