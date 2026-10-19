*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_PYCVT_PBO
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.

  SET PF-STATUS 'STANDARD'.
  SET TITLEBAR 'TITLE'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module INIT_CONTROLS_0100 OUTPUT
*&---------------------------------------------------------------------*
MODULE INIT_CONTROLS_0100 OUTPUT.

  IF GO_CONT IS INITIAL.
    PERFORM CREATE_ALV.
    PERFORM SHOW_START_MESSAGE.
  ENDIF.

ENDMODULE.
