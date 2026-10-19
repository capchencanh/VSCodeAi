*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PNK_TOP
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
    s_lifnr FOR matdoc-lifnr,
    s_ebeln FOR matdoc-ebeln,
    s_aufnr FOR matdoc-aufnr,
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
    p_adj AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK bl_opt.

CONSTANTS:
  gc_msgid     TYPE symsgid  VALUE 'ZWM03',
  gc_tcode     TYPE tcode    VALUE 'ZWM03',
* FORMNAME nhật ký in dùng chung cho 4 mẫu
  gc_prt_form  TYPE tdsfname VALUE 'ZWM03',
  gc_form_op1  TYPE tdsfname VALUE 'ZWM_SF_PNK',
  gc_form_op2  TYPE tdsfname VALUE 'ZWM_SF_PNK_OP2',
  gc_form_op3  TYPE tdsfname VALUE 'ZWM_SF_PNK_OP3',
  gc_form_op4  TYPE tdsfname VALUE 'ZWM_SF_PNK_OP4',
  gc_logo      TYPE char50   VALUE 'ZLOGO_0001',
  gc_max_days  TYPE i        VALUE 31,
  gc_spras_vi  TYPE spras    VALUE 'V',
  gc_spras_en  TYPE spras    VALUE 'E',
  gc_bwart_309 TYPE bwart    VALUE '309',
  gc_bwart_305 TYPE bwart    VALUE '305',
  gc_bwart_315 TYPE bwart    VALUE '315',
  gc_insmk_qi  TYPE insmk    VALUE '2',
  gc_grp_mh    TYPE zde_wm_grp_code VALUE 'MH',
  gc_grp_sx    TYPE zde_wm_grp_code VALUE 'SX',
  gc_grp_th    TYPE zde_wm_grp_code VALUE 'TH',
  gc_grp_dc    TYPE zde_wm_grp_code VALUE 'DC',
* STVARV (loại S): loại vật tư có retest
  gc_tvarv_mtart TYPE rvari_vnam VALUE 'ZWM03_MTART_KNL',
  gc_txt_sohd    TYPE tdid VALUE 'ZLF1',
  gc_txt_ngayhd  TYPE tdid VALUE 'ZLF2',
  gc_at_nongdo   TYPE atnam VALUE 'Z_NONG_DO_HL',
  gc_at_doam1    TYPE atnam VALUE 'Z_QC_DOAM1',
  gc_at_doam2    TYPE atnam VALUE 'Z_DO_AM_PKN',
  gc_at_nsx      TYPE atnam VALUE 'Z_NSX',
  gc_at_nuoc     TYPE atnam VALUE 'Z_NUOC_SX',
  gc_at_lonsx    TYPE atnam VALUE 'Z_BATCH_NSX',
  gc_at_quycach  TYPE atnam VALUE 'Z_QUY_CACH_BATCH',
  gc_at_baoquan  TYPE atnam VALUE 'Z_BAO_QUAN_BATCH'.

TYPES:
  BEGIN OF gty_item,
    mblnr     TYPE mblnr,
    mjahr     TYPE mjahr,
    zeile     TYPE mblpo,
    bwart     TYPE bwart,
    sobkz     TYPE sobkz,
    insmk     TYPE insmk,
    budat     TYPE budat,
    bldat     TYPE bldat,
    bktxt     TYPE bktxt,
    xblnr     TYPE xblnr1,
    usnam     TYPE usnam,
    bukrs     TYPE bukrs,
    werks     TYPE werks_d,
    lgort     TYPE lgort_d,
    matnr     TYPE matnr,
    ematn     TYPE ematn,
    charg     TYPE charg_d,
    menge     TYPE menge_d,
    meins     TYPE meins,
    erfmg     TYPE erfmg,
    erfme     TYPE erfme,
    ebeln     TYPE ebeln,
    ebelp     TYPE ebelp,
    aufnr     TYPE aufnr,
    kostl     TYPE kostl,
    kokrs     TYPE kokrs,
    lifnr     TYPE lifnr,
    kunnr     TYPE kunnr,
    vbeln_im  TYPE vbeln_vl,
    le_vbeln  TYPE vbeln_vl,
    bsart     TYPE esart,
    po_waers  TYPE waers,
    reswk     TYPE reswk,
    pstyp     TYPE pstyp,
    reslo     TYPE reslo,
    txz01     TYPE txz01,
    grp_found TYPE abap_bool,
    grp_code  TYPE zde_wm_grp_code,
    txt_vi    TYPE zde_wm_mvt_txt_vi,
    txt_en    TYPE zde_wm_mvt_txt_en,
    rev_bwart TYPE bwart,
    rev_cnt   TYPE i,
    menge_net TYPE menge_d,
    erfmg_net TYPE erfmg,
    del       TYPE abap_bool,
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
    erfmg     TYPE erfmg,
    erfme     TYPE erfme,
    usnam     TYPE usnam,
    budat     TYPE budat,
  END OF gty_rev,

  BEGIN OF gty_docadj,
    mblnr     TYPE mblnr,
    mjahr     TYPE mjahr,
    rev_docs  TYPE char255,
    adj_lines TYPE i,
  END OF gty_docadj,

  BEGIN OF gty_detail,
    org_mblnr TYPE mblnr,
    org_mjahr TYPE mjahr,
    org_zeile TYPE mblpo,
    matnr     TYPE matnr,
    org_bwart TYPE bwart,
    org_erfmg TYPE erfmg,
    org_erfme TYPE erfme,
    rev_mblnr TYPE mblnr,
    rev_mjahr TYPE mjahr,
    rev_zeile TYPE mblpo,
    rev_bwart TYPE bwart,
    rev_erfmg TYPE erfmg,
    rev_erfme TYPE erfme,
    usnam     TYPE usnam,
    budat     TYPE budat,
  END OF gty_detail,

  BEGIN OF gty_alv,
    sel         TYPE abap_bool,
    mblnr       TYPE mblnr,
    mjahr       TYPE mjahr,
    budat       TYPE budat,
    bwart       TYPE bwart,
    lgort       TYPE char10,
    code        TYPE char20,
    descr       TYPE char80,
    item_count  TYPE i,
    adj         TYPE char20,
    print_count TYPE i,
    werks       TYPE werks_d,
    obj_key     TYPE zewm_de_obj_key,
    adj_docs    TYPE char255,
  END OF gty_alv,
  gtt_alv TYPE STANDARD TABLE OF gty_alv WITH EMPTY KEY,

  BEGIN OF gty_sheet,
    docs  TYPE gtt_alv,
    lgort TYPE lgort_d,
  END OF gty_sheet,

  BEGIN OF gty_grp,
    mblnr TYPE mblnr,
    mjahr TYPE mjahr,
    lgort TYPE lgort_d,
  END OF gty_grp,

  BEGIN OF gty_hdr,
    p_kind   TYPE char1,
    p_number TYPE char10,
    code     TYPE char20,
    name     TYPE char255,
    address  TYPE char255,
    tax      TYPE char255,
    waers    TYPE waers,
    kursf    TYPE char30,
    belnr    TYPE belnr_d,
    descr    TYPE char255,
    descr_en TYPE char255,
    sohd     TYPE char255,
    ngayhd   TYPE char255,
  END OF gty_hdr,

  BEGIN OF gty_batch,
    matnr    TYPE matnr,
    werks    TYPE werks_d,
    charg    TYPE charg_d,
    vfdat    TYPE vfdat,
    qndat    TYPE qnpdat,
    licha    TYPE lichn,
    z_nongdo TYPE atwrt,
    z_doam1  TYPE atwrt,
    z_doam2  TYPE atwrt,
    z_nsx    TYPE atwrt,
    z_nuoc   TYPE atwrt,
    z_lonsx  TYPE atwrt,
    quycach  TYPE atwrt,
    baoquan  TYPE atwrt,
  END OF gty_batch,

  BEGIN OF gty_mat,
    matnr     TYPE matnr,
    mtart     TYPE mtart,
    groes     TYPE groes,
    raube     TYPE raube,
    mfrnr     TYPE mfrnr,
    meins     TYPE meins,
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

  BEGIN OF gty_marm,
    matnr TYPE matnr,
    meinh TYPE lrmei,
    mseh6 TYPE mseh6,
    ratio TYPE p LENGTH 16 DECIMALS 6,
  END OF gty_marm,

  BEGIN OF gty_unit,
    msehi TYPE msehi,
    msehl TYPE msehl,
  END OF gty_unit,

  BEGIN OF gty_bkpf,
    awkey TYPE awkey,
    belnr TYPE belnr_d,
    waers TYPE waers,
    kursf TYPE kursf,
  END OF gty_bkpf,

  BEGIN OF gty_cskt,
    kokrs TYPE kokrs,
    kostl TYPE kostl,
    ktext TYPE ktext,
  END OF gty_cskt,

  BEGIN OF gty_resb,
    aufnr TYPE aufnr,
    rsnum TYPE rsnum,
    rspos TYPE rspos,
    lgort TYPE lgort_d,
    lgobe TYPE lgobe,
  END OF gty_resb,

  BEGIN OF gty_issue,
    mblnr TYPE mblnr,
    mjahr TYPE mjahr,
    werks TYPE werks_d,
    lgort TYPE lgort_d,
    lgobe TYPE lgobe,
  END OF gty_issue,

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
  END OF gty_mvt.

DATA:
  gt_item      TYPE gtt_item,
  gt_mvt       TYPE SORTED TABLE OF gty_mvt WITH NON-UNIQUE KEY bwart seqnr,
  gt_rev       TYPE SORTED TABLE OF gty_rev WITH NON-UNIQUE KEY org_mblnr org_mjahr org_zeile,
  gt_docadj    TYPE HASHED TABLE OF gty_docadj WITH UNIQUE KEY mblnr mjahr,
  gt_detail    TYPE STANDARD TABLE OF gty_detail WITH EMPTY KEY,
  gt_alv       TYPE gtt_alv,
  gt_data      TYPE STANDARD TABLE OF zwm_st_pnk,
  gs_parameter TYPE zcore_st_parameter,
  gr_mtart_knl TYPE RANGE OF mtart,
  gt_mat       TYPE HASHED TABLE OF gty_mat WITH UNIQUE KEY matnr,
  gt_makt      TYPE HASHED TABLE OF gty_makt WITH UNIQUE KEY matnr spras,
  gt_marc      TYPE HASHED TABLE OF gty_marc WITH UNIQUE KEY matnr werks,
  gt_lgort     TYPE HASHED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
  gt_batch     TYPE HASHED TABLE OF gty_batch WITH UNIQUE KEY matnr werks charg,
  gt_marm      TYPE STANDARD TABLE OF gty_marm WITH EMPTY KEY,
  gt_unit_en   TYPE HASHED TABLE OF gty_unit WITH UNIQUE KEY msehi,
  gt_bkpf      TYPE SORTED TABLE OF gty_bkpf WITH NON-UNIQUE KEY awkey,
  gt_cskt      TYPE SORTED TABLE OF gty_cskt WITH NON-UNIQUE KEY kokrs kostl,
  gt_resb      TYPE HASHED TABLE OF gty_resb WITH UNIQUE KEY aufnr,
  gt_issue     TYPE SORTED TABLE OF gty_issue WITH NON-UNIQUE KEY mblnr,
  gt_partner   TYPE HASHED TABLE OF gty_partner WITH UNIQUE KEY kind number,
  gt_country   TYPE HASHED TABLE OF gty_country WITH UNIQUE KEY land1,
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
            RETURNING VALUE(rv_text) TYPE string,
      date_text IMPORTING iv_date        TYPE d
                RETURNING VALUE(rv_text) TYPE string,
      num_text IMPORTING iv_val         TYPE p
                         iv_dec         TYPE i DEFAULT 5
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
