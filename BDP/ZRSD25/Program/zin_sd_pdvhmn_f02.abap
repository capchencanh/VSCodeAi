*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_PDVHMN_F02
*&---------------------------------------------------------------------*

CLASS LCL_HANDLER DEFINITION.
  PUBLIC SECTION.
    METHODS ON_LINK_CLICK FOR EVENT LINK_CLICK OF CL_SALV_EVENTS_TABLE
      IMPORTING ROW COLUMN.
ENDCLASS.

CLASS LCL_HANDLER IMPLEMENTATION.
  METHOD ON_LINK_CLICK.

    READ TABLE GT_ALV INTO DATA(LS_ROW) INDEX ROW.
    CHECK SY-SUBRC = 0.

    CASE COLUMN.
      WHEN 'VBELN'.
        CHECK LS_ROW-VBELN IS NOT INITIAL.
        SET PARAMETER ID 'AUN' FIELD LS_ROW-VBELN.
        CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.   "#EC CI_CALLTA

      WHEN 'VBELN_VF'.
        CHECK LS_ROW-VBELN_VF IS NOT INITIAL.
* Nhieu hoa don -> mo so dau tien
        SPLIT LS_ROW-VBELN_VF AT ',' INTO DATA(LV_FIRST) DATA(LV_REST).
        DATA(LV_BILL) = CONV VBRK-VBELN( CONDENSE( LV_FIRST ) ).
        SET PARAMETER ID 'VF' FIELD LV_BILL.
        CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.   "#EC CI_CALLTA

      WHEN 'CHANGENR'.
        CHECK LS_ROW-VBELN IS NOT INITIAL.
        PERFORM SHOW_CHANGELOG USING LS_ROW-VBELN.
    ENDCASE.

  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*& Form SHOW_CHANGELOG
*&---------------------------------------------------------------------*
FORM SHOW_CHANGELOG USING IV_VBELN TYPE VBAK-VBELN.

  DATA LV_OBJID TYPE CDHDR-OBJECTID.

  LV_OBJID = IV_VBELN.

  SUBMIT RSSCD100
    WITH OBJEKT   = GC_OBJCLAS
    WITH OBJEKTID = LV_OBJID
    WITH CALLSUB  = ABAP_TRUE
    AND RETURN.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV.

  DATA: LO_ALV     TYPE REF TO CL_SALV_TABLE,
        LO_HANDLER TYPE REF TO LCL_HANDLER.

  TRY.
      CL_SALV_TABLE=>FACTORY(
        IMPORTING R_SALV_TABLE = LO_ALV
        CHANGING  T_TABLE      = GT_ALV ).
    CATCH CX_SALV_MSG.
      MESSAGE 'Khong khoi tao duoc ALV' TYPE 'E'.           "#EC NOTEXT
  ENDTRY.

  LO_ALV->GET_FUNCTIONS( )->SET_ALL( ABAP_TRUE ).
  LO_ALV->GET_LAYOUT( )->SET_KEY( VALUE #( REPORT = SY-REPID ) ).
  LO_ALV->GET_LAYOUT( )->SET_SAVE_RESTRICTION( IF_SALV_C_LAYOUT=>RESTRICT_NONE ).
  LO_ALV->GET_DISPLAY_SETTINGS( )->SET_STRIPED_PATTERN( ABAP_TRUE ).
  LO_ALV->GET_DISPLAY_SETTINGS( )->SET_LIST_HEADER( TEXT-H01 ).
  LO_ALV->GET_COLUMNS( )->SET_OPTIMIZE( ABAP_TRUE ).

  PERFORM SET_COLUMNS USING LO_ALV.

  CREATE OBJECT LO_HANDLER.
  SET HANDLER LO_HANDLER->ON_LINK_CLICK FOR LO_ALV->GET_EVENT( ).

  LO_ALV->DISPLAY( ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_COLUMNS
*&---------------------------------------------------------------------*
FORM SET_COLUMNS USING IO_ALV TYPE REF TO CL_SALV_TABLE.

  TYPES: BEGIN OF LTY_COL,
           NAME  TYPE LVC_FNAME,
           TEXT  TYPE SCRTEXT_L,
           ALIGN TYPE CHAR1,
           HOT   TYPE ABAP_BOOL,
         END OF LTY_COL.

  DATA: LO_COLS TYPE REF TO CL_SALV_COLUMNS_TABLE,
        LO_COL  TYPE REF TO CL_SALV_COLUMN_TABLE,
        LT_COL  TYPE STANDARD TABLE OF LTY_COL WITH EMPTY KEY,
        LT_CUR  TYPE STANDARD TABLE OF LVC_FNAME WITH EMPTY KEY.

  LT_CUR = VALUE #( ( 'NETWR' ) ( 'CRLIMIT' ) ( 'CREXPOS' )
                    ( 'OVERDUE' ) ( 'AMTBL' ) ).

  LT_COL = VALUE #(
    ( NAME = 'STT'      TEXT = 'STT' ALIGN = 'C' )
    ( NAME = 'VKBUR'    TEXT = 'Mã CN' ALIGN = 'L' )
    ( NAME = 'VKBUR_TX' TEXT = 'Chi Nhánh' ALIGN = 'L' )
    ( NAME = 'KUNNR'    TEXT = 'Mã KH' ALIGN = 'L' )
    ( NAME = 'KUNNR_TX' TEXT = 'Tên KH' ALIGN = 'L' )
    ( NAME = 'KDGRP'    TEXT = 'Mã Nhóm KH' ALIGN = 'C' )
    ( NAME = 'KDGRP_TX' TEXT = 'Nhóm KH' ALIGN = 'L' )
    ( NAME = 'VBELN'    TEXT = 'Đơn Hàng' ALIGN = 'L' HOT = ABAP_TRUE )
    ( NAME = 'VBELN_VF' TEXT = 'Hóa Đơn' ALIGN = 'L' HOT = ABAP_TRUE )
    ( NAME = 'CHANGENR' TEXT = 'Số Chứng Từ' ALIGN = 'L' HOT = ABAP_TRUE )
    ( NAME = 'AUDAT'    TEXT = 'Ngày Tháng' ALIGN = 'C' )
    ( NAME = 'NETWR'    TEXT = 'Số Tiền' ALIGN = 'R' )
    ( NAME = 'PERNR'    TEXT = 'Mã TDV' ALIGN = 'L' )
    ( NAME = 'PERNR_TX' TEXT = 'Tên TDV' ALIGN = 'L' )
    ( NAME = 'REASON'   TEXT = 'Lý Do Chặn' ALIGN = 'L' )
    ( NAME = 'CRLIMIT'  TEXT = 'Hạn Mức Nợ' ALIGN = 'R' )
    ( NAME = 'CREXPOS'  TEXT = 'Số Dư Công Nợ' ALIGN = 'R' )
    ( NAME = 'OVERDUE'  TEXT = 'Nợ Quá Hạn' ALIGN = 'R' )
    ( NAME = 'STATUS'   TEXT = 'Trạng Thái Phê Duyệt' ALIGN = 'L' )
    ( NAME = 'APPROVER' TEXT = 'Người Phê Duyệt' ALIGN = 'L' )
    ( NAME = 'APPDATE'  TEXT = 'Ngày Phê Duyệt' ALIGN = 'C' )
    ( NAME = 'AMTBL'    TEXT = 'Giá Trị Được Duyệt' ALIGN = 'R' ) ). "#EC NOTEXT

  LO_COLS = IO_ALV->GET_COLUMNS( ).
  TRY.
      LOOP AT LT_COL ASSIGNING FIELD-SYMBOL(<LFS_C>).
        LO_COL ?= LO_COLS->GET_COLUMN( <LFS_C>-NAME ).
        LO_COL->SET_LONG_TEXT( <LFS_C>-TEXT ).
        LO_COL->SET_MEDIUM_TEXT( CONV #( <LFS_C>-TEXT ) ).
        LO_COL->SET_SHORT_TEXT( CONV #( <LFS_C>-TEXT ) ).

        CASE <LFS_C>-ALIGN.
          WHEN 'C'. LO_COL->SET_ALIGNMENT( IF_SALV_C_ALIGNMENT=>CENTERED ).
          WHEN 'R'. LO_COL->SET_ALIGNMENT( IF_SALV_C_ALIGNMENT=>RIGHT ).
          WHEN OTHERS. LO_COL->SET_ALIGNMENT( IF_SALV_C_ALIGNMENT=>LEFT ).
        ENDCASE.

        IF <LFS_C>-HOT = ABAP_TRUE.
          LO_COL->SET_CELL_TYPE( IF_SALV_C_CELL_TYPE=>HOTSPOT ).
        ENDIF.
      ENDLOOP.

* Cot tien te tham chieu WAERK; an cot WAERK khoi luoi
      LOOP AT LT_CUR INTO DATA(LV_CUR).
        LO_COL ?= LO_COLS->GET_COLUMN( LV_CUR ).
        LO_COL->SET_CURRENCY_COLUMN( 'WAERK' ).
      ENDLOOP.

      LO_COL ?= LO_COLS->GET_COLUMN( 'WAERK' ).
      LO_COL->SET_TECHNICAL( ABAP_TRUE ).

    CATCH CX_SALV_NOT_FOUND CX_SALV_DATA_ERROR.
      MESSAGE 'Loi cau hinh cot ALV' TYPE 'S' DISPLAY LIKE 'W'. "#EC NOTEXT
  ENDTRY.

ENDFORM.