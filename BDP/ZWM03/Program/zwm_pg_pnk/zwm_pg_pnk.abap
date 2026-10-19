*&---------------------------------------------------------------------*
*& Report  ZWM_PG_PNK
*& Program Title  Phiếu nhập kho
*&---------------------------------------------------------------------*

REPORT zwm_pg_pnk MESSAGE-ID zwm03.

INCLUDE zwm_in_pnk_top.
INCLUDE zwm_in_pnk_f01.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM check_condition.

*---------------------------------------------------------------------*
* F4 chứng từ kho
*---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mblnr-low.

  PERFORM f4_help_mblnr CHANGING s_mblnr-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mblnr-high.

  PERFORM f4_help_mblnr CHANGING s_mblnr-high.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM get_mvt_group.

  IF gt_mvt IS INITIAL.
    MESSAGE s010 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_data.
  PERFORM check_authority.
  PERFORM match_mvt_group.
  PERFORM calc_adjust.
  PERFORM show_messages.

  IF gt_item IS INITIAL.
    MESSAGE s003 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_master_data.
  PERFORM build_alv_data.
  PERFORM display_alv.

*Text elements
*----------------------------------------------------------
* 001 Điều kiện chọn dữ liệu
* 002 Mẫu in
* 003 Tùy chọn

*Selection texts
*----------------------------------------------------------
* P_ADJ           SL thực nhận sau điều chỉnh
* P_ISN           In song ngữ Việt - Anh
* P_MJAHR         Năm chứng từ
* P_OP1           1. Phiếu nhập kho nguyên liệu
* P_OP2           2. Phiếu nhập kho HH, vật tư
* P_OP3           3. Phiếu nhập kho thành phẩm
* P_OP4           4. Nhập kho NL, BB có quy đổi
* S_AUFNR         Lệnh sản xuất
* S_BUDAT         Ngày hạch toán
* S_BWART         Movement Type
* S_EBELN         Đơn mua hàng (PO)
* S_LGORT         Storage Location
* S_LIFNR         Nhà cung cấp
* S_MBLNR         Chứng từ kho
* S_USNAM         Người tạo chứng từ
* S_WERKS         Plant
