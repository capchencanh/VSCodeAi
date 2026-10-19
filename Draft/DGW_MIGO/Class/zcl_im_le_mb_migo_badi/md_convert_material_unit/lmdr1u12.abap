FUNCTION md_single_rounding.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_S_GENERAL) TYPE  MDR1INSINGLEROUND
*"     VALUE(I_S_MPN) TYPE  MDR1INSINGLEROUND_MPN OPTIONAL
*"  EXPORTING
*"     VALUE(E_S_RESULTS) TYPE  MDR1OUTSINGLEROUND
*"  TABLES
*"      E_T_ROUND_REASONS TYPE  MDR1TRUNDUNGSGRUND OPTIONAL
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
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       16.02.99  99A  mwe         Grundversion
*-       12.09.01  470  mbi         Schnittstelle RFC-fähig gemacht
*-                                  (ohne Änderungsmarke!)
*- @001  20.11.01  470  hwi         Customizing zur Rundung
*-----------------------------------------------------------------------

  DATA:  l_s_general        TYPE mdr1p_s_in_single_round,
         l_s_mpn            type mdr1insingleround_mpn,
         l_s_mara           LIKE mara,
         l_s_eina           LIKE eina,
         l_s_eine           LIKE eine,
         l_s_marc           LIKE marc,
         l_s_marc_2         LIKE marc,
         l_s_mvke           LIKE mvke,
         l_s_knmt           LIKE knmt,
         l_s_knvv           LIKE knvv,
         l_t_qt_units       TYPE mdr1p_t_out_allowed_qt_unit
                            WITH HEADER LINE.
* start authorization check for external calls.
* authority check for external calls only
   DATA: l_rfc         TYPE sap_bool.

  CALL METHOD cl_rfc=>check_rfc_external_direct
    RECEIVING
      direct_external_call = l_rfc
    EXCEPTIONS
      OTHERS               = 8.

  IF sy-subrc <> 0.
    CLEAR l_rfc.
  ENDIF.
  IF l_rfc EQ abap_true.
*   Call was performed via direct external RFC (other system, client or user)
*   Perform authorization check

     AUTHORITY-CHECK OBJECT 'M_MATE_STA'
        ID 'ACTVT' FIELD '03'
        ID 'STATM' DUMMY .
    IF SY-SUBRC NE 0.
      MESSAGE e853(M3).
    ENDIF.
     EXIT.
 ENDIF.
* end authorization check
*                *** Initialisiere die Rückgabewerte
  CLEAR: e_s_results.

*                *** Eingabeparameter lokal merken
  l_s_general = i_s_general.
  l_s_mpn = i_s_mpn.

*                *** Prüfe die Eingabeparameter
  PERFORM check_input_u12  USING    l_s_general
                           CHANGING l_s_mara  .

*                *** Belege die Ausgabe-Werte mit Default-Werten
  PERFORM output_default_value USING    l_s_general
                               CHANGING e_s_results.

*                *** Lese alle benötigten Daten aus der DB und lege
*                *** in der entsprechenden Struktur bzw. in
*                *** l_s_params_results ab:
*  PERFORM read_data_u12 TABLES   l_t_qt_units
*                        USING    l_s_mara
*                        CHANGING l_s_general
*                                 e_s_results
*                                 l_s_eina
*                                 l_s_eine
*                                 l_s_marc
*                                 l_s_marc_2
*                                 l_s_mvke
*                                 l_s_knmt
*                                 l_s_knvv.

  PERFORM read_data_u12_2 TABLES   l_t_qt_units
                          USING    l_s_mara
                                   l_s_mpn
                          CHANGING l_s_general
                                   e_s_results
                                   l_s_eina
                                   l_s_eine
                                   l_s_marc
                                   l_s_marc_2
                                   l_s_mvke
                                   l_s_knmt
                                   l_s_knvv.

*                *** Abfangen von Spezialfall:
*                *** Eingabe-Menge (I_S_GENERAL-MENGE) <= 0
  IF i_s_general-menge > 0.
*                *** => Führe Rundung nur für positive Mengen durch
*                ***    NEU !!! (=> kein Runden bei Retouren)

*                ***    Auswahl und Durchführung des Rundungsverfahrens
*                ***    Rundungsergebnis steht in:
*                ***    - e_s_results-menge   in Eingabe-ME
*                ***    - e_s_results-lmenge  in der Rundungs-ME: logme
*                ***    - e_s_results-logme   Rundungs-ME (= log. ME)
    PERFORM choose_rounding_method  TABLES   l_t_qt_units
                                             e_t_round_reasons
                                    USING    l_s_general
                                    CHANGING e_s_results.

  ENDIF.

*                *** Allgemeiner User-Exit zur Korrektur der Rundungs
*                *** werte
  PERFORM call_user_exit_004 TABLES   l_t_qt_units
                                      e_t_round_reasons
                             USING    l_s_general
                                      l_s_eina
                                      l_s_eine
                                      l_s_marc
                                      l_s_marc_2
                                      l_s_mvke
                                      l_s_knmt
                                      l_s_knvv
                             CHANGING e_s_results.

*                *** Abschlußbehandlung:
*                *** - Prüfe Rundungs-ME auf erlaubte ME
*                ***   bzw. bei einem Kontrakt auf die Kontrakt-ME

*#@001 HWI 4.70 customizing of logistical rounding B
  IF  l_s_general-konnr    IS INITIAL
  AND l_s_general-rchalum  =  c_yes.
*                *** 1. Fall: Kein Kontrakt und Prüfung laut Customizing
*                ***          erwünscht
*#@001 HWI 4.70 customizing of logistical rounding E
    PERFORM check_allowed_qtunit TABLES   l_t_qt_units
                                          e_t_round_reasons
                                 USING    l_s_general
                                 CHANGING e_s_results.
*#@001 HWI 4.70 customizing of logistical rounding B
  ELSEIF NOT l_s_general-konnr IS INITIAL.
*                *** 2. Fall: Kontrakt vorhanden -> Customizing
*                ***          unerheblich

    PERFORM check_allowed_qtunit_konnr TABLES   l_t_qt_units
                                        e_t_round_reasons
                               USING    l_s_general
                               CHANGING e_s_results.
  ENDIF.

*                *** - Entferne nicht gültige Dezimalstellen bei der
*                ***   Rundungsmenge
  IF l_s_general-rvaldec = c_yes.
*#@001 HWI 4.70 customizing of logistical rounding E

    PERFORM check_allowed_dec  TABLES   e_t_round_reasons
                               USING    l_s_general
                               CHANGING e_s_results.
*#@001 HWI 4.70 customizing of logistical rounding B
  ENDIF.

*                *** - Steuerungs-Profildaten des Customizing in der
*                ***   Rückgabe vermerken.
*                ***   vermerken:
  e_s_results-mandt    =  l_s_general-mandt.
  e_s_results-cprof    =  l_s_general-cprof.
  e_s_results-rvalu    =  l_s_general-rvalu.
  e_s_results-rdyna    =  l_s_general-rdyna.
  e_s_results-rstat    =  l_s_general-rstat.
  e_s_results-rmami    =  l_s_general-rmami.
  e_s_results-rchalum  =  l_s_general-rchalum.
  e_s_results-rvaldec  =  l_s_general-rvaldec.
  e_s_results-purpar   =  l_s_general-purpar.
  e_s_results-rleave   =  l_s_general-rleave.
  e_s_results-raufab   =  l_s_general-raufab.
*#@001 HWI 4.70 customizing of logistical rounding E

*                *** - Für LB-Aufrufstelle ursprüngliche Eingabe-ME
*                ***   wieder herstellen!!!
  IF l_s_general-opcode = mdr1p_c_op_lb.
    PERFORM check_lb_output     CHANGING l_s_general
                                         e_s_results.
  ENDIF.

*                *** - Prüfe, ob Rundungsgründe belegt werden
  IF  e_s_results-logme = i_s_general-meinh
  AND e_s_results-menge = i_s_general-menge.
*                ***   Es hat sich nichts an der Menge und der ME ver-
*                ***   ändert
*                ***   => Keine Rundungsgründe ausgeben!!!
    CLEAR: e_t_round_reasons,
           e_t_round_reasons[].
  ENDIF.

ENDFUNCTION.

*
* 
