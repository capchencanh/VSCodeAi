*-------------------------------------------------------------------
***INCLUDE LMDR1I02 .
*-------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.08.97  400  welterm     Grundversion des Eingabe-DynPro
*-                                  für die Simulation eines dyn.
*-                                  Rundungsprofile.
*- @001  16.04.98  40c  welterm     Eweiterungen zu 40c:
*-                                  - keine Fehlermeldung wenn der
*-                                    Text zu einem Material nicht
*-                                    existiert.
*- @008  27.08.99  99A  kast        Erweiterung der Simulation um eine
*-                                  Schrittweite
*-       01.01.02  4.70 mwe         Altes Coding auskommentiert
*-                                  (ohne Änderungsmarke)
*-----------------------------------------------------------------------
*-----------------------------------------------------------------------
*
**&---------------------------------------------------------------------
*
**&      Module  ABBRUCH_0400  INPUT
**&---------------------------------------------------------------------
*
**       Abbruch des EingabeDynbros 400
**----------------------------------------------------------------------
*
*MODULE exit_0400 INPUT.
*
*  CLEAR ok_code.
*
*  LEAVE TO SCREEN 0.
*
*ENDMODULE.                 " ABBRUCH_0400  INPUT
*
**&---------------------------------------------------------------------
*
**&      Module  INPUT_CHECK_MATNR_0400  INPUT
**&---------------------------------------------------------------------
*
**       Prüfe die Eingabewerte zum Material des DynPro 400 auf Korrekt-
**       heit und bestimme den Default-Wert (BasisMengeneinheit).
**       Weiter wird der Material-Namen bestimmt.
**----------------------------------------------------------------------
*
*MODULE input_check_matnr_0400 INPUT.
*
**                *** Rette die Eingabe der Bestellmengeneinheit
*  g_help_bstme = mara-bstme.
**                *** Lese die Basismengeneinheit zu dem Material aus
**                *** MARA => Plausi auch als Match-Code fuer Eingabe-
**                *** feld moeglich.
*  PERFORM read_mara USING mara-matnr.
**                *** alter Wert der Eingabe der Bestellmengeneinheit
**                *** herstellen
*  mara-bstme = g_help_bstme.
*  CLEAR g_help_bstme.
*
*  IF sy-subrc <> 0.
*    MESSAGE e058.                " Fehlerausgabe: Materialnummer
*    "                existiert nicht!
*  ELSE.
**                *** Wenn das Material in MARA existiert und die
**                *** Eingabe-Mengeneinheit nicht belegt ist marm-meinh
**                *** = LEER => Default-Belegung der
*Eingabemengeneinheit
**                *** mit der Basismengeneinheit.
*    IF marm-meinh IS INITIAL.
*      marm-meinh = mara-meins.
*    ENDIF.
*  ENDIF.
*
**                *** Lese den Namen des Artikels aus der MAKT
*  PERFORM read_single_makt USING mara-matnr.
*  IF sy-subrc <> 0.
**$@001 Anfang
**$    MESSAGE e061.                " Fehlerausgabe: Der Materialtextex-
*    CLEAR makt-maktx.
**$@001 Ende
*  ENDIF.
*
**                *** Untersuche ob die eingegeben Mengeneinheit
**                *** zu dem Material in MARM existiert, wenn die
**                *** Eingabe-Mengeneinheit nicht mit der Basismengen-
**                *** einheit defaultmaessig belegt ist.
*  IF marm-meinh <> mara-meins.
*    PERFORM read_single_marm USING    mara-matnr
*                                      marm-meinh.
*    IF sy-subrc <> 0.
*      MESSAGE e059.              " Fehlerausgabe: Mengeneiheitexistiert
*      "                nicht zu dem Material!
*    ENDIF.
*  ENDIF.
*
*ENDMODULE.                 " INPUT_CHECK_MATNR_0400  INPUT
*
**&---------------------------------------------------------------------
*
**&      Module  INPUT_CHECK_BSTME_0400  INPUT
**&---------------------------------------------------------------------
*
**       Prüfe den Eingabewert zur Bestell-ME des DynPro 400 aufKorrekt-
**       heit und bestimme den Default-Wert (EingabeMengeneinheit).
**----------------------------------------------------------------------
*
*MODULE input_check_bstme_0400 INPUT.
*
**                *** die Basismengeneinheit zu dem Material(mara-meins)
**                *** wurde schon in input_check_matnr_0400 bestimmt.
*
**                *** Wenn die Bestellmengeneinheit nicht belegt ist
**                *** mara-bstme = LEER
**                *** => Default-Belegung der Bestellmengeneinheit
**                ***    mit der Eingabe-Mengeneinheit.
*  IF mara-bstme IS INITIAL.
*    mara-bstme = marm-meinh.
*  ELSE.
**                *** Untersuche ob die eingegeben Bestellmengeneinheit
**                *** zu dem Material in MARM existiert.
*    PERFORM read_single_marm USING    mara-matnr
*                                      mara-bstme.
*    IF sy-subrc <> 0.
*      MESSAGE e059.              " Fehlerausgabe: Mengeneiheitexistiert
*      "                nicht zu dem Material!
*    ENDIF.
*  ENDIF.
*
*ENDMODULE.                 " INPUT_CHECK_BSTME_0400  INPUT
*
**&---------------------------------------------------------------------
*
**&      Module  INPUT_CHECK_AMOUNT_0400  INPUT
**&---------------------------------------------------------------------
*
**       Prüfe die eingegebenen Mengenwerte auf Korrektheit und belege
**       bei falscher Belegung (Menge <= 0) die Mengen mitDefault-Werten
**----------------------------------------------------------------------
*
*MODULE input_check_amount_0400 INPUT.
*
**                *** Die eingegebene Von-Menge darf nicht größer
**                *** sein als die eingegebene Bis-Menge!
**                ***  g_0400_in_from_amount > g_0400_in_to_amount
**                ***       => FEHLER!!!!
*  IF g_0400_in_from_amount > g_0400_in_to_amount.
*    MESSAGE e057.
*  ENDIF.
*
**                *** Die Von-Menge und Bis-Menge müssen groesser
**                *** als 0 sein.
**                *** g_0400_in_from_amount <= 0 => Default-Wert 1
*  IF g_0400_in_from_amount <= 0.
*    g_0400_in_from_amount = c_0400_in_from_amount.
*  ENDIF.
**                *** g_0400_in_to_amount   <= 0 => Default-Wert 100
*  IF g_0400_in_to_amount <= 0.
*    g_0400_in_to_amount = c_0400_in_to_amount.
*  ENDIF.
*
**                *** Die Schrittweite muß größer als 0 sein
**                *** g_400_in_step         <= 0 => Default-Wert 1
*  IF g_0400_in_step <= 0.                                   " @008
*    g_0400_in_step = c_0400_in_step.                        " @008
*  ENDIF.                                                    " @008
*
*ENDMODULE.                 " INPUT_CHECK_AMOUNT_0400  INPUT
*
**&---------------------------------------------------------------------
*
**&      Module  WERTE_SAVE_OK_CODE_IN_0400_AUS  INPUT
**&---------------------------------------------------------------------
*
**       Verzweige in Abhaengigkeit von SAVE_OK_CODE in das
**       Ausgabe-DynPro
**----------------------------------------------------------------------
*
*MODULE evaluate_save_ok_code_0400 INPUT.
*
*  save_ok_code = ok_code.
*  CLEAR ok_code.
*
*  IF save_ok_code = c_fc_cont.
*
**                *** Verzweige in  das DynPro 600 zur Ausagbe der
**                *** Simulationswerte in tabellarischer Form
*    CALL SCREEN 0600
*         STARTING AT  50  1
*         ENDING   AT  115 26.
*
*  ENDIF.
*
*ENDMODULE.                 " WERTE_SAVE_OK_CODE_IN_0400_AUS  INPUT

*
* 
