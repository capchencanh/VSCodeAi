*&---------------------------------------------------------------------*
*& Report  ZWM_PG_BBKNHH
*& Program Title  Biên bản kiểm nhận hàng hóa
*&---------------------------------------------------------------------*

REPORT zwm_pg_bbknhh MESSAGE-ID zwm02.

INCLUDE zwm_in_bbknhh_top.
INCLUDE zwm_in_bbknhh_f01.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM check_condition.

*---------------------------------------------------------------------*
* F4 chứng từ nhập kho
*---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mblnr-low.

  PERFORM f4_help_mblnr.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mblnr-high.

  PERFORM f4_help_mblnr.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM get_parameter.

  IF p_src_a = abap_true.
    PERFORM get_data_a.
  ELSE.
    PERFORM get_data_b.
  ENDIF.

  PERFORM check_authority.

  IF gt_item IS INITIAL.
    MESSAGE s003 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_master_data.
  PERFORM build_alv_data.
  PERFORM display_alv.

*Text elements
*----------------------------------------------------------
* 001 Nguồn chứng từ
* 002 Điều kiện chọn dữ liệu
* 003 Nhóm hàng

*Selection texts
*----------------------------------------------------------
* P_KHAC          Hàng hóa khác
* P_MJAHR         Năm chứng từ
* P_SRC_A         (A) Theo Lệnh nhập kho – in trước khi nhập kho
* P_SRC_B         (B) Theo chứng từ nhập kho – in sau nhập kho
* P_THUGN         Thuốc gây nghiện, hướng thần, tiền chất
* P_VACSP         Vacxin, sinh phẩm
* S_BUDAT         Ngày nhập kho
* S_KUNNR         Khách hàng (hàng trả)
* S_LFDAT         Ngày giao hàng dự kiến
* S_LGORT         Storage Location
* S_LIFNR         Nhà cung cấp
* S_MBLNR         Chứng từ nhập kho
* S_TRAID         Số xe vận chuyển
* S_VBELN         Lệnh nhập kho (Inbound/Returns Delivery)
* S_WERKS         Plant
