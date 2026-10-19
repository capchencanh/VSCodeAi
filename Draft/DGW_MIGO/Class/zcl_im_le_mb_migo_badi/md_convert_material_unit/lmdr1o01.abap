*-------------------------------------------------------------------
***INCLUDE LMDR1O01 .
*-------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       01.01.02  4.70 mwe         Altes Coding auskommentiert
*-                                  (ohne Änderungsmarke)
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Module  SET_STATUS  OUTPUT
*&---------------------------------------------------------------------*
MODULE set_status OUTPUT.
*     Status für das Dynpro "Mengenerfassung" setzen
  SET TITLEBAR c_title_erfassung.

  IF sy-dynnr = c_dynpro_erfassung.
    SET PF-STATUS c_status_erfassung.
  ELSE.
    PERFORM set_status_0111 USING rt_extab.
  ENDIF.

* falls Position aus Bestellung: ME 'sperren'
  IF g_u01-kz_mesperre = c_yes.
    LOOP AT SCREEN.
      IF screen-group1 = 'G01'.
        CLEAR screen-input.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDMODULE.                             " SET_STATUS  OUTPUT

**&---------------------------------------------------------------------
*
**&      Module  READ_LINE  OUTPUT
**&---------------------------------------------------------------------
*
*MODULE READ_LINE OUTPUT.
*  IF SY-STEPL > 1.
*    EXIT FROM STEP-LOOP.
*  ENDIF.
*  READ TABLE G_T_LIST1 INDEX 1.
*ENDMODULE.                             " READ_LINE  OUTPUT

*
* 
