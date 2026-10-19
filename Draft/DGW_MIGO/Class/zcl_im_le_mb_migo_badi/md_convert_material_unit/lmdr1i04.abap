*----------------------------------------------------------------------*
***INCLUDE LMDR1I04 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       01.10.01  4.70 mbi         Grundversion
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Module  exit_0401  INPUT
*&---------------------------------------------------------------------*
*       Abbruch des EingabeDynbros 401
*----------------------------------------------------------------------*
MODULE exit_0401 INPUT.

  CLEAR ok_code.

  IF g_0401_call_from_0800 = c_yes.
*                *** Bei Aufruf aus dem Auswahldynpro 0800:
*                *** => zurück zu diesem Dynpro springen!
    LEAVE TO SCREEN 0800.

  ELSE.
*                *** Bei Aufruf aus der Rundungsprofil-Pflege (OWD1):
*                *** => Fortfahren mit dem Code nach dem Aufruf
*                ***    des Dynpro 0401
    LEAVE TO SCREEN 0.

  ENDIF.

ENDMODULE.                 " exit_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  input_check_matnr_obli_0401  INPUT
*&---------------------------------------------------------------------*
*       Mindestens die Materialnummer muss bei der Ausführung eingeben
*       werden!
*----------------------------------------------------------------------*
MODULE input_check_matnr_obli_0401 INPUT.

  IF ok_code = c_fc_exec_range
  OR ok_code = c_fc_exec_value
  OR ok_code = c_fc_cont.

    IF g_0401_matnr IS INITIAL.

      MESSAGE e002(lumer).

    ENDIF.

  ENDIF.

ENDMODULE.                 " input_check_matnr_obli_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  INPUT_CHECK_MATNR_0401  INPUT
*&---------------------------------------------------------------------*
*       Prüfe die Eingabewerte zum Material des DynPro 401 auf Korrekt-
*       heit und bestimme den Default-Wert (BasisMengeneinheit).
*       Weiter wird der Material-Namen bestimmt.
*----------------------------------------------------------------------*
MODULE input_check_matnr_0401 INPUT.

*                *** Bei neuer Eingabe immer wieder
*                *** alle abhängigen Daten initialisieren
  CLEAR: g_s_0401_makt,
         g_0401_meinh,
         g_0401_meinh_umrech.
*                *** Setze die Exception auf Farbe rot.
  g_0401_light = c_red.

  CLEAR: g_s_0401_mara.
*                *** Lese die Basismengeneinheit zu dem Material aus
*                *** MARA => Plausi auch als Match-Code fuer Eingabe-
*                *** feld moeglich.
  PERFORM read_mara_single_online
              USING
                  g_0401_matnr
              CHANGING
                  g_s_0401_mara.

  IF g_0401_bstme IS INITIAL.
*                *** Bestell-ME defaultmäßig mit Bestellmengeneinheit
*                *** des Materials vorbelegen
    g_0401_bstme = g_s_0401_mara-bstme.
  ENDIF.

  IF  NOT ( g_s_0401_mara      IS  INITIAL )
  AND       g_0401_meinh_input IS  INITIAL.
*                *** Wenn das Material in MARA existiert und die
*                *** Eingabe-Mengeneinheit nicht belegt, ist marm-meinh
*                *** = LEER => Default-Belegung der Eingabemengeneinheit
*                *** mit der Basismengeneinheit.
    g_0401_meinh_input = g_s_0401_mara-meins.
  ENDIF.

*                *** Lese den Namen des Artikels aus der MAKT
  PERFORM read_makt
              USING
                 g_0401_matnr
                 g_0401_werks
              CHANGING
                 g_s_0401_makt.

*                *** Untersuche ob die eingegebe Mengeneinheit
*                *** eine gültige zu dem Material ist, falls die
*                *** Eingabe-Mengeneinheit nicht mit der Basismengen-
*                *** einheit defaultmaessig belegt ist.
  IF g_0401_meinh_input <> g_s_0401_mara-meins.

*                *** Bemerkung: Falls ME ungültig ist, Fehlerausgabe in
*                *** Unterprogramm.
    PERFORM check_material_unit
                USING
                   g_0401_matnr
                   g_s_0401_mara-meins
                   g_0401_meinh_input.

  ENDIF.

*                *** Belege die Mengenfelder des Dynpros mit der Alt.-ME
  g_0401_meinh         =  g_0401_meinh_input.
  g_0401_meinh_umrech  =  g_0401_meinh_input.

ENDMODULE.                 " INPUT_CHECK_MATNR_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  INPUT_CHECK_BSTME_0401  INPUT
*&---------------------------------------------------------------------*
*       Prüfe den Eingabewert zur Bestell-ME des DynPro 401 auf Korrekt-
*       heit und bestimme den Default-Wert (Eingabe-Mengeneinheit).
*----------------------------------------------------------------------*
MODULE input_check_bstme_0401 INPUT.

*                *** Setze die Exception auf Farbe rot.
  g_0401_light = c_red.

*                *** die Basismengeneinheit zu dem Material (mara-meins)
*                *** wurde schon in input_check_matnr_0401 bestimmt.

*                *** Falls Bestellmengeneinheit nicht belegt, ist
*                *** mara-bstme = LEER
*                *** => Default-Belegung der Bestellmengeneinheit
*                ***    mit der Eingabe-Mengeneinheit.
  IF g_0401_bstme IS INITIAL.
    g_0401_bstme = g_0401_meinh_input.
  ELSE.
*                *** Untersuche, ob die eingegebe Bestellmengeneinheit
*                *** eine gültige zum Material ist.
    PERFORM check_material_unit
                    USING
                       g_0401_matnr
                       g_s_0401_mara-meins
                       g_0401_bstme.

  ENDIF.

ENDMODULE.                 " INPUT_CHECK_BSTME_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  INPUT_CHECK_AMOUNT_0401  INPUT
*&---------------------------------------------------------------------*
*       Prüfe die eingegebenen Mengenwerte auf Korrektheit und belege
*       bei falscher Belegung (Menge <= 0) die Mengen mit Default-Werten
*----------------------------------------------------------------------*
MODULE input_check_amount_0401 INPUT.

  DATA: l_help_f  TYPE f.

*                *** Die eingegebene Von-Menge darf nicht größer
*                *** sein als die eingegebene Bis-Menge!
*                ***  g_0401_in_from_amount > g_0401_in_to_amount
*                ***       => FEHLER!!!!
  IF g_0401_in_from_amount > g_0401_in_to_amount.
    MESSAGE e057.
  ENDIF.

*                *** Die Von-Menge und Bis-Menge müssen groesser
*                *** als 0 sein.
*                *** g_0401_in_from_amount <= 0 => Default-Wert 1
  IF g_0401_in_from_amount <= 0.
    g_0401_in_from_amount = c_0401_in_from_amount.
  ENDIF.
*                *** g_0401_in_to_amount   <= 0 => Default-Wert 100
  IF g_0401_in_to_amount <= 0.
    g_0401_in_to_amount = c_0401_in_to_amount.
  ENDIF.

*                *** Die Schrittweite muß größer als 0 sein
*                *** g_401_in_step         <= 0 => Default-Wert 1
  IF g_0401_in_step <= 0.
    g_0401_in_step = c_0401_in_step.
  ENDIF.


*                *** Auf Grund schlechter Antwortzeiten, sollten
*                *** nicht mehr als 10000 Werte simuliert werden
  l_help_f = (   g_0401_in_to_amount
               - g_0401_in_from_amount
               + 1 )
             / g_0401_in_step.

  IF  l_help_f > c_max_sim_num.

    MESSAGE e003(lumer)
       WITH c_max_sim_num.

    RETURN.

  ENDIF.



ENDMODULE.                 " INPUT_CHECK_AMOUNT_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  EVALUATE_SAVE_OK_CODE_0401  INPUT
*&---------------------------------------------------------------------*
*       Verzweige in Abhaengigkeit von SAVE_OK_CODE in das
*       Ausgabe-DynPro
*----------------------------------------------------------------------*
MODULE evaluate_save_ok_code_0401 INPUT.

  save_ok_code = ok_code.
  CLEAR ok_code.

  CASE save_ok_code.

    WHEN c_fc_exec_range.
*                *** Simulation für eine Range-Eingabe durchführen
      PERFORM simu_rdprf_range.

    WHEN c_fc_exec_value.
*                *** Simulation eines Einzelwerts durchführen
      PERFORM simu_rdprf_single_value.

*                *** Setze die Exception auf Farbe grün.
      g_0401_light = c_green.

    WHEN c_fc_detailrdprf.
*                *** Details zur Defintion des Rundungsprofils
*                *** anzeigen
      PERFORM show_detail_rdprf
        USING
          g_0401_rdprf
          g_0401_werks.

  ENDCASE.

ENDMODULE.                 " EVALUATE_SAVE_OK_CODE_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  input_check_single_value_0401  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE input_check_single_value_0401 INPUT.

*                *** Einzelwert <= 0 => Default-Wert 1
  IF g_0401_single_value <= 0.

    g_0401_single_value = c_default_single_value.

  ENDIF.

*                *** Eingabe wurde (falls nicht der gleiche Wert
*                *** wieder eingegeben wurde) verändert. Setze
*                *** Exception auf Farbe rot.
  g_0401_light = c_red.

ENDMODULE.                 " input_check_single_value_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_mara_bstme_0401  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_mara_bstme_0401 INPUT.

  PERFORM f4_help_qt_units_matnr
              USING
                 'G_0401_BSTME'
                 g_s_0401_general
                 'G_0401_MATNR'
              CHANGING
                 g_t_0401_qt_units.

ENDMODULE.                 " f4_help_mara_bstme_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_marm_meinh_0401  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_marm_meinh_0401 INPUT.

  PERFORM f4_help_qt_units_matnr
              USING
                 'G_0401_MEINH_INPUT'
                 g_s_0401_general
                 'G_0401_MATNR'
              CHANGING
                 g_t_0401_qt_units.

ENDMODULE.                 " f4_help_marm_meinh_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_meinh_0401  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_meinh_0401 INPUT.

  PERFORM f4_help_qt_units_matnr
              USING
                 'G_0401_MEINH'
                 g_s_0401_general
                 'G_0401_MATNR'
              CHANGING
                 g_t_0401_qt_units.

ENDMODULE.                 " f4_help_meinh_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_meinh_rounded_0401  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_meinh_rounded_0401 INPUT.

  PERFORM f4_help_qt_units_matnr
              USING
                 'G_0401_MEINH_ROUNDED'
                 g_s_0401_general
                 'G_0401_MATNR'
              CHANGING
                 g_t_0401_qt_units.

ENDMODULE.                 " f4_help_meinh_rounded_0401  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_meinh_umrech_0401  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_meinh_umrech_0401 INPUT.

  PERFORM f4_help_qt_units_matnr
              USING
                 'G_0401_MEINH_UMRECH'
                 g_s_0401_general
                 'G_0401_MATNR'
              CHANGING
                 g_t_0401_qt_units.

ENDMODULE.                 " f4_help_meinh_umrech_0401  INPUT

*
* 
