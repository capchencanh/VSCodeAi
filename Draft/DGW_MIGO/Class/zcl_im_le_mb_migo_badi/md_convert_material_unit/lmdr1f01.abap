*-------------------------------------------------------------------
***INCLUDE LMDR1F01 .
*-------------------------------------------------------------------

*----------------------------------------------------------------------*
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @001  05.01.97  12b  schweizerm  Korrekturen zu Rel.1.2b
*- @002  26.08.97  400  MWE         Änderung von Unterprogrammen, die
*                                   im FKB md_einzelrunden und im FKB
*                                   md_simu_dyn_rund_profil benutzt
*                                   werden:
*                                   - für den Aufruf von md_simu_dyn_
*                                     rund_profil darf im Fehler-Fall
*                                     keine Ausnahme gesetzt werden.
*  @003  05.01.98  40C  LDO         E-Meldungen durch S-Meldung + Raise
*                                   ersetzt.
*  @004  21.04.98  40C  MWE         Neue Lesebausteine für RDPR und RDTX
*                                   einbauen
*  @005  19.06.98  45A  LDO         Bei Buchungskreis übergreifenden
*                                   UB´s (sind NB´s wobei VZ ein
*                                   Lieferant ist), Einkaufsinfosatz
*                                   übergehen, es sei denn es ist
*                                   ein Rundungsprofil gepflegt.
*  @006  31.08.98  45B  MWE         Einkaufsinfosatz wird bei NBs
*                                   berücksichtigt, wenn mindestens
*                                   ein Feld im EK-Infosatz zur Rundung
*                                   gefüllt ist.
*  @007  23.05.99  99A  MWE         Einbau des Hinweises: 153620:
*                                   Rechenungenauigkeit bei der Umrech-
*                                   nung von ME!!!
*  @009  23.09.99  99B  MWE         Einbau des Hinweises: 167078
*                                   Rechenungenauigkeit und KurzDumps
*- @010  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @011  01.12.99  46C  mwe         Berücksichtigung von Konsignations-
*-                                  Infosätze
*-                                  Korrektur zu Hinweis: 186918
*- @012  26.04.00  46C  wsc         Korrektur Hinweis 216366
*- @013  24.09.01  470  mbi         Entfernen von nicht mehr
*-                                  durchlaufenem Coding, das aufgrund
*-                                  der Überarbeitung des Bausteins zur
*-                                  Simulation von Rundungsprofilen
*-                                  (MD_SIMU_DYN_RUND_PROFIL) entstanden
*-                                  ist
*- @014  14.01.02  470  mbi         Realisierung SMAD-Punkte
*-                                  - Verbesserung der Rundungs-
*-                                    Simulation
*-                                    (Marke: #mbi 4.70 RoundSimu )
*-                                  - Neues Steuerungscustomizing
*-                 (Marke: HWI 4.70 customizing of logistical rounding )
*-       01.01.02  470 mwe          Altes Coding auskommentiert
*-                                  (ohne Änderungsmarke)
*----------------------------------------------------------------------*

*$@013 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_T001W
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_t001w USING value(werk) LIKE t001w-werks.
*$  CLEAR sy-subrc.
*$  IF t001w-werks <> werk.
*$    CLEAR t001w.
*$    SELECT SINGLE * FROM t001w WHERE werks = werk.
*$  ENDIF.
*$ENDFORM.                               " READ_T001W
*$@013 mbi 4.70 - Ende

*$@013 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_LFA1
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_lfa1 USING value(lief) LIKE lfa1-lifnr.
*$  IF lief IS INITIAL.
*$    CLEAR lfa1.
*$  ELSEIF lfa1-lifnr <> lief.
*$    CLEAR lfa1.
*$    SELECT SINGLE * FROM lfa1 WHERE lifnr = lief.
*$*@003-Anfang : SY-SUBRC Behandlung an der Aufrufstelle
*$*   IF SY-SUBRC <> 0.
*$*     MESSAGE E019 WITH LIEF.
*$*   ENDIF.
*$*@003-Anfang
*$  ENDIF.
*$ENDFORM.                               " READ_LFA1
*$@013 mbi 4.70 - Ende

*$@013 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_RDTX
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_rdtx USING value(werk)  LIKE t001w-werks
*$                     VALUE(RDPRF) LIKE RDPR-RDPRF
*$*@012 - A
*$                     P_SUBRC      LIKE SY-SUBRC.
*$  CLEAR P_SUBRC.
*$*@012 - E
*$  IF rdprf IS INITIAL.
*$    CLEAR rdtx.
*$  ELSEIF ( werk <> rdtx-werks ) AND ( rdprf <> rdtx-rdprf ).
*$*$@004 Anfang
*$    PERFORM call_md_rdtx_read USING    sy-langu
*$                                       rdprf
*$                                       werk
*$                              CHANGING rdtx.
*$    IF sy-subrc <> 0.
*$
*$      werk = space.
*$
*$      PERFORM call_md_rdtx_read USING    sy-langu
*$                                         rdprf
*$                                         werk
*$                                CHANGING rdtx.
*$
*$*@012 - A
*$      P_SUBRC = SY-SUBRC.
*$*@012 - E
*$    ENDIF.
*$*$    SELECT SINGLE *
*$*$    FROM   rdtx
*$*$    WHERE  spras = sy-langu
*$*$    AND    werks = werk
*$*$    AND    rdprf = rdprf.
*$*$
*$*$    IF sy-subrc <> 0.
*$*$      SELECT SINGLE *
*$*$      FROM   rdtx
*$*$      WHERE  spras = sy-langu
*$*$      AND    werks = space
*$*$      AND    rdprf = rdprf.
*$*$*@003-Anfang : SY-SUBRC Behandlung an der Aufrufstelle
*$*$*     IF SY-SUBRC <> 0.
*$*$*       MESSAGE E020 WITH RDPRF.
*$*$*     ENDIF.
*$*$*@003-Ende
*$*$    ENDIF.
*$*$@004 Ende
*$  ENDIF.
*$ENDFORM.                               " READ_RDTX
*$@013 mbi 4.70 - Ende

*$@013 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_MATERIAL
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_material USING value(matnr) LIKE mara-matnr
*$                         value(werk)  LIKE t001w-werks.
*$  DATA: l_mtcom LIKE mtcom.
*$  DATA: l_mtcor LIKE mtcor.
*$  DATA: BEGIN OF l_t_void OCCURS 0,
*$          dum TYPE c,
*$        END OF l_t_void.
*$
*$  PERFORM read_mara USING matnr.
*$  PERFORM read_marc USING matnr werk.
*$
*$  l_mtcom-kenng = 'MAKT'.
*$  l_mtcom-matnr = matnr.
*$  l_mtcom-spras = sy-langu.
*$  l_mtcom-kzspr = c_nein.
*$
*$  CALL FUNCTION 'MATERIAL_READ'
*$       EXPORTING
*$            schluessel = l_mtcom
*$       IMPORTING
*$            matdaten   = makt
*$            return     = l_mtcor
*$       TABLES
*$            seqmat01   = l_t_void.
*$ENDFORM.                               " READ_MATERIAL
*$@013 mbi 4.70 - Ende

*$@013 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_INFORECORD
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_inforecord USING value(infonr) LIKE eina-infnr
*$                           value(ekorg)  LIKE eine-ekorg
*$*$@011 Anfang MWE-HW-186918
*$                           value(pstyp)  LIKE ekpo-pstyp
*$*$@011 Ende MWE-HW-186918
*$                           value(lifnr)  LIKE eina-lifnr
*$                           value(matnr)  LIKE eina-matnr
*$                           value(werk)   LIKE eine-werks
*$                           value(satnr)  LIKE mara-satnr
*$                           value(attyp)  LIKE mara-attyp.
*$
*$  CONSTANTS: c_esokz_normal LIKE meico-esokz VALUE '0'.
*$*$@011 Anfang MWE-HW-186918
*$  CONSTANTS: c_esokz_konsi  LIKE meico-esokz VALUE '2'.
*$*$@011 Ende MWE-HW-186918
*$
*$  DATA: l_meico LIKE meico.
*$*@005-Anfang
*$  DATA: l_werks LIKE t001w-werks.
*$*@005-Ende
*$
*$  CLEAR: eine, eina.
*$  l_meico-infnr = infonr.
*$*$@011 Anfang MWE-HW-186918
*$*$  l_meico-esokz = c_esokz_normal.
*$  IF pstyp = c_esokz_konsi.
*$    l_meico-esokz = c_esokz_konsi.
*$  ELSE.
*$    l_meico-esokz = c_esokz_normal.
*$  ENDIF.
*$*$@011 Ende MWE-HW-186918
*$  l_meico-ekorg = ekorg.
*$  l_meico-werks = werk.
*$  l_meico-lifnr = lifnr.
*$  l_meico-matnr = matnr.
*$  l_meico-satnr = satnr.
*$  l_meico-attyp = attyp.
*$  l_meico-infsa = ' '.
*$
*$  CALL FUNCTION 'ME_READ_INFORECORD'
*$       EXPORTING
*$            incom             = l_meico
*$       IMPORTING
*$            einadaten         = eina
*$            einedaten         = eine
*$       EXCEPTIONS
*$            bad_comin         = 01
*$            bad_material      = 02
*$            bad_materialclass = 03
*$            bad_supplier      = 04
*$            not_found         = 05.
*$
*$*@005-Anfang
*$* Sonderfall Buchungskreisübergreifende UB´s
*$* ( = NB´s mit VZ als Lieferant)
*$  IF g_u02-i_opcode = mdr1p_c_op_mm_normal.
*$*   Kein Infosatz vorhanden, dann bleibt wie gehabt.
*$    CHECK sy-subrc = 0.
*$*   Infosatz mit Rundungsprofil, dann zieht der Infosatz.
*$    CHECK eine-rdprf IS INITIAL
*$      AND eine-minbm IS INITIAL        " @006
*$      AND eine-bstma IS INITIAL.       " @006
*$*   Prüfen ob Buchungskreisübergreifende UB, dann Infosatz ignorieren.
*$    SELECT werks FROM t001w INTO l_werks
*$      WHERE lifnr = lifnr.
*$    ENDSELECT.
*$    IF sy-subrc = 0.
*$*     Lieferant ist ein VZ, somit Infosatz übergehen.
*$      sy-subrc = 4.
*$      CLEAR eina.
*$      CLEAR eine.
*$    ELSE.
*$*     Lieferant ist kein VZ, somit Infosatz beachten.
*$      sy-subrc = 0.
*$    ENDIF.
*$  ENDIF.
*$*@005-Ende
*$
*$ENDFORM.                               " READ_INFORECORD
*$@013 mbi 4.70 - Ende

*$@013 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_EKORG
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_ekorg USING value(werk)    LIKE t001w-werks
*$                      value(kzumlag) TYPE c
*$                      ekorg          LIKE eine-ekorg.
*$
*$  CALL FUNCTION 'ME_SELECT_EKORG_FOR_PLANT'
*$     EXPORTING
*$          i_werks                    = werk
*$*         I_PIPEL                    =
*$          i_umlag                    = kzumlag
*$*         I_KONSI                    =
*$     IMPORTING
*$          e_ekorg                    = ekorg
*$     EXCEPTIONS
*$          more_than_one_organization = 1
*$          no_entry_found             = 2
*$          no_default_found           = 3
*$          OTHERS                     = 4.
*$ENDFORM.                               " READ_EKORG
*$013 mbi 4.70 - Ende

**&---------------------------------------------------------------------
*
**&      Form  CONV2UNIT
**&---------------------------------------------------------------------
*
*FORM conv2unit USING menge TYPE mdr1p_p_16_dec_14
*                     value(von_me) LIKE mara-meins
*                     value(in_me)  LIKE mara-meins.
*  DATA: l_umrez TYPE mdr1p_p_16_dec_14.
*  DATA: l_umren TYPE mdr1p_p_16_dec_14.
*  DATA: l_addko LIKE t006-addko.
*  DATA: l_kz_found TYPE c.
*
** überhaupt was machen?
*  CHECK NOT menge IS INITIAL.
*  CHECK von_me <> in_me.
*
** in die Basis-ME umrechnen
*  IF von_me <> mara-meins.
**   Konvertierung schon gecachet?
*    PERFORM get_me USING mara-matnr von_me l_kz_found
*                         l_umrez l_umren l_addko.
*    IF l_kz_found = c_ja.
**$@007 Anfang  MWE-HW-153620
**$      menge = ( menge + l_addko ) * ( l_umrez / l_umren ).
*      menge =   ( menge + l_addko )
*              * ( l_umrez *  100000 / l_umren )
*              / 100000.
**$@007 Ende  MWE-HW-153620
*    ELSE.
*      CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
*        EXPORTING
*          input                = menge
*          kzmeinh              = c_ja
*          matnr                = mara-matnr
*          meinh                = von_me
*          meins                = mara-meins
*          type_umr             = '3'
*        IMPORTING
*          addko                = l_addko
*          output               = menge
*          umren                = l_umren
*          umrez                = l_umrez
*        EXCEPTIONS
*          conversion_not_found = 1
*          input_invalid        = 2
*          material_not_found   = 3
*          meinh_not_found      = 4
*          meins_missing        = 5
*          no_meinh             = 6
*          output_invalid       = 7
*          overflow             = 8
*          error_message        = 99
*          OTHERS               = 9.
*      IF sy-subrc = 1 OR sy-subrc = 4 OR sy-subrc = 6.
*        IF g_call_place_up  =  mdr1p_c_op_maintain_rdpf.    " @002
**         Fehlerausgabe beim Aufruf aus FKB md_simu_dyn_rund...  " @002
*          MESSAGE e062 WITH von_me.                         " @002
*        ELSE.                                               " @002
**         Bei sonstigen Aufrufen ist g_call_place_up             " @002
**         initialisiert => setzen der Ausnahme.                  " @002
*          RAISE meinh_not_found.
*        ENDIF.                                              " @002
*      ENDIF.
**     Konvertierung im Cache merken
*      PERFORM set_me USING mara-matnr von_me
*                           l_umrez l_umren l_addko.
*    ENDIF.
*  ENDIF.
*
** dann in die Alternativ-ME
*  IF in_me <> mara-meins.
**   Konvertierung schon gecachet?
*    PERFORM get_me USING mara-matnr in_me l_kz_found
*                         l_umrez l_umren l_addko.
*    IF l_kz_found = c_ja.
*      menge = ( l_umren / l_umrez ) * menge - l_addko.
*    ELSE.
*      CALL FUNCTION 'MATERIAL_UNIT_CONVERSION'
*        EXPORTING
*          input                = menge
*          kzmeinh              = c_nein
*          matnr                = mara-matnr
*          meinh                = in_me
*          meins                = mara-meins
*          type_umr             = '3'
*        IMPORTING
*          addko                = l_addko
*          output               = menge
*          umren                = l_umren
*          umrez                = l_umrez
*        EXCEPTIONS
*          conversion_not_found = 1
*          input_invalid        = 2
*          material_not_found   = 3
*          meinh_not_found      = 4
*          meins_missing        = 5
*          no_meinh             = 6
*          output_invalid       = 7
*          overflow             = 8
*          error_message        = 99
*          OTHERS               = 9.
*      IF sy-subrc = 1 OR sy-subrc = 4 OR sy-subrc = 6.
*        IF g_call_place_up  =  mdr1p_c_op_maintain_rdpf.    " @002
**         Fehlerausgabe beim Aufruf aus FKB md_simu_dyn_rund...  " @002
*          MESSAGE e062 WITH in_me.                          " @002
*        ELSE.                                               " @002
**         Bei sonstigen Aufrufen ist g_call_place_up             " @002
**         initialisiert => setzen der Ausnahme.                  " @002
*          RAISE meinh_not_found.
*        ENDIF.                                              " @002
*      ENDIF.
**     Konvertierung im Cache merken
*      PERFORM set_me USING mara-matnr in_me
*                           l_umrez l_umren l_addko.
*    ENDIF.
*  ENDIF.
*ENDFORM.                                                    " CONV2UNIT
*$@014 Anfang #mbi 4.70 RoundSimu
**&---------------------------------------------------------------------
*
**&      Form  FCODE_ERFASSUNG
**&---------------------------------------------------------------------
*
*FORM fcode_erfassung.
*
*  CASE g_fcode.
*
*    WHEN c_fc_refd.
*      SET SCREEN 0.
*      LEAVE SCREEN.
*
*    WHEN c_fc_rund.
*      SET SCREEN 0.
*      LEAVE SCREEN.
*
*  ENDCASE.
*
*ENDFORM.                               " FCODE_ERFASSUNG
*$@014 Ende #mbi 4.70 RoundSimu

**&---------------------------------------------------------------------
*
**&      Form  MENGEN_ANPASSEN
**&---------------------------------------------------------------------
*
*FORM mengen_anpassen.
*  DATA: l_menge TYPE mdr1p_p_16_dec_14.
*
** Menge in die neue Alternativ-ME umrechnen
*  l_menge = g_list1-menge.
*  PERFORM conv2unit USING l_menge g_list1-bstme g_list1-altme.
*  PERFORM use_decan USING l_menge g_list1-altme.
*  g_list1-amenge = l_menge.
** Restmenge berechnen
*  PERFORM conv2unit USING l_menge g_list1-altme g_list1-bstme.
*  l_menge = g_list1-menge - l_menge.
*  PERFORM use_decan USING l_menge g_list1-bstme.
*  g_list1-restmng = l_menge.
*ENDFORM.                               " MENGEN_ANPASSEN
**&---------------------------------------------------------------------
*
**&      Form  F4_ALTME
**&---------------------------------------------------------------------
*
*FORM f4_altme.
**  DATA: L_FIELD(30) TYPE C.
**  DATA: L_LINE      LIKE SY-TABIX.
*  DATA: l_numlines  LIKE sy-tabix.
*  DATA: l_meins     LIKE mara-meins.
*  DATA: l_display   TYPE c.
*
*  DATA: BEGIN OF l_t_fieldtab OCCURS 0.
*          INCLUDE STRUCTURE help_value.
*  DATA: END OF l_t_fieldtab.
*
*  DATA: BEGIN OF l_t_valuetab OCCURS 0,
*          text(100),
*        END OF l_t_valuetab.
*
*  DATA: BEGIN OF l_t_metab OCCURS 0,
*          meinh  LIKE marm-meinh,
*          msehl  LIKE t006a-msehl,
*          umrez  LIKE marm-umrez,
*          umren  LIKE marm-umren,
*          inhalt LIKE marm-umrez,
*         END OF l_t_metab.
*
*  DATA: BEGIN OF l_t_rmmme OCCURS 0.
*          INCLUDE STRUCTURE rmmme.
*  DATA: END OF l_t_rmmme.
**----------------------------------------------------------------------
** anzuzeigende Felder bekanntgeben, Schlüsselfelder definieren
*  l_t_fieldtab-tabname = 'MARM'.
*  l_t_fieldtab-fieldname = 'MEINH'.
*  l_t_fieldtab-selectflag = c_ja.
*  APPEND l_t_fieldtab.
*  l_t_fieldtab-tabname = 'MARM'.
*  l_t_fieldtab-fieldname = 'UMREZ'.
*  l_t_fieldtab-selectflag = c_nein.
*  APPEND l_t_fieldtab.
*  l_t_fieldtab-tabname = 'T006A'.
*  l_t_fieldtab-fieldname = 'MSEHL'.
*  l_t_fieldtab-selectflag = c_nein.
*  APPEND l_t_fieldtab.
*
** ME's zum Artikel sammeln. Dazu wird jedes anzuzeigende Feld
** in eine Zeile von l_t_valuetab geschrieben
** alternative Mengeneinheiten lesen
*  READ TABLE g_t_list1 INDEX 1.
*  g_list1 = g_t_list1.
*
*  CALL FUNCTION 'MATERIAL_UNIT_FIND'
*    EXPORTING
*      kzall      = c_nein        "nur die zum Artikel
*      matnr      = g_box1-matnr
*    TABLES
*      rmmme_itab = l_t_rmmme.    "mögliche Mengeneinheiten
*
** dazu die Texte aus T006A lesen
*  LOOP AT l_t_rmmme.
*    l_t_metab-meinh = l_t_rmmme-meinh.
*    l_t_metab-umrez = l_t_rmmme-umrez.
*    l_t_metab-umren = l_t_rmmme-umren.
*
*    CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
*      EXPORTING
*        language       = sy-langu
*        input          = l_t_rmmme-meinh
*      IMPORTING
*        output         = l_t_metab-meinh
*        long_text      = l_t_metab-msehl
*      EXCEPTIONS
*        unit_not_found = 01.
*    IF sy-subrc > 0.
*      l_t_metab-meinh = l_t_rmmme-meinh.
*      l_t_metab-msehl = l_t_rmmme-meinh.
*    ENDIF.
*    APPEND l_t_metab.
*  ENDLOOP.
*
** ME's nach Größe sortieren
*  LOOP AT l_t_metab.
*    CLEAR l_t_metab-inhalt.
*    IF l_t_metab-umren <> 0.
*      l_t_metab-inhalt = l_t_metab-umrez / l_t_metab-umren.
*    ENDIF.
*    MODIFY l_t_metab.
*  ENDLOOP.
*  SORT l_t_metab BY inhalt.
*
** l_t_valuetab aufbauen
*  LOOP AT l_t_metab.
**   1. Mengeneinheit
*    l_t_valuetab-text = l_t_metab-meinh.
*    APPEND l_t_valuetab.
**   2. Inhalt
*    CLEAR l_t_valuetab-text.
*    WRITE l_t_metab-inhalt TO l_t_valuetab-text
*          USING EDIT MASK '_____'.
*    APPEND l_t_valuetab.
**   3. Bezeichnung
*    l_t_valuetab-text = l_t_metab-msehl.
*    APPEND l_t_valuetab.
*  ENDLOOP.
*
** überhaupt was gefunden?
*  DESCRIBE TABLE l_t_valuetab LINES l_numlines.
*  IF l_numlines <= 0.
*    MESSAGE s017.
*    EXIT.
*  ENDIF.
*
** Popup ausgeben mit Auswahlmöglichkeit
*  l_display = c_nein.
*
*  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
*    EXPORTING
**            CUCOL         = 1
**            CUROW         = 1
*             display       = l_display
*             fieldname     = 'MEINH'   "für die Überschrift
*             tabname       = 'MARM'
*             no_conversion = c_ja
*    IMPORTING
*             select_value  = l_meins
*    TABLES
*             fields        = l_t_fieldtab
*             valuetab      = l_t_valuetab
*    EXCEPTIONS
*             field_not_in_ddic = 1
*             more_then_one_selectfield = 2
*             no_selectfield = 3.
*
*  CHECK NOT l_meins IS INITIAL.
*
*  g_list1-altme = l_meins.
** Mengenfelder an neue ME anpassen
*  PERFORM mengen_anpassen.
** geänderte Felder am Screen neu ausgeben
*  PERFORM screen_anpassen.
*  g_t_list1 = g_list1.
*  MODIFY g_t_list1 INDEX 1.
*ENDFORM.                                                    " F4_ALTME
**&---------------------------------------------------------------------
*
**&      Form  SCREEN_ANPASSEN
**&---------------------------------------------------------------------
*
*FORM screen_anpassen.
*  DATA: BEGIN OF l_t_fields OCCURS 0.
*          INCLUDE STRUCTURE dynpread.
*  DATA: END OF l_t_fields.
*
*  l_t_fields-stepl = 1.
*
*  l_t_fields-fieldname  = 'G_T_LIST1-MENGE'.
*  WRITE g_list1-menge TO l_t_fields-fieldvalue LEFT-JUSTIFIED
*        UNIT g_t_list1-bstme.
*  APPEND l_t_fields.
*  l_t_fields-fieldname  = 'G_T_LIST1-AMENGE'.
*  WRITE g_list1-amenge TO l_t_fields-fieldvalue LEFT-JUSTIFIED
*        UNIT g_t_list1-altme.
*  APPEND l_t_fields.
*  l_t_fields-fieldname  = 'G_T_LIST1-RESTMNG'.
*  WRITE g_list1-restmng TO l_t_fields-fieldvalue LEFT-JUSTIFIED
*        UNIT g_t_list1-bstme.
*  APPEND l_t_fields.
*
*  PERFORM set_value_on_screen TABLES l_t_fields.
*ENDFORM.                               " SCREEN_ANPASSEN
*
**&---------------------------------------------------------------------
*
**&      Form  SET_VALUE_ON_SCREEN
**&---------------------------------------------------------------------
*
*FORM set_value_on_screen TABLES dynpfields STRUCTURE dynpread.
*  DATA: l_repid LIKE sy-repid.
*  DATA: l_dynnr LIKE sy-dynnr.
*
** dem FuBau keine Referenz auf SY-Felder geben!!!
*  l_repid = sy-repid.
*  l_dynnr = sy-dynnr.
*
*  CALL FUNCTION 'DYNP_VALUES_UPDATE'
*    EXPORTING
*      dyname     = l_repid
*      dynumb     = l_dynnr
*    TABLES
*      dynpfields = dynpfields
*    EXCEPTIONS
*      OTHERS     = 1.
*ENDFORM.                               " SET_VALUE_ON_SCREEN
*
***&--------------------------------------------------------------------
*
**&      Form  CHECK_AMENGE
**&---------------------------------------------------------------------
*
*FORM check_amenge.
*  DATA: l_menge TYPE mdr1p_p_16_dec_14.
*  DATA: l_bestell_menge TYPE mdr1p_p_16_dec_14.
*
** Menge und Rest in Bestell-ME neu berechnen
*  l_menge = g_t_list1-amenge.
*  PERFORM use_decan USING l_menge g_list1-altme.
*  g_list1-amenge = l_menge.
*  PERFORM conv2unit USING l_menge g_list1-altme g_list1-bstme.
*  l_menge = l_menge + g_list1-restmng.
*  PERFORM use_decan USING l_menge g_list1-bstme.
*  g_list1-menge = l_menge.
** überprüfen, ob Gleichheit noch eingehalten ist, oder ob die
** Alternativ-ME sich nicht mit der Bestell-ME verträgt
*  l_bestell_menge = l_menge.
*  l_menge = g_list1-amenge.
*  PERFORM conv2unit USING l_menge g_list1-altme g_list1-bstme.
*  l_menge = l_menge + g_list1-restmng.
*  IF l_bestell_menge <> l_menge.
**   ME's sind unverträglich => Alternativmenge als Restmenge nehmen
*    g_list1-restmng = l_bestell_menge.
*    g_list1-amenge  = 0.
*  ENDIF.
** Rundungen durchführen
*  PERFORM runde_logistisch USING g_list1.
** geänderte Felder neu ausgeben
*  PERFORM screen_anpassen.
*ENDFORM.                               " CHECK_AMENGE
**&---------------------------------------------------------------------
*
**&      Form  CHECK_ALTME
**&---------------------------------------------------------------------
*
*FORM check_altme.
*  DATA: l_meins(3) TYPE c.
*
** MARM nur prüfen wenn nicht die Basis-ME eingegeben wurde
*  g_list1-altme = g_t_list1-altme.
*  IF g_list1-altme = mara-meins.
*    CLEAR sy-subrc.
*  ELSE.
*    SELECT SINGLE *
*    FROM  marm
*    WHERE matnr = g_box1-matnr
*    AND   meinh = g_list1-altme.
*  ENDIF.
*
*  IF sy-subrc <> 0.
*    l_meins = g_list1-altme.
*    MESSAGE w007 WITH g_box1-matnr l_meins.
*  ELSE.
**   Mengen an neue Einheit anpassen
*    PERFORM mengen_anpassen.
**   geänderte Felder neu anzeigen
*    PERFORM screen_anpassen.
*  ENDIF.
*ENDFORM.                               " CHECK_ALTME
**&---------------------------------------------------------------------
*
**&      Form  CHECK_RESTMNG
**&---------------------------------------------------------------------
*
*FORM check_restmng.
*  DATA: l_menge TYPE mdr1p_p_16_dec_14.
*
*  l_menge = g_t_list1-restmng.
*  PERFORM use_decan USING l_menge g_list1-altme.
*  g_list1-restmng = l_menge.
** Menge in Bestell-ME neu berechnen
*  l_menge = g_list1-amenge.
*  PERFORM conv2unit USING l_menge g_list1-altme g_list1-bstme.
*  l_menge = l_menge + g_list1-restmng.
*  PERFORM use_decan USING l_menge g_list1-bstme.
*  g_list1-menge = l_menge.
*  PERFORM mengen_anpassen.
** Rundungen durchführen
*  PERFORM runde_logistisch USING g_list1.
** geänderte Felder neu ausgeben
*  PERFORM screen_anpassen.
*ENDFORM.                               " CHECK_RESTMNG
**&---------------------------------------------------------------------
*
**&      Form  RUNDE_LOGISTISCH
**&---------------------------------------------------------------------
*
*FORM runde_logistisch USING value(list1) LIKE LINE OF g_t_list1.
*  DATA: l_opcode LIKE sy-input.
*  DATA: l_imenge TYPE f,                                    "@001
*        l_elmenge TYPE f.
*
**$@014 Anfang HWI 4.70 customizing of logistical rounding
*  DATA: l_s_general  TYPE  mdr1insingleround,
*        l_s_results  TYPE  mdr1outsingleround.
**$@014 Ende HWI 4.70 customizing of logistical rounding
*
*  IF g_u01-kz_ub = c_nein.
*    l_opcode = mdr1p_c_op_mm_normal.
*  ELSE.
*    l_opcode = mdr1p_c_op_mm_ub.
*  ENDIF.
*  l_imenge = list1-menge.                                   "@001
*
**$@014 Anfang HWI 4.70 customizing of logistical rounding
**$  CALL FUNCTION 'MD_EINZELRUNDUNG'
**$    EXPORTING
**$     i_opcode           = l_opcode
**$      i_matnr            = g_box1-matnr
**$      i_menge            = l_imenge                         "@001
**$      i_meins            = list1-bstme
**$      i_werk             = g_box1-werk
**$      i_lifnr            = g_u01-lifnr
**$      i_ekorg            = g_u01-i_ekorg
**$      i_infnr            = eina-infnr
**$    IMPORTING
**$      e_lmenge           = l_elmenge                        "@001
**$      e_logme            = g_box1-logme
**$    EXCEPTIONS
**$      invalid_opcode     = 1
**$      no_purchase_org    = 2
**$      rdpr_not_found     = 3
**$      material_not_found = 4
**$      meinh_not_found    = 5
**$      bad_params         = 6
**$      OTHERS             = 7.
*  l_s_general-opcode  =  l_opcode.
*  l_s_general-matnr   =  g_box1-matnr.
*  l_s_general-menge   =  l_imenge.
*  l_s_general-meinh   =  list1-bstme.
*  l_s_general-werks   =  g_box1-werk.
*  l_s_general-lifnr   =  g_u01-lifnr.
*  l_s_general-ekorg   =  g_u01-i_ekorg.
*  l_s_general-infnr   =  eina-infnr.
*
*  CALL FUNCTION 'MD_SINGLE_ROUNDING'
*    EXPORTING
*      i_s_general        = l_s_general
*    IMPORTING
*      e_s_results        = l_s_results
*    EXCEPTIONS
*      invalid_opcode     = 1
*      no_purchase_org    = 2
*      rdpr_not_found     = 3
*      material_not_found = 4
*      meinh_not_found    = 5
*      bad_params         = 6
*      debitor_not_found  = 7
*      no_round           = 8
*      rdprf_not_found    = 9
*      error              = 10
*      OTHERS             = 11.
*
*  l_elmenge     =  l_s_results-lmenge.
*  g_box1-logme  =  l_s_results-logme.
*
**$@014 Ende HWI 4.70 customizing of logistical rounding
*
*  IF sy-subrc = 0.
*    g_box1-lmenge = l_elmenge.
*  ELSE.
*    g_box1-lmenge = 0.
*  ENDIF.
*
*ENDFORM.                               " RUNDE_LOGISTISCH
**&---------------------------------------------------------------------
*
**&      Form  USE_DECAN
**& Menge gemäß der Dezimalstellen einer ME in T006 runden
**&---------------------------------------------------------------------
*
*FORM use_decan USING menge TYPE mdr1p_p_16_dec_14
*                     value(altme) LIKE marm-meinh.
*  DATA: l_menge TYPE mdr1p_p_16_dec_14.
**$@009 Anfang  MWE-HW-167078
**$  DATA: l_mul TYPE f.
*  DATA: l_mul(16)   TYPE p,
*        l_ganz(16)  TYPE p,
*        l_trunc(16) TYPE p.
**$@009 Ende  MWE-HW-167078
*  STATICS: s_t_t006 LIKE t006 OCCURS 0.
*  STATICS: s_t006 LIKE t006.
*  STATICS: s_first_time TYPE c VALUE c_ja.
**$@009 Anfang  MWE-HW-167078
*  DATA: l_help_menge(16)  TYPE  p  DECIMALS 14.
*  DATA: l_help_quan       LIKE  ekpo-menge.
*
*  CLEAR: l_help_menge.
*
*  sy-subrc = 0.
**$@009 Ende  MWE-HW-167078
*
*  l_menge = menge.
*  IF s_first_time = c_ja.
*    s_first_time = c_nein.
*    SELECT *
*    INTO   TABLE s_t_t006
*    FROM   t006.
*  ENDIF.
*  IF s_t006-msehi <> altme.
*    READ TABLE s_t_t006 INTO s_t006 WITH KEY msehi = altme.
*  ENDIF.
*
**$@009 Anfang  MWE-HW-167078
**$  IF sy-subrc = 0.
**$    IF s_t006-andec = 0.
**$      l_menge = TRUNC( l_menge ).
**$    ELSEIF s_t006-andec > 0.
**$      l_mul = 10 ** s_t006-andec.
**$      l_menge = l_menge * l_mul.
**$      l_menge = TRUNC( l_menge ).
**$      l_menge = l_menge / l_mul.
**$    ENDIF.
**$  ELSE.
**$    l_menge = TRUNC( l_menge ).
**$  ENDIF.
*  l_help_quan   =  l_menge.
*  l_help_menge  =  l_help_quan.
*
*  IF sy-subrc = 0.
*
*    IF s_t006-andec = 0.
*      l_help_menge = trunc( l_help_menge ).
*    ELSEIF s_t006-andec > 0.
** Abschneiden Nachkommastellen auf max. 14 Nachkommastellen wegen
** Feldüberlauf - intern wird nur mit 14 Nachkommastellen gerechnet,
** daher bei > 14 Nachkommastellen kein Abschneiden nötig!
*      IF s_t006-andec < 15.
*        l_mul = 10 ** s_t006-andec.
*        l_ganz = l_help_menge DIV 1.
*        l_help_menge = l_help_menge - l_ganz.
*        l_trunc = l_help_menge * l_mul.
*        l_help_menge = l_trunc / l_mul.
*        l_help_menge = trunc( l_help_menge ).
*      ENDIF.
*    ENDIF.
*  ELSE.
*    l_help_menge = trunc( l_help_menge ).
*  ENDIF.
*
*  l_menge = l_help_menge.
**$@009 Ende  MWE-HW-167078
*
*  menge = l_menge.
*
*ENDFORM.                               " USE_DECAN
*
**&---------------------------------------------------------------------
*
**&      Form  GET_ME
**& Mengeneinheit aus dem ME-Cache ermitteln
**&---------------------------------------------------------------------
*
*FORM get_me USING value(matnr) LIKE marm-matnr
*                  value(meinh) LIKE marm-meinh
*                  kz_found     TYPE c
*                  umrez        TYPE mdr1p_p_16_dec_14
*                  umren        TYPE mdr1p_p_16_dec_14
*                  addko        LIKE t006-addko.
*  kz_found = c_nein.
*  IF g_lru_me-matnr = matnr AND
*     g_lru_me-meinh = meinh.
*    kz_found = c_ja.
*    umrez = g_lru_me-umrez.
*    umren = g_lru_me-umren.
*    addko = g_lru_me-addko.
*  ELSE.
*    READ TABLE g_t_mecache
*      WITH KEY matnr = matnr
*               meinh = meinh.
*    IF sy-subrc = 0.
*      kz_found = c_ja.
*      umrez = g_t_mecache-umrez.
*      umren = g_t_mecache-umren.
*      addko = g_t_mecache-addko.
*    ENDIF.
*  ENDIF.
*ENDFORM.                               "GET_ME
*
**&---------------------------------------------------------------------
*
**&      Form  SET_ME
**& Mengeneinheit in den ME-Cache eintragen
**&---------------------------------------------------------------------
*
*FORM set_me USING value(matnr) LIKE marm-matnr
*                  value(meinh) LIKE marm-meinh
*                  value(umrez) TYPE mdr1p_p_16_dec_14
*                  value(umren) TYPE mdr1p_p_16_dec_14
*                  value(addko) LIKE t006-addko.
*  STATICS: s_first_time TYPE c VALUE c_ja.
*  STATICS: s_tail LIKE sy-tabix.       "Löschposition
*
*  IF s_first_time = c_ja.
**   Cache mit 10 leeren Einträgen anlegen
*    s_first_time = c_nein.
*    CLEAR g_t_mecache.
*    REFRESH g_t_mecache.
*    DO c_mecache_size TIMES.
*      APPEND g_t_mecache.
*    ENDDO.
*    s_tail = 1.
*  ENDIF.
** Eintrag auf Position s_tail übernehmen
*  g_t_mecache-matnr = matnr.
*  g_t_mecache-meinh = meinh.
*  g_t_mecache-umrez = umrez.
*  g_t_mecache-umren = umren.
*  g_t_mecache-addko = addko.
*  MODIFY g_t_mecache INDEX s_tail.
** den Eintrag im LRU merken
*  g_lru_me = g_t_mecache.
** s_tail eins hochsetzen bzw. wieder vorne anfangen
*  s_tail = s_tail + 1.
*  IF s_tail > c_mecache_size.
*    s_tail = 1.
*  ENDIF.
*ENDFORM.                               "SET_ME

*
* 
