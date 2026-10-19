FUNCTION md_einzelrundung.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_OPCODE) LIKE  SY-INPUT
*"     VALUE(I_MATNR) LIKE  MARA-MATNR
*"     VALUE(I_MENGE) TYPE  F
*"     VALUE(I_MEINS) LIKE  MARM-MEINH
*"     VALUE(I_WERK) LIKE  T001W-WERKS OPTIONAL
*"     VALUE(I_LIFNR) LIKE  LFA1-LIFNR OPTIONAL
*"     VALUE(I_EKORG) LIKE  EINE-EKORG OPTIONAL
*"     VALUE(I_INFNR) LIKE  EINA-INFNR OPTIONAL
*"     VALUE(I_PSTYP) LIKE  EKPO-PSTYP OPTIONAL
*"     VALUE(I_VKORG) LIKE  KNMT-VKORG OPTIONAL
*"     VALUE(I_VTWEG) LIKE  KNMT-VTWEG OPTIONAL
*"     VALUE(I_SPART) LIKE  KNVV-SPART OPTIONAL
*"     VALUE(I_KUNNR) LIKE  KNMT-KUNNR OPTIONAL
*"     VALUE(I_RDPR) LIKE  RDPR STRUCTURE  RDPR OPTIONAL
*"     VALUE(I_NO_MIN_MAX_CHECK) TYPE  C OPTIONAL
*"     VALUE(I_INFLS) LIKE  TVAK-INFLS DEFAULT 'X'
*"     VALUE(I_RDPRF) LIKE  MVKE-RDPRF OPTIONAL
*"     VALUE(I_SCMNG) LIKE  MVKE-SCMNG OPTIONAL
*"     VALUE(I_SCHME) LIKE  MVKE-SCHME OPTIONAL
*"     VALUE(I_WERKS_KRED) LIKE  T001W-WERKS OPTIONAL
*"     REFERENCE(I_OLD_VERSION) TYPE  C DEFAULT ' '
*"     REFERENCE(I_S_GENERAL) TYPE  MDR1P_S_IN_SINGLE_ROUND OPTIONAL
*"  EXPORTING
*"     VALUE(E_LMENGE) TYPE  F
*"     VALUE(E_LOGME) LIKE  MARM-MEINH
*"     VALUE(E_MENGE) TYPE  F
*"     VALUE(E_RDPRF) LIKE  MVKE-RDPRF
*"     VALUE(E_SCMNG) LIKE  MVKE-SCMNG
*"     VALUE(E_SCHME) LIKE  MVKE-SCHME
*"     VALUE(E_NICHT_KORREKT)
*"     REFERENCE(E_S_RESULTS) TYPE  MDR1P_S_OUT_SINGLE_ROUND
*"  TABLES
*"      T_RUNDUNGSGRUND TYPE  MDR1P_T_RUNDUNGSGRUND OPTIONAL
*"  EXCEPTIONS
*"      INVALID_OPCODE
*"      NO_PURCHASE_ORG
*"      RDPR_NOT_FOUND
*"      MATERIAL_NOT_FOUND
*"      MEINH_NOT_FOUND
*"      BAD_PARAMS
*"      DEBITOR_NOT_FOUND
*"      NO_ROUND
*"      RDPRF_NOT_FOUND
*"      ERROR
*"----------------------------------------------------------------------

*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @001  05.02.97  12b  schweizerm  Korrekturen zu Rel.1.2b
*- @002  08.04.98  40c  MWE         Erweiterung der Rundung zu 40c
*-                                  - neue Aufrufstelle bei Verkaufs-
*-                                    hilfsmittel
*-                                  - nur gültige Dezimalstellen
*-                                    zurückgeben
*- @003  16.04.98  40c  Doneyer
*- @004  02.07.98  4.5A MWE         Erweiterung für Rundung in LB
*- @005  03.03.99  99A  MWE         NEUER Rundungsbaustein:
*-                                  MD_SINGLE_ROUNDING übernimmt
*-                                  die Rundung von Mengen
*-                                  (alte Version kann nur noch
*-                                  über das NEUE Eingabe-Flag
*-                                  I_OLD_VERSION = 'X' aktiviert
*-                                  werden)
*- @006  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @007  01.12.99  46C  mwe         Berücksichtigung von Konsignations-
*-                                  Infosätze
*-                                  Korrektur zu Hinweis: 186918
*- @008  04.04.01  470  mwe         Unicode-Änderungen
*-                                  Entfernen von nicht mehr
*-                                  durchlaufenem Codeing
*- @009  15.01.01  470  mwe         Abbruchmeldung beim
*-                                  Aufruf des FB erzeugen und
*-                                  restliches Codeing auskommentieren
*-----------------------------------------------------------------------

*$@009 Anfang
  MESSAGE a004(lumer)
     WITH 'MD_EINZELRUNDUNG'
          'MD_SINGLE_ROUNDING'.
*$@005 Anfang
*  DATA: l_s_results    TYPE  mdr1p_s_out_single_round,
*        l_old_version  TYPE  c.
*
*$@008 Anfang MWE-ENTW-470-UNICODE
*  l_old_version = i_old_version.
*$@008 Ende MWE-ENTW-470-UNICODE
*$@005 Ende
*
** Eingabeparameter in g_u02 merken
*  CLEAR g_u02.
*  g_u02-i_opcode           = i_opcode.
*  g_u02-i_matnr            = i_matnr.
*  g_u02-i_menge            = i_menge.
*  g_u02-i_meins            = i_meins.
*  g_u02-i_werk             = i_werk.
*  g_u02-i_ekorg            = i_ekorg.
*  g_u02-i_lifnr            = i_lifnr.
*  g_u02-i_infnr            = i_infnr.
**$@007 Anfang MWE-HW-186918
*  g_u02-i_pstyp            = i_pstyp.
**$@007 Ende MWE-HW-186918
*  g_u02-i_vkorg            = i_vkorg.
*  g_u02-i_vtweg            = i_vtweg.
*  g_u02-i_spart            = i_spart.
*  g_u02-i_kunnr            = i_kunnr.
*  g_u02-i_rdpr             = i_rdpr.   "@001
*  g_u02-i_no_min_max_check = i_no_min_max_check.
*  g_u02-i_infls            = i_infls.
*  g_u02-i_rdprf            = i_rdprf.
*  g_u02-i_scmng            = i_scmng.
*  g_u02-i_schme            = i_schme.
**@003-Anfang
*  g_u02-i_werks_kred       = i_werks_kred.
**@003-Ende
*
*$@008 Anfang MWE-ENTW-470-UNICODE
**@005 Anfang
*  IF l_old_version IS INITIAL.
*$@008 Ende MWE-ENTW-470-UNICODE
** Aktivierung des NEUEN (zu 99A) Rundungsbausteins
*    PERFORM call_single_rounding USING    i_s_general
*                                          c_yes "MWE-ENTW-470-UNICODE
*                                 CHANGING l_s_results
*                                          g_u02.
*    e_s_results = l_s_results.
*
*$@008 Anfang MWE-ENTW-470-UNICODE
*  ELSE.
**@005 Ende
*
** bisher kein Rundungsgrund
*    CLEAR g_t_grund.
*    REFRESH g_t_grund.
*
**$@004 Anfang
** Überprüfe LB-Aufruf
*    IF i_opcode = 'L'.
**   => Aufruf erfolgte aus LB-Spezialfall
*      i_opcode       = mdr1p_c_op_mm_normal.
*      g_u02-i_opcode = i_opcode.
*      g_lb_call = c_charx.
*    ELSE.
**   => Aufruf nicht für den LB-Spezialfall
*      CLEAR g_lb_call.
*    ENDIF.
**$@004 Ende
*
** Parameter prüfen
*    g_params_ok = c_ja.              " setze defaultmässig Parameter OK
*    PERFORM check_params.              " vor dem Parameter-Check
*
*    IF g_params_ok = c_ja.           " Runde, wenn alle Eingabewerte OK
*      CASE i_opcode.
*        WHEN mdr1p_c_op_mm_normal OR mdr1p_c_op_mm_ub.
*          PERFORM runde_mm.
*        WHEN mdr1p_c_op_sd_auftrag OR mdr1p_c_op_sd_lieferung.
*          PERFORM runde_sd.
*        WHEN mdr1p_c_op_sd_verf.
*          PERFORM runde_verf.
*        WHEN mdr1p_c_op_additionals.   " @002
*          PERFORM rounding_for_additionals CHANGING g_u02.       " @002
*        WHEN OTHERS.
*          RAISE invalid_opcode.
*      ENDCASE.
*    ENDIF.
*
**$@002 Anfang
** nicht gültige Dezimalstellen entfernen:
*    PERFORM  falid_output_for_units USING g_u02.
**$@002 Ende
*
**$@004 Anfang
*    IF     g_lb_call   = c_charx
*       AND g_lb_change = c_charx.
**   => LB-Spezialfall führte zu Eingabe-Manipulation
*      CLEAR g_lb_change.
*      CLEAR g_lb_call.
**   Ausgabe in ursprünglicher Eingabemengeneinheit
*      PERFORM conv2unit USING g_u02-e_menge g_u02-i_meins g_lb_i_meins.
*      g_u02-i_meins   = g_lb_i_meins.
*    ENDIF.
**$@004 Ende
*
**@005 Anfang
*  ENDIF.
**@005 Ende
*$@008 Ende MWE-ENTW-470-UNICODE
*
** Rückgabewerte belegen
*  e_lmenge = g_u02-e_lmenge.
*  e_logme  = g_u02-e_logme.
*  e_menge  = g_u02-e_menge.
*  e_rdprf  = g_u02-e_rdprf.
*  e_scmng  = g_u02-e_scmng.
*  e_schme  = g_u02-e_schme.
** Rundung (bisher) immer korrekt
*  CLEAR e_nicht_korrekt.
** Rundungsgründe zurückliefern
*  t_rundungsgrund[] = g_t_grund[].
*$@009 Ende

ENDFUNCTION.

*
* 
