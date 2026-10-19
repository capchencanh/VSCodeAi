*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_LCVT_F01
*&---------------------------------------------------------------------*

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_function FOR EVENT added_function OF cl_salv_events_table
        IMPORTING e_salv_function,
      on_click FOR EVENT link_click OF cl_salv_events_table
        IMPORTING row column.
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
        PERFORM show_detail.
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
*&      Form  INIT_SCREEN
*&---------------------------------------------------------------------*
FORM init_screen .

  GET PARAMETER ID '/SCWM/LGN' FIELD p_lgnum.
  s_date[] = VALUE #( ( sign = 'I' option = 'EQ' low = sy-datum ) ).

ENDFORM.                    " INIT_SCREEN

*&---------------------------------------------------------------------*
*&      Form  CHECK_CONDITION
*&---------------------------------------------------------------------*
*       Option 1 phải chọn ít nhất một loại. Không nhập Warehouse Task: bắt buộc Ngày tạo WT, tối đa 31 ngày.
*----------------------------------------------------------------------*
FORM check_condition .

  DATA: lv_min TYPE d,
        lv_max TYPE d,
        lv_hi  TYPE d.

  CHECK sy-ucomm = 'ONLI' OR sy-ucomm = 'PRIN' OR sy-ucomm = 'SJOB'
     OR sy-batch = abap_true.

  IF p_op1 = abap_true AND p_b2b = abap_false AND p_ptw = abap_false AND p_pck = abap_false.
    MESSAGE e003.
  ENDIF.

  CHECK s_tanum[] IS INITIAL.

  IF s_date[] IS INITIAL.
    SET CURSOR FIELD 'S_DATE-LOW'.
    MESSAGE e002.
  ENDIF.

  LOOP AT s_date INTO DATA(ls_date).
    IF ls_date-sign <> 'I' OR ls_date-low IS INITIAL
       OR ( ls_date-option <> 'EQ'
        AND ( ls_date-option <> 'BT' OR ls_date-high IS INITIAL ) ).
      SET CURSOR FIELD 'S_DATE-LOW'.
      MESSAGE e002.
    ENDIF.
    lv_hi = COND #( WHEN ls_date-option = 'BT' THEN ls_date-high ELSE ls_date-low ).
    IF lv_min IS INITIAL OR ls_date-low < lv_min.
      lv_min = ls_date-low.
    ENDIF.
    IF lv_hi > lv_max.
      lv_max = lv_hi.
    ENDIF.
  ENDLOOP.

  IF lv_max - lv_min + 1 > gc_max_days.
    SET CURSOR FIELD 'S_DATE-LOW'.
    MESSAGE e002.
  ENDIF.

ENDFORM.                    " CHECK_CONDITION

*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITY_WH
*&---------------------------------------------------------------------*
FORM check_authority_wh .

  AUTHORITY-CHECK OBJECT '/SCWM/LG'
    ID '/SCWM/LGNU' FIELD p_lgnum
    ID '/SCWM/LGTY' DUMMY
    ID 'ACTVT'      FIELD '03'.
  IF sy-subrc <> 0.
    MESSAGE s001 WITH p_lgnum DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.                    " CHECK_AUTHORITY_WH

*&---------------------------------------------------------------------*
*&      Form  GET_OPTION_CONFIG
*&---------------------------------------------------------------------*
*       WPT của Option đang chọn (Option 1: chỉ các loại được tick) theo ZTWM_WT_OPT.
*----------------------------------------------------------------------*
FORM get_option_config .

  DATA lr_loai TYPE RANGE OF char1.

  gv_opt = COND #( WHEN p_op1 = abap_true THEN '1'
                   WHEN p_op2 = abap_true THEN '2'
                   ELSE '3' ).

  IF p_op1 = abap_true.
    IF p_b2b = abap_true.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = gc_loai_b2b ) TO lr_loai.
    ENDIF.
    IF p_ptw = abap_true.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = gc_loai_ptw ) TO lr_loai.
    ENDIF.
    IF p_pck = abap_true.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = gc_loai_pck ) TO lr_loai.
    ENDIF.
  ENDIF.

  SELECT loai, procty, rdoccat
    FROM ztwm_wt_opt
    WHERE lgnum = @p_lgnum
      AND opt   = @gv_opt
      AND loai  IN @lr_loai
    INTO CORRESPONDING FIELDS OF TABLE @gt_opt.

ENDFORM.                    " GET_OPTION_CONFIG

*&---------------------------------------------------------------------*
*&      Form  GET_CREATED_RANGE
*&---------------------------------------------------------------------*
*       Ngày tạo WT theo giờ Warehouse (CREATED_AT_WH). Có nhập Warehouse Task thì bỏ qua ngày mặc định.
*----------------------------------------------------------------------*
FORM get_created_range CHANGING cr_created TYPE gtt_r_ts.

  DATA: lv_hi   TYPE d,
        lv_t0   TYPE t VALUE '000000',
        lv_t1   TYPE t VALUE '235959',
        lv_from TYPE timestamp,
        lv_to   TYPE timestamp.

  CLEAR cr_created.
  CHECK s_tanum[] IS INITIAL.

  LOOP AT s_date INTO DATA(ls_date).
    lv_hi = COND #( WHEN ls_date-option = 'BT' THEN ls_date-high ELSE ls_date-low ).
    CONVERT DATE ls_date-low TIME lv_t0 INTO TIME STAMP lv_from TIME ZONE 'UTC'.
    CONVERT DATE lv_hi TIME lv_t1 INTO TIME STAMP lv_to TIME ZONE 'UTC'.
    APPEND VALUE #( sign = 'I' option = 'BT' low = lv_from high = lv_to ) TO cr_created.
  ENDLOOP.

ENDFORM.                    " GET_CREATED_RANGE

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       WT mở (/SCWM/ORDIM_O) và / hoặc WT đã xác nhận (/SCWM/ORDIM_C); bỏ WT đã hủy.
*----------------------------------------------------------------------*
FORM get_data .

  DATA: lr_created TYPE gtt_r_ts,
        lr_procty  TYPE RANGE OF /scwm/de_procty,
        lr_docno   TYPE RANGE OF /scdl/dl_docno_int,
        lt_wt      TYPE gtt_wt,
        lv_docno   TYPE /scdl/dl_docno_int.

  LOOP AT gt_opt INTO DATA(ls_opt).
    APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_opt-procty ) TO lr_procty.
  ENDLOOP.
  CHECK lr_procty IS NOT INITIAL.
  SORT lr_procty BY low.
  DELETE ADJACENT DUPLICATES FROM lr_procty COMPARING low.

  PERFORM get_created_range CHANGING lr_created.

  " Số chứng từ tham chiếu so sánh sau khi bỏ số 0 đầu để không phụ thuộc cách lưu
  LOOP AT s_docno INTO DATA(ls_docno).
    APPEND VALUE #( sign   = ls_docno-sign
                    option = ls_docno-option
                    low    = |{ ls_docno-low ALPHA = OUT }|
                    high   = |{ ls_docno-high ALPHA = OUT }| ) TO lr_docno.
  ENDLOOP.

  IF p_st1 = abap_true OR p_st3 = abap_true.
    SELECT FROM /scwm/ordim_o AS w
      LEFT OUTER JOIN mara AS m ON m~scm_matid_guid16 = w~matid
      LEFT OUTER JOIN /scdl/db_proch_o AS po ON po~docid = w~rdocid
      LEFT OUTER JOIN /scdl/db_proch_i AS pi ON pi~docid = w~rdocid
      FIELDS w~lgnum,
             w~tanum,
             w~who,
             w~procty,
             w~vltyp,
             w~vlpla,
             w~nltyp,
             w~nlpla,
             m~matnr,
             w~charg,
             w~meins,
             w~vsolm,
             w~created_by,
             w~created_at_wh,
             w~entitled,
             w~cat,
             w~rdoccat,
             w~prod_order,
             COALESCE( po~docno, pi~docno ) AS docno
      WHERE w~lgnum         = @p_lgnum
        AND w~tanum         IN @s_tanum
        AND w~procty        IN @lr_procty
        AND w~procty        IN @s_procty
        AND w~created_at_wh IN @lr_created
        AND w~created_by    IN @s_user
        AND ( w~vltyp IN @s_lgtyp OR w~nltyp IN @s_lgtyp )
        AND m~matnr         IN @s_matnr
        AND w~prod_order    IN @s_aufnr
        AND w~tostat        <> @gc_tostat_canc
      INTO CORRESPONDING FIELDS OF TABLE @lt_wt.
  ENDIF.

  IF p_st2 = abap_true OR p_st3 = abap_true.
    SELECT FROM /scwm/ordim_c AS w
      LEFT OUTER JOIN mara AS m ON m~scm_matid_guid16 = w~matid
      LEFT OUTER JOIN /scdl/db_proch_o AS po ON po~docid = w~rdocid
      LEFT OUTER JOIN /scdl/db_proch_i AS pi ON pi~docid = w~rdocid
      FIELDS w~lgnum,
             w~tanum,
             w~tapos,
             w~who,
             'X' AS conf,
             w~procty,
             w~vltyp,
             w~vlpla,
             w~nltyp,
             w~nlpla,
             m~matnr,
             w~charg,
             w~meins,
             w~vsolm,
             w~nistm,
             w~created_by,
             w~created_at_wh,
             w~entitled,
             w~cat,
             w~rdoccat,
             w~prod_order,
             COALESCE( po~docno, pi~docno ) AS docno
      WHERE w~lgnum         = @p_lgnum
        AND w~tanum         IN @s_tanum
        AND w~procty        IN @lr_procty
        AND w~procty        IN @s_procty
        AND w~created_at_wh IN @lr_created
        AND w~created_by    IN @s_user
        AND ( w~vltyp IN @s_lgtyp OR w~nltyp IN @s_lgtyp )
        AND m~matnr         IN @s_matnr
        AND w~prod_order    IN @s_aufnr
        AND w~tostat        <> @gc_tostat_canc
      APPENDING CORRESPONDING FIELDS OF TABLE @lt_wt.
  ENDIF.

  " Giữ WT có WPT (và loại chứng từ tham chiếu) khớp cấu hình; cấu hình để trống loại chứng từ = bất kỳ
  LOOP AT lt_wt INTO DATA(ls_wt).
    READ TABLE gt_opt INTO ls_opt
         WITH TABLE KEY procty = ls_wt-procty rdoccat = ls_wt-rdoccat.
    IF sy-subrc <> 0.
      READ TABLE gt_opt INTO ls_opt
           WITH TABLE KEY procty = ls_wt-procty rdoccat = space.
    ENDIF.
    CHECK sy-subrc = 0.

    IF lr_docno IS NOT INITIAL.
      lv_docno = |{ ls_wt-docno ALPHA = OUT }|.
      CHECK lv_docno IN lr_docno.
    ENDIF.

    ls_wt-loai = ls_opt-loai.
    INSERT ls_wt INTO TABLE gt_wt.
  ENDLOOP.

ENDFORM.                    " GET_DATA

*&---------------------------------------------------------------------*
*&      Form  CHECK_UNDECLARED_WPT
*&---------------------------------------------------------------------*
*       WT thỏa điều kiện lọc nhưng WPT chưa khai báo ở bất kỳ Option nào: báo ZWM07-005, mỗi WPT một lần.
*----------------------------------------------------------------------*
FORM check_undeclared_wpt .

  TYPES: BEGIN OF lty_und,
           procty TYPE /scwm/de_procty,
           tanum  TYPE /scwm/tanum,
         END OF lty_und.

  DATA: lr_created TYPE gtt_r_ts,
        lt_und     TYPE STANDARD TABLE OF lty_und WITH EMPTY KEY,
        lv_tanum   TYPE string.

  PERFORM get_created_range CHANGING lr_created.

  IF p_st1 = abap_true OR p_st3 = abap_true.
    SELECT FROM /scwm/ordim_o AS w
      LEFT OUTER JOIN ztwm_wt_opt AS o ON o~lgnum  = w~lgnum
                                      AND o~procty = w~procty
      FIELDS w~procty, MIN( w~tanum ) AS tanum
      WHERE w~lgnum         = @p_lgnum
        AND w~tanum         IN @s_tanum
        AND w~procty        IN @s_procty
        AND w~created_at_wh IN @lr_created
        AND w~created_by    IN @s_user
        AND w~tostat        <> @gc_tostat_canc
        AND o~procty        IS NULL
      GROUP BY w~procty
      INTO CORRESPONDING FIELDS OF TABLE @lt_und.
  ENDIF.

  IF p_st2 = abap_true OR p_st3 = abap_true.
    SELECT FROM /scwm/ordim_c AS w
      LEFT OUTER JOIN ztwm_wt_opt AS o ON o~lgnum  = w~lgnum
                                      AND o~procty = w~procty
      FIELDS w~procty, MIN( w~tanum ) AS tanum
      WHERE w~lgnum         = @p_lgnum
        AND w~tanum         IN @s_tanum
        AND w~procty        IN @s_procty
        AND w~created_at_wh IN @lr_created
        AND w~created_by    IN @s_user
        AND w~tostat        <> @gc_tostat_canc
        AND o~procty        IS NULL
      GROUP BY w~procty
      APPENDING CORRESPONDING FIELDS OF TABLE @lt_und.
  ENDIF.

  SORT lt_und BY procty tanum.
  DELETE ADJACENT DUPLICATES FROM lt_und COMPARING procty.

  LOOP AT lt_und INTO DATA(ls_und).
    lv_tanum = |{ ls_und-tanum ALPHA = OUT }|.
    PERFORM add_msg USING 'W' '005' ls_und-procty lv_tanum space.
  ENDLOOP.

ENDFORM.                    " CHECK_UNDECLARED_WPT

*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITY_TYPE
*&---------------------------------------------------------------------*
*       Loại WT mà user không có quyền ở Storage Type nguồn hoặc đích; báo số dòng bị loại.
*----------------------------------------------------------------------*
FORM check_authority_type .

  DATA: lt_typ    TYPE SORTED TABLE OF /scwm/lgtyp WITH UNIQUE KEY table_line,
        lv_count  TYPE i,
        lv_before TYPE i,
        lv_first  TYPE /scwm/lgtyp.

  LOOP AT gt_wt INTO DATA(ls_wt).
    IF ls_wt-vltyp IS NOT INITIAL.
      INSERT ls_wt-vltyp INTO TABLE lt_typ.
    ENDIF.
    IF ls_wt-nltyp IS NOT INITIAL.
      INSERT ls_wt-nltyp INTO TABLE lt_typ.
    ENDIF.
  ENDLOOP.

  LOOP AT lt_typ INTO DATA(lv_typ).
    AUTHORITY-CHECK OBJECT '/SCWM/LG'
      ID '/SCWM/LGNU' FIELD p_lgnum
      ID '/SCWM/LGTY' FIELD lv_typ
      ID 'ACTVT'      FIELD '03'.
    CHECK sy-subrc <> 0.

    IF lv_first IS INITIAL.
      lv_first = lv_typ.
    ENDIF.
    lv_before = lines( gt_wt ).
    DELETE gt_wt WHERE vltyp = lv_typ OR nltyp = lv_typ.
    lv_count = lv_count + lv_before - lines( gt_wt ).
  ENDLOOP.

  CHECK lv_count > 0.
  PERFORM add_msg USING 'W' '008' lv_count p_lgnum lv_first.

ENDFORM.                    " CHECK_AUTHORITY_TYPE

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
    CALL FUNCTION 'MESSAGES_INITIALIZE'
      EXCEPTIONS
        OTHERS = 0.
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
      OTHERS                  = 0.

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
      OTHERS     = 0.
  gv_msg_init = abap_false.

ENDFORM.                    " SHOW_MESSAGES

*&---------------------------------------------------------------------*
*&      Form  GET_MASTER_DATA
*&---------------------------------------------------------------------*
FORM get_master_data .

  DATA: lt_matnr TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line,
        lt_bkey  TYPE SORTED TABLE OF gty_bkey WITH UNIQUE KEY matnr charg,
        lt_lkey  TYPE SORTED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
        lt_pkey  TYPE SORTED TABLE OF werks_d WITH UNIQUE KEY table_line,
        lt_auf   TYPE SORTED TABLE OF aufnr WITH UNIQUE KEY table_line,
        lt_vbeln TYPE SORTED TABLE OF vbeln_vl WITH UNIQUE KEY table_line,
        lt_dlv   TYPE gtt_dlv,
        lv_vbeln TYPE vbeln_vl.

  LOOP AT gt_wt ASSIGNING FIELD-SYMBOL(<lfs_wt>).
    PERFORM get_erp_loc USING <lfs_wt>-lgnum <lfs_wt>-entitled <lfs_wt>-cat
                        CHANGING <lfs_wt>-werks <lfs_wt>-lgort.

    IF <lfs_wt>-matnr IS NOT INITIAL.
      INSERT <lfs_wt>-matnr INTO TABLE lt_matnr.
      IF <lfs_wt>-charg IS NOT INITIAL.
        INSERT VALUE #( matnr = <lfs_wt>-matnr charg = <lfs_wt>-charg ) INTO TABLE lt_bkey.
      ENDIF.
    ENDIF.
    IF <lfs_wt>-werks IS NOT INITIAL.
      INSERT <lfs_wt>-werks INTO TABLE lt_pkey.
      INSERT VALUE #( werks = <lfs_wt>-werks lgort = <lfs_wt>-lgort ) INTO TABLE lt_lkey.
    ENDIF.
    IF <lfs_wt>-prod_order IS NOT INITIAL.
      INSERT <lfs_wt>-prod_order INTO TABLE lt_auf.
    ENDIF.
    IF <lfs_wt>-rdoccat = gc_cat_pdo OR <lfs_wt>-rdoccat = gc_cat_pdi.
      PERFORM docno_to_vbeln USING <lfs_wt>-docno CHANGING lv_vbeln.
      IF lv_vbeln IS NOT INITIAL.
        INSERT lv_vbeln INTO TABLE lt_vbeln.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF lt_auf IS NOT INITIAL.
    SELECT FROM afpo
      INNER JOIN @lt_auf AS k ON k~table_line = afpo~aufnr
      FIELDS afpo~aufnr, MIN( afpo~matnr ) AS matnr
      GROUP BY afpo~aufnr
      INTO CORRESPONDING FIELDS OF TABLE @gt_auf   ##ITAB_DB_SELECT.

    LOOP AT gt_auf INTO DATA(ls_auf).
      INSERT ls_auf-matnr INTO TABLE lt_matnr.
    ENDLOOP.
  ENDIF.

  IF lt_matnr IS NOT INITIAL.
    SELECT FROM makt
      INNER JOIN @lt_matnr AS k ON k~table_line = makt~matnr
      FIELDS makt~matnr, makt~spras, makt~maktx
      WHERE makt~spras IN ( @gc_spras_vi, @gc_spras_en )
      INTO CORRESPONDING FIELDS OF TABLE @gt_makt   ##ITAB_DB_SELECT.
  ENDIF.

  IF lt_bkey IS NOT INITIAL.
    SELECT FROM mcha
      INNER JOIN @lt_bkey AS k ON k~matnr = mcha~matnr
                              AND k~charg = mcha~charg
      FIELDS mcha~matnr, mcha~werks, mcha~charg, mcha~licha
      INTO CORRESPONDING FIELDS OF TABLE @gt_batch   ##ITAB_DB_SELECT.

    PERFORM get_batch_charact.
  ENDIF.

  IF lt_lkey IS NOT INITIAL.
    SELECT FROM t001l
      INNER JOIN @lt_lkey AS k ON k~werks = t001l~werks
                              AND k~lgort = t001l~lgort
      FIELDS t001l~werks, t001l~lgort, t001l~lgobe
      INTO CORRESPONDING FIELDS OF TABLE @gt_lgort   ##ITAB_DB_SELECT.
  ENDIF.

  IF lt_pkey IS NOT INITIAL.
    SELECT FROM t001w
      INNER JOIN @lt_pkey AS k ON k~table_line = t001w~werks
      LEFT OUTER JOIN t001k ON t001k~bwkey = t001w~bwkey
      FIELDS t001w~werks, t001w~name1, t001k~bukrs
      INTO CORRESPONDING FIELDS OF TABLE @gt_plant   ##ITAB_DB_SELECT.
  ENDIF.

  IF lt_vbeln IS NOT INITIAL.
    " Ship-to của Delivery (VBPA header, WE) lấy tên từ ADRC; thiếu thì tên khách hàng KNA1
    SELECT FROM likp
      INNER JOIN @lt_vbeln AS k ON k~table_line = likp~vbeln
      LEFT OUTER JOIN vbpa ON vbpa~vbeln = likp~vbeln
                          AND vbpa~posnr = '000000'
                          AND vbpa~parvw = 'WE'
      LEFT OUTER JOIN adrc ON adrc~addrnumber = vbpa~adrnr
                          AND adrc~nation     = @space
      LEFT OUTER JOIN kna1 ON kna1~kunnr = likp~kunnr
      FIELDS likp~vbeln, likp~kunnr, likp~lifnr,
             adrc~date_from, adrc~name1, adrc~name2, adrc~name3, adrc~name4,
             kna1~name1 AS kname1
      INTO CORRESPONDING FIELDS OF TABLE @lt_dlv   ##ITAB_DB_SELECT.

    SORT lt_dlv BY vbeln ASCENDING date_from DESCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_dlv COMPARING vbeln.

    " Tên: NAME2–NAME4 nếu có, không thì NAME1 (như ZCORE_FM_GET_PROFILE_SD)
    LOOP AT lt_dlv ASSIGNING FIELD-SYMBOL(<lfs_dlv>).
      <lfs_dlv>-name = COND #( WHEN <lfs_dlv>-name1 IS INITIAL AND <lfs_dlv>-name2 IS INITIAL
                                    AND <lfs_dlv>-name3 IS INITIAL AND <lfs_dlv>-name4 IS INITIAL
                               THEN <lfs_dlv>-kname1
                               WHEN <lfs_dlv>-name2 IS INITIAL AND <lfs_dlv>-name3 IS INITIAL
                                    AND <lfs_dlv>-name4 IS INITIAL
                               THEN <lfs_dlv>-name1
                               ELSE condense( |{ <lfs_dlv>-name2 } { <lfs_dlv>-name3 } { <lfs_dlv>-name4 }| ) ).
    ENDLOOP.
    gt_dlv = lt_dlv.
  ENDIF.

  " Diễn giải WPT: tiếng Việt, thiếu thì tiếng Anh
  SELECT procty, spras, lbwat
    FROM /scwm/t333t
    WHERE lgnum = @p_lgnum
      AND spras IN ( @gc_spras_vi, @gc_spras_en )
    ORDER BY procty, spras DESCENDING
    INTO TABLE @DATA(lt_t333).
  LOOP AT lt_t333 INTO DATA(ls_t333).
    INSERT VALUE #( procty = ls_t333-procty lbwat = ls_t333-lbwat ) INTO TABLE gt_wpt.
  ENDLOOP.

  SELECT SINGLE lnumt FROM /scwm/t300t
    WHERE lgnum = @p_lgnum
      AND spras = @gc_spras_vi
    INTO @gv_lgnum_txt.
  IF sy-subrc <> 0.
    SELECT SINGLE lnumt FROM /scwm/t300t
      WHERE lgnum = @p_lgnum
        AND spras = @gc_spras_en
      INTO @gv_lgnum_txt.
  ENDIF.

ENDFORM.                    " GET_MASTER_DATA

*&---------------------------------------------------------------------*
*&      Form  GET_ERP_LOC
*&---------------------------------------------------------------------*
*       Plant / SLoc ERP của tồn EWM theo ánh xạ chuẩn (Party entitled + loại tồn), đọc 1 lần mỗi cặp.
*----------------------------------------------------------------------*
FORM get_erp_loc USING iv_lgnum    TYPE /scwm/lgnum
                       iv_entitled TYPE /scwm/de_entitled
                       iv_cat      TYPE /scwm/de_cat
                 CHANGING cv_werks TYPE werks_d
                          cv_lgort TYPE lgort_d.

  DATA: ls_map  TYPE gty_map,
        lv_bestq TYPE bestq.

  CLEAR: cv_werks, cv_lgort.

  READ TABLE gt_map INTO ls_map
       WITH TABLE KEY lgnum = iv_lgnum entitled = iv_entitled cat = iv_cat.
  IF sy-subrc <> 0.
    CLEAR ls_map.
    ls_map-lgnum    = iv_lgnum.
    ls_map-entitled = iv_entitled.
    ls_map-cat      = iv_cat.
    IF go_map IS NOT BOUND.
      CALL FUNCTION '/SCWM/GET_STOCKID_MAP_INSTANCE'
        IMPORTING
          eif_stockid_mapping = go_map.
    ENDIF.
    IF go_map IS BOUND.
      TRY.
          go_map->get_erp_stloc( EXPORTING iv_lgnum         = iv_lgnum
                                           iv_entitled      = iv_entitled
                                           iv_cat           = iv_cat
                                 IMPORTING ev_erp_plant     = ls_map-werks
                                           ev_erp_stloc     = ls_map-lgort
                                           ev_erp_stock_cat = lv_bestq ).
        CATCH /scwm/cx_stockid_map.
          CLEAR: ls_map-werks, ls_map-lgort.
      ENDTRY.
    ENDIF.
    INSERT ls_map INTO TABLE gt_map.
  ENDIF.

  cv_werks = ls_map-werks.
  cv_lgort = ls_map-lgort.

ENDFORM.                    " GET_ERP_LOC

*&---------------------------------------------------------------------*
*&      Form  DOCNO_TO_VBELN
*&---------------------------------------------------------------------*
*       Số Delivery ERP từ số chứng từ EWM (bỏ số 0 đầu rồi đệm lại 10 ký tự).
*----------------------------------------------------------------------*
FORM docno_to_vbeln USING iv_docno TYPE /scdl/dl_docno_int
                    CHANGING cv_vbeln TYPE vbeln_vl.

  DATA lv_str TYPE string.

  CLEAR cv_vbeln.
  lv_str = iv_docno.
  SHIFT lv_str LEFT DELETING LEADING '0'.
  CHECK lv_str IS NOT INITIAL AND lv_str CO '0123456789' AND strlen( lv_str ) <= 10.
  cv_vbeln = |{ lv_str ALPHA = IN WIDTH = 10 }|.

ENDFORM.                    " DOCNO_TO_VBELN

*&---------------------------------------------------------------------*
*&      Form  GET_BATCH_CHARACT
*&---------------------------------------------------------------------*
FORM get_batch_charact .

  DATA: lt_atnam TYPE STANDARD TABLE OF zcore_st_rseloption_atnam,
        lt_char  TYPE STANDARD TABLE OF bapi1003_alloc_values_char.

  lt_atnam = VALUE #( ( sign = 'I' option = 'EQ' low = gc_at_lonsx ) ).

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

    LOOP AT lt_char INTO DATA(ls_char) WHERE charact = gc_at_lonsx.
      <lfs_bat>-z_lonsx = ls_char-value_char.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " GET_BATCH_CHARACT

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_DATA
*&---------------------------------------------------------------------*
*       Mỗi dòng ALV là một Warehouse Task (WT đã xác nhận nhiều item vẫn một dòng).
*----------------------------------------------------------------------*
FORM build_alv_data .

  DATA: ls_alv  TYPE gty_alv,
        lv_time TYPE t.

  CLEAR gt_alv.

  LOOP AT gt_wt INTO DATA(ls_wt)
       GROUP BY ( lgnum = ls_wt-lgnum tanum = ls_wt-tanum ) INTO DATA(lg_wt).

    CLEAR ls_alv.
    LOOP AT GROUP lg_wt INTO DATA(ls_line).
      IF ls_alv IS INITIAL.
        ls_alv-tanum      = ls_line-tanum.
        ls_alv-lgnum      = ls_line-lgnum.
        ls_alv-who        = ls_line-who.
        ls_alv-procty     = ls_line-procty.
        ls_alv-vlpla      = ls_line-vlpla.
        ls_alv-nlpla      = ls_line-nlpla.
        ls_alv-aufnr      = ls_line-prod_order.
        ls_alv-created_by = ls_line-created_by.
        ls_alv-ref_doc    = COND #( WHEN ls_line-rdoccat IS NOT INITIAL
                                    THEN |{ ls_line-rdoccat } { ls_line-docno ALPHA = OUT }| ).
        CONVERT TIME STAMP ls_line-created_at_wh TIME ZONE 'UTC'
                INTO DATE ls_alv-created_on TIME lv_time.
      ENDIF.
    ENDLOOP.

    ls_alv-obj_key = COND #( WHEN ls_alv-who IS NOT INITIAL
                             THEN |{ ls_alv-lgnum }/WO{ ls_alv-who }|
                             ELSE |{ ls_alv-lgnum }/WT{ ls_alv-tanum }| ).
    APPEND ls_alv TO gt_alv.
  ENDLOOP.

  SORT gt_alv BY who vlpla tanum.

  PERFORM read_print_count.

ENDFORM.                    " BUILD_ALV_DATA

*&---------------------------------------------------------------------*
*&      Form  READ_PRINT_COUNT
*&---------------------------------------------------------------------*
FORM read_print_count .

  CHECK gt_alv IS NOT INITIAL.

  SELECT FROM @gt_alv AS k
    INNER JOIN ztwm_prtlog AS l ON l~obj_key = k~obj_key
    FIELDS l~obj_key, l~prt_count, l~last_date, l~last_time, l~last_user
    WHERE l~tcode    = @gc_tcode
      AND l~formname = @gc_prt_form
    INTO TABLE @DATA(lt_cnt)   ##ITAB_DB_SELECT.

  LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<lfs_alv>).
    DATA(ls_cnt) = VALUE #( lt_cnt[ obj_key = <lfs_alv>-obj_key ] OPTIONAL ).
    <lfs_alv>-print_count = ls_cnt-prt_count.
    <lfs_alv>-last_user   = ls_cnt-last_user.
    <lfs_alv>-last_print  = COND #( WHEN ls_cnt-last_date IS NOT INITIAL
                                    THEN |{ ls_cnt-last_date DATE = USER } { ls_cnt-last_time TIME = USER }|
                                    ELSE space ).
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

      lo_column ?= lo_columns->get_column( 'TANUM' ).
      PERFORM set_col_text USING lo_column 'Warehouse Task'.
      lo_column ?= lo_columns->get_column( 'PROCTY' ).
      PERFORM set_col_text USING lo_column 'WPT'.
      lo_column ?= lo_columns->get_column( 'VLPLA' ).
      PERFORM set_col_text USING lo_column 'Bin nguồn đầu'.
      lo_column ?= lo_columns->get_column( 'NLPLA' ).
      PERFORM set_col_text USING lo_column 'Bin đích'.
      lo_column ?= lo_columns->get_column( 'REF_DOC' ).
      PERFORM set_col_text USING lo_column 'Chứng từ tham chiếu'.
      lo_column ?= lo_columns->get_column( 'AUFNR' ).
      PERFORM set_col_text USING lo_column 'Lệnh SX'.
      lo_column ?= lo_columns->get_column( 'CREATED_BY' ).
      PERFORM set_col_text USING lo_column 'Người tạo'.
      lo_column ?= lo_columns->get_column( 'CREATED_ON' ).
      PERFORM set_col_text USING lo_column 'Ngày tạo'.
      lo_column ?= lo_columns->get_column( 'PRINT_COUNT' ).
      PERFORM set_col_text USING lo_column 'Đã in (lần)'.
      lo_column ?= lo_columns->get_column( 'LAST_PRINT' ).
      PERFORM set_col_text USING lo_column 'Lần cuối in'.
      lo_column ?= lo_columns->get_column( 'LAST_USER' ).
      PERFORM set_col_text USING lo_column 'Người in cuối'.

      " Lệnh SX chỉ hiện ở Option 2, 3
      IF p_op1 = abap_true.
        lo_columns->get_column( 'AUFNR' )->set_visible( abap_false ).
      ENDIF.
      lo_columns->get_column( 'LGNUM' )->set_technical( abap_true ).
      lo_columns->get_column( 'WHO' )->set_technical( abap_true ).
      lo_columns->get_column( 'OBJ_KEY' )->set_technical( abap_true ).
    CATCH cx_salv_not_found.
  ENDTRY.

  lv_head = |Warehouse { p_lgnum } \| Option: { COND string( WHEN p_op1 = abap_true THEN '1. Điều chuyển giữa 2 vị trí'
                                                          WHEN p_op2 = abap_true THEN '2. Điều chuyển phục vụ Lệnh sản xuất'
                                                          ELSE '3. Điều chuyển bổ sung cho sản xuất' ) }| &&
            | \| Trạng thái: { COND string( WHEN p_st1 = abap_true THEN 'Chưa xác nhận'
                                            WHEN p_st2 = abap_true THEN 'Đã xác nhận'
                                            ELSE 'Tất cả' ) }|.

  CREATE OBJECT lo_grid.
  lo_grid->create_label( row = 1 column = 1
                         text = 'ZWM07 – Danh sách Warehouse Order / Task' ).
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
*&      Form  GET_MAKTX
*&---------------------------------------------------------------------*
*       Tên vật tư: tiếng Việt, thiếu thì tiếng Anh.
*----------------------------------------------------------------------*
FORM get_maktx USING iv_matnr TYPE matnr
               CHANGING cv_maktx TYPE maktx.

  cv_maktx = VALUE #( gt_makt[ matnr = iv_matnr spras = gc_spras_vi ]-maktx OPTIONAL ).
  IF cv_maktx IS INITIAL.
    cv_maktx = VALUE #( gt_makt[ matnr = iv_matnr spras = gc_spras_en ]-maktx OPTIONAL ).
  ENDIF.

ENDFORM.                    " GET_MAKTX

*&---------------------------------------------------------------------*
*&      Form  SHOW_DETAIL
*&---------------------------------------------------------------------*
*       Chi tiết các dòng WT của những dòng ALV được chọn.
*----------------------------------------------------------------------*
FORM show_detail .

  DATA: lt_det TYPE gtt_det,
        ls_det TYPE gty_det,
        lo_det TYPE REF TO cl_salv_table.

  DATA(lt_sel) = VALUE gtt_alv( FOR ls_a IN gt_alv WHERE ( sel = abap_true ) ( ls_a ) ).
  IF lt_sel IS INITIAL.
    MESSAGE s007 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_sel INTO DATA(ls_sel).
    LOOP AT gt_wt INTO DATA(ls_w) WHERE tanum = ls_sel-tanum.
      CLEAR ls_det.
      ls_det-tanum = ls_w-tanum.
      ls_det-tapos = ls_w-tapos.
      ls_det-stat  = COND #( WHEN ls_w-conf = abap_true THEN 'Đã xác nhận' ELSE 'Chưa xác nhận' ).
      ls_det-vltyp = ls_w-vltyp.
      ls_det-vlpla = ls_w-vlpla.
      ls_det-nltyp = ls_w-nltyp.
      ls_det-nlpla = ls_w-nlpla.
      ls_det-matnr = ls_w-matnr.
      ls_det-charg = ls_w-charg.
      ls_det-menge = COND #( WHEN ls_w-conf = abap_true THEN ls_w-nistm ELSE ls_w-vsolm ).
      ls_det-meins = ls_w-meins.
      PERFORM get_maktx USING ls_w-matnr CHANGING ls_det-maktx.
      APPEND ls_det TO lt_det.
    ENDLOOP.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_det
                              CHANGING  t_table      = lt_det ).
    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.

  lo_det->get_columns( )->set_optimize( abap_true ).
  lo_det->set_screen_popup( start_column = 5
                            end_column   = 160
                            start_line   = 3
                            end_line     = 25 ).
  lo_det->display( ).

ENDFORM.                    " SHOW_DETAIL

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
      default_file_name = |ZWM07_{ sy-datum }.xlsx|
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
*       Nhãn cố định của phiếu.
*----------------------------------------------------------------------*
FORM get_parameter .

  CLEAR gs_parameter.

  gs_parameter-logo         = gc_logo.
  gs_parameter-title_report = 'LỆNH CHUYỂN VỊ TRÍ'.

  gs_parameter-header09 = 'Plant / Storage Location:'.
  gs_parameter-header11 = 'Người tạo phiếu:'.
  gs_parameter-header13 = 'Chứng từ tham chiếu:'.
  gs_parameter-header15 = 'Lệnh SX / Khách hàng:'.
  gs_parameter-header17 = 'Loại điều chuyển:'.

  gs_parameter-parameter01 = 'STT'.
  gs_parameter-parameter02 = 'Warehouse Task'.
  gs_parameter-parameter03 = 'Xác nhận'.
  gs_parameter-parameter04 = 'Bin nguồn'.
  gs_parameter-parameter05 = 'Bin đích'.
  gs_parameter-parameter06 = 'Số WT'.
  gs_parameter-parameter07 = 'Mã hàng'.
  gs_parameter-parameter08 = 'Tên hàng'.
  gs_parameter-parameter09 = 'Số lô SAP'.
  gs_parameter-parameter10 = 'Số lô NSX'.
  gs_parameter-parameter11 = 'Số lượng'.
  gs_parameter-parameter12 = 'ĐVT'.
  gs_parameter-parameter13 = 'SL thực chuyển'.
  gs_parameter-parameter14 = 'Bin thực tế'.

  gs_parameter-sign01 = 'Nhân viên kho'.
  gs_parameter-sign02 = 'Thủ kho'.
  IF gv_opt <> '1'.
    gs_parameter-sign03 = 'Người nhận (phân xưởng)'.
  ENDIF.
  gs_parameter-sign06 = '(Ký, ghi rõ họ tên)'.

  gs_parameter-footer05 = 'Ngày ….. tháng ….. năm ……..'.
  gs_parameter-footer06 = 'Trang'.

ENDFORM.                    " GET_PARAMETER

*&---------------------------------------------------------------------*
*&      Form  PRINT_DOCS
*&---------------------------------------------------------------------*
*       Gom: một phiếu cho mọi dòng được chọn. Không gom: mỗi Warehouse Order (WT lẻ: mỗi WT) một phiếu.
*       Chỉ In mới ghi nhật ký.
*----------------------------------------------------------------------*
FORM print_docs USING iv_preview TYPE abap_bool.

  DATA: ls_cparam  TYPE ssfctrlop,
        ls_output  TYPE ssfcompop,
        ls_job_inf TYPE ssfcrescl,
        lv_spld    TYPE usr01-spld,
        lv_fm      TYPE rs38l_fnam,
        lv_doc     TYPE string,
        lt_sheet   TYPE gtt_sheet,
        lt_done    TYPE gtt_alv.

  DATA(lt_sel) = VALUE gtt_alv( FOR ls_a IN gt_alv WHERE ( sel = abap_true ) ( ls_a ) ).
  IF lt_sel IS INITIAL.
    MESSAGE s007 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT lt_sel BY who vlpla tanum.

  IF p_g1 = abap_true.
    APPEND VALUE #( id = 1 alv = lt_sel ) TO lt_sheet.
  ELSE.
    LOOP AT lt_sel INTO DATA(ls_sel) GROUP BY ls_sel-obj_key INTO DATA(lv_key).
      APPEND VALUE #( id  = lines( lt_sheet ) + 1
                      alv = VALUE #( FOR ls_m IN GROUP lv_key ( ls_m ) ) ) TO lt_sheet.
    ENDLOOP.
  ENDIF.

  IF iv_preview = abap_false.
    DATA(lt_unit) = lt_sel.
    SORT lt_unit BY obj_key.
    DELETE ADJACENT DUPLICATES FROM lt_unit COMPARING obj_key.
    LOOP AT lt_unit INTO DATA(ls_unit) WHERE print_count > 0.
      lv_doc = COND #( WHEN ls_unit-who IS NOT INITIAL THEN |{ ls_unit-who ALPHA = OUT }|
                       ELSE |{ ls_unit-tanum ALPHA = OUT }| ).
      PERFORM add_msg USING 'I' '006' lv_doc ls_unit-print_count space.
    ENDLOOP.
    PERFORM show_messages.
  ENDIF.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = gc_form
    IMPORTING
      fm_name  = lv_fm
    EXCEPTIONS
      OTHERS   = 1.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

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

  LOOP AT lt_sheet INTO DATA(ls_sheet).
    PERFORM fill_sheet USING ls_sheet-alv.
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
    APPEND LINES OF ls_sheet-alv TO lt_done.
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
*&      Form  FILL_SHEET
*&---------------------------------------------------------------------*
*       Header và dòng của một phiếu; header gộp các giá trị không trùng của các WT trong phiếu.
*----------------------------------------------------------------------*
FORM fill_sheet USING it_alv TYPE gtt_alv.

  DATA: lt_line    TYPE gtt_wt,
        lt_creator TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line,
        lt_loc     TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line,
        lt_ref     TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line,
        lt_cust    TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line,
        lt_type    TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line,
        ls_data    TYPE zwm_st_lcvt,
        ls_plant   TYPE gty_partner,
        ls_comp    TYPE gty_partner,
        ls_cust    TYPE gty_partner,
        ls_bat     TYPE gty_batch,
        lv_vbeln   TYPE vbeln_vl,
        lv_text    TYPE string,
        lv_maktx   TYPE maktx,
        lv_stt     TYPE i,
        lv_min_ts  TYPE /scwm/de_created_dt_wh,
        lv_date    TYPE d,
        lv_time    TYPE t,
        lv_cnt     TYPE i,
        lv_open    TYPE abap_bool.

  CLEAR gt_data.

  LOOP AT it_alv INTO DATA(ls_alv).
    LOOP AT gt_wt INTO DATA(ls_wt) WHERE tanum = ls_alv-tanum.
      APPEND ls_wt TO lt_line.
    ENDLOOP.
    lv_cnt = nmax( val1 = lv_cnt val2 = ls_alv-print_count ).
  ENDLOOP.
  CHECK lt_line IS NOT INITIAL.

  IF p_g1 = abap_true.
    SORT lt_line BY nlpla vlpla tanum tapos.
  ELSE.
    SORT lt_line BY vlpla tanum tapos.
  ENDIF.

  PERFORM get_parameter.

  LOOP AT lt_line INTO DATA(ls_l).

    CLEAR: ls_data, ls_bat.
    lv_stt = lv_stt + 1.
    ls_data-stt   = lv_stt.
    ls_data-tanum = |{ ls_l-tanum ALPHA = OUT }|.
    ls_data-vlpla = ls_l-vlpla.
    ls_data-nlpla = ls_l-nlpla.
    ls_data-matnr = |{ ls_l-matnr ALPHA = OUT }|.
    ls_data-charg = ls_l-charg.
    ls_data-meins = ls_l-meins.
    ls_data-menge = COND #( WHEN ls_l-conf = abap_true THEN ls_l-nistm ELSE ls_l-vsolm ).
    PERFORM get_maktx USING ls_l-matnr CHANGING ls_data-maktx.

    " Số lô NSX: Z_BATCH_NSX, rồi MCHA-LICHA, rồi lô SAP; ưu tiên lô của Plant ánh xạ
    READ TABLE gt_batch INTO ls_bat
         WITH TABLE KEY matnr = ls_l-matnr charg = ls_l-charg werks = ls_l-werks.
    IF sy-subrc <> 0.
      READ TABLE gt_batch INTO ls_bat
           WITH KEY matnr = ls_l-matnr charg = ls_l-charg.
    ENDIF.
    ls_data-solo = COND #( WHEN ls_bat-z_lonsx IS NOT INITIAL THEN ls_bat-z_lonsx
                           WHEN ls_bat-licha   IS NOT INITIAL THEN ls_bat-licha
                           ELSE ls_l-charg ).
    APPEND ls_data TO gt_data.

    IF ls_l-conf = abap_false.
      lv_open = abap_true.
    ENDIF.
    IF lv_min_ts IS INITIAL OR ls_l-created_at_wh < lv_min_ts.
      lv_min_ts = ls_l-created_at_wh.
    ENDIF.

    lv_text = |{ ls_l-created_by }|.
    INSERT lv_text INTO TABLE lt_creator.

    IF ls_l-werks IS NOT INITIAL.
      PERFORM loc_text USING ls_l-werks ls_l-lgort CHANGING lv_text.
      INSERT lv_text INTO TABLE lt_loc.
    ENDIF.

    IF ls_l-rdoccat IS NOT INITIAL.
      lv_text = |{ ls_l-rdoccat } { ls_l-docno ALPHA = OUT }|.
      INSERT lv_text INTO TABLE lt_ref.
    ENDIF.

    IF ls_l-prod_order IS NOT INITIAL.
      DATA(lv_auf_mat) = VALUE matnr( gt_auf[ aufnr = ls_l-prod_order ]-matnr OPTIONAL ).
      PERFORM get_maktx USING lv_auf_mat CHANGING lv_maktx.
      lv_text = |LSX { ls_l-prod_order ALPHA = OUT }|.
      IF lv_maktx IS NOT INITIAL.
        lv_text = |{ lv_text } - { lv_maktx }|.
      ENDIF.
      INSERT lv_text INTO TABLE lt_cust.
    ENDIF.

    " Picking theo Outbound Delivery: tên ship-to; Putaway theo Inbound Delivery: tên nhà cung cấp
    IF ls_l-rdoccat = gc_cat_pdo OR ls_l-rdoccat = gc_cat_pdi.
      PERFORM docno_to_vbeln USING ls_l-docno CHANGING lv_vbeln.
      DATA(ls_dlv) = VALUE gty_dlv( gt_dlv[ vbeln = lv_vbeln ] OPTIONAL ).
      CLEAR ls_cust.
      IF ls_l-rdoccat = gc_cat_pdo.
        ls_cust-name = ls_dlv-name.
      ELSEIF ls_l-rdoccat = gc_cat_pdi AND ls_dlv-lifnr IS NOT INITIAL.
        PERFORM read_partner USING 'K' ls_dlv-lifnr CHANGING ls_cust.
      ENDIF.
      IF ls_cust-name IS NOT INITIAL AND ls_cust-name(1) <> '*'.
        lv_text = ls_cust-name.
        INSERT lv_text INTO TABLE lt_cust.
      ENDIF.
    ENDIF.

    lv_text = VALUE string( gt_wpt[ procty = ls_l-procty ]-lbwat OPTIONAL ).
    IF lv_text IS INITIAL.
      lv_text = |{ ls_l-procty }|.
    ENDIF.
    INSERT lv_text INTO TABLE lt_type.

  ENDLOOP.

  READ TABLE lt_line INTO DATA(ls_first) INDEX 1.

  " Header đơn vị theo Plant, MST theo Company Code
  DATA(ls_pl) = VALUE gty_plant( gt_plant[ werks = ls_first-werks ] OPTIONAL ).
  PERFORM read_partner USING 'P' ls_first-werks CHANGING ls_plant.
  PERFORM read_partner USING 'C' ls_pl-bukrs CHANGING ls_comp.
  gs_parameter-header01 = to_upper( ls_plant-name ).
  gs_parameter-header02 = ls_plant-address.
  gs_parameter-header03 = |Điện thoại: { ls_plant-tel }|.
  gs_parameter-header04 = |Fax: { ls_plant-fax }|.
  gs_parameter-header05 = |MST: { ls_comp-tax }|.
  gs_parameter-header06 = |Website: { ls_plant-remark }|.
  gs_parameter-header07 = |Warehouse { p_lgnum } – { gv_lgnum_txt }|.

  CONVERT TIME STAMP lv_min_ts TIME ZONE 'UTC' INTO DATE lv_date TIME lv_time.
  gs_parameter-header08 = |Ngày { lv_date+6(2) } tháng { lv_date+4(2) } năm { lv_date(4) }|.

  gs_parameter-header10 = concat_lines_of( table = lt_loc sep = `; ` ).
  gs_parameter-header12 = concat_lines_of( table = lt_creator sep = `, ` ).
  gs_parameter-header14 = concat_lines_of( table = lt_ref sep = `, ` ).
  gs_parameter-header16 = concat_lines_of( table = lt_cust sep = `; ` ).
  gs_parameter-header18 = concat_lines_of( table = lt_type sep = `, ` ).

  " Phiếu toàn WT đã xác nhận là bản đối chiếu
  IF lv_open = abap_false.
    gs_parameter-below_title_report = 'Bản đối chiếu'.
  ENDIF.

  " Mã vạch số Warehouse Order (hoặc WT); phiếu gom nhiều Warehouse Order không in mã vạch
  DATA(lt_key) = it_alv.
  SORT lt_key BY obj_key.
  DELETE ADJACENT DUPLICATES FROM lt_key COMPARING obj_key.
  IF lines( lt_key ) = 1.
    READ TABLE lt_key INTO DATA(ls_key) INDEX 1.
    gs_parameter-barcode = COND #( WHEN ls_key-who IS NOT INITIAL THEN |{ ls_key-who }|
                                   ELSE |{ ls_key-tanum }| ).
  ENDIF.

  gs_parameter-iso_line01 = COND #( WHEN lv_cnt = 0 THEN |Lần in: 1|
                                    ELSE |Bản in lại – lần { lv_cnt + 1 }| ).
  gs_parameter-footer07   = COND #( WHEN lv_cnt = 0 THEN space
                                    ELSE |Bản in lại – lần { lv_cnt + 1 }| ).
  gs_parameter-footer03   = |In lúc: { sy-datum+6(2) }/{ sy-datum+4(2) }/{ sy-datum(4) } | &&
                            |{ sy-uzeit(2) }:{ sy-uzeit+2(2) } – User: { sy-uname }|.

ENDFORM.                    " FILL_SHEET

*&---------------------------------------------------------------------*
*&      Form  LOC_TEXT
*&---------------------------------------------------------------------*
*       "Plant - tên / SLoc - tên".
*----------------------------------------------------------------------*
FORM loc_text USING iv_werks TYPE werks_d
                    iv_lgort TYPE lgort_d
              CHANGING cv_text TYPE string.

  DATA(ls_lg) = VALUE gty_lgort( gt_lgort[ werks = iv_werks lgort = iv_lgort ] OPTIONAL ).
  DATA(ls_pl) = VALUE gty_plant( gt_plant[ werks = iv_werks ] OPTIONAL ).
  cv_text = |{ iv_werks } - { ls_pl-name1 } / { iv_lgort } - { ls_lg-lgobe }|.

ENDFORM.                    " LOC_TEXT

*&---------------------------------------------------------------------*
*&      Form  READ_PARTNER
*&---------------------------------------------------------------------*
*       Loại: K nhà cung cấp, P Plant, C Company Code.
*----------------------------------------------------------------------*
FORM read_partner USING iv_kind   TYPE char1
                        iv_number TYPE any
                  CHANGING cs_partner TYPE gty_partner.

  DATA lv_num TYPE char10.

  CLEAR cs_partner.
  lv_num = iv_number.
  CONDENSE lv_num.
  CHECK lv_num IS NOT INITIAL.

  READ TABLE gt_partner INTO cs_partner
       WITH TABLE KEY kind = iv_kind number = lv_num.
  CHECK sy-subrc <> 0.

  cs_partner-kind   = iv_kind.
  cs_partner-number = lv_num.
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
  INSERT cs_partner INTO TABLE gt_partner.

ENDFORM.                    " READ_PARTNER

*&---------------------------------------------------------------------*
*&      Form  WRITE_PRTLOG
*&---------------------------------------------------------------------*
*       Mỗi Warehouse Order (WT lẻ: mỗi WT) một bản ghi, cộng số lần in trực tiếp trên DB.
*----------------------------------------------------------------------*
FORM write_prtlog USING it_doc TYPE gtt_alv.

  DATA(lt_unit) = it_doc.
  SORT lt_unit BY obj_key.
  DELETE ADJACENT DUPLICATES FROM lt_unit COMPARING obj_key.

  LOOP AT lt_unit INTO DATA(ls_doc).
    UPDATE ztwm_prtlog
      SET prt_count = prt_count + 1,
          rpt_opt   = @gv_opt,
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
                                                  rpt_opt    = gv_opt
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
            rpt_opt   = @gv_opt,
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
