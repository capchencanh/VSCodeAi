*----------------------------------------------------------------------*
*   INCLUDE LMDR1FGE                                                   *
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.01.99  99A  mwe         Grundversion
*- @001  15.11.99  46C  mwe         Änderungen zu Rel. 4.6C
*-                                  - Performnaceverbesserung bei READ
*-                                    TABLE mit BINARY SEARCH
*- @002  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @003  04.05.00  46C  mwe         Basis-ME bei Material (Standard)
*-                                  nicht in der MARM eingetragen
*-                                  Korrektur zu Hinweis: 300836
*- @004  27.06.01  470  mwe         Programmabruch wegen zu großen
*-                                  Umrechnungsfaktoren
*-                                  Korrektur zu Hinweis: 430276
*- @005  27.09.01  470  mbi         Schlechte Performance bei der
*-                                  Pufferung der Daten
*-                                  Korrektur zu Hinweis: 438417
*- @006  30.10.01  470  hwi         Realisierung SMAD-Punkte
*-                                  - Neues Customizing
*-                                  (Marke: HWI 4.70 customizing of
*-                                          logistical rounding)
*- @007  01.01.02 470   mwe         Coding aus LMDR1F06 übernommen
*- @008  25.04.06 700   mbi         Performance: replace sorted table by
*-                                  hash table (note 943418)
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  FIND_VALID_MATERIAL_UNITS
*&---------------------------------------------------------------------*
*       Bestimme alle zu einem Material gültigen ME aus der MARM und
*       T006, sowie deren Umrechnungsfaktoren
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_MATNR        Material
*$@003 Anfang MWE-HW-300836
*      -->P_MEINS        Basis-ME des Materials
*$@003 Ende MWE-HW-300836
*      <--P_T_qt_units   gültige ME mit den Umrechnungsfaktoren
*----------------------------------------------------------------------*
FORM find_valid_material_units
                   TABLES
                     p_t_qt_units   TYPE   mdr1p_t_out_allowed_qt_unit
                   USING
*$@003 Anfang MWE-HW-300836
*$                     p_matnr        LIKE   mara-matnr.
                     p_matnr        LIKE   mara-matnr
                     p_meins        LIKE   mara-meins.
*$@003 Ende MWE-HW-300836

*$@005 Anfang HW-438417-mbi
*                  *** Zeilentyp der Hashtabelle
  TYPES: BEGIN OF qt_unit_hash_line_type,

           matnr LIKE mara-matnr,
           itab  TYPE mdr1p_t_out_allowed_qt_unit,

         END OF qt_unit_hash_line_type.
*$@005 Ende HW-438417-mbi

  STATICS: s_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                             WITH HEADER LINE,
*$@005 Anfang HW-438417-mbi
*$           s_t_qt_units_all  TYPE  mdr1p_t_out_allowed_qt_unit
*$                             WITH HEADER LINE.
*                *** Benutze als großen Puffer eine Hashtabelle
           s_t_qt_units_all_hash
           TYPE HASHED TABLE OF qt_unit_hash_line_type
           WITH UNIQUE KEY matnr.

*                *** Arbeitsbereich für Hashtabelle
  DATA l_wa_qt_units_all_hash TYPE qt_unit_hash_line_type.
*$@005 Ende HW-438417-mbi

  DATA: l_save_index      LIKE sy-tabix,
        l_s_t006          LIKE t006 ,
        l_s_t006d         LIKE t006d,
        l_dimension       TYPE c,
        l_s_qt_unit       TYPE mdr1p_s_out_allowed_qt_unit,
        l_t_t006_qt_units TYPE mdr1p_t_out_allowed_qt_unit
                               WITH HEADER LINE.

  CLEAR: p_t_qt_units[],               " Rückabe leeren
*$@005 Anfang HW-438417-mbi
         s_t_qt_units.        " Kopfzeile von kleinem Puffer löschen
*$         s_t_qt_units,        " Kopfzeile von kleinem Puffer löschen
*$         s_t_qt_units_all.    " Kopfzeile von großem Puffer löschen
*$@005 Ende HW-438417-mbi

*                *** 1. Suche zuerst zum letzten gelesenen Material:
  READ TABLE s_t_qt_units INDEX 1.

  IF s_t_qt_units-matnr = p_matnr.
    p_t_qt_units[] = s_t_qt_units[].
  ELSE.
    sy-subrc = 0.
  ENDIF.

*                *** 2. Vesuch es dann im großen Puffer
  IF p_t_qt_units[] IS INITIAL.

*$@005 Anfang HW-438417-mbi
*                *** Lese den Hashtabellenpuffer
    READ TABLE s_t_qt_units_all_hash
         WITH TABLE KEY matnr = p_matnr
         INTO l_wa_qt_units_all_hash.

*                *** Teste, ob ein Eintrag existiert.
    IF sy-subrc = 0.

*                *** Falls ja, Daten übernehmen
      p_t_qt_units[] = l_wa_qt_units_all_hash-itab.

*                *** Daten im kleinen Puffer speichern
      s_t_qt_units[] = p_t_qt_units[].

    ELSE.

*$      LOOP AT     s_t_qt_units_all
*$        WHERE     matnr = p_matnr.
*$
*$        APPEND s_t_qt_units_all
*$            TO p_t_qt_units.
*$      ENDLOOP.
*$
*$      IF p_t_qt_units[] IS INITIAL.
*$        sy-subrc = 0.
*$      ELSE.
*$        s_t_qt_units[] = p_t_qt_units[].
*$      ENDIF.
*$
*$  ENDIF.
*$@005 Ende HW-438417-mbi

*                *** 3. gültige ME wurden für das Material noch nicht
*                ***    bestimmt => Bestimmung durchführen
*$@005 Anfang HW-438417-mbi
*$  IF p_t_qt_units[] IS INITIAL.
*$@005 Ende HW-438417-mbi
*                ***    - alles zuerst einmal im kleinen Puffer
      CLEAR: s_t_qt_units,
             s_t_qt_units[].

*                ***    - Lese die gültigen ME aus der MARM
      PERFORM read_marm_all TABLES s_t_qt_units
*$@003 Anfang MWE-HW-300836
*                          USING p_matnr.
                            USING p_matnr
                                  p_meins.
*$@003 Ende MWE-HW-300836


*                ***    - Merke die gültigen MARM-ME als Rückgabe
      p_t_qt_units[] = s_t_qt_units[].

*                ***    - Bearbeite die bestimmtene MARM-ME
      LOOP AT s_t_qt_units.

        l_save_index = sy-tabix.

        CLEAR: l_s_t006,
               l_s_t006d,
               l_s_qt_unit.
        l_dimension = c_no.

        l_s_qt_unit = s_t_qt_units.

*                ***      -> Bestimme die T006-Daten
        PERFORM read_t006 USING    l_s_qt_unit-meinh
                          CHANGING l_s_t006.

*                ***      -> Daten aus der T006 ablegen
        l_s_qt_unit-addko = l_s_t006-addko.

*                ***      -> Prüfe die ME auf Dimensionslos
        PERFORM check_dimension_of_qtunit USING    l_s_t006
                                          CHANGING l_s_t006d
                                                   l_dimension.

*                ***      -> spezielle Behandlung von nicht
*                ***         Dimensionslosen ME
        IF l_dimension = c_yes.
          PERFORM find_valid_t006_qtunits   TABLES   p_t_qt_units
                                                    l_t_t006_qt_units
                                            USING    l_s_t006
                                                     l_s_t006d
                                            CHANGING l_s_qt_unit.
        ENDIF.

        s_t_qt_units = l_s_qt_unit.

        MODIFY  s_t_qt_units
         INDEX  l_save_index.

      ENDLOOP.

      IF NOT ( l_t_t006_qt_units[] IS INITIAL ).
        APPEND LINES OF l_t_t006_qt_units
                     TO s_t_qt_units.
      ENDIF.

*$@005 Anfang HW-438417-mbi
*                *** Füge die Daten des kleinen Puffers in den
*                *** großen Puffer ein.
      l_wa_qt_units_all_hash-matnr = p_matnr.
      l_wa_qt_units_all_hash-itab  = s_t_qt_units[].

      INSERT l_wa_qt_units_all_hash
             INTO TABLE s_t_qt_units_all_hash.

      p_t_qt_units[] = s_t_qt_units[].

    ENDIF.

*$      APPEND LINES OF s_t_qt_units
*$                   TO s_t_qt_units_all.
*$
*$      p_t_qt_units[] = s_t_qt_units[].
*$@005 Ende HW-438417-mbi

  ENDIF.

ENDFORM.                               " FIND_VALID_MATERIAL_UNITS

*&---------------------------------------------------------------------*
*&      Form  check_dimension_of_qtunit
*&---------------------------------------------------------------------*
*       Prüfe ob eine ME dimensionslos ist
*----------------------------------------------------------------------*
*      -->P_S_T006      T006-Eintrag zu der ME
*      <--P_S_T006D     Bestimmter T006D Eintrag zu der Dimension
*      <--P_DIMENSION   = 'X', wenn eine nicht dimensionslose ME
*                       vorliegt.
*----------------------------------------------------------------------*
FORM check_dimension_of_qtunit
                   USING
                     p_s_t006     LIKE  t006
                   CHANGING
                     p_s_t006d    LIKE  t006d
                     p_dimension  TYPE  c.

*                *** Default Rückgabe:
  CLEAR: p_s_t006d.

  p_dimension = c_no.

*                *** Lese die T006D zu der Dimension aus der T006
  PERFORM read_t006d USING    p_s_t006-dimid
                     CHANGING p_s_t006d.

*                *** Entscheide, ob nicht dimensionslos!!!
  IF NOT ( p_s_t006d-leng   IS INITIAL )
  OR NOT ( p_s_t006d-mass   IS INITIAL )
  OR NOT ( p_s_t006d-timex  IS INITIAL )
  OR NOT ( p_s_t006d-ecurr  IS INITIAL )
  OR NOT ( p_s_t006d-temp   IS INITIAL )
  OR NOT ( p_s_t006d-molqu  IS INITIAL )
  OR NOT ( p_s_t006d-light  IS INITIAL ).
    p_dimension = c_yes.
  ENDIF.

ENDFORM.                               " check_dimension_of_qtunit

*&---------------------------------------------------------------------*
*&      Form  find_valid_t006_qtunits
*&---------------------------------------------------------------------*
*      Bestimme zu einer nicht dimensionslosen ME, die weitern
*      gültigen t006-ME und lege sie in einer Tabelle ab
*----------------------------------------------------------------------*
*      -->P_T_MARM_QT_UNITS  gültige MARM-ME
*      -->P_T_T006_QT_UNITS  aktuell schon bestimmte gültigen T006-ME
*      -->P_S_T006           aktueller T006-Eintrag zu der nicht
*                            dimensionslosen ME
*      -->P_S_T006D          aktueller T006D-Eintrag zu der Dimension
*      -->P_S_QT_UNIT        aktuelle nicht dimensionslose MARM-ME
*      <--P_T_T006_QT_UNITS  zusätzlich bestimmte gültigen T006-ME
*      <--P_S_QT_UNIT        anpassen der SI-Umrechnungsfaktoren
*----------------------------------------------------------------------*
FORM find_valid_t006_qtunits
                 TABLES
                   p_t_marm_qt_units  TYPE  mdr1p_t_out_allowed_qt_unit
                   p_t_t006_qt_units  TYPE  mdr1p_t_out_allowed_qt_unit
                 USING
                   p_s_t006           LIKE  t006
                   p_s_t006d          LIKE  t006d
                 CHANGING
                   p_s_qt_unit        TYPE  mdr1p_s_out_allowed_qt_unit.

  DATA: l_t_t006           LIKE  t006
                           OCCURS 0 WITH HEADER LINE,
        l_s_marm_qt_units  TYPE  mdr1p_s_out_allowed_qt_unit.

*$@004 Anfang HW-430276-MWE
  DATA: l_umrez_f  TYPE  f,
        l_umren_f  TYPE  f.
*$@004 Ende HW-430276-MWE

  CLEAR: l_t_t006[],
         l_s_marm_qt_units.

*                *** Wurde die Dimension schon berücksichtigt?
  READ TABLE p_t_t006_qt_units
* note 307543 - B
*   WITH KEY dimid = p_t_t006_qt_units-dimid.
    WITH KEY dimid = p_s_t006-dimid.
* note 307543 - E

  IF sy-subrc <> 0.
*                *** Deminsion noch nicht berücksichtigt =>
*                *** - Lese die T006 zu der DIMID
    PERFORM read_t006_dimid TABLES l_t_t006
                            USING  p_s_t006-dimid.

*                *** - Bestimme die Umrechnungsfaktoren in die
*                ***   MARM-Basis-ME zu der SI-ME, wenn sie in der MARM
*                ***   definiert wurde.
    READ TABLE   p_t_marm_qt_units
      WITH KEY   meinh = p_s_t006d-mssie.

    IF sy-subrc = 0.
      l_s_marm_qt_units = p_t_marm_qt_units.
    ELSE.
      sy-subrc = 0.
    ENDIF.

    LOOP AT l_t_t006.

      READ TABLE p_t_marm_qt_units
        WITH KEY meinh = l_t_t006-msehi.

      IF sy-subrc <> 0.
*                *** - Lege Eintrag in p_t_t006_qt_units an
        CLEAR: p_t_t006_qt_units,
               sy-subrc.

        p_t_t006_qt_units-matnr         = p_s_qt_unit-matnr.
        p_t_t006_qt_units-meinh         = l_t_t006-msehi.
        p_t_t006_qt_units-flagsiqtunit  = c_yes.
        p_t_t006_qt_units-addko         = l_t_t006-addko.
        p_t_t006_qt_units-dimid         = l_t_t006-dimid.
        p_t_t006_qt_units-mssie         = p_s_t006d-mssie.
        p_t_t006_qt_units-zaehl         = l_t_t006-zaehl.
        p_t_t006_qt_units-nennr         = l_t_t006-nennr.

*                *** - Bestimme die Umrechnungsfaktoren in die Basis-ME
*                ***   der MARM
* note 311301 - B
        IF l_s_marm_qt_units IS INITIAL.
*                ***   Basis-SI-ME nicht in MARM definiert
*$@004 Anfang HW-430276-MWE
*                ***   Verhinderung von eventuellem Kurz-Dumps
          l_umrez_f  =   l_t_t006-zaehl    "aktuelle SI-ME
                       * ( 10 ** l_t_t006-exp10 )
                       * p_s_t006-nennr    "MARM-ME&SI-ME
                       * p_s_qt_unit-umrez."laut MARM-Ein.

          IF l_umrez_f >=  c_10_exp_17.
*                ***   Große Werte nur als FP darstellbar:
            p_t_t006_qt_units-umrezf =  l_umrez_f.
*                ***   => nicht FB-Werte initialisieren.
            p_t_t006_qt_units-umrez  =  0.
          ELSE.
*$@004 Ende HW-430276-MWE
            p_t_t006_qt_units-umrez  =   l_t_t006-zaehl  "aktuelle SI-ME
* note 363841 - B
                                     * ( 10 ** l_t_t006-exp10 )
* note 363841 - E
                                     * p_s_t006-nennr   "MARM-ME&SI-ME
                                     * p_s_qt_unit-umrez."laut MARM-Ein.
*$@004 Anfang HW-430276-MWE
          ENDIF.

          l_umren_f  =   l_t_t006-nennr    "aktuelle SI-ME
                       * p_s_t006-zaehl    "MARM-ME&SI-ME
                       * ( 10 ** p_s_t006-exp10 )
                       * p_s_qt_unit-umren."laut MARM-Ein.

          IF l_umren_f >= c_10_exp_17.
*                ***   Große Werte nur als FP darstellbar:
            p_t_t006_qt_units-umrenf =  l_umren_f.
*                ***   => nicht FB-Werte initialisieren.
            p_t_t006_qt_units-umren  =  0.
          ELSE.
*$@004 Ende HW-430276-MWE
            p_t_t006_qt_units-umren  =   l_t_t006-nennr  "aktuelle SI-ME
                                     * p_s_t006-zaehl    "MARM-ME&SI-ME
* note 363841 - B
                                     * ( 10 ** p_s_t006-exp10 )
* note 363841 - E
                                     * p_s_qt_unit-umren."laut MARM-Ein.
*$@004 Anfang HW-430276-MWE
          ENDIF.
*$@004 Ende HW-430276-MWE
        ELSE.
*                ***   Basis-SI-ME ist in MARM definiert
*                ***   die entsprechenden Umrechnungsfaktoren stehen
*                ***   in l_s_marm_qt_units
* note 311301 - E
*$@004 Anfang HW-430276-MWE
          l_umrez_f  =   l_t_t006-zaehl
*$@005 begin of note 500817 - HWI
                       * ( 10 ** l_t_t006-exp10 )
*$@005 end of note 500817 - HWI
                       * l_s_marm_qt_units-umrez.

          IF l_umrez_f >=  c_10_exp_17.
*                ***   Große Werte nur als FP darstellbar:
            p_t_t006_qt_units-umrezf =  l_umrez_f.
*                ***   => nicht FB-Werte initialisieren.
            p_t_t006_qt_units-umrez  =  0.
          ELSE.
*$@004 Ende HW-430276-MWE
            p_t_t006_qt_units-umrez  =   l_t_t006-zaehl
*$@005 begin of note 500817 - HWI
                                       * ( 10 ** l_t_t006-exp10 )
*$@005 end of note 500817 - HWI
                                       * l_s_marm_qt_units-umrez.
*$@004 Anfang HW-430276-MWE
          ENDIF.

          l_umren_f  =   l_t_t006-nennr
                       * l_s_marm_qt_units-umren.

          IF l_umren_f >= c_10_exp_17.
*                ***   Große Werte nur als FP darstellbar:
            p_t_t006_qt_units-umrenf =  l_umren_f.
*                ***   => nicht FB-Werte initialisieren.
            p_t_t006_qt_units-umren  =  0.
          ELSE.
*$@004 Ende HW-430276-MWE
            p_t_t006_qt_units-umren  =   l_t_t006-nennr
                                       * l_s_marm_qt_units-umren.
*$@004 Anfang HW-430276-MWE
          ENDIF.
*$@004 Ende HW-430276-MWE
        ENDIF.

*                ***   in der Tabelle der gültigen T006-ME merken
        APPEND p_t_t006_qt_units.

      ENDIF.
    ENDLOOP.
  ENDIF.

*                *** - zum Schluß müssen noch die T006-Daten
*                ***   für die aktuelle MARA-ME aktualisiert werden
  p_s_qt_unit-addko  =  p_s_t006-addko.
  p_s_qt_unit-dimid  =  p_s_t006-dimid.
  p_s_qt_unit-mssie  =  p_s_t006d-mssie.
  p_s_qt_unit-zaehl  =  p_s_t006-zaehl.
  p_s_qt_unit-nennr  =  p_s_t006-nennr.

ENDFORM.                               " find_valid_t006_qtunits
*&---------------------------------------------------------------------*
*&      Form  CONV2UNIT_RULE_1
*&---------------------------------------------------------------------*
*       Umrechnung von einer Quell-ME in die Basis-ME
*----------------------------------------------------------------------*
*      -->P_QTY_OLD    Bisherige Menge (in der Quell-ME)
*      -->P_ADDKO      additive KOnstante der Quell-ME
*      -->P_UMREZ      Umrechnungszähler für die Umrechnung der
*                      Quell-ME in die Basis-ME
*      -->P_UMREN      Umrechnungszähler für die Umrechnung der
*                      Quell-ME in die Basis-ME
*$@004 Anfang HW-430276-MWE
*      -->p_umrezf
*      -->p_umrenf
*$@004 Ende HW-430276-MWE
*      <--P_QTY_NEW    neue Menge in Basis-ME
*----------------------------------------------------------------------*
FORM conv2unit_rule_1
                   USING
                     value(p_qty_old)   TYPE  mdr1p_p_16_dec_14
                     value(p_addko)     LIKE  t006-addko
                     value(p_umrez)     TYPE  mdr1p_p_16_dec_14
                     value(p_umren)     TYPE  mdr1p_p_16_dec_14
*$@004 Anfang HW-430276-MWE
                     p_umrezf           TYPE  f
                     p_umrenf           TYPE  f
*$@004 Ende HW-430276-MWE
                   CHANGING
                     value(p_qty_new)   TYPE  mdr1p_p_16_dec_14.

  DATA: l_help_qty_old(16)    TYPE  p DECIMALS 14,
        l_help_qty_new(16)    TYPE  p DECIMALS 14,
        l_help_umrez(16)      TYPE  p DECIMALS 14,
        l_help_umren(16)      TYPE  p DECIMALS 14.

*$@004 Anfang HW-430276-MWE
  DATA: l_help_qty_new_f      TYPE  f.
*$@004 Ende HW-430276-MWE


  l_help_qty_old    =  p_qty_old.
  l_help_umrez      =  p_umrez.
  l_help_umren      =  p_umren.

*                *** Default Belegung, für Nenner = 0
  l_help_qty_new    =  p_qty_old.

*$@004 Anfang HW-430276-MWE
*$  IF l_help_umren  <>  0.
*$*                *** Führe Umrechnung durch:
*$    l_help_qty_new  =   (  (  l_help_qty_old
*$                            + p_addko )
*$                         * l_help_umrez )
*$                      / l_help_umren .
*$  ENDIF.
  IF      l_help_umren  <>  0
  AND     l_help_umrez  <>  0.
*                *** Führe Umrechnung ohne FP durch:
    l_help_qty_new  =   (  (  l_help_qty_old
                            + p_addko )
                         * l_help_umrez )
                      / l_help_umren .

  ELSEIF  l_help_umren  <>  0
     AND  l_help_umrez  =   0.
*                *** Führe Umrechnung mit Zähler-FP durch:
    l_help_qty_new_f  =   (  (  l_help_qty_old
                              + p_addko )
                           * p_umrezf )
                        / l_help_umren .

    IF  l_help_qty_new_f < c_10_exp_17.

      l_help_qty_new   =   (  (  l_help_qty_old
                               + p_addko )
                            * p_umrezf )
                         / l_help_umren .

    ENDIF.

  ELSEIF  l_help_umren  =   0
     AND  l_help_umrez  <>  0.

    IF p_umrenf <> 0.
*                *** Führe Umrechnung mit Nenner-FP durch:
      l_help_qty_new_f  =   (  (  l_help_qty_old
                                + p_addko )
                             * l_help_umrez )
                          / p_umrenf .

      IF  l_help_qty_new_f < c_10_exp_17.

        l_help_qty_new   =   (  (  l_help_qty_old
                                  + p_addko )
                               * l_help_umrez )
                            / p_umrenf .

      ENDIF.

    ENDIF.

  ELSE.

    IF p_umrenf <> 0.
*                *** Führe Umrechnung mit Nenner-FP und Zähler-FP durch:
      l_help_qty_new_f  =   (  (  l_help_qty_old
                                + p_addko )
                             * p_umrezf )
                          / p_umrenf .

      IF  l_help_qty_new_f < c_10_exp_17.

        l_help_qty_new   =   (  (  l_help_qty_old
                                  + p_addko )
                               * p_umrezf )
                            / p_umrenf .

      ENDIF.

    ENDIF.

  ENDIF.
*$@004 Ende HW-430276-MWE

  p_qty_new  =  l_help_qty_new.

ENDFORM.                               " CONV2UNIT_RULE_1

*&---------------------------------------------------------------------*
*&      Form  CONV2UNIT_RULE_2
*&---------------------------------------------------------------------*
*       Umrechnung von der Basis-ME in eine Ziel-ME
*----------------------------------------------------------------------*
*      -->P_QTY_OLD    Bisherige Menge (in der Basis-ME)
*      -->P_ADDKO      additive Konstante der Ziel-ME
*      -->P_UMREZ      Umrechnungszähler für die Umrechnung der
*                      Ziel-ME in die Basis-ME
*      -->P_UMREN      Umrechnungszähler für die Umrechnung der
*                      Ziel-ME in die Basis-ME
*$@004 Anfang HW-430276-MWE
*      -->p_umrezf
*      -->p_umrenf
*$@004 Ende HW-430276-MWE
*      <--P_QTY_NEW    neue Menge in der Ziel-ME
*----------------------------------------------------------------------*
FORM conv2unit_rule_2
                   USING
                     value(p_qty_old)   TYPE  mdr1p_p_16_dec_14
                     value(p_addko)     LIKE  t006-addko
                     value(p_umrez)     TYPE  mdr1p_p_16_dec_14
                     value(p_umren)     TYPE  mdr1p_p_16_dec_14
*$@004 Anfang HW-430276-MWE
                     p_umrezf           TYPE  f
                     p_umrenf           TYPE  f
*$@004 Ende HW-430276-MWE
                   CHANGING
                     value(p_qty_new)   TYPE  mdr1p_p_16_dec_14.


  DATA: l_help_qty_old(16)    TYPE  p DECIMALS 14,
        l_help_qty_new(16)    TYPE  p DECIMALS 14,
        l_help_umrez(16)      TYPE  p DECIMALS 14,
        l_help_umren(16)      TYPE  p DECIMALS 14.

*$@004 Anfang HW-430276-MWE
  DATA: l_help_qty_new_f      TYPE  f.
*$@004 Ende HW-430276-MWE

  l_help_qty_old    =  p_qty_old.
  l_help_umrez      =  p_umrez.
  l_help_umren      =  p_umren.

*                *** Default Belegung, für Zähler = 0
  l_help_qty_new    =  p_qty_old.

*$@004 Anfang HW-430276-MWE
*$  IF l_help_umrez  <>  0.
*$*                *** Führe Umrechnung durch:
*$    l_help_qty_new  =   (   (  l_help_qty_old
*$                             * l_help_umren )
*$                          / l_help_umrez )
*$                      - p_addko.
*$  ENDIF.
  IF      l_help_umren  <>  0
  AND     l_help_umrez  <>  0.
*                *** Führe Umrechnung ohne FP durch:
    l_help_qty_new  =   (   (  l_help_qty_old
                             * l_help_umren )
                          / l_help_umrez )
                      - p_addko.

  ELSEIF  l_help_umren  <>  0
     AND  l_help_umrez  =   0.

    IF p_umrezf <> 0.
*                *** Führe Umrechnung mit Zähler-FP durch:
      l_help_qty_new_f  =   (   (  l_help_qty_old
                                 * l_help_umren )
                              / p_umrezf )
                          - p_addko.

      IF  l_help_qty_new_f < c_10_exp_17.

        l_help_qty_new    =   (   (  l_help_qty_old
                                   * l_help_umren )
                                / p_umrezf )
                            - p_addko.

      ENDIF.

    ENDIF.

  ELSEIF  l_help_umren  =   0
     AND  l_help_umrez  <>  0.
*                *** Führe Umrechnung mit Nenner-FP durch:
    l_help_qty_new_f  =   (   (  l_help_qty_old
                               * p_umrenf )
                            / l_help_umrez )
                        - p_addko.

    IF  l_help_qty_new_f < c_10_exp_17.

      l_help_qty_new    =   (   (  l_help_qty_old
                                 * p_umrenf )
                              / l_help_umrez )
                          - p_addko.

    ENDIF.

  ELSE.

    IF p_umrezf <> 0.
*                *** Führe Umrechnung mit Nenner-FP und Zähler-FP durch:
      l_help_qty_new_f  =   (   (  l_help_qty_old
                                 * p_umrenf )
                              / p_umrezf )
                          - p_addko.

      IF  l_help_qty_new_f < c_10_exp_17.

        l_help_qty_new    =   (   (  l_help_qty_old
                                   * p_umrenf )
                                / p_umrezf )
                            - p_addko.

      ENDIF.

    ENDIF.

  ENDIF.
*$@004 Ende HW-430276-MWE

  p_qty_new  =  l_help_qty_new.

ENDFORM.                               " CONV2UNIT_RULE_2

*&---------------------------------------------------------------------*
*&      Form  GET_UNITS_FACTORS_GENERAL
*&---------------------------------------------------------------------*
*       Bestimme die Umrechnungsfaktoren zu einem Material und
*       einer ME zu der Basis-ME des Materials
*----------------------------------------------------------------------*
*      -->P_MATNR    Material
*      -->P_UNIT     ME
*$@003 Anfang MWE-HW-300836
*      -->P_MEINS    Basis-ME
*$@003 Ende MWE-HW-300836
*      <--P_P_UMREZ
*      <--P_P_UMREN
*$@004 Anfang HW-430276-MWE
*      <--p_umrezf
*      <--p_umrenf
*$@004 Ende HW-430276-MWE
*      <--P_P_ADDKO
*----------------------------------------------------------------------*
FORM get_units_factors_general
                   USING
                     value(p_matnr)    LIKE  mara-matnr
                     value(p_unit)     LIKE   marm-meinh
*$@003 Anfang MWE-HW-300836
                     value(p_meins)    LIKE   mara-meins
*$@003 Ende MWE-HW-300836
                   CHANGING
                     value(p_umrez)    TYPE   mdr1p_p_16_dec_14
                     value(p_umren)    TYPE   mdr1p_p_16_dec_14
*$@004 Anfang HW-430276-MWE
                     p_umrezf          TYPE   f
                     p_umrenf          TYPE   f
*$@004 Ende HW-430276-MWE
                     value(p_addko)    LIKE   t006-addko.

*$@NOTE-943418-B
  STATICS: st_units_buffer TYPE HASHED TABLE OF mdr1p_s_units_factors
             WITH UNIQUE KEY matnr meinh.

  DATA:  lt_qt_units     TYPE mdr1p_t_out_allowed_qt_unit,
         ls_units_buffer TYPE mdr1p_s_units_factors.

  FIELD-SYMBOLS: <ss_units_buffer> TYPE mdr1p_s_units_factors,
                 <ls_qt_units>     TYPE mdr1outallowedqtunit.

* check if we have already determined the respective data
  READ TABLE st_units_buffer WITH TABLE KEY
    matnr = p_matnr
    meinh = p_unit
  ASSIGNING <ss_units_buffer>.

  IF sy-subrc <> 0.

*   check if we have alread determined the respective material units
*   read with basic unit of measure
    READ TABLE st_units_buffer WITH TABLE KEY
      matnr = p_matnr
      meinh = p_meins
    ASSIGNING <ss_units_buffer>.

    IF sy-subrc = 0.

*     unit of measurement p_unit not maintained!
      CLEAR: p_umrez,
             p_umren,
             p_addko,
             p_umrezf,
             p_umrenf.

      RETURN.

    ENDIF.

*   valid material units not yet determined

    PERFORM find_valid_material_units
      TABLES
        lt_qt_units
      USING
        p_matnr
        p_meins.

    LOOP AT lt_qt_units ASSIGNING <ls_qt_units>.

*     fill new buffer entry
      ls_units_buffer-matnr = <ls_qt_units>-matnr.
      ls_units_buffer-meinh = <ls_qt_units>-meinh.
      ls_units_buffer-umrez = <ls_qt_units>-umrez.
      ls_units_buffer-umren = <ls_qt_units>-umren.
      ls_units_buffer-addko = <ls_qt_units>-addko.
      ls_units_buffer-umrezf = <ls_qt_units>-umrezf.
      ls_units_buffer-umrenf = <ls_qt_units>-umrenf.

*     insert new buffer entry
      INSERT ls_units_buffer INTO TABLE st_units_buffer.

    ENDLOOP.

*   read again
    READ TABLE st_units_buffer WITH TABLE KEY
      matnr = p_matnr
      meinh = p_unit
    ASSIGNING <ss_units_buffer>.

    IF sy-subrc <> 0.

*     unit of measurement p_unit not maintained!
      CLEAR: p_umrez,
             p_umren,
             p_addko,
             p_umrezf,
             p_umrenf.

      RETURN.

    ENDIF.

  ENDIF.

* take the data out of the buffer
  p_umrez = <ss_units_buffer>-umrez.
  p_umren = <ss_units_buffer>-umren.
  p_addko = <ss_units_buffer>-addko.
  p_umrezf = <ss_units_buffer>-umrezf.
  p_umrenf = <ss_units_buffer>-umrenf.

**                *** Puffer definieren:
*  STATICS: s_t_units     TYPE mdr1p_t_units_factors
*                         WITH HEADER LINE,
*           s_s_unit      TYPE mdr1p_s_units_factors.
*
*  DATA:  l_t_qt_units    TYPE mdr1p_t_out_allowed_qt_unit
*                         WITH HEADER LINE.
*
*  CLEAR: l_t_qt_units[],
*         p_umrez,
*         p_umren,
*         p_addko.
*
**                *** 1. Umrechnungsfaktoren wurden zu letzt schon be-
**                ***    bestimmt.
*  IF  s_s_unit-matnr = p_matnr
*  AND s_s_unit-meinh = p_unit.
*    p_umrez = s_s_unit-umrez.
*    p_umren = s_s_unit-umren.
*    p_addko = s_s_unit-addko.
**$@004 Anfang HW-430276-MWE
*    p_umrezf = s_s_unit-umrezf.
*    p_umrenf = s_s_unit-umrenf.
**$@004 Ende HW-430276-MWE
*  ENDIF.
*
**                *** 2. Versuche die Umrechnungsfaktoren aus Puffer-Tab
**                ***    zu bestimmen
**$@004 Anfang HW-430276-MWE
**$  IF  p_umrez IS INITIAL
**$  AND p_umren IS INITIAL.
*  IF  (   p_umrez   IS INITIAL
*       OR p_umrezf  IS INITIAL )
*  AND (   p_umren   IS INITIAL
*       OR p_umrenf  IS INITIAL ).
**$@004 Ende HW-430276-MWE
*
*    READ TABLE  s_t_units
*      WITH KEY  matnr = p_matnr
*                meinh = p_unit
**$@001 Anfang MWE-ENTW-46C
*                BINARY SEARCH.
**$@001 Ende MWE-ENTW-46C
*
*    IF sy-subrc = 0.
*      p_umrez = s_t_units-umrez.
*      p_umren = s_t_units-umren.
*      p_addko = s_t_units-addko.
**$@004 Anfang HW-430276-MWE
*      p_umrezf = s_t_units-umrezf.
*      p_umrenf = s_t_units-umrenf.
**$@004 Ende HW-430276-MWE
*    ELSE.
*      sy-subrc = 0.
*    ENDIF.
*
*  ENDIF.
*
**                *** 3. Versuche die Daten von der DB zu bestimmen
**                ***    Bestimme dazu alle Umrechnungsfaktoren zu dem
**                ***    Artikel einmal, wenn noch nicht geschehen.
**$@004 Anfang HW-430276-MWE
**$  IF  p_umrez IS INITIAL
**$  AND p_umren IS INITIAL.
*  IF  p_umrez  IS INITIAL
*  AND p_umren  IS INITIAL
*  AND p_umrezf IS INITIAL
*  AND p_umrenf IS INITIAL.
**$@004 Ende HW-430276-MWE
*
*    READ TABLE  s_t_units
*      WITH KEY  matnr = p_matnr
**$@001 Anfang MWE-ENTW-46C
*                BINARY SEARCH.
**$@001 Ende MWE-ENTW-46C
*
*
*    IF sy-subrc <> 0.
**                ***    Zu dem Material wurde noch nichts bestimmt =>
*      PERFORM find_valid_material_units TABLES l_t_qt_units
**$@003 Anfang MWE-HW-300836
**$                                        USING  p_matnr.
*                                        USING  p_matnr
*                                               p_meins.
**$@003 Ende MWE-HW-300836
*
*      LOOP AT l_t_qt_units.
*
*        CLEAR: s_t_units.
*
*        MOVE-CORRESPONDING l_t_qt_units  TO  s_t_units.
*
*        IF s_t_units-meinh =  p_unit.
*          s_s_unit = s_t_units.
*          p_umrez = s_s_unit-umrez.
*          p_umren = s_s_unit-umren.
*          p_addko = s_s_unit-addko.
**$@004 Anfang HW-430276-MWE
*          p_umrezf = s_s_unit-umrezf.
*          p_umrenf = s_s_unit-umrenf.
**$@004 Ende HW-430276-MWE
*        ENDIF.
*
*        APPEND s_t_units.
*
*      ENDLOOP.
*
**$@001 Anfang MWE-ENTW-46C
*      SORT s_t_units
*        BY matnr
*           meinh.
**$@001 Ende MWE-ENTW-46C
*
*    ENDIF.
*  ENDIF.
*$@NOTE-943418-E

ENDFORM.                               " GET_UNITS_FACTORS_GENERAL

*#@006 HWI 4.70 customizing of logistical rounding B
*&---------------------------------------------------------------------*
*&      Form  change_appl_to_cust
*&---------------------------------------------------------------------*
*    rappl wird auf kundeneigene Einträge geändert
*----------------------------------------------------------------------*
*      -->P_OPCODE
*      <--P_RAPPL
*----------------------------------------------------------------------*
FORM change_appl_to_cust
  USING
    p_opcode   TYPE  syinput
  CHANGING
    p_rappl    TYPE  lumerrappl.

  CASE p_opcode.

    WHEN mdr1p_c_op_mm_normal or mdr1p_c_op_lb .

      p_rappl = c_rappl_cust_po_za  .     " ='ZA'.

    WHEN mdr1p_c_op_mm_ub.

      p_rappl = c_rappl_cust_stto_zb.     " = 'ZB'.

    WHEN mdr1p_c_op_sd_auftrag.

      p_rappl = c_rappl_cust_so_zc.       " = 'ZC'

    WHEN mdr1p_c_op_sd_lieferung.

      p_rappl = c_rappl_cust_dl_zd.       " = 'ZD'

    WHEN mdr1p_c_op_additionals.

      p_rappl = c_rappl_cust_add_ze.      " = 'ZE'.

  ENDCASE.

ENDFORM.                    " change_opcode_to_cust

*&---------------------------------------------------------------------*
*&      Form  change_appl_to_SAP
*&---------------------------------------------------------------------*
*       rappl wird auf SAP Einträge geändert
*----------------------------------------------------------------------*
*      -->P_OPCODE
*      <--P_RAPPL
*----------------------------------------------------------------------*
FORM change_appl_to_sap
  USING
    p_opcode  TYPE  syinput
  CHANGING
    p_rappl   TYPE  lumerrappl.

  CASE p_opcode.

    WHEN mdr1p_c_op_mm_normal or mdr1p_c_op_lb .

      p_rappl = c_rappl_sap_po_a.        " = 'A'.

    WHEN mdr1p_c_op_mm_ub.

      p_rappl = c_rappl_sap_stto_b.      " = 'B'.

    WHEN mdr1p_c_op_sd_auftrag.

      p_rappl = c_rappl_sap_so_c.        " = 'C'.

    WHEN mdr1p_c_op_sd_lieferung.

      p_rappl = c_rappl_sap_dl_d.        " = 'D'.

    WHEN mdr1p_c_op_additionals.

      p_rappl = c_rappl_sap_add_e.       " = 'E'.

  ENDCASE.

ENDFORM.                    " change_opcode_to_SAP

*&---------------------------------------------------------------------*
*&      Form  set_opcode_for_appl
*&---------------------------------------------------------------------*
*   Opcode laut ausgewählter Anwendung setzen
*----------------------------------------------------------------------*
*      -->P_APPL
*      <--P_OPCODE
*----------------------------------------------------------------------*
FORM set_opcode_for_appl
  USING
    p_appl     TYPE  lumerappl
  CHANGING
    p_opcode   TYPE  syinput.

  CASE p_appl.

    WHEN c_rappl_sap_po_a.        " = 'A'.

      p_opcode = mdr1p_c_op_mm_normal.

    WHEN c_rappl_sap_stto_b.      " = 'B'.

      p_opcode = mdr1p_c_op_mm_ub.

    WHEN c_rappl_sap_so_c.        " = 'C'.

      p_opcode = mdr1p_c_op_sd_auftrag.

    WHEN c_rappl_sap_dl_d.        " = 'D'.

      p_opcode = mdr1p_c_op_sd_lieferung.

    WHEN c_rappl_sap_add_e.       " = 'E'.

      p_opcode = mdr1p_c_op_additionals.

  ENDCASE.

ENDFORM.                    " set_opcode_for_appl
*#@006 HWI 4.70 customizing of logistical rounding E

*$@007 Anfang
*&---------------------------------------------------------------------*
*&      Form  ENTER_ROUNDING_REASON
*&---------------------------------------------------------------------*
*       Dieses Unterprogramm legt ein weiteren Eintrag
*       in eine Tabelle der Rundungsgründe an
*----------------------------------------------------------------------*
*      -->P_T_ROUNDING_REASONS    Tabelle der bereits gesammelten
*                                 Rundungsgründe
*      -->P_I_ROUNDING_REASON     neuer Rundungsgrund
*      <--P_T_ROUNDING_REASONS    Tabelle der Rundungsgründe mit dem
*                                 weiteren Eintrag für den neuen
*                                 Rundungsgrund
*----------------------------------------------------------------------*
FORM ENTER_ROUNDING_REASON
                     TABLES
                       P_T_ROUNDING_REASONS TYPE MDR1P_T_RUNDUNGSGRUND
                     USING
                       P_I_ROUNDING_REASON  TYPE C.

*                *** Initialisiere die Kopfdaten der Tabelle
  CLEAR: P_T_ROUNDING_REASONS.

*                *** Füge neuen Rundungsgrund hinzu
  P_T_ROUNDING_REASONS-KZGRUND = P_I_ROUNDING_REASON.
  APPEND P_T_ROUNDING_REASONS.

ENDFORM.                    " ENTER_ROUNDING_REASON
*$@007 Ende

*
* 
