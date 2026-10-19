*----------------------------------------------------------------------*
* Program ID: ZWM_PG_LCVT
* Program Name: Lệnh chuyển vị trí
*
* Program Summary: Lệnh chuyển vị trí (Warehouse Task EWM)
*
*
* Creation Date : 14.10.2026                     Created by： DanhDH
* Coding Standards Version 7
* Development Version:
* Available Condition:
*----------------------------------------------------------------------*
* CitekTechnology JSC.
* (C) CopyrightCitekTechnology JSC.
* All Rights Reserved
*----------------------------------------------------------------------*


REPORT zwm_pg_lcvt MESSAGE-ID zwm07.

INCLUDE zwm_in_lcvt_top.
INCLUDE zwm_in_lcvt_f01.

*---------------------------------------------------------------------*
* INITIALIZATION
*---------------------------------------------------------------------*
INITIALIZATION.

  PERFORM init_screen.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN OUTPUT
*---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  " Ba loại Bin-to-Bin / Putaway / Picking chỉ dùng cho Option 1
  LOOP AT SCREEN.
    IF screen-group1 = 'OP1'.
      screen-input = COND #( WHEN p_op1 = abap_true THEN '1' ELSE '0' ).
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM check_condition.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM check_authority_wh.
  PERFORM get_option_config.
  PERFORM get_data.
  PERFORM check_undeclared_wpt.
  PERFORM check_authority_type.
  PERFORM show_messages.

  IF gt_wt IS INITIAL.
    MESSAGE s004 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_master_data.
  PERFORM build_alv_data.
  PERFORM display_alv.

*Text elements
*----------------------------------------------------------
* 001 Điều kiện chọn dữ liệu
* 002 Trạng thái WT
* 003 Option
* 004 Gom

*Selection texts
*----------------------------------------------------------
* P_B2B           Bin-to-Bin
* P_G1            Gom WT (cùng Vị trí đích)
* P_G2            Không gom
* P_LGNUM         Warehouse
* P_OP1           1. Điều chuyển giữa 2 vị trí
* P_OP2           2. Điều chuyển phục vụ LSX
* P_OP3           3. Điều chuyển bổ sung cho SX
* P_PCK           Picking
* P_PTW           Putaway
* P_ST1           Chưa xác nhận
* P_ST2           Đã xác nhận (đối chiếu)
* P_ST3           Tất cả
* S_AUFNR         Lệnh sản xuất
* S_DATE          Ngày tạo WT
* S_DOCNO         Chứng từ tham chiếu
* S_LGTYP         Storage Type nguồn / đích
* S_MATNR         Vật tư
* S_PROCTY        Warehouse Process Type
* S_TANUM         Warehouse Task
* S_USER          Người tạo
