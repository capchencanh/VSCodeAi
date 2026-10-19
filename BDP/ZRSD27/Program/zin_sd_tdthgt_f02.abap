*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_TDTHGT_F02
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form BUILD_STRUCTURE
*&---------------------------------------------------------------------*
* Tao bang ket qua dong: cot co dinh (GTY_FIX) + cot nam/quy/thang (GT_DCOL)
FORM BUILD_STRUCTURE.

  DATA: LS_FIX  TYPE GTY_FIX,
        LV_QTY  TYPE VBAP-ZMENG,
        LV_VAL  TYPE VBAP-NETWR,
        LO_FIX  TYPE REF TO CL_ABAP_STRUCTDESCR,
        LO_QTY  TYPE REF TO CL_ABAP_DATADESCR,
        LO_VAL  TYPE REF TO CL_ABAP_DATADESCR,
        LO_TAB  TYPE REF TO CL_ABAP_TABLEDESCR,
        LT_COMP TYPE CL_ABAP_STRUCTDESCR=>COMPONENT_TABLE,
        LS_COMP TYPE CL_ABAP_STRUCTDESCR=>COMPONENT.

  LO_FIX ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( LS_FIX ).
  LO_QTY ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( LV_QTY ).
  LO_VAL ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( LV_VAL ).

  LT_COMP = LO_FIX->GET_COMPONENTS( ).

  LOOP AT GT_DCOL ASSIGNING FIELD-SYMBOL(<LFS_C>).
    CLEAR LS_COMP.
    LS_COMP-NAME = <LFS_C>-NAME.
    IF <LFS_C>-KIND = 'Q'.
      LS_COMP-TYPE = LO_QTY.
    ELSE.
      LS_COMP-TYPE = LO_VAL.
    ENDIF.
    APPEND LS_COMP TO LT_COMP.
  ENDLOOP.

  TRY.
      GO_STRUCT = CL_ABAP_STRUCTDESCR=>CREATE( LT_COMP ).
      LO_TAB    = CL_ABAP_TABLEDESCR=>CREATE( GO_STRUCT ).
    CATCH CX_SY_STRUCT_CREATION CX_SY_TABLE_CREATION.
      MESSAGE 'Không tạo được cấu trúc bảng kết quả' TYPE 'E'. "#EC NOTEXT
  ENDTRY.

  CREATE DATA GR_OUT TYPE HANDLE LO_TAB.
  ASSIGN GR_OUT->* TO <GFS_OUT>.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT
*&---------------------------------------------------------------------*
* Man hinh 0100: khung tren hien tieu de bao cao, khung duoi la ALV
FORM CREATE_OBJECT.

  CHECK GC_CONTAINER IS INITIAL.

  CREATE OBJECT GC_CONTAINER
    EXPORTING
      CONTAINER_NAME = GC_SCRFNAME.

  CREATE OBJECT GO_SPLIT
    EXPORTING
      PARENT  = GC_CONTAINER
      ROWS    = 2
      COLUMNS = 1.

  CALL METHOD GO_SPLIT->SET_ROW_HEIGHT
    EXPORTING
      ID     = 1
      HEIGHT = 12.

  CALL METHOD GO_SPLIT->GET_CONTAINER
    EXPORTING
      ROW       = 1
      COLUMN    = 1
    RECEIVING
      CONTAINER = GO_TOP.

  CALL METHOD GO_SPLIT->GET_CONTAINER
    EXPORTING
      ROW       = 2
      COLUMN    = 1
    RECEIVING
      CONTAINER = GO_BOT.

  CREATE OBJECT GREF_ALV
    EXPORTING
      I_PARENT = GO_BOT.

  PERFORM BUILD_TOP_DOC.
  PERFORM DISPLAY_ALV.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_TOP_DOC
*&---------------------------------------------------------------------*
* Tieu de bao cao, ngay chay bao cao, ty le thuc hien chung
FORM BUILD_TOP_DOC.

  DATA LV_TXT TYPE SDYDO_TEXT_ELEMENT.

  CREATE OBJECT GO_DOC.

  LV_TXT = |BẢNG THEO DÕI TÌNH HÌNH THỰC HIỆN CÁC GÓI THẦU CÒN HIỆU LỰC | &&
           |TÍNH ĐẾN NGÀY { GV_DATE_TO+6(2) }/{ GV_DATE_TO+4(2) }/{ GV_DATE_TO(4) }|.
  CALL METHOD GO_DOC->ADD_TEXT
    EXPORTING
      TEXT      = LV_TXT
      SAP_STYLE = CL_DD_AREA=>HEADING.
  CALL METHOD GO_DOC->NEW_LINE.

  LV_TXT = |Ngày chạy báo cáo: { SY-DATUM+6(2) }.{ SY-DATUM+4(2) }.{ SY-DATUM(4) }| &&
           |      Tỷ lệ thực hiện: { GV_RATE NUMBER = USER DECIMALS = 3 } %|.
  CALL METHOD GO_DOC->ADD_TEXT
    EXPORTING
      TEXT = LV_TXT.

  CALL METHOD GO_DOC->DISPLAY_DOCUMENT
    EXPORTING
      PARENT = GO_TOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV.

  DATA LT_FUNCTIONS TYPE UI_FUNCTIONS.

  PERFORM BUILD_FIELDCAT.

  GS_LAYOUT-ZEBRA      = ABAP_TRUE.
  GS_LAYOUT-CWIDTH_OPT = ABAP_TRUE.
  GS_LAYOUT-SEL_MODE   = 'A'.

  GS_VARIANT-REPORT = SY-REPID.

* Bao cao chi doc: an cac nut sua du lieu
  LT_FUNCTIONS = VALUE #(
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_APPEND_ROW )
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_INSERT_ROW )
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_DELETE_ROW )
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_COPY_ROW )
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_COPY )
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_CUT )
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_PASTE )
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_PASTE_NEW_ROW )
    ( CL_GUI_ALV_GRID=>MC_FC_LOC_UNDO )
    ( CL_GUI_ALV_GRID=>MC_FC_GRAPH ) ).

  CALL METHOD GREF_ALV->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      IS_VARIANT                    = GS_VARIANT
      I_SAVE                        = 'A'
      IS_LAYOUT                     = GS_LAYOUT
      IT_TOOLBAR_EXCLUDING          = LT_FUNCTIONS
    CHANGING
      IT_OUTTAB                     = <GFS_OUT>
      IT_FIELDCATALOG               = GT_FLDCAT
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE 'Lỗi hiển thị ALV' TYPE 'E'. "#EC NOTEXT
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_FIELDCAT
*&---------------------------------------------------------------------*
* Thu tu cot: nhom co dinh dau -> cot nam/quy/thang -> luy ke va nhom co dinh cuoi
FORM BUILD_FIELDCAT.

  TYPES: BEGIN OF LTY_COL,
           NAME  TYPE LVC_FNAME,
           TEXT  TYPE SCRTEXT_L,
           ALIGN TYPE CHAR1,
           KIND  TYPE CHAR1,
           CONV  TYPE CONVEXIT,
         END OF LTY_COL,
         LTT_COL TYPE STANDARD TABLE OF LTY_COL WITH EMPTY KEY.

  DATA: LT_COL  TYPE LTT_COL,
        LS_COL  TYPE LTY_COL,
        LS_FCAT TYPE LVC_S_FCAT,
        LV_DATE TYPE C LENGTH 10.

  LV_DATE = |{ GV_DATE_TO+6(2) }/{ GV_DATE_TO+4(2) }/{ GV_DATE_TO(4) }|.

  LT_COL = VALUE #(
    ( NAME = 'COMBO'     TEXT = 'Mã kết hợp'                  ALIGN = 'L' )
    ( NAME = 'VKORG'     TEXT = 'Mã chi nhánh'                ALIGN = 'C' )
    ( NAME = 'VKGRP_TX'  TEXT = 'Khu vực'                     ALIGN = 'L' )
    ( NAME = 'VKORG_TX'  TEXT = 'Chi nhánh'                   ALIGN = 'L' )
    ( NAME = 'TINH'      TEXT = 'Tỉnh'                        ALIGN = 'L' )
    ( NAME = 'KVGR1_TX'  TEXT = 'Tỉnh/ Thành mới sau sáp nhập' ALIGN = 'L' )
    ( NAME = 'KUNNR1'    TEXT = 'Mã đơn vị mời thầu'          ALIGN = 'L' CONV = 'ALPHA' )
    ( NAME = 'NAME1_L1'  TEXT = 'Tên đơn vị mời thầu'         ALIGN = 'L' )
    ( NAME = 'KUNNR'     TEXT = 'Mã khách hàng'               ALIGN = 'L' CONV = 'ALPHA' )
    ( NAME = 'NAME_KH'   TEXT = 'Tên khách hàng'              ALIGN = 'L' )
    ( NAME = 'PLTYP_TX'  TEXT = 'Loại hợp đồng'               ALIGN = 'L' )
    ( NAME = 'LOAI_CT'   TEXT = 'Loại hợp đồng cụ thể'        ALIGN = 'L' )
    ( NAME = 'VBELN_BG'  TEXT = 'Số báo giá'                  ALIGN = 'L' CONV = 'ALPHA' )
    ( NAME = 'VBELN1'    TEXT = 'Số hợp đồng cấp 1'           ALIGN = 'L' CONV = 'ALPHA' )
    ( NAME = 'VBELN'     TEXT = 'Số hợp đồng cấp 2'           ALIGN = 'L' CONV = 'ALPHA' )
    ( NAME = 'GUEBG'     TEXT = 'Bắt đầu có hiệu lực'         ALIGN = 'C' )
    ( NAME = 'GUEEN'     TEXT = 'Hết hiệu lực'                ALIGN = 'C' )
    ( NAME = 'DAYS_LEFT' TEXT = 'Số ngày hết hiệu lực (hiện tại)' ALIGN = 'R' )
    ( NAME = 'GUEEN_MM'  TEXT = 'Tháng hết hiệu lực'          ALIGN = 'C' )
    ( NAME = 'GUEEN_YY'  TEXT = 'Năm hết hiệu lực'            ALIGN = 'C' )
    ( NAME = 'MON_TOTAL' TEXT = 'Số tháng thực hiện gói thầu' ALIGN = 'R' )
    ( NAME = 'MON_DONE'  TEXT = 'Số tháng đã thực hiện'       ALIGN = 'R' )
    ( NAME = 'MON_LEFT'  TEXT = 'Số tháng còn lại'            ALIGN = 'R' )
    ( NAME = 'REP_DATE'  TEXT = 'Thời điểm báo cáo'           ALIGN = 'C' )
    ( NAME = 'MATNR'     TEXT = 'Mã hàng hóa'                 ALIGN = 'L' CONV = 'MATN1' )
    ( NAME = 'ARKTX'     TEXT = 'Tên hàng hóa'                ALIGN = 'L' )
    ( NAME = 'ZIEME'     TEXT = 'ĐVT'                         ALIGN = 'C' CONV = 'CUNIT' )
    ( NAME = 'PRICE'     TEXT = 'Giá trúng thầu (chưa VAT)'   ALIGN = 'R' KIND = 'V' )
    ( NAME = 'QTY_WIN'   TEXT = 'Số lượng trúng thầu'         ALIGN = 'R' KIND = 'Q' )
    ( NAME = 'VAL_WIN'   TEXT = 'Thành tiền trúng thầu'       ALIGN = 'R' KIND = 'V' ) ).

  LOOP AT GT_DCOL ASSIGNING FIELD-SYMBOL(<LFS_D>).
    CLEAR LS_COL.
    LS_COL-NAME  = <LFS_D>-NAME.
    LS_COL-TEXT  = <LFS_D>-TEXT.
    LS_COL-ALIGN = 'R'.
    LS_COL-KIND  = <LFS_D>-KIND.
    APPEND LS_COL TO LT_COL.
  ENDLOOP.

  APPEND LINES OF VALUE ltt_col(
    ( NAME = 'CUM_Q'     TEXT = |Số lượng thực hiện đến { LV_DATE }|
                         ALIGN = 'R' KIND = 'Q' )
    ( NAME = 'CUM_V'     TEXT = |Thành tiền thực hiện đến { LV_DATE }|
                         ALIGN = 'R' KIND = 'V' )
    ( NAME = 'REM_Q'     TEXT = |Số lượng chưa thực hiện đến { LV_DATE }|
                         ALIGN = 'R' KIND = 'Q' )
    ( NAME = 'REM_V'     TEXT = |Thành tiền chưa thực hiện đến { LV_DATE }|
                         ALIGN = 'R' KIND = 'V' )
    ( NAME = 'BSTNK1_BG' TEXT = 'PO number HĐ cấp 1/ BG'      ALIGN = 'L' )
    ( NAME = 'BSTNK'     TEXT = 'PO number HĐ cấp 2'          ALIGN = 'L' )
    ( NAME = 'ERDAT'     TEXT = 'Ngày tạo HĐ cấp 2'           ALIGN = 'C' )
    ( NAME = 'WGBEZ'     TEXT = 'Nhóm'                        ALIGN = 'L' )
    ( NAME = 'SPCL'      TEXT = |SPCL { GV_YEAR }|            ALIGN = 'L' )
    ( NAME = 'PRDHA_TX'  TEXT = 'Nhóm tác dụng dược lý'       ALIGN = 'L' )
    ( NAME = 'NOTE'      TEXT = 'Ghi chú'                     ALIGN = 'L' )
    ( NAME = 'PERNR_TDV' TEXT = 'Mã TDV'                      ALIGN = 'L' )
    ( NAME = 'NAME_TDV'  TEXT = 'Tên TDV'                     ALIGN = 'L' )
    ( NAME = 'PERNR_ASM' TEXT = 'Mã ASM'                      ALIGN = 'L' )
    ( NAME = 'NAME_ASM'  TEXT = 'Tên ASM'                     ALIGN = 'L' ) )
    TO LT_COL.

  CLEAR GT_FLDCAT.

  LOOP AT LT_COL ASSIGNING FIELD-SYMBOL(<LFS_C>).

    CLEAR LS_FCAT.
    LS_FCAT-FIELDNAME = <LFS_C>-NAME.
    LS_FCAT-COL_POS   = SY-TABIX.
    LS_FCAT-SCRTEXT_L = <LFS_C>-TEXT.
    LS_FCAT-SCRTEXT_M = <LFS_C>-TEXT.
    LS_FCAT-SCRTEXT_S = <LFS_C>-TEXT.
    LS_FCAT-REPTEXT   = <LFS_C>-TEXT.
    LS_FCAT-JUST      = <LFS_C>-ALIGN.
    LS_FCAT-CONVEXIT  = <LFS_C>-CONV.

*   Cot thanh tien tham chieu loai tien de hien dung so le
    IF <LFS_C>-KIND = 'V'.
      LS_FCAT-CFIELDNAME = 'WAERS'.
    ENDIF.

    APPEND LS_FCAT TO GT_FLDCAT.

  ENDLOOP.

* Cot ky thuat: khong hien thi nhung van can trong bang ket qua
  LOOP AT VALUE string_table( ( `POSNR` ) ( `VKGRP` ) ( `WAERS` ) )
       ASSIGNING FIELD-SYMBOL(<LFS_T>).
    CLEAR LS_FCAT.
    LS_FCAT-FIELDNAME = <LFS_T>.
    LS_FCAT-TECH      = ABAP_TRUE.
    APPEND LS_FCAT TO GT_FLDCAT.
  ENDLOOP.

ENDFORM.
