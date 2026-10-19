*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PCK_TOP
*&---------------------------------------------------------------------*

TABLES:
  matdoc.

*---------------------------------------------------------------------*
* SELECTION-SCREEN
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bl_para WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS:
    s_werks FOR matdoc-werks MEMORY ID wrk OBLIGATORY,
    s_mblnr FOR matdoc-mblnr.

  PARAMETERS:
    p_mjahr TYPE mjahr OBLIGATORY DEFAULT sy-datum(4).

  SELECT-OPTIONS:
    s_budat FOR matdoc-budat,
    s_bwart FOR matdoc-bwart,
    s_lgort FOR matdoc-lgort,
    s_umlgo FOR matdoc-umlgo,
    s_rsnum FOR matdoc-rsnum,
    s_usnam FOR matdoc-usnam.

SELECTION-SCREEN END OF BLOCK bl_para.

SELECTION-SCREEN BEGIN OF BLOCK bl_lay WITH FRAME TITLE TEXT-002.

  PARAMETERS:
    p_op1 RADIOBUTTON GROUP lay DEFAULT 'X',
    p_op2 RADIOBUTTON GROUP lay,
    p_op3 RADIOBUTTON GROUP lay.
*   Bỏ mẫu 4 (Hình 2 của FS chỉ có 3 mẫu)
*   p_op4 RADIOBUTTON GROUP lay MODIF ID op4.

SELECTION-SCREEN END OF BLOCK bl_lay.

SELECTION-SCREEN BEGIN OF BLOCK bl_opt WITH FRAME TITLE TEXT-003.

  PARAMETERS:
    p_isn AS CHECKBOX.

SELECTION-SCREEN END OF BLOCK bl_opt.

CONSTANTS:
  gc_msgid     TYPE symsgid  VALUE 'ZWM05',
  gc_tcode     TYPE tcode    VALUE 'ZWM05',
  gc_prt_form  TYPE tdsfname VALUE 'ZWM05',
* Mẫu 1, 2, 4 và phiếu chuyển trạng thái dùng chung form; mẫu 3 có thêm 2 cột ký tay
  gc_form_std  TYPE tdsfname VALUE 'ZWM_SF_PCK',
  gc_form_op3  TYPE tdsfname VALUE 'ZWM_SF_PCK_OP3',
  gc_logo      TYPE char50   VALUE 'ZLOGO_0001',
  gc_max_days  TYPE i        VALUE 31,
  gc_spras_vi  TYPE spras    VALUE 'V',
  gc_spras_en  TYPE spras    VALUE 'E',
  gc_grp_dc    TYPE zde_wm_grp_code VALUE 'DC',
  gc_grp_tt    TYPE zde_wm_grp_code VALUE 'TT',
  gc_bwart_ud  TYPE bwart    VALUE '321',
* Vật tư nhóm retest in thêm ngày KNL; mặc định Z21 khi STVARV chưa khai báo
  gc_mtart_knl TYPE mtart    VALUE 'Z21',
  gc_dimid_mass TYPE dimid   VALUE 'MASS',
* Đơn vị đóng gói: BOX in là HOP, CAR/KAR in là THU (theo bản in ECC)
  gc_unit_box  TYPE msehi    VALUE 'BOX',
  gc_unit_car  TYPE msehi    VALUE 'CAR',
  gc_unit_kar  TYPE msehi    VALUE 'KAR',
  gc_unit_hop  TYPE msehi    VALUE 'HOP',
  gc_unit_thu  TYPE msehi    VALUE 'THU',
* STVARV (loại S): nhóm vật tư kiểm soát đặc biệt, material type retest
  gc_tvarv_matkl TYPE rvari_vnam VALUE 'ZWM05_MATKL_KSDB',
  gc_tvarv_mtart TYPE rvari_vnam VALUE 'ZWM05_MTART_KNL',
  gc_at_nsx      TYPE atnam VALUE 'Z_NSX',
  gc_at_nuoc     TYPE atnam VALUE 'Z_NUOC_SX',
  gc_at_lonsx    TYPE atnam VALUE 'Z_BATCH_NSX',
  gc_at_quycach  TYPE atnam VALUE 'Z_QUY_CACH_BATCH',
  gc_at_baoquan  TYPE atnam VALUE 'Z_BAO_QUAN_BATCH'.

TYPES:
* Một dòng xuất (XAUTO trống) kèm thông tin dòng nhận (XAUTO = X)
  BEGIN OF gty_item,
    mblnr     TYPE mblnr,
    mjahr     TYPE mjahr,
    zeile     TYPE mblpo,
    bwart     TYPE bwart,
    sobkz     TYPE sobkz,
    budat     TYPE budat,
    bktxt     TYPE bktxt,
    usnam     TYPE usnam,
    bukrs     TYPE bukrs,
    werks     TYPE werks_d,
    lgort     TYPE lgort_d,
    umwrk     TYPE werks_d,
    umlgo     TYPE umlgo,
    matnr     TYPE matnr,
    ummat     TYPE ummat,
    charg     TYPE charg_d,
    umcha     TYPE umcha,
    menge     TYPE menge_d,
    meins     TYPE meins,
    erfmg     TYPE erfmg,
    erfme     TYPE erfme,
    rsnum     TYPE rsnum,
    aufnr     TYPE aufnr,
    smbln     TYPE mblnr,
    insmk     TYPE mb_insmk,
    rcv_werks TYPE werks_d,
    rcv_lgort TYPE lgort_d,
    rcv_matnr TYPE matnr,
    rcv_charg TYPE charg_d,
    rcv_insmk TYPE mb_insmk,
    to_werks  TYPE werks_d,
    to_lgort  TYPE lgort_d,
    to_matnr  TYPE matnr,
    to_charg  TYPE charg_d,
    grp_code  TYPE zde_wm_grp_code,
    txt_vi    TYPE zde_wm_mvt_txt_vi,
    txt_en    TYPE zde_wm_mvt_txt_en,
  END OF gty_item,
  gtt_item TYPE STANDARD TABLE OF gty_item WITH EMPTY KEY,

  BEGIN OF gty_doc,
    mblnr TYPE mblnr,
    mjahr TYPE mjahr,
  END OF gty_doc,

  BEGIN OF gty_cancel,
    mblnr     TYPE mblnr,
    mjahr     TYPE mjahr,
    rev_mblnr TYPE mblnr,
  END OF gty_cancel,

  BEGIN OF gty_docrev,
    mblnr    TYPE mblnr,
    mjahr    TYPE mjahr,
    rev_docs TYPE char255,
  END OF gty_docrev,

* Một phiếu in: chứng từ + SLoc xuất + SLoc nhận
  BEGIN OF gty_sheet,
    mblnr    TYPE mblnr,
    mjahr    TYPE mjahr,
    werks    TYPE werks_d,
    lgort    TYPE lgort_d,
    to_werks TYPE werks_d,
    to_lgort TYPE lgort_d,
  END OF gty_sheet,

  BEGIN OF gty_alv,
    sel         TYPE abap_bool,
    mblnr       TYPE mblnr,
    mjahr       TYPE mjahr,
    budat       TYPE budat,
    bwart       TYPE bwart,
    issue       TYPE char12,
    recv        TYPE char12,
    loai        TYPE char200,
    rsnum_txt   TYPE char60,
    lines       TYPE i,
    rev_by      TYPE char60,
    print_count TYPE i,
    last_user   TYPE syuname,
    werks       TYPE werks_d,
    lgort       TYPE lgort_d,
    to_werks    TYPE werks_d,
    to_lgort    TYPE lgort_d,
    obj_key     TYPE zewm_de_obj_key,
  END OF gty_alv,
  gtt_alv TYPE STANDARD TABLE OF gty_alv WITH EMPTY KEY,

* Kết quả xét một phiếu: form, tiêu đề, khối chữ ký, bị chặn in
  BEGIN OF gty_lay,
    grp      TYPE zde_wm_grp_code,
    form     TYPE tdsfname,
    title    TYPE char255,
    title_en TYPE char255,
    signs    TYPE string_table,
    type_txt TYPE char200,
    block    TYPE abap_bool,
  END OF gty_lay,

  BEGIN OF gty_run,
    alv TYPE gty_alv,
    lay TYPE gty_lay,
  END OF gty_run,
  gtt_run TYPE STANDARD TABLE OF gty_run WITH EMPTY KEY,

  BEGIN OF gty_fm,
    form TYPE tdsfname,
    fm   TYPE rs38l_fnam,
  END OF gty_fm,

  BEGIN OF gty_hdr,
    descr    TYPE char255,
    descr_en TYPE char255,
  END OF gty_hdr,

  BEGIN OF gty_batch,
    matnr    TYPE matnr,
    werks    TYPE werks_d,
    charg    TYPE charg_d,
    vfdat    TYPE vfdat,
    qndat    TYPE qnpdat,
    hsdat    TYPE hsdat,
    licha    TYPE lichn,
    z_nsx    TYPE atwrt,
    z_nuoc   TYPE atwrt,
    z_lonsx  TYPE atwrt,
    quycach  TYPE atwrt,
    baoquan  TYPE atwrt,
  END OF gty_batch,

  BEGIN OF gty_mat,
    matnr     TYPE matnr,
    mtart     TYPE mtart,
    matkl     TYPE matkl,
    groes     TYPE groes,
    raube     TYPE raube,
    mfrnr     TYPE mfrnr,
    raube_txt TYPE t142t-rbtxt,
  END OF gty_mat,

  BEGIN OF gty_makt,
    matnr TYPE matnr,
    spras TYPE spras,
    maktx TYPE maktx,
  END OF gty_makt,

  BEGIN OF gty_marc,
    matnr TYPE matnr,
    werks TYPE werks_d,
    herkl TYPE herkl,
  END OF gty_marc,

  BEGIN OF gty_marm,
    matnr TYPE matnr,
    meinh TYPE lrmei,
    umrez TYPE umrez,
    umren TYPE umren,
  END OF gty_marm,

  BEGIN OF gty_unit,
    msehi TYPE msehi,
    dimid TYPE dimid,
    mseh6 TYPE mseh6,
  END OF gty_unit,

  BEGIN OF gty_lgort,
    werks TYPE werks_d,
    lgort TYPE lgort_d,
    lgobe TYPE lgobe,
  END OF gty_lgort,

  BEGIN OF gty_plant,
    werks TYPE werks_d,
    name1 TYPE name1,
  END OF gty_plant,

  BEGIN OF gty_title,
    werks    TYPE werks_d,
    lgort    TYPE lgort_d,
    umlgo    TYPE umlgo,
    title_vi TYPE char255,
    title_en TYPE char255,
  END OF gty_title,

  BEGIN OF gty_sign,
    werks     TYPE werks_d,
    bwart     TYPE bwart,
    lgort     TYPE lgort_d,
    umlgo     TYPE umlgo,
    sign_qlcl TYPE abap_bool,
  END OF gty_sign,

  BEGIN OF gty_qamb,
    mblnr    TYPE mblnr,
    mjahr    TYPE mjahr,
    zeile    TYPE mblpo,
    prueflos TYPE qplos,
  END OF gty_qamb,

  BEGIN OF gty_insmk,
    domvalue_l TYPE domvalue_l,
    ddlanguage TYPE ddlanguage,
    ddtext     TYPE val_text,
  END OF gty_insmk,

  BEGIN OF gty_partner,
    kind    TYPE char1,
    number  TYPE char10,
    name    TYPE char255,
    address TYPE char255,
    tax     TYPE char255,
    tel     TYPE char255,
    fax     TYPE char255,
    remark  TYPE char255,
    land1   TYPE land1,
  END OF gty_partner,

  BEGIN OF gty_country,
    land1 TYPE land1,
    landx TYPE landx50,
  END OF gty_country,

  BEGIN OF gty_mvt,
    bwart     TYPE bwart,
    seqnr     TYPE seqnr,
    sobkz     TYPE sobkz,
    aufnr_flg TYPE zde_wm_aufnr_flg,
    werks     TYPE werks_d,
    grp_code  TYPE zde_wm_grp_code,
    txt_vi    TYPE zde_wm_mvt_txt_vi,
    txt_en    TYPE zde_wm_mvt_txt_en,
  END OF gty_mvt.

DATA:
  gt_item      TYPE gtt_item,
  gt_mvt       TYPE SORTED TABLE OF gty_mvt WITH NON-UNIQUE KEY bwart seqnr,
  gt_docrev    TYPE HASHED TABLE OF gty_docrev WITH UNIQUE KEY mblnr mjahr,
  gt_alv       TYPE gtt_alv,
  gt_data      TYPE STANDARD TABLE OF zwm_st_pck,
  gs_parameter TYPE zcore_st_parameter,
  gr_matkl_ksdb TYPE RANGE OF matkl,
  gr_mtart_knl  TYPE RANGE OF mtart,
  gt_mat       TYPE HASHED TABLE OF gty_mat WITH UNIQUE KEY matnr,
  gt_makt      TYPE HASHED TABLE OF gty_makt WITH UNIQUE KEY matnr spras,
  gt_marc      TYPE HASHED TABLE OF gty_marc WITH UNIQUE KEY matnr werks,
  gt_marm      TYPE SORTED TABLE OF gty_marm WITH NON-UNIQUE KEY matnr,
  gt_unit      TYPE HASHED TABLE OF gty_unit WITH UNIQUE KEY msehi,
  gt_lgort     TYPE HASHED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
  gt_plant     TYPE HASHED TABLE OF gty_plant WITH UNIQUE KEY werks,
  gt_batch     TYPE HASHED TABLE OF gty_batch WITH UNIQUE KEY matnr werks charg,
  gt_title     TYPE HASHED TABLE OF gty_title WITH UNIQUE KEY werks lgort umlgo,
  gt_sign      TYPE STANDARD TABLE OF gty_sign WITH EMPTY KEY,
  gt_qamb      TYPE SORTED TABLE OF gty_qamb WITH NON-UNIQUE KEY mblnr mjahr zeile,
  gt_insmk     TYPE SORTED TABLE OF gty_insmk WITH NON-UNIQUE KEY domvalue_l ddlanguage,
  gt_partner   TYPE HASHED TABLE OF gty_partner WITH UNIQUE KEY kind number,
  gt_country   TYPE HASHED TABLE OF gty_country WITH UNIQUE KEY land1,
  gv_bi        TYPE abap_bool,
  gv_msg_init  TYPE abap_bool,
  go_alv       TYPE REF TO cl_salv_table.

CLASS lcl_util DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      lbl IMPORTING iv_vi          TYPE csequence
                    iv_en          TYPE csequence
          RETURNING VALUE(rv_text) TYPE string,
      lbl_c IMPORTING iv_vi          TYPE csequence
                      iv_en          TYPE csequence
            RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_function FOR EVENT added_function OF cl_salv_events_table
        IMPORTING e_salv_function,
      on_click FOR EVENT link_click OF cl_salv_events_table
        IMPORTING row column.
ENDCLASS.
