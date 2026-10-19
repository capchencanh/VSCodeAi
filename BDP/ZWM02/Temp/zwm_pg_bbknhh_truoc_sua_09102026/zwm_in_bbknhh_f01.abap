*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_BBKNHH_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  INIT
*&---------------------------------------------------------------------*
FORM init .

  CLEAR:
    gt_alv,
    gt_data,
    gt_predata,
    gt_mch1,
    gt_atnam,
    gt_mara,
    gt_lfa1,
    gt_lfa1_ut2,
    gt_kna1,
    gs_alv,
    gs_data,
    gs_predata,
    gs_header,
    gs_mch1,
    gs_atnam,
    gs_mara,
    gs_lfa1,
    gs_lfa1_ut2,
    gs_kna1,
    gs_parameter.

  CLEAR:
    gv_selected_count,
    gv_current_source,
    gv_current_docno,
    gv_current_docno2.

ENDFORM.                    " INIT

*&---------------------------------------------------------------------*
*&      Form  CHECK_CONDITION
*&---------------------------------------------------------------------*
FORM check_condition .

* p_mjahr đã được OBLIGATORY trên selection-screen.
* Các điều kiện khác theo đặc tả đều không bắt buộc.

ENDFORM.                    " CHECK_CONDITION

*&---------------------------------------------------------------------*
*&      Form  MODIFY_SCREEN
*&---------------------------------------------------------------------*
FORM modify_screen .

ENDFORM.                    " MODIFY_SCREEN

*&---------------------------------------------------------------------*
*&      Form  GET_PARAMETER
*&---------------------------------------------------------------------*
FORM get_parameter .

  PERFORM check_require.

  IF p_vacsp EQ 'X'.

    gs_parameter-title_report =
      'BIÊN BẢN KIỂM NHẬN VACXIN, SINH PHẨM'.

  ELSEIF p_thugn EQ 'X'.

    gs_parameter-title_report =
      'BIÊN BẢN KIỂM NHẬN THUỐC GÂY NGHIỆN, THUỐC HƯỚNG TÂM THẦN, TIỀN CHẤT DÙNG LÀM THUỐC'.

    " HuanNLC added : Thêm Chu ki theo P_THUGN
    gs_parameter-footer06 = 'Lái xe'.
    " --- End ---

  ELSE.

    gs_parameter-title_report =
      'BIÊN BẢN KIỂM NHẬN HÀNG HÓA'.

  ENDIF.

  gs_parameter-parameter01 = 'Chúng tôi gồm:'.
  gs_parameter-parameter02 = 'Thủ kho:'.
  gs_parameter-parameter21 = 'Nhập tại kho:'.
  gs_parameter-parameter03 = 'Nhân viên kiểm nhận:'.
  gs_parameter-parameter04 = 'Người giao hàng:'.
  gs_parameter-parameter05 = 'Người vận chuyển:'.
  gs_parameter-parameter06 = 'Số xe vận chuyển:'.

  gs_parameter-parameter07 = 'STT'.
  gs_parameter-parameter08 = 'Tên hàng'.
  gs_parameter-parameter09 = 'SĐK'.
  gs_parameter-parameter10 = 'NSX – Nước SX'.
  gs_parameter-parameter11 = 'Số lô NSX'.
  gs_parameter-parameter12 = 'Ngày sản xuất'.
  gs_parameter-parameter13 = 'Hạn dùng'.
  gs_parameter-parameter14 = 'Quy cách'.
  gs_parameter-parameter15 = 'ĐVT'.
  gs_parameter-parameter16 = 'Số lượng hóa đơn'.
  gs_parameter-parameter17 = 'Số lượng thực tế'.
  gs_parameter-parameter18 = 'Hồ sơ đi kèm'.
  gs_parameter-parameter19 = 'Tình trạng niêm phong'.
  gs_parameter-parameter20 = 'Ghi chú'.
  gs_parameter-parameter22 = 'Số lô SAP'.

  gs_parameter-footer01 = 'Ngày………Tháng……Năm……'.
  gs_parameter-footer02 = 'Người giao hàng'.
  gs_parameter-footer03 = 'Người kiểm nhận'.
  gs_parameter-footer04 = 'Thủ kho'.
  gs_parameter-footer05 = 'Trang'.

ENDFORM.                    " GET_PARAMETER

*&---------------------------------------------------------------------*
*&      Form  FILL_DATA
*&---------------------------------------------------------------------*
FORM fill_data .

  DATA:
    lt_ekpo TYPE STANDARD TABLE OF ekpo,
    ls_ekpo TYPE ekpo.

  FIELD-SYMBOLS:
    <lf_header> TYPE zwm_st_bbknhh.

  CLEAR:
    gt_predata,
    gt_mch1,
    gt_mara,
    gt_lfa1,
    gt_kna1,
    gs_header.

  SELECT
    mseg~bukrs
    mkpf~budat
    mkpf~usnam
    mkpf~xblnr
    mkpf~le_vbeln
    mseg~ablad
    mkpf~frbnr
    mkpf~xabln
    mseg~zeile
    makt~maktx AS txz01
    mara~normt
    mara~mfrnr
    mseg~ematn
    marc~herkl
    adrc~country
    mseg~charg
    mseg~matnr
    mara~groes
    mseg~meins
    mseg~lsmng
    mseg~erfmg
    mseg~sgtxt
    mseg~wempf
    mseg~lifnr
    mseg~kunnr
    mkpf~mblnr
    mkpf~bktxt
    mkpf~bldat
    mseg~lsmeh
    mseg~werks
    mseg~erfme
    mseg~mblnr
    t001l~lgobe
    mseg~bwart
    mseg~sobkz
    mseg~vbeln_im
    mseg~lgort
    mseg~ebeln
    mseg~ebelp
    mseg~shkzg
  INTO CORRESPONDING FIELDS OF TABLE gt_predata
  FROM mseg
    INNER JOIN mkpf
      ON mseg~mblnr EQ mkpf~mblnr
     AND mseg~mjahr EQ mkpf~mjahr
    LEFT JOIN makt
      ON mseg~matnr EQ makt~matnr
     AND makt~spras EQ 'E'
    LEFT JOIN mara
      ON mseg~matnr EQ mara~matnr
    INNER JOIN marc
      ON mara~matnr EQ marc~matnr
     AND mseg~werks EQ marc~werks
    INNER JOIN t001w
      ON marc~werks EQ t001w~werks
    INNER JOIN adrc
      ON adrc~addrnumber EQ t001w~adrnr
    LEFT JOIN t001l
      ON mseg~lgort EQ t001l~lgort
     AND mseg~werks EQ t001l~werks
  WHERE mseg~mblnr IN s_mblnr
    AND mseg~werks IN s_werks
    AND mseg~lgort IN s_lgort
    AND mseg~lifnr IN s_lifnr
    AND mseg~kunnr IN s_kunnr
    AND mkpf~budat IN s_budat
    AND mseg~gjahr EQ p_mjahr
    AND mseg~xauto NE 'X'
    AND mseg~bwart NOT IN (
      302,
      310,
      312,
      314,
      317,
      320,
      322,
      324,
      326,
      342,
      344,
      350,
      352,
      412,
      414,
      416,
      442,
      541
    ).

  DELETE gt_predata WHERE shkzg = 'H' AND bwart <> '301'.

  IF gt_predata IS INITIAL.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* Lấy tên hàng từ PO
*---------------------------------------------------------------------*
  IF gt_predata IS NOT INITIAL.

    SELECT *
      FROM ekpo
      INTO TABLE lt_ekpo
      FOR ALL ENTRIES IN gt_predata
      WHERE matnr EQ gt_predata-matnr
        AND werks EQ gt_predata-werks.

  ENDIF.

  IF sy-subrc IS INITIAL.

    SORT lt_ekpo BY ebeln ebelp matnr werks lgort.

    LOOP AT gt_predata ASSIGNING <lf_header>.

      READ TABLE lt_ekpo INTO ls_ekpo
        WITH KEY ebeln = <lf_header>-ebeln
                 ebelp = <lf_header>-ebelp
                 matnr = <lf_header>-matnr
                 werks = <lf_header>-werks
                 lgort = <lf_header>-lgort
        BINARY SEARCH.

      IF sy-subrc IS INITIAL.

        <lf_header>-txz01 = ls_ekpo-txz01.

      ELSE.

        READ TABLE lt_ekpo INTO ls_ekpo
          WITH KEY ebeln = <lf_header>-ebeln
                   ebelp = <lf_header>-ebelp
                   matnr = <lf_header>-matnr
                   werks = <lf_header>-werks
                   lgort = space
          BINARY SEARCH.

        IF sy-subrc IS INITIAL.
          <lf_header>-txz01 = ls_ekpo-txz01.
        ENDIF.

      ENDIF.

    ENDLOOP.

    CLEAR lt_ekpo[].

  ENDIF.

*---------------------------------------------------------------------*
* Lấy header
*---------------------------------------------------------------------*
  READ TABLE gt_predata INTO gs_header INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* LAY THONG TIN ONE TIME CUSTOMER
*---------------------------------------------------------------------*
  SELECT
    kunnr
    xcpdk
    INTO TABLE gt_kna1
    FROM kna1
    FOR ALL ENTRIES IN gt_predata
    WHERE kunnr EQ gt_predata-lifnr
       OR kunnr EQ gt_predata-kunnr.

*---------------------------------------------------------------------*
* LAY THONG TIN BATCH
*---------------------------------------------------------------------*
  SELECT
    mch1~matnr
    mch1~charg
    mch1~qndat
    ausp~atwrt
    INTO CORRESPONDING FIELDS OF TABLE gt_mch1
    FROM mch1
      INNER JOIN ausp
        ON mch1~cuobj_bm EQ ausp~objek
    FOR ALL ENTRIES IN gt_predata
    WHERE mch1~matnr EQ gt_predata-matnr.

*---------------------------------------------------------------------*
* LAY THONG TIN NHA SAN XUAT TRUONG HOP EMATN TON TAI
*---------------------------------------------------------------------*
  DATA lt_tmp TYPE TABLE OF zwm_st_bbknhh.

  lt_tmp[] = gt_predata[].

  DELETE lt_tmp WHERE ematn IS INITIAL.

  IF lt_tmp IS NOT INITIAL.

    SELECT
      mara~matnr
      mara~mfrnr
      adrc~country
      INTO TABLE gt_mara
      FROM mara
        INNER JOIN lfa1
          ON mara~mfrnr EQ lfa1~lifnr
        INNER JOIN adrc
          ON adrc~addrnumber EQ lfa1~adrnr
      FOR ALL ENTRIES IN lt_tmp
      WHERE mara~matnr EQ lt_tmp-ematn.

  ENDIF.

*---------------------------------------------------------------------*
* LAY THONG TIN NUOC SAN XUAT UPDATE 04.02.15
*---------------------------------------------------------------------*
  SELECT
    lfa1~lifnr
    adrc~country
    INTO TABLE gt_lfa1
    FROM lfa1
      INNER JOIN adrc
        ON adrc~addrnumber EQ lfa1~adrnr
    FOR ALL ENTRIES IN gt_predata
    WHERE lfa1~lifnr EQ gt_predata-mfrnr.

ENDFORM.                    " FILL_DATA

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_DATA
*&---------------------------------------------------------------------*
FORM build_alv_data .

  CLEAR gt_alv.

  SORT gt_predata BY mblnr.

  LOOP AT gt_predata INTO gs_predata.

    AT NEW mblnr.

      CLEAR gs_alv.

      gs_alv-docno = gs_predata-mblnr.

      IF gs_predata-le_vbeln IS NOT INITIAL.
        gs_alv-docno2 = gs_predata-le_vbeln.
      ELSEIF gs_predata-vbeln_im IS NOT INITIAL.
        gs_alv-docno2 = gs_predata-vbeln_im.
      ENDIF.

      gs_alv-doc_type = 'Chứng từ vật tư'.

      IF gs_predata-lifnr IS NOT INITIAL.
        gs_alv-partner = gs_predata-lifnr.
      ELSEIF gs_predata-kunnr IS NOT INITIAL.
        gs_alv-partner = gs_predata-kunnr.
      ENDIF.

      gs_alv-lfdat = gs_predata-budat.
      gs_alv-werks = gs_predata-werks.

      IF p_src_a = 'X'.
        gs_alv-source = 'A'.
      ELSE.
        gs_alv-source = 'B'.
      ENDIF.

    ENDAT.

    gs_alv-item_count = gs_alv-item_count + 1.

    AT END OF mblnr.

      APPEND gs_alv TO gt_alv.

      CLEAR gs_alv.

    ENDAT.

  ENDLOOP.

ENDFORM.                    " BUILD_ALV_DATA

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV
*&---------------------------------------------------------------------*
FORM display_alv .

  DATA:
    lo_functions  TYPE REF TO cl_salv_functions_list,
    lo_selections TYPE REF TO cl_salv_selections,
    lo_columns    TYPE REF TO cl_salv_columns_table,
    lo_column     TYPE REF TO cl_salv_column_table.

  IF gt_alv IS INITIAL.
    RETURN.
  ENDIF.

  CLEAR go_alv.

  TRY.

      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_alv
        CHANGING
          t_table      = gt_alv ).

    CATCH cx_salv_msg.

      MESSAGE 'Không thể khởi tạo ALV.' TYPE 'E'.
      RETURN.

  ENDTRY.

  lo_functions = go_alv->get_functions( ).
  lo_functions->set_all( abap_true ).

  lo_selections = go_alv->get_selections( ).

  lo_selections->set_selection_mode(
    if_salv_c_selection_mode=>multiple ).

  lo_columns = go_alv->get_columns( ).
  lo_columns->set_optimize( abap_true ).

*---------------------------------------------------------------------*
* Ẩn field kỹ thuật SEL
*---------------------------------------------------------------------*
  TRY.

      lo_column ?= lo_columns->get_column( 'SEL' ).
      lo_column->set_visible( abap_false ).

    CATCH cx_salv_not_found.
  ENDTRY.

*---------------------------------------------------------------------*
* Đặt tiêu đề cột
*---------------------------------------------------------------------*
  TRY.

      lo_column ?= lo_columns->get_column( 'DOCNO' ).
      lo_column->set_short_text( 'Chứng từ' ).
      lo_column->set_medium_text( 'Số chứng từ' ).
      lo_column->set_long_text( 'Số chứng từ' ).

      lo_column ?= lo_columns->get_column( 'DOCNO2' ).
      lo_column->set_short_text( 'CTTC' ).
      lo_column->set_medium_text( 'Chứng từ tham chiếu' ).
      lo_column->set_long_text( 'Chứng từ tham chiếu' ).

      lo_column ?= lo_columns->get_column( 'DOC_TYPE' ).
      lo_column->set_short_text( 'Loại CT' ).
      lo_column->set_medium_text( 'Loại chứng từ' ).
      lo_column->set_long_text( 'Loại chứng từ' ).

      lo_column ?= lo_columns->get_column( 'PARTNER' ).
      lo_column->set_short_text( 'Đối tác' ).
      lo_column->set_medium_text( 'Nhà cung cấp/KH' ).
      lo_column->set_long_text( 'Nhà cung cấp/KH' ).

      lo_column ?= lo_columns->get_column( 'NAME' ).
      lo_column->set_short_text( 'Tên' ).
      lo_column->set_medium_text( 'Tên đối tác' ).
      lo_column->set_long_text( 'Tên đối tác' ).

      lo_column ?= lo_columns->get_column( 'LFDAT' ).
      lo_column->set_short_text( 'Ngày' ).
      lo_column->set_medium_text( 'Ngày chứng từ' ).
      lo_column->set_long_text( 'Ngày chứng từ' ).

      lo_column ?= lo_columns->get_column( 'ITEM_COUNT' ).
      lo_column->set_short_text( 'SL dòng' ).
      lo_column->set_medium_text( 'Số dòng' ).
      lo_column->set_long_text( 'Số dòng chi tiết' ).

      lo_column ?= lo_columns->get_column( 'GR_STATUS' ).
      lo_column->set_short_text( 'Trạng thái' ).
      lo_column->set_medium_text( 'Trạng thái GR' ).
      lo_column->set_long_text( 'Trạng thái nhập kho' ).

      lo_column ?= lo_columns->get_column( 'TRAID' ).
      lo_column->set_short_text( 'Số xe' ).
      lo_column->set_medium_text( 'Số xe vận chuyển' ).
      lo_column->set_long_text( 'Số xe vận chuyển' ).

      lo_column ?= lo_columns->get_column( 'PRINT_COUNT' ).
      lo_column->set_short_text( 'Đã in' ).
      lo_column->set_medium_text( 'Số lần in' ).
      lo_column->set_long_text( 'Số lần đã in' ).

      lo_column ?= lo_columns->get_column( 'WERKS' ).
      lo_column->set_short_text( 'Plant' ).
      lo_column->set_medium_text( 'Plant' ).
      lo_column->set_long_text( 'Plant' ).

      lo_column ?= lo_columns->get_column( 'SOURCE' ).
      lo_column->set_short_text( 'Nguồn' ).
      lo_column->set_medium_text( 'Nguồn chứng từ' ).
      lo_column->set_long_text( 'Nguồn chứng từ' ).

    CATCH cx_salv_not_found.

  ENDTRY.

  go_alv->display( ).

ENDFORM.                    " DISPLAY_ALV

*&---------------------------------------------------------------------*
*&      Form  GET_SELECTED_DOCUMENTS
*&---------------------------------------------------------------------*
FORM get_selected_documents .

  DATA:
    lt_rows  TYPE salv_t_row,
    lv_row   TYPE salv_de_row,
    lv_mblnr TYPE mblnr.

  RANGES:
    lr_mblnr FOR matdoc-mblnr.

  CLEAR:
    gv_selected_count,
    lr_mblnr[].

  IF go_alv IS INITIAL.
    RETURN.
  ENDIF.

  lt_rows = go_alv->get_selections( )->get_selected_rows( ).

  LOOP AT lt_rows INTO lv_row.

    READ TABLE gt_alv INTO gs_alv INDEX lv_row.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_mblnr = gs_alv-docno.

    IF lv_mblnr IS INITIAL.
      CONTINUE.
    ENDIF.

    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = lv_mblnr ) TO lr_mblnr.

    gs_alv-sel = abap_true.

    MODIFY gt_alv FROM gs_alv INDEX lv_row.

  ENDLOOP.

  SORT lr_mblnr BY low.
  DELETE ADJACENT DUPLICATES FROM lr_mblnr COMPARING low.

  gv_selected_count = lines( lr_mblnr ).

  IF gv_selected_count IS INITIAL.
    RETURN.
  ENDIF.

  DELETE gt_predata WHERE mblnr NOT IN lr_mblnr.

  IF gt_predata IS INITIAL.
    CLEAR gv_selected_count.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* Header phải lấy lại sau khi đã lọc theo các chứng từ được chọn
*---------------------------------------------------------------------*
  CLEAR gs_header.

  READ TABLE gt_predata INTO gs_header INDEX 1.

  IF sy-subrc <> 0.
    CLEAR gv_selected_count.
    RETURN.
  ENDIF.

  gv_current_docno = gs_header-mblnr.
  gv_current_docno2 = gs_header-le_vbeln.

  IF p_src_a = 'X'.
    gv_current_source = 'A'.
  ELSE.
    gv_current_source = 'B'.
  ENDIF.

ENDFORM.                    " GET_SELECTED_DOCUMENTS

*&---------------------------------------------------------------------*
*&      Form  DATA_PROCESSING
*&---------------------------------------------------------------------*
FORM data_processing .

  DATA:
    lw_number_temp    TYPE char10,
    lw_quy_cach_batch TYPE char255,
    lw_quy_cach       TYPE char255,
    lw_z_nsx          TYPE char10,
    gw_number         TYPE char10,
    lw_movetype       TYPE char5,
    lw_tdname         TYPE tdobname,
    lw_ut2            TYPE lty_lfa1_ut2,
    lt_documents      TYPE TABLE OF acc_doc,
    ls_documents      TYPE acc_doc,
    lw_belnr          TYPE belnr_d,
    lw_aworg          TYPE acchd-aworg.

*---------------------------------------------------------------------*
* Goi fucntion module lay ten cong ty, dia chi, telephone, fax
*---------------------------------------------------------------------*
  lw_number_temp = gs_header-bukrs.

  CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
    EXPORTING
      i_number     = lw_number_temp
      i_kind       = 'C'
    IMPORTING
      e_name       = gs_parameter-name
      e_address    = gs_parameter-address
      e_tel_number = gs_parameter-tel_number
      e_fax_number = gs_parameter-fax_number
      e_remark     = gs_parameter-email
      e_tax        = gs_parameter-tax.

  CLEAR lw_number_temp.

  CONCATENATE 'MST: ' gs_parameter-tax
    INTO gs_parameter-tax
    SEPARATED BY space.

  CONCATENATE 'Website:' gs_parameter-email
    INTO gs_parameter-email
    SEPARATED BY space.

  CONCATENATE 'Điện thoại:' gs_parameter-tel_number
    INTO gs_parameter-tel_number
    SEPARATED BY space.

  CONCATENATE 'Fax:' gs_parameter-fax_number
    INTO gs_parameter-fax_number
    SEPARATED BY space.

  CONCATENATE
    'Ngày'
    gs_header-budat+06(02)
    'tháng'
    gs_header-budat+04(02)
    'năm'
    gs_header-budat(04)
    INTO gs_parameter-header01
    SEPARATED BY space.

*---------------------------------------------------------------------*
* TAO THONG TIN DE LAY CHARACTERISTIC
*---------------------------------------------------------------------*
  CLEAR gt_atnam.

  gs_atnam-sign = 'I'.
  gs_atnam-option = 'EQ'.
  gs_atnam-low = 'Z_BAO_QUAN_BATCH'.
  APPEND gs_atnam TO gt_atnam.
  CLEAR gs_atnam.

  gs_atnam-sign = 'I'.
  gs_atnam-option = 'EQ'.
  gs_atnam-low = 'Z_BAO_QUAN_TPHH'.
  APPEND gs_atnam TO gt_atnam.
  CLEAR gs_atnam.

  gs_atnam-sign = 'I'.
  gs_atnam-option = 'EQ'.
  gs_atnam-low = 'LOBM_HSDAT'.
  APPEND gs_atnam TO gt_atnam.
  CLEAR gs_atnam.

  gs_atnam-sign = 'I'.
  gs_atnam-option = 'EQ'.
  gs_atnam-low = 'LOBM_VFDAT'.
  APPEND gs_atnam TO gt_atnam.
  CLEAR gs_atnam.

  gs_atnam-sign = 'I'.
  gs_atnam-option = 'EQ'.
  gs_atnam-low = 'Z_BATCH_NSX'.
  APPEND gs_atnam TO gt_atnam.
  CLEAR gs_atnam.

  gs_atnam-sign = 'I'.
  gs_atnam-option = 'EQ'.
  gs_atnam-low = 'Z_QUY_CACH_BATCH'.
  APPEND gs_atnam TO gt_atnam.
  CLEAR gs_atnam.

  gs_atnam-sign = 'I'.
  gs_atnam-option = 'EQ'.
  gs_atnam-low = 'Z_QUYCACH'.
  APPEND gs_atnam TO gt_atnam.
  CLEAR gs_atnam-low.

  CLEAR gs_atnam-low.
  gs_atnam-low = 'Z_NUOC_SX'.
  APPEND gs_atnam TO gt_atnam.

  CLEAR gs_atnam-low.
  gs_atnam-low = 'Z_NSX'.
  APPEND gs_atnam TO gt_atnam.

*---------------------------------------------------------------------*
* PROCESS DETAIL
*---------------------------------------------------------------------*
  LOOP AT gt_predata ASSIGNING <fs_pre_data>.

*---------------------------------------------------------------------*
* LAY THONG TIN SO HOA DON VA NGAY HOA DON
*---------------------------------------------------------------------*
    CONCATENATE
      <fs_pre_data>-bwart
      <fs_pre_data>-sobkz
      INTO lw_movetype.

    IF lw_movetype(01) EQ '6'
       OR lw_movetype EQ 'Z18'
       OR lw_movetype EQ 'Z19'
       OR lw_movetype EQ 'Z20'.

*---------------------------------------------------------------------*
* LAY THONG TIN SO HOA DON
*---------------------------------------------------------------------*
      lw_tdname = gs_header-le_vbeln.

      CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
        EXPORTING
          i_tdid      = 'ZLF1'
          i_tdname    = lw_tdname
          i_tdobject  = 'VBBK'
          i_tdspras   = sy-langu
        IMPORTING
          e_long_text = gw_sohd.

*---------------------------------------------------------------------*
* LAY THONG TIN NGAY HOA DON
*---------------------------------------------------------------------*
      CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
        EXPORTING
          i_tdid      = 'ZLF2'
          i_tdname    = lw_tdname
          i_tdobject  = 'VBBK'
          i_tdspras   = sy-langu
        IMPORTING
          e_long_text = gw_ngayhd.

      CONCATENATE
        gw_sohd
        gw_ngayhd
        INTO <fs_pre_data>-shd_nhd
        SEPARATED BY space.

      CLEAR:
        gw_sohd,
        gw_ngayhd,
        lw_tdname.

    ELSE.

      IF <fs_pre_data>-bktxt IS NOT INITIAL.

        WRITE <fs_pre_data>-bldat TO gw_bldat
          USING EDIT MASK '__.__.____'.

        CONCATENATE
          <fs_pre_data>-bktxt
          gw_bldat
          INTO <fs_pre_data>-shd_nhd
          SEPARATED BY space.

      ENDIF.

    ENDIF.

*---------------------------------------------------------------------*
* LAY THONG TIN NGUOI VAN CHUYEN
*---------------------------------------------------------------------*
    IF gs_header-ablad IS INITIAL.
      gs_header-ablad = <fs_pre_data>-ablad.
    ENDIF.

*---------------------------------------------------------------------*
* LAY THONG TIN SO THU TU
*---------------------------------------------------------------------*
    SHIFT <fs_pre_data>-zeile LEFT DELETING LEADING '0'.

    <fs_pre_data>-stt = <fs_pre_data>-zeile.

*---------------------------------------------------------------------*
* LAY THONG TIN SO LO
*---------------------------------------------------------------------*
    IF <fs_pre_data>-charg IS INITIAL.

      READ TABLE gt_mch1 INTO gs_mch1
        WITH TABLE KEY
          matnr = <fs_pre_data>-matnr
          atwrt = <fs_pre_data>-mblnr.

      IF sy-subrc = 0.
        <fs_pre_data>-charg = gs_mch1-charg.
      ENDIF.

    ENDIF.

    gw_charg = <fs_pre_data>-charg.

    CALL FUNCTION 'ZCORE_FM_GET_CRTRT_MULTIVAL'
      EXPORTING
        i_charg           = gw_charg
        i_matnr           = <fs_pre_data>-matnr
      IMPORTING
        ez_bao_quan_batch = <fs_pre_data>-ghichu
        ez_bao_quan_tphh  = lw_ghichu
        elobm_hsdat       = <fs_pre_data>-ngaysx
        elobm_vfdat       = <fs_pre_data>-handung
        ez_batch_nsx      = <fs_pre_data>-solo
        ez_quy_cach_batch = lw_quy_cach_batch
        ez_quycach        = lw_quy_cach
        ez_nsx            = lw_z_nsx
        ez_nuoc_sx        = lw_nuosx
      TABLES
        it_atnam          = gt_atnam.

*---------------------------------------------------------------------*
* TAMNTT UPDATE NGAYSX HANDUNG 21.09.2018
*---------------------------------------------------------------------*
    IF <fs_pre_data>-ngaysx IS INITIAL
       AND <fs_pre_data>-handung IS INITIAL.

      SELECT SINGLE
        hsdat
        vfdat
        FROM mch1
        INTO (
          <fs_pre_data>-ngaysx,
          <fs_pre_data>-handung
        )
        WHERE matnr = <fs_pre_data>-matnr
          AND charg = <fs_pre_data>-charg.

    ENDIF.

*---------------------------------------------------------------------*
* TUANNQ / UPDATE CHI TIEU HAN DUNG
*---------------------------------------------------------------------*
    IF p_thugn EQ 'X'
       OR p_khac EQ 'X'.

      gs_parameter-parameter13 = 'Hạn dùng/ Ngày KNL'.

      IF <fs_pre_data>-handung IS INITIAL.

        READ TABLE gt_mch1 INTO gs_mch1
          WITH KEY
            matnr = <fs_pre_data>-matnr
            charg = <fs_pre_data>-charg.

        IF sy-subrc EQ 0.
          <fs_pre_data>-handung = gs_mch1-qndat.
        ENDIF.

      ENDIF.

    ENDIF.

*---------------------------------------------------------------------*
* QUY CACH
*---------------------------------------------------------------------*
    IF lw_quy_cach_batch IS NOT INITIAL.

      <fs_pre_data>-groes = lw_quy_cach_batch.

    ELSEIF lw_quy_cach IS NOT INITIAL.

      <fs_pre_data>-groes = lw_quy_cach.

    ENDIF.

*---------------------------------------------------------------------*
* UPDATE QUY CACH
*---------------------------------------------------------------------*
    IF ( <fs_pre_data>-werks = '5000'
         AND <fs_pre_data>-bwart = '305' )
       OR
       ( <fs_pre_data>-bwart = '301'
         AND <fs_pre_data>-werks = '2000' ).

      <fs_pre_data>-groes = <fs_pre_data>-ablad.
      gs_header-ablad = ''.

    ENDIF.

    CLEAR:
      lw_quy_cach,
      lw_quy_cach_batch.

    IF <fs_pre_data>-solo IS INITIAL.
      <fs_pre_data>-solo = gw_charg.
    ENDIF.

*---------------------------------------------------------------------*
* LAY THONG TIN NHA CUNG CAP / CUSTOMER
*---------------------------------------------------------------------*
    IF <fs_pre_data>-lifnr IS NOT INITIAL.

      lw_number_temp = <fs_pre_data>-lifnr.

    ELSE.

      lw_number_temp = <fs_pre_data>-kunnr.

    ENDIF.

    gw_nhacungcap = lw_number_temp.

    READ TABLE gt_kna1 INTO gs_kna1
      WITH KEY kunnr = lw_number_temp.

    IF gs_kna1-xcpdk IS NOT INITIAL.

*---------------------------------------------------------------------*
* LAY THONG TIN ONE TIME CUSTOMER
*---------------------------------------------------------------------*
      CALL FUNCTION 'ZCORE_FM_GET_PROFILE_SD'
        EXPORTING
          i_number = lw_number_temp
          i_vbeln  = <fs_pre_data>-vbeln_im
          i_type   = 'WE'
        IMPORTING
          e_name   = gw_name.

      CLEAR:
        gs_kna1,
        lw_number_temp,
        ls_documents,
        lw_belnr,
        lw_aworg.

    ELSE.

      IF <fs_pre_data>-lifnr IS NOT INITIAL.

        lw_number_temp = <fs_pre_data>-lifnr.

        CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
          EXPORTING
            i_number = lw_number_temp
            i_kind   = 'K'
          IMPORTING
            e_name   = gw_name.

      ELSEIF <fs_pre_data>-kunnr IS NOT INITIAL.

        lw_number_temp = <fs_pre_data>-kunnr.

        CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
          EXPORTING
            i_number = lw_number_temp
            i_kind   = 'D'
          IMPORTING
            e_name   = gw_name.

        <fs_pre_data>-wempf = space.
        gs_header-xblnr = space.

      ENDIF.

    ENDIF.

*---------------------------------------------------------------------*
* LAY THONG TIN NHA CUNG CAP
*---------------------------------------------------------------------*
    SHIFT gw_nhacungcap LEFT DELETING LEADING '0'.

    IF gw_nhacungcap IS NOT INITIAL
       AND <fs_pre_data>-mblnr IS NOT INITIAL.

      IF <fs_pre_data>-bwart EQ '103'.

        CONCATENATE
          gw_nhacungcap
          '-'
          gw_name
          '-'
          <fs_pre_data>-mblnr
          'Nhập kho GR blocked Stock'
          INTO <fs_pre_data>-table_header
          SEPARATED BY space.

      ELSE.

        CONCATENATE
          gw_nhacungcap
          '-'
          gw_name
          '-'
          <fs_pre_data>-mblnr
          INTO <fs_pre_data>-table_header
          SEPARATED BY space.

      ENDIF.

    ELSE.

      <fs_pre_data>-table_header = <fs_pre_data>-mblnr.

    ENDIF.

    CLEAR:
      lw_number_temp,
      gw_nhacungcap.

*---------------------------------------------------------------------*
* LAY THONG TIN NHA SAN XUAT
*---------------------------------------------------------------------*
    gw_number = lw_z_nsx.

    SHIFT gw_number RIGHT DELETING TRAILING space.

    TRANSLATE gw_number USING ' 0'.

    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        i_number = gw_number
        i_kind   = 'K'
      IMPORTING
        e_name   = lw_nhasx.

    CLEAR gw_number.

    IF lw_nhasx IS NOT INITIAL
       AND lw_nuosx IS NOT INITIAL.

      CONCATENATE
        lw_nhasx
        '-'
        lw_nuosx
        INTO <fs_pre_data>-nsxns
        SEPARATED BY space.

    ELSEIF lw_nhasx IS NOT INITIAL.

      <fs_pre_data>-nsxns = lw_nhasx.

    ELSE.

      <fs_pre_data>-nsxns = lw_nuosx.

    ENDIF.

    CLEAR:
      lw_nhasx,
      lw_nuosx,
      lw_z_nsx.

    <fs_pre_data>-level = 2.

  ENDLOOP.

*---------------------------------------------------------------------*
* MERGE THONG TIN
*---------------------------------------------------------------------*
  CLEAR:
    gt_data,
    lw_mblnr,
    lw_soluonghd,
    lw_soluongtt.

  SORT gt_predata BY lifnr mblnr matnr solo.

  LOOP AT gt_predata INTO gs_predata.

    gs_data = gs_predata.

    IF lw_mblnr <> gs_data-mblnr.

      lw_mblnr = gs_data-mblnr.

      gs_data-level = '1'.

      APPEND gs_data TO gt_data.

    ENDIF.

    lw_soluonghd = lw_soluonghd + gs_predata-lsmng.
    lw_soluongtt = lw_soluongtt + gs_predata-erfmg.

    AT END OF solo.

      gs_data-lsmng = lw_soluonghd.
      gs_data-erfmg = lw_soluongtt.
      gs_data-level = '2'.

      APPEND gs_data TO gt_data.

      CLEAR:
        gs_data,
        gs_predata,
        lw_soluonghd,
        lw_soluongtt.

    ENDAT.

  ENDLOOP.

*---------------------------------------------------------------------*
* LAY MOVEMENT TYPE HEADER
*---------------------------------------------------------------------*
  CONCATENATE
    gs_header-bwart
    gs_header-sobkz
    INTO lw_movetype.

  IF lw_movetype(01) EQ '6'
     OR lw_movetype EQ 'Z18'
     OR lw_movetype EQ 'Z19'
     OR lw_movetype EQ 'Z20'.

*---------------------------------------------------------------------*
* LAY THONG TIN NGUOI KIEM NHAN
*---------------------------------------------------------------------*
    lw_tdname = gs_header-le_vbeln.

    CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
      EXPORTING
        i_tdid      = 'ZLF3'
        i_tdname    = lw_tdname
        i_tdobject  = 'VBBK'
        i_tdspras   = sy-langu
      IMPORTING
        e_long_text = gw_ngkiemnhan.

    gs_header-xblnr = gw_ngkiemnhan.

*---------------------------------------------------------------------*
* LAY THONG TIN NGUOI VAN CHUYEN
*---------------------------------------------------------------------*
    CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
      EXPORTING
        i_tdid      = 'ZLF4'
        i_tdname    = lw_tdname
        i_tdobject  = 'VBBK'
        i_tdspras   = sy-langu
      IMPORTING
        e_long_text = gw_ngvanchuyen.

    gs_header-frbnr = gw_ngvanchuyen.

*---------------------------------------------------------------------*
* LAY THONG TIN NGUOI GIAO HANG
*---------------------------------------------------------------------*
    CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
      EXPORTING
        i_tdid      = 'ZLF5'
        i_tdname    = lw_tdname
        i_tdobject  = 'VBBK'
        i_tdspras   = sy-langu
      IMPORTING
        e_long_text = gw_nggiaohang.

    gs_header-ablad = gw_nggiaohang.

*---------------------------------------------------------------------*
* LAY THONG TIN SO XE VAN CHUYEN
*---------------------------------------------------------------------*
    CALL FUNCTION 'ZCORE_FM_GET_LONG_TEXT'
      EXPORTING
        i_tdid      = 'ZLF6'
        i_tdname    = lw_tdname
        i_tdobject  = 'VBBK'
        i_tdspras   = sy-langu
      IMPORTING
        e_long_text = gw_soxe.

    gs_header-xabln = gw_soxe.

    CLEAR:
      lw_tdname,
      gw_soxe.

  ENDIF.

*---------------------------------------------------------------------*
* Tuanpt17/24.04.2023/Update NGUOI KIEM NHAN
*---------------------------------------------------------------------*
  IF lw_movetype EQ '305'.
    gs_header-xblnr = ' '.
  ENDIF.

*---------------------------------------------------------------------*
* LAY THONG TIN NGUOI GIAO HANG, NGUOI KIEM NHAN
*---------------------------------------------------------------------*
  PERFORM convert_firstchars_toupper
    USING gs_header-xblnr
    CHANGING gs_header-xblnr.

  PERFORM convert_firstchars_toupper
    USING gs_header-frbnr
    CHANGING gs_header-frbnr.

*---------------------------------------------------------------------*
* LAY THONG TIN NGUOI VAN CHUYEN
*---------------------------------------------------------------------*
  PERFORM convert_firstchars_toupper
    USING gs_header-ablad
    CHANGING gs_header-ablad.

  SORT gt_data BY lifnr mblnr level stt.

ENDFORM.                    " DATA_PROCESSING

*&---------------------------------------------------------------------*
*&      Form  EXPORT_DATA
*&---------------------------------------------------------------------*
FORM export_data .

  DATA:
    p_form    TYPE tdsfname,
    fm_name   TYPE rs38l_fnam,
    wa_cparam TYPE ssfctrlop,
    wa_output TYPE ssfcompop.

  wa_cparam-no_dialog = 'X'.
  wa_cparam-preview   = 'X'.

  wa_output-tddest   = 'LP01'.
  wa_output-tdnoprev = 'X'.
  wa_output-tdimmed  = 'X'.
  wa_output-tddelete = 'X'.

  p_form = 'ZWM_SF_BBKNHH'.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = p_form
    IMPORTING
      fm_name            = fm_name
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.

    MESSAGE ID sy-msgid
      TYPE sy-msgty
      NUMBER sy-msgno
      WITH sy-msgv1
           sy-msgv2
           sy-msgv3
           sy-msgv4.

    RETURN.

  ENDIF.

  CALL FUNCTION fm_name
    EXPORTING
      control_parameters = wa_cparam
      output_options     = wa_output
      user_settings      = space
      gs_parameter       = gs_parameter
      gs_header          = gs_header
    TABLES
      it_data            = gt_data
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.

  IF sy-subrc <> 0.

    MESSAGE ID sy-msgid
      TYPE sy-msgty
      NUMBER sy-msgno
      WITH sy-msgv1
           sy-msgv2
           sy-msgv3
           sy-msgv4.

  ENDIF.

ENDFORM.                    " EXPORT_DATA

*&---------------------------------------------------------------------*
*&      Form  F4_HELP_MBLNR
*&---------------------------------------------------------------------*
FORM f4_help_mblnr .

  DATA:
    flag TYPE c LENGTH 1.

  flag = 'X'.

  EXPORT flag TO MEMORY ID 'MB51_FLAG'.

  CALL TRANSACTION 'MB51'.

  GET PARAMETER ID 'MBN' FIELD s_mblnr-low.

ENDFORM.                    " F4_HELP_MBLNR

*&---------------------------------------------------------------------*
*&      Form  CHECK_REQUIRE
*&---------------------------------------------------------------------*
FORM check_require .

* Theo đặc tả mới:
* - Lệnh nhập kho: không bắt buộc
* - Ngày giao hàng dự kiến: không bắt buộc
* - Chứng từ nhập kho: không bắt buộc
* - Năm chứng từ: bắt buộc
* - Ngày nhập kho: không bắt buộc
* - Nhà cung cấp: không bắt buộc
* - Khách hàng: không bắt buộc
* - Plant: không bắt buộc
* - Storage Location: không bắt buộc
* - Số xe vận chuyển: không bắt buộc
*
* p_mjahr đã được khai báo OBLIGATORY trên selection-screen.
* Vì vậy không cần kiểm tra bắt buộc thêm ở đây.

ENDFORM.                    " CHECK_REQUIRE
*&---------------------------------------------------------------------*
*&      Form  CONVERT_FIRSTCHARS_TOUPPER
*&---------------------------------------------------------------------*
FORM convert_firstchars_toupper
  USING
    input_string
  CHANGING
    output_string.

  DATA:
    lv_input      TYPE string,
    lv_output     TYPE string,
    lv_char       TYPE c LENGTH 1,
    lv_prev_char  TYPE c LENGTH 1,
    lv_length     TYPE i,
    lv_index      TYPE i,
    lv_prev_index TYPE i.

  CONSTANTS:
    lc_separators TYPE string VALUE ` -.,;:`.

  CLEAR output_string.

  IF input_string IS INITIAL.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* Chuyển input sang STRING
*---------------------------------------------------------------------*
  lv_input = input_string.

*---------------------------------------------------------------------*
* Đưa toàn bộ về chữ thường
*---------------------------------------------------------------------*
  TRANSLATE lv_input TO LOWER CASE.

  lv_length = strlen( lv_input ).

  IF lv_length = 0.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* Ký tự đầu tiên viết hoa
*---------------------------------------------------------------------*
  lv_char = lv_input+0(1).

  TRANSLATE lv_char TO UPPER CASE.

  lv_output = lv_char.

*---------------------------------------------------------------------*
* Xử lý các ký tự còn lại
*---------------------------------------------------------------------*
  DO lv_length - 1 TIMES.

    lv_index = sy-index.

    lv_prev_index = lv_index - 1.

*---------------------------------------------------------------------*
* Lấy ký tự ngay trước
*---------------------------------------------------------------------*
    lv_prev_char = lv_input+lv_prev_index(1).

*---------------------------------------------------------------------*
* Lấy ký tự hiện tại
*---------------------------------------------------------------------*
    lv_char = lv_input+lv_index(1).

*---------------------------------------------------------------------*
* Nếu ký tự trước là separator thì viết hoa ký tự hiện tại
*---------------------------------------------------------------------*
    IF lc_separators CS lv_prev_char.

      TRANSLATE lv_char TO UPPER CASE.

    ENDIF.

*---------------------------------------------------------------------*
* Ghép vào kết quả
*---------------------------------------------------------------------*
    CONCATENATE
      lv_output
      lv_char
      INTO lv_output
      IN CHARACTER MODE.

  ENDDO.

*---------------------------------------------------------------------*
* Trả kết quả
*---------------------------------------------------------------------*
  output_string = lv_output.

ENDFORM.                    " CONVERT_FIRSTCHARS_TOUPPER

*
*
