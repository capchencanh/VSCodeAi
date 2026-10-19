*-------------------------------------------------------------------
***INCLUDE LMDR1F02 .
*-------------------------------------------------------------------

*----------------------------------------------------------------------*
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @001  05.01.97  12b  schweizerm  Korrekturen zu Rel. 1.2b
*- @002  06.03.97  400  schweizerm  Korrektur: Verwendung von I_RDPR
*- @003  20.03.97  400  Doneyer     Korrektur: Verwendung von I_RDPR
*- @004  07.08.97  400  Doneyer     Bestimmen der Mengeneinheitengruppe
*                                   bei UB wenn PRUEFE-LIEFERANT
*                                   markiert ist und kein Einkaufsinfo-
*                                   satz vorhanden ist.
*- @005  20.08.97  400  Doneyer     Auch bei UB´s variable Bestell-ME
*                                   zulassen
*- @006  26.08.97  400  mwe         Änderung von Unterprogrammen, die
*                                   im FKB md_einzelrunden und im FKB
*                                   md_simu_dyn_rund_profil benutzt
*                                   werden:
*                                   - für den Aufruf von md_simu_dyn_
*                                     rund_profil darf im Fehler-Fall
*                                     keine Ausnahme gesetzt werden.
*- @007  03.09.97  400  mwe         Beim Runden mit Rundungsmethode '2'
*                                   (dyn. Rundungsmethode) werden die
*                                   folgenden Schritte durchgeführt:
*                                   1. die Menge mit Hilfe des dyn.
*                                      Rundungsprofils (i_rdpr)
*                                      gerundet
*                                   2. wenn keine Rundung im 1. Schritt
*                                      durchgeführt wurde,
*                                      wird die Menge noch auf die
*                                      Bestell-Mengeneinheit aufgerundet
*- @008  27.10.97  400  mwe         Bei Eingabemenge = 0 erfolgt keine
*-                                  Rundung
*- @009  22.01.98  40B  mwe         Rundungsgründe richtig setzen:
*- @010  08.04.98  40C  mwe         Erweiterungen zu 40c:
*-                                  - neue Rundungsmethode Auf- und
*-                                    Abschlag
*-                                  - neue Lesebausteine für die
*-                                    RDPR und RDTX
*- @011  16.04.98  40C  Doneyer     Bei UB´s muss nicht die Lieferanten-
*-                                  nummer des abgebenden Werks
*-                                  übergeben werden. Falls diese
*-                                  nicht existiert reicht die Werks-
*-                                  nummer des abgebenden Werkes im
*-                                  Feld I_WERKS_KRED
*- @012  02.07.98  4.5A mwe         Erweiterungen für die Rundung im LB
*- @013  06.07.98  4.5A mwe         Fehlerkorrekturen zu 4.5A-Test
*- @014  31.08.98  4.5B mwe         RUNDUNGSGRUND SOLL NUR GESETZT
*-                                  werden, wenn sich die Menge
*-                                  geändert hat
*-                                  (siehe Meldungsnr.: 0000175818
*-                                   HINWEIS: 115691)
*- @015  02.11.98  99.A mwe         Die Rundung soll sich im LB (siehe
*-                                  @012) identisch zu der Bestellanlage
*-                                  verhalten, d.h. nur Rundung auf
*-                                  Bestell-ME, wenn nicht variable
*-                                  Bestell-ME gesetzt ist!!!
*- @016  10.11.98  99.A mwe         Soll immer aufgerundet werden
*-                                  (auf- und ab = 0), soll auch bei
*-                                  einem Vielfachen der Rundungs-ME
*-                                  gerundet werden (=> Anf. Metro)
*- @017  12.02.99 99.A WSC          Rundungsgrund bei statischem RDPRF
*-                                  nur setzen, wenn wirklich gerundet
*-                                  wurde
*- @018  23.05.99 99.A  mwe         Hinweis: 153574 eingebaut.
*-                                  Default für Bestell-ME = MARA-BSTME
*-                                  und nicht MARA-MEINS im Einkauf!!
*- @019  01.06.99 99.A  mwe         Hinweis: 154203 eingebaut.
*-                                  Rundungswert immer aus der MARC-
*-                                  Sicht entnehmen!
*- @020  08.11.99 46C   mwe         Der User-Exit
*-                                  userexit_cust_material_read
*-                                  zur individuellen Bestimmung
*-                                  der Kundennummer wird beim
*-                                  Lesen der KNMT nicht berücksichtigt
*-                                  => Hinweis 182741 einbauen
*- @021  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrektur zu Hinweis: 185005
*- @022  01.12.99  46C  mwe         Berücksichtigung von Konsignations-
*-                                  Infosätze
*-                                  Korrektur zu Hinweis: 186918
*- @023  04.04.01  470  mwe         Unicode-Änderungen
*-                                  Entfernen von nicht mehr
*-                                  durchlaufenem Codeing
*- @024  24.09.01  470  mbi         Entfernen von nicht mehr
*-                                  durchlaufenem Coding, das aufgrund
*-                                  der Überarbeitung des Bausteins zur
*-                                  Simulation von Rundungsprofilen
*-                                  (MD_SIMU_DYN_RUND_PROFIL) entstanden
*-                                  ist
*-       01.01.02  470 mwe          Altes Coding auskommentiert
*-                                  (ohne Änderungsmarke)
*----------------------------------------------------------------------*

*$@023 Anfang MWE-ENTW-470-UNICODE
**&---------------------------------------------------------------------
*
**&      Form  RUNDE_MM
**&---------------------------------------------------------------------
*
*FORM runde_mm.
*  DATA: l_kzekorg TYPE c.              "Kennung, daß EKOrg angegeben
*  DATA: l_menge TYPE mdr1p_p_16_dec_14.
*  DATA: l_min TYPE mdr1p_p_16_dec_14.
*  DATA: l_max TYPE mdr1p_p_16_dec_14.
*  DATA: l_bstme LIKE mara-bstme.
*  DATA: l_kz_marc TYPE c,              "Kennung, ob MARC existiert
*        l_vabme   LIKE eina-vabme.     " @015 => Kennzeichen var.
*Bst-ME
*
** Init.
*  CLEAR eina.
*  CLEAR eine.
*  CLEAR marc.
*
** MARA lesen
*  PERFORM read_mara USING g_u02-i_matnr.
*  IF sy-subrc <> 0.
*    RAISE material_not_found.
*  ENDIF.
*
** MARC lesen
*  PERFORM read_marc USING g_u02-i_matnr g_u02-i_werk.
*  IF sy-subrc = 0.
*    l_kz_marc = c_ja.
*  ELSE.
*    l_kz_marc = c_nein.
*  ENDIF.
*
** wenn gar nichts geht, dann zumindest das:
*  g_u02-e_lmenge = g_u02-i_menge.
*  g_u02-e_logme  = g_u02-i_meins.      "übergebene ME
*  g_u02-e_menge  = g_u02-i_menge.
*
** Generell wird angenommen, daß es keinen Infosatz gibt, es sei denn
** beim Lesen wird einer gefunden.
*  g_u02-kzinfosatz = c_nein.
*
*  IF NOT g_u02-i_lifnr IS INITIAL.
**   Lieferant ist angegeben
**   EKOrg ermitteln
*    l_kzekorg = c_ja.
*    IF g_u02-i_ekorg IS INITIAL.
**     falls eindeutige EKOrg zum Werk exist., nehme diese
*      PERFORM read_ekorg USING g_u02-i_werk c_nein g_u02-i_ekorg.
*      IF sy-subrc <> 0.
*        l_kzekorg = c_nein.
*      ENDIF.
*    ENDIF.
*
*    IF l_kzekorg = c_ja.
**     Einkaufsinfosatz lesen, wenn EKOrg angegeben
*      PERFORM read_inforecord USING g_u02-i_infnr g_u02-i_ekorg
**$@022 Anfang MWE-HW-186918
*                                    g_u02-i_pstyp
**$@022 Ende MWE-HW-186918
*                                    g_u02-i_lifnr g_u02-i_matnr
*                                    g_u02-i_werk
*                                    mara-satnr mara-attyp.
**     Kennung setzen, daß Infosatz existiert
*      IF sy-subrc = 0.
*        g_u02-kzinfosatz = c_ja.
*      ENDIF.
*    ENDIF.
*
**   Bestell- bzw. Verkaufs-ME ermitteln
*    PERFORM ermittle_bstme USING l_bstme.
*
**$@012 Anfang
*    IF g_lb_call = c_charx.
**     => LB-Spezialfall
*      CLEAR g_lb_change.
*
**$@015 Anfang
*      CLEAR l_vabme.
*
**     Bestimme Wert für die variable Bestell-ME
*      IF g_u02-kzinfosatz = c_ja.
**       => Wert aus Einkaufsinfosatz genommen
*        l_vabme = eina-vabme.
*      ELSE.
**       => Sonst aus MARA
*        l_vabme = mara-vabme.
*      ENDIF.
**$@015 Ende
*
*      IF  l_bstme <> g_u02-i_meins
*      AND l_vabme IS INITIAL.          " @015 bei nicht vari. ME
**       die Eingabe-Menge in Bestellmengeneinheit umwandeln
**       1. Rette die alte Werte:
*        g_lb_change   = c_charx.
*        g_lb_i_menge  = g_u02-i_menge.
*        g_lb_i_meins  = g_u02-i_meins.
**       2. Bestimme die Eingabewerte neu:
*        PERFORM conv2unit USING g_u02-i_menge g_u02-i_meins l_bstme.
*        g_u02-i_meins = l_bstme.
**       3. Ausgabe-Werte mit Default belegen
*        g_u02-e_lmenge = g_u02-i_menge.
*        g_u02-e_logme  = g_u02-i_meins.
*        g_u02-e_menge  = g_u02-i_menge.
*      ENDIF.
*    ENDIF.
**$@012 Ende
*
*    IF g_u02-kzinfosatz = c_ja.
**     Min-/Max-Schranken sind hier in Bestell-ME angegeben
**     => erst in Basis-ME umrechnen
*      CLEAR l_max. CLEAR l_min.
*      IF NOT eine-bstma IS INITIAL.
*        l_menge = eine-bstma.
*        PERFORM conv2unit USING l_menge l_bstme mara-meins.
*        l_max = l_menge.
*      ENDIF.
*      IF NOT eine-minbm IS INITIAL.
*        l_menge = eine-minbm.
*        PERFORM conv2unit USING l_menge l_bstme mara-meins.
*        l_min = l_menge.
*      ENDIF.
**$@019 Anfang  MWE-HW-154203
**$      PERFORM runde USING eine-rdprf
**$                          l_max
**$                          l_min
**$                          0            "kein Rundungswert
**$                          l_bstme.
*      IF l_kz_marc = c_ja.
*        l_menge = marc-bstrf.          "Rundungswert immer aus MARC
*      ENDIF.
*      PERFORM runde USING eine-rdprf
*                          l_max
*                          l_min
*                          l_menge
*                          l_bstme.
**$@019 Ende  MWE-HW-154203
*    ELSE.
*      IF l_kz_marc = c_ja.
*        l_max = marc-bstma.
*        l_min = marc-bstmi.
*        l_menge = marc-bstrf.          "Rundungswert
*        PERFORM runde USING marc-rdprf
*                            l_max
*                            l_min
*                            l_menge
*                            l_bstme.
*      ENDIF.
*    ENDIF.
*  ELSE.
**   kein Lieferant angegeben
**   Bestell- bzw. Verkaufs-ME ermitteln
*    PERFORM ermittle_bstme USING l_bstme.
*
*    IF l_kz_marc = c_ja.
*      l_max = marc-bstma.
*      l_min = marc-bstmi.
*      l_menge = marc-bstrf.            "Rundungswert
*      PERFORM runde USING marc-rdprf
*                          l_max
*                          l_min
*                          l_menge
*                          l_bstme.
*    ENDIF.
*  ENDIF.
*ENDFORM.                               " RUNDE_MM
*$@023 Ende MWE-ENTW-470-UNICODE

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-
*$*&      Form  RUNDE
*$*&--------------------------------------------------------------------
*$
*$FORM runde USING value(rdprf) LIKE marc-rdprf
*$                 value(bstma) TYPE mdr1p_p_16_dec_14
*$                 value(bstmi) TYPE mdr1p_p_16_dec_14
*$                 value(bstrf) TYPE mdr1p_p_16_dec_14
*$                 value(bstme) LIKE mara-bstme.
*$  DATA: l_rmenge TYPE mdr1p_p_16_dec_14.  "gerundete Menge in Basis-ME
*$  DATA: l_save TYPE mdr1p_p_16_dec_14.
*$  DATA: l_divs TYPE mdr1p_p_16_dec_14.
*$  DATA: l_qty LIKE rdpr-vormg.
*$  DATA: l_scmng TYPE mdr1p_p_16_dec_14.
*$  DATA: l_rest TYPE i,
*$        l_ganz TYPE i.
*$  DATA: l_eins TYPE mdr1p_p_16_dec_14 VALUE 1.
*$* @017-A
*$  DATA: old_mng TYPE mdr1p_p_16_dec_14.
*$* @017-E
*$
*$* @002-BEGIN
*$  IF NOT g_u02-i_rdpr-rdprf IS INITIAL.
*$    rdprf = g_u02-i_rdpr-rdprf.
*$  ENDIF.
*$
*$* in Basis-ME ausdrücken
*$  l_rmenge = g_u02-e_menge.
*$  PERFORM conv2unit USING l_rmenge g_u02-i_meins mara-meins.
*$  g_u02-e_menge = l_rmenge.
*$* wird später wieder in i_meins umgerechnet
*$* @002-END
*$
*$  IF g_u02-i_opcode = mdr1p_c_op_sd_auftrag AND
*$     rdprf IS INITIAL.
*$    l_scmng = mvke-scmng.
*$    PERFORM conv2unit USING l_scmng bstme mara-meins.
*$    l_rest = l_rmenge MOD l_scmng.
*$    l_ganz = l_rmenge DIV l_scmng.
*$    IF l_rest NE 0.
*$      g_u02-e_menge = ( l_ganz + l_eins ) * l_scmng.
*$    ENDIF.
*$    PERFORM rundungsgrund USING mdr1p_c_liefereinheit.
*$  ELSE.
*$* müssen wir überhaupt was machen?
*$    IF rdprf IS INITIAL AND
*$       bstma IS INITIAL AND
*$       bstmi IS INITIAL AND
*$       bstrf IS INITIAL.
*$*   nur auf Dezimalstellen der ME runden
*$*   Das save erst nach dem Perform, da sonst unterschiedliche ME @003
*$
*$*   L_SAVE = G_U02-E_MENGE.               "@002 @003
*$      PERFORM ermittle_logme USING bstme.                   "@002
*$      l_save   = g_u02-e_menge.                             "@003
*$
*$      l_rmenge = g_u02-e_menge.
*$      PERFORM use_decan USING l_rmenge g_u02-i_meins.
*$      g_u02-e_menge = l_rmenge.
*$*   g_u02-e_lmenge = g_u02-e_menge.       "@002
*$      IF g_u02-e_menge <> l_save.                           "@002
*$*     Rundungsgrund setzen
*$        PERFORM rundungsgrund USING mdr1p_c_decimals.
*$      ENDIF.                                                "@002
*$      EXIT.
*$    ENDIF.
*$  ENDIF.
*$* @002-BEGIN
*$** in Basis-ME ausdrücken
*$*  l_rmenge = g_u02-e_menge.
*$*  perform conv2unit using l_rmenge g_u02-i_meins mara-meins.
*$*  g_u02-e_menge = l_rmenge.
*$** wird später wieder in i_meins umgerechnet
*$* @002-END
*$
*$* Rundungswert in MARC berücksichtigen?
*$  IF rdprf IS INITIAL AND bstrf > 0.
*$    l_divs    = l_rmenge DIV bstrf.
*$    l_rmenge  = l_divs    *  bstrf.
*$    IF l_rmenge < g_u02-e_menge.
*$      l_rmenge = l_rmenge + bstrf.
*$*$@014 Anfang
*$    ENDIF.
*$      g_u02-e_menge = l_rmenge.
*$*   Rundungsgrund setzen
*$      PERFORM rundungsgrund USING mdr1p_c_rundungswert.
*$    ENDIF.
*$*$@014 Ende
*$  ENDIF.
*$
*$* Liefereinheit aus MVKE berücksichtigen?
*$  IF g_u02-i_opcode = mdr1p_c_op_sd_lieferung AND
*$     NOT mvke-scmng IS INITIAL.
*$    IF mvke-schme IS INITIAL.
*$      mvke-schme = mara-meins.
*$    ENDIF.
*$    PERFORM runde_auf_bstme USING l_rmenge mvke-schme.
*$    l_rmenge = g_u02-e_menge.
*$    l_divs    = l_rmenge DIV mvke-scmng.
*$    l_rmenge  = l_divs    *  mvke-scmng.
*$    IF l_rmenge < g_u02-e_menge.
*$      l_rmenge = l_rmenge + mvke-scmng.
*$*     Rundungsgrund setzen                                      " @014
*$      PERFORM rundungsgrund USING mdr1p_c_rundungswert.     " @014
*$    ENDIF.
*$    g_u02-e_menge = l_rmenge.
*$*$@014 Anfang
*$*$*   Rundungsgrund setzen
*$*$    PERFORM rundungsgrund USING mdr1p_c_liefereinheit.
*$*$@014 Ende
*$  ENDIF.
*$
*$* Rundungsprofil berücksichtigen
*$  IF NOT rdprf IS INITIAL.
*$*   Rundungsprofil lesen
*$    PERFORM read_rdpr USING g_u02-i_werk rdprf.
*$    IF sy-subrc <> 0.
*$      IF g_call_place_up  =  mdr1p_c_op_maintain_rdpf.      " @006
*$*       Fehlerausgabe beim Aufruf aus FKB md_simu_dyn_rund...    "
*$@006
*$        MESSAGE e063.                                       " @006
*$      ELSE.                                                 " @006
*$*       Bei sonstigen Aufrufen ist die g_u03-Struktur            "
*$@006
*$*       initialisiert => setzen der Ausnahme.                    "
*$@006
*$        RAISE rdpr_not_found.
*$      ENDIF.                                                " @006
*$    ENDIF.
*$
*$    CASE rdpr-rdmpo.
*$      WHEN c_rdmpo_abs.                "absolut runden
*$*       von Float in Quant umtüdeln ...
*$        l_qty = l_rmenge.
*$* @017-A
*$        old_mng = l_rmenge.
*$* @017-E
*$        CALL FUNCTION 'CHECK_ROUNDING_PROFILE'
*$          EXPORTING
*$            plant             = g_u02-i_werk
*$            profile           = rdprf
*$            quantity_in       = l_qty
*$          IMPORTING
*$            quantity_out      = l_qty
*$          EXCEPTIONS
*$            profile_not_found = 1
*$            OTHERS            = 2.
*$*       ... unn retour
*$        l_rmenge = l_qty.
*$        g_u02-e_menge = l_rmenge.
*$*       g_u02-e_logme = bleibt gleich
*$* @017-A
*$        IF l_rmenge <> old_mng.
*$* @017-E
*$*       Rundungsgrund setzen
*$          PERFORM rundungsgrund USING mdr1p_c_rdpr_absolut.
*$* @017-A
*$        ENDIF.
*$* @017-E
*$      WHEN c_rdmpo_no.                 "nicht runden
*$*       nix machen
*$        g_u02-e_menge = l_rmenge.
*$*       g_u02-e_logme = bleibt gleich
*$      WHEN c_rdmpo_bstme.              "runden nach VK-ME
*$*       Menge auf VK-ME runden
*$        PERFORM runde_auf_bstme USING l_rmenge bstme.
*$      WHEN c_rdmpo_opt.                "optimieren auf logist. ME
*$*       Menge auf VK-ME runden und versuchen zu optimieren
*$        PERFORM runde_auf_logme USING l_rmenge bstme.
*$      WHEN c_rdmpo_opt_no_null.
*$*       Menge auf VK-ME runden und versuchen zu optimieren
*$*       Nullmengen nur wenn das Rundungsprofil dies für BSTME
*$erfordert
*$        .
*$        PERFORM runde_auf_logme USING l_rmenge bstme.
*$*$@010 Anfang
*$      WHEN c_rdmpo_up_down.
*$*       Bei Auf- und Abschlagsrunden muessen die entsprechenden Felder
*$*       der g_u02-Struktur belegt sein
*$        g_u02-i_rdprf = rdprf.                              " @013
*$        PERFORM rounding_up_and_down CHANGING g_u02.
*$*$@010 Ende
*$    ENDCASE.
*$  ENDIF.
*$
*$* Maxmenge prüfen
*$  IF g_u02-i_no_min_max_check = c_charx.
*$  ELSE.
*$    IF NOT bstma IS INITIAL AND g_u02-e_menge > bstma.
*$      IF g_u02-i_opcode = mdr1p_c_op_mm_normal OR
*$         g_u02-i_opcode = mdr1p_c_op_mm_ub.
*$*          im Einkauf immer Bestell-ME zurückliefern
*$        g_u02-e_menge = bstma.
*$        g_u02-e_logme = bstme.
*$      ELSE.
*$        g_u02-e_menge = bstma.
*$ g_u02-e_logme = mara-meins.
*$      ENDIF.
*$*       Rundungsgrund setzen
*$      PERFORM rundungsgrund USING mdr1p_c_maxmenge.
*$    ENDIF.
*$  ENDIF.
*$
*$* Minmenge prüfen
*$  IF g_u02-i_no_min_max_check = c_charx.
*$  ELSE.
*$    IF NOT bstmi IS INITIAL AND g_u02-e_menge < bstmi.
*$*       Basis-ME oder Bestell-ME zurückliefern, sonst kommen
*$*       Ergebnisse wie 0,01 PAL raus
*$      IF g_u02-i_opcode = mdr1p_c_op_mm_normal OR
*$         g_u02-i_opcode = mdr1p_c_op_mm_ub.
*$*          im Einkauf immer Bestell-ME zurückliefern
*$        g_u02-e_menge = bstmi.
*$        g_u02-e_logme = bstme.
*$      ELSE.
*$        g_u02-e_menge = bstmi.
*$        g_u02-e_logme = mara-meins.
*$      ENDIF.
*$*       Rundungsgrund setzen
*$      PERFORM rundungsgrund USING mdr1p_c_minmenge.
*$    ENDIF.
*$  ENDIF.
*$
*$* @002-BEGIN alte Version verworfen
*$* logistische Menge und Mengeneinheit ermitteln
*$  PERFORM ermittle_logme USING bstme.
*$* @002-END
*$ENDFORM.                               " RUNDE
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$* @002-BEGIN
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  ERMITTLE_LOGME
*$*&--------------------------------------------------------------------
*$-*
*$FORM ermittle_logme USING value(bstme) LIKE mara-bstme.
*$  DATA: l_vabme LIKE eina-vabme.
*$  DATA: l_rmenge TYPE mdr1p_p_16_dec_14.
*$  DATA: l_save TYPE mdr1p_p_16_dec_14.
*$  DATA: l_divs TYPE mdr1p_p_16_dec_14.
*$
*$* logistische Menge und Einheit
*$* Ist bei Beschaffung keine variable Bestellmengeneinheit gesetzt,
*$* so wird die errechnete logistische Menge in die Bestellmengen-
*$* einheit umgerechnet
*$
*$* default: variable Bestell-ME (auch für SD)
*$  l_vabme = c_char1.
*$* Normalbestellung?
*$  IF g_u02-i_opcode = mdr1p_c_op_mm_normal.
*$*   Kennung zieht aus Infosatz oder MARA
*$    IF g_u02-kzinfosatz = c_ja.
*$      l_vabme = eina-vabme.
*$    ELSE.
*$      l_vabme = mara-vabme.
*$    ENDIF.
*$  ENDIF.
*$*@005 Begin : auch bei UB´s variable Bestell-ME zulassen.
*$  IF g_u02-i_opcode = mdr1p_c_op_mm_ub.
*$*   CLEAR L_VABME.
*$    IF g_u02-kzinfosatz = c_ja.
*$      l_vabme = eina-vabme.
*$    ELSE.
*$      l_vabme = mara-vabme.
*$    ENDIF.
*$  ENDIF.
*$*@005 End
*$  g_u02-e_lmenge = g_u02-e_menge.
*$  IF l_vabme IS INITIAL.
*$*   Bestell-ME ist fix vorgegeben
*$    l_save = g_u02-e_lmenge.
*$    PERFORM conv2unit USING g_u02-e_lmenge mara-meins bstme.
*$    g_u02-e_logme = bstme.
*$*   prüfen, ob das neue Ergebnis vom alten abweicht (in Stück)
*$    l_rmenge = g_u02-e_lmenge.
*$    PERFORM conv2unit USING l_rmenge bstme mara-meins.
*$    l_divs = abs( l_rmenge - l_save ).
*$    IF l_divs > c_epsilon.
*$      PERFORM rundungsgrund USING mdr1p_c_vabme.
*$    ENDIF.
*$  ELSE.
*$*   variable Bestell-/VK-ME
*$    PERFORM conv2unit USING g_u02-e_lmenge mara-meins g_u02-e_logme.
*$  ENDIF.
*$* Ergebnis noch in i_meins zurückrechnen
*$  PERFORM conv2unit USING g_u02-e_menge mara-meins g_u02-i_meins.
*$ENDFORM.                               " ERMITTLE_LOGME
*$* @002-END
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_MARC
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_marc USING value(matnr) LIKE mara-matnr
*$                     value(werk)  LIKE t001w-werks.
*$  CALL FUNCTION 'MARC_SINGLE_READ'
*$    EXPORTING
*$      matnr             = matnr
*$      werks             = werk
*$    IMPORTING
*$     wmarc             = marc
*$    EXCEPTIONS
*$      lock_on_marc      = 1
*$      lock_system_error = 2
*$      wrong_call        = 3
*$      not_found         = 4
*$      OTHERS            = 5.
*$
*$*  IF SY-SUBRC <> 0.
*$*     IF MARA-ATTYP = C_ATTYP_VARIANTE.
*$*        CALL FUNCTION 'MARC_SINGLE_READ'
*$*           EXPORTING
*$*              MATNR             = MARA-SATNR
*$*              WERKS             = WERK
*$*           IMPORTING
*$*              WMARC             = MARC
*$*         EXCEPTIONS
*$*              LOCK_ON_MARC      = 1
*$*              LOCK_SYSTEM_ERROR = 2
*$*              WRONG_CALL        = 3
*$*              NOT_FOUND         = 4
*$*              OTHERS            = 5.
*$*     ENDIF.
*$*  ENDIF.
*$
*$ENDFORM.                               " READ_MARC
*$@024 mbi 4.70 - Anfang

**&---------------------------------------------------------------------
*
**&      Form  READ_MARA
**&---------------------------------------------------------------------
*
*FORM read_mara USING value(matnr) LIKE mara-matnr.
*  DATA: l_mtcom LIKE mtcom.
*  DATA: l_mtcor LIKE mtcor.
*  DATA: BEGIN OF l_t_void OCCURS 0,
*          dum TYPE c,
*        END OF l_t_void.
*
*  l_mtcom-kenng = 'MARA'.
*  l_mtcom-matnr = matnr.
*  l_mtcom-spras = sy-langu.
*  l_mtcom-kzspr = c_nein.
*
*  CALL FUNCTION 'MATERIAL_READ'
*    EXPORTING
*      schluessel           = l_mtcom
*    IMPORTING
*      matdaten             = mara
*      return               = l_mtcor
*    TABLES
*      seqmat01             = l_t_void
*    EXCEPTIONS
*      account_not_found    = 1
*      batch_not_found      = 2
*      forecast_not_found   = 3
*      lock_on_account      = 4
*      lock_on_material     = 5
*      lock_on_plant        = 6
*      lock_on_sales        = 7
*      lock_on_sloc         = 8
*      lock_on_batch        = 9
*      lock_system_error    = 10
*      material_not_found   = 11
*      plant_not_found      = 12
*      sales_not_found      = 13
*      sloc_not_found       = 14
*      slocnumber_not_found = 15
*      sloctype_not_found   = 16
*      text_not_found       = 17
*      unit_not_found       = 18
*      invalid_mch1_matnr   = 19
*      invalid_mtcom        = 20
*      waart_error          = 21
*      sa_material          = 22
*      wv_material          = 23
*      OTHERS               = 24.
*ENDFORM.                               " READ_MARC
*
*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_RDPR
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_rdpr USING value(werk)  LIKE t001w-werks
*$                     value(rdprf) LIKE rdpr-rdprf.
*$  STATICS:  s_rdpr LIKE rdpr.
*$
*$* @001-BEGIN
*$  CLEAR sy-subrc.
*$
*$  IF NOT g_u02-i_rdpr-rdprf IS INITIAL.                     "@002
*$*   falls ein Profil im FuBau-Aufruf angegeben wurde, dann dieses
*$*   nehmen und nicht das aus den Stammdaten
*$    rdpr = g_u02-i_rdpr.
*$    EXIT.
*$  ENDIF.
*$* @001-END
*$
*$  CLEAR rdpr.
*$* erst im Cache nachschauen
*$  IF s_rdpr-rdprf = rdprf AND
*$     s_rdpr-werks = werk.
*$    rdpr = s_rdpr.
*$  ELSE.
*$*$@010 Anfang
*$    PERFORM call_md_rdpr_read USING    werk
*$                                       rdprf
*$                              CHANGING rdpr.
*$    IF sy-subrc <> 0.
*$
*$      werk = space.
*$
*$      PERFORM call_md_rdpr_read USING    werk
*$                                         rdprf
*$                                CHANGING rdpr.
*$    ENDIF.
*$
*$*$*   Cache neu füllen:
*$*$*   zuerst beim angegebenen Werk probieren
*$*$    SELECT *
*$*$    FROM   rdpr
*$*$    WHERE  werks = werk
*$*$    AND    rdprf = rdprf.
*$*$      EXIT.
*$*$    ENDSELECT.
*$*$
*$*$*   dann ohne Werk
*$*$    IF sy-subrc <> 0.
*$*$      SELECT *
*$*$      FROM   rdpr
*$*$      WHERE  werks = space
*$*$      AND    rdprf = rdprf.
*$*$        EXIT.
*$*$      ENDSELECT.
*$*$    ENDIF.
*$*$@010 Ende
*$    s_rdpr = rdpr.
*$    s_rdpr-werks = werk.
*$  ENDIF.
*$ENDFORM.                               " READ_RDPR
*$@024 mbi 4.70 - Ende

*$@023 Anfang MWE-ENTW-470-UNICODE
**&---------------------------------------------------------------------
*
**&      Form  ERMITTLE_BSTME
**&---------------------------------------------------------------------
*
*FORM ermittle_bstme USING bstme.
*  DATA: l_marc LIKE marc.
*  DATA: l_lfa1 LIKE lfa1.
*
*  CLEAR bstme.
**$@018 Anfang  MWE-HW-153574
**$* Normalbestellung
**$  IF G_U02-I_OPCODE = MDR1P_C_OP_MM_NORMAL.
**$    IF G_U02-KZINFOSATZ = C_JA.
**$*     aus Infosatz
**$      BSTME = EINA-MEINS.
**$    ENDIF.
**$* Umlagerungsbestellung
**$  ELSEIF G_U02-I_OPCODE = MDR1P_C_OP_MM_UB.
**$    IF G_U02-KZINFOSATZ = C_JA.
**$*     aus Infosatz
**$      BSTME = EINA-MEINS.
**$    ELSE.
**$*     oder Ausgabe-ME aus MARC
**$*@011-Anfang
**$*     CALL FUNCTION 'LFA1_SINGLE_READ'
**$*        EXPORTING
**$*          LFA1_LIFNR = G_U02-I_LIFNR
**$*        IMPORTING
**$*          WLFA1      = L_LFA1
**$*        EXCEPTIONS
**$*          NOT_FOUND  = 1
**$*          OTHERS     = 2.
**$*     CHECK SY-SUBRC = 0.
**$      CLEAR L_LFA1-WERKS.
**$      IF G_U02-I_LIFNR IS INITIAL.
**$        L_LFA1-WERKS = G_U02-I_WERKS_KRED.
**$      ELSE.
**$        CALL FUNCTION 'LFA1_SINGLE_READ'
**$             EXPORTING
**$                  LFA1_LIFNR = G_U02-I_LIFNR
**$             IMPORTING
**$                  WLFA1      = L_LFA1
**$             EXCEPTIONS
**$                  NOT_FOUND  = 1
**$                  OTHERS     = 2.
**$      ENDIF.
**$      CHECK NOT L_LFA1-WERKS IS INITIAL.
**$*@011-Ende
**$*     safety first!
**$      L_MARC = MARC.
**$      PERFORM READ_MARC USING G_U02-I_MATNR L_LFA1-WERKS.
**$      IF SY-SUBRC = 0.
**$        BSTME = MARC-AUSME.
**$      ENDIF.
**$      MARC = L_MARC.
**$    ENDIF.
*  IF   g_u02-i_opcode = mdr1p_c_op_mm_normal
*    OR g_u02-i_opcode = mdr1p_c_op_mm_ub.
*    IF   g_u02-i_opcode = mdr1p_c_op_mm_normal.
*      IF g_u02-kzinfosatz = c_ja.
**     aus Infosatz
*        bstme = eina-meins.
*      ENDIF.
** Umlagerungsbestellung
*    ELSEIF g_u02-i_opcode = mdr1p_c_op_mm_ub.
*      IF g_u02-kzinfosatz = c_ja.
**     aus Infosatz
*        bstme = eina-meins.
*      ELSE.
**     oder Ausgabe-ME aus MARC
*        CALL FUNCTION 'LFA1_SINGLE_READ'
*             EXPORTING
*                  lfa1_lifnr = g_u02-i_lifnr
*             IMPORTING
*                  wlfa1      = l_lfa1
*             EXCEPTIONS
*                  not_found  = 1
*                  OTHERS     = 2.
*        CHECK sy-subrc = 0.
**     safety first!
*        l_marc = marc.
*        PERFORM read_marc USING g_u02-i_matnr l_lfa1-werks.
*        IF sy-subrc = 0.
*          bstme = marc-ausme.
*        ENDIF.
*        marc = l_marc.
*      ENDIF.
*    ENDIF.
*    IF bstme IS INITIAL.
*      bstme = mara-bstme.
*    ENDIF.
**$@018 Ende  MWE-HW-153574
*
** Verkauf: Auftrag oder Lieferung
*  ELSEIF g_u02-i_opcode = mdr1p_c_op_sd_auftrag OR
*         g_u02-i_opcode = mdr1p_c_op_sd_lieferung.
*    bstme = mvke-vrkme.
*  ENDIF.
*
*  IF bstme IS INITIAL.
*    bstme = mara-meins.
*  ENDIF.
*ENDFORM.                               " ERMITTLE_BSTME
*$@023 Ende MWE-ENTW-470-UNICODE

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  RUNDE_AUF_BSTME
*$*&--------------------------------------------------------------------
*$-*
*$FORM runde_auf_bstme USING value(menge) TYPE mdr1p_p_16_dec_14
*$                           value(bstme) LIKE mara-bstme.
*$  DATA: l_menge TYPE mdr1p_p_16_dec_14.
*$  DATA: l_help_menge  LIKE ekpo-menge.
*$
*$  l_menge = menge.
*$* in Bestell-/VK-ME umrechnen
*$  PERFORM conv2unit USING l_menge mara-meins bstme.
*$* aufrunden
*$* Runden mit QUAN-Feld wegen Darstellungsungenauigkeiten, HW 150915
*$  l_help_menge = l_menge.
*$  l_help_menge = ceil( l_help_menge ).
*$  l_menge = l_help_menge.
*$* und wieder zurück in Basis-ME
*$  PERFORM conv2unit USING l_menge bstme mara-meins.
*$  g_u02-e_menge = l_menge.
*$  g_u02-e_logme = bstme.
*$
*$  IF l_menge <> menge.
*$*   Rundungsgrund setzen
*$    PERFORM rundungsgrund USING mdr1p_c_rdpr_bstme.
*$  ENDIF.
*$ENDFORM.                               " RUNDE_AUF_BSTME
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  RUNDE_AUF_LOGME
*$*&--------------------------------------------------------------------
*$-*
*$* @007 Anfang -> alte Version auskommentiert mit '*$@007'
*$*$@007form runde_auf_logme using value(menge) type f
*$*$@007                           value(bstme) like mara-bstme.
*$*$@007  data: l_kz_ok type c.
*$*$@007  data: l_menge type f.
*$*$@007  data: l_logme like marm-meinh.
*$*$@007
*$*$@007  data: begin of l_t_rmmme occurs 0.
*$*$@007          include structure rmmme.
*$*$@007  data: end of l_t_rmmme.
*$*$@007
*$*$@007  data: begin of l_t_metab occurs 0,
*$*$@007          meinh like rmmme-meinh,
*$*$@007          faktor type f,
*$*$@007         end of l_t_metab.
*$*$@007
*$*$@007* erst mal auf Bestell-/VK-ME runden
*$*$@007  perform runde_auf_bstme using menge bstme.
*$*$@007  l_menge = g_u02-e_menge.
*$*$@007* Default für logistische ME ist die Bestell-/VK-ME
*$*$@007  l_logme = bstme.
*$*$@007* alle Mengeneinheiten des Artikels lesen
*$*$@007  perform read_marm tables l_t_rmmme using g_u02-i_matnr.
*$*$@007* ME's nach Größe sortieren -> l_t_metab
*$*$@007  loop at l_t_rmmme.
*$*$@007    clear l_t_metab.
*$*$@007    l_t_metab-meinh = l_t_rmmme-meinh.
*$*$@007    if l_t_rmmme-umren <> 0.
*$*$@007      l_t_metab-faktor = l_t_rmmme-umrez / l_t_rmmme-umren.
*$*$@007    endif.
*$*$@007    append l_t_metab.
*$*$@007  endloop.
*$*$@007  sort l_t_metab descending by faktor.
*$*$@007
*$@007* alle ME's absteigend sortiert durchgehen
*$*$@007  l_kz_ok = c_nein.
*$*$@007  loop at l_t_metab.
*$*$@007*   Bestell-ME erreicht? => aufhören
*$*$@007    if l_t_metab-meinh = bstme.
*$*$@007      exit.
*$*$@007    endif.
*$*$@007    perform me_is_ok using l_t_metab-meinh l_t_metab-faktor
*$*$@007                           l_menge l_kz_ok.
*$*$@007    if l_kz_ok = c_ja.
*$*$@007      l_logme = l_t_metab-meinh.
*$*$@007*     Rundungsgrund setzen
*$*$@007      perform rundungsgrund using mdr1p_c_rdpr_opt.
*$*$@007      exit.
*$*$@007    endif.
*$*$@007  endloop.
*$*$@007
*$*$@007* prüfe innerhalb der ME-Hierarchie, was gefunden wurde
*$*$@007* perform ...
*$*$@007  g_u02-e_menge = l_menge.
*$*$@007  g_u02-e_logme = l_logme.
*$*$@007endform.                    " RUNDE_AUF_LOGME
*$* neue Version:
*$FORM runde_auf_logme USING value(menge) TYPE mdr1p_p_16_dec_14
*$                           value(bstme) LIKE mara-bstme.
*$  DATA: l_kz_ok TYPE c.
*$  DATA: l_menge TYPE mdr1p_p_16_dec_14.
*$  DATA: l_logme LIKE marm-meinh.
*$
*$  DATA: BEGIN OF l_t_rmmme OCCURS 0.
*$          INCLUDE STRUCTURE rmmme.
*$  DATA: END OF l_t_rmmme.
*$
*$  DATA: BEGIN OF l_t_metab OCCURS 0,
*$          meinh LIKE rmmme-meinh,
*$          faktor TYPE mdr1p_p_16_dec_14,
*$         END OF l_t_metab.
*$
*$* keine Default-Rundung auf Bestell-Mengeneinheit -> neue Verison
*$  l_menge = menge.
*$  l_logme = mara-meins.
*$
*$* alle Mengeneinheiten des Artikels lesen
*$  PERFORM read_marm TABLES l_t_rmmme USING g_u02-i_matnr.
*$
*$* ME's nach Größe sortieren -> l_t_metab
*$  LOOP AT l_t_rmmme.
*$    CLEAR l_t_metab.
*$    l_t_metab-meinh = l_t_rmmme-meinh.
*$    IF l_t_rmmme-umren <> 0.
*$      l_t_metab-faktor = l_t_rmmme-umrez / l_t_rmmme-umren.
*$    ENDIF.
*$    APPEND l_t_metab.
*$  ENDLOOP.
*$  SORT l_t_metab DESCENDING BY faktor.
*$
*$* alle ME's absteigend sortiert durchgehen
*$  l_kz_ok = c_nein.
*$  LOOP AT l_t_metab.
*$
*$*   dynamische Rundungsmethode -> Rundungsregeln zu den ME der ME-
*$*   Hierarchie anwenden:
*$    PERFORM me_is_ok USING l_t_metab-meinh l_t_metab-faktor
*$                          l_menge l_kz_ok bstme.
*$
*$    IF l_kz_ok = c_ja.
*$*     wurde die dynamische Rundungsmethode angewendet, ist die Rundung
*$*     fertig.
*$*     Wichtig: Es wird keine Aufrundung auf Bestellmengeneinheit
*$*              durcgeführt -> neue Version
*$
*$*     die logistische ME ist die ME der angewandten Rundungsregel
*$      l_logme = l_t_metab-meinh.
*$*$@009 Anfang
*$*$*     Rundungsgrund setzen, nur wenn sich gegenüber der Eingabe die
*$*$*     Mengeneinheit geändert hat.
*$*$      if    l_logme <> g_u02-i_meins
*$*$        perform rundungsgrund using mdr1p_c_rdpr_opt.
*$*$      endif.
*$*$@009 Ende
*$
*$*     Fertig ===>>>
*$      EXIT.
*$
*$    ENDIF.
*$
*$*   dynamische Rundungsmethode wurde nicht angewendet
*$    IF l_t_metab-meinh = bstme.
*$*     ist die Bestell-ME erreicht, dann Aufrundung aus Bestell-ME
*$      PERFORM runde_auf_bstme USING menge bstme.
*$      l_menge = g_u02-e_menge.
*$
*$*     die logistische ME ist die Bestell-/VK-ME
*$      l_logme = bstme.
*$
*$      EXIT.
*$    ENDIF.
*$  ENDLOOP.

*$* Rückgabe der bestimmten Werten
*$  g_u02-e_menge = l_menge.
*$  g_u02-e_logme = l_logme.
*$
*$ENDFORM.                               " RUNDE_AUF_LOGME
*$* @007 Ende -> neue Version
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_MARM
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_marm TABLES t_metab      STRUCTURE rmmme
*$               USING  value(matnr) LIKE      mara-matnr.
*$
*$  CALL FUNCTION 'MATERIAL_UNIT_FIND'
*$    EXPORTING
*$      kzall      = c_nein        "nur die zum Artikel
*$      matnr      = matnr
*$    TABLES
*$      rmmme_itab = t_metab.      "mögliche Mengeneinheiten
*$
*$ENDFORM.                               " READ_MARM
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  ME_IS_OK
*$*&--------------------------------------------------------------------
*$-*
*$FORM me_is_ok USING value(meinh) LIKE marm-meinh
*$                    value(faktor) TYPE mdr1p_p_16_dec_14
*$                    menge TYPE mdr1p_p_16_dec_14    "in Basis-ME
*$                    kz_ok TYPE c
*$                    bstme LIKE mara-bstme.
*$  DATA: l_kz_me_ok TYPE c.
*$  DATA: l_ganze_leinh TYPE mdr1p_p_16_dec_14.  "#ganze logist.
*$Einheiten
*$  DATA: l_ziel_leinh TYPE mdr1p_p_16_dec_14.
*$  "nächste/vorherige logist. Einheit
*$  DATA: l_diff TYPE mdr1p_p_16_dec_14.
*$  DATA: l_schwelle TYPE mdr1p_p_16_dec_14.
*$
*$  l_kz_me_ok = c_ja.
*$* erlaubte ME's des Lieferanten prüfen?
*$  IF NOT rdpr-chkmeli IS INITIAL.
*$    PERFORM pruefe_erlaubnis_lief USING meinh l_kz_me_ok.
*$  ENDIF.
*$
*$* erlaubte ME's des Kunden püfen, wenn auch beim Lieferanten zulässig
*$  IF l_kz_me_ok = c_ja.
*$    IF NOT rdpr-chkmeku IS INITIAL.
*$      PERFORM pruefe_erlaubnis_kunde USING meinh l_kz_me_ok.
*$    ENDIF.
*$  ENDIF.
*$
*$  IF l_kz_me_ok = c_ja.
*$    l_kz_me_ok = c_nein.
*$*   Schwellwerte lesen
*$    PERFORM read_tw06s USING meinh rdpr-rdrgl.
*$    CHECK sy-subrc = 0.
*$*   eigentliche Rundung durchführen
*$    l_ganze_leinh = menge.
*$    PERFORM conv2unit USING l_ganze_leinh mara-meins meinh.
*$    l_ganze_leinh = trunc( l_ganze_leinh ).
*$    l_ziel_leinh = l_ganze_leinh + 1.
*$    PERFORM conv2unit USING l_ganze_leinh meinh mara-meins.
*$    l_diff = menge - l_ganze_leinh.
*$    IF l_diff > 0.                                          "@001
*$*     Schwellwert zum Abrunden erreicht?
*$      l_schwelle = faktor * tw06s-swpab / 100.
*$      IF l_diff <= l_schwelle.
*$*       MENGE = L_GANZE_LEINH.
*$*       L_KZ_ME_OK = C_JA.
*$        IF rdpr-rdmpo = c_rdmpo_opt.
*$          menge = l_ganze_leinh.
*$          l_kz_me_ok = c_ja.
*$        ENDIF.
*$        IF rdpr-rdmpo = c_rdmpo_opt_no_null.
*$          IF meinh = bstme.
*$*             Ist die BSTME erreicht so wird gerundet, auch wenn
*$*             sich Null als Rundungsergebnis ergibt.
*$            menge = l_ganze_leinh.
*$            l_kz_me_ok = c_ja.
*$          ENDIF.
*$          IF l_ganze_leinh > 0.
*$            menge = l_ganze_leinh.
*$            l_kz_me_ok = c_ja.
*$          ENDIF.
*$        ENDIF.
*$      ENDIF.
*$*     Schwellwert zum Aufrunden erreicht?
*$      l_schwelle = faktor * tw06s-swpauf / 100.
*$      IF l_diff >= l_schwelle.
*$        menge = l_ziel_leinh.
*$        PERFORM conv2unit USING menge meinh mara-meins.
*$        l_kz_me_ok = c_ja.
*$      ENDIF.
*$
*$*     wurde gerundet, dann Rundungsgrund setzen:                  "
*$@009
*$      IF l_kz_me_ok = c_ja.                                 " @009
*$        PERFORM rundungsgrund USING mdr1p_c_rdpr_opt.       " @009
*$      ENDIF.                                                " @009
*$
*$*$@016 Anfang
*$*$    ELSEIF l_diff = 0 AND              "@001
*$*$           ( tw06s-swpab <> 0 OR tw06s-swpauf <> 0 ).
*$    ELSEIF l_diff = 0.
*$*$@016 Ende
*$*     Originalmenge ist schon Vielfaches dieser ME
*$      l_kz_me_ok = c_ja.
*$*     Rundungsgrund setzen, nur wenn sich gegenüber der Eingabe   "
*$@009
*$*     die Mengeneinheit geändert hat.                             "
*$@009
*$      IF meinh <> g_u02-i_meins.                            " @009
*$        PERFORM rundungsgrund USING mdr1p_c_rdpr_opt.       " @009
*$      ENDIF.                                                " @009
*$
*$    ENDIF.
*$  ENDIF.
*$  kz_ok = l_kz_me_ok.
*$ENDFORM.                               " ME_IS_OK
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  PRUEFE_ERLAUBNIS_LIEF
*$*&--------------------------------------------------------------------
*$-*
*$FORM pruefe_erlaubnis_lief USING value(meinh) LIKE marm-meinh
*$                                 kz_erlaubt TYPE c.
*$  DATA: l_megru LIKE twmeg-megru.
*$
*$*@004-BEGIN
*$  DATA: l_vkorg LIKE mvke-vkorg.
*$  DATA: l_vtweg LIKE mvke-vtweg.
*$*@004-END
*$
*$  kz_erlaubt = c_ja.
*$* Mengeneinheitengruppe des Liefernden ermitteln: EINE oder MVKE
*$  IF g_u02-i_opcode = mdr1p_c_op_mm_normal OR
*$     g_u02-i_opcode = mdr1p_c_op_mm_ub.
*$*@004-Begin
*$*   L_MEGRU = EINE-MEGRU.
*$    IF g_u02-kzinfosatz = c_ja.
*$      l_megru = eine-megru.
*$    ELSE.
*$      PERFORM read_tvkwz.
*$      PERFORM read_knvv.
*$      PERFORM abmischen_vz_fi USING l_vkorg l_vtweg.
*$      IF NOT l_vkorg IS INITIAL AND
*$         NOT l_vtweg IS INITIAL.
*$        PERFORM read_mvke USING g_u02-i_matnr l_vkorg l_vtweg.
*$        l_megru = mvke-megru.
*$      ENDIF.
*$    ENDIF.
*$*@004-END
*$  ELSE.
*$    l_megru = mvke-megru.
*$  ENDIF.
*$* Mengeneinheitengruppe muß angegeben sein
*$  CHECK NOT l_megru IS INITIAL.
*$* prüfen, ob meinh in der ME-Gruppe enthalten ist
*$  PERFORM read_twmeg USING l_megru meinh.
*$
*$  IF sy-subrc <> 0.
*$    kz_erlaubt = c_nein.
*$  ENDIF.
*$ENDFORM.                               " PRUEFE_ERLAUBNIS_LIEF
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  PRUEFE_ERLAUBNIS_KUNDE
*$*&--------------------------------------------------------------------
*$-*
*$FORM pruefe_erlaubnis_kunde USING value(meinh) LIKE marm-meinh
*$                                  kz_erlaubt TYPE c.
*$  DATA: l_megru LIKE twmeg-megru.
*$
*$  kz_erlaubt = c_ja.
*$* Mengeneinheitengruppe des Empfängers ermitteln: KNMT oder MARC
*$  IF g_u02-i_opcode = mdr1p_c_op_mm_normal OR
*$     g_u02-i_opcode = mdr1p_c_op_mm_ub OR
*$* @001-BEGIN
*$            g_u02-i_opcode = mdr1p_c_op_sd_auftrag
*$        AND g_u02-kz_is_werk = c_ja
*$     OR
*$            g_u02-i_opcode = mdr1p_c_op_sd_lieferung
*$        AND g_u02-kz_is_werk = c_ja.
*$* @001-END
*$    l_megru = marc-megru.
*$  ELSE.
*$    l_megru = knmt-megru.
*$  ENDIF.
*$* Mengeneinheitengruppe muß angegeben sein
*$  CHECK NOT l_megru IS INITIAL.
*$* prüfen, ob meinh in der ME-Gruppe enthalten ist
*$  PERFORM read_twmeg USING l_megru meinh.
*$
*$  IF sy-subrc <> 0.
*$    kz_erlaubt = c_nein.
*$  ENDIF.
*$ENDFORM.                               " PRUEFE_ERLAUBNIS_KUNDE
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_TW06S
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_tw06s USING value(meins) LIKE tw06s-meins
*$                      value(rdrgl) LIKE tw06s-rdrgl.
*$  STATICS: BEGIN OF s_t_tw06s OCCURS 0.
*$          INCLUDE STRUCTURE tw06s.
*$  STATICS: END OF s_t_tw06s.
*$
*$* erst im Cache suchen
*$  READ TABLE s_t_tw06s
*$    WITH KEY rdrgl = rdrgl
*$             meins = meins.
*$  IF sy-subrc = 0.
*$    tw06s = s_t_tw06s.
*$  ELSE.
*$*   Cache neu füllen
*$    REFRESH s_t_tw06s.
*$
*$    SELECT *
*$    INTO   TABLE s_t_tw06s
*$    FROM   tw06s
*$    WHERE  rdrgl = rdrgl.
*$
*$    READ TABLE s_t_tw06s
*$      WITH KEY rdrgl = rdrgl
*$               meins = meins.
*$    tw06s = s_t_tw06s.
*$  ENDIF.
*$ENDFORM.                               " READ_TW06S
*$@024 mbi 4.70 - Ende

**&---------------------------------------------------------------------
*
**&      Form  RUNDE_SD
**&---------------------------------------------------------------------
*
*FORM runde_sd.
**  DATA: L_MENGE TYPE F.
*  DATA: l_mindest TYPE mdr1p_p_16_dec_14.
*  DATA: l_max TYPE mdr1p_p_16_dec_14.
*  DATA: l_bstme LIKE mara-bstme.
*  DATA: l_kz_mvke TYPE c.              "Kennung, ob MVKE existiert
*
** Init.
*  CLEAR knmt.
*  CLEAR mvke.
*  CLEAR marc.                          "@001
*
** MARA lesen
*  PERFORM read_mara USING g_u02-i_matnr.
*  IF sy-subrc <> 0.
*    RAISE material_not_found.
*  ENDIF.
*
** MVKE lesen
*  PERFORM read_mvke USING g_u02-i_matnr
*                          g_u02-i_vkorg
*                          g_u02-i_vtweg.
*  IF sy-subrc = 0.
*    l_kz_mvke = c_ja.
*  ELSE.
*    l_kz_mvke = c_nein.
*  ENDIF.
*
** @001-BEGIN
** wenn der Kunde auch ein Werk ist (z.B. Umlagerung VZ an Filiale),
** dann wird es kein KNMT geben; dann erlaubte ME's aus MARC ziehen
*  PERFORM read_kna1 USING g_u02-i_kunnr.
*  IF sy-subrc <> 0.
*    RAISE debitor_not_found.
*  ENDIF.
*
*  g_u02-kz_is_werk = c_nein.
*  IF NOT kna1-werks IS INITIAL.
**   MARC lesen
*    PERFORM read_marc USING g_u02-i_matnr kna1-werks.
*    IF sy-subrc = 0.
*      g_u02-kz_is_werk = c_ja.
*    ENDIF.
*  ENDIF.
** @001-END
*
** wenn gar nichts geht, dann zumindest das:
*  g_u02-e_lmenge = g_u02-i_menge.
*  g_u02-e_logme  = g_u02-i_meins.      "übergebene ME
*  g_u02-e_menge  = g_u02-i_menge.
*
*  g_u02-kzinfosatz = c_nein.
*
*  IF NOT g_u02-i_kunnr IS INITIAL.
**   Kunde ist angegeben
**   if g_u02-kz_is_werk = c_nein.                       "@001
**     Kundeninfosatz lesen
**     (nur lesen, wenn der Kunde ein "echter" externer Kunde ist)
*    PERFORM read_knmt USING g_u02-i_matnr
*                            g_u02-i_vkorg
*                            g_u02-i_vtweg
*                            g_u02-i_kunnr.
**     Kennung setzen, daß Infosatz existiert
*    IF sy-subrc = 0.
*      g_u02-kzinfosatz = c_ja.
*    ENDIF.
**   endif.                                              "@001
*
**   Verkaufs-ME ermitteln
*    PERFORM ermittle_bstme USING l_bstme.
*
*    IF g_u02-i_opcode = mdr1p_c_op_sd_auftrag.
*      IF g_u02-kzinfosatz = c_ja    AND
*         NOT g_u02-i_infls IS INITIAL AND
*         NOT knmt-rdprf IS INITIAL.
*        g_u02-e_rdprf = knmt-rdprf.
*        CLEAR l_mindest.
*        IF l_kz_mvke = c_ja.
*          l_mindest = mvke-aumng.
*        ENDIF.
*        PERFORM runde USING knmt-rdprf 0 l_mindest 0 l_bstme.
*      ELSE.
*        IF l_kz_mvke = c_nein.
*          RAISE no_round.
*        ELSE.
*          l_mindest = mvke-aumng.
*          IF mvke-scmng IS INITIAL.
*            IF mvke-rdprf IS INITIAL.
*              RAISE no_round.
*            ELSE.
*              g_u02-e_rdprf = mvke-rdprf.
*              PERFORM runde USING mvke-rdprf 0 l_mindest 0 l_bstme.
*            ENDIF.
*          ELSE.
*            g_u02-e_scmng = mvke-scmng.
*            IF mvke-schme IS INITIAL.
*              g_u02-e_schme = mara-meins.
*              PERFORM runde USING mvke-rdprf 0 l_mindest 0 mara-meins.
*            ELSE.
*              g_u02-e_schme = mvke-schme.
*              PERFORM runde USING mvke-rdprf 0 l_mindest 0 mvke-schme.
*            ENDIF.
*          ENDIF.
*        ENDIF.
*      ENDIF.
*    ELSE.
*      IF g_u02-kzinfosatz = c_ja.
*        l_mindest = knmt-minlf.
*        PERFORM runde USING knmt-rdprf 0 l_mindest 0 l_bstme.
*      ELSE.
*        IF l_kz_mvke = c_ja.
*          IF g_u02-i_opcode = mdr1p_c_op_sd_auftrag.
*            l_mindest = mvke-aumng.
*            CLEAR l_max.
*          ELSE.
*            l_mindest = mvke-lfmng.
*            l_max = mvke-lfmax.
*          ENDIF.
*          PERFORM runde USING mvke-rdprf l_max l_mindest 0 l_bstme.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*  ELSE.
**   kein Kunde angegeben
**   Verkaufs-ME ermitteln
*    PERFORM ermittle_bstme USING l_bstme.
*
*    IF l_kz_mvke = c_ja.
*      IF g_u02-i_opcode = mdr1p_c_op_sd_auftrag.
*        l_mindest = mvke-aumng.
*        CLEAR l_max.
*      ELSE.
*        l_mindest = mvke-lfmng.
*        l_max = mvke-lfmax.
*      ENDIF.
*      PERFORM runde USING mvke-rdprf l_max l_mindest 0 l_bstme.
*    ENDIF.
*  ENDIF.
*ENDFORM.                               " RUNDE_SD

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_KNMT
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_knmt USING value(matnr) LIKE knmt-matnr
*$                     value(vkorg) LIKE knmt-vkorg
*$                     value(vtweg) LIKE knmt-vtweg
*$                     value(kunnr) LIKE knmt-kunnr.
*$
*$  DATA: l_kdmat LIKE knmt-kdmat.
*$  DATA: l_spart LIKE knvv-spart.
*$*$@020 Anfang MWE-HW-182741
*$  DATA: l_knmt_kunnr  LIKE  knmt-kunnr.
*$
*$  l_knmt_kunnr  =  kunnr.
*$
*$* Bestimme kundenindividuell abweichende Kunndennummer
*$* zum Lesen des Infosatzes (nicht zum Lesen von KNVV!)
*$  PERFORM userexit_cust_material_read(sapmv45a) USING l_knmt_kunnr.
*$*$@020 Ende MWE-HW-182741
*$
*$  l_spart = g_u02-i_spart.
*$  IF l_spart IS INITIAL AND
*$     ( knvv-kunnr <> kunnr OR
*$       knvv-vkorg <> vkorg OR
*$       knvv-vtweg <> vtweg ).
*$*   Sparte zum Kunden suchen; erste nehmen, wenn mehrere
*$    SELECT kunnr
*$           vkorg
*$           vtweg
*$           spart
*$    INTO  (knvv-kunnr,
*$           knvv-vkorg,
*$           knvv-vtweg,
*$           knvv-spart)
*$    FROM   knvv
*$    UP TO  1 ROWS
*$    WHERE  kunnr = kunnr
*$    AND    vkorg = vkorg
*$    AND    vtweg = vtweg.
*$      l_spart = knvv-spart.
*$      EXIT.
*$    ENDSELECT.
*$  ENDIF.
*$
*$  CALL FUNCTION 'RV_CUSTOMER_MATERIAL_READ'
*$       EXPORTING
*$            cmr_kdmat      = l_kdmat   "leer!?
*$*$@020 Anfang MWE-HW-182741
*$*$            cmr_kunnr      = kunnr
*$            cmr_kunnr      = l_knmt_kunnr
*$*$@020 Ende MWE-HW-182741
*$            cmr_matnr      = matnr
*$            cmr_spart      = l_spart
*$            cmr_vkorg      = vkorg
*$            cmr_vtweg      = vtweg
*$       IMPORTING
*$            cmr_knmt       = knmt
*$       EXCEPTIONS
*$            knmt_not_found = 1
*$            OTHERS         = 2.
*$ENDFORM.                               " READ_KNMT
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_MVKE
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_mvke USING value(matnr) LIKE mvke-matnr
*$                     value(vkorg) LIKE mvke-vkorg
*$                     value(vtweg) LIKE mvke-vtweg.
*$
*$  CALL FUNCTION 'MVKE_SINGLE_READ'
*$    EXPORTING
*$      matnr             = matnr
*$      vkorg             = vkorg
*$      vtweg             = vtweg
*$    IMPORTING
*$      wmvke             = mvke
*$    EXCEPTIONS
*$      lock_on_mvke      = 1
*$      lock_system_error = 2
*$      wrong_call        = 3
*$      not_found         = 4
*$      OTHERS            = 5.
*$ENDFORM.                               " READ_MVKE
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_TWMEG
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_twmeg USING value(megru) LIKE twmeg-megru
*$                      value(meinh) LIKE twmeg-meins.
*$  STATICS: BEGIN OF s_t_twmeg OCCURS 0.
*$          INCLUDE STRUCTURE twmeg.
*$  STATICS: END OF s_t_twmeg.
*$
*$* zuerst im Cache suchen
*$  READ TABLE s_t_twmeg
*$    WITH KEY megru = megru
*$             meins = meinh.
*$
*$  IF sy-subrc = 0.
*$    twmeg = s_t_twmeg.
*$  ELSE.
*$*   Cache neu füllen
*$    REFRESH s_t_twmeg.
*$
*$    SELECT *
*$    INTO   TABLE s_t_twmeg
*$    FROM   twmeg
*$    WHERE  megru = megru.
*$
*$    READ TABLE s_t_twmeg
*$      WITH KEY megru = megru
*$               meins = meinh.
*$    twmeg = s_t_twmeg.
*$  ENDIF.
*$ENDFORM.                               " READ_TWMEG
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  CHECK_PARAMS
*$*&--------------------------------------------------------------------
*$-*
*$FORM check_params.
*$
*$  IF g_u02-i_opcode = mdr1p_c_op_mm_normal OR
*$     g_u02-i_opcode = mdr1p_c_op_mm_ub.
*$*   Beschaffung:
*$*   Empfangswerk muß angegeben sein
*$    IF g_u02-i_werk IS INITIAL.
*$      RAISE bad_params.
*$    ENDIF.
*$  ELSEIF g_u02-i_opcode = mdr1p_c_op_sd_auftrag OR
*$         g_u02-i_opcode = mdr1p_c_op_sd_lieferung.
*$*   Verkauf:
*$*   VKOrg und Vertriebsweg muß angegeben sein
*$    IF g_u02-i_vkorg IS INITIAL OR
*$       g_u02-i_vtweg IS INITIAL.
*$      RAISE bad_params.
*$    ENDIF.
*$  ENDIF.
*$
*$* @008 Anfang
*$*   Bei Eingabemenge = 0 => keine Rundung durchführen!!!!
*$  IF g_u02-i_menge = 0.
*$*   Belege die Ausgabe-Werte mit den Eingabe-Werten!
*$    g_u02-e_menge  = g_u02-i_menge.
*$    g_u02-e_logme  = g_u02-i_meins.
*$    g_u02-e_lmenge = g_u02-i_menge.
*$    g_u02-e_rdprf  = g_u02-i_rdprf.
*$    g_u02-e_scmng  = g_u02-i_scmng.
*$*   Setze Flag Eingabe-Fehler ohne Programmabbruch! => Keine Rundung!
*$    g_params_ok = c_nein.
*$  ENDIF.
*$* @008 Ende
*$
*$ENDFORM.                               " CHECK_PARAMS
*$@024 mbi 4.70 - Ende
*
**&---------------------------------------------------------------------
*
**&      Form  RUNDUNGSGRUND
**&---------------------------------------------------------------------
*
*FORM rundungsgrund USING value(grund) TYPE c.
*
*  g_t_grund-kzgrund = grund.
*  APPEND g_t_grund.
*
*ENDFORM.                               " RUNDUNGSGRUND
*
*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_KNA1
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_kna1 USING value(kunnr) LIKE kna1-kunnr.
*$  CLEAR sy-subrc.
*$
*$  CALL FUNCTION 'WAUF_KNA1_READ'
*$    EXPORTING
*$      im_kunnr        = kunnr
*$    IMPORTING
*$      ex_kna1         = kna1
*$    EXCEPTIONS
*$      no_kunnr        = 1
*$      no_record_found = 2
*$      OTHERS          = 3.
*$ENDFORM.                                                    "
*$READ_KNA1
*$@024 mbi 4.70 - Ende

*$@023 Anfang MWE-ENTW-470-UNICODE
**&---------------------------------------------------------------------
*
**&      Form  RUNDE_VERF
**&---------------------------------------------------------------------
*
*FORM runde_verf.
*
*  DATA: l_rmenge TYPE mdr1p_p_16_dec_14,
*        l_qty    LIKE rdpr-vormg,
*        l_bstme  LIKE mara-bstme,
*        l_scmng  TYPE mdr1p_p_16_dec_14,
*        l_ganz   TYPE i.
*
*  PERFORM read_mara USING g_u02-i_matnr.
*  IF sy-subrc NE 0.
*    RAISE material_not_found.
*  ENDIF.
*
*  g_u02-e_lmenge = g_u02-i_menge.
*  g_u02-e_logme  = g_u02-i_meins.
*  g_u02-e_menge  = g_u02-i_menge.
*
*  IF NOT g_u02-i_rdprf IS INITIAL.
*    PERFORM read_rdpr USING g_u02-i_werk g_u02-i_rdprf.
*    IF sy-subrc NE 0.
*      RAISE rdpr_not_found.
*    ENDIF.
*    CASE rdpr-rdmpo.
*      WHEN c_rdmpo_abs.
*        l_rmenge = g_u02-e_lmenge.
*        PERFORM conv2unit USING l_rmenge g_u02-i_meins mara-meins.
*        l_qty = l_rmenge.
*        CALL FUNCTION 'CHECK_ROUNDING_PROFILE'
*             EXPORTING
*                  plant             = g_u02-i_werk
*                  profile           = g_u02-i_rdprf
*                  quantity_in       = l_qty
*                  kz_round_down     = c_charx
*             IMPORTING
*                  quantity_out      = l_qty
*             EXCEPTIONS
*                  profile_not_found = 1
*                  OTHERS            = 2.
*
*        IF sy-subrc NE 0.
*          RAISE no_round.
*        ENDIF.
*        l_rmenge = l_qty.
*        PERFORM conv2unit USING l_rmenge mara-meins g_u02-i_meins.
*        g_u02-e_lmenge = l_rmenge.
*      WHEN c_rdmpo_bstme OR c_rdmpo_opt OR c_rdmpo_opt_no_null.
*        g_u02-e_lmenge = floor( g_u02-i_menge ).
*    ENDCASE.
*  ELSE.
*    IF g_u02-i_scmng IS INITIAL.
*      RAISE no_round.
*    ENDIF.
*    l_rmenge = g_u02-e_lmenge.
*    PERFORM conv2unit USING l_rmenge g_u02-i_meins mara-meins.
*    l_scmng  = g_u02-i_scmng.
*    IF NOT g_u02-i_schme IS INITIAL.
*      l_bstme = g_u02-i_schme.
*    ELSE.
*      l_bstme = mara-meins.
*    ENDIF.
*    PERFORM conv2unit USING l_scmng l_bstme mara-meins.
*    l_ganz = l_rmenge DIV l_scmng.
*    l_rmenge = l_ganz * l_scmng.
*    PERFORM conv2unit USING l_rmenge mara-meins g_u02-i_meins.
*    g_u02-e_lmenge = l_rmenge.
*  ENDIF.
*
*ENDFORM.                               " RUNDE_VERF
*$@023 Ende MWE-ENTW-470-UNICODE

*$@024 mbi 4.70 - Anfang
*$*@004-BEGIN
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_TVKWZ
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_tvkwz.
*$
*$  DATA: l_werks LIKE lfa1-werks.
*$
*$  CLEAR g_t_vkorg_vtweg_vz[].
*$
*$*@011-Anfang
*$* CHECK NOT G_U02-I_LIFNR IS INITIAL.
*$*
*$*  Bei UB´s der Werksnummer des Lieferanten (= VZ) bestimmen.
*$* SELECT SINGLE WERKS FROM LFA1 INTO L_WERKS
*$*    WHERE LIFNR = G_U02-I_LIFNR.
*$
*$  IF NOT g_u02-i_lifnr IS INITIAL.
*$    SELECT SINGLE werks FROM lfa1 INTO l_werks
*$     WHERE lifnr = g_u02-i_lifnr.
*$  ELSE.
*$    l_werks = g_u02-i_werks_kred.
*$  ENDIF.
*$
*$  CHECK NOT l_werks IS INITIAL.
*$*@011-Ende
*$
*$  SELECT * FROM tvkwz
*$     WHERE werks = l_werks.
*$    g_t_vkorg_vtweg_vz-vkorg = tvkwz-vkorg.
*$    g_t_vkorg_vtweg_vz-vtweg = tvkwz-vtweg.
*$    APPEND g_t_vkorg_vtweg_vz.
*$  ENDSELECT.
*$
*$ENDFORM.                               " READ_TVKWZ
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_KNVV
*$*&--------------------------------------------------------------------
*$-*
*$FORM read_knvv.
*$
*$  DATA: l_kunnr LIKE t001w-kunnr.
*$
*$  CLEAR g_t_vkorg_vtweg_fi[].
*$
*$  CHECK NOT g_u02-i_werk IS INITIAL.
*$
*$*  Bei UB´s der Kundennummer der Filiale bestimmen.
*$  SELECT SINGLE kunnr FROM t001w INTO l_kunnr
*$     WHERE werks = g_u02-i_werk.
*$
*$  SELECT * FROM knvv
*$     WHERE kunnr = l_kunnr.
*$    g_t_vkorg_vtweg_fi-vkorg = knvv-vkorg.
*$    g_t_vkorg_vtweg_fi-vtweg = knvv-vtweg.
*$    APPEND g_t_vkorg_vtweg_fi.
*$  ENDSELECT.
*$
*$ENDFORM.                               " READ_KNVV
*$@024 mbi 4.70 - Ende

*$@024 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  ABMISCHEN_VZ_FI
*$*&--------------------------------------------------------------------
*$-*
*$FORM abmischen_vz_fi USING l_vkorg LIKE mvke-vkorg
*$l_vtweg like mvke-vtweg.
*$
*$DATA: l_lines         LIKE sy-stepl.
*$
*$CLEAR l_vkorg.
*$CLEAR l_vtweg.
*$
*$LOOP AT g_t_vkorg_vtweg_vz.
*$  READ TABLE g_t_vkorg_vtweg_fi
*$     WITH KEY vkorg = g_t_vkorg_vtweg_vz-vkorg
*$              vtweg = g_t_vkorg_vtweg_vz-vtweg.
*$  IF sy-subrc <> 0.
*$    DELETE g_t_vkorg_vtweg_vz.
*$  ENDIF.
*$ENDLOOP.
*$
*$DESCRIBE TABLE g_t_vkorg_vtweg_vz LINES l_lines.
*$
*$IF l_lines = 1.
*$  READ TABLE g_t_vkorg_vtweg_vz INDEX 1.
*$  l_vkorg = g_t_vkorg_vtweg_vz-vkorg.
*$  l_vtweg = g_t_vkorg_vtweg_vz-vtweg.
*$ENDIF.
*$
*$ENDFORM.                               " ABMISCHEN_VZ_FI
*$*@004-END
*$@024 mbi 4.70 - Ende

*
* 
