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
    p_src_a RADIOBUTTON GROUP src DEFAULT 'X' USER-COMMAND src1,
    p_src_b RADIOBUTTON GROUP src.

SELECTION-SCREEN END OF BLOCK source.

*---------------------------------------------------------------------*
* Điều kiện lọc
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK para WITH FRAME TITLE TEXT-002.

  SELECT-OPTIONS:
    s_werks FOR lips-werks MEMORY ID wrk OBLIGATORY,
    s_vbeln FOR likp-vbeln,
    s_lfdat FOR likp-lfdat,
    s_mblnr FOR matdoc-mblnr.

  PARAMETERS:
    p_mjahr TYPE mjahr DEFAULT sy-datum(4).

  SELECT-OPTIONS:
    s_budat FOR matdoc-budat,
    s_lifnr FOR matdoc-lifnr,
    s_kunnr FOR matdoc-kunnr,
    s_lgort FOR matdoc-lgort,
    s_traid FOR likp-traid.

SELECTION-SCREEN END OF BLOCK para.

*---------------------------------------------------------------------*
* Nhóm hàng
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK mat WITH FRAME TITLE TEXT-003.

  PARAMETERS:
    p_vacsp RADIOBUTTON GROUP r1,
    p_thugn RADIOBUTTON GROUP r1,
    p_khac  RADIOBUTTON GROUP r1 DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK mat.

*---------------------------------------------------------------------*
* Hằng số
*---------------------------------------------------------------------*
CONSTANTS:
  gc_tcode    TYPE tcode    VALUE 'ZWM02',
  gc_formname TYPE tdsfname VALUE 'ZWM_SF_BBKNHH',
  gc_logo     TYPE char50   VALUE 'ZLOGO_0001',
  gc_src_a    TYPE char1    VALUE 'A',
  gc_src_b    TYPE char1    VALUE 'B',
* Danh mục loại Delivery áp dụng (STVARV, loại S)
  gc_tvarv_lfart TYPE rvari_vnam VALUE 'ZWM02_LFART',
* Nhóm nghiệp vụ Movement Type lấy ở nguồn B (ZTWM_MVT_GRP-GRP_CODE)
  gc_grp_mh      TYPE zde_wm_grp_code VALUE 'MH',
  gc_grp_th      TYPE zde_wm_grp_code VALUE 'TH',
* Text ID của Delivery: header (VBBK) và item (VBBP)
  gc_txt_sohd    TYPE tdid VALUE 'ZLF1',
  gc_txt_ngayhd  TYPE tdid VALUE 'ZLF2',
  gc_txt_kiemnh  TYPE tdid VALUE 'ZLF3',
  gc_txt_giaohg  TYPE tdid VALUE 'ZLF5',
  gc_txt_soxe    TYPE tdid VALUE 'ZLF6',
  gc_txt_hoso    TYPE tdid VALUE space,
  gc_txt_niemph  TYPE tdid VALUE space,
* Đặc tính lô / vật tư
  gc_at_nsx      TYPE atnam VALUE 'Z_NSX',
  gc_at_lonsx    TYPE atnam VALUE 'Z_BATCH_NSX',
  gc_at_nuoc     TYPE atnam VALUE 'LOBM_HERKL',
  gc_at_gpnk     TYPE atnam VALUE 'Z_GIAYPHEP_NK',
  gc_at_baoquan  TYPE atnam VALUE 'Z_DIEUKIENBAOQUAN',
  gc_at_quycach  TYPE atnam VALUE 'Z_QUY_CACH_BATCH'.

*---------------------------------------------------------------------*
* Dòng chứng từ nguồn (A: LIKP/LIPS, B: MATDOC)
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_item,
    src       TYPE char1,
    docno     TYPE char10,
    mjahr     TYPE mjahr,
    posnr     TYPE posnr_vl,
    zeile     TYPE mblpo,
    doc_type  TYPE char4,
    bwart     TYPE bwart,
    sobkz     TYPE sobkz,
    aufnr     TYPE aufnr,
    ebeln     TYPE ebeln,
    ebelp     TYPE ebelp,
    werks     TYPE werks_d,
    lgort     TYPE lgort_d,
    matnr     TYPE matnr,
    ematn     TYPE ematn,
    charg     TYPE charg_d,
    qty_inv   TYPE lsmng,
    qty_act   TYPE erfmg,
    unit      TYPE erfme,
    lifnr     TYPE elifn,
    kunnr     TYPE kunnr,
    lfdat     TYPE lfdat_v,
    wadat_ist TYPE wadat_ist,
    budat     TYPE budat,
    bldat     TYPE bldat,
    xblnr     TYPE xblnr1,
    frbnr     TYPE frbnr1,
    xabln     TYPE xabln,
    bktxt     TYPE bktxt,
    sgtxt     TYPE sgtxt,
    traid     TYPE traid,
    bolnr     TYPE bolnr,
    lifex     TYPE lifex,
    wbstk     TYPE wbstk,
    vbeln_im  TYPE vbeln_vl,
    vbelp_im  TYPE posnr_vl,
  END OF gty_item,
  gtt_item TYPE STANDARD TABLE OF gty_item WITH EMPTY KEY,

*---------------------------------------------------------------------*
* Màn hình trung gian - mỗi dòng 1 chứng từ
*---------------------------------------------------------------------*
  BEGIN OF gty_alv,
    sel         TYPE abap_bool,
    docno       TYPE char10,
    mjahr       TYPE mjahr,
    doc_type    TYPE char4,
    partner     TYPE char10,
    name        TYPE char80,
    lfdat       TYPE lfdat_v,
    item_count  TYPE i,
    gr_status   TYPE char20,
    traid       TYPE char40,
    print_count TYPE i,
    werks       TYPE werks_d,
    source      TYPE char1,
    obj_key     TYPE zewm_de_obj_key,
  END OF gty_alv,
  gtt_alv TYPE STANDARD TABLE OF gty_alv WITH EMPTY KEY,

  BEGIN OF gty_batch,
    matnr     TYPE matnr,
    werks     TYPE werks_d,
    charg     TYPE charg_d,
    hsdat     TYPE hsdat,
    vfdat     TYPE vfdat,
    qndat     TYPE qnpdat,
    licha     TYPE lichn,
    z_nsx     TYPE atwrt,
    z_lonsx   TYPE atwrt,
    herkl     TYPE atwrt,
    gpnk      TYPE atwrt,
    baoquan   TYPE atwrt,
    quycach   TYPE atwrt,
  END OF gty_batch,

  BEGIN OF gty_mat,
    matnr TYPE matnr,
    maktx TYPE maktx,
    normt TYPE normt,
    groes TYPE groes,
    mfrnr TYPE mfrnr,
  END OF gty_mat,

  BEGIN OF gty_lgort,
    werks TYPE werks_d,
    lgort TYPE lgort_d,
    lgobe TYPE lgobe,
  END OF gty_lgort,

  BEGIN OF gty_dlv,
    vbeln     TYPE vbeln_vl,
    lfdat     TYPE lfdat_v,
    wadat_ist TYPE wadat_ist,
    traid     TYPE traid,
    bolnr     TYPE bolnr,
    lifex     TYPE lifex,
  END OF gty_dlv,

  BEGIN OF gty_marc,
    matnr TYPE matnr,
    werks TYPE werks_d,
    herkl TYPE herkl,
  END OF gty_marc,

  BEGIN OF gty_partner,
    kind   TYPE char1,
    number TYPE char10,
    name   TYPE char255,
    land1  TYPE land1,
  END OF gty_partner,

  BEGIN OF gty_country,
    land1 TYPE land1,
    landx TYPE landx50,
  END OF gty_country,

* Dòng bảng nhóm Movement Type (ZTWM_MVT_GRP)
  BEGIN OF gty_mvt,
    bwart     TYPE bwart,
    seqnr     TYPE seqnr,
    sobkz     TYPE sobkz,
    aufnr_flg TYPE zde_wm_aufnr_flg,
    bsart     TYPE esart,
    pstyp     TYPE pstyp,
    werks     TYPE werks_d,
    grp_code  TYPE zde_wm_grp_code,
  END OF gty_mvt,

* Loại PO và Item Category của PO tham chiếu
  BEGIN OF gty_po,
    ebeln TYPE ebeln,
    ebelp TYPE ebelp,
    bsart TYPE esart,
    pstyp TYPE pstyp,
  END OF gty_po.

*---------------------------------------------------------------------*
* Dữ liệu chương trình
*---------------------------------------------------------------------*
DATA:
  gt_item  TYPE gtt_item,
  gt_alv   TYPE gtt_alv,
  gt_data  TYPE STANDARD TABLE OF zwm_st_bbknhh,
  gs_parameter TYPE zcore_st_parameter,
  gt_batch TYPE HASHED TABLE OF gty_batch WITH UNIQUE KEY matnr werks charg,
  gt_mat   TYPE HASHED TABLE OF gty_mat WITH UNIQUE KEY matnr,
  gt_lgort TYPE HASHED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
  gt_dlv   TYPE HASHED TABLE OF gty_dlv WITH UNIQUE KEY vbeln,
  gt_marc  TYPE HASHED TABLE OF gty_marc WITH UNIQUE KEY matnr werks,
  gt_partner TYPE HASHED TABLE OF gty_partner WITH UNIQUE KEY kind number,
  gt_country TYPE HASHED TABLE OF gty_country WITH UNIQUE KEY land1,
  gt_mvt   TYPE SORTED TABLE OF gty_mvt WITH NON-UNIQUE KEY bwart seqnr,
  gt_po    TYPE HASHED TABLE OF gty_po WITH UNIQUE KEY ebeln ebelp,
  gr_lfart TYPE RANGE OF lfart,
  go_alv   TYPE REF TO cl_salv_table.

*---------------------------------------------------------------------*
* Sự kiện màn hình trung gian
*---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_function FOR EVENT added_function OF cl_salv_events_table
        IMPORTING e_salv_function,
      on_click FOR EVENT link_click OF cl_salv_events_table
        IMPORTING row column.
ENDCLASS.
