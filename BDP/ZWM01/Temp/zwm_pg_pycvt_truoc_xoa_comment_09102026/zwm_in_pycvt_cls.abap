*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PYCVT_CLS
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Sự kiện của màn hình trung gian: nút trên thanh công cụ ALV,
* nhấp ô Chọn, đóng popup chi tiết giữ tồn
*----------------------------------------------------------------------*
CLASS LCL_EVT DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      ON_FUNC FOR EVENT ADDED_FUNCTION OF CL_SALV_EVENTS_TABLE
        IMPORTING E_SALV_FUNCTION,
      ON_LINK FOR EVENT LINK_CLICK OF CL_SALV_EVENTS_TABLE
        IMPORTING ROW COLUMN,
      ON_CLOSE FOR EVENT CLOSE OF CL_GUI_DIALOGBOX_CONTAINER
        IMPORTING SENDER.
ENDCLASS.

CLASS LCL_EVT IMPLEMENTATION.
  METHOD ON_FUNC.
    PERFORM HANDLE_FUNCTION USING E_SALV_FUNCTION.
  ENDMETHOD.

  METHOD ON_LINK.
    PERFORM HANDLE_LINK USING ROW COLUMN.
  ENDMETHOD.

  METHOD ON_CLOSE.
    SENDER->FREE( EXCEPTIONS OTHERS = 1 ).
    CLEAR: GO_DLG, GO_SALV_1, GO_SALV_2.
  ENDMETHOD.
ENDCLASS.
