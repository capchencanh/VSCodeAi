*----------------------------------------------------------------------*
***INCLUDE LMDR1F12 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       16.02.99  99A  mwe         Grundversion
*- @001  15.11.99  46C  mwe         - Performnaceverbesserung bei READ
*-                                    TABLE mit BINARY SEARCH und
*-                                    LOOP mit WHERE
*- @002  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @003  01.12.99  46C  mwe         Berücksichtigung von Konsignations-
*-                                  Infosätze
*-                                  Korrektur zu Hinweis: 186918
*- @004  04.05.00  46C  mwe         Basis-ME bei Material (Standard)
*-                                  nicht in der MARM eingetragen
*-                                  Korrektur zu Hinweis: 300836
*- @005  27.06.01  470  mwe         Programmabruch wegen zu großen
*-                                  Umrechnungsfaktoren
*-                                  Korrektur zu Hinweis: 430276
*- @006  12.10.01  470  mbi         Verbesserung der Simulation der
*-                                  Rundung.
*  @007  25.10.01  470  hwi         Customizing of logistical rounding
*-
*  @008  19.03.02  470  mam         Chargen Behandlung, Hinweis: 504954
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_U12
*&---------------------------------------------------------------------*
*       Eingabeprüfung zu FB: MD_SINGLE_ROUNDING
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      <--P_S_MARA     MARA-Eintrag zu P_S_GENERAL-MATNR
*----------------------------------------------------------------------*
FORM check_input_u12
                   USING
                     p_s_general  TYPE  mdr1p_s_in_single_round
                   CHANGING
                     p_s_mara     TYPE  mara.

  DATA:  l_s_round_params TYPE mdr1p_s_round_params.

  CLEAR: p_s_mara,
         l_s_round_params.

*                *** 1. Prüfungen unabhängig vom OPCODE
*                ***    - Material muß immer existieren!!!
  IF p_s_general-matnr IS INITIAL.
    MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                         RAISING bad_params.
  ENDIF.
*                ***    - Zum Material muß der MARA-Eintrag existieren
  PERFORM read_mara_single USING     p_s_general-matnr
                           CHANGING  p_s_mara.

*                ***    - Eingabe-ME muß gefüllt sein!!!
  IF p_s_general-meinh IS INITIAL.
    MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                         RAISING bad_params.
  ENDIF.

*                ***    - Prüfe eingegebene Rundungs-Parameter:
  MOVE-CORRESPONDING p_s_general  TO  l_s_round_params.

  IF NOT ( l_s_round_params IS INITIAL ).
*                ***      wenn die Rundungsparameter gefüllt sind muß
*                ***      midestens:
*                ***      -> die Default-ME mitgeben werden
    IF l_s_round_params-defqtunit IS INITIAL.
      MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                           RAISING bad_params.
    ENDIF.
  ENDIF.

*                ***    - Bei einer Kontrakt-Menge muß immer die
*                ***      auch die Kontrakt-ME vorgegeben werden!
  IF  NOT ( p_s_general-konnr   IS  INITIAL )
  AND       p_s_general-kmeinh  IS  INITIAL.
    MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                         RAISING bad_params.
  ENDIF.

*                *** 2. Prüfungen abhängig vom OPCODE
  CASE p_s_general-opcode.

*                ***    - EK-OpCodes
    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_lb.
*                ***      -> Empfangswerk muß angegeben sein
      IF p_s_general-werks IS INITIAL.
        MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                             RAISING bad_params.
      ENDIF.

*                ***    - allgemeine VK-OpCodes
    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung.
*                ***      -> VKOrg und Vertriebsweg muß angegeben sein
      IF p_s_general-vkorg IS INITIAL
      OR p_s_general-vtweg IS INITIAL.
        MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                             RAISING bad_params.
      ENDIF.
*                ***      -> Kundennummer muß angegeben sein NEU !!!
      IF p_s_general-kunnr IS INITIAL.
        MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                             RAISING bad_params.
      ENDIF.

*                ***    - spezielles VK-Verfahren
    WHEN mdr1p_c_op_sd_verf.
*                ***      -> Alle Rundungsparameter werden von der
*                ***         Aufrufstelle vorgegeben
      IF l_s_round_params IS INITIAL.
        MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                             RAISING bad_params.
      ENDIF.

*                ***    - Verkaufshilfsmittel-OpCode
    WHEN mdr1p_c_op_additionals.

*                ***      -> Das Werk muss gefüllt sein
      IF p_s_general-werks IS INITIAL.
        MESSAGE  e066  RAISING  bad_params.
      ENDIF.

*                ***      -> Die Eingabemengeneinheit muss die
*                ***         Basis-ME sein
      IF p_s_general-meinh <> p_s_mara-meins.
        MESSAGE e069  WITH    p_s_general-meinh  p_s_mara-meins
                      RAISING bad_params.
      ENDIF.

*                ***    - FALSCHER OPCODE!!! => FEHLER
    WHEN OTHERS.
      MESSAGE e002(rpugen) WITH    'MD_SINGLE_ROUNDING'
                                   RAISING bad_params.
  ENDCASE.

ENDFORM.                               " CHECK_INPUT_U12

*&---------------------------------------------------------------------*
*&      Form  OUTPUT_DEFAULT_VALUE
*&---------------------------------------------------------------------*
*       Belege die Rückgabewerte mit Default-Werten:
*       Default-Werte = entsprechende Eingabewerte
*----------------------------------------------------------------------*
*      -->P_S_GENERAL   allgemeine Eingabestruktur
*      <--P_S_RESULTS   Rückgabestruktur
*----------------------------------------------------------------------*
FORM output_default_value
                   USING
                     p_s_general  TYPE  mdr1p_s_in_single_round
                   CHANGING
                     p_s_results  TYPE  mdr1p_s_out_single_round.

  p_s_results-menge  = p_s_general-menge.
  p_s_results-lmenge = p_s_general-menge.
  p_s_results-logme  = p_s_general-meinh.
  p_s_results-rdprf  = p_s_general-rdprf.
  p_s_results-scmng  = p_s_general-scmng.
  p_s_results-schme  = p_s_general-schme.            " ??? => NEU!!!

ENDFORM.                               " OUTPUT_DEFAULT_VALUE

*&---------------------------------------------------------------------*
*&      Form  READ_data_U12
*&---------------------------------------------------------------------*
*       Lese alle benötigten Daten aus der DB bzw. aus der Eingabestrukt
*       => Bestimmung der Rundungsparameter und der erlaubten ME
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur laut Aufrufstelle
*      -->P_S_MARA     gelesener MARA-Eintrag
*      <--P_S_GENERAL  allgemeine Eingabestruktur für LB-Aufruf mit
*                      manipulierter Eingabe-Menge und -ME.
*      <--p_s_results  Bestimmte Rundungsparameter
*      <--p_t_qt_units erlaubte ME
*      <--P_S_EINA     für EK
*      <--P_S_EINE     für EK
*      <--P_S_MARC     für EK
*      <--P_S_MARC_2   für EK
*      <--P_S_MVKE     für VK
*      <--P_S_KNMT     für VK
*      <--P_S_KNVV     für VK
*----------------------------------------------------------------------*
FORM read_data_u12 TABLES
                     p_t_qt_units    TYPE  mdr1p_t_out_allowed_qt_unit
                   USING
                     p_s_mara        TYPE  mara
                   CHANGING
                     p_s_general     TYPE  mdr1p_s_in_single_round
                     p_s_results     TYPE  mdr1p_s_out_single_round
                     p_s_eina        TYPE  eina
                     p_s_eine        TYPE  eine
                     p_s_marc        TYPE  marc
                     p_s_marc_2      TYPE  marc
                     p_s_mvke        TYPE  mvke
                     p_s_knmt        TYPE  knmt
                     p_s_knvv        TYPE  knvv.

  DATA:  l_s_round_params  TYPE  mdr1p_s_round_params,
         l_s_input         TYPE  mdr1p_s_in_allowed_qt_unit,
         l_s_mpn           TYPE  mdr1insingleround_mpn.

*$@006 mbi 4.70 - Anfang
*                *** Dummy-Variable, die nur als Parameter eines
*                *** Unterprogrammes mitgegeben werden müßen.
  DATA l_dummy TYPE mdr1p_s_in_allowed_qt_unit.
*$@006 mbi 4.70 - Ende


*#@007 HWI 4.70 customizing of logistical rounding B

  IF p_s_general-rappl IS INITIAL.

    IF p_s_general-tcode IS INITIAL.
      p_s_general-tcode = sy-tcode.
    ENDIF.

*                *** FB/UP zum Lesen des Customizings
    PERFORM call_customizing_read CHANGING p_s_general.

  ENDIF.

*#@007 HWI 4.70 customizing of logistical rounding E

  CLEAR: p_t_qt_units[].

*                *** 1. Basis-ME in den Rundungsparametern ablegen:
  p_s_results-meins = p_s_mara-meins.

*                *** 2. weitere Rundungsparameter bestimmen:
  MOVE-CORRESPONDING p_s_general  TO  l_s_round_params.

  IF NOT ( l_s_round_params IS INITIAL ).
*                ***    a) Rundungsparameter wurden schon von der
*                ***       Aufrufstelle bestimmt
*                ***       => KEINE DB-Zugriffe mehr nötig!
    MOVE-CORRESPONDING l_s_round_params  TO p_s_results.
  ELSE.
*                ***    b) Rundungsparameter werden über DB-Zugriffe be-
*                ***       stimmt
    PERFORM read_data_from_db_u12 USING    p_s_mara
                                           p_s_general
                                           l_s_mpn
                                  CHANGING p_s_results
                                           p_s_eina
                                           p_s_eine
                                           p_s_marc
                                           p_s_marc_2
                                           p_s_mvke
                                           p_s_knmt
                                           p_s_knvv.
  ENDIF.

*                *** 3. Bestimme die erlaubten ME (p_t_qt_units)

*                ***    - Eingabestruktur für den FB: MD_ALLOWED_QT_UNIT
*                ***      belegen:
*                ***      -> mit den Daten aus der Eingabestruktur
  MOVE-CORRESPONDING p_s_general  TO  l_s_input.

*                ***      -> mit den Daten der bestimmten RundParametern
  MOVE-CORRESPONDING p_s_results  TO  l_s_input.

*                ***      -> Festlegung der Unternehmenssicht abhängig
*                ***         vom OPCODE:
  CASE p_s_general-opcode.

*                ***         EK-OPCodes => EK-Sicht
    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_lb.

      l_s_input-appview  = mdr1p_c_appview_purchase.

*                ***         VK-OPCode => VK-Sicht
    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung
      OR mdr1p_c_op_sd_verf.

      l_s_input-appview  = mdr1p_c_appview_sale.

*                ***         Bei Additional => nur die Basis-ME ist
*                ***                           erlaubt!!!
*                ***                        => Bestimmung über Baustein
*                ***                           nicht nötig
    WHEN mdr1p_c_op_additionals.

      CLEAR: l_s_input-appview,  " => KEINE Bestimmung über Baustein
             p_t_qt_units.

      p_t_qt_units-matnr         = p_s_general-matnr.
      p_t_qt_units-meinh         = p_s_results-meins.
      p_t_qt_units-umrez         = 1.
      p_t_qt_units-umren         = 1.
      p_t_qt_units-flagdefqtunit = c_yes.
      p_t_qt_units-flagvenqtunit = c_yes.
      p_t_qt_units-flagbuyqtunit = c_yes.
      p_t_qt_units-flagallqtunit = c_yes.

      APPEND p_t_qt_units.

  ENDCASE.

*                ***      -> Auswahl der Funktionalität: erlaubte log.ME
  l_s_input-flagallqtunit  =  c_yes.

  IF NOT ( l_s_input-appview IS INITIAL ).
*                ***    - Aufruf des FB zur Bestimmung der erl. ME,
*                ***      wenn gewünscht!!!
    PERFORM call_allowed_quantity_unit TABLES   p_t_qt_units
                                       USING    l_s_input
                                                p_s_mara
                                                p_s_eina
                                                p_s_eine
                                                p_s_marc
                                                p_s_marc_2
                                                p_s_mvke
                                                p_s_knmt
                                                p_s_knvv.
  ENDIF.

*$@001 Anfang MWE-ENTW-46C
*                ***    - Sortiere die Menge der erlaubten
*                ***      ME
  SORT p_t_qt_units
    BY meinh.
*$@001 Ende MWE-ENTW-46C

*                *** 4. Aus dem Ergebnis die Default-ME bestimmen:
  LOOP AT p_t_qt_units
    WHERE flagdefqtunit = c_yes.
*                ***    Es gibt nur eine ausgezeichnete Default-ME
    p_s_results-defqtunit  =  p_t_qt_units-meinh.
    p_s_results-defumrez   =  p_t_qt_units-umrez.
    p_s_results-defumren   =  p_t_qt_units-umren.
*$@001 Anfang MWE-ENTW-46C
    EXIT.
*$@001 Ende MWE-ENTW-46C
  ENDLOOP.

*$@006 mbi 4.70 - Anfang
*                *** Bestimme zu der ME der Liefereinheit die Umrech-
*                *** nungsfaktoren.
  READ TABLE p_t_qt_units WITH KEY meinh = p_s_results-schme
       BINARY SEARCH.

*                *** Nur, falls Liefereinheit gepflegt ist.
  IF sy-subrc = 0.

*                *** Übernehme die Umrechnungsfaktoren
    p_s_results-schmeumrez = p_t_qt_units-umrez.
    p_s_results-schmeumren = p_t_qt_units-umren.

  ENDIF.

*                *** Bestimme je nach Anwendungssicht die Megru´s
  IF l_s_input-appview = mdr1p_c_appview_purchase.

*                *** Einkaufssicht

*                *** Bestimme die Lieferanten-ME-Gruppe
    PERFORM det_ven_unit_gr_purchase
                USING
                   l_dummy
                   p_s_eine
                   p_s_marc_2               "note 2081705
                CHANGING
                   p_s_results-venunitgr.

*                *** Bestimme die Abnehmer-ME-Gruppe
    PERFORM det_buy_unit_gr_purchase
                USING
                   l_dummy
                   p_s_marc
                CHANGING
                   p_s_results-buyunitgr.

  ELSEIF l_s_input-appview = mdr1p_c_appview_sale.

*                *** Verkaufssicht

*                *** Bestimme die Lieferanten-ME-Gruppe
    PERFORM det_ven_unit_gr_sale
                USING
                   l_dummy
                   p_s_mvke
                CHANGING
                   p_s_results-venunitgr.

*                *** Bestimme die Abnehmer-ME-Gruppe
    PERFORM det_buy_unit_gr_sale
                USING
                   l_dummy
                   p_s_knmt
                   p_s_knvv
                CHANGING
                   p_s_results-buyunitgr.

  ENDIF.
*$@006 mbi 4.70 - Ende

* Anfang MWE-HW-333191
  IF l_s_round_params IS INITIAL.
*                ***    Restliche bestimmte Rundungsparameter
*                ***    an Aufrufstelle zurückliefern
*                ***    Kennzeichen für variable Bestell-ME festlegen:
    IF NOT ( p_s_eina IS INITIAL ).

      p_s_results-vabme  =  p_s_eina-vabme.

    ELSE.

      p_s_results-vabme  =  p_s_mara-vabme.

    ENDIF.

*                ***    Kennzeichen für variable Verkaufs-ME festlegen:
    IF NOT ( p_s_mvke IS INITIAL ).

      p_s_results-vavme  =  p_s_mvke-vavme.

    ENDIF.
  ENDIF.
* Ende MWE-HW-333191

*                *** 5. Spezialbehandlung für LB-Aufruf:
  IF p_s_general-opcode = mdr1p_c_op_lb.
*                ***    - Untersuche, ob Eingabe-ME eine erlaubte ME ist
    CLEAR p_t_qt_units.

    READ TABLE p_t_qt_units
      WITH KEY meinh = p_s_general-meinh
*$@001 Anfang MWE-ENTW-46C
               BINARY SEARCH.
*$@001 Ende MWE-ENTW-46C

    IF NOT ( p_t_qt_units-flagallqtunit = c_yes ).
*                ***    - Eingabe-ME nicht erlaubt ME
*                ***      => ursprüngliche Eingabe merken!!!
      p_s_results-lbqt     = p_s_general-menge.
      p_s_results-lbqtunit = p_s_general-meinh.
      p_s_results-lbumrez  = p_s_general-umrez.
      p_s_results-lbumren  = p_s_general-umren.
*                ***      => Umwandlung der Eingabe-Menge in Default-ME
*                ***         und in der allgemeinen EIngabestruktur
*                ***         ablegen:
*                ***         - P_S_GENERAL-MENGE (manipuliert)
*                ***         - P_S_GENERAL-MEINS = DEFQTUNIT.
      PERFORM determine_i_qty_in_unit_new USING    p_s_general
                                                   p_s_results-defqtunit
                                          CHANGING p_s_results
                                                   p_s_general-menge.
      p_s_general-meinh = p_s_results-defqtunit.
      CLEAR: p_s_general-umrez,
             p_s_general-umren.
    ENDIF.
  ENDIF.

* Begin-of-Note-589767
* Enterprise 2.0
* BADI for modification of input parameters in rounding
* For example assign the site's unit of issue (MARC-AUSME)
* to default UoM in Sales Order in RETAIL ADD ON

  PERFORM call_badi_rounding TABLES   p_t_qt_units
                             USING    p_s_general
                                      p_s_mara
                             CHANGING p_s_eina
                                      p_s_eine
                                      p_s_marc
                                      p_s_marc_2
                                      p_s_mvke
                                      p_s_knmt
                                      p_s_knvv
                                      p_s_results.

* End-of-Note-589767




*                *** 6. Kundenindividuelle Korrektur der bestimmten
*                ***    Rundungsparameter mit Hilfe eines User-Exits
*                ***    möglich
  PERFORM call_user_exit_005 TABLES   p_t_qt_units
                             USING    p_s_general
                                      p_s_mara
                             CHANGING p_s_eina
                                      p_s_eine
                                      p_s_marc
                                      p_s_marc_2
                                      p_s_mvke
                                      p_s_knmt
                                      p_s_knvv
                                      p_s_results.

ENDFORM.                               " READ_data_U12

*&---------------------------------------------------------------------*
*&      Form  read_data_u12_2
*&---------------------------------------------------------------------*
*       Lese alle benötigten Daten aus der DB bzw. aus der Eingabestrukt
*       => Bestimmung der Rundungsparameter und der erlaubten ME
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur laut Aufrufstelle
*      -->P_S_MARA     gelesener MARA-Eintrag
*      -->P_S_MPN      Herstellermaterialnummer und Profil
*      <--P_S_GENERAL  allgemeine Eingabestruktur für LB-Aufruf mit
*                      manipulierter Eingabe-Menge und -ME.
*      <--p_s_results  Bestimmte Rundungsparameter
*      <--p_t_qt_units erlaubte ME
*      <--P_S_EINA     für EK
*      <--P_S_EINE     für EK
*      <--P_S_MARC     für EK
*      <--P_S_MARC_2   für EK
*      <--P_S_MVKE     für VK
*      <--P_S_KNMT     für VK
*      <--P_S_KNVV     für VK
*----------------------------------------------------------------------*
FORM read_data_u12_2 TABLES
                       p_t_qt_units    TYPE  mdr1p_t_out_allowed_qt_unit
                     USING
                       p_s_mara        TYPE  mara
                       p_s_mpn         TYPE  mdr1insingleround_mpn
                     CHANGING
                       p_s_general     TYPE  mdr1p_s_in_single_round
                       p_s_results     TYPE  mdr1p_s_out_single_round
                       p_s_eina        TYPE  eina
                       p_s_eine        TYPE  eine
                       p_s_marc        TYPE  marc
                       p_s_marc_2      TYPE  marc
                       p_s_mvke        TYPE  mvke
                       p_s_knmt        TYPE  knmt
                       p_s_knvv        TYPE  knvv.

  DATA:  l_s_round_params  TYPE  mdr1p_s_round_params,
         l_s_input         TYPE  mdr1p_s_in_allowed_qt_unit.

*$@006 mbi 4.70 - Anfang
*                *** Dummy-Variable, die nur als Parameter eines
*                *** Unterprogrammes mitgegeben werden müßen.
  DATA l_dummy TYPE mdr1p_s_in_allowed_qt_unit.
*$@006 mbi 4.70 - Ende


*#@007 HWI 4.70 customizing of logistical rounding B

  IF p_s_general-rappl IS INITIAL.

    IF p_s_general-tcode IS INITIAL.
      p_s_general-tcode = sy-tcode.
    ENDIF.

*                *** FB/UP zum Lesen des Customizings
    PERFORM call_customizing_read CHANGING p_s_general.

  ENDIF.

*#@007 HWI 4.70 customizing of logistical rounding E

  CLEAR: p_t_qt_units[].

*                *** 1. Basis-ME in den Rundungsparametern ablegen:
  p_s_results-meins = p_s_mara-meins.

*                *** 2. weitere Rundungsparameter bestimmen:
  MOVE-CORRESPONDING p_s_general  TO  l_s_round_params.

  IF NOT ( l_s_round_params IS INITIAL ).
*                ***    a) Rundungsparameter wurden schon von der
*                ***       Aufrufstelle bestimmt
*                ***       => KEINE DB-Zugriffe mehr nötig!
    MOVE-CORRESPONDING l_s_round_params  TO p_s_results.
  ELSE.
*                ***    b) Rundungsparameter werden über DB-Zugriffe be-
*                ***       stimmt
    PERFORM read_data_from_db_u12 USING    p_s_mara
                                           p_s_general
                                           p_s_mpn
                                  CHANGING p_s_results
                                           p_s_eina
                                           p_s_eine
                                           p_s_marc
                                           p_s_marc_2
                                           p_s_mvke
                                           p_s_knmt
                                           p_s_knvv.
  ENDIF.

*                *** 3. Bestimme die erlaubten ME (p_t_qt_units)

*                ***    - Eingabestruktur für den FB: MD_ALLOWED_QT_UNIT
*                ***      belegen:
*                ***      -> mit den Daten aus der Eingabestruktur
  MOVE-CORRESPONDING p_s_general  TO  l_s_input.

*                ***      -> mit den Daten der bestimmten RundParametern
  MOVE-CORRESPONDING p_s_results  TO  l_s_input.

*                ***      -> Festlegung der Unternehmenssicht abhängig
*                ***         vom OPCODE:
  CASE p_s_general-opcode.

*                ***         EK-OPCodes => EK-Sicht
    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_lb.

      l_s_input-appview  = mdr1p_c_appview_purchase.

*                ***         VK-OPCode => VK-Sicht
    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung
      OR mdr1p_c_op_sd_verf.

      l_s_input-appview  = mdr1p_c_appview_sale.

*                ***         Bei Additional => nur die Basis-ME ist
*                ***                           erlaubt!!!
*                ***                        => Bestimmung über Baustein
*                ***                           nicht nötig
    WHEN mdr1p_c_op_additionals.

      CLEAR: l_s_input-appview,  " => KEINE Bestimmung über Baustein
             p_t_qt_units.

      p_t_qt_units-matnr         = p_s_general-matnr.
      p_t_qt_units-meinh         = p_s_results-meins.
      p_t_qt_units-umrez         = 1.
      p_t_qt_units-umren         = 1.
      p_t_qt_units-flagdefqtunit = c_yes.
      p_t_qt_units-flagvenqtunit = c_yes.
      p_t_qt_units-flagbuyqtunit = c_yes.
      p_t_qt_units-flagallqtunit = c_yes.

      APPEND p_t_qt_units.

  ENDCASE.

*                ***      -> Auswahl der Funktionalität: erlaubte log.ME
  l_s_input-flagallqtunit  =  c_yes.

  IF NOT ( l_s_input-appview IS INITIAL ).
*                ***    - Aufruf des FB zur Bestimmung der erl. ME,
*                ***      wenn gewünscht!!!
    PERFORM call_allowed_quantity_unit TABLES   p_t_qt_units
                                       USING    l_s_input
                                                p_s_mara
                                                p_s_eina
                                                p_s_eine
                                                p_s_marc
                                                p_s_marc_2
                                                p_s_mvke
                                                p_s_knmt
                                                p_s_knvv.
  ENDIF.

*$@001 Anfang MWE-ENTW-46C
*                ***    - Sortiere die Menge der erlaubten
*                ***      ME
  SORT p_t_qt_units
    BY meinh.
*$@001 Ende MWE-ENTW-46C

*                *** 4. Aus dem Ergebnis die Default-ME bestimmen:
  LOOP AT p_t_qt_units
    WHERE flagdefqtunit = c_yes.
*                ***    Es gibt nur eine ausgezeichnete Default-ME
    p_s_results-defqtunit  =  p_t_qt_units-meinh.
    p_s_results-defumrez   =  p_t_qt_units-umrez.
    p_s_results-defumren   =  p_t_qt_units-umren.
*$@001 Anfang MWE-ENTW-46C
    EXIT.
*$@001 Ende MWE-ENTW-46C
  ENDLOOP.

*$@006 mbi 4.70 - Anfang
*                *** Bestimme zu der ME der Liefereinheit die Umrech-
*                *** nungsfaktoren.
  READ TABLE p_t_qt_units WITH KEY meinh = p_s_results-schme
       BINARY SEARCH.

*                *** Nur, falls Liefereinheit gepflegt ist.
  IF sy-subrc = 0.

*                *** Übernehme die Umrechnungsfaktoren
    p_s_results-schmeumrez = p_t_qt_units-umrez.
    p_s_results-schmeumren = p_t_qt_units-umren.

  ENDIF.

*                *** Bestimme je nach Anwendungssicht die Megru´s
  IF l_s_input-appview = mdr1p_c_appview_purchase.

*                *** Einkaufssicht

*                *** Bestimme die Lieferanten-ME-Gruppe
    PERFORM det_ven_unit_gr_purchase
                USING
                   l_dummy
                   p_s_eine
                   p_s_marc_2                     "note 2081705
                CHANGING
                   p_s_results-venunitgr.

*                *** Bestimme die Abnehmer-ME-Gruppe
    PERFORM det_buy_unit_gr_purchase
                USING
                   l_dummy
                   p_s_marc
                CHANGING
                   p_s_results-buyunitgr.

  ELSEIF l_s_input-appview = mdr1p_c_appview_sale.

*                *** Verkaufssicht

*                *** Bestimme die Lieferanten-ME-Gruppe
    PERFORM det_ven_unit_gr_sale
                USING
                   l_dummy
                   p_s_mvke
                CHANGING
                   p_s_results-venunitgr.

*                *** Bestimme die Abnehmer-ME-Gruppe
    PERFORM det_buy_unit_gr_sale
                USING
                   l_dummy
                   p_s_knmt
                   p_s_knvv
                CHANGING
                   p_s_results-buyunitgr.

  ENDIF.
*$@006 mbi 4.70 - Ende

* Anfang MWE-HW-333191
  IF l_s_round_params IS INITIAL.
*                ***    Restliche bestimmte Rundungsparameter
*                ***    an Aufrufstelle zurückliefern
*                ***    Kennzeichen für variable Bestell-ME festlegen:
    IF NOT ( p_s_eina IS INITIAL ).

      p_s_results-vabme  =  p_s_eina-vabme.

    ELSE.

      p_s_results-vabme  =  p_s_mara-vabme.

    ENDIF.

*                ***    Kennzeichen für variable Verkaufs-ME festlegen:
    IF NOT ( p_s_mvke IS INITIAL ).

      p_s_results-vavme  =  p_s_mvke-vavme.

    ENDIF.
  ENDIF.
* Ende MWE-HW-333191

*                *** 5. Spezialbehandlung für LB-Aufruf:
  IF p_s_general-opcode = mdr1p_c_op_lb.
*                ***    - Untersuche, ob Eingabe-ME eine erlaubte ME ist
    CLEAR p_t_qt_units.

    READ TABLE p_t_qt_units
      WITH KEY meinh = p_s_general-meinh
*$@001 Anfang MWE-ENTW-46C
               BINARY SEARCH.
*$@001 Ende MWE-ENTW-46C

    IF NOT ( p_t_qt_units-flagallqtunit = c_yes ).
*                ***    - Eingabe-ME nicht erlaubt ME
*                ***      => ursprüngliche Eingabe merken!!!
      p_s_results-lbqt     = p_s_general-menge.
      p_s_results-lbqtunit = p_s_general-meinh.
      p_s_results-lbumrez  = p_s_general-umrez.
      p_s_results-lbumren  = p_s_general-umren.
*                ***      => Umwandlung der Eingabe-Menge in Default-ME
*                ***         und in der allgemeinen EIngabestruktur
*                ***         ablegen:
*                ***         - P_S_GENERAL-MENGE (manipuliert)
*                ***         - P_S_GENERAL-MEINS = DEFQTUNIT.
      PERFORM determine_i_qty_in_unit_new USING    p_s_general
                                                   p_s_results-defqtunit
                                          CHANGING p_s_results
                                                   p_s_general-menge.
      p_s_general-meinh = p_s_results-defqtunit.
      CLEAR: p_s_general-umrez,
             p_s_general-umren.
    ENDIF.
  ENDIF.

* Begin-of-Note-589767
* Enterprise 2.0
* BADI for modification of input parameters in rounding
* For example assign the site's unit of issue (MARC-AUSME)
* to default UoM in Sales Order in RETAIL ADD ON

  PERFORM call_badi_rounding TABLES   p_t_qt_units
                             USING    p_s_general
                                      p_s_mara
                             CHANGING p_s_eina
                                      p_s_eine
                                      p_s_marc
                                      p_s_marc_2
                                      p_s_mvke
                                      p_s_knmt
                                      p_s_knvv
                                      p_s_results.

* End-of-Note-589767

*                *** 6. Kundenindividuelle Korrektur der bestimmten
*                ***    Rundungsparameter mit Hilfe eines User-Exits
*                ***    möglich
  PERFORM call_user_exit_005 TABLES   p_t_qt_units
                             USING    p_s_general
                                      p_s_mara
                             CHANGING p_s_eina
                                      p_s_eine
                                      p_s_marc
                                      p_s_marc_2
                                      p_s_mvke
                                      p_s_knmt
                                      p_s_knvv
                                      p_s_results.

ENDFORM.                    "read_data_u12_2

*&---------------------------------------------------------------------*
*&      Form  READ_data_from_DB_U12
*&---------------------------------------------------------------------*
*       Lese alle benötigten Rundungsparamter aus der DB
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      -->P_S_MARA     gelesener MARA-Eintrag
*      <--l_s_results  Bestimmte Rundungsparameter
*      <--P_S_EINA     für EK
*      <--P_S_EINE     für EK
*      <--P_S_MARC     für EK
*      <--P_S_MARC_2   für EK
*      <--P_S_MVKE     für VK
*      <--P_S_KNMT     für VK
*      <--P_S_KNVV     für VK
*----------------------------------------------------------------------*
FORM read_data_from_db_u12 USING
                     p_s_mara           TYPE  mara
                     p_s_general        TYPE  mdr1p_s_in_single_round
                     p_s_mpn            TYPE  mdr1insingleround_mpn
                   CHANGING
                     p_s_results        TYPE  mdr1p_s_out_single_round
                     p_s_eina           TYPE  eina
                     p_s_eine           TYPE  eine
                     p_s_marc           TYPE  marc
                     p_s_marc_2         TYPE  marc
                     p_s_mvke           TYPE  mvke
                     p_s_knmt           TYPE  knmt
                     p_s_knvv           TYPE  knvv.

*                *** 1. Daten, die unabhängig vom OpCode benötigt werden


*                *** 2. Daten, die abhängig vom OPCODE benötigt werden
  CASE p_s_general-opcode.

*                ***    - EK-OpCodes
    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_lb.

      PERFORM read_data_purch_u12 USING    p_s_mara
                                           p_s_general
                                           p_s_mpn
                                  CHANGING p_s_results
                                           p_s_eina
                                           p_s_eine
                                           p_s_marc
                                           p_s_marc_2.

*                ***    - allgemeine VK-OpCodes
    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung.

      PERFORM read_data_sales_u12 USING    p_s_mara
                                           p_s_general
                                  CHANGING p_s_results
                                           p_s_mvke
                                           p_s_knmt
                                           p_s_knvv.

*                ***    - spezielles VK-Verfahren
    WHEN mdr1p_c_op_sd_verf.
*                ***      für diesen Fall werden keine weiteren
*                ***      DB-Zugriffe benötigt (alle Rundungsparameter
*                ***      werden von der Aufrufstelle vorgegeben.

*                ***    - Verkaufshilfsmittel-OpCode
    WHEN mdr1p_c_op_additionals.
*                ***      die Daten werden hier nur aus der MARC
*                ***      genommen.
      PERFORM read_data_addit_u12 USING    p_s_general
                                  CHANGING p_s_results
                                           p_s_marc.

  ENDCASE.

ENDFORM.                               " READ_data_from_DB_U12

*&---------------------------------------------------------------------*
*&      Form  read_data_purch_u12
*&---------------------------------------------------------------------*
*       Bestimme Daten für den Einkauf
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      -->P_S_MARA     Bestimmter MARA-Eintrag
*      <--P_S_RESULTS  Bestimmte Rundungsparameter
*      <--P_S_EINA
*      <--P_S_EINE
*      <--P_S_MARC
*      <--P_S_MARC_2
*----------------------------------------------------------------------*
FORM read_data_purch_u12
                   USING
                     p_s_mara      TYPE mara
                     p_s_general   TYPE mdr1p_s_in_single_round
                     p_s_mpn       TYPE mdr1insingleround_mpn
                   CHANGING
                     p_s_results   TYPE mdr1p_s_out_single_round
                     p_s_eina      TYPE eina
                     p_s_eine      TYPE eine
                     p_s_marc      TYPE marc
                     p_s_marc_2    TYPE marc.

  DATA:  l_s_lfa1  LIKE  lfa1,
         l_ekorg   LIKE  eine-ekorg.

  CLEAR: p_s_eina,
         p_s_eine,
         p_s_marc,
         p_s_marc_2,
         l_s_lfa1.

  IF NOT ( p_s_general-lifnr IS INITIAL ).
*                *** Wenn der Lieferant bekannt ist:
    l_ekorg = p_s_general-ekorg.

    IF l_ekorg IS INITIAL.
*                *** - EKORG zum Werk (= Abnehmer) bestimmen,
*                ***   wenn EKORG nicht vorgegeben und wenn es eine
*                ***   eindeutige zum Werk gibt
*                ***   das Ergebnis wird in der Eingabe-Struktur gemerkt
      PERFORM read_ekorg_single USING     p_s_general-werks
                                CHANGING  l_ekorg.
    ENDIF.

    IF NOT ( l_ekorg IS INITIAL ).

      IF cl_ops_switch_check=>sfsw_segmentation( ) EQ abap_on.
        l_s_general-sgt_scat = p_s_general-sgt_scat.
      ENDIF.
*                *** - EK-Infosatz zu Lieferant und EKORG bestimmen
      PERFORM read_eina_eine  USING     p_s_general-lifnr
                                        l_ekorg              " <> LEER
                                        p_s_general-werks
                                        p_s_general-matnr
                                        p_s_general-infnr
                                        p_s_mara-satnr
                                        p_s_mara-attyp
*$@003 Anfang MWE-HW-186918
                                        p_s_general-pstyp
*$@003 Ende MWE-HW-186918
                                        p_s_mpn-ematn
                                        p_s_mpn-mprof
                              CHANGING  p_s_eina
                                        p_s_eine.
    ENDIF.

*                *** - Ist die Bestell-ME EINA-MEINS nicht belegt,
*                ***   müssen noch weitere Daten zur Bestimmung der
*                ***   erlaubten ME bestimmt werden
    IF p_s_eina-meins IS INITIAL.
*                ***   Unteruche zuerst, ob interner Lieferant vor-
*                ***   liegt => Lese LFA1
      PERFORM read_lfa1_single  USING     p_s_general-lifnr
                                CHANGING  l_s_lfa1.

*                ***   Bei internen Lieferanten (UBs) wird der
*                ***   der Marc-Satz zum Lieferwerk gelesen
      IF NOT ( l_s_lfa1-werks IS INITIAL ).

        PERFORM read_marc_single  USING    p_s_general-matnr
                                           l_s_lfa1-werks
                                  CHANGING p_s_marc_2.
*                ***   Setzte zusätzlich noch Kennzeichen interner
*                ***   Lieferant
        p_s_results-intvend = c_intvend.               " = 'I'

      ELSE.
        p_s_results-intvend = c_extvend.               " = 'E'
      ENDIF.
    ENDIF.                             " Bestell-ME: EINA-MEINS = LEER
  ELSE.
*                *** Lieferant nicht bekannt oder nicht angelegt
*                *** z.B.: VZ nicht als Kreditor angelegt (möglich!!)
*                *** => Lese MARC zum Übergebenen Kreditor = Werk!!!
    IF NOT ( p_s_general-werks_kred IS INITIAL ).

      PERFORM read_marc_single  USING    p_s_general-matnr
                                         p_s_general-werks_kred
                                CHANGING p_s_marc_2.
*                ***   Setzte zusätzlich noch Kennzeichen interner
*                ***   Lieferant
      p_s_results-intvend = c_intvend. " = 'I'

    ENDIF.
  ENDIF.                               " Lieferant gefüllt

*#@007 HWI 4.70 customizing of logistical rounding B

  PERFORM call_purpar_determine USING    p_s_eina
                                         p_s_eine
                                         p_s_general-matnr
                                         p_s_general-werks
                                         p_s_general-purpar
                                CHANGING p_s_results
                                         p_s_marc.
*#@007 HWI 4.70 customizing of logistical rounding E

ENDFORM.                               " read_data_purch_u12

*&---------------------------------------------------------------------*
*&      Form  choose_rounding_method
*&---------------------------------------------------------------------*
*       Lege die Rundungsmethode an Hand der bestimmten Rundungs-
*       parameter fest und führe die Rundung durch.
*----------------------------------------------------------------------*
*      -->p_t_qt_units erlaubte ME
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      -->P_S_RESULTS  Bestimmte Rundungsparameter
*      <--P_S_RESULTS  Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons Rundungsgründe
*----------------------------------------------------------------------*
FORM choose_rounding_method
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

*                *** Rundungsverfahren abhängig vom OPCODE festlegen und
*                *** durchführen
  CASE p_s_general-opcode.

*                *** - EK-OpCodes
    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_lb.

      PERFORM rounding_purchase   TABLES   p_t_qt_units
                                           p_t_round_reasons
                                  USING    p_s_general
                                  CHANGING p_s_results.

*                ***    - allgemeine VK-OpCodes
    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung.

      PERFORM rounding_sales   TABLES   p_t_qt_units
                                        p_t_round_reasons
                               USING    p_s_general
                               CHANGING p_s_results.

*                ***    - spezielles VK-Verfahren
    WHEN mdr1p_c_op_sd_verf.

      PERFORM rounding_sales_special TABLES   p_t_qt_units
                                              p_t_round_reasons
                                     USING    p_s_general
                                     CHANGING p_s_results.

*                ***    - Verkaufshilfsmittel-OpCode
    WHEN mdr1p_c_op_additionals.
      PERFORM rounding_additionals   TABLES   p_t_qt_units
                                              p_t_round_reasons
                                     USING    p_s_general
                                     CHANGING p_s_results.

  ENDCASE.

*                *** nach der Rundung befindet sich das Rundungsergebnis
*                *** in:
*                ***   p_s_results-roundqt: Rundungsmenge in ME:rqtunit
*                ***   p_s_results-rqtunit: Rundungs-ME
*                *** wenn gerundet wurde!!!
  IF NOT ( p_s_results-roundqt IS INITIAL )
  OR NOT ( p_s_results-rqtunit IS INITIAL ).
*                *** Ergebnis in eigentliche Ausgabe-Felder Stellen
    p_s_results-lmenge = p_s_results-roundqt.
    p_s_results-logme  = p_s_results-rqtunit.
  ENDIF.

  IF p_s_results-logme = p_s_general-meinh.
*                *** - Eingabe-ME = Rundungs-ME => keine Umrechnung
    p_s_results-menge = p_s_results-lmenge.
  ELSE.
*                *** - Eingabe-ME <> Rundungs-ME => Umrechnung durchf.
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    p_s_general-meinh
                           CHANGING p_s_results
                                    p_s_results-menge.
  ENDIF.

ENDFORM.                               " choose_rounding_method

*&---------------------------------------------------------------------*
*&      Form  rounding_purchase
*&---------------------------------------------------------------------*
*       Auswahl und Durchführung der Rundungsverfahren für die
*       EK-OpCodes
*       Hinweis: Die Rundung wird nur Durchgeführt wenn die entsp.
*                Rundungsparameter durch die folgende Logik belegt
*                wurden:
*                1. durch Vorgabewerte der Aufrufstelle (NEU!!!)
*                   oder
*                2. durch den EK-Info-Satz (EINA/EINE)
*                   oder
*                3. durch den MARC-Satz
*
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM rounding_purchase
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  IF  p_s_results-rdprf IS INITIAL
  AND p_s_results-bstrf IS INITIAL
  AND p_s_results-maxqt IS INITIAL
  AND p_s_results-minqt IS INITIAL.
*                *** Die Parameter geben keine Rundungsverf.
*                *** vor
*                *** => Runde auf erlaubte log. ME => s. Abschlußbeh.
*                *** => Entferne ungültige Dezimalstellen => s. Abschl.
    EXIT.                              " => FERTIG
  ENDIF.

  IF NOT ( p_s_results-rdprf IS INITIAL ).
*                *** Rundungsprofilmethoden
    PERFORM rounding_profil  TABLES   p_t_qt_units
                                      p_t_round_reasons
                             USING    p_s_general
                             CHANGING p_s_results.
  ELSE.

    IF p_s_results-bstrf > 0
*#@007 HWI 4.70 customizing of logistical rounding B
    AND p_s_general-rvalu = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

*                *** Rundungswertverfahren
      PERFORM call_rounding_value  TABLES   p_t_round_reasons
                                   USING    p_s_general
                                   CHANGING p_s_results.
    ENDIF.
*                *** sonst nur MAX/MIN-Test!!!
  ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding B
* Customizing rules
* IF  NOT ( p_s_general-no_min_max_check = c_yes )
  IF (    NOT ( p_s_results-maxqt IS INITIAL )
       OR NOT ( p_s_results-minqt IS INITIAL ) )
  AND p_s_general-rmami = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

*                *** Max und Min-Grenzen bei den gerundeten ME prüfen
    PERFORM check_min_max TABLES   p_t_round_reasons
                          USING    p_s_general
                          CHANGING p_s_results.
  ENDIF.

ENDFORM.                               " rounding_purchase

*&---------------------------------------------------------------------*
*&      Form  rounding_profil
*&---------------------------------------------------------------------*
*       Runde mit Hilfe eines Rundungsprofils
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM rounding_profil
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_t_rdpr LIKE rdpr
                 OCCURS 0 WITH HEADER LINE.

  CLEAR l_t_rdpr[].

*                *** Bestimme zuerst die Rundungsprofil Definition,
*                *** wenn sie noch nicht durch die Aufrufstelle vor-
*                *** gegeben wurde.
  IF  p_s_results-rdprf  <>  p_s_results-rdpr-rdprf
  AND (   p_s_general-werks       =   p_s_results-rdpr-werks
       OR p_s_results-rdpr-werks  IS  INITIAL ).
*                *** - Bestimme die komplette Definition mit Hilfe
*                ***   des entsprechenden Lesebausteins.
    PERFORM read_rdpr_all  TABLES   l_t_rdpr
                           USING    p_s_results-rdprf
                                    p_s_general-werks
                           CHANGING p_s_results-rdpr.
  ENDIF.

*                *** Auswahl der Rundungsverfahrens über die Rundungs-
*                *** Methode:
  CASE p_s_results-rdpr-rdmpo.

    WHEN c_rdmpo_abs.                  "absolut runden
*#@007 HWI 4.70 customizing of logistical rounding B
      IF p_s_general-rstat = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

        PERFORM call_check_rounding_profile TABLES   l_t_rdpr
                                                     p_t_round_reasons
                                            USING    p_s_general
                                            CHANGING p_s_results.

*#@007 HWI 4.70 customizing of logistical rounding B
      ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding E

    WHEN c_rdmpo_no.                   "nicht runden
*                *** die gerundete Menge entspricht der Eingabe-Menge
*                *** (Max- und Min-Tests können noch durchgeführt werd.)
*#@007 HWI 4.70 customizing of logistical rounding B
      IF p_s_general-rdyna = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

        p_s_results-roundqt = p_s_general-menge.
        p_s_results-rqtunit = p_s_general-meinh.

*#@007 HWI 4.70 customizing of logistical rounding B
      ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding E

    WHEN c_rdmpo_bstme.                "runde auf die Default-ME
*                *** Runde auf die entsprechende Default-ME
*#@007 HWI 4.70 customizing of logistical rounding B
      IF p_s_general-rdyna = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

        PERFORM rounding_defqtunit TABLES   p_t_round_reasons
                                   USING    p_s_general
                                   CHANGING p_s_results.

*#@007 HWI 4.70 customizing of logistical rounding B
      ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding E

    WHEN c_rdmpo_opt.                  "runde auf logist. ME
*                *** Runde mit Hilfe von Schwellenwert für Auf- und
*                *** Abrunden (ME-abhängig)
*#@007 HWI 4.70 customizing of logistical rounding B
      IF p_s_general-rdyna = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

        PERFORM rounding_qtunits TABLES    p_t_qt_units
                                           p_t_round_reasons
                                 USING     p_s_general
                                 CHANGING  p_s_results.

*#@007 HWI 4.70 customizing of logistical rounding B
      ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding E


    WHEN c_rdmpo_opt_no_null.          "runde auf log. ME ohne Null
*                *** Runde mit Hilfe von Schwellenwert für Auf- und
*                *** Abrunden (ME-abhängig), wobei auf 0 nur
*                *** bei der Default-ME abgerundet werden darf.
*#@007 HWI 4.70 customizing of logistical rounding B
      IF p_s_general-rdyna = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

        PERFORM rounding_qtunits TABLES    p_t_qt_units
                                           p_t_round_reasons
                                 USING     p_s_general
                                 CHANGING  p_s_results.

*#@007 HWI 4.70 customizing of logistical rounding B
      ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding E

    WHEN c_rdmpo_up_down.              "runde mit Auf- und Abschlag
*                *** Runde mit Hilfe von Auf- und Abschlagsrundung

*#@007 HWI 4.70 customizing of logistical rounding B
      IF p_s_general-raufab = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

        PERFORM rounding_up_down  TABLES   l_t_rdpr
                                           p_t_round_reasons
                                  USING    p_s_general
                                  CHANGING p_s_results.

*#@007 HWI 4.70 customizing of logistical rounding B
      ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding E

    WHEN OTHERS.
*                *** nicht bekannt Rundungsmethode wird als
*                *** individuelle Rundungsmethode interpretiert
*                *** => Aufruf eines User-Exits zum kundenindividuellen
*                ***    Runden
      PERFORM call_user_exit_003 TABLES   p_t_qt_units
                                          p_t_round_reasons
                                 USING    p_s_general
                                 CHANGING p_s_results.

  ENDCASE.

ENDFORM.                               " rounding_profil

*&---------------------------------------------------------------------*
*&      Form  rounding_defqtunit
*&---------------------------------------------------------------------*
*       Runde auf die bestimmte Default-ME (Bestell- oder VK-ME) mit
*       dem kleinsten ganzzahligem Ergebnis >= Eingabemenge
*----------------------------------------------------------------------*
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons Rundungsgründe
*----------------------------------------------------------------------*
FORM rounding_defqtunit
                   TABLES
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_qty            TYPE mdr1p_p_16_dec_14,
        l_qty_p(16)      TYPE p   DECIMALS 14,
        l_roundqt_p(16)  TYPE p   DECIMALS 14.

*                *** Umwandeln der Eingabe-Menge in Default-ME
  PERFORM determine_i_qty_in_unit_new USING    p_s_general
                                               p_s_results-defqtunit
                                      CHANGING p_s_results
                                               l_qty.
*                *** Aufrunden auf kleinsten ganzzahligen Wert,
*                *** der nicht kleiner als l_qty ist!!!
  l_qty_p              =  l_qty.
  l_roundqt_p          =  ceil( l_qty_p ).

  p_s_results-roundqt  =  l_roundqt_p.
  p_s_results-rqtunit  =  p_s_results-defqtunit.

  IF l_qty  <>  p_s_results-roundqt.
*                *** Rundungsgrund setzen, wenn wirklich eine neu
*                *** Menge durch das Aufrunden entsteht
    PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                  USING  mdr1p_c_rdpr_bstme.
  ENDIF.

ENDFORM.                               " rounding_defqtunit

*&---------------------------------------------------------------------*
*&      Form  rounding_qtunits
*&---------------------------------------------------------------------*
*       Runde abhängig von den gültigen ME des Materials (MARM) mit
*       Hilfe von Rundungsregeln, die pro ME definiert werden.
*       => dynamisches Runden
*----------------------------------------------------------------------*
*      -->P_T_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungspara.
*      <--P_S_RESULTS       Bestimmte Rundungspara. und der Rundungswert
*      <--p_t_round_reasons Rundungsgründe
*----------------------------------------------------------------------*
FORM rounding_qtunits
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_swpauf LIKE tw06s-swpauf,
        l_swpab  LIKE tw06s-swpab,
        l_found  TYPE c.

  DATA: l_t_qt_units TYPE   mdr1p_t_out_allowed_qt_unit
                     WITH HEADER LINE,
        BEGIN OF       l_t_qtu_sort   OCCURS 0,
          facto  TYPE  mdr1p_p_16_dec_14,
*$@005 Anfang HW-430276-MWE
          factof TYPE  f,
*$@005 Ende HW-430276-MWE
          meinh  LIKE  marm-meinh,
          umrez  TYPE  mdr1p_p_16_dec_14,
          umren  TYPE  mdr1p_p_16_dec_14,
*$@005 Anfang HW-430276-MWE
          umrezf TYPE  f,
          umrenf TYPE  f,
*$@005 Ende HW-430276-MWE
        END OF         l_t_qtu_sort.

*$@005 Anfang HW-430276-MWE
  DATA:  l_facto_f  TYPE  f.
*$@005 Ende HW-430276-MWE

*                *** Bestimme die gültigen ME zu dem Artikle mit
*                *** den Umrechnungs-Faktoren
  PERFORM get_units_factors TABLES l_t_qt_units
                            USING  p_s_general
                                   p_s_results.

*                *** Sortiere die bestimmten ME nach der Größe durch
*                *** Bestimmung des Umrechnungsfaktors
*                *** - Baue neue Tabelle mit dem Umrechnungsfaktor auf:
  LOOP AT l_t_qt_units.

    CLEAR: l_t_qtu_sort.
    MOVE-CORRESPONDING  l_t_qt_units  TO  l_t_qtu_sort.

*$@005 Anfang HW-430276-MWE
*$    IF l_t_qtu_sort-umren <> 0.
*$      l_t_qtu_sort-facto =    l_t_qtu_sort-umrez
*$                            / l_t_qtu_sort-umren.
*$    ENDIF.
    IF      l_t_qtu_sort-umrez  <>  0
    AND     l_t_qtu_sort-umren  <>  0.
*                *** Faktor ohne FP
      l_t_qtu_sort-facto =    l_t_qtu_sort-umrez
                            / l_t_qtu_sort-umren.

    ELSEIF  l_t_qtu_sort-umrez  =   0
       AND  l_t_qtu_sort-umren  =   0.

      IF l_t_qtu_sort-umrenf <> 0.
*                *** Faktor mit Zaehler-FP und Nenner-FP
        l_facto_f  =    l_t_qtu_sort-umrezf
                      / l_t_qtu_sort-umrenf.

        IF  l_facto_f  >=  c_10_exp_17.

          l_t_qtu_sort-factof  =  l_facto_f.
          l_t_qtu_sort-facto   =  c_max_p_16_dec_14.

        ELSE.

          l_t_qtu_sort-facto   =  l_facto_f.

        ENDIF.

      ENDIF.

    ELSEIF  l_t_qtu_sort-umrez  =   0
       AND  l_t_qtu_sort-umren  <>  0.
*                *** Faktor mit Zaehler-FP
      l_facto_f  =    l_t_qtu_sort-umrezf
                    / l_t_qtu_sort-umren.

      IF  l_facto_f  >=  c_10_exp_17.

        l_t_qtu_sort-factof  =  l_facto_f.
        l_t_qtu_sort-facto   =  c_max_p_16_dec_14.

      ELSE.

        l_t_qtu_sort-facto   =   l_t_qtu_sort-umrezf
                               / l_t_qtu_sort-umren.

      ENDIF.

    ELSE.
*                *** Faktor mit Nenner-FP
      IF l_t_qtu_sort-umrenf <> 0.

        l_facto_f  =    l_t_qtu_sort-umrez
                      / l_t_qtu_sort-umrenf.

        IF  l_facto_f  >=  c_10_exp_17.

          l_t_qtu_sort-factof  =  l_facto_f.
          l_t_qtu_sort-facto   =  c_max_p_16_dec_14.

        ELSE.

          l_t_qtu_sort-facto   =   l_t_qtu_sort-umrez
                                 / l_t_qtu_sort-umrenf.

        ENDIF.

      ENDIF.

    ENDIF.
*$@005 Ende HW-430276-MWE

    APPEND l_t_qtu_sort.

  ENDLOOP.
*                *** - Sortiere die neue Tabelle absteigend nach dem
*                ***   Umrechnungsfaktorn
*                ***   => d.h. die größten ME kommen zuerst!!!
*$@005 Anfang HW-430276-MWE
*$  SORT l_t_qtu_sort   DESCENDING   BY  facto.
  SORT l_t_qtu_sort   DESCENDING   BY  facto
                                       factof.

*$@005 Ende HW-430276-MWE

*                *** Beginne mit der größten ME und veruche auf diese
*                *** ME mit Hilfe der eventuell für die ME hinter-
*                *** legte Rundungsregel zu runden.
  LOOP AT l_t_qtu_sort.

    CLEAR: l_swpauf,
           l_swpab.

    l_found = c_no.

*                *** - Bestimme die Rundungsregel, die bei der ME
*                ***   hinterlegt ist.
    PERFORM determine_rounding_rule TABLES   p_t_qt_units
                                    USING    p_s_results
                                             l_t_qtu_sort-meinh
                                    CHANGING l_found
                                             l_swpauf
                                             l_swpab.

*                *** - Wende die existierende Regel an und beende
*                ***   die Schleife, wenn mit Regel gerundet wurde
    IF l_found = c_yes.
      PERFORM rounding_with_rule TABLES   p_t_round_reasons
                                 USING    p_s_general
                                          l_swpauf
                                          l_swpab
                                          l_t_qtu_sort-meinh
                                 CHANGING p_s_results.

      IF NOT ( p_s_results-rqtunit IS INITIAL ).

        EXIT.  " ---> FERTIG: verlasse die Schleife

      ENDIF.

    ENDIF.

    IF l_t_qtu_sort-meinh = p_s_results-defqtunit.
*                *** - Wurde auf aktuelle ME nicht gerundet,
*                ***   und die Default-ME = der aktuellen ME
*                ***   => Runde auf die Default-ME und beende die
*                ***      Schleife
      PERFORM rounding_defqtunit TABLES   p_t_round_reasons
                                 USING    p_s_general
                                 CHANGING p_s_results.

      EXIT.     " ---> FERTIG: verlasse die Schleife

    ENDIF.

  ENDLOOP.

ENDFORM.                               " rounding_qtunits

*&---------------------------------------------------------------------*
*&      Form  determine_rounding_rule
*&---------------------------------------------------------------------*
*       Bestimme die Rundungsregel zu einer ME bei einem dyn. Rundungs-
*       verfahren => Schwellenwerte (Auf und Ab-%-Wert) bestimmen
*       unter Berücksichtigung der erlaubten Lief- und Abn-ME
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS          erlaubte ME
*      -->P_S_RESULTS           Bestimmte Rundungsparameter
*      -->P_MEINH               ME
*      <--P_FOUND               Kennzeichen ob Schwellenwerte existieren
*      <--P_SWPAUF              Schwellenwert fürs Aufrunden auf den
*                               nächst größeren ganzzahligen Wert der
*                               ME
*      <--P_SWPAB  text         Schwellenwert fürs Abrunden auf den
*                               nächst kleineren ganzzahligen Wert der
*                               der ME
*----------------------------------------------------------------------*
FORM determine_rounding_rule
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                   USING
                     p_s_results       TYPE mdr1p_s_out_single_round
                     p_meinh           LIKE marm-meinh
                   CHANGING
                     p_found           TYPE c
                     p_swpauf          LIKE tw06s-swpauf
                     p_swpab           LIKE tw06s-swpab.

  DATA:  l_s_tw06s  LIKE  tw06s.

  CLEAR: p_swpauf,
         p_swpab,
         l_s_tw06s.

*                *** Default: ME-erlaubt = l_found = 'X'
  p_found = c_yes.

*                *** Wird eine Prüfung auf erlaubten Lief- oder Abn-
*                *** ME gewünscht:
  IF NOT ( p_s_results-rdpr-chkmeli IS INITIAL )
  OR NOT ( p_s_results-rdpr-chkmeku  IS  INITIAL ).

*                *** - Suche die ME in der Tabelle der erlaubten Me
    READ TABLE p_t_qt_units
      WITH KEY meinh = p_meinh
*$@001 Anfang MWE-ENTW-46C
               BINARY SEARCH.
*$@001 Ende MWE-ENTW-46C

    IF sy-subrc <> 0.
*                *** - ME nicht gefunden
*                ***   => nicht erlaubte ME
      p_found = c_no.
    ELSE.
      IF  NOT ( p_s_results-rdpr-chkmeli    IS INITIAL )
      AND     ( p_t_qt_units-flagvenqtunit  =  c_no  ).
*                *** - erlaubte LIef-ME prüfen und keine erlaubte Lie-ME
*                ***   => nicht erlaubte ME
        p_found = c_no.
      ENDIF.

      IF  NOT ( p_s_results-rdpr-chkmeku   IS INITIAL )
      AND     ( p_t_qt_units-flagbuyqtunit =  c_no  ).
*                *** - erlaubte Abn-ME prüfen und keine erlaubte Abn-ME
*                ***   => nicht erlaubte ME
        p_found = c_no.
      ENDIF.
    ENDIF.
  ENDIF.

  IF p_found  =  c_yes.
*                *** Bestimme die Schwellenwerte aus TW06S zu der ME
*                *** und der Rundungsgegel
    PERFORM read_tw06s_single USING     p_meinh
                                        p_s_results-rdpr-rdrgl
                              CHANGING  l_s_tw06s.

    IF  l_s_tw06s IS INITIAL.
*                *** Kein Satz gefunden
      p_found = c_no.
    ELSE.
*                *** Schwellenwerte existieren
      p_found   =  c_yes.
      p_swpauf  =  l_s_tw06s-swpauf.
      p_swpab   =  l_s_tw06s-swpab.
    ENDIF.
  ENDIF.

ENDFORM.                               " determine_rounding_rule

*&---------------------------------------------------------------------*
*&      Form  rounding_with_rule
*&---------------------------------------------------------------------*
*       Runde mit Hilfe von vorgegeben Schwellenwerten
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      -->P_SWPAUF     Schwellenwert zum Aufrunden
*      -->P_SWPAB      Schwellenwert zum Abrunden
*      -->P_MEINH      Mengeneinheit zu dem Schwellenwert
*      -->P_S_RESULTS  Rundungsparameter
*      <--P_S_RESULTS  Rundungsparameter mit RUndungs-ergebnis
*      <--p_t_round_reasons Rundungsgründe
*----------------------------------------------------------------------*
FORM rounding_with_rule
                   TABLES
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                     p_swpauf          LIKE tw06s-swpauf
                     p_swpab           LIKE tw06s-swpab
                     p_meinh           LIKE marm-meinh
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_qty              TYPE  mdr1p_p_16_dec_14,
        l_qty_trunc(16)    TYPE  p   DECIMALS 14,
        l_qty_trunc_1(16)  TYPE  p   DECIMALS 14,
        l_qty_p(16)        TYPE  p   DECIMALS 14,
        l_diff_p(16)       TYPE  p   DECIMALS 14,
        l_swpauf_p(16)     TYPE  p   DECIMALS 14,
        l_swpab_p(16)      TYPE  p   DECIMALS 14.

  l_qty = p_s_general-menge.

*                *** Bestimme die Eingabe-Menge in der Schwellen-ME
  PERFORM determine_i_qty_in_unit_new USING    p_s_general
                                               p_meinh
                                      CHANGING p_s_results
                                               l_qty.

*                *** Bestimme zu der Eingabe-Menge in der Schwellen-ME
*                *** den ganzzahligen Wert und den nächst größeren
*                *** ganzzahligen Wert in der Schwellen-ME
  l_qty_p        =  l_qty.
  l_qty_trunc    =  trunc( l_qty_p ).
  l_qty_trunc_1  =  l_qty_trunc + 1.

*                *** Bestimme Differenz zwischen Eingabe-Menge
*                *** und ganzzahliger Anteil
*                *** => L_diff >= 0     da  l_qty >= L_qty_trunc
  l_diff_p       =    l_qty_p
                    - l_qty_trunc.

*                *** Bestimme die Schwellen Werte in der Schwellen-ME
  l_swpauf_p     =    p_swpauf.
  l_swpauf_p     =    l_swpauf_p
                    / 100 .
  l_swpab_p      =    p_swpab.
  l_swpab_p      =    l_swpab_p
                    / 100 .

*                *** Durchführung der Rundung mit den bestimmten Werten
  IF l_diff_p = 0.
*                *** Rundung fertig
*                ***    Rundungs-Menge = Eingabe-Menge in Schwellen-ME
*                *** da Eingabe-Menge schon als Vielfaches der
*                *** Schwellen-ME vorliegt.
    p_s_results-roundqt = l_qty.
    p_s_results-rqtunit = p_meinh.
  ELSE.
*                *** Durchführung der Rundung mit den bestimmten Werten

*                *** 1. Schwellen-Wert zum Abrunden erreicht:
    IF l_diff_p <= l_swpab_p.
*                ***    => Abrunde auf L_qty_trunc
      p_s_results-roundqt = l_qty_trunc.
      p_s_results-rqtunit = p_meinh.
*                ***    Spezial-Behandlung bei Rundungsmethode ohne
*                ***    Null-Runden außer bei der Default-ME
      IF  p_s_results-rdpr-rdmpo =  c_rdmpo_opt_no_null
      AND p_s_results-roundqt    =  0
      AND p_s_results-rqtunit    <> p_s_results-defqtunit.
*                ***    => Nullrunden nicht erlaubt => nicht runden!!!
        CLEAR: p_s_results-roundqt,
               p_s_results-rqtunit.
      ENDIF.
    ENDIF.

*                *** 2. Schwellen-Wert zum Abrunden erreicht:
    IF l_diff_p >= l_swpauf_p.
*                ***    => Aufrunde auf L_qty_trunc_1
*                ***    => hat höhere Prio
*                ***       (d.h. L_diff = L_swpab = l_swpauf wird immer
*                ***        Aufgerundet)
      p_s_results-roundqt = l_qty_trunc_1.
      p_s_results-rqtunit = p_meinh.
    ENDIF.

  ENDIF.

*                *** Rundungsgrund setzen, wenn
*                *** - gerundet wurde ( p_s_results-rqtunit <> LEER)
*                *** und
*                *** - sich die Menge oder Mengeneinheit geändert
*                ***   hat
  IF  NOT ( p_s_results-rqtunit IS INITIAL )
  AND     (   p_s_results-roundqt <> p_s_general-menge
           OR p_s_results-rqtunit <> p_s_general-meinh ).

    PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                  USING  mdr1p_c_rdpr_opt.
  ENDIF.

ENDFORM.                               " rounding_with_rule

*&---------------------------------------------------------------------*
*&      Form  rounding_up_down
*&---------------------------------------------------------------------*
*       Führe das Runden mit Auf- und Abschlag durch
*----------------------------------------------------------------------*
*      -->P_T_RDPR          Komplette Defintion des RUndungsprofils
*                           (wenn schon bestimmt)
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--P_T_RDPR          Komplette Defintion des RUndungsprofils
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM rounding_up_down
                   TABLES
                     p_t_rdpr          STRUCTURE  rdpr
                     p_t_round_reasons TYPE   mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE   mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE   mdr1p_s_out_single_round.

  DATA: l_qty       TYPE mdr1p_p_16_dec_14,
        l_qty_quan  LIKE ekpo-menge.

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

*                *** Sortiere die Sätze des Rundungsprofils
*                *** nach den Schwellenwerten abszteigend =>
*                ***  Beginn mit den größten Werten
  SORT p_t_rdpr  BY  bdmng  DESCENDING.

  l_qty_quan = l_qty.
*                *** Bestimme den größten Schwellenwert der kleiner oder
*                *** gleich der Eingabemenge ist
  LOOP AT p_t_rdpr.

    IF l_qty_quan >= p_t_rdpr-bdmng.

*                *** Schwellenwert gefunden => Wende Auf oder Abschlag
*                ***                           des Schwellenwerts
*                ***                           auf die Menge an
      p_s_results-roundqt  =   l_qty
                             * ( 1 + ( p_t_rdpr-vormg / 100 ) ).
*                *** Rundungs-ME: Basis-ME
      p_s_results-rqtunit = p_s_results-meins.
*                *** Rundungsgrund setzen
      PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                    USING  mdr1p_c_rdpr_opt.
*                *** Beende die Schleife
      EXIT.

    ENDIF.

  ENDLOOP.

ENDFORM.                               " rounding_up_down

*&---------------------------------------------------------------------*
*&      Form  check_min_max
*&---------------------------------------------------------------------*
*       Überprüfe. ob die gerundeten Mengen in den Min- und Max-Grenzen
*       liegen.
*       Liegt die gerundete Menge nicht in den entsprechenden Grenzen
*       wird sie noch an die Grenzen angepaßt.
*----------------------------------------------------------------------*
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM check_min_max
                   TABLES
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_qty       TYPE mdr1p_p_16_dec_14,
        l_qty_quan  LIKE ekpo-menge,
        l_max_quan  LIKE ekpo-menge,
        l_min_quan  LIKE ekpo-menge,
        l_qty_unit  LIKE marm-meinh.

*                *** Bestimme die gerundete Menge in der ME der Grenzen

*                *** - Bestimme die Rundungsmenge und Rund-ME:
  IF p_s_results-rqtunit IS INITIAL.
*                ***   gerundete Menge = Eingabe-Menge
    l_qty        = p_s_general-menge.
    l_qty_unit   = p_s_general-meinh.
  ELSE.
    l_qty        = p_s_results-roundqt.
    l_qty_unit   = p_s_results-rqtunit.
  ENDIF.

*                *** - Menge in ME der Grenzen umrechnen, wenn nötig
  IF p_s_results-mamiqtunit <> l_qty_unit.
    PERFORM conv2unit_new  USING    p_s_general
                                    l_qty             " Menge in alt ME
                                    l_qty_unit        " alte ME
                                    p_s_results-mamiqtunit " neue ME
                           CHANGING p_s_results
                                    l_qty.            " Menge in neuerME
  ENDIF.

*                *** Tests durchführen:
  l_qty_quan = l_qty.
  l_max_quan = p_s_results-maxqt.
  l_min_quan = p_s_results-minqt.

  IF NOT ( l_max_quan IS INITIAL ).
*                *** 1. Maxprüfung (wenn Grenze gegeben)
    IF l_qty_quan > l_max_quan.
      p_s_results-roundqt = p_s_results-maxqt.
      p_s_results-rqtunit = p_s_results-mamiqtunit.
*                *** Rundungsgrund setzen
      PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                    USING  mdr1p_c_maxmenge.
    ENDIF.
  ENDIF.

  IF NOT ( l_min_quan IS INITIAL ).
*                *** 2. Minprüfung (wenn Grenze gegeben)
    IF l_qty_quan < l_min_quan.
      p_s_results-roundqt = p_s_results-minqt.
      p_s_results-rqtunit = p_s_results-mamiqtunit.
*                *** Rundungsgrund setzen
      PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                    USING  mdr1p_c_minmenge.
    ENDIF.
  ENDIF.

ENDFORM.                               " check_min_max

*#@007 HWI 4.70 customizing of logistical rounding B

*&---------------------------------------------------------------------*
*&      Form  CHECK_ALLOWED_QTUNIT
*&---------------------------------------------------------------------*
*       Überprüfe, ob die gerundete Menge auch eine erlaubte
*       ME ist:
*       Ist die ME nicht erlaubt => Umrechnung in die Default-ME
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM check_allowed_qtunit
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_qty_base_old  TYPE  mdr1p_p_16_dec_14,
        l_qty_base_new  TYPE  mdr1p_p_16_dec_14,
        l_diff          TYPE  mdr1p_p_16_dec_14,
        l_qty_unit_new  LIKE  marm-meinh.

*                *** Suche die Rundungs-ME in der Tabelle
*                *** der erlaubten Me
  READ TABLE p_t_qt_units
    WITH KEY meinh = p_s_results-logme
*$@001 Anfang MWE-ENTW-46C
             BINARY SEARCH.
*$@001 Ende MWE-ENTW-46C

  IF sy-subrc                        <>  0
  OR p_t_qt_units-flagallqtunit      =   c_no.


*                ***    Rundungs-Menge in Basis-ME
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    p_s_results-meins
                           CHANGING p_s_results
                                    l_qty_base_old.

*                ***    Bestimme die gültige ME

*                ***    kein Kontrakt => Default-ME ist gültig
    l_qty_unit_new  =  p_s_results-defqtunit.
*                ***    Wandele p_s_results-lmenge in Default-ME um
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    l_qty_unit_new
                           CHANGING p_s_results
                                    p_s_results-lmenge.
    p_s_results-logme = l_qty_unit_new.

*                ***    Menge in Default-ME in Basis-ME ausdrücken
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    p_s_results-meins
                           CHANGING p_s_results
                                    l_qty_base_new.

*                ***    Rundungsgrund immer setzen!!!

    PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                  USING  mdr1p_c_vabme.


*                ***    Passe zusätzlich die Rundungs-Menge in Eingabe-
*                ***    ME an:
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    p_s_general-meinh
                           CHANGING p_s_results
                                    p_s_results-menge.
  ENDIF.

ENDFORM.                               " CHECK_ALLOWED_QTUNIT
*#@007 HWI 4.70 customizing of logistical rounding E

*&---------------------------------------------------------------------*
*&      Form  CHECK_ALLOWED_DEC
*&---------------------------------------------------------------------*
*       Entferne nicht erlaubte Nachkommastellen an dem Rundungsergebnis
*----------------------------------------------------------------------*
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM check_allowed_dec
                   TABLES
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_qty_save TYPE mdr1p_p_16_dec_14.

*                *** Entferne nicht zulässige Nachkommastellen bei
*                *** der Rundungs-Menge in Rundungs-ME
  l_qty_save = p_s_results-lmenge.

  PERFORM remove_no_valid_dec TABLES   p_t_round_reasons
                              USING    p_s_results-logme
                              CHANGING p_s_results-lmenge.

  IF l_qty_save <> p_s_results-lmenge.
*                *** Berechne die Rundungsmenge in Eingabe-ME neu
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    p_s_general-meinh
                           CHANGING p_s_results
                                    p_s_results-menge.
  ENDIF.

*                *** Entferne nicht zulässige Nachkommastellen bei
*                *** der Rundungs-Menge in Eingabe-ME
  l_qty_save = p_s_results-menge.

  PERFORM remove_no_valid_dec TABLES   p_t_round_reasons
                              USING    p_s_general-meinh
                              CHANGING p_s_results-menge.

ENDFORM.                               " CHECK_ALLOWED_DEC

*&---------------------------------------------------------------------*
*&      Form  CHECK_LB_OUTPUT
*&---------------------------------------------------------------------*
*       Nehme die für LB-Aufrufe notwendige Simulierung der Eingabe-
*       Werte wieder zurück
*----------------------------------------------------------------------*
*      -->P_S_GENERAL       allgemeine Eingabestruktur mit manipulierter
*                           LB-Eingabe
*      <--P_S_GENERAL       allgemeine Eingabestruktur ohne
*                           manipulierter LB-Eingabe
*      -->P_S_RESULTS       Rundungsparameter mit Rundungsergebnis
*      <--P_S_RESULTS       Rundungsparameter mit Rundungswergebnis
*                           und LB-Korrektur
*----------------------------------------------------------------------*
FORM check_lb_output
                   CHANGING
                     p_s_general       TYPE mdr1p_s_in_single_round
                     p_s_results       TYPE mdr1p_s_out_single_round.

  IF NOT p_s_results-lbqtunit IS INITIAL.
*                *** Mache Simulation wieder Rückgängig
    p_s_general-menge = p_s_results-lbqt.
    p_s_general-meinh = p_s_results-lbqtunit.  " = ursprüngliche Ein-ME
    p_s_general-umrez = p_s_results-lbumrez.
    p_s_general-umren = p_s_results-lbumren.
*                *** Wandele die Rundungs-Menge in Eingabe-ME wieder
*                *** in die ursprüngliche Eingabe-ME um
    IF p_s_results-logme = p_s_general-meinh.
      p_s_results-menge = p_s_results-lmenge.
    ELSE.
      PERFORM conv2unit_new  USING    p_s_general
                                      p_s_results-lmenge
                                      p_s_results-logme
                                      p_s_general-meinh
                             CHANGING p_s_results
                                      p_s_results-menge.
    ENDIF.
  ENDIF.

ENDFORM.                               " CHECK_LB_OUTPUT

*&---------------------------------------------------------------------*
*&      Form  remove_no_valid_dec
*&---------------------------------------------------------------------*
*       Entferne nicht gültige Nachkommastellen zu einer Menge
*       abhängig von der ME
*----------------------------------------------------------------------*
*     <-->p_t_round_reasons  Rundungsgründe
*      -->P_qty_unit         ME
*      -->p_qty              Menge
*      <--P_qty_unit         Menge reduziert um ungültige
*                            Nachkommastellen
*----------------------------------------------------------------------*
FORM remove_no_valid_dec
                   TABLES
                     p_t_round_reasons  TYPE mdr1p_t_rundungsgrund
                   USING
                     value(p_qty_unit)  LIKE marm-meinh
                   CHANGING
                     value(p_qty)       TYPE mdr1p_p_16_dec_14.

  DATA: l_s_t006        LIKE  t006.

  CLEAR: l_s_t006.


  PERFORM read_t006 USING    p_qty_unit
                    CHANGING l_s_t006.

  PERFORM call_rm_invalid_deci_place  TABLES    p_t_round_reasons
                                      USING     p_qty
                                                p_qty_unit
                                                l_s_t006-andec
                                      CHANGING  p_qty.

ENDFORM.                               " remove_no_valid_dec

*&---------------------------------------------------------------------*
*&      Form  read_data_sales_u12
*&---------------------------------------------------------------------*
*       Bestimme Daten für den Verkauf
*----------------------------------------------------------------------*
*      -->P_S_MARA     Bestimmter MARA-Eintrag
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      <--P_S_RESULTS  Bestimmte Rundungsparameter
*      <--P_S_MVKE
*      <--P_S_KNMT
*      <--P_S_KNVV
*----------------------------------------------------------------------*
FORM read_data_sales_u12
                   USING
                     p_s_mara      TYPE mara
                     p_s_general   TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results   TYPE mdr1p_s_out_single_round
                     p_s_mvke      TYPE mvke
                     p_s_knmt      TYPE knmt
                     p_s_knvv      TYPE knvv.

  CLEAR: p_s_mvke,
         p_s_knmt,
         p_s_knvv.

*                *** Bestimme die Daten aus der MVKE
  PERFORM read_mvke_single  USING    p_s_general-matnr
                                     p_s_general-vkorg
                                     p_s_general-vtweg
                            CHANGING p_s_mvke.

*                *** Bestimme die Daten aus dem VK-Info-Statz KNMT bei:
*                *** - Leiferung muß INFLS = 'X' immer gesetzt sein
*                ***   (es gibt kein solches Kennz. in der DB für die
*                ***    Lieferung!!!)
*                *** - bei Kundenauftrag, wenn er berücksichtigt werden
*                ***   soll => Kennzeichen aus der DB bestimmen
  IF NOT ( p_s_general-infls   IS  INITIAL ).
    PERFORM read_knmt_single USING    p_s_general-kunnr
                                      p_s_general-vkorg
                                      p_s_general-vtweg
                                      p_s_general-spart
                                      p_s_general-matnr
                             CHANGING p_s_knmt.
  ENDIF.

*                *** Wenn Abnehmer-ME-Gruppe nicht aus der KNMT
*                *** bestimmt wird => Bestimme sie aus KNVV
  IF p_s_knmt-megru  IS  INITIAL.
    PERFORM read_knvv_single USING    p_s_general-kunnr
                                      p_s_general-vkorg
                                      p_s_general-vtweg
                                      p_s_general-spart
                             CHANGING p_s_knvv.
  ENDIF.

*                *** Bestimme noch die Liefermengenschrittweite
*                *** unabhängig vom OPCODE
  IF NOT ( p_s_mvke-scmng IS INITIAL ).

    p_s_results-scmng = p_s_mvke-scmng.

    IF NOT ( p_s_mvke-schme IS INITIAL ).
      p_s_results-schme = p_s_mvke-schme.
    ELSE.
      p_s_results-schme = p_s_mara-meins.
    ENDIF.

  ENDIF.

*                *** Belege die Daten abhängig vom OPCODE

  IF p_s_general-opcode  =  mdr1p_c_op_sd_auftrag.
*                *** - Für den Kundenauftrag:
    IF  NOT ( p_s_knmt        IS  INITIAL )
    AND NOT ( p_s_knmt-rdprf  IS  INITIAL ).

      p_s_results-rdprf      = p_s_knmt-rdprf.
      p_s_results-bstrf      = 0.
      p_s_results-maxqt      = 0.
      p_s_results-minqt      = p_s_mvke-aumng.
      p_s_results-mamiqtunit = p_s_results-meins.    " immer in Basis-ME
      p_s_results-mamiumrez  = 1.
      p_s_results-mamiumren  = 1.

    ELSE.

*$@006 mbi 4.70 - Anfang
*$      IF  NOT ( p_s_mvke  IS INITIAL )
*$      AND     (   NOT ( p_s_mvke-rdprf IS INITIAL )
*$               OR NOT ( p_s_mvke-scmng IS INITIAL ) ).

      IF ( NOT ( p_s_mvke IS INITIAL )
           AND (    NOT ( p_s_mvke-rdprf IS INITIAL )
                 OR NOT ( p_s_mvke-scmng IS INITIAL ) ) )

*                *** Falls die Simulation eines Rundungsprofils
*                *** durchgeführt wird (Transaktion WLB8), soll keine
*                *** Ausnahme geworfen werden, sondern die restlichen
*                *** Parameter (z.B. erlaubte ME oder Megru´s) bestimmt
*                *** werden.
         OR p_s_general-simurounding = c_yes.
*$@006 mbi 4.70 - Ende

        p_s_results-rdprf      = p_s_mvke-rdprf.
        p_s_results-bstrf      = 0.
        p_s_results-maxqt      = 0.
        p_s_results-minqt      = p_s_mvke-aumng.
        p_s_results-mamiqtunit = p_s_results-meins.    " immer Basis-ME
        p_s_results-mamiumrez  = 1.
        p_s_results-mamiumren  = 1.

      ELSE.
*#@007 HWI 4.70 customizing of logistical rounding B
        IF p_s_general-rleave = c_yes.
          MESSAGE e093   RAISING no_round.
        ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding E

      ENDIF.

    ENDIF.

  ENDIF.

  IF p_s_general-opcode  =  mdr1p_c_op_sd_lieferung.
*                *** - Für die Lieferung:
    IF  NOT ( p_s_knmt        IS  INITIAL ).

      p_s_results-rdprf      = p_s_knmt-rdprf.
      p_s_results-bstrf      = 0.
      p_s_results-maxqt      = 0.
      p_s_results-minqt      = p_s_knmt-minlf.
      p_s_results-mamiqtunit = p_s_results-meins.    " immer in Basis-ME
      p_s_results-mamiumrez  = 1.
      p_s_results-mamiumren  = 1.

    ELSE.
      IF NOT ( p_s_mvke  IS INITIAL ).

        p_s_results-rdprf      = p_s_mvke-rdprf.
        p_s_results-bstrf      = 0.
        p_s_results-maxqt      = p_s_mvke-lfmax.
        p_s_results-minqt      = p_s_mvke-lfmng.
        p_s_results-mamiqtunit = p_s_results-meins.    " immer Basis-ME
        p_s_results-mamiumrez  = 1.
        p_s_results-mamiumren  = 1.

      ENDIF.

    ENDIF.

  ENDIF.

ENDFORM.                               " read_data_sales_u12

*&---------------------------------------------------------------------*
*&      Form  rounding_sales
*&---------------------------------------------------------------------*
*       Auswahl und Durchführung der Rundungsverfahren für die
*       'normalen' VK-OPCODES
*       Hinweis: Die Rundung wird nur Durchgeführt wenn die entsp.
*                Rundungsparameter durch die folgende Logik belegt
*                wurden:
*                1. durch Vorgabewerte der Aufrufstelle (NEU!!!)
*                   oder
*                2. durch den EK-Info-Satz (EINA/EINE)
*                   oder
*                3. durch den MARC-Satz
*
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM rounding_sales
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  IF        p_s_results-rdprf IS INITIAL
  AND NOT ( p_s_results-scmng IS INITIAL )
*#@007 HWI 4.70 customizing of logistical rounding B
  AND       p_s_general-rvalu = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

*                *** Rundungswertverfahren für VK
*                *** (Bei Lieferung auch nur noch, wenn kein Profil
*                *** existiert NEU !!!)
    PERFORM call_rounding_value  TABLES   p_t_round_reasons
                                 USING    p_s_general
                                 CHANGING p_s_results.
*                *** Rundungs-ME = p_s_results-schme
*                *** => Umrechnung in diese ME, wenn sie nicht der
*                ***    Rundungs-ME (Basis-ME) entspricht.
    IF p_s_results-rqtunit <> p_s_results-schme.
      PERFORM conv2unit_new  USING    p_s_general
                                      p_s_results-roundqt
                                      p_s_results-rqtunit
                                      p_s_results-schme
                             CHANGING p_s_results
                                      p_s_results-roundqt.
      p_s_results-rqtunit = p_s_results-schme.
    ENDIF.
*                *** Setze zusätzlich noch ein Rundungsgrund, wenn
*                *** sich die Rundungs-ME von der Eingabe-ME unter-
*                *** scheidet
    IF p_s_results-rqtunit <> p_s_general-meinh.
      PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                    USING  mdr1p_c_liefereinheit.
    ENDIF.
  ENDIF.

  IF NOT ( p_s_results-rdprf IS INITIAL ).
*                *** Rundungsprofilmethoden
    PERFORM rounding_profil  TABLES   p_t_qt_units
                                      p_t_round_reasons
                             USING    p_s_general
                             CHANGING p_s_results.

  ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding B
* Customizing rules
* IF  NOT ( p_s_general-no_min_max_check = c_yes )
  IF (   NOT ( p_s_results-maxqt IS INITIAL )
      OR NOT ( p_s_results-minqt IS INITIAL ) )
  AND       p_s_general-rmami = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

*                *** Max und Min-Grenzen bei den gerundeten ME prüfen
    PERFORM check_min_max TABLES   p_t_round_reasons
                          USING    p_s_general
                          CHANGING p_s_results.
  ENDIF.

ENDFORM.                               " rounding_sales

*&---------------------------------------------------------------------*
*&      Form  rounding_sales_special
*&---------------------------------------------------------------------*
*       Auswahl und Durchführung der Rundungsverfahren für die
*       das spezielle VK-Rundungsverfahren
*       => OPCODE = mdr1p_c_op_sd_verf
*       Hinweis: Alle benötigten Rundungsparameter werden von der
*                Aufrufstelle belegt!!!
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM rounding_sales_special
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_t_rdpr     LIKE  rdpr
                     OCCURS 0 WITH HEADER LINE,
        l_help_quan  LIKE  ekpo-menge.

*                *** 1. Versuch mit Rundungsprofilmethode
  IF NOT ( p_s_results-rdprf IS INITIAL ).
*                ***    Runde hier nur bei den folgenden Methoden

*                ***     Bestimme zuerst die Rundungsprofil Definition,
*                ***     wenn sie noch nicht durch die Aufrufstelle vor-
*                ***     gegeben wurde.
    IF  p_s_results-rdprf  =  p_s_results-rdpr-rdprf
    AND p_s_general-werks  =  p_s_results-rdpr-werks.
*                ***     - Bestimme die komplette Definition mit Hilfe
*                ***       des entsprechenden Lesebausteins.
      PERFORM read_rdpr_all  TABLES   l_t_rdpr
                             USING    p_s_results-rdprf
                                      p_s_general-werks
                             CHANGING p_s_results-rdpr.
    ENDIF.

*                ***     - Auswahl der Rundungsverfahren abhängig von
*                ***       der Methode
    CASE p_s_results-rdpr-rdmpo.

      WHEN c_rdmpo_abs.                "absolut runden
        PERFORM call_check_rounding_profile TABLES   l_t_rdpr
                                                     p_t_round_reasons
                                            USING    p_s_general
                                            CHANGING p_s_results.

      WHEN c_rdmpo_no.                 "nicht runden
*                *** die gerundete Menge entspricht der Eingabe-Menge
*                *** (Max- und Min-Tests können noch durchgeführt werd.)
        p_s_results-roundqt = p_s_general-menge.
        p_s_results-rqtunit = p_s_general-meinh.

      WHEN c_rdmpo_bstme.              "runde auf die Default-ME
      WHEN c_rdmpo_opt.                "runde auf logist. ME
      WHEN c_rdmpo_opt_no_null.        "runde auf log. ME ohne Null
      WHEN c_rdmpo_up_down.            "runde mit Auf- und Abschlag
*                *** Runde auf den größten ganzzahligen Wert der nicht
*                *** größer ist als der Eingabewert:
*                *** Bsp.:   5,7  =>   5 gerundet
*                ***        -5,7  => - 6 gerundet
*                ***                     (kann aber nicht auftreten)
        l_help_quan         = p_s_general-menge.
        p_s_results-roundqt = floor( l_help_quan ).
        p_s_results-rqtunit = p_s_general-meinh.

        IF p_s_results-roundqt <> p_s_general-menge.
          PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                        USING  mdr1p_c_sd_special.
        ENDIF.

      WHEN OTHERS.
*                *** nicht bekannt Rundungsmethode wird als
*                *** individuelle Rundungsmethode interpretiert
*                *** => Aufruf eines User-Exits zum kundenindividuellen
*                ***    Runden
        PERFORM call_user_exit_003 TABLES   p_t_qt_units
                                            p_t_round_reasons
                                   USING    p_s_general
                                   CHANGING p_s_results.

    ENDCASE.

  ELSEIF NOT ( p_s_results-scmng IS INITIAL ).
*                *** Runde mit Liefermengenschrittweite
    PERFORM call_rounding_value  TABLES   p_t_round_reasons
                                 USING    p_s_general
                                 CHANGING p_s_results.
*                *** Rundungs-ME: ist p_s_results-schme
*                *** => Umrechnung in diese ME, wenn sie nicht der
*                ***    Basis-ME entspricht.
    IF p_s_results-rqtunit <> p_s_results-schme.
      PERFORM conv2unit_new  USING    p_s_general
                                      p_s_results-roundqt
                                      p_s_results-rqtunit
                                      p_s_results-schme
                             CHANGING p_s_results
                                      p_s_results-roundqt.
      p_s_results-rqtunit = p_s_results-schme.
    ENDIF.
*                *** Setze zusätzlich noch ein Rundungsgrund, wenn
*                *** sich die Rundungs-ME von der Eingabe-ME unter-
*                *** scheidet
    IF p_s_results-rqtunit <> p_s_general-meinh.
      PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                    USING  mdr1p_c_liefereinheit.
    ENDIF.
  ELSE.
*                *** => Kein Profil und Keine Schrittweite
*                *** => FEHLER
    MESSAGE e093    RAISING no_round.
  ENDIF.

ENDFORM.                               " rounding_sales_special

*&---------------------------------------------------------------------*
*&      Form  read_data_addit_u12
*&---------------------------------------------------------------------*
*       Bestimme die Daten bei Additionals
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      <--P_S_RESULTS  Bestimmte Rundungsparameter
*      <--P_S_MARC
*----------------------------------------------------------------------*
FORM read_data_addit_u12
                   USING
                     p_s_general   TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results   TYPE mdr1p_s_out_single_round
                     p_s_marc      TYPE marc.

  CLEAR: p_s_marc.


*                *** Der MARC-Satz zum Abnehmer-Werk wird für
*                *** die Bestimmung der Rundungsparameter gelesen
  PERFORM read_marc_single  USING    p_s_general-matnr
                                     p_s_general-werks
                            CHANGING p_s_marc.
  IF p_s_marc IS INITIAL.
    MESSAGE e067 WITH    p_s_general-werks
                         p_s_general-matnr
                 RAISING rdprf_not_found.
  ENDIF.

  IF p_s_marc-rdprf IS INITIAL.
    MESSAGE e070 WITH    p_s_general-werks
                         p_s_general-matnr
                 RAISING rdprf_not_found.
  ENDIF.

*                *** Gelesene Wert aus MARC als Rundungsparameter nutzen
  p_s_results-rdprf      = p_s_marc-rdprf.
  p_s_results-bstrf      = 0.
  p_s_results-maxqt      = p_s_marc-bstma. " Immer Basis-ME: MARA-MEINS
  p_s_results-minqt      = p_s_marc-bstmi. " Immer Basis-ME: MARA-MEINS
  p_s_results-mamiqtunit = p_s_results-meins.
  p_s_results-mamiumrez  = 1.
  p_s_results-mamiumren  = 1.

ENDFORM.                               " read_data_addit_u12

*&---------------------------------------------------------------------*
*&      Form  rounding_additionals
*&---------------------------------------------------------------------*
*       Auswahl und Durchführung der Rundungsverfahren für Additionals
*       Rundungsparameter nur aus MARC.
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM rounding_additionals
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  IF NOT ( p_s_results-rdprf IS INITIAL ).
*                *** Rundungsprofilmethoden (Rundungsprofil ist immer
*                *** hier gefüllt!!!)
    PERFORM rounding_profil  TABLES   p_t_qt_units
                                      p_t_round_reasons
                             USING    p_s_general
                             CHANGING p_s_results.

  ENDIF.
*#@007 HWI 4.70 customizing of logistical rounding B
*  IF  NOT ( p_s_general-no_min_max_check = c_yes )
* Customizing rules
  IF (    NOT ( p_s_results-maxqt IS INITIAL )
       OR NOT ( p_s_results-minqt IS INITIAL ) )
  AND p_s_general-rmami = c_yes.
*#@007 HWI 4.70 customizing of logistical rounding E

*                *** Max und Min-Grenzen bei den gerundeten ME prüfen
    PERFORM check_min_max TABLES   p_t_round_reasons
                          USING    p_s_general
                          CHANGING p_s_results.
  ENDIF.

ENDFORM.                               " rounding_additionals

*&---------------------------------------------------------------------*
*&      Form  DETER_I_QTY_IN_UNIT_NEW
*&---------------------------------------------------------------------*
*       Bestimme die Eingabe-Menge in einer anderen Mengeneinheit
*----------------------------------------------------------------------*
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      -->P_UNIT_NEW        Ziel ME
*      <--P_S_RESULTS       Rundungsparameter mit Eingabe-Menge in
*                           Basis-ME (wenn bestimmt wurde)
*      <--P_QTY_NEW         Eingabe-Menge in der Ziel-ME P_UNIT
*----------------------------------------------------------------------*
FORM determine_i_qty_in_unit_new
                   USING
                     p_s_general       TYPE   mdr1p_s_in_single_round
                     value(p_unit_new) LIKE   marm-meinh
                   CHANGING
                     p_s_results       TYPE   mdr1p_s_out_single_round
                     value(p_qty_new)  TYPE   mdr1p_p_16_dec_14.

  CLEAR: p_qty_new.

  IF      p_unit_new   =   p_s_general-meinh.
*                *** 1. Ziel-ME (= P_UNIT)  = Eingabe-ME
*                ***    => Menge = Eingabe-Menge
    p_qty_new = p_s_general-menge.

  ELSEIF  p_unit_new   =   p_s_results-lbqtunit.
*                *** 2. Ziel-ME (= P_UNIT)  = orginal Eingabe-ME (LB)
*                ***    => Menge = orginal LB-Eingabe-Menge
    p_qty_new = p_s_results-lbqt.

  ELSEIF  p_unit_new   =   p_s_results-meins
      AND NOT ( p_s_results-inqtmeins IS INITIAL ).
*                *** 3. Ziel-ME (= P_UNIT)  = Basis-ME
*                ***    und Eingabe-Menge in Basis-ME schon bestimmt
*                ***    => Menge = Eingabe-Menge in Basis-ME

    p_qty_new = p_s_results-inqtmeins.
  ELSE.
*                *** 4. sonst
*                ***    => Konvertiere die Eingabe-Menge in die
*                ***       entsprechende neue ME um
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_general-menge " Eingabe-Menge
                                    p_s_general-meinh " Eingabe-ME
                                    p_unit_new        " neue ME
                           CHANGING p_s_results
                                    p_qty_new.        " Menge in neuerME
  ENDIF.

*                *** Wenn die neue ME die Basis-ME ist, dann lege
*                *** in der Ergebnisstruktur ab!!
  IF  p_unit_new             =   p_s_results-meins
  AND p_s_results-inqtmeins  IS  INITIAL.
    p_s_results-inqtmeins = p_qty_new.
  ENDIF.

ENDFORM.                               " DETER_I_QTY_IN_UNIT_NEW

*&---------------------------------------------------------------------*
*&      Form  conv2unit_new
*&---------------------------------------------------------------------*
*       Umrechnung einer Menge von der Quell-ME in eine Ziel-ME mit
*       der Umrechnungsfaktoren aus MARM und T006!
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      -->P_QTY_OLD    Menge in der alten ME
*      -->P_UNIT_OLD   alte ME
*      -->P_UNIT_NEW   neue ME
*      -->P_S_RESULTS  Rundungsparameter
*      <--P_S_RESULTS  Rundungsparameter mit eventuell der Eingabe-ME
*                      umgerechnet in Basis-ME
*      <--P_QTY_NEW    Menge in der neuen ME
*----------------------------------------------------------------------*
FORM conv2unit_new
                   USING
                     p_s_general       TYPE   mdr1p_s_in_single_round
                     value(p_qty_old)  TYPE   mdr1p_p_16_dec_14
                     value(p_unit_old) LIKE   marm-meinh
                     value(p_unit_new) LIKE   marm-meinh
                   CHANGING
                     p_s_results       TYPE   mdr1p_s_out_single_round
                     value(p_qty_new)  TYPE   mdr1p_p_16_dec_14.

  DATA: l_umrez TYPE mdr1p_p_16_dec_14,
        l_umren TYPE mdr1p_p_16_dec_14,
*$@005 Anfang HW-430276-MWE
        l_umrezf TYPE f,
        l_umrenf TYPE f,
*$@005 Ende HW-430276-MWE
        l_addko LIKE t006-addko.

  CLEAR: p_qty_new,
         l_umrez,
         l_umren,
*$@005 Anfang HW-430276-MWE
         l_umrezf,
         l_umrenf,
*$@005 Ende HW-430276-MWE
         l_addko.

*                *** 0. Default-Belegung für den Fall:
*                ***    p_unit_old = p_s_results-meins = p_unit_new
  p_qty_new = p_qty_old.

* begin of note 335820
* Falls die neue Mengeneinheit schon identisch mit der alten ME ist,
* muss nichts mehr umgerechnet werden - also Form verlassen.
  CHECK p_unit_old <> p_unit_new.
* end of note 335820

*                *** 1. Umrechne der alten Menge in die Basis-ME,
*                ***    wenn Basis-ME <> alte ME
  IF p_unit_old <> p_s_results-meins.
*                ***    - Bestimme die Umrechnungsfaktoren für die
*                ***      alte ME
    PERFORM get_unit_factors USING    p_s_general
                                      p_s_results
                                      p_unit_old
                             CHANGING l_umrez
                                      l_umren
*$@005 Anfang HW-430276-MWE
                                      l_umrezf
                                      l_umrenf
*$@005 Ende HW-430276-MWE
                                      l_addko.

    PERFORM conv2unit_rule_1 USING     p_qty_old
                                       l_addko
                                       l_umrez
                                       l_umren
*$@005 Anfang HW-430276-MWE
                                       l_umrezf
                                       l_umrenf
*$@005 Ende HW-430276-MWE
                             CHANGING  p_qty_new.

  ENDIF.

*                *** 2. Umrechnen der Menge in Basis-ME in die neue ME,
*                ***    wenn diese nicht die Basis-ME ist
  IF p_unit_new <> p_s_results-meins.

    CLEAR: l_umrez,
           l_umren,
*$@005 Anfang HW-430276-MWE
           l_umrezf,
           l_umrenf,
*$@005 Ende HW-430276-MWE
           l_addko.
*                ***    - Bestimme die Umrechnungsfaktoren für die
*                ***      alte ME
    PERFORM get_unit_factors USING    p_s_general
                                      p_s_results
                                      p_unit_new
                             CHANGING l_umrez
                                      l_umren
*$@005 Anfang HW-430276-MWE
                                      l_umrezf
                                      l_umrenf
*$@005 Ende HW-430276-MWE
                                      l_addko.

    PERFORM conv2unit_rule_2 USING     p_qty_new
                                       l_addko
                                       l_umrez
                                       l_umren
*$@005 Anfang HW-430276-MWE
                                       l_umrezf
                                       l_umrenf
*$@005 Ende HW-430276-MWE
                             CHANGING  p_qty_new.

  ENDIF.

ENDFORM.                               " conv2unit_new

*&---------------------------------------------------------------------*
*&      Form  get_unit_factors
*&---------------------------------------------------------------------*
*       Bestimme die Umrechnungsfaktoren von der gegebenen ME in die
*       Basis-ME für ein Material
*----------------------------------------------------------------------*
*      -->P_S_GENERAL allgemeine Eingabeparameter
*      -->P_S_RESULTS Rundungsparameter
*      -->P_UNIT      Mengeneinheit
*      <--P_UMREZ     Umrechnungszähler
*      <--P_UMREN     Umrechnungsnenner
*$@005 Anfang HW-430276-MWE
*      <--p_umrezf
*      <--p_umrenf
*$@005 Ende HW-430276-MWE
*      <--P_ADDKO     additive Konstante
*----------------------------------------------------------------------*
FORM get_unit_factors
                   USING
                     p_s_general       TYPE   mdr1p_s_in_single_round
                     p_s_results       TYPE   mdr1p_s_out_single_round
                     value(p_unit)     LIKE   marm-meinh
                   CHANGING
                     value(p_umrez)    TYPE   mdr1p_p_16_dec_14
                     value(p_umren)    TYPE   mdr1p_p_16_dec_14
*$@005 Anfang HW-430276-MWE
                     p_umrezf          TYPE   f
                     p_umrenf          TYPE   f
*$@005 Ende HW-430276-MWE
                     value(p_addko)    LIKE   t006-addko.

*                *** 1. Allgemeine Bestimmung der Umrechnungsfaktoren
  PERFORM get_units_factors_general USING    p_s_general-matnr
                                             p_unit
*$@004 Anfang MWE-HW-300836
                                             p_s_results-meins
*$@004 Ende MWE-HW-300836
                                    CHANGING p_umrez
                                             p_umren
*$@005 Anfang HW-430276-MWE
                                             p_umrezf
                                             p_umrenf
*$@005 Ende HW-430276-MWE
                                             p_addko.

*                *** 2. Teste ob die bestimmten Werte nicht durch
*                ***    die Aufrufstelle schon vorgegeben
*                ***    bzw. aus EK-Info bestimmt wurden
*                ***    (Reicht aber für die additive Konstante nicht
*                ****   aus, daher erst am Ende durchführen!!!)
  PERFORM ckeck_set_factors USING    p_s_general
                                     p_s_results
                                     p_unit
                            CHANGING p_umrez
                                     p_umren.

*                *** 3. Abschlußbehandlung
*$@005 Anfang HW-430276-MWE
*$  IF p_umren IS INITIAL
*$  OR p_umrez IS INITIAL.
  IF (    p_umren  IS INITIAL
      AND p_umrenf IS INITIAL )
  OR (    p_umrez  IS INITIAL
      AND p_umrezf IS INITIAL ) .
*$@005 Ende HW-430276-MWE
*                *** Devision durch 0 geht bicht und 0 als Zähler macht
*                *** keinen Sinn =>
    p_umren = 1.
    p_umrez = 1.

  ENDIF.

ENDFORM.                               " get_unit_factors

*&---------------------------------------------------------------------*
*&      Form  ckeck_set_factors
*&---------------------------------------------------------------------*
*       Prüfe ob nicht die Umrechnungsfaktoren zu einer ME
*       durch die Aufrufstelle vorgegeben wurden.
*----------------------------------------------------------------------*
*      -->P_S_GENERAL allgemeine Eingabeparameter
*      -->P_S_RESULTS Rundungsparameter
*      -->P_UNIT      Mengeneinheit
*      -->P_UMREZ     Umrechnungszähler (Default)
*      -->P_UMREN     Umrechnungsnenner (Default)
*      <--P_UMREZ     Umrechnungszähler
*      <--P_UMREN     Umrechnungsnenner
*----------------------------------------------------------------------*
FORM ckeck_set_factors
                   USING
                     p_s_general       TYPE   mdr1p_s_in_single_round
                     p_s_results       TYPE   mdr1p_s_out_single_round
                     value(p_unit)     LIKE   marm-meinh
                   CHANGING
                     value(p_umrez)    TYPE   mdr1p_p_16_dec_14
                     value(p_umren)    TYPE   mdr1p_p_16_dec_14.

*                ***    - Eingabe-ME mit Umrechnungsfaktoren
  IF        p_unit = p_s_general-meinh
  AND NOT ( p_s_general-umrez IS INITIAL )
  AND NOT ( p_s_general-umren IS INITIAL ).
*                ***      => Hole immer die vorgegebenen UMrechnnugsfak.
    p_umrez = p_s_general-umrez.
    p_umren = p_s_general-umren.
  ENDIF.

*                ***    - org. Eingabe-ME mit Umrechnungsfaktoren bei LB
  IF        p_unit = p_s_results-lbqtunit
  AND NOT ( p_s_results-lbumrez IS INITIAL )
  AND NOT ( p_s_results-lbumren IS INITIAL ).
*                ***      => Hole immer die vorgegebenen UMrechnnugsfak.
    p_umrez = p_s_results-lbumrez.
    p_umren = p_s_results-lbumren.
  ENDIF.

*                ***    - Default-ME mit Umrechnungsfaktoren
  IF        p_unit = p_s_results-defqtunit
  AND NOT ( p_s_results-defumrez IS INITIAL )
  AND NOT ( p_s_results-defumren IS INITIAL ).
*                ***      => Hole immer die vorgegebenen UMrechnnugsfak.
    p_umrez = p_s_results-defumrez.
    p_umren = p_s_results-defumren.

  ENDIF.

*                ***    - MaxMin-ME  mit Umrechnungsfaktoren
  IF        p_unit = p_s_results-mamiqtunit
  AND NOT ( p_s_results-mamiumrez IS INITIAL )
  AND NOT ( p_s_results-mamiumren IS INITIAL ).
*                ***      => Hole immer die vorgegebenen UMrechnnugsfak.
    p_umrez = p_s_results-mamiumrez.
    p_umren = p_s_results-mamiumren.
  ENDIF.

*                ***    - Kontrakt-ME  mit Umrechnungsfaktoren
  IF        p_unit = p_s_general-kmeinh
  AND NOT ( p_s_general-kumrez IS INITIAL )
  AND NOT ( p_s_general-kumren IS INITIAL ).
*                ***      => Hole immer die vorgegebenen UMrechnnugsfak.
    p_umrez = p_s_general-kumrez.
    p_umren = p_s_general-kumren.
  ENDIF.
*$@008 Anfang HW-504954-MAM

*               ***    - Chargen-Behandlung
  IF NOT ( p_s_general-charg   IS INITIAL ).
*               ***      Prüfe, ob für die ME bei der Charge abweichende
*               ***      Umrechnungsfaktoren existieren.
    PERFORM chargen_check USING
                            p_s_general
                            p_s_results
                            p_unit
                          CHANGING
                            p_umrez
                            p_umren.
  ENDIF.

*                ***    - Spezielle SD-Umrechnungsfaktoren bei Verweis
*                ***      auf banf, mit Ursprung Kundenauftrag
  IF        p_unit = p_s_general-sdmeinh
  AND NOT ( p_s_general-sdumrez IS INITIAL )
  AND NOT ( p_s_general-sdumren IS INITIAL ).
*                ***      => Hole immer die vorgegebenen UMrechnnugsfak.
    p_umrez = p_s_general-sdumrez.
    p_umren = p_s_general-sdumren.
  ENDIF.

ENDFORM.                               " ckeck_set_factors

*&---------------------------------------------------------------------*
*&      Form  chargen_check
*&---------------------------------------------------------------------*
*       Prüfe, ob für die Charge abweichende Umrechnungsfaktoren  zu
*       der Menegeneinheit gepflegt sind
*----------------------------------------------------------------------*
*      -->P_S_GENERAL allgemeine Eingabeparameter
*      -->P_S_RESULTS Rundungsparameter
*      -->P_UNIT      Mengeneinheit
*      -->P_UMREZ     Umrechnungszähler (Default)
*      -->P_UMREN     Umrechnungsnenner (Default)
*      <--P_UMREZ     Umrechnungszähler
*      <--P_UMREN     Umrechnungsnenner
*----------------------------------------------------------------------*
FORM chargen_check
  USING
    p_s_general       TYPE   mdr1p_s_in_single_round
    p_s_results       TYPE   mdr1p_s_out_single_round
    value(p_unit)     LIKE   marm-meinh
  CHANGING
    value(p_umrez)    TYPE   mdr1p_p_16_dec_14
    value(p_umren)    TYPE   mdr1p_p_16_dec_14.

  TYPES:
        BEGIN OF t_meinh_konv,
           matnr LIKE   mara-matnr,
           meinh LIKE   mara-meins,
           kzwso LIKE   marm-kzwso,
           umrez TYPE   mdr1p_p_16_dec_14,
           umren TYPE   mdr1p_p_16_dec_14,
        END OF t_meinh_konv.

  STATICS:
    s_last_matnr    LIKE   mara-matnr,
    s_t_meinh_konv  TYPE   t_meinh_konv
                    OCCURS 0
                    WITH HEADER LINE.

  DATA: l_input  TYPE   float,
        l_tabix  LIKE   sy-tabix.

  IF s_last_matnr <> p_s_general-matnr.
*                *** Puffer ist nur für ein Artikel gültig
    s_last_matnr     =  p_s_general-matnr.
    CLEAR: s_t_meinh_konv,
           s_t_meinh_konv[].

  ENDIF.

  READ TABLE  s_t_meinh_konv
    WITH KEY  matnr  =  p_s_general-matnr
              meinh  =  p_unit
              BINARY SEARCH.

  IF sy-subrc <> 0.

    l_tabix = sy-tabix.
*                *** Informationen wurden noch nicht bestimmt
*                *** => Bestimmung durchführen
    CLEAR: sy-subrc,
           s_t_meinh_konv.

    CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
      EXPORTING
        input         = l_input
        matnr         = s_last_matnr
        meinh         = p_unit
        meins         = p_s_results-meins      "Basis-ME
        charge        = p_s_general-charg
        werks         = p_s_general-werks
      IMPORTING
        output        = l_input
        umren         = s_t_meinh_konv-umren
        umrez         = s_t_meinh_konv-umrez
        kzwso         = s_t_meinh_konv-kzwso
      EXCEPTIONS
        error_message = 98
        OTHERS        = 99.

    IF sy-subrc = 0.

      s_t_meinh_konv-matnr = s_last_matnr.
      s_t_meinh_konv-meinh = p_unit.
*                *** Sortiertes Einfügen!
      INSERT  s_t_meinh_konv
       INDEX  l_tabix.

    ELSE.

      CLEAR: sy-subrc,
             s_t_meinh_konv-umrez,
             s_t_meinh_konv-umren,
             s_t_meinh_konv-kzwso.
*                *** Auch Einträge für Fehlerfälle vornehmen
*                *** Sortiertes Einfügen!
      INSERT  s_t_meinh_konv
       INDEX  l_tabix.

    ENDIF.

  ENDIF.

  IF  NOT ( s_t_meinh_konv-kzwso IS INITIAL )
  AND NOT ( s_t_meinh_konv-umren IS INITIAL )
  AND NOT ( s_t_meinh_konv-umrez IS INITIAL ).
    p_umrez = s_t_meinh_konv-umrez.
    p_umren = s_t_meinh_konv-umren.
  ENDIF.

ENDFORM.                               " chargen_check

*$@008 Ende HW-504954-MAM

*&---------------------------------------------------------------------*
*&      Form  get_units_factors
*&---------------------------------------------------------------------*
*       Bestimme die gültige ME zu einem MAterial für die dyn. Rundung
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  Allgemeine Eingabe-Parameter
*      -->P_S_RESULTS  Rundungsparameter
*      <--P_T_QT_UNITS Tabelle der gültigen ME mit den Umrechnungsfak.
*----------------------------------------------------------------------*
FORM get_units_factors
                 TABLES
                   p_t_qt_units  TYPE  mdr1p_t_out_allowed_qt_unit
                 USING
                   p_s_general   TYPE   mdr1p_s_in_single_round
                   p_s_results   TYPE   mdr1p_s_out_single_round.

  DATA: l_save_umrez TYPE mdr1p_p_16_dec_14,
        l_save_umren TYPE mdr1p_p_16_dec_14.

  CLEAR: l_save_umrez,
         l_save_umren.

*                *** 1. Bestimme alle gültigen ME des Materials mit
*                ***    den ME
  PERFORM find_valid_material_units TABLES  p_t_qt_units
*$@004 Anfang MWE-HW-300836
*$                                    USING   p_s_general-matnr.
                                    USING   p_s_general-matnr
                                            p_s_results-meins.
*$@004 Ende MWE-HW-300836

*                *** 2. Teste ob die bestimmten Werte nicht durch
*                ***    die Aufrufstelle schon vorgegeben
*                ***    bzw. aus EK-Info bestimmt wurden
*                ***    (Reicht aber für die additive Konstante nicht
*                ****   aus, daher erst am Ende durchführen!!!)
  LOOP AT p_t_qt_units.

    l_save_umrez = p_t_qt_units-umrez.
    l_save_umren = p_t_qt_units-umren.

    PERFORM ckeck_set_factors USING    p_s_general
                                       p_s_results
                                       p_t_qt_units-meinh
                              CHANGING p_t_qt_units-umrez
                                       p_t_qt_units-umren.

    IF l_save_umrez  <>  p_t_qt_units-umrez
    OR l_save_umren  <>  p_t_qt_units-umren.
      MODIFY p_t_qt_units.
    ENDIF.

  ENDLOOP.

*                *** Wenn die Default-ME nicht in der MARM enthalten,
*                *** dann muß diese noch aufgenommen werden (NEU!!!)
  READ TABLE p_t_qt_units
    WITH KEY meinh = p_s_results-defqtunit.

  IF sy-subrc <> 0 .
    CLEAR: p_t_qt_units.
    p_t_qt_units-matnr = p_s_general-matnr.
    p_t_qt_units-meinh = p_s_results-defqtunit.
    p_t_qt_units-umrez = p_s_results-defumrez.
    p_t_qt_units-umren = p_s_results-defumren.
    APPEND p_t_qt_units.
  ENDIF.

ENDFORM.                               " get_units_factors

*#@007 HWI 4.70 customizing of logistical rounding B

*&---------------------------------------------------------------------*
*&      Form  check_allowed_qtunit_Konnr
*&---------------------------------------------------------------------*
*       Umrechnung der logistischen ME in die KontraktME
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM check_allowed_qtunit_konnr
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

  DATA: l_qty_base_old  TYPE  mdr1p_p_16_dec_14,
        l_qty_base_new  TYPE  mdr1p_p_16_dec_14,
        l_diff          TYPE  mdr1p_p_16_dec_14,
        l_qty_unit_new  LIKE  marm-meinh.



  IF p_s_general-kmeinh  <>  p_s_results-logme .
*                *** ME <> Kontrakt-ME!!!

*                ***    Rundungs-Menge in Basis-ME
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    p_s_results-meins
                           CHANGING p_s_results
                                    l_qty_base_old.

*                ***    => Kontrakt-ME ist gültig
    l_qty_unit_new  =  p_s_general-kmeinh.


*                ***    Wandele p_s_results-lmenge in Default-ME um
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    l_qty_unit_new
                           CHANGING p_s_results
                                    p_s_results-lmenge.
    p_s_results-logme = l_qty_unit_new.

*                ***    Menge in Default-ME in Basis-ME ausdrücken
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    p_s_results-meins
                           CHANGING p_s_results
                                    l_qty_base_new.

*                ***    Für Kontrakte Rundungsgrund immer setzen!!!

    PERFORM enter_rounding_reason TABLES p_t_round_reasons
                                  USING  mdr1p_c_contract.

*                ***    Passe zusätzlich die Rundungs-Menge in Eingabe-
*                ***    ME an:
    PERFORM conv2unit_new  USING    p_s_general
                                    p_s_results-lmenge
                                    p_s_results-logme
                                    p_s_general-meinh
                           CHANGING p_s_results
                                    p_s_results-menge.
  ENDIF.



ENDFORM.                    " check_allowed_qtunit_Konnr

*#@007 HWI 4.70 customizing of logistical rounding E

*
* 
