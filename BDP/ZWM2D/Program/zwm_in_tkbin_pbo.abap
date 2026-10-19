*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_TKBIN_PBO
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.

  SET PF-STATUS 'STANDARD'.
  SET TITLEBAR 'TITLE'.

  PERFORM SET_SEARCH_TEXTS.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module INIT_CONTROLS_0100 OUTPUT
*&---------------------------------------------------------------------*
MODULE INIT_CONTROLS_0100 OUTPUT.

  IF GO_CONT IS INITIAL.
    PERFORM CREATE_CONTROLS.
  ENDIF.
  PERFORM REFRESH_CONTROLS.

ENDMODULE.
