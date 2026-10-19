*----------------------------------------------------------------------*
***INCLUDE LMDR1F10 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.01.99  99A  mwe         Grundversion
*- @001  15.11.99  46C  mwe         - Performnaceverbesserung bei READ
*-                                    TABLE mit BINARY SEARCH
*- @002  04.05.00  46C  mwe         Basis-ME bei Material (Standard)
*-                                  nicht in der MARM eingetragen
*-                                  Korrektur zu Hinweis: 300836
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_U10
*&---------------------------------------------------------------------*
*       Eingabeprüfung zu FB: MD_ALLOWED_QUANTITY_UNIT
*----------------------------------------------------------------------*
*  -->  p_s_general      allgemeine Eingabestruktur
*  -->  p_s_mara         MARA-Eintrag zu dem Material
*  -->  p_s_eina         EINA-Eintrag (EK-Info-Satz) zu Lief und Mat.
*  -->  p_s_eine         EINE-Eintrag 2.Teil des EK-Info-Satz
*----------------------------------------------------------------------*
FORM check_input_u10
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_mara     TYPE  mara
                    p_s_eina     TYPE  eina
                    p_s_eine     TYPE  eine.

*                *** 1. Es muß mindestens eine Prüfung oder eine Be-
*                ***    stimmung einer ME durchgeführt werden!!!
  IF  NOT ( p_s_general-flagdefqtunit = c_yes )
  AND NOT ( p_s_general-flagvenqtunit = c_yes )
  AND NOT ( p_s_general-flagbuyqtunit = c_yes )
  AND NOT ( p_s_general-flagallqtunit = c_yes ).

    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

*                *** 2. Bei der Prüfung der erlaubten logistischen
*                ***    müssen auch alle dazu notwenige Daten bestimmt
*                ***    werden => alle Bestimmungsflags müssen gesetzt
*                ***              sein
  IF  p_s_general-flagallqtunit     = c_yes
  AND (   NOT ( p_s_general-flagdefqtunit = c_yes )
       OR NOT ( p_s_general-flagbuyqtunit = c_yes )
       OR NOT ( p_s_general-flagvenqtunit = c_yes ) ).

    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

*                *** 3. Die Unternehmenssicht muß mit einem korrekten
*                ***    Wert gefüllt sein.
  IF  NOT ( p_s_general-appview  =  mdr1p_c_appview_purchase )
  AND NOT ( p_s_general-appview  =  mdr1p_c_appview_sale     )
  AND NOT ( p_s_general-appview  =  mdr1p_c_appview_alloc    )
  AND NOT ( p_s_general-appview  =  mdr1p_c_appview_customer ).

    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

*                *** 4. Prüfung der Pflichtparameter, die immer gefüllt
*                ***    sein müssen =>

*                *** - Material muß existieren!!!
  PERFORM check_input_u10_matnr  USING  p_s_general.

*                ***    - die Umrechnungsfaktoren zu der Bestell-ME
*                ***      in einem existierenden EK-Info-Satz
  IF  NOT ( p_s_eina-meins IS INITIAL )
  AND     (   ( p_s_eina-umrez IS INITIAL )
           OR ( p_s_eina-umren IS INITIAL ) ).

    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

*                ***    - Wenn EK-Info-Sätze existieren, müssen sie
*                ***      komplett übermittelt werden:
  IF (    NOT ( p_s_eina IS INITIAL )
      AND     ( p_s_eine IS INITIAL ) )
  OR (        ( p_s_eina IS INITIAL )
      AND NOT ( p_s_eine IS INITIAL ) ).
    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

*                ***    - Wenn die Default-ME vorgegeben ist müssen auch
*                ***      die Umrechnungsfaktoren mitgegeben werden!!!
  IF  NOT ( p_s_general-defqtunit IS INITIAL )
  AND (   p_s_general-defumrez IS INITIAL
       OR p_s_general-defumren IS INITIAL ).
    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

*                *** 4. Prüfungen zu den einzelnen Prüfungen und Be-
*                ***    stimmungen:

*                ***    - bei der Bestimmung der Default-ME:
  IF p_s_general-flagdefqtunit = c_yes.
    PERFORM check_input_u10_defqtunit USING p_s_mara.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_U10

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_U10_DEFQTUNIT
*&---------------------------------------------------------------------*
*       Prüfe alle Pflichtparameter für die Bestimmung der Default-
*       ME
*----------------------------------------------------------------------*
*      -->P_S_MARA          MARA-Eintrag zu dem Material
*----------------------------------------------------------------------*
FORM check_input_u10_defqtunit
                  USING
                    p_s_mara     TYPE  mara.

*                *** - bei allen Sichtweisen muß mindestens der MARA-
*                ***   Eintrag vorhanden sein
  PERFORM check_input_u10_mara   USING  p_s_mara.

ENDFORM.                               " CHECK_INPUT_U10_DEFQTUNIT

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_U10_MATNR
*&---------------------------------------------------------------------*
*       Prüfe die Eingabe der Materialnummer
*----------------------------------------------------------------------*
*      -->P_S_GENERAL    Allgemeine Eingabestruktur
*----------------------------------------------------------------------*
FORM check_input_u10_matnr
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit.

  IF p_s_general-matnr IS INITIAL.
    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_U10_MATNR

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_U10_MARA
*&---------------------------------------------------------------------*
*       Überprüfe die Existens des MARA-Satzes und die Pflege der
*       Bestell/VK-ME
*----------------------------------------------------------------------*
*      -->P_S_MARA          MARA-Eintrag zu dem Material
*----------------------------------------------------------------------*
FORM check_input_u10_mara
                  USING
                    p_s_mara     TYPE  mara.

  IF p_s_mara IS INITIAL.
    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

  IF p_s_mara-meins IS INITIAL.
    MESSAGE e002(rpugen) WITH    'MD_ALLOWED_QUANTITY_UNIT'
                         RAISING bad_params.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_U10_MARA

*&---------------------------------------------------------------------*
*&      Form  DETERMINE_DEF_QT_UNIT
*&---------------------------------------------------------------------*
*       Bestimme die Default ME
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      -->P_S_MARA     MARA-Eintrag zu dem Material
*      -->P_S_EINA     EINA-Eintrag (EK-Info-Satz) zu Lief und Mat.
*      -->P_S_MARC_2   MARC-Eintrag zu Werk (bei int. Lief) und Mat.
*      -->P_S_MVKE     MVKE-Eintrag zum Eingabe-Werk
*      <--P_T_QT_UNITS Ausgabewerte mit der bestimmten Default-ME
*                      belegt
*----------------------------------------------------------------------*
FORM determine_def_qt_unit
                  TABLES
                    p_t_qt_units TYPE  mdr1p_t_out_allowed_qt_unit
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_mara     TYPE  mara
                    p_s_eina     TYPE  eina
                    p_s_marc_2   TYPE  marc
                    p_s_mvke     TYPE  mvke.

  DATA: l_s_qt_unit   TYPE mdr1p_s_out_allowed_qt_unit.

  CLEAR: l_s_qt_unit.

*                *** Bestimmung abhängig von der Sicht
  CASE p_s_general-appview.

*                *** Bei der EK-Sicht
    WHEN mdr1p_c_appview_purchase.
      PERFORM det_def_qt_unit_purchase USING    p_s_general
                                                p_s_eina
                                                p_s_marc_2
                                                p_s_mara
                                       CHANGING l_s_qt_unit.

*                *** Bei der VK-Sicht
    WHEN mdr1p_c_appview_sale.
      PERFORM det_def_qt_unit_sale     USING    p_s_general
                                                p_s_mvke
                                                p_s_mara
                                       CHANGING l_s_qt_unit.

  ENDCASE.

*                *** Bestimme die Umrechnungsfaktoren für die ME aus
*                *** MARM, wenn nicht vorgegeben (über EK-Info-Satz)
  IF  NOT (   l_s_qt_unit-meinh  IS  INITIAL )
      AND (   l_s_qt_unit-umrez  IS  INITIAL
           OR l_s_qt_unit-umren  IS  INITIAL ).

*$@002 Anfang MWE-HW-300836
*$    PERFORM read_marm_single CHANGING  l_s_qt_unit.
    PERFORM read_marm_single USING     p_s_mara-meins
                             CHANGING  l_s_qt_unit.
*$@002 Ende MWE-HW-300836

    IF l_s_qt_unit-umrez IS INITIAL
    OR l_s_qt_unit-umren IS INITIAL.
*                *** Existiert kein Eintrag in der MARM
*                *** => FEHLER!!!
      SET PARAMETER ID 'MAT' FIELD l_s_qt_unit-matnr.
      SET PARAMETER ID 'MXX' FIELD '0'.

      MESSAGE e005(rpudb) WITH    l_s_qt_unit-meinh
                                  l_s_qt_unit-matnr
                          RAISING error.
    ENDIF.

  ENDIF.

*                *** Lege die bestimmte Default-ME in der Ausgabe-
*                *** Tabelle als Default-ME gekennzeichnet an
  IF NOT ( l_s_qt_unit-meinh  IS  INITIAL ).

    l_s_qt_unit-flagdefqtunit = c_yes.

    APPEND l_s_qt_unit  TO  p_t_qt_units.
  ENDIF.

ENDFORM.                               " DETERMINE_DEF_QT_UNIT

*&---------------------------------------------------------------------*
*&      Form  DET_DEF_QT_UNIT_PURCHASE
*&---------------------------------------------------------------------*
*       Bestimme die Default-ME aus Einkaufssicht:
*       => Default-Bestell-ME
*----------------------------------------------------------------------*
*      -->P_S_GENERAL      allgemeine Eingabestruktur
*      -->P_S_EINA         EINA-Eintrag (EK-Info-Satz) zu Lief und Mat.
*      -->P_S_MARC_2       MARC-Eintrag zu Werk (bei int. Lief) und Mat.
*      -->P_S_MARA         MARA-Eintrag zu dem Material
*      <--P_S_QT_UNIT      Bestimmte ME zu dem Artikel mit (wenn vorh.)
*                          den Umrechnungsfaktoren
*----------------------------------------------------------------------*
FORM det_def_qt_unit_purchase
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_eina     TYPE  eina
                    p_s_marc_2   TYPE  marc
                    p_s_mara     TYPE  mara
                  CHANGING
                    p_s_qt_unit  TYPE  mdr1p_s_out_allowed_qt_unit.

  DATA: l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params.

*                *** Initialisiere die Rückgabewerte
  CLEAR: p_s_qt_unit.

*                *** Material-Nummer ist immer die gleiche
  p_s_qt_unit-matnr  =  p_s_general-matnr.

*                *** 1. Der Wert wurden von der Aufrufstelle vorgegeben
*                ***    wenn gefüllt.
  MOVE-CORRESPONDING p_s_general TO l_s_qt_units_params.

  IF NOT ( l_s_qt_units_params IS INITIAL ).
    p_s_qt_unit-meinh  =  p_s_general-defqtunit.
    p_s_qt_unit-umrez  =  p_s_general-defumrez.
    p_s_qt_unit-umren  =  p_s_general-defumren.
  ELSE.

*                *** 2. Bestimme Wert aus EK-Info-Satz,
*                ***    wenn Einkaufsinfosatz existiert ME gefüllt =>
*                ***      Default-Bestell-ME = EINA-MEINS
    IF      ( p_s_qt_unit-meinh  IS  INITIAL )
    AND NOT ( p_s_eina           IS  INITIAL ).
      p_s_qt_unit-meinh  =  p_s_eina-meins.
      p_s_qt_unit-umrez  =  p_s_eina-umrez.
      p_s_qt_unit-umren  =  p_s_eina-umren.
    ENDIF.

*                *** 3. Bei internen Lieferanten wird als nächstes
*                ***    versucht den Default-Wert aus der MARC des
*                ***    Lieferwerks als Ausgabe-ME zu bestimmen
*                *** (zu MARC des Liefer-Werks: LFA1-WERKS => MARC_2)
    IF      ( p_s_qt_unit-meinh    IS  INITIAL )
    AND     ( p_s_general-intvend  =   c_intvend )
    AND NOT ( p_s_marc_2           IS  INITIAL ).
      p_s_qt_unit-meinh  =  p_s_marc_2-ausme.
    ENDIF.

*                *** 4. Versuche es mit der Bestell-ME aus der MARA
*                ***    jedoch nur bei externen Liefranten!!!
    IF  ( p_s_qt_unit-meinh      IS  INITIAL )
    AND ( p_s_general-intvend  =   c_extvend ).
      p_s_qt_unit-meinh  =  p_s_mara-bstme.
    ENDIF.

*                *** 5. Wenn alle bisherige Bestimmungen nicht erfolg-
*                ***    reich waren, wird die Basis-ME als Default-ME
*                ***    genommen
*                ***       Default-Bestell-ME = MARA-MEINS
    IF p_s_qt_unit-meinh  IS  INITIAL.
      p_s_qt_unit-meinh  =  p_s_mara-meins.
      p_s_qt_unit-umrez  =  1.
      p_s_qt_unit-umren  =  1.
    ENDIF.
  ENDIF.

ENDFORM.                               " DET_DEF_QT_UNIT_PURCHASE

*&---------------------------------------------------------------------*
*&      Form  DET_DEF_QT_UNIT_SALE
*&---------------------------------------------------------------------*
*       Bestimme die Default-ME aus Einkaufssicht:
*       Verkaufs-ME
*----------------------------------------------------------------------*
*      -->P_S_GENERAL    allgemeine Eingabestruktur
*      -->P_S_MVKE       MVKE-Eintrag zum Eingabe-Werk
*      -->P_S_MARA       MARA-Eintrag zu dem Material
*      <--P_S_QT_UNIT    Bestimmte ME zu dem Artikel mit (wenn vorh.)
*                        den Umrechnungsfaktoren
*----------------------------------------------------------------------*
FORM det_def_qt_unit_sale
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_mvke     TYPE  mvke
                    p_s_mara     TYPE  mara
                  CHANGING
                    p_s_qt_unit  TYPE  mdr1p_s_out_allowed_qt_unit.

  DATA: l_s_maw1   LIKE maw1,
        l_s_tvkov  LIKE tvkov,
        l_success  TYPE c,
        l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params.

*                *** Initialisiere die Rückgabewerte und lokale Var.
  CLEAR: p_s_qt_unit,
         l_s_maw1,
         l_s_tvkov.

*                *** Material-Nummer ist immer die gleiche
  p_s_qt_unit-matnr  =  p_s_general-matnr.

  MOVE-CORRESPONDING p_s_general TO l_s_qt_units_params.

  IF NOT ( l_s_qt_units_params IS INITIAL ).
*                *** 1. Der Wert wurden von der Aufrufstelle vorgegeben
    p_s_qt_unit-meinh  =  p_s_general-defqtunit.
    p_s_qt_unit-umrez  =  p_s_general-defumrez.
    p_s_qt_unit-umren  =  p_s_general-defumren.
  ELSE.
*                *** 2. Bestimme aus MVKE die Default-ME, wenn nicht
*                ***    vorgegeben
*                ***      Default-Verkaufs-ME = MVKE-VRKME
    IF p_s_qt_unit-meinh  IS  INITIAL.
      p_s_qt_unit-meinh  = p_s_mvke-vrkme.
    ENDIF.

*                *** 3. Bestimme aus MAW1 unter berücksichtigung
*                ***    Des Vertriebstyps aus der TVKOV
    IF p_s_qt_unit-meinh  IS  INITIAL.
      l_success = c_no.
*                ***    - Lese die MAW1 zum Material
      PERFORM read_maw1 USING     p_s_general-matnr
                        CHANGING  l_s_maw1
                                  l_success.

*                ***    - Lese die TVKOV
      IF l_success = c_yes.
        PERFORM read_tvkov USING    p_s_general-vkorg
                                    p_s_general-vtweg
                           CHANGING l_s_tvkov
                                    l_success.
      ENDIF.

*                ***    - Bestimme die ME aus MAW1 abhängig vom VEr-
*                ***      triebstyp
      IF l_success = c_yes.
        IF l_s_tvkov-vltyp = '1'.
*                ***      Bei Filialen => Verkaufs-ME
          p_s_qt_unit-meinh  =  l_s_maw1-wvrkm.
        ELSE.
*                ***      Bei VZ (sonst) => Ausgabe-ME
          p_s_qt_unit-meinh  =  l_s_maw1-wausm.
        ENDIF.
      ENDIF.
    ENDIF.

*                *** 4. Wenn alles kein Erfolg hatte, dann bleibt nur
*                ***    noch die Basis-ME
    IF p_s_qt_unit-meinh  IS  INITIAL.
      p_s_qt_unit-meinh  =  p_s_mara-meins.
      p_s_qt_unit-umrez  =  1.
      p_s_qt_unit-umren  =  1.
    ENDIF.
  ENDIF.

ENDFORM.                               " DET_DEF_QT_UNIT_SALE

*&---------------------------------------------------------------------*
*&      Form  DETERMINE_VEN_QT_UNIT
*&---------------------------------------------------------------------*
*       Bestimme die gültigen Lieferanten-ME
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
*      -->P_S_GENERAL    allgemeine Eingabestruktur
*$@002 Anfang MWE-HW-300836
*      -->P_S_MARA       MARA-Satz
*$@002 Ende MWE-HW-300836
*      -->P_S_EINE       EINE-Eintrag (EK-Info-Satz) zu Lief und Mat.
*      -->P_S_MVKE       MVKE-Eintrag zum Eingabe-Werk
*      -->P_T_QT_UNITS   eventuell schon mit der Bestimmten Default-ME
*                        gefüllt
*      <--P_T_QT_UNITS   Ausgabewerte mit den bestimmten erlaubten
*                        Lieferanten-ME
*----------------------------------------------------------------------*
FORM determine_ven_qt_unit
                  TABLES
                    p_t_qt_units TYPE  mdr1p_t_out_allowed_qt_unit
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit
*$@002 Anfang MWE-HW-300836
                    p_s_mara     TYPE  mara
*$@002 Ende MWE-HW-300836
                    p_s_eine     TYPE  eine
                    p_s_marc_2   TYPE  marc                   " note 2081705
                    p_s_mvke     TYPE  mvke.

  DATA: l_ven_unit_group   LIKE twmeg-megru,
        l_t_qt_units       TYPE mdr1p_s_out_allowed_qt_unit
                           OCCURS 0  WITH HEADER LINE.

  CLEAR: l_ven_unit_group,
         l_t_qt_units[].

*                *** Bestimmung abhängig von der Sicht die ME-Gruppe
*                *** des Lieferanten
  CASE p_s_general-appview.

*                *** Bei der EK-Sicht
    WHEN mdr1p_c_appview_purchase.
      PERFORM det_ven_unit_gr_purchase USING    p_s_general
                                                p_s_eine
                                                p_s_marc_2     " note 2081705
                                       CHANGING l_ven_unit_group.

*                *** Bei der VK-Sicht
    WHEN mdr1p_c_appview_sale.
      PERFORM det_ven_unit_gr_sale     USING    p_s_general
                                                p_s_mvke
                                       CHANGING l_ven_unit_group.

  ENDCASE.

*                *** Bestimme alle gültige ME zum Material
  PERFORM find_valid_material_units TABLES    l_t_qt_units
*$@002 Anfang MWE-HW-300836
*$                                    USING     p_s_general-matnr.
                                    USING     p_s_general-matnr
                                              p_s_mara-meins.
*$@002 Ende MWE-HW-300836

*                *** Bestimme mit Hilfe der Definion der ME-Gruppe
*                *** und der gültigen ME des Artikels die erlaubten
*                *** ME des Lieferanten
  PERFORM det_valide_qt_units TABLES l_t_qt_units       " Menge der ME
                                     p_t_qt_units       " Rückgabe
                              USING  l_ven_unit_group   " Einschränk.
                                     c_vendor.

ENDFORM.                               " DETERMINE_VEN_QT_UNIT

*&---------------------------------------------------------------------*
*&      Form  DET_VEN_UNIT_GR_PURCHASE
*&---------------------------------------------------------------------*
*       Bestimme die ME-Gruppe zu dem Lieferant aus Einkaufssicht
*----------------------------------------------------------------------*
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_EINE          EINE-Eintrag (EK-Info-Satz) zu Lief und Mat.
*      <--P_VEN_UNIT_GROUP  Bestimme ME-Gruppe
*----------------------------------------------------------------------*
FORM det_ven_unit_gr_purchase
           USING
             p_s_general         TYPE mdr1p_s_in_allowed_qt_unit
             p_s_eine            TYPE eine
             p_s_marc_2          TYPE marc                        " note 2081705
           CHANGING
             p_ven_unit_group    LIKE twmeg-megru.

  DATA: l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params.

*                *** Initialisiere die Rückgabewerte
  CLEAR: p_ven_unit_group.

  MOVE-CORRESPONDING p_s_general TO l_s_qt_units_params.

  IF NOT ( l_s_qt_units_params IS INITIAL ).
*                *** 1. Vorgabe aus der Aufrufstelle
    p_ven_unit_group  = p_s_general-venunitgr.
  ELSE.
*                *** 2. Aus Einkaufsinfosatz, sonst
*                ***      Lief ME-Gruppe = EINE-MEGRU
* Begin note 2081705
    IF p_s_general-intvend  =   c_intvend.
      p_ven_unit_group  = p_s_marc_2-megru.
    ELSE.
* Begin note 2081705
      p_ven_unit_group  = p_s_eine-megru.         "note 2081705
    ENDIF.
  ENDIF.

ENDFORM.                               " DET_VEN_UNIT_GR_PURCHASE

*&---------------------------------------------------------------------*
*&      Form  DET_VEN_UNIT_GR_SALE
*&---------------------------------------------------------------------*
*       Bestimme die ME-Gruppe zu dem Lieferant aus VVerkaufssicht
*----------------------------------------------------------------------*
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_P_S_MVKE        MVKE-Eintrag
*      <--P_VEN_UNIT_GROUP  Bestimme ME-Gruppe
*----------------------------------------------------------------------*
FORM det_ven_unit_gr_sale
           USING
             p_s_general         TYPE  mdr1p_s_in_allowed_qt_unit
             p_s_mvke            TYPE  mvke
           CHANGING
             p_ven_unit_group    LIKE twmeg-megru.

  DATA: l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params.

*                *** Initialisiere die Rückgabewerte
  CLEAR: p_ven_unit_group.

  MOVE-CORRESPONDING p_s_general TO l_s_qt_units_params.

  IF NOT ( l_s_qt_units_params IS INITIAL ).
*                *** 1. Vorgabe aus der Aufrufstelle
    p_ven_unit_group  = p_s_general-venunitgr.
  ELSE.
*                *** 2. ME-Gruppe aus der MVKE, sonst
    p_ven_unit_group  = p_s_mvke-megru.
  ENDIF.

ENDFORM.                               " DET_VEN_UNIT_GR_SALE

*&---------------------------------------------------------------------*
*&      Form  DET_VALIDE_QT_UNITS
*&---------------------------------------------------------------------*
*       Bestimme aus einer vorgegeben Menge von ME die gültigen ME
*       mit Hilfe einer vorgegebene  ME-Gruppe und lege die Werte
*       in eine Tabelle mit bereits existierenden ME.
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS_ALL  Menge der ME
*      -->P_T_QT_UNITS      Bereits bestimmte ME
*      -->P_UNIT_GROUP      ME-Gruppe mit der gefiltert wird
*      -->P_VEN_OR_BUY      Unterscheidung zwischen Lieferant und Ab-
*                           nehmer
*      <--P_t_QT_UNITS      Bereits bestimmten ME
*                           + den gültigen ME laut ME-Gruppe
*----------------------------------------------------------------------*
FORM det_valide_qt_units
              TABLES
                p_t_qt_units_all TYPE   mdr1p_t_out_allowed_qt_unit
                p_t_qt_units     TYPE   mdr1p_t_out_allowed_qt_unit
              USING
                p_unit_group     LIKE   twmeg-megru
                p_ven_or_buy     TYPE   c.

  DATA: l_t_twmeg  LIKE twmeg
                   OCCURS 0 WITH HEADER LINE,
        l_without  TYPE c.

  CLEAR: l_t_twmeg[].
  l_without = c_no.

  IF NOT ( p_unit_group IS INITIAL ).
*                *** Bestimme die komplette Definition der ME-Gruppe
*                *** aus der Tabelle: TWMEG
    PERFORM read_twmeg_all TABLES l_t_twmeg
                           USING  p_unit_group.
  ELSE.
*                *** es gibt keine ME-Gruppe => Alle ME aus der MARA
*                *** sind gültig
    LOOP AT p_t_qt_units_all.

      CLEAR: l_t_twmeg.

      l_t_twmeg-meins = p_t_qt_units_all-meinh.
      APPEND l_t_twmeg.

    ENDLOOP.
  ENDIF.

*                *** Untersuche, ob Definition über Ein- oder Ausschluß
*                *** der ME festgelegt wurde
  READ TABLE l_t_twmeg INDEX 1.

  IF l_t_twmeg-without = c_yes.
    l_without = c_yes.
  ENDIF.

*                *** Sortier die Tabellen nach der ME aufsteigend
  SORT l_t_twmeg         BY megru ASCENDING
                            meins ASCENDING.

  SORT p_t_qt_units      BY matnr ASCENDING
                            meinh ASCENDING.

  SORT p_t_qt_units_all  BY matnr ASCENDING
                            meinh ASCENDING.

*                *** Bearbeite die Menge der vorgegebenen ME
  LOOP AT p_t_qt_units_all.
*                *** Ist ME in der Definition der ME-Gruppe enthalten?
    READ TABLE l_t_twmeg
      WITH KEY megru = p_unit_group
               meins = p_t_qt_units_all-meinh
*$@001 Anfang MWE-ENTW-46C
               BINARY SEARCH.
*$@001 Ende MWE-ENTW-46C

    IF   (    sy-subrc  =  0
          AND l_without = c_no )
      OR (    sy-subrc <> 0
          AND l_without = c_yes ).
*                *** enweder die ME existiert in der Definition der
*                ***         ME-Gruppe als eingeschlossene ME
*                *** oder    die ME existiert NICHT als ausgeschlossene
*                ***         ME in der Definition der ME-Gruppe
*                *** => gültige ME in der Tabelle Eintragen falls nicht
*                ***    vorhanden
      READ TABLE p_t_qt_units
        WITH KEY matnr = p_t_qt_units_all-matnr
                 meinh = p_t_qt_units_all-meinh
*$@001 Anfang MWE-ENTW-46C
                 BINARY SEARCH.
*$@001 Ende MWE-ENTW-46C

      IF sy-subrc = 0.
*                ***    Eintrag gefunden
*                ***    => SY-TABIX zeigt auf den entsprechenden Eintrag
*                ***       von p_t_qt_units
        IF p_ven_or_buy = c_vendor.
          p_t_qt_units-flagvenqtunit  = c_yes.
        ELSE.
          p_t_qt_units-flagbuyqtunit  = c_yes.
        ENDIF.

        p_t_qt_units-flagsiqtunit  = p_t_qt_units_all-flagsiqtunit.
        p_t_qt_units-addko         = p_t_qt_units_all-addko.
        p_t_qt_units-dimid         = p_t_qt_units_all-dimid.
        p_t_qt_units-mssie         = p_t_qt_units_all-mssie.
        p_t_qt_units-zaehl         = p_t_qt_units_all-zaehl.
        p_t_qt_units-nennr         = p_t_qt_units_all-nennr.

        MODIFY p_t_qt_units INDEX sy-tabix.

      ELSE.

        p_t_qt_units            = p_t_qt_units_all.

        IF p_ven_or_buy = c_vendor.
          p_t_qt_units-flagvenqtunit  = c_yes.
        ELSE.
          p_t_qt_units-flagbuyqtunit  = c_yes.
        ENDIF.

        APPEND p_t_qt_units.

*$@001 Anfang MWE-ENTW-46C
        SORT p_t_qt_units BY matnr ASCENDING
                             meinh ASCENDING.
*$@001 Ende MWE-ENTW-46C

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDFORM.                               " DET_VALIDE_QT_UNITS

*&---------------------------------------------------------------------*
*&      Form  DETERMINE_BUYER_QT_UNIT
*&---------------------------------------------------------------------*
*       Bestimme die gültigen Abnehmer-ME
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS  Bereits bestimmte ME
*      -->P_S_GENERAL   allgemeine Eingabestruktur
*$@002 Anfang MWE-HW-300836
*      -->P_S_MARA      MARA-Satz
*$@002 Ende MWE-HW-300836
*      -->P_S_MARC      MARC-Satz zu Werk (als Abnehmer) und Material
*      -->P_S_KNMT      KNMT-Satz
*      -->P_S_KNVV      KNVV-Satz
*      <--P_T_QT_UNITS  Zusätzlich alle gültigen Abnehmer-ME
*----------------------------------------------------------------------*
FORM determine_buyer_qt_unit
                  TABLES
                    p_t_qt_units  TYPE  mdr1p_t_out_allowed_qt_unit
                  USING
                    p_s_general   TYPE  mdr1p_s_in_allowed_qt_unit
*$@002 Anfang MWE-HW-300836
                    p_s_mara      TYPE  mara
*$@002 Ende MWE-HW-300836
                    p_s_marc      TYPE  marc
                    p_s_knmt      TYPE  knmt
                    p_s_knvv      TYPE  knvv.

  DATA: l_buyer_unit_group   LIKE twmeg-megru,
        l_t_qt_units         TYPE mdr1p_s_out_allowed_qt_unit
                                  OCCURS 0  WITH HEADER LINE.

  CLEAR: l_buyer_unit_group,
         l_t_qt_units[].

*                *** Bestimmung abhängig von der Sicht die ME-Gruppe
*                *** des Abnehmers
  CASE p_s_general-appview.

*                *** Bei der EK-Sicht
    WHEN mdr1p_c_appview_purchase.
      PERFORM det_buy_unit_gr_purchase USING    p_s_general
                                                p_s_marc
                                       CHANGING l_buyer_unit_group.

*                *** Bei der VK-Sicht
    WHEN mdr1p_c_appview_sale.
      PERFORM det_buy_unit_gr_sale     USING    p_s_general
                                                p_s_knmt
                                                p_s_knvv
                                       CHANGING l_buyer_unit_group.

  ENDCASE.

*                *** Bestimme alle gültige ME zum Material
  PERFORM find_valid_material_units TABLES    l_t_qt_units
*$@002 Anfang MWE-HW-300836
*$                                    USING     p_s_general-matnr.
                                    USING     p_s_general-matnr
                                              p_s_mara-meins.
*$@002 Ende MWE-HW-300836

*                *** Bestimme mit Hilfe der Definion der ME-Gruppe
*                *** und der gültigen ME des Artikels die erlaubten
*                *** ME des Abnehmers
  PERFORM det_valide_qt_units TABLES l_t_qt_units        " Menge der ME
                                     p_t_qt_units        " Rückgabe
                              USING  l_buyer_unit_group  " Einschränkung
                                     c_buyer.            " Abnehmer

ENDFORM.                               " DETERMINE_BUYER_QT_UNIT

*&---------------------------------------------------------------------*
*&      Form  DET_BUY_UNIT_GR_PURCHASE
*&---------------------------------------------------------------------*
*       Bestimme die ME-Gruppe zum Abnehmer aus EK-Sicht
*----------------------------------------------------------------------*
*      -->P_S_GENERAL         allgemeine Eingabestruktur
*      -->P_S_MARC            MARC-Satz zum Werk (als Abnhemer)
*      <--P_BUYER_UNIT_GROUP  Bestimme ME-Gruppe
*----------------------------------------------------------------------*
FORM det_buy_unit_gr_purchase
                  USING
                    p_s_general        TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_marc           TYPE  marc
                  CHANGING
                    p_buyer_unit_group LIKE  twmeg-megru.

  DATA: l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params.

*                *** Rückagewert initialisieren
  CLEAR: p_buyer_unit_group.

  MOVE-CORRESPONDING p_s_general TO l_s_qt_units_params.

  IF NOT ( l_s_qt_units_params IS INITIAL ).
*                *** 1. Vorgabe aus der Aufrufstelle
    p_buyer_unit_group = p_s_general-buyunitgr.
  ELSE.
*                *** 2. Bestimme die gültige Abnehmer-ME-Gruppe aus der
*                ***    MARC zum abnehmenden Werk und dem Material,
*                ***    sonst
    p_buyer_unit_group = p_s_marc-megru.
  ENDIF.

ENDFORM.                               " DET_BUY_UNIT_GR_PURCHASE

*&---------------------------------------------------------------------*
*&      Form  DET_BUY_UNIT_GR_SALE
*&---------------------------------------------------------------------*
*       Bestimme die ME-Gruppe zum Abnehmer aus VK-Sicht
*----------------------------------------------------------------------*
*      -->P_S_GENERAL           allgemeine Eingabestruktur
*      -->P_S_KNMT              KNMT-Satz zum Kunde
*      -->P_S_KNVV              KNVV-Satz zum Kunde
*      <--P_L_BUYER_UNIT_GROUP  Bestimme ME-Gruppe
*----------------------------------------------------------------------*
FORM det_buy_unit_gr_sale
                  USING
                    p_s_general        TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_knmt           TYPE  knmt
                    p_s_knvv           TYPE  knvv
                  CHANGING
                    p_buyer_unit_group LIKE  twmeg-megru.

  DATA: l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params.

*                *** Rückagewert initialisieren
  CLEAR: p_buyer_unit_group.

  MOVE-CORRESPONDING p_s_general TO l_s_qt_units_params.

  IF NOT ( l_s_qt_units_params IS INITIAL ).
*                *** 1. Vorgabe aus der Aufrufstelle
    p_buyer_unit_group = p_s_general-buyunitgr.
  ELSE.
*                *** 2. Berücksichtigung des VK-Info-Satz, wenn erlaubt
*                ***    (INFLS = 'X')
    IF NOT ( p_s_general-infls = c_no ).
      p_buyer_unit_group = p_s_knmt-megru.
    ENDIF.

    IF p_buyer_unit_group IS INITIAL.
*                *** 3. aus der KNVV, sonst (als letzte Möglichkeit)
      p_buyer_unit_group = p_s_knvv-megru.
    ENDIF.
  ENDIF.

ENDFORM.                               " DET_BUY_UNIT_GR_SALE

*&---------------------------------------------------------------------*
*&      Form  DETERMINE_ALLOWED_QT_UNIT
*&---------------------------------------------------------------------*
*       Bestimme die erlaubtnen ME
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS  Bereits bestimmten ME = Obermenge der er-
*                       laubten ME
*      -->P_S_GENERAL   allgemeine Eingabestruktur
*      -->P_S_MARA      MARA-Satz (für alle Sichten)
*      -->P_S_EINA      EINA-Satz für EK-Sicht
*      -->P_S_MVKE      MVKE-Satz für VK-Sicht
*      <--P_T_QT_UNITS  ME mit der Kennzeichnung der erlaubten ME
*----------------------------------------------------------------------*
FORM determine_allowed_qt_unit
                  TABLES
                    p_t_qt_units  TYPE  mdr1p_t_out_allowed_qt_unit
                  USING
                    p_s_general   TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_mara      TYPE  mara
                    p_s_eina      TYPE  eina
                    p_s_mvke      TYPE  mvke.

  DATA: l_other_qt_units TYPE c.

*                *** Bearbeite jede ME der Obermenge einzeln
  LOOP AT p_t_qt_units.

    l_other_qt_units = c_no.

    IF p_t_qt_units-flagdefqtunit = c_yes.
*                *** Die Default-ME ist immer auch eine erlaubte ME!!!
      p_t_qt_units-flagallqtunit  = c_yes.
    ELSE.
*                *** Bei nicht Defaul-ME muß die Möglichkeit für
*                *** Alternativ-ME überprüft werden
      PERFORM other_qt_units_possible  USING    p_s_general
                                                p_s_mara
                                                p_s_eina
                                                p_s_mvke
                                       CHANGING l_other_qt_units.
    ENDIF.

    IF l_other_qt_units = c_yes.
*                *** Bei der Möglichkeit von Alternativ-ME,
*                *** muß jede erlaubte ME eine gültige
*                ***   Liefaranten- und Abnehmer-ME sein
      IF  p_t_qt_units-flagvenqtunit = c_yes
      AND p_t_qt_units-flagbuyqtunit = c_yes.

        p_t_qt_units-flagallqtunit  = c_yes.

      ENDIF.

    ENDIF.

    IF p_t_qt_units-flagallqtunit  = c_yes.
      MODIFY p_t_qt_units.
    ENDIF.

  ENDLOOP.

ENDFORM.                               " DETERMINE_ALLOWED_QT_UNIT

*&---------------------------------------------------------------------*
*&      Form  OTHER_QT_UNITS_POSSIBLE
*&---------------------------------------------------------------------*
*       Bestimme, ob mehr als eine erlaubte ME zulässig sind
*----------------------------------------------------------------------*
*      -->P_S_GENERAL      allgemeine Eingabestruktur
*      -->P_S_MARA         MARA-Satz (für alle Sichten)
*      -->P_S_EINA         EINA-Satz für EK-Sicht
*      -->P_S_MVKE         MVKE-Satz für VK-Sicht
*      <--P_other_possible Kennzeichen, ob weitere ME zulässig sind
*----------------------------------------------------------------------*
FORM other_qt_units_possible
                  USING
                    p_s_general      TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_mara         TYPE  mara
                    p_s_eina         TYPE  eina
                    p_s_mvke         TYPE  mvke
                  CHANGING
                    p_other_possible TYPE c.

  DATA: l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params.

*                *** Default-Belegung für Rückgabewert
  p_other_possible = c_no.

  MOVE-CORRESPONDING p_s_general TO l_s_qt_units_params.

*                *** Bestimmung abhängig von der Sicht das Kennzeichen
  CASE p_s_general-appview.

*                *** Bei der EK-Sicht
    WHEN mdr1p_c_appview_purchase.

      IF NOT ( l_s_qt_units_params IS INITIAL ).
*                *** Vorgabe von der Aufrufstelle berücksichtigen
        IF NOT ( p_s_general-vabme IS INITIAL ).
          p_other_possible = c_yes.
        ENDIF.
      ELSE.
        IF NOT ( p_s_eina IS INITIAL ).
*                *** Existier EK-Infosatz => Kennzeichen aus EINE
          IF NOT ( p_s_eina-vabme IS INITIAL ).
            p_other_possible = c_yes.
          ENDIF.
        ELSE.
*                *** sonst => Kennzeichen aus der MARA
          IF NOT ( p_s_mara-vabme IS INITIAL ).
            p_other_possible = c_yes.
          ENDIF.
        ENDIF.
      ENDIF.

*                *** Bei der VK-Sicht
    WHEN mdr1p_c_appview_sale.

      IF NOT ( l_s_qt_units_params IS INITIAL ).
*                *** Vorgabe von der Aufrufstelle berücksichtigen
        IF p_s_general-vavme IS INITIAL.
          p_other_possible = c_yes.
        ENDIF.
      ELSE.
        IF NOT ( p_s_mvke IS INITIAL ).
*                *** Existiert MVKE-Satz => Kennzeichen aus MVKE
          IF p_s_mvke-vavme IS INITIAL.
            p_other_possible = c_yes.
          ELSEIF p_s_general-MSR_VAR_SUOM = c_msr_var.
            p_other_possible = c_yes.
          ENDIF.
        ELSE.
*                *** sonst => Immer variabel
          p_other_possible = c_yes.
        ENDIF.
      ENDIF.

*                *** Bei der Aufteiler-Sicht
    WHEN mdr1p_c_appview_alloc.
*                *** in der Aufteiler_sicht sind alle MARM-Einträge
*                *** gültig
      p_other_possible = c_yes.

  ENDCASE.

ENDFORM.                               " OTHER_QT_UNITS_POSSIBLE

*
* 
