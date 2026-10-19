*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PXK_F01
*&---------------------------------------------------------------------*

CLASS lcl_util IMPLEMENTATION.

  METHOD lbl.
    rv_text = COND #( WHEN gv_bi = abap_true AND iv_en IS NOT INITIAL
                      THEN |{ iv_vi }/ { iv_en }|
                      ELSE iv_vi ).
  ENDMETHOD.

  METHOD lbl_c.
    rv_text = |{ lbl( iv_vi = iv_vi iv_en = iv_en ) }:|.
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
*       MvT khai báo ở ZTWM_MVT_GRP, bỏ nhóm chuyển kho / chuyển trạng thái (ZWM05).
*----------------------------------------------------------------------*
FORM get_mvt_group .

  SELECT bwart, seqnr, sobkz, aufnr_flg, bsart, pstyp, werks,
         grp_code, txt_vi, txt_en, rev_bwart
    FROM ztwm_mvt_grp
    WHERE grp_code NOT IN ( @gc_grp_dc, @gc_grp_tt, @gc_grp_vt )
    INTO CORRESPONDING FIELDS OF TABLE @gt_mvt.

ENDFORM.                    " GET_MVT_GROUP

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       Dòng xuất (Credit), bỏ chứng từ đảo và dòng sinh tự động.
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
    LEFT OUTER JOIN lips ON lips~vbeln = matdoc~vbeln_im
                        AND lips~posnr = matdoc~vbelp_im
    LEFT OUTER JOIN likp ON likp~vbeln = matdoc~vbeln_im
    FIELDS matdoc~mblnr,
           matdoc~mjahr,
           matdoc~zeile,
           matdoc~bwart,
           matdoc~sobkz,
           matdoc~budat,
           matdoc~bldat,
           matdoc~bktxt,
           matdoc~usnam,
           matdoc~bukrs,
           matdoc~werks,
           matdoc~lgort,
           matdoc~matnr,
           matdoc~charg,
           matdoc~menge,
           matdoc~meins,
           matdoc~erfmg,
           matdoc~erfme,
           matdoc~aufnr,
           matdoc~kostl,
           matdoc~kokrs,
           matdoc~anln1,
           matdoc~anln2,
           matdoc~lifnr,
           matdoc~kunnr,
           matdoc~vbeln_im,
           matdoc~vbelp_im,
           lips~aufnr AS lips_aufnr,
           likp~kunnr AS shipto
    WHERE matdoc~record_type = 'MDOC'
      AND matdoc~werks IN @s_werks
      AND matdoc~mblnr IN @s_mblnr
      AND matdoc~mjahr IN @lr_mjahr
      AND matdoc~budat IN @s_budat
      AND matdoc~bwart IN @s_bwart
      AND matdoc~bwart IN @lr_bwart
      AND matdoc~lgort IN @s_lgort
      AND matdoc~vbeln_im IN @s_vbeln
      AND matdoc~kostl IN @s_kostl
      AND matdoc~usnam IN @s_usnam
      AND ( matdoc~aufnr IN @s_aufnr OR lips~aufnr IN @s_aufnr )
      AND matdoc~shkzg = 'H'
      AND matdoc~smbln = @space
      AND matdoc~xauto = @space
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

  DATA(lt_key) = VALUE gtt_line( FOR ls_i IN gt_item
                                 ( werks = ls_i-werks lgort = ls_i-lgort bwart = ls_i-bwart ) ).
  SORT lt_key BY werks lgort bwart.
  DELETE ADJACENT DUPLICATES FROM lt_key COMPARING werks lgort bwart.

  LOOP AT lt_key INTO DATA(ls_key).
    AUTHORITY-CHECK OBJECT 'M_MSEG_WWA'
      ID 'ACTVT' FIELD '03'
      ID 'WERKS' FIELD ls_key-werks.
    lv_ok = xsdbool( sy-subrc = 0 ).
    IF lv_ok = abap_true.
      AUTHORITY-CHECK OBJECT 'M_MSEG_BWA'
        ID 'ACTVT' FIELD '03'
        ID 'BWART' FIELD ls_key-bwart.
      lv_ok = xsdbool( sy-subrc = 0 ).
    ENDIF.
    IF lv_ok = abap_true.
      AUTHORITY-CHECK OBJECT 'M_MSEG_LGO'
        ID 'ACTVT' FIELD '03'
        ID 'WERKS' FIELD ls_key-werks
        ID 'LGORT' FIELD ls_key-lgort
        ID 'BWART' FIELD ls_key-bwart.
      lv_ok = xsdbool( sy-subrc = 0 ).
    ENDIF.
    CHECK lv_ok = abap_false.

    IF lv_werks IS INITIAL.
      lv_werks = ls_key-werks.
      lv_bwart = ls_key-bwart.
    ENDIF.
    lv_before = lines( gt_item ).
    DELETE gt_item WHERE werks = ls_key-werks
                     AND lgort = ls_key-lgort
                     AND bwart = ls_key-bwart.
    lv_count = lv_count + lv_before - lines( gt_item ).
  ENDLOOP.

  CHECK lv_werks IS NOT INITIAL.

  IF gt_item IS INITIAL.
    MESSAGE s001 WITH lv_werks lv_bwart DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  PERFORM add_msg USING 'W' '011' lv_count lv_werks lv_bwart.

ENDFORM.                    " CHECK_AUTHORITY

*&---------------------------------------------------------------------*
*&      Form  MATCH_MVT_GROUP
*&---------------------------------------------------------------------*
*       Dòng khớp đầu tiên của ZTWM_MVT_GRP (theo SEQNR) quyết định diễn giải và MvT đảo; điều kiện trống = bất kỳ.
*----------------------------------------------------------------------*
FORM match_mvt_group .

  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
    LOOP AT gt_mvt INTO DATA(ls_mvt) WHERE bwart = <lfs_item>-bwart.
      CHECK ( ls_mvt-sobkz IS INITIAL OR ls_mvt-sobkz = <lfs_item>-sobkz )
        AND ( ls_mvt-aufnr_flg IS INITIAL OR <lfs_item>-aufnr IS NOT INITIAL
                                          OR <lfs_item>-lips_aufnr IS NOT INITIAL )
        AND ( ls_mvt-werks IS INITIAL OR ls_mvt-werks = <lfs_item>-werks ).
      <lfs_item>-txt_vi    = ls_mvt-txt_vi.
      <lfs_item>-txt_en    = ls_mvt-txt_en.
      <lfs_item>-rev_bwart = ls_mvt-rev_bwart.
      EXIT.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " MATCH_MVT_GROUP

*&---------------------------------------------------------------------*
*&      Form  FILTER_SAMPLE
*&---------------------------------------------------------------------*
*       Mẫu 4 chỉ nhận MvT xuất lấy mẫu; chứng từ khác báo ZWM04-004.
*----------------------------------------------------------------------*
FORM filter_sample .

  DATA lt_ok TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line.

  CHECK p_op4 = abap_true AND gt_item IS NOT INITIAL.

  PERFORM get_sample_mvt.

  LOOP AT gt_item INTO DATA(ls_item) WHERE bwart IN gr_bwart_mau.
    INSERT |{ ls_item-mblnr }{ ls_item-mjahr }| INTO TABLE lt_ok.
  ENDLOOP.

  LOOP AT gt_item INTO ls_item
       GROUP BY ( mblnr = ls_item-mblnr mjahr = ls_item-mjahr ) INTO DATA(lg_doc).
    CHECK NOT line_exists( lt_ok[ table_line = |{ lg_doc-mblnr }{ lg_doc-mjahr }| ] ).
    DATA(lv_doc) = |{ lg_doc-mblnr ALPHA = OUT }|.
    PERFORM add_msg USING 'E' '004' lv_doc space space.
  ENDLOOP.

  DELETE gt_item WHERE bwart NOT IN gr_bwart_mau.

ENDFORM.                    " FILTER_SAMPLE

*&---------------------------------------------------------------------*
*&      Form  GET_SAMPLE_MVT
*&---------------------------------------------------------------------*
*       MvT xuất lấy mẫu: STVARV ZWM04_BWART_MAU (loại S), trống thì mặc định 331, 333, 335.
*----------------------------------------------------------------------*
FORM get_sample_mvt .

  SELECT sign, opti, low, high
    FROM tvarvc
    WHERE name = @gc_tvarv_bwart_mau
      AND type = 'S'
      AND low <> @space
    INTO TABLE @DATA(lt_tvarv).
  gr_bwart_mau = VALUE #( FOR ls_t IN lt_tvarv
                          ( sign = ls_t-sign option = ls_t-opti low = ls_t-low high = ls_t-high ) ).

  IF gr_bwart_mau IS INITIAL.
    gr_bwart_mau = VALUE #( sign = 'I' option = 'EQ'
                            ( low = gc_bwart_xm1 )
                            ( low = gc_bwart_xm2 )
                            ( low = gc_bwart_xm3 ) ).
  ENDIF.

ENDFORM.                    " GET_SAMPLE_MVT

*&---------------------------------------------------------------------*
*&      Form  CALC_ADJUST
*&---------------------------------------------------------------------*
*       SL thực xuất = SL dòng gốc - SL dòng đảo (SMBLN, hoặc MvT đảo qua LFBNR); SL = 0 không in.
*----------------------------------------------------------------------*
FORM calc_adjust .

  DATA: lt_rev TYPE STANDARD TABLE OF gty_rev WITH EMPTY KEY,
        lv_rev TYPE menge_d,
        lv_all TYPE abap_bool.

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
           r~meins
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
             r~meins
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
    <lfs_item>-del = xsdbool( <lfs_item>-menge_net <= 0 ).
  ENDLOOP.

  " Chú thích số chứng từ đảo của mỗi chứng từ
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
  ENDLOOP.

  " Chứng từ có mọi dòng đã đảo hết: không in
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
    PERFORM add_msg USING 'W' '003' lv_doc space space.
  ENDLOOP.

  DELETE gt_item WHERE del = abap_true.

ENDFORM.                    " CALC_ADJUST

*&---------------------------------------------------------------------*
*&      Form  CHECK_OPEN_WT
*&---------------------------------------------------------------------*
*       Lệnh xuất kho còn Warehouse Task chưa xác nhận (ORDIM_O) thì không in chứng từ.
*----------------------------------------------------------------------*
FORM check_open_wt .

  DATA: lt_dlv TYPE SORTED TABLE OF gty_dlv WITH UNIQUE KEY docno,
        lt_bad TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line.

  LOOP AT gt_item INTO DATA(ls_item) WHERE vbeln_im IS NOT INITIAL.
    INSERT VALUE #( docno = ls_item-vbeln_im ) INTO TABLE lt_dlv.
  ENDLOOP.
  CHECK lt_dlv IS NOT INITIAL.

  SELECT FROM /scdl/db_proch_o AS p
    INNER JOIN @lt_dlv AS k ON k~docno = p~docno
    FIELDS p~docid, p~docno
    INTO TABLE @DATA(lt_proch)   ##ITAB_DB_SELECT.
  CHECK lt_proch IS NOT INITIAL.

  SELECT FROM @lt_proch AS p
    INNER JOIN /scwm/ordim_o AS o ON o~rdocid = p~docid
    FIELDS DISTINCT p~docno
    INTO TABLE @DATA(lt_open)   ##ITAB_DB_SELECT.
  CHECK lt_open IS NOT INITIAL.

  LOOP AT gt_item INTO ls_item WHERE vbeln_im IS NOT INITIAL.
    CHECK line_exists( lt_open[ docno = ls_item-vbeln_im ] ).
    INSERT |{ ls_item-mblnr }{ ls_item-mjahr }| INTO TABLE lt_bad.
  ENDLOOP.
  CHECK lt_bad IS NOT INITIAL.

  LOOP AT gt_item INTO ls_item
       GROUP BY ( mblnr = ls_item-mblnr mjahr = ls_item-mjahr ) INTO DATA(lg_doc).
    CHECK line_exists( lt_bad[ table_line = |{ lg_doc-mblnr }{ lg_doc-mjahr }| ] ).
    DATA(lv_doc) = |{ lg_doc-mblnr ALPHA = OUT }|.
    PERFORM add_msg USING 'W' '005' lv_doc space space.
  ENDLOOP.

  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
    <lfs_item>-del = xsdbool( line_exists( lt_bad[ table_line = |{ <lfs_item>-mblnr }{ <lfs_item>-mjahr }| ] ) ).
  ENDLOOP.
  DELETE gt_item WHERE del = abap_true.

ENDFORM.                    " CHECK_OPEN_WT

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
        lt_anl    TYPE SORTED TABLE OF gty_anlt WITH UNIQUE KEY bukrs anln1 anln2 spras,
        lt_aufnr  TYPE SORTED TABLE OF aufnr WITH UNIQUE KEY table_line,
        lt_bp     TYPE SORTED TABLE OF bu_partner WITH UNIQUE KEY table_line,
        lt_bwart  TYPE SORTED TABLE OF bwart WITH UNIQUE KEY table_line,
        lt_resb   TYPE STANDARD TABLE OF gty_resb WITH EMPTY KEY,
        lv_awkey  TYPE awkey,
        lv_aufnr  TYPE aufnr,
        lv_bp     TYPE bu_partner.

  LOOP AT gt_item INTO DATA(ls_item).
    IF ls_item-matnr IS NOT INITIAL.
      INSERT ls_item-matnr INTO TABLE lt_matnr.
      INSERT VALUE #( matnr = ls_item-matnr werks = ls_item-werks ) INTO TABLE lt_mkey.
    ENDIF.
    INSERT VALUE #( werks = ls_item-werks lgort = ls_item-lgort ) INTO TABLE lt_lkey.
    IF ls_item-matnr IS NOT INITIAL AND ls_item-charg IS NOT INITIAL.
      INSERT VALUE #( matnr = ls_item-matnr werks = ls_item-werks charg = ls_item-charg )
             INTO TABLE lt_bkey.
    ENDIF.
    IF gv_bi = abap_true AND ls_item-erfme IS NOT INITIAL.
      INSERT ls_item-erfme INTO TABLE lt_unit.
    ENDIF.
    lv_awkey = |{ ls_item-mblnr }{ ls_item-mjahr }|.
    INSERT lv_awkey INTO TABLE lt_awkey.
    INSERT ls_item-bwart INTO TABLE lt_bwart.
    IF ls_item-kostl IS NOT INITIAL.
      INSERT VALUE #( kokrs = ls_item-kokrs kostl = ls_item-kostl ) INTO TABLE lt_kostl.
    ENDIF.
    IF ls_item-anln1 IS NOT INITIAL.
      INSERT VALUE #( bukrs = ls_item-bukrs anln1 = ls_item-anln1 anln2 = ls_item-anln2
                      spras = gc_spras_vi ) INTO TABLE lt_anl.
      INSERT VALUE #( bukrs = ls_item-bukrs anln1 = ls_item-anln1 anln2 = ls_item-anln2
                      spras = gc_spras_en ) INTO TABLE lt_anl.
    ENDIF.
    lv_aufnr = COND #( WHEN ls_item-lips_aufnr IS NOT INITIAL THEN ls_item-lips_aufnr
                       ELSE ls_item-aufnr ).
    IF lv_aufnr IS NOT INITIAL.
      INSERT lv_aufnr INTO TABLE lt_aufnr.
    ELSE.
      lv_bp = COND #( WHEN ls_item-shipto IS NOT INITIAL THEN ls_item-shipto
                      WHEN ls_item-kunnr  IS NOT INITIAL THEN ls_item-kunnr
                      ELSE ls_item-lifnr ).
      IF lv_bp IS NOT INITIAL.
        INSERT lv_bp INTO TABLE lt_bp.
      ENDIF.
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
      FIELDS mara~matnr, mara~mtart, mara~matkl, mara~groes, mara~raube, mara~mfrnr,
             t142t~rbtxt AS raube_txt
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

  " Nhóm vật tư kiểm soát đặc biệt cho mẫu 3
  IF p_op3 = abap_true.
    SELECT sign, opti, low, high
      FROM tvarvc
      WHERE name = @gc_tvarv_matkl
        AND type = 'S'
        AND low <> @space
      INTO TABLE @DATA(lt_tvarv).
    gr_matkl_ksdb = VALUE #( FOR ls_t IN lt_tvarv
                             ( sign = ls_t-sign option = ls_t-opti low = ls_t-low high = ls_t-high ) ).
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
    FIELDS bkpf~awkey, bkpf~belnr
    WHERE bkpf~awtyp = 'MKPF'
    INTO CORRESPONDING FIELDS OF TABLE @gt_bkpf   ##ITAB_DB_SELECT.

  " Diễn giải theo Movement Type
  SELECT FROM t156t
    INNER JOIN @lt_bwart AS k ON k~table_line = t156t~bwart
    FIELDS t156t~bwart, t156t~spras, t156t~btext
    WHERE t156t~spras IN ( @gc_spras_vi, @gc_spras_en )
      AND t156t~sobkz = @space
      AND t156t~kzbew = @space
      AND t156t~kzzug = @space
      AND t156t~kzvbr = @space
    INTO CORRESPONDING FIELDS OF TABLE @gt_t156t   ##ITAB_DB_SELECT.

  IF lt_kostl IS NOT INITIAL.
    SELECT FROM cskt
      INNER JOIN @lt_kostl AS k ON k~kokrs = cskt~kokrs
                               AND k~kostl = cskt~kostl
      FIELDS cskt~kokrs, cskt~kostl, cskt~ltext
      WHERE cskt~spras = @sy-langu
        AND cskt~datbi >= @sy-datum
      INTO CORRESPONDING FIELDS OF TABLE @gt_cskt   ##ITAB_DB_SELECT.
  ENDIF.

  IF lt_anl IS NOT INITIAL.
    SELECT FROM anlt
      INNER JOIN @lt_anl AS k ON k~bukrs = anlt~bukrs
                             AND k~anln1 = anlt~anln1
                             AND k~anln2 = anlt~anln2
                             AND k~spras = anlt~spras
      FIELDS anlt~bukrs, anlt~anln1, anlt~anln2, anlt~spras, anlt~txt50
      INTO CORRESPONDING FIELDS OF TABLE @gt_anlt   ##ITAB_DB_SELECT.
  ENDIF.

  IF lt_bp IS NOT INITIAL.
    SELECT FROM but000
      INNER JOIN @lt_bp AS k ON k~table_line = but000~partner
      FIELDS but000~partner, but000~name_org1, but000~name_org2,
             but000~name_org3, but000~name_org4
      INTO CORRESPONDING FIELDS OF TABLE @gt_bp   ##ITAB_DB_SELECT.
  ENDIF.

  IF lt_aufnr IS NOT INITIAL.
    SELECT FROM aufk
      INNER JOIN @lt_aufnr AS k ON k~table_line = aufk~aufnr
      FIELDS aufk~aufnr, aufk~ktext
      INTO CORRESPONDING FIELDS OF TABLE @gt_aufk   ##ITAB_DB_SELECT.

    " Kho của thành phần đầu tiên trong lệnh SX
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
                      ( low = gc_at_quycach ) ( low = gc_at_quycach2 )
                      ( low = gc_at_baoquan ) ).

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
        WHEN gc_at_quycach2.
          <lfs_bat>-quycach2 = ls_char-value_char.
        WHEN gc_at_baoquan.
          <lfs_bat>-baoquan  = ls_char-value_char.
      ENDCASE.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " GET_BATCH_CHARACT

*&---------------------------------------------------------------------*
*&      Form  SET_RECIPIENTS
*&---------------------------------------------------------------------*
*       Đơn vị nhận theo thứ tự: Order, Ship-to, (KH/NCC của chứng từ), Cost Center, Asset.
*----------------------------------------------------------------------*
FORM set_recipients .

  DATA: lv_aufnr TYPE aufnr,
        lv_bp    TYPE bu_partner,
        lv_text  TYPE char255.

  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
    CLEAR: <lfs_item>-rcp_kind, <lfs_item>-rcp_code, <lfs_item>-rcp_name.

    lv_aufnr = COND #( WHEN <lfs_item>-lips_aufnr IS NOT INITIAL THEN <lfs_item>-lips_aufnr
                       ELSE <lfs_item>-aufnr ).
    lv_bp    = COND #( WHEN <lfs_item>-shipto IS NOT INITIAL THEN <lfs_item>-shipto
                       WHEN <lfs_item>-kunnr  IS NOT INITIAL THEN <lfs_item>-kunnr
                       ELSE <lfs_item>-lifnr ).

    IF lv_aufnr IS NOT INITIAL.
      <lfs_item>-rcp_kind = 'O'.
      <lfs_item>-rcp_code = |{ lv_aufnr ALPHA = OUT }|.
      DATA(ls_resb) = VALUE gty_resb( gt_resb[ aufnr = lv_aufnr ] OPTIONAL ).
      IF ls_resb-lgobe IS NOT INITIAL.
        lv_text = ls_resb-lgobe.
        REPLACE ALL OCCURRENCES OF 'NVL' IN lv_text WITH ''.
        CONDENSE lv_text.
        <lfs_item>-rcp_name = |Phân xưởng { lv_text }|.
      ELSE.
        <lfs_item>-rcp_name = VALUE #( gt_aufk[ aufnr = lv_aufnr ]-ktext OPTIONAL ).
      ENDIF.

    ELSEIF lv_bp IS NOT INITIAL.
      <lfs_item>-rcp_kind = COND #( WHEN <lfs_item>-shipto IS NOT INITIAL OR <lfs_item>-kunnr IS NOT INITIAL
                                    THEN 'D' ELSE 'K' ).
      <lfs_item>-rcp_code = |{ lv_bp ALPHA = OUT }|.
      DATA(ls_bp) = VALUE gty_bp( gt_bp[ partner = lv_bp ] OPTIONAL ).
      <lfs_item>-rcp_name = condense( |{ ls_bp-name_org2 } { ls_bp-name_org3 } { ls_bp-name_org4 }| ).

    ELSEIF <lfs_item>-kostl IS NOT INITIAL.
      <lfs_item>-rcp_kind = 'C'.
      <lfs_item>-rcp_code = |{ <lfs_item>-kostl ALPHA = OUT }|.
      <lfs_item>-rcp_name = VALUE #( gt_cskt[ kokrs = <lfs_item>-kokrs
                                              kostl = <lfs_item>-kostl ]-ltext OPTIONAL ).

    ELSEIF <lfs_item>-anln1 IS NOT INITIAL.
      <lfs_item>-rcp_kind = 'A'.
      <lfs_item>-rcp_code = |{ <lfs_item>-anln1 ALPHA = OUT }|.
      DATA(lv_txt) = VALUE anlt-txt50( gt_anlt[ bukrs = <lfs_item>-bukrs
                                                anln1 = <lfs_item>-anln1
                                                anln2 = <lfs_item>-anln2
                                                spras = gc_spras_vi ]-txt50 OPTIONAL ).
      IF lv_txt IS INITIAL.
        lv_txt = VALUE #( gt_anlt[ bukrs = <lfs_item>-bukrs
                                   anln1 = <lfs_item>-anln1
                                   anln2 = <lfs_item>-anln2
                                   spras = gc_spras_en ]-txt50 OPTIONAL ).
      ENDIF.
      <lfs_item>-rcp_name = lv_txt.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " SET_RECIPIENTS

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_DATA
*&---------------------------------------------------------------------*
FORM build_alv_data .

  DATA: ls_alv   TYPE gty_alv,
        ls_hdr   TYPE gty_hdr,
        lv_multi TYPE abap_bool,
        lv_first TYPE gty_item.

  CLEAR gt_alv.

  LOOP AT gt_item INTO DATA(ls_item)
       GROUP BY ( mblnr = ls_item-mblnr mjahr = ls_item-mjahr ) INTO DATA(lg_doc).

    CLEAR: ls_alv, lv_multi, lv_first.
    LOOP AT GROUP lg_doc INTO DATA(ls_line).
      IF ls_alv IS INITIAL.
        lv_first       = ls_line.
        ls_alv-sel     = abap_true.
        ls_alv-mblnr   = ls_line-mblnr.
        ls_alv-mjahr   = ls_line-mjahr.
        ls_alv-bwart   = ls_line-bwart.
        ls_alv-lgort   = ls_line-lgort.
        ls_alv-werks   = ls_line-werks.
        ls_alv-obj_key = |{ ls_line-mblnr }/{ ls_line-mjahr }|.
        ls_alv-code    = COND #( WHEN ls_line-rcp_name IS NOT INITIAL
                                 THEN |{ ls_line-rcp_code } - { ls_line-rcp_name }|
                                 ELSE ls_line-rcp_code ).
        PERFORM resolve_header USING ls_line abap_false CHANGING ls_hdr.
        ls_alv-descr = ls_hdr-descr.
      ELSEIF ls_line-lgort <> lv_first-lgort OR ls_line-rcp_code <> lv_first-rcp_code.
        lv_multi = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_multi = abap_true.
      ls_alv-code = |{ ls_alv-code } (+)|.
    ENDIF.
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
    FIELDS l~obj_key, l~prt_count, l~last_user
    WHERE l~tcode    = @gc_tcode
      AND l~formname = @gc_prt_form
    INTO TABLE @DATA(lt_cnt)   ##ITAB_DB_SELECT.

  LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<lfs_alv>).
    DATA(ls_cnt) = VALUE #( lt_cnt[ obj_key = <lfs_alv>-obj_key ] OPTIONAL ).
    <lfs_alv>-print_count = ls_cnt-prt_count.
    <lfs_alv>-last_user   = ls_cnt-last_user.
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
      lo_column ?= lo_columns->get_column( 'BWART' ).
      PERFORM set_col_text USING lo_column 'MvT'.
      lo_column ?= lo_columns->get_column( 'LGORT' ).
      PERFORM set_col_text USING lo_column 'SLoc'.
      lo_column ?= lo_columns->get_column( 'CODE' ).
      PERFORM set_col_text USING lo_column 'Đơn vị nhận'.
      lo_column ?= lo_columns->get_column( 'DESCR' ).
      PERFORM set_col_text USING lo_column 'Diễn giải'.
      lo_column ?= lo_columns->get_column( 'PRINT_COUNT' ).
      PERFORM set_col_text USING lo_column 'Số lần in'.
      lo_column ?= lo_columns->get_column( 'LAST_USER' ).
      PERFORM set_col_text USING lo_column 'User in lần cuối'.

      lo_columns->get_column( 'WERKS' )->set_technical( abap_true ).
      lo_columns->get_column( 'OBJ_KEY' )->set_technical( abap_true ).
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
                                                   WHEN p_op3 = abap_true THEN '3. Thuốc gây nghiện'
                                                   ELSE '4. Xuất lấy mẫu kiểm nghiệm' ) }|.

  CREATE OBJECT lo_grid.
  lo_grid->create_label( row = 1 column = 1
                         text = 'ZWM04 – Danh sách chứng từ xuất kho' ).
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
*&      Form  GET_PARAMETER
*&---------------------------------------------------------------------*
FORM get_parameter .

  CLEAR gs_parameter.

  gs_parameter-logo = gc_logo.

  gs_parameter-header09 = lcl_util=>lbl_c( iv_vi = 'Mã đơn vị nhận' iv_en = 'Recipient unit code' ).
  gs_parameter-header11 = lcl_util=>lbl_c( iv_vi = 'Tên đơn vị nhận' iv_en = 'Recipient unit name' ).
  gs_parameter-header13 = lcl_util=>lbl_c( iv_vi = 'Địa chỉ' iv_en = 'Address' ).
  gs_parameter-header16 = lcl_util=>lbl_c( iv_vi = 'Kho xuất' iv_en = 'Storage location' ).
  gs_parameter-header18 = lcl_util=>lbl_c( iv_vi = 'Diễn giải' iv_en = 'Description' ).
  gs_parameter-header20 = lcl_util=>lbl_c( iv_vi = 'Lệnh xuất kho' iv_en = 'Goods delivery order' ).
  gs_parameter-header22 = lcl_util=>lbl_c( iv_vi = 'Số chứng từ kho' iv_en = 'Goods issue number' ).
  gs_parameter-header24 = lcl_util=>lbl_c( iv_vi = 'Số chứng từ kế toán' iv_en = 'Financial number' ).

  gs_parameter-parameter01 = lcl_util=>lbl( iv_vi = 'STT' iv_en = 'No.' ).
  gs_parameter-parameter02 = lcl_util=>lbl( iv_vi = 'Mã hàng' iv_en = 'Product code' ).
  gs_parameter-parameter03 = lcl_util=>lbl( iv_vi = 'Tên hàng' iv_en = 'Product name' ).
  gs_parameter-parameter04 = lcl_util=>lbl( iv_vi = 'Nồng độ - Hàm lượng' iv_en = 'Concentration/ content' ).
  gs_parameter-parameter05 = lcl_util=>lbl( iv_vi = 'Độ ẩm' iv_en = 'Water' ).
  gs_parameter-parameter06 = lcl_util=>lbl( iv_vi = 'NSX – Nước SX' iv_en = 'Manufacturer - Country' ).
  gs_parameter-parameter07 = lcl_util=>lbl( iv_vi = 'Số lô NSX' iv_en = 'Batch number' ).
  gs_parameter-parameter08 = lcl_util=>lbl( iv_vi = 'Số lô SAP' iv_en = 'SAP batch' ).
  gs_parameter-parameter09 = lcl_util=>lbl( iv_vi = 'Hạn dùng' iv_en = 'Expiry date' ).
  gs_parameter-parameter10 = lcl_util=>lbl( iv_vi = 'Ngày KNL' iv_en = 'Retest date' ).
  gs_parameter-parameter11 = lcl_util=>lbl( iv_vi = 'Quy cách' iv_en = 'Packaging' ).
  gs_parameter-parameter12 = lcl_util=>lbl( iv_vi = 'ĐVT' iv_en = 'Unit' ).
  gs_parameter-parameter13 = lcl_util=>lbl( iv_vi = 'Số lượng' iv_en = 'Quantity' ).
  IF p_bq = abap_true AND p_op4 = abap_false.
    gs_parameter-parameter14 = lcl_util=>lbl( iv_vi = 'ĐK bảo quản' iv_en = 'Storage conditions' ).
  ENDIF.

  " Nhãn chữ ký theo mẫu (hàng ký 1 dòng)
  IF p_op3 = abap_true.
    gs_parameter-sign01 = lcl_util=>lbl( iv_vi = 'Người giao' iv_en = 'Deliverer' ).
    gs_parameter-sign02 = lcl_util=>lbl( iv_vi = 'Người nhận' iv_en = 'Receiver' ).
    gs_parameter-sign03 = lcl_util=>lbl( iv_vi = 'Thủ kho' iv_en = 'Warehouse-keeper' ).
    gs_parameter-sign04 = lcl_util=>lbl( iv_vi = 'Trưởng bộ phận' iv_en = 'Manager' ).
    gs_parameter-sign05 = lcl_util=>lbl( iv_vi = 'Giám đốc' iv_en = 'Director' ).
  ELSEIF p_op4 = abap_true.
    gs_parameter-sign01 = lcl_util=>lbl( iv_vi = 'Người lấy mẫu' iv_en = 'Sampler' ).
    gs_parameter-sign02 = lcl_util=>lbl( iv_vi = 'Người kiểm tra' iv_en = 'Reviewer' ).
    gs_parameter-sign03 = lcl_util=>lbl( iv_vi = 'Thủ kho' iv_en = 'Warehouse-keeper' ).
  ELSE.
    gs_parameter-sign01 = lcl_util=>lbl( iv_vi = 'Người nhận' iv_en = 'Receiver' ).
    gs_parameter-sign02 = lcl_util=>lbl( iv_vi = 'Thủ kho' iv_en = 'Warehouse-keeper' ).
    gs_parameter-sign03 = lcl_util=>lbl( iv_vi = 'Trưởng bộ phận' iv_en = 'Manager' ).
  ENDIF.
  gs_parameter-sign06    = lcl_util=>lbl( iv_vi = '(Ký, ghi rõ họ tên)' iv_en = '(Signature, full name)' ).
  gs_parameter-footer05  = 'Ngày ….. tháng ….. năm ……..'.
  gs_parameter-footer06  = lcl_util=>lbl( iv_vi = 'Trang' iv_en = 'Page' ).

ENDFORM.                    " GET_PARAMETER

*&---------------------------------------------------------------------*
*&      Form  PRINT_DOCS
*&---------------------------------------------------------------------*
*       Mỗi phiếu = chứng từ + SLoc + lệnh xuất kho + đơn vị nhận. Chỉ In mới ghi nhật ký.
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
        lt_sheet   TYPE SORTED TABLE OF gty_sheet
                   WITH UNIQUE KEY mblnr mjahr lgort vbeln_im rcp_code.

  DATA(lt_sel) = VALUE gtt_alv( FOR ls_a IN gt_alv WHERE ( sel = abap_true ) ( ls_a ) ).
  IF lt_sel IS INITIAL.
    MESSAGE s009 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_sel INTO DATA(ls_sel).
    lv_doc = |{ ls_sel-mblnr ALPHA = OUT }|.
    IF ls_sel-print_count > 0 AND iv_preview = abap_false.
      PERFORM add_msg USING 'I' '007' lv_doc ls_sel-print_count space.
    ENDIF.
    " Mẫu 3: cảnh báo khi chứng từ có vật tư ngoài nhóm kiểm soát đặc biệt
    IF p_op3 = abap_true AND gr_matkl_ksdb IS NOT INITIAL.
      LOOP AT gt_item INTO DATA(ls_chk) WHERE mblnr = ls_sel-mblnr AND mjahr = ls_sel-mjahr.
        DATA(lv_matkl) = VALUE matkl( gt_mat[ matnr = ls_chk-matnr ]-matkl OPTIONAL ).
        IF lv_matkl NOT IN gr_matkl_ksdb.
          PERFORM add_msg USING 'W' '006' lv_doc space space.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
    LOOP AT gt_item INTO DATA(ls_item) WHERE mblnr = ls_sel-mblnr AND mjahr = ls_sel-mjahr.
      INSERT VALUE #( mblnr    = ls_item-mblnr
                      mjahr    = ls_item-mjahr
                      lgort    = ls_item-lgort
                      vbeln_im = ls_item-vbeln_im
                      rcp_code = ls_item-rcp_code ) INTO TABLE lt_sheet.
    ENDLOOP.
  ENDLOOP.
  PERFORM show_messages.

  lv_form = COND #( WHEN p_op4 = abap_true THEN gc_form_op4
                    WHEN p_op2 = abap_true THEN gc_form_op2
                    ELSE gc_form_op1 ).

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
    DATA(lv_cnt) = VALUE i( lt_sel[ mblnr = ls_sheet-mblnr mjahr = ls_sheet-mjahr ]-print_count OPTIONAL ).
    PERFORM fill_form USING ls_sheet lv_cnt.
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

  CHECK iv_preview = abap_false AND ls_job_inf-outputdone = abap_true.

  PERFORM write_prtlog USING lt_sel.
  PERFORM read_print_count.
  go_alv->refresh( ).

ENDFORM.                    " PRINT_DOCS

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM
*&---------------------------------------------------------------------*
FORM fill_form USING is_sheet TYPE gty_sheet
                     iv_cnt   TYPE i.

  DATA: lt_line     TYPE gtt_line,
        ls_hdr      TYPE gty_hdr,
        ls_plant    TYPE gty_partner,
        ls_plant_en TYPE gty_partner,
        ls_comp     TYPE gty_partner,
        ls_rcp      TYPE gty_partner,
        lv_docs     TYPE string.

  CLEAR gt_data.

  LOOP AT gt_item INTO DATA(ls_i) WHERE mblnr    = is_sheet-mblnr
                                    AND mjahr    = is_sheet-mjahr
                                    AND lgort    = is_sheet-lgort
                                    AND vbeln_im = is_sheet-vbeln_im
                                    AND rcp_code = is_sheet-rcp_code.
    APPEND ls_i TO lt_line.
  ENDLOOP.

  READ TABLE lt_line INTO DATA(ls_first) INDEX 1.
  CHECK sy-subrc = 0.

  SORT lt_line BY zeile.

  " Tiêu đề theo mẫu in
  IF p_op4 = abap_true.
    gs_parameter-title_report    = 'PHIẾU XUẤT KHO NGUYÊN VẬT LIỆU ĐỂ LẤY MẪU KIỂM NGHIỆM'.
    gs_parameter-title_report_en = 'MATERIAL ISSUE SLIP FOR SAMPLING'.
  ELSEIF p_op3 = abap_true.
    gs_parameter-title_report    = 'PHIẾU XUẤT KHO THUỐC GÂY NGHIỆN, THUỐC HƯỚNG THẦN, TIỀN CHẤT DÙNG LÀM THUỐC'.
    CLEAR gs_parameter-title_report_en.
  ELSE.
    gs_parameter-title_report    = 'PHIẾU XUẤT KHO'.
    gs_parameter-title_report_en = COND #( WHEN gv_bi = abap_true THEN 'GOODS ISSUE SLIP' ).
  ENDIF.

  " Header đơn vị theo Plant, MST theo Company Code
  PERFORM read_partner USING 'P' ls_first-werks CHANGING ls_plant.
  PERFORM read_partner USING 'C' ls_first-bukrs CHANGING ls_comp.
  gs_parameter-header01 = to_upper( ls_plant-name ).
  gs_parameter-header02 = ls_plant-address.
  gs_parameter-header03 = |{ lcl_util=>lbl_c( iv_vi = 'Điện thoại' iv_en = 'Tel' ) } { ls_plant-tel }|.
  gs_parameter-header04 = |Fax: { ls_plant-fax }|.
  gs_parameter-header05 = |{ lcl_util=>lbl_c( iv_vi = 'MST' iv_en = 'TIN' ) } { ls_comp-tax }|.
  gs_parameter-header06 = |Website: { ls_plant-remark }|.
  CLEAR: gs_parameter-header39, gs_parameter-header40.
  IF gv_bi = abap_true.
    PERFORM read_partner USING 'Q' ls_first-werks CHANGING ls_plant_en.
    gs_parameter-header39 = to_upper( ls_plant_en-name ).
    gs_parameter-header40 = ls_plant_en-address.
  ENDIF.

  gs_parameter-header08 = COND #(
    WHEN gv_bi = abap_true
    THEN |Ngày/ Date { ls_first-budat+6(2) } tháng/ month { ls_first-budat+4(2) } năm/ year { ls_first-budat(4) }|
    ELSE |Ngày { ls_first-budat+6(2) } tháng { ls_first-budat+4(2) } năm { ls_first-budat(4) }| ).

  " Đơn vị nhận
  gs_parameter-header10 = ls_first-rcp_code.
  gs_parameter-header12 = ls_first-rcp_name.
  CLEAR gs_parameter-header14.
  IF ls_first-rcp_kind = 'D' OR ls_first-rcp_kind = 'K'.
    PERFORM read_partner USING ls_first-rcp_kind ls_first-rcp_code CHANGING ls_rcp.
    IF gs_parameter-header12 IS INITIAL.
      gs_parameter-header12 = ls_rcp-name.
    ENDIF.
    gs_parameter-header14 = ls_rcp-address.
  ENDIF.

  DATA(ls_lgort) = VALUE gty_lgort( gt_lgort[ werks = ls_first-werks lgort = ls_first-lgort ] OPTIONAL ).
  gs_parameter-header17 = |{ ls_first-lgort } - { ls_lgort-lgobe }|.

  PERFORM resolve_header USING ls_first abap_true CHANGING ls_hdr.
  gs_parameter-header19 = COND #( WHEN gv_bi = abap_true AND ls_hdr-descr_en IS NOT INITIAL
                                  THEN |{ ls_hdr-descr }/ { ls_hdr-descr_en }|
                                  ELSE ls_hdr-descr ).
  gs_parameter-header21 = |{ ls_first-vbeln_im ALPHA = OUT }|.
  gs_parameter-header23 = |{ ls_first-mblnr ALPHA = OUT }|.
  gs_parameter-header25 = ls_hdr-belnr.

  gs_parameter-iso_line01 = COND #( WHEN iv_cnt = 0 THEN |Lần in: 1|
                                    ELSE |Bản in lại – lần { iv_cnt + 1 }| ).
  gs_parameter-footer07   = COND #( WHEN iv_cnt = 0 THEN space
                                    ELSE |Bản in lại – lần { iv_cnt + 1 }| ).
  gs_parameter-footer03   = |In lúc: { sy-datum+6(2) }/{ sy-datum+4(2) }/{ sy-datum(4) } | &&
                            |{ sy-uzeit(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) } – User: { sy-uname }|.

  PERFORM fill_form_lines USING lt_line.

  READ TABLE gt_docadj INTO DATA(ls_adj)
       WITH TABLE KEY mblnr = is_sheet-mblnr mjahr = is_sheet-mjahr.
  lv_docs = COND #( WHEN sy-subrc = 0 THEN ls_adj-rev_docs ).
  gs_parameter-long_text1 = COND #( WHEN lv_docs IS NOT INITIAL
                                    THEN |Số lượng đã trừ chứng từ điều chỉnh: { lv_docs }|
                                    ELSE space ).

ENDFORM.                    " FILL_FORM

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM_LINES
*&---------------------------------------------------------------------*
FORM fill_form_lines USING it_line TYPE gtt_line.

  DATA: ls_data    TYPE zwm_st_pxk,
        ls_partner TYPE gty_partner,
        lv_stt     TYPE i,
        lv_nsx     TYPE char255,
        lv_land1   TYPE land1,
        lv_nuoc    TYPE char255,
        lv_mfrnr   TYPE mfrnr.

  LOOP AT it_line INTO DATA(ls_item).

    CLEAR: ls_data, lv_nsx, lv_land1, lv_nuoc.
    lv_stt = lv_stt + 1.
    ls_data-stt   = lv_stt.
    ls_data-mblnr = ls_item-mblnr.
    ls_data-matnr = ls_item-matnr.
    ls_data-charg = ls_item-charg.
    ls_data-lgort = ls_item-lgort.
    ls_data-werks = ls_item-werks.
    ls_data-erfme = ls_item-erfme.
    ls_data-erfmg = ls_item-erfmg_net.

    DATA(ls_mat) = VALUE gty_mat( gt_mat[ matnr = ls_item-matnr ] OPTIONAL ).
    DATA(ls_bat) = VALUE gty_batch( gt_batch[ matnr = ls_item-matnr
                                              werks = ls_item-werks
                                              charg = ls_item-charg ] OPTIONAL ).

    ls_data-maktx = VALUE #( gt_makt[ matnr = ls_item-matnr spras = gc_spras_vi ]-maktx OPTIONAL ).
    DATA(lv_maktx_en) = VALUE maktx( gt_makt[ matnr = ls_item-matnr spras = gc_spras_en ]-maktx OPTIONAL ).
    IF ls_data-maktx IS INITIAL.
      ls_data-maktx = lv_maktx_en.
    ENDIF.
    IF gv_bi = abap_true.
      ls_data-maktx_en = lv_maktx_en.
    ENDIF.

    " Nồng độ - hàm lượng, độ ẩm: mẫu 1 và 3
    IF p_op1 = abap_true OR p_op3 = abap_true.
      ls_data-nodhl = ls_bat-z_nongdo.
      ls_data-doam  = COND #( WHEN ls_bat-z_doam2 IS NOT INITIAL THEN ls_bat-z_doam2
                              ELSE ls_bat-z_doam1 ).
    ENDIF.

    " NSX: Z_NSX của lô, không có thì NSX theo MPN
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
      DATA(lv_herkl) = VALUE herkl( gt_marc[ matnr = ls_item-matnr
                                             werks = ls_item-werks ]-herkl OPTIONAL ).
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

    ls_data-solo    = COND #( WHEN ls_bat-z_lonsx IS NOT INITIAL THEN ls_bat-z_lonsx
                              ELSE ls_bat-licha ).
    ls_data-handung = ls_bat-vfdat.
    ls_data-ngaykn  = ls_bat-qndat.

    ls_data-groes = COND #( WHEN ls_bat-quycach  IS NOT INITIAL THEN ls_bat-quycach
                            WHEN ls_bat-quycach2 IS NOT INITIAL THEN ls_bat-quycach2
                            ELSE ls_mat-groes ).

    IF gv_bi = abap_true AND ls_item-erfme IS NOT INITIAL.
      ls_data-erfme_en = VALUE #( gt_unit_en[ msehi = ls_item-erfme ]-msehl OPTIONAL ).
    ENDIF.

    IF p_bq = abap_true AND p_op4 = abap_false.
      ls_data-baoquan = COND #( WHEN ls_bat-baoquan IS NOT INITIAL THEN ls_bat-baoquan
                                ELSE ls_mat-raube_txt ).
    ENDIF.

    APPEND ls_data TO gt_data.
  ENDLOOP.

ENDFORM.                    " FILL_FORM_LINES

*&---------------------------------------------------------------------*
*&      Form  RESOLVE_HEADER
*&---------------------------------------------------------------------*
*       Diễn giải: ZTWM_MVT_GRP, rồi T156T, rồi Header text. IV_FULL = space: chỉ diễn giải (màn hình trung gian).
*----------------------------------------------------------------------*
FORM resolve_header USING is_line TYPE gty_item
                          iv_full TYPE abap_bool
                    CHANGING cs_hdr TYPE gty_hdr.

  DATA lv_awkey TYPE awkey.

  CLEAR cs_hdr.

  IF is_line-txt_vi IS NOT INITIAL.
    cs_hdr-descr    = is_line-txt_vi.
    cs_hdr-descr_en = is_line-txt_en.
  ELSE.
    DATA(lv_vi) = VALUE t156t-btext( gt_t156t[ bwart = is_line-bwart spras = gc_spras_vi ]-btext OPTIONAL ).
    DATA(lv_en) = VALUE t156t-btext( gt_t156t[ bwart = is_line-bwart spras = gc_spras_en ]-btext OPTIONAL ).
    cs_hdr-descr    = COND #( WHEN lv_vi IS NOT INITIAL THEN lv_vi ELSE lv_en ).
    cs_hdr-descr_en = lv_en.
    IF cs_hdr-descr IS INITIAL.
      cs_hdr-descr = is_line-bktxt.
    ENDIF.
  ENDIF.

  CHECK iv_full = abap_true.

  lv_awkey = |{ is_line-mblnr }{ is_line-mjahr }|.
  cs_hdr-belnr = VALUE #( gt_bkpf[ awkey = lv_awkey ]-belnr OPTIONAL ).

ENDFORM.                    " RESOLVE_HEADER

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

    INSERT ztwm_prtlog FROM @( VALUE ztwm_prtlog( tcode      = gc_tcode
                                                  formname   = gc_prt_form
                                                  obj_key    = ls_doc-obj_key
                                                  rpt_opt    = lv_opt
                                                  werks      = ls_doc-werks
                                                  lgort      = ls_doc-lgort(4)
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
