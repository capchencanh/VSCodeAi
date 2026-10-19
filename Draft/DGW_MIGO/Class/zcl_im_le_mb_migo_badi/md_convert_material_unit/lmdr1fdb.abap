*----------------------------------------------------------------------*
***INCLUDE LMDR1FDB .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.01.99  99A  mwe         Grundversion
*- @001  28.06.99  99B  mwe         MARC-Sätze bei Herstellerteile
*-                                  korrekt bestimmen
*-                                  => Hinweis 159591 einbauen
*- @002  08.11.99  46C  mwe         Der User-Exit
*-                                  userexit_cust_material_read
*-                                  zur individuellen Bestimmung
*-                                  der Kundennummer wird beim
*-                                  Lesen der KNMT nicht berücksichtigt
*-                                  => Hinweis 182741 einbauen
*- @003  15.11.99  46C  mwe         - Performnaceverbesserung bei READ
*-                                    TABLE mit BINARY SEARCH
*- @004  01.12.99  46C  mwe         Berücksichtigung von Konsignations-
*-                                  Infosätze
*-                                  Korrektur zu Hinweis: 186918
*- @005  02.03.00  46C  mwe         Korrekten MARC-Satz zu
*-                                  Wertartikeln bestimmen
*-                                  Korrektur zu Hinweis: 204696
*- @007  04.05.00  46C  mwe         Basis-ME bei Material (Standard)
*-                                  nicht in der MARM eingetragen
*-                                  Korrektur zu Hinweis: 300836
*- @008  19.04.01  470  mwe         Unicode-Änderungen
*-                                  - Parameter typisieren
*-                                  - entfernen von veraltertem Codeing
*- @009  05.10.01  470  mbi         Realisierung SMAD-Punkte
*-                                  - Verbesserung der Rundungs-
*-                                    Simulation
*-                                    (Marke: #mbi 4.70 RoundSimu )
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  READ_MARM_SINGLE
*&---------------------------------------------------------------------*
*       Lese genau einen Eintrag in der MARM zu einer ME
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_S_qt_unit  Material, ME
*$@007 Anfang MWE-HW-300836
*        >P_MEINS      Basis-ME des Materials
*$@007 Ende MWE-HW-300836
*      <--P_S_qt_unit  Material, ME, und Umrechnungsfaktoren aus MARM
*----------------------------------------------------------------------*
FORM read_marm_single
*$@007 Anfang MWE-HW-300836
                  USING
                    p_meins      LIKE mara-meins
*$@007 Ende MWE-HW-300836
                  CHANGING
                    p_s_qt_unit  TYPE mdr1p_s_out_allowed_qt_unit.

  DATA: l_t_qt_units TYPE mdr1p_s_out_allowed_qt_unit
                     OCCURS 0 WITH HEADER LINE.

*                *** Lese gleich alle ME zu dem Artikel
  PERFORM read_marm_all TABLES l_t_qt_units
*$@007 Anfang MWE-HW-300836
*$                        USING  p_s_qt_unit-matnr.
                        USING  p_s_qt_unit-matnr
                               p_meins.
*$@007 Ende MWE-HW-300836

*                *** Suche Eintrag zu der gewünschten ME
  READ TABLE l_t_qt_units WITH KEY matnr = p_s_qt_unit-matnr
                                   meinh = p_s_qt_unit-meinh.

  IF sy-subrc = 0.
    p_s_qt_unit = l_t_qt_units.
  ELSE.
*                *** Entscheidung über Fehler trifft die Aufrufstelle!!
    CLEAR: p_s_qt_unit-umrez,
           p_s_qt_unit-umren.
  ENDIF.

ENDFORM.                               " READ_MARM_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_MARM_ALL
*&---------------------------------------------------------------------*
*       Lese die Tabelle MARM zu einem Material, wenn nichts gefunden
*       dann lese die Basis-ME aus der MARA
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_MATNR        Material
*$@007 Anfang MWE-HW-300836
*        >P_MEINS        Basis-ME des Materials
*$@007 Ende MWE-HW-300836
*      <--P_T_qt_units   gültige ME mit den Umrechnungsfaktoren zu
*                        dem Material aus der MARM
*----------------------------------------------------------------------*
FORM read_marm_all TABLES
                     p_t_qt_units   TYPE   mdr1p_t_out_allowed_qt_unit
                   USING
*$@007 Anfang MWE-HW-300836
*$                     p_matnr        LIKE   mara-matnr.
                     p_matnr        LIKE   mara-matnr
                     p_meins        LIKE   mara-meins.
*$@007 Ende MWE-HW-300836

  DATA: l_t_marm    LIKE   marm
                    OCCURS 0     WITH HEADER LINE.

  CLEAR:   p_t_qt_units[],
           l_t_marm[].

  CALL FUNCTION 'MARM_GENERIC_READ_WITH_MATNR'
    EXPORTING
*     KZRFB         = ' '
      matnr         = p_matnr
    TABLES
      marm_tab      = l_t_marm
*     MEINH         =
    EXCEPTIONS
      wrong_call    = 1
      not_found     = 2
      error_message = 98
      OTHERS        = 99.

  IF sy-subrc = 0.
*                *** Fülle mit l_t_marm die Rückgabe-Tabelle!!!
* Begin note 2296821
* We have to ensure that base unit is added first to the list.
    READ TABLE l_t_marm  WITH KEY meinh = p_meins.
    IF sy-subrc <> 0.
      MOVE-CORRESPONDING  l_t_marm TO p_t_qt_units.
      APPEND p_t_qt_units.
    ELSE.
      p_t_qt_units-matnr = p_matnr.
      p_t_qt_units-meinh = p_meins.
      p_t_qt_units-umrez = 1.
      p_t_qt_units-umren = 1.
      APPEND p_t_qt_units.
    ENDIF.
* End note 2296821
    LOOP AT l_t_marm.
      IF l_t_marm-meinh <> p_meins.       " note 2296821
        CLEAR: p_t_qt_units.

        MOVE-CORRESPONDING  l_t_marm TO p_t_qt_units.
        APPEND  p_t_qt_units.               " note 2296821
      ENDIF.
    ENDLOOP.

*$@007 Anfang MWE-HW-300836
*$  ELSE.
*$*                *** Existiert kein Eintrag in der MARM muß mindestens
*$*                *** sie Basis-ME als gültige ME des Artikels zurück-
*$*                *** geliefert werden!!!
*$    PERFORM read_mara_single USING    p_matnr
*$                             CHANGING l_s_mara.
*$    IF l_s_mara IS INITIAL.
*$*                *** => FEHLER!!!
*$      MESSAGE e002(rpudb) WITH    p_matnr
*$                          RAISING error.
*$    ELSE.
*$
*$      CLEAR: p_t_qt_units.
*$      p_t_qt_units-matnr = p_matnr.
*$      p_t_qt_units-meinh = l_s_mara-meins.
*$      p_t_qt_units-umrez = 1.
*$      p_t_qt_units-umren = 1.
*$      APPEND p_t_qt_units.
*$    ENDIF.
*                *** Prüfe, ob die Basis-ME auch in der MARM eingetragen
*                *** ist
* Begin note 2296821
*    READ TABLE  p_t_qt_units
*      WITH KEY  meinh = p_meins
*                TRANSPORTING NO FIELDS.
*
*  ENDIF.
*
*  IF sy-subrc <> 0.
**                *** Die Basis-ME muß immer in der Tabelle eingetragen
**                *** sein
*    CLEAR: sy-subrc,
*           p_t_qt_units.
*
*    p_t_qt_units-matnr = p_matnr.
*    p_t_qt_units-meinh = p_meins.
*    p_t_qt_units-umrez = 1.
*    p_t_qt_units-umren = 1.
*    APPEND p_t_qt_units.
*
* End note 2296821
  ENDIF.

*$@007 Ende MWE-HW-300836

ENDFORM.                               " READ_MARM_ALL

*&---------------------------------------------------------------------*
*&      Form  READ_TWMEG_ALL
*&---------------------------------------------------------------------*
*       Lese die TWMEG zu einer vorgegebenen ME
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_VEN_UNIT_GROUP   vorgegeben ME-Grupppe
*      <--P_T_TWMEG          komplette Definition der ME-Gruppe aus der
*                            TWMEG
*----------------------------------------------------------------------*
FORM read_twmeg_all TABLES
                      p_t_twmeg         STRUCTURE  twmeg
                    USING
                      p_ven_unit_group  LIKE       twmeg-megru.

* ??? => soll durch entsprechende FB-Aufrufe gelöst werden

  STATICS: s_t_twmeg   LIKE   twmeg
                       OCCURS 0     WITH HEADER LINE.

  CLEAR:   p_t_twmeg.

*                *** Suche zuerst in der lokalen Tabelle suchen
  LOOP AT s_t_twmeg
    WHERE megru = p_ven_unit_group.

    APPEND s_t_twmeg  TO  p_t_twmeg.

  ENDLOOP.

  IF sy-subrc <> 0.
*                *** Kein Eintrag gefunden => Lese direkt auf der DB
    SELECT      *
          FROM  twmeg
    INTO TABLE  p_t_twmeg
         WHERE  megru       = p_ven_unit_group.

*                *** Gelesene Daten an Puffer anhängen
    APPEND LINES OF p_t_twmeg  TO  s_t_twmeg.
  ENDIF.

  IF sy-subrc <> 0.
*                *** Existiert kein Eintrag in der TWMEG
*                *** => FEHLER!!!
    MESSAGE e001(rpudb)  WITH    p_ven_unit_group
                         RAISING error.
  ENDIF.

ENDFORM.                               " READ_TWMEG_ALL

*&---------------------------------------------------------------------*
*&      Form  READ_MAW1
*&---------------------------------------------------------------------*
*       Lese die Vorschlagswerte zu einem Artikel.
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_MATNR      Material-Nummer
*      <--P_S_MAW1     Gelesener Eintrag aus der MAW1 zum Material
*      <--P_SUCCESS    Bei erfolgreichem Lesen ist dieses Flag auf 'X'
*                      = C_YES gesetzt
*----------------------------------------------------------------------*
FORM read_maw1 USING
                 p_matnr     LIKE  mara-matnr
               CHANGING
                 p_s_maw1    LIKE  maw1
                 p_success   TYPE  c.

  CLEAR: p_s_maw1.

  CALL FUNCTION 'MAW1_SINGLE_READ'
    EXPORTING
*     KZRFB         = ' ' " => kein Puffer-Refresh
*     MAXTZ         = 0    " => Puffer unendlich!!
      matnr         = p_matnr
    IMPORTING
      wmaw1         = p_s_maw1
    EXCEPTIONS
      wrong_call    = 1
      not_found     = 2
      error_message = 98  " Ausnahme bei Meldungen
      OTHERS        = 99.

  IF sy-subrc = 0.
    p_success = c_yes.
  ELSE.
    p_success = c_no.
    sy-subrc  = 0.
    CLEAR: p_s_maw1.
  ENDIF.

ENDFORM.                                                    " READ_MAW1

*&---------------------------------------------------------------------*
*&      Form  READ_TVKOV
*&---------------------------------------------------------------------*
*       Lese den TVKOV-Eintrag zu einer Vertriebslinie und VK-Organ.
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_S_VKORG   VK-Organisation
*      -->P_S_VTWEG   Vertrieblinie
*      <--P_S_TVKOV   Gelesener
*      <--P_SUCCESS   Bei erfolgreichem Lesen ist dieses Flag auf 'X'
*                     = C_YES gesetzt
*----------------------------------------------------------------------*
FORM read_tvkov USING
                  p_vkorg    LIKE  tvkov-vkorg
                  p_vtweg    LIKE  tvkov-vtweg
                CHANGING
                  p_s_tvkov  LIKE  tvkov
                  p_success  TYPE  c.

  CLEAR: p_s_tvkov.

  IF NOT ( p_vkorg IS INITIAL )
  OR NOT ( p_vtweg IS INITIAL ).

    CALL FUNCTION 'TVKOV_SINGLE_READ'
      EXPORTING
*       KZRFB         = ' ' " => Kein Puffer-Refresh
        tvkov_vkorg   = p_vkorg
        tvkov_vtweg   = p_vtweg
      IMPORTING
        wtvkov        = p_s_tvkov
      EXCEPTIONS
        not_found     = 1
        error_message = 98 " Ausnahme bei Meldungen
        OTHERS        = 99.

    IF sy-subrc = 0.
      p_success = c_yes.
    ELSE.
      p_success = c_no.
      sy-subrc  = 0.
      CLEAR: p_s_tvkov.
    ENDIF.
  ELSE.
    p_success = c_no.
    CLEAR: p_s_tvkov.
  ENDIF.

ENDFORM.                               " READ_TVKOV

*&---------------------------------------------------------------------*
*&      Form  READ_MARA_SINGLE
*&---------------------------------------------------------------------*
*       Lese die MARA-Daten zu einem Artikel mit Hilfe des FB:
*       MATERIAL_READ
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_MATNR     Material-Nummer
*      <--P_S_MARA    bestimmter MARA-Eintrag
*----------------------------------------------------------------------*
FORM read_mara_single
                  USING
                    VALUE(p_matnr)  LIKE  mara-matnr
                  CHANGING
                    p_s_mara        TYPE  mara.

* Anfang MWE-HPR-HW-318728
*  DATA: l_mtcom LIKE mtcom,
*        l_mtcor LIKE mtcor,
*        BEGIN OF l_t_void OCCURS 0,
*          dum TYPE c,
*        END OF l_t_void.
*
*  CLEAR: p_s_mara.
*
*  l_mtcom-kenng = 'MARA'.
*  l_mtcom-matnr = p_matnr.
*  l_mtcom-spras = sy-langu.
*  l_mtcom-kzspr = c_nein.
*
*  CLEAR:  sy-msgid.
*
*  CALL FUNCTION 'MATERIAL_READ'
*       EXPORTING
*            schluessel           = l_mtcom
*       IMPORTING
*            matdaten             = p_s_mara
*            return               = l_mtcor
**           MATPER               =
*       TABLES
*            seqmat01             = l_t_void
*       EXCEPTIONS
*            account_not_found    = 1
*            batch_not_found      = 2
*            forecast_not_found   = 3
*            lock_on_account      = 4
*            lock_on_material     = 5
*            lock_on_plant        = 6
*            lock_on_sales        = 7
*            lock_on_sloc         = 8
*            lock_on_batch        = 9
*            lock_system_error    = 10
*            material_not_found   = 11
*            plant_not_found      = 12
*            sales_not_found      = 13
*            sloc_not_found       = 14
*            slocnumber_not_found = 15
*            sloctype_not_found   = 16
*            text_not_found       = 17
*            unit_not_found       = 18
*            invalid_mch1_matnr   = 19
*            invalid_mtcom        = 20
*            sa_material          = 21
*            wv_material          = 22
*            waart_error          = 23
*            error_message        = 98  " Ausnahme bei Meldungen
*            OTHERS               = 99
*            .
  CLEAR: p_s_mara.

  CLEAR:  sy-msgid.

  CALL FUNCTION 'MARA_SINGLE_READ'
    EXPORTING
*     KZRFB             = ' '
*     MAXTZ             = 0
      matnr             = p_matnr
*     SPERRMODUS        = ' '
*     STD_SPERRMODUS    = ' '
*     OUTPUT_NO_MESSAGE =
    IMPORTING
      wmara             = p_s_mara
    EXCEPTIONS
      lock_on_material  = 1
      lock_system_error = 2
      wrong_call        = 3
      not_found         = 4
      error_message     = 98
      OTHERS            = 99.
* Ende MWE-HPR-HW-318728

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      SET PARAMETER ID 'MAT' FIELD p_matnr.
      SET PARAMETER ID 'MXX' FIELD '0'.

      MESSAGE e002(rpudb) WITH p_matnr
                          RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " READ_MARA_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_MARA_SINGLE_F4
*&---------------------------------------------------------------------*
*       Lese die MARA-Daten zu einem Artikel mit Hilfe des FB:
*       MATERIAL_READ für F4-Hilfen => nur I-Message erlaubt!!!
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_MATNR     Material-Nummer
*      <--P_S_MARA    bestimmter MARA-Eintrag
*----------------------------------------------------------------------*
FORM read_mara_single_f4
                  USING
                    VALUE(p_matnr)  LIKE  mara-matnr
                  CHANGING
                    p_s_mara        TYPE  mara.

* Anfang MWE-HPR-HW-318728
*  DATA: l_mtcom LIKE mtcom,
*        l_mtcor LIKE mtcor,
*        BEGIN OF l_t_void OCCURS 0,
*          dum TYPE c,
*        END OF l_t_void.
*
*  CLEAR: p_s_mara.
*
*  l_mtcom-kenng = 'MARA'.
*  l_mtcom-matnr = p_matnr.
*  l_mtcom-spras = sy-langu.
*  l_mtcom-kzspr = c_nein.
*
*  CLEAR:  sy-msgid.
*
*  CALL FUNCTION 'MATERIAL_READ'
*       EXPORTING
*            schluessel           = l_mtcom
*       IMPORTING
*            matdaten             = p_s_mara
*            return               = l_mtcor
**           MATPER               =
*       TABLES
*            seqmat01             = l_t_void
*       EXCEPTIONS
*            account_not_found    = 1
*            batch_not_found      = 2
*            forecast_not_found   = 3
*            lock_on_account      = 4
*            lock_on_material     = 5
*            lock_on_plant        = 6
*            lock_on_sales        = 7
*            lock_on_sloc         = 8
*            lock_on_batch        = 9
*            lock_system_error    = 10
*            material_not_found   = 11
*            plant_not_found      = 12
*            sales_not_found      = 13
*            sloc_not_found       = 14
*            slocnumber_not_found = 15
*            sloctype_not_found   = 16
*            text_not_found       = 17
*            unit_not_found       = 18
*            invalid_mch1_matnr   = 19
*            invalid_mtcom        = 20
*            sa_material          = 21
*            wv_material          = 22
*            waart_error          = 23
*            error_message        = 98  " Ausnahme bei Meldungen
*            OTHERS               = 99
*            .
  CLEAR: p_s_mara.

  CLEAR:  sy-msgid.

  CALL FUNCTION 'MARA_SINGLE_READ'
    EXPORTING
*     KZRFB             = ' '
*     MAXTZ             = 0
      matnr             = p_matnr
*     SPERRMODUS        = ' '
*     STD_SPERRMODUS    = ' '
*     OUTPUT_NO_MESSAGE =
    IMPORTING
      wmara             = p_s_mara
    EXCEPTIONS
      lock_on_material  = 1
      lock_system_error = 2
      wrong_call        = 3
      not_found         = 4
      error_message     = 98
      OTHERS            = 99.
* Ende MWE-HPR-HW-318728

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE c_msgty_i NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE i002(rpudb) WITH p_matnr
                          RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " READ_MARA_SINGLE_f4

*&---------------------------------------------------------------------*
*&      Form  READ_EINA_EINE
*&---------------------------------------------------------------------*
*       Bestimme die Daten des Einkaufsinfosatz aus EINA und EINE
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_LIFNR        Lieferant
*      -->P_EKORG        EKORG muß gefüllt sein!!!
*      -->P_WERKS        Werk
*      -->P_MATNR        Material
*      -->P_INFNR        Info-Satz-Nr
*      -->P_SATNR
*      -->P_ATTYP
*$@004 Anfang MWE-HW-186918
*      -->P_PSTYP        BestellPosTyp
*$@004 Ende MWE-HW-186918
*      <--P_S_EINA       Daten aus der EINE
*      <--P_S_EINE       Daten aus der EINA
*----------------------------------------------------------------------*
FORM read_eina_eine USING
                      VALUE(p_lifnr)   LIKE  lfa1-lifnr
                      VALUE(p_ekorg)   LIKE  t024e-ekorg
                      VALUE(p_werks)   LIKE  t001w-werks
                      VALUE(p_matnr)   LIKE  mara-matnr
                      VALUE(p_infnr)   LIKE  eina-infnr
                      VALUE(p_satnr)   LIKE  mara-satnr
                      VALUE(p_attyp)   LIKE  mara-attyp
*$@004 Anfang MWE-HW-186918
                      VALUE(p_pstyp)   LIKE  ekpo-bstyp
*$@004 Ende MWE-HW-186918
                      VALUE(p_ematn)   LIKE  ekpo-ematn
                      VALUE(p_mprof)   LIKE  mara-mprof
                    CHANGING
                      p_s_eina         TYPE eina
                      p_s_eine         TYPE eine.

  DATA:  l_meico  LIKE  meico.
  DATA:  s_tcurm  LIKE  tcurm.                             "note 208292

  CLEAR: p_s_eina,
         p_s_eine.

  l_meico-infnr = p_infnr.
  l_meico-esokz = '0'.
*$@004 Anfang MWE-HW-186918
* note 208292 - B
  IF p_pstyp = '3'.
*                *** Bei Bestellpositionstyp 'Lohnbearbeitung'
*                *** Lohnbearbeitungs-Infosatz lesen
    l_meico-esokz = '3'.
  ELSEIF p_pstyp = '2'.
    IF s_tcurm IS INITIAL.
      SELECT SINGLE * FROM tcurm INTO s_tcurm.
    ENDIF.
    IF NOT s_tcurm-konsi IS INITIAL.
*                *** Bei Bestellpositionstyp 'Konsignation'
*                *** und Aktivierung Konsignationsinfosätze
*                *** Konsignations-Infosatz lesen
      l_meico-esokz = '2'.
    ENDIF.
* note 208292 - E
  ENDIF.
*$@004 Ende MWE-HW-186918
  l_meico-ekorg = p_ekorg.
  l_meico-werks = p_werks.
  l_meico-lifnr = p_lifnr.
  l_meico-matnr = p_matnr.
  l_meico-ematn = p_ematn.
  l_meico-mprof = p_mprof.
  l_meico-satnr = p_satnr.
  l_meico-attyp = p_attyp.
  l_meico-infsa = '-'.                 " Zuerst direkt für den Artikel
  IF cl_ops_switch_check=>sfsw_segmentation( ) EQ abap_on.
    l_meico-sgt_scat = l_s_general-sgt_scat.
  ENDIF.
  CALL FUNCTION 'ME_READ_INFORECORD'
    EXPORTING
      incom             = l_meico
*     INPREISSIM        = ' '
*     I_NO_OTHER_ORG    =
*     I_SET_ENQUEUE     =
    IMPORTING
*     DATEN             =
      einadaten         = p_s_eina
      einedaten         = p_s_eine
*     EXCOM             =
*     EXPREISSIM        =
*     E_ENQUEUE_FAILED  =
*      TABLES
*     ELEMENTE          =
    EXCEPTIONS
      bad_comin         = 1
      bad_material      = 2
      bad_materialclass = 3
      bad_supplier      = 4
      not_found         = 5
      OTHERS            = 6.
  IF sy-subrc <> 0.
    IF p_attyp  = c_attyp_variante.
*                *** Kann EK-Infosatz für Variante nicht gefunden
*                *** => Versuche es bei Varianten auch noch für
*                ***    den Sammelartikel!!!
*                *** Wichtig: Ist Artikel = log. Variante
*                ***          => BSTME nicht aus EK-Info des Sammelart.
*                ***             sondern aus der MARA, wenn abweichende
*                ***             EAN für die BSTME in der MLEA hinterl.
      CLEAR: sy-subrc,
             l_meico,
             p_s_eina,
             p_s_eine.

      l_meico-esokz = '0'.
*$@004 Anfang mwe-hw-186918
      IF p_pstyp = '2'.
*                *** Bei Bestellpositionstyp 'Konsignation'
*                *** Konsignations-Infosatz lesen
        l_meico-esokz = '2'.
      ENDIF.
*$@004 Ende MWE-HW-186918
      l_meico-ekorg = p_ekorg.
      l_meico-werks = p_werks.
      l_meico-lifnr = p_lifnr.
      l_meico-matnr = p_matnr.
      l_meico-ematn = p_ematn.
      l_meico-mprof = p_mprof.
      l_meico-satnr = p_satnr.
      l_meico-attyp = p_attyp.
      IF cl_ops_switch_check=>sfsw_segmentation( ) EQ abap_on.
        l_meico-sgt_scat = l_s_general-sgt_scat.
      ENDIF.
      l_meico-infsa = '+'.         " EK-Info zum Sammelartikel bestimmen
*                *** Wichtig: Die vorgegebene EK-Info-Nr wird beim
*                ***          2. Versuch nicht mehr berücksicht.

      CALL FUNCTION 'ME_READ_INFORECORD'
        EXPORTING
          incom             = l_meico
*         INPREISSIM        = ' '
*         I_NO_OTHER_ORG    =
*         I_SET_ENQUEUE     =
        IMPORTING
*         DATEN             =
          einadaten         = p_s_eina
          einedaten         = p_s_eine
*         EXCOM             =
*         EXPREISSIM        =
*         E_ENQUEUE_FAILED  =
*      TABLES
*         ELEMENTE          =
        EXCEPTIONS
          bad_comin         = 1
          bad_material      = 2
          bad_materialclass = 3
          bad_supplier      = 4
          not_found         = 5
          OTHERS            = 6.

      IF sy-subrc <> 0.
        CLEAR:  sy-subrc,
                p_s_eina,
                p_s_eine.
      ENDIF.
    ELSE.
*                *** Sonstige Fehler
*                *** => KEIN FEHLER => Initialisere Rückgabe
      CLEAR:  sy-subrc,
              p_s_eina,
              p_s_eine.
    ENDIF.
  ENDIF.
* note 350808 - B
  IF   p_s_eina-infnr <> p_infnr
   AND NOT p_s_eina-loekz IS INITIAL.
*                *** Infosatz wird verworfen, falls Nummer nicht
*                *** mitgegeben und Löschkennzeichen sitzt
    CLEAR p_s_eina.
  ENDIF.
  IF   p_s_eine-infnr <> p_infnr
   AND NOT p_s_eine-loekz IS INITIAL.
*                *** Infosatz wird verworfen, falls Nummer nicht
*                *** mitgegeben und Löschkennzeichen sitzt
    CLEAR p_s_eine.
  ENDIF.
* note 350808 - E

*                *** Wenn etwas gefunden wurde, dann müssen immer beide
*                *** Einträge EINE und EINA existieren
*                *** (Existiert nur einer dieser Einträge => nichts gef.
  IF p_s_eina IS INITIAL
  OR p_s_eine IS INITIAL.
    CLEAR:  p_s_eina,
            p_s_eine.
  ENDIF.

ENDFORM.                               " READ_EINA_EINE

*&---------------------------------------------------------------------*
*&      Form  READ_MARC_SINGLE
*&---------------------------------------------------------------------*
*       Bestimmung eines MARC-Satzes (existiert keiner => Wert-Artikel)
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_MATNR    Materialnummer
*      -->P_WERKS    Werk
*      <--P_S_MARC   gelesener MARC-Eintrag
*----------------------------------------------------------------------*
FORM read_marc_single
                    USING
                      VALUE(p_matnr)   LIKE  mara-matnr
                      VALUE(p_werks)   LIKE  t001w-werks
                    CHANGING
                      p_s_marc         TYPE  marc.

  DATA: l_mtcom LIKE mtcom,
        l_mtcor LIKE mtcor,
*$@005 Anfang MWE-HW-204696
        l_mt06e LIKE mt06e,
*$@005 Ende MWE-HW-204696
        BEGIN OF l_t_void OCCURS 0,
          dum TYPE c,
        END OF l_t_void.

  DATA: ls_v_marc_md TYPE v_marc_md.

  CLEAR: p_s_marc.

*  l_mtcom-kenng = 'MARC'.
  " call MATERIAL_READ for MARC with new S/4HANA identifier to read and return only MARC master data and not aggregations
  l_mtcom-kenng = 'MARCM'.
  l_mtcom-matnr = p_matnr.
  l_mtcom-werks = p_werks.
  l_mtcom-spras = sy-langu.
  l_mtcom-kzspr = c_no.
*$@001 Anfang   MWE-HW-159591
  l_mtcom-kzmpn = c_yes.
*$@001 Ende   MWE-HW-159591

  CALL FUNCTION 'MATERIAL_READ'
    EXPORTING
      schluessel           = l_mtcom
    IMPORTING
*     matdaten             = p_s_marc
      matdaten             = ls_v_marc_md
      return               = l_mtcor
*     MATPER               =
    TABLES
      seqmat01             = l_t_void
    EXCEPTIONS
      account_not_found    = 1
      batch_not_found      = 2
      forecast_not_found   = 3
      lock_on_account      = 4
      lock_on_material     = 5
      lock_on_plant        = 6
      lock_on_sales        = 7
      lock_on_sloc         = 8
      lock_on_batch        = 9
      lock_system_error    = 10
      material_not_found   = 11
      plant_not_found      = 12
      sales_not_found      = 13
      sloc_not_found       = 14
      slocnumber_not_found = 15
      sloctype_not_found   = 16
      text_not_found       = 17
      unit_not_found       = 18
      invalid_mch1_matnr   = 19
      invalid_mtcom        = 20
      sa_material          = 21
      wv_material          = 22
      waart_error          = 23
      error_message        = 98  " Ausnahme bei Meldungen
      OTHERS               = 99.

  IF sy-subrc <> 0.
*$@005 Anfang MWE-HW-204696
*                *** Bei nicht gefundendem MARC-Satz, versuche
*                *** es noch mit dem VIEW MT06E, um den korrekten
*                *** MARC-Satz für Material und Vorlagewerk zu
*                *** bestimmen
    CLEAR: p_s_marc.

    l_mtcom-kenng = 'MT06E'.
    l_mtcom-matnr = p_matnr.
    l_mtcom-werks = p_werks.
    l_mtcom-spras = sy-langu.
    l_mtcom-kzspr = c_no.
    l_mtcom-kzmpn = c_yes.

    CALL FUNCTION 'MATERIAL_READ'
      EXPORTING
        schluessel           = l_mtcom
      IMPORTING
        matdaten             = l_mt06e
        return               = l_mtcor
*       MATPER               =
      TABLES
        seqmat01             = l_t_void
      EXCEPTIONS
        account_not_found    = 1
        batch_not_found      = 2
        forecast_not_found   = 3
        lock_on_account      = 4
        lock_on_material     = 5
        lock_on_plant        = 6
        lock_on_sales        = 7
        lock_on_sloc         = 8
        lock_on_batch        = 9
        lock_system_error    = 10
        material_not_found   = 11
        plant_not_found      = 12
        sales_not_found      = 13
        sloc_not_found       = 14
        slocnumber_not_found = 15
        sloctype_not_found   = 16
        text_not_found       = 17
        unit_not_found       = 18
        invalid_mch1_matnr   = 19
        invalid_mtcom        = 20
        sa_material          = 21
        wv_material          = 22
        waart_error          = 23
        t134m_not_found      = 24
        error_message        = 98 " Ausnahme bei Meldungen
        OTHERS               = 99.

    IF sy-subrc = 0.
*                *** MARC-Werte übernehmen:
      CLEAR: p_s_marc.

      p_s_marc-matnr = p_matnr.
      p_s_marc-werks = p_werks.

      p_s_marc-ausme = l_mt06e-ausme.
      p_s_marc-rdprf = l_mt06e-rdprf.
      p_s_marc-bstrf = l_mt06e-bstrf.
      p_s_marc-bstma = l_mt06e-bstma.
      p_s_marc-bstmi = l_mt06e-bstmi.
      p_s_marc-megru = l_mt06e-megru.

    ELSE.
*$@005 Ende MWE-HW-204696
*                *** Kann MARC-Satz nicht bestimmt werden
*                *** => KEIN FEHLER => Initialisere Rückgabe
      CLEAR:  sy-subrc,
              p_s_marc.
*$@005 Anfang MWE-HW-204696
    ENDIF.
*$@005 Ende MWE-HW-204696
  ELSE.
    MOVE-CORRESPONDING ls_v_marc_md TO p_s_marc.
  ENDIF.

ENDFORM.                               " READ_MARC_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_LFA1_SINGLE
*&---------------------------------------------------------------------*
*       Bestimme die Daten aus der LFA1 zu einem Lieferanten
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_LIFNR     Lieferant
*      <--P_S_LFA1    Bestimmte LFA1-Daten
*----------------------------------------------------------------------*
FORM read_lfa1_single
                    USING
                      VALUE(p_lifnr)   LIKE  lfa1-lifnr
                    CHANGING
                      p_s_lfa1         TYPE  lfa1.

  CLEAR:   p_s_lfa1.

  CALL FUNCTION 'WY_LFA1_SINGLE_READ'
    EXPORTING
      pi_lifnr         = p_lifnr
      pi_cvp_behavior  = gc_cvp_raise_exc         "2269110
*     PI_BYPASSING_BUFFER =            => Default: - Puffer nutzen
*     PI_REFRESH_BUFFER   =            =>          - kein Refresh
    IMPORTING
      po_lfa1          = p_s_lfa1
    EXCEPTIONS
      no_records_found = 1
      error_message    = 98
      OTHERS           = 99.

  IF sy-subrc <> 0.
*                *** Existiert kein Eintrag in der LFA1
*                *** => FEHLER!!! (nur wenn Lieferant auch belegt!!!)
    SET PARAMETER ID 'LIF' FIELD p_lifnr.
    MESSAGE e003(rpudb) WITH p_lifnr
                        RAISING error.
  ENDIF.

ENDFORM.                               " READ_LFA1_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_LFA1_SINGLE_F4
*&---------------------------------------------------------------------*
*       Bestimme die Daten aus der LFA1 zu einem Lieferanten
*       bei F4-Hilfe => nur I-Message
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_LIFNR     Lieferant
*      <--P_S_LFA1    Bestimmte LFA1-Daten
*----------------------------------------------------------------------*
FORM read_lfa1_single_f4
                    USING
                      VALUE(p_lifnr)   LIKE  lfa1-lifnr
                    CHANGING
                      p_s_lfa1         TYPE  lfa1.

  CLEAR:   p_s_lfa1.

  CALL FUNCTION 'WY_LFA1_SINGLE_READ'
    EXPORTING
      pi_lifnr         = p_lifnr
*     PI_BYPASSING_BUFFER =            => Default: - Puffer nutzen
*     PI_REFRESH_BUFFER   =            =>          - kein Refresh
    IMPORTING
      po_lfa1          = p_s_lfa1
    EXCEPTIONS
      no_records_found = 1
      error_message    = 98
      OTHERS           = 99.

  IF sy-subrc <> 0.
*                *** Existiert kein Eintrag in der LFA1
*                *** => FEHLER!!! (nur wenn Lieferant auch belegt!!!)
    MESSAGE i003(rpudb) WITH p_lifnr
                        RAISING error.
  ENDIF.

ENDFORM.                               " READ_LFA1_SINGLE_F4

*&---------------------------------------------------------------------*
*&      Form  READ_KNMT_SINGLE
*&---------------------------------------------------------------------*
*       Bestimme die Daten zum Kunden-Info-Satz aus der KNMT
*       => mit Puffer
*----------------------------------------------------------------------*
*      -->P_KUNNR   Kundenummer
*      -->P_VKORG   Verkaufsorganisation
*      -->P_VTWEG   Vertreibsweg
*      -->P_SPART   Sparte
*      -->P_MATNR   Material
*      <--P_S_KNMT  Bestimmte Daten aus der KNMT
*----------------------------------------------------------------------*
FORM read_knmt_single
                    USING
                      VALUE(p_kunnr)     LIKE  kna1-kunnr
                      VALUE(p_vkorg)     LIKE  tvko-vkorg
                      VALUE(p_vtweg)     LIKE  tvtw-vtweg
                      VALUE(p_spart)     LIKE  tspa-spart
                      VALUE(p_matnr)     LIKE  mara-matnr
                    CHANGING
                      p_s_knmt           TYPE  knmt.

* ??? => soll durch entsprechende FB mit Puffer ersetzt werden ???

  STATICS: BEGIN OF s_t_knmt_spart OCCURS 0,
             spart LIKE   tspa-spart.
             INCLUDE STRUCTURE knmt.
           STATICS: END OF   s_t_knmt_spart.
  STATICS: BEGIN OF s_s_knmt_spart,
             spart LIKE   tspa-spart.
             INCLUDE STRUCTURE knmt.
           STATICS: END OF   s_s_knmt_spart.

  DATA: l_kdmat LIKE knmt-kdmat,
*$@002 Anfang  MWE-HW-182741
        l_kunnr LIKE kna1-kunnr.

  l_kunnr = p_kunnr.

  PERFORM userexit_cust_material_read(sapmv45a) USING l_kunnr.
*$@002 Ende MWE-HW-182741

  CLEAR: p_s_knmt.

*                *** Untesruche, ob der gesuchte Satz nicht schon beim
*                *** letzten Aufruf gelesen wurde => kein Zugriff auf
*                *** Puffertabelle notwendig
  IF  s_s_knmt_spart-spart = p_spart
*$@002 Anfang MWE-HW-182741
*$  AND s_s_knmt_spart-kunnr = p_kunnr
  AND s_s_knmt_spart-kunnr = l_kunnr
*$@002 Ende MWE-HW-182741
  AND s_s_knmt_spart-vkorg = p_vkorg
  AND s_s_knmt_spart-vtweg = p_vtweg
  AND s_s_knmt_spart-matnr = p_matnr.
    MOVE-CORRESPONDING  s_s_knmt_spart  TO  p_s_knmt .
  ELSE.
*                *** sonst, suche in der lokalen Tabelle
    LOOP AT s_t_knmt_spart
      WHERE spart = p_spart
*$@002 Anfang MWE-HW-182741
*$        AND kunnr = p_kunnr
        AND kunnr = l_kunnr
*$@002 Ende MWE-HW-182741
        AND vkorg = p_vkorg
        AND vtweg = p_vtweg
        AND matnr = p_matnr.

      MOVE-CORRESPONDING  s_t_knmt_spart  TO  p_s_knmt .

    ENDLOOP.
  ENDIF.

  IF p_s_knmt IS INITIAL.
*                *** Kein Eintrag gefunden => Lese direkt auf der DB
    CALL FUNCTION 'RV_CUSTOMER_MATERIAL_READ'
      EXPORTING
        cmr_kdmat      = l_kdmat " = LEER!!!
*$@002 Anfang MWE-HW-182741
*$              cmr_kunnr      = p_kunnr
        cmr_kunnr      = l_kunnr
*$@002 Ende MWE-HW-182741
        cmr_matnr      = p_matnr
        cmr_spart      = p_spart
        cmr_vkorg      = p_vkorg
        cmr_vtweg      = p_vtweg
      IMPORTING
        cmr_knmt       = p_s_knmt
      EXCEPTIONS
        knmt_not_found = 1
        error_message  = 98      " Ausnahme bei Meldungen
        OTHERS         = 99.

    IF sy-subrc <> 0.
*                *** Kann KNMT-Satz nicht bestimmt werden
*                *** => KEIN FEHLER => Initialisere Rückgabe
      CLEAR:  sy-subrc,
              p_s_knmt.
    ELSE.
*                *** Gefundener Eintrag in Puffer eintragen
      CLEAR: s_t_knmt_spart.

      MOVE-CORRESPONDING  p_s_knmt  TO  s_t_knmt_spart.
      s_t_knmt_spart-spart = p_spart.

      APPEND s_t_knmt_spart.
    ENDIF.
  ENDIF.

ENDFORM.                               " READ_KNMT_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_MVKE_SINGLE
*&---------------------------------------------------------------------*
*       Bestimme die Daten aus der MVKE
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_MATNR   Material
*      -->P_VKORG   Verkaufsorganisation
*      -->P_VTWEG   Vertreibsweg
*      <--P_S_MVKE  Bestimmte Daten aus der MVKE
*----------------------------------------------------------------------*
FORM read_mvke_single
                    USING
                      VALUE(p_matnr)     LIKE  mara-matnr
                      VALUE(p_vkorg)     LIKE  tvko-vkorg
                      VALUE(p_vtweg)     LIKE  tvtw-vtweg
                    CHANGING
                      p_s_mvke           TYPE  mvke.

  CLEAR: p_s_mvke.

  CALL FUNCTION 'MVKE_SINGLE_READ'
    EXPORTING
*     KZRFB             = ' '
*     MAXTZ             = 0
      matnr             = p_matnr
      vkorg             = p_vkorg
      vtweg             = p_vtweg
*     SPERRMODUS        = ' '
*     STD_SPERRMODUS    = ' '
    IMPORTING
      wmvke             = p_s_mvke
    EXCEPTIONS
      lock_on_mvke      = 1
      lock_system_error = 2
      wrong_call        = 3
      not_found         = 4
      error_message     = 98     " Ausnahme bei Meldungen
      OTHERS            = 99.

  IF sy-subrc <> 0.
*                *** Kann MVKE-Satz nicht bestimmt werden
*                *** => KEIN FEHLER => Initialisere Rückgabe
    CLEAR:  sy-subrc,
            p_s_mvke.
  ENDIF.

ENDFORM.                               " READ_MVKE_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_KNVV_SINGLE
*&---------------------------------------------------------------------*
*       Bestimme die Daten aus der KNVV.
*       => mit Pufferung
*----------------------------------------------------------------------*
*      -->P_KUNNR  Kundennummer
*      -->P_VKORG  VKORG
*      -->P_VTWEG  Vertreibsweg
*      -->P_SPART  Sparte
*      <--P_S_KNVV Bestimmte Daten aus der KNVV
*----------------------------------------------------------------------*
FORM read_knvv_single
                    USING
                      VALUE(p_kunnr)     LIKE  kna1-kunnr
                      VALUE(p_vkorg)     LIKE  tvko-vkorg
                      VALUE(p_vtweg)     LIKE  tvtw-vtweg
                      VALUE(p_spart)     LIKE  tspa-spart
                    CHANGING
                      p_s_knvv           TYPE  knvv.

  CLEAR:   p_s_knvv.

  CALL FUNCTION 'KNVV_SINGLE_READ'
    EXPORTING
      i_kunnr        = p_kunnr
      i_vkorg        = p_vkorg
      i_vtweg        = p_vtweg
      i_spart        = p_spart
      i_cvp_behavior = gc_cvp_raise_exc        "2269110
*     I_RESET_BUFFER = => Kein Puffer-Refresh
*     I_BYPASSING_BUFFER =        => Puffer nutzen
    IMPORTING
      o_knvv         = p_s_knvv
    EXCEPTIONS
      not_found      = 1
      error_message  = 98
      OTHERS         = 99.

  IF sy-subrc <> 0.
*                *** Kann KNVV-Satz nicht bestimmt werden
*                *** => KEIN FEHLER => Initialisere Rückgabe
    CLEAR:  sy-subrc,
            p_s_knvv.
  ENDIF.

ENDFORM.                               " READ_KNVV_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_EKORG_SINGLE
*&---------------------------------------------------------------------*
*       Bestimme die EKORG zum Abnehmer-Werk, wenn dem Werk eine EKORG
*       eindeutig zugeornet ist!!!
*----------------------------------------------------------------------*
*      -->P_WERKS  Werk
*      <--P_EKORG  EKORG
*----------------------------------------------------------------------*
FORM read_ekorg_single
                    USING
                      VALUE(p_werks)  LIKE t001w-werks
                    CHANGING
                      VALUE(p_ekorg)  LIKE eine-ekorg.

  CLEAR: p_ekorg.

  CALL FUNCTION 'ME_SELECT_EKORG_FOR_PLANT'
    EXPORTING
      i_werks                    = p_werks
*     I_PIPEL                    =
*     I_UMLAG                    =
*     I_KONSI                    =
*     I_STANDARD                 =
    IMPORTING
      e_ekorg                    = p_ekorg
    EXCEPTIONS
      more_than_one_organization = 1
      no_entry_found             = 2
      no_default_found           = 3
      error_message              = 98
      OTHERS                     = 99.
  IF sy-subrc <> 0.
*                *** Keine eindeutige EKORG bestimmbar
*                *** => KEIN FEHLER => Initialisere Rückgabe
    CLEAR:  sy-subrc,
            p_ekorg.
  ENDIF.

ENDFORM.                               " READ_EKORG_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_RDPR_ALL
*&--------------------------------------------------------------------*
*       Lese die Komplette Defintion eines Rundungsprofils
*       1. zu Werk und Profil
*       2. zu Profil (Werk = LEER)
*----------------------------------------------------------------------*
*      -->P_RDPRF   Rundungsprofil
*      -->P_werks   Werk
*      <--P_S_RDPR  1. Eintrag in der RDPR zu der Def. des RundProfils
*      <--P_T_RDPR  Komplette Defintion des RUndungsprofils
*----------------------------------------------------------------------*
FORM read_rdpr_all
                   TABLES
                     p_t_rdpr          STRUCTURE  rdpr
                   USING
                     VALUE(p_rdprf)    LIKE rdpr-rdprf
                     VALUE(p_werks)    LIKE rdpr-werks
                   CHANGING
                     p_s_rdpr          LIKE rdpr.

  CLEAR: p_t_rdpr[],
         p_s_rdpr,
         sy-msgid.

  CALL FUNCTION 'MD_RDPR_READ'
    EXPORTING
      i_opcode           = '1'  " genau ein Eintrag lesen
      i_rdprf            = p_rdprf
      i_werks            = p_werks
*     I_RDMPO            =
      i_buffer_on        = c_yes " gelesene Daten puffern
      i_read_with_buffer = c_yes " lese über Puffer
      i_buffer_size      = 0    " Puffer beliebig groß
    TABLES
      e_t_rdpr           = p_t_rdpr
    EXCEPTIONS
      no_entry_found     = 1
      invalid_opcode     = 2
      bad_params         = 3
      error_message      = 98
      OTHERS             = 99.

  IF sy-subrc <> 0.
*                *** Mit Werk nichts gefunden => ohne Werk versuchen
    CLEAR: sy-subrc,
           p_werks.      " => macht keine Probleme, da CALL by VALUE!!!

    CALL FUNCTION 'MD_RDPR_READ'
      EXPORTING
        i_opcode           = '1' " genau ein Eintrag
        i_rdprf            = p_rdprf
        i_werks            = p_werks
*       I_RDMPO            =
        i_buffer_on        = c_yes     " gelesene Daten puffern
        i_read_with_buffer = c_yes     " lese über Puffer
        i_buffer_size      = 0  " Puffer beliebig groß
      TABLES
        e_t_rdpr           = p_t_rdpr
      EXCEPTIONS
        no_entry_found     = 1
        invalid_opcode     = 2
        bad_params         = 3
        error_message      = 98
        OTHERS             = 99.
  ENDIF.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING rdpr_not_found.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH    'MD_RDPR_READ'
                           RAISING rdpr_not_found.
    ENDIF.
  ELSE.
*                *** Bestimme noch 1. Eintrag der Def.
    READ TABLE p_t_rdpr INDEX 1.
    p_s_rdpr  = p_t_rdpr.
  ENDIF.

ENDFORM.                               " READ_RDPR_ALL

*&---------------------------------------------------------------------*
*&      Form  READ_TW06S_SINGLE
*&---------------------------------------------------------------------*
*       Lese die TW06S zu einer Rundungsregel und einer ME
*----------------------------------------------------------------------*
*      -->P_MEINH     ME
*      -->P_RDRGL     Rundungsregel
*      <--P_S_TW06S   Bestimmter Eintrag
*----------------------------------------------------------------------*
FORM read_tw06s_single
                   USING
                     VALUE(p_meinh)  LIKE  marm-meinh
                     VALUE(p_rdrgl)  LIKE  tw06s-rdrgl
                   CHANGING
                     p_s_tw06s       LIKE tw06s.

* ??? => soll durch entsprechende FB-Aufrufe gelöst werden

*                *** globaler Puffer: Tabelle und letzter best. Eintrag
  STATICS: s_t_tw06s LIKE   tw06s
                       OCCURS 0     WITH HEADER LINE,
           s_s_tw06s LIKE   tw06s.

*                *** lokaler Puffer: pro Aufruf neu initialisiert
  DATA:    l_t_tw06s   LIKE   tw06s
                       OCCURS 0     WITH HEADER LINE.

  CLEAR:   p_s_tw06s.

  IF  s_s_tw06s-meins = p_meinh
  AND s_s_tw06s-rdrgl = p_rdrgl.
*                *** Gesuchter Eintrag = letzter bestimmter Eintrag
    p_s_tw06s = s_s_tw06s.

  ELSE.

    READ TABLE s_t_tw06s
      WITH KEY rdrgl = p_rdrgl
               meins = p_meinh
*$@003 Anfang MWE-ENTW-46C
               BINARY SEARCH.
*$@003 Ende MWE-ENTW-46C

    IF sy-subrc = 0.
*                *** gesuchter Eintrag im Puffer enthalten
      s_s_tw06s = s_t_tw06s.
      p_s_tw06s = s_t_tw06s.

    ELSE.

      READ TABLE s_t_tw06s
        WITH KEY rdrgl = p_rdrgl
*$@003 Anfang MWE-ENTW-46C
                 BINARY SEARCH.
*$@003 Ende MWE-ENTW-46C

      IF sy-subrc = 0.
*                *** gesuchte Regel schon im Puffer, aber zur ME sind
*                *** keine Schwellenwerte definiert
        CLEAR: p_s_tw06s.
      ELSE.

        SELECT      *
        INTO TABLE  l_t_tw06s
              FROM  tw06s
             WHERE  rdrgl = p_rdrgl.

        IF sy-subrc = 0.

          APPEND LINES OF l_t_tw06s
                       TO s_t_tw06s.

*$@003 Anfang MWE-ENTW-46C
          SORT s_t_tw06s
            BY rdrgl
               meins.
*$@003 Ende MWE-ENTW-46C


          READ TABLE l_t_tw06s
            WITH KEY rdrgl = p_rdrgl
                     meins = p_meinh.

          IF sy-subrc = 0.
*                *** Schwellenwerte zu der Regel und der ME in DB gefund
            s_s_tw06s = l_t_tw06s.
            p_s_tw06s = l_t_tw06s.

          ELSE.
*                *** Keine Schwellenwerte zu der Regel und der ME in der
*                *** DB hinterlegt
            CLEAR: p_s_tw06s.
          ENDIF.
        ELSE.
*                *** Rundungsregel existiert nicht
          CLEAR: p_s_tw06s.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  sy-subrc = 0.

ENDFORM.                               " READ_TW06S_SINGLE

*&---------------------------------------------------------------------*
*&      Form  READ_T006
*&---------------------------------------------------------------------*
*       Lese T006 zu einer vorgegebenen ME
*----------------------------------------------------------------------*
*      -->P_UNIT      ME
*      <--P_S_T006    Bestimmtere EIntrag zur ME
*----------------------------------------------------------------------*
FORM read_t006
                   USING
                     VALUE(p_unit)  LIKE marm-meinh
                   CHANGING
                     p_s_t006       LIKE t006.

* ??? => soll durch entsprechende FB-Aufrufe gelöst werden
* Anfang MWE-HPR-HW-318728
  DATA:  l_tabix  LIKE  sy-tabix.
* Ende MWE-HPR-HW-318728

  STATICS: s_s_t006        LIKE t006.

  CLEAR: p_s_t006.

* Anfang MWE-HPR-HW-318728
**                *** Fülle den Puffer mit allen Sätzen aus der DB T006
**                *** beim 1. Lesen.
**                *** Danach wird nur noch über den Puffer zugegriffen
*  IF g_t006_first_read = c_yes.
*
*    SELECT     *
*    INTO TABLE g_t_t006
*    FROM       t006.
*
*    SORT  g_t_t006
*      BY  msehi.
*
*    g_t006_first_read = c_no.
*
*  ENDIF.
* Ende MWE-HPR-HW-318728

  IF s_s_t006-msehi  =  p_unit.
*                *** gesuchter Eintrag wurde als letztes gelesen:
    p_s_t006 = s_s_t006.
  ELSE.
*                *** Suche eintrag im Puffer
    READ TABLE  g_t_t006
          INTO  s_s_t006
      WITH KEY  msehi = p_unit BINARY SEARCH.

    IF sy-subrc = 0.
      p_s_t006 = s_s_t006.
    ELSE.
      CLEAR: p_s_t006.

* Anfang MWE-HPR-HW-318728
      l_tabix  =  sy-tabix.

      CLEAR: sy-subrc.

      SELECT SINGLE  *
               INTO  p_s_t006
               FROM  t006
              WHERE  msehi = p_unit.

      IF sy-subrc = 0.

        s_s_t006  =  p_s_t006.

        INSERT s_s_t006
          INTO g_t_t006
         INDEX l_tabix.

      ELSE.

        CLEAR: p_s_t006.

      ENDIF.
* Ende MWE-HPR-HW-318728

    ENDIF.

  ENDIF.

ENDFORM.                                                    " READ_T006

*&---------------------------------------------------------------------*
*&      Form  READ_T006_DIMID
*&---------------------------------------------------------------------*
*       Lese T006 zu einer vorgegebenen ME
*----------------------------------------------------------------------*
*      -->P_DIMID     Dimensions-ID
*      <--P_T_T006    Bestimmtere EInträge zur der Dimensions-ID
*----------------------------------------------------------------------*
FORM read_t006_dimid
                   TABLES
                     p_t_t006        STRUCTURE  t006
                   USING
                     VALUE(p_dimid)  LIKE t006-dimid.

* ??? => soll durch entsprechende FB-Aufrufe gelöst werden
* Anfang MWE-HPR-HW-318728
  DATA:  l_tabix  LIKE  sy-tabix.
* Ende MWE-HPR-HW-318728

  STATICS: s_t_t006      LIKE  t006
                         OCCURS 0  WITH HEADER LINE,
* Anfang MWE-HPR-HW-318728
*           s_first_call  TYPE  c                       VALUE 'X'.
           s_dimid_last  LIKE  t006-dimid,
           s_t_t006_last LIKE  t006
                         OCCURS 0
                         WITH HEADER LINE.
* Ende MWE-HPR-HW-318728

  CLEAR: p_t_t006[].

*                *** Fülle den Puffer mit allen Sätzen aus der DB T006
*                *** beim 1. Lesen.
*                *** Danach wird nur noch über den Puffer zugegriffen
  IF g_t006_first_read = c_yes.

    SELECT     *
    INTO TABLE g_t_t006
* Anfang MWE-HPR-HW-318728
*    FROM       t006.
    FROM       t006
    ORDER BY   PRIMARY KEY.
* Ende MWE-HPR-HW-318728

    s_t_t006[] = g_t_t006[].

* Anfang MWE-HPR-HW-318728
*    SORT  g_t_t006
*      BY  msehi.
* Ende MWE-HPR-HW-318728

    SORT  s_t_t006
      BY  dimid.

    g_t006_first_read = c_no.
* Anfang MWE-HPR-HW-318728
*    s_first_call      = c_no.
*
*  ELSE.
*
*    IF s_first_call = c_yes.
*
*      s_t_t006[] = g_t_t006[].
*
*      SORT  s_t_t006
*        BY  dimid.
*
*      s_first_call      = c_no.
*
*   ENDIF.
* Ende MWE-HPR-HW-318728

  ENDIF.

*                *** Suche eintrag im Puffer
* Anfang MWE-HPR-HW-318728
*  LOOP AT  s_t_t006
*    WHERE  dimid = p_dimid.
*
*    APPEND s_t_t006
*        TO p_t_t006.
*
*  ENDLOOP.
  IF s_dimid_last  =  p_dimid.

    p_t_t006[] = s_t_t006_last[].

  ELSE.

    CLEAR: s_t_t006_last[].

    s_dimid_last  =  p_dimid.

    READ TABLE  s_t_t006
      WITH KEY  dimid    =  s_dimid_last
                BINARY SEARCH
                TRANSPORTING NO FIELDS.

    l_tabix  =  sy-tabix.

    LOOP AT  s_t_t006
       FROM  l_tabix.

      IF s_t_t006-dimid  <>  p_dimid.

        EXIT.

      ENDIF.

      APPEND s_t_t006
          TO s_t_t006_last.

    ENDLOOP.

    p_t_t006[] = s_t_t006_last[].

  ENDIF.
* Ende MWE-HPR-HW-318728

ENDFORM.                               " READ_T006_DIMID

*&---------------------------------------------------------------------*
*&      Form  READ_T006D
*&---------------------------------------------------------------------*
*       Bestimme T006D-Eintrag zu einer Dimension
*----------------------------------------------------------------------*
*      -->P_DIMID   Dimension
*      <--P_S_T006D bestimmter T006D-Eintrag
*----------------------------------------------------------------------*
FORM read_t006d
                   USING
                     p_dimid       LIKE   t006d-dimid
                   CHANGING
                     p_s_t006d     LIKE   t006d.

* ??? => soll durch entsprechende FB-Aufrufe gelöst werden

  STATICS: s_t_t006d    LIKE t006d
                           OCCURS 0  WITH HEADER LINE,
           s_s_t006d    LIKE t006d,
           s_first_read TYPE c                        VALUE c_yes.

  CLEAR: p_s_t006d.

*                *** Fülle den Puffer mit allen Sätzen aus der DB T006
*                *** beim 1. Lesen.
*                *** Danach wird nur noch über den Puffer zugegriffen
  IF s_first_read = c_yes.

    SELECT     *
    INTO TABLE s_t_t006d
    FROM       t006d.

    SORT  s_t_t006d
      BY  dimid.

    s_first_read = c_no.

  ENDIF.

  IF s_s_t006d-dimid  =  p_dimid.
*                *** gesuchter Eintrag wurde als letztes gelesen:
    p_s_t006d = s_s_t006d.
  ELSE.
*                *** Suche eintrag im Puffer
    READ TABLE  s_t_t006d
          INTO  s_s_t006d
      WITH KEY  dimid = p_dimid  BINARY SEARCH.

    IF sy-subrc = 0.
      p_s_t006d = s_s_t006d.
    ELSE.
      CLEAR: p_s_t006d.
    ENDIF.

  ENDIF.

ENDFORM.                               " READ_T006D

*&---------------------------------------------------------------------*
*&      Form  READ_T006A
*&---------------------------------------------------------------------*
*       Bestimme die sprachabhängige Texte zu einer ME
*----------------------------------------------------------------------*
*      -->P_QTY_UNIT
*      <--P_S_T006A
*----------------------------------------------------------------------*
FORM read_t006a
                   USING
                     p_qty_unit  LIKE  marm-meinh
                   CHANGING
                     p_s_t006a   LIKE  t006a.

* ??? => soll durch entsprechende FB-Aufrufe gelöst werden

  STATICS: s_t_t006a    LIKE t006a
                           OCCURS 0  WITH HEADER LINE,
           s_s_t006a    LIKE t006a,
           s_first_read TYPE c                        VALUE c_yes,
           s_langu      LIKE sy-langu.

  CLEAR: p_s_t006a.

  IF s_first_read = c_yes.

    s_langu       =  sy-langu.
    s_first_read  =  c_no.

    CLEAR: s_t_t006a[],
           s_s_t006a.

    SELECT      *
    INTO TABLE  s_t_t006a
    FROM        t006a
         WHERE  spras  =  s_langu.

    SORT  s_t_t006a
      BY  spras
          msehi.

  ELSE.
    IF s_langu <> sy-langu.

      s_langu  =  sy-langu.

      CLEAR: s_t_t006a[],
             s_s_t006a.

      SELECT      *
      INTO TABLE  s_t_t006a
      FROM        t006a
           WHERE  spras  =  s_langu.

      SORT  s_t_t006a
        BY  spras
            msehi.

    ENDIF.
  ENDIF.

  IF s_s_t006a-msehi  =  p_qty_unit.
    p_s_t006a  =  s_s_t006a.
  ELSE.
    READ TABLE  s_t_t006a
      WITH KEY  spras  =  s_langu
                msehi  =  p_qty_unit  BINARY SEARCH.

    IF sy-subrc = 0.
      s_s_t006a  =  s_t_t006a.
      p_s_t006a  =  s_s_t006a.
    ELSE.
      CLEAR: sy-subrc,
             p_s_t006a.
    ENDIF.

  ENDIF.

ENDFORM.                               " READ_T006A

*$@008 Anfang MWE-ENTW-470-UNICODE
*&---------------------------------------------------------------------*
*&      Form  read_makt
*&---------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
*      -->P_MATNR
*      -->P_WERK
*      <--P_S_MAKT
*----------------------------------------------------------------------*
FORM read_makt
  USING
    p_matnr  LIKE mara-matnr
    p_werk   LIKE t001w-werks
  CHANGING
    p_s_makt LIKE makt.

  DATA: l_s_mtcom LIKE mtcom,
        l_s_mtcor LIKE mtcor,
        BEGIN OF l_t_void OCCURS 0,
          dum TYPE c,
        END OF l_t_void.

*  PERFORM read_mara USING matnr.
*  PERFORM read_marc USING matnr werk.

  l_s_mtcom-kenng  = 'MAKT'.
  l_s_mtcom-matnr  = p_matnr.
  l_s_mtcom-spras  = sy-langu.
  l_s_mtcom-kzspr  = c_no.

  CALL FUNCTION 'MATERIAL_READ'
    EXPORTING
      schluessel           = l_s_mtcom
    IMPORTING
      matdaten             = p_s_makt
      return               = l_s_mtcor
*     MATPER               =
    TABLES
      seqmat01             = l_t_void
    EXCEPTIONS
      account_not_found    = 1
      batch_not_found      = 2
      forecast_not_found   = 3
      lock_on_account      = 4
      lock_on_material     = 5
      lock_on_plant        = 6
      lock_on_sales        = 7
      lock_on_sloc         = 8
      lock_on_batch        = 9
      lock_system_error    = 10
      material_not_found   = 11
      plant_not_found      = 12
      sales_not_found      = 13
      sloc_not_found       = 14
      slocnumber_not_found = 15
      sloctype_not_found   = 16
      text_not_found       = 17
      unit_not_found       = 18
      invalid_mch1_matnr   = 19
      invalid_mtcom        = 20
      sa_material          = 21
      wv_material          = 22
      waart_error          = 23
      t134m_not_found      = 24
      error_message        = 98
      OTHERS               = 99.
  IF sy-subrc <> 0.

    CLEAR: l_s_mtcor.

  ENDIF.

ENDFORM.                    " read_makt
*&---------------------------------------------------------------------*
*&      Form  read_rdtx_single
*&---------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
*      -->P_WERK
*      -->P_RDPRF
*      <--P_SUBRC
*      <--P_S_RDTX
*----------------------------------------------------------------------*
FORM read_rdtx_single
  USING
    p_werk       LIKE  t001w-werks
    p_rdprf      LIKE  rdpr-rdprf
  CHANGING
    p_subrc      LIKE  sy-subrc
    p_s_rdtx     LIKE  rdtx.

  DATA: l_werks  LIKE  t001w-werks.

  CLEAR: p_subrc,
         p_s_rdtx,
         l_werks.


  PERFORM call_md_rdtx_read USING    sy-langu
                                     p_rdprf
                                     p_werk
                            CHANGING p_s_rdtx.
  IF sy-subrc <> 0.

    PERFORM call_md_rdtx_read USING    sy-langu
                                       p_rdprf
                                       l_werks
                              CHANGING p_s_rdtx.

    p_subrc = sy-subrc.

  ENDIF.

ENDFORM.                    " read_rdtx_single

*&---------------------------------------------------------------------*
*&      Form  read_ekorg_with_umlag
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_WERK
*      -->P_UMLAG
*      <--P_EKORG  text
*----------------------------------------------------------------------*
FORM read_ekorg_with_umlag
  USING
    p_werk   LIKE  t001w-werks
    p_umlag  TYPE  c
  CHANGING
    p_ekorg  LIKE  eine-ekorg.

  CLEAR: p_ekorg.

  CALL FUNCTION 'ME_SELECT_EKORG_FOR_PLANT'
    EXPORTING
      i_werks                    = p_werk
*     I_PIPEL                    =
      i_umlag                    = p_umlag
*     I_KONSI                    =
    IMPORTING
      e_ekorg                    = p_ekorg
    EXCEPTIONS
      more_than_one_organization = 1
      no_entry_found             = 2
      no_default_found           = 3
      error_message              = 98
      OTHERS                     = 99.

  IF sy-subrc <> 0.
*                *** Keine eindeutige EKORG bestimmbar
*                *** => KEIN FEHLER => Initialisere Rückgabe
    CLEAR:  sy-subrc,
            p_ekorg.
  ENDIF.

ENDFORM.                    " read_ekorg_with_umlag

*&---------------------------------------------------------------------*
*&      Form  read_t001w_new
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_WERKS  text
*      <--P_S_T001W  text
*----------------------------------------------------------------------*
FORM read_t001w_new
  USING
   p_werks   LIKE   t001w-werks
  CHANGING
   p_s_t001w LIKE   t001w.

  CLEAR: sy-subrc,
         p_s_t001w.

  SELECT SINGLE *
           FROM t001w
           INTO p_s_t001w
          WHERE werks = p_werks.

ENDFORM.                    " read_t001w_new
*$@008 Ende MWE-ENTW-470-UNICODE

*$@009 #mbi 4.70 RoundSimu - Anfang
*&---------------------------------------------------------------------*
*&      Form  read_tvko_single
*&---------------------------------------------------------------------*
*       Unterprogramm zum Lesen eines Satzes aus der Tabelle TVKO
*----------------------------------------------------------------------*
*  -->  p_vkorg  Verkaufsorganisation
*  <--  sy-subrc
*----------------------------------------------------------------------*
FORM read_tvko_single
  USING
    p_vkorg  LIKE  tvko-vkorg.

  CALL FUNCTION 'TVKO_SINGLE_READ'
    EXPORTING
*     KZRFB         = ' '
      vkorg         = p_vkorg
*   IMPORTING
*     WTVKO         =
    EXCEPTIONS
      not_found     = 1
      error_message = 98
      OTHERS        = 99.


ENDFORM.                    " read_tvko_single

*&---------------------------------------------------------------------*
*&      Form  read_tvkot_single
*&---------------------------------------------------------------------*
*       Unterprogramm zum Lesen eines Satzes aus der Tabelle TVKOT
*----------------------------------------------------------------------*
*  -->  p_vkorg    Verkaufsorganistation
*  <--  p_tvkot    Gelesener Datensatz (nur Rückgabe)
*----------------------------------------------------------------------*
FORM read_tvkot_single
  USING
    p_vkorg    LIKE  tvkot-vkorg
  CHANGING
    p_s_tvkot  LIKE  tvkot.

  DATA: l_spras LIKE sy-langu.

  CLEAR: p_s_tvkot.

  l_spras = sy-langu.

  CALL FUNCTION 'TVKOT_SINGLE_READ'
    EXPORTING
*     KZRFB         = ' '
      spras         = l_spras
      vkorg         = p_vkorg
    IMPORTING
      wtvkot        = p_s_tvkot
    EXCEPTIONS
      not_found     = 1
      error_message = 98
      OTHERS        = 99.
  IF sy-subrc <> 0.

    CLEAR: sy-subrc,
           p_s_tvkot.

  ENDIF.

ENDFORM.                    " read_tvkot_single

*&---------------------------------------------------------------------*
*&      Form  read_tvtwt_single
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_vtweg    Vertriebsweg
*  <--  p_tvtwt    Gelesener Datensatz (nur Rückgabe)
*----------------------------------------------------------------------*
FORM read_tvtwt_single
  USING
    p_vtweg    LIKE  tvtwt-vtweg
  CHANGING
    p_s_tvtwt  LIKE  tvtwt.

  DATA: l_spras LIKE sy-langu.

  CLEAR: p_s_tvtwt.

  l_spras = sy-langu.

  CALL FUNCTION 'TVTWT_SINGLE_READ'
    EXPORTING
*     KZRFB         = ' '
      spras         = l_spras
      vtweg         = p_vtweg
    IMPORTING
      wtvtwt        = p_s_tvtwt
    EXCEPTIONS
      not_found     = 1
      error_message = 98
      OTHERS        = 99.
  IF sy-subrc <> 0.
    CLEAR: sy-subrc,
           p_s_tvtwt.
  ENDIF.

ENDFORM.                    " read_tvtwt_single

*&---------------------------------------------------------------------*
*&      Form  read_tvtw_single
*&---------------------------------------------------------------------*
*       Test, ob Vertriebsweg existiert.
*----------------------------------------------------------------------*
*  -->  p_vtweg
*----------------------------------------------------------------------*
FORM read_tvtw_single
  USING
    p_vtweg  LIKE  tvtw-vtweg.

  CALL FUNCTION 'TVTW_SINGLE_READ'
    EXPORTING
*     KZRFB         = ' '
      vtweg         = p_vtweg
*   IMPORTING
*     WTVTW         =
    EXCEPTIONS
      not_found     = 1
      error_message = 98
      OTHERS        = 99.

  IF sy-subrc <> 0.
*                *** Fehlermeldung: Vtweg existiert nicht
    MESSAGE e122(m3) WITH p_vtweg.

  ENDIF.

ENDFORM.                    " read_tvtw_single

*&---------------------------------------------------------------------*
*&      Form  read_kna1_single
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_kunnr
*  <--  p_s_kna1
*----------------------------------------------------------------------*
FORM read_kna1_single
  USING
    p_kunnr   LIKE  kna1-kunnr
  CHANGING
    p_s_kna1  LIKE  kna1.

  CLEAR p_s_kna1.

  CALL FUNCTION 'KNA1_READ_SINGLE'
    EXPORTING
      id_kunnr            = p_kunnr
      id_cvp_behavior     = gc_cvp_raise_exc  "2269110
    IMPORTING
      es_kna1             = p_s_kna1
    EXCEPTIONS
      not_found           = 1
      input_not_specified = 2
      error_message       = 98
      OTHERS              = 99.

  IF sy-subrc <> 0.

    CLEAR: sy-subrc,
           p_s_kna1.

  ENDIF.

ENDFORM.                    " read_kna1_single

*&---------------------------------------------------------------------*
*&      Form  read_tspa_single
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_spart
*  <--  sy-subrc
*----------------------------------------------------------------------*
FORM read_tspa_single
  USING
    p_spart  LIKE  tspa-spart.

  DATA: l_wa_tspa LIKE tspa.

  SELECT SINGLE *
           FROM tspa
           INTO l_wa_tspa
          WHERE spart = p_spart.

ENDFORM.                    " read_tspa_single

*&---------------------------------------------------------------------*
*&      Form  read_tspat_single
*&---------------------------------------------------------------------*
*       Text zur Sparte lesen
*----------------------------------------------------------------------*
*  -->  p_spart   Sparte
*  <--  p_name    Name/Text zur Sparte
*----------------------------------------------------------------------*
FORM read_tspat_single
  USING
    p_spart  TYPE tspat-spart
  CHANGING
    p_name   TYPE tspat-vtext.

  DATA: l_spras LIKE sy-langu.

  CLEAR p_name.
  l_spras = sy-langu.

  CALL FUNCTION 'CLEX_READ_TABLE_TSPAT'
    EXPORTING
      language     = l_spras
      division     = p_spart
    IMPORTING
      shorttext    = p_name
    EXCEPTIONS
      no_shorttext = 1
      OTHERS       = 2.

  IF sy-subrc <> 0.

    CLEAR: sy-subrc,
           p_name.

  ENDIF.

ENDFORM.                    " read_tspat_single
*&---------------------------------------------------------------------*
*&      Form  read_tvkos_single
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_vkorg
*  -->  p_spart
*  <--  sy-subrc
*----------------------------------------------------------------------*
FORM read_tvkos_single
  USING
    p_vkorg  LIKE  tvkos-vkorg
    p_spart  LIKE  tvkos-spart.

  DATA: l_wa_tvkos LIKE tvkos.

  SELECT SINGLE  *
           FROM  tvkos
           INTO  l_wa_tvkos
          WHERE  vkorg = p_vkorg
            AND  spart = p_spart.

ENDFORM.                    " read_tvkos_single

*&---------------------------------------------------------------------*
*&      Form  read_t024e_single
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM read_t024e_single
  USING
    p_ekorg    LIKE  t024e-ekorg
  CHANGING
    p_s_t024e  LIKE  t024e.

  CLEAR: sy-subrc,
         sy-msgid.

  CALL FUNCTION 'MEX_READ_T024E'
    EXPORTING
      im_ekorg      = p_ekorg
    IMPORTING
      ex_t024e      = p_s_t024e
    EXCEPTIONS
      not_found     = 1
      error_message = 98
      OTHERS        = 99.

  IF sy-subrc <> 0.

    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
*                *** => Hier wird immer ein Error (= c_msgty_e)
*                *** ausgegeben!
      MESSAGE ID sy-msgid TYPE c_msgty_e NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'MEX_READ_T024E'.
    ENDIF.

  ENDIF.

ENDFORM.                    " read_t024e_single

*&---------------------------------------------------------------------*
*&      Form  read_t163_single
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_pstyp
*  <--  sy-subrc
*----------------------------------------------------------------------*
FORM read_t163_single
  USING
    p_pstyp  LIKE  t163-pstyp.

  CALL FUNCTION 'MEX_READ_T163'
    EXPORTING
      i_pstyp       = p_pstyp
* IMPORTING
*     E_T163        =
    EXCEPTIONS
      not_found     = 1
      error_message = 98
      OTHERS        = 99.

ENDFORM.                    " read_t163_single

*&---------------------------------------------------------------------*
*&      Form  read_t163y_single
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_pstyp
*  <--  p_name
*----------------------------------------------------------------------*
FORM read_t163y_single
  USING
    p_pstyp  LIKE  t163y-pstyp
  CHANGING
    p_name   LIKE  t163y-ptext.

  DATA: l_langu    LIKE sy-langu,
        l_wa_t163y LIKE t163y.

  CLEAR: p_name.

  l_langu = sy-langu.

  SELECT SINGLE *
           FROM t163y
           INTO l_wa_t163y
          WHERE spras = l_langu
            AND pstyp = p_pstyp.

  IF sy-subrc = 0.
    p_name = l_wa_t163y-ptext.
  ENDIF.

ENDFORM.                    " read_t163y_single

*&---------------------------------------------------------------------*
*&      Form  read_mara_single_online
*&---------------------------------------------------------------------*
*       MARA-Eintrag für den Online-Fall (Aufruf
*----------------------------------------------------------------------*
*      -->P_MATNR    text
*      <--P_S_MARA   text
*----------------------------------------------------------------------*
FORM read_mara_single_online
  USING
    VALUE(p_matnr)  LIKE  mara-matnr
  CHANGING
    p_s_mara        TYPE  mara.

  CLEAR: p_s_mara,
         sy-msgid.

  CALL FUNCTION 'MARA_SINGLE_READ'
    EXPORTING
*     KZRFB             = ' '
*     MAXTZ             = 0
      matnr             = p_matnr
*     SPERRMODUS        = ' '
*     STD_SPERRMODUS    = ' '
*     OUTPUT_NO_MESSAGE =
    IMPORTING
      wmara             = p_s_mara
    EXCEPTIONS
      lock_on_material  = 1
      lock_system_error = 2
      wrong_call        = 3
      not_found         = 4
      error_message     = 98
      OTHERS            = 99.

  IF sy-subrc <> 0.

    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch (ohne Ausnahme)
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      SET PARAMETER ID 'MAT' FIELD p_matnr.
      SET PARAMETER ID 'MXX' FIELD '0'.

      MESSAGE e002(rpudb) WITH p_matnr.

    ENDIF.

  ENDIF.

ENDFORM.                    " read_mara_single_online

*&---------------------------------------------------------------------*
*&      Form  read_lfa1_single_2
*&---------------------------------------------------------------------*
*       Bestimme die Daten aus der LFA1 zu einem Lieferanten
*       (mit Pufferung) für den Onlinefall ohne Setzen einer Ausnahem
*       im Fehlerfall
*----------------------------------------------------------------------*
*      -->P_LIFNR     Lieferant
*      <--P_S_LFA1    Bestimmte LFA1-Daten
*----------------------------------------------------------------------*
FORM read_lfa1_single_2
  USING
    VALUE(p_lifnr)   LIKE  lfa1-lifnr
  CHANGING
    p_s_lfa1         TYPE  lfa1.

  CLEAR:   p_s_lfa1.

  CALL FUNCTION 'WY_LFA1_SINGLE_READ'
    EXPORTING
      pi_lifnr         = p_lifnr
      pi_cvp_behavior  = gc_cvp_raise_exc "2269110
*     PI_BYPASSING_BUFFER =            => Default: - Puffer nutzen
*     PI_REFRESH_BUFFER   =            =>          - kein Refresh
    IMPORTING
      po_lfa1          = p_s_lfa1
    EXCEPTIONS
      no_records_found = 1
      error_message    = 98
      OTHERS           = 99.

  IF sy-subrc <> 0.
*                *** Existiert kein Eintrag in der LFA1
*                *** => FEHLER!!! (nur wenn Lieferant auch belegt!!!)
    SET PARAMETER ID 'LIF' FIELD p_lifnr.
    MESSAGE e003(rpudb) WITH p_lifnr.
  ENDIF.

ENDFORM.                               " read_lfa1_single_2

*&---------------------------------------------------------------------*
*&      Form  get_rdprf_werks
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->p_rdprf
*      <->p_werks
*----------------------------------------------------------------------*
FORM get_rdprf_werks
  USING
    p_rdprf  LIKE  rdpr-rdprf
  CHANGING
    p_werks  LIKE  rdpr-werks.

  DATA l_wa_rdpr LIKE rdpr.

  SELECT SINGLE *
           FROM rdpr
           INTO l_wa_rdpr
          WHERE rdprf = p_rdprf
            AND werks = p_werks.

  IF sy-subrc <> 0.
*                *** Rundungsprofil bezieht sich auf kein Werk
    CLEAR p_werks.

  ENDIF.

ENDFORM.                    " get_rdprf_werks

*&---------------------------------------------------------------------*
*&      Form  read_control_params_0840
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <->P_S_GENERAL
*----------------------------------------------------------------------*
FORM read_control_params_0840
  CHANGING
    p_s_general  LIKE  g_s_0830_general.

  SELECT SINGLE                 *
           FROM                 rcpr
  INTO CORRESPONDING FIELDS OF  p_s_general
          WHERE                 cprof  =  p_s_general-cprof.

ENDFORM.                    " read_control_params_0840
*$@009 #mbi 4.70 RoundSimu - Ende

*
* 
