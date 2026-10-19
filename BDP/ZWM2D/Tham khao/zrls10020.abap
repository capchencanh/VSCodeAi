report zrls10020 line-size 132 message-id l1 no standard page heading.

*........Tables.........................................................
tables: lagp,                          " Storage bins
        lqua,                          " Quants
        rlist,                         " Fields for WM lists
        mlvs,                          " Mat. Master View
        mtcom,                         " Material Master Communication
        mtcor,                         "  Return Codes
        rl01s,                         " I/O fields (SAPML01S)
        makt,                          " Material Descriptions
*{INSERT FES ABAPLEADER DUYEN -27.02.15
        mara,
*INSERT}
        rl030_unique.                  " Unique fields lagp & lqua.

*........Constants......................................................
data:
       pf_status       like sy-pfkey value 'STANDARD_ALV_NO_CHG',
       con_title(3)    type c value '001',
       sav_matnr       like mlvs-matnr,
       sav_werks       like lqua-werks,
       sav_index       like sy-index.

data:  sav_repid           like sy-repid.
"22.06.2019 vuhvt
TYPES:

      BEGIN OF GTY_EKPO,
         EBELN TYPE EBELN,
        TXZ01 TYPE TXZ01,
        MATNR TYPE MATNR,
       END OF GTY_EKPO,




       BEGIN OF GTY_MSEG,
         MBLNR TYPE MBLNR,
         EBELN TYPE EBELN,
         MATNR TYPE MATNR,
       END OF GTY_MSEG.


DATA:
*      GT_ITEM              TYPE TABLE OF ZSD_ST_BCPBHDT,
*      GS_ITEM              TYPE          ZSD_ST_BCPBHDT,

     GT_EKPO              TYPE TABLE OF GTY_EKPO,
     GS_EKPO              TYPE          GTY_EKPO,

         GT_MSEG              TYPE TABLE OF GTY_MSEG,
         GS_MSEG              TYPE          GTY_MSEG.
"end 22.06.2019 vuhvt

*.........General declarations for use of ALV...........................
type-pools: slis.

data: xfield      type slis_t_fieldcat_alv,
      afield      type slis_fieldcat_alv,
      xheader     type slis_t_listheader with header line,
      xevents     type slis_t_event,
      ls_event    type slis_alv_event,
      gt_extab    type slis_t_extab with header line,
      gt_sp_group type slis_t_sp_group_alv,
      variant     like disvariant,
      c_variant   like disvariant,
      layout      type slis_layout_alv,
      a_save      type c value 'A',
      rs_selfield type slis_selfield,
      sonum       LIKE lqua-sonum,                           "n_819153
      sav_colno   type slis_sel_tab_field.

*........mllvskon.......................................................
INCLUDE ZMLLVSKON.
*include mllvskon.

*........Internal Tables................................................

data:  begin of dum_tab occurs 1,
         dumdum(1) type c,
      end of dum_tab.

data:  begin of mat occurs 1.
        include structure mlvs.
data:  end of mat.

data:   begin of lt_lagplqua occurs 0.
        include structure rl030_unique.
data:   lsonr like rl01s-lsonr,
***{INSERT FES ABAPLEADER DUYEN 27.02.15
****Content: add Material group selection
**        matkl like mara-matkl,
***INSERT}
***{INSERT FES ABAPLEADER DUYNC4 09.09.15
****Content: add FIELD QUY DOI
        QUYDOI TYPE CHAR255,
***INSERT}
        idatu_q like lqua-idatu,                 "n_686284

  "Vuhvt 22.06.2019
        EBELN Type   EKPO-EBELN,
         TXZ01 Type   EKPO-TXZ01.
data:  end of lt_lagplqua.

*........Select-Options and Parameter..................................
selection-screen skip 1.
selection-screen  begin of block xxx with frame title text-100.
select-options:  werks for lqua-werks,
*{INSERT FES ABAPLEADER DUYEN 27.02.15
**Content: add Material group selection
                 matkl for mara-matkl,
*INSERT}
                 wdatu for lqua-wdatu,
                 bestq for lqua-bestq.
Parameters:      sobkz type lqua-sobkz.                     "n_819153
Parameters:      lsonr type rl01s-lsonr.                    "n_819153
selection-screen end of block xxx.
selection-screen skip 1.
parameters:    p_vari like disvariant-variant.

*---------------------------------------------------------------------*
*        INITIALIZATION                                               *
*---------------------------------------------------------------------*
initialization.

  set titlebar '002'.

*---------------------------------------------------------------------*
*        AT SELECTION SCREEN ON VALUE-REQUEST                         *
*---------------------------------------------------------------------*
at selection-screen on value-request for p_vari.
  perform f4_for_variant.

*---------------------------------------------------------------------*
*        AT SELECTION SCREEN                                          *
*---------------------------------------------------------------------*
at selection-screen.
  perform check_variant_existence.

*---------------------------------------------------------------------*
*        START-OF-SELECTION                                           *
*---------------------------------------------------------------------*
start-of-selection.
  move sy-repid to sav_repid.

*---------------------------------------------------------------------*
*        GET LAGP                                                     *
*---------------------------------------------------------------------*
get lagp.

*---------------------------------------------------------------------*
*        GET LQUA                                                     *
*---------------------------------------------------------------------*
get lqua.


*..........Check special stock number .................................
  if not sobkz is initial.                                 "v_n_819153
    check lqua-sobkz = sobkz.
  endif.
  if not lsonr is initial.
    perform sonum_conv_ext_int(sapfl000) using sobkz
                                             lsonr
                                             sonum.
    check lqua-sonum = sonum.
  endif.                                                   "^_n_819153

*.....................................................................*
*        MOVE-CORRESPONDING                                           *
*.....................................................................*
  move-corresponding lagp to lt_lagplqua.
  move-corresponding lqua to lt_lagplqua.
  move: lagp-btanr to lt_lagplqua-btanr_b,
        lqua-btanr to lt_lagplqua-btanr_q,
        lagp-idatu to lt_lagplqua-idatu,           "n_686284
        lqua-idatu to lt_lagplqua-idatu_q.         "n_686284

  if ( lt_lagplqua-matnr ne sav_matnr )
       or  ( lt_lagplqua-werks ne sav_werks ).

*........Material description retrieval ................................

    perform mlvs_lesen using lt_lagplqua-matnr
                             lt_lagplqua-werks
                             lt_lagplqua-lgnum.
    move lt_lagplqua-matnr to sav_matnr.
    move lt_lagplqua-werks to sav_werks.
    move mlvs-maktx to lt_lagplqua-maktx.

  else.
    clear mlvs-maktx.
  endif.

  if lqua-sobkz = sobkz_projekt.  "Sonderbestand Q
    perform sonum_conv_int_ext(sapfl000) using lqua-sobkz
                                               lqua-sonum
                                               lt_lagplqua-lsonr.
  else.
    move lqua-sonum to lt_lagplqua-lsonr.
  endif.

  append lt_lagplqua.

  check select-options.

*........When Position in storage bin assigned..........................
  if lqua-plpos ne space.
    call function 'L_PLATZ_POSITION_MISCHEN'
         exporting
              lgpla   = lqua-lgpla
              plpos   = lqua-plpos
         importing
              o_lgpla = lqua-lgpla.
  endif.

end-of-selection.



  perform list_header.                 "  Show the list's header

  sort lt_lagplqua by matnr.           "  Sorting by material desc.

*.......ALV events and subroutines......................................

  perform special_group using gt_sp_group[]. " Grouping fieldcat.

  perform define_events using xevents[].     " Define ALV events

  perform define_layout using layout.  " Screens format

  perform build_fieldcat.              " Build field catalog

  perform variant_init.                " Sends variant to ALV

  perform call_alv.                    " Execute ALV function


************************************************************************
*                 FORMS
************************************************************************
*---------------------------------------------------------------------*
*        AT USER_COMMAND                                              *
*---------------------------------------------------------------------*
at user-command.
*.......Dynamic call from the ALV.......................................
form user_command  using r_ucomm like sy-ucomm
                   rs_selfield type slis_selfield. "#EC CALLED

  sav_index = rs_selfield-tabindex.    "Line in list
  sav_colno =  rs_selfield-sel_tab_field.        "Column header

  if sav_index le 0.
*........Position the cursor on a line in the list......................
    message e004(0k).
  endif.
  read table lt_lagplqua index sav_index.

  case sav_colno.
*........Quant display.................................................*
    when 'LT_LAGPLQUA-MATNR'.
      call function 'L_QUANT_DISPLAY'
           exporting
                i_lgnum = lt_lagplqua-lgnum
                i_lqnum = lt_lagplqua-lqnum.
*........storage bin display............................................
    when  'LT_LAGPLQUA-LGPLA'.
      call function 'L_BIN_DISPLAY'
           exporting
                i_lgnum = lt_lagplqua-lgnum
                i_lgtyp = lt_lagplqua-lgtyp
                i_lgpla = lt_lagplqua-lgpla.
*........Batch Display.................................................*
    when 'LT_LAGPLQUA-CHARG'.
      call function 'L_BATCH_DISPLAY'
           exporting
                i_matnr = lt_lagplqua-matnr
                i_werks = lt_lagplqua-werks
                i_charg = lt_lagplqua-charg.
*........Storage unit display..........................................*
    when 'LT_LAGPLQUA-LENUM'.
      call function 'L_SU_DISPLAY'
           exporting
                i_lenum = lt_lagplqua-lenum.
*........Transfer requirement display..................................*
    when 'LT_LAGPLQUA-TBNUM'.
      call function 'L_TR_DISPLAY'
           exporting
                i_lgnum = lt_lagplqua-lgnum
                i_tbnum = lt_lagplqua-tbnum.
*........Transfer order display (lqua).................................*
    when 'LT_LAGPLQUA-BTANR_Q'.
      call function 'L_TO_DISPLAY'
           exporting
                i_lgnum = lt_lagplqua-lgnum
                i_tanum = lt_lagplqua-btanr_q.
*........Transfer order display (lagp).................................*
    when 'LT_LAGPLQUA-BTANR_B'.
      call function 'L_TO_DISPLAY'
           exporting
                i_lgnum = lt_lagplqua-lgnum
                i_tanum = lt_lagplqua-btanr_b.

  endcase.
endform.

*......................................................................*
*       Form define_events                                             *
*......................................................................*
form define_events using xevents type slis_t_event.
  call function 'REUSE_ALV_EVENTS_GET'
       exporting
            i_list_type = 0
       importing
            et_events   = xevents.

*........Add event TOP-OF-PAGE .........................................
  read table xevents with key name = slis_ev_top_of_page
                          into ls_event.
  if sy-subrc = 0.
    move slis_ev_top_of_page to ls_event-form.
    append ls_event to xevents.
  endif.

*........Add event AT-USER-COMMAND .....................................
  read table xevents with key name = slis_ev_user_command
                          into ls_event.
  if sy-subrc = 0.
    move slis_ev_user_command to ls_event-form.
    append ls_event to xevents.
  endif.

endform.                               " DEFINE_EVENTS
*---------------------------------------------------------------------*
*      Form  DEFINE_LAYOUT                                            *
*---------------------------------------------------------------------*
form define_layout using p_layout type slis_layout_alv.

  p_layout-group_change_edit = 'X'.
  p_layout-detail_popup = 'X'.

endform.                               " DEFINE_LAYOUT
*---------------------------------------------------------------------*
*      Form  SPECIAL_GROUP                                            *
*---------------------------------------------------------------------*
*      Feldgruppen definieren                                         *
*      Defines groups in the field catalog                            *
*---------------------------------------------------------------------*
*     -->LT_SP_GROUP[]  Feldgruppentexte                              *
*---------------------------------------------------------------------*
form special_group using lt_sp_group type slis_t_sp_group_alv.
  data: ls_sp_group type slis_sp_group_alv.

  clear ls_sp_group.
  ls_sp_group-sp_group = 'P'.
  ls_sp_group-text = text-011.
  append ls_sp_group to lt_sp_group.

  clear ls_sp_group.
  ls_sp_group-sp_group = 'Q'.
  ls_sp_group-text = text-012.
  append ls_sp_group to lt_sp_group.

endform.                               " SPECIAL_GROUP

*---------------------------------------------------------------------*
*       FORM CALL_ALV                                                 *
*---------------------------------------------------------------------*
form call_alv.
*{INSERT FES ABAPLEADER DUYEN 27.02.15
**Content: add Material group selection
RANGES: LR_MATNR FOR MARA-MATNR.
IF lt_lagplqua[] is not INITIAL and MATKL[] is not INITIAL.
   SELECT MARA~MATNR AS LOW
     INTO CORRESPONDING FIELDS OF TABLE LR_MATNR
   FROM  MARA
     FOR ALL ENTRIES IN lt_lagplqua
   WHERE
     MARA~MATNR = lt_lagplqua-MATNR
     AND MARA~MATKL IN MATKL.



  LOOP AT LR_MATNR.
    LR_MATNR-SIGN = 'I'.
    LR_MATNR-OPTION = 'EQ'.
    MODIFY LR_MATNR INDEX sy-tabix.
  ENDLOOP.
  IF LR_MATNR[] IS NOT INITIAL.
    "Remove record not match material group
    DELETE lt_lagplqua WHERE MATNR not in LR_MATNR.
  ENDIF.
ENDIF.
*INSERT}

*{INSERT FES ABAPLEADER DUYNC4 09.09.15
**Content: add column "quy doi"
TYPES: BEGIN OF LTY_MARM,
        MATNR TYPE MATNR,
        UMREZ TYPE UMREZ,
        UMREN TYPE UMREN,
        MSEH6 TYPE MSEH6,
        MEINH TYPE LRMEI,
       END OF   LTY_MARM.

DATA: LW_QUYDOI      TYPE          P DECIMALS 7,
      LW_COUNT       TYPE          INT4,
      LW_VIEN        TYPE          P DECIMALS 7,
      LW_TABIX       TYPE          SY-TABIX,
      LW_QUYDOI_CHAR TYPE          CHAR255,
      LW_CHECK_AM    TYPE          CHAR1,

      LT_PRE_MARM    TYPE TABLE OF LTY_MARM WITH HEADER LINE,
      LT_MARM        TYPE TABLE OF LTY_MARM WITH HEADER LINE.

IF lt_lagplqua[] is not INITIAL.
  SELECT
    MARM~MATNR
    MARM~UMREZ
    MARM~UMREN
    T006A~MSEH6
    MARM~MEINH
  INTO TABLE LT_MARM
  FROM MARM INNER JOIN T006A ON MARM~MEINH EQ T006A~MSEHI
  FOR ALL ENTRIES IN lt_lagplqua
  WHERE MARM~MATNR  EQ lt_lagplqua-MATNR
    AND T006A~SPRAS EQ SY-LANGU.

  SORT LT_MARM BY MATNR UMREZ DESCENDING UMREN ASCENDING.

       "22.06.2019 VuhVT
 SELECT MSEG~MBLNR
        MSEG~EBELN
        MSEG~MATNR
     INTO CORRESPONDING FIELDS OF TABLE GT_MSEG
   FROM  MSEG
     FOR ALL ENTRIES IN lt_lagplqua
   WHERE
     MSEG~MBLNR = lt_lagplqua-WENUM.

    SELECT
        EKPO~EBELN
        EKPO~MATNR
        EKPO~TXZ01
     INTO CORRESPONDING FIELDS OF TABLE GT_EKPO
   FROM  EKPO
     FOR ALL ENTRIES IN GT_MSEG
   WHERE
     EKPO~EBELN = GT_MSEG-EBELN.
     "end 22.06.2019 VuHVT


  LOOP AT lt_lagplqua.
    LW_TABIX = SY-TABIX.

    IF lt_lagplqua-VERME EQ 0.
      lt_lagplqua-QUYDOI = '0'.
    ELSE.
      LT_PRE_MARM[] = LT_MARM[].
      DELETE LT_PRE_MARM[] WHERE MATNR NE lt_lagplqua-MATNR.

      IF lt_lagplqua-VERME LE 0.
        lt_lagplqua-VERME = lt_lagplqua-VERME * -1.

        LW_CHECK_AM = 'X'.
      ENDIF.

      LW_VIEN = lt_lagplqua-VERME.

      DESCRIBE TABLE LT_PRE_MARM LINES LW_COUNT.

      DO LW_COUNT TIMES.
        READ TABLE LT_PRE_MARM INDEX SY-INDEX.
        IF SY-SUBRC EQ 0 AND LW_VIEN IS NOT INITIAL.
          LW_QUYDOI = LW_VIEN * LT_PRE_MARM-UMREN / LT_PRE_MARM-UMREZ.

          LW_QUYDOI = FLOOR( LW_QUYDOI ).

          IF SY-INDEX EQ 1.
            LW_VIEN = lt_lagplqua-VERME - ( LW_QUYDOI * LT_PRE_MARM-UMREZ / LT_PRE_MARM-UMREN ).
          ELSE.
            LW_VIEN = LW_VIEN - ( LW_QUYDOI * LT_PRE_MARM-UMREZ / LT_PRE_MARM-UMREN ).
          ENDIF.

          WRITE LW_QUYDOI TO LW_QUYDOI_CHAR DECIMALS 0 LEFT-JUSTIFIED.

          IF LW_QUYDOI_CHAR NE '0'.
            CONCATENATE lt_lagplqua-QUYDOI LW_QUYDOI_CHAR LT_PRE_MARM-MSEH6 INTO lt_lagplqua-QUYDOI SEPARATED BY SPACE.

            CONDENSE lt_lagplqua-QUYDOI.
          ENDIF.
        ENDIF.
      ENDDO.

      IF LW_CHECK_AM IS NOT INITIAL.
        CONCATENATE '-' lt_lagplqua-QUYDOI INTO lt_lagplqua-QUYDOI.

        lt_lagplqua-VERME = lt_lagplqua-VERME * -1.
      ENDIF.

      CLEAR LW_CHECK_AM.
    ENDIF.

       "22.06.2019 VuhVT lay ten tu PO
          READ TABLE GT_MSEG INTO GS_MSEG WITH KEY MBLNR = lt_lagplqua-WENUM.
      IF SY-SUBRC EQ 0.
         lt_lagplqua-EBELN = GS_MSEG-EBELN. "dien them thong tin ship to
          READ TABLE GT_EKPO INTO GS_EKPO WITH KEY EBELN = lt_lagplqua-EBELN MATNR = lt_lagplqua-MATNR.
          IF SY-SUBRC EQ 0.
              lt_lagplqua-MAKTX = GS_EKPO-TXZ01.
           ENDIF.

      ENDIF.


       "end 22.06.2019 VuhVT
    MODIFY lt_lagplqua INDEX LW_TABIX.
  ENDLOOP.
ENDIF.
*INSERT}

  call function 'REUSE_ALV_LIST_DISPLAY'
      exporting
*             I_INTERFACE_CHECK        = ' '
              i_callback_program       = sav_repid
              i_callback_pf_status_set = 'SET_PF_STATUS'
*             I_CALLBACK_USER_COMMAND  = ' '
*             i_structure_name         = ''
              is_layout                = layout
              it_fieldcat              = xfield
              it_excluding             = gt_extab[]
              it_special_groups        = gt_sp_group[]
*             IT_SORT                  =
*             IT_FILTER                =
*             is_sel_hide              =
              i_default                = 'X'
              i_save                   = 'A'
              is_variant               = variant
              it_events                =  xevents[]
*             IT_EVENT_EXIT            =
*             IS_PRINT                 =
*             IS_REPREP_ID             =
*             I_SCREEN_START_COLUMN    = 0
*             I_SCREEN_START_LINE      = 0
*             I_SCREEN_END_COLUMN      = 0
*             I_SCREEN_END_LINE        = 0
*        importing
*             E_EXIT_CAUSED_BY_CALLER  =
*             ES_EXIT_CAUSED_BY_USER   =
       tables
            t_outtab                 = lt_lagplqua

      exceptions
           program_error            = 1
           others                   = 2.

  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
endform.

*&---------------------------------------------------------------------*
*&      Form  SET_PF_STATUS
*&---------------------------------------------------------------------*
*       Sets PF-STATUS
*----------------------------------------------------------------------*
*  -->  p1        extab
*----------------------------------------------------------------------*
form set_pf_status using extab type slis_t_extab. "#EC CALLED

  set pf-status pf_status excluding extab.
  set titlebar con_title.

endform.                               " SET_PF_STATUS

*---------------------------------------------------------------------*
*      Form  F4_FOR_VARIANT                                           *
*---------------------------------------------------------------------*
form f4_for_variant.

  data: i_variant like disvariant,
        e_variant like disvariant.

  i_variant-report = sy-repid.

  call function 'REUSE_ALV_VARIANT_F4'
       exporting
            is_variant          = i_variant
            i_save              = a_save
*           i_tabname_header    =
*           i_tabname_item      =
*           it_default_fieldcat =
       importing
*           e_exit              =
            es_variant          = e_variant
       exceptions
            not_found = 2.

  if sy-subrc = 2.
    message s205(0k).
  else.
    p_vari = e_variant-variant.
  endif.
endform.                               " F4_FOR_VARIANT

*---------------------------------------------------------------------*
*      Form  CHECK_VARIANT_EXISTENCE                                  *
*---------------------------------------------------------------------*
form check_variant_existence.

  if not p_vari is initial.
    move: p_vari  to c_variant-variant,
          sy-repid to c_variant-report.

    call function 'REUSE_ALV_VARIANT_EXISTENCE'
         exporting
              i_save     = a_save
         changing
              cs_variant = c_variant.
*        exceptions
*             wrong_input   = 1
*             not_found     = 2
*             program_error = 3
*             others        = 4.
  endif.

endform.                               " CHECK_VARIANT_EXISTENCE
*---------------------------------------------------------------------*
*      Form  VARIANT_INIT                                             *
*---------------------------------------------------------------------*
*      variant instalation                                            *
*---------------------------------------------------------------------*
form variant_init.

  clear variant.
  variant-report = sy-repid.

  if not p_vari is initial.
    move p_vari to variant-variant.
  endif.

endform.                               " VARIANT_INIT
*---------------------------------------------------------------------*
*      Form  LIST_HEADER                             *
*---------------------------------------------------------------------*
*      Informationen für den Listkopf aufbauen                        *
*      Information for list header                                    *
*---------------------------------------------------------------------*
form list_header.

  refresh xheader.
  clear xheader.

*........Selektionsinfo................................................
  xheader-typ  = 'S'.
  xheader-key  = text-015.
  xheader-info = s1_lgnum.
  append xheader.

  clear xheader.
  xheader-typ = 'H'.
  xheader-info = sy-title.
  append xheader.

endform.                               " LIST_HEADER

*---------------------------------------------------------------------*
*        TOP-OF-PAGE                                                  *
*---------------------------------------------------------------------*
form top_of_page.                      "#EC CALLED

  call function 'REUSE_ALV_COMMENTARY_WRITE'
       exporting
            it_list_commentary = xheader[].

endform.

*---------------------------------------------------------------------*
*       FORM MLVS_LESEN                                               *
*---------------------------------------------------------------------*
*       Lesen eines MLVS-Satzes                                       *
*       Einlesen des MLVS-Satzes in die interne Tabelle MAT           *
*       Verzweigung nach MEI_SCHREIBEN.                               *
*       Material retrieval                                            *
*---------------------------------------------------------------------*
*       VALUE(PAR_MATNR)    Materialnummer .   Material number        *
*       VALUE(PAR_WERKS)    Werk           .   Plant                  *
*       VALUE(PAR_LGNUM)    Lagernummer    .   Whse number            *
*---------------------------------------------------------------------*
form mlvs_lesen using value(p_matnr)
                      value(p_werks)
                      value(p_lgnum).
  clear mtcom.
  move: con_mlvs   to mtcom-kenng,
        p_matnr    to mtcom-matnr,
        sy-langu   to mtcom-spras.

  call function 'MATERIAL_READ'
       exporting
            schluessel = mtcom
       importing
            matdaten   = mlvs
            return     = mtcor
       tables
            seqmat01   = dum_tab.
  mat = mlvs.
  append mat.

endform.

*---------------------------------------------------------------------*
*      Form  BUILD_FIELDCAT                                           *
*---------------------------------------------------------------------*
form build_fieldcat.

  refresh xfield.

*........Material.......................................................
  clear afield.
  afield-fieldname = 'MATNR'.
  afield-ref_tabname = 'LQUA'.
  afield-key = 'X'.
  afield-hotspot = 'X'.
  append afield to xfield.
*.......Plant...........................................................
  clear afield.
  afield-fieldname = 'WERKS'.
  afield-ref_tabname = 'LQUA'.
  append afield to xfield.
*.......Storage location................................................
  clear afield.
  afield-fieldname = 'LGORT'.
  afield-ref_tabname = 'LQUA'.
  append afield to xfield.

*.......Stock category in the Warehouse Management system...............
  clear afield.
  afield-fieldname = 'BESTQ'.
  afield-ref_tabname = 'LQUA'.
  append afield to xfield.
*.......Batch number...................................................
  clear afield.
  afield-fieldname = 'CHARG'.
  afield-ref_tabname = 'LQUA'.
  afield-hotspot = 'X'.
  append afield to xfield.
*.......Batch number...................................................
  clear afield.
  afield-fieldname = 'SOBKZ'.
  afield-ref_tabname = 'LQUA'.
  append afield to xfield.
*.......special stock number............................................
  clear afield.
  afield-fieldname = 'LSONR'.
  afield-ref_tabname = 'RL01S'.
  append afield to xfield.
*.......Material description...........................................
  clear afield.
  afield-fieldname = 'MAKTX'.
  afield-ref_tabname = 'MLVS'.
  append afield to xfield.
*.......Storage type...................................................
  clear afield.
  afield-fieldname = 'LGTYP'.
  afield-ref_tabname = 'LQUA'.
  afield-no_sum = 'X'.
  append afield to xfield.
*.......Storage bin....................................................
  clear afield.
  afield-fieldname = 'LGPLA'.
  afield-ref_tabname = 'LQUA'.
  afield-hotspot = 'X'.
  append afield to xfield.
*.......Available stock................................................
  clear afield.
  afield-fieldname = 'VERME'.
  afield-ref_tabname = 'LQUA'.
  afield-qfieldname = 'MEINS'.
  append afield to xfield.
*.......Base unit of measure...........................................
  clear afield.
  afield-fieldname = 'MEINS'.
  afield-ref_tabname = 'LQUA'.
  append afield to xfield.
*.......QUY DOI...........................................
  "DUYNC4 09.09.15
  clear afield.
  afield-fieldname = 'QUYDOI'.
  afield-tabname = 'LT_LAGPLQUA'.
  afield-seltext_m = 'Quy Đổi'.
  AFIELD-OUTPUTLEN = 30.
  append afield to xfield.
  "END UPDATE
*.......Date of goods receipt..........................................
  clear afield.
  afield-fieldname = 'WDATU'.
  afield-ref_tabname = 'LQUA'.
  append afield to xfield.

*---------------------------------------------------------------------*
*        2. potential fields to select  (LQUA)                        *
*---------------------------------------------------------------------*

*........Capacity usage of quant........................................
  clear afield.
  afield-fieldname = 'VFDAT'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Position in storage bin........................................
  clear afield.
  afield-fieldname = 'PLPOS'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Total quantity.................................................
  clear afield.
  afield-fieldname = 'GESME'.
  afield-ref_tabname = 'LQUA'.
  afield-qfieldname = 'MEINS'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Transfer order number of last stock transfer (lqua)............
  clear afield.
  afield-fieldname = 'BTANR_Q'.
  afield-tabname = 'LT_LAGPLQUA'.
  afield-ref_tabname = 'LTAP'.               "n_1567315
  afield-ref_fieldname = 'TANUM'.            "n_1567315
  afield-no_out = 'X'.
  afield-seltext_m = text-001.
  afield-hotspot = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Blocking indicator: for putaways (user)........................
  clear afield.
  afield-fieldname = 'SKZUE'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Blocking indicator: for stock removals (user)..................
  clear afield.
  afield-fieldname = 'SKZUA'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Blocking indicator: current placement into stock (system)......
  clear afield.
  afield-fieldname = 'SKZSE'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Blocking indicator: current stock removal (system).............
  clear afield.
  afield-fieldname = 'SKZSA'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Blocking indicator: current inventory (system).................
  clear afield.
  afield-fieldname = 'SKZSI'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Blocking reason................................................
  clear afield.
  afield-fieldname = 'SPGRU'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Certificate number.............................................
  clear afield.
  afield-fieldname = 'ZEUGN'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Date of last movement..........................................
  clear afield.
  afield-fieldname = 'BDATU'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Time of last movement..........................................
  clear afield.
  afield-fieldname = 'BZEIT'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Item in transfer order of last stock transfer..................
  clear afield.
  afield-fieldname = 'BTAPS'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Date of last placement into stock..............................
  clear afield.
  afield-fieldname = 'EDATU'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Time of last placement into stock..............................
  clear afield.
  afield-fieldname = 'EZEIT'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Date of last stock removal.....................................
  clear afield.
  afield-fieldname = 'ADATU'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Time of last stock removal.....................................
  clear afield.
  afield-fieldname = 'AZEIT'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Date of last addition to existing stock........................
  clear afield.
  afield-fieldname = 'ZDATU'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Goods receipt number...........................................
  clear afield.
  afield-fieldname = 'WENUM'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Goods receipt item.............................................
  clear afield.
  afield-fieldname = 'WEPOS'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Storage unit type..............................................
  clear afield.
  afield-fieldname = 'LETYP'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*.......Quantity to be placed into stock................................
  clear afield.
  afield-fieldname = 'EINME'.
  afield-ref_tabname = 'LQUA'.
  afield-qfieldname = 'MEINS'.
  afield-no_out = 'X'.
  append afield to xfield.
*........Quantity to be removed from stock..............................
  clear afield.
  afield-fieldname = 'AUSME'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-qfieldname = 'MEINS'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Weight of material.............................................
  clear afield.
  afield-fieldname = 'MGEWI'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Transfer requirement number....................................
  clear afield.
  afield-fieldname = 'TBNUM'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-hotspot = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Weight unit....................................................
  clear afield.
  afield-fieldname = 'GEWEI'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Number of system inventory record..............................
  clear afield.
  afield-fieldname = 'IVNUM'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Item number in inventory document..............................
  clear afield.
  afield-fieldname = 'IVPOS'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Requirement type...............................................
  clear afield.
  afield-fieldname = 'BETYP'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Requirement number.............................................
  clear afield.
  afield-fieldname = 'BENUM'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Storage unit number............................................
  clear afield.
  afield-fieldname = 'LENUM'.
  afield-ref_tabname = 'LQUA'.
  afield-hotspot = 'X'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*........Inspection lot number..........................................
  clear afield.
  afield-fieldname = 'QPLOS'.
  afield-ref_tabname = 'LQUA'.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.
*.......Date of last inventory for this quant ............."v_n_686284
  clear afield.
  afield-fieldname = 'IDATU_Q'.
  afield-tabname = 'LT_LAGPLQUA'.
  afield-ref_tabname = 'LINV'.               "n_1567315
  afield-ref_fieldname = 'IDATU'.            "n_1567315
  afield-seltext_m = text-003.
  afield-no_out = 'X'.
  afield-sp_group = 'Q'.
  append afield to xfield.                                 "^_n_686284

*---------------------------------------------------------------------*
*        3. potential fields to select  (LAGP)                        *
*---------------------------------------------------------------------*

*........Storage section................................................
  clear afield.
  afield-fieldname = 'LGBER'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Storage bin type...............................................
  clear afield.
  afield-fieldname = 'LPTYP'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Section of a storage bin.......................................
  clear afield.
  afield-fieldname = 'PLAUF'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Number of quants in storage bin................................
  clear afield.
  afield-fieldname = 'ANZQU'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Maximum number of quants in storage bin........................
  clear afield.
  afield-fieldname = 'MAXQU'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Number of storage units in storage bin.........................
  clear afield.
  afield-fieldname = 'ANZLE'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Maximum number of storage units in storage bin.................
  clear afield.
  afield-fieldname = 'MAXLE'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Indicator: dynamic storage bin..................................
  clear afield.
  afield-fieldname = 'KZDYN'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Load capacity of storage bin....................................
  clear afield.
  afield-fieldname = 'LGEWI'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Date of last bin clearing.......................................
  clear afield.
  afield-fieldname = 'RDATU'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Time of last clearing...........................................
  clear afield.
  afield-fieldname = 'RZEIT'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Inventory method...............................................
  clear afield.
  afield-fieldname = 'KZINV'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Date of last inventory for this storage bin.....................
  clear afield.
  afield-fieldname = 'IDATU'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Inventory in preparation.......................................
  clear afield.
  afield-fieldname = 'IVIVO'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  append afield to xfield.
*.......Indicator whether storage bin is empty..........................
  clear afield.
  afield-fieldname = 'KZLER'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Indicator whether storage bin is full..........................
  clear afield.
  afield-fieldname = 'KZVOL'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Sort field for storage bin (cross-line storage)................
  clear afield.
  afield-fieldname = 'SORLP'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Fire-containment section.......................................
  clear afield.
  afield-fieldname = 'BRAND'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*......Last changed by..................................................
  clear afield.
  afield-fieldname = 'UNAME'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Date of last change.............................................
  clear afield.
  afield-fieldname = 'LAEDT'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Total capacity of storage bin..................................
  clear afield.
  afield-fieldname = 'LKAPV'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Available capacity in storage bin..............................
  clear afield.
  afield-fieldname = 'RKAPV'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Picking area...................................................
  clear afield.
  afield-fieldname = 'KOBER'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Sort field for storage bin (TO items, picking)..................
  clear afield.
  afield-fieldname = 'REIHF'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*.......Verification field for mobile data entry........................
  clear afield.
  afield-fieldname = 'VERIF'.
  afield-ref_tabname = 'LAGP'.
  afield-no_out = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.
*........Transfer order number of last stock transfer (lagp)............
  clear afield.
  afield-fieldname = 'BTANR_B'.
  afield-tabname = 'LT_LAGPLQUA'.
  afield-ref_tabname = 'LTAP'.               "n_1567315
  afield-ref_fieldname = 'TANUM'.            "n_1567315
  afield-no_out = 'X'.
  afield-seltext_m = text-002.
  afield-hotspot = 'X'.
  afield-sp_group = 'P'.
  append afield to xfield.

endform.

*GUI Texts
*----------------------------------------------------------
* 001 --> WM-Bestände mit Materialkurztext
* 002 --> WM-Bestände: Einstiegsbild
* 001 --> WM Stock with Material Description
* 002 --> WM Stock: Initial Screen

*Text elements
*----------------------------------------------------------
* 001 TO (Quant)
* 002 TO (Bin)
* 003 Lst Inv.Q.
* 011 Bin Data
* 012 Quant Data
* 015 Warehouse Number
* 100 Program Parameters
* 101 Stor.Loc


*Selection texts
*----------------------------------------------------------
* BESTQ         Stock Category
* LSONR         Special Stock Number
* MATKL         Material Group
* P_VARI         Layout
* SOBKZ         Special Stock Indicator
* WDATU         Goods Receipt Date
* WERKS         Plant


*Messages
*----------------------------------------------------------
*
* Message class: 0K
*004   Position the cursor on a line in the list
*205   No selection

*
* 
