*-------------------------------------------------------------------
***INCLUDE LMDR1F03 .
*-------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.08.97  400 welterm      Grundversion für Aufruf in der
*-                                  Pflege von Rundungsprofile
*-                                  (Prog.: SAPL0WCL, Transaktion: OWD1)
*- @001  20.01.97  40B welterm      Ausgabe der gerundeten Mengenein-
*-                                  mit Dezimalstellen
*- @002  15.04.98  40C welterm      Erweiterungen zu 40c:
*-                                  - Fehler bei der Belegung der
*-                                    globalen Variablen für den Aufruf
*-                                    von Rundung
*-                                  - auch nicht dynamische Rundungs-
*-                                    profile werden berücksichtigt
*-                                  - Bei der Simulation muss noch das
*-                                    Dezimalstellen-Runden beachtet
*-                                    werden
*-                                  - Ausgabe einer neuen Zeile beim
*-                                    Wechsel der log. Mengeneinheit
*- @008  27.08.99  99A kast         Erweiterung der Simulation um eine
*-                                  Schrittweite
*- @009  17.09.01  470 mbi          Realisierung SMAD-Punkte
*-                                  - Verbesserung der Rundungs-
*-                                    Simulation:
*-                                    Ersetzung von altem Coding durch
*-                                    neues.
*-                                    (Marke: #mbi 4.70 RoundSimu )
*-       01.01.02  470 mwe          Altes Coding auskommentiert
*-                                  (ohne Änderungsmarke)
*-----------------------------------------------------------------------

**&---------------------------------------------------------------------
*
**&      Form  SIM_CHECK_PARAMS
**&---------------------------------------------------------------------
*
**       Je nach Aufrufstelle (= OpCode) werden die entsprechenden
**       Eingabeparameter auf Korrektheit überprüft
**----------------------------------------------------------------------
*
*FORM sim_check_params.
*
*  CASE g_u03-u02-i_opcode.
** ???    when c_op_mm_normal            " Aufruf bei Norm al
** ???    when c_op_mm_ub.               " Aufruf bei Umlieferung
** ???    when c_op_sd_auftrag           " Aufruf bei Auftrag
** ???    when c_op_sd_lieferung.        " Aufruf bei Lieferung
** ???    when c_op_sd_verf.             " Aufruf bei ???
*    WHEN mdr1p_c_op_maintain_rdpf.     " Aufruf bei Pflege Profil = '6'
*
**                *** Bei dem Aufruf bei der Pflege der Rundungsprofile
**                *** muessen die folgenden Parameter gefuellt sein
**                *** (Pflichtparameter):
**                ***    - i_werk   (Default: SPACES => keine Plausi)
**                ***    - i_rdpr   (Rundungsprofil)
**                ***    - i_rdprf  (Rundungsprofil-Bezeichner)
*      IF    g_u03-u02-i_rdprf  IS  INITIAL
*         OR g_u03-u02-i_rdpr   IS  INITIAL.
*        RAISE bad_params.
*      ENDIF.
*
**                *** Der Profil-Eintrag (i_rpdr) muss mit dem Profil-
**                *** Bezeichner und dem Werk uebereinstimmen!
*      IF    g_u03-u02-i_rdpr-rdprf  <>  g_u03-u02-i_rdprf
*         OR g_u03-u02-i_rdpr-werks  <>  g_u03-u02-i_werk.
*        RAISE bad_profil.
*      ENDIF.
*
**$@002 Anfang
**$*                *** Im ersten Schritt werden nur dynamische Rundungs
**$*                *** Profile berücksichtigt!
**$      IF g_u03-u02-i_rdpr-rdmpo = c_rdmpo_abs. " absolut runden = ' '
**$        RAISE no_dyn_profil.
**$      ENDIF.
**$@002 Ende
*
*    WHEN OTHERS.
*
*      RAISE invalid_opcode.
*
*  ENDCASE.
*
*ENDFORM.                               " SIM_CHECK_PARAMS
*
**&---------------------------------------------------------------------
*
**&      Form  SIM_MAINTAIN_RDPF
**&---------------------------------------------------------------------
*
**       Fuehre die Simulation eines Rungsprofils beim Aufruf in
**       der Pflege von Rundungsprofilen (Prog SAPL0WCL, Transaktion
**       OWD1) durch.
**----------------------------------------------------------------------
*
*FORM sim_maintain_rdpf.
*
**                *** Vorbelegung der Ausgabefelder des Dynpros
**                *** mit den belegten Importparametern (Plausi
**                *** erfolgte in sim_check_param).
*  rdpr         =  g_u03-u02-i_rdpr.    " Def. Rundungsprofil
*  rdtx-text40  =  g_u03-i_text40.      " Name des Rundungsprofils
*  t001w-name1  =  g_u03-i_name1.       " Name des Werks
*
**$@009 mbi 4.70 RoundSimu - Anfang
***                *** Alte Version ohne ALV-Technik und Simulation von
***                *** Einzelwerten
**
***                *** Vorbelegung der Eingabefelder des Eingabedynpros
**  g_0400_in_from_amount  =  c_0400_in_from_amount.
**  g_0400_in_to_amount    =  c_0400_in_to_amount.
**
***                *** Vorbelegung der Schrittweite im Eingabedynpro
**  g_0400_in_step         =  c_0400_in_step.                 " @008
**
**
***                *** Aufruf des Eingabe-Dynpros, in dem eine weitere
***                *** Verzweigung in das Ausgabe-Dynpro (Ausgabe der
***                *** simulierten Werten) erfolgt.
**  CALL SCREEN 0400
**       STARTING AT 2 13.
**                *** Initialisiere Dynpro 0401
*  PERFORM initialization_0401.
*
*  g_0401_rdprf    =  rdpr-rdprf.
*  g_0401_werks    =  rdpr-werks.
**                *** Zur Sicherheit auch das Ausgabe-Feld für das Werk
**                *** korrekt belegen.
*  g_0401_werks    =  g_u03-u02-i_werk.
**                *** Aufruf des neuen Eingabedynpros 401
*  CALL SCREEN 0401
*       STARTING AT 2 13.
**$@009 mbi 4.70 RoundSimu - Ende
*
*ENDFORM.                               " SIM_PFLEGE_RDPF
*
**&---------------------------------------------------------------------
*
**&      Form  OUTPUT_SIM_RDPR
**&---------------------------------------------------------------------
*
**       Ausgabe der Simulation eines Rundungsprofils
**       (Eingabe-Werte            -> DynPro 400
**        Ausgabe-Werte (gerundet) -> DynPro 600
**----------------------------------------------------------------------
*
**      -->P_RDPR   Definition des Rundungsprofils aus demEingabeDynPro*
**      -->P_MATNR  Materialnummer aus dem EingabeDynPro
*
**      -->P_MEINH  Mengeneinheit aus dem  EingabeDynPro
*
**      -->P_MEINS  Basis-Mengeneinheit des Materials
*
**      -->P_BSTME  Bestellmengeneinheit
*
**      -->P_FROM_AMOUNT  Eingabe Von-Menge
*
**      -->P_TO_AMOUNT    Eingabe Bis-Menge
*
**----------------------------------------------------------------------
*
**      @008  Erweiterung der Schnittstelle für die Schrittweite:
*
**      -->P_STEP   Schrittweite
*
**----------------------------------------------------------------------
*
*FORM output_sim_rdpr USING     value(p_rdpr)         LIKE  rdpr
*                               value(p_matnr)        LIKE  mara-matnr
*                               value(p_meinh)        LIKE  marm-meinh
*                               value(p_meins)        LIKE  mara-meins
*                               value(p_bstme)        LIKE  mara-bstme
*                               value(p_from_amount)  LIKE  rdpr-vormg
*                               value(p_to_amount)    LIKE  rdpr-vormg
**                     *** Übergabe der Schrittweite               "@008
*                               value(p_step)         LIKE  rdpr-vormg.
*
*  DATA:  l_current_amount        LIKE  rdpr-vormg,
*         l_current_round_amount  LIKE  rdpr-vormg,
*         l_befor_round_amount    LIKE  rdpr-vormg,
*         l_befor_lamount         LIKE  rdpr-vormg,
*         l_befor_logunit         LIKE  marm-meinh,
*         l_out_from_amount       LIKE  rdpr-vormg,
*         l_out_to_amount         LIKE  rdpr-vormg,
*         l_current_lamount       LIKE  rdpr-vormg,
*         l_current_logunit       LIKE  marm-meinh,
*         l_step                  LIKE  rdpr-vormg.          " @008
*
*  l_step = p_step.                                          " @008
*
**                *** Belege den ersten Wert, der gerundet werden soll,
**                *** mit der unteren Intervall-Grenze!
*  l_current_amount  =  p_from_amount.
**                *** Da noch kein Wert gerundet wurde, wird der vor-
**                *** herige gerundete Werte mit dem Default-Wert -1
**                *** initialisiert!
*  l_befor_round_amount  =  -1.
*
**                *** Ausgabe der Spalten-Ueberschriften:
*  WRITE:   /02 text-600, '[' NO-GAP, marm-meinh CENTERED NO-GAP, ']',
*            16 text-601, '[' NO-GAP, marm-meinh CENTERED NO-GAP, ']',
*            29 text-602, '[' NO-GAP, marm-meinh CENTERED NO-GAP, ']',
*            45 text-603,
*            60 text-604.
*  SKIP.
*
**                *** Bestimme alle Rundungswerte zu den Werten des
**                *** Intervalls und gebe sie aus.
**                *** Schleife wird mindestens einmal durchlaufen, da
**                *** beim Eintritt der Schleife gilt:
**                *** l_current_amount = p_from_amount <= p_to_amount
*  WHILE l_current_amount  <=  p_to_amount.
*
**                *** 1. Bestimme zu dem aktuellen Wert den Rundungswert
*    PERFORM compute_round_amount  USING     p_rdpr
*                                            p_matnr
*                                            p_meinh
*                                            p_meins
*                                            p_bstme
*                                            l_current_amount
*                                  CHANGING  l_current_round_amount
*                                            l_current_logunit
*                                            l_current_lamount.
*
**                *** 2. Ausgabe des Rundungswerts, wenn folgendes gilt:
**                ***    a) der aktuelle Rundungswert stimmt nicht mit
**                ***       letzten Rundungswert ueberein
**                ***       (diese Bedingung ist fuer den ersten
**                ***        Schleifendurchlauf immer erfüllt)
**                ***    b) die logistische Mengeneinheit hat sich
**                ***       geändert
*    IF    l_current_round_amount  <>  l_befor_round_amount
*       OR l_befor_logunit         <>  l_current_logunit.    " @002
**                ***    und
**                ***    c) der aktuelle Rundungswert bezieht sich nicht
**                ***       auf den ersten Wert des Intervalls.
*      IF l_current_amount  > p_from_amount.
**                *** Ausgabe der Zeile zum letzten Rundungswert:
**                *** - der Werte des Intervalls, die zu dem
**                ***   letzten Rundungswert gehören (in Eingabe-Mengen-
**                ***   einheit)
**                *** - letzter Rundungswert (in Eingabe-Mengeneinheit)
**                *** - logistischer Rundungswert zum letzten Rundungs-
**                ***   wert (in logistische Mengeneinheit)
**                *** - logistische Mengeneinheit zum letzten Rundungs-
**                ***   wert
*
**                       *** Erweiterung um Schrittweite           "@008
**$@008        l_out_to_amount = l_current_amount - 1.
*        l_out_to_amount = l_current_amount - l_step.
*
**$@002 Anfang
**$        WRITE: /1(8) l_out_from_amount
**$               RIGHT-JUSTIFIED DECIMALS 0 EXPONENT 0.
**$        WRITE: 15(8) l_out_to_amount
**$               RIGHT-JUSTIFIED DECIMALS 0 EXPONENT 0.
**$        WRITE: 31(12) l_befor_round_amount                     " @001
**$               RIGHT-JUSTIFIED            EXPONENT 0.          " @001
**$        WRITE: 51(8) l_befor_lamount
**$               RIGHT-JUSTIFIED DECIMALS 0 EXPONENT 0.
*        WRITE: /1(8) l_out_from_amount
*               RIGHT-JUSTIFIED UNIT marm-meinh.
*        WRITE: 15(8) l_out_to_amount
*               RIGHT-JUSTIFIED UNIT marm-meinh.
*        WRITE: 31(12) l_befor_round_amount
*               RIGHT-JUSTIFIED UNIT marm-meinh.
*        WRITE: 51(8) l_befor_lamount
*               RIGHT-JUSTIFIED UNIT l_befor_logunit.
**$@002 Ende
*        WRITE: 60(3) l_befor_logunit
*               RIGHT-JUSTIFIED.
*
*      ENDIF.
**                *** 3. Bei einem Wechsel des Rundungswerts:
**                ***    muss die Von-Menge für die nächste Ausgabezeile
**                ***    belegt werden (die l_out_from_amount ist bei
**                ***    dem ersten Wert des Intervalls noch nicht
**                ***    belegt, jedoch wird zu diesem Wert in demersten
**                ***    Schleifenducrhlauf noch keine Zeile ausgegeben)
*      l_out_from_amount  =  l_current_amount.
*    ENDIF.
*
**                *** 4. Naechster Wert des Intervalls, der gerundetwird
**                       *** @008 naechster Wert des Intervallserrechnet
**                       ***      sich aus dem vorherigen Wert und der
**                       ***      Schrittweite.
*
**$@008    l_current_amount = l_current_amount + 1.
*    l_current_amount = l_current_amount + l_step.           " @008
*
**                *** 5. Gerundeter Wert als letzter Rundungswert
**                ***    für den naechsten Schleifendurchlauf merken.
*    l_befor_round_amount = l_current_round_amount.
*    l_befor_lamount      = l_current_lamount.
*    l_befor_logunit      = l_current_logunit.
*
*  ENDWHILE.
*
**                *** Ausgabe der letzten Zeile fuer den letzten
**                *** Schleifendurchlauf
*  l_out_to_amount = p_to_amount.
*
**$@002 Anfang
**$  WRITE: /1(8) l_out_from_amount
**$         RIGHT-JUSTIFIED DECIMALS 0 EXPONENT 0.
**$  WRITE: 15(8) l_out_to_amount
**$         RIGHT-JUSTIFIED DECIMALS 0 EXPONENT 0.
**$  WRITE: 31(12) l_befor_round_amount                           " @001
**$         RIGHT-JUSTIFIED            EXPONENT 0.                " @001
**$  WRITE: 51(8) l_befor_lamount
**$         RIGHT-JUSTIFIED DECIMALS 0 EXPONENT 0.
*  WRITE: /1(8) l_out_from_amount
*         RIGHT-JUSTIFIED UNIT marm-meinh.
*  WRITE: 15(8) l_out_to_amount
*         RIGHT-JUSTIFIED UNIT marm-meinh.
*  WRITE: 31(12) l_befor_round_amount
*         RIGHT-JUSTIFIED UNIT marm-meinh.
*  WRITE: 51(8) l_befor_lamount
*         RIGHT-JUSTIFIED UNIT l_befor_logunit.
**$@002 Ende
*
*  WRITE: 60(3) l_befor_logunit
*         RIGHT-JUSTIFIED.
*
*ENDFORM.                               " OUTPUT_SIM_RDPR
*
**&---------------------------------------------------------------------
*
**&      Form  COMPUTE_ROUND_AMOUNT
**&---------------------------------------------------------------------
*
**       Je nach OPCODE des FKB wird der aktuelle Wert des Eingabe-
**       Intervalls gerundet.
**----------------------------------------------------------------------
*
**      -->P_RDPR   Definition des Rundungsprofils aus demEingabeDynPro*
**      -->P_MATNR  Materialnummer aus dem EingabeDynPro
*
**      -->P_MEINH  Mengeneinheit aus dem  EingabeDynPro
*
**      -->P_MEINS  Basis-Mengeneinheit des Materials
*
**      -->P_BSTME  Bestellmengeneinheit
*
**      -->P_AMOUNT Eingabemenge aus dem Intervall
*
**      <--R_ROUND  Rundungsmenge zu der Eingabemenge (nur Rückgabe)
*
**      <--R_ROUND  logistische Mengeneinheit         (nur Rückgabe)
*
**      <--R_ROUND  Rundungsmenge zu der Eingabemenge (nur Rückgabe)
*
**----------------------------------------------------------------------
*
*
*FORM compute_round_amount USING    value(p_rdpr)    LIKE  rdpr
*                                   value(p_matnr)   LIKE  mara-matnr
*                                   value(p_meinh)   LIKE  marm-meinh
*                                   value(p_meins)   LIKE  mara-meins
*                                   value(p_bstme)   LIKE  mara-bstme
*                                   value(p_amount)  LIKE  rdpr-vormg
*                         CHANGING  value(r_round)   LIKE  rdpr-vormg
*                                   value(r_logunit) LIKE  marm-meinh
*                                   value(r_lamount) LIKE  rdpr-vormg.
*
**                *** Je nach OPCODE muessen verschiedene Aktionen zur
**                *** Rundung durchgeführt werden.
**                *** Wichtig: Zur eigentlichen Rundung wird immer
**                ***          das Unterprogram RUNDE benutzt.
*  CASE g_u03-u02-i_opcode.
** ???    when c_op_mm_normal            " Simulation bei Normal
** ???      or c_op_mm_ub.               "           oder Umlieferung
** ???    when c_op_sd_auftrag           " Simulation bei Auftrag
** ???      or c_op_sd_lieferung.        "           oder Lieferung
** ???    when c_op_sd_verf.             " Simulation bei ???
*    WHEN mdr1p_c_op_maintain_rdpf.     " Simulation bei Pflege Profil
*
*      PERFORM round_maintain_rdpf USING     p_rdpr
*                                            p_matnr
*                                            p_meinh
*                                            p_meins
*                                            p_bstme
*                                            p_amount
*                                  CHANGING  r_round
*                                            r_logunit
*                                            r_lamount.
*    WHEN OTHERS.
*
*      RAISE invalid_opcode.
*
*  ENDCASE.
*
*ENDFORM.                               " COMPUTE_ROUND_AMOUNT
*
**&---------------------------------------------------------------------
*
**&      Form  ROUND_MAINTAIN_RDPF
**&---------------------------------------------------------------------
*
**       Bestimme den Rundungswert zu dem aktuellen Wert des Eingabe-
**       Intervalls zur Simulation bei der Pflege eines Rundungsprofils.
**
**----------------------------------------------------------------------
*
**      -->P_RDPR   Definition des Rundungsprofils aus demEingabeDynPro*
**      -->P_MATNR  Materialnummer aus dem EingabeDynPro
*
**      -->P_MEINH  Mengeneinheit aus dem  EingabeDynPro
*
**      -->P_MEINS  Basis-Mengeneinheit des Materials
*
**      -->P_BSTME  Bestellmengeneinheit
*
**      -->P_AMOUNT Eingabemenge aus dem Intervall
*
**      <--R_ROUND  Rundungsmenge zu der Eingabemenge (nur Rückgabe)
*
**      <--R_ROUND  logistische Mengeneinheit         (nur Rückgabe)
*
**      <--R_ROUND  Rundungsmenge zu der Eingabemenge (nur Rückgabe)
*
**----------------------------------------------------------------------
*
*
*FORM round_maintain_rdpf USING     value(p_rdpr)    LIKE  rdpr
*                                   value(p_matnr)   LIKE  mara-matnr
*                                   value(p_meinh)   LIKE  marm-meinh
*                                   value(p_meins)   LIKE  mara-meins
*                                   value(p_bstme)   LIKE  mara-bstme
*                                   value(p_amount)  LIKE  rdpr-vormg
*                         CHANGING  value(r_round)   LIKE  rdpr-vormg
*                                   value(r_logunit) LIKE  marm-meinh
*                                   value(r_lamount) LIKE  rdpr-vormg.
**$@009 mbi 4.70 RoundSimu - Anfang
**$  DATA:  l_chkmeli   LIKE  rdpr-chkmeli,
**$         l_chkmeku   LIKE  rdpr-chkmeku.
**$*                *** Initialisierung der globalen Datenstruktur g_u0,
**$*                *** da diese in dem Unterprogram RUNDE benutzt wird.
**$  CLEAR g_u02.
**$*                *** Belege alle wichtigen globalen Variablen des
**$*                *** Unterprogramms RUNDE
**$*                *** 1. Belegung vom Rundungsprofil und Werk
**$*                ***    (Beides wird vor dem CALL von 0400 belegt)
**$*$@002  g_u02-i_rdpr-rdprf        =  p_rdpr-rdprf.
**$  g_u02-i_rdprf             =  p_rdpr-rdprf.                " @002
**$  g_u02-i_werk              =  p_rdpr-werks.
**$  g_u02-i_rdpr              =  p_rdpr.
**$*                *** 2. Default-Wert fuer den Rundungswert (=
**$aktueller
**$*                ***    Wert des Intervalls) und der logistischen
**$*                ***    Mengeneinheit (= Eingabemengeneinheit bei
**$0400)
**$  g_u02-e_menge             =  p_amount.
**$  g_u02-e_logme             =  p_meinh.
**$  g_u02-e_lmenge            =  p_amount.
**$*                *** 3. Mengeneinheit des Eingabe/Rundungs-Wertes und
**$*                ***    Materialnummer
**$*                ***    (Beides wird bei der Eingabe von DynPro 0400
**$*                ***     belegt)
**$  g_u02-i_menge             =  p_amount.                    " @002
**$  g_u02-i_meins             =  p_meinh.
**$  g_u02-i_matnr             =  p_matnr.
**$  mara-matnr                =  p_matnr.
**$*                *** 4. Bestimme die Basismengeneinheit MARA-MEINSzum
**$*                ***    eingegebenen Material (Parameter p_meins)
**$  mara-meins = p_meins.
**$*                *** 5. Wichtig: Bei dieser Rundung werden
**$*                ***    a) keine Max- und Min-Mengenberücksichtigt!!!
**$  g_u02-i_no_min_max_check  =  c_charx .
**$*                ***    b) keine Erlaubnisprüfung der Mengeneinheit
**$*                ***       für den Lieferant und den Kunden durch-
**$*                ***       führen!!!
**$  l_chkmeli  =  p_rdpr-chkmeli.        " lokale Sicherung der
**$  l_chkmeku  =  p_rdpr-chkmeku.        " aktuellen Werte
**$  CLEAR g_u02-i_rdpr-chkmeli.          " Ausschaltung der Prüfung
**$(rdpr
**$  CLEAR g_u02-i_rdpr-chkmeku.          " wird in RUNDE mit
**$g_u02-i_rdpr
**$  " ueberschrieben
**$*                *** Aufruf des Rundungs-Unterprogramms RUNDE
**$  PERFORM runde USING    p_rdpr-rdprf  " Rundungsprofil
**$                         0             " kein Max-Wert
**$                         0             " kein Min-Wert
**$                         0             " kein Rundungswert
**$                         p_bstme.      " eingegebene Bestell-ME
**$*                *** Herstellen der aktuellen Werte in RDPR-Struktur
**$  rdpr-chkmeli = l_chkmeli.           " jetzt die RDPR direkt
**$ansprechen
**$  rdpr-chkmeku = l_chkmeku.            " da nach RUND hier die Werte
**$von
**$  " g_u02-i_rdpr stehen.
**$*$@002 Anfang
**$*                *** die Ausgabemengen (gerundet) dürfen nur zur
**$*                *** Mengeneinheit gültige NAchkommastelle besitzen
**$  PERFORM  falid_output_for_units USING g_u02.
**$*$@002 Ende
**$*                *** Rückgabewert mit den globalen Werten aus RUND
**$*                *** belegen.
**$  r_round    =  g_u02-e_menge.
**$  r_logunit  =  g_u02-e_logme.
**$  r_lamount  =  g_u02-e_lmenge.
*
*
*  DATA: l_t_qt_units TYPE mdr1p_t_out_allowed_qt_unit,
*        l_t_round_reasons TYPE mdr1p_t_rundungsgrund,
*        l_s_general TYPE mdr1p_s_in_single_round,
*        l_s_results TYPE mdr1p_s_out_single_round,
*
** Arbeitsbereiche
*  l_wa_qt_units TYPE mdr1p_s_out_allowed_qt_unit.
*
**                *** finde zunächst die gültigen Materialeinheiten
**                *** heraus
*  PERFORM find_valid_material_units
*              TABLES
*                 l_t_qt_units
*              USING
*                 p_matnr
*                 p_meins.
*
**                *** fülle die lokalen Strukturen mit den Daten, die in
**                *** der Routine rounding_profil benötigt werden. Die
**                *** Tabelle "l_t_round_reasons" bleibt dabei leer.
*  l_s_general-meinh = p_meinh.  "Eingabe-ME
*  l_s_general-menge = p_amount. "Eingabemenge = Eingabemenge Intervall
*  l_s_general-matnr = p_matnr.  "Materialnummer
*  l_s_general-werks = p_rdpr-werks.
*
*  l_s_results-meins = p_meins.  "Basis-ME
*
*  READ TABLE l_t_qt_units WITH KEY meinh = p_bstme INTO l_wa_qt_units.
*
*  l_s_general-defqtunit = l_wa_qt_units-meinh.
*  l_s_general-defumrez = l_wa_qt_units-umrez.
*  l_s_general-defumren = l_wa_qt_units-umren.
*  l_s_general-rdprf = p_rdpr-rdprf.
*
*  l_s_results-defqtunit = l_wa_qt_units-meinh.
*  l_s_results-defumrez  = l_wa_qt_units-umrez.
*  l_s_results-defumren = l_wa_qt_units-umren.
*  l_s_results-rdprf = p_rdpr-rdprf.
*
*  PERFORM rounding_profil
*              TABLES
*                 l_t_qt_units
*                 l_t_round_reasons
*              USING
*                 l_s_general
*              CHANGING
*                 l_s_results.
*
**                *** nach der Rundung befindet sich dasrundungsergebnis
**                *** in:
**                ***   p_s_results-roundqt: Rundungsmenge in ME:rqtunit
**                ***   p_s_results-rqtunit: Rundungs-ME
**                *** wenn gerundet wurde!!!
*  IF NOT ( l_s_results-roundqt IS INITIAL )
*  OR NOT ( l_s_results-rqtunit IS INITIAL ).
**                *** Ergebnis in eigentliche Ausgabe-Felder Stellen
*    l_s_results-lmenge = l_s_results-roundqt.
*    l_s_results-logme  = l_s_results-rqtunit.
*  ENDIF.
*
*  IF l_s_results-logme = l_s_general-meinh.
**                *** - Eingabe-ME = Rundungs-ME => keine Umrechnung
*    l_s_results-menge = l_s_results-lmenge.
*  ELSE.
**                *** - Eingabe-ME <> Rundungs-ME => Umrechnung durchf.
*    PERFORM conv2unit_new  USING    l_s_general
*                                    l_s_results-lmenge
*                                    l_s_results-logme
*                                    l_s_general-meinh
*                           CHANGING l_s_results
*                                    l_s_results-menge.
*  ENDIF.
*
**                 *** die Ausgabemengen (gerundet) dürfen nur zur
**                 *** Mengeneinheit gültige Nachkommastellen besitzen
*  PERFORM check_allowed_dec
*              TABLES
*                 l_t_round_reasons
*              USING
*                 l_s_general
*              CHANGING
*                 l_s_results.
*
**                *** Rückgabewerte mit den Ergebnissen aus l_s_results
**                *** belegen
*  r_round = l_s_results-menge.
*  r_logunit = l_s_results-logme.
*  r_lamount = l_s_results-lmenge.
*
**$@009 mbi 4.70 RoundSimu - Ende
*
*ENDFORM.                               " ROUND_MAINTAIN_RDPF
*
*
**&---------------------------------------------------------------------
*
**&      Form  READ_SINGLE_MARM
**&---------------------------------------------------------------------
*
**       Lese den Eintrag in MARM zu der Materialnumer und der
**       Mengeneinheit.
**
**----------------------------------------------------------------------
*
**      -->P_MATNR  Materialnummer
*
**      -->P_MEINH  Mengeneinheit
*
**----------------------------------------------------------------------
*
*
*FORM read_single_marm USING     value(p_matnr)  LIKE  mara-matnr
*                                value(p_meinh)  LIKE  marm-meinh.
*
*  CALL FUNCTION 'MARM_SINGLE_READ'
*       EXPORTING
*            kzrfb      = c_yes             " Lese mit Puffer
*            maxtz      = c_max_buffer_size " maximal 10Puffer-Eintraege
*            matnr      = p_matnr
*            meinh      = p_meinh
**    IMPORTING                           " Es werden keine Daten ausdem
**         WMARM      =                   " FK-Baustein benötigt.
*       EXCEPTIONS
*            wrong_call = 1
*            not_found  = 2
*            OTHERS     = 3.
*
*ENDFORM.                    "read_single_marm
*
**&---------------------------------------------------------------------
*
**&      Form  READ_SINGLE_MAKT
**&---------------------------------------------------------------------
*
**       Lese den Eintrag in MAKT zu der Materialnumer zur Bestimmung
**       des Materialnamens.
**
**----------------------------------------------------------------------
*
**      -->P_MATNR  Materialnummer
*
**----------------------------------------------------------------------
*
*
*FORM read_single_makt USING     value(p_matnr)  LIKE  mara-matnr.
*
*  CALL FUNCTION 'MAKT_SINGLE_READ'
*    EXPORTING
*      kzrfb      = c_yes           " Pufferung benutzen
*      maxtz      = c_max_buffer_size  " max Anzahl der Puffer-Ein.
*      matnr      = p_matnr
*      spras      = sy-langu
*    IMPORTING
*      wmakt      = makt
*    EXCEPTIONS
*      wrong_call = 1
*      not_found  = 2
*      OTHERS     = 3.
*
*ENDFORM.                    "read_single_makt

*
* 
