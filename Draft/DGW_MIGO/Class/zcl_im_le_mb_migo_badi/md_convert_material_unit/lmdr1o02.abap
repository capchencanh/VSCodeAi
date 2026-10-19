*-------------------------------------------------------------------
***INCLUDE LMDR1O02 .
*-------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.08.97  400  welterm     Grundversion des Eingabe-DynPro
*-                                  für die Simulation eines dyn.
*-                                  Rundungsprofile.
*- @008  27.08.99  99A  kast        Erweiterung der Simulation um eine
*-                                  Schrittweite.
*-       01.01.02  4.70 mwe         Altes Coding auskommentiert
*-                                  (ohne Änderungsmarke)
*-----------------------------------------------------------------------

**&---------------------------------------------------------------------
*
**&      Module  STATUS_0400  OUTPUT
**&---------------------------------------------------------------------
*
**       Nimmt die Einstellung des Screens zum Dynpro 400 (Eingabe-
**       PopUp fuer die Simulaton eines dyn. Rundungsprofils) vor!
**----------------------------------------------------------------------
*
*MODULE status_0400 OUTPUT.
*
*  SET TITLEBAR     '400'.
*  SET PF-STATUS    'S0400'.       " Es wird der Grundstatus S0400 für
*  " das PopUp 0400 gesetzt.
*
*ENDMODULE.                 " STATUS_0400  OUTPUT
*
**&---------------------------------------------------------------------
*
**&      Module  STATUS_0600  OUTPUT
**&---------------------------------------------------------------------
*
**       Status fuer das DynPro 0600 (Ausgabe der Simulationswerte
**       eines dyn. Rundungsprofils) setzen!
**----------------------------------------------------------------------
*
*MODULE status_0600 OUTPUT.
*
*  SET TITLEBAR '600'.
*  SUPPRESS DIALOG.
*  LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0.
*  SET PF-STATUS space.
*  NEW-PAGE NO-TITLE NO-HEADING.
*
*ENDMODULE.                 " STATUS_0600  OUTPUT
*
**&---------------------------------------------------------------------
*
**&      Module  OUTPUT_SIMULATION_RDPR  OUTPUT
**&---------------------------------------------------------------------
*
**       Bestimme die Simulationswerte für das eingegebene Intervall
**       g_0400_in_from_amount  bis  g_0400_in_to_amount (Eingabe in
**       DynPro 400) zu einem Rundungsprofil und gebe diese Wert
**       in Dynpro 600 aus.
**----------------------------------------------------------------------
*
*MODULE output_simulation_rdpr OUTPUT.
*
*  PERFORM output_sim_rdpr USING     rdpr
*                                    mara-matnr
*                                    marm-meinh
*                                    mara-meins
*                                    mara-bstme
*                                    g_0400_in_from_amount
*                                    g_0400_in_to_amount
*                                    g_0400_in_step.         " @008
*ENDMODULE.                 " OUTPUT_SIMULATION_RDPR  OUTPUT
*
**&---------------------------------------------------------------------
*
**&      Module  MODIFY_SCREEN_0400  OUTPUT
**&---------------------------------------------------------------------
*
**       Setzen von Screen-Attributen abhängig von den Rundungs-
**       methoden.
**----------------------------------------------------------------------
*
*MODULE modify_screen_0400 OUTPUT.
*
*  LOOP AT SCREEN.
*
*    CASE rdpr-rdmpo.
*      WHEN    c_rdmpo_abs
*           OR c_rdmpo_no.
**                *** bei der statischen Rundungsmethode
**                *** bei keiner Rundung:
**                *** ist die Bestell-Mengeneinheit nicht eingabebereit
*        IF screen-group1 = 'GR2'.
*          screen-input = 0.
*        ENDIF.
*
*      WHEN c_rdmpo_up_down.
**                *** beim Auf- und Abschlagsrunden wird immer die
**                *** Basismengeneinheit als Eingabe- und Bestell-ME
**                *** genommen
*        IF screen-group1 = 'GR1'.       " Eingabemengeneiheit
*          screen-input = 0.
*        ENDIF.
*
*        IF screen-group1 = 'GR2'.       " Bestellmengeneinheit
*          screen-input = 0.
*        ENDIF.
*
*    ENDCASE.
*
*    MODIFY SCREEN.
*
*  ENDLOOP.
*
*ENDMODULE.                 " MODIFY_SCREEN_0400  OUTPUT

*
* 
