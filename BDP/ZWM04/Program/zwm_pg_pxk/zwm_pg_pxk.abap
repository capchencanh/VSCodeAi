*&---------------------------------------------------------------------*
*& Report  ZWM_PG_PXK
*& Program Title  Phiếu xuất kho
*&---------------------------------------------------------------------*

REPORT zwm_pg_pxk MESSAGE-ID zwm04.

INCLUDE zwm_in_pxk_top.
INCLUDE zwm_in_pxk_f01.

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

  " Mẫu 4 luôn song ngữ
  gv_bi = xsdbool( p_isn = abap_true OR p_op4 = abap_true ).

  PERFORM get_mvt_group.

  IF gt_mvt IS INITIAL.
    MESSAGE s010 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_data.
  PERFORM check_authority.
  PERFORM match_mvt_group.
  PERFORM filter_sample.
  PERFORM calc_adjust.
  PERFORM check_open_wt.
  PERFORM show_messages.

  IF gt_item IS INITIAL.
    MESSAGE s008 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_master_data.
  PERFORM set_recipients.
  PERFORM build_alv_data.
  PERFORM display_alv.

*Text elements
*----------------------------------------------------------
* 001 Điều kiện chọn dữ liệu
* 002 Mẫu in
* 003 Tùy chọn

*Selection texts
*----------------------------------------------------------
* P_BQ            Hiển thị cột ĐK bảo quản
* P_ISN           In song ngữ Việt - Anh
* P_MJAHR         Năm chứng từ
* P_OP1           1. Phiếu xuất kho nguyên liệu
* P_OP2           2. Phiếu xuất kho HH, vật tư
* P_OP3           3. Phiếu XK thuốc gây nghiện
* P_OP4           4. Xuất NVL lấy mẫu KN
* S_AUFNR         Lệnh sản xuất / Order
* S_BUDAT         Ngày hạch toán
* S_BWART         Movement Type
* S_KOSTL         Cost Center
* S_LGORT         Storage Location
* S_MBLNR         Chứng từ kho
* S_USNAM         Người tạo chứng từ
* S_VBELN         Lệnh xuất kho
* S_WERKS         Plant
