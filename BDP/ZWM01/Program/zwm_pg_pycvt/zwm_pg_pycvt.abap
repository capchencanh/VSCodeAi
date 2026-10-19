*&---------------------------------------------------------------------*
*& Report ZWM_PG_PYCVT
*& Phiếu yêu cầu vật tư (ZWM01)
*&---------------------------------------------------------------------*
REPORT ZWM_PG_PYCVT.

INCLUDE ZWM_IN_PYCVT_TOP.
INCLUDE ZWM_IN_PYCVT_CLS.
INCLUDE ZWM_IN_PYCVT_PBO.
INCLUDE ZWM_IN_PYCVT_PAI.
INCLUDE ZWM_IN_PYCVT_F01.
INCLUDE ZWM_IN_PYCVT_F02.

INITIALIZATION.
  PERFORM INIT_SELECTION.

AT SELECTION-SCREEN OUTPUT.
  " Mọi ô điều kiện luôn hiển thị; Cost Center nhập sai loại phiếu thì báo lỗi ở VALIDATE_SELECTION

AT SELECTION-SCREEN.
  PERFORM VALIDATE_SELECTION.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR S_RSNUM-LOW.
PERFORM F4_HELP_RSNUM_LOW.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR S_RSNUM-HIGH.
PERFORM F4_HELP_RSNUM_HIGH.

START-OF-SELECTION.
  PERFORM DETERMINE_DOC_TYPE.
  " Parameter excecute
  PERFORM GET_PARAMETER.
  " Get data
  PERFORM FILL_DATA.
  " Data processing
  PERFORM DATA_PROCESSING.
  " Export data
  " Có kiểm tra sẵn sàng: màn hình trung gian; không: xem trước bản in ngay
  IF P_KTNVL = ABAP_TRUE.
    PERFORM CHECK_READINESS.
    CALL SCREEN 0100.
  ELSE.
    GT_PRINT = GT_PREDATA.
    PERFORM EXPORT_DATA USING ABAP_TRUE.
  ENDIF.

*Nhãn màn hình chọn, tiêu đề khung: gán trong FORM INIT_SELECTION (không cần Text Elements)
*----------------------------------------------------------

*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   Cost Center chỉ áp dụng cho phiếu cho bộ phận khác
*   Bạn không có quyền với Order Type &1 tại Plant &2
*   Bạn không có quyền với Movement Type &1
*   Vui lòng chọn một dòng
*
* Message class: 00
*398   & & & &
*
* Message class: ZWM01
*000   Bạn không có quyền trên Plant &1.
*001   Vui lòng nhập ít nhất một trong: Số phiếu, Lệnh sản xuất, Ngày yêu cầu.
*002   Không có dữ liệu thỏa điều kiện.
*003   Dòng &1/&2 - vật tư &3 chưa được chỉ định Batch, không được đưa vào phiếu
*004   Chưa chọn dòng nào để in.
*005   Phiếu &1 đã được in &2 lần. Bản in này được đánh dấu là bản in lại.
*006   Không đọc được tồn EWM cho Warehouse &1: &2.
*007   Thiếu cấu hình &1 cho Warehouse &2.
