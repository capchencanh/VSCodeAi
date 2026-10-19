*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PNK_F01
*&---------------------------------------------------------------------*

CLASS lcl_util IMPLEMENTATION.

  METHOD lbl.
    rv_text = COND #( WHEN p_isn = abap_true AND iv_en IS NOT INITIAL
                      THEN |{ iv_vi }/ { iv_en }|
                      ELSE iv_vi ).
  ENDMETHOD.

  METHOD lbl_c.
    rv_text = |{ lbl( iv_vi = iv_vi iv_en = iv_en ) }:|.
  ENDMETHOD.

  METHOD date_text.
    CHECK iv_date IS NOT INITIAL.
    rv_text = |{ iv_date+6(2) }/{ iv_date+4(2) }/{ iv_date(4) }|.
  ENDMETHOD.

  METHOD num_text.
    rv_text = |{ iv_val DECIMALS = iv_dec }|.
    IF rv_text CS '.'.
      rv_text = replace( val = rv_text pcre = '0+$' with = `` ).
      rv_text = replace( val = rv_text pcre = '\.$' with = `` ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_function.
    CASE e_salv_function.
      WHEN 'PREV'.
        PERFORM print_docs USING abap_true.
      WHEN 'PRINT'.
        PERFORM print_docs USING abap_false.
      WHEN 'SELALL'.
        PERFORM select_all.
      WHEN 'DETAIL'.
        PERFORM show_adjust.
      WHEN 'EXCEL'.
        PERFORM export_excel.
    ENDCASE.
  ENDMETHOD.

  METHOD on_click.
    CHECK column = 'SEL'.
    READ TABLE gt_alv ASSIGNING FIELD-SYMBOL(<lfs_alv>) INDEX row.
    CHECK sy-subrc = 0.
    <lfs_alv>-sel = xsdbool( <lfs_alv>-sel = abap_false ).
    go_alv->refresh( ).
  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*&      Form  CHECK_CONDITION
*&---------------------------------------------------------------------*
*       Không nhập Chứng từ kho: bắt buộc Ngày hạch toán, tối đa 31 ngày.
*----------------------------------------------------------------------*
FORM check_condition .

  DATA: lv_min TYPE budat,
        lv_max TYPE budat,
        lv_hi  TYPE budat.

  CHECK sy-ucomm = 'ONLI' OR sy-ucomm = 'PRIN' OR sy-ucomm = 'SJOB'
     OR sy-batch = abap_true.
  CHECK s_mblnr[] IS INITIAL.

  IF s_budat[] IS INITIAL.
    SET CURSOR FIELD 'S_BUDAT-LOW'.
    MESSAGE e002.
  ENDIF.

  LOOP AT s_budat INTO DATA(ls_budat).
    IF ls_budat-sign <> 'I' OR ls_budat-low IS INITIAL
       OR ( ls_budat-option <> 'EQ'
        AND ( ls_budat-option <> 'BT' OR ls_budat-high IS INITIAL ) ).
      SET CURSOR FIELD 'S_BUDAT-LOW'.
      MESSAGE e002.
    ENDIF.
    lv_hi = COND #( WHEN ls_budat-option = 'BT' THEN ls_budat-high ELSE ls_budat-low ).
    IF lv_min IS INITIAL OR ls_budat-low < lv_min.
      lv_min = ls_budat-low.
    ENDIF.
    IF lv_hi > lv_max.
      lv_max = lv_hi.
    ENDIF.
  ENDLOOP.

  IF lv_max - lv_min + 1 > gc_max_days.
    SET CURSOR FIELD 'S_BUDAT-LOW'.
    MESSAGE e002.
  ENDIF.

ENDFORM.                    " CHECK_CONDITION

*&---------------------------------------------------------------------*
*&      Form  GET_MVT_GROUP
*&---------------------------------------------------------------------*
FORM get_mvt_group .

  SELECT bwart, seqnr, sobkz, aufnr_flg, bsart, pstyp, werks,
         grp_code, txt_vi, txt_en, rev_bwart
    FROM ztwm_mvt_grp
    INTO CORRESPONDING FIELDS OF TABLE @gt_mvt.

ENDFORM.                    " GET_MVT_GROUP

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       Dòng nhập (Debit); bỏ chứng từ đảo, MvT 309 chỉ lấy dòng tự sinh.
*----------------------------------------------------------------------*
FORM get_data .

  DATA: lr_mjahr TYPE RANGE OF mjahr,
        lr_bwart TYPE RANGE OF bwart.

  IF s_mblnr[] IS NOT INITIAL.
    lr_mjahr = VALUE #( ( sign = 'I' option = 'EQ' low = p_mjahr ) ).
  ENDIF.

  LOOP AT gt_mvt INTO DATA(ls_mvt).
    APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_mvt-bwart ) TO lr_bwart.
  ENDLOOP.
  SORT lr_bwart BY low.
  DELETE ADJACENT DUPLICATES FROM lr_bwart COMPARING low.
  CHECK lr_bwart IS NOT INITIAL.

  SELECT FROM matdoc
    LEFT OUTER JOIN ekpo ON ekpo~ebeln = matdoc~ebeln
                        AND ekpo~ebelp = matdoc~ebelp
    LEFT OUTER JOIN ekko ON ekko~ebeln = ekpo~ebeln
    FIELDS matdoc~mblnr,
           matdoc~mjahr,
           matdoc~zeile,
           matdoc~bwart,
           matdoc~sobkz,
           matdoc~insmk,
           matdoc~budat,
           matdoc~bldat,
           matdoc~bktxt,
           matdoc~xblnr,
           matdoc~usnam,
           matdoc~bukrs,
           matdoc~werks,
           matdoc~lgort,
           matdoc~matnr,
           matdoc~ematn,
           matdoc~charg,
           matdoc~menge,
           matdoc~meins,
           matdoc~erfmg,
           matdoc~erfme,
           matdoc~ebeln,
           matdoc~ebelp,
           matdoc~aufnr,
           matdoc~kostl,
           matdoc~kokrs,
           matdoc~lifnr,
           matdoc~kunnr,
           matdoc~vbeln_im,
           matdoc~le_vbeln,
           ekko~bsart,
           ekko~waers AS po_waers,
           ekko~reswk,
           ekpo~pstyp,
           ekpo~reslo,
           ekpo~txz01
    WHERE matdoc~record_type = 'MDOC'
      AND matdoc~werks IN @s_werks
      AND matdoc~mblnr IN @s_mblnr
      AND matdoc~mjahr IN @lr_mjahr
      AND matdoc~budat IN @s_budat
      AND matdoc~bwart IN @s_bwart
      AND matdoc~bwart IN @lr_bwart
      AND matdoc~lgort IN @s_lgort
      AND matdoc~lifnr IN @s_lifnr
      AND matdoc~ebeln IN @s_ebeln
      AND matdoc~aufnr IN @s_aufnr
      AND matdoc~usnam IN @s_usnam
      AND matdoc~shkzg = 'S'
      AND matdoc~smbln = @space
      AND ( ( matdoc~bwart <> @gc_bwart_309 AND matdoc~xauto = @space )
         OR ( matdoc~bwart = @gc_bwart_309 AND matdoc~xauto = @abap_true ) )
    INTO CORRESPONDING FIELDS OF TABLE @gt_item.

ENDFORM.                    " GET_DATA

*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITY
*&---------------------------------------------------------------------*
FORM check_authority .

  DATA: lv_count  TYPE i,
        lv_before TYPE i,
        lv_ok     TYPE abap_bool,
        lv_werks  TYPE werks_d,
        lv_bwart  TYPE bwart.

  DATA(lt_key) = VALUE gtt_line( FOR ls_i IN gt_item ( werks = ls_i-werks bwart = ls_i-bwart ) ).
  SORT lt_key BY werks bwart.
  DELETE ADJACENT DUPLICATES FROM lt_key COMPARING werks bwart.

  LOOP AT lt_key INTO DATA(ls_key).
    AUTHORITY-CHECK OBJECT 'M_MSEG_WMB'
      ID 'ACTVT' FIELD '03'
      ID 'WERKS' FIELD ls_key-werks.
    lv_ok = xsdbool( sy-subrc = 0 ).
    IF lv_ok = abap_true.
      AUTHORITY-CHECK OBJECT 'M_MSEG_BMB'
        ID 'ACTVT' FIELD '03'
        ID 'BWART' FIELD ls_key-bwart.
      lv_ok = xsdbool( sy-subrc = 0 ).
    ENDIF.
    CHECK lv_ok = abap_false.

    IF lv_werks IS INITIAL.
      lv_werks = ls_key-werks.
      lv_bwart = ls_key-bwart.
    ENDIF.
    lv_before = lines( gt_item ).
    DELETE gt_item WHERE werks = ls_key-werks AND bwart = ls_key-bwart.
    lv_count = lv_count + lv_before - lines( gt_item ).
  ENDLOOP.

  CHECK lv_werks IS NOT INITIAL.

  IF gt_item IS INITIAL.
    MESSAGE s001 WITH lv_werks lv_bwart DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  PERFORM add_msg USING 'W' '008' lv_count lv_werks lv_bwart.

ENDFORM.                    " CHECK_AUTHORITY

*&---------------------------------------------------------------------*
*&      Form  MATCH_MVT_GROUP
*&---------------------------------------------------------------------*
*       Dòng khớp đầu tiên của ZTWM_MVT_GRP (theo SEQNR) quyết định nhóm; điều kiện trống = bất kỳ.
*----------------------------------------------------------------------*
FORM match_mvt_group .

  DATA lt_unreg TYPE SORTED TABLE OF bwart WITH UNIQUE KEY table_line.

  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
    LOOP AT gt_mvt INTO DATA(ls_mvt) WHERE bwart = <lfs_item>-bwart.
      CHECK ( ls_mvt-sobkz IS INITIAL OR ls_mvt-sobkz = <lfs_item>-sobkz )
        AND ( ls_mvt-aufnr_flg IS INITIAL OR <lfs_item>-aufnr IS NOT INITIAL )
        AND ( ls_mvt-bsart IS INITIAL OR ls_mvt-bsart = <lfs_item>-bsart )
        AND ( ls_mvt-pstyp IS INITIAL OR ls_mvt-pstyp = <lfs_item>-pstyp )
        AND ( ls_mvt-werks IS INITIAL OR ls_mvt-werks = <lfs_item>-werks ).
      <lfs_item>-grp_found = abap_true.
      <lfs_item>-grp_code  = ls_mvt-grp_code.
      <lfs_item>-txt_vi    = ls_mvt-txt_vi.
      <lfs_item>-txt_en    = ls_mvt-txt_en.
      <lfs_item>-rev_bwart = ls_mvt-rev_bwart.
      EXIT.
    ENDLOOP.
    IF <lfs_item>-grp_found = abap_false.
      INSERT <lfs_item>-bwart INTO TABLE lt_unreg.
    ENDIF.
  ENDLOOP.

  LOOP AT lt_unreg INTO DATA(lv_bwart).
    PERFORM add_msg USING 'W' '007' lv_bwart space space.
  ENDLOOP.

ENDFORM.                    " MATCH_MVT_GROUP

*&---------------------------------------------------------------------*
*&      Form  CALC_ADJUST
*&---------------------------------------------------------------------*
*       SL thực nhận = SL dòng gốc - SL dòng đảo (SMBLN, hoặc MvT đảo qua LFBNR).
*----------------------------------------------------------------------*
FORM calc_adjust .

  DATA: lt_rev  TYPE STANDARD TABLE OF gty_rev WITH EMPTY KEY,
        lv_rev  TYPE menge_d,
        lv_all  TYPE abap_bool.

  CHECK gt_item IS NOT INITIAL.

  DATA(lt_okey) = VALUE gtt_okey( FOR ls_i IN gt_item
                                  ( mblnr = ls_i-mblnr mjahr = ls_i-mjahr
                                    zeile = ls_i-zeile rev_bwart = ls_i-rev_bwart ) ).
  DATA(lt_okey2) = VALUE gtt_okey( FOR ls_k IN lt_okey WHERE ( rev_bwart IS NOT INITIAL ) ( ls_k ) ).

  SELECT FROM matdoc AS r
    INNER JOIN @lt_okey AS o ON r~smbln = o~mblnr
                            AND r~sjahr = o~mjahr
                            AND r~smblp = o~zeile
    FIELDS o~mblnr AS org_mblnr,
           o~mjahr AS org_mjahr,
           o~zeile AS org_zeile,
           r~mblnr AS rev_mblnr,
           r~mjahr AS rev_mjahr,
           r~zeile AS rev_zeile,
           r~bwart AS rev_bwart,
           r~menge,
           r~meins,
           r~erfmg,
           r~erfme,
           r~usnam,
           r~budat
    WHERE r~record_type = 'MDOC'
    INTO CORRESPONDING FIELDS OF TABLE @lt_rev   ##ITAB_DB_SELECT.

  IF lt_okey2 IS NOT INITIAL.
    SELECT FROM matdoc AS r
      INNER JOIN @lt_okey2 AS o ON r~lfbnr = o~mblnr
                               AND r~lfbja = o~mjahr
                               AND r~lfpos = o~zeile
                               AND r~bwart = o~rev_bwart
      FIELDS o~mblnr AS org_mblnr,
             o~mjahr AS org_mjahr,
             o~zeile AS org_zeile,
             r~mblnr AS rev_mblnr,
             r~mjahr AS rev_mjahr,
             r~zeile AS rev_zeile,
             r~bwart AS rev_bwart,
             r~menge,
             r~meins,
             r~erfmg,
             r~erfme,
             r~usnam,
             r~budat
      WHERE r~record_type = 'MDOC'
      APPENDING CORRESPONDING FIELDS OF TABLE @lt_rev   ##ITAB_DB_SELECT.
  ENDIF.

  SORT lt_rev BY org_mblnr org_mjahr org_zeile rev_mblnr rev_mjahr rev_zeile.
  DELETE ADJACENT DUPLICATES FROM lt_rev
         COMPARING org_mblnr org_mjahr org_zeile rev_mblnr rev_mjahr rev_zeile.
  INSERT LINES OF lt_rev INTO TABLE gt_rev.

  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
    CLEAR lv_rev.
    <lfs_item>-menge_net = <lfs_item>-menge.
    <lfs_item>-erfmg_net = <lfs_item>-erfmg.
    LOOP AT gt_rev INTO DATA(ls_rev)
         WHERE org_mblnr = <lfs_item>-mblnr
           AND org_mjahr = <lfs_item>-mjahr
           AND org_zeile = <lfs_item>-zeile.
      <lfs_item>-rev_cnt = <lfs_item>-rev_cnt + 1.
      lv_rev = lv_rev + ls_rev-menge.
    ENDLOOP.
    CHECK <lfs_item>-rev_cnt > 0.
    <lfs_item>-menge_net = nmax( val1 = <lfs_item>-menge - lv_rev val2 = 0 ).
    IF <lfs_item>-menge <> 0.
      <lfs_item>-erfmg_net = <lfs_item>-erfmg * <lfs_item>-menge_net / <lfs_item>-menge.
    ELSE.
      <lfs_item>-erfmg_net = 0.
    ENDIF.
    <lfs_item>-del = xsdbool( p_adj = abap_true AND <lfs_item>-menge_net <= 0 ).
  ENDLOOP.

  LOOP AT gt_rev INTO ls_rev.
    READ TABLE gt_docadj ASSIGNING FIELD-SYMBOL(<lfs_adj>)
         WITH TABLE KEY mblnr = ls_rev-org_mblnr mjahr = ls_rev-org_mjahr.
    IF sy-subrc <> 0.
      INSERT VALUE #( mblnr = ls_rev-org_mblnr mjahr = ls_rev-org_mjahr )
             INTO TABLE gt_docadj ASSIGNING <lfs_adj>.
    ENDIF.
    DATA(lv_rev_doc) = |{ ls_rev-rev_mblnr ALPHA = OUT }|.
    IF <lfs_adj>-rev_docs NS lv_rev_doc.
      <lfs_adj>-rev_docs = COND #( WHEN <lfs_adj>-rev_docs IS INITIAL THEN lv_rev_doc
                                   ELSE |{ <lfs_adj>-rev_docs }, { lv_rev_doc }| ).
    ENDIF.

    READ TABLE gt_item INTO DATA(ls_org)
         WITH KEY mblnr = ls_rev-org_mblnr mjahr = ls_rev-org_mjahr zeile = ls_rev-org_zeile.
    APPEND VALUE #( org_mblnr = ls_rev-org_mblnr
                    org_mjahr = ls_rev-org_mjahr
                    org_zeile = ls_rev-org_zeile
                    matnr     = ls_org-matnr
                    org_bwart = ls_org-bwart
                    org_erfmg = ls_org-erfmg
                    org_erfme = ls_org-erfme
                    rev_mblnr = ls_rev-rev_mblnr
                    rev_mjahr = ls_rev-rev_mjahr
                    rev_zeile = ls_rev-rev_zeile
                    rev_bwart = ls_rev-rev_bwart
                    rev_erfmg = ls_rev-erfmg
                    rev_erfme = ls_rev-erfme
                    usnam     = ls_rev-usnam
                    budat     = ls_rev-budat ) TO gt_detail.
  ENDLOOP.

  LOOP AT gt_item ASSIGNING <lfs_item> WHERE rev_cnt > 0.
    READ TABLE gt_docadj ASSIGNING <lfs_adj>
         WITH TABLE KEY mblnr = <lfs_item>-mblnr mjahr = <lfs_item>-mjahr.
    IF sy-subrc = 0.
      <lfs_adj>-adj_lines = <lfs_adj>-adj_lines + 1.
    ENDIF.
  ENDLOOP.

  " Bỏ dòng/chứng từ đã đảo toàn bộ
  CHECK p_adj = abap_true.

  LOOP AT gt_item INTO DATA(ls_it)
       GROUP BY ( mblnr = ls_it-mblnr mjahr = ls_it-mjahr ) INTO DATA(lg_doc).
    lv_all = abap_true.
    LOOP AT GROUP lg_doc INTO DATA(ls_line).
      IF ls_line-del = abap_false.
        lv_all = abap_false.
      ENDIF.
    ENDLOOP.
    CHECK lv_all = abap_true.
    DATA(lv_doc) = |{ lg_doc-mblnr ALPHA = OUT }|.
    PERFORM add_msg USING 'W' '004' lv_doc space space.
  ENDLOOP.

  DELETE gt_item WHERE del = abap_true.

ENDFORM.                    " CALC_ADJUST

*&---------------------------------------------------------------------*
*&      Form  ADD_MSG
*&---------------------------------------------------------------------*
FORM add_msg USING iv_type TYPE c
                   iv_no   TYPE c
                   iv_v1   TYPE any
                   iv_v2   TYPE any
                   iv_v3   TYPE any.

  DATA: lv_v1 TYPE symsgv,
        lv_v2 TYPE symsgv,
        lv_v3 TYPE symsgv,
        lv_ty TYPE symsgty,
        lv_no TYPE symsgno.

  IF gv_msg_init = abap_false.
    CALL FUNCTION 'MESSAGES_INITIALIZE'.
    gv_msg_init = abap_true.
  ENDIF.

  lv_ty = iv_type.
  lv_no = iv_no.
  lv_v1 = iv_v1.
  lv_v2 = iv_v2.
  lv_v3 = iv_v3.
  CONDENSE: lv_v1, lv_v2, lv_v3.

  CALL FUNCTION 'MESSAGE_STORE'
    EXPORTING
      arbgb                   = gc_msgid
      exception_if_not_active = space
      msgty                   = lv_ty
      msgv1                   = lv_v1
      msgv2                   = lv_v2
      msgv3                   = lv_v3
      txtnr                   = lv_no
    EXCEPTIONS
      OTHERS                  = 1.

ENDFORM.                    " ADD_MSG

*&---------------------------------------------------------------------*
*&      Form  SHOW_MESSAGES
*&---------------------------------------------------------------------*
FORM show_messages .

  CHECK gv_msg_init = abap_true.

  CALL FUNCTION 'MESSAGES_SHOW'
    EXPORTING
      show_linno = space
    EXCEPTIONS
      OTHERS     = 1.
  gv_msg_init = abap_false.

ENDFORM.                    " SHOW_MESSAGES

*&---------------------------------------------------------------------*
*&      Form  GET_MASTER_DATA
*&---------------------------------------------------------------------*
FORM get_master_data .

  DATA: lt_matnr  TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line,
        lt_mkey   TYPE SORTED TABLE OF gty_marc WITH UNIQUE KEY matnr werks,
        lt_lkey   TYPE SORTED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
        lt_bkey   TYPE SORTED TABLE OF gty_batch WITH UNIQUE KEY matnr werks charg,
        lt_unit   TYPE SORTED TABLE OF msehi WITH UNIQUE KEY table_line,
        lt_awkey  TYPE SORTED TABLE OF awkey WITH UNIQUE KEY table_line,
        lt_kostl  TYPE SORTED TABLE OF gty_cskt WITH UNIQUE KEY kokrs kostl,
        lt_aufnr  TYPE SORTED TABLE OF aufnr WITH UNIQUE KEY table_line,
        lt_xbl    TYPE SORTED TABLE OF mblnr WITH UNIQUE KEY table_line,
        lt_resb   TYPE STANDARD TABLE OF gty_resb WITH EMPTY KEY,
        lv_awkey  TYPE awkey,
        lv_xbl    TYPE mblnr,
        lv_werks  TYPE werks_d,
        lv_one    TYPE f,
        lv_ratio  TYPE f,
        lv_base   TYPE meins.

  LOOP AT gt_item INTO DATA(ls_item).
    IF ls_item-matnr IS NOT INITIAL.
      INSERT ls_item-matnr INTO TABLE lt_matnr.
      INSERT VALUE #( matnr = ls_item-matnr werks = ls_item-werks ) INTO TABLE lt_mkey.
    ENDIF.
    IF ls_item-ematn IS NOT INITIAL.
      INSERT ls_item-ematn INTO TABLE lt_matnr.
    ENDIF.
    INSERT VALUE #( werks = ls_item-werks lgort = ls_item-lgort ) INTO TABLE lt_lkey.
    IF ls_item-reslo IS NOT INITIAL.
      lv_werks = COND #( WHEN ls_item-reswk IS NOT INITIAL THEN ls_item-reswk ELSE ls_item-werks ).
      INSERT VALUE #( werks = lv_werks lgort = ls_item-reslo ) INTO TABLE lt_lkey.
    ENDIF.
    IF ls_item-matnr IS NOT INITIAL AND ls_item-charg IS NOT INITIAL.
      INSERT VALUE #( matnr = ls_item-matnr werks = ls_item-werks charg = ls_item-charg )
             INTO TABLE lt_bkey.
    ENDIF.
    IF p_isn = abap_true AND ls_item-erfme IS NOT INITIAL.
      INSERT ls_item-erfme INTO TABLE lt_unit.
    ENDIF.
    lv_awkey = |{ ls_item-mblnr }{ ls_item-mjahr }|.
    INSERT lv_awkey INTO TABLE lt_awkey.
    IF ls_item-kostl IS NOT INITIAL.
      INSERT VALUE #( kokrs = ls_item-kokrs kostl = ls_item-kostl ) INTO TABLE lt_kostl.
    ENDIF.
    IF ls_item-aufnr IS NOT INITIAL.
      INSERT ls_item-aufnr INTO TABLE lt_aufnr.
    ENDIF.
    IF ( ls_item-bwart = gc_bwart_305 OR ls_item-bwart = gc_bwart_315 )
       AND ls_item-xblnr IS NOT INITIAL.
      lv_xbl = ls_item-xblnr.
      INSERT lv_xbl INTO TABLE lt_xbl.
    ENDIF.
  ENDLOOP.

  IF lt_matnr IS NOT INITIAL.
    SELECT FROM makt
      INNER JOIN @lt_matnr AS k ON k~table_line = makt~matnr
      FIELDS makt~matnr, makt~spras, makt~maktx
      WHERE makt~spras IN ( @gc_spras_vi, @gc_spras_en )
      INTO CORRESPONDING FIELDS OF TABLE @gt_makt   ##ITAB_DB_SELECT.

    SELECT FROM mara
      INNER JOIN @lt_matnr AS k ON k~table_line = mara~matnr
      LEFT OUTER JOIN t142t ON t142t~raube = mara~raube
                           AND t142t~spras = @sy-langu
      FIELDS mara~matnr, mara~mtart, mara~groes, mara~raube, mara~mfrnr,
             mara~meins, t142t~rbtxt AS raube_txt
      INTO CORRESPONDING FIELDS OF TABLE @gt_mat   ##ITAB_DB_SELECT.
  ENDIF.

  IF lt_mkey IS NOT INITIAL.
    SELECT FROM marc
      INNER JOIN @lt_mkey AS k ON k~matnr = marc~matnr
                              AND k~werks = marc~werks
      FIELDS marc~matnr, marc~werks, marc~herkl
      INTO CORRESPONDING FIELDS OF TABLE @gt_marc   ##ITAB_DB_SELECT.
  ENDIF.

  SELECT FROM t001l
    INNER JOIN @lt_lkey AS k ON k~werks = t001l~werks
                            AND k~lgort = t001l~lgort
    FIELDS t001l~werks, t001l~lgort, t001l~lgobe
    INTO CORRESPONDING FIELDS OF TABLE @gt_lgort   ##ITAB_DB_SELECT.

  IF lt_bkey IS NOT INITIAL.
    SELECT FROM mcha
      INNER JOIN @lt_bkey AS k ON k~matnr = mcha~matnr
                              AND k~werks = mcha~werks
                              AND k~charg = mcha~charg
      FIELDS mcha~matnr, mcha~werks, mcha~charg, mcha~vfdat, mcha~qndat, mcha~licha
      INTO CORRESPONDING FIELDS OF TABLE @gt_batch   ##ITAB_DB_SELECT.

    PERFORM get_batch_charact.
  ENDIF.

  SELECT sign, opti, low, high
    FROM tvarvc
    WHERE name = @gc_tvarv_mtart
      AND type = 'S'
      AND low <> @space
    INTO TABLE @DATA(lt_tvarv).
  gr_mtart_knl = VALUE #( FOR ls_t IN lt_tvarv
                          ( sign = ls_t-sign option = ls_t-opti low = ls_t-low high = ls_t-high ) ).

  " Chỉ mẫu 2/3; tỷ lệ quy đổi lấy từ class chuẩn
  IF ( p_op2 = abap_true OR p_op3 = abap_true ) AND lt_matnr IS NOT INITIAL.
    SELECT FROM marm
      INNER JOIN @lt_matnr AS k ON k~table_line = marm~matnr
      LEFT OUTER JOIN t006a ON t006a~msehi = marm~meinh
                           AND t006a~spras = @sy-langu
      FIELDS marm~matnr, marm~meinh, t006a~mseh6
      INTO CORRESPONDING FIELDS OF TABLE @gt_marm   ##ITAB_DB_SELECT.
    LOOP AT gt_marm ASSIGNING FIELD-SYMBOL(<lfs_marm>).
      lv_one   = 1.
      lv_ratio = 0.
      lv_base  = VALUE #( gt_mat[ matnr = <lfs_marm>-matnr ]-meins OPTIONAL ).
      TRY.
          cl_md_product_unit_conversion=>convert(
            EXPORTING input           = lv_one
                      is_alternativeunit = abap_true
                      product         = <lfs_marm>-matnr
                      alternativeunit = <lfs_marm>-meinh
            IMPORTING output          = lv_ratio
            CHANGING  baseunit        = lv_base ).
        CATCH cx_md_product_unit_conversion.
          CONTINUE.
      ENDTRY.
      <lfs_marm>-ratio = lv_ratio.
    ENDLOOP.
    SORT gt_marm BY matnr ratio DESCENDING.
  ENDIF.

  IF lt_unit IS NOT INITIAL.
    SELECT FROM t006a
      INNER JOIN @lt_unit AS k ON k~table_line = t006a~msehi
      FIELDS t006a~msehi, t006a~msehl
      WHERE t006a~spras = @gc_spras_en
      INTO CORRESPONDING FIELDS OF TABLE @gt_unit_en   ##ITAB_DB_SELECT.
  ENDIF.

  SELECT FROM bkpf
    INNER JOIN @lt_awkey AS k ON k~table_line = bkpf~awkey
    FIELDS bkpf~awkey, bkpf~belnr, bkpf~waers, bkpf~kursf
    WHERE bkpf~awtyp = 'MKPF'
    INTO CORRESPONDING FIELDS OF TABLE @gt_bkpf   ##ITAB_DB_SELECT.

  IF lt_kostl IS NOT INITIAL.
    SELECT FROM cskt
      INNER JOIN @lt_kostl AS k ON k~kokrs = cskt~kokrs
                               AND k~kostl = cskt~kostl
      FIELDS cskt~kokrs, cskt~kostl, cskt~ktext
      WHERE cskt~spras = @sy-langu
        AND cskt~datbi >= @sy-datum
      INTO CORRESPONDING FIELDS OF TABLE @gt_cskt   ##ITAB_DB_SELECT.
  ENDIF.

  " Kho của thành phần đầu tiên trong lệnh SX
  IF lt_aufnr IS NOT INITIAL.
    SELECT FROM resb
      INNER JOIN @lt_aufnr AS k ON k~table_line = resb~aufnr
      LEFT OUTER JOIN t001l ON t001l~werks = resb~werks
                           AND t001l~lgort = resb~lgort
      FIELDS resb~aufnr, resb~rsnum, resb~rspos, resb~lgort, t001l~lgobe
      WHERE resb~lgort <> @space
        AND resb~xloek = @space
      INTO CORRESPONDING FIELDS OF TABLE @lt_resb   ##ITAB_DB_SELECT.
    SORT lt_resb BY aufnr rsnum rspos.
    DELETE ADJACENT DUPLICATES FROM lt_resb COMPARING aufnr.
    INSERT LINES OF lt_resb INTO TABLE gt_resb.
  ENDIF.

  " Kho xuất của chứng từ tham chiếu (MvT 305/315)
  IF lt_xbl IS NOT INITIAL.
    SELECT FROM matdoc AS i
      INNER JOIN @lt_xbl AS k ON k~table_line = i~mblnr
      LEFT OUTER JOIN t001l ON t001l~werks = i~werks
                           AND t001l~lgort = i~lgort
      FIELDS i~mblnr, i~mjahr, i~werks, i~lgort, t001l~lgobe
      WHERE i~record_type = 'MDOC'
        AND i~xauto = @space
      INTO CORRESPONDING FIELDS OF TABLE @gt_issue   ##ITAB_DB_SELECT.
  ENDIF.

ENDFORM.                    " GET_MASTER_DATA

*&---------------------------------------------------------------------*
*&      Form  GET_BATCH_CHARACT
*&---------------------------------------------------------------------*
FORM get_batch_charact .

  DATA: lt_atnam TYPE STANDARD TABLE OF zcore_st_rseloption_atnam,
        lt_char  TYPE STANDARD TABLE OF bapi1003_alloc_values_char.

  lt_atnam = VALUE #( sign = 'I' option = 'EQ'
                      ( low = gc_at_nongdo ) ( low = gc_at_doam1 ) ( low = gc_at_doam2 )
                      ( low = gc_at_nsx )    ( low = gc_at_nuoc )  ( low = gc_at_lonsx )
                      ( low = gc_at_quycach ) ( low = gc_at_baoquan ) ).

  LOOP AT gt_batch ASSIGNING FIELD-SYMBOL(<lfs_bat>).
    CLEAR lt_char.
    CALL FUNCTION 'ZCORE_FM_GET_CRTRT_MULTIVAL'
      EXPORTING
        i_matnr    = <lfs_bat>-matnr
        i_charg    = <lfs_bat>-charg
        i_werks    = <lfs_bat>-werks
        i_klart    = '023'
      TABLES
        it_atnam   = lt_atnam
        it_charact = lt_char.

    LOOP AT lt_char INTO DATA(ls_char).
      CASE ls_char-charact.
        WHEN gc_at_nongdo.
          <lfs_bat>-z_nongdo = ls_char-value_char.
        WHEN gc_at_doam1.
          <lfs_bat>-z_doam1  = ls_char-value_char.
        WHEN gc_at_doam2.
          <lfs_bat>-z_doam2  = ls_char-value_char.
        WHEN gc_at_nsx.
          <lfs_bat>-z_nsx    = ls_char-value_char.
        WHEN gc_at_nuoc.
          <lfs_bat>-z_nuoc   = ls_char-value_char.
        WHEN gc_at_lonsx.
          <lfs_bat>-z_lonsx  = ls_char-value_char.
        WHEN gc_at_quycach.
          <lfs_bat>-quycach  = ls_char-value_char.
        WHEN gc_at_baoquan.
          <lfs_bat>-baoquan  = ls_char-value_char.
      ENDCASE.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " GET_BATCH_CHARACT

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_DATA
*&---------------------------------------------------------------------*
FORM build_alv_data .

  DATA: ls_alv TYPE gty_alv,
        ls_hdr TYPE gty_hdr.

  CLEAR gt_alv.

  LOOP AT gt_item INTO DATA(ls_item)
       GROUP BY ( mblnr = ls_item-mblnr mjahr = ls_item-mjahr ) INTO DATA(lg_doc).

    CLEAR ls_alv.
    LOOP AT GROUP lg_doc INTO DATA(ls_line).
      IF ls_alv IS INITIAL.
        ls_alv-sel     = abap_true.
        ls_alv-mblnr   = ls_line-mblnr.
        ls_alv-mjahr   = ls_line-mjahr.
        ls_alv-budat   = ls_line-budat.
        ls_alv-bwart   = ls_line-bwart.
        ls_alv-lgort   = ls_line-lgort.
        ls_alv-werks   = ls_line-werks.
        ls_alv-obj_key = |{ ls_line-mblnr }/{ ls_line-mjahr }|.

        PERFORM resolve_header USING ls_line abap_false CHANGING ls_hdr.
        ls_alv-code  = COND #( WHEN ls_line-aufnr IS NOT INITIAL
                               THEN |LSX { ls_line-aufnr ALPHA = OUT }|
                               ELSE ls_hdr-code ).
        ls_alv-descr = ls_hdr-descr.

        READ TABLE gt_docadj INTO DATA(ls_adj)
             WITH TABLE KEY mblnr = ls_line-mblnr mjahr = ls_line-mjahr.
        IF sy-subrc = 0.
          ls_alv-adj      = |Có ({ ls_adj-adj_lines } dòng)|.
          ls_alv-adj_docs = ls_adj-rev_docs.
        ENDIF.
      ELSEIF ls_line-lgort <> ls_alv-lgort(4) AND ls_alv-lgort+4(1) IS INITIAL.
        ls_alv-lgort+4(1) = '+'.
      ENDIF.
      ls_alv-item_count = ls_alv-item_count + 1.
    ENDLOOP.
    APPEND ls_alv TO gt_alv.
  ENDLOOP.

  PERFORM read_print_count.

ENDFORM.                    " BUILD_ALV_DATA

*&---------------------------------------------------------------------*
*&      Form  READ_PRINT_COUNT
*&---------------------------------------------------------------------*
FORM read_print_count .

  CHECK gt_alv IS NOT INITIAL.

  SELECT FROM @gt_alv AS k
    INNER JOIN ztwm_prtlog AS l ON l~obj_key = k~obj_key
    FIELDS l~obj_key, l~prt_count
    WHERE l~tcode    = @gc_tcode
      AND l~formname = @gc_prt_form
    INTO TABLE @DATA(lt_cnt)   ##ITAB_DB_SELECT.

  LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<lfs_alv>).
    <lfs_alv>-print_count = VALUE #( lt_cnt[ obj_key = <lfs_alv>-obj_key ]-prt_count OPTIONAL ).
  ENDLOOP.

ENDFORM.                    " READ_PRINT_COUNT

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM display_alv .

  DATA: lo_column TYPE REF TO cl_salv_column_table,
        lo_grid   TYPE REF TO cl_salv_form_layout_grid,
        lv_head   TYPE string.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = go_alv
                              CHANGING  t_table      = gt_alv ).
    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  go_alv->set_screen_status( pfstatus      = 'STANDARD'
                             report        = sy-repid
                             set_functions = cl_salv_table=>c_functions_all ).

  DATA(lo_columns) = go_alv->get_columns( ).
  lo_columns->set_optimize( abap_true ).

  TRY.
      lo_column ?= lo_columns->get_column( 'SEL' ).
      lo_column->set_cell_type( if_salv_c_cell_type=>checkbox_hotspot ).
      PERFORM set_col_text USING lo_column 'Chọn'.

      lo_column ?= lo_columns->get_column( 'MBLNR' ).
      PERFORM set_col_text USING lo_column 'Chứng từ kho'.
      lo_column ?= lo_columns->get_column( 'MJAHR' ).
      PERFORM set_col_text USING lo_column 'Năm'.
      lo_column ?= lo_columns->get_column( 'BUDAT' ).
      PERFORM set_col_text USING lo_column 'Ngày HT'.
      lo_column ?= lo_columns->get_column( 'BWART' ).
      PERFORM set_col_text USING lo_column 'MvT'.
      lo_column ?= lo_columns->get_column( 'LGORT' ).
      PERFORM set_col_text USING lo_column 'SLoc'.
      lo_column ?= lo_columns->get_column( 'CODE' ).
      PERFORM set_col_text USING lo_column 'NCC / KH'.
      lo_column ?= lo_columns->get_column( 'DESCR' ).
      PERFORM set_col_text USING lo_column 'Diễn giải'.
      lo_column ?= lo_columns->get_column( 'ITEM_COUNT' ).
      PERFORM set_col_text USING lo_column 'Số dòng'.
      lo_column ?= lo_columns->get_column( 'ADJ' ).
      PERFORM set_col_text USING lo_column 'Có điều chỉnh'.
      lo_column ?= lo_columns->get_column( 'PRINT_COUNT' ).
      PERFORM set_col_text USING lo_column 'Đã in (lần)'.

      lo_columns->get_column( 'WERKS' )->set_technical( abap_true ).
      lo_columns->get_column( 'OBJ_KEY' )->set_technical( abap_true ).
      lo_columns->get_column( 'ADJ_DOCS' )->set_technical( abap_true ).
    CATCH cx_salv_not_found.
  ENDTRY.

  READ TABLE s_werks INTO DATA(ls_werks) INDEX 1.
  lv_head = |Plant { ls_werks-low }|.
  IF s_mblnr[] IS NOT INITIAL.
    READ TABLE s_mblnr INTO DATA(ls_mblnr) INDEX 1.
    lv_head = |{ lv_head } \| Chứng từ kho { ls_mblnr-low ALPHA = OUT }|.
  ELSE.
    READ TABLE s_budat INTO DATA(ls_budat) INDEX 1.
    lv_head = |{ lv_head } \| Ngày hạch toán { ls_budat-low DATE = USER }|.
    IF ls_budat-option = 'BT'.
      lv_head = |{ lv_head } - { ls_budat-high DATE = USER }|.
    ENDIF.
  ENDIF.
  lv_head = |{ lv_head } \| Mẫu in: { COND string( WHEN p_op1 = abap_true THEN '1. Nguyên liệu'
                                                   WHEN p_op2 = abap_true THEN '2. Hàng hóa, vật tư'
                                                   WHEN p_op3 = abap_true THEN '3. Thành phẩm'
                                                   ELSE '4. NL, BB có quy đổi' ) }|.
  lv_head = |{ lv_head } \| SL sau điều chỉnh: { COND string( WHEN p_adj = abap_true THEN 'Có'
                                                              ELSE 'Không' ) }|.

  CREATE OBJECT lo_grid.
  lo_grid->create_label( row = 1 column = 1
                         text = 'ZWM03 – Danh sách chứng từ nhập kho' ).
  lo_grid->create_text( row = 2 column = 1 text = lv_head ).
  go_alv->set_top_of_list( lo_grid ).

  DATA(lo_events) = go_alv->get_event( ).
  SET HANDLER lcl_handler=>on_function FOR lo_events.
  SET HANDLER lcl_handler=>on_click FOR lo_events.

  go_alv->display( ).

ENDFORM.                    " DISPLAY_ALV

*&---------------------------------------------------------------------*
*&      Form  SET_COL_TEXT
*&---------------------------------------------------------------------*
FORM set_col_text USING io_column TYPE REF TO cl_salv_column_table
                        iv_text   TYPE csequence.

  io_column->set_short_text( CONV #( iv_text ) ).
  io_column->set_medium_text( CONV #( iv_text ) ).
  io_column->set_long_text( CONV #( iv_text ) ).

ENDFORM.                    " SET_COL_TEXT

*&---------------------------------------------------------------------*
*&      Form  SELECT_ALL
*&---------------------------------------------------------------------*
FORM select_all .

  DATA(lv_sel) = xsdbool( line_exists( gt_alv[ sel = abap_false ] ) ).
  MODIFY gt_alv FROM VALUE #( sel = lv_sel ) TRANSPORTING sel WHERE sel <> lv_sel.
  go_alv->refresh( ).

ENDFORM.                    " SELECT_ALL

*&---------------------------------------------------------------------*
*&      Form  SHOW_ADJUST
*&---------------------------------------------------------------------*
FORM show_adjust .

  DATA: lt_show TYPE STANDARD TABLE OF gty_detail WITH EMPTY KEY,
        lo_pop  TYPE REF TO cl_salv_table.

  DATA(lt_sel) = VALUE gtt_alv( FOR ls_a IN gt_alv WHERE ( sel = abap_true ) ( ls_a ) ).
  IF lt_sel IS INITIAL.
    MESSAGE s009 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_detail INTO DATA(ls_detail).
    CHECK line_exists( lt_sel[ mblnr = ls_detail-org_mblnr mjahr = ls_detail-org_mjahr ] ).
    APPEND ls_detail TO lt_show.
  ENDLOOP.

  IF lt_show IS INITIAL.
    MESSAGE s011.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_pop
                              CHANGING  t_table      = lt_show ).
    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  DATA(lo_columns) = lo_pop->get_columns( ).
  lo_columns->set_optimize( abap_true ).

  TRY.
      DATA(lo_column) = CAST cl_salv_column_table( lo_columns->get_column( 'ORG_MBLNR' ) ).
      PERFORM set_col_text USING lo_column 'CT gốc'.
      lo_column ?= lo_columns->get_column( 'ORG_MJAHR' ).
      PERFORM set_col_text USING lo_column 'Năm'.
      lo_column ?= lo_columns->get_column( 'ORG_ZEILE' ).
      PERFORM set_col_text USING lo_column 'Dòng'.
      lo_column ?= lo_columns->get_column( 'MATNR' ).
      PERFORM set_col_text USING lo_column 'Mã hàng'.
      lo_column ?= lo_columns->get_column( 'ORG_BWART' ).
      PERFORM set_col_text USING lo_column 'MvT gốc'.
      lo_column ?= lo_columns->get_column( 'ORG_ERFMG' ).
      PERFORM set_col_text USING lo_column 'SL gốc'.
      lo_column ?= lo_columns->get_column( 'ORG_ERFME' ).
      PERFORM set_col_text USING lo_column 'ĐVT'.
      lo_column ?= lo_columns->get_column( 'REV_MBLNR' ).
      PERFORM set_col_text USING lo_column 'CT đảo'.
      lo_column ?= lo_columns->get_column( 'REV_MJAHR' ).
      PERFORM set_col_text USING lo_column 'Năm đảo'.
      lo_column ?= lo_columns->get_column( 'REV_ZEILE' ).
      PERFORM set_col_text USING lo_column 'Dòng đảo'.
      lo_column ?= lo_columns->get_column( 'REV_BWART' ).
      PERFORM set_col_text USING lo_column 'MvT đảo'.
      lo_column ?= lo_columns->get_column( 'REV_ERFMG' ).
      PERFORM set_col_text USING lo_column 'SL đảo'.
      lo_column ?= lo_columns->get_column( 'REV_ERFME' ).
      PERFORM set_col_text USING lo_column 'ĐVT đảo'.
      lo_column ?= lo_columns->get_column( 'USNAM' ).
      PERFORM set_col_text USING lo_column 'Người tạo'.
      lo_column ?= lo_columns->get_column( 'BUDAT' ).
      PERFORM set_col_text USING lo_column 'Ngày'.
    CATCH cx_salv_not_found.
  ENDTRY.

  lo_pop->set_screen_popup( start_column = 5
                            end_column   = 150
                            start_line   = 3
                            end_line     = 22 ).
  lo_pop->display( ).

ENDFORM.                    " SHOW_ADJUST

*&---------------------------------------------------------------------*
*&      Form  EXPORT_EXCEL
*&---------------------------------------------------------------------*
FORM export_excel .

  DATA: lv_file   TYPE string,
        lv_path   TYPE string,
        lv_full   TYPE string,
        lv_action TYPE i.

  DATA(lv_xml) = go_alv->to_xml( xml_type = if_salv_bs_xml=>c_type_xlsx ).
  DATA(lt_bin) = cl_bcs_convert=>xstring_to_solix( iv_xstring = lv_xml ).

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_extension = 'xlsx'
      default_file_name = |ZWM03_{ sy-datum }.xlsx|
    CHANGING
      filename          = lv_file
      path              = lv_path
      fullpath          = lv_full
      user_action       = lv_action
    EXCEPTIONS
      OTHERS            = 1 ).
  CHECK sy-subrc = 0 AND lv_action = cl_gui_frontend_services=>action_ok.

  cl_gui_frontend_services=>gui_download(
    EXPORTING
      bin_filesize = xstrlen( lv_xml )
      filename     = lv_full
      filetype     = 'BIN'
    CHANGING
      data_tab     = lt_bin
    EXCEPTIONS
      OTHERS       = 1 ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.                    " EXPORT_EXCEL

*&---------------------------------------------------------------------*
*&      Form  GET_PARAMETER
*&---------------------------------------------------------------------*
FORM get_parameter .

  CLEAR gs_parameter.

  gs_parameter-logo = gc_logo.

  gs_parameter-header09 = lcl_util=>lbl_c( iv_vi = 'Nhà cung cấp/ Khách hàng' iv_en = 'Supplier/ Customer name' ).
  gs_parameter-header12 = lcl_util=>lbl_c( iv_vi = 'Mã NCC/ KH' iv_en = 'Supplier/ Customer code' ).
  gs_parameter-header14 = lcl_util=>lbl_c( iv_vi = 'Địa chỉ' iv_en = 'Address' ).
  gs_parameter-header16 = lcl_util=>lbl_c( iv_vi = 'Mã số thuế' iv_en = 'Tax code' ).
  gs_parameter-header24 = lcl_util=>lbl_c( iv_vi = 'Loại tiền' iv_en = 'Currency' ).
  gs_parameter-header23 = lcl_util=>lbl_c( iv_vi = 'Tỷ giá' iv_en = 'Exchange rate' ).
  gs_parameter-header19 = lcl_util=>lbl_c( iv_vi = 'Số chứng từ kho' iv_en = 'Warehouse Document No' ).
  gs_parameter-header20 = lcl_util=>lbl_c( iv_vi = 'Số chứng từ kế toán' iv_en = 'Accounting Document No' ).
  gs_parameter-header21 = lcl_util=>lbl_c( iv_vi = 'Nhập tại kho' iv_en = 'Storage location' ).
  gs_parameter-header22 = lcl_util=>lbl_c( iv_vi = 'Số hóa đơn gốc' iv_en = 'Invoice No' ).
  gs_parameter-header25 = lcl_util=>lbl_c( iv_vi = 'Ngày hóa đơn gốc' iv_en = 'Invoice date' ).
  gs_parameter-header27 = lcl_util=>lbl_c( iv_vi = 'Diễn giải' iv_en = 'Description' ).

  gs_parameter-parameter01 = lcl_util=>lbl( iv_vi = 'STT' iv_en = 'No.' ).
  gs_parameter-parameter02 = lcl_util=>lbl( iv_vi = 'Số PO' iv_en = 'PO No.' ).
  gs_parameter-parameter03 = lcl_util=>lbl( iv_vi = 'Mã hàng' iv_en = 'Goods code' ).
  gs_parameter-parameter04 = lcl_util=>lbl( iv_vi = 'Tên hàng' iv_en = 'Goods name - Description' ).
  gs_parameter-parameter05 = lcl_util=>lbl( iv_vi = 'Nồng độ - Hàm lượng' iv_en = 'Concentration/ content' ).
  gs_parameter-parameter06 = lcl_util=>lbl( iv_vi = 'Độ ẩm' iv_en = 'Water' ).
  gs_parameter-parameter07 = lcl_util=>lbl( iv_vi = 'NSX – Nước SX' iv_en = 'Manufacturer - Country' ).
  gs_parameter-parameter08 = lcl_util=>lbl( iv_vi = 'Số lô NSX' iv_en = 'Batch number' ).
  gs_parameter-parameter09 = lcl_util=>lbl( iv_vi = 'Số lô SAP' iv_en = 'SAP batch' ).
  gs_parameter-parameter10 = lcl_util=>lbl( iv_vi = 'Hạn dùng' iv_en = 'Exp. date' ).
  gs_parameter-parameter11 = lcl_util=>lbl( iv_vi = 'Quy cách' iv_en = 'Packaging' ).
  gs_parameter-parameter12 = lcl_util=>lbl( iv_vi = 'ĐVT' iv_en = 'Unit' ).
  gs_parameter-parameter13 = lcl_util=>lbl( iv_vi = 'Số lượng' iv_en = 'Quantity' ).
  gs_parameter-parameter14 = lcl_util=>lbl( iv_vi = 'SL quy đổi' iv_en = 'Conversion of quantity' ).
  gs_parameter-parameter15 = lcl_util=>lbl( iv_vi = 'ĐK bảo quản' iv_en = 'Storage conditions' ).
  gs_parameter-parameter16 = lcl_util=>lbl( iv_vi = 'Chứng từ kho' iv_en = 'Warehouse document' ).

  gs_parameter-footer01 = lcl_util=>lbl( iv_vi = 'Người lập phiếu' iv_en = 'Prepared by' ).
  gs_parameter-footer02 = lcl_util=>lbl( iv_vi = 'Thủ kho' iv_en = 'Warehouse-keeper' ).
  gs_parameter-footer04 = lcl_util=>lbl( iv_vi = 'Trưởng bộ phận' iv_en = 'Manager' ).
  gs_parameter-footer05 = 'Ngày ….. tháng ….. năm ……..'.
  gs_parameter-footer06 = lcl_util=>lbl( iv_vi = 'Trang' iv_en = 'Page' ).
  gs_parameter-sign01   = lcl_util=>lbl( iv_vi = 'Người lập phiếu/ Người giao'
                                         iv_en = 'Prepared by/ Deliverer' ).
  gs_parameter-sign02   = lcl_util=>lbl( iv_vi = '(Ký, ghi rõ họ tên)' iv_en = '(Signature, full name)' ).

ENDFORM.                    " GET_PARAMETER

*&---------------------------------------------------------------------*
*&      Form  PRINT_DOCS
*&---------------------------------------------------------------------*
*       Mẫu 1/2/4: mỗi chứng từ + SLoc 1 phiếu. Mẫu 3: các chứng từ đã chọn in chung 1 phiếu.
*----------------------------------------------------------------------*
FORM print_docs USING iv_preview TYPE abap_bool.

  DATA: lv_fm      TYPE rs38l_fnam,
        lv_form    TYPE tdsfname,
        ls_cparam  TYPE ssfctrlop,
        ls_output  TYPE ssfcompop,
        ls_job_opt TYPE ssfcresop,
        ls_job_inf TYPE ssfcrescl,
        lv_spld    TYPE usr01-spld,
        lv_doc     TYPE string,
        lt_grp     TYPE SORTED TABLE OF gty_grp WITH UNIQUE KEY mblnr mjahr lgort,
        lt_sheet   TYPE STANDARD TABLE OF gty_sheet WITH EMPTY KEY.

  DATA(lt_sel) = VALUE gtt_alv( FOR ls_a IN gt_alv WHERE ( sel = abap_true ) ( ls_a ) ).
  IF lt_sel IS INITIAL.
    MESSAGE s009 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_sel INTO DATA(ls_sel).
    lv_doc = |{ ls_sel-mblnr ALPHA = OUT }|.
    IF p_adj = abap_true AND ls_sel-adj_docs IS NOT INITIAL.
      PERFORM add_msg USING 'I' '005' lv_doc ls_sel-adj_docs space.
    ENDIF.
    IF ls_sel-print_count > 0 AND iv_preview = abap_false.
      PERFORM add_msg USING 'I' '006' lv_doc ls_sel-print_count space.
    ENDIF.
  ENDLOOP.
  PERFORM show_messages.

  IF p_op3 = abap_true.
    APPEND VALUE #( docs = lt_sel ) TO lt_sheet.
  ELSE.
    LOOP AT lt_sel INTO ls_sel.
      LOOP AT gt_item INTO DATA(ls_item) WHERE mblnr = ls_sel-mblnr AND mjahr = ls_sel-mjahr.
        INSERT VALUE #( mblnr = ls_item-mblnr mjahr = ls_item-mjahr lgort = ls_item-lgort )
               INTO TABLE lt_grp.
      ENDLOOP.
    ENDLOOP.
    LOOP AT lt_grp INTO DATA(ls_grp).
      APPEND VALUE #( docs  = VALUE #( ( lt_sel[ mblnr = ls_grp-mblnr mjahr = ls_grp-mjahr ] ) )
                      lgort = ls_grp-lgort ) TO lt_sheet.
    ENDLOOP.
  ENDIF.

  lv_form = COND #( WHEN p_op1 = abap_true THEN gc_form_op1
                    WHEN p_op2 = abap_true THEN gc_form_op2
                    WHEN p_op3 = abap_true THEN gc_form_op3
                    ELSE gc_form_op4 ).

  " Máy in mặc định của user, không có thì hiện hộp thoại chọn máy in
  SELECT SINGLE spld FROM usr01 WHERE bname = @sy-uname INTO @lv_spld.
  IF iv_preview = abap_true.
    ls_cparam-no_dialog = abap_true.
    ls_cparam-preview   = abap_true.
    ls_output-tddest    = COND #( WHEN lv_spld IS NOT INITIAL THEN lv_spld ELSE 'LP01' ).
  ELSE.
    IF lv_spld IS NOT INITIAL.
      ls_cparam-no_dialog = abap_true.
      ls_output-tddest    = lv_spld.
    ENDIF.
    ls_output-tdimmed = abap_true.
    ls_output-tdnewid = abap_true.
  ENDIF.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = lv_form
    IMPORTING
      fm_name            = lv_fm
    EXCEPTIONS
      OTHERS             = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'SSF_OPEN'
    EXPORTING
      control_parameters = ls_cparam
      output_options     = ls_output
      user_settings      = space
    IMPORTING
      job_output_options = ls_job_opt
    EXCEPTIONS
      OTHERS             = 1.
  IF sy-subrc <> 0.
    IF sy-msgid IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    ENDIF.
    RETURN.
  ENDIF.

  ls_cparam-no_open  = abap_true.
  ls_cparam-no_close = abap_true.

  PERFORM get_parameter.

  LOOP AT lt_sheet INTO DATA(ls_sheet).
    PERFORM fill_form USING ls_sheet-docs ls_sheet-lgort.
    CHECK gt_data IS NOT INITIAL.

    CALL FUNCTION lv_fm
      EXPORTING
        control_parameters = ls_cparam
        output_options     = ls_output
        user_settings      = space
        gs_parameter       = gs_parameter
      TABLES
        it_data            = gt_data
      EXCEPTIONS
        OTHERS             = 1.
    IF sy-subrc <> 0.
      IF sy-msgid IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
      ENDIF.
      EXIT.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'SSF_CLOSE'
    IMPORTING
      job_output_info = ls_job_inf
    EXCEPTIONS
      OTHERS          = 1.
  IF sy-subrc <> 0.
    IF sy-msgid IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    ENDIF.
    RETURN.
  ENDIF.

  CHECK ls_job_inf-outputdone = abap_true.

  PERFORM write_prtlog USING lt_sel.

  IF iv_preview = abap_true.
    LOOP AT lt_sel INTO ls_sel WHERE print_count > 0.
      MESSAGE i006 WITH |{ ls_sel-mblnr ALPHA = OUT }| ls_sel-print_count.
    ENDLOOP.
  ENDIF.

  PERFORM read_print_count.
  go_alv->refresh( ).

ENDFORM.                    " PRINT_DOCS

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM
*&---------------------------------------------------------------------*
FORM fill_form USING it_doc   TYPE gtt_alv
                     iv_lgort TYPE lgort_d.

  DATA: lt_line     TYPE gtt_line,
        ls_hdr      TYPE gty_hdr,
        ls_plant    TYPE gty_partner,
        ls_plant_en TYPE gty_partner,
        ls_comp     TYPE gty_partner,
        lv_cnt      TYPE i,
        lv_qi       TYPE abap_bool,
        lv_knl      TYPE abap_bool,
        lv_docs     TYPE string.

  CLEAR gt_data.

  LOOP AT it_doc INTO DATA(ls_doc).
    lv_cnt = nmax( val1 = lv_cnt val2 = ls_doc-print_count ).
    LOOP AT gt_item INTO DATA(ls_i) WHERE mblnr = ls_doc-mblnr AND mjahr = ls_doc-mjahr.
      CHECK iv_lgort IS INITIAL OR ls_i-lgort = iv_lgort.
      APPEND ls_i TO lt_line.
    ENDLOOP.
  ENDLOOP.

  READ TABLE lt_line INTO DATA(ls_first) INDEX 1.
  CHECK sy-subrc = 0.

  " Mẫu 3 hoặc nhập vào tồn QI: tiêu đề phiếu chờ kiểm nghiệm
  lv_qi = xsdbool( p_op3 = abap_true OR line_exists( lt_line[ insmk = gc_insmk_qi ] ) ).
  IF lv_qi = abap_true.
    gs_parameter-title_report    = 'PHIẾU NHẬP KHO CHỜ KIỂM NGHIỆM'.
    gs_parameter-title_report_en = COND #( WHEN p_isn = abap_true
                                           THEN 'GOODS RECEIPT WAITING FOR QUALITY CONTROL' ).
  ELSE.
    gs_parameter-title_report    = 'PHIẾU NHẬP KHO'.
    gs_parameter-title_report_en = COND #( WHEN p_isn = abap_true THEN 'GOODS RECEIPT SLIP' ).
  ENDIF.

  PERFORM read_partner USING 'P' ls_first-werks CHANGING ls_plant.
  PERFORM read_partner USING 'C' ls_first-bukrs CHANGING ls_comp.
  gs_parameter-header01 = to_upper( ls_plant-name ).
  gs_parameter-header02 = ls_plant-address.
  gs_parameter-header03 = |{ lcl_util=>lbl_c( iv_vi = 'Điện thoại' iv_en = 'Tel' ) } { ls_plant-tel }|.
  gs_parameter-header04 = |Fax: { ls_plant-fax }|.
  gs_parameter-header05 = |{ lcl_util=>lbl_c( iv_vi = 'MST' iv_en = 'TIN' ) } { ls_comp-tax }|.
  gs_parameter-header06 = |Website: { ls_plant-remark }|.
  CLEAR: gs_parameter-header39, gs_parameter-header40.
  IF p_isn = abap_true.
    PERFORM read_partner USING 'Q' ls_first-werks CHANGING ls_plant_en.
    gs_parameter-header39 = to_upper( ls_plant_en-name ).
    gs_parameter-header40 = ls_plant_en-address.
  ENDIF.

  gs_parameter-header08 = COND #(
    WHEN p_isn = abap_true
    THEN |Ngày/ Date { ls_first-budat+6(2) } tháng/ month { ls_first-budat+4(2) } năm/ year { ls_first-budat(4) }|
    ELSE |Ngày { ls_first-budat+6(2) } tháng { ls_first-budat+4(2) } năm { ls_first-budat(4) }| ).

  PERFORM resolve_header USING ls_first abap_true CHANGING ls_hdr.
  gs_parameter-header10 = ls_hdr-name.
  gs_parameter-header13 = ls_hdr-code.
  gs_parameter-header15 = ls_hdr-address.
  gs_parameter-header17 = ls_hdr-tax.
  gs_parameter-header30 = ls_hdr-waers.
  gs_parameter-header31 = ls_hdr-kursf.
  gs_parameter-header32 = COND #( WHEN p_op3 = abap_true THEN space ELSE ls_first-mblnr ).
  gs_parameter-header33 = ls_hdr-belnr.
  gs_parameter-header34 = ls_hdr-sohd.
  gs_parameter-header35 = ls_hdr-ngayhd.
  gs_parameter-header28 = COND #( WHEN p_isn = abap_true AND ls_hdr-descr_en IS NOT INITIAL
                                  THEN |{ ls_hdr-descr }/ { ls_hdr-descr_en }|
                                  ELSE ls_hdr-descr ).

  DATA(ls_lgort) = VALUE gty_lgort( gt_lgort[ werks = ls_first-werks lgort = ls_first-lgort ] OPTIONAL ).
  gs_parameter-header26 = |{ ls_first-lgort } – { ls_lgort-lgobe }|.

  gs_parameter-iso_line01 = COND #( WHEN lv_cnt = 0 THEN |Lần in: 1|
                                    ELSE |Bản in lại – lần { lv_cnt + 1 }| ).
  gs_parameter-footer07   = COND #( WHEN lv_cnt = 0 THEN space
                                    ELSE |Bản in lại – lần { lv_cnt + 1 }| ).
  gs_parameter-footer03   = |In lúc: { sy-datum+6(2) }/{ sy-datum+4(2) }/{ sy-datum(4) } | &&
                            |{ sy-uzeit(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) } – User: { sy-uname }|.

  PERFORM fill_form_lines USING lt_line CHANGING lv_knl.

  gs_parameter-parameter10 = COND #( WHEN lv_knl = abap_true
                                     THEN lcl_util=>lbl( iv_vi = 'Hạn dùng/ Ngày KNL'
                                                         iv_en = 'Exp. date/ Retest date' )
                                     ELSE lcl_util=>lbl( iv_vi = 'Hạn dùng' iv_en = 'Exp. date' ) ).

  IF p_adj = abap_true.
    LOOP AT it_doc INTO ls_doc.
      READ TABLE gt_docadj INTO DATA(ls_adj)
           WITH TABLE KEY mblnr = ls_doc-mblnr mjahr = ls_doc-mjahr.
      CHECK sy-subrc = 0 AND ls_adj-rev_docs IS NOT INITIAL.
      lv_docs = COND #( WHEN lv_docs IS INITIAL THEN ls_adj-rev_docs
                        ELSE |{ lv_docs }, { ls_adj-rev_docs }| ).
    ENDLOOP.
    gs_parameter-long_text1 = COND #( WHEN lv_docs IS NOT INITIAL
                                      THEN |Số lượng đã trừ chứng từ điều chỉnh: { lv_docs }| ).
  ELSE.
    gs_parameter-long_text1 = 'Số lượng gốc của dòng, chưa trừ chứng từ điều chỉnh (bản đối chiếu).'.
  ENDIF.

ENDFORM.                    " FILL_FORM

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM_LINES
*&---------------------------------------------------------------------*
FORM fill_form_lines USING it_line TYPE gtt_line
                     CHANGING cv_knl TYPE abap_bool.

  DATA: ls_data    TYPE zwm_st_pnk,
        ls_first   TYPE gty_item,
        ls_partner TYPE gty_partner,
        lv_stt     TYPE i,
        lv_menge   TYPE menge_d,
        lv_erfmg   TYPE erfmg,
        lv_first   TYPE abap_bool,
        lv_nsx     TYPE char255,
        lv_land1   TYPE land1,
        lv_nuoc    TYPE char255,
        lv_mfrnr   TYPE mfrnr.

  DATA(lt_line) = it_line.
  IF p_op3 = abap_true.
    SORT lt_line BY matnr lgort mblnr zeile.
  ELSE.
    SORT lt_line BY mblnr lgort zeile.
  ENDIF.

  LOOP AT lt_line INTO DATA(ls_item)
       GROUP BY ( mblnr = ls_item-mblnr mjahr = ls_item-mjahr
                  matnr = ls_item-matnr ematn = ls_item-ematn
                  charg = ls_item-charg lgort = ls_item-lgort
                  erfme = ls_item-erfme ebeln = ls_item-ebeln )
       INTO DATA(lg_mat).

    CLEAR: ls_data, lv_menge, lv_erfmg.
    lv_first = abap_true.
    LOOP AT GROUP lg_mat INTO DATA(ls_line).
      IF lv_first = abap_true.
        ls_first = ls_line.
        lv_first = abap_false.
      ENDIF.
      IF p_adj = abap_true.
        lv_menge = lv_menge + ls_line-menge_net.
        lv_erfmg = lv_erfmg + ls_line-erfmg_net.
      ELSE.
        lv_menge = lv_menge + ls_line-menge.
        lv_erfmg = lv_erfmg + ls_line-erfmg.
      ENDIF.
    ENDLOOP.

    lv_stt = lv_stt + 1.
    ls_data-stt   = lv_stt.
    ls_data-mblnr = lg_mat-mblnr.
    ls_data-ebeln = lg_mat-ebeln.
    ls_data-matnr = lg_mat-matnr.
    ls_data-charg = lg_mat-charg.
    ls_data-lgort = lg_mat-lgort.
    ls_data-werks = ls_first-werks.
    ls_data-erfme = lg_mat-erfme.
    ls_data-erfmg = lv_erfmg.

    DATA(ls_mat) = VALUE gty_mat( gt_mat[ matnr = lg_mat-matnr ] OPTIONAL ).
    DATA(ls_bat) = VALUE gty_batch( gt_batch[ matnr = lg_mat-matnr
                                              werks = ls_first-werks
                                              charg = lg_mat-charg ] OPTIONAL ).

    IF lg_mat-matnr IS NOT INITIAL.
      ls_data-maktx = VALUE #( gt_makt[ matnr = lg_mat-matnr spras = gc_spras_vi ]-maktx OPTIONAL ).
      DATA(lv_maktx_en) = VALUE maktx( gt_makt[ matnr = lg_mat-matnr spras = gc_spras_en ]-maktx OPTIONAL ).
      IF ls_data-maktx IS INITIAL.
        ls_data-maktx = lv_maktx_en.
      ENDIF.
      IF p_isn = abap_true.
        ls_data-maktx_en = lv_maktx_en.
      ENDIF.
    ELSE.
      ls_data-maktx = ls_first-txz01.
    ENDIF.

    IF p_op1 = abap_true.
      ls_data-nodhl = ls_bat-z_nongdo.
      ls_data-doam  = COND #( WHEN ls_bat-z_doam1 IS NOT INITIAL THEN ls_bat-z_doam1
                              ELSE ls_bat-z_doam2 ).
    ENDIF.

    " NSX: Z_NSX của lô, không có thì NSX theo MPN
    CLEAR: lv_nsx, lv_land1, lv_nuoc.
    IF ls_bat-z_nsx IS NOT INITIAL.
      IF ls_bat-z_nsx CO '0123456789 '.
        PERFORM read_partner USING 'K' ls_bat-z_nsx CHANGING ls_partner.
        lv_nsx   = ls_partner-name.
        lv_land1 = ls_partner-land1.
      ENDIF.
      IF lv_nsx IS INITIAL.
        lv_nsx = ls_bat-z_nsx.
      ENDIF.
    ELSE.
      lv_mfrnr = ls_mat-mfrnr.
      IF lv_mfrnr IS INITIAL AND lg_mat-ematn IS NOT INITIAL.
        lv_mfrnr = VALUE #( gt_mat[ matnr = lg_mat-ematn ]-mfrnr OPTIONAL ).
      ENDIF.
      IF lv_mfrnr IS NOT INITIAL.
        PERFORM read_partner USING 'K' lv_mfrnr CHANGING ls_partner.
        lv_nsx   = ls_partner-name.
        lv_land1 = ls_partner-land1.
      ENDIF.
    ENDIF.

    " Nước SX: Z_NUOC_SX của lô, rồi MARC-HERKL, rồi nước của NSX
    IF ls_bat-z_nuoc IS NOT INITIAL.
      PERFORM get_country USING ls_bat-z_nuoc CHANGING lv_nuoc.
    ELSE.
      DATA(lv_herkl) = VALUE herkl( gt_marc[ matnr = lg_mat-matnr
                                             werks = ls_first-werks ]-herkl OPTIONAL ).
      IF lv_herkl IS NOT INITIAL.
        PERFORM get_country USING lv_herkl CHANGING lv_nuoc.
      ELSEIF lv_land1 IS NOT INITIAL.
        PERFORM get_country USING lv_land1 CHANGING lv_nuoc.
      ENDIF.
    ENDIF.

    ls_data-nsxns = COND #( WHEN lv_nsx IS NOT INITIAL AND lv_nuoc IS NOT INITIAL
                              THEN |{ lv_nsx } - { lv_nuoc }|
                            WHEN lv_nsx IS NOT INITIAL THEN lv_nsx
                            ELSE lv_nuoc ).

    ls_data-solo = COND #( WHEN ls_bat-z_lonsx IS NOT INITIAL THEN ls_bat-z_lonsx
                           WHEN ls_bat-licha   IS NOT INITIAL THEN ls_bat-licha
                           ELSE lg_mat-charg ).

    " Hạn dùng: SLED; trống và vật tư thuộc nhóm có retest thì lấy Ngày KNL
    ls_data-handung = ls_bat-vfdat.
    IF ls_data-handung IS INITIAL AND gr_mtart_knl IS NOT INITIAL
       AND ls_mat-mtart IN gr_mtart_knl AND ls_bat-qndat IS NOT INITIAL.
      ls_data-handung = ls_bat-qndat.
      cv_knl = abap_true.
    ENDIF.

    ls_data-groes = COND #( WHEN ls_bat-quycach IS NOT INITIAL THEN ls_bat-quycach
                            ELSE ls_mat-groes ).

    IF p_isn = abap_true AND lg_mat-erfme IS NOT INITIAL.
      ls_data-erfme_en = VALUE #( gt_unit_en[ msehi = lg_mat-erfme ]-msehl OPTIONAL ).
    ENDIF.

    IF p_op1 = abap_false.
      PERFORM calc_convert USING lg_mat-matnr lv_menge lv_erfmg lg_mat-erfme ls_first-meins
                           CHANGING ls_data-quydoi.
      ls_data-baoquan = COND #( WHEN ls_bat-baoquan IS NOT INITIAL THEN ls_bat-baoquan
                                ELSE ls_mat-raube_txt ).
    ENDIF.

    APPEND ls_data TO gt_data.
  ENDLOOP.

ENDFORM.                    " FILL_FORM_LINES

*&---------------------------------------------------------------------*
*&      Form  CALC_CONVERT
*&---------------------------------------------------------------------*
*       Mẫu 4: SL x tỷ lệ quy đổi. Mẫu 2/3: tách theo 2 đơn vị lớn nhất.
*----------------------------------------------------------------------*
FORM calc_convert USING iv_matnr TYPE matnr
                        iv_menge TYPE menge_d
                        iv_erfmg TYPE erfmg
                        iv_erfme TYPE erfme
                        iv_meins TYPE meins
                  CHANGING cv_text TYPE any.

  DATA: lv_in   TYPE f,
        lv_out  TYPE f,
        lv_base TYPE meins,
        lv_val  TYPE p LENGTH 16 DECIMALS 5,
        lv_r1   TYPE p LENGTH 16 DECIMALS 6,
        lv_r2   TYPE p LENGTH 16 DECIMALS 6,
        lv_a    TYPE p LENGTH 15 DECIMALS 0,
        lv_b    TYPE p LENGTH 15 DECIMALS 0,
        lv_c    TYPE p LENGTH 15 DECIMALS 0,
        lv_d    TYPE p LENGTH 15 DECIMALS 0,
        lv_idx  TYPE sy-tabix,
        lv_unit TYPE c LENGTH 10,
        lv_u1   TYPE string,
        lv_u2   TYPE string,
        lv_txt  TYPE string.

  CLEAR cv_text.
  CHECK iv_matnr IS NOT INITIAL AND iv_menge > 0.

  IF p_op4 = abap_true.
    lv_in   = iv_erfmg.
    lv_base = iv_meins.
    TRY.
        cl_md_product_unit_conversion=>convert(
          EXPORTING input              = lv_in
                    is_alternativeunit = abap_true
                    product            = iv_matnr
                    alternativeunit    = iv_erfme
          IMPORTING output             = lv_out
          CHANGING  baseunit           = lv_base ).
      CATCH cx_md_product_unit_conversion.
        RETURN.
    ENDTRY.
    lv_val = lv_out.
    CHECK lv_val <> 0.
    WRITE iv_meins TO lv_unit.
    cv_text = |{ lcl_util=>num_text( iv_val = lv_val iv_dec = 5 ) } { lv_unit }|.
    RETURN.
  ENDIF.

  READ TABLE gt_marm TRANSPORTING NO FIELDS WITH KEY matnr = iv_matnr BINARY SEARCH.
  CHECK sy-subrc = 0.
  lv_idx = sy-tabix.
  READ TABLE gt_marm INTO DATA(ls_u1) INDEX lv_idx.
  CHECK ls_u1-ratio > 0.
  lv_idx = lv_idx + 1.
  READ TABLE gt_marm INTO DATA(ls_u2) INDEX lv_idx.
  IF sy-subrc <> 0 OR ls_u2-matnr <> iv_matnr.
    CLEAR ls_u2.
  ENDIF.

  lv_r1 = ls_u1-ratio.
  lv_b  = floor( iv_menge / lv_r1 ).
  IF ls_u2-ratio > 0.
    lv_r2 = ls_u2-ratio.
    lv_a  = floor( iv_menge / lv_r2 ).
    lv_c  = floor( lv_r1 / lv_r2 ).
    lv_d  = lv_a - lv_b * lv_c.
  ENDIF.

  lv_u1 = COND #( WHEN ls_u1-mseh6 IS NOT INITIAL THEN ls_u1-mseh6 ELSE ls_u1-meinh ).
  lv_u2 = COND #( WHEN ls_u2-mseh6 IS NOT INITIAL THEN ls_u2-mseh6 ELSE ls_u2-meinh ).

  IF lv_b <> 0.
    lv_txt = |{ lv_b } { lv_u1 }|.
  ENDIF.
  IF lv_d <> 0.
    lv_txt = condense( |{ lv_txt } { lv_d } { lv_u2 }| ).
  ENDIF.
  cv_text = lv_txt.

ENDFORM.                    " CALC_CONVERT

*&---------------------------------------------------------------------*
*&      Form  RESOLVE_HEADER
*&---------------------------------------------------------------------*
*       IV_FULL = space: chỉ lấy mã đối tác và diễn giải (màn hình trung gian).
*----------------------------------------------------------------------*
FORM resolve_header USING is_line TYPE gty_item
                          iv_full TYPE abap_bool
                    CHANGING cs_hdr TYPE gty_hdr.

  DATA: ls_partner TYPE gty_partner,
        lv_issue   TYPE mblnr,
        lv_text    TYPE char255,
        lv_dlv     TYPE vbeln_vl,
        lv_werks   TYPE werks_d,
        lv_awkey   TYPE awkey.

  CLEAR cs_hdr.

  " Đối tác: kho xuất 305/315, lệnh SX, STO, khách hàng, NCC, Cost Center
  IF ( is_line-bwart = gc_bwart_305 OR is_line-bwart = gc_bwart_315 )
     AND is_line-xblnr IS NOT INITIAL.
    lv_issue = is_line-xblnr.
    DATA(ls_issue) = VALUE gty_issue( gt_issue[ mblnr = lv_issue ] OPTIONAL ).
    IF ls_issue-mblnr IS NOT INITIAL.
      cs_hdr-name     = |{ ls_issue-lgort } - { ls_issue-lgobe }|.
      cs_hdr-code     = ls_issue-lgort.
      cs_hdr-p_kind   = 'P'.
      cs_hdr-p_number = ls_issue-werks.
    ENDIF.
  ELSEIF is_line-aufnr IS NOT INITIAL.
    DATA(ls_resb) = VALUE gty_resb( gt_resb[ aufnr = is_line-aufnr ] OPTIONAL ).
    IF ls_resb-aufnr IS NOT INITIAL.
      lv_text = ls_resb-lgobe.
      REPLACE ALL OCCURRENCES OF 'NVL' IN lv_text WITH ''.
      CONDENSE lv_text.
      cs_hdr-name = |Phân xưởng { lv_text }|.
      cs_hdr-code = ls_resb-lgort.
    ENDIF.
  ELSEIF is_line-reswk IS NOT INITIAL.
    DATA(ls_sto) = VALUE gty_lgort( gt_lgort[ werks = is_line-reswk lgort = is_line-reslo ] OPTIONAL ).
    cs_hdr-name     = ls_sto-lgobe.
    cs_hdr-code     = COND #( WHEN is_line-reslo IS NOT INITIAL THEN is_line-reslo ELSE is_line-reswk ).
    cs_hdr-p_kind   = 'P'.
    cs_hdr-p_number = is_line-reswk.
  ELSEIF is_line-kunnr IS NOT INITIAL.
    cs_hdr-code     = |{ is_line-kunnr ALPHA = OUT }|.
    cs_hdr-p_kind   = 'D'.
    cs_hdr-p_number = is_line-kunnr.
  ELSEIF is_line-lifnr IS NOT INITIAL.
    cs_hdr-code     = |{ is_line-lifnr ALPHA = OUT }|.
    cs_hdr-p_kind   = 'K'.
    cs_hdr-p_number = is_line-lifnr.
  ELSEIF is_line-kostl IS NOT INITIAL.
    cs_hdr-name = VALUE #( gt_cskt[ kokrs = is_line-kokrs kostl = is_line-kostl ]-ktext OPTIONAL ).
    cs_hdr-code = is_line-kostl.
  ENDIF.

  " Diễn giải theo ZTWM_MVT_GRP, không có thì lấy Header text
  IF is_line-grp_found = abap_true.
    cs_hdr-descr    = is_line-txt_vi.
    cs_hdr-descr_en = is_line-txt_en.
    IF is_line-grp_code = gc_grp_dc AND is_line-reslo IS NOT INITIAL.
      lv_werks = COND #( WHEN is_line-reswk IS NOT INITIAL THEN is_line-reswk ELSE is_line-werks ).
      DATA(lv_lgobe) = VALUE lgobe( gt_lgort[ werks = lv_werks lgort = is_line-reslo ]-lgobe OPTIONAL ).
      lv_text = |{ is_line-reslo } - { lv_lgobe }|.
      cs_hdr-descr = |{ cs_hdr-descr } { lv_text }|.
      IF cs_hdr-descr_en IS NOT INITIAL.
        cs_hdr-descr_en = |{ cs_hdr-descr_en } { lv_text }|.
      ENDIF.
    ENDIF.
  ELSE.
    cs_hdr-descr = is_line-bktxt.
  ENDIF.

  CHECK iv_full = abap_true.

  IF cs_hdr-p_kind IS NOT INITIAL.
    PERFORM read_partner USING cs_hdr-p_kind cs_hdr-p_number CHANGING ls_partner.
    IF cs_hdr-name IS INITIAL.
      cs_hdr-name = ls_partner-name.
    ENDIF.
    cs_hdr-address = ls_partner-address.
    IF cs_hdr-p_kind CA 'KD'.
      cs_hdr-tax = ls_partner-tax.
    ENDIF.
  ENDIF.

  lv_awkey = |{ is_line-mblnr }{ is_line-mjahr }|.
  DATA(ls_bkpf) = VALUE gty_bkpf( gt_bkpf[ awkey = lv_awkey ] OPTIONAL ).
  IF ls_bkpf-awkey IS NOT INITIAL.
    cs_hdr-belnr = ls_bkpf-belnr.
    cs_hdr-waers = ls_bkpf-waers.
    cs_hdr-kursf = lcl_util=>num_text( iv_val = ls_bkpf-kursf iv_dec = 5 ).
  ELSE.
    cs_hdr-waers = is_line-po_waers.
  ENDIF.

  " Số/ngày hóa đơn gốc theo nhóm nghiệp vụ
  CASE is_line-grp_code.
    WHEN gc_grp_th.
      lv_dlv = COND #( WHEN is_line-vbeln_im IS NOT INITIAL THEN is_line-vbeln_im
                       ELSE is_line-le_vbeln ).
      IF lv_dlv IS NOT INITIAL.
        PERFORM read_text USING gc_txt_sohd 'VBBK' lv_dlv CHANGING cs_hdr-sohd.
        PERFORM read_text USING gc_txt_ngayhd 'VBBK' lv_dlv CHANGING cs_hdr-ngayhd.
      ENDIF.
    WHEN gc_grp_sx.
      IF is_line-aufnr IS NOT INITIAL.
        cs_hdr-sohd = |LSX { is_line-aufnr ALPHA = OUT }|.
      ENDIF.
    WHEN gc_grp_mh.
      cs_hdr-sohd   = is_line-bktxt.
      cs_hdr-ngayhd = lcl_util=>date_text( is_line-bldat ).
  ENDCASE.

ENDFORM.                    " RESOLVE_HEADER

*&---------------------------------------------------------------------*
*&      Form  READ_TEXT
*&---------------------------------------------------------------------*
FORM read_text USING iv_id     TYPE tdid
                     iv_object TYPE c
                     iv_name   TYPE any
               CHANGING cv_text TYPE any.

  DATA: lv_name TYPE tdobname,
        lv_obj  TYPE tdobject,
        lv_text TYPE char255.

  CLEAR cv_text.
  CHECK iv_id IS NOT INITIAL AND iv_name IS NOT INITIAL.

  lv_name = iv_name.
  lv_obj  = iv_object.
  CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
    EXPORTING
      i_tdid      = iv_id
      i_tdname    = lv_name
      i_tdobject  = lv_obj
      i_tdspras   = sy-langu
    IMPORTING
      e_long_text = lv_text.
  cv_text = lv_text.

ENDFORM.                    " READ_TEXT

*&---------------------------------------------------------------------*
*&      Form  READ_PARTNER
*&---------------------------------------------------------------------*
*       Loại: K nhà cung cấp, D khách hàng, P Plant, Q Plant (địa chỉ quốc tế), C Company Code.
*----------------------------------------------------------------------*
FORM read_partner USING iv_kind   TYPE char1
                        iv_number TYPE any
                  CHANGING cs_partner TYPE gty_partner.

  DATA lv_num TYPE char10.

  CLEAR cs_partner.
  lv_num = iv_number.
  CONDENSE lv_num.
  CHECK lv_num IS NOT INITIAL.
  IF ( iv_kind = 'K' OR iv_kind = 'D' ) AND lv_num CO '0123456789'.
    lv_num = |{ lv_num ALPHA = IN WIDTH = 10 }|.
  ENDIF.

  READ TABLE gt_partner INTO cs_partner WITH TABLE KEY kind = iv_kind number = lv_num.
  CHECK sy-subrc <> 0.

  cs_partner-kind   = iv_kind.
  cs_partner-number = lv_num.
  IF iv_kind = 'Q'.
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        i_number     = lv_num
        i_kind       = 'P'
        i_nation     = 'I'
      IMPORTING
        e_name       = cs_partner-name
        e_address    = cs_partner-address.
  ELSE.
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        i_number     = lv_num
        i_kind       = iv_kind
      IMPORTING
        e_name       = cs_partner-name
        e_address    = cs_partner-address
        e_tax        = cs_partner-tax
        e_tel_number = cs_partner-tel
        e_fax_number = cs_partner-fax
        e_remark     = cs_partner-remark.
  ENDIF.
  IF iv_kind = 'K'.
    SELECT SINGLE land1 FROM lfa1 WHERE lifnr = @lv_num INTO @cs_partner-land1.
  ELSEIF iv_kind = 'D'.
    SELECT SINGLE land1 FROM kna1 WHERE kunnr = @lv_num INTO @cs_partner-land1.
  ENDIF.
  INSERT cs_partner INTO TABLE gt_partner.

ENDFORM.                    " READ_PARTNER

*&---------------------------------------------------------------------*
*&      Form  GET_COUNTRY
*&---------------------------------------------------------------------*
FORM get_country USING iv_text TYPE csequence
                 CHANGING cv_landx TYPE any.

  DATA: ls_country TYPE gty_country,
        lv_land1   TYPE land1.

  cv_landx = iv_text.
  CHECK iv_text IS NOT INITIAL AND strlen( iv_text ) <= 3.

  lv_land1 = iv_text.
  READ TABLE gt_country INTO ls_country WITH TABLE KEY land1 = lv_land1.
  IF sy-subrc <> 0.
    ls_country-land1 = lv_land1.
    SELECT SINGLE landx50 FROM t005t
      WHERE spras = @sy-langu
        AND land1 = @lv_land1
      INTO @ls_country-landx.
    INSERT ls_country INTO TABLE gt_country.
  ENDIF.
  IF ls_country-landx IS NOT INITIAL.
    cv_landx = ls_country-landx.
  ENDIF.

ENDFORM.                    " GET_COUNTRY

*&---------------------------------------------------------------------*
*&      Form  WRITE_PRTLOG
*&---------------------------------------------------------------------*
*       Mỗi chứng từ 1 bản ghi, cộng số lần in trực tiếp trên DB.
*----------------------------------------------------------------------*
FORM write_prtlog USING it_doc TYPE gtt_alv.

  DATA(lv_opt) = COND zewm_de_rpt_opt( WHEN p_op1 = abap_true THEN '1'
                                       WHEN p_op2 = abap_true THEN '2'
                                       WHEN p_op3 = abap_true THEN '3'
                                       ELSE '4' ).

  LOOP AT it_doc INTO DATA(ls_doc).
    UPDATE ztwm_prtlog
      SET prt_count = prt_count + 1,
          rpt_opt   = @lv_opt,
          last_date = @sy-datum,
          last_time = @sy-uzeit,
          last_user = @sy-uname
      WHERE tcode    = @gc_tcode
        AND formname = @gc_prt_form
        AND obj_key  = @ls_doc-obj_key.
    CHECK sy-dbcnt = 0.

    DATA(ls_item) = VALUE gty_item( gt_item[ mblnr = ls_doc-mblnr mjahr = ls_doc-mjahr ] OPTIONAL ).
    INSERT ztwm_prtlog FROM @( VALUE ztwm_prtlog( tcode      = gc_tcode
                                                  formname   = gc_prt_form
                                                  obj_key    = ls_doc-obj_key
                                                  rpt_opt    = lv_opt
                                                  werks      = ls_doc-werks
                                                  lgort      = ls_item-lgort
                                                  prt_count  = 1
                                                  first_date = sy-datum
                                                  first_time = sy-uzeit
                                                  first_user = sy-uname
                                                  last_date  = sy-datum
                                                  last_time  = sy-uzeit
                                                  last_user  = sy-uname ) ).
    IF sy-subrc <> 0.
      " User khác vừa tạo cùng khóa: cộng vào bản ghi đó
      UPDATE ztwm_prtlog
        SET prt_count = prt_count + 1,
            rpt_opt   = @lv_opt,
            last_date = @sy-datum,
            last_time = @sy-uzeit,
            last_user = @sy-uname
        WHERE tcode    = @gc_tcode
          AND formname = @gc_prt_form
          AND obj_key  = @ls_doc-obj_key.
    ENDIF.
  ENDLOOP.
  COMMIT WORK.

ENDFORM.                    " WRITE_PRTLOG

*&---------------------------------------------------------------------*
*&      Form  F4_HELP_MBLNR
*&---------------------------------------------------------------------*
FORM f4_help_mblnr CHANGING cv_mblnr TYPE matdoc-mblnr.

  DATA: lv_flag  TYPE c LENGTH 1 VALUE 'X',
        lv_mjahr TYPE mjahr,
        lt_dynp  TYPE STANDARD TABLE OF dynpread.

  EXPORT flag = lv_flag TO MEMORY ID 'MB51_FLAG'.
  CALL TRANSACTION 'MB51' WITH AUTHORITY-CHECK.
  GET PARAMETER ID 'MBN' FIELD cv_mblnr.
  GET PARAMETER ID 'MJA' FIELD lv_mjahr.

  CHECK lv_mjahr IS NOT INITIAL.
  APPEND VALUE #( fieldname = 'P_MJAHR' fieldvalue = lv_mjahr ) TO lt_dynp.
  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-cprog
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp
    EXCEPTIONS
      OTHERS     = 1.

ENDFORM.                    " F4_HELP_MBLNR
