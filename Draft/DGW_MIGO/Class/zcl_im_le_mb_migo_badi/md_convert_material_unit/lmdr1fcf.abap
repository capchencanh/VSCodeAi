*----------------------------------------------------------------------*
***INCLUDE LMDR1FCF .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       06.02.99  99A  mwe         Grundversion
*- @001  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @002  01.12.99  46C  mwe         Berücksichtigung von Konsignations-
*-                                  Infosätze
*-                                  Korrektur zu Hinweis: 186918
*- @003  16.12.99  46C  mwe         Bei der Dialogausgabe auch die
*-                                  Umrechnungsfaktoren in BAsis-ME
*-                                  ausgeben!!!
*- @004  04.04.01  470  mwe         Unicode-Änderungen
*-                                  - Parameter typisieren
*-                                  - entfernen von veraltertem Codeing
*-                                  (Marke: MWE-ENTW-470-UNICODE )
*- @005  24.09.01  470  mbi         Unicode-Änderungen
*-                                  - alte F4-Hilfe nicht mehr nutzbar!
*-                                  (Marke: #mbi 4.70 UNICODE )
*- @006  24.09.01  470  mbi         Realisierung SMAD-Punkte
*-                                  - Verbesserung der Rundungs-
*-                                    Simulation
*-                                  (Marke: #mbi 4.70 RoundSimu )
*- @007  30.10.01  470  hwi         Realisierung SMAD-Punkte
*-                                  - Neues Customizing
*-                                  4 neue Formroutinen zur Realisierung
*-                                  des Customizings hinzugefügt:
*-                                  call_customizing_read
*-                                  change_appl_to_cust
*-                                  change_appl_to_SAP
*-                                  call_purpar_determine
*-                                  (Marke: HWI 4.70 customizing of
*-                                          logistical rounding)
*- @008  01.01.02 470   mwe         Coding aus LMDR1F06 übernommen
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  CALL_ALLOWED_QUANTITY_UNIT
*&---------------------------------------------------------------------*
*       Bestimme möglichen F4-Werte mit Hilfe des FB
*       MD_ALLOWED_QUANTITY_UNIT
*----------------------------------------------------------------------*
*      <--P_T_QT_UNITS    Tabelle mit den bestimmten Werten
*      -->P_L_S_GENERAL     allgemeine Eingabestruktur
*      -->P_L_S_MARA
*      -->P_L_S_EINA
*      -->P_L_S_EINE
*      -->P_L_S_MARC
*      -->P_L_S_MARC_2
*      -->P_L_S_MVKE
*      -->P_L_S_KNMT
*      -->P_L_S_KNVV
*----------------------------------------------------------------------*
FORM call_allowed_quantity_unit
                  TABLES
                    p_t_qt_units TYPE  mdr1p_t_out_allowed_qt_unit
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_mara     TYPE mara
                    p_s_eina     TYPE eina
                    p_s_eine     TYPE eine
                    p_s_marc     TYPE marc
                    p_s_marc_2   TYPE marc
                    p_s_mvke     TYPE mvke
                    p_s_knmt     TYPE knmt
                    p_s_knvv     TYPE knvv.

  IF p_s_general-flagallqtunit = c_yes.
*                *** Bei der Bestimmung der erlaubten log. ME muß der
*                *** Baustein mit der kompletten Funkt. aufgerufen
*                *** werden!!!
    p_s_general-flagdefqtunit  =  c_yes.
    p_s_general-flagvenqtunit  =  c_yes.
    p_s_general-flagbuyqtunit  =  c_yes.
  ENDIF.

  CLEAR: sy-msgid.

  CALL FUNCTION 'MD_ALLOWED_QUANTITY_UNIT'
    EXPORTING
      i_s_general   = p_s_general
      i_s_mara      = p_s_mara
      i_s_eina      = p_s_eina
      i_s_eine      = p_s_eine
      i_s_marc      = p_s_marc
      i_s_marc_2    = p_s_marc_2
      i_s_mvke      = p_s_mvke
      i_s_knmt      = p_s_knmt
      i_s_knvv      = p_s_knvv
    TABLES
      o_t_qt_units  = p_t_qt_units
    EXCEPTIONS
      bad_params    = 1
      error         = 2
      error_message = 98         " Ausnahme bei Meldungen
      OTHERS        = 99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'MD_ALLOWED_QUANTITY_UNIT'
                           RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " CALL_ALLOWED_QUANTITY_UNIT

*&---------------------------------------------------------------------*
*&      Form  CALL_ALLOWED_QUANTITY_UNIT_F4
*&---------------------------------------------------------------------*
*       Bestimme möglichen F4-Werte mit Hilfe des FB
*       MD_ALLOWED_QUANTITY_UNIT
*----------------------------------------------------------------------*
*      <--P_T_QT_UNITS    Tabelle mit den bestimmten Werten
*      -->P_L_S_GENERAL     allgemeine Eingabestruktur
*      -->P_L_S_MARA
*      -->P_L_S_EINA
*      -->P_L_S_EINE
*      -->P_L_S_MARC
*      -->P_L_S_MARC_2
*      -->P_L_S_MVKE
*      -->P_L_S_KNMT
*      -->P_L_S_KNVV
*----------------------------------------------------------------------*
FORM call_allowed_quantity_unit_f4
                  TABLES
                    p_t_qt_units TYPE  mdr1p_t_out_allowed_qt_unit
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_mara     TYPE mara
                    p_s_eina     TYPE eina
                    p_s_eine     TYPE eine
                    p_s_marc     TYPE marc
                    p_s_marc_2   TYPE marc
                    p_s_mvke     TYPE mvke
                    p_s_knmt     TYPE knmt
                    p_s_knvv     TYPE knvv.

  IF p_s_general-flagallqtunit = c_yes.
*                *** Bei der Bestimmung der erlaubten log. ME muß der
*                *** Baustein mit der kompletten Funkt. aufgerufen
*                *** werden!!!
    p_s_general-flagdefqtunit  =  c_yes.
    p_s_general-flagvenqtunit  =  c_yes.
    p_s_general-flagbuyqtunit  =  c_yes.
  ENDIF.

  CLEAR: sy-msgid.

  CALL FUNCTION 'MD_ALLOWED_QUANTITY_UNIT'
    EXPORTING
      i_s_general   = p_s_general
      i_s_mara      = p_s_mara
      i_s_eina      = p_s_eina
      i_s_eine      = p_s_eine
      i_s_marc      = p_s_marc
      i_s_marc_2    = p_s_marc_2
      i_s_mvke      = p_s_mvke
      i_s_knmt      = p_s_knmt
      i_s_knvv      = p_s_knvv
    TABLES
      o_t_qt_units  = p_t_qt_units
    EXCEPTIONS
      bad_params    = 1
      error         = 2
      error_message = 98         " Ausnahme bei Meldungen
      OTHERS        = 99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE c_msgty_i NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE i001(rpugen) WITH 'MD_ALLOWED_QUANTITY_UNIT'
                           RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " CALL_ALLOWED_QUANTITY_UNIT_f4

*&---------------------------------------------------------------------*
*&      Form  CALL_IF_INT_TABLE_VALUE_REQ
*&---------------------------------------------------------------------*
*       Aufruf des FB F4IF_INT_TABLE_VALUE_REQUEST zur der Anzeige
*       F4-Werte
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS  Bestimmte ME
*      -->P_S_GENERAL   ursprüngliche Eingabe-Werte (unverändert!!!)
*----------------------------------------------------------------------*
FORM call_if_int_table_value_req
                  TABLES
                    p_t_qt_units   TYPE  mdr1p_t_out_allowed_qt_unit
                  USING
                    p_s_general    TYPE  mdr1p_s_in_allowed_qt_unit
                    p_dynpprog     LIKE  sy-repid
                    p_dynpnr       LIKE  sy-dynnr
                    p_dynprofield  LIKE  help_info-dynprofld
                    p_stepl        LIKE  help_info-stepl
                    p_display      LIKE  ddrefstruc-bool
                    p_titel        TYPE  c.

  DATA: l_window_titel(100)       TYPE  c ,
        BEGIN OF  value_tab  OCCURS 0,
          meinh          LIKE  marm-meinh,
          msehl          LIKE  t006a-msehl,
*$@003 Anfang MWE-ENTW-46C
*$ Anfang MWE-HW-376048
*$          umrez          TYPE  marm-umrez,
*$          umren          TYPE  marm-umren,
          umrez          TYPE  mdr1convnum,
          umren          TYPE  mdr1convden,
*$ Ende MWE-HW-376048
*$@003 Ende MWE-ENTW-46C
          flagdefqtunit  TYPE  mdr1defqtunit,  " Kennzeichen für DefME
          flagvenqtunit  TYPE  mdr1venqtunit,  " Kennzeichen für LiefME
          flagbuyqtunit  TYPE  mdr1buyqtunit,  " Kennzeichen für AbnME
        END OF    value_tab,
        l_dynpprog       LIKE  sy-repid,
        l_dynpnr         LIKE  sy-dynnr,
        l_dynprofield    LIKE  help_info-dynprofld,
        l_stepl          LIKE  help_info-stepl,
        l_display        LIKE  ddrefstruc-bool.

*                *** Fülle die F4-Werte mit den bestimmten Werten,
*                *** die angezeigt werden sollen
  LOOP AT p_t_qt_units.

    CLEAR: value_tab.

    IF  p_s_general-flagdefqtunit  = c_yes
    AND p_t_qt_units-flagdefqtunit = c_yes.
      MOVE-CORRESPONDING p_t_qt_units TO value_tab.
    ENDIF.

    IF  p_s_general-flagvenqtunit  = c_yes
    AND p_t_qt_units-flagvenqtunit = c_yes.
      MOVE-CORRESPONDING p_t_qt_units TO value_tab.
    ENDIF.

    IF  p_s_general-flagbuyqtunit  = c_yes
    AND p_t_qt_units-flagbuyqtunit = c_yes.
      MOVE-CORRESPONDING p_t_qt_units TO value_tab.
    ENDIF.

    IF  p_s_general-flagallqtunit  = c_yes
    AND p_t_qt_units-flagallqtunit = c_yes.
      MOVE-CORRESPONDING p_t_qt_units TO value_tab.
    ELSE.
      IF  p_s_general-flagallqtunit  = c_yes.
        CLEAR: value_tab.
      ENDIF.
    ENDIF.

*$@006 #mbi 4.70 RoundSimu - Anfang
*                *** Neuer Fall: F4-Hilfe für die gültigen ALternativME
*                ***             zu einem Artikel
    IF  p_s_general-flagdefqtunit  = c_no
    AND p_s_general-flagvenqtunit  = c_no
    AND p_s_general-flagbuyqtunit  = c_no
    AND p_s_general-flagallqtunit  = c_no.

      MOVE-CORRESPONDING p_t_qt_units TO value_tab.

    ENDIF.
*$@006 #mbi 4.70 RoundSimu - Ende

    IF NOT ( value_tab IS INITIAL ).
      APPEND value_tab.
    ENDIF.

  ENDLOOP.

*                *** Bestimme je nach ausgewählter Funktion die
*                *** Überschrift in der F4-Hilfe:
*                *** - Default: keine Vorgabe => 'ALt. Mengeneinheiten
  IF p_titel IS INITIAL.
    CLEAR: l_window_titel.

*                *** - Unterscheide zwischen
    CASE p_s_general-appview.
*                ***   EK-Sicht
      WHEN mdr1p_c_appview_purchase.
*                ***   -> bei der Bestimmung der erlaubten logistischen
*                ***      BestellMengeneinheit
        IF p_s_general-flagallqtunit  = c_yes.
          l_window_titel = text-002.
        ENDIF.
*                ***   -> bei der Bestimmung der Default-ME (alleine)
        IF  p_s_general-flagdefqtunit  = c_yes
        AND p_s_general-flagvenqtunit  = c_no
        AND p_s_general-flagbuyqtunit  = c_no
        AND p_s_general-flagallqtunit  = c_no.
          l_window_titel = text-003.
        ENDIF.

*$@006 #mbi 4.70 RoundSimu - Anfang
*                *** Neuer Fall: F4-Hilfe für die gültigen ALternativME
*                ***             zu einem Artikel
        IF  p_s_general-flagdefqtunit  = c_no
        AND p_s_general-flagvenqtunit  = c_no
        AND p_s_general-flagbuyqtunit  = c_no
        AND p_s_general-flagallqtunit  = c_no.
          l_window_titel = text-008.
        ENDIF.
*$@006 #mbi 4.70 RoundSimu - Ende


*                ***   VK-Sicht
      WHEN mdr1p_c_appview_sale.
*                ***   -> bei der Bestimmung der erlaubten logistischen
*                ***      VerkaufsMengeneinheit
        IF p_s_general-flagallqtunit  = c_yes.
          l_window_titel = text-001.
        ENDIF.
*                ***   -> bei der Bestimmung der Default-ME (alleine)
        IF  p_s_general-flagdefqtunit  = c_yes
        AND p_s_general-flagvenqtunit  = c_no
        AND p_s_general-flagbuyqtunit  = c_no
        AND p_s_general-flagallqtunit  = c_no.
          l_window_titel = text-004.
        ENDIF.

*$@006 #mbi 4.70 RoundSimu - Anfang
*                *** Neuer Fall: F4-Hilfe für die gültigen ALternativME
*                ***             zu einem Artikel
        IF  p_s_general-flagdefqtunit  = c_no
        AND p_s_general-flagvenqtunit  = c_no
        AND p_s_general-flagbuyqtunit  = c_no
        AND p_s_general-flagallqtunit  = c_no.
          l_window_titel = text-008.
        ENDIF.
*$@006 #mbi 4.70 RoundSimu - Ende

*                ***   Aufteiler-Sicht
      WHEN mdr1p_c_appview_alloc.
*                ***   -> bei der Bestimmung der erlaubten logistischen
*                ***      VerkaufsMengeneinheit (immer)
        l_window_titel = text-007.

    ENDCASE.

    IF l_window_titel IS INITIAL.
*                ***   - bei der Bestimmung der Lief-ME (alleine)
      IF  p_s_general-flagdefqtunit  = c_no
      AND p_s_general-flagvenqtunit  = c_yes
      AND p_s_general-flagbuyqtunit  = c_no
      AND p_s_general-flagallqtunit  = c_no.
        l_window_titel = text-005.
      ENDIF.
*                ***   - bei der Bestimmung der Abn-ME (alleine)
      IF  p_s_general-flagdefqtunit  = c_no
      AND p_s_general-flagvenqtunit  = c_no
      AND p_s_general-flagbuyqtunit  = c_yes
      AND p_s_general-flagallqtunit  = c_no.
        l_window_titel = text-006.
      ENDIF.
    ENDIF.
  ELSE.
    l_window_titel  =  p_titel.
  ENDIF.

*                *** Nur die Lokalen Variablen als Aufrufparameter
*                *** vorsehen
  l_dynpprog      =  p_dynpprog.
  l_dynpnr        =  p_dynpnr.
  l_dynprofield   =  p_dynprofield.
  l_stepl         =  p_stepl.
  l_display       =  p_display.

  CLEAR: sy-msgid.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
*           DDIC_STRUCTURE   = ' '
            retfield         = 'MEINH' " Feldname der Rückgabe
*           PVALKEY          = ' '
            dynpprog         = l_dynpprog
            dynpnr           = l_dynpnr
            dynprofield      = l_dynprofield
            stepl            = l_stepl
            window_title     = l_window_titel
*           VALUE            = ' '
            value_org        = 'S'
*           MULTIPLE_CHOICE  = ' '
            display          = l_display
*           CALLBACK_PROGRAM = ' '
*           CALLBACK_FORM    = ' '
       TABLES
            value_tab        = value_tab
*           FIELD_TAB        =
*           RETURN_TAB       =
*           DYNPFLD_MAPPING  =
       EXCEPTIONS
            parameter_error  = 1
            no_values_found  = 2
            error_message    = 98      " Ausnahme bei Meldungen
            OTHERS           = 99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
*                *** Immer nur I-Messages im Dialog-Modus
      sy-msgty  =  c_msgty_i.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE i001(rpugen) WITH 'F4IF_INT_TABLE_VALUE_REQUEST'
                           RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " CALL_IF_INT_TABLE_VALUE_REQ

*&---------------------------------------------------------------------*
*&      Form  CALL_ROUNDING_VALUE
*&---------------------------------------------------------------------*
*       Aufruf des Funktionsbausteins:
*            MD_ROUNDING_VALUE
*       mit den korrekten Eingabeparametern zur Bestimmung des
*       Rundungswerts mit Hilfe der Rundungswertmethode.
*----------------------------------------------------------------------*
*      -->P_T_ROUND_REASONS  Tabelle mit den bisherigen Rundungsgründen
*                            (Normalfall LEER)
*      -->P_S_GENERAL        Eingabestruktur von MD_SINGLE_ROUNDING
*      -->P_S_RESULTS        Bestimmte Rundungsparameter
*      <--P_S_RESULTS        Bestimmte Rundungsparameter mit dem
*                            bestimmten Rundungswert
*      -->P_T_ROUND_REASONS  Tabelle erweitert um ein neuer Rundungs-
*                            grund, wenn der gerundete Wert von dem Ein-
*                            gabewert abweicht.
*----------------------------------------------------------------------*
FORM call_rounding_value
                   TABLES
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_quantity    TYPE mdr1p_p_16_dec_14,
        l_round_value TYPE mdr1p_p_16_dec_14.

*                *** Bestimme die Eingabe-Menge in Basis-ME
  PERFORM determine_i_qty_in_unit_new USING    p_s_general
                                               p_s_results-meins
                                      CHANGING p_s_results
                                               l_quantity.

*                *** Bestimme an Hand des Opcodes den Rundungswert
*                *** und die Mengeneinh des Rundungswerts
  CASE p_s_general-opcode.

*                *** - EK-OpCodes
    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_lb.

*                ***   bei EK liegt der Rundungswert immer in Basis-ME
*                ***   vor!!!
      l_round_value = p_s_results-bstrf.

*                *** - allgemeine VK-OpCodes und
*                *** - spezielles VK-Verfahren
    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung
      OR mdr1p_c_op_sd_verf.

*                ***   bei VK muß der Rundungswert noch in Basis-ME
*                ***   umgerechnet werden
      l_round_value = p_s_results-scmng.

      PERFORM conv2unit_new  USING    p_s_general
                                      l_round_value     " Menge (alt ME)
                                      p_s_results-schme " alte ME
                                      p_s_results-meins " neue ME
                             CHANGING p_s_results
                                      l_round_value.    " Menge (neu ME)

*                ***    - Verkaufshilfsmittel-OpCode
    WHEN mdr1p_c_op_additionals.
*                ***      => gibt hierzu keine Rundungswertmethode

  ENDCASE.

*                *** Initialisiere das Ergebnis der Rundung
  CLEAR: p_s_results-roundqt,
         p_s_results-rqtunit,
         sy-msgid.

*                *** Aufruf des FB zum Runden:
  CALL FUNCTION 'MD_ROUNDING_VALUE'
       EXPORTING
            i_quantity               = l_quantity
            i_value                  = l_round_value
*           I_WITH_MINUTES           = ' '
       IMPORTING
            e_rounding_quantity      = p_s_results-roundqt
       TABLES
            ch_t_rounding_reasons    = p_t_round_reasons
*           ch_t_minutes             =
       EXCEPTIONS
            input_less_or_equal_zero = 1
            error_message            = 98      " Ausnahme bei Meldungen
            OTHERS                   = 99
            .

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'MD_ROUNDING_VALUE'
                           RAISING error.
    ENDIF.
  ELSE.
* note 334664 - B
*$*                *** Rundungs-ME ist die Basis-ME
*$    p_s_results-rqtunit = p_s_results-meins.

*$@ Begin of note-494293
   IF p_s_general-opcode  =  mdr1p_c_op_mm_normal
   OR p_s_general-opcode  =  mdr1p_c_op_mm_ub
   OR p_s_general-opcode  =  mdr1p_c_op_lb.
*                *** Ergebnisbehandlung im Einkauf:
* $@ End of note-494293

*                *** Rundungs-ME ist hierbei immer die Eingabe-ME
    p_s_results-rqtunit  =  p_s_general-meinh.

    IF p_s_results-roundqt  =  l_quantity.
*                *** Eingabe-Menge ist bereits ein Vielfaches
*                *** des Rundungswerts
*                *** => Rundungsmenge = Eingabe-Menge
      p_s_results-roundqt  =  p_s_general-menge.

    ELSE.
*                *** Eingabe-Menge wurde auf Vielfaches des
*                *** Rundungswerts angepaßt
*                *** => Rundungsmenge in Eingabe-ME umrechnen
      PERFORM conv2unit_new  USING    p_s_general
                                      p_s_results-roundqt " in Basis-ME
                                      p_s_results-meins     " Basis-ME
                                      p_s_results-rqtunit   " Ein.-ME
                             CHANGING p_s_results
                                      p_s_results-roundqt." in Ein.-ME


    ENDIF.

*$@ Begin of note-494293
    ELSE.
*                *** Ergebnisbehandlung im Verkauf:
*                *** Zuerst Rundungs-ME bei Basis-ME belassen
*                *** (Zusätzlichen bzw. unnötige Umrechnungen
*                ***  vermeiden!!!)
      p_s_results-rqtunit  =  p_s_results-meins.
    ENDIF.
*$@ End of note-494293

* note 334664 - E

  ENDIF.

ENDFORM.                               " CALL_ROUNDING_VALUE

*&---------------------------------------------------------------------*
*&      Form  CALL_CHECK_ROUNDING_PROFILE
*&---------------------------------------------------------------------*
*       Führe die statische Rundung mit Hilfe des FB:
*           'CHECK_ROUNDING_PROFILE'
*       durch.
*----------------------------------------------------------------------*
*      -->P_T_RDPR          Komplette Defintion des RUndungsprofils
*                           (wenn schon bestimmt)
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--P_T_RDPR          Komplette Defintion des RUndungsprofils
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM call_check_rounding_profile
                   TABLES
                     p_t_rdpr          STRUCTURE  rdpr
                     p_t_round_reasons TYPE   mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE   mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE   mdr1p_s_out_single_round.

  DATA: l_qty       TYPE mdr1p_p_16_dec_14,
        l_qty_old   TYPE mdr1p_p_16_dec_14,
        l_qty_quan  LIKE rdpr-vormg.   " Menge in QUAN


*                *** Bestimme unter Umständen noch die komplette
*                *** Defintion des Rundungsprofils
  IF p_t_rdpr[] IS INITIAL.
    PERFORM read_rdpr_all  TABLES   p_t_rdpr
                           USING    p_s_results-rdprf
                                    p_s_general-werks
                           CHANGING p_s_results-rdpr.
  ENDIF.

*                *** Eingabe-Menge in Basis-ME bei statischen Verfahren
*                *** berücksichtigen
  PERFORM determine_i_qty_in_unit_new USING    p_s_general
                                               p_s_results-meins
                                      CHANGING p_s_results
                                               l_qty.

*                *** Rette die Eingabe-Menge in Basis-Me
  l_qty_old  = l_qty.
*                *** Wandele die Menge in den Daten-Typ QUAN um
  l_qty_quan = l_qty.

  CLEAR:  sy-msgid.

  CALL FUNCTION 'CHECK_ROUNDING_PROFILE'
       EXPORTING
*           IT399D            = ' '
            plant             = p_s_general-werks
            profile           = p_s_results-rdprf
            quantity_in       = l_qty_quan
*           REF_PLANT         = ' '
            kz_use_irdpr      = c_yes
*           KZ_ROUND_DOWN     =
       IMPORTING
            quantity_out      = l_qty_quan
       TABLES
            irdpr             = p_t_rdpr
       EXCEPTIONS
            profile_not_found = 1
            error_message     = 98
            OTHERS            = 99
            .

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'CHECK_ROUNDING_PROFILE'
                           RAISING error.
    ENDIF.
  ELSE.
*                *** Wandele das Rundungsergebnis wieder in Float zurück
    p_s_results-roundqt = l_qty_quan.
    p_s_results-rqtunit = p_s_results-meins.

*                *** Wenn Rundungs-Ergebnis von der Eingabe abweicht
*                *** setze Rundungsgrund
    IF p_s_results-roundqt <> l_qty_old.
      PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                    USING  mdr1p_c_rdpr_absolut.
    ENDIF.
  ENDIF.

ENDFORM.                               " CALL_CHECK_ROUNDING_PROFILE
*&---------------------------------------------------------------------*
*&      Form  CALL_SINGLE_ROUNDING
*&---------------------------------------------------------------------*
*       Aufuf des NEUEN Rundungsbausteins in der alten Version.
*----------------------------------------------------------------------*
*      -->P_S_GENERAL    allgemeine Eingabe-Parameter des neuen
*                        Bausteins
*$@004 Anfang MWE-ENTW-470-UNICODE
*      -->P_OUT_ERROR    Kein Fehlerabbruch!
*$@004 Ende MWE-ENTW-470-UNICODE
*      -->P_S_U02        Eingabe-Parameter der alten Version
*      <--P_S_RESULTS    Ergebnis des neuen Bausteins
*      <--P_S_U02        Ergebnis für die alte Version
*----------------------------------------------------------------------*
FORM call_single_rounding
                   USING
                     p_s_general       TYPE   mdr1p_s_in_single_round
*$@004 Anfang MWE-ENTW-470-UNICODE
                     p_out_error       TYPE   c
*$@004 Ende MWE-ENTW-470-UNICODE
                   CHANGING
                     p_s_results       TYPE   mdr1p_s_out_single_round
                     p_s_u02           LIKE   g_u02.

  DATA: l_s_general TYPE  mdr1p_s_in_single_round.

  CLEAR: l_s_general,
         g_t_grund[].

*                *** Bestimme die Eingabe-Parameter:
  IF NOT ( p_s_general IS INITIAL ).
*                *** - Parameter werden schon durch die Aufrufstelle der
*                ***   alten Version versorgt
    l_s_general = p_s_general.

  ELSE.
*                *** - Parameter müssen aus den Eingabeparametern der
*                ***   alten Version bestimmt werden!!!
    l_s_general-opcode              =  p_s_u02-i_opcode.
    l_s_general-matnr               =  p_s_u02-i_matnr.
    l_s_general-menge               =  p_s_u02-i_menge.
    l_s_general-meinh               =  p_s_u02-i_meins.
    l_s_general-werks               =  p_s_u02-i_werk.
    l_s_general-ekorg               =  p_s_u02-i_ekorg.
    l_s_general-lifnr               =  p_s_u02-i_lifnr.
    l_s_general-infnr               =  p_s_u02-i_infnr.
*$@002 Anfang MWE-HW-186918
    l_s_general-pstyp               =  p_s_u02-i_pstyp.
*$@002 Ende MWE-HW-186918
    l_s_general-vkorg               =  p_s_u02-i_vkorg.
    l_s_general-vtweg               =  p_s_u02-i_vtweg.
    l_s_general-spart               =  p_s_u02-i_spart.
    l_s_general-kunnr               =  p_s_u02-i_kunnr.
    l_s_general-rdpr                =  p_s_u02-i_rdpr.
    l_s_general-no_min_max_check    =  p_s_u02-i_no_min_max_check.
    l_s_general-infls               =  p_s_u02-i_infls.
    l_s_general-rdprf               =  p_s_u02-i_rdprf.
    l_s_general-scmng               =  p_s_u02-i_scmng.
    l_s_general-schme               =  p_s_u02-i_schme.
    l_s_general-werks_kred          =  p_s_u02-i_werks_kred.
  ENDIF.

  CLEAR:  sy-msgid.

  CALL FUNCTION 'MD_SINGLE_ROUNDING'
    EXPORTING
      i_s_general        = l_s_general
    IMPORTING
      e_s_results        = p_s_results
    TABLES
      e_t_round_reasons  = g_t_grund
    EXCEPTIONS
      invalid_opcode     = 1
      no_purchase_org    = 2
      rdpr_not_found     = 3
      material_not_found = 4
      meinh_not_found    = 5
      bad_params         = 6
      debitor_not_found  = 7
      no_round           = 8
      rdprf_not_found    = 9
      error              = 10
      error_message      = 98
      OTHERS             = 99.

  IF sy-subrc = 0.
*                *** Rückgabe-Werte füllen aus p_s_results
    p_s_u02-e_lmenge  =  p_s_results-lmenge.
    p_s_u02-e_logme   =  p_s_results-logme.
    p_s_u02-e_menge   =  p_s_results-menge.
    p_s_u02-e_rdprf   =  p_s_results-rdprf.
    p_s_u02-e_scmng   =  p_s_results-scmng.
    p_s_u02-e_schme   =  p_s_results-schme.
  ELSE.
*$@004 Anfang MWE-ENTW-470-UNICODE
    IF p_out_error = c_yes. "MWE-ENTW-470-UNICODE
*$@004 Ende MWE-ENTW-470-UNICODE
*                ***   Spezielles Fehlerhändling:
      IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
*                *** abhängi von der Ausnahme.
        CASE sy-subrc.
          WHEN 1.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING invalid_opcode.
          WHEN 2.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING no_purchase_org.
          WHEN 3.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING rdpr_not_found.
          WHEN 4.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING material_not_found.
          WHEN 5.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING meinh_not_found.
          WHEN 6.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING bad_params.
          WHEN 7.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING debitor_not_found.
          WHEN 8.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING no_round.
          WHEN 9.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING rdprf_not_found.
          WHEN 10.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING error.
          WHEN OTHERS.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    RAISING error.
        ENDCASE.
      ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
        CASE sy-subrc.
          WHEN 1.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING invalid_opcode.
          WHEN 2.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING no_purchase_org.
          WHEN 3.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING rdpr_not_found.
          WHEN 4.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING material_not_found.
          WHEN 5.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING meinh_not_found.
          WHEN 6.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING bad_params.
          WHEN 7.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING debitor_not_found.
          WHEN 8.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING no_round.
          WHEN 9.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING rdprf_not_found.
          WHEN 10.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING error.
          WHEN OTHERS.
            MESSAGE e001(rpugen) WITH 'MD_SINGLE_ROUNDING'
                    RAISING error.
        ENDCASE.
      ENDIF.
*$@004 Anfang MWE-ENTW-470-UNICODE
    ENDIF.
*$@004 Ende MWE-ENTW-470-UNICODE

  ENDIF.

ENDFORM.                               " CALL_SINGLE_ROUNDING
*&---------------------------------------------------------------------*
*&      Form  CALL_RM_INVALID_DECI_PLACE
*&---------------------------------------------------------------------*
*       Aufruf des FBs zum Entfernen ungültiger Dezimalstellen
*----------------------------------------------------------------------*
*      -->P_T_ROUND_REASONS   Rundungsgründe
*      -->P_QTY_OLD           alte Menge
*      -->P_QTY_UNIT          ME
*      -->P_ANDEC             Anzahl der gültigen Dezimalstellen
*      <--P_QTY_NEW           neue MEnge
*----------------------------------------------------------------------*
FORM call_rm_invalid_deci_place
                   TABLES
                     p_t_round_reasons  TYPE mdr1p_t_rundungsgrund
                   USING
                     value(p_qty_old)   TYPE  mdr1p_p_16_dec_14
                     value(p_qty_unit)  LIKE  marm-meinh
                     value(p_andec)     LIKE  t006-andec
                   CHANGING
                     value(p_qty_new)   TYPE  mdr1p_p_16_dec_14.

  DATA: l_qty_new  TYPE  mdr1p_p_16_dec_14.

*                *** Default-Belegung
  l_qty_new  =  p_qty_old.

  CALL FUNCTION 'MD_RM_INVALID_DECI_PLACE'
       EXPORTING
            i_quantity            =  p_qty_old
            i_unit                =  p_qty_unit
            i_valid_deci          =  p_andec
*         I_WITH_MINUTES        =
       IMPORTING
            e_valid_quantity      =  l_qty_new
       TABLES
            ch_t_rounding_reasons =  p_t_round_reasons
       EXCEPTIONS
            input_less_zero       =  1
            user_exit_error       =  2
            error_message         =  98
            OTHERS                =  99
            .

  IF sy-subrc <> 0.
    CLEAR: sy-subrc.
    p_qty_new  =  p_qty_old.
  ELSE.
    p_qty_new  =  l_qty_new.
  ENDIF.

ENDFORM.                               " CALL_RM_INVALID_DECI_PLACE

*$@005 #mbi 4.70 UNICODE - Anfang
*&---------------------------------------------------------------------*
*&      Form  call_f4help_value_request
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_f4help_value_request
  TABLES
    p_value_tab         TYPE       STANDARD TABLE
    p_dynpfld_mapping   STRUCTURE  dselc
  USING
    p_retfield          TYPE       dfies-fieldname
    p_dynpprog          TYPE       sy-repid
    p_dynpnr            TYPE       sy-dynnr
    p_dynprofield       TYPE       help_info-dynprofld
    p_value_org         TYPE       ddbool_d
    p_callback_program  TYPE       sy-repid
    p_callback_form     TYPE       sy-xform.

  CLEAR: sy-msgid,
         sy-subrc.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE         = ' '
      retfield               = p_retfield
*     PVALKEY                = ' '
      dynpprog               = p_dynpprog
      dynpnr                 = p_dynpnr
      dynprofield            = p_dynprofield
*     STEPL                  = 0
*     WINDOW_TITLE           =
*     VALUE                  = ' '
      value_org              = p_value_org
*     MULTIPLE_CHOICE        = ' '
*     DISPLAY                = ' '
      callback_program       = p_callback_program
      callback_form          = p_callback_form
*     MARK_TAB               =
*   IMPORTING
*     USER_RESET             =
    TABLES
      value_tab              = p_value_tab
*     FIELD_TAB              =
*     RETURN_TAB             =
      dynpfld_mapping        = p_dynpfld_mapping
    EXCEPTIONS
      parameter_error        = 1
      no_values_found        = 2
      error_message          = 98
      OTHERS                 = 99.

  IF sy-subrc <> 0.

    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'F4IF_INT_TABLE_VALUE_REQUEST'
                           RAISING error.
    ENDIF.

  ENDIF.

ENDFORM.                    " call_f4help_value_request
*$@005 #mbi 4.70 UNICODE - Anfang

*$@006 #mbi 4.70 RoundSimu - Anfang
*&---------------------------------------------------------------------*
*&      Form  call_single_rounding_2
*&---------------------------------------------------------------------*
*       Aufruf des Rundungsbausteins zur
*       Rundungs-Simulation zu einer Anwendung
*----------------------------------------------------------------------*
*  <--  p_t_round_reasons
*  -->  p_s_general
*  <--  p_s_results
*----------------------------------------------------------------------*
FORM call_single_rounding_2
  TABLES
    p_t_round_reasons  TYPE mdr1trundungsgrund
  USING
    p_s_general        TYPE mdr1insingleround
  CHANGING
    p_s_results        TYPE mdr1outsingleround.

  CLEAR: p_t_round_reasons[],
         p_s_results.

  CLEAR:  sy-msgid.

  CALL FUNCTION 'MD_SINGLE_ROUNDING'
    EXPORTING
      i_s_general        = p_s_general
    IMPORTING
      e_s_results        = p_s_results
    TABLES
      e_t_round_reasons  = p_t_round_reasons
    EXCEPTIONS
      invalid_opcode     = 1
      no_purchase_org    = 2
      rdpr_not_found     = 3
      material_not_found = 4
      meinh_not_found    = 5
      bad_params         = 6
      debitor_not_found  = 7
      no_round           = 8
      rdprf_not_found    = 9
      error              = 10
      error_message      = 98
      OTHERS             = 99.

  IF sy-subrc <> 0.
*                *** Spezielles Fehlerhändling ohne Setzen von
*                *** Ausnahmen
    IF NOT ( sy-msgid IS INITIAL ).

      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    ELSE.

      MESSAGE e001(rpugen)
         WITH 'MD_SINGLE_ROUNDING'.

    ENDIF.

  ENDIF.

ENDFORM.                    " call_single_rounding_2

*&---------------------------------------------------------------------*
*&      Form  call_mdr1_determ_round_params
*&---------------------------------------------------------------------*
*       Bestimmung der Rundungsparameter
*----------------------------------------------------------------------*
*  <--  p_t_qt_units
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_mdr1_determ_round_params
  TABLES
    p_t_qt_units TYPE mdr1toutallowedqtunit
  CHANGING
    p_s_general  TYPE mdr1insingleround
    p_s_results  TYPE mdr1outsingleround.

  CLEAR: sy-msgid,
         sy-subrc.

  CALL FUNCTION 'MDR1_DETERMINE_ROUND_PARAMS'
    TABLES
      ch_t_qt_units = p_t_qt_units
    CHANGING
      ch_s_general  = p_s_general
      ch_s_results  = p_s_results
    EXCEPTIONS
      no_round      = 1
      error         = 2
      error_message = 98
      OTHERS        = 99.

  IF sy-subrc <> 0.

    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'MDR1_DETERMINE_ROUND_PARAMS'.
    ENDIF.

  ENDIF.

ENDFORM.                    " call_mdr1_determ_round_params

*&---------------------------------------------------------------------*
*&      Form  call_mdr1_simu_rounding
*&---------------------------------------------------------------------*
*       Aufruf der neuen Simulation
*----------------------------------------------------------------------*
*  -->  p_s_general
*----------------------------------------------------------------------*
FORM call_mdr1_simu_rounding
  USING
    p_s_general  TYPE  mdr1insingleround.

  CLEAR: sy-msgid,
         sy-subrc.

  CALL FUNCTION 'MDR1_SIMU_ROUNDING'
    EXPORTING
      i_s_general   = p_s_general
    EXCEPTIONS
      error         = 1
      bad_params    = 2
      bad_profil    = 3
*                *** error_message = 98 => diese EXCEPTION nicht
*                *** abfangen, sonst wird bei einem Eingabefehlern auf
*                *** Dynpro 800, der FB mit verlassen!!!
      OTHERS        = 99.

  IF sy-subrc <> 0.

    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'MDR1_SIMU_ROUNDING'.
    ENDIF.

  ENDIF.

ENDFORM.                    " call_mdr1_simu_rounding
*$@006 #mbi 4.70 RoundSimu - Ende

*#@007 HWI 4.70 customizing of logistical rounding B
*&---------------------------------------------------------------------*
*&      Form  call_customizing_read
*&---------------------------------------------------------------------*
*       Tabellen RCTR und RCPR werden gelesen
*----------------------------------------------------------------------*
*      -->P_P_S_GENERAL-TCODE
*      -->P_P_S_GENERAL-OPCODE
*      <--P_P_S_GENERAL
*----------------------------------------------------------------------*
FORM call_customizing_read  CHANGING
                            p_p_s_general TYPE  mdr1insingleround.


  DATA: s_rctr LIKE rctr.
  DATA: s_rcpr LIKE rcpr.

  CLEAR:  sy-msgid.


  CALL FUNCTION 'MD_CUSTOMIZING_READ'
    IMPORTING
      e_rcpr        = s_rcpr
      e_rctr        = s_rctr
    CHANGING
      c_p_s_general = p_p_s_general
    EXCEPTIONS
      error         = 1
      error_message = 98
      OTHERS        = 99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setze Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'MD_CUSTOMIZING_READ'
                           RAISING error.
    ENDIF.
  ELSE.
*                *** Eintrag ist eindeutig, wir übernehmen diesen

    MOVE-CORRESPONDING s_rcpr TO p_p_s_general.
  ENDIF.

ENDFORM.                    " call_customizing_read

*&---------------------------------------------------------------------*
*&      Form  call_purpar_determine
*&---------------------------------------------------------------------*
*       Bestimmung der Rundungsparameter laut Customizing
*----------------------------------------------------------------------*
*      -->P_S_EINA
*      -->P_S_EINE
*      -->P_S_GENERAL-MATNR
*      -->P_S_GENERAL-WERKS
*      <--P_S_RESULTS
*      <--P_S_MARC
*----------------------------------------------------------------------*
FORM call_purpar_determine
  USING
    p_s_eina           LIKE eina
    p_s_eine           LIKE eine
    p_s_general-matnr  LIKE mara-matnr
    p_s_general-werks  LIKE t001w-werks
    p_s_general-purpar TYPE lumerrpurpar
  CHANGING
    p_s_results        TYPE mdr1outsingleround
    p_s_marc           LIKE marc.

  DATA: p_s_purpar TYPE mdr1outsingleround.

  CALL FUNCTION 'MD_PURPAR_DETERMINE'
    EXPORTING
      i_s_eina      = p_s_eina
      i_s_eine      = p_s_eine
      i_matnr       = p_s_general-matnr
      i_werks       = p_s_general-werks
      i_purpar      = p_s_general-purpar
      i_s_results   = p_s_results
    IMPORTING
      e_s_purpar    = p_s_purpar
    CHANGING
      c_s_marc      = p_s_marc
    EXCEPTIONS
      error         = 1
      error_message = 98
      OTHERS        = 99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setze Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'MD_CUSTOMIZING_READ'
                           RAISING error.
    ENDIF.

  ELSE.
* Die Parameter zur Rundung im Einkauf stehen nun in p_s_purpar,
* diese übernehmen wir

    p_s_results-rdprf = p_s_purpar-rdprf.
    p_s_results-bstrf = p_s_purpar-bstrf.
    p_s_results-maxqt = p_s_purpar-maxqt. " immer in Basis-ME
    p_s_results-minqt = p_s_purpar-minqt. " immer in Basis-ME
    p_s_results-mamiqtunit = p_s_purpar-mamiqtunit.
    p_s_results-mamiumrez = p_s_purpar-mamiumrez.
    p_s_results-mamiumren = p_s_purpar-mamiumren.
  ENDIF.

ENDFORM.                    " call_purpar_determine
*#@007 HWI 4.70 customizing of logistical rounding E

*$@008 Anfang
*&---------------------------------------------------------------------*
*&      Form  CALL_MD_RDTX_READ
*&---------------------------------------------------------------------*
*       Lesen der RDTX mit einem FB
*----------------------------------------------------------------------*
*      -->p_spras     Sprache
*      -->p_rdprf     Rundungsprofil
*      -->p_werks     Werk
*      <--e_rdtx      RDTX-Eintrag
*----------------------------------------------------------------------*
FORM call_md_rdtx_read USING    value(p_spras)  LIKE rdtx-spras
                                value(p_rdprf)  LIKE rdtx-rdprf
                                value(p_werks)  LIKE rdtx-werks
                       CHANGING value(e_rdtx)   LIKE rdtx.

  DATA: l_t_rdtx LIKE rdtx OCCURS 0 WITH HEADER LINE.

  CLEAR: e_rdtx,
         l_t_rdtx[].

  CALL FUNCTION 'MD_RDTX_READ'
    EXPORTING
      i_opcode           = '1'     " einzelner Eintrag lesen
      i_rdprf            = p_rdprf
      i_werks            = p_werks
      i_spras            = p_spras
      i_buffer_size      = 0       " beliebig viele Einträge puff.
      i_buffer_on        = c_yes   " gelesene Eint. puffern
      i_read_with_buffer = c_yes   " Lesen mit Pufferung
    TABLES
      e_t_rdtx           = l_t_rdtx
    EXCEPTIONS
      no_entry_found     = 1
      invalid_opcode     = 2
      bad_params         = 3
      OTHERS             = 4.
* Fehler wird in der Aufrufstelle abgefangen

  IF sy-subrc = 0.
* Der Kuztext steht in der L_t_rdtx im 1. Eintrag
    READ TABLE l_t_rdtx INDEX 1.
    MOVE-CORRESPONDING l_t_rdtx TO e_rdtx.
  ENDIF.

ENDFORM.                    " CALL_MD_RDTX_READ
*$@008 Ende

*
* 
