*&---------------------------------------------------------------------*
*& Report  ZWM_PG_PXK_TEST
*& Program Title  Test Smart Form phiếu xuất kho (ZWM04) bằng dữ liệu mẫu
*&---------------------------------------------------------------------*
* Chỉ dùng để xem thử form in: không đọc chứng từ kho, không ghi ZTWM_PRTLOG.
* GS_PARAMETER và IT_DATA dựng giống FORM GET_PARAMETER / FILL_FORM / FILL_FORM_LINES
* của ZWM_PG_PXK nên layout in ra giống khi in thật. Header đơn vị đọc thật từ
* ZCORE_FM_GET_PROFILE theo Plant; không có thì dùng chữ mẫu.
*&---------------------------------------------------------------------*

REPORT zwm_pg_pxk_test.

CONSTANTS:
  gc_form_op1 TYPE tdsfname VALUE 'ZWM_SF_PXK',
  gc_form_op2 TYPE tdsfname VALUE 'ZWM_SF_PXK_OP2',
  gc_form_op4 TYPE tdsfname VALUE 'ZWM_SF_PXK_OP4',
  gc_logo     TYPE char50   VALUE 'ZLOGO_0001'.

*---------------------------------------------------------------------*
* SELECTION-SCREEN
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bl_lay WITH FRAME TITLE TEXT-001.

  PARAMETERS:
    p_op1 RADIOBUTTON GROUP lay DEFAULT 'X',
    p_op2 RADIOBUTTON GROUP lay,
    p_op3 RADIOBUTTON GROUP lay,
    p_op4 RADIOBUTTON GROUP lay.

SELECTION-SCREEN END OF BLOCK bl_lay.

SELECTION-SCREEN BEGIN OF BLOCK bl_opt WITH FRAME TITLE TEXT-002.

  PARAMETERS:
    p_isn   AS CHECKBOX,
    p_bq    AS CHECKBOX DEFAULT 'X',
    p_adj   AS CHECKBOX,
    p_prev  AS CHECKBOX DEFAULT 'X',
    p_rows  TYPE i DEFAULT 5,
    p_sheet TYPE i DEFAULT 1,
    p_cnt   TYPE i DEFAULT 0,
    p_werks TYPE werks_d DEFAULT '1000'.

SELECTION-SCREEN END OF BLOCK bl_opt.

*---------------------------------------------------------------------*
* TYPES / DATA
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_partner,
    name    TYPE char255,
    address TYPE char255,
    tax     TYPE char255,
    tel     TYPE char255,
    fax     TYPE char255,
    remark  TYPE char255,
  END OF gty_partner,

* Dòng dữ liệu mẫu; HD_DAYS / KN_DAYS = số ngày cộng vào ngày chạy (0 = để trống)
  BEGIN OF gty_sample,
    matnr    TYPE matnr,
    maktx    TYPE maktx,
    maktx_en TYPE maktx,
    nodhl    TYPE char255,
    doam     TYPE char255,
    nsxns    TYPE char255,
    solo     TYPE char255,
    charg    TYPE charg_d,
    hd_days  TYPE i,
    kn_days  TYPE i,
    groes    TYPE char255,
    erfme    TYPE erfme,
    erfme_en TYPE msehl,
    erfmg    TYPE erfmg,
    baoquan  TYPE char255,
  END OF gty_sample,
  gtt_sample TYPE STANDARD TABLE OF gty_sample WITH EMPTY KEY.

DATA:
  gs_parameter TYPE zcore_st_parameter,
  gt_data      TYPE STANDARD TABLE OF zwm_st_pxk,
  gt_sample    TYPE gtt_sample,
  gs_plant     TYPE gty_partner,
  gs_plant_en  TYPE gty_partner,
  gs_comp      TYPE gty_partner,
  gv_bi        TYPE abap_bool.

CLASS lcl_util DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      lbl IMPORTING iv_vi          TYPE csequence
                    iv_en          TYPE csequence
          RETURNING VALUE(rv_text) TYPE string,
      lbl_c IMPORTING iv_vi          TYPE csequence
                      iv_en          TYPE csequence
            RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

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

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  IF p_rows < 1 OR p_rows > 200.
    MESSAGE |Số dòng thử phải từ 1 đến 200| TYPE 'E'.
  ENDIF.
  IF p_sheet < 1 OR p_sheet > 20.
    MESSAGE |Số phiếu thử phải từ 1 đến 20| TYPE 'E'.
  ENDIF.
  IF p_cnt < 0.
    MESSAGE |Số lần đã in không được âm| TYPE 'E'.
  ENDIF.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

  " Mẫu 4 luôn song ngữ
  gv_bi = xsdbool( p_isn = abap_true OR p_op4 = abap_true ).

  PERFORM get_company.
  PERFORM build_sample.
  PERFORM get_parameter.
  PERFORM print_forms.

*&---------------------------------------------------------------------*
*&      Form  GET_PROFILE
*&---------------------------------------------------------------------*
*       Đọc tên / địa chỉ Plant (P), Company Code (C) hoặc Plant tiếng Anh (iv_en).
*----------------------------------------------------------------------*
FORM get_profile USING iv_kind   TYPE char1
                       iv_number TYPE csequence
                       iv_en     TYPE abap_bool
                 CHANGING cs_partner TYPE gty_partner.

  DATA lv_num TYPE char10.

  CLEAR cs_partner.
  lv_num = iv_number.
  CHECK lv_num IS NOT INITIAL.

  IF iv_en = abap_true.
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        i_number  = lv_num
        i_kind    = 'P'
        i_nation  = 'I'
      IMPORTING
        e_name    = cs_partner-name
        e_address = cs_partner-address
      EXCEPTIONS
        OTHERS    = 1.
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
        e_remark     = cs_partner-remark
      EXCEPTIONS
        OTHERS       = 1.
  ENDIF.
  IF sy-subrc <> 0.
    CLEAR cs_partner.
  ENDIF.

ENDFORM.                    " GET_PROFILE

*&---------------------------------------------------------------------*
*&      Form  GET_COMPANY
*&---------------------------------------------------------------------*
*       Header đơn vị theo Plant, MST theo Company Code; thiếu thì điền chữ mẫu.
*----------------------------------------------------------------------*
FORM get_company .

  DATA lv_bukrs TYPE bukrs.

  CLEAR: gs_plant, gs_plant_en, gs_comp.

  IF p_werks IS NOT INITIAL.
    SELECT SINGLE k~bukrs
      FROM t001w AS w
      INNER JOIN t001k AS k ON k~bwkey = w~bwkey
      WHERE w~werks = @p_werks
      INTO @lv_bukrs.

    PERFORM get_profile USING 'P' p_werks abap_false CHANGING gs_plant.
    PERFORM get_profile USING 'C' lv_bukrs abap_false CHANGING gs_comp.
    IF gv_bi = abap_true.
      PERFORM get_profile USING 'Q' p_werks abap_true CHANGING gs_plant_en.
    ENDIF.
  ENDIF.

  IF gs_plant-name IS INITIAL.
    gs_plant-name    = 'Công ty cổ phần Dược - Trang thiết bị y tế Bình Định (dữ liệu mẫu)'.
    gs_plant-address = '498 Nguyễn Thái Học, phường Quy Nhơn, tỉnh Gia Lai'.
    gs_plant-tel     = '0256 000 0000'.
    gs_plant-fax     = '0256 000 0001'.
    gs_plant-remark  = 'www.example.vn'.
  ENDIF.
  IF gs_comp-tax IS INITIAL.
    gs_comp-tax = '4100259564'.
  ENDIF.
  IF gv_bi = abap_true AND gs_plant_en-name IS INITIAL.
    gs_plant_en-name    = 'Binh Dinh Pharmaceutical and Medical Equipment Joint Stock Company (sample)'.
    gs_plant_en-address = '498 Nguyen Thai Hoc Street, Quy Nhon Ward, Gia Lai Province'.
  ENDIF.

ENDFORM.                    " GET_COMPANY

*&---------------------------------------------------------------------*
*&      Form  BUILD_SAMPLE
*&---------------------------------------------------------------------*
*       Vòng lặp theo thứ tự; dòng cuối cố ý thiếu hết dữ liệu lô để xem ô trống.
*----------------------------------------------------------------------*
FORM build_sample .

  gt_sample = VALUE #(
    ( matnr = '000000000002100277' maktx = 'Paracetamol (Acetaminophen) BP' maktx_en = 'Paracetamol (Acetaminophen) BP'
      nodhl = '99,0 – 101,0 % (tính theo chế phẩm khan)' doam = '<= 0,5 %'
      nsxns = 'Anhui BBCA Pharmaceutical Co., Ltd - Trung Quốc'
      solo = 'PAR2610A' charg = 'AA6001' hd_days = 900 kn_days = 540
      groes = 'Thùng 25 kg' erfme = 'KG' erfme_en = 'Kilogram' erfmg = 25
      baoquan = 'Nơi khô mát, nhiệt độ dưới 30°C, tránh ánh sáng' )
    ( matnr = '000000000002500004' maktx = 'Tinh bột sắn' maktx_en = 'Tapioca starch'
      nodhl = 'Không áp dụng' doam = '12,5 %'
      nsxns = 'Công ty TNHH Tinh bột Việt Nam - Việt Nam'
      solo = 'TB-261012' charg = '121026' hd_days = 360 kn_days = 180
      groes = 'Bao 25 kg' erfme = 'KG' erfme_en = 'Kilogram' erfmg = '12.5'
      baoquan = 'Nơi khô ráo, thoáng mát' )
    ( matnr = '000000000002100301' maktx = 'Lactose monohydrat' maktx_en = 'Lactose monohydrate'
      nodhl = '99,5 %' doam = '5,0 %'
      nsxns = 'DFE Pharma GmbH & Co. KG - Đức'
      solo = 'LAC-2602' charg = 'AA6003' hd_days = 720 kn_days = 360
      groes = 'Bao 25 kg' erfme = 'KG' erfme_en = 'Kilogram' erfmg = 100
      baoquan = 'Nhiệt độ dưới 25°C' )
    ( matnr = '000000000002100455' maktx = 'Magnesi stearat' maktx_en = 'Magnesium stearate'
      nodhl = '4,0 – 5,0 % Mg' doam = '4,0 %'
      nsxns = 'Peter Greven GmbH & Co. KG - Đức'
      solo = 'MGS-7781' charg = 'AB1204' hd_days = 540 kn_days = 270
      groes = 'Thùng 10 kg' erfme = 'G' erfme_en = 'Gram' erfmg = 500
      baoquan = 'Nơi khô, nhiệt độ dưới 30°C' )
    ( matnr = '000000000002100512' maktx = 'Cellulose vi tinh thể (Avicel PH 101)' maktx_en = 'Microcrystalline cellulose'
      nodhl = '97,0 – 102,0 %' doam = '<= 5,0 %'
      nsxns = 'Shandong Liaocheng E-Jiao Pharmaceutical Group Co., Ltd. (chi nhánh Hà Nam) - Trung Quốc'
      solo = 'MCC-PH101-2609' charg = 'AB1310' hd_days = 1080 kn_days = 0
      groes = 'Bao 20 kg' erfme = 'KG' erfme_en = 'Kilogram' erfmg = '40.25'
      baoquan = 'Bảo quản trong bao bì kín, nơi khô ráo, nhiệt độ 15°C – 30°C, tránh ẩm' )
    ( matnr = '000000000002100688' maktx = 'Ethanol 96% (dung môi)' maktx_en = 'Ethanol 96% (solvent)'
      nodhl = '96,0 % v/v' doam = ''
      nsxns = 'Công ty CP Hóa chất Miền Nam - Việt Nam'
      solo = 'ETH-2610' charg = 'AB1415' hd_days = 365 kn_days = 0
      groes = 'Phuy 200 L' erfme = 'L' erfme_en = 'Litre' erfmg = '200.5'
      baoquan = 'Xa nguồn lửa, nơi thoáng mát' )
    ( matnr = '000000000002400019' maktx = 'Vỏ nang gelatin cứng số 0' maktx_en = 'Hard gelatin capsule shell No. 0'
      nodhl = '' doam = '13,0 – 16,0 %'
      nsxns = 'Qualicaps Co., Ltd - Nhật Bản'
      solo = 'QC-0-2605' charg = 'AB1502' hd_days = 730 kn_days = 365
      groes = 'Thùng 50.000 viên' erfme = 'ST' erfme_en = 'Piece' erfmg = 100000
      baoquan = 'Nhiệt độ 15°C – 25°C, độ ẩm 45 – 55 %' )
    ( matnr = '000000000002999999' maktx = 'Vật tư thiếu dữ liệu lô (ô trống)'
      erfme = 'KG' erfmg = 1 ) ).

ENDFORM.                    " BUILD_SAMPLE

*&---------------------------------------------------------------------*
*&      Form  GET_PARAMETER
*&---------------------------------------------------------------------*
*       Nhãn cố định của form, giống FORM GET_PARAMETER của ZWM_PG_PXK.
*----------------------------------------------------------------------*
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
*&      Form  FILL_FORM
*&---------------------------------------------------------------------*
*       Header của 1 phiếu thử + các dòng; IV_SHEET = số thứ tự phiếu.
*----------------------------------------------------------------------*
FORM fill_form USING iv_sheet TYPE i.

  DATA: lv_docno TYPE n LENGTH 10,
        lv_ord   TYPE n LENGTH 10,
        lv_fin   TYPE n LENGTH 10,
        lv_adj   TYPE n LENGTH 10.

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
  gs_parameter-header01 = to_upper( gs_plant-name ).
  gs_parameter-header02 = gs_plant-address.
  gs_parameter-header03 = |{ lcl_util=>lbl_c( iv_vi = 'Điện thoại' iv_en = 'Tel' ) } { gs_plant-tel }|.
  gs_parameter-header04 = |Fax: { gs_plant-fax }|.
  gs_parameter-header05 = |{ lcl_util=>lbl_c( iv_vi = 'MST' iv_en = 'TIN' ) } { gs_comp-tax }|.
  gs_parameter-header06 = |Website: { gs_plant-remark }|.
  CLEAR: gs_parameter-header39, gs_parameter-header40.
  IF gv_bi = abap_true.
    gs_parameter-header39 = to_upper( gs_plant_en-name ).
    gs_parameter-header40 = gs_plant_en-address.
  ENDIF.

  gs_parameter-header08 = COND #(
    WHEN gv_bi = abap_true
    THEN |Ngày/ Date { sy-datum+6(2) } tháng/ month { sy-datum+4(2) } năm/ year { sy-datum(4) }|
    ELSE |Ngày { sy-datum+6(2) } tháng { sy-datum+4(2) } năm { sy-datum(4) }| ).

  " Đơn vị nhận
  gs_parameter-header10 = 'PX-SX01'.
  gs_parameter-header12 = 'Phân xưởng sản xuất viên nang'.
  gs_parameter-header14 = '498 Nguyễn Thái Học, phường Quy Nhơn, tỉnh Gia Lai (mẫu)'.

  gs_parameter-header17 = '1300 - Kho nguyên liệu'.
  gs_parameter-header19 = COND #( WHEN gv_bi = abap_true
                                  THEN 'Xuất NVL sản xuất/ Issue raw material for production'
                                  ELSE 'Xuất NVL sản xuất' ).

  " Mỗi phiếu thử một bộ số khác nhau để phân biệt khi in nhiều phiếu
  lv_docno = 4900000000 + iv_sheet.
  lv_ord   = 3280000000 + iv_sheet.
  lv_fin   = 5000000000 + iv_sheet.
  lv_adj   = 4900009000 + iv_sheet.
  gs_parameter-header21 = |{ lv_ord ALPHA = OUT }|.
  gs_parameter-header23 = |{ lv_docno ALPHA = OUT }|.
  gs_parameter-header25 = |{ lv_fin ALPHA = OUT }|.

  gs_parameter-iso_line01 = COND #( WHEN p_cnt = 0 THEN |Lần in: 1|
                                    ELSE |Bản in lại – lần { p_cnt + 1 }| ).
  gs_parameter-footer07   = COND #( WHEN p_cnt = 0 THEN space
                                    ELSE |Bản in lại – lần { p_cnt + 1 }| ).
  gs_parameter-footer03   = |In lúc: { sy-datum+6(2) }/{ sy-datum+4(2) }/{ sy-datum(4) } | &&
                            |{ sy-uzeit(2) }:{ sy-uzeit+2(2) }:{ sy-uzeit+4(2) } – User: { sy-uname }|.

  gs_parameter-long_text1 = COND #( WHEN p_adj = abap_true
                                    THEN |Số lượng đã trừ chứng từ điều chỉnh: { lv_adj ALPHA = OUT }|
                                    ELSE space ).

  PERFORM fill_form_lines USING lv_docno.

ENDFORM.                    " FILL_FORM

*&---------------------------------------------------------------------*
*&      Form  FILL_FORM_LINES
*&---------------------------------------------------------------------*
*       Dòng chi tiết, cùng quy tắc ẩn/hiện cột như FILL_FORM_LINES của ZWM_PG_PXK.
*----------------------------------------------------------------------*
FORM fill_form_lines USING iv_docno TYPE clike.

  DATA: ls_data TYPE zwm_st_pxk,
        lv_cnt  TYPE i,
        lv_idx  TYPE i.

  CLEAR gt_data.
  lv_cnt = lines( gt_sample ).

  DO p_rows TIMES.

    lv_idx = ( sy-index - 1 ) MOD lv_cnt + 1.
    READ TABLE gt_sample ASSIGNING FIELD-SYMBOL(<lfs_s>) INDEX lv_idx.
    CHECK sy-subrc = 0.

    CLEAR ls_data.
    ls_data-stt   = sy-index.
    ls_data-mblnr = iv_docno.
    ls_data-matnr = <lfs_s>-matnr.
    ls_data-charg = <lfs_s>-charg.
    ls_data-lgort = '1300'.
    ls_data-werks = p_werks.
    ls_data-erfme = <lfs_s>-erfme.
    ls_data-erfmg = <lfs_s>-erfmg.
    ls_data-maktx = <lfs_s>-maktx.
    IF gv_bi = abap_true.
      ls_data-maktx_en = <lfs_s>-maktx_en.
      ls_data-erfme_en = <lfs_s>-erfme_en.
    ENDIF.

    " Nồng độ - hàm lượng, độ ẩm: mẫu 1 và 3
    IF p_op1 = abap_true OR p_op3 = abap_true.
      ls_data-nodhl = <lfs_s>-nodhl.
      ls_data-doam  = <lfs_s>-doam.
    ENDIF.

    ls_data-nsxns = <lfs_s>-nsxns.
    ls_data-solo  = <lfs_s>-solo.
    ls_data-groes = <lfs_s>-groes.
    IF <lfs_s>-hd_days > 0.
      ls_data-handung = sy-datum + <lfs_s>-hd_days.
    ENDIF.
    IF <lfs_s>-kn_days > 0.
      ls_data-ngaykn = sy-datum + <lfs_s>-kn_days.
    ENDIF.

    IF p_bq = abap_true AND p_op4 = abap_false.
      ls_data-baoquan = <lfs_s>-baoquan.
    ENDIF.

    APPEND ls_data TO gt_data.

  ENDDO.

ENDFORM.                    " FILL_FORM_LINES

*&---------------------------------------------------------------------*
*&      Form  PRINT_FORMS
*&---------------------------------------------------------------------*
*       Cùng cách mở / gọi / đóng SSF như PRINT_DOCS; không ghi nhật ký in.
*----------------------------------------------------------------------*
FORM print_forms .

  DATA: lv_fm      TYPE rs38l_fnam,
        lv_form    TYPE tdsfname,
        ls_cparam  TYPE ssfctrlop,
        ls_output  TYPE ssfcompop,
        ls_job_opt TYPE ssfcresop,
        ls_job_inf TYPE ssfcrescl,
        lv_spld    TYPE usr01-spld,
        lv_sheet   TYPE i.

  lv_form = COND #( WHEN p_op4 = abap_true THEN gc_form_op4
                    WHEN p_op2 = abap_true THEN gc_form_op2
                    ELSE gc_form_op1 ).

  " Máy in mặc định của user, không có thì hiện hộp thoại chọn máy in
  SELECT SINGLE spld FROM usr01 WHERE bname = @sy-uname INTO @lv_spld.
  IF p_prev = abap_true.
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
      formname = lv_form
    IMPORTING
      fm_name  = lv_fm
    EXCEPTIONS
      OTHERS   = 1.
  IF sy-subrc <> 0.
    MESSAGE |Không tìm thấy Smart Form { lv_form }: kiểm tra đã upload và activate ở SMARTFORMS| TYPE 'S' DISPLAY LIKE 'E'.
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

  DO p_sheet TIMES.

    lv_sheet = sy-index.
    PERFORM fill_form USING lv_sheet.

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

  ENDDO.

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

  IF p_prev = abap_false AND ls_job_inf-outputdone = abap_true.
    MESSAGE |Đã gửi { p_sheet } phiếu thử, form { lv_form }| TYPE 'S'.
  ENDIF.

ENDFORM.                    " PRINT_FORMS

*---------------------------------------------------------------------*
* Text elements (tạo bằng SE38 > Goto > Text elements, hoặc qua MCP)
*---------------------------------------------------------------------*
* Text symbols
* 001 Mẫu in cần thử
* 002 Dữ liệu thử
*
* Selection texts
* P_ADJ           Có dòng "đã trừ chứng từ điều chỉnh"
* P_BQ            Hiển thị cột ĐK bảo quản
* P_CNT           Số lần đã in (>0 = bản in lại)
* P_ISN           In song ngữ Việt - Anh
* P_OP1           1. Phiếu xuất kho nguyên liệu
* P_OP2           2. Phiếu xuất kho HH, vật tư
* P_OP3           3. Phiếu XK thuốc gây nghiện
* P_OP4           4. Xuất NVL lấy mẫu KN
* P_PREV          Xem trước (bỏ chọn = in ra máy in)
* P_ROWS          Số dòng hàng mỗi phiếu
* P_SHEET         Số phiếu
* P_WERKS         Plant lấy header (trống = chữ mẫu)
