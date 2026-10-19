*----------------------------------------------------------------------*
***INCLUDE LMDR1F11 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       06.02.99  99A  mwe         Grundversion
*- @001  01.12.99  46C  mwe         Berücksichtigung von Konsignations-
*-                                  Infosätze
*-                                  Korrektur zu Hinweis: 186918
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_U11
*&---------------------------------------------------------------------*
*       Eingabeprüfung zu FB: F4_ALLOWED_QUANTITY_UNIT
*----------------------------------------------------------------------*
*      -->P_I_S_GENERAL  allgemeine Eingabestruktur
*----------------------------------------------------------------------*
FORM check_input_u11
                  USING
                    p_s_general  TYPE  mdr1p_s_in_allowed_qt_unit
                    p_dialog     TYPE  c.

  DATA: l_s_qt_units_params  TYPE  mdr1p_s_qt_units_params.

  CLEAR: l_s_qt_units_params.

*                *** 1. Es muß mindestens eine Prüfung oder eine Be-
*                ***    stimmung einer ME durchgeführt werden!!!
  IF  NOT ( p_s_general-flagdefqtunit = c_yes )
  AND NOT ( p_s_general-flagvenqtunit = c_yes )
  AND NOT ( p_s_general-flagbuyqtunit = c_yes )
  AND NOT ( p_s_general-flagallqtunit = c_yes ).

    IF p_dialog = c_yes.
      MESSAGE i002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                           RAISING bad_params.
    ELSE.
      MESSAGE e002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                           RAISING bad_params.
    ENDIF.
  ENDIF.

*                *** 2. Die Unternehmenssicht muß mit einem korrekten
*                ***    Wert gefüllt sein.
  IF  NOT ( p_s_general-appview  =  mdr1p_c_appview_purchase )
  AND NOT ( p_s_general-appview  =  mdr1p_c_appview_sale     )
  AND NOT ( p_s_general-appview  =  mdr1p_c_appview_alloc    )
  AND NOT ( p_s_general-appview  =  mdr1p_c_appview_customer ).

    IF p_dialog = c_yes.
      MESSAGE i002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                           RAISING bad_params.
    ELSE.
      MESSAGE e002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                           RAISING bad_params.
    ENDIF.
  ENDIF.

*                *** 3. Material muß immer existieren!!!
  IF p_s_general-matnr IS INITIAL.
    IF p_dialog = c_yes.
      MESSAGE i002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                           RAISING bad_params.
    ELSE.
      MESSAGE e002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                           RAISING bad_params.
    ENDIF.
  ENDIF.

*                *** 4. Wenn die Parameter für die Bestimmung der
*                ***    erlaubten ME durch die Aufrufstelle vor-
*                ***    gegeben werden:
  MOVE-CORRESPONDING p_s_general TO l_s_qt_units_params.

  IF NOT ( l_s_qt_units_params   IS INITIAL ).
*                ***    Muß bei Bestimmung der Default-ME und erlaubter
*                ***    ME die Default-ME angegeben sein!
    IF  (   p_s_general-flagdefqtunit = c_yes
         OR p_s_general-flagallqtunit = c_yes )
    AND ( p_s_general-flagdefqtunit IS INITIAL ).
      IF p_dialog = c_yes.
        MESSAGE i002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                             RAISING bad_params.
      ELSE.
        MESSAGE e002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                             RAISING bad_params.
      ENDIF.
    ENDIF.
*                ***    Muß bei Bestimmung der erlaubten Lieferanten-ME
*                ***    die ME-Gruppe des Lieferanten gefüllt sein!
    IF  ( p_s_general-flagvenqtunit =  c_yes )
    AND ( p_s_general-venunitgr     IS INITIAL ).
      IF p_dialog = c_yes.
        MESSAGE i002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                             RAISING bad_params.
      ELSE.
        MESSAGE e002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                             RAISING bad_params.
      ENDIF.
    ENDIF.
*                ***    Muß bei Bestimmung der erlaubten Abnehmer-ME
*                ***    die ME-Gruppe des Abnehmers gefüllt sein!
    IF  ( p_s_general-flagbuyqtunit =  c_yes )
    AND ( p_s_general-buyunitgr     IS INITIAL ).
      IF p_dialog = c_yes.
        MESSAGE i002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                             RAISING bad_params.
      ELSE.
        MESSAGE e002(rpugen) WITH    'F4_ALLOWED_QUANTITY_UNIT'
                             RAISING bad_params.
      ENDIF.
    ENDIF.

  ENDIF.

ENDFORM.                               " CHECK_INPUT_U11

*&---------------------------------------------------------------------*
*&      Form  READ_DATA_U11
*&---------------------------------------------------------------------*
*       Bestimme je nach Sicht und Funktion die entsprechenden daten
*       von der DB
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      <--P_S_GENERAL  allgemeine Eingabestruktur mit Belegung der Kenn-
*                      zeichnung interner und externer Lieferant und
*                      Kunde, wenn notwendig!!!
*      <--P_S_MARA
*      <--P_S_EINA
*      <--P_S_EINE
*      <--P_S_MARC
*      <--P_S_MARC_2
*      <--P_S_MVKE
*      <--P_S_KNMT
*      <--P_S_KNVV
*----------------------------------------------------------------------*
FORM read_data_u11
                   USING
                     p_dialog      TYPE  c
                   CHANGING
                     p_s_general   TYPE  mdr1p_s_in_allowed_qt_unit
                     p_s_mara      TYPE  mara
                     p_s_eina      TYPE  eina
                     p_s_eine      TYPE  eine
                     p_s_marc      TYPE  marc
                     p_s_marc_2    TYPE  marc
                     p_s_mvke      TYPE  mvke
                     p_s_knmt      TYPE  knmt
                     p_s_knvv      TYPE  knvv.

*                ***   Bestimme die Daten, die nur von der Funktion
*                ***   abhängen
*                ***   - bei der Bestimmung der Default-ME, bei der
*                ***     Bestimmung der erlaubten Lief-ME und bei
*                ***     der Bestimmung der erlaubten log. ME:
*                ***     => MARA lesen (muß existieren)
  IF p_s_general-flagdefqtunit  =  c_yes
  OR p_s_general-flagvenqtunit  =  c_yes
  OR p_s_general-flagallqtunit  =  c_yes.
    IF p_dialog = c_yes.
      PERFORM read_mara_single_f4 USING    p_s_general-matnr
                                  CHANGING p_s_mara.
    ELSE.
      PERFORM read_mara_single USING    p_s_general-matnr
                               CHANGING p_s_mara.
    ENDIF.
  ENDIF.

*                ***   Bestimme die Daten, die nur von der Sicht und
*                ***   der Funktion abhängen
*                ***   => Unterscheide zuerst zwischen den Sichten
  CASE p_s_general-appview.

*                *** - Bei der EK-Sicht:
    WHEN mdr1p_c_appview_purchase.
      PERFORM read_data_purch_u11 USING    p_s_mara
                                           p_dialog
                                  CHANGING p_s_general
                                           p_s_eina
                                           p_s_eine
                                           p_s_marc
                                           p_s_marc_2.

*                *** - Bei der VK-Sicht:
    WHEN mdr1p_c_appview_sale.
      PERFORM read_data_sales_u11 USING    p_s_general
                                  CHANGING p_s_mvke
                                           p_s_knmt
                                           p_s_knvv.

  ENDCASE.

ENDFORM.                               " READ_DATA_U11

*&---------------------------------------------------------------------*
*&      Form  ALLOWED_QTUNITS_WITHOUT_DIALOG
*&---------------------------------------------------------------------*
*       Versorge die Rückgabetabelle mit bestimmten Werten, die von
*       der Aufrufstelle verlangt werden.
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS   Bestimmte Mengeneinheiten
*      -->P_I_S_GENERAL  ursprüngliche Eingabe-Werte (unverändert!!!)
*      <--P_T_QT_UNITS   gefüllte Rückgabe-Tabelle mit den angeforderten
*                        ME
*----------------------------------------------------------------------*
FORM allowed_qtunits_without_dialog
                   TABLES
                     p_t_qt_units     TYPE  mdr1p_t_out_allowed_qt_unit
                     p_o_t_qt_units   TYPE  mdr1p_t_out_allowed_qt_unit
                   USING
                     p_s_general      TYPE  mdr1p_s_in_allowed_qt_unit.

  CLEAR: p_o_t_qt_units[].

  LOOP AT p_t_qt_units.

    CLEAR: p_o_t_qt_units.

    IF  p_s_general-flagdefqtunit  = c_yes
    AND p_t_qt_units-flagdefqtunit = c_yes.
      MOVE-CORRESPONDING p_t_qt_units TO p_o_t_qt_units.
    ENDIF.

    IF  p_s_general-flagvenqtunit  = c_yes
    AND p_t_qt_units-flagvenqtunit = c_yes.
      MOVE-CORRESPONDING p_t_qt_units TO p_o_t_qt_units.
    ENDIF.

    IF  p_s_general-flagbuyqtunit  = c_yes
    AND p_t_qt_units-flagbuyqtunit = c_yes.
      MOVE-CORRESPONDING p_t_qt_units TO p_o_t_qt_units.
    ENDIF.

    IF  p_s_general-flagallqtunit  = c_yes
    AND p_t_qt_units-flagallqtunit = c_yes.
      MOVE-CORRESPONDING p_t_qt_units TO p_o_t_qt_units.
    ENDIF.

    IF NOT ( p_o_t_qt_units IS INITIAL ).
      APPEND p_o_t_qt_units.
    ENDIF.

  ENDLOOP.

ENDFORM.                               " ALLOWED_QTUNITS_WITHOUT_DIALOG

*&---------------------------------------------------------------------*
*&      Form  read_data_purch_u11
*&---------------------------------------------------------------------*
*       Bestimme die Daten für die Einkaufssicht.
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      -->P_S_MARA     Bestimmter MARA-Eintrag
*      <--P_S_GENERAL  allgemeine Eingabestruktur mit Belegung der Kenn-
*                      zeichnung interner und externer Lieferant
*      <--P_S_EINA
*      <--P_S_EINE
*      <--P_S_MARC
*      <--P_S_MARC_2
*----------------------------------------------------------------------*
FORM read_data_purch_u11
                   USING
                     p_s_mara      TYPE  mara
                     p_dialog      TYPE  c
                   CHANGING
                     p_s_general   TYPE  mdr1p_s_in_allowed_qt_unit
                     p_s_eina      TYPE  eina
                     p_s_eine      TYPE  eine
                     p_s_marc      TYPE  marc
                     p_s_marc_2    TYPE  marc.

  DATA: l_s_lfa1  LIKE  lfa1,
        l_ekorg   LIKE  eine-ekorg.

  CLEAR: l_s_lfa1,
         l_ekorg.

*                *** - Wird der EK-Info-Satz bestimmt
  IF p_s_general-flagdefqtunit  =  c_yes   " bei Default-Bestell-ME
  OR p_s_general-flagvenqtunit  =  c_yes   " bei erlaubten Lief-ME
  OR p_s_general-flagallqtunit  =  c_yes.  " bei erlaubten log. ME

    IF NOT ( p_s_general-lifnr IS INITIAL ).
*                *** Bestimme EK-Info nur wenn Lief bekannt!!!
      l_ekorg  =  p_s_general-ekorg.

      IF         l_ekorg          IS INITIAL
      AND NOT ( p_s_general-werks IS INITIAL ).
*                *** - EKORG zum Werk (= Abnehmer) bestimmen,
*                ***   wenn EKORG nicht vorgegeben und wenn es eine
*                ***   eindeutige zum Werk gibt
*                ***   das Ergebnis wird in der Eingabe-Struktur gemerkt
        PERFORM read_ekorg_single USING     p_s_general-werks
                                  CHANGING  l_ekorg.
      ENDIF.

      IF NOT ( l_ekorg IS INITIAL ).
        PERFORM read_eina_eine  USING     p_s_general-lifnr
                                          p_s_general-ekorg  " <> LEER
                                          p_s_general-werks
                                          p_s_general-matnr
                                          p_s_general-infnr
                                          p_s_mara-satnr
                                          p_s_mara-attyp
*$@001 Anfang MWE-HW-186918
                                          p_s_general-pstyp
*$@001 Ende MWE-HW-186918
                                          space
                                          space
                                CHANGING  p_s_eina
                                          p_s_eine.
      ENDIF.
    ENDIF.
  ENDIF.

*                *** - Wird der MARC-Satz zum Abnehmer-Werk gelesen
  IF p_s_general-flagbuyqtunit  =  c_yes   " bei erlaubten Abnehmer-ME
  OR p_s_general-flagallqtunit  =  c_yes.  " bei erlaubten log. ME

    IF NOT ( p_s_general-werks IS INITIAL ).
*                ***   Lese nur, wenn Werk gefüllt!!!
      PERFORM read_marc_single  USING    p_s_general-matnr
                                         p_s_general-werks
                                CHANGING p_s_marc.
    ENDIF.

  ENDIF.

*                *** - Bei internen Lieferanten (UBs) wird der
*                ***   der Marc-Satz zum Lieferwerk gelesen
  IF p_s_general-flagdefqtunit  =  c_yes   " bei Default-Bestell-ME
  OR p_s_general-flagallqtunit  =  c_yes.  " bei erlaubten log. ME

*                ***    Unteruche zuerst, ob interner Lieferant vor-
*                ***    liegt => Lese LFA1
    IF NOT ( p_s_general-lifnr IS INITIAL ).
*                ***    Lese nur, wenn Lieferant gefüllt!!!
      IF p_dialog = c_yes.
        PERFORM read_lfa1_single_f4  USING     p_s_general-lifnr
                                     CHANGING  l_s_lfa1.
      ELSE.
        PERFORM read_lfa1_single  USING     p_s_general-lifnr
                                  CHANGING  l_s_lfa1.
      ENDIF.
    ELSE.
*                ***    Lieferant nicht bekannt (z.B.: zu einem VZ gibt
*                ***    es keinen Kreditoren-Satamm!!)
      l_s_lfa1-werks = p_s_general-werks_kred.
    ENDIF.

    IF NOT ( l_s_lfa1-werks IS INITIAL ).
*                ***     Lese nur bei internen Lieferanten
      PERFORM read_marc_single  USING    p_s_general-matnr
                                         l_s_lfa1-werks
                                CHANGING p_s_marc_2.
*                ***     Setzte zusätzlich noch Kennzeichen interner
*                ***     Lieferant
      p_s_general-intvend = c_intvend. " = 'I'
    ELSE.
      p_s_general-intvend = c_extvend. " = 'E'
    ENDIF.
  ENDIF.

ENDFORM.                               " read_data_purch_u11

*&---------------------------------------------------------------------*
*&      Form  read_data_sales_u11
*&---------------------------------------------------------------------*
*       Bestimme die Daten für die Verkaufssicht
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  allgemeine Eingabestruktur
*      <--P_S_GENERAL  allgemeine Eingabestruktur mit Belegung der Kenn-
*                      zeichnung interner und externer Kunden.
*      <--P_S_MVKE
*      <--P_S_KNMT
*      <--P_S_KNVV
*----------------------------------------------------------------------*
FORM read_data_sales_u11
                   USING
                     p_s_general   TYPE  mdr1p_s_in_allowed_qt_unit
                   CHANGING
                     p_s_mvke      TYPE  mvke
                     p_s_knmt      TYPE  knmt
                     p_s_knvv      TYPE  knvv.

*                *** - Der KNMT-Satz wird gelesen:
  IF p_s_general-flagbuyqtunit  =  c_yes   " bei erlaubteb Abnehmer-ME
  OR p_s_general-flagallqtunit  =  c_yes.  " bei erlaubten log. ME
*                ***   Lese KNMT nur, wenn der Eintrag berücksichtigt
*                ***   werden soll (INFLS = 'X')
*                ***   und wenn Kunde gefüllt ist!!!
    IF  NOT ( p_s_general-infls =  c_no )
    AND NOT ( p_s_general-kunnr IS INITIAL ).

      PERFORM read_knmt_single  USING    p_s_general-kunnr
                                         p_s_general-vkorg
                                         p_s_general-vtweg
                                         p_s_general-spart
                                         p_s_general-matnr
                                CHANGING p_s_knmt.
    ENDIF.
  ENDIF.

*                *** - Wird der MVKE-Satz gelesen
  IF p_s_general-flagdefqtunit  =  c_yes   " bei Default-Bestell-ME
  OR p_s_general-flagvenqtunit  =  c_yes   " bei erlaubten
                                       "Lieferanten-ME
  OR p_s_general-flagallqtunit  =  c_yes.  " bei erlaubten log. ME
    PERFORM read_mvke_single USING     p_s_general-matnr
                                       p_s_general-vkorg
                                       p_s_general-vtweg
                             CHANGING  p_s_mvke.
  ENDIF.

*                *** - Wird der KNVV-Satz gelesen
  IF p_s_general-flagbuyqtunit  =  c_yes   " bei erlaubter Abnehmer_ME
  OR p_s_general-flagallqtunit  =  c_yes.  " bei erlaubten log. ME
*                ***   Lese KNVV nur bei defüllten Kunden
    IF NOT ( p_s_general-kunnr IS INITIAL ).
      PERFORM read_knvv_single USING     p_s_general-kunnr
                                         p_s_general-vkorg
                                         p_s_general-vtweg
                                         p_s_general-spart
                               CHANGING  p_s_knvv.
    ENDIF.
  ENDIF.

ENDFORM.                               " read_data_sales_u11

*
* 
