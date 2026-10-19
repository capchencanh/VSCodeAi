*----------------------------------------------------------------------*
***INCLUDE LMDR1F15 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       01.10.01  4.70 mbi         Grundversion
*-----------------------------------------------------------------------
***********************************************************************
*                       Dynpro 401
***********************************************************************
*&---------------------------------------------------------------------*
*&      Form  initialization_0401
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM initialization_0401.

*                *** Vorbelegung der Eingabefelder des Eingabedynpros
  g_0401_in_from_amount  =  c_0401_in_from_amount.
  g_0401_in_to_amount    =  c_0401_in_to_amount.
  g_0401_in_step         =  c_0401_in_step.
  g_0401_single_value    =  c_default_single_value.
  g_0401_light           =  c_red.

  CLEAR:  g_0401_meinh,
          g_0401_bstme,
          g_0401_meinh_umrech,
          g_0401_value_umrech,
          g_0401_meinh_rounded,
          g_0401_rounded_value,
          g_0401_call_from_0800,
          g_0401_meinh_input,
          g_s_0401_mara,
          g_0401_matnr,
          g_s_0401_makt.

ENDFORM.                    " initialization_0401

*&---------------------------------------------------------------------*
*&      Form  check_material_unit
*&---------------------------------------------------------------------*
*       Unterprogramm zum überprüfen, ob eine ME eine gültige zum
*       Material ist.
*----------------------------------------------------------------------*
*  -->  p_matnr        Materialnummer zum Material
*  -->  p_meins        Basismengeneinheit zum Material
*  -->  p_meinh        Zu überprüfende Alternativmengeneinheit
*----------------------------------------------------------------------*
FORM check_material_unit
  USING
    p_matnr LIKE mara-matnr
    p_meins LIKE mara-meins
    p_meinh LIKE marm-meinh.

  DATA: l_t_qt_units   TYPE  mdr1p_t_out_allowed_qt_unit,
        l_wa_qt_units  TYPE  mdr1p_s_out_allowed_qt_unit.

  PERFORM find_valid_material_units
              TABLES
                 l_t_qt_units
              USING
                 p_matnr
                 p_meins.

  READ TABLE  l_t_qt_units
    WITH KEY  meinh = p_meinh
        INTO  l_wa_qt_units.

  IF sy-subrc <> 0.
*                *** Fehlermeldung:Die Mengeneinheit existiert nicht zu
*                ***               dem Material
    MESSAGE e059.
  ENDIF.

ENDFORM.                    " check_material_unit

*&---------------------------------------------------------------------*
*&      Form  show_detail_rdprf
*&---------------------------------------------------------------------*
*       Detailinformationen zu einem Rundungsprofil im Dynpro
*       845 anzeigen
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_detail_rdprf
  USING
    p_rdprf   LIKE  rdpr-rdprf
    p_werks   LIKE  t001w-werks.

*                *** Bestimme zunächst das Rundungsprofil
  PERFORM get_data_dynpro_0845
     TABLES
       g_t_rdpr
     USING
       p_rdprf
       p_werks
     CHANGING
       g_0845_rdprf
       g_0845_rdprf_name
       g_0845_werks
       g_0845_werks_name
       g_0845_rdmpo
       g_0845_rdrgl
       g_0845_chkmeli
       g_0845_chkmeku.

  CALL SCREEN 0845
    STARTING AT 40 01.

ENDFORM.                    " show_detail_rdprf

*&---------------------------------------------------------------------*
*&      Form  get_data_dynpro_0845
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--p_t_rdpr
*      -->p_rdprf
*      -->p_werks
*      <--p_0845_rdprf
*      <--p_0845_rdprf_name
*      <--p_0845_werks
*      <--p_0845_werks_name
*      <--p_0845_rdmpo
*      <--p_0845_rdrgl
*      <--p_0845_chkmeli
*      <--p_0845_chkmeku
*----------------------------------------------------------------------*
FORM get_data_dynpro_0845
  TABLES
    p_t_rdpr           STRUCTURE  rdpr
  USING
    p_rdprf            LIKE  rdpr-rdprf
    p_werks            LIKE  t001w-werks
  CHANGING
    p_0845_rdprf       LIKE  g_0845_rdprf
    p_0845_rdprf_name  LIKE  g_0845_rdprf_name
    p_0845_werks       LIKE  g_0845_werks
    p_0845_werks_name  LIKE  g_0845_werks_name
    p_0845_rdmpo       LIKE  g_0845_rdmpo
    p_0845_rdrgl       LIKE  g_0845_rdrgl
    p_0845_chkmeli     LIKE  g_0845_chkmeli
    p_0845_chkmeku     LIKE  g_0845_chkmeku.

  DATA:
    l_t_rdpr   LIKE rdpr
               OCCURS 0,
    l_s_rdpr   LIKE rdpr,
    l_s_rdtx   LIKE rdtx,
    l_subrc    LIKE sy-subrc,
    l_wa_t001w LIKE t001w.

*                *** Lese alle Daten zum Rundungsprofil
*                *** (Wichtig: Hier kann es nicht zu einer
*                ***           Fehlermeldung mit Ausnahme
*                ***           kommen, da in der Aufrufstelle
*                ***           das Rundungsprofil nicht geändert
*                ***           werden kann!!!)
  PERFORM read_rdpr_all
              TABLES
                 l_t_rdpr
              USING
                 p_rdprf
                 p_werks
              CHANGING
                 l_s_rdpr.

*                *** Zuweisung der Parameter
  p_0845_rdprf   = p_rdprf.
  p_0845_werks   = l_s_rdpr-werks.
  p_0845_rdmpo   = l_s_rdpr-rdmpo.
  p_0845_rdrgl   = l_s_rdpr-rdrgl.
  p_0845_chkmeli = l_s_rdpr-chkmeli.
  p_0845_chkmeku = l_s_rdpr-chkmeku.

*                *** Speichere die Daten der lokalen Tabelle in der
*                *** globalen Tabelle für die Detailanzeige des rdprf
  p_t_rdpr[] = l_t_rdpr[].

  IF p_werks IS INITIAL.

*                *** Profil bezieht sich nicht auf ein Werk
    CLEAR: p_0845_werks_name.

  ELSE.

*                *** Namen des Werks lesen
    PERFORM read_t001w_new
                USING
                   p_werks
                CHANGING
                   l_wa_t001w.

    p_0845_werks_name = l_wa_t001w-name1.

  ENDIF.

*                *** Namen des Profils lesen
  PERFORM read_rdtx_single
              USING
                 p_werks
                 p_rdprf
              CHANGING
                 l_subrc
                 l_s_rdtx.

  IF l_subrc = 0.

*                *** Namen übernehmen
    p_0845_rdprf_name = l_s_rdtx-text40.

  ELSE.

*                *** Namen löschen
    CLEAR p_0845_rdprf_name.

  ENDIF.

ENDFORM.                    " get_data_dynpro_0845


***********************************************************************
*                       Dynpro 800
***********************************************************************
*&---------------------------------------------------------------------*
*&      Form  call_dynpro_0800
*&---------------------------------------------------------------------*
*       In Auswahldynpro 800 verzweigen:
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_dynpro_0800.

  CALL SCREEN 0800
    STARTING AT 10 01.

  IF ok_code = c_fc_canc.
*                *** Wurde in Dynpro 800 Abbrechen gedrückt,
*                *** gehe zurück zum Dynpro, in dem der
*                *** Baustein aufgerufen wurde.

    LEAVE TO SCREEN 0.

  ENDIF.

ENDFORM.                    " call_dynpro_0800

*&---------------------------------------------------------------------*
*&      Form  evaluate_checkboxes_0800
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM evaluate_checkboxes_0800.

  CASE c_yes.

    WHEN g_0800_no_appl.

*                *** Initialisiere Dynpro 0401
      PERFORM initialization_0401.

      g_0401_rdprf           =  g_0800_rdprf.
      g_0401_werks           =  g_0800_werks.

*                *** Aufrufstelle 800 für EXIT aus 401 markieren
      g_0401_call_from_0800  =  c_yes.

      LEAVE TO SCREEN 0401.

    WHEN g_0800_with_appl.

*                *** Initialisiere das Dynpro vor dem Aufruf!
      PERFORM initialization_0820.

      LEAVE TO SCREEN 820.

  ENDCASE.

ENDFORM.                    " evaluate_checkboxes_0800

***********************************************************************
*                       Dynpro 845
***********************************************************************
*&---------------------------------------------------------------------*
*&      Form  set_screen_static_profil_0845
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_screen_static_profil_0845 .

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN  c_rdpr_rdrgl
        OR  c_0845_rdrgl
        OR  c_0845_buttondetail
        OR  c_0845_buttonshow2
        OR  c_0845_chkmeli
        OR  c_0845_chkmeku.

        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_static_profil_0845

*&---------------------------------------------------------------------*
*&      Form  set_screen_up_down_0845
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_screen_up_down_0845 .

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN  c_rdpr_rdrgl
        OR  c_0845_rdrgl
        OR  c_0845_buttondetail
        OR  c_0845_buttonshow1
        OR  c_0845_chkmeli
        OR  c_0845_chkmeku.

        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_up_down_0845

*&---------------------------------------------------------------------*
*&      Form  set_screen_no_rounding_0845
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_screen_no_rounding_0845 .

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN  c_rdpr_rdrgl
        OR  c_0845_rdrgl
        OR  c_0845_buttondetail
        OR  c_0845_buttonshow1
        OR  c_0845_buttonshow2
        OR  c_0845_chkmeli
        OR  c_0845_chkmeku.

        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_no_rounding_0845
*&---------------------------------------------------------------------*
*&      Form  set_screen_dynamic_profil_0845
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_screen_dynamic_profil_0845 .

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN  c_0845_buttonshow1
        OR  c_0845_buttonshow2.

        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_dynamic_profil_0845

*&---------------------------------------------------------------------*
*&      Form  show_rdrgl_detail
*&---------------------------------------------------------------------*
*       Definition der Rundungsregel anzeigen!
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_rdrgl_detail .

*                *** Bestimme die Daten, die angezeigt werden sollen
  PERFORM get_data_rdrgl
    USING
      g_0845_rdrgl
    CHANGING
      g_t_rdrgl.

*                *** Lege das Layout des ALV fest
  PERFORM set_layout_alv_rdrgl_detail
    CHANGING
      g_s_layout_alv.

*                *** Generiere den Feldkatalog und passe ihn an die
*                *** Bedürfnisse.
  PERFORM mask_columns_rdrgl_detail
    CHANGING
      g_t_fieldcatalog.

*                *** Zeiger auf die Datentabelle setzen
  GET REFERENCE OF g_t_rdrgl
              INTO g_ref_to_table_alv_0850.

*                *** Rufe das Anzeigedynpro auf
  CALL SCREEN 0850
    STARTING AT 40 01.

ENDFORM.                    " show_rdrgl_detail

*&---------------------------------------------------------------------*
*&      Form  get_data_rdrgl
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_T_RRDRGL_0850  text
*----------------------------------------------------------------------*
FORM get_data_rdrgl
  USING
    p_rdrgl LIKE tw06s-rdrgl
  CHANGING
    r_g_t_rdrgl TYPE STANDARD TABLE.

*                *** globale Tabelle zunächst initialisieren
  CLEAR r_g_t_rdrgl.

*                *** Bestimme die Daten von der Datenbank
  SELECT       *
    FROM       tw06s
    INTO TABLE r_g_t_rdrgl
   WHERE       rdrgl = p_rdrgl.

ENDFORM.                    " get_data_rdrgl

*&---------------------------------------------------------------------*
*&      Form  show_threshold_roundingvalues
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_threshold_roundingvalues .

*                *** Die anzuzeigenden Daten, die in der Tabelle
*                *** g_t_rdpr_0850 gespeichert sind, wurden schon
*                *** im Unterprogramm get_data_dynpro_0845 bestimmt

*                *** Lege das Layout des ALV fest
  PERFORM set_layout_alv_thres_rvalues
    CHANGING
      g_s_layout_alv.

*                *** Generiere den Feldkatalog und passe ihn an die
*                *** Bedürfnisse.
  PERFORM mask_columns_threshold_rvalues
    CHANGING
      g_t_fieldcatalog.

*                *** Zeiger auf die Datentabelle setzen
  GET REFERENCE OF g_t_rdpr
              INTO g_ref_to_table_alv_0850.

*                *** Rufe das Anzeigedynpro auf
  CALL SCREEN 0850
    STARTING AT 40 01.

ENDFORM.                    " show_threshold_roundingvalues

*&---------------------------------------------------------------------*
*&      Form  show_markup_discount
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_markup_discount .

*                *** Bestimme die Daten, die angezeigt werden sollen
  PERFORM get_data_markup_discount
    TABLES
      g_t_rdpr
      g_t_markup_discount.

*                *** Lege das Layout des ALV fest
  PERFORM set_layout_alv_markup_discount
    CHANGING
      g_s_layout_alv.

*                *** manueller Aufbau des Feldkatalogs
  PERFORM mask_columns_markup_discount
    CHANGING
      g_t_fieldcatalog.

*                *** Zeiger auf die Datentabelle setzen
  GET REFERENCE OF g_t_markup_discount
              INTO g_ref_to_table_alv_0850.

*                *** Rufe das Anzeigedynpro auf
  CALL SCREEN 0850
    STARTING AT 40 01.

ENDFORM.                    " show_markup_discount

*&---------------------------------------------------------------------*
*&      Form  get_data_markup_discount
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_G_T_RDPR_0850  text
*      <--P_G_T_MARKUP_DISCOUNT  text
*----------------------------------------------------------------------*
FORM get_data_markup_discount
  TABLES
    p_t_rdpr_0850        LIKE  g_t_rdpr
    p_t_markup_discount  LIKE  g_t_markup_discount.

  DATA: l_wa_rdpr             LIKE rdpr,
        l_wa_markup_discount  TYPE markup_discount_line_type.

*                *** globale Tabelle zunächst initialisieren
  CLEAR: p_t_markup_discount,
         p_t_markup_discount[].

  LOOP AT p_t_rdpr_0850
     INTO l_wa_rdpr.

    l_wa_markup_discount-threshold_value = l_wa_rdpr-bdmng.

    IF l_wa_rdpr-vormg < 0.

      l_wa_markup_discount-percentage = abs( l_wa_rdpr-vormg ).
      l_wa_markup_discount-down       = c_yes.

      CLEAR l_wa_markup_discount-up.

    ELSE.

      l_wa_markup_discount-percentage = l_wa_rdpr-vormg.
      l_wa_markup_discount-up         = c_yes.

      CLEAR l_wa_markup_discount-down.

    ENDIF.

    APPEND l_wa_markup_discount
        TO p_t_markup_discount.

  ENDLOOP.

ENDFORM.                    " get_data_markup_discount

*&---------------------------------------------------------------------*
*&      Form  simu_rdprf_range
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM simu_rdprf_range .

*                *** Bestimme die anzuzeigenden Daten
  PERFORM get_data_sim_rdpr
              TABLES
                g_t_simu_rounding_range
              USING
                rdpr
                g_0401_matnr
                g_0401_meinh_input
                g_s_0401_mara-meins
                g_0401_bstme
                g_0401_in_from_amount
                g_0401_in_to_amount
                g_0401_in_step.


*                *** lege zunächst das Layout des ALV-Controls fest
  PERFORM set_layout_alv   CHANGING g_s_layout_alv.

*                *** generiere den Feldkatalog und passe ihn
*                *** auf die gewünschten Bedürfnisse an
  PERFORM mask_columns     USING    g_0401_meinh_input
                           CHANGING g_t_fieldcatalog.


*                *** Zeiger auf die Datentabelle setzen
  GET REFERENCE OF g_t_simu_rounding_range
              INTO g_ref_to_table_alv_0850.

*                *** Rufe das Anzeigedynpro auf
  CALL SCREEN 0850
    STARTING AT 40 01.

ENDFORM.                    " simu_rdprf_range

*&---------------------------------------------------------------------*
*&      Form  get_data_sim_rdpr
*&---------------------------------------------------------------------*
*       Unterprogramm zur Bestimmung der Daten, die später auf dem ALV
*       ausgegeben werden sollen.
*----------------------------------------------------------------------*
*  -->  p_rdpr          Definition des Rundungsprofils aus dem
*                       EingabeDynPro
*  -->  p_matnr         Materialnummer aus dem EingabeDynPro
*  -->  p_meinh         Mengeneinheit aus dem  EingabeDynPro
*  -->  p_meins         Basis-Mengeneinheit des Materials
*  -->  p_bstme         Bestellmengeneinheit
*  -->  p_from_amount   Eingabe Von-Menge
*  -->  p_to_amount     Eingabe Bis-Menge
*  -->  p_step          Schrittweite
*----------------------------------------------------------------------*
FORM get_data_sim_rdpr
  TABLES
    p_t_simu_rounding_range STRUCTURE mdr1alvsimurundprofil
  USING
    value(p_rdpr)           LIKE      rdpr
    value(p_matnr)          LIKE      mara-matnr
    value(p_meinh)          LIKE      marm-meinh
    value(p_meins)          LIKE      mara-meins
    value(p_bstme)          LIKE      mara-bstme
    value(p_from_amount)    LIKE      rdpr-vormg
    value(p_to_amount)      LIKE      rdpr-vormg
    value(p_step)           LIKE      rdpr-vormg.

  DATA:    l_current_amount         LIKE  rdpr-vormg,
           l_current_round_amount   LIKE  rdpr-vormg,
           l_befor_round_amount     LIKE  rdpr-vormg,
           l_befor_lamount          LIKE  rdpr-vormg,
           l_befor_logunit          LIKE  marm-meinh,
           l_out_from_amount        LIKE  rdpr-vormg,
           l_out_to_amount          LIKE  rdpr-vormg,
           l_current_lamount        LIKE  rdpr-vormg,
           l_current_logunit        LIKE  marm-meinh,
           l_step                   LIKE  rdpr-vormg,
*                *** Arbeitsbereich, um die interne globale Tabelle
*                *** g_t_simu_rounding_range mit Daten zu füllen
           l_wa_simu_rounding_range TYPE  mdr1alvsimurundprofil.

*                *** interne Tabelle zunächst initialisieren
  CLEAR: p_t_simu_rounding_range,
         p_t_simu_rounding_range[].

  l_step = p_step.

*                *** Belege den ersten Wert, der gerundet werden soll,
*                *** mit der unteren Intervall-Grenze!
  l_current_amount      =  p_from_amount.
*                *** Da noch kein Wert gerundet wurde, wird der vor-
*                *** herige gerundete Werte mit dem Default-Wert -1
*                *** initialisiert!
  l_befor_round_amount  =  -1.
*                *** Bestimme alle Rundungswerte zu den Werten des
*                *** Intervalls und gebe sie aus.
*                *** Schleife wird mindestens einmal durchlaufen, da
*                *** beim Eintritt der Schleife gilt:
*                *** l_current_amount = p_from_amount <= p_to_amount
  WHILE l_current_amount  <=  p_to_amount.

*                *** 1. Bestimme zu dem aktuellen Wert den Rundungswert
    PERFORM compute_rounding_results  USING     p_rdpr
                                                p_matnr
                                                p_meinh
                                                p_meins
                                                p_bstme
                                                l_current_amount
                                      CHANGING  l_current_round_amount
                                                l_current_logunit
                                                l_current_lamount.
*                *** 2. Ausgabe des Rundungswerts, wenn folgendes gilt:
*                ***    a) der aktuelle Rundungswert stimmt nicht mit
*                ***       letzten Rundungswert ueberein
*                ***       (diese Bedingung ist fuer den ersten
*                ***        Schleifendurchlauf immer erfüllt)
*                ***    b) die logistische Mengeneinheit hat sich
*                ***       geändert
    IF    l_current_round_amount  <>  l_befor_round_amount
       OR l_befor_logunit         <>  l_current_logunit.
*                ***    und
*                ***    c) der aktuelle Rundungswert bezieht sich nicht
*                ***       auf den ersten Wert des Intervalls.
      IF l_current_amount  > p_from_amount.
*                *** Ausgabe der Zeile zum letzten Rundungswert:
*                *** - der Werte des Intervalls, die zu dem
*                ***   letzten Rundungswert gehören (in Eingabe-Mengen-
*                ***   einheit)
*                *** - letzter Rundungswert (in Eingabe-Mengeneinheit)
*                *** - logistischer Rundungswert zum letzten Rundungs-
*                ***   wert (in logistische Mengeneinheit)
*                *** - logistische Mengeneinheit zum letzten Rundungs-
*                ***   wert

*                       *** Erniedrigung um Schrittweite
        l_out_to_amount = l_current_amount - l_step.

*                *** füllen des Arbeitsbereiches mit den Daten
        l_wa_simu_rounding_range-fromamount     = l_out_from_amount.
        l_wa_simu_rounding_range-toamount       = l_out_to_amount.
        l_wa_simu_rounding_range-roundamount    = l_befor_round_amount.
        l_wa_simu_rounding_range-inqtunit       = p_meinh.
        l_wa_simu_rounding_range-roundlogamount = l_befor_lamount.
        l_wa_simu_rounding_range-logqtunit      = l_befor_logunit.

*                *** und speichern in der internen Tabelle
        APPEND l_wa_simu_rounding_range
            TO p_t_simu_rounding_range.

      ENDIF.
*                *** 3. Bei einem Wechsel des Rundungswerts:
*                ***    muss die Von-Menge für die nächste Ausgabezeile
*                ***    belegt werden (die l_out_from_amount ist bei
*                ***    dem ersten Wert des Intervalls noch nicht
*                ***    belegt, jedoch wird zu diesem Wert in dem ersten
*                ***    Schleifenducrhlauf noch keine Zeile ausgegeben)
      l_out_from_amount  =  l_current_amount.

    ENDIF.

*                *** 4. Naechster Wert des Intervalls, der gerundet wird
*                       ***      naechster Wert des Intervalls errechnet
*                       ***      sich aus dem vorherigen Wert und der
*                       ***      Schrittweite.
    l_current_amount = l_current_amount + l_step.

*                *** 5. Gerundeter Wert als letzter Rundungswert
*                ***    für den naechsten Schleifendurchlauf merken.
    l_befor_round_amount = l_current_round_amount.
    l_befor_lamount      = l_current_lamount.
    l_befor_logunit      = l_current_logunit.

  ENDWHILE.

*                *** Ausgabe der letzten Zeile fuer den letzten
*                *** Schleifendurchlauf
  l_out_to_amount = l_current_amount - l_step.

*                *** füllen des Arbeitsbereiches mit den Daten
  l_wa_simu_rounding_range-fromamount     = l_out_from_amount.
  l_wa_simu_rounding_range-toamount       = l_out_to_amount.
  l_wa_simu_rounding_range-roundamount    = l_befor_round_amount.
  l_wa_simu_rounding_range-inqtunit       = p_meinh.
  l_wa_simu_rounding_range-roundlogamount = l_befor_lamount.
  l_wa_simu_rounding_range-logqtunit      = l_befor_logunit.

*                *** und speichern in der internen Tabelle
  APPEND l_wa_simu_rounding_range
      TO p_t_simu_rounding_range.

ENDFORM.                    " get_data_sim_rdpr

*&---------------------------------------------------------------------*
*&      Form  compute_rounding_results
*&---------------------------------------------------------------------*
*       Unterprogramm zur Berechnung der Rundungsergebnisse
*----------------------------------------------------------------------*
*  -->  p_rdpr        Definition des Rundungsprofils aus dem
*                     EingabeDynPro
*  -->  p_matnr       Materialnummer aus dem EingabeDynPro
*  -->  p_meinh       Mengeneinheit aus dem  EingabeDynPro
*  -->  p_meins       Basis-Mengeneinheit des Materials
*  -->  p_bstme       Bestellmengeneinheit
*  -->  p_amount      Eingabemenge aus dem Intervall
*  <--  r_round       Rundungsmenge zu der Eingabemenge (nur Rückgabe)
*  <--  r_logunit     Logistische Mengeneinheit         (nur Rückgabe)
*  <--  r_lamount     Rundungsmenge zu der Eingabemenge (nur Rückgabe)
*----------------------------------------------------------------------*
FORM compute_rounding_results
  USING
    value(p_rdpr)    LIKE  rdpr
    value(p_matnr)   LIKE  mara-matnr
    value(p_meinh)   LIKE  marm-meinh
    value(p_meins)   LIKE  mara-meins
    value(p_bstme)   LIKE  mara-bstme
    value(p_amount)  LIKE  rdpr-vormg
  CHANGING
    value(p_round)   LIKE  rdpr-vormg
    value(p_logunit) LIKE  marm-meinh
    value(p_lamount) LIKE  rdpr-vormg.

  DATA:   l_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                            WITH HEADER LINE,
          l_t_round_reasons TYPE mdr1p_t_rundungsgrund,
          l_s_general       TYPE mdr1p_s_in_single_round,
          l_s_results       TYPE mdr1p_s_out_single_round,

*                *** Arbeitsbereiche
  l_wa_qt_units TYPE mdr1p_s_out_allowed_qt_unit.

*                *** finde zunächst die gültigen Materialeinheiten
*                *** heraus
  PERFORM find_valid_material_units
              TABLES
                 l_t_qt_units
              USING
                 p_matnr
                 p_meins.
*                *** Default-Werte für erlaubte Abnehmer- und
*                *** Lieferanten-ME setzen
  LOOP AT l_t_qt_units.

    l_t_qt_units-flagvenqtunit = c_yes.
    l_t_qt_units-flagbuyqtunit = c_yes.

    MODIFY l_t_qt_units.

  ENDLOOP.

*                *** fülle die lokalen Strukturen mit den Daten, die in
*                *** der Routine rounding_profil benötigt werden. Die
*                *** Tabelle "l_t_round_reasons" bleibt dabei leer.
  l_s_general-meinh = p_meinh.  "Eingabe-ME
  l_s_general-menge = p_amount. "Eingabemenge = Eingabemenge Intervall
  l_s_general-matnr = p_matnr.  "Materialnummer
  l_s_general-werks = p_rdpr-werks.

  l_s_results-meins = p_meins.  "Basis-ME

*                *** Bestimme die Daten zur Bestell-ME, die Bestell-ME
*                *** muss immer eine gültige ME sein!!!
  READ TABLE l_t_qt_units
        INTO l_wa_qt_units
    WITH KEY meinh = p_bstme .

  l_s_general-defqtunit = l_wa_qt_units-meinh.
  l_s_general-defumrez  = l_wa_qt_units-umrez.
  l_s_general-defumren  = l_wa_qt_units-umren.
  l_s_general-rdprf     = p_rdpr-rdprf.

*                *** Default-werte für das Rundungs-Ergebnis
*                *** belegen
  l_s_results-defqtunit = l_wa_qt_units-meinh.
  l_s_results-defumrez  = l_wa_qt_units-umrez.
  l_s_results-defumren  = l_wa_qt_units-umren.
  l_s_results-rdprf     = p_rdpr-rdprf.
  l_s_results-menge     = l_s_general-menge.
  l_s_results-lmenge    = l_s_general-menge.
  l_s_results-logme     = l_s_general-meinh.

*                *** Neues Rundungs-Customizing entsprechend mit
*                *** Default-Werten belegen
  l_s_general-rvalu     = c_yes.
  l_s_general-rdyna     = c_yes.
  l_s_general-rstat     = c_yes.
  l_s_general-rmami     = c_yes.
  l_s_general-rchalum   = c_yes.
  l_s_general-rvaldec   = c_yes.
  l_s_general-purpar    = c_purpar_default_0.
  l_s_general-rleave    = c_yes.
  l_s_general-raufab    = c_yes.

  PERFORM rounding_profil
              TABLES
                 l_t_qt_units
                 l_t_round_reasons
              USING
                 l_s_general
              CHANGING
                 l_s_results.

*                *** nach der Rundung befindet sich das Rundungsergebnis
*                *** in:
*                ***   p_s_results-roundqt: Rundungsmenge in ME:rqtunit
*                ***   p_s_results-rqtunit: Rundungs-ME
*                *** wenn gerundet wurde!!!
  IF NOT ( l_s_results-roundqt IS INITIAL )
  OR NOT ( l_s_results-rqtunit IS INITIAL ).
*                *** Ergebnis in eigentliche Ausgabe-Felder Stellen
    l_s_results-lmenge = l_s_results-roundqt.
    l_s_results-logme  = l_s_results-rqtunit.
  ENDIF.

  IF l_s_results-logme = l_s_general-meinh.
*                *** - Eingabe-ME = Rundungs-ME => keine Umrechnung
    l_s_results-menge = l_s_results-lmenge.
  ELSE.
*                *** - Eingabe-ME <> Rundungs-ME => Umrechnung durchf.
    PERFORM conv2unit_new  USING    l_s_general
                                    l_s_results-lmenge
                                    l_s_results-logme
                                    l_s_general-meinh
                           CHANGING l_s_results
                                    l_s_results-menge.
  ENDIF.

*                 *** die Ausgabemengen (gerundet) dürfen nur zur
*                 *** Mengeneinheit gültige Nachkommastellen besitzen
  PERFORM check_allowed_dec
              TABLES
                 l_t_round_reasons
              USING
                 l_s_general
              CHANGING
                 l_s_results.

*                *** Rückgabewerte mit den Ergebnissen aus l_s_results
*                *** belegen
  p_round   = l_s_results-menge.
  p_logunit = l_s_results-logme.
  p_lamount = l_s_results-lmenge.

ENDFORM.                    " compute_rounding_results

*&---------------------------------------------------------------------*
*&      Form  simu_rdprf_single_value
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM simu_rdprf_single_value .

  DATA: l_round   LIKE rdpr-vormg,
        l_logunit LIKE marm-meinh,
        l_lamount LIKE rdpr-vormg.

  PERFORM compute_rounding_results
              USING
                  rdpr
                  g_0401_matnr
                  g_0401_meinh_input
                  g_s_0401_mara-meins
                  g_s_0401_mara-bstme
                  g_0401_single_value
              CHANGING
                  l_round
                  l_logunit
                  l_lamount.

  g_0401_rounded_value = l_lamount.
  g_0401_meinh_rounded = l_logunit.
  g_0401_value_umrech  = l_round.

ENDFORM.                    " simu_rdprf_single_value

*&---------------------------------------------------------------------*
*&      Form  initialization_0820
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialization_0820 .

*                *** Initialisiere die Felder des Dynpros
  CLEAR: g_0820_matnr_name,
         g_0820_werks_name,
         g_0820_vkorg_name,
         g_0820_vtweg_name,
         g_0820_kunnr_name,
         g_0820_spart_name,
         g_0820_lifnr_name,
         g_0820_ekorg_name,
         g_0820_pstyp_name,
         g_0820_werks_kred_name,
         g_0820_single_value,
         g_0820_rounded_value,
         g_0820_value_umrech,
         g_0820_meinh_umrech,
         g_0820_no_0800_call,
         g_s_0820_general,
         g_s_0820_results.

*                *** Vorbelegung der Eingabefelder des Eingabedynpros
  g_0820_light            =  c_red.
  g_0820_control_initial  =  c_yes.
  g_0820_rounding_initial =  c_yes.

*                *** Defaultdaten und Daten aus der Aufrufstelle
*                *** in die Struktur g_s_0820_general eintragen
*                *** - Default Eingabewert
  g_0820_single_value  =  c_default_single_value.
*                *** - Transformiere Neuer Anwendungs-Opcode
*                ***   zu dem alten Opcode
  PERFORM set_opcode_for_appl   USING      g_0800_appl
                                CHANGING   g_s_0820_general-opcode.

  IF g_s_0820_general-opcode = mdr1p_c_op_sd_lieferung.
*                *** - Bei Lieferung muß das Kennzeichen 'Infosatz'
*                ***   berücksichtigen immer gesetzt sein.
    g_s_0820_general-infls = c_yes.

  ELSE.
*                *** - Sonst ist der Default nicht gesetzt:
    g_s_0820_general-infls = c_no.

  ENDIF.
*                *** - Ausgewählter Transaktionscode
  g_s_0820_general-tcode   =  g_0800_tcode.
*                *** - Gültiges Customizing zur ausgewählten
*                ***   Anwendung (opcode) und Transaktion (tcode)
*                ***   lesen und eintragen!
  PERFORM call_customizing_read CHANGING g_s_0820_general.

*                *** gelesenes Customizing in der Struktur merken,
*                *** die benutzt wird,um festzustellen,ob der Benutzer
*                *** das Profil geändert hat.
  MOVE-CORRESPONDING g_s_0820_general TO g_s_0820_rcpr_init.

ENDFORM.                    " initialization_0820

*&---------------------------------------------------------------------*
*&      Form  set_screen_purchase_order_0820
*&---------------------------------------------------------------------*
*       Lege das Bild für Normalbestellung fest
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_screen_purchase_order_0820 .

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0820_GENERAL-WERKS'.
*                *** Werk-Eingabefeld ist obligatorisch
        screen-required = 1.

      WHEN 'G_S_0820_GENERAL-VKORG'
        OR 'G_S_0820_GENERAL-VTWEG'
        OR 'G_S_0820_GENERAL-KUNNR'
        OR 'G_S_0820_GENERAL-SPART'
        OR 'G_S_0820_GENERAL-INFLS'
        OR 'MDR1INSINGLEROUND-VKORG'
        OR 'MDR1INSINGLEROUND-VTWEG'
        OR 'MDR1INSINGLEROUND-KUNNR'
        OR 'MDR1INSINGLEROUND-SPART'
        OR 'MDR1INSINGLEROUND-INFLS'
        OR 'G_0820_VKORG_NAME'
        OR 'G_0820_VTWEG_NAME'
        OR 'G_0820_KUNNR_NAME'
        OR 'G_0820_SPART_NAME'.
*                *** die Verkaufsfelder müssen unsichtbar sein!
        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_purchase_order_0820

*&---------------------------------------------------------------------*
*&      Form  set_screen_sales_order_0820
*&---------------------------------------------------------------------*
*       Lege das Bild für den Kundenauftrag fest
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_screen_sales_order_0820 .

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0820_GENERAL-VKORG'
        OR 'G_S_0820_GENERAL-VTWEG'
        OR 'G_S_0820_GENERAL-KUNNR'
        OR 'G_S_0820_GENERAL-SPART'.
*                *** Obligatorische Eingabefelder festlegen
        screen-required = 1.

      WHEN 'G_S_0820_GENERAL-WERKS'
        OR 'G_S_0820_GENERAL-LIFNR'
        OR 'G_S_0820_GENERAL-EKORG'
        OR 'G_S_0820_GENERAL-PSTYP'
        OR 'G_S_0820_GENERAL-WERKS_KRED'
        OR 'MDR1INSINGLEROUND-WERKS'
        OR 'MDR1INSINGLEROUND-LIFNR'
        OR 'MDR1INSINGLEROUND-EKORG'
        OR 'MDR1INSINGLEROUND-PSTYP'
        OR 'MDR1INSINGLEROUND-WERKS_KRED'
        OR 'G_0820_WERKS_NAME'
        OR 'G_0820_LIFNR_NAME'
        OR 'G_0820_EKORG_NAME'
        OR 'G_0820_PSTYP_NAME'
        OR 'G_0820_WERKS_KRED_NAME'.
*                *** die Einkaufsfelder müssen unsichtbar sein!
        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_sales_order_0820

*&---------------------------------------------------------------------*
*&      Form  set_screen_delivery_0820
*&---------------------------------------------------------------------*
*       Lege das Bild für die Lieferung fest
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_screen_delivery_0820 .

*                *** 1. Teil identisch zu Kundenauftrag
  PERFORM set_screen_sales_order_0820.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0820_GENERAL-INFLS'.
*                *** Abweichung zum Kundenauftrag, das Lesen der
*                *** der Infosätze ist NICHT steuerbar!!!
        screen-input = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_delivery_0820

*&---------------------------------------------------------------------*
*&      Form  simu_rounding_appl
*&---------------------------------------------------------------------*
*       Rundungs-Simulation zu einer Anwendung
*----------------------------------------------------------------------*
*  <--  p_t_round_reasons
*  <->  p_s_general
*  <--  p_s_results
*----------------------------------------------------------------------*
FORM simu_rounding_appl
  TABLES
    p_t_round_reasons  TYPE mdr1trundungsgrund
  CHANGING
    p_s_general        TYPE mdr1insingleround
    p_s_results        TYPE mdr1outsingleround.

*                *** - Kennzeichen setzen: Komme aus Simulation der
*                ***   Rundung
  p_s_general-simurounding = c_yes.

*                *** Bestimme die Rundungsparameter
  PERFORM call_single_rounding_2   TABLES    p_t_round_reasons
                                   USING     p_s_general
                                   CHANGING  p_s_results.

ENDFORM.                    " simu_rounding_appl

*&---------------------------------------------------------------------*
*&      Form  put_results_into_general
*&---------------------------------------------------------------------*
*       Trage die bestimmten Rundungsparameter in die Struktur
*       p_s_general ein
*----------------------------------------------------------------------*
*      -->p_s_results
*      <--p_s_general
*----------------------------------------------------------------------*
FORM put_results_into_general
  USING
    p_s_results        TYPE mdr1outsingleround
  CHANGING
    p_s_general        TYPE mdr1insingleround.

  DATA:
    l_s_roundparams  TYPE  mdr1roundparams,
    l_s_paramspur    TYPE  mdr1paramspur,
    l_s_paramssell   TYPE  mdr1paramssell.

*                *** Rundungsparameter aus p_s_results ausfiltern
  MOVE-CORRESPONDING  p_s_results
                  TO  l_s_roundparams.

  MOVE-CORRESPONDING  p_s_results
                  TO  l_s_paramspur.

  MOVE-CORRESPONDING  p_s_results
                  TO  l_s_paramssell.

*                *** Rundungsparameter in p_s_general eintragen
  MOVE-CORRESPONDING  l_s_roundparams
                  TO  p_s_general.

  MOVE-CORRESPONDING  l_s_paramspur
                  TO  p_s_general.

  MOVE-CORRESPONDING  l_s_paramssell
                  TO  p_s_general.


ENDFORM.                    " put_results_into_general

*&---------------------------------------------------------------------*
*&      Form  init_general_params
*&---------------------------------------------------------------------*
*       Initialisiere die Rundungsparameter in p_s_general-Struktur
*----------------------------------------------------------------------*
*      <->P_S_GENERAL
*----------------------------------------------------------------------*
FORM init_general_params
  CHANGING
    p_s_general        TYPE mdr1insingleround.

  DATA:
    l_s_roundparams  TYPE  mdr1roundparams,
    l_s_paramspur    TYPE  mdr1paramspur,
    l_s_paramssell   TYPE  mdr1paramssell.

*                *** Initialisierte Rundungsparameter in
*                *** p_s_general eintragen
  MOVE-CORRESPONDING  l_s_roundparams
                  TO  p_s_general.

  MOVE-CORRESPONDING  l_s_paramspur
                  TO  p_s_general.

  MOVE-CORRESPONDING  l_s_paramssell
                  TO  p_s_general.


ENDFORM.                    " init_general_params

*&---------------------------------------------------------------------*
*&      Form  simu_rounding_params
*&---------------------------------------------------------------------*
*       Simulatio der Bestimmung der Rundungsparameter
*----------------------------------------------------------------------*
*  <--  p_t_qt_units
*  <->  p_s_general
*  <--  p_s_results
*----------------------------------------------------------------------*
FORM simu_rounding_params
  TABLES
    p_t_qt_units    TYPE mdr1toutallowedqtunit
  CHANGING
    p_s_general     TYPE mdr1insingleround
    p_s_results     TYPE mdr1outsingleround.

*                *** Kennzeichen setzen: Komme aus Simulation der
*                *** Rundung
  p_s_general-simurounding = c_yes.

*                *** alle Daten in der Ergebnis-Struktur löschen, da
*                *** diese neu bestimmt werden sollen
  CLEAR p_s_results.

*                *** Bestimme die Rundungsparameter
  PERFORM call_mdr1_determ_round_params
              TABLES
                 p_t_qt_units
              CHANGING
                 p_s_general
                 p_s_results.

*                *** Bestimmte Rundungsparamter der Struktur p_s_results
*                *** in die Struktur p_s_general übernehmen
  PERFORM  put_results_into_general USING    p_s_results
                                    CHANGING p_s_general.

ENDFORM.                    " simu_rounding_params

*&---------------------------------------------------------------------*
*&      Form  set_screen_show_0830
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_s_general
*  <--  SCREEN    je nach OPCODE gestzt!
*----------------------------------------------------------------------*
FORM set_screen_show_0830
  USING
    p_s_general   LIKE  g_s_0830_general.

*                *** Verzweige je nach opcode
  CASE p_s_general-opcode.

    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_additionals.

      PERFORM set_screen_pur_0830   USING  p_s_general.

    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung.

      PERFORM set_screen_sell_0830  USING  p_s_general.

  ENDCASE.

ENDFORM.                    " set_screen_show_0830

*&---------------------------------------------------------------------*
*&      Form  set_screen_pur_0830
*&---------------------------------------------------------------------*
*       Bild für Einkaufsparameter festlegen
*----------------------------------------------------------------------*
*  -->  p_s_general
*  <--  SCREEN
*----------------------------------------------------------------------*
FORM set_screen_pur_0830
  USING
    p_s_general  LIKE  g_s_0830_general.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0830_GENERAL-VAVME'
        OR 'G_S_0830_GENERAL-SCMNG'
        OR 'G_S_0830_GENERAL-SCHME'
        OR 'G_S_0830_GENERAL-SCHMEUMREZ'
        OR 'G_S_0830_GENERAL-SCHMEUMREN'
        OR 'MDR1INSINGLEROUND-VAVME'
        OR 'MDR1INSINGLEROUND-SCMNG'
        OR 'MDR1INSINGLEROUND-SCHME'
        OR 'MDR1INSINGLEROUND-SCHMEUMREZ'
        OR 'MDR1INSINGLEROUND-SCHMEUMREN'.

*                *** Verkaufsparameter nicht sichtbar
        screen-active = 0.

      WHEN 'G_0830_DEFQTUNIT_NAME'.

*                *** Beim Eikauf ist die Default-ME die Bestell-ME
        g_0830_defqtunit_name =  text-814. "= 'Bestell-ME'.

*                *** Beachte: Felder nur anzeigen, falls nicht initial.
*                *** Bestell-ME muß nicht geprüft werden, da diese immer
*                *** gefunden wird (mindestens mara-meins wird gefunden)
      WHEN 'G_S_0830_GENERAL-VENUNITGR'
        OR 'MDR1INSINGLEROUND-VENUNITGR'.

        IF  p_s_general-venunitgr IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-BUYUNITGR'
        OR 'MDR1INSINGLEROUND-BUYUNITGR'.

        IF  p_s_general-buyunitgr IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-RDPRF'
        OR 'BUTTONDETAILRDPRF'
        OR 'MDR1INSINGLEROUND-RDPRF'.

        IF  p_s_general-rdprf IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_0830_MAXQT'
        OR 'MDR1INSINGLEROUND-MAXQT'.

        IF  p_s_general-maxqt IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_0830_MINQT'
        OR 'MDR1INSINGLEROUND-MINQT'.

        IF  p_s_general-minqt IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-MAMIQTUNIT'
        OR 'MDR1INSINGLEROUND-MAMIQTUNIT'
        OR 'G_S_0830_GENERAL-MAMIUMREZ'
        OR 'G_S_0830_GENERAL-MAMIUMREN'
        OR 'MDR1INSINGLEROUND-MAMIUMREZ'
        OR 'MDR1INSINGLEROUND-MAMIUMREN'.

*                *** Falls es keine Min-Max-Grenzen gibt, nicht anzeigen
        IF  p_s_general-minqt IS INITIAL
        AND p_s_general-maxqt IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-BSTRF'
        OR 'MDR1INSINGLEROUND-BSTRF'
        OR 'G_0830_BSTRFQTUNIT'
        OR 'MDR1OUTSINGLEROUND-MEINS'.

        IF  p_s_general-bstrf IS INITIAL.

          screen-active = 0.

        ENDIF.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_pur_0830

*&---------------------------------------------------------------------*
*&      Form  set_screen_sell_0830
*&---------------------------------------------------------------------*
*       Bild für Verkaufssparameter festlegen
*----------------------------------------------------------------------*
*  -->  p_s_general
*  <--  SCREEN
*----------------------------------------------------------------------*
FORM set_screen_sell_0830
  USING
    p_s_general  LIKE  g_s_0830_general.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0830_GENERAL-VABME'
        OR 'G_S_0830_GENERAL-BSTRF'
        OR 'G_0830_BSTRFQTUNIT'
        OR 'MDR1INSINGLEROUND-VABME'
        OR 'MDR1INSINGLEROUND-BSTRF'
        OR 'MDR1OUTSINGLEROUND-MEINS'.

*                *** Einkaufsparameter werden nicht angezeigt
        screen-active = 0.

      WHEN 'G_0830_DEFQTUNIT_NAME'.

*                *** Beim Verkauf ist die Default-ME die Verkaufs-ME
        g_0830_defqtunit_name = text-815. " = 'Verkaufs-ME'.


*                *** Beachte: Felder nur anzeigen, falls nicht initial.
*                *** Verkaufs-ME muß nicht geprüft werden, da diese
*                *** immer gefunden wird (mindestens mara-meins wird
*                *** gefunden)
      WHEN 'G_S_0830_GENERAL-VENUNITGR'
        OR 'MDR1INSINGLEROUND-VENUNITGR'.

        IF p_s_general-venunitgr IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-BUYUNITGR'
        OR 'MDR1INSINGLEROUND-BUYUNITGR'.

        IF p_s_general-buyunitgr IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-RDPRF'
        OR 'BUTTONDETAILRDPRF'
        OR 'MDR1INSINGLEROUND-RDPRF'.

        IF p_s_general-rdprf IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_0830_MAXQT'
        OR 'MDR1INSINGLEROUND-MAXQT'.

        IF p_s_general-maxqt IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_0830_MINQT'
        OR 'MDR1INSINGLEROUND-MINQT'.

        IF p_s_general-minqt IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-MAMIQTUNIT'
        OR 'MDR1INSINGLEROUND-MAMIQTUNIT'
        OR 'G_S_0830_GENERAL-MAMIUMREZ'
        OR 'G_S_0830_GENERAL-MAMIUMREN'
        OR 'MDR1INSINGLEROUND-MAMIUMREZ'
        OR 'MDR1INSINGLEROUND-MAMIUMREN'.

*                *** Falls es keine Min-Max-Grenzen gibt, nicht anzeigen
        IF  p_s_general-minqt IS INITIAL
        AND p_s_general-maxqt IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-SCMNG'
        OR 'MDR1INSINGLEROUND-SCMNG'
        OR 'G_S_0830_GENERAL-SCHME'
        OR 'MDR1INSINGLEROUND-SCHME'
        OR 'G_S_0830_GENERAL-SCHMEUMREZ'
        OR 'MDR1INSINGLEROUND-SCHMEUMREZ'
        OR 'G_S_0830_GENERAL-SCHMEUMREN'
        OR 'MDR1INSINGLEROUND-SCHMEUMREN'.

        IF p_s_general-scmng IS INITIAL.

          screen-active = 0.

        ENDIF.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_sell_0830

*&---------------------------------------------------------------------*
*&      Form  set_screen_change_0830
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_s_general
*  <--  SCREEN    je nach OPCODE gestzt!
*----------------------------------------------------------------------*
FORM set_screen_change_0830
  USING
    p_s_general   LIKE  g_s_0830_general.

*                *** Verzweige je nach opcode
  CASE p_s_general-opcode.

    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_additionals.

      PERFORM set_screen_pur_change_0830   USING p_s_general.

    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung.

      PERFORM set_screen_sell_change_0830  USING p_s_general.

  ENDCASE.

ENDFORM.                    " set_screen_change_0830

*&---------------------------------------------------------------------*
*&      Form  set_screen_pur_change_0830
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_s_general
*  <--  SCREEN    je nach OPCODE gestzt!
*----------------------------------------------------------------------*
FORM set_screen_pur_change_0830
  USING
    p_s_general   LIKE  g_s_0830_general.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0830_GENERAL-VAVME'
        OR 'G_S_0830_GENERAL-SCMNG'
        OR 'G_S_0830_GENERAL-SCHME'
        OR 'G_S_0830_GENERAL-SCHMEUMREZ'
        OR 'G_S_0830_GENERAL-SCHMEUMREN'
        OR 'MDR1INSINGLEROUND-VAVME'
        OR 'MDR1INSINGLEROUND-SCMNG'
        OR 'MDR1INSINGLEROUND-SCHME'
        OR 'MDR1INSINGLEROUND-SCHMEUMREZ'
        OR 'MDR1INSINGLEROUND-SCHMEUMREN'.

*                *** Verkaufsparameter nicht sichtbar
        screen-active = 0.

      WHEN 'G_0830_DEFQTUNIT_NAME'.

*                *** Beim Eikauf ist die Default-ME die Bestell-ME
        g_0830_defqtunit_name =  text-814. "= 'Bestell-ME'.

      WHEN 'BUTTONDETAILRDPRF'.
*                *** Detail-Button für Rundungsprofil nur anzeigen,
*                *** falls Feld einen Wert enthält
        IF p_s_general-rdprf IS INITIAL.

          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0830_GENERAL-DEFQTUNIT'
        OR 'G_S_0830_GENERAL-VENUNITGR'
        OR 'G_S_0830_GENERAL-BUYUNITGR'
        OR 'G_S_0830_GENERAL-RDPRF'
        OR 'G_0830_MAXQT'
        OR 'G_0830_MINQT'
        OR 'G_S_0830_GENERAL-MAMIQTUNIT'
        OR 'G_S_0830_GENERAL-BSTRF'
        OR 'G_S_0830_GENERAL-VABME'.

*                *** Felder sind nun eingabebereit (außer Umrechnungs-
*                *** faktoren)
        screen-input = 1.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_pur_change_0830

*&---------------------------------------------------------------------*
*&      Form  set_screen_sell_change_0830
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_s_general
*  <--  SCREEN
*----------------------------------------------------------------------*
FORM set_screen_sell_change_0830
  USING
    p_s_general  LIKE  g_s_0830_general.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0830_GENERAL-VABME'
        OR 'G_S_0830_GENERAL-BSTRF'
        OR 'G_0830_BSTRFQTUNIT'
        OR 'MDR1INSINGLEROUND-VABME'
        OR 'MDR1INSINGLEROUND-BSTRF'
        OR 'MDR1OUTSINGLEROUND-MEINS'.

*                *** Einkaufsparameter werden nicht angezeigt
        screen-active = 0.

      WHEN 'G_0830_DEFQTUNIT_NAME'.

*                *** Beim Verkauf ist die Default-ME die Verkaufs-ME
        g_0830_defqtunit_name = text-815. " = 'Verkaufs-ME'.

      WHEN 'G_S_0830_GENERAL-DEFQTUNIT'
        OR 'G_S_0830_GENERAL-VENUNITGR'
        OR 'G_S_0830_GENERAL-BUYUNITGR'
        OR 'G_S_0830_GENERAL-RDPRF'
        OR 'G_0830_MAXQT'
        OR 'G_0830_MINQT'
        OR 'G_S_0830_GENERAL-MAMIQTUNIT'
        OR 'G_S_0830_GENERAL-SCMNG'
        OR 'G_S_0830_GENERAL-SCHME'
        OR 'G_S_0830_GENERAL-VAVME'.
*                *** Felder sind nun eingabebereit (außer Umrechnungs-
*                *** faktoren)
        screen-input = 1.

      WHEN 'BUTTONDETAILRDPRF'.

*                *** Nur anzeigen, falls Feld einen Wert enthält
        IF p_s_general-rdprf IS INITIAL.

          screen-active = 0.

        ENDIF.


    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_sell_change_0830

*&---------------------------------------------------------------------*
*&      Form  show_allowed_qt_units
*&---------------------------------------------------------------------*
*       Die erlaubten log. ME  zu einem Artikel anzeigen
*----------------------------------------------------------------------*
*  -->  p_s_general
*----------------------------------------------------------------------*
FORM show_allowed_qt_units
  TABLES
    p_t_qt_units  TYPE mdr1toutallowedqtunit
  USING
    p_s_general   TYPE mdr1insingleround.

  DATA: l_s_qt_units TYPE mdr1outallowedqtunit.

*                *** Festlegen der erlaubten log. ME
  CLEAR: g_t_allowed_qt_units[],
         g_t_allowed_qt_units.

  LOOP AT p_t_qt_units
     INTO l_s_qt_units
    WHERE flagallqtunit = c_yes.

    APPEND l_s_qt_units
        TO g_t_allowed_qt_units.

  ENDLOOP.

*                *** Lege zunächst das Layout des ALV fest
  PERFORM set_layout_alv_all_qt_units
    USING
      p_s_general
    CHANGING
      g_s_layout_alv.

*                *** Generiere den Feldkatalog und passe ihn auf
*                *** die Bedürfnisse an.
  PERFORM mask_columns_all_qt_units
    CHANGING
      g_t_fieldcatalog.

*                *** Zeiger auf die Datentabelle setzen
  GET REFERENCE OF g_t_allowed_qt_units
              INTO g_ref_to_table_alv_0850.

*                *** Rufe das Anzeigedynpro auf
  CALL SCREEN 0850
    STARTING AT 40 01.

ENDFORM.                    " show_allowed_qt_units

*&---------------------------------------------------------------------*
*&      Form  toggle_modus_dynpro_0830
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  <->  p_mode_dynpro
*----------------------------------------------------------------------*
FORM toggle_modus_dynpro_0830
  CHANGING
    p_mode_dynpro  LIKE  g_0830_mode_dynpro.

*                *** Verändere den Schalter. Wird beim Module
*                *** 'modify_screen_0830' berücksichtigt.
  CASE p_mode_dynpro.

    WHEN c_0830_change_mode.

      p_mode_dynpro = c_0830_show_mode.

    WHEN c_0830_show_mode.

      p_mode_dynpro = c_0830_change_mode.

  ENDCASE.

ENDFORM.                    " toggle_modus_dynpro_0830

*&---------------------------------------------------------------------*
*&      Form  check_material_unit_2
*&---------------------------------------------------------------------*
*       Teste, ob eine eingegebene ME eine gültige ME ist, und wenn ja,
*       übernehme die Umrechnungsfaktoren.
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS  alle gültigen ME
*      -->P_QTUNIT      zu Prüfende ME
*      <--FEHLER-Meldung, wenn nicht gültig
*      <->p_umrez  Variable, der der Umrechnungszähler zugewiesen wird
*      <->p_umren  Variable, der der Umrechnungsnenner zugewiesen wird
*----------------------------------------------------------------------*
FORM check_material_unit_2
  TABLES
    p_t_qt_units   TYPE  mdr1toutallowedqtunit
  USING
    p_qtunit       LIKE  mara-meins
  CHANGING
    p_umrez  LIKE mdr1outallowedqtunit-umrez
    p_umren  LIKE mdr1outallowedqtunit-umren.

*                *** work-area
  DATA l_wa_mdr1outallowedqtunit LIKE mdr1outallowedqtunit.

  READ TABLE   p_t_qt_units
    WITH KEY   meinh = p_qtunit INTO l_wa_mdr1outallowedqtunit.

  IF sy-subrc <> 0.
*                *** Fehlermeldung:Die Mengeneinheit existiert nicht zu
*                ***               dem Material
    MESSAGE e059.

  ELSE.

*                *** ME ist erlaubt => übernehme die
*                *** Umrechnungsfaktoren
    p_umrez = l_wa_mdr1outallowedqtunit-umrez.
    p_umren = l_wa_mdr1outallowedqtunit-umren.

  ENDIF.

ENDFORM.                    " check_material_unit_2

*&---------------------------------------------------------------------*
*&      Form  call_f4_help_qtunit
*&---------------------------------------------------------------------*
*       F4-Eingabehilfe für die auswahl einer gültigen ME
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS
*      -->P_S_GENERAL
*      -->p_dynprfield
*----------------------------------------------------------------------*
FORM call_f4_help_qtunit
  TABLES
    p_t_qt_units  TYPE  mdr1toutallowedqtunit
  USING
    p_s_general   TYPE  mdr1insingleround
    p_dynprofield TYPE  help_info-dynprofld.

  DATA:
    BEGIN OF  value_tab  OCCURS 0,
      meinh          LIKE  marm-meinh,
      umrez          TYPE  mdr1convnum,
      umren          TYPE  mdr1convden,
      flagdefqtunit  TYPE  mdr1defqtunit,  " Kennzeichen für DefME
      flagvenqtunit  TYPE  mdr1venqtunit,  " Kennzeichen für LiefME
      flagbuyqtunit  TYPE  mdr1buyqtunit,  " Kennzeichen für AbnME
      flagallqtunit  TYPE  mdr1allqtunit,
    END OF    value_tab,
    l_dynpprog            LIKE  sy-repid,
    l_dynpnr              LIKE  sy-dynnr,
    l_stepl               LIKE  help_info-stepl,
    l_display             LIKE  ddrefstruc-bool,
    l_window_titel(100)   TYPE  c .

  l_dynpprog = sy-repid.
  l_dynpnr   = sy-dynnr.
  l_display  = c_no.

*                *** Fülle die F4-Werte mit den bestimmten Werten,
*                *** die angezeigt werden sollen
  LOOP AT p_t_qt_units.

    MOVE-CORRESPONDING p_t_qt_units TO value_tab.

    APPEND value_tab.

  ENDLOOP.

*                *** Überschrift in der F4-Hilfe:
  l_window_titel = text-008.

  CLEAR: sy-msgid.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
*           DDIC_STRUCTURE   = ' '
            retfield         = 'MEINH' " Feldname der Rückgabe
*           PVALKEY          = ' '
            dynpprog         = l_dynpprog
            dynpnr           = l_dynpnr
            dynprofield      = p_dynprofield
            stepl            = l_stepl
            window_title     = l_window_titel
*           VALUE            = ' '
            value_org        = 'S'
*           MULTIPLE_CHOICE  = ' '
            display          = l_display
*           CALLBACK_PROGRAM = ' '
*           CALLBACK_FORM    = ' '
       TABLES
            value_tab        = value_tab
*           FIELD_TAB        =
*           RETURN_TAB       =
*           DYNPFLD_MAPPING  =
       EXCEPTIONS
            parameter_error  = 1
            no_values_found  = 2
            error_message    = 98      " Ausnahme bei Meldungen
            OTHERS           = 99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
*                *** Immer nur I-Messages im Dialog-Modus
      sy-msgty  =  c_msgty_i.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE i001(rpugen) WITH 'F4IF_INT_TABLE_VALUE_REQUEST'
                           RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                    " call_f4_help_qtunit

*&---------------------------------------------------------------------*
*&      Form  set_screen_show_0840
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_GENERAL
*----------------------------------------------------------------------*
FORM set_screen_show_0840
  USING
    p_s_general   LIKE  g_s_0840_general.

*                *** Verzweige je nach opcode
  CASE p_s_general-opcode.

    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_additionals.

      PERFORM set_screen_pur_0840   USING  p_s_general.

    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung.

      PERFORM set_screen_sell_0840  USING  p_s_general.

  ENDCASE.

ENDFORM.                    " set_screen_show_0840

*&---------------------------------------------------------------------*
*&      Form  set_screen_pur_0840
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_s_general
*  <--  SCREEN
*----------------------------------------------------------------------*
FORM set_screen_pur_0840
  USING
    p_s_general  LIKE  g_s_0840_general.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0840_GENERAL-RLEAVE'
        OR 'MDR1INSINGLEROUND-RLEAVE'.

*                *** Kundenauftragsfeld nicht anzeigen
        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_pur_0840

*&---------------------------------------------------------------------*
*&      Form  set_screen_sell_0840
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_GENERAL
*----------------------------------------------------------------------*
FORM set_screen_sell_0840
  USING
    p_s_general  LIKE  g_s_0840_general.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0840_GENERAL-RLEAVE'
        OR 'MDR1INSINGLEROUND-RLEAVE'.

        IF p_s_general-opcode = mdr1p_c_op_sd_lieferung.
*                *** Kundenauftragsfeld bei der Lieferung nicht
*                *** anzeigen!
          screen-active = 0.

        ENDIF.

      WHEN 'G_S_0840_GENERAL-PURPAR'
        OR 'MDR1INSINGLEROUND-PURPAR'.

*                *** Einkaufsfeld nicht anzeigen!
        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_sell_0840

*&---------------------------------------------------------------------*
*&      Form  set_screen_change_0840
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_GENERAL
*----------------------------------------------------------------------*
FORM set_screen_change_0840
  USING
    p_s_general   LIKE  g_s_0840_general.

*                *** Verzweige je nach opcode
  CASE p_s_general-opcode.

    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_additionals.

      PERFORM set_screen_pur_change_0840   USING p_s_general.

    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung.

      PERFORM set_screen_sell_change_0840  USING p_s_general.

  ENDCASE.

ENDFORM.                    " set_screen_change_0840

*&---------------------------------------------------------------------*
*&      Form  set_screen_pur_change_0840
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_GENERAL
*----------------------------------------------------------------------*
FORM set_screen_pur_change_0840
  USING
    p_s_general  LIKE  g_s_0840_general.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0840_GENERAL-RLEAVE'
        OR 'MDR1INSINGLEROUND-RLEAVE'.

*                *** Kundenauftragsfeld nicht anzeigen
        screen-active = 0.

      WHEN 'G_S_0840_GENERAL-RVALU'
        OR 'G_S_0840_GENERAL-RDYNA'
        OR 'G_S_0840_GENERAL-RSTAT'
        OR 'G_S_0840_GENERAL-RMAMI'
        OR 'G_S_0840_GENERAL-RCHALUM'
        OR 'G_S_0840_GENERAL-RVALDEC'
        OR 'G_S_0840_GENERAL-PURPAR'
        OR 'G_S_0840_GENERAL-RAUFAB'.

*                *** Felder sind nun eingabebereit (außer Umrechnungs-
*                *** faktoren)
        screen-input = 1.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_pur_change_0840

*&---------------------------------------------------------------------*
*&      Form  set_screen_sell_change_0840
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_GENERAL
*----------------------------------------------------------------------*
FORM set_screen_sell_change_0840
  USING
    p_s_general  LIKE  g_s_0840_general.

  LOOP AT SCREEN.

    CASE screen-name.

      WHEN 'G_S_0840_GENERAL-RLEAVE'
        OR 'MDR1INSINGLEROUND-RLEAVE'.

        IF p_s_general-opcode = mdr1p_c_op_sd_lieferung.
*                *** Kundenauftragsfeld bei der Lieferung nicht
*                *** anzeigen!
          screen-active = 0.

        ELSE.
*                *** Feld ist beim Kundenauftrag eingabebereit
          screen-input = 1.

        ENDIF.

      WHEN 'G_S_0840_GENERAL-PURPAR'
        OR 'MDR1INSINGLEROUND-PURPAR'.

*                *** Einkaufsfeld nicht anzeigen!
        screen-active = 0.

      WHEN 'G_S_0840_GENERAL-RVALU'
        OR 'G_S_0840_GENERAL-RDYNA'
        OR 'G_S_0840_GENERAL-RSTAT'
        OR 'G_S_0840_GENERAL-RMAMI'
        OR 'G_S_0840_GENERAL-RCHALUM'
        OR 'G_S_0840_GENERAL-RVALDEC'
        OR 'G_S_0840_GENERAL-RAUFAB'.

*                *** Felder sind nun eingabebereit (außer Umrechnungs-
*                *** faktoren)
        screen-input = 1.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.                    " set_screen_sell_change_0840

*&---------------------------------------------------------------------*
*&      Form  toggle_modus_dynpro_0840
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <->P_MODE_DYNPRO
*----------------------------------------------------------------------*
FORM toggle_modus_dynpro_0840
  CHANGING
    p_mode_dynpro  LIKE  g_0840_mode_dynpro.

*                *** Verändere den Schalter. Wird beim Module
*                *** 'modify_screen_0840' berücksichtigt.
  CASE p_mode_dynpro.

    WHEN c_0840_change_mode.

      p_mode_dynpro = c_0840_show_mode.

    WHEN c_0840_show_mode.

      p_mode_dynpro = c_0840_change_mode.

  ENDCASE.

ENDFORM.                    " toggle_modus_dynpro_0840
*&---------------------------------------------------------------------*
*&      Form  recompute_allowed_qt_units
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_GENERAL  text
*      <--P_T_ALLOWED_QT_UNITS  text
*----------------------------------------------------------------------*
FORM recompute_allowed_qt_units
  USING
    p_s_general TYPE mdr1insingleround
  CHANGING
    p_t_allowed_qt_units TYPE mdr1toutallowedqtunit.

  DATA: l_s_input TYPE mdr1inallowedqtunit,
        l_s_mara LIKE mara.

  CLEAR p_t_allowed_qt_units.

*                *** Dieses Feld muß gefüllt werden, damit der Baustein
*                *** nicht mit der Fehlermeldung: "Fehlende Rundungs-
*                *** parameter" abbricht, wird aber ansonsten für
*                *** nichts benötigt! (Es ist also egal mit welchem
*                *** Wert das Feld belegt wird)
  l_s_mara-meins = p_s_general-defqtunit.

*                ***    - Eingabestruktur für den FB: MD_ALLOWED_QT_UNIT
*                ***      belegen:
*                ***      -> mit den Daten aus der Eingabestruktur
  MOVE-CORRESPONDING p_s_general  TO  l_s_input.

*                ***      -> Festlegung der Unternehmenssicht abhängig
*                ***         vom OPCODE:
  CASE p_s_general-opcode.

*                ***         EK-OPCodes => EK-Sicht
    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_lb.

      l_s_input-appview  = mdr1p_c_appview_purchase.

*                ***         VK-OPCode => VK-Sicht
    WHEN mdr1p_c_op_sd_auftrag
      OR mdr1p_c_op_sd_lieferung
      OR mdr1p_c_op_sd_verf.

      l_s_input-appview  = mdr1p_c_appview_sale.

  ENDCASE.

*                *** Bei der Bestimmung der erlaubten log. ME muß der
*                *** Baustein mit der kompletten Funkt. aufgerufen
*                *** werden!!!
  l_s_input-flagallqtunit  =  c_yes.
  l_s_input-flagdefqtunit  =  c_yes.
  l_s_input-flagvenqtunit  =  c_yes.
  l_s_input-flagbuyqtunit  =  c_yes.

  CALL FUNCTION 'MD_ALLOWED_QUANTITY_UNIT'
    EXPORTING
      i_s_general        = l_s_input
      i_s_mara           = l_s_mara
*       I_S_EINA           =
*       I_S_EINE           =
*       I_S_MARC           =
*       I_S_MARC_2         =
*       I_S_MVKE           =
*       I_S_KNMT           =
*       I_S_KNVV           =
    TABLES
      o_t_qt_units       = p_t_allowed_qt_units
   EXCEPTIONS
     bad_params         = 1
     error              = 2
     OTHERS             = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " recompute_allowed_qt_units
*&---------------------------------------------------------------------*
*&      Form  f4_help_qt_units_matnr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p_dynprofield  Der Name der ME, auf die sich der Aufruf bezieht
*----------------------------------------------------------------------*
FORM f4_help_qt_units_matnr
  USING
    p_dynprofield     TYPE  help_info-dynprofld
    p_s_general       TYPE  mdr1insingleround
    p_matnr_fieldname TYPE  dynpread-fieldname
  CHANGING
    p_t_qt_units      TYPE  mdr1toutallowedqtunit.

  DATA: l_dynpprog TYPE sy-repid,
        l_dynpnr   TYPE sy-dynnr,
        l_matnr    LIKE mara-matnr,

*                *** Deklaration von Variablen, die dem Funktions-
*                *** baustein 'DYNP_VALUES_READ' übergeben werden.
    l_s_dynpread         TYPE          dynpread,
    l_t_dynpread         TYPE TABLE OF dynpread.
  DATA: l_matnr1   LIKE mara-matnr.                  " note 1623804
  l_dynpprog = sy-repid.
  l_dynpnr = sy-dynnr.

*                *** Der Inhalt des Dynprofeldes p_matnr_fieldname
*                *** soll in das namensgleiche ABAP-Datenfeld
*                *** transportiert werden.
  l_s_dynpread-fieldname = p_matnr_fieldname.

  APPEND l_s_dynpread
      TO l_t_dynpread.

*                *** Der Aufruf dieses Funktionsbausteins ist nötig, da
*                *** zum Zeitpunkt 'PROCESS ON VALUE REQUEST' der Dynpro
*                *** -Ablauflogik KEINE Daten vom Dynpro zu den ABAP-
*                *** Datenfeldern transportiert werden, unsere F4-Hilfe
*                *** aber von dem Inhalt des Dynprofeldes
*                *** p_matnr_fieldname
*                *** abhängig sein soll, d.h. nur falls in diesem Feld
*                *** ein Artikel eingegeben wurde, kann die F4-Hilfe
*                *** angezeigt werden, da sonst die erlaubten ME's nicht
*                *** bestimmt werden können.
  CLEAR: sy-subrc,
         sy-msgid.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname                         = l_dynpprog
      dynumb                         = l_dynpnr
      translate_to_upper             = c_yes
*     REQUEST                        = ' '
*     PERFORM_CONVERSION_EXITS       = ' '
*     PERFORM_INPUT_CONVERSION       = ' '
*     DETERMINE_LOOP_INDEX           = ' '
    TABLES
      dynpfields                     = l_t_dynpread
    EXCEPTIONS
      invalid_abapworkarea           = 1
      invalid_dynprofield            = 2
      invalid_dynproname             = 3
      invalid_dynpronummer           = 4
      invalid_request                = 5
      no_fielddescription            = 6
      invalid_parameter              = 7
      undefind_error                 = 8
      double_conversion              = 9
      stepl_not_found                = 10
      error_message                  = 98
      OTHERS                         = 99
            .
  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e001(rpugen) WITH 'DYNP_VALUES_READ'
                           RAISING error.
    ENDIF.

  ENDIF.

*                *** Lese den Inhalt des Dynprofeldes
*                *** p_matnr_fieldname.
*                *** Tabelle hat nur eine Zeile, da nur der Inhalt
*                *** EINES Dynprofeldes gelesen wurde.
  READ TABLE l_t_dynpread
       INDEX 1
        INTO l_s_dynpread.

  l_matnr = l_s_dynpread-fieldvalue.


*                *** Falls das Dynprofeld 'MARA-MATNR' leer
*                *** ist, können die Werte der F4-Hilfe nicht
*                *** berechnet werden. => KEINE F4-Hilfe!!
  IF NOT ( l_matnr IS INITIAL ).
* Begin note 1623804
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        INPUT              =  l_matnr
      IMPORTING
        OUTPUT             =  l_matnr1.
    l_matnr = l_matnr1.
* End note 1623804
    IF g_s_0401_mara-meins IS INITIAL.

*                *** Lese die Basismengeneinheit zu dem Material aus
*                *** MARA => Plausi auch als Match-Code fuer Eingabe-
*                *** feld moeglich.
      PERFORM read_mara_single_online
                  USING
                      l_matnr
                  CHANGING
                      g_s_0401_mara.

    ENDIF.

    PERFORM find_valid_material_units
                TABLES
                   p_t_qt_units
                USING
                   g_s_0401_mara-matnr
                   g_s_0401_mara-meins.

    PERFORM call_f4_help_qtunit
                TABLES
                   p_t_qt_units
                USING
                   p_s_general
                   p_dynprofield.

  ENDIF.

ENDFORM.                    " f4_help_qt_units_matnr

*&---------------------------------------------------------------------*
*&      Form  call_dynpro_0820
*&---------------------------------------------------------------------*
*       Bei direkten Aufruf in der Anwendung, immer direkt in die
*       Anwendungssimulation gehen
*----------------------------------------------------------------------*
*      -->P_S_GENERAL
*----------------------------------------------------------------------*
FORM call_dynpro_0820
  USING
    p_s_general  TYPE  mdr1insingleround.

*                *** Belege die globale Schnittstelle des Dynpros
*                *** 0820
*                *** - Initialisiere alle globale Felder des Dynpros
  CLEAR: g_0820_matnr_name,
         g_0820_werks_name,
         g_0820_vkorg_name,
         g_0820_vtweg_name,
         g_0820_kunnr_name,
         g_0820_spart_name,
         g_0820_lifnr_name,
         g_0820_ekorg_name,
         g_0820_pstyp_name,
         g_0820_werks_kred_name,
         g_0820_single_value,
         g_0820_rounded_value,
         g_0820_value_umrech,
         g_0820_meinh_umrech,
         g_s_0820_general,
         g_s_0820_results.

*                *** Steuerungsstruktur belegen:
  g_s_0820_general = p_s_general.

*                *** Vorbelegung der Eingabefelder des Eingabedynpros
  g_0820_light            =  c_red.
  g_0820_control_initial  =  c_yes.
  g_0820_rounding_initial =  c_yes.

*                *** Defaultdaten und Daten aus der Aufrufstelle
*                *** in die Struktur g_s_0820_general eintragen
*                *** - Default Eingabewert
  g_0820_single_value  =  c_default_single_value.

  IF g_s_0820_general-opcode = mdr1p_c_op_sd_lieferung.
*                *** - Bei Lieferung muß das Kennzeichen 'Infosatz'
*                ***   berücksichtigen immer gesetzt sein.
    g_s_0820_general-infls = c_yes.

  ELSE.
*                *** - Sonst ist der Default nicht gesetzt:
    g_s_0820_general-infls = c_no.

  ENDIF.
*                *** Transaktionscode aus der aufrufenden Anwendung
*                *** berücksichtigen
  IF g_s_0820_general-tcode IS INITIAL.
    g_s_0820_general-tcode   =  sy-tcode.
  ENDIF.
*                *** - Gültiges Customizing zur ausgewählten
*                ***   Anwendung (opcode) und Transaktion (tcode)
*                ***   lesen und eintragen!
  PERFORM call_customizing_read CHANGING g_s_0820_general.

*                *** gelesenes Customizing in der Struktur merken,
*                *** die benutzt wird,um festzustellen,ob der Benutzer
*                *** das Profil geändert hat.
  MOVE-CORRESPONDING g_s_0820_general TO g_s_0820_rcpr_init.

*                *** Vor Dynpro-Aufruf, Aufrufstelle als Aufruf aus
*                *** FB d.h., nicht über Dynpro 0800 kennzeichen
  g_0820_no_0800_call = c_yes.

  CALL SCREEN 0820
  STARTING AT 40 01.

ENDFORM.                    " call_dynpro_0820

*
* 
