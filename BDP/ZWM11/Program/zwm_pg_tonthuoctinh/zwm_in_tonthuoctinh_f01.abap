*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_TONTHUOCTINH_F01
*&---------------------------------------------------------------------*

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_function FOR EVENT added_function OF cl_salv_events_table
        IMPORTING e_salv_function,
      on_double_click FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_function.
    CASE e_salv_function.
      WHEN 'MSC3N'.
        PERFORM show_selected_batch.
    ENDCASE.
  ENDMETHOD.

  METHOD on_double_click.
    READ TABLE gt_alv ASSIGNING FIELD-SYMBOL(<lfs_alv>) INDEX row.
    CHECK sy-subrc = 0.
    CASE column.
      WHEN 'CHARG'.
        PERFORM open_batch USING <lfs_alv>-matnr <lfs_alv>-werks <lfs_alv>-charg.
      WHEN 'MATNR'.
        PERFORM open_material USING <lfs_alv>-matnr.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*&      Form  INIT
*&---------------------------------------------------------------------*
FORM init .

  DATA ls_dyn TYPE smp_dyntxt.

  ls_dyn-icon_id   = icon_refresh.
  ls_dyn-icon_text = 'Lấy thuộc tính theo Batch Class'.
  ls_dyn-quickinfo = 'Sinh lại khối lọc thuộc tính theo Batch Class'.
  sscrfields-functxt_01 = ls_dyn.

  PERFORM get_batch_class_type.

ENDFORM.                    " INIT

*&---------------------------------------------------------------------*
*&      Form  GET_BATCH_CLASS_TYPE
*&---------------------------------------------------------------------*
*       Class type và bảng đối tượng phân loại của lô lấy theo cấu hình hệ thống.
*----------------------------------------------------------------------*
FORM get_batch_class_type .

  DATA lv_kzdch TYPE tcuch-kzdch.

  CALL FUNCTION 'VB_BATCH_DEFINITION'
    IMPORTING
      kzdch = lv_kzdch.

  gv_obtab = COND #( WHEN lv_kzdch = '0' THEN gc_obtab_mcha ELSE gc_obtab_mch1 ).

  CALL FUNCTION 'CLOB_GET_CLASSTYPE_FOR_BATCH'
    EXPORTING
      table     = gc_obtab_mcha
      ptable    = gv_obtab
      spras     = sy-langu
    IMPORTING
      classtype = gv_klart
    EXCEPTIONS
      OTHERS    = 1.
  IF sy-subrc <> 0.
    gv_klart = gc_klart_def.
    gv_obtab = gc_obtab_mcha.
  ENDIF.

ENDFORM.                    " GET_BATCH_CLASS_TYPE

*&---------------------------------------------------------------------*
*&      Form  MODIFY_SCREEN
*&---------------------------------------------------------------------*
*       Ẩn các dòng điều kiện thuộc tính vượt quá số thuộc tính đã sinh.
*----------------------------------------------------------------------*
FORM modify_screen .

  DATA lv_idx TYPE n LENGTH 2.

  IF p_auto = abap_true AND p_class IS NOT INITIAL AND p_class <> gv_class_cur.
    PERFORM build_char_list USING abap_false abap_false.
  ENDIF.

  LOOP AT gt_char ASSIGNING FIELD-SYMBOL(<lfs_char>).
    DATA(lv_name) = |LBL{ <lfs_char>-idx }|.
    ASSIGN (lv_name) TO FIELD-SYMBOL(<lfs_lbl>).
    CHECK sy-subrc = 0.
    <lfs_lbl> = COND string( WHEN <lfs_char>-label IS NOT INITIAL
                             THEN |{ <lfs_char>-atnam } - { <lfs_char>-label }|
                             ELSE <lfs_char>-atnam ).
  ENDLOOP.

  DATA(lv_cnt) = lines( gt_char ).

  LOOP AT SCREEN.
    CHECK screen-group1(1) = 'C' AND screen-group1+1(2) CO '0123456789'.
    lv_idx = screen-group1+1(2).
    CHECK lv_idx > lv_cnt.
    screen-active = 0.
    MODIFY SCREEN.
  ENDLOOP.

ENDFORM.                    " MODIFY_SCREEN

*&---------------------------------------------------------------------*
*&      Form  AT_SELECTION_SCREEN
*&---------------------------------------------------------------------*
FORM at_selection_screen .

  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      PERFORM build_char_list USING abap_true abap_true.
    WHEN 'ONLI' OR 'PRIN' OR 'SJOB'.
      PERFORM check_condition.
    WHEN OTHERS.
      IF p_auto = abap_true AND p_class <> gv_class_cur.
        IF p_class IS INITIAL.
          PERFORM clear_char_list.
        ELSE.
          PERFORM build_char_list USING abap_true abap_true.
        ENDIF.
      ENDIF.
  ENDCASE.

ENDFORM.                    " AT_SELECTION_SCREEN

*&---------------------------------------------------------------------*
*&      Form  CHECK_CONDITION
*&---------------------------------------------------------------------*
FORM check_condition .

  AUTHORITY-CHECK OBJECT 'M_MSEG_WMB'
    ID 'ACTVT' FIELD '03'
    ID 'WERKS' FIELD p_werks.
  IF sy-subrc <> 0.
    SET CURSOR FIELD 'P_WERKS'.
    MESSAGE e001 WITH p_werks space.
  ENDIF.

  PERFORM get_unit_info.
  PERFORM get_conditions.

ENDFORM.                    " CHECK_CONDITION

*&---------------------------------------------------------------------*
*&      Form  GET_UNIT_INFO
*&---------------------------------------------------------------------*
*       Số lẻ làm tròn và tên hiển thị của ĐVT quy đổi.
*----------------------------------------------------------------------*
FORM get_unit_info .

  CHECK p_meinh IS NOT INITIAL.

  SELECT SINGLE andec
    FROM t006
    WHERE msehi = @p_meinh
    INTO @gv_andec.
  IF sy-subrc <> 0.
    SET CURSOR FIELD 'P_MEINH'.
    MESSAGE e004 WITH p_meinh 'ĐVT quy đổi'.
  ENDIF.

  WRITE p_meinh TO gv_meinh_ext.

ENDFORM.                    " GET_UNIT_INFO

*&---------------------------------------------------------------------*
*&      Form  CLEAR_CHAR_LIST
*&---------------------------------------------------------------------*
FORM clear_char_list .

  DATA: lv_idx  TYPE n LENGTH 2,
        lv_name TYPE string.

  CLEAR: gt_char, gv_class_cur.

  DO gc_max_char TIMES.
    lv_idx  = sy-index.
    lv_name = |S_C{ lv_idx }[]|.
    ASSIGN (lv_name) TO FIELD-SYMBOL(<lfs_sel>).
    IF sy-subrc = 0.
      CLEAR <lfs_sel>.
    ENDIF.
    lv_name = |P_H{ lv_idx }|.
    ASSIGN (lv_name) TO FIELD-SYMBOL(<lfs_flag>).
    IF sy-subrc = 0.
      CLEAR <lfs_flag>.
    ENDIF.
  ENDDO.

ENDFORM.                    " CLEAR_CHAR_LIST

*&---------------------------------------------------------------------*
*&      Form  BUILD_CHAR_LIST
*&---------------------------------------------------------------------*
*       Thuộc tính của Batch Class đã chọn; không chọn class thì lấy hợp thuộc tính
*       của các vật tư trong phạm vi. IV_DEFAULTS: đặt lại tick hiển thị và xóa giá trị lọc.
*----------------------------------------------------------------------*
FORM build_char_list USING iv_msg      TYPE abap_bool
                           iv_defaults TYPE abap_bool.

  DATA: lt_char TYPE gtt_char,
        lt_mat  TYPE gtt_mat,
        lt_cfg  TYPE gtt_cfg,
        lv_idx  TYPE n LENGTH 2,
        lv_name TYPE string.

  CLEAR gt_char.
  gv_class_cur = p_class.

  IF p_class IS NOT INITIAL.
    SELECT c~atinn, c~atnam, c~atfor, c~atkle, c~anzdz, m~posnr AS pos, t~atbez AS label
      FROM klah AS h
      INNER JOIN ksml AS m ON m~clint = h~clint
      INNER JOIN cabn AS c ON c~atinn = m~imerk
      LEFT OUTER JOIN cabnt AS t ON t~atinn = c~atinn
                                AND t~spras = @sy-langu
                                AND t~adzhl = '0000'
      WHERE h~klart = @gv_klart
        AND h~class = @p_class
        AND m~lkenz = @space
      INTO CORRESPONDING FIELDS OF TABLE @lt_char.
  ELSE.
    PERFORM get_scope_materials CHANGING lt_mat.
    IF lt_mat IS NOT INITIAL.
      SELECT DISTINCT c~atinn, c~atnam, c~atfor, c~atkle, c~anzdz, t~atbez AS label
        FROM @lt_mat AS k
        INNER JOIN inob AS i ON i~objek = k~matnr
                            AND i~obtab = @gc_obtab_mara
                            AND i~klart = @gv_klart
        INNER JOIN kssk AS s ON s~objek = i~cuobj
                            AND s~klart = i~klart
                            AND s~mafid = 'O'
        INNER JOIN ksml AS m ON m~clint = s~clint
                            AND m~lkenz = @space
        INNER JOIN cabn AS c ON c~atinn = m~imerk
        LEFT OUTER JOIN cabnt AS t ON t~atinn = c~atinn
                                  AND t~spras = @sy-langu
                                  AND t~adzhl = '0000'
        INTO CORRESPONDING FIELDS OF TABLE @lt_char.
    ENDIF.
  ENDIF.

  SORT lt_char BY atinn.
  DELETE ADJACENT DUPLICATES FROM lt_char COMPARING atinn.

  PERFORM read_char_config CHANGING lt_cfg.
  SORT lt_cfg BY atnam ASCENDING show_alv DESCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_cfg COMPARING atnam.

* Xếp trước thuộc tính cấu hình hiển thị, rồi cấu hình không hiển thị, rồi chưa cấu hình;
* chưa có cấu hình nào thì hiển thị mặc định tất cả
  LOOP AT lt_char ASSIGNING FIELD-SYMBOL(<lfs_char>).
    READ TABLE lt_cfg ASSIGNING FIELD-SYMBOL(<lfs_cfg>)
         WITH KEY atnam = <lfs_char>-atnam BINARY SEARCH.
    IF sy-subrc = 0.
      <lfs_char>-show_def = xsdbool( <lfs_cfg>-show_alv = abap_true ).
      <lfs_char>-seqnr    = COND #( WHEN <lfs_char>-show_def = abap_true THEN 1 ELSE 2 ).
      IF <lfs_cfg>-atbez IS NOT INITIAL.
        <lfs_char>-label = <lfs_cfg>-atbez.
      ENDIF.
    ELSE.
      <lfs_char>-seqnr    = 3.
      <lfs_char>-show_def = xsdbool( lt_cfg IS INITIAL ).
    ENDIF.
  ENDLOOP.

  SORT lt_char BY seqnr pos atnam.

  DATA(lv_total) = lines( lt_char ).
  IF lv_total > gc_max_char.
    DELETE lt_char FROM gc_max_char + 1.
  ENDIF.

  LOOP AT lt_char ASSIGNING <lfs_char>.
    <lfs_char>-idx = sy-tabix.
  ENDLOOP.
  gt_char = lt_char.

  IF iv_defaults = abap_true.
    DO gc_max_char TIMES.
      lv_idx  = sy-index.
      lv_name = |S_C{ lv_idx }[]|.
      ASSIGN (lv_name) TO FIELD-SYMBOL(<lfs_sel>).
      IF sy-subrc = 0.
        CLEAR <lfs_sel>.
      ENDIF.
      lv_name = |P_H{ lv_idx }|.
      ASSIGN (lv_name) TO FIELD-SYMBOL(<lfs_flag>).
      IF sy-subrc = 0.
        READ TABLE gt_char ASSIGNING <lfs_char> WITH KEY idx = lv_idx.
        <lfs_flag> = COND abap_bool( WHEN sy-subrc = 0 THEN <lfs_char>-show_def ELSE abap_false ).
      ENDIF.
    ENDDO.
  ENDIF.

  IF lv_total > gc_max_char AND iv_msg = abap_true.
    MESSAGE w003 WITH lv_total gc_max_char.
  ENDIF.

ENDFORM.                    " BUILD_CHAR_LIST

*&---------------------------------------------------------------------*
*&      Form  READ_CHAR_CONFIG
*&---------------------------------------------------------------------*
*       Cấu hình thuộc tính lô hiển thị trên ALV (ZTWM_CHAR_PARAM) theo P_CLASS, trống = mọi class.
*----------------------------------------------------------------------*
FORM read_char_config CHANGING ct_cfg TYPE gtt_cfg.

  DATA lr_class TYPE RANGE OF klah-class.

  lr_class = COND #( WHEN p_class IS NOT INITIAL
                     THEN VALUE #( ( sign = 'I' option = 'EQ' low = p_class ) ) ).

  SELECT class, atnam, atbez, show_alv
    FROM ztwm_char_param
    WHERE class IN @lr_class
    INTO CORRESPONDING FIELDS OF TABLE @ct_cfg.

ENDFORM.                    " READ_CHAR_CONFIG

*&---------------------------------------------------------------------*
*&      Form  GET_SCOPE_MATERIALS
*&---------------------------------------------------------------------*
FORM get_scope_materials CHANGING ct_mat TYPE gtt_mat.

  SELECT DISTINCT b~matnr
    FROM nsdm_e_mchb AS b
    INNER JOIN mara AS m ON m~matnr = b~matnr
    WHERE b~werks = @p_werks
      AND b~lgort IN @s_lgort
      AND b~matnr IN @s_matnr
      AND m~mtart IN @s_mtart
      AND m~matkl IN @s_matkl
      AND b~charg IN @s_charg
    INTO TABLE @ct_mat.

ENDFORM.                    " GET_SCOPE_MATERIALS

*&---------------------------------------------------------------------*
*&      Form  PREPARE_CHAR
*&---------------------------------------------------------------------*
*       Chưa sinh khối thuộc tính (chạy trực tiếp, chạy nền) thì sinh theo class / phạm vi;
*       giữ nguyên giá trị đã lưu trong variant, chỉ đặt tick mặc định khi màn hình còn trống.
*----------------------------------------------------------------------*
FORM prepare_char .

  DATA: lv_idx   TYPE n LENGTH 2,
        lv_name  TYPE string,
        lv_clean TYPE abap_bool VALUE abap_true.

  IF gt_char IS INITIAL OR gv_class_cur <> p_class.
    DO gc_max_char TIMES.
      lv_idx  = sy-index.
      lv_name = |S_C{ lv_idx }[]|.
      ASSIGN (lv_name) TO FIELD-SYMBOL(<lfs_sel>).
      IF sy-subrc = 0 AND <lfs_sel> IS NOT INITIAL.
        lv_clean = abap_false.
      ENDIF.
      lv_name = |P_H{ lv_idx }|.
      ASSIGN (lv_name) TO FIELD-SYMBOL(<lfs_chk>).
      IF sy-subrc = 0 AND <lfs_chk> = abap_true.
        lv_clean = abap_false.
      ENDIF.
    ENDDO.
    PERFORM build_char_list USING abap_true lv_clean.
  ENDIF.

  LOOP AT gt_char ASSIGNING FIELD-SYMBOL(<lfs_char>).
    lv_name = |P_H{ <lfs_char>-idx }|.
    ASSIGN (lv_name) TO FIELD-SYMBOL(<lfs_flag>).
    CHECK sy-subrc = 0.
    <lfs_char>-show = <lfs_flag>.
  ENDLOOP.

ENDFORM.                    " PREPARE_CHAR

*&---------------------------------------------------------------------*
*&      Form  GET_CONDITIONS
*&---------------------------------------------------------------------*
*       Điều kiện thuộc tính: nhiều thuộc tính kết hợp AND, nhiều giá trị của 1 thuộc tính kết hợp OR.
*----------------------------------------------------------------------*
FORM get_conditions .

  DATA: lt_range TYPE RANGE OF atwrt,
        ls_cond  TYPE gty_cond,
        lv_lo    TYPE f,
        lv_hi    TYPE f,
        lv_cur   TYPE c LENGTH 30,
        lv_ok    TYPE abap_bool.

  FIELD-SYMBOLS <lt_sel> TYPE STANDARD TABLE.

  CLEAR gt_cond.

  LOOP AT gt_char ASSIGNING FIELD-SYMBOL(<lfs_char>).
    DATA(lv_name) = |S_C{ <lfs_char>-idx }[]|.
    ASSIGN (lv_name) TO <lt_sel>.
    CHECK sy-subrc = 0.
    lt_range = <lt_sel>.
    CHECK lt_range IS NOT INITIAL.

    CLEAR ls_cond.
    ls_cond-atinn = <lfs_char>-atinn.
    ls_cond-atnam = <lfs_char>-atnam.
    ls_cond-atfor = <lfs_char>-atfor.
    lv_cur = |S_C{ <lfs_char>-idx }-LOW|.

    LOOP AT lt_range INTO DATA(ls_rng).
      IF <lfs_char>-atfor = gc_atfor_char.
        IF <lfs_char>-atkle IS INITIAL.
          TRANSLATE: ls_rng-low  TO UPPER CASE,
                     ls_rng-high TO UPPER CASE.
        ENDIF.
        APPEND ls_rng TO ls_cond-r_char.
      ELSE.
        IF ls_rng-option = 'CP' OR ls_rng-option = 'NP'.
          SET CURSOR FIELD lv_cur.
          MESSAGE e004 WITH ls_rng-low <lfs_char>-atnam.
        ENDIF.
        PERFORM conv_value USING ls_rng-low <lfs_char>-atfor
                           CHANGING lv_lo lv_ok.
        IF lv_ok = abap_true.
          PERFORM conv_value USING ls_rng-high <lfs_char>-atfor
                             CHANGING lv_hi lv_ok.
        ENDIF.
        IF lv_ok = abap_false.
          SET CURSOR FIELD lv_cur.
          MESSAGE e004 WITH ls_rng-low <lfs_char>-atnam.
        ENDIF.
        APPEND VALUE #( sign = ls_rng-sign option = ls_rng-option low = lv_lo high = lv_hi )
               TO ls_cond-r_flv.
      ENDIF.
    ENDLOOP.

    APPEND ls_cond TO gt_cond.
  ENDLOOP.

ENDFORM.                    " GET_CONDITIONS

*&---------------------------------------------------------------------*
*&      Form  CONV_VALUE
*&---------------------------------------------------------------------*
*       Giá trị nhập (theo định dạng người dùng) sang dạng lưu trong AUSP-ATFLV:
*       số là float, ngày là YYYYMMDD dạng float.
*----------------------------------------------------------------------*
FORM conv_value USING iv_text  TYPE clike
                      iv_atfor TYPE atfor
             CHANGING cv_float TYPE f
                      cv_ok    TYPE abap_bool.

  DATA: lv_ext  TYPE c LENGTH 10,
        lv_str  TYPE c LENGTH 30,
        lv_date TYPE d,
        lv_n8   TYPE n LENGTH 8.

  CLEAR cv_float.
  cv_ok = abap_true.
  CHECK iv_text IS NOT INITIAL.

  IF iv_atfor = gc_atfor_date.
    lv_ext = iv_text.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external            = lv_ext
      IMPORTING
        date_internal            = lv_date
      EXCEPTIONS
        date_external_is_invalid = 1
        OTHERS                   = 2.
    IF sy-subrc <> 0.
      cv_ok = abap_false.
      RETURN.
    ENDIF.
    lv_n8    = lv_date.
    cv_float = lv_n8.
  ELSE.
    lv_str = iv_text.
    CALL FUNCTION 'C14W_CHAR_NUMBER_CONVERSION'
      EXPORTING
        i_string = lv_str
      IMPORTING
        e_float  = cv_float
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      cv_ok = abap_false.
    ENDIF.
  ENDIF.

ENDFORM.                    " CONV_VALUE

*&---------------------------------------------------------------------*
*&      Form  GET_BATCH_FILTER
*&---------------------------------------------------------------------*
*       Lọc thuộc tính ngay trên DB: giao dần từng điều kiện trên AUSP,
*       rồi đổi đối tượng phân loại sang khóa lô (vật tư, Plant, lô).
*----------------------------------------------------------------------*
FORM get_batch_filter .

  DATA: lt_set   TYPE SORTED TABLE OF gty_set WITH UNIQUE KEY cuobj,
        lt_new   TYPE SORTED TABLE OF gty_set WITH UNIQUE KEY cuobj,
        ls_mch1  TYPE gty_obj_mch1,
        ls_mcha  TYPE gty_obj_mcha.

  CLEAR gt_flt.
  CHECK gt_cond IS NOT INITIAL.

  LOOP AT gt_cond ASSIGNING FIELD-SYMBOL(<lfs_cond>).
    CLEAR lt_new.
    IF sy-tabix = 1.
      IF <lfs_cond>-atfor = gc_atfor_char.
        SELECT DISTINCT i~cuobj
          FROM ausp AS a
          INNER JOIN inob AS i ON i~cuobj = a~objek
          WHERE a~klart = @gv_klart
            AND a~mafid = 'O'
            AND a~atinn = @<lfs_cond>-atinn
            AND a~atwrt IN @<lfs_cond>-r_char
            AND i~klart = @gv_klart
            AND i~obtab = @gv_obtab
          INTO TABLE @lt_new.
      ELSE.
        SELECT DISTINCT i~cuobj
          FROM ausp AS a
          INNER JOIN inob AS i ON i~cuobj = a~objek
          WHERE a~klart = @gv_klart
            AND a~mafid = 'O'
            AND a~atinn = @<lfs_cond>-atinn
            AND a~atflv IN @<lfs_cond>-r_flv
            AND i~klart = @gv_klart
            AND i~obtab = @gv_obtab
          INTO TABLE @lt_new.
      ENDIF.
    ELSE.
      IF <lfs_cond>-atfor = gc_atfor_char.
        SELECT DISTINCT s~cuobj
          FROM ausp AS a
          INNER JOIN @lt_set AS s ON a~objek = s~cuobj
          WHERE a~klart = @gv_klart
            AND a~mafid = 'O'
            AND a~atinn = @<lfs_cond>-atinn
            AND a~atwrt IN @<lfs_cond>-r_char
          INTO TABLE @lt_new.
      ELSE.
        SELECT DISTINCT s~cuobj
          FROM ausp AS a
          INNER JOIN @lt_set AS s ON a~objek = s~cuobj
          WHERE a~klart = @gv_klart
            AND a~mafid = 'O'
            AND a~atinn = @<lfs_cond>-atinn
            AND a~atflv IN @<lfs_cond>-r_flv
          INTO TABLE @lt_new.
      ENDIF.
    ENDIF.
    lt_set = lt_new.
    IF lt_set IS INITIAL.
      RETURN.
    ENDIF.
  ENDLOOP.

  SELECT i~objek
    FROM inob AS i
    INNER JOIN @lt_set AS s ON s~cuobj = i~cuobj
    WHERE i~klart = @gv_klart
      AND i~obtab = @gv_obtab
    INTO TABLE @DATA(lt_obj).

  LOOP AT lt_obj ASSIGNING FIELD-SYMBOL(<lfs_obj>).
    IF gv_obtab = gc_obtab_mcha.
      ls_mcha = <lfs_obj>-objek.
      INSERT VALUE #( matnr = ls_mcha-matnr werks = ls_mcha-werks charg = ls_mcha-charg )
             INTO TABLE gt_flt.
    ELSE.
      ls_mch1 = <lfs_obj>-objek.
      INSERT VALUE #( matnr = ls_mch1-matnr werks = p_werks charg = ls_mch1-charg )
             INTO TABLE gt_flt.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " GET_BATCH_FILTER

*&---------------------------------------------------------------------*
*&      Form  GET_STOCK
*&---------------------------------------------------------------------*
*       Tồn theo lô (MCHB) và tồn không quản lý lô (MARD) trong phạm vi Plant / SLoc.
*----------------------------------------------------------------------*
FORM get_stock .

  DATA: lr_zustd TYPE RANGE OF dzustd,
        lr_vfdat TYPE RANGE OF vfdat,
        lv_min_u TYPE labst,
        lv_min_q TYPE insme,
        lv_min_b TYPE speme.

  CLEAR gt_stock.

* Có điều kiện thuộc tính mà không lô nào thỏa thì không còn gì để lấy
  IF gt_cond IS NOT INITIAL AND gt_flt IS INITIAL.
    RETURN.
  ENDIF.

  IF p_incl = abap_false.
    lr_zustd = VALUE #( ( sign = 'I' option = 'EQ' low = space ) ).
    lr_vfdat = VALUE #( ( sign = 'I' option = 'EQ' low = '00000000' )
                        ( sign = 'I' option = 'GE' low = p_date ) ).
  ENDIF.

* Chỉ lấy lô còn tồn theo các loại tồn được tick; loại không tick không tham gia
  lv_min_u = COND #( WHEN p_only = abap_false THEN -1
                     WHEN p_unr  = abap_true  THEN 0
                     ELSE gc_qty_none ).
  lv_min_q = COND #( WHEN p_only = abap_false THEN -1
                     WHEN p_qi   = abap_true  THEN 0
                     ELSE gc_qty_none ).
  lv_min_b = COND #( WHEN p_only = abap_false THEN -1
                     WHEN p_blk  = abap_true  THEN 0
                     ELSE gc_qty_none ).

  IF gt_cond IS INITIAL.
    SELECT b~matnr, b~werks, b~lgort, b~charg,
           b~clabs, b~cinsm, b~cspem,
           a~vfdat, a~hsdat, a~qndat, a~licha, a~zustd,
           m~meins, m~begru, t~maktx
      FROM nsdm_e_mchb AS b
      INNER JOIN mcha AS a ON a~matnr = b~matnr
                          AND a~werks = b~werks
                          AND a~charg = b~charg
      INNER JOIN mara AS m ON m~matnr = b~matnr
      LEFT OUTER JOIN makt AS t ON t~matnr = b~matnr
                               AND t~spras = @sy-langu
      WHERE b~werks = @p_werks
        AND b~lgort IN @s_lgort
        AND b~matnr IN @s_matnr
        AND b~charg IN @s_charg
        AND m~mtart IN @s_mtart
        AND m~matkl IN @s_matkl
        AND b~lvorm = @space
        AND a~lvorm = @space
        AND a~zustd IN @lr_zustd
        AND a~vfdat IN @lr_vfdat
        AND ( b~clabs > @lv_min_u OR b~cinsm > @lv_min_q OR b~cspem > @lv_min_b )
      INTO CORRESPONDING FIELDS OF TABLE @gt_stock.
  ELSE.
    SELECT b~matnr, b~werks, b~lgort, b~charg,
           b~clabs, b~cinsm, b~cspem,
           a~vfdat, a~hsdat, a~qndat, a~licha, a~zustd,
           m~meins, m~begru, t~maktx
      FROM nsdm_e_mchb AS b
      INNER JOIN @gt_flt AS f ON f~matnr = b~matnr
                             AND f~werks = b~werks
                             AND f~charg = b~charg
      INNER JOIN mcha AS a ON a~matnr = b~matnr
                          AND a~werks = b~werks
                          AND a~charg = b~charg
      INNER JOIN mara AS m ON m~matnr = b~matnr
      LEFT OUTER JOIN makt AS t ON t~matnr = b~matnr
                               AND t~spras = @sy-langu
      WHERE b~werks = @p_werks
        AND b~lgort IN @s_lgort
        AND b~matnr IN @s_matnr
        AND b~charg IN @s_charg
        AND m~mtart IN @s_mtart
        AND m~matkl IN @s_matkl
        AND b~lvorm = @space
        AND a~lvorm = @space
        AND a~zustd IN @lr_zustd
        AND a~vfdat IN @lr_vfdat
        AND ( b~clabs > @lv_min_u OR b~cinsm > @lv_min_q OR b~cspem > @lv_min_b )
      INTO CORRESPONDING FIELDS OF TABLE @gt_stock.
  ENDIF.

* Vật tư không quản lý lô: chỉ hiển thị khi không có điều kiện thuộc tính và không lọc theo lô
  IF gt_cond IS INITIAL AND s_charg[] IS INITIAL.
    SELECT d~matnr, d~werks, d~lgort,
           d~labst AS clabs, d~insme AS cinsm, d~speme AS cspem,
           m~meins, m~begru, t~maktx
      FROM nsdm_e_mard AS d
      INNER JOIN mara AS m ON m~matnr = d~matnr
      INNER JOIN marc AS c ON c~matnr = d~matnr
                          AND c~werks = d~werks
      LEFT OUTER JOIN makt AS t ON t~matnr = d~matnr
                               AND t~spras = @sy-langu
      WHERE d~werks = @p_werks
        AND d~lgort IN @s_lgort
        AND d~matnr IN @s_matnr
        AND m~mtart IN @s_mtart
        AND m~matkl IN @s_matkl
        AND m~xchpf = @space
        AND c~xchpf = @space
        AND d~lvorm = @space
        AND ( d~labst > @lv_min_u OR d~insme > @lv_min_q OR d~speme > @lv_min_b )
      APPENDING CORRESPONDING FIELDS OF TABLE @gt_stock.
  ELSEIF gt_cond IS NOT INITIAL.
    SELECT DISTINCT d~matnr
      FROM nsdm_e_mard AS d
      INNER JOIN mara AS m ON m~matnr = d~matnr
      INNER JOIN marc AS c ON c~matnr = d~matnr
                          AND c~werks = d~werks
      WHERE d~werks = @p_werks
        AND d~lgort IN @s_lgort
        AND d~matnr IN @s_matnr
        AND m~mtart IN @s_mtart
        AND m~matkl IN @s_matkl
        AND m~xchpf = @space
        AND c~xchpf = @space
        AND d~lvorm = @space
      INTO TABLE @DATA(lt_nobatch)
      UP TO @gc_max_msg ROWS.
    LOOP AT lt_nobatch ASSIGNING FIELD-SYMBOL(<lfs_nb>).
      DATA(lv_matnr_txt) = |{ <lfs_nb>-matnr ALPHA = OUT }|.
      PERFORM add_msg USING 'W' '006' lv_matnr_txt space.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " GET_STOCK

*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITY
*&---------------------------------------------------------------------*
*       Loại các dòng thuộc SLoc, nhóm quyền vật tư mà người dùng không có quyền đọc.
*----------------------------------------------------------------------*
FORM check_authority .

  TYPES: BEGIN OF lty_lgort,
           lgort TYPE lgort_d,
         END OF lty_lgort,
         BEGIN OF lty_begru,
           begru TYPE begru,
         END OF lty_begru.

  DATA: lt_lgort  TYPE SORTED TABLE OF lty_lgort WITH UNIQUE KEY lgort,
        lt_begru  TYPE SORTED TABLE OF lty_begru WITH UNIQUE KEY begru,
        lv_lgort  TYPE lgort_d,
        lv_before TYPE i.

  lv_before = lines( gt_stock ).

  LOOP AT gt_stock ASSIGNING FIELD-SYMBOL(<lfs_stock>).
    INSERT VALUE #( lgort = <lfs_stock>-lgort ) INTO TABLE lt_lgort.
    IF <lfs_stock>-begru IS NOT INITIAL.
      INSERT VALUE #( begru = <lfs_stock>-begru ) INTO TABLE lt_begru.
    ENDIF.
  ENDLOOP.

  LOOP AT lt_lgort INTO DATA(ls_lgort).
    AUTHORITY-CHECK OBJECT 'M_MSEG_LGO'
      ID 'ACTVT' FIELD '03'
      ID 'WERKS' FIELD p_werks
      ID 'LGORT' FIELD ls_lgort-lgort
      ID 'BWART' DUMMY.
    CHECK sy-subrc <> 0.
    IF lv_lgort IS INITIAL.
      lv_lgort = ls_lgort-lgort.
    ENDIF.
    DELETE gt_stock WHERE lgort = ls_lgort-lgort.
  ENDLOOP.

  LOOP AT lt_begru INTO DATA(ls_begru).
    AUTHORITY-CHECK OBJECT 'M_MATE_MAR'
      ID 'ACTVT' FIELD '03'
      ID 'BEGRU' FIELD ls_begru-begru.
    IF sy-subrc = 0.
      AUTHORITY-CHECK OBJECT 'M_MATE_CHG'
        ID 'ACTVT' FIELD '03'
        ID 'BEGRU' FIELD ls_begru-begru.
    ENDIF.
    CHECK sy-subrc <> 0.
    DELETE gt_stock WHERE begru = ls_begru-begru.
  ENDLOOP.

  IF gt_stock IS INITIAL.
    MESSAGE s001 WITH p_werks lv_lgort DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  DATA(lv_removed) = lv_before - lines( gt_stock ).
  IF lv_removed > 0.
    PERFORM add_msg USING 'W' '009' lv_removed p_werks.
  ENDIF.

ENDFORM.                    " CHECK_AUTHORITY

*&---------------------------------------------------------------------*
*&      Form  GET_OBJEK
*&---------------------------------------------------------------------*
*       Khóa đối tượng phân loại của lô (INOB-OBJEK).
*----------------------------------------------------------------------*
FORM get_objek USING iv_matnr TYPE matnr
                     iv_werks TYPE werks_d
                     iv_charg TYPE charg_d
            CHANGING cv_objek TYPE inob-objek.

  DATA: ls_mch1 TYPE gty_obj_mch1,
        ls_mcha TYPE gty_obj_mcha.

  CLEAR cv_objek.

  IF gv_obtab = gc_obtab_mcha.
    ls_mcha = VALUE #( matnr = iv_matnr werks = iv_werks charg = iv_charg ).
    cv_objek = ls_mcha.
  ELSE.
    ls_mch1 = VALUE #( matnr = iv_matnr charg = iv_charg ).
    cv_objek = ls_mch1.
  ENDIF.

ENDFORM.                    " GET_OBJEK

*&---------------------------------------------------------------------*
*&      Form  GET_CHAR_VALUES
*&---------------------------------------------------------------------*
*       Giá trị thuộc tính của các lô trong kết quả: thuộc tính tick hiển thị và Lô NSX.
*----------------------------------------------------------------------*
FORM get_char_values .

  DATA: lt_key   TYPE SORTED TABLE OF gty_key WITH UNIQUE KEY objek,
        lr_atnam TYPE RANGE OF atnam,
        lv_objek TYPE inob-objek,
        lv_txt   TYPE atwrt.

  CLEAR: gt_inob, gt_valtxt.

  lr_atnam = VALUE #( ( sign = 'I' option = 'EQ' low = gc_at_lonsx ) ).
  LOOP AT gt_char ASSIGNING FIELD-SYMBOL(<lfs_char>) WHERE show = abap_true.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_char>-atnam ) TO lr_atnam.
  ENDLOOP.

  LOOP AT gt_stock ASSIGNING FIELD-SYMBOL(<lfs_stock>) WHERE charg IS NOT INITIAL.
    PERFORM get_objek USING <lfs_stock>-matnr <lfs_stock>-werks <lfs_stock>-charg
                      CHANGING lv_objek.
    INSERT VALUE #( objek = lv_objek ) INTO TABLE lt_key.
  ENDLOOP.
  CHECK lt_key IS NOT INITIAL.

  SELECT i~objek, i~cuobj
    FROM inob AS i
    INNER JOIN @lt_key AS k ON k~objek = i~objek
    WHERE i~klart = @gv_klart
      AND i~obtab = @gv_obtab
    INTO TABLE @gt_inob.
  CHECK gt_inob IS NOT INITIAL.

  DATA(lt_cuobj) = VALUE gtt_set90( FOR ls_inob IN gt_inob ( objek = ls_inob-cuobj ) ).

  SELECT a~objek, c~atnam, c~atfor, c~anzdz, a~atwrt, a~atflv
    FROM ausp AS a
    INNER JOIN cabn AS c ON c~atinn = a~atinn
    INNER JOIN @lt_cuobj AS k ON k~objek = a~objek
    WHERE a~klart = @gv_klart
      AND a~mafid = 'O'
      AND c~atnam IN @lr_atnam
    INTO TABLE @DATA(lt_val).

* Thuộc tính nhiều giá trị: nối bằng dấu phẩy
  LOOP AT lt_val ASSIGNING FIELD-SYMBOL(<lfs_val>).
    PERFORM fmt_value USING <lfs_val> CHANGING lv_txt.
    READ TABLE gt_valtxt ASSIGNING FIELD-SYMBOL(<lfs_vt>)
         WITH TABLE KEY objek = <lfs_val>-objek atnam = <lfs_val>-atnam.
    IF sy-subrc = 0.
      <lfs_vt>-txt = |{ <lfs_vt>-txt }, { lv_txt }|.
    ELSE.
      INSERT VALUE #( objek = <lfs_val>-objek atnam = <lfs_val>-atnam txt = lv_txt )
             INTO TABLE gt_valtxt.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " GET_CHAR_VALUES

*&---------------------------------------------------------------------*
*&      Form  FMT_VALUE
*&---------------------------------------------------------------------*
FORM fmt_value USING is_val TYPE gty_val
            CHANGING cv_txt TYPE atwrt.

  DATA: lv_int  TYPE i,
        lv_n8   TYPE n LENGTH 8,
        lv_date TYPE d,
        lv_dec  TYPE i.

  CLEAR cv_txt.

  CASE is_val-atfor.
    WHEN gc_atfor_char.
      cv_txt = is_val-atwrt.
    WHEN gc_atfor_date.
      lv_int  = is_val-atflv.
      lv_n8   = lv_int.
      lv_date = lv_n8.
      IF lv_date IS NOT INITIAL.
        cv_txt = |{ lv_date DATE = USER }|.
      ENDIF.
    WHEN OTHERS.
      lv_dec = is_val-anzdz.
      WRITE is_val-atflv TO cv_txt DECIMALS lv_dec LEFT-JUSTIFIED.
  ENDCASE.

ENDFORM.                    " FMT_VALUE

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_DATA
*&---------------------------------------------------------------------*
FORM build_alv_data .

  DATA: ls_alv   TYPE gty_alv,
        lv_objek TYPE inob-objek,
        lv_cuobj TYPE ausp-objek,
        lv_nsx   TYPE atwrt,
        lv_comp  TYPE string,
        lv_date_txt TYPE string,
        lv_n007  TYPE i,
        lv_n008  TYPE i.

  FIELD-SYMBOLS: <lfs_ch>   TYPE atwrt,
                 <lfs_inob> TYPE gty_inob,
                 <lfs_vt>   TYPE gty_valtxt,
                 <lfs_char> TYPE gty_char.

  LOOP AT gt_stock ASSIGNING FIELD-SYMBOL(<lfs_stock>).
    CLEAR: ls_alv, lv_nsx.
    MOVE-CORRESPONDING <lfs_stock> TO ls_alv.

    IF p_unr = abap_true.
      ls_alv-total = ls_alv-total + <lfs_stock>-clabs.
    ELSE.
      CLEAR ls_alv-clabs.
    ENDIF.
    IF p_qi = abap_true.
      ls_alv-total = ls_alv-total + <lfs_stock>-cinsm.
    ELSE.
      CLEAR ls_alv-cinsm.
    ENDIF.
    IF p_blk = abap_true.
      ls_alv-total = ls_alv-total + <lfs_stock>-cspem.
    ELSE.
      CLEAR ls_alv-cspem.
    ENDIF.

    IF p_meinh IS NOT INITIAL.
      PERFORM convert_qty USING <lfs_stock>-matnr <lfs_stock>-meins ls_alv-total
                          CHANGING ls_alv-qtycv ls_alv-meinhcv.
    ENDIF.

    IF <lfs_stock>-charg IS NOT INITIAL.
      PERFORM get_objek USING <lfs_stock>-matnr <lfs_stock>-werks <lfs_stock>-charg
                        CHANGING lv_objek.
      READ TABLE gt_inob ASSIGNING <lfs_inob> WITH TABLE KEY objek = lv_objek.
      IF sy-subrc = 0.
        lv_cuobj = <lfs_inob>-cuobj.
        READ TABLE gt_valtxt ASSIGNING <lfs_vt>
             WITH TABLE KEY objek = lv_cuobj atnam = gc_at_lonsx.
        IF sy-subrc = 0.
          lv_nsx = <lfs_vt>-txt.
        ENDIF.
        LOOP AT gt_char ASSIGNING <lfs_char> WHERE show = abap_true.
          READ TABLE gt_valtxt ASSIGNING <lfs_vt>
               WITH TABLE KEY objek = lv_cuobj atnam = <lfs_char>-atnam.
          CHECK sy-subrc = 0.
          lv_comp = |CH{ <lfs_char>-idx }|.
          ASSIGN COMPONENT lv_comp OF STRUCTURE ls_alv TO <lfs_ch>.
          CHECK sy-subrc = 0.
          <lfs_ch> = <lfs_vt>-txt.
          <lfs_char>-has_val = abap_true.
        ENDLOOP.
      ENDIF.
* Lô NSX: thuộc tính Z_BATCH_NSX, rồi số lô nhà sản xuất của lô, rồi số lô SAP
      ls_alv-lonsx = COND #( WHEN lv_nsx IS NOT INITIAL THEN lv_nsx
                             WHEN <lfs_stock>-licha IS NOT INITIAL THEN <lfs_stock>-licha
                             ELSE <lfs_stock>-charg ).
    ENDIF.

    DATA(lv_expired) = xsdbool( ls_alv-vfdat IS NOT INITIAL AND ls_alv-vfdat < p_date ).
    IF ls_alv-vfdat IS NOT INITIAL.
      ls_alv-hsdcl = ls_alv-vfdat - p_date.
    ENDIF.

    ls_alv-status = COND #( WHEN lv_expired = abap_true AND <lfs_stock>-zustd IS NOT INITIAL
                            THEN 'Hết hạn; Hạn chế sử dụng'
                            WHEN lv_expired = abap_true
                            THEN 'Hết hạn'
                            WHEN <lfs_stock>-zustd IS NOT INITIAL
                            THEN 'Hạn chế sử dụng' ).

    IF lv_expired = abap_true AND lv_n007 < gc_max_msg.
      lv_n007 = lv_n007 + 1.
      lv_date_txt = |{ ls_alv-vfdat DATE = USER }|.
      PERFORM add_msg USING 'W' '007' <lfs_stock>-charg lv_date_txt.
    ENDIF.
    IF <lfs_stock>-zustd IS NOT INITIAL AND lv_n008 < gc_max_msg.
      lv_n008 = lv_n008 + 1.
      PERFORM add_msg USING 'W' '008' <lfs_stock>-charg space.
    ENDIF.

    IF ls_alv-hsdcl < 0 AND ls_alv-vfdat IS NOT INITIAL.
      ls_alv-colr = VALUE #( ( fname = 'HSDCL'  color = VALUE #( col = 6 int = 1 inv = 0 ) )
                             ( fname = 'VFDAT'  color = VALUE #( col = 6 int = 1 inv = 0 ) )
                             ( fname = 'STATUS' color = VALUE #( col = 6 int = 1 inv = 0 ) ) ).
    ENDIF.

    APPEND ls_alv TO gt_alv.
  ENDLOOP.

  SORT gt_alv BY matnr vfdat lgort charg.

ENDFORM.                    " BUILD_ALV_DATA

*&---------------------------------------------------------------------*
*&      Form  CONVERT_QTY
*&---------------------------------------------------------------------*
*       Quy đổi theo MARM bằng FM chuẩn; vật tư chưa khai báo quy đổi thì để trống.
*----------------------------------------------------------------------*
FORM convert_qty USING iv_matnr TYPE matnr
                       iv_meins TYPE meins
                       iv_qty   TYPE menge_d
              CHANGING cv_qty   TYPE menge_d
                       cv_meinh TYPE meins.

  DATA: lv_in      TYPE ekpo-menge,
        lv_out     TYPE ekpo-menge,
        lv_mat_txt TYPE string.

  CLEAR: cv_qty, cv_meinh.

  CHECK NOT line_exists( gt_noconv[ table_line = iv_matnr ] ).

  IF iv_meins = p_meinh.
    cv_qty = iv_qty.
  ELSE.
    lv_in = iv_qty.
    CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
      EXPORTING
        i_matnr              = iv_matnr
        i_in_me              = iv_meins
        i_out_me             = p_meinh
        i_menge              = lv_in
      IMPORTING
        e_menge              = lv_out
      EXCEPTIONS
        error_in_application = 1
        error                = 2
        OTHERS               = 3.
    IF sy-subrc <> 0.
      INSERT iv_matnr INTO TABLE gt_noconv.
      IF lines( gt_noconv ) <= gc_max_msg.
        lv_mat_txt = |{ iv_matnr ALPHA = OUT }|.
        PERFORM add_msg USING 'W' '005' lv_mat_txt gv_meinh_ext.
      ENDIF.
      RETURN.
    ENDIF.
    cv_qty = round( val = lv_out dec = gv_andec ).
  ENDIF.

  cv_meinh = p_meinh.

ENDFORM.                    " CONVERT_QTY

*&---------------------------------------------------------------------*
*&      Form  ADD_MSG
*&---------------------------------------------------------------------*
FORM add_msg USING iv_type TYPE c
                   iv_no   TYPE c
                   iv_v1   TYPE any
                   iv_v2   TYPE any.

  DATA: lv_v1 TYPE symsgv,
        lv_v2 TYPE symsgv,
        lv_ty TYPE symsgty,
        lv_no TYPE symsgno.

  IF gv_msg_init = abap_false.
    CALL FUNCTION 'MESSAGES_INITIALIZE'
      EXCEPTIONS
        OTHERS = 1.
    gv_msg_init = abap_true.
  ENDIF.

  lv_ty = iv_type.
  lv_no = iv_no.
  lv_v1 = iv_v1.
  lv_v2 = iv_v2.
  CONDENSE: lv_v1, lv_v2.

  CALL FUNCTION 'MESSAGE_STORE'
    EXPORTING
      arbgb                   = gc_msgid
      exception_if_not_active = space
      msgty                   = lv_ty
      msgv1                   = lv_v1
      msgv2                   = lv_v2
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

  DATA(lt_text) = VALUE gtt_coltxt( ( fname = 'WERKS'   text = 'Plant' )
                                    ( fname = 'LGORT'   text = 'SLoc' )
                                    ( fname = 'MATNR'   text = 'Vật tư' )
                                    ( fname = 'MAKTX'   text = 'Mô tả vật tư' )
                                    ( fname = 'CHARG'   text = 'Lô SAP' )
                                    ( fname = 'LONSX'   text = 'Lô NSX' )
                                    ( fname = 'MEINS'   text = 'ĐVT cơ sở' )
                                    ( fname = 'CLABS'   text = 'Unrestricted' )
                                    ( fname = 'CINSM'   text = 'QI' )
                                    ( fname = 'CSPEM'   text = 'Blocked' )
                                    ( fname = 'TOTAL'   text = 'Tổng tồn' )
                                    ( fname = 'QTYCV'   text = 'SL theo ĐVT chọn' )
                                    ( fname = 'MEINHCV' text = 'ĐVT chọn' )
                                    ( fname = 'HSDAT'   text = 'Ngày SX' )
                                    ( fname = 'VFDAT'   text = 'HSD' )
                                    ( fname = 'QNDAT'   text = 'Retest' )
                                    ( fname = 'HSDCL'   text = 'HSD còn lại (ngày)' )
                                    ( fname = 'STATUS'  text = 'Trạng thái' ) ).

  TRY.
      lo_columns->set_color_column( 'COLR' ).

      LOOP AT lt_text ASSIGNING FIELD-SYMBOL(<lfs_text>).
        lo_column ?= lo_columns->get_column( <lfs_text>-fname ).
        PERFORM set_col_text USING lo_column <lfs_text>-text.
      ENDLOOP.

* Cột số lượng gắn ĐVT để tổng chỉ cộng các dòng cùng đơn vị
      lo_columns->get_column( 'CLABS' )->set_quantity_column( 'MEINS' ).
      lo_columns->get_column( 'CINSM' )->set_quantity_column( 'MEINS' ).
      lo_columns->get_column( 'CSPEM' )->set_quantity_column( 'MEINS' ).
      lo_columns->get_column( 'TOTAL' )->set_quantity_column( 'MEINS' ).
      lo_columns->get_column( 'QTYCV' )->set_quantity_column( 'MEINHCV' ).
      lo_columns->get_column( 'QTYCV' )->set_zero( abap_false ).
      lo_columns->get_column( 'HSDCL' )->set_zero( abap_false ).

      IF p_unr = abap_false.
        lo_columns->get_column( 'CLABS' )->set_visible( abap_false ).
      ENDIF.
      IF p_qi = abap_false.
        lo_columns->get_column( 'CINSM' )->set_visible( abap_false ).
      ENDIF.
      IF p_blk = abap_false.
        lo_columns->get_column( 'CSPEM' )->set_visible( abap_false ).
      ENDIF.
      IF p_meinh IS INITIAL.
        lo_columns->get_column( 'QTYCV' )->set_visible( abap_false ).
        lo_columns->get_column( 'MEINHCV' )->set_visible( abap_false ).
      ENDIF.

* Cột thuộc tính động nằm ngay sau cột STATUS: nhãn theo cấu hình, ẩn cột không tick hoặc không có giá trị ở mọi dòng
      DATA(lt_cols) = lo_columns->get( ).
      READ TABLE lt_cols TRANSPORTING NO FIELDS WITH KEY columnname = 'STATUS'.
      DATA(lv_base) = sy-tabix.

      DO gc_max_char TIMES.
        DATA(lv_i) = sy-index.
        READ TABLE lt_cols INTO DATA(ls_col) INDEX lv_base + lv_i.
        CHECK sy-subrc = 0.
        lo_column ?= ls_col-r_column.
        READ TABLE gt_char ASSIGNING FIELD-SYMBOL(<lfs_char>) INDEX lv_i.
        IF sy-subrc <> 0 OR <lfs_char>-show = abap_false OR <lfs_char>-has_val = abap_false.
          lo_column->set_visible( abap_false ).
          CONTINUE.
        ENDIF.
        DATA(lv_label) = COND string( WHEN <lfs_char>-label IS NOT INITIAL
                                      THEN <lfs_char>-label
                                      ELSE <lfs_char>-atnam ).
        PERFORM set_col_text USING lo_column lv_label.
      ENDDO.
    CATCH cx_salv_not_found cx_salv_data_error INTO DATA(lx_col).
      MESSAGE lx_col TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

  DATA(lo_layout) = go_alv->get_layout( ).
  lo_layout->set_key( VALUE #( report = sy-repid ) ).
  lo_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
  IF p_layo IS NOT INITIAL.
    lo_layout->set_initial_layout( p_layo ).
  ENDIF.

  go_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).

  lv_head = |Plant { p_werks }|.
  IF p_class IS NOT INITIAL.
    lv_head = |{ lv_head } \| Batch Class { p_class }|.
  ENDIF.
  IF p_meinh IS NOT INITIAL.
    lv_head = |{ lv_head } \| ĐVT quy đổi { gv_meinh_ext }|.
  ENDIF.
  lv_head = |{ lv_head } \| Ngày tham chiếu { p_date DATE = USER }|.

  CREATE OBJECT lo_grid.
  lo_grid->create_label( row = 1 column = 1
                         text = 'ZWM11 – Tồn kho theo thuộc tính lô' ).
  lo_grid->create_text( row = 2 column = 1 text = lv_head ).
  go_alv->set_top_of_list( lo_grid ).

  DATA(lo_events) = go_alv->get_event( ).
  SET HANDLER lcl_handler=>on_function FOR lo_events.
  SET HANDLER lcl_handler=>on_double_click FOR lo_events.

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
*&      Form  SHOW_SELECTED_BATCH
*&---------------------------------------------------------------------*
*       Nút Chi tiết lô: dòng đang chọn, không chọn thì dòng của ô đang đứng.
*----------------------------------------------------------------------*
FORM show_selected_batch .

  DATA lv_row TYPE i.

  DATA(lo_sel)  = go_alv->get_selections( ).
  DATA(lt_rows) = lo_sel->get_selected_rows( ).
  READ TABLE lt_rows INTO lv_row INDEX 1.

  IF lv_row = 0.
    lv_row = lo_sel->get_current_cell( )-row.
  ENDIF.

  READ TABLE gt_alv ASSIGNING FIELD-SYMBOL(<lfs_alv>) INDEX lv_row.
  IF sy-subrc <> 0.
    MESSAGE s010 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM open_batch USING <lfs_alv>-matnr <lfs_alv>-werks <lfs_alv>-charg.

ENDFORM.                    " SHOW_SELECTED_BATCH

*&---------------------------------------------------------------------*
*&      Form  OPEN_BATCH
*&---------------------------------------------------------------------*
FORM open_batch USING iv_matnr TYPE matnr
                      iv_werks TYPE werks_d
                      iv_charg TYPE charg_d.

  CHECK iv_charg IS NOT INITIAL.

  SET PARAMETER ID 'MAT' FIELD iv_matnr.
  SET PARAMETER ID 'CHA' FIELD iv_charg.
  SET PARAMETER ID 'WRK' FIELD iv_werks.
  CALL TRANSACTION 'MSC3N' WITH AUTHORITY-CHECK AND SKIP FIRST SCREEN.

ENDFORM.                    " OPEN_BATCH

*&---------------------------------------------------------------------*
*&      Form  OPEN_MATERIAL
*&---------------------------------------------------------------------*
FORM open_material USING iv_matnr TYPE matnr.

  SET PARAMETER ID 'MAT' FIELD iv_matnr.
  CALL TRANSACTION 'MM03' WITH AUTHORITY-CHECK AND SKIP FIRST SCREEN.

ENDFORM.                    " OPEN_MATERIAL

*&---------------------------------------------------------------------*
*&      Form  F4_CLASS
*&---------------------------------------------------------------------*
FORM f4_class CHANGING cv_class TYPE klah-class.

  DATA lt_ret TYPE STANDARD TABLE OF ddshretval.

  SELECT h~class, s~kschl
    FROM klah AS h
    LEFT OUTER JOIN swor AS s ON s~clint = h~clint
                             AND s~spras = @sy-langu
    WHERE h~klart = @gv_klart
    ORDER BY h~class
    INTO TABLE @DATA(lt_class).
  DELETE ADJACENT DUPLICATES FROM lt_class COMPARING class.
  CHECK lt_class IS NOT INITIAL.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'CLASS'
      value_org   = 'S'
    TABLES
      value_tab   = lt_class
      return_tab  = lt_ret
    EXCEPTIONS
      OTHERS      = 1.
  CHECK sy-subrc = 0.

  READ TABLE lt_ret ASSIGNING FIELD-SYMBOL(<lfs_ret>) INDEX 1.
  IF sy-subrc = 0.
    cv_class = <lfs_ret>-fieldval.
  ENDIF.

ENDFORM.                    " F4_CLASS

*&---------------------------------------------------------------------*
*&      Form  F4_CHAR_VALUE
*&---------------------------------------------------------------------*
*       Giá trị cho phép của thuộc tính kiểu ký tự (CAWN).
*----------------------------------------------------------------------*
FORM f4_char_value USING iv_idx   TYPE clike
                CHANGING cv_value TYPE atwrt.

  DATA: lv_idx TYPE n LENGTH 2,
        lt_ret TYPE STANDARD TABLE OF ddshretval.

  lv_idx = iv_idx.

  READ TABLE gt_char ASSIGNING FIELD-SYMBOL(<lfs_char>) WITH KEY idx = lv_idx.
  CHECK sy-subrc = 0 AND <lfs_char>-atfor = gc_atfor_char.

  SELECT w~atwrt, t~atwtb
    FROM cawn AS w
    LEFT OUTER JOIN cawnt AS t ON t~atinn = w~atinn
                              AND t~atzhl = w~atzhl
                              AND t~adzhl = w~adzhl
                              AND t~spras = @sy-langu
    WHERE w~atinn = @<lfs_char>-atinn
    INTO TABLE @DATA(lt_val).
  CHECK lt_val IS NOT INITIAL.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'ATWRT'
      value_org   = 'S'
    TABLES
      value_tab   = lt_val
      return_tab  = lt_ret
    EXCEPTIONS
      OTHERS      = 1.
  CHECK sy-subrc = 0.

  READ TABLE lt_ret ASSIGNING FIELD-SYMBOL(<lfs_ret>) INDEX 1.
  IF sy-subrc = 0.
    cv_value = <lfs_ret>-fieldval.
  ENDIF.

ENDFORM.                    " F4_CHAR_VALUE

*&---------------------------------------------------------------------*
*&      Form  F4_LAYOUT
*&---------------------------------------------------------------------*
FORM f4_layout CHANGING cv_layo TYPE slis_vari.

  DATA(ls_layout) = cl_salv_layout_service=>f4_layouts(
                      s_key    = VALUE #( report = sy-repid )
                      restrict = if_salv_c_layout=>restrict_none ).
  cv_layo = ls_layout-layout.

ENDFORM.                    " F4_LAYOUT
