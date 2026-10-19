*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_THCPVC_F02
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT.

  CHECK GC_CONTAINER IS INITIAL.

  CREATE OBJECT GC_CONTAINER
    EXPORTING
      CONTAINER_NAME = GC_SCRFNAME.

  CREATE OBJECT GREF_ALV
    EXPORTING
      I_PARENT = GC_CONTAINER.

  PERFORM DISPLAY_ALV.

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
  GS_LAYOUT-GRID_TITLE = 'Báo Cáo Tổng Hợp Chi Phí Vận Chuyển'. "#EC NOTEXT

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
      IT_OUTTAB                     = GT_ALV
      IT_FIELDCATALOG               = GT_FLDCAT
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE 'Loi hien thi ALV' TYPE 'E'.                    "#EC NOTEXT
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_FIELDCAT
*&---------------------------------------------------------------------*
FORM BUILD_FIELDCAT.

  TYPES: BEGIN OF LTY_COL,
           NAME  TYPE LVC_FNAME,
           TEXT  TYPE LVC_S_FCAT-REPTEXT,
           ALIGN TYPE CHAR1,
           TOTAL TYPE ABAP_BOOL,
         END OF LTY_COL.

  DATA: LT_COL  TYPE STANDARD TABLE OF LTY_COL WITH EMPTY KEY,
        LS_FCAT TYPE LVC_S_FCAT.

  LT_COL = VALUE #(
    ( NAME = 'VKGRP'    TEXT = 'Mã Khu Vực' ALIGN = 'C' )
    ( NAME = 'VKGRP_TX' TEXT = 'Tên Khu Vực' ALIGN = 'L' )
    ( NAME = 'VKBUR'    TEXT = 'Mã Chi Nhánh' ALIGN = 'C' )
    ( NAME = 'VKBUR_TX' TEXT = 'Tên Chi Nhánh' ALIGN = 'L' )
    ( NAME = 'KVGR2'    TEXT = 'Mã Vùng Vận Chuyển' ALIGN = 'C' )
    ( NAME = 'KVGR2_TX' TEXT = 'Tên Vùng Vận Chuyển' ALIGN = 'L' )
    ( NAME = 'MFRGR'    TEXT = 'Mã Loại Hàng Hóa Vận Chuyển' ALIGN = 'C' )
    ( NAME = 'MFRGR_TX' TEXT = 'Tên Loại Hàng Hóa Vận Chuyển' ALIGN = 'L' )
    ( NAME = 'VTWEG'    TEXT = 'Mã Kênh Bán Hàng' ALIGN = 'C' )
    ( NAME = 'VTWEG_TX' TEXT = 'Tên Kênh Bán Hàng' ALIGN = 'L' )
    ( NAME = 'DATE_FR'  TEXT = 'Từ Ngày' ALIGN = 'C' )
    ( NAME = 'DATE_TO'  TEXT = 'Đến Ngày' ALIGN = 'C' )
    ( NAME = 'NETWR'    TEXT = 'Doanh Số Thực Hiện' ALIGN = 'R' TOTAL = ABAP_TRUE )
    ( NAME = 'FREIGHT1' TEXT = 'Chi Phí Vận Chuyển Theo Tỷ Lệ Chuẩn' ALIGN = 'R' TOTAL = ABAP_TRUE )
    ( NAME = 'RATE1'    TEXT = 'Tỷ Lệ Chi Phí Vận Chuyển Theo Tỷ Lệ Chuẩn' ALIGN = 'L' )
    ( NAME = 'FREIGHT2' TEXT = 'Chi Phí Vận Chuyển Bổ Sung' ALIGN = 'R' TOTAL = ABAP_TRUE )
    ( NAME = 'RATE2'    TEXT = 'Tỷ Lệ Chi Phí Vận Chuyển Theo Chi Phí Bổ Sung' ALIGN = 'L' )
    ( NAME = 'KZWI4'    TEXT = 'Thành Tiền Chi Phí Được Duyệt' ALIGN = 'R' TOTAL = ABAP_TRUE )
    ( NAME = 'WAERK'    TEXT = 'Loại Tiền' ALIGN = 'C' ) ). "#EC NOTEXT

  CLEAR GT_FLDCAT.

  LOOP AT LT_COL ASSIGNING FIELD-SYMBOL(<LFS_C>).

    CLEAR LS_FCAT.
    LS_FCAT-FIELDNAME = <LFS_C>-NAME.
    LS_FCAT-COL_POS   = SY-TABIX.
    LS_FCAT-REPTEXT   = <LFS_C>-TEXT.

    IF STRLEN( <LFS_C>-TEXT ) <= 40.
      LS_FCAT-SCRTEXT_L = <LFS_C>-TEXT.
      LS_FCAT-SCRTEXT_M = <LFS_C>-TEXT.
      LS_FCAT-SCRTEXT_S = <LFS_C>-TEXT.
    ENDIF.
    LS_FCAT-JUST      = <LFS_C>-ALIGN.
    LS_FCAT-DO_SUM    = <LFS_C>-TOTAL.

    IF <LFS_C>-NAME = 'NETWR' OR <LFS_C>-NAME = 'FREIGHT1'
    OR <LFS_C>-NAME = 'FREIGHT2' OR <LFS_C>-NAME = 'KZWI4'.
      LS_FCAT-CFIELDNAME = 'WAERK'.
    ENDIF.

    APPEND LS_FCAT TO GT_FLDCAT.
  ENDLOOP.

ENDFORM.