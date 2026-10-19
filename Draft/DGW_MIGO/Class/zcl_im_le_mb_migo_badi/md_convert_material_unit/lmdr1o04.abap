*----------------------------------------------------------------------*
***INCLUDE LMDR1O04 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       01.10.01  4.70 mbi         Grundversion
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Module  status_0401  OUTPUT
*&---------------------------------------------------------------------*
*       Setzten des Status und Vorbelegung verschiedener Felder des
*       Dynpros.
*----------------------------------------------------------------------*
MODULE status_0401 OUTPUT.

  SET PF-STATUS c_pf_status_s0401.                          " = 'S0401'.
  SET TITLEBAR  c_titelbar_401.                             " = '401'.

ENDMODULE.                 " status_0401  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  modify_screen_0401  OUTPUT
*&---------------------------------------------------------------------*
*       Setzen von Screen-Attributen abhängig von den Rundungs-
*       methoden.
*----------------------------------------------------------------------*
MODULE modify_screen_0401 OUTPUT.

  LOOP AT SCREEN.

    CASE rdpr-rdmpo.
      WHEN    c_rdmpo_abs
           OR c_rdmpo_no.
*                *** bei der statischen Rundungsmethode
*                *** bei keiner Rundung:
*                *** ist die Bestell-Mengeneinheit nicht eingabebereit
        IF screen-group1 = c_0401_group_gr2                 " ='GR2'.
        OR screen-name = c_mara_bstme.
          screen-active = 0.
        ENDIF.


      WHEN c_rdmpo_up_down.
*                *** beim Auf- und Abschlagsrunden wird immer die
*                *** Basismengeneinheit als Eingabe- und Bestell-ME
*                *** genommen
        IF screen-group1 = c_0401_group_gr1.    " Eingabemengeneiheit
          screen-input = 0.
        ENDIF.

        IF screen-group1 = c_0401_group_gr2    " Bestellmengeneinheit
        OR screen-name = c_mara_bstme.
          screen-active = 0.
        ENDIF.

    ENDCASE.

*                *** Überprüfen, welche Exception angezeigt werden soll.
    CASE g_0401_light.

      WHEN c_green.

        CASE screen-name.

          WHEN c_greenlight.         " = 'GREENLIGHT'.

            screen-active = 1.

          WHEN c_redlight.           " = 'REDLIGHT'.

            screen-active = 0.

        ENDCASE.

      WHEN c_red.

        CASE screen-name.

          WHEN c_greenlight.         " = 'GREENLIGHT'.

            screen-active = 0.

          WHEN c_redlight.           " = 'REDLIGHT'.

            screen-active = 1.

        ENDCASE.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDMODULE.                 " modify_screen_0401  OUTPUT

*
* 
