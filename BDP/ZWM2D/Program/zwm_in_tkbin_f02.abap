*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_TKBIN_F02
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form SHOW_LIST
*&---------------------------------------------------------------------*
* Danh sach ton kho tai Bin (ALV chuan toan man hinh)
FORM SHOW_LIST.

  DATA: LO_SALV TYPE REF TO CL_SALV_TABLE,
        LV_HEAD TYPE STRING.

* Dong tieu de: Warehouse | Storage Type | Thoi diem chay | User
  LV_HEAD = |Warehouse { P_LGNUM }|.                                      "#EC NOTEXT
  IF LINES( S_LGTYP[] ) = 1 AND S_LGTYP[ 1 ]-SIGN = 'I' AND S_LGTYP[ 1 ]-OPTION = 'EQ'.
    LV_HEAD = |{ LV_HEAD } \| Storage Type { S_LGTYP[ 1 ]-LOW }|.          "#EC NOTEXT
  ENDIF.
  LV_HEAD = |{ LV_HEAD } \| Thời điểm chạy { SY-DATUM DATE = USER } { SY-UZEIT TIME = USER } \| User { SY-UNAME }|. "#EC NOTEXT

  TRY.
      CL_SALV_TABLE=>FACTORY( IMPORTING R_SALV_TABLE = LO_SALV
                              CHANGING  T_TABLE      = GT_LIST ).

      PERFORM FORMAT_ALV USING LO_SALV ABAP_FALSE.

      LO_SALV->GET_FUNCTIONS( )->SET_ALL( ABAP_TRUE ).
      LO_SALV->GET_DISPLAY_SETTINGS( )->SET_STRIPED_PATTERN( ABAP_TRUE ).

      DATA(LO_TOP) = NEW CL_SALV_FORM_LAYOUT_GRID( ).
      LO_TOP->CREATE_TEXT( ROW = 1 COLUMN = 1 TEXT = LV_HEAD ).
      LO_SALV->SET_TOP_OF_LIST( LO_TOP ).

      DATA(LO_LAYOUT) = LO_SALV->GET_LAYOUT( ).
      LO_LAYOUT->SET_KEY( VALUE #( REPORT = SY-REPID ) ).
      LO_LAYOUT->SET_SAVE_RESTRICTION( IF_SALV_C_LAYOUT=>RESTRICT_NONE ).
      IF P_VARI IS NOT INITIAL.
        LO_LAYOUT->SET_INITIAL_LAYOUT( P_VARI ).
      ENDIF.

      LO_SALV->DISPLAY( ).

    CATCH CX_SALV_ERROR INTO DATA(LX_SALV).
      MESSAGE LX_SALV->GET_TEXT( ) TYPE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FORMAT_ALV
*&---------------------------------------------------------------------*
* Cot hien thi cho ca danh sach (IV_MAP = space) va ALV ton o dang chon
FORM FORMAT_ALV USING IO_SALV TYPE REF TO CL_SALV_TABLE
                      IV_MAP  TYPE ABAP_BOOL.

  TYPES: BEGIN OF LTY_COL,
           NAME TYPE LVC_FNAME,
           TEXT TYPE STRING,
           LIST TYPE ABAP_BOOL,
           MAP  TYPE ABAP_BOOL,
           TECH TYPE ABAP_BOOL,
         END OF LTY_COL,
         TT_COL TYPE STANDARD TABLE OF LTY_COL WITH EMPTY KEY.

  DATA: LO_COLS TYPE REF TO CL_SALV_COLUMNS_TABLE,
        LO_COL  TYPE REF TO CL_SALV_COLUMN_TABLE,
        LV_CONV TYPE ABAP_BOOL,
        LV_POS  TYPE I.

  DATA(LT_COL) = VALUE TT_COL(
    ( NAME = 'ICON'     TEXT = 'TT Bin'              LIST = 'X' )
    ( NAME = 'LGTYP'    TEXT = 'Storage Type'        LIST = 'X' )
    ( NAME = 'LGBER'    TEXT = 'Section'             LIST = 'X' )
    ( NAME = 'LGPLA'    TEXT = 'Storage Bin'         LIST = 'X' MAP = 'X' )
    ( NAME = 'AISLE'    TEXT = 'Dãy'                 LIST = 'X' )
    ( NAME = 'STACK'    TEXT = 'Kệ'                  LIST = 'X' )
    ( NAME = 'LEVEL'    TEXT = 'Tầng'                LIST = 'X' )
    ( NAME = 'CELL'     TEXT = 'Ô'                   LIST = 'X' )
    ( NAME = 'SLOT'     TEXT = 'Vị trí'              LIST = 'X' )
    ( NAME = 'LPTYP'    TEXT = 'Loại Bin' )
    ( NAME = 'CAPA'     TEXT = 'Sức chứa còn lại' )
    ( NAME = 'HUID'     TEXT = 'Handling Unit'       LIST = 'X' MAP = 'X' )
    ( NAME = 'HU_TOP'   TEXT = 'HU cấp cao nhất'     TECH = 'X' )
    ( NAME = 'STOCK_ID' TEXT = 'Stock Item'          TECH = 'X' )
    ( NAME = 'MATNR'    TEXT = 'Vật tư'              LIST = 'X' MAP = 'X' )
    ( NAME = 'MAKTX'    TEXT = 'Mô tả vật tư'        LIST = 'X' MAP = 'X' )
    ( NAME = 'WERKS'    TEXT = 'Plant'               LIST = 'X' MAP = 'X' )
    ( NAME = 'LGORT'    TEXT = 'SLoc'                LIST = 'X' MAP = 'X' )
    ( NAME = 'ENTITLED' TEXT = 'Party entitled' )
    ( NAME = 'CAT'      TEXT = 'Stock Type'          LIST = 'X' MAP = 'X' )
    ( NAME = 'CAT_TXT'  TEXT = 'Mô tả Stock Type'    LIST = 'X' MAP = 'X' )
    ( NAME = 'STK_USG'  TEXT = 'Tồn đặc biệt'        LIST = 'X' MAP = 'X' )
    ( NAME = 'STK_NO'   TEXT = 'Số tồn đặc biệt'     LIST = 'X' MAP = 'X' )
    ( NAME = 'OWNER'    TEXT = 'Chủ sở hữu tồn' )
    ( NAME = 'CHARG'    TEXT = 'Số lô SAP'           LIST = 'X' MAP = 'X' )
    ( NAME = 'NSX_LOT'  TEXT = 'Số lô NSX'           LIST = 'X' MAP = 'X' )
    ( NAME = 'NSX'      TEXT = 'Nhà sản xuất'        LIST = 'X' )
    ( NAME = 'VFDAT'    TEXT = 'Hạn dùng'            LIST = 'X' MAP = 'X' )
    ( NAME = 'QNDAT'    TEXT = 'Ngày KNL'            LIST = 'X' MAP = 'X' )
    ( NAME = 'WDATE'    TEXT = 'Ngày nhập'           LIST = 'X' MAP = 'X' )
    ( NAME = 'WDATU_TS' TEXT = 'Thời điểm nhập' )
    ( NAME = 'AGE'      TEXT = 'Ngày tồn'            LIST = 'X' )
    ( NAME = 'QUAN'     TEXT = 'Tổng tồn'            LIST = 'X' MAP = 'X' )
    ( NAME = 'AVAIL'    TEXT = 'Khả dụng'            LIST = 'X' MAP = 'X' )
    ( NAME = 'WAIT_IN'  TEXT = 'Chờ putaway'         LIST = 'X' MAP = 'X' )
    ( NAME = 'PICK_QTY' TEXT = 'SL đang pick'        LIST = 'X' MAP = 'X' )
    ( NAME = 'MEINS'    TEXT = 'ĐVT'                 LIST = 'X' MAP = 'X' )
    ( NAME = 'QUAN_CV'  TEXT = 'SL quy đổi'          LIST = 'X' MAP = 'X' )
    ( NAME = 'MEINS_CV' TEXT = 'ĐVT quy đổi'         LIST = 'X' MAP = 'X' )
    ( NAME = 'SKZUE'    TEXT = 'Khóa nhập'           LIST = 'X' )
    ( NAME = 'SKZUA'    TEXT = 'Khóa xuất'           LIST = 'X' )
    ( NAME = 'SKZSI'    TEXT = 'Khóa kiểm kê'        LIST = 'X' )
    ( NAME = 'LOCK_TXT' TEXT = 'Diễn giải khóa'      LIST = 'X' )
    ( NAME = 'CHG_USER' TEXT = 'Người đổi Bin' )
    ( NAME = 'CHG_DATE' TEXT = 'Ngày đổi Bin' )
    ( NAME = 'CHG_TIME' TEXT = 'Giờ đổi Bin' )
    ( NAME = 'IDATE'    TEXT = 'Kiểm kê gần nhất'    LIST = 'X' )
    ( NAME = 'MV_DATE'  TEXT = 'Di chuyển gần nhất'  LIST = 'X' )
    ( NAME = 'MV_TIME'  TEXT = 'Giờ di chuyển'       LIST = 'X' )
    ( NAME = 'BTANR'    TEXT = 'Số WT gần nhất'      LIST = 'X' ) ).                "#EC NOTEXT

  LO_COLS = IO_SALV->GET_COLUMNS( ).
  LO_COLS->SET_OPTIMIZE( ABAP_TRUE ).

  LV_CONV = COND #( WHEN GV_UNIT_CV IS NOT INITIAL THEN ABAP_TRUE ).

  LOOP AT LT_COL ASSIGNING FIELD-SYMBOL(<LFS_COL>).
    TRY.
        LO_COL ?= LO_COLS->GET_COLUMN( <LFS_COL>-NAME ).
        LO_COL->SET_SHORT_TEXT( CONV #( <LFS_COL>-TEXT ) ).
        LO_COL->SET_MEDIUM_TEXT( CONV #( <LFS_COL>-TEXT ) ).
        LO_COL->SET_LONG_TEXT( CONV #( <LFS_COL>-TEXT ) ).
        IF <LFS_COL>-NAME = 'ICON'.
          LO_COL->SET_ICON( ABAP_TRUE ).
        ENDIF.
        IF <LFS_COL>-TECH = ABAP_TRUE.
          LO_COL->SET_TECHNICAL( ABAP_TRUE ).
        ENDIF.
        IF IV_MAP = ABAP_TRUE.
          LO_COL->SET_VISIBLE( <LFS_COL>-MAP ).
        ELSE.
          LO_COL->SET_VISIBLE( <LFS_COL>-LIST ).
        ENDIF.
*       2 cot quy doi chi hien khi dang quy doi
        IF ( <LFS_COL>-NAME = 'QUAN_CV' OR <LFS_COL>-NAME = 'MEINS_CV' ) AND LV_CONV = ABAP_FALSE.
          LO_COL->SET_VISIBLE( ABAP_FALSE ).
        ENDIF.
      CATCH CX_SALV_NOT_FOUND.
        CONTINUE.
    ENDTRY.
  ENDLOOP.

* ALV ton o dang chon: thu tu cot theo danh sach cot cua man hinh so do
  IF IV_MAP = ABAP_TRUE.
    DATA(LT_ORD) = VALUE STRING_TABLE( ( `MATNR` ) ( `LGPLA` ) ( `MAKTX` ) ( `WERKS` ) ( `LGORT` ) ( `CHARG` )
      ( `NSX_LOT` ) ( `VFDAT` ) ( `QNDAT` ) ( `QUAN` ) ( `AVAIL` ) ( `WAIT_IN` ) ( `PICK_QTY` )
      ( `MEINS` ) ( `QUAN_CV` ) ( `MEINS_CV` ) ( `CAT` ) ( `CAT_TXT` ) ( `STK_USG` )
      ( `STK_NO` ) ( `HUID` ) ( `WDATE` ) ).
    LOOP AT LT_ORD ASSIGNING FIELD-SYMBOL(<LFS_ORD>).
      LV_POS = SY-TABIX.
      LO_COLS->SET_COLUMN_POSITION( COLUMNNAME = CONV #( <LFS_ORD> ) POSITION = LV_POS ).
    ENDLOOP.
  ENDIF.

* Cot so luong gan DVT: dong tong chi cong khi cung DVT
  TRY.
      CAST CL_SALV_COLUMN_TABLE( LO_COLS->GET_COLUMN( 'QUAN' ) )->SET_QUANTITY_COLUMN( 'MEINS' ).
      CAST CL_SALV_COLUMN_TABLE( LO_COLS->GET_COLUMN( 'AVAIL' ) )->SET_QUANTITY_COLUMN( 'MEINS' ).
      CAST CL_SALV_COLUMN_TABLE( LO_COLS->GET_COLUMN( 'WAIT_IN' ) )->SET_QUANTITY_COLUMN( 'MEINS' ).
      CAST CL_SALV_COLUMN_TABLE( LO_COLS->GET_COLUMN( 'PICK_QTY' ) )->SET_QUANTITY_COLUMN( 'MEINS' ).
      CAST CL_SALV_COLUMN_TABLE( LO_COLS->GET_COLUMN( 'QUAN_CV' ) )->SET_QUANTITY_COLUMN( 'MEINS_CV' ).
      IO_SALV->GET_AGGREGATIONS( )->ADD_AGGREGATION( COLUMNNAME = 'QUAN' ).
    CATCH CX_SALV_NOT_FOUND CX_SALV_DATA_ERROR CX_SALV_EXISTING.
      " khong gan duoc DVT/tong: bo qua, van hien thi binh thuong
      RETURN.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_SEARCH_TEXTS
*&---------------------------------------------------------------------*
FORM SET_SEARCH_TEXTS.

  GV_INFO = |Warehouse: { P_LGNUM }      Storage Type: { GV_LGTYP_MAP }|. "#EC NOTEXT

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CREATE_CONTROLS
*&---------------------------------------------------------------------*
* Man hinh chia vung: so do (trai 60%), thong ke (phai tren), ton o chon (phai duoi)
FORM CREATE_CONTROLS.

  CREATE OBJECT GO_CONT EXPORTING CONTAINER_NAME = GC_CONT_NAME.

  CREATE OBJECT GO_SPLIT_H EXPORTING PARENT = GO_CONT ROWS = 1 COLUMNS = 2.
  GO_SPLIT_H->SET_COLUMN_WIDTH( ID = 1 WIDTH = 60 ).
  GO_CELL_MAP = GO_SPLIT_H->GET_CONTAINER( ROW = 1 COLUMN = 1 ).
  GO_CELL_RGT = GO_SPLIT_H->GET_CONTAINER( ROW = 1 COLUMN = 2 ).

  CREATE OBJECT GO_SPLIT_V EXPORTING PARENT = GO_CELL_RGT ROWS = 2 COLUMNS = 1.
  GO_SPLIT_V->SET_ROW_HEIGHT( ID = 1 HEIGHT = 30 ).
  GO_CELL_STAT = GO_SPLIT_V->GET_CONTAINER( ROW = 1 COLUMN = 1 ).
  GO_CELL_QUAN = GO_SPLIT_V->GET_CONTAINER( ROW = 2 COLUMN = 1 ).

* So do 2D: HTML viewer, bat su kien nhap o
  CREATE OBJECT GO_HTML EXPORTING PARENT = GO_CELL_MAP.
  DATA LT_EVT TYPE CNTL_SIMPLE_EVENTS.
  APPEND VALUE #( EVENTID    = CL_GUI_HTML_VIEWER=>M_ID_SAPEVENT
                  APPL_EVENT = ABAP_TRUE ) TO LT_EVT.
  GO_HTML->SET_REGISTERED_EVENTS( EVENTS = LT_EVT ).
  SET HANDLER LCL_EVT=>ON_SAPEVENT FOR GO_HTML.

  TRY.
*     Chu thich va thong ke: cot noi dung to mau theo trang thai
      CL_SALV_TABLE=>FACTORY( EXPORTING R_CONTAINER  = GO_CELL_STAT
                              IMPORTING R_SALV_TABLE = GO_SALV_STAT
                              CHANGING  T_TABLE      = GT_STAT ).
      GO_SALV_STAT->GET_FUNCTIONS( )->SET_ALL( ABAP_FALSE ).
      DATA(LO_COLS) = GO_SALV_STAT->GET_COLUMNS( ).
      LO_COLS->SET_OPTIMIZE( ABAP_TRUE ).
      LO_COLS->SET_COLOR_COLUMN( 'COLTAB' ).
      LO_COLS->GET_COLUMN( 'TEXT' )->SET_LONG_TEXT( 'Chú thích' ).   "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'TEXT' )->SET_MEDIUM_TEXT( 'Chú thích' ). "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'TEXT' )->SET_SHORT_TEXT( 'Chú thích' ).  "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'VAL' )->SET_LONG_TEXT( 'Tổng vị trí' ).  "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'VAL' )->SET_MEDIUM_TEXT( 'Tổng vị trí' ). "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'VAL' )->SET_SHORT_TEXT( 'Vị trí' ).      "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'VAL' )->SET_ALIGNMENT( IF_SALV_C_ALIGNMENT=>RIGHT ).
      LO_COLS->GET_COLUMN( 'PCT' )->SET_LONG_TEXT( 'Tỉ lệ % vị trí' ). "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'PCT' )->SET_MEDIUM_TEXT( 'Tỉ lệ %' ).    "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'PCT' )->SET_SHORT_TEXT( 'Tỉ lệ %' ).     "#EC NOTEXT
      LO_COLS->GET_COLUMN( 'PCT' )->SET_ALIGNMENT( IF_SALV_C_ALIGNMENT=>RIGHT ).
      GO_SALV_STAT->DISPLAY( ).

*     Ton cua o dang chon
      CL_SALV_TABLE=>FACTORY( EXPORTING R_CONTAINER  = GO_CELL_QUAN
                              IMPORTING R_SALV_TABLE = GO_SALV_QUAN
                              CHANGING  T_TABLE      = GT_VIEW ).
      PERFORM FORMAT_ALV USING GO_SALV_QUAN ABAP_TRUE.
      GO_SALV_QUAN->GET_FUNCTIONS( )->SET_ALL( ABAP_TRUE ).
      DATA(LO_LAYOUT) = GO_SALV_QUAN->GET_LAYOUT( ).
      LO_LAYOUT->SET_KEY( VALUE #( REPORT = SY-REPID HANDLE = 'QUAN' ) ).
      LO_LAYOUT->SET_SAVE_RESTRICTION( IF_SALV_C_LAYOUT=>RESTRICT_NONE ).
      GO_SALV_QUAN->DISPLAY( ).

    CATCH CX_SALV_ERROR INTO DATA(LX_SALV).
      MESSAGE LX_SALV->GET_TEXT( ) TYPE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form FREE_CONTROLS
*&---------------------------------------------------------------------*
FORM FREE_CONTROLS.

  IF GO_HTML IS BOUND.
    GO_HTML->FREE( EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  IF GO_CONT IS BOUND.
    GO_CONT->FREE( EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  CLEAR: GO_HTML, GO_SALV_STAT, GO_SALV_QUAN, GO_CELL_MAP, GO_CELL_RGT,
         GO_CELL_STAT, GO_CELL_QUAN, GO_SPLIT_H, GO_SPLIT_V, GO_CONT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form REFRESH_CONTROLS
*&---------------------------------------------------------------------*
* Chi dung lai phan nao du lieu da doi
FORM REFRESH_CONTROLS.

  IF GV_DIRTY_MAP = ABAP_TRUE.
    PERFORM SHOW_HTML.
    CLEAR GV_DIRTY_MAP.
  ENDIF.

  IF GV_DIRTY_VIEW = ABAP_TRUE.
    PERFORM BUILD_VIEW.
    GO_SALV_QUAN->REFRESH( ).
    CLEAR GV_DIRTY_VIEW.
  ENDIF.

  IF GV_DIRTY_STAT = ABAP_TRUE.
    PERFORM BUILD_STAT.
    GO_SALV_STAT->REFRESH( ).
    CLEAR GV_DIRTY_STAT.
  ENDIF.

  CLEAR GV_CLICKED.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_VIEW
*&---------------------------------------------------------------------*
* Ton cua Bin dang chon (vung 4)
FORM BUILD_VIEW.

  DATA LV_TXT TYPE STRING.

  CLEAR GT_VIEW.
  GV_UNIT_VIEW = P_SMEINS.
  PERFORM SET_VIEW_LAYOUT.
  CHECK GV_SEL_LGPLA IS NOT INITIAL.

  LOOP AT GT_STK ASSIGNING FIELD-SYMBOL(<LFS_O>) USING KEY K_BIN
       WHERE LGPLA = GV_SEL_LGPLA AND MATNR IS NOT INITIAL.
    APPEND <LFS_O> TO GT_VIEW.
  ENDLOOP.

* Hang dang ve Bin nay (WT chua xac nhan) chua co trong ton
  PERFORM ADD_PENDING_ROWS USING GV_SEL_LGPLA CHANGING GT_VIEW.
  PERFORM ADD_PLANT_SLOC CHANGING GT_VIEW.

  IF GT_VIEW IS INITIAL.
    READ TABLE GT_CELL ASSIGNING FIELD-SYMBOL(<LFS_C>) WITH TABLE KEY LGPLA = GV_SEL_LGPLA.
    IF SY-SUBRC = 0.
      PERFORM LOCK_TEXT USING <LFS_C> CHANGING LV_TXT.
    ENDIF.
    MESSAGE S008 WITH GV_SEL_LGPLA LV_TXT DISPLAY LIKE 'I'.
  ELSE.
    GV_UNIT_CV = P_SMEINS.
    PERFORM ENRICH_EXTRA CHANGING GT_VIEW.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_VIEW_LAYOUT
*&---------------------------------------------------------------------*
* Tieu de ALV ton cua o chon va hien/an 2 cot quy doi theo DVT dang nhap
FORM SET_VIEW_LAYOUT.

  DATA: LV_CONV TYPE ABAP_BOOL,
        LV_HEAD TYPE STRING.

  LV_CONV = COND #( WHEN P_SMEINS IS NOT INITIAL THEN ABAP_TRUE ).
  LV_HEAD = COND #( WHEN GV_SEL_LGPLA IS INITIAL
                    THEN `Tồn kho tại ô đang chọn`
                    ELSE |Tồn kho tại ô đang chọn: { GV_SEL_LGPLA }| ).  "#EC NOTEXT

  GO_SALV_QUAN->GET_DISPLAY_SETTINGS( )->SET_LIST_HEADER( CONV #( LV_HEAD ) ).

  TRY.
      DATA(LO_COLS) = GO_SALV_QUAN->GET_COLUMNS( ).
      LO_COLS->GET_COLUMN( 'QUAN_CV' )->SET_VISIBLE( LV_CONV ).
      LO_COLS->GET_COLUMN( 'MEINS_CV' )->SET_VISIBLE( LV_CONV ).
    CATCH CX_SALV_NOT_FOUND.
      RETURN.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOCK_PHRASE
*&---------------------------------------------------------------------*
* Dien giai khoa tu cac co khoa cua Bin
FORM LOCK_PHRASE USING    IV_UE  TYPE CLIKE
                          IV_UA  TYPE CLIKE
                          IV_SI  TYPE CLIKE
                          IV_PI  TYPE CLIKE
                 CHANGING CV_TXT TYPE STRING.

  DATA LT_PART TYPE STRING_TABLE.

  IF IV_UE = ABAP_TRUE AND IV_UA = ABAP_TRUE.
    APPEND 'Khóa nhập + xuất' TO LT_PART.                       "#EC NOTEXT
  ELSEIF IV_UE = ABAP_TRUE.
    APPEND 'Khóa nhập' TO LT_PART.                              "#EC NOTEXT
  ELSEIF IV_UA = ABAP_TRUE.
    APPEND 'Khóa xuất' TO LT_PART.                              "#EC NOTEXT
  ENDIF.

  IF IV_SI = ABAP_TRUE.
    IF IV_PI IS INITIAL.
      APPEND 'Khóa do kiểm kê' TO LT_PART.                      "#EC NOTEXT
    ELSE.
      APPEND |Khóa do kiểm kê (chứng từ { IV_PI ALPHA = OUT })| TO LT_PART. "#EC NOTEXT
    ENDIF.
  ENDIF.

  CV_TXT = CONCAT_LINES_OF( TABLE = LT_PART SEP = `; ` ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form LOCK_TEXT
*&---------------------------------------------------------------------*
FORM LOCK_TEXT USING    IS_CELL TYPE GTY_CELL
               CHANGING CV_TEXT TYPE STRING.

  PERFORM LOCK_PHRASE USING IS_CELL-SKZUE IS_CELL-SKZUA IS_CELL-SKZSI SPACE
                      CHANGING CV_TEXT.

  IF CV_TEXT IS INITIAL.
    CV_TEXT = 'không khóa'.                                     "#EC NOTEXT
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CELL_STATUS
*&---------------------------------------------------------------------*
* Trang thai Bin, uu tien: khoa nhap/xuat (L) > khoa kiem ke (K) > co hang (F) > trong (E)
FORM CELL_STATUS USING    IS_CELL TYPE GTY_CELL
                 CHANGING CV_ST   TYPE C.

  IF IS_CELL-SKZUE = ABAP_TRUE OR IS_CELL-SKZUA = ABAP_TRUE.
    CV_ST = 'L'.
  ELSEIF IS_CELL-SKZSI = ABAP_TRUE.
    CV_ST = 'K'.
  ELSEIF IS_CELL-HAS_STOCK = ABAP_TRUE.
    CV_ST = 'F'.
  ELSE.
    CV_ST = 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_STAT
*&---------------------------------------------------------------------*
* Chu thich va thong ke (vung 3): 9 dong, kem so vi tri va ti le %
FORM BUILD_STAT.

  DATA: LV_TOT   TYPE I,
        LV_FULL  TYPE I,
        LV_EMPTY TYPE I,
        LV_LOCK  TYPE I,
        LV_PI    TYPE I,
        LV_FOUND TYPE I,
        LV_SEL   TYPE I,
        LV_ST    TYPE C LENGTH 1,
        LV_UOM   TYPE CHAR10,
        LV_QTY   TYPE STRING,
        LV_DEC   TYPE I.

  CLEAR GT_STAT.

  LV_TOT = LINES( GT_CELL ).
  LOOP AT GT_CELL ASSIGNING FIELD-SYMBOL(<LFS_C>).
    PERFORM CELL_STATUS USING <LFS_C> CHANGING LV_ST.
    CASE LV_ST.
      WHEN 'L'.
        LV_LOCK = LV_LOCK + 1.
      WHEN 'K'.
        LV_PI = LV_PI + 1.
      WHEN 'F'.
        LV_FULL = LV_FULL + 1.
      WHEN OTHERS.
        LV_EMPTY = LV_EMPTY + 1.
    ENDCASE.
    IF <LFS_C>-FOUND = ABAP_TRUE.
      LV_FOUND = LV_FOUND + 1.
    ENDIF.
  ENDLOOP.
  IF GV_SEL_LGPLA IS NOT INITIAL.
    LV_SEL = 1.
  ENDIF.

* Mau o cot noi dung: 5 = xanh la, 2 = xam nhat, 6 = do, 3 = vang; ket qua tim = dam, o chon = dao mau
  PERFORM ADD_STAT USING 'Tổng vị trí của Storage Type'                    LV_TOT   LV_TOT ABAP_TRUE  0 0 0. "#EC NOTEXT
  PERFORM ADD_STAT USING 'Có hàng, không khóa'                             LV_FULL  LV_TOT ABAP_TRUE  5 0 0. "#EC NOTEXT
  PERFORM ADD_STAT USING 'Trống, sử dụng được'                             LV_EMPTY LV_TOT ABAP_TRUE  2 0 0. "#EC NOTEXT
  PERFORM ADD_STAT USING 'Khóa nhập và/hoặc khóa xuất'                     LV_LOCK  LV_TOT ABAP_TRUE  6 0 0. "#EC NOTEXT
  PERFORM ADD_STAT USING 'Khóa kiểm kê'                                    LV_PI    LV_TOT ABAP_TRUE  3 0 0. "#EC NOTEXT
  PERFORM ADD_STAT USING 'Không có Bin (đường đi, cột, cửa)'               GV_NOBIN LV_TOT ABAP_FALSE 0 0 0. "#EC NOTEXT
  PERFORM ADD_STAT USING 'Kết quả tìm (giữ màu trạng thái, thêm viền)'     LV_FOUND LV_TOT ABAP_TRUE  5 1 0. "#EC NOTEXT
  PERFORM ADD_STAT USING 'Ô đang chọn (giữ màu trạng thái, thêm viền)'     LV_SEL   LV_TOT ABAP_FALSE 5 0 1. "#EC NOTEXT

  APPEND VALUE #( TEXT = 'Tổng tồn kho (ĐVT cơ sở)' ) TO GT_STAT.            "#EC NOTEXT
  IF GV_FOUND_ONE = ABAP_TRUE.
    WRITE GV_FOUND_UOM TO LV_UOM.
    LV_DEC = COND #( WHEN frac( GV_FOUND_QTY ) = 0 THEN 0 ELSE 3 ).
    LV_QTY = |{ GV_FOUND_QTY NUMBER = USER DECIMALS = LV_DEC } { LV_UOM }|.
    GT_STAT[ LINES( GT_STAT ) ]-VAL = LV_QTY.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ADD_STAT
*&---------------------------------------------------------------------*
* Mot dong chu thich: IV_PCT = X thi tinh ti le theo IV_TOT;
* IV_COL / IV_INT / IV_INV = mau (0 = khong to), do dam, dao mau cua cot noi dung
FORM ADD_STAT USING IV_TEXT TYPE CLIKE
                    IV_N    TYPE I
                    IV_TOT  TYPE I
                    IV_PCT  TYPE ABAP_BOOL
                    IV_COL  TYPE I
                    IV_INT  TYPE I
                    IV_INV  TYPE I.

  DATA: LV_PCT  TYPE P LENGTH 8 DECIMALS 2,
        LS_STAT TYPE GTY_STAT.

  LS_STAT-TEXT = IV_TEXT.
  LS_STAT-VAL  = |{ IV_N NUMBER = USER }|.

  IF IV_PCT = ABAP_TRUE AND IV_TOT > 0.
    LV_PCT = CONV DECFLOAT34( IV_N ) * 100 / CONV DECFLOAT34( IV_TOT ).
    LS_STAT-PCT = |{ LV_PCT NUMBER = USER DECIMALS = 2 }|.
  ENDIF.

  IF IV_COL > 0.
    LS_STAT-COLTAB = VALUE #( ( FNAME = 'TEXT' COLOR-COL = IV_COL COLOR-INT = IV_INT COLOR-INV = IV_INV ) ).
  ENDIF.

  APPEND LS_STAT TO GT_STAT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SHOW_UNPLACED
*&---------------------------------------------------------------------*
* Bin co ma khong dung cau truc: khong len so do, liet ke trong popup
FORM SHOW_UNPLACED.

  DATA: LT_BAD  TYPE STANDARD TABLE OF GTY_KEY WITH EMPTY KEY,
        LO_SALV TYPE REF TO CL_SALV_TABLE,
        LV_N    TYPE I.

  LOOP AT GT_CELL ASSIGNING FIELD-SYMBOL(<LFS_C>).
    CHECK <LFS_C>-PLACED = ABAP_FALSE.
    APPEND VALUE #( LGPLA = <LFS_C>-LGPLA ) TO LT_BAD.
  ENDLOOP.
  CHECK LT_BAD IS NOT INITIAL.

  LV_N = LINES( LT_BAD ).
  MESSAGE S004 WITH LV_N GV_LGTYP_MAP DISPLAY LIKE 'W'.

  TRY.
      CL_SALV_TABLE=>FACTORY( IMPORTING R_SALV_TABLE = LO_SALV
                              CHANGING  T_TABLE      = LT_BAD ).
      LO_SALV->SET_SCREEN_POPUP( START_COLUMN = 20 END_COLUMN = 70
                                 START_LINE   = 5  END_LINE   = 25 ).
      LO_SALV->GET_DISPLAY_SETTINGS( )->SET_LIST_HEADER( 'Bin chưa xác định vị trí' ). "#EC NOTEXT
      LO_SALV->DISPLAY( ).
    CATCH CX_SALV_ERROR.
      RETURN.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SHOW_HTML
*&---------------------------------------------------------------------*
* Dung HTML so do roi nap vao HTML viewer (ma hoa UTF-8)
FORM SHOW_HTML.

  DATA: LT_H   TYPE STRING_TABLE,
        LV_URL(250) TYPE C.

  PERFORM BUILD_HTML CHANGING LT_H.

  TRY.
      DATA(LV_X)   = CL_BCS_CONVERT=>STRING_TO_XSTRING( IV_STRING   = CONCAT_LINES_OF( TABLE = LT_H )
                                                        IV_CODEPAGE = '4110' ).
      DATA(LT_BIN) = CL_BCS_CONVERT=>XSTRING_TO_SOLIX( IV_XSTRING = LV_X ).
    CATCH CX_BCS.
      RETURN.
  ENDTRY.

  GO_HTML->LOAD_DATA( EXPORTING  TYPE         = 'text'
                                 SUBTYPE      = 'html'
                                 SIZE         = XSTRLEN( LV_X )
                      IMPORTING  ASSIGNED_URL = LV_URL
                      CHANGING   DATA_TABLE   = LT_BIN
                      EXCEPTIONS OTHERS       = 1 ).
  IF SY-SUBRC = 0.
    GO_HTML->SHOW_URL( URL = LV_URL ).
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_HTML
*&---------------------------------------------------------------------*
* Moi khoi (Day + Ke) la 1 bang: hang = Tang (tang cao xep tren), cot = Vi tri,
* tieu de O lay theo O thuc te cua cac Bin (cot khong co Bin thi khong co tieu de).
* Mau nen theo trang thai Bin: khoa nhap/xuat > khoa kiem ke > co hang > trong;
* ket qua tim va o dang chon chi them vien, khong doi mau nen.
FORM BUILD_HTML CHANGING CT_H TYPE STRING_TABLE.

  TYPES: BEGIN OF LTY_BLK,
           BLOCK TYPE C LENGTH 16,
         END OF LTY_BLK,
         BEGIN OF LTY_LVL,
           LEVEL TYPE I,
         END OF LTY_LVL,
         BEGIN OF LTY_COL,
           SLOT TYPE I,
           CELL TYPE I,
         END OF LTY_COL.

  DATA: LT_BLK   TYPE SORTED TABLE OF LTY_BLK WITH UNIQUE KEY BLOCK,
        LT_LVL   TYPE SORTED TABLE OF LTY_LVL WITH UNIQUE KEY LEVEL,
        LT_COL   TYPE SORTED TABLE OF LTY_COL WITH UNIQUE KEY SLOT,
        LT_ORDER TYPE STANDARD TABLE OF LTY_LVL WITH EMPTY KEY,
        LV_SMIN  TYPE I,
        LV_SMAX  TYPE I,
        LV_S     TYPE I,
        LV_K     TYPE I,
        LV_NEXT  TYPE I,
        LV_CELL  TYPE I,
        LV_ST    TYPE C LENGTH 1,
        LV_CLS   TYPE STRING,
        LV_LOCK  TYPE STRING,
        LV_TIP   TYPE STRING,
        LV_ID    TYPE STRING,
        LV_NUM   TYPE STRING,
        LV_ANY   TYPE ABAP_BOOL,
        LV_DESC  TYPE ABAP_BOOL.

  FIELD-SYMBOLS: <LFS_COL> TYPE LTY_COL,
                 <LFS_NXT> TYPE LTY_COL.

  CLEAR: CT_H, GV_NOBIN.

* Chi so dong trong GT_CELL de bat su kien nhap o
  LOOP AT GT_CELL ASSIGNING FIELD-SYMBOL(<LFS_C>).
    <LFS_C>-IDX = SY-TABIX.
    IF <LFS_C>-PLACED = ABAP_TRUE.
      INSERT VALUE #( BLOCK = <LFS_C>-BLOCK ) INTO TABLE LT_BLK.
    ENDIF.
  ENDLOOP.

  READ TABLE GT_LAY ASSIGNING FIELD-SYMBOL(<LFS_L>)
       WITH TABLE KEY LGNUM = P_LGNUM LGTYP = GV_LGTYP_MAP.

  APPEND `<!DOCTYPE html><html><head><meta charset="utf-8">` TO CT_H.
  APPEND `<meta http-equiv="X-UA-Compatible" content="IE=edge"><style>` TO CT_H.
  APPEND `body{font-family:Arial,sans-serif;font-size:11px;margin:6px;background:#fff}` TO CT_H.
  APPEND `table{border-collapse:separate;border-spacing:1px;margin-bottom:10px}` TO CT_H.
  APPEND `td{box-sizing:border-box;width:16px;height:16px;padding:0;border:2px solid transparent}` TO CT_H.
  APPEND `td.h{height:12px;font-size:9px;text-align:center;color:#444;background:#eef;border:0}` TO CT_H.
  APPEND `td.lv{width:auto;padding:0 4px;font-size:9px;color:#444;border:0}` TO CT_H.
  APPEND `a{display:block;width:12px;height:12px;text-decoration:none}` TO CT_H.
  APPEND `.f{background:#a9d18e}.e{background:#e7e6e6}.l{background:#e06666}.k{background:#ffd966}` TO CT_H.
  APPEND `.s{border-color:#1f5fbf}.c{border-color:#000}` TO CT_H.
  APPEND `.blk{font-weight:bold;margin:8px 0 2px 0}` TO CT_H.
  APPEND `.note{font-size:10px;color:#444;margin-bottom:4px}` TO CT_H.
  APPEND `</style><script>` TO CT_H.
  APPEND `function pk(td){var o=document.getElementById('sel');` TO CT_H.
  APPEND `if(o){o.className=o.className.replace(' c','');o.removeAttribute('id');}` TO CT_H.
  APPEND `td.className=td.className+' c';td.id='sel';}` TO CT_H.
  APPEND `</script></head><body>` TO CT_H.

  APPEND `<div class="note">Màu nền = trạng thái Bin (giống đèn trạng thái của danh sách). ` &&
         `Viền xanh đậm = kết quả tìm · Viền đen = ô đang chọn</div>` TO CT_H.

  IF LT_BLK IS INITIAL.
    APPEND `<p>Không có Bin nào xác định được vị trí trên sơ đồ.</p>` TO CT_H.
  ENDIF.

  LOOP AT LT_BLK ASSIGNING FIELD-SYMBOL(<LFS_BLK>).

*   Khung luoi cua khoi: Vi tri nho nhat - lon nhat, cac Tang co Bin va O cua tung Vi tri
    CLEAR: LT_LVL, LT_COL, LV_SMIN, LV_SMAX, LV_ANY.
    LOOP AT GT_CELL ASSIGNING <LFS_C> USING KEY K_POS
         WHERE BLOCK = <LFS_BLK>-BLOCK AND PLACED = ABAP_TRUE.
      IF LV_ANY = ABAP_FALSE OR <LFS_C>-SLOT < LV_SMIN.
        LV_SMIN = <LFS_C>-SLOT.
      ENDIF.
      IF LV_ANY = ABAP_FALSE OR <LFS_C>-SLOT > LV_SMAX.
        LV_SMAX = <LFS_C>-SLOT.
      ENDIF.
      LV_ANY = ABAP_TRUE.
      INSERT VALUE #( LEVEL = <LFS_C>-LEVEL ) INTO TABLE LT_LVL.
      INSERT VALUE #( SLOT = <LFS_C>-SLOT CELL = <LFS_C>-CELL ) INTO TABLE LT_COL.
    ENDLOOP.

    APPEND |<div class="blk">{ <LFS_BLK>-BLOCK }</div><table>| TO CT_H.

*   Hang tieu de O: gom cac Vi tri lien tiep cung 1 O; cot khong co Bin de trong
    APPEND `<tr><td class="lv"></td>` TO CT_H.
    LV_S = LV_SMIN.
    WHILE LV_S <= LV_SMAX.
      READ TABLE LT_COL ASSIGNING <LFS_COL> WITH TABLE KEY SLOT = LV_S.
      IF SY-SUBRC <> 0.
        APPEND `<td class="h"></td>` TO CT_H.
        LV_S = LV_S + 1.
        CONTINUE.
      ENDIF.
      LV_CELL = <LFS_COL>-CELL.
      LV_K    = 1.
      DO.
        LV_NEXT = LV_S + LV_K.
        READ TABLE LT_COL ASSIGNING <LFS_NXT> WITH TABLE KEY SLOT = LV_NEXT.
        IF SY-SUBRC <> 0 OR <LFS_NXT>-CELL <> LV_CELL.
          EXIT.
        ENDIF.
        LV_K = LV_K + 1.
      ENDDO.
      APPEND |<td class="h" colspan="{ LV_K }">Ô{ LV_CELL WIDTH = 2 ALIGN = RIGHT PAD = '0' }</td>| TO CT_H. "#EC NOTEXT
      LV_S = LV_S + LV_K.
    ENDWHILE.
    APPEND `</tr>` TO CT_H.

*   Hang nhan Vi tri (cot khong co Bin de trong)
    APPEND `<tr><td class="lv"></td>` TO CT_H.
    LV_S = LV_SMIN.
    WHILE LV_S <= LV_SMAX.
      IF NOT LINE_EXISTS( LT_COL[ SLOT = LV_S ] ).
        APPEND `<td class="h"></td>` TO CT_H.
        LV_S = LV_S + 1.
        CONTINUE.
      ENDIF.
      LV_NUM = |{ LV_S }|.
      IF LV_S < 10.
        LV_NUM = |0{ LV_S }|.
      ENDIF.
      APPEND |<td class="h">{ LV_NUM }</td>| TO CT_H.
      LV_S = LV_S + 1.
    ENDWHILE.
    APPEND `</tr>` TO CT_H.

*   Cac Tang: tang cao xep tren (hoac thap xep tren neu LEVEL_DESC trong)
    LV_DESC = ABAP_TRUE.
    IF <LFS_L> IS ASSIGNED AND <LFS_L>-LEVEL_DESC IS INITIAL.
      LV_DESC = ABAP_FALSE.
    ENDIF.
    LT_ORDER = LT_LVL.
    IF LV_DESC = ABAP_TRUE.
      SORT LT_ORDER BY LEVEL DESCENDING.
    ENDIF.

    LOOP AT LT_ORDER ASSIGNING FIELD-SYMBOL(<LFS_LV>).
      APPEND |<tr><td class="lv">Tầng { <LFS_LV>-LEVEL }</td>| TO CT_H. "#EC NOTEXT
      DO LV_SMAX - LV_SMIN + 1 TIMES.
        LV_S = LV_SMIN + SY-INDEX - 1.
        READ TABLE GT_CELL ASSIGNING <LFS_C> WITH KEY K_POS COMPONENTS
             BLOCK = <LFS_BLK>-BLOCK LEVEL = <LFS_LV>-LEVEL SLOT = LV_S.
        IF SY-SUBRC <> 0.
          APPEND `<td title="Không có Bin"></td>` TO CT_H.         "#EC NOTEXT
          GV_NOBIN = GV_NOBIN + 1.
          CONTINUE.
        ENDIF.

        PERFORM CELL_STATUS USING <LFS_C> CHANGING LV_ST.
        LV_CLS = SWITCH #( LV_ST WHEN 'L' THEN `l` WHEN 'K' THEN `k` WHEN 'F' THEN `f` ELSE `e` ).
        IF <LFS_C>-FOUND = ABAP_TRUE.
          LV_CLS = LV_CLS && ` s`.
        ENDIF.
        CLEAR LV_ID.
        IF <LFS_C>-LGPLA = GV_SEL_LGPLA.
          LV_CLS = LV_CLS && ` c`.
          LV_ID  = ` id="sel"`.
        ENDIF.

        PERFORM LOCK_TEXT USING <LFS_C> CHANGING LV_LOCK.
        LV_TIP = |{ <LFS_C>-LGPLA } - { COND string( WHEN <LFS_C>-HAS_STOCK = ABAP_TRUE THEN 'Có hàng' ELSE 'Trống' ) }| &&
                 |, { LV_LOCK } - { <LFS_C>-LINES } dòng tồn|.                                  "#EC NOTEXT
        LV_TIP = escape( val = LV_TIP format = cl_abap_format=>e_html_attr ).

        APPEND |<td class="{ LV_CLS }"{ LV_ID }><a href="SAPEVENT:CELL?{ <LFS_C>-IDX }" | &&
               |onclick="pk(this.parentNode)" title="{ LV_TIP }"></a></td>| TO CT_H.
      ENDDO.
      APPEND `</tr>` TO CT_H.
    ENDLOOP.

    APPEND `</table>` TO CT_H.
  ENDLOOP.

  APPEND `</body></html>` TO CT_H.

ENDFORM.
