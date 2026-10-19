*----------------------------------------------------------------------*
* Program ID: ZWM_PG_TONTHUOCTINH
* Program Name: Báo cáo tồn kho theo thuộc tính lô
*
* Program Summary: Báo cáo tồn kho theo thuộc tính lô
*
*
* Creation Date : 15.10.2026                     Created by： DanhDH
* Coding Standards Version 7
* Development Version:
* Available Condition:
*----------------------------------------------------------------------*
* CitekTechnology JSC.
* (C) CopyrightCitekTechnology JSC.
* All Rights Reserved
*----------------------------------------------------------------------*


REPORT zwm_pg_tonthuoctinh MESSAGE-ID zwm11.

INCLUDE zwm_in_tonthuoctinh_top.
INCLUDE zwm_in_tonthuoctinh_f01.

*---------------------------------------------------------------------*
* INITIALIZATION
*---------------------------------------------------------------------*
INITIALIZATION.

  PERFORM init.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN OUTPUT
*---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  PERFORM modify_screen.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM at_selection_screen.

*---------------------------------------------------------------------*
* F4
*---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_class.

  PERFORM f4_class CHANGING p_class.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_layo.

  PERFORM f4_layout CHANGING p_layo.

* F4 giá trị cho phép của thuộc tính kiểu ký tự
DEFINE lm_f4_char.
  AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_c&1-low.
    PERFORM f4_char_value USING '&1' CHANGING s_c&1-low.
  AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_c&1-high.
    PERFORM f4_char_value USING '&1' CHANGING s_c&1-high.
END-OF-DEFINITION.

lm_f4_char 01.
lm_f4_char 02.
lm_f4_char 03.
lm_f4_char 04.
lm_f4_char 05.
lm_f4_char 06.
lm_f4_char 07.
lm_f4_char 08.
lm_f4_char 09.
lm_f4_char 10.
lm_f4_char 11.
lm_f4_char 12.
lm_f4_char 13.
lm_f4_char 14.
lm_f4_char 15.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM get_unit_info.
  PERFORM prepare_char.
  PERFORM get_conditions.
  PERFORM get_batch_filter.
  PERFORM get_stock.

  IF gt_stock IS INITIAL.
    MESSAGE i002.
    RETURN.
  ENDIF.

  PERFORM check_authority.
  PERFORM get_char_values.
  PERFORM build_alv_data.
  PERFORM show_messages.
  PERFORM display_alv.

*Text elements
*----------------------------------------------------------
* 001 Phạm vi
* 002 Phân loại lô
* 003 Lọc theo thuộc tính lô (động theo Batch Class)
* 004 Loại tồn
* 005 Đơn vị tính và ngày tham chiếu
* 006 Hiển thị
* 007 Tick = hiển thị cột thuộc tính trên ALV; nhập điều kiện lọc bên phải

*Selection texts
*----------------------------------------------------------
* P_AUTO          Sinh khối lọc thuộc tính
* P_BLK           Blocked
* P_CLASS         Batch Class
* P_DATE          Ngày tham chiếu (HSD còn lại)
* P_INCL          Bao gồm lô đã khóa / hết hạn
* P_LAYO          Layout
* P_MEINH         ĐVT quy đổi muốn xem
* P_ONLY          Chỉ hiển thị lô còn tồn
* P_QI            Quality Inspection
* P_UNR           Unrestricted
* P_WERKS         Plant
* S_CHARG         Lô
* S_LGORT         Storage Location
* S_MATKL         Nhóm vật tư
* S_MATNR         Vật tư
* S_MTART         Material Type
