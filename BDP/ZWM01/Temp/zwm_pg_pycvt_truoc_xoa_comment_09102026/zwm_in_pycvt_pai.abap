*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PYCVT_PAI
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module EXIT_COMMAND_0100 INPUT
*&---------------------------------------------------------------------*
MODULE EXIT_COMMAND_0100 INPUT.

  CASE SY-UCOMM.
    WHEN 'BACK' OR 'EXIT' OR 'CANC' OR '&F03' OR '&BACK' OR '&F12' OR '&F15'.
      PERFORM FREE_CONTROLS.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0100 INPUT
*&---------------------------------------------------------------------*
* Các nút chức năng nằm trên thanh công cụ ALV (xử lý ở LCL_EVT)
MODULE USER_COMMAND_0100 INPUT.

  GV_OK = SY-UCOMM.
  CLEAR SY-UCOMM.

ENDMODULE.
