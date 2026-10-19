*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_TKBIN_CLS
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Tien ich: cat 1 thanh phan cua ma Bin theo vi tri bat dau (tinh tu 1)
* va do dai. Tra ve rong khi vuot qua do dai ma Bin.
*----------------------------------------------------------------------*
CLASS LCL_UTIL DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS PART
      IMPORTING IV_BIN         TYPE CLIKE
                IV_OFF         TYPE I
                IV_LEN         TYPE I
      RETURNING VALUE(RV_PART) TYPE STRING.
ENDCLASS.

CLASS LCL_UTIL IMPLEMENTATION.
  METHOD PART.
    IF IV_OFF <= 0 OR IV_LEN <= 0 OR IV_OFF + IV_LEN - 1 > STRLEN( IV_BIN ).
      RETURN.
    ENDIF.
    RV_PART = SUBSTRING( VAL = IV_BIN OFF = IV_OFF - 1 LEN = IV_LEN ).
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Bat su kien nhap o tren so do (HTML viewer)
*----------------------------------------------------------------------*
CLASS LCL_EVT DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS ON_SAPEVENT
      FOR EVENT SAPEVENT OF CL_GUI_HTML_VIEWER
      IMPORTING ACTION GETDATA.
ENDCLASS.

CLASS LCL_EVT IMPLEMENTATION.
  METHOD ON_SAPEVENT.
    PERFORM HANDLE_SAPEVENT USING ACTION GETDATA.
  ENDMETHOD.
ENDCLASS.
