*&---------------------------------------------------------------------*
*&  Include           ZWM_IN_TKBIN_PAI
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
MODULE USER_COMMAND_0100 INPUT.

  GV_OK = SY-UCOMM.
  CLEAR SY-UCOMM.

  PERFORM HANDLE_COMMAND USING GV_OK.

ENDMODULE.
