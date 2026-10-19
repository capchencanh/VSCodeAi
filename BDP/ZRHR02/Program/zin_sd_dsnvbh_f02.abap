*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_DSNVBH_F02
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV
*& Option 2 - FS muc 2.3: ALV khong co tieu de va phan ky duyet,
*& xuat Excel bang chuc nang chuan cua ALV
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV.

  DATA LO_ALV TYPE REF TO CL_SALV_TABLE.

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

  LO_ALV->DISPLAY( ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_COLUMNS
*& 14 chi tieu theo FS muc 2.4
*&---------------------------------------------------------------------*
FORM SET_COLUMNS USING IO_ALV TYPE REF TO CL_SALV_TABLE.

  TYPES: BEGIN OF LTY_COL,
           NAME  TYPE LVC_FNAME,
           TEXT  TYPE SCRTEXT_L,
           ALIGN TYPE CHAR1,
         END OF LTY_COL.

  DATA: LO_COLS TYPE REF TO CL_SALV_COLUMNS_TABLE,
        LO_COL  TYPE REF TO CL_SALV_COLUMN_TABLE,
        LT_COL  TYPE STANDARD TABLE OF LTY_COL WITH EMPTY KEY.

  LT_COL = VALUE #(
    ( NAME = 'STT'      TEXT = 'STT' ALIGN = 'C' )
    ( NAME = 'PERNR'    TEXT = 'Mã Nhân Viên' ALIGN = 'L' )
    ( NAME = 'PARVW'    TEXT = 'Partner Function' ALIGN = 'L' )
    ( NAME = 'PARVW_TX' TEXT = 'Tên Partner Function' ALIGN = 'L' )
    ( NAME = 'ENAME'    TEXT = 'Tên Nhân Viên' ALIGN = 'L' )
    ( NAME = 'ORGEH_TX' TEXT = 'Tên Phòng Ban/ Chi Nhánh (HRM)' ALIGN = 'L' )
    ( NAME = 'ORGEH'    TEXT = 'Mã Phòng Ban/ Mã Chi Nhánh (HRM)' ALIGN = 'L' )
    ( NAME = 'VKBUR_TX' TEXT = 'Tên Phòng Ban/ Chi Nhánh (SAP)' ALIGN = 'L' )
    ( NAME = 'VKBUR'    TEXT = 'Mã Phòng Ban/ Mã Chi Nhánh (SAP)' ALIGN = 'L' )
    ( NAME = 'PLANS_TX' TEXT = 'Vị Trí Công Việc' ALIGN = 'L' )
    ( NAME = 'PLANS'    TEXT = 'Mã VTCV' ALIGN = 'L' )
    ( NAME = 'PERIOD'   TEXT = 'Tháng Áp Dụng' ALIGN = 'C' )
    ( NAME = 'SPGRP_TX' TEXT = 'Nhóm Sản Phẩm' ALIGN = 'L' )
    ( NAME = 'SPGRP'    TEXT = 'Mã Nhóm Sản Phẩm' ALIGN = 'C' )
    ( NAME = 'NETWR'    TEXT = 'Doanh Số' ALIGN = 'R' ) ). "#EC NOTEXT

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
      ENDLOOP.

      LO_COL ?= LO_COLS->GET_COLUMN( 'NETWR' ).
      LO_COL->SET_CURRENCY_COLUMN( 'WAERK' ).

      LO_COL ?= LO_COLS->GET_COLUMN( 'WAERK' ).
      LO_COL->SET_TECHNICAL( ABAP_TRUE ).

    CATCH CX_SALV_NOT_FOUND CX_SALV_DATA_ERROR.
      MESSAGE 'Loi cau hinh cot ALV' TYPE 'S' DISPLAY LIKE 'W'. "#EC NOTEXT
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PRINT_FORM
*& Option 1 - FS muc 2.3: Ban in ky duyet A4 ngang, dang Excel
*& chinh sua duoc, co Header/Footer va phan ky duyet
*&---------------------------------------------------------------------*
FORM PRINT_FORM.

  DATA LR_CONTEXT TYPE REF TO DATA.

  CLEAR GS_FORM.

  PERFORM FILL_FORM_HEADER.

  GS_FORM-ITEM = GT_ALV.

  GET REFERENCE OF GS_FORM INTO LR_CONTEXT.

* FM chi co dung 1 exception PROCESS_TERMINATED
  CALL FUNCTION 'ZXLWB_CALLFORM'
    EXPORTING
      IV_FORMNAME        = GC_FORMNAME
      IV_CONTEXT_REF     = LR_CONTEXT
      IV_VIEWER_TITLE    = TEXT-H01
      IV_VIEWER_INPLACE  = ABAP_TRUE
    EXCEPTIONS
      PROCESS_TERMINATED = 1.

  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FILL_FORM_HEADER
*& Tieu de ban in - FS muc 2.3 Hinh 1
*&---------------------------------------------------------------------*
FORM FILL_FORM_HEADER.

  DATA: LV_MONTH TYPE C LENGTH 2,
        LV_YEAR  TYPE C LENGTH 4.

  GS_FORM-COMPANY = 'CÔNG TY CP DƯỢC - TTBYT BÌNH ĐỊNH'. "#EC NOTEXT
  GS_FORM-TITLE   = 'DOANH SỐ NHÂN VIÊN BÁN HÀNG'.       "#EC NOTEXT

  LV_MONTH = S_FKDAT-LOW+4(2).
  LV_YEAR  = S_FKDAT-LOW(4).

  GS_FORM-PERIOD = |Tháng { LV_MONTH } năm { LV_YEAR }|. "#EC NOTEXT

*&---------------------------------------------------------------------*
*& TODO - Cho BA cung cap:
*& - Ten chi nhanh (GS_FORM-BRANCH): lay theo to chuc ban hang
*&   nao, hay lay dia chi Plant? FS Hinh 1 chi ghi "Chi nhanh Bidiphar..."
*& - So quyet dinh (GS_FORM-DECIDE): FS Hinh 1 ghi
*&   "(Theo QD... /QD-DBD - Quy che luong, thuong khoi ban hang chi nhanh)"
*&   nhung khong cho so quyet dinh cu the.
*&---------------------------------------------------------------------*

ENDFORM.
