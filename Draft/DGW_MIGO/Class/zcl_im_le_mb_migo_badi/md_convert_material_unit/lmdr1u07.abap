FUNCTION md_rounding_value.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_QUANTITY) TYPE  MDR1P_P_16_DEC_14
*"     REFERENCE(I_VALUE) TYPE  MDR1P_P_16_DEC_14
*"     REFERENCE(I_WITH_MINUTES) TYPE  C DEFAULT ' '
*"  EXPORTING
*"     REFERENCE(E_ROUNDING_QUANTITY) TYPE  MDR1P_P_16_DEC_14
*"  TABLES
*"      CH_T_ROUNDING_REASONS TYPE  MDR1P_T_RUNDUNGSGRUND OPTIONAL
*"      CH_T_MINUTES TYPE  MDR1P_T_RUNDUNGSGRUND OPTIONAL
*"  EXCEPTIONS
*"      INPUT_LESS_OR_EQUAL_ZERO
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       ??.??.??  ???  mwe         Grundversion
*- @001  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*-----------------------------------------------------------------------

*                *** lokale Daten-Deklaration
  DATA: l_complete(16)           TYPE  p  DECIMALS  14,
        l_rest(16)               TYPE  p  DECIMALS  14,
        l_quantity(16)           TYPE  p  DECIMALS  14,
        l_value(16)              TYPE  p  DECIMALS  14,
        l_rounding_quantity(16)  TYPE  p  DECIMALS  14.

*                *** Initialisierung: lokale und Ausgabe-Daten
  CLEAR: l_complete,
         l_rest,
         e_rounding_quantity.

  l_quantity  =  i_quantity.
  l_value     =  i_value.

*                *** Prüfe auf korrekte Versorgung der Eingabe-Parameter
  IF    l_quantity <= 0
     OR l_value    <= 0.
    MESSAGE e082 WITH 'MD_ROUNDING_VALUE'
            RAISING input_less_or_equal_zero.
  ENDIF.

*                *** Durchführung der Rundung:

*                *** (1) Bestimme ganzzahligen Anteil
  l_complete = l_quantity  DIV  l_value.

*                *** (2) Bestimme Rest
  l_rest     = l_quantity  MOD  l_value.

*                *** (3) Entscheide über die Rundung
* Begin-of-Note-762408
*  IF l_rest > 0.
  IF l_rest > c_epsylon.
* End-of-Note-762408
*                ***     => Rundung durchführen
    l_rounding_quantity = ( l_complete + 1 ) * l_value.
*                ***     => setze Rundungsgrund = Rundungswert
    PERFORM enter_rounding_reason TABLES ch_t_rounding_reasons
                                  USING  mdr1p_c_rundungswert.

  ELSE.
*                ***     => KEINE Rundung durchführen
    l_rounding_quantity = l_quantity.

  ENDIF.

  e_rounding_quantity = l_rounding_quantity.

*                *** Protokoll wegschreiben, wenn verlangt
  IF i_with_minutes = c_yes.
*                *** ??? => da ist noch einiges offen!!!
  ENDIF.

ENDFUNCTION.

*
* 
