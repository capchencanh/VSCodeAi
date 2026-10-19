*&---------------------------------------------------------------------*
*& Report  ZWM_PG_BBKNHH
*& Program Title  Biên bảng kiểm nhận hàng hóa
*&---------------------------------------------------------------------*
*& Request    Date          ABAPer        Action     Comments
*&           01.10.2026    HAIDX         Create
*&---------------------------------------------------------------------*

REPORT zwm_pg_bbknhh.

INCLUDE zwm_in_bbknhh_top.
INCLUDE zwm_in_bbknhh_f01.

*---------------------------------------------------------------------*
* INITIALIZATION
*---------------------------------------------------------------------*
INITIALIZATION.

  PERFORM init.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM check_condition.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN OUTPUT
*---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  PERFORM modify_screen.

*---------------------------------------------------------------------*
* F4 MBLNR LOW
*---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mblnr-low.

  PERFORM f4_help_mblnr.

*---------------------------------------------------------------------*
* F4 MBLNR HIGH
*---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mblnr-high.

  PERFORM f4_help_mblnr.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM get_parameter.

*---------------------------------------------------------------------*
* Get data
*---------------------------------------------------------------------*
  PERFORM fill_data.

  IF gt_predata IS INITIAL.

    MESSAGE 'Không tìm thấy chứng từ phù hợp.' TYPE 'I'.

    RETURN.

  ENDIF.

*---------------------------------------------------------------------*
* Build ALV
*---------------------------------------------------------------------*
  PERFORM build_alv_data.

  IF gt_alv IS INITIAL.

    MESSAGE 'Không tìm thấy chứng từ để hiển thị.' TYPE 'I'.

    RETURN.

  ENDIF.

*---------------------------------------------------------------------*
* Display ALV
*---------------------------------------------------------------------*
  PERFORM display_alv.

*---------------------------------------------------------------------*
* Get selected documents
*---------------------------------------------------------------------*
  PERFORM get_selected_documents.

  IF gv_selected_count IS INITIAL.

    MESSAGE 'Chưa chọn chứng từ để in.'
      TYPE 'S'
      DISPLAY LIKE 'E'.

    RETURN.

  ENDIF.

*---------------------------------------------------------------------*
* Sau khi lọc theo chứng từ được chọn
*---------------------------------------------------------------------*
  IF gt_predata IS INITIAL.

    MESSAGE 'Không có dữ liệu chi tiết của chứng từ được chọn.'
      TYPE 'I'.

    RETURN.

  ENDIF.

*---------------------------------------------------------------------*
* Data processing
*---------------------------------------------------------------------*
  PERFORM data_processing.

  IF gt_data IS INITIAL.

    MESSAGE 'Không có dữ liệu để in.'
      TYPE 'I'.

    RETURN.

  ENDIF.

*---------------------------------------------------------------------*
* Export / Print
*---------------------------------------------------------------------*
  PERFORM export_data.

*Text elements
*----------------------------------------------------------
* 001 Nguồn chứng từ
* 002 Điều kiện chọn dữ liệu
* 003 Nhóm hàng


*Selection texts
*----------------------------------------------------------
* P_KHAC         Khác
* P_MJAHR         Năm chứng từ
* P_SRC_A         (A) Theo Lệnh nhập kho
* P_SRC_B         (B) Theo chứng từ nhập kho
* P_THUGN         Thuốc gây nghiện
* P_VACSP         Vắc xin sinh phẩm
* S_BUDAT         Ngày nhập kho
* S_KUNNR         Khách hàng (hàng trả)
* S_LFDAT         Ngày giao hàng dự kiến
* S_LGORT         Storage Location
* S_LIFNR         Nhà cung cấp
* S_MBLNR         Chứng từ nhập kho
* S_TRAID         Số xe vận chuyển
* S_VBELN         Lệnh nhập kho
* S_WERKS         Plant


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   Không thể khởi tạo ALV.

*
*
