FUNCTION md_rm_invalid_deci_place.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_QUANTITY) TYPE  MDR1P_P_16_DEC_14
*"     VALUE(I_UNIT) LIKE  MARM-MEINH
*"     VALUE(I_VALID_DECI) LIKE  T006-ANDEC
*"     VALUE(I_WITH_MINUTES) TYPE  C OPTIONAL
*"  EXPORTING
*"     VALUE(E_VALID_QUANTITY) TYPE  MDR1P_P_16_DEC_14
*"  TABLES
*"      CH_T_ROUNDING_REASONS TYPE  MDR1P_T_RUNDUNGSGRUND OPTIONAL
*"  EXCEPTIONS
*"      INPUT_LESS_ZERO
*"      USER_EXIT_ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*- @001  11.08.99  99B  mwe         Beim Abschneiden von ungültigen
*                                   Dezimalstellen kann es zu unge-
*                                   wollten Überläufen kommen
*                                   HW: 167078
*- @002  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @003  26.11.99  46C  mwe         Ungewollte Rundung bei
*-                                  Multiplikation mit P-Feldern
*-                                  ohne Nachkommastellen
*-                                  Korrektur zu Hinweis: 186492
*-----------------------------------------------------------------------

*                *** lokale Daten-Deklaration
  DATA:  l_user_exit_valid_deci LIKE t006-andec,
         l_help_qty(16)  TYPE  p DECIMALS 14,
*$@001 Anfang MWE-HW-167078
         l_mul(16)       TYPE  p,
         l_div_1(16)     TYPE  p,
         l_trunc(16)     TYPE  p,
*$@001 Ende MWE-HW-167078
*$@003 Anfang MWE-HW-186492
         l_truncn        TYPE  mdr1p_p_16_dec_14.
*$@003 Ende MWE-HW-186492

*                *** Initialisierung: lokale und Ausgabe-Daten
  CLEAR: l_user_exit_valid_deci,
         e_valid_quantity,
         l_help_qty.

*                *** Prüfe auf korrekte Versorgung der Eingabe-Parameter
  IF i_valid_deci < 0.
    MESSAGE e083 WITH 'MD_RM_INVALID_DECI_PLACE'
         RAISING input_less_zero.
  ENDIF.

*                *** Default-Belegung der Ausgabemenge, und der Anzahl
*                *** der gültigen Dezimalstellen laut User-Exit
  e_valid_quantity        = i_quantity.
  l_user_exit_valid_deci  = i_valid_deci.

*                *** Entferne ungültige Dezimalstellen mit Hilfe eines
*                *** USER-EXITS
  PERFORM call_user_exit_001 USING     i_quantity
                                       i_unit
                                       i_valid_deci
                             CHANGING  e_valid_quantity
                                       l_user_exit_valid_deci.

*                *** Entfernen mit USER-EXIT erfolgreich
  IF     e_valid_quantity       = i_quantity
     AND l_user_exit_valid_deci = i_valid_deci.
*                *** üngültige Dezimalstellen einfach ohne Rundung
*                *** abschneiden, wenn USER-EXIT nicht erfolgreich
*                *** (Default-Abschneidung auf 14-NachStellen)
    l_help_qty  =  i_quantity.

    IF i_valid_deci = 0.
*                *** Es werden alle Dezimalstellen entfernt
      l_help_qty  =  trunc( l_help_qty ).
    ELSE.
*$@001 Anfang MWE-HW-167078
*$      l_help_qty  =    ( trunc( l_help_qty * ( 10 ** i_valid_deci ) )
*$                     / ( 10 ** i_valid_deci ).
*                *** Abschneiden Nachkommastellen auf max.
*                *** 14 Nachkommastellen wegen Feldüberlauf
*                *** (intern wird nur mit 14 Nachkommastellen
*                *** gerechnet, daher bei > 14 Nachkommastellen
*                *** kein Abschneiden nötig!)
      IF i_valid_deci < 15.
        l_mul       =  10          **   i_valid_deci.
        l_div_1     =  l_help_qty  DIV  1.
        l_help_qty  =  l_help_qty  -    l_div_1.
*$@003 Anfang MWE-HW-186492
*$        l_trunc     =  l_help_qty  *    l_mul.
        l_truncn    =  l_help_qty  *    l_mul.
        l_trunc     =  trunc( l_truncn ).
*$@003 Ende MWE-HW-186492
        l_help_qty  =  l_trunc     /    l_mul.
        l_help_qty  =  l_help_qty  +    l_div_1.
      ENDIF.
*$@001 Ende MWE-HW-167078
    ENDIF.

    e_valid_quantity  =  l_help_qty.

  ENDIF.

*                *** Entscheide über Rundungsgrund
  IF e_valid_quantity <> i_quantity.
*                *** => setze Rundungsgrund = Dezimalstellen-Entfernen
    PERFORM enter_rounding_reason TABLES ch_t_rounding_reasons
                                  USING  mdr1p_c_decimals.
  ENDIF.


*                *** Protokoll wegschreiben, wenn verlangt
  IF i_with_minutes = c_yes.
*                *** ??? => da ist noch einiges offen!!!
  ENDIF.

ENDFUNCTION.

*
* 
