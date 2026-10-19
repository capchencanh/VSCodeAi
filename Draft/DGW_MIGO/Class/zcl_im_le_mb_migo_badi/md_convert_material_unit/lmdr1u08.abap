
* -------------------------------------------------------------------- *
FUNCTION f4_order_quantity.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_WERK) LIKE  T001W-WERKS
*"     VALUE(I_MATNR) LIKE  MARA-MATNR
*"     VALUE(I_MENGE) LIKE  EBAN-MENGE
*"     VALUE(I_MEINS) LIKE  MARA-BSTME
*"     VALUE(I_LIFNR) LIKE  LFA1-LIFNR OPTIONAL
*"     VALUE(I_EKORG) LIKE  EINE-EKORG OPTIONAL
*"     VALUE(I_LIWRK) LIKE  T001W-WERKS OPTIONAL
*"     VALUE(I_MESPERRE) TYPE  MDR1MESPERRE DEFAULT SPACE
*"     VALUE(I_PSTYP) LIKE  EKPO-PSTYP OPTIONAL
*"  EXPORTING
*"     VALUE(E_MENGE) LIKE  EBAN-MENGE
*"     VALUE(E_MEINS) LIKE  MARM-MEINH
*"  EXCEPTIONS
*"      WRONG_INPUT_COMBINATION
*"      ERROR_BY_OPERATION
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       ??.??.??  ???              Grundversion
*- @001  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @002  01.12.99  46C  mwe         Berücksichtigung von Konsignations-
*-                                  Infosätze
*-                                  Korrektur zu Hinweis: 186918
*- @003  02.03.00  46C  mwe         Korrekten MARC-Satz zu
*-                                  Wertartikeln bestimmen
*-                                  Korrektur zu Hinweis: 204696
*- @004  26.04.00  46C  wsc         Korrektur Hinweis 216366
*- @005  04.04.01  470  mwe         Unicode-Änderungen
*-                                  - Parameter typisieren
*-                                  - entfernen von veraltertem Codeing
*- @006  20.08.01  470  mbi         Fehlende Fehlerausgabe und Fehler
*-                                  bei der erweiterten Syntaxprüfung
*-                                  Korrektur zu Hinweis: 0428526
*-       12.09.01  470  mbi         Schnittstelle RFC-fähig gemacht
*-                                  (ohne Änderungsmarke!)
*- @007  14.01.02  470  mbi         Realisierung SMAD-Punkte
*-                                  - Verbesserung der Rundungs-
*-                                    Simulation
*-                                    (Marke: #mbi 4.70 RoundSimu )
*- @008  15.01.02  470  mwe         Fehler aus der erweiterten
*-                                  Syntax-Prüfung und CHECKMAN
*-                                  beseitigt
*-----------------------------------------------------------------------
* Dukumentation:  siehe FuBauSt-Doku
* Strukturen:
*  g_f4_data     hält alle nötigen 'Stammdaten'
*  g_f4_amounts  hält die verschiedenen Mengen und ME's
*  g_u01         hält globale Parameter ...
* Ablauf:
* 1. form collect_f4_data      bestimmt Daten für Struktur  g_f4_data
* 2. 'Initialisierung' der Daten in Struktur                g_f4_amounts
* 3. form calculate_f4_amounts bestimmt Daten für Struktur  g_f4_amounts
* 4. Aufruf Dynpro 0111 zur Ausgabe der Werte aus beiden Strukturen
* 5. Übernahme der auf dem Dynpro ausgewählten Menge und ME in
*    e_menge und e_meins
* Dynpro 0111:
*  auf dem Dynpro wird nach Änderung von Wunschmenge und/oder ME
*  form  calculate_f4_amounts   zur Neuberechnung der Daten/Werte
*  für Struktur g_f4_amounts aufgerufen.
* -------------------------------------------------------------------- *
*$@005 Anfang MWE-ENTW-470-UNICODE
  DATA:
    l_infnr      LIKE  eina-infnr.

*                *** Defaultwert für den Returncode des PAI-Moduls
  g_retcode = 0.

*                *** Prüfe, ob der FB  mit den korrekten Eingabepara.
*                *** aufgerufen wurde
  IF i_werk   IS INITIAL
  OR i_matnr  IS INITIAL
  OR i_meins  IS INITIAL.
    MESSAGE e002(rpugen) WITH    'F4_ORDER_QUANTITY'
                         RAISING wrong_input_combination.
  ENDIF.

*                *** Bestimme mit Hilfe der Eingabeparameter die Daten
*                *** in
*                *** - l_s_f4_data
*                *** - g_u01
  PERFORM collect_f4_data USING    i_werk
                                   i_matnr
                                   i_lifnr
                                   i_ekorg
                                   i_liwrk
                                   i_mesperre
                                   i_pstyp
                          CHANGING g_f4_data
                                   g_f4_amounts-basisme
                                   l_infnr.

*                *** Initialisierung von g_f4_amounts
  CLEAR: g_f4_amounts-bmenge,
         g_f4_amounts-bstme,
         g_f4_amounts-restb,
         g_f4_amounts-lmenge,
         g_f4_amounts-logme,
         g_f4_amounts-restl.

  g_f4_amounts-menge = i_menge.
  g_f4_amounts-meins = i_meins.
  g_f4_amounts-vorzb = c_positiv.
  g_f4_amounts-vorzl = c_positiv.
  g_f4_amounts-bstme = g_f4_data-bstme.

  IF NOT ( g_f4_amounts-meins IS  INITIAL ).
*                *** 'initiale' Berechnung der im Dynpro angezeigten
*                *** Mengen
    PERFORM calculate_f4_amounts  USING    i_matnr
                                           g_f4_data-werk
                                           l_infnr
                                           g_f4_data-vabme
                                  CHANGING g_f4_amounts.
  ENDIF.

  IF g_retcode <> 0.

    e_menge  = i_menge.
    e_meins  = i_meins.
    RAISE error_by_operation.

  ENDIF.

*                *** Dynpro aufrufen
  CALL SCREEN c_dynpro_f4_amounts STARTING AT sy-cucol sy-curow.

*                *** Rückgabewerte festlegen
  CASE g_fcode.

    WHEN c_fc_refd.
*                *** vom Benutzer eingegebener Wert (Wunschmenge)
      e_menge  = g_f4_amounts-menge.
      e_meins  = g_f4_amounts-meins.

    WHEN c_fc_rund.
*                *** Werte aus der Rundung
      e_menge  = g_f4_amounts-lmenge.
      e_meins  = g_f4_amounts-logme.

    WHEN c_fc_best.
*                *** Wert in BestME
      e_menge  = g_f4_amounts-bmenge.
      e_meins  = g_f4_amounts-bstme.

    WHEN OTHERS.
*                *** was setzen wir defaultmäßig ???
      e_menge  = i_menge.
      e_meins  = i_meins.

  ENDCASE.

ENDFUNCTION.

****************************************************************
***********   U N T E R P R O G R A M M E    *******************
****************************************************************


************************************************************************
*  Unterprogramme zum FB                                               *
************************************************************************


FORM collect_f4_data
  USING
    p_werk       LIKE      t001w-werks
    p_matnr      LIKE      mara-matnr
    p_lifnr      LIKE      lfa1-lifnr
    p_ekorg      LIKE      t024w-ekorg
    p_liwrk      LIKE      t001w-werks
    p_mesperre   TYPE      c
    p_pstyp      LIKE      ekpo-pstyp
  CHANGING
    p_s_f4_data  STRUCTURE g_f4_data
    p_meins      LIKE      mara-meins
    p_infnr      LIKE      eina-infnr.

  DATA: l_rdprf        LIKE   rdpr-rdprf,
        l_ekorg        LIKE   eine-ekorg,
        l_kzinfosatz   TYPE   c,
        l_ul_lief      LIKE   t001w-lifnr,
        l_subrc        LIKE   sy-subrc,
        l_s_t001w      LIKE   t001w,
        l_s_lfa1       LIKE   lfa1,
        l_s_makt       LIKE   makt,
        l_s_mara       LIKE   mara,
        l_s_marc_werk  LIKE   marc,
        l_s_marc_liwrk LIKE   marc,
        l_s_eina       LIKE   eina,
        l_s_eine       LIKE   eine,
        l_s_rdtx       LIKE   rdtx.

*                *** kommt die Position aus einer Bestellung,
*                *** so darf die Mengeneinheit
*                *** nicht mehr verändert werden
  g_u01-kz_mesperre = p_mesperre.

*                *** Art der Bestellung bestimmen
*$@006 Anfang HW-428526-MBI
*$  IF     NOT ( p_lifnr IS INITIAL ).
*$
*$    g_u01-kz_ub = c_no.
*$
*$  ELSEIF NOT ( p_liwrk IS INITIAL ).
*$
*$    g_u01-kz_ub = c_yes.
*$
*$  ELSEIF     p_lifnr IS INITIAL
*$         AND p_liwrk IS INITIAL.
*$
*$    g_u01-kz_ub = c_no.
*$
*$  ELSE.
*$
*$    MESSAGE e002(rpugen) WITH    'F4_ORDER_QUANTITY'
*$                         RAISING wrong_input_combination.
*$
*$  ENDIF.
  IF     NOT ( p_lifnr IS INITIAL ).

    g_u01-kz_ub = c_no.

  ELSEIF NOT ( p_liwrk IS INITIAL ).

    g_u01-kz_ub = c_yes.

  ELSE.

    MESSAGE e002(rpugen) WITH    'F4_ORDER_QUANTITY'
                         RAISING wrong_input_combination.

  ENDIF.
*$@006 Ende HW-428526-MBI

*                *** Betriebestamm lesen
  IF g_u01-kz_ub = c_yes.

    PERFORM read_t001w_new USING    p_liwrk
                           CHANGING l_s_t001w.

    IF sy-subrc <> 0.

      MESSAGE s018 WITH    p_liwrk
                   RAISING error_by_operation.

    ENDIF.

    p_s_f4_data-liwrk    = p_liwrk.
    p_s_f4_data-nameliwk = l_s_t001w-name1.
    l_ul_lief            = l_s_t001w-lifnr.

  ENDIF.

  CLEAR: l_s_t001w.

  PERFORM read_t001w_new USING    p_werk
                         CHANGING l_s_t001w.

  IF sy-subrc <> 0.

    MESSAGE s018 WITH    p_werk
                 RAISING wrong_input_combination.

  ENDIF.

  p_s_f4_data-werk     = l_s_t001w-werks.
  p_s_f4_data-namewerk = l_s_t001w-name1.

*                *** Lieferantenstamm lesen
  PERFORM read_lfa1_single  USING    p_lifnr
                            CHANGING l_s_lfa1.

  p_s_f4_data-lief      = l_s_lfa1-lifnr.
  p_s_f4_data-namelief  = l_s_lfa1-name1.

*                *** Materialstamm (MAKT,MARA,MARC) lesen
  PERFORM read_makt  USING    p_matnr
                              p_werk
                     CHANGING l_s_makt.

  PERFORM read_mara_single USING     p_matnr
                           CHANGING  l_s_mara.

  PERFORM read_marc_single USING     p_matnr
                                     p_werk
                           CHANGING  l_s_marc_werk.

  p_s_f4_data-matnr    = p_matnr.
  p_s_f4_data-namemat  = l_s_makt-maktx.

*                *** EkOrg ermitteln, falls nicht angegeben - zum
*                *** Infosatzlesen und für MD_SINGLE_ROUNDING
  IF p_ekorg IS INITIAL.

    PERFORM read_ekorg_with_umlag  USING    p_werk
                                            g_u01-kz_ub
                                   CHANGING l_ekorg.

  ELSE.

    l_ekorg = p_ekorg.

  ENDIF.

  g_u01-i_ekorg = l_ekorg.

*                *** Infosatz lesen für Rundungsprofil und für
*                *** MD_SINGLE_ROUNDING
  IF g_u01-kz_ub = c_no.

    g_u01-lifnr = p_lifnr.

  ELSE.

    g_u01-lifnr = l_ul_lief.

  ENDIF.

  PERFORM read_eina_eine   USING    g_u01-lifnr
                                    l_ekorg
                                    p_werk
                                    p_matnr
                                    space
                                    l_s_mara-satnr
                                    l_s_mara-attyp
                                    p_pstyp
                                    space
                                    space
                           CHANGING l_s_eina
                                    l_s_eine.


  IF l_s_eina  IS  INITIAL
  OR l_s_eine  IS  INITIAL.
    l_kzinfosatz = c_no.
  ELSE.
    l_kzinfosatz = c_yes.
    p_infnr      = l_s_eina-infnr.
  ENDIF.

*                *** Rundungsprofil bestimmen: EINE vor MARC
  IF l_kzinfosatz = c_no.
    l_rdprf = l_s_marc_werk-rdprf.
  ELSE.
    l_rdprf = l_s_eine-rdprf.
  ENDIF.

*                *** Rundungsprofiltext lesen
  PERFORM read_rdtx_single USING    p_werk
                                    l_rdprf
*$@006 Anfang HW-428526-MBI
*$                                    l_subrc
*$                           CHANGING l_s_rdtx.

                           CHANGING l_subrc
                                    l_s_rdtx.
*$@006 Ende HW-428526-MBI

  IF l_subrc <> 0.
    MESSAGE s020  WITH    l_rdprf
                  RAISING error_by_operation.
  ENDIF.

  p_s_f4_data-rdprf   = l_rdprf.
  p_s_f4_data-namerd  = l_s_rdtx-text40.

*                *** Bestellmenge und Kennzeichen 'Variable BestME
*                *** erlaubt?' lesen
  IF g_u01-kz_ub = c_no.             "kein Lieferwerk

    IF l_kzinfosatz = c_yes.

      p_s_f4_data-bstme = l_s_eina-meins.
      p_s_f4_data-vabme = l_s_eina-vabme.

    ELSE.

      p_s_f4_data-bstme = l_s_mara-bstme.
      p_s_f4_data-vabme = l_s_mara-vabme.

    ENDIF.

  ELSE.                                "Lieferwerk

    IF l_kzinfosatz = c_yes.

      p_s_f4_data-bstme = l_s_eina-meins.
      p_s_f4_data-vabme = l_s_eina-vabme.

    ELSE.

      PERFORM read_marc_single  USING    p_matnr
                                         p_liwrk
                                CHANGING l_s_marc_liwrk.

      p_s_f4_data-bstme = l_s_marc_liwrk-ausme.
      p_s_f4_data-vabme = l_s_mara-vabme.

    ENDIF.

  ENDIF.

  IF p_s_f4_data-bstme IS INITIAL.
*                *** falls keine BSTME ermittelt werden konnte,
*                *** BasisME nehmen
    p_s_f4_data-bstme = l_s_mara-meins.

  ENDIF.

*                *** Basis-ME entsprechend belegen
  p_meins = l_s_mara-meins.

ENDFORM.                    "collect_f4_data



*---------------------------------------------------------------------*
*  FORM calculate_f4_amounts
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
*  -->  P_MATNR
*  -->  P_WERKS
*  -->  P_INFNR
*  -->  P_VABME
*  -->  P_F4_AMOUNTS
*---------------------------------------------------------------------*
FORM calculate_f4_amounts
  USING
    p_matnr       LIKE        mara-matnr
    p_werks       LIKE        t001w-werks
    p_infnr       LIKE        eina-infnr
    p_vabme       LIKE        mara-vabme
  CHANGING
    p_f4_amounts  STRUCTURE   g_f4_amounts.

*                *** ausgehend von der Wunschmenge in g_f4_amounts-menge
*                *** und -meins werden nun die entspr. Mengen in
*                *** BestellME bzw. nach Anwendung des
*                *** Rundungsprofils berechnet, samt Restmengen in
*                *** BasisME.
  DATA: l_opcode           LIKE sy-input,
        l_elmenge          TYPE mdr1p_p_16_dec_14,
        l_hmenge           TYPE mdr1p_p_16_dec_14,
        l_elogme           LIKE mara-meins,
        l_f_elmenge        TYPE f,
        l_f_hmenge         TYPE f,
        l_s_general        TYPE mdr1p_s_in_single_round,
        l_s_results        TYPE mdr1p_s_out_single_round,
        l_s_u02            TYPE mdr1p_in_md_einzelr.

*                *** Menge in BestellME
  l_hmenge = p_f4_amounts-menge.

  PERFORM conv2unit_f4  USING     p_matnr
                                  p_f4_amounts-meins
                                  p_f4_amounts-bstme
                        CHANGING  l_hmenge.

  p_f4_amounts-bmenge = l_hmenge.

*                *** Rest dazu (incl. Vorzeichen)
  PERFORM calculate_remainder USING    p_matnr
                                       p_f4_amounts
                              CHANGING p_f4_amounts-bmenge
                                       p_f4_amounts-bstme
                                       p_f4_amounts-restb
                                       p_f4_amounts-vorzb.

*                *** Menge in 'log. ME' nach Rundung
  IF g_u01-kz_ub = c_no.

    l_opcode = mdr1p_c_op_mm_normal.

  ELSE.

    l_opcode = mdr1p_c_op_mm_ub.

  ENDIF.

*                *** Rundungsbaustein wird immer aufgerufen, wg.
*                *** Rundungswert, MinMaxMenge
  l_hmenge = p_f4_amounts-menge.

  l_f_hmenge  =  l_hmenge.

  l_s_general-opcode           = l_opcode.
  l_s_general-matnr            = p_matnr.
  l_s_general-menge            = l_f_hmenge.
  l_s_general-meinh            = p_f4_amounts-meins.
  l_s_general-werks            = p_werks.
  l_s_general-lifnr            = g_u01-lifnr.
  l_s_general-ekorg            = g_u01-i_ekorg.
  l_s_general-infnr            = p_infnr.

  g_s_0111_general             = l_s_general.

  PERFORM call_single_rounding USING      l_s_general
                                          c_no        "kein Fehlerausg.
                               CHANGING   l_s_results
                                          l_s_u02.

  l_f_elmenge  = l_s_results-lmenge.
  l_elogme     = l_s_results-logme.

  l_elmenge  =  l_f_elmenge.

  IF sy-subrc = 0.
*                *** Übernahme der gerundeten Menge in einer ME gemäß
*                *** Kennzeichen 'VarME'
    IF p_vabme IS INITIAL.
*                *** keine variable BestME erlaubt, also 'gerundete'
*                *** Menge in g_f4_amounts-bstme umrechnen ...
      PERFORM conv2unit_f4  USING     p_matnr
                                      l_elogme
                                      p_f4_amounts-bstme
                            CHANGING  l_elmenge.

      p_f4_amounts-lmenge  = l_elmenge.
      p_f4_amounts-logme   = p_f4_amounts-bstme.

    ELSE.

      p_f4_amounts-lmenge  = l_elmenge.
      p_f4_amounts-logme   = l_elogme.

    ENDIF.

  ELSE.

    p_f4_amounts-lmenge = 0.
    g_retcode = 1.

  ENDIF.

*                *** Rest dazu
  PERFORM calculate_remainder USING    p_matnr
                                       p_f4_amounts
                              CHANGING p_f4_amounts-lmenge
                                       p_f4_amounts-logme
                                       p_f4_amounts-restl
                                       p_f4_amounts-vorzl.

ENDFORM.                    "calculate_f4_amounts


*---------------------------------------------------------------------*
*  FORM calculate_remainder
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
*  -->  P_MATNR
*  -->  P_F4_AMOUNTS
*  -->  P_AMOUNT
*  -->  P_UNIT
*  -->  P_REMAINDER
*  -->  P_SIGN
*---------------------------------------------------------------------*
FORM calculate_remainder
  USING
    p_matnr       LIKE mara-matnr
    p_f4_amounts  LIKE g_f4_amounts
  CHANGING
    p_amount      LIKE eban-menge
    p_unit        LIKE mara-meins
    p_remainder   LIKE eban-menge
    p_sign        TYPE c.
*                *** Unterprogramm zur Bestimmung der Differenz in
*                *** BasisME zwischen der übergebenen Menge   AMOUNT
*                *** in der Mengeneinheit  UNIT, und der
*                *** Wunschmenge  G_F4_AMOUNTS-MENGE   in der ME
*                *** G_F4_AMOUNTS-MEINS.

*                *** die in 'remainder' zurückgelieferte Menge ist immer
*                *** positiv !
*                *** das Vorzeichen ist gesondert in 'sign' abgelegt.
  DATA: l_hamount1 TYPE mdr1p_p_16_dec_14,
        l_hamount2 TYPE mdr1p_p_16_dec_14.

*                *** Rechne Wunschmenge in BasisME um
  l_hamount1 = p_f4_amounts-menge.

  PERFORM conv2unit_f4  USING     p_matnr
                                  p_f4_amounts-meins
                                  p_f4_amounts-basisme
                        CHANGING  l_hamount1.

*                *** Rechne 'amount' von 'unit' in BasisME
  l_hamount2 = p_amount.

  PERFORM conv2unit_f4  USING     p_matnr
                                  p_unit
                                  p_f4_amounts-basisme
                        CHANGING  l_hamount2.


*                *** Berechne Differenz der Mengen (= 'remainder')
  p_remainder = l_hamount1 - l_hamount2.

  IF p_remainder < 0.

    p_sign = c_negativ.

  ELSE.

    p_sign = c_positiv.

  ENDIF.

  p_remainder = abs( p_remainder ).

ENDFORM.                    "calculate_remainder



************************************************************************
*  Unterprogramme zum Dynpro-Processing                                *
************************************************************************


FORM set_status_0111
  USING
    rt_extab  TYPE  slis_t_extab.

  DATA : l_fcode LIKE rsmpe-func.

  IF g_u01-kz_mesperre = c_yes.         "Pos. aus Bestellung
*                *** Wurde die Position aus einer Bestellung übernommen,
*                *** darf die Mengen einheit nicht mehr geändert werden
*                *** => nur Button 'Wunschmenge' aktiv
    DELETE rt_extab WHERE fcode = 'REFD'.

    l_fcode = 'BEST'.
    APPEND l_fcode
        TO rt_extab.

    l_fcode = 'RUND'.
    APPEND l_fcode
        TO rt_extab.

  ELSE.                                "keine Bestellpos.
*                *** ist variable BestellME nicht erlaubt, darf nur der
*                *** Button zur Übernahme der Menge in BestellME aktiv
*                *** sein, bzw. der Button zu Übernahme der gerundeten
*                *** Menge, da bei Rundung auch VabMe berücks.
    IF g_f4_data-vabme IS INITIAL.

      DELETE rt_extab WHERE fcode = 'BEST'.
      DELETE rt_extab WHERE fcode = 'RUND'.

      l_fcode = 'REFD'.
      APPEND l_fcode TO rt_extab.

    ENDIF.
*                *** ist variable BestellME erlaubt, sind alle Buttons
*                *** aktiv ...
    IF NOT ( g_f4_data-vabme IS INITIAL ).

      DELETE rt_extab WHERE fcode = 'BEST'.
      DELETE rt_extab WHERE fcode = 'REFD'.
      DELETE rt_extab WHERE fcode = 'RUND'.

    ENDIF.

  ENDIF.

*                *** solange keine Wunsch-ME spezifiziert ist, kann auch
*                *** die Wunschmenge nicht übernommen werden ...
  IF g_f4_amounts-meins IS INITIAL.

    l_fcode = 'REFD'.
    APPEND l_fcode TO rt_extab.

  ENDIF.

  SET PF-STATUS c_status_f4_amounts EXCLUDING rt_extab.

ENDFORM.                               " SET_STATUS_0111


*---------------------------------------------------------------------*
*       FORM FCODE_F4_AMOUNTS                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fcode_f4_amounts.

  CASE g_fcode.

    WHEN c_fc_refd.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN c_fc_rund.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN c_fc_best.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN c_fc_info.
      PERFORM display_info.

*$@007 Anfang #mbi 4.70 RoundSimu
    WHEN c_fc_simu.
      PERFORM call_mdr1_simu_rounding
        USING g_s_0111_general.
*$@007 Ende #mbi 4.70 RoundSimu

  ENDCASE.

ENDFORM.                               " FCODE_F4_AMOUNTS

*---------------------------------------------------------------------*
*  FORM display_info
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
FORM display_info.
*                *** Test zur Ausgabe eines Info-Popups zur F4-Hilfe von
*                *** Dynpro 01111

  CALL FUNCTION 'POPUP_DISPLAY_TEXT'
       EXPORTING
           language       = sy-langu
            popup_title    = ' '
           start_column   = 10
           start_row      = 3
           text_object    = 'F4_ORDER_QUANTITY_INFO'
           help_modal     = c_yes
*    IMPORTING
*         CANCELLED      =
*    EXCEPTIONS
*         TEXT_NOT_FOUND = 1
*         OTHERS         = 2
            .
*  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.


ENDFORM.                    "display_info



*---------------------------------------------------------------------*
*  FORM f4_meins
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
FORM f4_meins.
*                *** F4-Hilfe auf Wunsch-ME (g_f4_amounts-meins) in
*                *** Dynpro 0111 das geht auch noch schöner mit FuBauSt
*                *** SMEINH_MEINH_HELP z.B. in  display_units (SAPMM06E)

  DATA: l_numlines  LIKE sy-tabix,
        l_meins     LIKE mara-meins,
        l_menge     TYPE mdr1p_p_16_dec_14,
        l_display   TYPE c.

  DATA: BEGIN OF l_t_fieldtab OCCURS 0.
          INCLUDE STRUCTURE help_value.
  DATA: END OF l_t_fieldtab.

  DATA: BEGIN OF l_t_valuetab OCCURS 0,
          text(100),
        END OF l_t_valuetab.
*                *** Parameter für Baustein F4_ALLOWED_QUANTITY_UNIT
  DATA: l_allowed_unit_parameters TYPE mdr1p_s_in_allowed_qt_unit,
        lt_allowed_units          TYPE mdr1p_t_out_allowed_qt_unit
                                  WITH HEADER LINE.
*                *** 'alte' Mengeneinheit vom Dynpro 'retten' ...
*                *** zusätzlich 'alte' Menge 'retten' - dmarx 17/05/99
  DATA: BEGIN OF l_dynpfields OCCURS 3.
          INCLUDE STRUCTURE dynpread.
  DATA: END OF l_dynpfields.
  DATA: l_dynnr      LIKE sy-dynnr.


  l_dynnr = sy-dynnr.

  l_dynpfields-fieldname  = 'G_F4_AMOUNTS-MEINS'.
  APPEND l_dynpfields.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = 'SAPLMDR1'
      dynumb     = l_dynnr
    TABLES
      dynpfields = l_dynpfields
    EXCEPTIONS
      OTHERS     = 04.

  g_f4_amounts-meins = l_dynpfields-fieldvalue.

  CLEAR l_dynpfields[].

  l_dynpfields-fieldname  = 'G_F4_AMOUNTS-MENGE'.
  APPEND l_dynpfields.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = 'SAPLMDR1'
      dynumb     = l_dynnr
    TABLES
      dynpfields = l_dynpfields
    EXCEPTIONS
      OTHERS     = 04.

  g_f4_amounts-menge = l_dynpfields-fieldvalue.

*                *** anzuzeigende Felder bekanntgeben, Schlüsselfelder
*                *** definieren
  l_t_fieldtab-tabname = 'MARM'.
  l_t_fieldtab-fieldname = 'MEINH'.
  l_t_fieldtab-selectflag = c_yes.
  APPEND l_t_fieldtab.

  l_t_fieldtab-tabname = 'T006A'.
  l_t_fieldtab-fieldname = 'MSEHL'.
  l_t_fieldtab-selectflag = c_no.
  APPEND l_t_fieldtab.

*                *** neue Bestimmung der erlaubten ME's  dmarx 29/11/99
  l_allowed_unit_parameters-appview       = mdr1p_c_appview_purchase.
  l_allowed_unit_parameters-flagallqtunit = c_yes.
  l_allowed_unit_parameters-lifnr         = g_f4_data-lief.
  l_allowed_unit_parameters-ekorg         = g_u01-i_ekorg.
  l_allowed_unit_parameters-werks         = g_f4_data-werk.
  l_allowed_unit_parameters-matnr         = g_f4_data-matnr.

  CALL FUNCTION 'F4_ALLOWED_QUANTITY_UNIT'
    EXPORTING
      i_s_general  = l_allowed_unit_parameters
      i_dialog     = ' '
    TABLES
      o_t_qt_units = lt_allowed_units
    EXCEPTIONS
      bad_params   = 1
      error        = 2
      OTHERS       = 99.

  IF sy-subrc <> 0.

    MESSAGE s017.
    EXIT.

  ENDIF.

  LOOP AT lt_allowed_units.
*                *** 1. Mengeneinheit
    l_t_valuetab-text = lt_allowed_units-meinh.
    APPEND l_t_valuetab.
*                *** 2. Bezeichnung
    l_t_valuetab-text = lt_allowed_units-msehl.
    APPEND l_t_valuetab.
  ENDLOOP.


*                *** überhaupt was gefunden?
  DESCRIBE TABLE l_t_valuetab LINES l_numlines.

  IF l_numlines <= 0.
    MESSAGE s017.
    EXIT.
  ENDIF.

*                *** Popup ausgeben
  l_display = c_no.
  IF g_u01-kz_mesperre = c_yes.
*                *** Pos. aus Best., keine andere ME erlaubt => F4 nur
*                *** mit Anzeige
    l_display = c_yes.
  ELSE.
*                *** andere ME erlaubt => F4 mit Auswahlmöglichkeit
    l_display = c_no.
  ENDIF.

*$@008 Anfang
* Bitte F4IF_INT_TABLE_VALUE_REQUEST verwenden
*$  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
*$    EXPORTING
*$*            CUCOL         = 1
*$*            CUROW         = 1
*$             display       = l_display
*$             fieldname     = 'MEINH'   "für die Überschrift
*$             tabname       = 'MARM'
*$             no_conversion = c_yes
*$    IMPORTING
*$             select_value  = l_meins
*$    TABLES
*$             fields        = l_t_fieldtab
*$             valuetab      = l_t_valuetab
*$    EXCEPTIONS
*$             field_not_in_ddic = 1
*$             more_then_one_selectfield = 2
*$             no_selectfield = 3.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE         = ' '
      retfield               = 'MEINH'
*     PVALKEY                = ' '
*     DYNPPROG               = ' '
*     DYNPNR                 = ' '
*     DYNPROFIELD            = ' '
*     STEPL                  = 0
*     WINDOW_TITLE           =
*     VALUE                  = ' '
*     VALUE_ORG              = 'C'
*     MULTIPLE_CHOICE        = ' '
      display                = l_display
*     CALLBACK_PROGRAM       = ' '
*     CALLBACK_FORM          = ' '
*     MARK_TAB               =
*   IMPORTING
*     USER_RESET             =
    TABLES
      value_tab              = l_t_valuetab
*     field_tab              = l_t_fieldtab
*     RETURN_TAB             =
*     DYNPFLD_MAPPING        =
    EXCEPTIONS
      parameter_error        = 1
      no_values_found        = 2
      OTHERS                 = 3.

  CHECK NOT l_meins IS INITIAL.

*                *** Auswahl einer ME nur möglich, wenn Pos. nicht aus
*                *** Bestellung ...
  CHECK NOT g_u01-kz_mesperre = c_yes.

*                *** Mengenfelder an neue ME anpassen
  l_menge = g_f4_amounts-menge.

  PERFORM conv2unit_f4 USING     g_f4_data-matnr
                                 g_f4_amounts-meins
                                 l_meins
                       CHANGING  l_menge.

  g_f4_amounts-menge = l_menge.
  g_f4_amounts-meins = l_meins.

*                *** geänderte Felder am Screen neu ausgeben
*                *** perform screen_anpassen.
  l_dynpfields-stepl = 1.

  l_dynpfields-fieldname  = 'G_F4_AMOUNTS-MENGE'.

  WRITE g_f4_amounts-menge TO l_dynpfields-fieldvalue LEFT-JUSTIFIED
        UNIT g_f4_amounts-meins.

  APPEND l_dynpfields.

  l_dynpfields-fieldname  = 'G_F4_AMOUNTS-MEINS'.
  l_dynpfields-fieldvalue = g_f4_amounts-meins.
  APPEND l_dynpfields.

  PERFORM set_value_on_screen TABLES l_dynpfields.

ENDFORM.                                                    " F4_MEINS

*---------------------------------------------------------------------*
*  FORM plausi_meins
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
FORM plausi_meins.
*                *** Überprüfung, ob eingegebene Wunsch-ME
*                *** (g_f4_amounts-meins) erlaubt ? *
  DATA: l_meins(3) TYPE c.

*                *** MARM nur lesen, wenn nicht Bestell-ME oder Basis-ME
*                *** eingegeben
  IF g_f4_amounts-meins = g_f4_amounts-bstme
  OR g_f4_amounts-meins = g_f4_amounts-basisme.

    sy-subrc = 0.

  ELSE.

    SELECT SINGLE   *
             FROM   marm
            WHERE   matnr = g_f4_data-matnr
              AND   meinh = g_f4_amounts-meins.
  ENDIF.

  IF sy-subrc <> 0.

    l_meins = g_f4_amounts-meins.
    CLEAR g_f4_amounts-meins.

    MESSAGE i007 WITH g_f4_data-matnr l_meins.

  ENDIF.

ENDFORM.                    "plausi_meins


*---------------------------------------------------------------------*
*  FORM conv2unit_f4
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
*  -->  P_MATNR
*  -->  P_IN_ME
*  -->  P_OUT_ME
*  -->  P_MENGE
*---------------------------------------------------------------------*
FORM conv2unit_f4
  USING
    p_matnr     LIKE  mara-matnr
    p_in_me     LIKE  mara-meins
    p_out_me    LIKE  mara-meins
  CHANGING
    p_menge     TYPE  mdr1p_p_16_dec_14.

  DATA: l_help_menge       LIKE ekpo-menge,
        l_t_round_reasons  TYPE mdr1p_t_rundungsgrund
                           WITH HEADER LINE.

  l_help_menge  =  p_menge.

  CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
    EXPORTING
      i_matnr              = p_matnr
      i_in_me              = p_in_me
      i_out_me             = p_out_me
      i_menge              = l_help_menge
    IMPORTING
      e_menge              = l_help_menge
    EXCEPTIONS
      error_in_application = 1
      error                = 2
      error_message        = 98
      OTHERS               = 99.

  IF sy-subrc <> 0.

    CLEAR: sy-subrc.

  ELSE.

    p_menge = l_help_menge.

    PERFORM remove_no_valid_dec  TABLES    l_t_round_reasons
                                 USING     p_out_me
                                 CHANGING  p_menge.

  ENDIF.

ENDFORM.                    "conv2unit_f4

*&---------------------------------------------------------------------*
*&      Form  SET_VALUE_ON_SCREEN
*&---------------------------------------------------------------------*
FORM set_value_on_screen TABLES dynpfields STRUCTURE dynpread.

  DATA: l_repid LIKE sy-repid.
  DATA: l_dynnr LIKE sy-dynnr.

* dem FuBau keine Referenz auf SY-Felder geben!!!
  l_repid = sy-repid.
  l_dynnr = sy-dynnr.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = l_repid
      dynumb     = l_dynnr
    TABLES
      dynpfields = dynpfields
    EXCEPTIONS
      OTHERS     = 1.

ENDFORM.                               " SET_VALUE_ON_SCREEN


*$@007 Anfang #mbi 4.70 RoundSimu
*&---------------------------------------------------------------------*
*&      Form  FCODE_ERFASSUNG
*&---------------------------------------------------------------------*
FORM fcode_erfassung.

  CASE g_fcode.

    WHEN c_fc_refd.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN c_fc_rund.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN c_fc_simu.
      PERFORM call_mdr1_simu_rounding
        USING g_s_0111_general.

  ENDCASE.

ENDFORM.                               " FCODE_ERFASSUNG
*$@007 Ende #mbi 4.70 RoundSimu

*  g_retcode = 0.
*
** wurden die nötigen Eingaben gemacht ??
*  IF i_werk IS INITIAL  OR
*     i_matnr IS INITIAL OR
*     i_meins IS INITIAL.
*    RAISE wrong_input_combination.
*  ENDIF.
*
** Bestimmung der nötigen Hilfs-Daten in g_f4_data und einiger globaler
** Parameter in Struktur g_u01
*  PERFORM collect_f4_data CHANGING g_f4_data
*                                   i_werk i_matnr i_lifnr
*                                   i_ekorg i_liwrk i_mesperre
**$@002 Anfang MWE-HW-186918
*                                   i_pstyp.
**$@002 Ende MWE-HW-186918
*
** Initialisierung von g_f4_amounts
*  g_f4_amounts-menge = i_menge.
*  g_f4_amounts-meins = i_meins.
*  CLEAR: g_f4_amounts-bmenge, g_f4_amounts-bstme, g_f4_amounts-restb,
*         g_f4_amounts-lmenge, g_f4_amounts-logme, g_f4_amounts-restl.
*  g_f4_amounts-vorzb = c_positiv.
*  g_f4_amounts-vorzl = c_positiv.
*  g_f4_amounts-bstme = g_f4_data-bstme.
*  g_f4_amounts-basisme = mara-meins.
*
** 'initiale' Berechnung der im Dynpro angezeigten Mengen
*  PERFORM calculate_f4_amounts CHANGING g_f4_amounts.
*
*  IF g_retcode <> 0.
*    e_menge  = i_menge.
*    e_meins  = i_meins.
*    RAISE error_by_operation.
*  ENDIF.
*
** Dynpro aufrufen
*  CALL SCREEN c_dynpro_f4_amounts STARTING AT sy-cucol sy-curow.
*
** Rückgabewerte festlegen
*  CASE g_fcode.
*    WHEN c_fc_refd.
**** vom Benutzer eingegebener Wert (Wunschmenge)
*      e_menge  = g_f4_amounts-menge.
*      e_meins  = g_f4_amounts-meins.
*    WHEN c_fc_rund.
**** Werte aus der Rundung
*      e_menge  = g_f4_amounts-lmenge.
*      e_meins  = g_f4_amounts-logme.
*    WHEN c_fc_best.
**** Wert in BestME
*      e_menge  = g_f4_amounts-bmenge.
*      e_meins  = g_f4_amounts-bstme.
*    WHEN OTHERS.
**** was setzen wir defaultmäßig ???
*      e_menge  = i_menge.
*      e_meins  = i_meins.
*  ENDCASE.
*
*ENDFUNCTION.
*
************************************************************************
**  Unterprogramm zum Lesen der Hilfsdaten für die Mengenberechnung    *
************************************************************************
*
*FORM collect_f4_data CHANGING g_f4_data STRUCTURE g_f4_data
*                              i_werk i_matnr i_lifnr
*                              i_ekorg i_liwrk i_mesperre
**$@002 Anfang MWE-HW-186918
*                              p_pstyp  LIKE  ekpo-pstyp
**$@002 Ende MWE-HW-186918
*                              .
*
*  DATA: l_rdprf LIKE rdpr-rdprf.
*  DATA: l_ekorg LIKE eine-ekorg.
*  DATA: l_kzinfosatz TYPE c.
*  DATA: l_ul_lief LIKE t001w-lifnr.
**@004 - A
*  DATA: l_subrc LIKE sy-subrc.
**@004 - E
*
** kommt die Position aus einer Bestellung, so darf die Mengeneinheit
** nicht mehr verändert werden
*  g_u01-kz_mesperre = i_mesperre.
*
** Art der Bestellung bestimmen
*  IF NOT i_lifnr IS INITIAL.
*    g_u01-kz_ub = c_nein.
*  ELSEIF NOT i_liwrk IS INITIAL.
*    g_u01-kz_ub = c_ja.
*  ELSEIF i_lifnr IS INITIAL AND i_liwrk IS INITIAL.
*    g_u01-kz_ub = c_nein.
*  ELSE.
*    RAISE wrong_input_combination.
*  ENDIF.
*
** Betriebestamm lesen
*  IF g_u01-kz_ub = c_ja.
*    PERFORM read_t001w USING i_liwrk.
*    IF sy-subrc <> 0.
*      MESSAGE s018 WITH i_liwrk.
*      RAISE error_by_operation.
*    ENDIF.
*    g_f4_data-liwrk = i_liwrk.
*    g_f4_data-nameliwk = t001w-name1.
*    l_ul_lief = t001w-lifnr.
*  ENDIF.
*  PERFORM read_t001w USING i_werk.
*  IF sy-subrc <> 0.
*    MESSAGE s018 WITH i_werk.
*    RAISE wrong_input_combination.
*  ENDIF.
*  g_f4_data-werk = t001w-werks.
*  g_f4_data-namewerk = t001w-name1.
*
** Lieferantenstamm lesen
*  PERFORM read_lfa1 USING i_lifnr.
*  IF sy-subrc <> 0.
*    MESSAGE s019 WITH i_lifnr.
*    RAISE error_by_operation.
*  ENDIF.
*  g_f4_data-lief = lfa1-lifnr.
*  g_f4_data-namelief = lfa1-name1.
*
** Materialstamm lesen
*  PERFORM read_material USING i_matnr i_werk.
*  g_f4_data-matnr = i_matnr.
*  g_f4_data-namemat = makt-maktx.
*
** EkOrg ermitteln, falls nicht angegeben - zum Infosatzlesen und für
** MD_EINZELRUNDUNG
*  IF i_ekorg IS INITIAL.
*    PERFORM read_ekorg USING i_werk g_u01-kz_ub l_ekorg.
*  ELSE.
*    l_ekorg = i_ekorg.
*  ENDIF.
*  g_u01-i_ekorg = l_ekorg.
*
** Infosatz lesen für Rundungsprofil und für MD_EINZELRUNDUNG
*  IF g_u01-kz_ub = c_nein.
*    g_u01-lifnr = i_lifnr.
*  ELSE.
*    g_u01-lifnr = l_ul_lief.
*  ENDIF.
*  PERFORM read_inforecord USING space l_ekorg
**$@002 Anfang MWE-HW-186918
*                                p_pstyp
**$@002 Ende MWE-HW-186918
*                                g_u01-lifnr i_matnr i_werk
*                                mara-satnr mara-attyp.
*  IF sy-subrc = 0.
*    l_kzinfosatz = c_ja.
*  ELSE.
*    l_kzinfosatz = c_nein.
*  ENDIF.
** Rundungsprofil bestimmen: EINE vor MARC
** ??? hier muß wohl noch die neue Logik rein: is EINE-RDPRF leer,
**     dann wird MARC-RDPRF genommen !
*  IF l_kzinfosatz = c_ja.
*    l_rdprf = eine-rdprf.
*  ELSE.
*    l_rdprf = marc-rdprf.
*  ENDIF.
*
** Rundungsprofiltext lesen
**@004 - A
** PERFORM READ_RDTX USING I_WERK L_RDPRF.
** IF SY-SUBRC <> 0.
*  PERFORM read_rdtx USING i_werk l_rdprf l_subrc.
*  IF l_subrc <> 0.
**@004 - E
*    MESSAGE s020 WITH l_rdprf.
*    RAISE error_by_operation.
*  ENDIF.
*  g_f4_data-rdprf = l_rdprf.
*  g_f4_data-namerd = rdtx-text40.
*
** Bestellmenge und Kennzeichen 'Variable BestME erlaubt?' lesen
*  IF g_u01-kz_ub = c_nein.             "kein Lieferwerk
*    IF l_kzinfosatz = c_ja.
*      g_f4_data-bstme = eina-meins.
*      g_f4_data-vabme = eina-vabme.
*    ELSE.
*      g_f4_data-bstme = mara-bstme.
*      g_f4_data-vabme = mara-vabme.
*    ENDIF.
*  ELSE.                                "Lieferwerk
*    IF l_kzinfosatz = c_ja.
*      g_f4_data-bstme = eina-meins.
*      g_f4_data-vabme = eina-vabme.
*    ELSE.
** aber die doch aus der MARC fürs VZ, oder ??
**$@003 Anfang MWE-HW-204696
**$      PERFORM read_marc USING i_matnr i_liwrk.
*      PERFORM read_marc_single  USING    i_matnr
*                                         i_liwrk
*                                CHANGING marc.
**$@003 Ende MWE-HW-204696
*      g_f4_data-bstme = marc-ausme.
*      g_f4_data-vabme = mara-vabme.
*    ENDIF.
*  ENDIF.
** note 216365 - B
*  IF g_f4_data-bstme IS INITIAL.
**   falls keine BSTME ermittelt werden konnte, BasisME nehmen
*    g_f4_data-bstme = mara-meins.
*  ENDIF.
** note 216365 - E
*
*ENDFORM.                    "collect_f4_data
*
*
*
************************************************************************
*
**  Unterprogramm zur Berechnung der versch. Mengen und ME's
*
************************************************************************
*
*
*FORM calculate_f4_amounts CHANGING g_f4_amounts STRUCTURE g_f4_amounts.
** ausgehend von der Wunschmenge in g_f4_amounts-menge und -meins
** werden nun die entspr. Mengen in BestellME bzw. nach Anwendung des
** Rundungsprofils berechnet, samt Restmengen in BasisME.
*
*  DATA: l_opcode LIKE sy-input.
*  DATA: l_elmenge TYPE mdr1p_p_16_dec_14.
*  DATA: l_hmenge TYPE mdr1p_p_16_dec_14.
*  DATA: l_elogme LIKE mara-meins.
**$@001 Anfang MWE-HW-185005
*  DATA: l_f_elmenge TYPE f,
*        l_f_hmenge  TYPE f.
**$@001 Ende MWE-HW-185005
*  CHECK g_f4_amounts-meins <> space.
*
**** Menge in BestellME
*  l_hmenge = g_f4_amounts-menge.
*  PERFORM conv2unit USING l_hmenge
*                          g_f4_amounts-meins g_f4_amounts-bstme.
*  PERFORM use_decan USING l_hmenge g_f4_amounts-bstme.
*  g_f4_amounts-bmenge = l_hmenge.
*
**** Rest dazu (incl. Vorzeichen)
*  PERFORM calculate_remainder CHANGING g_f4_amounts-bmenge
*                                       g_f4_amounts-bstme
*                                       g_f4_amounts-restb
*                                       g_f4_amounts-vorzb.
*
**** Menge in 'log. ME' nach Rundung
*  IF g_u01-kz_ub = c_nein.
*    l_opcode = mdr1p_c_op_mm_normal.
*  ELSE.
*    l_opcode = mdr1p_c_op_mm_ub.
*  ENDIF.
*
** Rundungsbaustein wird immer aufgerufen, wg. Rundungswert, MinMaxMenge
*  l_hmenge = g_f4_amounts-menge.
*
**$@001 Anfang MWE-HW-185005
*  l_f_hmenge  =  l_hmenge.
**$@001 Ende MWE-HW-185005
*
*  CALL FUNCTION 'MD_EINZELRUNDUNG'
*       EXPORTING
*            i_opcode           = l_opcode
*            i_matnr            = g_f4_data-matnr
**$@001 Anfang MWE-HW-185005
**$            i_menge            = l_hmenge
*            i_menge            = l_f_hmenge
**$@001 Ende MWE-HW-185005
*            i_meins            = g_f4_amounts-meins
*            i_werk             = g_f4_data-werk
*            i_lifnr            = g_u01-lifnr
*            i_ekorg            = g_u01-i_ekorg
*            i_infnr            = eina-infnr
**           i_rdprf            = g_f4_data-rdprf
*       IMPORTING
**$@001 Anfang MWE-HW-185005
**$            e_lmenge           = l_elmenge
*            e_lmenge           = l_f_elmenge
**$@001 Ende MWE-HW-185005
*            e_logme            = l_elogme
*       EXCEPTIONS
*            invalid_opcode     = 1
*            no_purchase_org    = 2
*            rdpr_not_found     = 3
*            material_not_found = 4
*            meinh_not_found    = 5
*            bad_params         = 6
*            OTHERS             = 7.
*
**$@001 Anfang MWE-HW-185005
*  l_elmenge  =  l_f_elmenge.
**$@001 Ende MWE-HW-185005
*
** Übernahme der gerundeten Menge in einer ME gemäß Kennzeichen 'VarME'
*  IF sy-subrc = 0.
*    IF g_f4_data-vabme IS INITIAL.
**      keine variable BestME erlaubt, also 'gerundete' Menge in
**      g_f4_amounts-bstme umrechnen ...
*      PERFORM conv2unit USING l_elmenge l_elogme g_f4_amounts-bstme.
*      PERFORM use_decan USING l_elmenge g_f4_amounts-bstme.
*      g_f4_amounts-lmenge = l_elmenge.
*      g_f4_amounts-logme = g_f4_amounts-bstme.
*    ELSE.
*      g_f4_amounts-lmenge = l_elmenge.
*      g_f4_amounts-logme = l_elogme.
*    ENDIF.
*  ELSE.
*    g_f4_amounts-lmenge = 0.
*    g_retcode = 1.
*  ENDIF.
*
**** Rest dazu
*  PERFORM calculate_remainder CHANGING g_f4_amounts-lmenge
*                                       g_f4_amounts-logme
*                                       g_f4_amounts-restl
*                                       g_f4_amounts-vorzl.
*
*ENDFORM.                    "calculate_f4_amounts
*
*
*
************************************************************************
*
** Unterprogramm zur Bestimmung der Differenz in BasisME zwischen der
*
** übergebenen Menge   AMOUNT   in der Mengeneinheit  UNIT, und der
*
** Wunschmenge  G_F4_AMOUNTS-MENGE   in der ME   G_F4_AMOUNTS-MEINS.
*
************************************************************************
*
*FORM calculate_remainder CHANGING amount      LIKE eban-menge
*                                  unit        LIKE mara-meins
*                                  remainder   LIKE eban-menge
*                                  sign        TYPE c.
*
** die in 'remainder' zurückgelieferte Menge ist immer positiv !
** das Vorzeichen ist gesondert in 'sign' abgelegt.
*
*  DATA: l_hamount1 TYPE mdr1p_p_16_dec_14.
*  DATA: l_hamount2 TYPE mdr1p_p_16_dec_14.
*
** Rechne Wunschmenge in BasisME um
*  l_hamount1 = g_f4_amounts-menge.
*  PERFORM conv2unit USING l_hamount1
*                          g_f4_amounts-meins g_f4_amounts-basisme.
*  PERFORM use_decan USING l_hamount1 g_f4_amounts-basisme.
*
** Rechne 'amount' von 'unit' in BasisME
*  l_hamount2 = amount.
*  PERFORM conv2unit USING l_hamount2
*                          unit g_f4_amounts-basisme.
*  PERFORM use_decan USING l_hamount2 g_f4_amounts-basisme.
*
** Berechne Differenz der Mengen (= 'remainder')
*  remainder = l_hamount1 - l_hamount2.
*  IF remainder < 0.
*    sign = c_negativ.
*  ELSE.
*    sign = c_positiv.
*  ENDIF.
*  remainder = abs( remainder ).
*
*ENDFORM.                    "calculate_remainder
*
*
*
************************************************************************
*
**  Unterprogramme zum Dynpro-Processing
*
************************************************************************
*
*FORM set_status_0111 USING rt_extab TYPE slis_t_extab.
*
*  DATA : l_fcode LIKE rsmpe-func.
*
*  IF g_u01-kz_mesperre = c_ja.         "Pos. aus Bestellung
** Wurde die Position aus einer Bestellung übernommen, darf die Mengen-
** einheit nicht mehr geändert werden => nur Button 'Wunschmenge' aktiv
*    DELETE rt_extab WHERE fcode = 'REFD'.
*    l_fcode = 'BEST'.
*    APPEND l_fcode TO rt_extab.
*    l_fcode = 'RUND'.
*    APPEND l_fcode TO rt_extab.
*  ELSE.                                "keine Bestellpos.
** ist variable BestellME nicht erlaubt, darf nur der Button zur Über-
** nahme der Menge in BestellME aktiv sein, bzw. der Button zu Über-
** nahme der gerundeten Menge, da bei Rundung auch VabMe berücks.
*    IF g_f4_data-vabme IS INITIAL.
*      DELETE rt_extab WHERE fcode = 'BEST'.
*      DELETE rt_extab WHERE fcode = 'RUND'.
*      l_fcode = 'REFD'.
*      APPEND l_fcode TO rt_extab.
*    ENDIF.
** ist variable BestellME erlaubt, sind alle Buttons aktiv ...
*    IF NOT ( g_f4_data-vabme IS INITIAL ).
*      DELETE rt_extab WHERE fcode = 'BEST'.
*      DELETE rt_extab WHERE fcode = 'REFD'.
*      DELETE rt_extab WHERE fcode = 'RUND'.
*    ENDIF.
*  ENDIF.
*
** solange keine Wunsch-ME spezifiziert ist, kann auch die Wunschmenge
** nicht übernommen werden ...
*  IF g_f4_amounts-meins IS INITIAL.
*    l_fcode = 'REFD'.
*    APPEND l_fcode TO rt_extab.
*  ENDIF.
*
*  SET PF-STATUS c_status_f4_amounts EXCLUDING rt_extab.
*
*ENDFORM.                               " SET_STATUS_0111
*
*
**---------------------------------------------------------------------*
**       FORM FCODE_F4_AMOUNTS                                         *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
*FORM fcode_f4_amounts.
*  CASE g_fcode.
*    WHEN c_fc_refd.
*      SET SCREEN 0.
*      LEAVE SCREEN.
*    WHEN c_fc_rund.
*      SET SCREEN 0.
*      LEAVE SCREEN.
*    WHEN c_fc_best.
*      SET SCREEN 0.
*      LEAVE SCREEN.
*    WHEN c_fc_info.
*      PERFORM display_info.
*  ENDCASE.
*ENDFORM.                               " FCODE_F4_AMOUNTS
*
*
************************************************************************
*
** Test zur Ausgabe eines Info-Popups zur F4-Hilfe von Dynpro 01111
*
************************************************************************
*
*FORM display_info.
*
*
*  CALL FUNCTION 'POPUP_DISPLAY_TEXT'
*       EXPORTING
*           language       = sy-langu
*            popup_title    = ' '
*           start_column   = 10
*           start_row      = 3
*            text_object    = 'F4_ORDER_QUANTITY_INFO'
*           help_modal     = 'X'
**    IMPORTING
**         CANCELLED      =
**    EXCEPTIONS
**         TEXT_NOT_FOUND = 1
**         OTHERS         = 2
*            .
*  IF sy-subrc <> 0.
** MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.
*
*
*ENDFORM.                    "display_info
*
************************************************************************
*
** F4-Hilfe auf Wunsch-ME (g_f4_amounts-meins) in Dynpro 0111
*
************************************************************************
*
** das geht auch noch schöner mit FuBauSt SMEINH_MEINH_HELP
** z.B. in  display_units (SAPMM06E)
*FORM f4_meins.
*  DATA: l_numlines  LIKE sy-tabix.
*  DATA: l_meins     LIKE mara-meins.
*  DATA: l_menge TYPE mdr1p_p_16_dec_14.
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
** DATA: BEGIN OF l_t_metab OCCURS 0,
**         meinh  LIKE marm-meinh,
**         msehl  LIKE t006a-msehl,
**         umrez  LIKE marm-umrez,
**         umren  LIKE marm-umren,
**         inhalt LIKE marm-umrez,
**        END OF l_t_metab.
*
** DATA: BEGIN OF l_t_rmmme OCCURS 0.
**         INCLUDE STRUCTURE rmmme.
** DATA: END OF l_t_rmmme.
*
** Parameter für Baustein F4_ALLOWED_QUANTITY_UNIT
*  DATA: l_allowed_unit_parameters TYPE mdr1p_s_in_allowed_qt_unit,
*        lt_allowed_units          TYPE mdr1p_t_out_allowed_qt_unit
*                                  WITH HEADER LINE.
*
** --------------------------------------------------------------------
*
** 'alte' Mengeneinheit vom Dynpro 'retten' ...
** zusätzlich 'alte' Menge 'retten' - dmarx 17/05/99
*  DATA: BEGIN OF l_dynpfields OCCURS 3.
*          INCLUDE STRUCTURE dynpread.
*  DATA: END OF l_dynpfields.
*  DATA: l_dynnr      LIKE sy-dynnr.
*  l_dynnr = sy-dynnr.
*
*  l_dynpfields-fieldname  = 'G_F4_AMOUNTS-MEINS'.
*  APPEND l_dynpfields.
*  CALL FUNCTION 'DYNP_VALUES_READ'
*    EXPORTING
*      dyname     = 'SAPLMDR1'
*      dynumb     = l_dynnr
*    TABLES
*      dynpfields = l_dynpfields
*    EXCEPTIONS
*      OTHERS     = 04.
*  g_f4_amounts-meins = l_dynpfields-fieldvalue.
*
*  CLEAR l_dynpfields[].
*
*  l_dynpfields-fieldname  = 'G_F4_AMOUNTS-MENGE'.
*  APPEND l_dynpfields.
*  CALL FUNCTION 'DYNP_VALUES_READ'
*    EXPORTING
*      dyname     = 'SAPLMDR1'
*      dynumb     = l_dynnr
*    TABLES
*      dynpfields = l_dynpfields
*    EXCEPTIONS
*      OTHERS     = 04.
*  g_f4_amounts-menge = l_dynpfields-fieldvalue.
*
** --------------------------------------------------------------------
*
** anzuzeigende Felder bekanntgeben, Schlüsselfelder definieren
*  l_t_fieldtab-tabname = 'MARM'.
*  l_t_fieldtab-fieldname = 'MEINH'.
*  l_t_fieldtab-selectflag = c_ja.
*  APPEND l_t_fieldtab.
** l_t_fieldtab-tabname = 'MARM'.
** l_t_fieldtab-fieldname = 'UMREZ'.
** l_t_fieldtab-selectflag = c_nein.
** APPEND l_t_fieldtab.
*  l_t_fieldtab-tabname = 'T006A'.
*  l_t_fieldtab-fieldname = 'MSEHL'.
*  l_t_fieldtab-selectflag = c_nein.
*  APPEND l_t_fieldtab.
*
** dmarx 29/11/99  kann alles raus wg. Umbau auf Baustein
**  F4_ALLOWED_QUANTITY_UNIT
** --------------------------------------------------------------------
*
** ME's zum Artikel sammeln. Dazu wird jedes anzuzeigende Feld
** in eine Zeile von l_t_valuetab geschrieben
** alternative Mengeneinheiten lesen
** CALL FUNCTION 'MATERIAL_UNIT_FIND'
**      EXPORTING
**           kzall      = c_nein        "nur die zum Artikel
**           matnr      = g_f4_data-matnr
**      TABLES
**           rmmme_itab = l_t_rmmme.    "mögliche Mengeneinheiten
*
** dazu die Texte aus T006A lesen
** LOOP AT l_t_rmmme.
**   l_t_metab-meinh = l_t_rmmme-meinh.
**   l_t_metab-umrez = l_t_rmmme-umrez.
**   l_t_metab-umren = l_t_rmmme-umren.
**   CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
**        EXPORTING
**             language       = sy-langu
**              input          = l_t_rmmme-meinh
**         IMPORTING
**              output         = l_t_metab-meinh
**              long_text      = l_t_metab-msehl
**         EXCEPTIONS
**              unit_not_found = 01.
**   IF sy-subrc > 0.
**     l_t_metab-meinh = l_t_rmmme-meinh.
**     l_t_metab-msehl = l_t_rmmme-meinh.
**   ENDIF.
**   APPEND l_t_metab.
** ENDLOOP.
*
** ME's nach Größe sortieren
** LOOP AT l_t_metab.
**   CLEAR l_t_metab-inhalt.
**   IF l_t_metab-umren <> 0.
**     l_t_metab-inhalt = l_t_metab-umrez / l_t_metab-umren.
**   ENDIF.
**   MODIFY l_t_metab.
** ENDLOOP.
** SORT l_t_metab BY inhalt.
*
** l_t_valuetab aufbauen
** LOOP AT l_t_metab.
**   1. Mengeneinheit
**   l_t_valuetab-text = l_t_metab-meinh.
**   APPEND l_t_valuetab.
**   2. Inhalt
**   CLEAR l_t_valuetab-text.
**   WRITE l_t_metab-inhalt TO l_t_valuetab-text
**         USING EDIT MASK '_____'.
**   APPEND l_t_valuetab.
**   3. Bezeichnung
**   l_t_valuetab-text = l_t_metab-msehl.
**   APPEND l_t_valuetab.
** ENDLOOP.
*
** neue Bestimmung der erlaubten ME's  dmarx 29/11/99
*  l_allowed_unit_parameters-appview       = mdr1p_c_appview_purchase.
*  l_allowed_unit_parameters-flagallqtunit = 'X'.
*  l_allowed_unit_parameters-lifnr         = g_f4_data-lief.
*  l_allowed_unit_parameters-ekorg         = g_u01-i_ekorg.
*  l_allowed_unit_parameters-werks         = g_f4_data-werk.
*  l_allowed_unit_parameters-matnr         = g_f4_data-matnr.
*
*  CALL FUNCTION 'F4_ALLOWED_QUANTITY_UNIT'
*    EXPORTING
*      i_s_general  = l_allowed_unit_parameters
*      i_dialog     = ' '
*    TABLES
*      o_t_qt_units = lt_allowed_units
*    EXCEPTIONS
*      bad_params   = 1
*      error        = 2
*      OTHERS       = 99.
*
*  IF sy-subrc <> 0.
*    MESSAGE s017.
*    EXIT.
*  ENDIF.
*
*  LOOP AT lt_allowed_units.
**   1. Mengeneinheit
*    l_t_valuetab-text = lt_allowed_units-meinh.
*    APPEND l_t_valuetab.
**   2. Bezeichnung
*    l_t_valuetab-text = lt_allowed_units-msehl.
*    APPEND l_t_valuetab.
*  ENDLOOP.
*
*
** überhaupt was gefunden?
*  DESCRIBE TABLE l_t_valuetab LINES l_numlines.
*  IF l_numlines <= 0.
*    MESSAGE s017.
*    EXIT.
*  ENDIF.
*
** --------------------------------------------------------------------
*
** Popup ausgeben
*  l_display = c_nein.
*  IF g_u01-kz_mesperre = c_ja.
** Pos. aus Best., keine andere ME erlaubt => F4 nur mit Anzeige
*    l_display = c_ja.
*  ELSE.
** andere ME erlaubt => F4 mit Auswahlmöglichkeit
*    l_display = c_nein.
*  ENDIF.
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
** Auswahl einer ME nur möglich, wenn Pos. nicht aus Bestellung ...
*  CHECK NOT g_u01-kz_mesperre = c_ja.
*
** --------------------------------------------------------------------
*
** Mengenfelder an neue ME anpassen
*  l_menge = g_f4_amounts-menge.
*  PERFORM conv2unit USING l_menge
*                          g_f4_amounts-meins l_meins.
*  PERFORM use_decan USING l_menge l_meins.
*
*  g_f4_amounts-menge = l_menge.
*  g_f4_amounts-meins = l_meins.
*
** --------------------------------------------------------------------
*
** geänderte Felder am Screen neu ausgeben
** perform screen_anpassen.
*  l_dynpfields-stepl = 1.
*
*  l_dynpfields-fieldname  = 'G_F4_AMOUNTS-MENGE'.
*  WRITE g_f4_amounts-menge TO l_dynpfields-fieldvalue LEFT-JUSTIFIED
*        UNIT g_f4_amounts-meins.
*  APPEND l_dynpfields.
*
*  l_dynpfields-fieldname  = 'G_F4_AMOUNTS-MEINS'.
*  l_dynpfields-fieldvalue = g_f4_amounts-meins.
*  APPEND l_dynpfields.
*
*  PERFORM set_value_on_screen TABLES l_dynpfields.
*
*ENDFORM.                                                    " F4_MEINS
*
************************************************************************
*
** Überprüfung, ob eingegebene Wunsch-ME (g_f4_amounts-meins) erlaubt ?
*
************************************************************************
*
*FORM plausi_meins.
*  DATA: l_meins(3) TYPE c.
*
** MARM nur lesen, wenn nicht Bestell-ME oder Basis-ME eingegeben
*  IF g_f4_amounts-meins = g_f4_amounts-bstme OR
*     g_f4_amounts-meins = g_f4_amounts-basisme.
*    sy-subrc = 0.
*  ELSE.
*    SELECT SINGLE * FROM marm
*    WHERE matnr = g_f4_data-matnr
*    AND   meinh = g_f4_amounts-meins.
*  ENDIF.
*
*  IF sy-subrc <> 0.
*    l_meins = g_f4_amounts-meins.
*    CLEAR g_f4_amounts-meins.
*    MESSAGE i007 WITH g_f4_data-matnr l_meins.
*  ENDIF.
*
*ENDFORM.                    "plausi_meins
*$@005 Ende MWE-ENTW-470-UNICODE

*
* 
