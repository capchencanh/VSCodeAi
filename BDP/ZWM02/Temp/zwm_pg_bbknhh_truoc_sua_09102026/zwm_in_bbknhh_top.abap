*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_BBKNHH_TOP
*&---------------------------------------------------------------------*

TABLES:
  likp,
  lips,
  matdoc.

*---------------------------------------------------------------------*
* Nguồn chứng từ
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK source WITH FRAME TITLE TEXT-001.

  PARAMETERS:
    p_src_a RADIOBUTTON GROUP src
            USER-COMMAND src1
            DEFAULT 'X',
    p_src_b RADIOBUTTON GROUP src.

SELECTION-SCREEN END OF BLOCK source.

*---------------------------------------------------------------------*
* Điều kiện lọc
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK para WITH FRAME TITLE TEXT-002.

  SELECT-OPTIONS:
    s_werks FOR lips-werks,
    s_vbeln FOR likp-vbeln,
    s_lfdat FOR likp-lfdat,
    s_mblnr FOR matdoc-mblnr,
    s_budat FOR matdoc-budat,
    s_lifnr FOR matdoc-lifnr,
    s_kunnr FOR matdoc-kunnr,
    s_lgort FOR matdoc-lgort,
    s_traid FOR likp-traid.

  PARAMETERS:
    p_mjahr TYPE mjahr DEFAULT sy-datum(4) OBLIGATORY.

SELECTION-SCREEN END OF BLOCK para.

*---------------------------------------------------------------------*
* Nhóm hàng
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK mat WITH FRAME TITLE TEXT-003.

  PARAMETERS:
    p_vacsp RADIOBUTTON GROUP r1 USER-COMMAND int1,
    p_thugn RADIOBUTTON GROUP r1,
    p_khac  RADIOBUTTON GROUP r1 DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK mat.

*---------------------------------------------------------------------*
* Type cũ
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF lty_mch1,
    matnr TYPE matnr,
    charg TYPE charg_d,
    atwrt TYPE atwrt,
    qndat TYPE qnpdat,
  END OF lty_mch1,

  BEGIN OF lty_mara,
    matnr   TYPE matnr,
    mfrnr   TYPE mfrnr,
    country TYPE land1,
  END OF lty_mara,

  BEGIN OF lty_lfa1,
    lifnr   TYPE lifnr,
    country TYPE land1,
  END OF lty_lfa1,

  BEGIN OF lty_lfa1_ut2,
    lifnr TYPE lifnr,
    name2 TYPE adrc-name2,
    name3 TYPE adrc-name3,
    name4 TYPE adrc-name4,
  END OF lty_lfa1_ut2,

  BEGIN OF lty_kna1,
    kunnr TYPE kunnr,
    xcpdk TYPE xcpdk,
  END OF lty_kna1.

*---------------------------------------------------------------------*
* ALV - Danh sách chứng từ
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF lty_alv,
    sel          TYPE abap_bool,
    docno        TYPE char20,
    docno2       TYPE char20,
    doc_type     TYPE char20,
    partner      TYPE char20,
    name         TYPE char255,
    lfdat        TYPE dats,
    item_count   TYPE i,
    gr_status    TYPE char30,
    traid        TYPE char50,
    print_count  TYPE i,
    werks        TYPE werks_d,
    source       TYPE char1,
  END OF lty_alv.

DATA:
  gt_alv TYPE STANDARD TABLE OF lty_alv,
  gs_alv TYPE lty_alv.

DATA:
  go_alv TYPE REF TO cl_salv_table.

*---------------------------------------------------------------------*
* Internal table cũ
*---------------------------------------------------------------------*
DATA:
  gt_data    TYPE TABLE OF zwm_st_bbknhh,
  gt_predata TYPE TABLE OF zwm_st_bbknhh,
  gs_data    TYPE zwm_st_bbknhh,
  gs_predata TYPE zwm_st_bbknhh,
  gs_header  TYPE zwm_st_bbknhh.

DATA:
  gt_mch1 TYPE TABLE OF lty_mch1
          WITH NON-UNIQUE KEY matnr atwrt,
  gs_mch1 TYPE lty_mch1.

DATA:
  gt_atnam TYPE TABLE OF zcore_st_rseloption_atnam,
  gs_atnam TYPE zcore_st_rseloption_atnam.

DATA:
  gt_mara TYPE TABLE OF lty_mara,
  gs_mara TYPE lty_mara.

DATA:
  gt_lfa1     TYPE TABLE OF lty_lfa1,
  gt_lfa1_ut2 TYPE TABLE OF lty_lfa1_ut2,
  gs_lfa1     TYPE lty_lfa1,
  gs_lfa1_ut2 TYPE lty_lfa1_ut2.

DATA:
  gt_kna1 TYPE TABLE OF lty_kna1,
  gs_kna1 TYPE lty_kna1.

*---------------------------------------------------------------------*
* Field symbols
*---------------------------------------------------------------------*
FIELD-SYMBOLS:
  <fs_pre_data> TYPE zwm_st_bbknhh.

*---------------------------------------------------------------------*
* Các biến cũ
*---------------------------------------------------------------------*
DATA:
  gs_parameter   TYPE zcore_st_parameter,
  lw_notice      TYPE char50,
  gw_name        TYPE char255,
  lw_mblnr       TYPE mblnr,
  lw_lifnr       TYPE elifn,
  lw_nhasx       TYPE char255,
  lw_nuosx       TYPE char255,
  lw_ghichu      TYPE char255,
  gw_bldat       TYPE char10,
  gw_charg       TYPE charg_d,
  lw_matnr       TYPE matnr,
  lw_soluonghd   TYPE lsmng,
  lw_soluongtt   TYPE erfmg,
  gw_nhacungcap  TYPE char10,
  gw_ngkiemnhan  TYPE char255,
  gw_ngvanchuyen TYPE char255,
  gw_ngayhd      TYPE char255,
  gw_sohd        TYPE char255,
  gw_nggiaohang  TYPE char255,
  gw_soxe        TYPE char255.

*---------------------------------------------------------------------*
* Biến phục vụ ALV / in
*---------------------------------------------------------------------*
DATA:
  gv_selected_count  TYPE i,
  gv_current_source  TYPE char1,
  gv_current_docno   TYPE char20,
  gv_current_docno2  TYPE char20.

*
*
