*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_TONTHUOCTINH_TOP
*&---------------------------------------------------------------------*

TABLES:
  mara,
  mchb,
  sscrfields.

DATA:
  gv_atwrt TYPE atwrt.

*---------------------------------------------------------------------*
* SELECTION-SCREEN
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bl_scope WITH FRAME TITLE TEXT-001.

  PARAMETERS:
    p_werks TYPE werks_d OBLIGATORY DEFAULT '1000'.

  SELECT-OPTIONS:
    s_lgort FOR mchb-lgort,
    s_matnr FOR mara-matnr MATCHCODE OBJECT mat1,
    s_mtart FOR mara-mtart,
    s_matkl FOR mara-matkl,
    s_charg FOR mchb-charg.

SELECTION-SCREEN END OF BLOCK bl_scope.

SELECTION-SCREEN BEGIN OF BLOCK bl_class WITH FRAME TITLE TEXT-002.

  PARAMETERS:
    p_class TYPE klah-class,
    p_auto  AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK bl_class.

SELECTION-SCREEN FUNCTION KEY 1.

* Một dòng điều kiện thuộc tính: tick hiển thị, tên thuộc tính, giá trị từ - đến
DEFINE lm_char_row.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS p_h&1 AS CHECKBOX MODIF ID c&1.
    SELECTION-SCREEN COMMENT 3(29) lbl&1 FOR FIELD s_c&1 MODIF ID c&1.
    SELECTION-SCREEN POSITION 33.
    SELECT-OPTIONS s_c&1 FOR gv_atwrt VISIBLE LENGTH 20 MODIF ID c&1.
  SELECTION-SCREEN END OF LINE.
END-OF-DEFINITION.

SELECTION-SCREEN BEGIN OF BLOCK bl_char WITH FRAME TITLE TEXT-003.

  SELECTION-SCREEN COMMENT /1(79) TEXT-007 MODIF ID c01.
  lm_char_row 01.
  lm_char_row 02.
  lm_char_row 03.
  lm_char_row 04.
  lm_char_row 05.
  lm_char_row 06.
  lm_char_row 07.
  lm_char_row 08.
  lm_char_row 09.
  lm_char_row 10.
  lm_char_row 11.
  lm_char_row 12.
  lm_char_row 13.
  lm_char_row 14.
  lm_char_row 15.

SELECTION-SCREEN END OF BLOCK bl_char.

SELECTION-SCREEN BEGIN OF BLOCK bl_stock WITH FRAME TITLE TEXT-004.

  PARAMETERS:
    p_unr  AS CHECKBOX DEFAULT 'X',
    p_qi   AS CHECKBOX DEFAULT 'X',
    p_blk  AS CHECKBOX DEFAULT 'X',
    p_only AS CHECKBOX DEFAULT 'X',
    p_incl AS CHECKBOX.

SELECTION-SCREEN END OF BLOCK bl_stock.

SELECTION-SCREEN BEGIN OF BLOCK bl_unit WITH FRAME TITLE TEXT-005.

  PARAMETERS:
    p_meinh TYPE marm-meinh,
    p_date  TYPE sy-datum DEFAULT sy-datum.

SELECTION-SCREEN END OF BLOCK bl_unit.

SELECTION-SCREEN BEGIN OF BLOCK bl_lay WITH FRAME TITLE TEXT-006.

  PARAMETERS:
    p_layo TYPE slis_vari.

SELECTION-SCREEN END OF BLOCK bl_lay.

CONSTANTS:
  gc_msgid      TYPE symsgid    VALUE 'ZWM11',
  gc_max_char   TYPE i          VALUE 15,
  gc_max_msg    TYPE i          VALUE 50,
  gc_atfor_char TYPE atfor      VALUE 'CHAR',
  gc_atfor_date TYPE atfor      VALUE 'DATE',
  gc_at_lonsx   TYPE atnam      VALUE 'Z_BATCH_NSX',
  gc_klart_def  TYPE klassenart VALUE '022',
  gc_obtab_mcha TYPE tabelle    VALUE 'MCHA',
  gc_obtab_mch1 TYPE tabelle    VALUE 'MCH1',
  gc_obtab_mara TYPE tabelle    VALUE 'MARA',
* Ngưỡng không bao giờ đạt: loại tồn không tick thì không tham gia điều kiện còn tồn
  gc_qty_none   TYPE labst      VALUE '9999999999'.

TYPES:
* Thuộc tính của Batch Class, tương ứng 1 dòng điều kiện trên màn hình chọn
  BEGIN OF gty_char,
    idx      TYPE n LENGTH 2,
    atinn    TYPE atinn,
    atnam    TYPE atnam,
    atfor    TYPE atfor,
    atkle    TYPE cabn-atkle,
    anzdz    TYPE cabn-anzdz,
    pos      TYPE n LENGTH 3,
    seqnr    TYPE i,
    label    TYPE char80,
    show_def TYPE abap_bool,
    show     TYPE abap_bool,
    has_val  TYPE abap_bool,
  END OF gty_char,
  gtt_char TYPE STANDARD TABLE OF gty_char WITH EMPTY KEY,

  BEGIN OF gty_cfg,
    class    TYPE klah-class,
    atnam    TYPE atnam,
    atbez    TYPE ztwm_char_param-atbez,
    show_alv TYPE ztwm_char_param-show_alv,
  END OF gty_cfg,
  gtt_cfg TYPE STANDARD TABLE OF gty_cfg WITH EMPTY KEY,

* Điều kiện đã quy đổi của 1 thuộc tính: CHAR dùng ATWRT, NUM / DATE dùng ATFLV
  BEGIN OF gty_cond,
    atinn  TYPE atinn,
    atnam  TYPE atnam,
    atfor  TYPE atfor,
    r_char TYPE RANGE OF atwrt,
    r_flv  TYPE RANGE OF ausp-atflv,
  END OF gty_cond,

  BEGIN OF gty_set,
    cuobj TYPE inob-cuobj,
  END OF gty_set,

  BEGIN OF gty_set90,
    objek TYPE ausp-objek,
  END OF gty_set90,
  gtt_set90 TYPE STANDARD TABLE OF gty_set90 WITH EMPTY KEY,

  BEGIN OF gty_key,
    objek TYPE inob-objek,
  END OF gty_key,

  BEGIN OF gty_flt,
    matnr TYPE matnr,
    werks TYPE werks_d,
    charg TYPE charg_d,
  END OF gty_flt,

  BEGIN OF gty_mat,
    matnr TYPE matnr,
  END OF gty_mat,
  gtt_mat TYPE STANDARD TABLE OF gty_mat WITH EMPTY KEY,

* Khóa đối tượng phân loại của lô: theo cấp độ lô (MCH1 theo vật tư, MCHA theo Plant)
  BEGIN OF gty_obj_mch1,
    matnr TYPE matnr,
    charg TYPE charg_d,
  END OF gty_obj_mch1,

  BEGIN OF gty_obj_mcha,
    matnr TYPE matnr,
    werks TYPE werks_d,
    charg TYPE charg_d,
  END OF gty_obj_mcha,

  BEGIN OF gty_stock,
    matnr TYPE matnr,
    werks TYPE werks_d,
    lgort TYPE lgort_d,
    charg TYPE charg_d,
    clabs TYPE labst,
    cinsm TYPE insme,
    cspem TYPE speme,
    vfdat TYPE vfdat,
    hsdat TYPE hsdat,
    qndat TYPE qnpdat,
    licha TYPE lichn,
    zustd TYPE dzustd,
    meins TYPE meins,
    begru TYPE begru,
    maktx TYPE maktx,
  END OF gty_stock,

  BEGIN OF gty_inob,
    objek TYPE inob-objek,
    cuobj TYPE inob-cuobj,
  END OF gty_inob,

  BEGIN OF gty_val,
    objek TYPE ausp-objek,
    atnam TYPE atnam,
    atfor TYPE atfor,
    anzdz TYPE cabn-anzdz,
    atwrt TYPE atwrt,
    atflv TYPE ausp-atflv,
  END OF gty_val,

  BEGIN OF gty_valtxt,
    objek TYPE ausp-objek,
    atnam TYPE atnam,
    txt   TYPE atwrt,
  END OF gty_valtxt,

  BEGIN OF gty_ch,
    ch01 TYPE atwrt,
    ch02 TYPE atwrt,
    ch03 TYPE atwrt,
    ch04 TYPE atwrt,
    ch05 TYPE atwrt,
    ch06 TYPE atwrt,
    ch07 TYPE atwrt,
    ch08 TYPE atwrt,
    ch09 TYPE atwrt,
    ch10 TYPE atwrt,
    ch11 TYPE atwrt,
    ch12 TYPE atwrt,
    ch13 TYPE atwrt,
    ch14 TYPE atwrt,
    ch15 TYPE atwrt,
  END OF gty_ch,

  BEGIN OF gty_alv,
    werks   TYPE werks_d,
    lgort   TYPE lgort_d,
    matnr   TYPE matnr,
    maktx   TYPE maktx,
    charg   TYPE charg_d,
    lonsx   TYPE char30,
    meins   TYPE meins,
    clabs   TYPE labst,
    cinsm   TYPE insme,
    cspem   TYPE speme,
    total   TYPE menge_d,
    qtycv   TYPE menge_d,
    meinhcv TYPE meins,
    hsdat   TYPE hsdat,
    vfdat   TYPE vfdat,
    qndat   TYPE qnpdat,
    hsdcl   TYPE i,
    status  TYPE char40,
    INCLUDE TYPE gty_ch.
TYPES:
    colr    TYPE lvc_t_scol,
  END OF gty_alv,

  BEGIN OF gty_coltxt,
    fname TYPE lvc_fname,
    text  TYPE char40,
  END OF gty_coltxt,
  gtt_coltxt TYPE STANDARD TABLE OF gty_coltxt WITH EMPTY KEY.

DATA:
  gt_char      TYPE gtt_char,
  gt_cond      TYPE STANDARD TABLE OF gty_cond WITH EMPTY KEY,
  gt_flt       TYPE HASHED TABLE OF gty_flt WITH UNIQUE KEY matnr werks charg,
  gt_stock     TYPE STANDARD TABLE OF gty_stock WITH EMPTY KEY,
  gt_inob      TYPE HASHED TABLE OF gty_inob WITH UNIQUE KEY objek,
  gt_valtxt    TYPE HASHED TABLE OF gty_valtxt WITH UNIQUE KEY objek atnam,
  gt_noconv    TYPE HASHED TABLE OF matnr WITH UNIQUE KEY table_line,
  gt_alv       TYPE STANDARD TABLE OF gty_alv WITH EMPTY KEY,
  gv_klart     TYPE klassenart,
  gv_obtab     TYPE tabelle,
  gv_class_cur TYPE klah-class,
  gv_andec     TYPE t006-andec,
  gv_meinh_ext TYPE c LENGTH 10,
  gv_msg_init  TYPE abap_bool,
  go_alv       TYPE REF TO cl_salv_table.
