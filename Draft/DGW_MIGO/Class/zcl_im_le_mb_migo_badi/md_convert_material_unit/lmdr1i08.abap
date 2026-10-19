*----------------------------------------------------------------------*
***INCLUDE LMDR1I08 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       01.10.01  4.70 mbi         Grundversion
*-----------------------------------------------------------------------
***********************************************************************
*                       Dynpro 800
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  exit_0800  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0800 INPUT.

  LEAVE TO SCREEN 0.

ENDMODULE.                 " exit_0800  INPUT


*&---------------------------------------------------------------------*
*&      Module  check_input_rdprf_0800  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_rdprf_0800 INPUT.

  IF g_0800_no_appl  =  c_yes.
*                *** anwendungsunabhängiger Fall
    IF g_0800_rdprf  IS  INITIAL.
*                *** Rundungsprofil muss eingegeben sein!
      MESSAGE e000(lumer).

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_input_rdprf_0800  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_rappl_0800  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_rappl_0800 INPUT.

  IF g_0800_with_appl  =  c_yes.
*                *** anwendungsabhängiger Fall
    IF g_0800_appl  IS  INITIAL.
*                *** Rundungsprofil muss eingegeben sein!
      MESSAGE e001(lumer).

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_input_rappl_0800  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_werks_0800  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_werks_0800 INPUT.

*                *** Eingabeprüfung nur bei entsprechend
*                *** unternehmensunabhängigen Auswahl und Werks belegt
  IF        g_0800_no_appl  =  c_yes.

    IF NOT ( g_0800_werks  IS INITIAL ).

      SELECT SINGLE  *
               FROM  t001w
              WHERE  werks = g_0800_werks.

      IF sy-subrc <> 0.

        MESSAGE e000(6r) WITH g_0800_werks .

      ELSE.

*                *** Namen übernehmen
        g_0401_rdpr_werks_name = t001w-name1.

      ENDIF.

    ELSE.

*                *** Namen des Werks löschen
      CLEAR g_0401_rdpr_werks_name.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_input_werks_0800  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_all_input_0800  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_all_input_0800 INPUT.

*                *** Eingabeprüfung nur bei entsprechend
*                *** unternehmensunabhängigen Auswahl
  IF g_0800_no_appl  =  c_yes.

    IF g_0800_rdprf  IS  INITIAL.
*                *** Rundungsprofil muss eingegeben sein!
      MESSAGE e000(lumer).

    ELSE.
*                *** Definition des Rundungsprofils muss existieren!
      SELECT  *
        FROM  rdpr
       WHERE  rdprf = g_0800_rdprf
         AND  werks = g_0800_werks.
      ENDSELECT.

      IF sy-subrc <> 0.
        MESSAGE e079(6r).
      ENDIF.

      SELECT  *
        FROM  rdtx
       WHERE  werks = g_0800_werks
         AND  rdprf = g_0800_rdprf
         AND  spras = sy-langu.
      ENDSELECT.

      IF sy-subrc <> 0.
        rdtx-spras = sy-langu.
        rdtx-werks = g_0800_werks.
        rdtx-rdprf = g_0800_rdprf.
        CLEAR rdtx-text40.
      ENDIF.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_all_input_0800  INPUT

*&---------------------------------------------------------------------*
*&      Module  evaluate_save_ok_code_0800  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE evaluate_save_ok_code_0800 INPUT.

*                *** ok_code sichern.
  save_ok_code = ok_code.
  CLEAR ok_code.

  CASE save_ok_code.

    WHEN c_fc_cont.

      PERFORM evaluate_checkboxes_0800.

  ENDCASE.

ENDMODULE.                 " evaluate_save_ok_code_0800  INPUT

*&---------------------------------------------------------------------*
*&      Module  F4_HEPL_RDPRF_0800  INPUT
*&---------------------------------------------------------------------*
*       Dieses Modul realisiert eine Eingabehilfe fuer die             *
*       Felder RDPR-RDPRF und RDPR-WERKS                               *
*----------------------------------------------------------------------*
MODULE f4_hepl_rdprf_0800 INPUT.

  g_dynpprog = sy-repid.
  g_dynpnr = sy-dynnr.

  PERFORM f4help_rdpr_rdprf
    USING
      g_dynpprog
      g_dynpnr
      'G_0800_RDPRF'
      'G_0800_WERKS'
      c_yes
      c_yes.

ENDMODULE.                             " F4_HEPL_RDPRF_0800  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_werks_0800  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_werks_0800 INPUT.

  g_dynpprog = sy-repid.
  g_dynpnr = sy-dynnr.

  PERFORM f4help_rdpr_werks
    USING
      g_dynpprog
      g_dynpnr.

ENDMODULE.                 " f4_help_werks_0800  INPUT

***********************************************************************
*                       Dynpro 820
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  exit_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0820 INPUT.

  CLEAR ok_code.

  IF g_0820_no_0800_call  IS INITIAL.
*                *** Bei Aufruf aus Dynpro 0800
    LEAVE TO SCREEN 0800.
  ELSE.
*                *** Sonst
    LEAVE TO SCREEN 0.
  ENDIF.

ENDMODULE.                 " exit_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  evaluate_save_ok_code_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE evaluate_save_ok_code_0820 INPUT.

*                *** Zunächst ok_code sichern
  save_ok_code = ok_code.
  CLEAR ok_code.

*                *** Restliche  Daten aus der
*                *** Eingabe in  g_s_0820_general
*                *** eintragen

  CASE save_ok_code.

    WHEN c_fc_exec_value.
*                *** Rundungssimulationdurchführen

*                *** Eingabe-Wert für die Menge noch übernehmen
      g_s_0820_general-menge  =  g_0820_single_value.
      g_s_0820_general_init-menge = g_0820_single_value.

      IF g_s_0820_general-defqtunit  IS  INITIAL.
*                *** Rundungsparameter bestimmen und in g_s_0820_general
*                *** und g_s_0820_results eintragen, wenn sie noch nicht
*                *** bestimmt wurden
        PERFORM simu_rounding_params TABLES   g_t_0820_qt_units
                                     CHANGING g_s_0820_general
                                              g_s_0820_results.

        g_s_0820_general_init = g_s_0820_general.

      ENDIF.

*                *** Eingabewert runden
      PERFORM simu_rounding_appl  TABLES   g_t_0820_round_reasons
                                  CHANGING g_s_0820_general
                                           g_s_0820_results.

*                *** Ergebnis der Rundung in die Dynprofelder
*                *** übernehmen.
      g_0820_rounded_value  =  g_s_0820_results-lmenge.
      g_0820_value_umrech   =  g_s_0820_results-menge.
      g_0820_meinh_umrech   =  g_s_0820_general-meinh.

*                *** Setze die Exception auf Farbe grün.
      g_0820_light = c_green.

    WHEN c_0820_rparam.
*                *** Simulation der Parameterbestimmung

*                *** Eingabe-Wert für die Menge noch übernehmen
      g_s_0820_general-menge  =  g_0820_single_value.
      g_s_0820_general_init-menge = g_0820_single_value.

      IF g_s_0820_general-defqtunit  IS  INITIAL.
*                *** Rundungsparameter bestimmen und in g_s_0820_general
*                *** und g_s_0820_results eintragen, wenn sie noch nicht
*                *** bestimmt wurden
        PERFORM simu_rounding_params TABLES   g_t_0820_qt_units
                                     CHANGING g_s_0820_general
                                              g_s_0820_results.

        g_s_0820_general_init = g_s_0820_general.

      ENDIF.

*                *** Übernahme der erlaubten logistischen
*                *** Mengeneinheiten
      g_t_0830_qt_units = g_t_0820_qt_units.

*                *** Das Rundungscustomizing und die bestimmte
*                *** Rundungsparameter in die globalen Struktur
*                *** g_s_0830_general des Dynpros 0830 übernehmen:
*                *** (Dabei werden auch die restlichen Eingabeparameter
*                ***  aus Dynpro 0820 übergeben, diese können jedoch
*                ***  nicht in Dynpro 0830 geändert werden!!!)
      g_s_0830_general  =  g_s_0820_general.

      g_0830_maxqt      =  g_s_0830_general-maxqt.
      g_0830_minqt      =  g_s_0830_general-minqt.

*                *** Die Mengeneinheit für den Rundungswert
*                *** (beachte: beim Einkauf immer Basismengeneinheit)
      g_0830_bstrfqtunit = g_s_0820_results-meins.
*                *** Default-Modus: Anzeige-Modus
      g_0830_mode_dynpro = c_0830_show_mode.
*                *** Bestimme das Werk zum Rundungsprofil
      g_0830_rdprf_werks = g_s_0830_general-werks.

      PERFORM get_rdprf_werks
        USING
          g_s_0830_general-rdprf
        CHANGING
          g_0830_rdprf_werks.   " Werk zum Rundungsprofil

      CALL SCREEN 0830
      STARTING AT 40 01.

      IF  g_s_0820_general <> g_s_0830_general.

*                *** Die geänderte Rundungsparametern aus Dynpro 0830
*                *** übernehmen
        g_s_0820_general  =  g_s_0830_general.
        g_t_0820_qt_units = g_t_0830_qt_units.

*                *** Setze die Exception auf Farbe rot,
*                *** wenn sich was an den Parametern geändert hat!
        g_0820_light = c_red.

        IF g_s_0820_general_init <> g_s_0820_general.

*                *** die Rundungsparameter wurden verändert
          g_0820_rounding_initial = c_no.

        ELSE.

          g_0820_rounding_initial = c_yes.

        ENDIF.

      ENDIF.

    WHEN c_0820_rcont.
*                *** Simulation der Steuerungsparameter
      g_s_0840_general  =  g_s_0820_general.
*                *** Default-Modus: Anzeige-Modus
      g_0840_mode_dynpro = c_0840_show_mode.

      CALL SCREEN 0840
      STARTING AT 40 01.

      IF  g_s_0820_general  <>  g_s_0840_general.
*                *** Die geänderte Steuerungsparametern aus Dynpro 0840
*                *** übernehmen
        g_s_0820_general  =  g_s_0840_general.
*                *** Die bereits bestimmten Rundungsparameter
*                *** initialisieren
        CLEAR: g_t_0820_qt_units,
               g_t_0820_qt_units[],
               g_s_0820_results.
*                *** Initialisieren der Rundungsparameter:
        PERFORM init_general_params
                    CHANGING
                       g_s_0820_general.
*                *** Setze die Exception auf Farbe rot,
*                *** wenn sich was an den Parametern geändert hat!
        g_0820_light = c_red.

*                *** Überprüfe, ob das geänderte Customizing dem
*                *** initialen Customizing entspricht
        MOVE-CORRESPONDING g_s_0820_general TO g_s_0820_rcpr_tmp.

        IF g_s_0820_rcpr_init <> g_s_0820_rcpr_tmp.

*                *** Customizing wurde geändert
          g_0820_control_initial = c_no.

        ELSE.

*                *** Customizing wurde "refresht"
          g_0820_control_initial = c_yes.

        ENDIF.

*                *** Da sich das Customizing verändert hat werden die
*                *** Rundungsparameter neub bestimmt
        g_0820_rounding_initial = c_yes.

      ENDIF.


  ENDCASE.

ENDMODULE.                 " evaluate_save_ok_code_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_matnr_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_matnr_0820 INPUT.

*                *** Bei neuer Eingabe immer wieder
*                *** alle abhängigen Daten initialisieren
  CLEAR: g_0820_matnr_name,
         g_0820_meinh_umrech,
         mara,
         makt.
*                *** Bereits bestimmte Rundungsparamter in der Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.

*                *** Überprüfe, ob Artikel überhaupt existiert
  PERFORM read_mara_single_online
    USING
      g_s_0820_general-matnr
    CHANGING
      mara.

  IF  NOT ( mara                    IS  INITIAL )
  AND       g_s_0820_general-meinh  IS  INITIAL.
*                *** Wenn das Material in MARA existiert und die
*                *** Eingabe-Mengeneinheit nicht belegt, ist marm-meinh
*                *** = LEER => Default-Belegung der Eingabemengeneinheit
*                *** mit der Basismengeneinheit.
    g_s_0820_general-meinh = mara-meins.
  ENDIF.

*                *** Lese den Namen des Artikels aus der MAKT
  PERFORM read_makt
              USING
                 g_s_0820_general-matnr
                 rdpr-werks
              CHANGING
                 makt.

  IF NOT ( makt IS INITIAL ).
*                *** Namen auf das Dynpro übernehmen
    g_0820_matnr_name = makt-maktx.

  ENDIF.

*                *** Untersuche ob die eingegebe Mengeneinheit
*                *** eine gültige zu dem Material ist, falls die
*                *** Eingabe-Mengeneinheit nicht mit der Basismengen-
*                *** einheit defaultmaessig belegt ist.
  IF g_s_0820_general-meinh <> mara-meins.

*                *** Bemerkung: Falls ME ungültig ist, Fehlerausgabe in
*                *** Unterprogramm.
    PERFORM check_material_unit
                USING
                   g_s_0820_general-matnr
                   mara-meins
                   g_s_0820_general-meinh.

  ENDIF.

*                *** Belege die Mengenfelder des Dynpros mit der Alt.-ME
  g_0820_meinh_umrech  =  g_s_0820_general-meinh.

ENDMODULE.                 " check_input_matnr_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_werks_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_werks_0820 INPUT.

*                *** Nur falls Werk Pflicht ist
  IF  NOT ( g_s_0820_general-werks IS INITIAL )
  AND     (   g_s_0820_general-opcode = mdr1p_c_op_mm_normal
           OR g_s_0820_general-opcode = mdr1p_c_op_mm_ub
           OR g_s_0820_general-opcode = mdr1p_c_op_additionals ).

    CLEAR: g_0820_werks_name,
           t001w.
*                *** Setze die Exception auf Farbe rot.
    g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
    PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Überprüfe, ob das Werk überhaupt existiert
    PERFORM read_t001w_new
                USING
                   g_s_0820_general-werks
                CHANGING
                   t001w.

    IF sy-subrc <>  0
    OR t001w    IS  INITIAL.

*                *** Fehlerausgabe: Werk existiert nicht!
      MESSAGE e000 WITH g_s_0820_general-werks.

    ELSE.
*                *** Namen auf das Dynpro übernehmen
      g_0820_werks_name = t001w-name1.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_input_werks_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_vkorg_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_vkorg_0820 INPUT.

  CLEAR: tvkot,
         g_0820_vkorg_name.
*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Überprüfe, ob die Vkorg überhaupt existiert
  PERFORM read_tvko_single
              USING
                 g_s_0820_general-vkorg.

  IF sy-subrc <> 0.
*                *** Fehlerausgabe: Vkorg existiert nicht!

    MESSAGE e118(m3) WITH g_s_0820_general-vkorg.

  ELSE.
*                *** Namen der Vkorg lesen
    PERFORM read_tvkot_single
                USING
                   g_s_0820_general-vkorg
                CHANGING
                   tvkot.

    IF NOT ( tvkot  IS  INITIAL ).
*                *** Namen auf das Dynpro übernehmen
      g_0820_vkorg_name = tvkot-vtext.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_input_vkorg_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_vtweg_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_vtweg_0820 INPUT.

  CLEAR: g_0820_vtweg_name,
         tvtwt.
*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Überprüfe, ob der Vtweg überhaupt existiert
  PERFORM read_tvtw_single
              USING
                 g_s_0820_general-vtweg.

*                *** Alles in Ordnung:

*                *** Lese den Namen des Vtweg (falls vorhanden) und
*                *** übernehme ihn in das Dynpro.
  PERFORM read_tvtwt_single
              USING
                 g_s_0820_general-vtweg
              CHANGING
                 tvtwt.

  IF NOT ( tvtwt IS INITIAL ).
*                *** Name übernehmen
    g_0820_vtweg_name = tvtwt-vtext.

  ENDIF.

ENDMODULE.                 " check_input_vtweg_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  ckeck_input_kunnr_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ckeck_input_kunnr_0820 INPUT.

  CLEAR: g_0820_kunnr_name.
*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Überprüfe, ob Kunde überhaupt existiert
  PERFORM read_kna1_single
              USING
                 g_s_0820_general-kunnr
              CHANGING
                 kna1.

  IF kna1  IS  INITIAL.

*                *** Fehlermeldung: Kunde existiert nicht!
    MESSAGE e240(m3) WITH g_s_0820_general-kunnr.

  ELSE.

*                *** Übernehme Name in das Dynpro
    g_0820_kunnr_name = kna1-name1.

  ENDIF.

ENDMODULE.                 " ckeck_input_kunnr_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_spart_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_spart_0820 INPUT.

  CLEAR: g_0820_spart_name.
*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Nur falls die Sparte eingengeben wurde
  IF NOT ( g_s_0820_general-spart IS INITIAL ).

*                *** Überprüfe, ob Sparte überhaupt existiert
    PERFORM read_tspa_single
                USING
                   g_s_0820_general-spart.

    IF sy-subrc <> 0.

*                *** Fehlermeldung: Sparte nicht vorhanden!
      MESSAGE e098(cz) WITH g_s_0820_general-spart.

    ELSE.
*                *** Namen lesen
      PERFORM read_tspat_single
                  USING
                     g_s_0820_general-spart
                  CHANGING
                     g_0820_spart_name.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_input_spart_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_lifnr_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_lifnr_0820 INPUT.

  CLEAR: g_0820_lifnr_name,
         lfa1.
*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

  IF NOT ( g_s_0820_general-lifnr IS INITIAL ).
*                *** Überprüfe, ob Lieferant überhaupt existiert.
*                *** Falls nicht, wird entsprechende Fehlermeldung
*                *** in dem Unterprogramm ausgegeben.
    PERFORM read_lfa1_single_2
                USING
                    g_s_0820_general-lifnr
                CHANGING
                    lfa1.

*                *** Übernehme den Namen auf das Dynpro
    g_0820_lifnr_name = lfa1-name1.

  ENDIF.

ENDMODULE.                 " check_input_lifnr_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_ekorg_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_ekorg_0820 INPUT.

  CLEAR: g_0820_ekorg_name,
         t024e.
*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Überprüfe, ob die Ekorg überhaupt existiert.
*                *** Falls nicht, wird entsprechende Meldung
*                *** angezeigt.
  PERFORM read_t024e_single
              USING
                 g_s_0820_general-ekorg
              CHANGING
                 t024e.

*                *** Übernehme den Namen in das Dynpro
  g_0820_ekorg_name = t024e-ekotx.

ENDMODULE.                 " check_input_ekorg_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_pstyp_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_pstyp_0820 INPUT.


  CLEAR: g_0820_pstyp_name.
*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Nur, falls pstyp eingegeben wurde
  IF NOT ( g_s_0820_general-pstyp IS INITIAL ).

*                *** Überprüfe, ob psytp überhaupt exisiert
    PERFORM read_t163_single
                USING
                   g_s_0820_general-pstyp.

    IF sy-subrc <> 0.

*                *** Fehlermeldung: Positionstyp existiert nicht!
      MESSAGE e114(mw) WITH g_s_0820_general-pstyp.

    ELSE.

*                *** Namen lesen. Falls kein Name gelesen werden
*                *** kann, bleibt g_0820_pstyp_name leer.
      PERFORM read_t163y_single
                  USING
                     g_s_0820_general-pstyp
                  CHANGING
                     g_0820_pstyp_name.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_input_pstyp_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_input_werks_kred_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_input_werks_kred_0820 INPUT.

  CLEAR: g_0820_werks_kred_name,
         t001w,
         marc.
*                *** Setze die Exception auf Farbe rot.
  g_0820_light         = c_red.
*                *** Bereits bestimmte Rundungsparamter in die Struktur
*                *** g_s_0820_general müssen wieder initialisiert
*                *** werden
  PERFORM  init_general_params  CHANGING g_s_0820_general.

*                *** Nur, falls ein Lieferwerk eingegeben wurde
  IF NOT ( g_s_0820_general-werks_kred IS INITIAL ).

*                *** Überprüfe, ob das Werk überhaupt existiert
    PERFORM read_t001w_new
                USING
                   g_s_0820_general-werks_kred
                CHANGING
                   t001w.

    IF sy-subrc <> 0
    OR t001w    IS INITIAL.

*                *** Fehlerausgabe: Werk existiert nicht!
      MESSAGE e000 WITH g_s_0820_general-werks_kred.

    ELSE.
*                *** Namen auf das Dynpro übernehmen
      g_0820_werks_kred_name = t001w-name1.
*                *** Überprüfen, ob Material zum Lieferwerk gepflegt ist
      PERFORM read_marc_single
                  USING
                      g_s_0820_general-matnr
                      g_s_0820_general-werks_kred
                  CHANGING
                      marc.

*                *** Wenn kein Satz gefunden wurde, ist marc initial
      IF marc IS INITIAL.

*                *** Fehlermeldung: Material in Werk nicht vorhanden!
        MESSAGE e200(m3) WITH g_s_0820_general-matnr
                              g_s_0820_general-werks_kred.

      ENDIF.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_input_werks_kred_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_marc_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_marc_0820 INPUT.

*                *** Nur falls Werk Pflicht ist
  IF  NOT ( g_s_0820_general-werks IS INITIAL )
  AND     (   g_s_0820_general-opcode = mdr1p_c_op_mm_normal
           OR g_s_0820_general-opcode = mdr1p_c_op_mm_ub
           OR g_s_0820_general-opcode = mdr1p_c_op_additionals ).

    CLEAR: marc.

*                *** Werk exisitert, da schon in Modul
*                *** 'check_input_werks_0820' getestet. Der Datensatz
*                *** wurde in die t001w gelesen.

*                *** Überprüfen, ob Material im Werk gepflegt ist
    PERFORM read_marc_single
                USING
                    g_s_0820_general-matnr
                    g_s_0820_general-werks
                CHANGING
                    marc.

*                *** Wenn kein Satz gefunden wurde, ist marc initial
    IF marc IS INITIAL.

*                *** Fehlermeldung: Material in Werk nicht vorhanden!
      MESSAGE e200(m3)
         WITH g_s_0820_general-matnr
              g_s_0820_general-werks.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_marc_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_tvkov_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_tvkov_0820 INPUT.

  DATA: l_success  TYPE c.

  CLEAR: tvkov.

*                *** Überprüfe, ob der Vtweg zur eingegeben Vkorg
*                *** überhaupt existiert. Dabei müßen natürlich
*                *** beide Felder gefüllt sein. Dies ist aber
*                *** gewährleistet, da beides Muß-Felder sind.
*                *** Check, ob beide existieren wurde auch schon
*                *** durchlaufen.
  PERFORM read_tvkov
              USING
                 g_s_0820_general-vkorg
                 g_s_0820_general-vtweg
              CHANGING
                 tvkov
                 l_success.

  IF l_success = c_no.

*                *** Fehlermeldung: Vtweg existiert nicht zur Vkorg!
    MESSAGE e096(cz) WITH g_s_0820_general-vkorg
                          g_s_0820_general-vtweg.

  ENDIF.

ENDMODULE.                 " check_tvkov_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_mvke_0820  INPUT
*&---------------------------------------------------------------------*
*       Test, ob ein MVKE-Satz beim Kundenauftrag existieren muss!
*       Dies ist vom vorgegebenen Customizing abhängig!!!!
*----------------------------------------------------------------------*
MODULE check_mvke_0820 INPUT.

  IF  g_s_0820_general-opcode  =  mdr1p_c_op_sd_auftrag
  AND g_s_0820_general-rleave  =  c_yes.
*                *** MVKE-Existenz-Test für Kundenauftrag nur
*                *** durchführen, wenn dies laut Customizing
*                *** gewünscht
    CLEAR: mvke.
*                *** Vtweg exisiert zur Vkorg. Überprüfe, ob Verkaufs-
*                *** daten zum Material und Vkorg/Vtweg existieren.
    PERFORM read_mvke_single
                USING
                    g_s_0820_general-matnr
                    g_s_0820_general-vkorg
                    g_s_0820_general-vtweg
                CHANGING
                    mvke.

*                *** Falls kein Satz gelesen werden konnte, ist
*                *** mvke initial.
    IF mvke IS INITIAL.

*                *** Fehlermeldung: Zum Material fehlen die Verkaufs-
*                *** daten.
      MESSAGE e738(vo)
         WITH g_s_0820_general-matnr
              g_s_0820_general-vkorg
              g_s_0820_general-vtweg.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_mvke_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_tvkos_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_tvkos_0820 INPUT.

*                *** Nur falls Sparte eingegeben wurde (optional)
  IF NOT ( g_s_0820_general-spart IS INITIAL ).

*                *** Überprüfe, ob Sparte für Vkorg zulässig ist
    PERFORM read_tvkos_single
                USING
                   g_s_0820_general-vkorg
                   g_s_0820_general-spart.

    IF sy-subrc <> 0.
*                *** Fehlermeldung: In Vkorg ist Sparte nicht erlaubt!
      MESSAGE e097(cz) WITH g_s_0820_general-vkorg
                            g_s_0820_general-spart.

    ENDIF.

  ENDIF.

ENDMODULE.                 " check_tvkos_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  input_check_single_value_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE input_check_single_value_0820 INPUT.

*                *** Eingabe wurde (falls nicht der gleiche Wert
*                *** wieder eingegeben wurde) verändert. Setze
*                *** Exception auf Farbe rot.
  g_0820_light = c_red.

*                *** Einzelwert <= 0 => Default-Wert 1
  IF g_0820_single_value <= 0.

    g_0820_single_value  = c_default_single_value.

  ENDIF.

ENDMODULE.                 " input_check_single_value_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_general_meinh_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_general_meinh_0820 INPUT.

  IF        g_s_0820_general-defqtunit  IS  INITIAL
  AND NOT ( g_s_0820_general-matnr      IS  INITIAL ).
*                *** Rundungsparameter bestimmen und in g_s_0820_general
*                *** und g_s_0820_results eintragen, wenn sie noch nicht
*                *** bestimmt wurden
    PERFORM simu_rounding_params TABLES   g_t_0820_qt_units
                                 CHANGING g_s_0820_general
                                          g_s_0820_results.

    g_s_0820_general_init = g_s_0820_general.

  ENDIF.

  IF NOT ( g_t_0820_qt_units[] IS INITIAL ).

    PERFORM call_f4_help_qtunit  TABLES  g_t_0820_qt_units
                                 USING   g_s_0820_general
                                         'G_S_0820_GENERAL-MEINH'.
  ENDIF.

ENDMODULE.                 " f4_help_general_meinh_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_results_logme_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_results_logme_0820 INPUT.

  IF        g_s_0820_general-defqtunit  IS  INITIAL
  AND NOT ( g_s_0820_general-matnr      IS  INITIAL ).
*                *** Rundungsparameter bestimmen und in g_s_0820_general
*                *** und g_s_0820_results eintragen, wenn sie noch nicht
*                *** bestimmt wurden
    PERFORM simu_rounding_params TABLES   g_t_0820_qt_units
                                 CHANGING g_s_0820_general
                                          g_s_0820_results.

    g_s_0820_general_init = g_s_0820_general.

  ENDIF.

  IF NOT ( g_t_0820_qt_units[] IS INITIAL ).

    PERFORM call_f4_help_qtunit  TABLES  g_t_0820_qt_units
                                 USING   g_s_0820_general
                                         'G_S_0820_RESULTS-LOGME'.

  ENDIF.

ENDMODULE.                 " f4_help_results_logme_0820  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_meinh_umrech_0820  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_meinh_umrech_0820 INPUT.

  IF        g_s_0820_general-defqtunit  IS  INITIAL
  AND NOT ( g_s_0820_general-matnr      IS  INITIAL ).
*                *** Rundungsparameter bestimmen und in g_s_0820_general
*                *** und g_s_0820_results eintragen, wenn sie noch nicht
*                *** bestimmt wurden
    PERFORM simu_rounding_params TABLES   g_t_0820_qt_units
                                 CHANGING g_s_0820_general
                                          g_s_0820_results.

    g_s_0820_general_init = g_s_0820_general.

  ENDIF.

  IF NOT ( g_t_0820_qt_units[] IS INITIAL ).

    PERFORM call_f4_help_qtunit  TABLES  g_t_0820_qt_units
                                 USING   g_s_0820_general
                                         'G_0820_MEINH_UMRECH'.

  ENDIF.
ENDMODULE.                 " f4_help_meinh_umrech_0820  INPUT

***********************************************************************
*                       Dynpro 830
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  exit_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0830 INPUT.

  CLEAR: ok_code.

  DATA: l_answer  TYPE c.

*                *** Beim Abbruch keine geänderten Daten übernehmen
  IF g_s_0830_general    <>  g_s_0820_general
  OR g_t_0830_qt_units[] <>  g_t_0820_qt_units[].

*                *** Wurden die Daten bereits geänder, erfolgt ein
*                *** entsprechender Hinweis!
    ##fm_olded
* Beim Abbruch gehen die geänderte Werte verloren!
    CALL FUNCTION 'POPUP_TO_DECIDE'
      EXPORTING
*       DEFAULTOPTION     = '1'
        textline1         = text-831 " = !
        textline2         = text-832 " = ?
*       TEXTLINE3         = ' '
        text_option1      = text-833 " = Ja
        text_option2      = text-834 " = Nein
*       ICON_TEXT_OPTION1 = ' '
*       ICON_TEXT_OPTION2 = ' '
        titel             = text-835 " = Abbruch
*       START_COLUMN      = 25
*       START_ROW         = 6
*       CANCEL_DISPLAY    = 'X'
      IMPORTING
        answer            = l_answer.

    IF l_answer = c_answer_no_2                             " = '2'
    OR l_answer = c_answer_cancel_a.  " = 'A'
*                *** Beim Abrechen oder bei NEIN erfolgt
*                *** kein Abbruch!!
      EXIT.
    ENDIF.

  ENDIF.
*                *** Ursprüngliche Daten wiederherstellen
  g_s_0830_general     =  g_s_0820_general.
  g_t_0830_qt_units[]  =  g_t_0820_qt_units[].

  LEAVE TO SCREEN 0.

ENDMODULE.                 " exit_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_rdprf_bstrf_0830  INPUT
*&---------------------------------------------------------------------*
*       Prüfe gleichzeitige Eingabe von Rundungsprofil
*       und Rundungswert.
*----------------------------------------------------------------------*
MODULE check_rdprf_bstrf_0830 INPUT.

  IF  NOT ( g_s_0830_general-rdprf  IS  INITIAL )
  AND NOT ( g_s_0830_general-bstrf  IS  INITIAL ).

*                *** Rundungsprofil und Rundungswert dürfen nicht
*                *** gleichzeitig belegt sein!
    MESSAGE e593(m3).

  ENDIF.

ENDMODULE.                 " check_rdprf_bstrf_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_defqtunit_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_defqtunit_0830 INPUT.

  IF NOT ( g_s_0830_general-defqtunit IS  INITIAL ).

*                *** Untersuche ob die eingegebe Mengeneinheit
*                *** eine gültige zu dem Material ist.
*                *** Bemerkung: Falls ME ungültig ist, Fehlerausgabe in
*                *** Unterprogramm.
    PERFORM check_material_unit_2
                TABLES
                  g_t_0830_qt_units
                USING
                  g_s_0830_general-defqtunit
                CHANGING
                  g_s_0830_general-defumrez
                  g_s_0830_general-defumren.

*                *** Die betroffene ME entsprechend der neuen
*                *** Default-ME anpassen
    LOOP AT g_t_0830_qt_units
       INTO g_s_0830_qt_units.

      IF g_s_0830_qt_units-meinh  =  g_s_0830_general-defqtunit.

*                *** gewählte ME ist nun default- und erlaubte ME
        g_s_0830_qt_units-flagdefqtunit  =  c_yes.
        g_s_0830_qt_units-flagallqtunit  =  c_yes.

        MODIFY g_t_0830_qt_units
          FROM g_s_0830_qt_units.

      ENDIF.

      IF  g_s_0830_qt_units-meinh <>  g_s_0830_general-defqtunit
      AND g_s_0830_qt_units-flagdefqtunit  =   c_yes.

*                *** alte default-ME ist nun keine default-ME mehr
        g_s_0830_qt_units-flagdefqtunit  =  c_no.

*                *** überprüfe, ob sie noch erlaubt ist...
        IF (    (   g_s_0830_general-opcode = mdr1p_c_op_mm_normal
                 OR g_s_0830_general-opcode = mdr1p_c_op_mm_ub
                 OR g_s_0830_general-opcode = mdr1p_c_op_additionals )
            AND (        g_s_0830_general-vabme           IS INITIAL
                 OR (    g_s_0830_qt_units-flagvenqtunit  =  c_no
                     OR  g_s_0830_qt_units-flagbuyqtunit  =  c_no ) ) )
        OR (    (   g_s_0830_general-opcode = mdr1p_c_op_sd_auftrag
                 OR g_s_0830_general-opcode = mdr1p_c_op_sd_lieferung )
            AND (        g_s_0830_general-vavme           IS INITIAL
                 OR (    g_s_0830_qt_units-flagvenqtunit  =  c_no
                     OR  g_s_0830_qt_units-flagbuyqtunit  =  c_no ) ) ).

*                *** ...wenn nicht, setzte das Kennzeichen zurück
          g_s_0830_qt_units-flagallqtunit  =  c_no.

        ENDIF.

        MODIFY g_t_0830_qt_units
          FROM g_s_0830_qt_units.

      ENDIF.

    ENDLOOP.

  ENDIF.

ENDMODULE.                 " check_defqtunit_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_mamiqtunit_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_mamiqtunit_0830 INPUT.

*                *** Untersuche ob die eingegebe Mengeneinheit
*                *** eine gültige zu dem Material ist.
  IF NOT ( g_s_0830_general-mamiqtunit IS  INITIAL ).

*                *** Bemerkung: Falls ME ungültig ist, Fehlerausgabe in
*                *** Unterprogramm.
    PERFORM check_material_unit_2
                TABLES
                  g_t_0830_qt_units
                USING
                  g_s_0830_general-mamiqtunit
                CHANGING
                  g_s_0830_general-mamiumrez
                  g_s_0830_general-mamiumren.

  ENDIF.

ENDMODULE.                 " check_mamiqtunit_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_vabme_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_vabme_0830 INPUT.

*                *** Die betroffene ME entsprechend dem
*                *** dem VABME ändern
  LOOP AT g_t_0830_qt_units
     INTO g_s_0830_qt_units.

    IF g_s_0830_qt_units-flagdefqtunit  =  c_no.

      IF g_s_0830_general-vabme  IS INITIAL.


        g_s_0830_qt_units-flagallqtunit  =  c_no.

        MODIFY g_t_0830_qt_units
          FROM g_s_0830_qt_units.

      ELSE.

        IF  g_s_0830_qt_units-flagvenqtunit  =  c_yes
        AND g_s_0830_qt_units-flagbuyqtunit  =  c_yes.

          g_s_0830_qt_units-flagallqtunit  =  c_yes.

          MODIFY g_t_0830_qt_units
            FROM g_s_0830_qt_units.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDMODULE.                 " check_vabme_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_schme_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_schme_0830 INPUT.

*                *** Untersuche ob die eingegebe Mengeneinheit
*                *** eine gültige zu dem Material ist.
  IF NOT ( g_s_0830_general-schme IS  INITIAL ).

*                *** Bemerkung: Falls ME ungültig ist, Fehlerausgabe in
*                *** Unterprogramm.
    PERFORM check_material_unit_2
                TABLES
                  g_t_0830_qt_units
                USING
                  g_s_0830_general-schme
                CHANGING
                  g_s_0830_general-schmeumrez
                  g_s_0830_general-schmeumren.

  ENDIF.

ENDMODULE.                 " check_schme_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_vavme_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_vavme_0830 INPUT.

*                *** Die betroffene ME entsprechend dem
*                *** dem VAVME ändern
  LOOP AT g_t_0830_qt_units
     INTO g_s_0830_qt_units.

    IF g_s_0830_qt_units-flagdefqtunit  =  c_no.

      IF g_s_0830_general-vavme  IS INITIAL.


        g_s_0830_qt_units-flagallqtunit  =  c_no.

        MODIFY g_t_0830_qt_units
          FROM g_s_0830_qt_units.

      ELSE.

        IF  g_s_0830_qt_units-flagvenqtunit  =  c_yes
        AND g_s_0830_qt_units-flagbuyqtunit  =  c_yes.

          g_s_0830_qt_units-flagallqtunit  =  c_yes.

          MODIFY g_t_0830_qt_units
            FROM g_s_0830_qt_units.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDMODULE.                 " check_vavme_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  evaluate_save_ok_code_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE evaluate_save_ok_code_0830 INPUT.

*                *** Zunächst ok_code sichern
  save_ok_code = ok_code.
  CLEAR ok_code.

*                *** Zuerst werden die eventuell geänderte
*                *** Min- und Max-Mengen in G_S_0830_GENERAL
*                *** übernommen
  g_s_0830_general-maxqt  =  g_0830_maxqt.
  g_s_0830_general-minqt  =  g_0830_minqt.

  CASE save_ok_code.

    WHEN c_0830_allqtunits.     "= 'ALLQTUNITS'.
*                *** Erlaubte ME´s anzeigen
      PERFORM show_allowed_qt_units  TABLES g_t_0830_qt_units
                                     USING  g_s_0830_general.

    WHEN c_0830_detailrdprf.    "= 'DETAILRDPRF'.
*                *** Detail zum Rundungsprofil anzeigen
      PERFORM show_detail_rdprf
        USING
          g_s_0830_general-rdprf
          g_0830_rdprf_werks.

    WHEN c_fc_toggle.         "= 'TOGGLE'.
*                *** Anzeigen <-> Ändern
      PERFORM toggle_modus_dynpro_0830  CHANGING  g_0830_mode_dynpro.

    WHEN c_fc_take.           " = 'TAKE'
*                *** Bei der Übernahme der Daten
*                *** Screen einfach verlassen!
      LEAVE TO SCREEN 0.

    WHEN c_fc_undo.           " = 'UNDO'
*                *** Ursprüngliche Daten wiederherstellen
      CLEAR: g_t_0830_qt_units,
             g_t_0830_qt_units[],
             g_s_0830_results.
*                *** Initialisieren der Rundungsparameter:
      PERFORM init_general_params
                  CHANGING
                     g_s_0830_general.

*                *** Eingabe-Wert für die Menge noch übernehmen
      g_s_0830_general-menge  =  g_0820_single_value.

      PERFORM simu_rounding_params TABLES   g_t_0830_qt_units
                                   CHANGING g_s_0830_general
                                            g_s_0830_results.

      g_0830_maxqt      =  g_s_0830_general-maxqt.
      g_0830_minqt      =  g_s_0830_general-minqt.

*                *** Die Mengeneinheit für den Rundungswert kann nicht
*                *** manuell geändert werden,  daher muss dieser Wert
*                *** auch nicht neu bestimmt werden!

*                *** Das Werk zum Rundungsprofil kann nicht manuell
*                *** geändert werden, daher muss dieser Wert auch nicht
*                *** neu bestimmt werden!


  ENDCASE.

ENDMODULE.                 " evaluate_save_ok_code_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_rdprf_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_rdprf_0830 INPUT.

  g_dynpprog = sy-repid.
  g_dynpnr   = sy-dynnr.

  PERFORM f4help_rdpr_rdprf
              USING
                 g_dynpprog
                 g_dynpnr
                 'G_S_0830_GENERAL-RDPRF'
                 'G_0830_RDPRF_WERKS'
                 c_no
                 c_yes.

ENDMODULE.                 " f4_help_rdprf_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_defqtunit_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_defqtunit_0830 INPUT.

  PERFORM call_f4_help_qtunit  TABLES  g_t_0830_qt_units
                               USING   g_s_0830_general
                                       'G_S_0830_GENERAL-DEFQTUNIT'.

ENDMODULE.                 " f4_help_defqtunit_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_mamiqtunit_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_mamiqtunit_0830 INPUT.

  PERFORM call_f4_help_qtunit  TABLES  g_t_0830_qt_units
                               USING   g_s_0830_general
                                       'G_S_0830_GENERAL-MAMIQTUNIT'.

ENDMODULE.                 " f4_help_mamiqtunit_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_help_schme_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_help_schme_0830 INPUT.

  PERFORM call_f4_help_qtunit  TABLES  g_t_0830_qt_units
                               USING   g_s_0830_general
                                       'G_S_0830_GENERAL-SCHME'.

ENDMODULE.                 " f4_help_schme_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_unitgrs_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_unitgrs_0830 INPUT.

  PERFORM recompute_allowed_qt_units
          USING
            g_s_0830_general
          CHANGING
            g_t_0830_qt_units.

ENDMODULE.                 " check_unitgrs_0830  INPUT

*&---------------------------------------------------------------------*
*&      Module  check_rdprf_0830  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_rdprf_0830 INPUT.

*                *** Definition des Rundungsprofils muss existieren!
  SELECT  *
    FROM  rdpr
   WHERE  rdprf = g_s_0830_general-rdprf
     AND  werks = g_0830_rdprf_werks.
  ENDSELECT.

  IF sy-subrc <> 0.
    MESSAGE e687(m3) WITH g_s_0830_general-rdprf.
  ENDIF.

ENDMODULE.                 " check_rdprf_0830  INPUT

***********************************************************************
*                       Dynpro 840
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  exit_0840  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0840 INPUT.

  CLEAR: ok_code,
         g_answer.

*                *** Beim Abbruch keine geänderten Daten übernehmen
  IF g_s_0840_general    <>  g_s_0820_general.

*                *** Wurden die Daten bereits geänder, erfolgt ein
*                *** entsprechender Hinweis!
* Beim Abbruch gehen die geänderte Werte verloren!
    CALL FUNCTION 'POPUP_TO_DECIDE'
      EXPORTING
*       DEFAULTOPTION     = '1'
        textline1         = text-831 " = !
        textline2         = text-832 " = ?
*       TEXTLINE3         = ' '
        text_option1      = text-833 " = Ja
        text_option2      = text-834 " = Nein
*       ICON_TEXT_OPTION1 = ' '
*       ICON_TEXT_OPTION2 = ' '
        titel             = text-836 " = Abbruch
*       START_COLUMN      = 25
*       START_ROW         = 6
*       CANCEL_DISPLAY    = 'X'
      IMPORTING
        answer            = g_answer.

    IF g_answer = c_answer_no_2                             " = '2'
    OR g_answer = c_answer_cancel_a.  " = 'A'
*                *** Beim Abrechen oder bei NEIN erfolgt
*                *** kein Abbruch!!
      EXIT.
    ENDIF.

  ENDIF.
*                *** Ursprüngliche Daten wiederherstellen
  g_s_0840_general     =  g_s_0820_general.

  LEAVE TO SCREEN 0.

ENDMODULE.                 " exit_0840  INPUT

*&---------------------------------------------------------------------*
*&      Module  evaluate_save_ok_code_0840  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE evaluate_save_ok_code_0840 INPUT.

*                *** Zunächst ok_code sichern
  save_ok_code = ok_code.
  CLEAR ok_code.

  CASE save_ok_code.

    WHEN c_fc_toggle.         "= 'TOGGLE'.
*                *** Anzeigen <-> Ändern
      PERFORM toggle_modus_dynpro_0840  CHANGING  g_0840_mode_dynpro.

    WHEN c_fc_take.           " = 'TAKE'
*                *** Beid er Übernahme der Daten
*                *** Screen einfach verlassen!
      LEAVE TO SCREEN 0.

    WHEN c_fc_undo.           " = 'UNDO'
*                *** Ursprüngliche Daten wiederherstellen
*                *** Steuerungdsparameter laut Profil-Eintrag
*                *** neu bestimmen
      PERFORM read_control_params_0840
                  CHANGING
                     g_s_0840_general.

  ENDCASE.

ENDMODULE.                 " evaluate_save_ok_code_0840  INPUT

***********************************************************************
*                       Dynpro 845
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  exit_0845  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0845 INPUT.

  CLEAR ok_code.

  LEAVE TO SCREEN 0.

ENDMODULE.                 " exit_0845  INPUT

*&---------------------------------------------------------------------*
*&      Module  evaluate_save_ok_code_0845  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE evaluate_save_ok_code_0845 INPUT.

*                *** Zunächst ok_code sichern
  save_ok_code = ok_code.
  CLEAR ok_code.

  CASE save_ok_code.

    WHEN c_0845_rdrgldetail.

      PERFORM show_rdrgl_detail.

    WHEN c_0845_show1.

      PERFORM show_threshold_roundingvalues.

    WHEN c_0845_show2.

      PERFORM show_markup_discount.

  ENDCASE.

ENDMODULE.                 " evaluate_save_ok_code_0845  INPUT

***********************************************************************
*                       Dynpro 850
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  exit_0850  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0850 INPUT.

  CLEAR ok_code.

  LEAVE TO SCREEN 0.

ENDMODULE.                 " exit_0850  INPUT

*
* 
