FUNCTION ZFM_CONVERT_UNIT.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_MATNR) TYPE  MATNR
*"     REFERENCE(I_MEINS_IN) TYPE  MEINS
*"     REFERENCE(I_MEINS_OUT) TYPE  MEINS
*"     REFERENCE(I_QTY)
*"  EXPORTING
*"     REFERENCE(E_QTY)
*"--------------------------------------------------------------------
DATA: LW_INPUT  TYPE EKPO-MENGE,
        LW_OUTPUT TYPE EKPO-MENGE.

  LW_INPUT = I_QTY.

  CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
    EXPORTING
      I_MATNR              = I_MATNR
      I_IN_ME              = I_MEINS_IN
      I_OUT_ME             = I_MEINS_OUT
      I_MENGE              = LW_INPUT
    IMPORTING
      E_MENGE              = LW_OUTPUT
    EXCEPTIONS
      ERROR_IN_APPLICATION = 1
      ERROR                = 2
      OTHERS               = 3.
  IF SY-SUBRC = 0.
    E_QTY = LW_OUTPUT.
  ELSE.
    CLEAR: E_QTY.
*    E_QTY = I_QTY.
  ENDIF.





ENDFUNCTION.

*
* 
