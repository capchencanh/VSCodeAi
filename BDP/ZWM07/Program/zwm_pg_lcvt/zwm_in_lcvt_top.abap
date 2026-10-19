*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_LCVT_TOP
*&---------------------------------------------------------------------*

TABLES:
  /scwm/ordim_o.

DATA:
  gv_matnr TYPE matnr,
  gv_aufnr TYPE aufnr,
  gv_docno TYPE /scdl/dl_docno_int.

*---------------------------------------------------------------------*
* SELECTION-SCREEN
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bl_para WITH FRAME TITLE TEXT-001.

  PARAMETERS:
    p_lgnum TYPE /scwm/lgnum OBLIGATORY.

  SELECT-OPTIONS:
    s_tanum  FOR /scwm/ordim_o-tanum,
    s_procty FOR /scwm/ordim_o-procty,
    s_date   FOR sy-datum,
    s_lgtyp  FOR /scwm/ordim_o-vltyp,
    s_docno  FOR gv_docno,
    s_aufnr  FOR gv_aufnr,
    s_matnr  FOR gv_matnr,
    s_user   FOR /scwm/ordim_o-created_by.

SELECTION-SCREEN END OF BLOCK bl_para.

SELECTION-SCREEN BEGIN OF BLOCK bl_st WITH FRAME TITLE TEXT-002.

  PARAMETERS:
    p_st1 RADIOBUTTON GROUP st DEFAULT 'X',
    p_st2 RADIOBUTTON GROUP st,
    p_st3 RADIOBUTTON GROUP st.

SELECTION-SCREEN END OF BLOCK bl_st.

SELECTION-SCREEN BEGIN OF BLOCK bl_opt WITH FRAME TITLE TEXT-003.

  PARAMETERS:
    p_op1 RADIOBUTTON GROUP opt USER-COMMAND uopt DEFAULT 'X',
    p_b2b AS CHECKBOX DEFAULT 'X' MODIF ID op1,
    p_ptw AS CHECKBOX DEFAULT 'X' MODIF ID op1,
    p_pck AS CHECKBOX DEFAULT 'X' MODIF ID op1,
    p_op2 RADIOBUTTON GROUP opt,
    p_op3 RADIOBUTTON GROUP opt.

SELECTION-SCREEN END OF BLOCK bl_opt.

SELECTION-SCREEN BEGIN OF BLOCK bl_grp WITH FRAME TITLE TEXT-004.

  PARAMETERS:
    p_g1 RADIOBUTTON GROUP grp DEFAULT 'X',
    p_g2 RADIOBUTTON GROUP grp.

SELECTION-SCREEN END OF BLOCK bl_grp.

CONSTANTS:
  gc_msgid       TYPE symsgid  VALUE 'ZWM07',
  gc_tcode       TYPE tcode    VALUE 'ZWM07',
  gc_prt_form    TYPE tdsfname VALUE 'ZWM07',
  gc_form        TYPE tdsfname VALUE 'ZWM_SF_LCVT',
  gc_logo        TYPE char50   VALUE 'ZLOGO_0001',
  gc_max_days    TYPE i        VALUE 31,
  gc_spras_vi    TYPE spras    VALUE 'V',
  gc_spras_en    TYPE spras    VALUE 'E',
  gc_tostat_canc TYPE /scwm/de_tostat VALUE 'A',
* Loại điều chuyển của Option 1 trong ZTWM_WT_OPT
  gc_loai_b2b    TYPE c LENGTH 1 VALUE 'B',
  gc_loai_ptw    TYPE c LENGTH 1 VALUE 'P',
  gc_loai_pck    TYPE c LENGTH 1 VALUE 'K',
  gc_cat_pdo     TYPE /scwm/de_doccat VALUE 'PDO',
  gc_cat_pdi     TYPE /scwm/de_doccat VALUE 'PDI',
  gc_at_lonsx    TYPE atnam    VALUE 'Z_BATCH_NSX'.

TYPES:
  gtt_r_ts TYPE RANGE OF /scwm/de_created_dt_wh,

* Dòng cấu hình ZTWM_WT_OPT của Option đang chọn
  BEGIN OF gty_opt,
    loai    TYPE c LENGTH 1,
    procty  TYPE /scwm/de_procty,
    rdoccat TYPE /scwm/de_doccat,
  END OF gty_opt,

* Một dòng WT: WT mở (không có TAPOS) hoặc một item của WT đã xác nhận
  BEGIN OF gty_wt,
    lgnum         TYPE /scwm/lgnum,
    tanum         TYPE /scwm/tanum,
    tapos         TYPE /scwm/tapos,
    who           TYPE /scwm/de_who,
    conf          TYPE abap_bool,
    procty        TYPE /scwm/de_procty,
    loai          TYPE c LENGTH 1,
    vltyp         TYPE /scwm/ltap_vltyp,
    vlpla         TYPE /scwm/ltap_vlpla,
    nltyp         TYPE /scwm/ltap_nltyp,
    nlpla         TYPE /scwm/ltap_nlpla,
    matnr         TYPE matnr,
    charg         TYPE charg_d,
    meins         TYPE meins,
    vsolm         TYPE menge_d,
    nistm         TYPE menge_d,
    created_by    TYPE /scwm/de_creator,
    created_at_wh TYPE /scwm/de_created_dt_wh,
    entitled      TYPE /scwm/de_entitled,
    cat           TYPE /scwm/de_cat,
    rdoccat       TYPE /scwm/de_doccat,
    docno         TYPE /scdl/dl_docno_int,
    prod_order    TYPE aufnr,
    werks         TYPE werks_d,
    lgort         TYPE lgort_d,
  END OF gty_wt,
  gtt_wt TYPE STANDARD TABLE OF gty_wt WITH EMPTY KEY,

  BEGIN OF gty_alv,
    sel         TYPE abap_bool,
    tanum       TYPE /scwm/tanum,
    procty      TYPE /scwm/de_procty,
    vlpla       TYPE /scwm/ltap_vlpla,
    nlpla       TYPE /scwm/ltap_nlpla,
    ref_doc     TYPE char200,
    aufnr       TYPE aufnr,
    created_by  TYPE /scwm/de_creator,
    created_on  TYPE d,
    print_count TYPE i,
    last_print  TYPE char20,
    last_user   TYPE syuname,
    lgnum       TYPE /scwm/lgnum,
    who         TYPE /scwm/de_who,
    obj_key     TYPE zewm_de_obj_key,
  END OF gty_alv,
  gtt_alv TYPE STANDARD TABLE OF gty_alv WITH EMPTY KEY,

* Một phiếu in: tập các dòng ALV được in chung
  BEGIN OF gty_sheet,
    id    TYPE i,
    alv   TYPE gtt_alv,
  END OF gty_sheet,
  gtt_sheet TYPE STANDARD TABLE OF gty_sheet WITH EMPTY KEY,

  BEGIN OF gty_det,
    tanum TYPE /scwm/tanum,
    tapos TYPE /scwm/tapos,
    stat  TYPE char20,
    vltyp TYPE /scwm/ltap_vltyp,
    vlpla TYPE /scwm/ltap_vlpla,
    nltyp TYPE /scwm/ltap_nltyp,
    nlpla TYPE /scwm/ltap_nlpla,
    matnr TYPE matnr,
    maktx TYPE maktx,
    charg TYPE charg_d,
    menge TYPE menge_d,
    meins TYPE meins,
  END OF gty_det,
  gtt_det TYPE STANDARD TABLE OF gty_det WITH EMPTY KEY,

  BEGIN OF gty_bkey,
    matnr TYPE matnr,
    charg TYPE charg_d,
  END OF gty_bkey,

  BEGIN OF gty_batch,
    matnr   TYPE matnr,
    werks   TYPE werks_d,
    charg   TYPE charg_d,
    licha   TYPE lichn,
    z_lonsx TYPE atwrt,
  END OF gty_batch,

  BEGIN OF gty_makt,
    matnr TYPE matnr,
    spras TYPE spras,
    maktx TYPE maktx,
  END OF gty_makt,

  BEGIN OF gty_auf,
    aufnr TYPE aufnr,
    matnr TYPE matnr,
  END OF gty_auf,

  BEGIN OF gty_dlv,
    vbeln     TYPE vbeln_vl,
    kunnr     TYPE kunnr,
    lifnr     TYPE lifnr,
    date_from TYPE adrc-date_from,
    name1     TYPE adrc-name1,
    name2     TYPE adrc-name2,
    name3     TYPE adrc-name3,
    name4     TYPE adrc-name4,
    kname1    TYPE kna1-name1,
    name      TYPE char255,
  END OF gty_dlv,
  gtt_dlv TYPE STANDARD TABLE OF gty_dlv WITH EMPTY KEY,

  BEGIN OF gty_lgort,
    werks TYPE werks_d,
    lgort TYPE lgort_d,
    lgobe TYPE lgobe,
  END OF gty_lgort,

  BEGIN OF gty_plant,
    werks TYPE werks_d,
    name1 TYPE name1,
    bukrs TYPE bukrs,
  END OF gty_plant,

* Plant / SLoc ERP của tồn EWM (Party entitled + loại tồn)
  BEGIN OF gty_map,
    lgnum    TYPE /scwm/lgnum,
    entitled TYPE /scwm/de_entitled,
    cat      TYPE /scwm/de_cat,
    werks    TYPE werks_d,
    lgort    TYPE lgort_d,
  END OF gty_map,

  BEGIN OF gty_wpt,
    procty TYPE /scwm/de_procty,
    lbwat  TYPE /scwm/de_desc40,
  END OF gty_wpt,

  BEGIN OF gty_partner,
    kind    TYPE char1,
    number  TYPE char10,
    name    TYPE char255,
    address TYPE char255,
    tax     TYPE char255,
    tel     TYPE char255,
    fax     TYPE char255,
    remark  TYPE char255,
  END OF gty_partner.

DATA:
  gt_opt       TYPE SORTED TABLE OF gty_opt WITH NON-UNIQUE KEY procty rdoccat,
  gt_wt        TYPE SORTED TABLE OF gty_wt WITH NON-UNIQUE KEY tanum tapos,
  gt_alv       TYPE gtt_alv,
  gt_data      TYPE STANDARD TABLE OF zwm_st_lcvt,
  gs_parameter TYPE zcore_st_parameter,
  gt_batch     TYPE SORTED TABLE OF gty_batch WITH NON-UNIQUE KEY matnr charg werks,
  gt_makt      TYPE HASHED TABLE OF gty_makt WITH UNIQUE KEY matnr spras,
  gt_auf       TYPE HASHED TABLE OF gty_auf WITH UNIQUE KEY aufnr,
  gt_dlv       TYPE HASHED TABLE OF gty_dlv WITH UNIQUE KEY vbeln,
  gt_lgort     TYPE HASHED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
  gt_plant     TYPE HASHED TABLE OF gty_plant WITH UNIQUE KEY werks,
  gt_map       TYPE HASHED TABLE OF gty_map WITH UNIQUE KEY lgnum entitled cat,
  gt_wpt       TYPE HASHED TABLE OF gty_wpt WITH UNIQUE KEY procty,
  gt_partner   TYPE HASHED TABLE OF gty_partner WITH UNIQUE KEY kind number,
  gv_opt       TYPE c LENGTH 1,
  gv_lgnum_txt TYPE /scwm/de_desc40,
  gv_msg_init  TYPE abap_bool,
  go_map       TYPE REF TO /scwm/if_stockid_mapping,
  go_alv       TYPE REF TO cl_salv_table.
