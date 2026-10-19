*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PYCVT_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*

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

  SELECT
    RESB~WERKS  "PLANT
    RESB~RSNUM  "Number of Reservation/Dependent Requirement
    RKPF~RSDAT  "NGAY YEU CAU
    RKPF~KUNNR  "DON VI NHAN 1
    RKPF~KOSTL  "DON VI NHAN 2
    CSKT~LTEXT  "DON VI NHAN 3
    RKPF~ANLN1  "DON VI NHAN 4
    RKPF~AUFNR  "DON VI NHAN 5
    RESB~UMLGO  "Đơn vị nhận 6
    RESB~LGORT  "Đơn vị xuất
    T001L~LGOBE "DIEN GIAI KHO
    RKPF~WEMPF  "NGUOI YEU CAU 1
    RKPF~USNAM  "NGUOI YEU CAU 2
    RESB~SGTXT  "DIEN GIAI
    RESB~MATNR  "Material Number
    MAKT~MAKTX  "Material Description
*    RESB~MEINS  "DON VI TINH
    RESB~ERFME
    RESB~BDMNG  "Requirement Quantity
    RESB~RSPOS  "STT
    RESB~ABLAD  "UPLOADING POINT
    AFIH~EQUNR  "THIET BI
    RESB~BWART  "MOVEMENT TYPE
    RESB~SOBKZ  "PHAN CHU CUA MOVEMENT TYPE
    RESB~ENMNG  "SO LUONG THUC XUAT
    RESB~ERFMG
    MARA~MTART
  INTO CORRESPONDING FIELDS OF TABLE GT_PREDATA
  FROM RESB
      LEFT  JOIN T001L ON T001L~WERKS = RESB~WERKS AND T001L~LGORT = RESB~LGORT
      INNER JOIN RKPF  ON RESB~RSNUM  = RKPF~RSNUM
      INNER JOIN MARA  ON MARA~MATNR  = RESB~MATNR    "SauHT---update----25.10.2025
      INNER JOIN MAKT  ON MAKT~MATNR  = RESB~MATNR AND MAKT~SPRAS = 'E'
      LEFT  JOIN AFIH  ON RESB~AUFNR  = AFIH~AUFNR
      LEFT  JOIN CSKT  ON CSKT~KOKRS  = 'BDFC' AND CSKT~KOSTL = RKPF~KOSTL AND CSKT~DATBI GE SY-DATUM AND CSKT~SPRAS = SY-LANGU
  WHERE RESB~RSNUM IN S_RSNUM
    AND RESB~XLOEK NE 'X'
*    AND RESB~KZEAR NE 'X'
    AND RESB~POSTP NE 'N'.
*    AND RESB~WERKS IN LSU_WERKS.

  IF SY-SUBRC <> 0.
    MESSAGE 'No data found' TYPE 'I'.
    STOP.
  ENDIF.

  "PHAN QUYEN
  TYPES:  BEGIN OF GTY_WERKS,
            WERKS TYPE MSEG-WERKS,
          END OF GTY_WERKS.

  DATA: GT_WERKSA TYPE TABLE OF GTY_WERKS,
        GS_WERKSA TYPE          GTY_WERKS,

        GT_WERKSB TYPE TABLE OF GTY_WERKS,
        GS_WERKSB TYPE          GTY_WERKS.

  MOVE-CORRESPONDING GT_PREDATA TO GT_WERKSA .
  MOVE-CORRESPONDING GT_PREDATA TO GT_WERKSB .

  SORT GT_WERKSA BY WERKS .
  DELETE ADJACENT DUPLICATES FROM GT_WERKSA COMPARING WERKS.

  SORT GT_WERKSB BY WERKS .
  DELETE ADJACENT DUPLICATES FROM GT_WERKSB COMPARING WERKS.

  LOOP AT GT_WERKSB INTO GS_WERKSB.
    AUTHORITY-CHECK OBJECT 'M_MSEG_WMB'
      ID 'WERKS' FIELD GS_WERKSB-WERKS
      ID 'ACTVT' FIELD '03'.
    IF SY-SUBRC <> 0.
      DELETE GT_PREDATA WHERE WERKS = GS_WERKSB-WERKS .
    ENDIF.
  ENDLOOP.

  LOOP AT GT_WERKSA INTO GS_WERKSA.
    AUTHORITY-CHECK OBJECT 'M_MRES_WWA'
      ID 'WERKS' FIELD GS_WERKSA-WERKS
      ID 'ACTVT' FIELD '03'.
    IF SY-SUBRC <> 0.
      DELETE GT_PREDATA WHERE WERKS = GS_WERKSB-WERKS .
    ENDIF.
  ENDLOOP.

  IF GT_PREDATA IS INITIAL.
    MESSAGE 'No Authentication' TYPE 'I'.
    STOP.
  ENDIF.
  "END PHAN QUYEN

  "LAY THONG TIN DIEN GIAI THIET BI
  SELECT
    EQUNR
    EQKTX
  INTO TABLE GT_EQKT
  FROM EQKT
  FOR ALL ENTRIES IN GT_PREDATA
  WHERE EQUNR EQ GT_PREDATA-EQUNR
    AND SPRAS EQ SY-LANGU.

  SELECT
    LGORT
    LGOBE
  INTO TABLE GT_T001L
  FROM T001L
  FOR ALL ENTRIES IN GT_PREDATA
  WHERE LGORT EQ GT_PREDATA-UMLGO
    AND WERKS EQ GT_PREDATA-WERKS.

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

  SELECT
    BUKRS
    ANLN1
    TXT50
  INTO TABLE GT_ANLA
  FROM ANLA
  FOR ALL ENTRIES IN GT_PREDATA
  WHERE ANLN1 EQ GT_PREDATA-ANLN1
    AND BUKRS EQ LW_BUKRS.

*----SauHT----update--------25.10.2025-------------start-------*
  IF P_KTNVL IS NOT INITIAL.
    PERFORM CHECK_TK.
  ENDIF.


  "Lay CT chuyen kho theo PYC
  PERFORM GET_PCK.


*----SauHT----update--------25.10.2025-------------end---------*

ENDFORM.             " FILL_DATA
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


  SORT GT_PREDATA BY RSNUM LGORT RSPOS.

  "SauHT----update-----24.10.2025------start--------*
*  LOOP AT GT_PREDATA INTO GS_DATA.
  LOOP AT GT_PREDATA ASSIGNING FIELD-SYMBOL(<LF_DATA>).
*    GS_DATA = <LF_DATA>.
    GW_LINEEND = SY-TABIX.
    AT NEW LGORT.
      GW_LINESTART = SY-TABIX.
    ENDAT.

    IF <LF_DATA>-ERFMG > 0.
      "Check Phieu chuyen kho
      CLEAR LW_SL_CK.
      LOOP AT GT_PCK INTO DATA(LS_PCK) WHERE RSNUM = <LF_DATA>-RSNUM
                                         AND RSPOS = <LF_DATA>-RSPOS.
        LW_SL_CK = LW_SL_CK + LS_PCK-ERFMG.
      ENDLOOP.

      LW_SL_CL = <LF_DATA>-ERFMG - LW_SL_CK.

      IF LW_SL_CL = 0.
        <LF_DATA>-SS_TK = 'Đã xuất đủ'.
      ELSEIF LW_SL_CL > 0.

        IF <LF_DATA>-MTART = 'B101' OR <LF_DATA>-MTART = 'B102'.
          LRT_LGORT-SIGN = 'I'.
          LRT_LGORT-OPTION = 'EQ'.
          LRT_LGORT-LOW = 'B101'.
          APPEND LRT_LGORT.

          LRT_LGORT-SIGN = 'I'.
          LRT_LGORT-OPTION = 'EQ'.
          LRT_LGORT-LOW = 'B102'.
          APPEND LRT_LGORT.
        ELSEIF <LF_DATA>-MTART = 'B106' OR <LF_DATA>-MTART = 'B112'.
          LRT_LGORT-SIGN = 'I'.
          LRT_LGORT-OPTION = 'EQ'.
          LRT_LGORT-LOW = 'B106'.
          APPEND LRT_LGORT.

          LRT_LGORT-SIGN = 'I'.
          LRT_LGORT-OPTION = 'EQ'.
          LRT_LGORT-LOW = 'B112'.
          APPEND LRT_LGORT.
        ENDIF.

        LOOP AT GT_MB5B INTO GS_MB5B WHERE WERKS = <LF_DATA>-WERKS
                                       AND MATNR = <LF_DATA>-MATNR
                                       AND LGORT IN LRT_LGORT[].
          <LF_DATA>-ENDMENGE = <LF_DATA>-ENDMENGE + GS_MB5B-ENDMENGE.
        ENDLOOP.

        LW_THIEU = <LF_DATA>-ENDMENGE - <LF_DATA>-ERFMG.
        IF LW_THIEU >= 0.
          <LF_DATA>-SS_TK = 'Đủ'.
        ELSE.
          LW_THIEU = ABS( LW_THIEU ).
          WRITE LW_THIEU TO <LF_DATA>-SS_TK UNIT <LF_DATA>-ERFME.
*      <LF_DATA>-SS_TK = ABS( LW_THIEU ).
          CONDENSE <LF_DATA>-SS_TK NO-GAPS.
          CONCATENATE 'Thiếu' '-' <LF_DATA>-SS_TK INTO <LF_DATA>-SS_TK SEPARATED BY SPACE.
        ENDIF.
      ENDIF.
    ENDIF.

    "SauHT----update-----24.10.2025------end----------*
    IF GS_PARAMETER-HEADER13 IS INITIAL.
      GS_PARAMETER-HEADER13 = <LF_DATA>-SGTXT.
    ENDIF.

    "SauHT----update-----24.10.2025------start----------*
    GS_HEADER = <LF_DATA>.
*    GS_HEADER = GS_DATA.
    "SauHT----update-----24.10.2025------end----------*
    AT END OF LGORT.
      GS_HEADER-LINEEND = GW_LINEEND.
      GS_HEADER-LINESTART = GW_LINESTART.
      APPEND GS_HEADER TO GT_HEADER.
      CLEAR GS_HEADER.
    ENDAT.
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

  GS_PARAMETER-PARAMETER01 = 'STT'.
  GS_PARAMETER-PARAMETER02 = 'Mã hàng'.
  GS_PARAMETER-PARAMETER03 = 'Tên hàng'.
  GS_PARAMETER-PARAMETER04 = 'ĐVT'.
  GS_PARAMETER-PARAMETER05 = 'Số lượng yêu cầu'.
  GS_PARAMETER-PARAMETER06 = 'Số lô'.
  GS_PARAMETER-PARAMETER07 = 'Số lượng thực xuất'.
  IF P_KTNVL IS NOT INITIAL.
    GS_PARAMETER-PARAMETER06 = 'Thiếu/ đủ so với SL yêu cầu'.
    GS_PARAMETER-PARAMETER07 =  'Tồn kho sẵn sàng'.
  ENDIF.
  GS_PARAMETER-PARAMETER08 = 'Ghi chú'.

  IF P_INSN IS INITIAL.
    GS_PARAMETER-HEADER04 = 'Số Reservation:'.
    GS_PARAMETER-HEADER06 = 'Đơn vị nhận:'.
    GS_PARAMETER-HEADER08 = 'Đơn vị xuất:'.
    GS_PARAMETER-HEADER10 = 'Người yêu cầu:'.
    GS_PARAMETER-HEADER12 = 'Diễn giải:'.

    GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU VẬT TƯ'.
    GS_PARAMETER-FOOTER01 = 'Trưởng bộ phận'.
    GS_PARAMETER-FOOTER03 = 'Người nhận'.
    GS_PARAMETER-FOOTER04 = 'Người lập'.
    GS_PARAMETER-FOOTER02 = 'Người giao'.
    GS_PARAMETER-FOOTER05 = 'Ngày …… Tháng …… Năm ………'.
    GS_PARAMETER-FOOTER06 = 'Trang'.
  ELSE.
    GS_PARAMETER-PARAMETER06 = 'Số lô sản xuất'.

    GS_PARAMETER-HEADER04 = 'Số yêu cầu/ Reservation No.:'.
    GS_PARAMETER-HEADER01 = 'PHIẾU YÊU CẦU VẬT TƯ/ MATERIAL REQUISITION SLIP'.
    GS_PARAMETER-HEADER06 = 'Đơn vị nhận/ Recipient unit:'.
    GS_PARAMETER-HEADER08 = 'Đơn vị xuất/ Export unit:'.
    GS_PARAMETER-HEADER10 = 'Người yêu cầu/ Requester:'.
    GS_PARAMETER-HEADER12 = 'Diễn giải/ Description:'.

    GS_PARAMETER-PARAMETER11 = 'No.'.
    GS_PARAMETER-PARAMETER12 = 'Goods code'.
    GS_PARAMETER-PARAMETER13 = 'Goods name'.
    GS_PARAMETER-PARAMETER14 = 'Unit'.
    GS_PARAMETER-PARAMETER15 = 'Required quantity'.
    GS_PARAMETER-PARAMETER16 = 'Batch number'.
    GS_PARAMETER-PARAMETER17 = 'Actual quantity'.
    GS_PARAMETER-PARAMETER18 = 'Remark'.

    GS_PARAMETER-FOOTER05 = 'Ngày/ Date …… tháng/ month …… năm/ year ………'.
    GS_PARAMETER-FOOTER06 = 'Trang/ Page'.

    IF R_1 IS NOT INITIAL.
      GS_PARAMETER-FOOTER01 = 'Người nhận/ Receiver'.
      GS_PARAMETER-FOOTER02 = 'Trưởng phòng QA/ QA Head'.
      GS_PARAMETER-FOOTER03 = 'Trưởng bộ phận/ Department Head'.
      GS_PARAMETER-FOOTER04 = 'Người lập/ Initiator'.
    ELSE.
      GS_PARAMETER-FOOTER01 = 'Nhân viên kho'.
      GS_PARAMETER-FOOTER02 = 'Trưởng phòng QA'.
      GS_PARAMETER-FOOTER03 = 'Trưởng bộ phận'.
      GS_PARAMETER-FOOTER04 = 'Người lập'.

      GS_PARAMETER-SIGN01 = 'Warehouse staff'.
      GS_PARAMETER-SIGN02 = 'QA Head'.
      GS_PARAMETER-SIGN03 = 'Department Head'.
      GS_PARAMETER-SIGN04 = 'Initiator'.
    ENDIF.

  ENDIF.


ENDFORM.                    " GET_PARAMETER
*&---------------------------------------------------------------------*
*&      Form  EXPORT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM EXPORT_DATA .
  DATA: P_FORM  TYPE TDSFNAME,
        FM_NAME TYPE RS38L_FNAM.
  DATA: WA_CPARAM TYPE SSFCTRLOP,
        WA_OUTPUT TYPE SSFCOMPOP.

  IF P_INSN IS INITIAL.
    P_FORM = 'ZWM_SF_PYCVT'.
    IF P_KTNVL IS NOT INITIAL.
      P_FORM = 'ZWM_SF_PYCVT_TK'.
    ENDIF.
  ELSE.
    P_FORM = 'ZWM_SF_PYCVT_EN'.
  ENDIF.

  WA_CPARAM-NO_DIALOG = 'X'.
  WA_CPARAM-PREVIEW   = 'X'.
  WA_OUTPUT-TDDEST    = 'LP01'.
  WA_OUTPUT-TDNOPREV  = 'X'.
  WA_OUTPUT-TDIMMED   = 'X'.
  WA_OUTPUT-TDDELETE  = 'X'.

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
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
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
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    EXIT.
  ENDIF.
  WA_CPARAM-NO_OPEN       = 'X'.
  WA_CPARAM-NO_CLOSE      = 'X'.

  DATA LW_MOVETYPE TYPE CHAR5.

  LOOP AT GT_HEADER INTO GS_HEADER.
    "LAY THONG TIN THIET BI
    CONCATENATE GS_HEADER-BWART GS_HEADER-SOBKZ INTO LW_MOVETYPE.

    IF LW_MOVETYPE EQ 'Z11'.
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
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        I_NUMBER       = GW_NUMBER
        I_KIND         = 'P'
      IMPORTING
        E_NAME         = GS_PARAMETER-HEADER02
        E_ADDRESS      = GS_PARAMETER-HEADER03
        E_NAME_N_TITLE = GS_PARAMETER-NAME
        E_ADDRESS_EN   = GS_PARAMETER-ADDRESS
        E_TAX          = GS_PARAMETER-TAX
        E_TEL_NUMBER   = GS_PARAMETER-TEL_NUMBER
        E_FAX_NUMBER   = GS_PARAMETER-FAX_NUMBER.

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

    IF GS_HEADER-RSDAT IS NOT INITIAL.
      IF P_INSN IS INITIAL.
        CONCATENATE 'Ngày' GS_HEADER-RSDAT+06(02) 'tháng' GS_HEADER-RSDAT+04(02) 'năm' GS_HEADER-RSDAT(04) INTO GS_PARAMETER-HEADER05 SEPARATED BY SPACE.
      ELSE.
        CONCATENATE 'Ngày/ Date' GS_HEADER-RSDAT+06(02) 'tháng/ month' GS_HEADER-RSDAT+04(02) 'năm/ year' GS_HEADER-RSDAT(04) INTO GS_PARAMETER-HEADER05 SEPARATED BY SPACE.
      ENDIF.
    ENDIF.

    "LAY THONG TIN DON VI NHAN
    IF GS_HEADER-KUNNR IS NOT INITIAL.
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
    ELSEIF GS_HEADER-KOSTL IS NOT INITIAL.
      CONCATENATE GS_HEADER-KOSTL '-' GS_HEADER-LTEXT INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
    ELSEIF GS_HEADER-ANLN1 IS NOT INITIAL.
      READ TABLE GT_ANLA INTO GS_ANLA WITH KEY ANLN1 = GS_HEADER-ANLN1.
      CONCATENATE GS_HEADER-ANLN1 '-' GS_ANLA-TXT50 INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
    ELSEIF GS_HEADER-AUFNR IS NOT INITIAL.
      SHIFT GS_HEADER-AUFNR LEFT DELETING LEADING '0'.
      IF P_INSN IS INITIAL.
        CONCATENATE 'Lệnh' GS_HEADER-AUFNR INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
      ELSE.
        CONCATENATE 'Lệnh/ Order No.' GS_HEADER-AUFNR INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
      ENDIF.
    ELSE.
      CONCATENATE GS_HEADER-UMLGO GW_LGOBE INTO GS_PARAMETER-HEADER07 SEPARATED BY SPACE.
    ENDIF.

    "LAY THONG TIN DON VI XUAT
    CONCATENATE GS_HEADER-LGORT GS_HEADER-LGOBE INTO GS_PARAMETER-HEADER09 SEPARATED BY SPACE.

    "LAY THONG TIN NGUOI YEU CAU
    IF GS_HEADER-WEMPF IS NOT INITIAL.
      GS_PARAMETER-HEADER11 = GS_HEADER-WEMPF.
    ELSE.
      GS_PARAMETER-HEADER11 = GS_HEADER-USNAM.
    ENDIF.

    CLEAR GT_DATA.
    APPEND LINES OF GT_PREDATA FROM GS_HEADER-LINESTART TO GS_HEADER-LINEEND TO GT_DATA.

    CALL FUNCTION FM_NAME
      EXPORTING
        CONTROL_PARAMETERS = WA_CPARAM
        OUTPUT_OPTIONS     = WA_OUTPUT
        USER_SETTINGS      = SPACE
        GS_PARAMETER       = GS_PARAMETER
        GW_FLAG            = R_1
      TABLES
        GT_DATA            = GT_DATA
      EXCEPTIONS
        FORMATTING_ERROR   = 1
        INTERNAL_ERROR     = 2
        SEND_ERROR         = 3
        USER_CANCELED      = 4
        OTHERS             = 5.
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
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
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
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
*       text
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM CHECK_TK .

  DATA:
    LRT_LGORT      TYPE RANGE OF LGORT_D,
    LRT_LGORT_S    TYPE RANGE OF LGORT_D WITH HEADER LINE,
    LRT_MATNR      TYPE RANGE OF MATNR,
    LRT_WERKS      TYPE RANGE OF T001W-WERKS,
    LRT_DATUM      TYPE RANGE OF MKPF-BUDAT WITH HEADER LINE,
    LT_TOTAL_BATCH TYPE TABLE OF GTY_TOTAL_BATCH WITH HEADER LINE.

  LRT_MATNR = VALUE #( FOR LS_DATA IN GT_PREDATA
                  ( SIGN = 'I'
                    OPTION = 'EQ'
                    LOW = LS_DATA-MATNR )
                  ).
  SORT LRT_MATNR BY LOW.
  DELETE ADJACENT DUPLICATES FROM LRT_MATNR COMPARING LOW.

  LRT_WERKS = VALUE #( FOR LS_DATA IN GT_PREDATA
                  ( SIGN = 'I'
                    OPTION = 'EQ'
                    LOW = LS_DATA-WERKS )
                  ).
  SORT LRT_WERKS BY LOW.
  DELETE ADJACENT DUPLICATES FROM LRT_WERKS COMPARING LOW.

  LRT_LGORT = VALUE #( FOR LS_DATA IN GT_PREDATA
                  ( SIGN = 'I'
                    OPTION = 'EQ'
                    LOW = LS_DATA-LGORT )
                  ).
  LRT_LGORT_S[] = LRT_LGORT[].

  LRT_LGORT_S-SIGN = 'I'.
  LRT_LGORT_S-OPTION = 'EQ'.
  LRT_LGORT_S-LOW = 'B101'.
  APPEND LRT_LGORT_S.
  LRT_LGORT_S-SIGN = 'I'.
  LRT_LGORT_S-OPTION = 'EQ'.
  LRT_LGORT_S-LOW = 'B102'.
  APPEND LRT_LGORT_S.

  LRT_LGORT_S-SIGN = 'I'.
  LRT_LGORT_S-OPTION = 'EQ'.
  LRT_LGORT_S-LOW = 'B106'.
  APPEND LRT_LGORT_S.
  LRT_LGORT_S-SIGN = 'I'.
  LRT_LGORT_S-OPTION = 'EQ'.
  LRT_LGORT_S-LOW = 'B112'.
  APPEND LRT_LGORT_S.

  SORT LRT_LGORT_S BY LOW.
  DELETE ADJACENT DUPLICATES FROM LRT_LGORT_S COMPARING LOW.



  LRT_DATUM-SIGN = 'I'.
  LRT_DATUM-OPTION = 'EQ'.
  LRT_DATUM-LOW = SY-DATUM.
  APPEND LRT_DATUM.

  SUBMIT ZSAP_PG_RM07MLBD USING SELECTION-SCREEN '1000'
        WITH MATNR    IN LRT_MATNR[]
        WITH WERKS    IN LRT_WERKS[]
        WITH LGORT    IN LRT_LGORT_S[]
        WITH DATUM    IN LRT_DATUM[]
*        WITH CHARG    IN GR_CHARG[] "LuanLD2 18.12.2019
        WITH LGBST    EQ 'X'    "Storage Loc./Batch Stock
        WITH BWBST    EQ ''     "Valuated Stock
        WITH SBBST    EQ ''     "Special Stock
        WITH XSUM     EQ ''     "Totals Only - Hierarchical Representation
        WITH PA_SUMFL EQ 'X'    "Totals Only - Non-Hierarchical Representation
        WITH XCHAR    EQ ''     "Only Matls Handled in Batches
        WITH XNOMCHB  EQ ''     "Also Batches w/o Stock Segment
        WITH NOSTO    EQ ''    "No Reversal Movement VUHVT.21.08.2020 check no X
        WITH PA_WDZER EQ 'X'    "Without Opening Stock; Without Closing Stock
        WITH PA_WDZEW EQ 'X'    "Without Opening Stock; With Closing Stock
        WITH PA_WDWIZ EQ 'X'    "With Opening Stock; Without Closing Stock
        WITH PA_WDWUW EQ 'X'    "With Opening Stock; With Closing Stock; Changed
        WITH PA_WDWEW EQ 'X'    "With Opening Stock; With Closing Stock; Unchanged
        WITH PA_NDZER EQ ''     "Without Openning Stock; Without Closing Stock
        WITH PA_NDSTO EQ 'X'    "With Openning Stock; With Closing Stock; Unchanged
        WITH P_SUBMIT EQ 'X'
        AND RETURN.
  IMPORT BESTAND TO LT_TOTAL_BATCH FROM MEMORY ID 'ZSAP_PG_RM07MLBD'.
  FREE MEMORY ID 'ZSAP_PG_RM07MLBD'.

  LOOP AT LT_TOTAL_BATCH INTO GS_MB5B.
    CLEAR: GS_MB5B-CHARG.

    COLLECT GS_MB5B INTO GT_MB5B.
    CLEAR GS_MB5B.
  ENDLOOP.
  SORT GT_MB5B BY WERKS LGORT MATNR.

  CLEAR LT_TOTAL_BATCH[].

ENDFORM.                    " CHECK_TK

*&---------------------------------------------------------------------*
*&      Form  GET_PCK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM GET_PCK .

  SELECT
         MSEG~MBLNR
         MSEG~MJAHR
         MSEG~RSNUM
         MSEG~RSPOS
         MSEG~ERFMG
         MSEG~ERFME
         MSEG~SMBLN
         MSEG~SJAHR
   FROM MSEG
   INTO TABLE GT_PCK
   FOR ALL ENTRIES IN GT_PREDATA
 WHERE MSEG~XAUTO NE 'X'
   AND MSEG~RSNUM = GT_PREDATA-RSNUM.

  DATA(LT_PCK) = GT_PCK[].

  DELETE GT_PCK WHERE SMBLN IS NOT INITIAL.
  DELETE LT_PCK WHERE SMBLN IS INITIAL.
  SORT LT_PCK BY SMBLN SJAHR.
  LOOP AT GT_PCK INTO DATA(LS_PCK).
    READ TABLE LT_PCK TRANSPORTING NO FIELDS
      WITH KEY SMBLN = LS_PCK-MBLNR
               SJAHR = LS_PCK-MJAHR
      BINARY SEARCH.
    IF SY-SUBRC IS INITIAL.
      DELETE TABLE GT_PCK FROM LS_PCK.
    ENDIF.
  ENDLOOP.

  SORT GT_PCK BY RSNUM RSPOS.

ENDFORM.                    " GET_PCK

*
* 
