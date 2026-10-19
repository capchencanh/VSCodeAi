*----------------------------------------------------------------------*
* Program ID: ZWM_PG_PCK
* Program Name: Phiếu chuyển kho
*
* Program Summary: Phiếu chuyển kho
*
*
* Creation Date : 13.10.2026 14:51:01            Created by： DanhDH
* Coding Standards Version 7
* Development Version:
* Available Condition:
*----------------------------------------------------------------------*
* CitekTechnology JSC.
* (C) CopyrightCitekTechnology JSC.
* All Rights Reserved
*----------------------------------------------------------------------*


REPORT zwm_pg_pck MESSAGE-ID zwm05.

INCLUDE zwm_in_pck_top.
INCLUDE zwm_in_pck_f01.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM check_condition.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN OUTPUT
*---------------------------------------------------------------------*
* Bỏ mẫu 4 (Hình 2 của FS chỉ có 3 mẫu) nên không cần ẩn radio nữa
*AT SELECTION-SCREEN OUTPUT.
*
*  " Ẩn mẫu 4
*  LOOP AT SCREEN.
*    IF screen-group1 = 'OP4'.
*      screen-active = 0.
*      MODIFY SCREEN.
*    ENDIF.
*  ENDLOOP.

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

  gv_bi = p_isn.

  PERFORM get_mvt_group.

  IF gt_mvt IS INITIAL.
    MESSAGE s009 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_data.
  PERFORM check_authority.
  PERFORM match_mvt_group.
  PERFORM show_messages.

  IF gt_item IS INITIAL.
    MESSAGE s003 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_cancel_info.
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
* P_ISN           In song ngữ Việt - Anh
* P_MJAHR         Năm chứng từ
* P_OP1           1. Thành phẩm, hàng hóa
* P_OP2           2. Thuốc gây nghiện
* P_OP3           3. Nguyên liệu, bao bì
* S_BUDAT         Ngày hạch toán
* S_BWART         Movement Type
* S_LGORT         SLoc xuất
* S_MBLNR         Chứng từ kho
* S_RSNUM         Reservation
* S_UMLGO         SLoc nhận
* S_USNAM         Người tạo chứng từ
* S_WERKS         Plant
