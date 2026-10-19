*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_BBKNHH_F01
*&---------------------------------------------------------------------*

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
    READ TABLE gt_alv ASSIGNING FIELD-SYMBOL(<lf_alv>) INDEX row.
    CHECK sy-subrc = 0.
    <lf_alv>-sel = xsdbool( <lf_alv>-sel = abap_false ).
    go_alv->refresh( ).
  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*&      Form  CHECK_CONDITION
*&---------------------------------------------------------------------*
FORM check_condition .

  CHECK sy-ucomm = 'ONLI' OR sy-ucomm = 'PRIN' OR sy-ucomm = 'SJOB'
     OR sy-batch = abap_true.

  IF p_src_a = abap_true.
    IF s_vbeln[] IS INITIAL AND s_lfdat[] IS INITIAL.
      MESSAGE e002.
    ENDIF.
  ELSE.
    IF s_mblnr[] IS INITIAL AND s_budat[] IS INITIAL.
      MESSAGE e002.
    ENDIF.
    IF s_mblnr[] IS NOT INITIAL AND p_mjahr IS INITIAL.
      SET CURSOR FIELD 'P_MJAHR'.
      MESSAGE e002.
    ENDIF.
  ENDIF.

ENDFORM.                    " CHECK_CONDITION

*&---------------------------------------------------------------------*
*&      Form  GET_PARAMETER
*&---------------------------------------------------------------------*
*       Danh mục loại Delivery đọc từ STVARV.
*       Nhãn cố định của biểu mẫu.
*----------------------------------------------------------------------*
FORM get_parameter .

  SELECT name, sign, opti, low, high
    FROM tvarvc
    WHERE name = @gc_tvarv_lfart
      AND type = 'S'
      AND low <> @space
    INTO TABLE @DATA(lt_tvarv).

  CLEAR gr_lfart.
  LOOP AT lt_tvarv INTO DATA(ls_tvarv).
    APPEND VALUE #( sign = ls_tvarv-sign option = ls_tvarv-opti
                    low  = ls_tvarv-low  high   = ls_tvarv-high ) TO gr_lfart.
  ENDLOOP.

  CLEAR gs_parameter.

  IF p_vacsp = abap_true.
    gs_parameter-title_report = 'BIÊN BẢN KIỂM NHẬN VACXIN, SINH PHẨM'.
  ELSEIF p_thugn = abap_true.
    gs_parameter-title_report =
      'BIÊN BẢN KIỂM NHẬN THUỐC GÂY NGHIỆN, THUỐC HƯỚNG THẦN, TIỀN CHẤT DÙNG LÀM THUỐC'.
    gs_parameter-footer06 = 'Lái xe'.
  ELSE.
    gs_parameter-title_report = 'BIÊN BẢN KIỂM NHẬN HÀNG HÓA'.
  ENDIF.

  gs_parameter-logo        = gc_logo.
  gs_parameter-parameter01 = 'Ngày kiểm nhận:'.
  gs_parameter-parameter02 = 'Thủ kho:'.
  gs_parameter-parameter03 = 'Người kiểm nhận:'.
  gs_parameter-parameter04 = 'Nhập tại kho:'.
  gs_parameter-parameter05 = 'Người giao hàng:'.
  gs_parameter-parameter06 = 'Số xe vận chuyển:'.
  gs_parameter-parameter07 = 'Giấy phép NK/quota:'.

  gs_parameter-parameter11 = 'STT'.
  gs_parameter-parameter12 = 'Tên hàng'.
  gs_parameter-parameter13 = 'SĐK'.
  gs_parameter-parameter14 = 'NSX - Nước SX'.
  gs_parameter-parameter15 = 'Số lô NSX'.
  gs_parameter-parameter16 = 'Số lô SAP'.
  gs_parameter-parameter17 = 'Ngày SX'.
  gs_parameter-parameter18 = COND #( WHEN p_vacsp = abap_true THEN 'Hạn dùng'
                                     ELSE 'Hạn dùng / Ngày KNL' ).
  gs_parameter-parameter19 = 'Quy cách'.
  gs_parameter-parameter20 = 'ĐVT'.
  gs_parameter-parameter21 = 'SL hóa đơn'.
  gs_parameter-parameter22 = 'SL thực tế'.
  gs_parameter-parameter23 = 'Hồ sơ đi kèm'.
  gs_parameter-parameter24 = 'Tình trạng niêm phong'.
  gs_parameter-parameter25 = 'Ghi chú'.

  gs_parameter-footer01 = 'Ngày ….. tháng ….. năm ……..'.
  gs_parameter-footer02 = 'Người giao hàng'.
  gs_parameter-footer03 = 'Người kiểm nhận'.
  gs_parameter-footer04 = 'Thủ kho'.
  gs_parameter-footer05 = '(Ký, ghi rõ họ tên)'.
  gs_parameter-footer07 = 'Trang'.

ENDFORM.                    " GET_PARAMETER

*&---------------------------------------------------------------------*
*&      Form  GET_DATA_A
*&---------------------------------------------------------------------*
*       Inbound / Returns Delivery, chưa hoặc đã Goods Receipt.
*       Bỏ dòng không quản lý tồn kho và dòng chính của batch split.
*----------------------------------------------------------------------*
FORM get_data_a .

  DATA lr_vbtyp TYPE RANGE OF vbtypl.

  " Chưa khai báo danh mục loại Delivery: lấy mọi Inbound / Returns Delivery
  IF gr_lfart IS INITIAL.
    lr_vbtyp = VALUE #( sign = 'I' option = 'EQ' ( low = '7' ) ( low = 'T' ) ).
  ENDIF.

  SELECT FROM likp
    INNER JOIN lips ON lips~vbeln = likp~vbeln
    FIELDS @gc_src_a     AS src,
           likp~vbeln    AS docno,
           lips~posnr,
           likp~lfart    AS doc_type,
           lips~bwart,
           lips~werks,
           lips~lgort,
           lips~matnr,
           lips~ematn,
           lips~charg,
           lips~lfimg    AS qty_inv,
           lips~vrkme    AS unit,
           likp~lifnr,
           likp~kunnr,
           likp~lfdat,
           likp~wadat_ist,
           likp~bldat,
           likp~traid,
           likp~bolnr,
           likp~lifex,
           likp~wbstk
    WHERE likp~vbeln IN @s_vbeln
      AND likp~lfdat IN @s_lfdat
      AND likp~lifnr IN @s_lifnr
      AND likp~kunnr IN @s_kunnr
      AND likp~traid IN @s_traid
      AND likp~lfart IN @gr_lfart
      AND likp~vbtyp IN @lr_vbtyp
      AND lips~werks IN @s_werks
      AND lips~lgort IN @s_lgort
      AND lips~wbsta <> @space
      AND lips~chspl = @space
    INTO CORRESPONDING FIELDS OF TABLE @gt_item.

  LOOP AT gt_item INTO DATA(ls_item).
    INSERT VALUE #( vbeln     = ls_item-docno
                    lfdat     = ls_item-lfdat
                    wadat_ist = ls_item-wadat_ist
                    traid     = ls_item-traid
                    bolnr     = ls_item-bolnr
                    lifex     = ls_item-lifex ) INTO TABLE gt_dlv.
  ENDLOOP.

ENDFORM.                    " GET_DATA_A

*&---------------------------------------------------------------------*
*&      Form  GET_DATA_B
*&---------------------------------------------------------------------*
*       Dòng nhập (Debit) của chứng từ vật tư; bỏ chứng từ đã hủy, chứng
*       từ hủy và dòng tự sinh. Chỉ giữ dòng thuộc nhóm Mua hàng / Trả hàng
*       theo bảng ZTWM_MVT_GRP (dòng khớp đầu tiên theo SEQNR).
*----------------------------------------------------------------------*
FORM get_data_b .

  DATA: lr_mjahr TYPE RANGE OF mjahr,
        lr_bwart TYPE RANGE OF bwart,
        ls_mvt   TYPE gty_mvt,
        ls_po    TYPE gty_po,
        lv_keep  TYPE abap_bool.

  IF s_mblnr[] IS NOT INITIAL.
    lr_mjahr = VALUE #( ( sign = 'I' option = 'EQ' low = p_mjahr ) ).
  ENDIF.

  SELECT bwart, seqnr, sobkz, aufnr_flg, bsart, pstyp, werks, grp_code
    FROM ztwm_mvt_grp
    INTO TABLE @gt_mvt.

  LOOP AT gt_mvt INTO ls_mvt WHERE grp_code = gc_grp_mh OR grp_code = gc_grp_th.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_mvt-bwart ) TO lr_bwart.
  ENDLOOP.
  CHECK lr_bwart IS NOT INITIAL.

  SELECT FROM matdoc
    FIELDS @gc_src_b AS src,
           mblnr     AS docno,
           mjahr,
           zeile,
           bwart     AS doc_type,
           bwart,
           sobkz,
           aufnr,
           ebeln,
           ebelp,
           werks,
           lgort,
           matnr,
           ematn,
           charg,
           lsmng     AS qty_inv,
           erfmg     AS qty_act,
           erfme     AS unit,
           lifnr,
           kunnr,
           budat,
           bldat,
           xblnr,
           frbnr,
           xabln,
           bktxt,
           sgtxt,
           vbeln_im,
           vbelp_im
    WHERE record_type = 'MDOC'
      AND mblnr IN @s_mblnr
      AND mjahr IN @lr_mjahr
      AND budat IN @s_budat
      AND werks IN @s_werks
      AND lgort IN @s_lgort
      AND lifnr IN @s_lifnr
      AND kunnr IN @s_kunnr
      AND bwart IN @lr_bwart
      AND shkzg = 'S'
      AND cancelled = @space
      AND smbln = @space
      AND xauto = @space
    INTO CORRESPONDING FIELDS OF TABLE @gt_item.

  " PO tham chiếu: loại PO và Item Category để khớp điều kiện bảng
  DATA(lt_ebeln) = VALUE gtt_item( FOR ls_e IN gt_item WHERE ( ebeln IS NOT INITIAL )
                                   ( ebeln = ls_e-ebeln ebelp = ls_e-ebelp ) ).
  SORT lt_ebeln BY ebeln ebelp.
  DELETE ADJACENT DUPLICATES FROM lt_ebeln COMPARING ebeln ebelp.

  IF lt_ebeln IS NOT INITIAL.
    SELECT FROM ekpo
      INNER JOIN ekko ON ekko~ebeln = ekpo~ebeln
      INNER JOIN @lt_ebeln AS k ON k~ebeln = ekpo~ebeln AND k~ebelp = ekpo~ebelp
      FIELDS ekpo~ebeln, ekpo~ebelp, ekko~bsart, ekpo~pstyp
      INTO CORRESPONDING FIELDS OF TABLE @gt_po   ##ITAB_DB_SELECT.
  ENDIF.

  " Dòng khớp đầu tiên theo SEQNR quyết định nhóm; điều kiện trống = bất kỳ
  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<lfs_item>).
    lv_keep = abap_false.
    CLEAR ls_po.
    IF <lfs_item>-ebeln IS NOT INITIAL.
      ls_po = VALUE #( gt_po[ ebeln = <lfs_item>-ebeln ebelp = <lfs_item>-ebelp ] OPTIONAL ).
    ENDIF.

    LOOP AT gt_mvt INTO ls_mvt WHERE bwart = <lfs_item>-bwart.
      CHECK ( ls_mvt-sobkz IS INITIAL OR ls_mvt-sobkz = <lfs_item>-sobkz )
        AND ( ls_mvt-aufnr_flg IS INITIAL OR <lfs_item>-aufnr IS NOT INITIAL )
        AND ( ls_mvt-bsart IS INITIAL OR ls_mvt-bsart = ls_po-bsart )
        AND ( ls_mvt-pstyp IS INITIAL OR ls_mvt-pstyp = ls_po-pstyp )
        AND ( ls_mvt-werks IS INITIAL OR ls_mvt-werks = <lfs_item>-werks ).
      lv_keep = xsdbool( ls_mvt-grp_code = gc_grp_mh OR ls_mvt-grp_code = gc_grp_th ).
      EXIT.
    ENDLOOP.

    IF lv_keep = abap_false.
      DELETE gt_item.
    ENDIF.
  ENDLOOP.

  " Delivery tham chiếu: lấy số xe, Bill of Lading, hóa đơn, text
  DATA(lt_vbeln) = VALUE gtt_item( FOR ls_i IN gt_item WHERE ( vbeln_im IS NOT INITIAL )
                                   ( vbeln_im = ls_i-vbeln_im ) ).
  SORT lt_vbeln BY vbeln_im.
  DELETE ADJACENT DUPLICATES FROM lt_vbeln COMPARING vbeln_im.
  CHECK lt_vbeln IS NOT INITIAL.

  SELECT FROM likp
    INNER JOIN @lt_vbeln AS k ON k~vbeln_im = likp~vbeln
    FIELDS likp~vbeln, likp~lfdat, likp~wadat_ist, likp~traid, likp~bolnr, likp~lifex
    INTO CORRESPONDING FIELDS OF TABLE @gt_dlv   ##ITAB_DB_SELECT.

ENDFORM.                    " GET_DATA_B

*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORITY
*&---------------------------------------------------------------------*
*       Loại dòng thuộc Plant không có quyền xem chứng từ nhập (M_MSEG_WWE)
*----------------------------------------------------------------------*
FORM check_authority .

  DATA: lv_count TYPE i,
        lv_lines TYPE i,
        lv_werks TYPE werks_d.

  DATA(lt_werks) = VALUE gtt_item( FOR ls_i IN gt_item ( werks = ls_i-werks ) ).
  SORT lt_werks BY werks.
  DELETE ADJACENT DUPLICATES FROM lt_werks COMPARING werks.

  LOOP AT lt_werks INTO DATA(ls_werks).
    AUTHORITY-CHECK OBJECT 'M_MSEG_WWE'
      ID 'ACTVT' FIELD '03'
      ID 'WERKS' FIELD ls_werks-werks.
    CHECK sy-subrc <> 0.
    IF lv_werks IS INITIAL.
      lv_werks = ls_werks-werks.
    ENDIF.
    lv_lines = lines( gt_item ).
    DELETE gt_item WHERE werks = ls_werks-werks.
    lv_count = lv_count + lv_lines - lines( gt_item ).
  ENDLOOP.

  CHECK lv_werks IS NOT INITIAL.

  IF gt_item IS INITIAL.
    MESSAGE s001 WITH lv_werks DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  MESSAGE s007 WITH lv_count lv_werks DISPLAY LIKE 'W'.

ENDFORM.                    " CHECK_AUTHORITY

*&---------------------------------------------------------------------*
*&      Form  GET_MASTER_DATA
*&---------------------------------------------------------------------*
*       Vật tư (kể cả mã MPN), kho, thuộc tính lô
*----------------------------------------------------------------------*
FORM get_master_data .

  DATA: lt_matnr TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line,
        lt_mkey  TYPE SORTED TABLE OF gty_marc WITH UNIQUE KEY matnr werks,
        lt_lkey  TYPE SORTED TABLE OF gty_lgort WITH UNIQUE KEY werks lgort,
        lt_bkey  TYPE SORTED TABLE OF gty_batch WITH UNIQUE KEY matnr werks charg.

  LOOP AT gt_item INTO DATA(ls_item).
    INSERT ls_item-matnr INTO TABLE lt_matnr.
    IF ls_item-ematn IS NOT INITIAL.
      INSERT ls_item-ematn INTO TABLE lt_matnr.
    ENDIF.
    INSERT VALUE #( matnr = ls_item-matnr werks = ls_item-werks ) INTO TABLE lt_mkey.
    INSERT VALUE #( werks = ls_item-werks lgort = ls_item-lgort ) INTO TABLE lt_lkey.
    IF ls_item-charg IS NOT INITIAL.
      INSERT VALUE #( matnr = ls_item-matnr werks = ls_item-werks charg = ls_item-charg )
             INTO TABLE lt_bkey.
    ENDIF.
  ENDLOOP.

  SELECT FROM mara
    INNER JOIN @lt_matnr AS k ON k~table_line = mara~matnr
    LEFT OUTER JOIN makt ON makt~matnr = mara~matnr
                        AND makt~spras = @sy-langu
    FIELDS mara~matnr, makt~maktx, mara~normt, mara~groes, mara~mfrnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_mat.

  SELECT FROM marc
    INNER JOIN @lt_mkey AS k ON k~matnr = marc~matnr
                            AND k~werks = marc~werks
    FIELDS marc~matnr, marc~werks, marc~herkl
    INTO CORRESPONDING FIELDS OF TABLE @gt_marc.

  SELECT FROM t001l
    INNER JOIN @lt_lkey AS k ON k~werks = t001l~werks
                            AND k~lgort = t001l~lgort
    FIELDS t001l~werks, t001l~lgort, t001l~lgobe
    INTO CORRESPONDING FIELDS OF TABLE @gt_lgort.

  CHECK lt_bkey IS NOT INITIAL.

  SELECT FROM mcha
    INNER JOIN @lt_bkey AS k ON k~matnr = mcha~matnr
                            AND k~werks = mcha~werks
                            AND k~charg = mcha~charg
    FIELDS mcha~matnr, mcha~werks, mcha~charg, mcha~hsdat, mcha~vfdat,
           mcha~qndat, mcha~licha
    INTO CORRESPONDING FIELDS OF TABLE @gt_batch.

  PERFORM get_batch_charact.

ENDFORM.                    " GET_MASTER_DATA

*&---------------------------------------------------------------------*
*&      Form  GET_BATCH_CHARACT
*&---------------------------------------------------------------------*
*       Đặc tính lô; điều kiện bảo quản lô trống thì lấy của vật tư
*----------------------------------------------------------------------*
FORM get_batch_charact .

  DATA: lt_atnam TYPE STANDARD TABLE OF zcore_st_rseloption_atnam,
        lt_char  TYPE STANDARD TABLE OF bapi1003_alloc_values_char.

  lt_atnam = VALUE #( sign = 'I' option = 'EQ'
                      ( low = gc_at_nsx ) ( low = gc_at_lonsx ) ( low = gc_at_nuoc )
                      ( low = gc_at_gpnk ) ( low = gc_at_baoquan ) ( low = gc_at_quycach ) ).

  LOOP AT gt_batch ASSIGNING FIELD-SYMBOL(<lf_bat>).
    CLEAR lt_char.
    CALL FUNCTION 'ZCORE_FM_GET_CRTRT_MULTIVAL'
      EXPORTING
        i_matnr    = <lf_bat>-matnr
        i_charg    = <lf_bat>-charg
        i_werks    = <lf_bat>-werks
        i_klart    = '023'
      TABLES
        it_atnam   = lt_atnam
        it_charact = lt_char.

    LOOP AT lt_char INTO DATA(ls_char).
      CASE ls_char-charact.
        WHEN gc_at_nsx.      <lf_bat>-z_nsx   = ls_char-value_char.
        WHEN gc_at_lonsx.    <lf_bat>-z_lonsx = ls_char-value_char.
        WHEN gc_at_nuoc.     <lf_bat>-herkl   = ls_char-value_char.
        WHEN gc_at_gpnk.     <lf_bat>-gpnk    = ls_char-value_char.
        WHEN gc_at_baoquan.  <lf_bat>-baoquan = ls_char-value_char.
        WHEN gc_at_quycach.  <lf_bat>-quycach = ls_char-value_char.
      ENDCASE.
    ENDLOOP.

    IF <lf_bat>-baoquan IS INITIAL.
      CLEAR lt_char.
      CALL FUNCTION 'ZCORE_FM_GET_CRTRT_MULTIVAL'
        EXPORTING
          i_matnr    = <lf_bat>-matnr
          i_klart    = '001'
        TABLES
          it_atnam   = lt_atnam
          it_charact = lt_char.
      READ TABLE lt_char INTO ls_char WITH KEY charact = gc_at_baoquan.
      IF sy-subrc = 0.
        <lf_bat>-baoquan = ls_char-value_char.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " GET_BATCH_CHARACT

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_DATA
*&---------------------------------------------------------------------*
*       Mỗi dòng = 1 Lệnh nhập kho hoặc 1 chứng từ nhập kho
*----------------------------------------------------------------------*
FORM build_alv_data .

  DATA: ls_alv  TYPE gty_alv,
        lv_kind TYPE char1,
        lv_dlv  TYPE vbeln_vl,
        lv_text TYPE char255.

  CLEAR gt_alv.
  SORT gt_item BY src docno mjahr posnr zeile.

  LOOP AT gt_item INTO DATA(ls_item)
       GROUP BY ( src = ls_item-src docno = ls_item-docno mjahr = ls_item-mjahr )
       INTO DATA(lg_doc).

    CLEAR ls_alv.
    LOOP AT GROUP lg_doc INTO DATA(ls_line).
      IF ls_alv IS INITIAL.
        ls_alv-sel      = abap_true.
        ls_alv-source   = ls_line-src.
        ls_alv-docno    = ls_line-docno.
        ls_alv-mjahr    = ls_line-mjahr.
        ls_alv-doc_type = ls_line-doc_type.
        ls_alv-werks    = ls_line-werks.
        IF ls_line-lifnr IS NOT INITIAL.
          ls_alv-partner = ls_line-lifnr.
          lv_kind = 'K'.
        ELSE.
          ls_alv-partner = ls_line-kunnr.
          lv_kind = 'D'.
        ENDIF.
        PERFORM get_partner USING lv_kind ls_alv-partner CHANGING ls_alv-name.

        PERFORM get_dlv_number USING ls_line CHANGING lv_dlv.
        READ TABLE gt_dlv INTO DATA(ls_dlv) WITH TABLE KEY vbeln = lv_dlv.
        IF sy-subrc <> 0.
          CLEAR ls_dlv.
        ENDIF.
        ls_alv-lfdat = ls_dlv-lfdat.
        ls_alv-traid = ls_dlv-traid.
        IF ls_alv-traid IS INITIAL AND lv_dlv IS NOT INITIAL.
          PERFORM read_text USING gc_txt_soxe 'VBBK' lv_dlv CHANGING lv_text.
          ls_alv-traid = lv_text.
        ENDIF.
        IF ls_alv-traid IS INITIAL.
          ls_alv-traid = ls_line-xabln.
        ENDIF.

        IF ls_line-src = gc_src_a.
          ls_alv-gr_status = SWITCH #( ls_line-wbstk WHEN 'C' THEN 'Đã nhập'
                                                     WHEN 'B' THEN 'Nhập một phần'
                                                     ELSE 'Chưa nhập' ).
          ls_alv-obj_key = |{ gc_src_a }/{ ls_line-docno }|.
        ELSE.
          ls_alv-gr_status = 'Đã nhập'.
          ls_alv-obj_key = |{ gc_src_b }/{ ls_line-docno }/{ ls_line-mjahr }|.
        ENDIF.
      ENDIF.
      ls_alv-item_count = ls_alv-item_count + 1.
    ENDLOOP.
    APPEND ls_alv TO gt_alv.
  ENDLOOP.

  PERFORM read_print_count.

  SORT gt_alv BY partner docno mjahr.

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
      AND l~formname = @gc_formname
    INTO TABLE @DATA(lt_cnt)   ##ITAB_DB_SELECT.

  LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<lf_alv>).
    READ TABLE lt_cnt INTO DATA(ls_cnt) WITH KEY obj_key = <lf_alv>-obj_key.
    <lf_alv>-print_count = COND #( WHEN sy-subrc = 0 THEN ls_cnt-prt_count ELSE 0 ).
  ENDLOOP.

ENDFORM.                    " READ_PRINT_COUNT

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM display_alv .

  DATA: lo_column TYPE REF TO cl_salv_column_table,
        lo_grid   TYPE REF TO cl_salv_form_layout_grid,
        lv_doc    TYPE string,
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

      lo_column ?= lo_columns->get_column( 'DOCNO' ).
      lv_doc = COND #( WHEN p_src_a = abap_true THEN 'Lệnh nhập kho' ELSE 'Chứng từ kho' ).
      PERFORM set_col_text USING lo_column lv_doc.
      lo_column ?= lo_columns->get_column( 'MJAHR' ).
      lo_column->set_visible( xsdbool( p_src_b = abap_true ) ).
      lo_column ?= lo_columns->get_column( 'DOC_TYPE' ).
      PERFORM set_col_text USING lo_column 'Loại'.
      lo_column ?= lo_columns->get_column( 'PARTNER' ).
      PERFORM set_col_text USING lo_column 'NCC / KH'.
      lo_column ?= lo_columns->get_column( 'NAME' ).
      PERFORM set_col_text USING lo_column 'Tên'.
      lo_column ?= lo_columns->get_column( 'LFDAT' ).
      PERFORM set_col_text USING lo_column 'Ngày GH dự kiến'.
      lo_column ?= lo_columns->get_column( 'ITEM_COUNT' ).
      PERFORM set_col_text USING lo_column 'Số dòng'.
      lo_column ?= lo_columns->get_column( 'GR_STATUS' ).
      PERFORM set_col_text USING lo_column 'Trạng thái GR'.
      lo_column ?= lo_columns->get_column( 'TRAID' ).
      PERFORM set_col_text USING lo_column 'Số xe'.
      lo_column ?= lo_columns->get_column( 'PRINT_COUNT' ).
      PERFORM set_col_text USING lo_column 'Đã in (lần)'.

      lo_columns->get_column( 'WERKS' )->set_technical( abap_true ).
      lo_columns->get_column( 'SOURCE' )->set_technical( abap_true ).
      lo_columns->get_column( 'OBJ_KEY' )->set_technical( abap_true ).
    CATCH cx_salv_not_found.
  ENDTRY.

  " Dòng thông tin: nguồn, Plant, nhóm hàng
  lv_head = |Nguồn: { COND string( WHEN p_src_a = abap_true THEN '(A) Lệnh nhập kho'
                                   ELSE '(B) Chứng từ nhập kho' ) }|.
  LOOP AT s_werks INTO DATA(ls_werks) WHERE sign = 'I' AND option = 'EQ'.
    lv_head = |{ lv_head } \| Plant { ls_werks-low }|.
    EXIT.
  ENDLOOP.
  lv_head = |{ lv_head } \| Nhóm hàng: { COND string( WHEN p_vacsp = abap_true THEN 'Vacxin, sinh phẩm'
                                                       WHEN p_thugn = abap_true THEN 'Thuốc gây nghiện, hướng thần, tiền chất'
                                                       ELSE 'Hàng hóa khác' ) }|.
  CREATE OBJECT lo_grid.
  lo_grid->create_label( row = 1 column = 1
                         text = 'ZWM02 – Danh sách chứng từ cần in biên bản kiểm nhận' ).
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
*       Chọn tất cả; đã chọn hết thì bỏ chọn tất cả
*----------------------------------------------------------------------*
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
      default_file_name = |ZWM02_{ sy-datum }.xlsx|
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
*&      Form  PRINT_DOCS
*&---------------------------------------------------------------------*
*       Mỗi chứng từ được chọn 1 biên bản. IV_PREVIEW = X: xem trước.
*       Chỉ ghi nhật ký in khi đã in ra máy in (kể cả in từ xem trước).
*----------------------------------------------------------------------*
FORM print_docs USING iv_preview TYPE abap_bool.

  DATA: lv_fm      TYPE rs38l_fnam,
        ls_cparam  TYPE ssfctrlop,
        ls_output  TYPE ssfcompop,
        ls_job_opt TYPE ssfcresop,
        ls_job_inf TYPE ssfcrescl,
        lv_spld    TYPE usr01-spld,
        lv_msg     TYPE abap_bool,
        lv_line    TYPE symsgv.

  DATA(lt_sel) = VALUE gtt_alv( FOR ls_a IN gt_alv WHERE ( sel = abap_true ) ( ls_a ) ).
  IF lt_sel IS INITIAL.
    MESSAGE s008 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Cảnh báo trước khi in: bản in lại, dòng chưa có Batch
  CALL FUNCTION 'MESSAGES_INITIALIZE'.
  LOOP AT lt_sel INTO DATA(ls_sel).
    IF ls_sel-print_count > 0 AND iv_preview = abap_false.
      PERFORM store_msg USING 'I' '005' ls_sel-docno ls_sel-print_count CHANGING lv_msg.
    ENDIF.
    IF ls_sel-source = gc_src_a.
      LOOP AT gt_item INTO DATA(ls_item) WHERE src = gc_src_a
                                           AND docno = ls_sel-docno
                                           AND charg IS INITIAL.
        lv_line = |{ ls_item-docno ALPHA = OUT }/{ ls_item-posnr ALPHA = OUT }|.
        PERFORM store_msg USING 'W' '006' lv_line space CHANGING lv_msg.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
  IF lv_msg = abap_true.
    CALL FUNCTION 'MESSAGES_SHOW'
      EXPORTING
        show_linno = space
      EXCEPTIONS
        OTHERS     = 1.
  ENDIF.

  " Máy in mặc định của user; chưa khai báo thì hiện hộp thoại chọn máy in
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
      formname           = gc_formname
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

  LOOP AT lt_sel INTO ls_sel.
    PERFORM fill_form USING ls_sel.

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

  " In từ màn hình xem trước: báo bản in lại sau khi đã in
  IF iv_preview = abap_true.
    LOOP AT lt_sel INTO ls_sel WHERE print_count > 0.
      MESSAGE i005 WITH |{ ls_sel-docno ALPHA = OUT }| ls_sel-print_count.
    ENDLOOP.
  ENDIF.

  PERFORM read_print_count.
  go_alv->refresh( ).

ENDFORM.                    " PRINT_DOCS

*&---------------------------------------------------------------------*
*&      Form  STORE_MSG
*&---------------------------------------------------------------------*
FORM store_msg USING iv_type TYPE c
                     iv_no   TYPE c
                     iv_v1   TYPE any
                     iv_v2   TYPE any
               CHANGING cv_has TYPE abap_bool.

  DATA: lv_v1 TYPE symsgv,
        lv_v2 TYPE symsgv,
        lv_ty TYPE symsgty,
        lv_no TYPE symsgno.

  lv_ty = iv_type.
  lv_no = iv_no.
  lv_v1 = iv_v1.
  lv_v2 = iv_v2.
  SHIFT lv_v1 LEFT DELETING LEADING '0'.
  CONDENSE lv_v2.

  CALL FUNCTION 'MESSAGE_STORE'
    EXPORTING
      arbgb                  = 'ZWM02'
      exception_if_not_active = space
      msgty                  = lv_ty
      msgv1                  = lv_v1
      msgv2                  = lv_v2
      txtnr                  = lv_no
    EXCEPTIONS
      OTHERS                 = 1.
  IF sy-subrc = 0.
    cv_has = abap_true.
  ENDIF.

ENDFORM.                    " STORE_MSG

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM
*&---------------------------------------------------------------------*
*       Header và các dòng của 1 biên bản (1 chứng từ)
*----------------------------------------------------------------------*
FORM fill_form USING is_doc TYPE gty_alv.

  DATA: lt_line  TYPE gtt_item,
        lv_dlv   TYPE vbeln_vl,
        lv_text  TYPE char255,
        lv_text2 TYPE char255,
        lv_num   TYPE char10,
        lv_kind  TYPE char1,
        lv_name  TYPE char255,
        lv_blk   TYPE abap_bool,
        lv_305   TYPE abap_bool,
        ls_data  TYPE zwm_st_bbknhh.

  lt_line = VALUE #( FOR ls_i IN gt_item WHERE ( src   = is_doc-source
                                                 AND docno = is_doc-docno
                                                 AND mjahr = is_doc-mjahr ) ( ls_i ) ).
  READ TABLE lt_line INTO DATA(ls_first) INDEX 1.
  CHECK sy-subrc = 0.

  lv_blk = xsdbool( line_exists( lt_line[ bwart = '103' ] ) ).
  lv_305 = xsdbool( is_doc-source = gc_src_b AND line_exists( lt_line[ bwart = '305' ] ) ).

  PERFORM get_dlv_number USING ls_first CHANGING lv_dlv.
  READ TABLE gt_dlv INTO DATA(ls_dlv) WITH TABLE KEY vbeln = lv_dlv.
  IF sy-subrc <> 0.
    CLEAR ls_dlv.
  ENDIF.

  " Đơn vị theo Plant
  lv_num = is_doc-werks.
  CLEAR: gs_parameter-name, gs_parameter-address, gs_parameter-tax,
         gs_parameter-tel_number, gs_parameter-fax_number.
  CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
    EXPORTING
      i_number     = lv_num
      i_kind       = 'P'
    IMPORTING
      e_name       = gs_parameter-name
      e_address    = gs_parameter-address
      e_tax        = gs_parameter-tax
      e_tel_number = gs_parameter-tel_number
      e_fax_number = gs_parameter-fax_number.
  TRANSLATE gs_parameter-name TO UPPER CASE.
  gs_parameter-header11 = |MST: { gs_parameter-tax }|.
  IF gs_parameter-tel_number IS NOT INITIAL.
    gs_parameter-header11 = |{ gs_parameter-header11 } – ĐT: { gs_parameter-tel_number }|.
  ENDIF.
  IF gs_parameter-fax_number IS NOT INITIAL.
    gs_parameter-header11 = |{ gs_parameter-header11 } – Fax: { gs_parameter-fax_number }|.
  ENDIF.

  " Mã biểu mẫu GMP: chờ BIDIPHAR cung cấp
  CLEAR gs_parameter-header02.

  " Lần in
  gs_parameter-header03 = COND #( WHEN is_doc-print_count = 0 THEN |Lần in: 1|
                                  ELSE |Bản in lại – lần { is_doc-print_count + 1 }| ).

  " Ngày kiểm nhận
  DATA(lv_date) = COND datum( WHEN is_doc-source = gc_src_b THEN ls_first-budat
                              WHEN ls_first-wadat_ist IS NOT INITIAL THEN ls_first-wadat_ist
                              ELSE ls_first-lfdat ).
  PERFORM format_date USING lv_date CHANGING gs_parameter-header04.
  CLEAR gs_parameter-header05.

  " Người kiểm nhận
  CLEAR gs_parameter-header06.
  IF lv_305 = abap_false.
    IF lv_dlv IS NOT INITIAL.
      PERFORM read_text USING gc_txt_kiemnh 'VBBK' lv_dlv CHANGING gs_parameter-header06.
    ELSE.
      gs_parameter-header06 = ls_first-xblnr.
    ENDIF.
  ENDIF.

  " Nhập tại kho
  CLEAR gs_parameter-header07.
  LOOP AT lt_line INTO DATA(ls_line).
    READ TABLE gt_lgort INTO DATA(ls_lgort) WITH TABLE KEY werks = ls_line-werks lgort = ls_line-lgort.
    IF sy-subrc <> 0.
      CLEAR ls_lgort.
    ENDIF.
    lv_text = |{ ls_line-lgort } – { ls_lgort-lgobe }|.
    IF gs_parameter-header07 IS INITIAL.
      gs_parameter-header07 = lv_text.
    ELSEIF gs_parameter-header07 NS lv_text.
      gs_parameter-header07 = |{ gs_parameter-header07 }; { lv_text }|.
    ENDIF.
  ENDLOOP.

  " Người giao hàng
  CLEAR gs_parameter-header08.
  IF lv_305 = abap_false.
    IF lv_dlv IS NOT INITIAL.
      PERFORM read_text USING gc_txt_giaohg 'VBBK' lv_dlv CHANGING gs_parameter-header08.
    ENDIF.
    IF gs_parameter-header08 IS INITIAL.
      gs_parameter-header08 = COND #( WHEN ls_dlv-bolnr IS NOT INITIAL THEN ls_dlv-bolnr
                                      ELSE ls_first-frbnr ).
    ENDIF.
  ENDIF.

  " Số xe vận chuyển
  gs_parameter-header09 = ls_dlv-traid.
  IF gs_parameter-header09 IS INITIAL AND lv_dlv IS NOT INITIAL.
    PERFORM read_text USING gc_txt_soxe 'VBBK' lv_dlv CHANGING gs_parameter-header09.
  ENDIF.
  IF gs_parameter-header09 IS INITIAL.
    gs_parameter-header09 = ls_first-xabln.
  ENDIF.

  " Giấy phép NK / quota: chỉ mẫu thuốc gây nghiện
  CLEAR gs_parameter-header10.
  IF p_thugn = abap_true.
    LOOP AT lt_line INTO ls_line WHERE charg IS NOT INITIAL.
      READ TABLE gt_batch INTO DATA(ls_bat)
           WITH TABLE KEY matnr = ls_line-matnr werks = ls_line-werks charg = ls_line-charg.
      CHECK sy-subrc = 0 AND ls_bat-gpnk IS NOT INITIAL.
      IF gs_parameter-header10 IS INITIAL.
        gs_parameter-header10 = ls_bat-gpnk.
      ELSEIF gs_parameter-header10 NS ls_bat-gpnk.
        gs_parameter-header10 = |{ gs_parameter-header10 }, { ls_bat-gpnk }|.
      ENDIF.
    ENDLOOP.
  ENDIF.

  CLEAR gt_data.

  " Dòng nhóm: NCC/KH | chứng từ | số, ngày hóa đơn
  CLEAR ls_data.
  ls_data-level = '1'.
  IF ls_first-lifnr IS NOT INITIAL.
    lv_kind = 'K'.
    lv_num  = ls_first-lifnr.
  ELSE.
    lv_kind = 'D'.
    lv_num  = ls_first-kunnr.
  ENDIF.
  PERFORM get_partner USING lv_kind lv_num CHANGING lv_name.
  lv_text  = COND #( WHEN lv_kind = 'K' THEN 'NCC' ELSE 'KH' ).
  lv_text2 = COND #( WHEN is_doc-source = gc_src_a THEN 'Lệnh nhập kho' ELSE 'Chứng từ nhập kho' ).
  ls_data-table_header = |{ lv_text } { lv_num ALPHA = OUT } – { lv_name } \| { lv_text2 } { is_doc-docno ALPHA = OUT }|.
  IF lv_blk = abap_true.
    ls_data-table_header = |{ ls_data-table_header } (Nhập kho GR blocked stock)|.
  ENDIF.

  CLEAR: lv_text, lv_text2.
  IF lv_dlv IS NOT INITIAL.
    lv_text = ls_dlv-lifex.
    IF lv_text IS INITIAL.
      PERFORM read_text USING gc_txt_sohd 'VBBK' lv_dlv CHANGING lv_text.
    ENDIF.
    PERFORM read_text USING gc_txt_ngayhd 'VBBK' lv_dlv CHANGING lv_text2.
    IF lv_text2 IS NOT INITIAL.
      lv_text = |{ lv_text } - { lv_text2 }|.
    ENDIF.
  ELSEIF ls_first-bktxt IS NOT INITIAL.
    PERFORM format_date USING ls_first-bldat CHANGING lv_text2.
    lv_text = |{ ls_first-bktxt } - { lv_text2 }|.
  ENDIF.
  IF lv_text IS NOT INITIAL.
    ls_data-shd_nhd = lv_text.
    ls_data-table_header = |{ ls_data-table_header } \| HĐ { lv_text }|.
  ENDIF.
  ls_data-mblnr  = is_doc-docno.
  ls_data-lifnr  = ls_first-lifnr.
  ls_data-kunnr  = ls_first-kunnr.
  APPEND ls_data TO gt_data.

  PERFORM fill_form_lines USING is_doc lt_line.

ENDFORM.                    " FILL_FORM

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM_LINES
*&---------------------------------------------------------------------*
*       Dòng chi tiết: cộng dồn cùng vật tư + lô trong 1 chứng từ
*----------------------------------------------------------------------*
FORM fill_form_lines USING is_doc  TYPE gty_alv
                           it_line TYPE gtt_item.

  DATA: ls_data   TYPE zwm_st_bbknhh,
        lv_stt    TYPE i,
        lv_nsx    TYPE char255,
        lv_land1  TYPE land1,
        lv_nuoc   TYPE char255,
        lv_tdname TYPE tdobname,
        lv_text   TYPE char255,
        lv_return TYPE abap_bool.

  DATA(lt_line) = it_line.
  SORT lt_line BY matnr ematn charg unit posnr zeile.

  LOOP AT lt_line INTO DATA(ls_item)
       GROUP BY ( matnr = ls_item-matnr ematn = ls_item-ematn
                  charg = ls_item-charg unit  = ls_item-unit )
       INTO DATA(lg_mat).

    CLEAR ls_data.
    lv_stt = lv_stt + 1.
    ls_data-level = '2'.
    ls_data-stt   = lv_stt.
    ls_data-mblnr = is_doc-docno.
    ls_data-matnr = lg_mat-matnr.
    ls_data-ematn = lg_mat-ematn.
    ls_data-charg = lg_mat-charg.
    ls_data-erfme = lg_mat-unit.

    LOOP AT GROUP lg_mat INTO DATA(ls_line).
      ls_data-lsmng = ls_data-lsmng + ls_line-qty_inv.
      ls_data-erfmg = ls_data-erfmg + ls_line-qty_act.
      ls_data-werks = ls_line-werks.
      ls_data-lgort = ls_line-lgort.
      ls_data-bwart = ls_line-bwart.
      ls_data-lifnr = ls_line-lifnr.
      ls_data-kunnr = ls_line-kunnr.

      " Hồ sơ đi kèm
      IF ls_data-sgtxt IS INITIAL.
        IF ls_line-src = gc_src_a.
          lv_tdname = |{ ls_line-docno }{ ls_line-posnr }|.
          PERFORM read_text USING gc_txt_hoso 'VBBP' lv_tdname CHANGING lv_text.
          ls_data-sgtxt = lv_text.
        ELSE.
          ls_data-sgtxt = ls_line-sgtxt.
        ENDIF.
      ENDIF.

      " Tình trạng niêm phong: nguồn A và hàng trả để trống
      lv_return = xsdbool( ls_line-lifnr IS INITIAL AND ls_line-kunnr IS NOT INITIAL ).
      IF ls_data-txz01 IS INITIAL AND ls_line-src = gc_src_b
         AND lv_return = abap_false AND ls_line-vbeln_im IS NOT INITIAL.
        lv_tdname = |{ ls_line-vbeln_im }{ ls_line-vbelp_im }|.
        PERFORM read_text USING gc_txt_niemph 'VBBP' lv_tdname CHANGING lv_text.
        ls_data-txz01 = lv_text.
      ENDIF.
    ENDLOOP.

    " Tên hàng: có mã MPN thì lấy mô tả mã MPN
    READ TABLE gt_mat INTO DATA(ls_mat) WITH TABLE KEY matnr = lg_mat-matnr.
    IF sy-subrc <> 0.
      CLEAR ls_mat.
    ENDIF.
    ls_data-maktx = ls_mat-maktx.
    ls_data-normt = ls_mat-normt.
    ls_data-groes = ls_mat-groes.
    CLEAR lv_nsx.
    IF lg_mat-ematn IS NOT INITIAL.
      READ TABLE gt_mat INTO DATA(ls_mpn) WITH TABLE KEY matnr = lg_mat-ematn.
      IF sy-subrc = 0.
        IF ls_mpn-maktx IS NOT INITIAL.
          ls_data-maktx = ls_mpn-maktx.
        ENDIF.
        ls_data-mfrnr = ls_mpn-mfrnr.
      ENDIF.
    ENDIF.

    " Lô: thuộc tính theo MCHA + đặc tính lô
    READ TABLE gt_batch INTO DATA(ls_bat)
         WITH TABLE KEY matnr = lg_mat-matnr werks = ls_data-werks charg = lg_mat-charg.
    IF sy-subrc <> 0.
      CLEAR ls_bat.
    ENDIF.
    ls_data-ngaysx  = ls_bat-hsdat.
    ls_data-handung = ls_bat-vfdat.
    IF ls_data-handung IS INITIAL AND p_vacsp = abap_false.
      ls_data-handung = ls_bat-qndat.
    ENDIF.
    ls_data-solo = COND #( WHEN ls_bat-z_lonsx IS NOT INITIAL THEN ls_bat-z_lonsx
                           WHEN ls_bat-licha   IS NOT INITIAL THEN ls_bat-licha
                           ELSE lg_mat-charg ).
    IF ls_bat-quycach IS NOT INITIAL.
      ls_data-groes = ls_bat-quycach.
    ENDIF.
    ls_data-ghichu = ls_bat-baoquan.

    " NSX: Z_NSX của lô, không có thì NSX của mã MPN
    CLEAR: lv_nsx, lv_land1.
    IF ls_bat-z_nsx IS NOT INITIAL.
      IF ls_bat-z_nsx CO '0123456789 '.
        PERFORM get_partner USING 'K' ls_bat-z_nsx CHANGING lv_nsx.
        PERFORM get_partner_land USING 'K' ls_bat-z_nsx CHANGING lv_land1.
      ENDIF.
      IF lv_nsx IS INITIAL.
        lv_nsx = ls_bat-z_nsx.
      ENDIF.
    ELSEIF ls_data-mfrnr IS NOT INITIAL.
      PERFORM get_partner USING 'K' ls_data-mfrnr CHANGING lv_nsx.
      PERFORM get_partner_land USING 'K' ls_data-mfrnr CHANGING lv_land1.
    ENDIF.

    " Nước SX: LOBM_HERKL của lô, rồi MARC-HERKL, rồi quốc gia của NSX
    CLEAR lv_nuoc.
    IF ls_bat-herkl IS NOT INITIAL.
      lv_land1 = ls_bat-herkl.
    ELSE.
      READ TABLE gt_marc INTO DATA(ls_marc)
           WITH TABLE KEY matnr = lg_mat-matnr werks = ls_data-werks.
      IF sy-subrc = 0 AND ls_marc-herkl IS NOT INITIAL.
        lv_land1 = ls_marc-herkl.
      ENDIF.
    ENDIF.
    IF lv_land1 IS NOT INITIAL.
      PERFORM get_country USING lv_land1 CHANGING lv_nuoc.
    ENDIF.

    ls_data-nsxns = COND #( WHEN lv_nsx IS NOT INITIAL AND lv_nuoc IS NOT INITIAL
                              THEN |{ lv_nsx } - { lv_nuoc }|
                            WHEN lv_nsx IS NOT INITIAL THEN lv_nsx
                            ELSE lv_nuoc ).

    " SL thực tế nguồn A: ghi tay
    IF is_doc-source = gc_src_a.
      CLEAR ls_data-erfmg.
    ENDIF.

    APPEND ls_data TO gt_data.
  ENDLOOP.

ENDFORM.                    " FILL_FORM_LINES

*&---------------------------------------------------------------------*
*&      Form  FORMAT_DATE
*&---------------------------------------------------------------------*
FORM format_date USING iv_date TYPE d
                 CHANGING cv_text TYPE any.

  CLEAR cv_text.
  CHECK iv_date IS NOT INITIAL.
  CONCATENATE iv_date+6(2) iv_date+4(2) iv_date(4) INTO cv_text SEPARATED BY '/'.

ENDFORM.                    " FORMAT_DATE

*&---------------------------------------------------------------------*
*&      Form  GET_DLV_NUMBER
*&---------------------------------------------------------------------*
*       Delivery của chứng từ: nguồn A là chính nó, nguồn B là Delivery
*       tham chiếu (nếu có)
*----------------------------------------------------------------------*
FORM get_dlv_number USING is_item TYPE gty_item
                    CHANGING cv_dlv TYPE vbeln_vl.

  cv_dlv = COND #( WHEN is_item-src = gc_src_a THEN is_item-docno
                   ELSE is_item-vbeln_im ).

ENDFORM.                    " GET_DLV_NUMBER

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
*&      Form  GET_PARTNER
*&---------------------------------------------------------------------*
*       Tên NCC (K) / khách hàng (D), có lưu đệm
*----------------------------------------------------------------------*
FORM get_partner USING iv_kind   TYPE char1
                       iv_number TYPE any
                 CHANGING cv_name TYPE any.

  DATA ls_partner TYPE gty_partner.

  PERFORM read_partner USING iv_kind iv_number CHANGING ls_partner.
  cv_name = ls_partner-name.

ENDFORM.                    " GET_PARTNER

*&---------------------------------------------------------------------*
*&      Form  GET_PARTNER_LAND
*&---------------------------------------------------------------------*
FORM get_partner_land USING iv_kind   TYPE char1
                            iv_number TYPE any
                      CHANGING cv_land1 TYPE land1.

  DATA ls_partner TYPE gty_partner.

  PERFORM read_partner USING iv_kind iv_number CHANGING ls_partner.
  cv_land1 = ls_partner-land1.

ENDFORM.                    " GET_PARTNER_LAND

*&---------------------------------------------------------------------*
*&      Form  READ_PARTNER
*&---------------------------------------------------------------------*
FORM read_partner USING iv_kind   TYPE char1
                        iv_number TYPE any
                  CHANGING cs_partner TYPE gty_partner.

  DATA lv_num TYPE char10.

  CLEAR cs_partner.
  lv_num = iv_number.
  CONDENSE lv_num.
  CHECK lv_num IS NOT INITIAL.
  IF lv_num CO '0123456789'.
    lv_num = |{ lv_num ALPHA = IN WIDTH = 10 }|.
  ENDIF.

  READ TABLE gt_partner INTO cs_partner WITH TABLE KEY kind = iv_kind number = lv_num.
  CHECK sy-subrc <> 0.

  cs_partner-kind   = iv_kind.
  cs_partner-number = lv_num.
  CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
    EXPORTING
      i_number = lv_num
      i_kind   = iv_kind
    IMPORTING
      e_name   = cs_partner-name.
  IF iv_kind = 'K'.
    SELECT SINGLE land1 FROM lfa1 WHERE lifnr = @lv_num INTO @cs_partner-land1.
  ELSE.
    SELECT SINGLE land1 FROM kna1 WHERE kunnr = @lv_num INTO @cs_partner-land1.
  ENDIF.
  INSERT cs_partner INTO TABLE gt_partner.

ENDFORM.                    " READ_PARTNER

*&---------------------------------------------------------------------*
*&      Form  GET_COUNTRY
*&---------------------------------------------------------------------*
FORM get_country USING iv_land1 TYPE land1
                 CHANGING cv_landx TYPE any.

  DATA ls_country TYPE gty_country.

  READ TABLE gt_country INTO ls_country WITH TABLE KEY land1 = iv_land1.
  IF sy-subrc <> 0.
    ls_country-land1 = iv_land1.
    SELECT SINGLE landx50 FROM t005t
      WHERE spras = @sy-langu
        AND land1 = @iv_land1
      INTO @ls_country-landx.
    IF ls_country-landx IS INITIAL.
      ls_country-landx = iv_land1.
    ENDIF.
    INSERT ls_country INTO TABLE gt_country.
  ENDIF.
  cv_landx = ls_country-landx.

ENDFORM.                    " GET_COUNTRY

*&---------------------------------------------------------------------*
*&      Form  WRITE_PRTLOG
*&---------------------------------------------------------------------*
*       Nhật ký in ZTWM_PRTLOG (dùng chung nhóm form kho): mỗi chứng từ
*       1 bản ghi, cộng số lần in ngay trên DB
*----------------------------------------------------------------------*
FORM write_prtlog USING it_doc TYPE gtt_alv.

  LOOP AT it_doc INTO DATA(ls_doc).
    UPDATE ztwm_prtlog
      SET prt_count = prt_count + 1,
          last_date = @sy-datum,
          last_time = @sy-uzeit,
          last_user = @sy-uname
      WHERE tcode    = @gc_tcode
        AND formname = @gc_formname
        AND obj_key  = @ls_doc-obj_key.
    CHECK sy-dbcnt = 0.

    READ TABLE gt_item INTO DATA(ls_item) WITH KEY src   = ls_doc-source
                                                    docno = ls_doc-docno
                                                    mjahr = ls_doc-mjahr.
    INSERT ztwm_prtlog FROM @( VALUE ztwm_prtlog( tcode      = gc_tcode
                                                  formname   = gc_formname
                                                  obj_key    = ls_doc-obj_key
                                                  rpt_opt    = ls_doc-source
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
            last_date = @sy-datum,
            last_time = @sy-uzeit,
            last_user = @sy-uname
        WHERE tcode    = @gc_tcode
          AND formname = @gc_formname
          AND obj_key  = @ls_doc-obj_key.
    ENDIF.
  ENDLOOP.
  COMMIT WORK.

ENDFORM.                    " WRITE_PRTLOG

*&---------------------------------------------------------------------*
*&      Form  F4_HELP_MBLNR
*&---------------------------------------------------------------------*
*       Chọn chứng từ như MB51
*----------------------------------------------------------------------*
FORM f4_help_mblnr .

  DATA lv_flag TYPE c LENGTH 1 VALUE 'X'.

  EXPORT flag = lv_flag TO MEMORY ID 'MB51_FLAG'.
  CALL TRANSACTION 'MB51' WITH AUTHORITY-CHECK.
  GET PARAMETER ID 'MBN' FIELD s_mblnr-low.

ENDFORM.                    " F4_HELP_MBLNR
