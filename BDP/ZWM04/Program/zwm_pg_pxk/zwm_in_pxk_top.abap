*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PXK_TOP
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
    s_vbeln FOR matdoc-vbeln_im,
    s_aufnr FOR matdoc-aufnr,
    s_kostl FOR matdoc-kostl,
    s_usnam FOR matdoc-usnam.

SELECTION-SCREEN END OF BLOCK bl_para.

SELECTION-SCREEN BEGIN OF BLOCK bl_lay WITH FRAME TITLE TEXT-002.

  PARAMETERS:
    p_op1 RADIOBUTTON GROUP lay DEFAULT 'X',
    p_op2 RADIOBUTTON GROUP lay,
    p_op3 RADIOBUTTON GROUP lay,
    p_op4 RADIOBUTTON GROUP lay.

SELECTION-SCREEN END OF BLOCK bl_lay.

SELECTION-SCREEN BEGIN OF BLOCK bl_opt WITH FRAME TITLE TEXT-003.

  PARAMETERS:
    p_isn AS CHECKBOX,
    p_bq  AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK bl_opt.

CONSTANTS:
  gc_msgid     TYPE symsgid  VALUE 'ZWM04',
  gc_tcode     TYPE tcode    VALUE 'ZWM04',
* FORMNAME nhật ký in dùng chung cho 4 mẫu
  gc_prt_form  TYPE tdsfname VALUE 'ZWM04',
* Mẫu 1 và 3 dùng chung layout, khác tiêu đề và chữ ký
  gc_form_op1  TYPE tdsfname VALUE 'ZWM_SF_PXK',
  gc_form_op2  TYPE tdsfname VALUE 'ZWM_SF_PXK_OP2',
  gc_form_op4  TYPE tdsfname VALUE 'ZWM_SF_PXK_OP4',
  gc_logo      TYPE char50   VALUE 'ZLOGO_0001',
  gc_max_days  TYPE i        VALUE 31,
  gc_spras_vi  TYPE spras    VALUE 'V',
  gc_spras_en  TYPE spras    VALUE 'E',
* Mẫu 4 chỉ nhận MvT xuất lấy mẫu; mặc định 331, 333, 335 khi STVARV chưa khai báo
  gc_bwart_xm1 TYPE bwart    VALUE '331',
  gc_bwart_xm2 TYPE bwart    VALUE '333',
  gc_bwart_xm3 TYPE bwart    VALUE '335',
  gc_tvarv_bwart_mau TYPE rvari_vnam VALUE 'ZWM04_BWART_MAU',
* Nhóm nghiệp vụ thuộc chuyển kho / chuyển trạng thái: không in ở ZWM04
  gc_grp_dc    TYPE zde_wm_grp_code VALUE 'DC',
  gc_grp_tt    TYPE zde_wm_grp_code VALUE 'TT',
  gc_grp_vt    TYPE zde_wm_grp_code VALUE 'VT',
* STVARV (loại S): nhóm vật tư kiểm soát đặc biệt (mẫu 3)
  gc_tvarv_matkl TYPE rvari_vnam VALUE 'ZWM04_MATKL_KSDB',
  gc_at_nongdo   TYPE atnam VALUE 'Z_NONG_DO_HL',
  gc_at_doam1    TYPE atnam VALUE 'ZQC_DOAM1',
  gc_at_doam2    TYPE atnam VALUE 'Z_DO_AM_PKN',
  gc_at_nsx      TYPE atnam VALUE 'Z_NSX',
  gc_at_nuoc     TYPE atnam VALUE 'Z_NUOC_SX',
  gc_at_lonsx    TYPE atnam VALUE 'Z_BATCH_NSX',
  gc_at_quycach  TYPE atnam VALUE 'Z_QUYCACH_TPHH',
  gc_at_quycach2 TYPE atnam VALUE 'Z_QUY_CACH_BATCH',
  gc_at_baoquan  TYPE atnam VALUE 'Z_BAO_QUAN_BATCH'.

TYPES:
  BEGIN OF gty_item,
    mblnr     TYPE mblnr,
    mjahr     TYPE mjahr,
    zeile     TYPE mblpo,
    bwart     TYPE bwart,
    sobkz     TYPE sobkz,
    budat     TYPE budat,
    bldat     TYPE bldat,
    bktxt     TYPE bktxt,
    usnam     TYPE usnam,
    bukrs     TYPE bukrs,
    werks     TYPE werks_d,
    lgort     TYPE lgort_d,
    matnr     TYPE matnr,
    charg     TYPE charg_d,
    menge     TYPE menge_d,
    meins     TYPE meins,
    erfmg     TYPE erfmg,
    erfme     TYPE erfme,
    aufnr     TYPE aufnr,
    kostl     TYPE kostl,
    kokrs     TYPE kokrs,
    anln1     TYPE anln1,
    anln2     TYPE anln2,
    lifnr     TYPE lifnr,
    kunnr     TYPE kunnr,
    vbeln_im  TYPE vbeln_vl,
    vbelp_im  TYPE posnr_vl,
    lips_aufnr TYPE aufnr,
    shipto    TYPE kunnr,
    txt_vi    TYPE zde_wm_mvt_txt_vi,
    txt_en    TYPE zde_wm_mvt_txt_en,
    rev_bwart TYPE bwart,
    rev_cnt   TYPE i,
    menge_net TYPE menge_d,
    erfmg_net TYPE erfmg,
    del       TYPE abap_bool,
    rcp_kind  TYPE char1,
    rcp_code  TYPE char20,
    rcp_name  TYPE char255,
  END OF gty_item,
  gtt_item TYPE SORTED TABLE OF gty_item WITH NON-UNIQUE KEY mblnr mjahr zeile,
  gtt_line TYPE STANDARD TABLE OF gty_item WITH EMPTY KEY,

  BEGIN OF gty_okey,
    mblnr     TYPE mblnr,
    mjahr     TYPE mjahr,
    zeile     TYPE mblpo,
    rev_bwart TYPE bwart,
  END OF gty_okey,
  gtt_okey TYPE STANDARD TABLE OF gty_okey WITH EMPTY KEY,

  BEGIN OF gty_rev,
    org_mblnr TYPE mblnr,
    org_mjahr TYPE mjahr,
    org_zeile TYPE mblpo,
    rev_mblnr TYPE mblnr,
    rev_mjahr TYPE mjahr,
    rev_zeile TYPE mblpo,
    rev_bwart TYPE bwart,
    menge     TYPE menge_d,
    meins     TYPE meins,
  END OF gty_rev,

  BEGIN OF gty_docadj,
    mblnr    TYPE mblnr,
    mjahr    TYPE mjahr,
    rev_docs TYPE char255,
  END OF gty_docadj,

  BEGIN OF gty_alv,
    sel         TYPE abap_bool,
    mblnr       TYPE mblnr,
    mjahr       TYPE mjahr,
    bwart       TYPE bwart,
    lgort       TYPE char10,
    code        TYPE char80,
    descr       TYPE char80,
    print_count TYPE i,
    last_user   TYPE syuname,
    werks       TYPE werks_d,
    obj_key     TYPE zewm_de_obj_key,
  END OF gty_alv,
  gtt_alv TYPE STANDARD TABLE OF gty_alv WITH EMPTY KEY,

* Một phiếu in: cùng chứng từ + SLoc + lệnh xuất kho + đơn vị nhận
  BEGIN OF gty_sheet,
    mblnr    TYPE mblnr,
    mjahr    TYPE mjahr,
    lgort    TYPE lgort_d,
    vbeln_im TYPE vbeln_vl,
    rcp_code TYPE char20,
  END OF gty_sheet,

  BEGIN OF gty_hdr,
    descr    TYPE char255,
    descr_en TYPE char255,
    belnr    TYPE belnr_d,
  END OF gty_hdr,

  BEGIN OF gty_batch,
    matnr     TYPE matnr,
    werks     TYPE werks_d,
    charg     TYPE charg_d,
    vfdat     TYPE vfdat,
    qndat     TYPE qnpdat,
    licha     TYPE lichn,
    z_nongdo  TYPE atwrt,
    z_doam1   TYPE atwrt,
    z_doam2   TYPE atwrt,
    z_nsx     TYPE atwrt,
    z_nuoc    TYPE atwrt,
    z_lonsx   TYPE atwrt,
    quycach   TYPE atwrt,
    quycach2  TYPE atwrt,
    baoquan   TYPE atwrt,
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

  BEGIN OF gty_lgort,
    werks TYPE werks_d,
    lgort TYPE lgort_d,
    lgobe TYPE lgobe,
  END OF gty_lgort,

  BEGIN OF gty_unit,
    msehi TYPE msehi,
    msehl TYPE msehl,
  END OF gty_unit,

  BEGIN OF gty_bkpf,
    awkey TYPE awkey,
    belnr TYPE belnr_d,
  END OF gty_bkpf,

  BEGIN OF gty_cskt,
    kokrs TYPE kokrs,
    kostl TYPE kostl,
    ltext TYPE cskt-ltext,
  END OF gty_cskt,

  BEGIN OF gty_anlt,
    bukrs TYPE bukrs,
    anln1 TYPE anln1,
    anln2 TYPE anln2,
    spras TYPE spras,
    txt50 TYPE anlt-txt50,
  END OF gty_anlt,

  BEGIN OF gty_bp,
    partner  TYPE bu_partner,
    name_org1 TYPE bu_nameor1,
    name_org2 TYPE bu_nameor2,
    name_org3 TYPE bu_nameor3,
    name_org4 TYPE bu_nameor4,
  END OF gty_bp,

  BEGIN OF gty_aufk,
    aufnr TYPE aufnr,
    ktext TYPE aufk-ktext,
  END OF gty_aufk,

  BEGIN OF gty_resb,
    aufnr TYPE aufnr,
    rsnum TYPE rsnum,
    rspos TYPE rspos,
    lgort TYPE lgort_d,
    lgobe TYPE lgobe,
  END OF gty_resb,

  BEGIN OF gty_t156t,
    bwart TYPE bwart,
    spras TYPE spras,
    btext TYPE t156t-btext,
  END OF gty_t156t,

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
    bsart     TYPE esart,
    pstyp     TYPE pstyp,
    werks     TYPE werks_d,
    grp_code  TYPE zde_wm_grp_code,
    txt_vi    TYPE zde_wm_mvt_txt_vi,
    txt_en    TYPE zde_wm_mvt_txt_en,
    rev_bwart TYPE zde_wm_rev_bwart,
  END OF gty_mvt,

  BEGIN OF gty_dlv,
    docno TYPE c LENGTH 35,
  END OF gty_dlv.

DATA:
  gt_item      TYPE gtt_item,
  gt_mvt       TYPE SORTED TABLE OF gty_mvt WITH NON-UNIQUE KEY bwart seqnr,
  gt_rev       TYPE SORTED TABLE OF gty_rev WITH NON-UNIQUE KEY org_mblnr org_mjahr org_zeile,
  gt_docadj    TYPE HASHED TABLE OF gty_docadj WITH UNIQUE KEY mblnr mjahr,
  gt_alv       TYPE gtt_alv,
  gt_data      TYPE STANDARD TABLE OF zwm_st_pxk,
  gs_parameter TYPE zcore_st_parameter,
  gr_matkl_ksdb TYPE RANGE OF matkl,
  gr_bwart_mau  TYPE RANGE OF bwart,
  gt_mat       TYPE HASHED TABLE OF gty_mat WITH UNIQUE KEY matnr,
  gt_makt      TYPE HASHED TABLE OF gty_makt WITH UNIQUE KEY matnr spras,
  gt_marc      TYPE HASHED TABLE OF gty_marc WITH UNIQUE KEY matnr werks,
  gt_lgort     TYPE HASHED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
  gt_batch     TYPE HASHED TABLE OF gty_batch WITH UNIQUE KEY matnr werks charg,
  gt_unit_en   TYPE HASHED TABLE OF gty_unit WITH UNIQUE KEY msehi,
  gt_bkpf      TYPE SORTED TABLE OF gty_bkpf WITH NON-UNIQUE KEY awkey,
  gt_cskt      TYPE SORTED TABLE OF gty_cskt WITH NON-UNIQUE KEY kokrs kostl,
  gt_anlt      TYPE SORTED TABLE OF gty_anlt WITH NON-UNIQUE KEY bukrs anln1 anln2 spras,
  gt_bp        TYPE HASHED TABLE OF gty_bp WITH UNIQUE KEY partner,
  gt_aufk      TYPE HASHED TABLE OF gty_aufk WITH UNIQUE KEY aufnr,
  gt_resb      TYPE HASHED TABLE OF gty_resb WITH UNIQUE KEY aufnr,
  gt_t156t     TYPE SORTED TABLE OF gty_t156t WITH UNIQUE KEY bwart spras,
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
