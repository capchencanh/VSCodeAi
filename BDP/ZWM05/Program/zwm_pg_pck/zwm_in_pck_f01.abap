*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PCK_F01
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
*       MvT khai báo ở ZTWM_MVT_GRP thuộc nhóm chuyển kho (DC) hoặc chuyển trạng thái (TT).
*----------------------------------------------------------------------*
FORM get_mvt_group .

  SELECT bwart, seqnr, sobkz, aufnr_flg, werks, grp_code, txt_vi, txt_en
    FROM ztwm_mvt_grp
    WHERE grp_code IN ( @gc_grp_dc, @gc_grp_tt )
    INTO CORRESPONDING FIELDS OF TABLE @gt_mvt.

ENDFORM.                    " GET_MVT_GROUP

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       Dòng xuất (XAUTO trống) ghép dòng nhận (XAUTO = X) qua LINE_ID / PARENT_ID.
*----------------------------------------------------------------------*
FORM get_data .

  DATA: lr_mjahr TYPE RANGE OF mjahr,
        lr_bwart TYPE RANGE OF bwart,
        lt_raw   TYPE gtt_item.

  IF s_mblnr[] IS NOT INITIAL.
    lr_mjahr = VALUE #( ( sign = 'I' option = 'EQ' low = p_mjahr ) ).
  ENDIF.

  lr_bwart = VALUE #( FOR ls_m IN gt_mvt ( sign = 'I' option = 'EQ' low = ls_m-bwart ) ).
  SORT lr_bwart BY low.
  DELETE ADJACENT DUPLICATES FROM lr_bwart COMPARING low.
  CHECK lr_bwart IS NOT INITIAL.

  SELECT FROM matdoc AS i
    LEFT OUTER JOIN matdoc AS r ON r~mblnr       = i~mblnr
                               AND r~mjahr       = i~mjahr
                               AND r~parent_id   = i~line_id
                               AND r~xauto       = 'X'
                               AND r~record_type = 'MDOC'
    FIELDS i~mblnr,
           i~mjahr,
           i~zeile,
           i~bwart,
           i~sobkz,
           i~budat,
           i~bktxt,
           i~usnam,
           i~bukrs,
           i~werks,
           i~lgort,
           i~umwrk,
           i~umlgo,
           i~matnr,
           i~ummat,
           i~charg,
           i~umcha,
           i~menge,
           i~meins,
           i~erfmg,
           i~erfme,
           i~rsnum,
           i~aufnr,
           i~smbln,
           i~insmk,
           r~werks AS rcv_werks,
           r~lgort AS rcv_lgort,
           r~matnr AS rcv_matnr,
           r~charg AS rcv_charg,
           r~insmk AS rcv_insmk
    WHERE i~record_type = 'MDOC'
      AND i~xauto       = @space
      AND i~werks IN @s_werks
      AND i~mblnr IN @s_mblnr
      AND i~mjahr IN @lr_mjahr
      AND i~budat IN @s_budat
      AND i~bwart IN @s_bwart
      AND i~bwart IN @lr_bwart
      AND i~lgort IN @s_lgort
      AND i~rsnum IN @s_rsnum
      AND i~usnam IN @s_usnam
    INTO CORRESPONDING FIELDS OF TABLE @lt_raw.

  SORT lt_raw BY mblnr mjahr zeile.
  DELETE ADJACENT DUPLICATES FROM lt_raw COMPARING mblnr mjahr zeile.

  " Đơn vị nhận: dòng nhận, không có (chuyển 2 bước) thì UMWRK / UMLGO của dòng xuất
  LOOP AT lt_raw ASSIGNING FIELD-SYMBOL(<lfs_raw>).
    <lfs_raw>-to_werks = COND #( WHEN <lfs_raw>-rcv_werks IS NOT INITIAL THEN <lfs_raw>-rcv_werks
                                 WHEN <lfs_raw>-umwrk     IS NOT INITIAL THEN <lfs_raw>-umwrk
                                 ELSE <lfs_raw>-werks ).
    <lfs_raw>-to_lgort = COND #( WHEN <lfs_raw>-rcv_lgort IS NOT INITIAL THEN <lfs_raw>-rcv_lgort
                                 WHEN <lfs_raw>-umlgo     IS NOT INITIAL THEN <lfs_raw>-umlgo
                                 ELSE <lfs_raw>-lgort ).
    <lfs_raw>-to_matnr = COND #( WHEN <lfs_raw>-rcv_matnr IS NOT INITIAL THEN <lfs_raw>-rcv_matnr
                                 WHEN <lfs_raw>-ummat     IS NOT INITIAL THEN <lfs_raw>-ummat
                                 ELSE <lfs_raw>-matnr ).
    <lfs_raw>-to_charg = COND #( WHEN <lfs_raw>-rcv_charg IS NOT INITIAL THEN <lfs_raw>-rcv_charg
                                 ELSE <lfs_raw>-umcha ).
  ENDLOOP.

  DELETE lt_raw WHERE to_lgort NOT IN s_umlgo.
  gt_item = lt_raw.

ENDFORM.                    " GET_DATA

*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITY
*&---------------------------------------------------------------------*
FORM check_authority .

  DATA: lv_count  TYPE i,
        lv_before TYPE i,
        lv_ok     TYPE abap_bool,
        lv_werks  TYPE werks_d,
        lv_lgort  TYPE lgort_d,
        lv_bwart  TYPE bwart.

  DATA(lt_key) = VALUE gtt_item( FOR ls_i IN gt_item
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
      lv_lgort = ls_key-lgort.
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
    MESSAGE s001 WITH lv_werks lv_lgort lv_bwart DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  PERFORM add_msg USING 'W' '010' lv_count lv_werks lv_bwart.

ENDFORM.                    " CHECK_AUTHORITY

*&---------------------------------------------------------------------*
*&      Form  MATCH_MVT_GROUP
*&---------------------------------------------------------------------*
*       Dòng khớp đầu tiên của ZTWM_MVT_GRP (theo SEQNR) quyết định nhóm và diễn giải; điều kiện trống = bất kỳ.
*----------------------------------------------------------------------*
FORM match_mvt_group .

  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
    LOOP AT gt_mvt INTO DATA(ls_mvt) WHERE bwart = <lfs_item>-bwart.
      CHECK ( ls_mvt-sobkz IS INITIAL OR ls_mvt-sobkz = <lfs_item>-sobkz )
        AND ( ls_mvt-aufnr_flg IS INITIAL OR <lfs_item>-aufnr IS NOT INITIAL )
        AND ( ls_mvt-werks IS INITIAL OR ls_mvt-werks = <lfs_item>-werks ).
      <lfs_item>-grp_code = ls_mvt-grp_code.
      <lfs_item>-txt_vi   = ls_mvt-txt_vi.
      <lfs_item>-txt_en   = ls_mvt-txt_en.
      EXIT.
    ENDLOOP.
  ENDLOOP.

  DELETE gt_item WHERE grp_code IS INITIAL.

ENDFORM.                    " MATCH_MVT_GROUP

*&---------------------------------------------------------------------*
*&      Form  GET_CANCEL_INFO
*&---------------------------------------------------------------------*
*       Chứng từ đảo tham chiếu (SMBLN / SJAHR) tới từng chứng từ đang xét.
*----------------------------------------------------------------------*
FORM get_cancel_info .

  DATA: lt_doc  TYPE SORTED TABLE OF gty_doc WITH UNIQUE KEY mblnr mjahr,
        lv_rev  TYPE string.

  LOOP AT gt_item INTO DATA(ls_item).
    INSERT VALUE #( mblnr = ls_item-mblnr mjahr = ls_item-mjahr ) INTO TABLE lt_doc.
  ENDLOOP.
  CHECK lt_doc IS NOT INITIAL.

  SELECT FROM matdoc AS c
    INNER JOIN @lt_doc AS k ON c~smbln = k~mblnr
                           AND c~sjahr = k~mjahr
    FIELDS DISTINCT k~mblnr, k~mjahr, c~mblnr AS rev_mblnr
    WHERE c~record_type = 'MDOC'
    INTO TABLE @DATA(lt_cancel)   ##ITAB_DB_SELECT.

  SORT lt_cancel BY mblnr mjahr rev_mblnr.

  LOOP AT lt_cancel INTO DATA(ls_cancel).
    READ TABLE gt_docrev ASSIGNING FIELD-SYMBOL(<lfs_rev>)
         WITH TABLE KEY mblnr = ls_cancel-mblnr mjahr = ls_cancel-mjahr.
    IF sy-subrc <> 0.
      INSERT VALUE #( mblnr = ls_cancel-mblnr mjahr = ls_cancel-mjahr )
             INTO TABLE gt_docrev ASSIGNING <lfs_rev>.
    ENDIF.
    lv_rev = |{ ls_cancel-rev_mblnr ALPHA = OUT }|.
    <lfs_rev>-rev_docs = COND #( WHEN <lfs_rev>-rev_docs IS INITIAL THEN lv_rev
                                 ELSE |{ <lfs_rev>-rev_docs }, { lv_rev }| ).
  ENDLOOP.

ENDFORM.                    " GET_CANCEL_INFO

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

  DATA: lt_matnr TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line,
        lt_mkey  TYPE SORTED TABLE OF gty_marc WITH UNIQUE KEY matnr werks,
        lt_lkey  TYPE SORTED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
        lt_bkey  TYPE SORTED TABLE OF gty_batch WITH UNIQUE KEY matnr werks charg,
        lt_pkey  TYPE SORTED TABLE OF werks_d WITH UNIQUE KEY table_line,
        lt_qkey  TYPE SORTED TABLE OF gty_qamb WITH UNIQUE KEY mblnr mjahr zeile,
        lt_unit  TYPE SORTED TABLE OF msehi WITH UNIQUE KEY table_line.

  LOOP AT gt_item INTO DATA(ls_item).
    IF ls_item-matnr IS NOT INITIAL.
      INSERT ls_item-matnr INTO TABLE lt_matnr.
      INSERT VALUE #( matnr = ls_item-matnr werks = ls_item-werks ) INTO TABLE lt_mkey.
      IF ls_item-charg IS NOT INITIAL.
        INSERT VALUE #( matnr = ls_item-matnr werks = ls_item-werks charg = ls_item-charg )
               INTO TABLE lt_bkey.
      ENDIF.
    ENDIF.
    INSERT ls_item-werks    INTO TABLE lt_pkey.
    INSERT ls_item-to_werks INTO TABLE lt_pkey.
    INSERT VALUE #( werks = ls_item-werks    lgort = ls_item-lgort )    INTO TABLE lt_lkey.
    INSERT VALUE #( werks = ls_item-to_werks lgort = ls_item-to_lgort ) INTO TABLE lt_lkey.
    IF ls_item-grp_code = gc_grp_tt.
      INSERT VALUE #( mblnr = ls_item-mblnr mjahr = ls_item-mjahr zeile = ls_item-zeile )
             INTO TABLE lt_qkey.
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

    SELECT FROM marm
      INNER JOIN @lt_matnr AS k ON k~table_line = marm~matnr
      FIELDS marm~matnr, marm~meinh, marm~umrez, marm~umren
      WHERE marm~umrez <> 0
        AND marm~umren <> 0
      INTO CORRESPONDING FIELDS OF TABLE @gt_marm   ##ITAB_DB_SELECT.

    LOOP AT gt_marm INTO DATA(ls_marm).
      INSERT ls_marm-meinh INTO TABLE lt_unit.
    ENDLOOP.
    INSERT gc_unit_hop INTO TABLE lt_unit.
    INSERT gc_unit_thu INTO TABLE lt_unit.

    SELECT FROM t006
      INNER JOIN @lt_unit AS k ON k~table_line = t006~msehi
      LEFT OUTER JOIN t006a ON t006a~msehi = t006~msehi
                           AND t006a~spras = @gc_spras_en
      FIELDS t006~msehi, t006~dimid, t006a~mseh6
      INTO CORRESPONDING FIELDS OF TABLE @gt_unit   ##ITAB_DB_SELECT.
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

  SELECT FROM t001w
    INNER JOIN @lt_pkey AS k ON k~table_line = t001w~werks
    FIELDS t001w~werks, t001w~name1
    INTO CORRESPONDING FIELDS OF TABLE @gt_plant   ##ITAB_DB_SELECT.

  IF lt_bkey IS NOT INITIAL.
    SELECT FROM mcha
      INNER JOIN @lt_bkey AS k ON k~matnr = mcha~matnr
                              AND k~werks = mcha~werks
                              AND k~charg = mcha~charg
      FIELDS mcha~matnr, mcha~werks, mcha~charg, mcha~vfdat, mcha~qndat, mcha~hsdat, mcha~licha
      INTO CORRESPONDING FIELDS OF TABLE @gt_batch   ##ITAB_DB_SELECT.

    PERFORM get_batch_charact.
  ENDIF.

  IF lt_qkey IS NOT INITIAL.
    SELECT FROM qamb
      INNER JOIN @lt_qkey AS k ON k~mblnr = qamb~mblnr
                              AND k~mjahr = qamb~mjahr
                              AND k~zeile = qamb~zeile
      FIELDS qamb~mblnr, qamb~mjahr, qamb~zeile, qamb~prueflos
      INTO CORRESPONDING FIELDS OF TABLE @gt_qamb   ##ITAB_DB_SELECT.
  ENDIF.

  SELECT werks, lgort, umlgo, title_vi, title_en
    FROM ztwm_pck_title
    INTO CORRESPONDING FIELDS OF TABLE @gt_title.

  SELECT werks, bwart, lgort, umlgo, sign_qlcl
    FROM ztwm_pck_sign
    INTO CORRESPONDING FIELDS OF TABLE @gt_sign.

  " Nhóm vật tư kiểm soát đặc biệt (mẫu 2) và material type nhóm retest
  SELECT sign, opti, low, high
    FROM tvarvc
    WHERE name = @gc_tvarv_matkl
      AND type = 'S'
      AND low <> @space
    INTO TABLE @DATA(lt_tvarv).
  gr_matkl_ksdb = VALUE #( FOR ls_t IN lt_tvarv
                           ( sign = ls_t-sign option = ls_t-opti low = ls_t-low high = ls_t-high ) ).

  SELECT sign, opti, low, high
    FROM tvarvc
    WHERE name = @gc_tvarv_mtart
      AND type = 'S'
      AND low <> @space
    INTO TABLE @lt_tvarv.
  gr_mtart_knl = VALUE #( FOR ls_t IN lt_tvarv
                          ( sign = ls_t-sign option = ls_t-opti low = ls_t-low high = ls_t-high ) ).
  IF gr_mtart_knl IS INITIAL.
    gr_mtart_knl = VALUE #( ( sign = 'I' option = 'EQ' low = gc_mtart_knl ) ).
  ENDIF.

  " Tên loại tồn kho cho phiếu chuyển trạng thái
  SELECT domvalue_l, ddlanguage, ddtext
    FROM dd07t
    WHERE domname    = 'MB_INSMK'
      AND as4local   = 'A'
      AND ddlanguage IN ( @gc_spras_vi, @gc_spras_en )
    INTO CORRESPONDING FIELDS OF TABLE @gt_insmk.

ENDFORM.                    " GET_MASTER_DATA

*&---------------------------------------------------------------------*
*&      Form  GET_BATCH_CHARACT
*&---------------------------------------------------------------------*
FORM get_batch_charact .

  DATA: lt_atnam TYPE STANDARD TABLE OF zcore_st_rseloption_atnam,
        lt_char  TYPE STANDARD TABLE OF bapi1003_alloc_values_char.

  lt_atnam = VALUE #( sign = 'I' option = 'EQ'
                      ( low = gc_at_nsx )     ( low = gc_at_nuoc )
                      ( low = gc_at_lonsx )   ( low = gc_at_quycach )
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
        WHEN gc_at_nsx.
          <lfs_bat>-z_nsx   = ls_char-value_char.
        WHEN gc_at_nuoc.
          <lfs_bat>-z_nuoc  = ls_char-value_char.
        WHEN gc_at_lonsx.
          <lfs_bat>-z_lonsx = ls_char-value_char.
        WHEN gc_at_quycach.
          <lfs_bat>-quycach = ls_char-value_char.
        WHEN gc_at_baoquan.
          <lfs_bat>-baoquan = ls_char-value_char.
      ENDCASE.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " GET_BATCH_CHARACT

*&---------------------------------------------------------------------*
*&      Form  RESOLVE_SHEET
*&---------------------------------------------------------------------*
*       Form, tiêu đề, khối chữ ký của một phiếu; IV_MSG = X: báo ZWM05-005 / 007 và chặn in.
*----------------------------------------------------------------------*
FORM resolve_sheet USING is_sheet TYPE gty_sheet
                         iv_msg   TYPE abap_bool
                   CHANGING cs_lay TYPE gty_lay.

  DATA: lv_ctrl TYPE abap_bool,
        lv_diff TYPE abap_bool,
        lv_qlcl TYPE abap_bool,
        lv_opt  TYPE char1,
        lv_doc  TYPE string.

  CLEAR cs_lay.

  READ TABLE gt_item INTO DATA(ls_first)
       WITH KEY mblnr    = is_sheet-mblnr
                mjahr    = is_sheet-mjahr
                werks    = is_sheet-werks
                lgort    = is_sheet-lgort
                to_werks = is_sheet-to_werks
                to_lgort = is_sheet-to_lgort.
  CHECK sy-subrc = 0.

  cs_lay-grp  = ls_first-grp_code.
  cs_lay-form = gc_form_std.

  IF cs_lay-grp = gc_grp_tt.
    cs_lay-type_txt = 'Chuyển trạng thái'.
    cs_lay-title    = 'PHIẾU CHUYỂN TRẠNG THÁI'.
    cs_lay-signs    = VALUE #( ( lcl_util=>lbl( iv_vi = 'Người lập phiếu' iv_en = 'Prepared by' ) ) ).
    RETURN.
  ENDIF.

* Bỏ mẫu 4: còn 3 mẫu
*  lv_opt = COND #( WHEN p_op1 = abap_true THEN '1'
*                   WHEN p_op2 = abap_true THEN '2'
*                   WHEN p_op3 = abap_true THEN '3'
*                   ELSE '4' ).
  lv_opt = COND #( WHEN p_op1 = abap_true THEN '1'
                   WHEN p_op2 = abap_true THEN '2'
                   ELSE '3' ).
  cs_lay-type_txt = |Chuyển kho – Mẫu { lv_opt }|.
  IF p_op3 = abap_true.
    cs_lay-form = gc_form_op3.
  ENDIF.

  " Chỉ kiểm khi đã khai báo nhóm vật tư kiểm soát đặc biệt
  IF gr_matkl_ksdb IS NOT INITIAL.
    LOOP AT gt_item INTO DATA(ls_chk) WHERE mblnr    = is_sheet-mblnr
                                        AND mjahr    = is_sheet-mjahr
                                        AND werks    = is_sheet-werks
                                        AND lgort    = is_sheet-lgort
                                        AND to_werks = is_sheet-to_werks
                                        AND to_lgort = is_sheet-to_lgort.
      DATA(lv_matkl) = VALUE matkl( gt_mat[ matnr = ls_chk-matnr ]-matkl OPTIONAL ).
      IF lv_matkl IN gr_matkl_ksdb.
        lv_ctrl = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.

    lv_doc = |{ is_sheet-mblnr ALPHA = OUT }|.
    IF lv_ctrl = abap_true AND p_op2 = abap_false.
      cs_lay-block = abap_true.
      IF iv_msg = abap_true.
        PERFORM add_msg USING 'W' '007' lv_doc space space.
      ENDIF.
    ELSEIF lv_ctrl = abap_false AND p_op2 = abap_true AND iv_msg = abap_true.
      PERFORM add_msg USING 'W' '005' lv_doc space space.
    ENDIF.
  ENDIF.

  IF p_op2 = abap_true.
    cs_lay-title = 'PHIẾU CHUYỂN KHO THUỐC GÂY NGHIỆN, THUỐC HƯỚNG THẦN, TIỀN CHẤT DÙNG LÀM THUỐC'.
  ELSE.
    DATA(ls_title) = VALUE gty_title( gt_title[ werks = is_sheet-werks
                                                lgort = is_sheet-lgort
                                                umlgo = is_sheet-to_lgort ] OPTIONAL ).
    cs_lay-title = COND #( WHEN ls_title-title_vi IS NOT INITIAL THEN ls_title-title_vi
                           ELSE 'PHIẾU CHUYỂN KHO' ).
    IF gv_bi = abap_true.
      cs_lay-title_en = COND #( WHEN ls_title-title_en IS NOT INITIAL THEN ls_title-title_en
                                WHEN p_op1 = abap_true THEN 'CERTIFICATE OF RELEASE'
                                WHEN p_op3 = abap_true THEN 'MATERIAL TRANSFER SLIP' ).
    ENDIF.
  ENDIF.

  " Khối chữ ký chỉ hiện khi SLoc xuất khác SLoc nhận
  lv_diff = xsdbool( is_sheet-lgort <> is_sheet-to_lgort OR is_sheet-werks <> is_sheet-to_werks ).

  LOOP AT gt_sign INTO DATA(ls_sign) WHERE sign_qlcl = abap_true.
    CHECK ( ls_sign-werks IS INITIAL OR ls_sign-werks = is_sheet-werks )
      AND ( ls_sign-bwart IS INITIAL OR ls_sign-bwart = ls_first-bwart )
      AND ( ls_sign-lgort IS INITIAL OR ls_sign-lgort = is_sheet-lgort )
      AND ( ls_sign-umlgo IS INITIAL OR ls_sign-umlgo = is_sheet-to_lgort ).
    lv_qlcl = abap_true.
    EXIT.
  ENDLOOP.

* Bỏ mẫu 4 (luôn hiện khối chữ ký kèm Trưởng phòng QLCL)
*  IF p_op4 = abap_true OR lv_diff = abap_true.
  IF lv_diff = abap_true.
    cs_lay-signs = VALUE #( ( lcl_util=>lbl( iv_vi = 'Người nhận hàng' iv_en = 'Receiver' ) )
                            ( lcl_util=>lbl( iv_vi = 'Thủ kho' iv_en = 'Warehouse-keeper' ) ) ).
*    IF p_op4 = abap_true OR lv_qlcl = abap_true.
    IF lv_qlcl = abap_true.
      APPEND lcl_util=>lbl( iv_vi = 'Trưởng phòng QLCL' iv_en = 'QC Manager' ) TO cs_lay-signs.
    ENDIF.
    APPEND lcl_util=>lbl( iv_vi = 'Trưởng bộ phận' iv_en = 'Manager' ) TO cs_lay-signs.
  ENDIF.

ENDFORM.                    " RESOLVE_SHEET

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_DATA
*&---------------------------------------------------------------------*
FORM build_alv_data .

  DATA: ls_alv   TYPE gty_alv,
        ls_lay   TYPE gty_lay,
        ls_sheet TYPE gty_sheet,
        lt_rs    TYPE SORTED TABLE OF rsnum WITH UNIQUE KEY table_line.

  CLEAR gt_alv.

  LOOP AT gt_item INTO DATA(ls_item)
       GROUP BY ( mblnr    = ls_item-mblnr
                  mjahr    = ls_item-mjahr
                  werks    = ls_item-werks
                  lgort    = ls_item-lgort
                  to_werks = ls_item-to_werks
                  to_lgort = ls_item-to_lgort ) INTO DATA(lg_sheet).

    CLEAR: ls_alv, lt_rs.
    LOOP AT GROUP lg_sheet INTO DATA(ls_line).
      IF ls_alv IS INITIAL.
        ls_alv-sel      = abap_true.
        ls_alv-mblnr    = ls_line-mblnr.
        ls_alv-mjahr    = ls_line-mjahr.
        ls_alv-budat    = ls_line-budat.
        ls_alv-bwart    = ls_line-bwart.
        ls_alv-werks    = ls_line-werks.
        ls_alv-lgort    = ls_line-lgort.
        ls_alv-to_werks = ls_line-to_werks.
        ls_alv-to_lgort = ls_line-to_lgort.
      ENDIF.
      ls_alv-lines = ls_alv-lines + 1.
      IF ls_line-rsnum IS NOT INITIAL.
        INSERT ls_line-rsnum INTO TABLE lt_rs.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_rs INTO DATA(lv_rs).
      IF ls_alv-rsnum_txt IS INITIAL.
        ls_alv-rsnum_txt = lv_rs.
      ELSE.
        ls_alv-rsnum_txt = |{ ls_alv-rsnum_txt }; { lv_rs }|.
      ENDIF.
    ENDLOOP.

    ls_alv-issue   = |{ ls_alv-werks }/{ ls_alv-lgort }|.
    ls_alv-recv    = |{ ls_alv-to_werks }/{ ls_alv-to_lgort }|.
    ls_alv-rev_by  = VALUE #( gt_docrev[ mblnr = ls_alv-mblnr mjahr = ls_alv-mjahr ]-rev_docs OPTIONAL ).
    ls_alv-obj_key = |{ ls_alv-mblnr }/{ ls_alv-mjahr }/{ ls_alv-werks }{ ls_alv-lgort }/| &&
                     |{ ls_alv-to_werks }{ ls_alv-to_lgort }|.

    ls_sheet = CORRESPONDING #( ls_alv ).
    PERFORM resolve_sheet USING ls_sheet abap_false CHANGING ls_lay.
    ls_alv-loai = ls_lay-type_txt.
    IF ls_lay-signs IS NOT INITIAL.
      ls_alv-loai = |{ ls_lay-type_txt } – ký: { concat_lines_of( table = ls_lay-signs sep = ` / ` ) }|.
    ENDIF.

    APPEND ls_alv TO gt_alv.
  ENDLOOP.

  SORT gt_alv BY mblnr mjahr werks lgort to_werks to_lgort.

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
      lo_column ?= lo_columns->get_column( 'BUDAT' ).
      PERFORM set_col_text USING lo_column 'Ngày HT'.
      lo_column ?= lo_columns->get_column( 'BWART' ).
      PERFORM set_col_text USING lo_column 'MvT'.
      lo_column ?= lo_columns->get_column( 'ISSUE' ).
      PERFORM set_col_text USING lo_column 'Plant/SLoc xuất'.
      lo_column ?= lo_columns->get_column( 'RECV' ).
      PERFORM set_col_text USING lo_column 'Plant/SLoc nhận'.
      lo_column ?= lo_columns->get_column( 'LOAI' ).
      PERFORM set_col_text USING lo_column 'Loại phiếu'.
      lo_column ?= lo_columns->get_column( 'RSNUM_TXT' ).
      PERFORM set_col_text USING lo_column 'Reservation'.
      lo_column ?= lo_columns->get_column( 'LINES' ).
      PERFORM set_col_text USING lo_column 'Số dòng'.
      lo_column ?= lo_columns->get_column( 'REV_BY' ).
      PERFORM set_col_text USING lo_column 'Hủy bởi'.
      lo_column ?= lo_columns->get_column( 'PRINT_COUNT' ).
      PERFORM set_col_text USING lo_column 'Đã in (lần)'.

      lo_columns->get_column( 'LAST_USER' )->set_technical( abap_true ).
      lo_columns->get_column( 'WERKS' )->set_technical( abap_true ).
      lo_columns->get_column( 'LGORT' )->set_technical( abap_true ).
      lo_columns->get_column( 'TO_WERKS' )->set_technical( abap_true ).
      lo_columns->get_column( 'TO_LGORT' )->set_technical( abap_true ).
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
  lv_head = |{ lv_head } \| Mẫu in: { COND string( WHEN p_op1 = abap_true THEN '1. Thành phẩm, hàng hóa'
                                                   WHEN p_op2 = abap_true THEN '2. Thuốc gây nghiện'
                                                   ELSE '3. Nguyên liệu, bao bì' ) }|.
*                                                   WHEN p_op3 = abap_true THEN '3. Nguyên liệu, bao bì'
*                                                   ELSE '4. Mẫu 4' ) }|.

  CREATE OBJECT lo_grid.
  lo_grid->create_label( row = 1 column = 1
                         text = 'ZWM05 – Danh sách chứng từ chuyển kho' ).
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
      default_file_name = |ZWM05_{ sy-datum }.xlsx|
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
*       Nhãn cố định của một phiếu; cột và nhãn thay đổi theo nhóm nghiệp vụ và mẫu in.
*----------------------------------------------------------------------*
FORM get_parameter USING is_lay TYPE gty_lay.

  DATA(lv_dc) = xsdbool( is_lay-grp <> gc_grp_tt ).

  CLEAR gs_parameter.

  gs_parameter-logo = gc_logo.

  gs_parameter-header22 = lcl_util=>lbl_c( iv_vi = 'Số chứng từ' iv_en = 'Document number' ).
  gs_parameter-header20 = lcl_util=>lbl_c( iv_vi = 'Số yêu cầu' iv_en = 'Reservation number' ).
  gs_parameter-header18 = lcl_util=>lbl_c( iv_vi = 'Diễn giải' iv_en = 'Description' ).
  IF lv_dc = abap_true.
    gs_parameter-header09 = lcl_util=>lbl_c( iv_vi = 'Mã/ tên đơn vị nhận' iv_en = 'Recipient code/ name' ).
    gs_parameter-header16 = lcl_util=>lbl_c( iv_vi = 'Kho xuất' iv_en = 'Issuing storage location' ).
  ELSE.
    gs_parameter-header11 = lcl_util=>lbl_c( iv_vi = 'Chuyển trạng thái' iv_en = 'Status transfer' ).
    gs_parameter-header16 = lcl_util=>lbl_c( iv_vi = 'Kho' iv_en = 'Storage location' ).
  ENDIF.

  gs_parameter-parameter01 = lcl_util=>lbl( iv_vi = 'STT' iv_en = 'No.' ).
  gs_parameter-parameter02 = lcl_util=>lbl( iv_vi = 'Mã hàng' iv_en = 'Product code' ).
  gs_parameter-parameter03 = lcl_util=>lbl( iv_vi = 'Tên hàng' iv_en = 'Product name' ).
  gs_parameter-parameter04 = lcl_util=>lbl( iv_vi = 'NSX – Nước SX' iv_en = 'Manufacturer - Country' ).
  gs_parameter-parameter05 = lcl_util=>lbl( iv_vi = 'Số lô NSX' iv_en = 'Batch number' ).
  gs_parameter-parameter06 = lcl_util=>lbl( iv_vi = 'Số lô SAP' iv_en = 'SAP batch' ).
  gs_parameter-parameter07 = COND #( WHEN lv_dc = abap_true AND p_op1 = abap_true AND gv_bi = abap_true
                                     THEN lcl_util=>lbl( iv_vi = 'Ngày SX - Hạn dùng' iv_en = 'MFG date - Expiry date' )
                                     ELSE lcl_util=>lbl( iv_vi = 'Hạn dùng / KNL' iv_en = 'Expiry / Retest date' ) ).
  gs_parameter-parameter08 = lcl_util=>lbl( iv_vi = 'Quy cách' iv_en = 'Packaging' ).
  gs_parameter-parameter09 = lcl_util=>lbl( iv_vi = 'ĐVT' iv_en = 'Unit' ).
  gs_parameter-parameter10 = lcl_util=>lbl( iv_vi = 'Số lượng' iv_en = 'Quantity' ).
  gs_parameter-parameter11 = lcl_util=>lbl( iv_vi = 'SL quy đổi' iv_en = 'Conversion of quantity' ).
  gs_parameter-parameter12 = lcl_util=>lbl( iv_vi = 'ĐK bảo quản' iv_en = 'Storage conditions' ).
  IF lv_dc = abap_true AND p_op3 = abap_true.
    gs_parameter-parameter13 = lcl_util=>lbl( iv_vi = 'Ngày cấp/ Thủ kho' iv_en = 'Date of issue/ Storekeeper' ).
    gs_parameter-parameter14 = lcl_util=>lbl( iv_vi = 'Người nhận' iv_en = 'Receiver' ).
  ENDIF.
  IF lv_dc = abap_true AND p_op1 = abap_true AND gv_bi = abap_true.
    gs_parameter-parameter15 = lcl_util=>lbl( iv_vi = 'Dạng bào chế' iv_en = 'Dosage form' ).
  ENDIF.

  gs_parameter-sign01 = VALUE #( is_lay-signs[ 1 ] OPTIONAL ).
  gs_parameter-sign02 = VALUE #( is_lay-signs[ 2 ] OPTIONAL ).
  gs_parameter-sign03 = VALUE #( is_lay-signs[ 3 ] OPTIONAL ).
  gs_parameter-sign04 = VALUE #( is_lay-signs[ 4 ] OPTIONAL ).
  gs_parameter-sign06 = lcl_util=>lbl( iv_vi = '(Ký, ghi rõ họ tên)' iv_en = '(Signature, full name)' ).

  gs_parameter-footer05 = 'Ngày ….. tháng ….. năm ……..'.
  gs_parameter-footer06 = lcl_util=>lbl( iv_vi = 'Trang' iv_en = 'Page' ).

ENDFORM.                    " GET_PARAMETER

*&---------------------------------------------------------------------*
*&      Form  PRINT_DOCS
*&---------------------------------------------------------------------*
*       Mỗi dòng ALV là một phiếu. Chỉ In mới ghi nhật ký.
*----------------------------------------------------------------------*
FORM print_docs USING iv_preview TYPE abap_bool.

  DATA: ls_cparam  TYPE ssfctrlop,
        ls_output  TYPE ssfcompop,
        ls_job_opt TYPE ssfcresop,
        ls_job_inf TYPE ssfcrescl,
        lv_spld    TYPE usr01-spld,
        lv_doc     TYPE string,
        ls_lay     TYPE gty_lay,
        ls_sheet   TYPE gty_sheet,
        ls_fm      TYPE gty_fm,
        lt_fm      TYPE HASHED TABLE OF gty_fm WITH UNIQUE KEY form,
        lt_run     TYPE gtt_run,
        lt_done    TYPE gtt_alv.

  DATA(lt_sel) = VALUE gtt_alv( FOR ls_a IN gt_alv WHERE ( sel = abap_true ) ( ls_a ) ).
  IF lt_sel IS INITIAL.
    MESSAGE s008 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_sel INTO DATA(ls_sel).
    lv_doc = |{ ls_sel-mblnr ALPHA = OUT }|.
    IF ls_sel-rev_by IS NOT INITIAL.
      PERFORM add_msg USING 'I' '004' lv_doc ls_sel-rev_by space.
    ENDIF.
    IF ls_sel-print_count > 0 AND iv_preview = abap_false.
      PERFORM add_msg USING 'I' '006' lv_doc ls_sel-print_count space.
    ENDIF.

    ls_sheet = CORRESPONDING #( ls_sel ).
    PERFORM resolve_sheet USING ls_sheet abap_true CHANGING ls_lay.
    CHECK ls_lay-block = abap_false.
    APPEND VALUE #( alv = ls_sel lay = ls_lay ) TO lt_run.
  ENDLOOP.
  PERFORM show_messages.

  CHECK lt_run IS NOT INITIAL.

  LOOP AT lt_run INTO DATA(ls_run).
    CHECK NOT line_exists( lt_fm[ form = ls_run-lay-form ] ).
    ls_fm-form = ls_run-lay-form.
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname = ls_fm-form
      IMPORTING
        fm_name  = ls_fm-fm
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    INSERT ls_fm INTO TABLE lt_fm.
  ENDLOOP.

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

  LOOP AT lt_run INTO ls_run.
    PERFORM fill_form USING ls_run-alv ls_run-lay.
    CHECK gt_data IS NOT INITIAL.

    ls_fm = lt_fm[ form = ls_run-lay-form ].
    CALL FUNCTION ls_fm-fm
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
    APPEND ls_run-alv TO lt_done.
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

  PERFORM write_prtlog USING lt_done.
  PERFORM read_print_count.
  go_alv->refresh( ).

ENDFORM.                    " PRINT_DOCS

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM
*&---------------------------------------------------------------------*
FORM fill_form USING is_alv TYPE gty_alv
                     is_lay TYPE gty_lay.

  DATA: lt_line     TYPE gtt_item,
        lt_rs       TYPE SORTED TABLE OF rsnum WITH UNIQUE KEY table_line,
        lt_stat     TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line,
        ls_hdr      TYPE gty_hdr,
        ls_plant    TYPE gty_partner,
        ls_plant_en TYPE gty_partner,
        ls_comp     TYPE gty_partner,
        lv_from     TYPE string,
        lv_to       TYPE string,
        lv_rs       TYPE string,
        lv_from_stk TYPE string,
        lv_to_stk   TYPE string,
        lv_pair     TYPE string,
        lv_lot      TYPE string,
        lv_lbl      TYPE string,
        lv_diff_pl  TYPE abap_bool.

  CLEAR gt_data.

  LOOP AT gt_item INTO DATA(ls_i) WHERE mblnr    = is_alv-mblnr
                                    AND mjahr    = is_alv-mjahr
                                    AND werks    = is_alv-werks
                                    AND lgort    = is_alv-lgort
                                    AND to_werks = is_alv-to_werks
                                    AND to_lgort = is_alv-to_lgort.
    APPEND ls_i TO lt_line.
  ENDLOOP.

  READ TABLE lt_line INTO DATA(ls_first) INDEX 1.
  CHECK sy-subrc = 0.

  SORT lt_line BY zeile.

  PERFORM get_parameter USING is_lay.

  gs_parameter-title_report    = is_lay-title.
  gs_parameter-title_report_en = is_lay-title_en.

  " Header đơn vị theo Plant, MST theo Company Code
  PERFORM read_partner USING 'P' ls_first-werks CHANGING ls_plant.
  PERFORM read_partner USING 'C' ls_first-bukrs CHANGING ls_comp.
  gs_parameter-header01 = to_upper( ls_plant-name ).
  gs_parameter-header02 = ls_plant-address.
  gs_parameter-header03 = |{ lcl_util=>lbl_c( iv_vi = 'Điện thoại' iv_en = 'Tel' ) } { ls_plant-tel }|.
  gs_parameter-header04 = |Fax: { ls_plant-fax }|.
  gs_parameter-header05 = |{ lcl_util=>lbl_c( iv_vi = 'MST' iv_en = 'TIN' ) } { ls_comp-tax }|.
  gs_parameter-header06 = |Website: { ls_plant-remark }|.
  IF gv_bi = abap_true.
    PERFORM read_partner USING 'Q' ls_first-werks CHANGING ls_plant_en.
    gs_parameter-header39 = to_upper( ls_plant_en-name ).
    gs_parameter-header40 = ls_plant_en-address.
  ENDIF.

  gs_parameter-header08 = COND #(
    WHEN gv_bi = abap_true
    THEN |Ngày/ Date { ls_first-budat+6(2) } tháng/ month { ls_first-budat+4(2) } năm/ year { ls_first-budat(4) }|
    ELSE |Ngày { ls_first-budat+6(2) } tháng { ls_first-budat+4(2) } năm { ls_first-budat(4) }| ).

  gs_parameter-header23 = |{ ls_first-mblnr ALPHA = OUT }|.

  " Số yêu cầu: các reservation khác nhau của cả chứng từ
  LOOP AT gt_item INTO DATA(ls_doc) WHERE mblnr = ls_first-mblnr
                                      AND mjahr = ls_first-mjahr.
    IF ls_doc-rsnum IS NOT INITIAL.
      INSERT ls_doc-rsnum INTO TABLE lt_rs.
    ENDIF.
  ENDLOOP.
  LOOP AT lt_rs INTO DATA(lv_rsnum).
    lv_rs = COND #( WHEN lv_rs IS INITIAL THEN |{ lv_rsnum }| ELSE |{ lv_rs }; { lv_rsnum }| ).
  ENDLOOP.
  gs_parameter-header21 = lv_rs.

  PERFORM resolve_header USING ls_first CHANGING ls_hdr.
  gs_parameter-header19 = COND #( WHEN gv_bi = abap_true AND ls_hdr-descr_en IS NOT INITIAL
                                   AND ls_hdr-descr_en <> ls_hdr-descr
                                  THEN |{ ls_hdr-descr }/ { ls_hdr-descr_en }|
                                  ELSE ls_hdr-descr ).

  " Plant chỉ hiện ở kho xuất / kho nhận khi chuyển giữa 2 Plant
  lv_diff_pl = xsdbool( ls_first-werks <> ls_first-to_werks ).
  PERFORM loc_text USING ls_first-werks ls_first-lgort lv_diff_pl CHANGING lv_from.
  gs_parameter-header17 = lv_from.

  IF is_lay-grp = gc_grp_tt.
    LOOP AT lt_line INTO DATA(ls_t).
      PERFORM stock_text USING ls_t-insmk CHANGING lv_from_stk.
      PERFORM stock_text USING ls_t-rcv_insmk CHANGING lv_to_stk.
      lv_pair = |{ lv_from_stk } → { lv_to_stk }|.
      INSERT lv_pair INTO TABLE lt_stat.
    ENDLOOP.
    gs_parameter-header12 = concat_lines_of( table = lt_stat sep = `; ` ).

    " Chứng từ sinh từ Usage Decision: kèm số lô kiểm tra
    DATA(ls_qa) = VALUE gty_qamb( gt_qamb[ mblnr = ls_first-mblnr mjahr = ls_first-mjahr
                                           zeile = ls_first-zeile ] OPTIONAL ).
    IF ls_qa-prueflos IS NOT INITIAL.
      lv_lot = |{ ls_qa-prueflos ALPHA = OUT }|.
      lv_lbl = lcl_util=>lbl( iv_vi = 'Lô kiểm tra' iv_en = 'Inspection lot' ).
      gs_parameter-header12 = |{ gs_parameter-header12 } – { lv_lbl } { lv_lot }|.
    ENDIF.
  ELSE.
    PERFORM loc_text USING ls_first-to_werks ls_first-to_lgort lv_diff_pl CHANGING lv_to.
    gs_parameter-header10 = lv_to.
  ENDIF.

  DATA(lv_cnt) = is_alv-print_count.
  gs_parameter-iso_line01 = COND #( WHEN lv_cnt = 0 THEN |Lần in: 1|
                                    ELSE |Bản in lại – lần { lv_cnt + 1 }| ).
  gs_parameter-footer07   = COND #( WHEN lv_cnt = 0 THEN space
                                    ELSE |Bản in lại – lần { lv_cnt + 1 }| ).
  gs_parameter-footer03   = |In lúc: { sy-datum+6(2) }/{ sy-datum+4(2) }/{ sy-datum(4) } | &&
                            |{ sy-uzeit(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) } – User: { sy-uname }|.

  IF is_alv-rev_by IS NOT INITIAL.
    lv_lbl = lcl_util=>lbl( iv_vi = 'Chứng từ đã bị hủy bởi' iv_en = 'Document cancelled by' ).
    gs_parameter-footer04 = |{ lv_lbl } { is_alv-rev_by }|.
  ENDIF.

  PERFORM fill_form_lines USING lt_line is_lay.

ENDFORM.                    " FILL_FORM

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM_LINES
*&---------------------------------------------------------------------*
FORM fill_form_lines USING it_line TYPE gtt_item
                           is_lay  TYPE gty_lay.

  DATA: ls_data    TYPE zwm_st_pck,
        ls_partner TYPE gty_partner,
        lv_stt     TYPE i,
        lv_nsx     TYPE char255,
        lv_land1   TYPE land1,
        lv_nuoc    TYPE char255,
        lv_mfrnr   TYPE mfrnr,
        lv_exp     TYPE string,
        lv_knl     TYPE string,
        lv_hsd     TYPE string,
        lv_qd      TYPE char255.

  LOOP AT it_line INTO DATA(ls_item).

    CLEAR: ls_data, lv_nsx, lv_land1, lv_nuoc, lv_exp, lv_knl, lv_hsd.
    lv_stt = lv_stt + 1.
    ls_data-stt   = lv_stt.
    ls_data-mblnr = ls_item-mblnr.
    ls_data-lgort = ls_item-lgort.
    ls_data-werks = ls_item-werks.
    ls_data-meins = ls_item-meins.
    ls_data-menge = ls_item-menge.

    DATA(ls_mat) = VALUE gty_mat( gt_mat[ matnr = ls_item-matnr ] OPTIONAL ).
    DATA(ls_bat) = VALUE gty_batch( gt_batch[ matnr = ls_item-matnr
                                              werks = ls_item-werks
                                              charg = ls_item-charg ] OPTIONAL ).

    " Đổi mã vật tư: mã xuất → mã nhận
    ls_data-matnr = |{ ls_item-matnr ALPHA = OUT }|.
    IF ls_item-to_matnr IS NOT INITIAL AND ls_item-to_matnr <> ls_item-matnr.
      ls_data-matnr = |{ ls_data-matnr } → { ls_item-to_matnr ALPHA = OUT }|.
    ENDIF.

    ls_data-maktx = VALUE #( gt_makt[ matnr = ls_item-matnr spras = gc_spras_vi ]-maktx OPTIONAL ).
    IF ls_data-maktx IS INITIAL.
      ls_data-maktx = VALUE #( gt_makt[ matnr = ls_item-matnr spras = gc_spras_en ]-maktx OPTIONAL ).
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

    " Số lô NSX: Z_BATCH_NSX, rồi LICHA, rồi lô SAP
    ls_data-solo = COND #( WHEN ls_bat-z_lonsx IS NOT INITIAL THEN ls_bat-z_lonsx
                           WHEN ls_bat-licha   IS NOT INITIAL THEN ls_bat-licha
                           ELSE ls_item-charg ).

    ls_data-charg = ls_item-charg.
    IF ls_item-to_charg IS NOT INITIAL AND ls_item-to_charg <> ls_item-charg.
      ls_data-charg = |{ ls_item-charg } → { ls_item-to_charg }|.
    ENDIF.

    " Hạn dùng; vật tư nhóm retest thêm ngày KNL; mẫu 1 song ngữ ghép Ngày SX - Hạn dùng
    PERFORM fmt_date USING ls_bat-vfdat CHANGING lv_exp.
    IF ls_bat-qndat IS NOT INITIAL AND ls_mat-mtart IN gr_mtart_knl.
      PERFORM fmt_date USING ls_bat-qndat CHANGING lv_knl.
      lv_knl = |KNL { lv_knl }|.
    ENDIF.
    lv_exp = condense( |{ lv_exp } { lv_knl }| ).
    IF is_lay-grp = gc_grp_dc AND p_op1 = abap_true AND gv_bi = abap_true.
      PERFORM fmt_date USING ls_bat-hsdat CHANGING lv_hsd.
      lv_exp = COND #( WHEN lv_hsd IS NOT INITIAL THEN |{ lv_hsd } - { lv_exp }| ELSE lv_exp ).
    ENDIF.
    ls_data-handung = lv_exp.

    ls_data-groes = COND #( WHEN ls_bat-quycach IS NOT INITIAL THEN ls_bat-quycach
                            ELSE ls_mat-groes ).

    PERFORM convert_qty USING ls_item-matnr ls_item-menge ls_item-erfmg ls_item-erfme ls_item-meins
                        CHANGING lv_qd.
    ls_data-quydoi = lv_qd.

    ls_data-baoquan = COND #( WHEN ls_bat-baoquan IS NOT INITIAL THEN ls_bat-baoquan
                              ELSE ls_mat-raube_txt ).

    APPEND ls_data TO gt_data.
  ENDLOOP.

ENDFORM.                    " FILL_FORM_LINES

*&---------------------------------------------------------------------*
*&      Form  CONVERT_QTY
*&---------------------------------------------------------------------*
*       Quy đổi SL theo MARM từ đơn vị lớn đến nhỏ; chỉ có 1 đơn vị thì lấy SL theo ĐVT nhập liệu.
*----------------------------------------------------------------------*
FORM convert_qty USING iv_matnr TYPE matnr
                       iv_menge TYPE menge_d
                       iv_erfmg TYPE erfmg
                       iv_erfme TYPE erfme
                       iv_meins TYPE meins
                 CHANGING cv_text TYPE char255.

  TYPES: BEGIN OF lty_unit,
           factor TYPE decfloat34,
           pref   TYPE i,
           mass   TYPE abap_bool,
           name   TYPE string,
         END OF lty_unit.

  DATA: lt_u     TYPE STANDARD TABLE OF lty_unit WITH EMPTY KEY,
        lv_rest  TYPE decfloat34,
        lv_n     TYPE decfloat34,
        lv_code  TYPE msehi,
        lv_txt   TYPE string,
        lv_part  TYPE string,
        lv_chr   TYPE c LENGTH 30,
        lv_cunit TYPE c LENGTH 10.

  CLEAR cv_text.

  LOOP AT gt_marm INTO DATA(ls_m) WHERE matnr = iv_matnr.
    lv_code = COND #( WHEN ls_m-meinh = gc_unit_box THEN gc_unit_hop
                      WHEN ls_m-meinh = gc_unit_car OR ls_m-meinh = gc_unit_kar THEN gc_unit_thu
                      ELSE ls_m-meinh ).
    DATA(ls_un) = VALUE gty_unit( gt_unit[ msehi = lv_code ] OPTIONAL ).
    APPEND VALUE #( factor = CONV decfloat34( ls_m-umrez ) / ls_m-umren
                    pref   = COND #( WHEN lv_code = gc_unit_hop OR lv_code = gc_unit_thu THEN 0 ELSE 1 )
                    mass   = xsdbool( ls_un-dimid = gc_dimid_mass )
                    name   = COND #( WHEN ls_un-mseh6 IS NOT INITIAL
                                     THEN to_upper( condense( ls_un-mseh6 ) )
                                     ELSE |{ lv_code }| ) ) TO lt_u.
  ENDLOOP.

  SORT lt_u BY factor DESCENDING pref ASCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_u COMPARING factor.

  IF lines( lt_u ) > 1 AND iv_menge > 0.
    lv_rest = iv_menge.
    LOOP AT lt_u INTO DATA(ls_u).
      lv_n = lv_rest / ls_u-factor.
      IF ls_u-mass = abap_false.
        lv_n = floor( lv_n ).
      ENDIF.
      lv_rest = lv_rest - lv_n * ls_u-factor.
      CHECK lv_n > 0.
      PERFORM fmt_qty USING lv_n CHANGING lv_part.
      lv_part = |{ lv_part } { ls_u-name }|.
      lv_txt  = COND #( WHEN lv_txt IS INITIAL THEN lv_part ELSE |{ lv_txt } { lv_part }| ).
    ENDLOOP.
  ENDIF.

  IF lv_txt IS INITIAL.
    IF iv_erfme IS NOT INITIAL.
      WRITE iv_erfmg UNIT iv_erfme TO lv_chr LEFT-JUSTIFIED.
      CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
        EXPORTING
          input    = iv_erfme
          language = sy-langu
        IMPORTING
          output   = lv_cunit
        EXCEPTIONS
          OTHERS   = 1.
    ELSE.
      WRITE iv_menge UNIT iv_meins TO lv_chr LEFT-JUSTIFIED.
      CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
        EXPORTING
          input    = iv_meins
          language = sy-langu
        IMPORTING
          output   = lv_cunit
        EXCEPTIONS
          OTHERS   = 1.
    ENDIF.
    lv_txt = |{ lv_chr } { lv_cunit }|.
  ENDIF.

  cv_text = lv_txt.

ENDFORM.                    " CONVERT_QTY

*&---------------------------------------------------------------------*
*&      Form  FMT_QTY
*&---------------------------------------------------------------------*
*       Số nguyên không phần lẻ; số lẻ tối đa 3 chữ số, bỏ số 0 cuối.
*----------------------------------------------------------------------*
FORM fmt_qty USING iv_qty TYPE decfloat34
             CHANGING cv_text TYPE string.

  DATA lv_int TYPE decfloat34.

  lv_int = trunc( iv_qty ).
  IF iv_qty = lv_int.
    cv_text = |{ iv_qty DECIMALS = 0 NUMBER = USER }|.
    RETURN.
  ENDIF.

  cv_text = |{ iv_qty DECIMALS = 3 NUMBER = USER }|.
  WHILE cv_text IS NOT INITIAL
    AND substring( val = cv_text off = strlen( cv_text ) - 1 len = 1 ) = '0'.
    cv_text = substring( val = cv_text len = strlen( cv_text ) - 1 ).
  ENDWHILE.
  IF cv_text IS NOT INITIAL
     AND ( substring( val = cv_text off = strlen( cv_text ) - 1 len = 1 ) = ','
        OR substring( val = cv_text off = strlen( cv_text ) - 1 len = 1 ) = '.' ).
    cv_text = substring( val = cv_text len = strlen( cv_text ) - 1 ).
  ENDIF.

ENDFORM.                    " FMT_QTY

*&---------------------------------------------------------------------*
*&      Form  FMT_DATE
*&---------------------------------------------------------------------*
FORM fmt_date USING iv_date TYPE d
              CHANGING cv_text TYPE string.

  CLEAR cv_text.
  CHECK iv_date IS NOT INITIAL.
  cv_text = |{ iv_date+6(2) }/{ iv_date+4(2) }/{ iv_date(4) }|.

ENDFORM.                    " FMT_DATE

*&---------------------------------------------------------------------*
*&      Form  LOC_TEXT
*&---------------------------------------------------------------------*
*       "SLoc - tên"; IV_PLANT = X thêm "Plant - tên /" phía trước.
*----------------------------------------------------------------------*
FORM loc_text USING iv_werks TYPE werks_d
                    iv_lgort TYPE lgort_d
                    iv_plant TYPE abap_bool
              CHANGING cv_text TYPE string.

  DATA(ls_lg) = VALUE gty_lgort( gt_lgort[ werks = iv_werks lgort = iv_lgort ] OPTIONAL ).
  cv_text = |{ iv_lgort } - { ls_lg-lgobe }|.

  CHECK iv_plant = abap_true.
  DATA(ls_pl) = VALUE gty_plant( gt_plant[ werks = iv_werks ] OPTIONAL ).
  cv_text = |{ iv_werks } - { ls_pl-name1 } / { cv_text }|.

ENDFORM.                    " LOC_TEXT

*&---------------------------------------------------------------------*
*&      Form  STOCK_TEXT
*&---------------------------------------------------------------------*
*       Tên loại tồn kho theo domain MB_INSMK (Việt, thiếu thì Anh).
*----------------------------------------------------------------------*
FORM stock_text USING iv_insmk TYPE mb_insmk
                CHANGING cv_text TYPE string.

  DATA(lv_vi) = VALUE val_text( gt_insmk[ domvalue_l = iv_insmk ddlanguage = gc_spras_vi ]-ddtext OPTIONAL ).
  DATA(lv_en) = VALUE val_text( gt_insmk[ domvalue_l = iv_insmk ddlanguage = gc_spras_en ]-ddtext OPTIONAL ).

  IF gv_bi = abap_true AND lv_vi IS NOT INITIAL AND lv_en IS NOT INITIAL.
    cv_text = |{ lv_vi }/ { lv_en }|.
  ELSEIF lv_vi IS NOT INITIAL.
    cv_text = lv_vi.
  ELSE.
    cv_text = lv_en.
  ENDIF.

ENDFORM.                    " STOCK_TEXT

*&---------------------------------------------------------------------*
*&      Form  RESOLVE_HEADER
*&---------------------------------------------------------------------*
*       Diễn giải: chứng từ hủy, MvT 321, Header text, rồi ZTWM_MVT_GRP.
*----------------------------------------------------------------------*
FORM resolve_header USING is_line TYPE gty_item
                    CHANGING cs_hdr TYPE gty_hdr.

  CLEAR cs_hdr.

  IF is_line-smbln IS NOT INITIAL.
    DATA(lv_ref) = |{ is_line-smbln ALPHA = OUT }|.
    cs_hdr-descr    = |Hủy chứng từ { lv_ref }|.
    cs_hdr-descr_en = |Cancel document { lv_ref }|.
  ELSEIF is_line-bwart = gc_bwart_ud.
    cs_hdr-descr    = COND #( WHEN is_line-txt_vi IS NOT INITIAL THEN is_line-txt_vi
                              ELSE 'Đạt yêu cầu sử dụng' ).
    cs_hdr-descr_en = is_line-txt_en.
  ELSEIF is_line-bktxt IS NOT INITIAL.
    cs_hdr-descr = is_line-bktxt.
  ELSE.
    cs_hdr-descr    = is_line-txt_vi.
    cs_hdr-descr_en = is_line-txt_en.
  ENDIF.

ENDFORM.                    " RESOLVE_HEADER

*&---------------------------------------------------------------------*
*&      Form  READ_PARTNER
*&---------------------------------------------------------------------*
*       Loại: K nhà cung cấp, P Plant, Q Plant (địa chỉ quốc tế), C Company Code.
*----------------------------------------------------------------------*
FORM read_partner USING iv_kind   TYPE char1
                        iv_number TYPE any
                  CHANGING cs_partner TYPE gty_partner.

  DATA lv_num TYPE char10.

  CLEAR cs_partner.
  lv_num = iv_number.
  CONDENSE lv_num.
  CHECK lv_num IS NOT INITIAL.
  IF iv_kind = 'K' AND lv_num CO '0123456789'.
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
*       Mỗi phiếu 1 bản ghi, cộng số lần in trực tiếp trên DB.
*----------------------------------------------------------------------*
FORM write_prtlog USING it_doc TYPE gtt_alv.

* Bỏ mẫu 4: còn 3 mẫu
*  DATA(lv_opt) = COND zewm_de_rpt_opt( WHEN p_op1 = abap_true THEN '1'
*                                       WHEN p_op2 = abap_true THEN '2'
*                                       WHEN p_op3 = abap_true THEN '3'
*                                       ELSE '4' ).
  DATA(lv_opt) = COND zewm_de_rpt_opt( WHEN p_op1 = abap_true THEN '1'
                                       WHEN p_op2 = abap_true THEN '2'
                                       ELSE '3' ).

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
                                                  lgort      = ls_doc-lgort
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
