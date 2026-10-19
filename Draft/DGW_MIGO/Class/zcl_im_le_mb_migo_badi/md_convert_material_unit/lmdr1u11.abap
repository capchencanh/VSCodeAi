FUNCTION f4_allowed_quantity_unit.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_S_GENERAL) TYPE  MDR1INALLOWEDQTUNIT
*"     VALUE(I_DIALOG) TYPE  MDR1DIALOG
*"     VALUE(I_DYNPPROG) TYPE  SYREPID OPTIONAL
*"     VALUE(I_DYNPNR) LIKE  SY-DYNNR OPTIONAL
*"     VALUE(I_DYNPROFIELD) LIKE  HELP_INFO-DYNPROFLD OPTIONAL
*"     VALUE(I_STEPL) LIKE  HELP_INFO-STEPL DEFAULT 0
*"     VALUE(I_DISPLAY) LIKE  DDREFSTRUC-BOOL OPTIONAL
*"     VALUE(I_TITEL) TYPE  MDR1TITEL OPTIONAL
*"  TABLES
*"      O_T_QT_UNITS TYPE  MDR1TOUTALLOWEDQTUNIT OPTIONAL
*"  EXCEPTIONS
*"      BAD_PARAMS
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       06.02.99  99A  mwe         Grundversion
*-       12.09.01  470  mbi         Schnittstelle RFC-fähig gemacht
*-                                  (ohne Änderungsmarke!)
*-----------------------------------------------------------------------

  DATA:  l_s_general  TYPE  mdr1p_s_in_allowed_qt_unit,
         l_s_mara     LIKE mara,
         l_s_eina     LIKE eina,
         l_s_eine     LIKE eine,
         l_s_marc     LIKE marc,
         l_s_marc_2   LIKE marc,
         l_s_mvke     LIKE mvke,
         l_s_knmt     LIKE knmt,
         l_s_knvv     LIKE knvv,
         l_t_qt_units TYPE mdr1p_s_out_allowed_qt_unit
                      OCCURS 0  WITH HEADER LINE,
         l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params,
         l_index      LIKE sy-tabix,
         l_s_t006a    LIKE t006a.

  CLEAR: l_s_qt_units_params.

  l_s_general = i_s_general.

*                *** Prüfe, ob die Eingabe korrekt ist
  PERFORM check_input_u11  USING  l_s_general
                                  i_dialog.

*                *** DB-Zugriffe nur, wenn Parameter zur Bestimmung
*                *** der erlaubten ME nicht von Aufrufstelle vorgegeben
*                *** sind
  MOVE-CORRESPONDING l_s_general TO l_s_qt_units_params.

  IF l_s_qt_units_params IS INITIAL.
*                *** Bestimme je nach Sicht und Funktion die weiteren
*                *** Daten
    PERFORM read_data_u11 USING    i_dialog
                          CHANGING l_s_general
                                   l_s_mara
                                   l_s_eina
                                   l_s_eine
                                   l_s_marc
                                   l_s_marc_2
                                   l_s_mvke
                                   l_s_knmt
                                   l_s_knvv.
  ENDIF.

*                *** Bestimme mit Hilfe des FB:
*                ***     MD_ALLOWED_QUANTITY_UNIT
*                *** Die Daten, die in der F4-Hilfe vorgeschlagen
*                *** werden.
  IF i_dialog = c_yes.
*                *** - im Dialog-Fall nur I-Messages ausgeben!!!
    PERFORM call_allowed_quantity_unit_f4  TABLES    l_t_qt_units
                                           USING     l_s_general
                                                     l_s_mara
                                                     l_s_eina
                                                     l_s_eine
                                                     l_s_marc
                                                     l_s_marc_2
                                                     l_s_mvke
                                                     l_s_knmt
                                                     l_s_knvv.
  ELSE.
    PERFORM call_allowed_quantity_unit  TABLES    l_t_qt_units
                                        USING     l_s_general
                                                  l_s_mara
                                                  l_s_eina
                                                  l_s_eine
                                                  l_s_marc
                                                  l_s_marc_2
                                                  l_s_mvke
                                                  l_s_knmt
                                                  l_s_knvv.
  ENDIF.

*                *** Bestimme zu den ME die entsprechenden Langtexte
  LOOP AT  l_t_qt_units.

    l_index = sy-tabix.
    CLEAR: l_s_t006a.

    PERFORM read_t006a USING    l_t_qt_units-meinh
                       CHANGING l_s_t006a.

    l_t_qt_units-msehl = l_s_t006a-msehl.

    MODIFY l_t_qt_units
     INDEX l_index.

  ENDLOOP.

*                *** Unterscheide bei der Rückgabe der Werte zwischen:
  IF i_dialog = c_yes.
*                *** - Mit Dialog-Ausgabe:
*                ***   Ausgabe der bestimmten Vorschlagswerte
*                ***   Wichtig: Aufruf mit ursprünglicher Eingabe!!!
    PERFORM call_if_int_table_value_req  TABLES  l_t_qt_units
                                         USING   i_s_general  " <- !!!
                                                 i_dynpprog
                                                 i_dynpnr
                                                 i_dynprofield
                                                 i_stepl
                                                 i_display
                                                 i_titel.
  ELSE.
*                *** - Ohne Dialog-Ausgabe:
    PERFORM allowed_qtunits_without_dialog TABLES l_t_qt_units
                                                  o_t_qt_units
                                           USING  i_s_general.
  ENDIF.

ENDFUNCTION.

*
* 
