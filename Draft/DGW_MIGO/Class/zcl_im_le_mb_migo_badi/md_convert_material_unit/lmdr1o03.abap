*----------------------------------------------------------------------*
***INCLUDE LMDR1O03 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       25.03.98  4.0c welterm     Erweiterungen für 40c:
*-                                  - neue Transaktion zum Aufruf
*-                                    der Simulation
*- @001  11.11.01  470  mbi         Realisierung SMAD-Punkte
*-                                  - Verbesserung der Rundungs-
*-                                    Simulation
*-                                    (Marke: #mbi 4.70 RoundSimu )
*-----------------------------------------------------------------------
*$@001 #mbi 4.70 RoundSimu - Anfang
*$*&--------------------------------------------------------------------
*$*&      Module  CALL_INPUT_DYNPRO_0500  OUTPUT
*$*&-------------------------------------------------------------------
*$*       Aufruf des Auswahl-PopUps 0500.
*$*---------------------------------------------------------------------
*$MODULE call_input_dynpro_0500 OUTPUT.
*$
*$  CALL SCREEN 0500
*$     STARTING  AT 05 05.
*$
*$  IF ok_code = c_fc_canc.
*$    SET SCREEN 0.
*$    LEAVE SCREEN.
*$  ENDIF.
*$
*$ENDMODULE.                         " CALL_INPUT_DYNPRO_0500  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  call_mdr1_simu_rounding_0300  OUTPUT
*&---------------------------------------------------------------------*
*       Neue Simulation
*----------------------------------------------------------------------*
MODULE call_mdr1_simu_rounding_0300 OUTPUT.

  DATA: l_s_general  TYPE  mdr1insingleround.

*                *** Neue Simulation nutzen:
*                *** Hier erfolgt der Aufruf ohne gesetzte
*                *** Steuerungsparameter!!
  PERFORM call_mdr1_simu_rounding
    USING l_s_general.

ENDMODULE.                 " call_mdr1_simu_rounding_0300  OUTPUT
*$@001 #mbi 4.70 RoundSimu - Ende

*
* 
