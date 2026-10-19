FUNCTION md_allowed_quantity_unit.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_S_GENERAL) TYPE  MDR1INALLOWEDQTUNIT
*"     VALUE(I_S_MARA) TYPE  MARA OPTIONAL
*"     VALUE(I_S_EINA) TYPE  EINA OPTIONAL
*"     VALUE(I_S_EINE) TYPE  EINE OPTIONAL
*"     VALUE(I_S_MARC) TYPE  MARC OPTIONAL
*"     VALUE(I_S_MARC_2) TYPE  MARC OPTIONAL
*"     VALUE(I_S_MVKE) TYPE  MVKE OPTIONAL
*"     VALUE(I_S_KNMT) TYPE  KNMT OPTIONAL
*"     VALUE(I_S_KNVV) TYPE  KNVV OPTIONAL
*"  TABLES
*"      O_T_QT_UNITS TYPE  MDR1TOUTALLOWEDQTUNIT
*"  EXCEPTIONS
*"      BAD_PARAMS
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.01.99  99A  mwe         Grundversion
*- @001  04.05.00  46C  mwe         Basis-ME bei Material (Standard)
*-                                  nicht in der MARM eingetragen
*-                                  Korrektur zu Hinweis: 300836
*-       12.09.01  470  mbi         Schnitstelle RFC-fähig gemacht
*-                                  (ohne Änderungsmarke!)
*-----------------------------------------------------------------------

*                *** Prüfe, ob die Eingabe korrekt ist
  PERFORM check_input_u10  USING  i_s_general
                                  i_s_mara
                                  i_s_eina
                                  i_s_eine.

*                *** Bestimme noch alle notwendigen Daten
* ??? => in 1. Version nicht notwendig!!!  PERFORM determine_date_u10.

*                *** Bestimme die einzelnen Daten (als Default-Werte),
*                *** Wichtig:  Die Werte können abschließend noch ein-
*                ***           individuell mit einem USER-EXIT ver-
*                ***           ändert werden

  IF i_s_general-flagdefqtunit = c_yes.
*                *** (1) Bestimme die Default-ME
    PERFORM determine_def_qt_unit  TABLES o_t_qt_units
                                   USING  i_s_general
                                          i_s_mara
                                          i_s_eina
                                          i_s_marc_2
                                          i_s_mvke.
  ENDIF.

  IF i_s_general-flagvenqtunit = c_yes.
*                *** (2) Bestimme die ME-Gruppe des Lieferanten
    PERFORM determine_ven_qt_unit  TABLES o_t_qt_units
                                   USING  i_s_general
*$@001 Anfang MWE-HW-300836
                                          i_s_mara
*$@001 Ende MWE-HW-300836
                                          i_s_eine
                                          i_s_marc_2                    " note 2081705
                                          i_s_mvke.
  ENDIF.

  IF i_s_general-flagbuyqtunit = c_yes.
*                *** (3) Bestimme die ME-Gruppe des Abnehmers
    PERFORM determine_buyer_qt_unit  TABLES o_t_qt_units
                                     USING  i_s_general
*$@001 Anfang MWE-HW-300836
                                            i_s_mara
*$@001 Ende MWE-HW-300836
                                            i_s_marc
                                            i_s_knmt
                                            i_s_knvv.
  ENDIF.

  IF i_s_general-flagallqtunit = c_yes.
*                *** (4) Bestimme die erlaubten logistischen ME
    PERFORM determine_allowed_qt_unit TABLES o_t_qt_units
                                      USING  i_s_general
                                             i_s_mara
                                             i_s_eina
                                             i_s_mvke.
  ENDIF.

*                *** Individuelle Bestimmung mit Hilfe eines USER-EXIT
  PERFORM call_user_exit_002 TABLES o_t_qt_units
                             USING  i_s_general
                                    i_s_mara
                                    i_s_eina
                                    i_s_eine
                                    i_s_marc
                                    i_s_marc_2
                                    i_s_mvke
                                    i_s_knmt
                                    i_s_knvv.

ENDFUNCTION.

*
* 
