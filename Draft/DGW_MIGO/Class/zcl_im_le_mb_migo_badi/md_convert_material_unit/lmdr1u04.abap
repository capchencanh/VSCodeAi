FUNCTION md_simu_dyn_rund_profil.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_OPCODE) LIKE  SY-INPUT
*"     VALUE(I_MATNR) LIKE  MARA-MATNR OPTIONAL
*"     VALUE(I_MENGE) TYPE  MDR1MENGE OPTIONAL
*"     VALUE(I_MEINS) LIKE  MARM-MEINH OPTIONAL
*"     VALUE(I_WERK) LIKE  T001W-WERKS OPTIONAL
*"     VALUE(I_LIFNR) LIKE  LFA1-LIFNR OPTIONAL
*"     VALUE(I_EKORG) LIKE  EINE-EKORG OPTIONAL
*"     VALUE(I_INFNR) LIKE  EINA-INFNR OPTIONAL
*"     VALUE(I_VKORG) LIKE  KNMT-VKORG OPTIONAL
*"     VALUE(I_VTWEG) LIKE  KNMT-VTWEG OPTIONAL
*"     VALUE(I_SPART) LIKE  KNVV-SPART OPTIONAL
*"     VALUE(I_KUNNR) LIKE  KNMT-KUNNR OPTIONAL
*"     VALUE(I_RDPR) LIKE  RDPR STRUCTURE  RDPR OPTIONAL
*"     VALUE(I_NO_MIN_MAX_CHECK) TYPE  MDR1NOMINMAXCHECK OPTIONAL
*"     VALUE(I_INFLS) LIKE  TVAK-INFLS DEFAULT 'X'
*"     VALUE(I_RDPRF) LIKE  MVKE-RDPRF OPTIONAL
*"     VALUE(I_SCMNG) LIKE  MVKE-SCMNG OPTIONAL
*"     VALUE(I_SCHME) LIKE  MVKE-SCHME OPTIONAL
*"     VALUE(I_TEXT40) LIKE  RDTX-TEXT40
*"     VALUE(I_NAME1) LIKE  T001W-NAME1
*"  EXCEPTIONS
*"      INVALID_OPCODE
*"      BAD_PARAMS
*"      BAD_PROFIL
*"----------------------------------------------------------------------

*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       06.08.97  4.0  welterm     Grundversion für Aufruf in der
*-                                  Pflege von Rundungsprofile
*-                                  (Prog.: SAPL0WCL, Transaktion: OWD1)
*-       16.04.98  4.0c welterm     Fehlerausgabe mit Message und
*-                                  raising (=> keine Änderungsmarke)
*- @001  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*-        12.09.01  470  mbi        Schnittstelle RFC-fähig gemacht
*-                                  (ohne Änderungsmarke!)
*-----------------------------------------------------------------------

*                *** Eingabeparameter in g_u03 (globale Daten mit
*                *** der gleichen Struktur wie g_u02 von
*                *** md_einzelrundun erweitert um weitere Ein-
*                *** gabeparameter) merken!
  CLEAR g_u03.
  g_u03-i_text40               = i_text40.       " zusaetzlich zu g_u02
  g_u03-i_name1                = i_name1.        " zusaetzlich zu g_u02
  g_u03-u02-i_opcode           = i_opcode.
  g_u03-u02-i_matnr            = i_matnr.
  g_u03-u02-i_menge            = i_menge.
  g_u03-u02-i_meins            = i_meins.
  g_u03-u02-i_werk             = i_werk.
  g_u03-u02-i_ekorg            = i_ekorg.
  g_u03-u02-i_lifnr            = i_lifnr.
  g_u03-u02-i_infnr            = i_infnr.
  g_u03-u02-i_vkorg            = i_vkorg.
  g_u03-u02-i_vtweg            = i_vtweg.
  g_u03-u02-i_spart            = i_spart.
  g_u03-u02-i_kunnr            = i_kunnr.
  g_u03-u02-i_rdpr             = i_rdpr.
  g_u03-u02-i_no_min_max_check = i_no_min_max_check.
  g_u03-u02-i_infls            = i_infls.
  g_u03-u02-i_rdprf            = i_rdprf.
  g_u03-u02-i_scmng            = i_scmng.
  g_u03-u02-i_schme            = i_schme.

*                *** Aufrustelle festlegen (Default = 6)
  g_call_place_up = mdr1p_c_op_maintain_rdpf.

*                *** Je nach opcode muessen die Eingabe-Parameter
*                *** auf ihre Korrektheit ueberprueft werden!
  PERFORM sim_check_params.

*                *** Je nach Aufrufstelle (= opcode) wird die ent-
*                *** sprechende Simulation aufgerufen.
  CASE i_opcode.
* ???    when c_op_mm_normal            " Simulation bei Normal
* ???      or c_op_mm_ub.               "           oder Umlieferung
* ???        perform sim_runde_mm.
* ???    when c_op_sd_auftrag           " Simulation bei Auftrag
* ???      or c_op_sd_lieferung.        "           oder Lieferung
* ???        perform sim_runde_sd.
* ???    when c_op_sd_verf.             " Simulation bei ???
* ???        perform sim_runde_verf.
    WHEN mdr1p_c_op_maintain_rdpf.     " Simulation bei Pflege Profil

      PERFORM sim_maintain_rdpf.

    WHEN OTHERS.

      MESSAGE e071 WITH 'MD_SIMU_DYN_RUND_PROFIL' i_opcode
              RAISING invalid_opcode.

  ENDCASE.

ENDFUNCTION.

*
* 
