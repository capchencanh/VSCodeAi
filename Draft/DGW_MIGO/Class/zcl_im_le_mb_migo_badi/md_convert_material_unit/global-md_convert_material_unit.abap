FUNCTION-POOL mdr1 MESSAGE-ID 6r.
*----------------------------------------------------------------------*
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @001  05.01.97  12b  schweizerm  Korrekturen zu Rel.1.2b
*- @002  07.08.97  400  mwe         Erweiterung wg neum Simulations-
*-                                  FKB 'MD_SIMU_DYN_RUND_PROFIL'.
*- @003  07.08.97  400  Doneyer     Bestimmen der Mengeneinheitengruppe
*                                   bei UB wenn PRUEFE-LIEFERANT
*                                   markiert ist und kein Einkaufsinfo-
*                                   satz vorhanden ist.
*- @004 27.10.97   400  mwe         Neuer Schalter für den Fall, dass
*-                                  keine Rundung auf Grund falscher
*-                                  Eingabeparameter durchgeführt wird.
*- @005 08.04.98   40c  mwe         Erweiterung der Rundung für 40C
*- @006 02.07.98   4.5A mwe         Erweiterung für das Runden im LB
*- @007 07.01.99   99A  mwe         Erweiterung der Rundung:
*-                                  - neuer fb zum prüfen der erlaubten
*-                                    ME
*-                                  - neuer FB für die Rundung
*- @008 27.08.99  99A  kast        Erweiterung der Simulation um eine
*-                                 Schrittweite
*- @009  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @010  27.06.01  470  mwe         Programmabruch wegen zu großen
*-                                  Umrechnungsfaktoren
*-                                  Korrektur zu Hinweis: 430276
*- @011  19.09.01  470  mbi         Realisierung SMAD-Punkte
*-                                  - Verbesserung der Rundungs-
*-                                    Simulation
*-                                    (Marke: #mbi 4.70 RoundSimu )
*- @012  25.10.01  470  hwi         Realisierung SMAD-Punkte
*-                                  - Customizing of logistical rounding
*-                 (Marke: HWI 4.70 customizing of logistical rounding)
*-       01.01.02  470  mwe         Nicht mehr benötige Variablen
*-                                  auskommentiert
*-                                  (ohne Änderungsmarken!)
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
*- Tabellen
*----------------------------------------------------------------------*
TABLES:
  eina,                                "Infosatz, allgemeine Daten
  eine,                                "Infosatz, EkOrg/Werk-Ebene
  kna1,                   "Kundenstamm                          " @001
  knmt,                   "Kunden-Material-Info Datentabelle
  knvv,                                "Kundenstamm Vertriebsdaten
  lfa1,                                "Lieferantenstamm
  makt,                                "Artikeltexte
  mara,                                "Artikelstamm, allgemein
  marc,                                "Artikelstamm, Werksebene
  marm,                                "Artikelmengeneinheiten
  mvke,                                "Materialstamm: Verkaufsdaten
  rdpr,                                "Rundungsprofil
  rdtx,                                "Rundungsprofiltexte
  t001w,                               "Werksstamm
  t006,                                "Maßeinheiten
  tvak,                                "Verkaufsbelege: Arten
  tw06s,                  "Retail: Mengeneinheitenrundungsregel
*@003-Begin
  tvkwz,
*@003-End
  twmeg.                               "Retail: Mengeneinheitengruppe

*$@011 #mbi 4.70 RoundSimu - Anfang
TABLES:
  tvkot,                  "Org.-Einheit: Verkaufsorganisationen: Texte
  tvkov,                  "Org.-Einheit: Verkaufsorganisationen
  tvtwt,                  "Org.-Einheit: Vertriebswege: Texte
  t024e,                  "Einkaufsorganisationen
  rctr,                   "neues Rundungs-Customizing
  tstc.                   "Transaktionen

*----------------------------------------------------------------------*
*- Controls
*----------------------------------------------------------------------*
DATA: g_custom_container_0850   TYPE REF TO  cl_gui_custom_container,
      g_alv_grid_0850           TYPE REF TO  cl_gui_alv_grid.
*$@011 #mbi 4.70 RoundSimu - Ende

*----------------------------------------------------------------------*
*- Typen
*----------------------------------------------------------------------*
TYPE-POOLS:
  mdr1p, slis.

** Definition einer Zeile des Mengeneinheiten-Cache
*TYPES: BEGIN OF y_mecacheline,
*         matnr LIKE marm-matnr,
*         meinh LIKE marm-meinh,
*         umrez TYPE mdr1p_p_16_dec_14,
*         umren TYPE mdr1p_p_16_dec_14,
*         addko LIKE t006-addko,
*      END OF y_mecacheline.

*$@011 #mbi 4.70 RoundSimu - Anfang
TYPES: BEGIN OF markup_discount_line_type,
          threshold_value LIKE rdpr-bdmng,
          percentage LIKE rdpr-vormg,
          up,
          down,
        END OF markup_discount_line_type.
*$@011 #mbi 4.70 RoundSimu - Ende

*----------------------------------------------------------------------*
*- Konstanten
*----------------------------------------------------------------------*
CONSTANTS:
* allgemeine Konstanten:
*  c_ja       TYPE c VALUE 'X',
*  c_nein     TYPE c VALUE ' ',
  c_char1    TYPE c VALUE '1',         "ist 'ne eins!
*  c_charx    TYPE c VALUE 'X',

  c_yes      TYPE c VALUE 'X',                              " @007
  c_no       TYPE c VALUE ' ',                              " @007
  c_msr_var  TYPE c VALUE 'A',              " note 3024359
*  c_epsilon  TYPE mdr1p_p_16_dec_14 VALUE '0.001',"für float Vergleich
                                                            " @001

* Vorzeichen für Dynpro 0111
  c_positiv  TYPE c VALUE ' ',
  c_negativ  TYPE c VALUE '-',

* Dynpro-Nummern:
  c_dynpro_erfassung(4) TYPE c VALUE '0100',
  c_dynpro_f4_amounts(4)   TYPE c VALUE '0111',

* GUI-Stati:
  c_status_erfassung(5)  TYPE c VALUE 'S0100',
  c_status_f4_amounts(5) TYPE c VALUE 'S0111',

* GUI-Titel:
  c_title_erfassung(3)   TYPE c VALUE '100',

* Funktionscodes:
  c_fc_refd(4)           TYPE c VALUE 'REFD',
  c_fc_rund(4)           TYPE c VALUE 'RUND',
  c_fc_best(4)           TYPE c VALUE 'BEST',
  c_fc_info(4)           TYPE c VALUE 'INFO',
  c_fc_nextpage(2)       TYPE c VALUE 'P+',
  c_fc_prevpage(2)       TYPE c VALUE 'P-',
  c_fc_firstpage(3)      TYPE c VALUE 'P--',
  c_fc_lastpage(3)       TYPE c VALUE 'P++',
  c_fc_exit(4)           TYPE c VALUE 'EXIT',
  c_fc_back(4)           TYPE c VALUE 'BACK',
  c_fc_canc(4)           TYPE c VALUE 'CANC',
  c_fc_cont(4)           TYPE c VALUE 'CONT',
  c_fc_simu(4)           TYPE c VALUE 'SIMU',               " @005
*$@011 #mbi 4.70 RoundSimu - Anfang
  c_fc_exec_range(9)     TYPE c VALUE 'EXECRANGE',
  c_fc_exec_value(15)    TYPE c VALUE 'EXECSINGLEVALUE',
  c_fc_detailrdprf(11)   TYPE c VALUE 'DETAILRDPRF',
  c_fc_toggle(6)         TYPE c VALUE 'TOGGLE',
  c_fc_take(4)           TYPE c VALUE 'TAKE',
  c_fc_undo(4)           TYPE c VALUE 'UNDO',
*$@011 #mbi 4.70 RoundSimu - Ende

* Konstanten für Funktionsaufrufe                               " @002
*  c_max_buffer_size      LIKE mtcom-maxtz  VALUE 10,        " @002

* OpCode von md_einzelrundung
*        und md_simu_dyn_rund_profil:                           " @002
* => alte Konstanten sollten nicht mehr genutzt werden, die neuen
*    beginnen mit mdr1p_... (danach identisch) und befinden sich in
*    der Type-Gruppe MDR1P
*  c_op_mm_normal         TYPE c VALUE '1',
*  c_op_sd_auftrag        TYPE c VALUE '2',
*  c_op_sd_lieferung      TYPE c VALUE '3',
*  c_op_mm_ub             TYPE c VALUE '4',
*  c_op_sd_verf           TYPE c VALUE '5',
*  c_op_maintain_rdpf     TYPE c VALUE '6',                      " @002
*  c_op_additionals       TYPE c VALUE '7',                      " @005
*  c_op_lb                TYPE c VALUE 'L',                      " @007

* KEZI-Ausprägungen von RDPR-RDMPO:
  c_rdmpo_abs            TYPE c VALUE ' ',
  c_rdmpo_no             TYPE c VALUE '0',
  c_rdmpo_bstme          TYPE c VALUE '1',
  c_rdmpo_opt            TYPE c VALUE '2',
  c_rdmpo_opt_no_null    TYPE c VALUE '3',
  c_rdmpo_up_down        TYPE c VALUE '4',                  " @005

* Spezielle Artikeltypen
  c_attyp_variante(2)    TYPE c VALUE '02',

* Konstanten fuer Eingabefelder des DynPro 0400                 " @002
  c_0400_in_from_amount  TYPE mdr1p_p_16_dec_14 VALUE 1,    " @002
  c_0400_in_to_amount    TYPE mdr1p_p_16_dec_14 VALUE 100,  " @002
  c_0400_in_step         TYPE mdr1p_p_16_dec_14 VALUE 1.    " @008

*$@005 Anfang
* Konstanten für die F4-Hilfe von DynPro 0500
CONSTANTS :
  c_sy_notfound    LIKE sy-subrc VALUE '4'.
* Konstanten für den Steuerungscode von md_rdpr_simu
CONSTANTS:  c_buffer_refrech   TYPE c  VALUE '0',
            c_single_read      TYPE c  VALUE '1',
            c_read_all         TYPE c  VALUE '2'.
* spezieller Initialwert für die Runungsmethode rdpr-rdmpo, wegen
* Belegung von Spaces mit statischer Rundungsmethode
CONSTANTS:  c_rdmpo_init       LIKE rdpr-rdmpo VALUE 'X'.
*$@005 Ende

*$@007 Anfang
* Konstanten für die Anwendungssichtweisen
* => alte Konstanten sollten nicht mehr genutzt werden, die neuen
*    beginnen mit mdr1p_... (danach identisch) und befinden sich in
*    der Type-Gruppe MDR1P
*  c_appview_purchase   TYPE  mdr1appview  VALUE '01',
*  c_appview_sale       TYPE  mdr1appview  VALUE '02',
*  c_appview_customer   TYPE  mdr1appview  VALUE 'X1',

CONSTANTS:

* Konstanten für Liferant und Abnehmer
  c_vendor             TYPE  c            VALUE 'V',
  c_buyer              TYPE  c            VALUE 'B',

* Konstanten für interne und externe Lieferanten
  c_intvend            TYPE  c            VALUE 'I',
  c_extvend            TYPE  c            VALUE 'E',

* Konstanten für die Bestimmung der Umrechnungsfaktren über Baustein:
* '
  c_with_fm            TYPE  c            VALUE '1',
  c_without_fm         TYPE  c            VALUE '2',

* Konstanten für den Message-Typ
  c_msgty_i            LIKE  sy-msgty     VALUE 'I',
*$@011 #mbi 4.70 RoundSimu - Anfang
  c_msgty_e            LIKE  sy-msgty     VALUE 'E'.
*$@011 #mbi 4.70 RoundSimu - Ende

*$@007 Ende
*$@010 Anfang HW-430276-MWE
CONSTANTS:
  c_max_p_16_dec_14    TYPE  mdr1p_p_16_dec_14
                       VALUE '99999999999999999.99999999999999',
  c_10_exp_17          TYPE  f
                       VALUE '1.0E17'.
*$@010 Ende HW-430276-MWE
* Begin-of-Note-762408
CONSTANTS:
c_epsylon              TYPE f
                       VALUE '1.0E-13'.
* End-of-Note-762408

*$@011 #mbi 4.70 RoundSimu - Anfang
CONSTANTS:
*                *** Der Inhalt dieser Konstante gibt an, ob bzw. wie
*                *** Varianten des ALV-Grid-Control gespeichert werden
*                *** können. Bedeutung: c_save_alv =
*                *** ' ' => Kein Speichern von Layouts möglich
*                *** 'U' => Der Benutzer kann nur benutzerspezifische
*                *** Layouts speichern
*                *** 'X' => Der Benutzer kann nur übergreifende Layouts
*                *** speichern
*                *** 'A' => Der Benutzer kann sowohl benutzerspezifische
*                *** als auch übergreifende Layouts speichern
  c_save_alv             TYPE  c                  VALUE 'A',
*                *** Konstanten zur Schnittstelle des FB:
*                *** POPUP_TODECIDE
  c_answer_no_2          TYPE  c                  VALUE '2',
  c_answer_cancel_a      TYPE  c                  VALUE 'A',
*                *** Konstanten für alle Dynpros
  c_greenlight           LIKE  screen-name        VALUE 'GREENLIGHT',
  c_redlight             LIKE  screen-name        VALUE 'REDLIGHT',
  c_rdpr_rdrgl(10)       TYPE  c                  VALUE 'RDPR-RDRGL',
*                *** - Ampelsteurung
  c_red                  TYPE  c                        VALUE '0',
  c_green                TYPE  c                        VALUE '1',
*                *** - Defaultwerte für Eingabefelder
  c_default_single_value TYPE  mdr1p_p_16_dec_14        VALUE 1,
*                *** Konstanten fuer Dynpro 401
  c_pf_status_s0401(5)   TYPE  c                        VALUE 'S0401',
  c_titelbar_401(3)      TYPE  c                        VALUE '401',
  c_0401_group_gr1       LIKE  screen-group1            VALUE 'GR1',
  c_0401_group_gr2       LIKE  screen-group1            VALUE 'GR2',
  c_max_sim_num          TYPE  p                        VALUE 10000,
  c_mara_bstme(10)       TYPE  c           VALUE 'MARA-BSTME',
*                *** - Defaultwerte für Eingabefelder
  c_0401_in_from_amount  TYPE  mdr1p_p_16_dec_14        VALUE 1,
  c_0401_in_to_amount    TYPE  mdr1p_p_16_dec_14        VALUE 100,
  c_0401_in_step         TYPE  mdr1p_p_16_dec_14        VALUE 1,
*                *** Konstanten fuer Dynpro 800
  c_g_0800_no_appl(14)   TYPE  c           VALUE 'G_0800_NO_APPL',
  c_g_0800_with_appl(16) TYPE  c           VALUE 'G_0800_WITH_APPL',
  c_pf_status_s0800(5)   TYPE  c           VALUE 'S0800',
  c_titelbar_800(3)      TYPE  c           VALUE '800',
*                *** Konstanten fuer Dynpro 820
  c_pf_status_s0820(5)   TYPE  c           VALUE 'S0820',
  c_titelbar_820(3)      TYPE  c           VALUE '820',
  c_0820_rcont(5)        TYPE  c           VALUE 'RCONT',
  c_0820_rparam(6)       TYPE  c           VALUE 'RPARAM',
  c_0820_control_initial(15)   TYPE c      VALUE 'CONTROL_INITIAL',
  c_0820_rounding_initial(16)  TYPE c      VALUE 'ROUNDING_INITIAL',
*                *** Konstanten fuer Dynpro 830
  c_pf_status_s0830(5)   TYPE  c           VALUE 'S0830',
  c_titelbar_830(3)      TYPE  c           VALUE '830',
  c_0830_change_mode     TYPE  c           VALUE '0',
  c_0830_show_mode       TYPE  c           VALUE '1',
  c_0830_allqtunits(10)  TYPE  c           VALUE 'ALLQTUNITS',
  c_0830_detailrdprf(11) TYPE  c           VALUE 'DETAILRDPRF',
*                *** Konstanten fuer Dynpro 840
  c_pf_status_s0840(5)   TYPE  c           VALUE 'S0840',
  c_titelbar_840(3)      TYPE  c           VALUE '840',
  c_0840_change_mode     TYPE  c           VALUE '0',
  c_0840_show_mode       TYPE  c           VALUE '1',
*                *** Konstanten fuer Dynpro 845
  c_pf_status_s0845(5)   TYPE  c           VALUE 'S0845',
  c_titelbar_845(3)      TYPE  c           VALUE '845',
  c_0845_rdrgl(12)       TYPE  c           VALUE 'G_0845_RDRGL',
  c_0845_buttondetail(12) TYPE  c          VALUE 'BUTTONDETAIL',
  c_0845_buttonshow1(11) TYPE  c           VALUE 'BUTTONSHOW1',
  c_0845_buttonshow2(11) TYPE  c           VALUE 'BUTTONSHOW2',
  c_0845_chkmeli(14)     TYPE  c           VALUE 'G_0845_CHKMELI',
  c_0845_chkmeku(14)     TYPE  c           VALUE 'G_0845_CHKMEKU',
  c_0845_rdrgldetail(11) TYPE  c           VALUE 'RDRGLDETAIL',
  c_0845_show1(5)        TYPE  c           VALUE 'SHOW1',
  c_0845_show2(5)        TYPE  c           VALUE 'SHOW2',
*                *** Konstanten fuer Dynpro 850
  c_pf_status_s0850(5)   TYPE  c           VALUE 'S0850',
*                *** Konstanten für die ALV-Ausgabe:
*                *** - Selektionsmöglichkeiten
  c_sel_mode_d           TYPE  lvc_libox   VALUE 'D',
*                *** - Strukturnamen für den Feldkatalogaufbau
  c_structure_name_tw06s LIKE  dd02l-tabname   VALUE 'TW06S',
  c_structure_name_rdpr  LIKE  dd02l-tabname   VALUE 'RDPR',
  c_structure_name_alvsim  LIKE  dd02l-tabname
                           VALUE 'MDR1ALVSIMURUNDPROFIL',
*                *** - Feldnamen (= Spaltenamen)
  c_fieldname_mandt       TYPE  lvc_fname       VALUE 'MANDT',
  c_fieldname_rdrgl       TYPE  lvc_fname       VALUE 'RDRGL',
  c_fieldname_meins       TYPE  lvc_fname       VALUE 'MEINS',
  c_fieldname_swpauf      TYPE  lvc_fname       VALUE 'SWPAUF',
  c_fieldname_swpab       TYPE  lvc_fname       VALUE 'SWPAB',
  c_fieldname_werks_2     TYPE  lvc_fname       VALUE 'WERKS',
  c_fieldname_rdprf_2     TYPE  lvc_fname       VALUE 'RDPRF',
  c_fieldname_rdzae       TYPE  lvc_fname       VALUE 'RDZAE',
  c_fieldname_rdmpo       TYPE  lvc_fname       VALUE 'RDMPO',
  c_fieldname_chkmeli     TYPE  lvc_fname       VALUE 'CHKMELI',
  c_fieldname_chkmeku     TYPE  lvc_fname       VALUE 'CHKMEKU',
  c_fieldname_bdmng       TYPE  lvc_fname       VALUE 'BDMNG',
  c_fieldname_vormg       TYPE  lvc_fname       VALUE 'VORMG',
  c_fieldname_thersh      TYPE  lvc_fname       VALUE 'THRESHOLD_VALUE',
  c_fieldname_precentage  TYPE  lvc_fname       VALUE 'PERCENTAGE',
  c_fieldname_up          TYPE  lvc_fname       VALUE 'UP',
  c_fieldname_down        TYPE  lvc_fname       VALUE 'DOWN',
  c_fieldname_fromamount  TYPE  lvc_fname       VALUE 'FROMAMOUNT',
  c_fieldname_toamount    TYPE  lvc_fname       VALUE 'TOAMOUNT',
  c_fieldname_roundamount TYPE  lvc_fname       VALUE 'ROUNDAMOUNT',
  c_fieldname_inqtunit    TYPE  lvc_fname       VALUE 'INQTUNIT',
  c_fieldname_roundlogam  TYPE  lvc_fname       VALUE 'ROUNDLOGAMOUNT',
  c_fieldname_logqtunit   TYPE  lvc_fname       VALUE 'LOGQTUNIT',
*                *** - Farben für die Spalten
  c_emphsz_colour_c500    TYPE  lvc_emphsz      VALUE 'C500',
  c_emphsz_colour_c510    TYPE  lvc_emphsz      VALUE 'C510',



*                *** Konstanten fuer die Nutzung der Standard-Bausteine
*                *** bei den programmierten F4-Hilfen
  c_fieldname_rdprf      TYPE  dfies-fieldname          VALUE 'RDPRF',
  c_fieldname_werks      TYPE  dfies-fieldname          VALUE 'WERKS',
  c_dynprofield_werks    TYPE  help_info-dynprofld      VALUE 'WERKS',
  c_ddbool_s             TYPE  ddbool_d                 VALUE 'S',
  c_fldname_f0002        TYPE  dselc-fldname            VALUE 'F0002'.

*$@011 #mbi 4.70 RoundSimu - Ende

*$@012 HWI 4.70 customizing of logistical rounding B
CONSTANTS:
*                *** Konstanten für das neue Rundungs-Customizing
  c_purpar_default_0        TYPE  lumerrpurpar          VALUE '0',
*                *** Konstanten für die Anwendungen des Customizings
  c_rappl_sap_po_a          TYPE  lumerrappl            VALUE 'A',
  c_rappl_sap_stto_b        TYPE  lumerrappl            VALUE 'B',
  c_rappl_sap_so_c          TYPE  lumerrappl            VALUE 'C',
  c_rappl_sap_dl_d          TYPE  lumerrappl            VALUE 'D',
  c_rappl_sap_add_e         TYPE  lumerrappl            VALUE 'E',
  c_rappl_cust_po_za        TYPE  lumerrappl            VALUE 'ZA',
  c_rappl_cust_stto_zb      TYPE  lumerrappl            VALUE 'ZB',
  c_rappl_cust_so_zc        TYPE  lumerrappl            VALUE 'ZC',
  c_rappl_cust_dl_zd        TYPE  lumerrappl            VALUE 'ZD',
  c_rappl_cust_add_ze       TYPE  lumerrappl            VALUE 'ZE'.

*$@012 HWI 4.70 customizing of logistical rounding E

*----------------------------------------------------------------------*
*- globale Daten
*----------------------------------------------------------------------*

DATA:
ok_code       LIKE sy-ucomm,
save_ok_code  LIKE sy-ucomm,         "akt. OK-Code            " @002
g_fcode       LIKE sy-ucomm,         "akt. Funktionscode
*g_pagebegin   LIKE sy-tabix,         "Index erster Zeile in Anzeige
*g_index       LIKE sy-tabix,         "zum Array-Indizieren
*g_looplines   LIKE sy-loopc,         "akt. Anzahl step-loop Zeilen
g_retcode     LIKE sy-subrc,         "interner return-code

* Daten für Felder auf Dynpro 0400 (Eingabedynpro fuer die      " @002
* Simulation von Rundungsprofilen)                              " @002
g_0400_in_from_amount        LIKE  rdpr-vormg,              " @002
g_0400_in_to_amount          LIKE  rdpr-vormg,              " @002
g_0400_in_step               LIKE  rdpr-vormg,              " @008

* globaler Schalter fuer die Festlegung der Aufrufstellen von Unter-
* Programmen, die in beiden FKB md_einzelrun und md_simu_dyn_rund_profil
* benutzt werden.
g_call_place_up              TYPE  c,                       " @002

* globaler Schalter für das Ausschalten der Rundung bei unsinnigen
* Eingabewerten!
g_params_ok                  TYPE  c,                       " @004

g_lb_call                    TYPE  c,                       " @006
g_lb_change                  TYPE  c,                       " @006
g_lb_i_menge                 TYPE  mdr1p_p_16_dec_14,       " @006
g_lb_i_meins                 LIKE  marm-meinh,              " @006
g_t006_first_read            TYPE  c             VALUE c_yes," @007

*$@011 #mbi 4.70 RoundSimu - Anfang
*                *** Globaler Schalter zur Aktivierung der alten
*                *** Simulation, d.h.:
*                *** - Keine ALV-Ausgabe
*                *** - Keine Simulation von EInzelwerten
*                *** - Keine anendungsabhängige Simulationsmöglichkeit
*                *** Glonbales Hilfsfeld für FB POPUP_TO_DECIDE
g_answer                     TYPE  c,
*                *** globale Variablen, die für die F4-Hilfe des Dynpros
*                *** '0500' benötigt werden.
g_dynpprog                   TYPE  sy-repid,
g_dynpnr                     TYPE  sy-dynnr,

*                *** globale Variablen für Dynpro 0400: Eingabedynpro
*                *** für die Simulation von Rundungsprofilen
*                *** - Aufruf aus 0800
g_0401_call_from_0800        TYPE  c,
*                *** - Daten für Felder auf Dynpro 0401
g_0401_rdprf                 LIKE  rdpr-rdprf,
g_0401_werks                 LIKE  rdpr-werks,
g_0401_matnr                 LIKE  mara-matnr,
g_0401_bstme                 TYPE  mdr1_0401_bstme,
g_0401_meinh_input           TYPE  mdr1_0401_meinh,
g_0401_in_from_amount        TYPE  mdr1_0401_from_amount,
g_0401_in_to_amount          TYPE  mdr1_0401_to_amount,
g_0401_in_step               TYPE  mdr1_0401_step,
g_0401_single_value          TYPE  mdr1_0401_single_value,
g_0401_meinh                 TYPE  mdr1_0401_meinh,
g_0401_meinh_rounded         TYPE  mdr1_0401_meinh_rounded,
g_0401_rounded_value         TYPE  mdr1_0401_rounded_value,
g_0401_meinh_umrech          TYPE  mdr1_0401_meinh_umrech,
g_0401_value_umrech          TYPE  mdr1_0401_value_umrech,
g_0401_rdpr_werks_name       LIKE  t001w-name1,
g_0401_light                 TYPE  c,

*                *** Daten Auswahl und Eingabefelder des Dynpro 800
*                *** - Radio-Button-Auswahlfelder
g_0800_rdprf                 LIKE  rdpr-rdprf,
g_0800_werks                 LIKE  rdpr-werks,
g_0800_tcode                 LIKE  rctr-tcode,
g_0800_no_appl               TYPE  c,
g_0800_with_appl             TYPE  c,
g_0800_appl                  TYPE  lumerappl,

*                *** Daten Auswahl und Eingabefelder des Dynpro 820
g_0820_matnr_name            LIKE  makt-maktx,
g_0820_werks_name            LIKE  t001w-name1,
g_0820_vkorg_name            LIKE  tvkot-vtext,
g_0820_vtweg_name            LIKE  tvtwt-vtext,
g_0820_kunnr_name            LIKE  kna1-name1,
g_0820_spart_name            LIKE  tspat-vtext,
g_0820_lifnr_name            LIKE  lfa1-name1,
g_0820_ekorg_name            LIKE  t024e-ekotx,
g_0820_pstyp_name            LIKE  t163y-ptext,
g_0820_werks_kred_name       LIKE  t001w-name1,
g_0820_single_value          TYPE  mdr1_0820_single_value,
g_0820_rounded_value         TYPE  mdr1_0820_rounded_value,
g_0820_value_umrech          TYPE  mdr1_0820_value_umrech,
g_0820_meinh_umrech          TYPE  mdr1_0820_meinh_umrech,
g_0820_light                 TYPE  c,
g_0820_control_initial       TYPE  c,
g_0820_rounding_initial      TYPE  c,
g_0820_no_0800_call          TYPE  c,


*                *** Daten Auswahl und Eingabefelder des Dynpro 820
g_0830_defqtunit_name(40)    TYPE  c,
g_0830_bstrfqtunit           TYPE  meins,
g_0830_rdprf_werks           TYPE  werks_d,
g_0830_maxqt                 LIKE  marc-bstmi,
g_0830_minqt                 LIKE  marc-bstma,

*                *** globale Variable, die anzeigt, ob das Dynpro 0830
*                *** sich im Ändern- oder Anzeige-Modus befindet.
*                *** Siehe auch: Konstanten für Dynpro 0830.
g_0830_mode_dynpro           TYPE  c,

*                *** globale Variable, die anzeigt, ob das Dynpro 0840
*                *** sich im Ändern- oder Anzeige-Modus befindet.
*                *** Siehe auch: Konstanten für Dynpro 0840.
g_0840_mode_dynpro           TYPE  c,

*                *** Daten Auswahl und Eingabefelder des Dynpro 845
g_0845_werks                 LIKE  t001w-werks,
g_0845_werks_name            LIKE  t001w-name1,
g_0845_rdmpo                 LIKE  rdpr-rdmpo,
g_0845_rdrgl                 LIKE  rdpr-rdrgl,
g_0845_chkmeli               LIKE  rdpr-chkmeli,
g_0845_chkmeku               LIKE  rdpr-chkmeku,
g_0845_rdprf                 LIKE  rdpr-rdprf,
g_0845_rdprf_name            TYPE  rdtx-text40,
*$@011 #mbi 4.70 RoundSimu - Ende

*----------------------------------------------------------------------*
*- Strukturen
*----------------------------------------------------------------------*
* globale Daten von  'f4_bedarfsmenge_erfassen'
*               bzw. 'f4_order_quantity'
BEGIN OF g_u01,
  i_ekorg     LIKE eine-ekorg,
  kz_amenge   TYPE c,  "Kennung, daß g_list1-amenge geändert wurde
  kz_altme    TYPE c,                "                    -altme
  kz_restmng  TYPE c,                "                    -restmng
  lifnr       LIKE lfa1-lifnr,       "ext. oder interne LiefNr
  kz_ub       TYPE c,                "Kennung, ob Umlagerung
  kz_mesperre TYPE c,  "Kennung, daß ME nicht verändert werden darf
  meins    LIKE mara-meins,          "Wunsch-ME für F4-Hilfe merken
END OF g_u01,

* globale Daten von 'md_einzelrundung'
*$@005 Anfang
*$  BEGIN OF g_u02,
*$    i_opcode           TYPE c,
*$    i_matnr            LIKE mara-matnr,
*$    i_menge            TYPE f,
*$    i_meins            LIKE marm-meinh,
*$    i_werk             LIKE t001w-werks,
*$    i_lifnr            LIKE lfa1-lifnr,
*$    i_ekorg            LIKE eine-ekorg,
*$    i_infnr            LIKE eina-infnr,
*$    i_vkorg            LIKE knmt-vkorg,
*$    i_vtweg            LIKE knmt-vtweg,
*$    i_spart            LIKE knvv-spart,
*$    i_kunnr            LIKE knmt-kunnr,
*$    i_rdpr             LIKE rdpr,                               " @001
*$    i_no_min_max_check TYPE c,
*$    i_infls            LIKE tvak-infls,
*$    i_rdprf            LIKE mvke-rdprf,
*$    i_scmng            LIKE mvke-scmng,
*$    i_schme            LIKE mvke-schme,
*$    e_lmenge           TYPE f,                                  " @001
*$    e_logme            LIKE marm-meinh,
*$    e_menge            TYPE f,                                  " @001
*$    kzinfosatz         TYPE c,
*$    kz_is_werk         TYPE c,                                  " @001
*$    e_rdprf            LIKE mvke-rdprf,
*$    e_scmng            LIKE mvke-scmng,
*$    e_schme            LIKE mvke-schme,
*$  END OF g_u02,
*$  BEGIN OF g_u03,                                               " @002
*$    u02        LIKE  g_u02,                                     " @002
*$    i_text40   LIKE  rdtx-text40,                               " @002
*$    i_name1    LIKE  t001w-name1,                               " @002
*$  END OF g_u03.                                                 " @002
* globale Daten von 'md_einzelrundung'
g_u02         TYPE  mdr1p_in_md_einzelr,
* globale Daten von 'md_simu_dyn_rund_profil'
g_u03         TYPE  mdr1p_in_md_simu,
* globale Daten von 'md_rdpr_read'
g_u04         TYPE  mdr1p_in_md_rdpr," Eingabe-Parameter
g_last_rdprf  LIKE  rdpr-rdprf,      " Daten des letzten Aufrufs
g_last_werks  LIKE  rdpr-werks,
g_buffer_size TYPE  int4,
g_first_time  TYPE  c           VALUE 'X',
* globale Daten von 'md_rdtx_read'
g_u05              TYPE  mdr1p_in_md_rdtx,  " Eingabe-Parameter
g_last_rdtx_rdprf  LIKE  rdtx-rdprf, " Daten des letzten Aufruf
g_last_rdtx_werks  LIKE  rdtx-werks,
g_last_rdtx_spras  LIKE  rdtx-spras,
g_buffer_size_rdtx TYPE  int4,
g_first_time_rdtx  TYPE  c           VALUE 'X'.
*$@005 Ende

** Daten für Felder auf Dynpro 0100
*DATA: BEGIN OF g_box1,
*        werk     LIKE t001w-werks,
*        namewerk LIKE t001w-name1,
*        lief     LIKE lfa1-lifnr,
*        namelief LIKE lfa1-name1,
*        liwrk    LIKE t001w-werks,
*        nameliwk LIKE t001w-name1,
*        matnr    LIKE mara-matnr,
*        namemat  LIKE makt-maktx,
*        rdprf    LIKE marc-rdprf,
*        namerd   LIKE rdtx-text40,
*        lmenge   LIKE eban-menge,      "gerundete logist. Menge
*        logme    LIKE marm-meinh,      "logist. Mengeneinheit
*      END OF g_box1.

****** Daten für Felder auf Dynpro 0111:
* Hilfsstruktur zum Deaktivieren von Buttons ...
DATA: rt_extab TYPE slis_t_extab.
* ersetzt g_box1
DATA: BEGIN OF g_f4_data,
        werk     LIKE t001w-werks,
        namewerk LIKE t001w-name1,
        lief     LIKE lfa1-lifnr,
        namelief LIKE lfa1-name1,
        liwrk    LIKE t001w-werks,
        nameliwk LIKE t001w-name1,
        matnr    LIKE mara-matnr,
        namemat  LIKE makt-maktx,
        rdprf    LIKE marc-rdprf,
        namerd   LIKE rdtx-text40,
        bstme    LIKE mara-bstme,
        vabme    LIKE mara-vabme,
      END OF g_f4_data.

* ersetzt g_t_list1 ??
DATA: BEGIN OF g_f4_amounts,
        menge   LIKE eban-menge,       "Wunschmenge
        meins    LIKE mara-meins,
        bmenge   LIKE eban-menge,      "Menge in Bestell-ME
        bstme    LIKE mara-bstme,      "Bestell-ME
        restb    LIKE eban-menge,      "Restmenge immer in Basis-ME
        vorzb  TYPE c  VALUE ' ',      "Vorzeichen vom Rest zur bmenge
        lmenge   LIKE eban-menge,      "log. Menge nach Rundung
        logme    LIKE mara-bstme,      "Alternativ-ME nach Rundung
        restl    LIKE eban-menge,      "Restmenge in Basis-ME
        vorzl  TYPE c  VALUE ' ',      "Vorzeichen vom Rest zur bmenge
        basisme  LIKE mara-meins,      "BasisME
      END OF g_f4_amounts.

*$@005 Anfang
* Daten für die F4-Hilfe von DynPro 0500
DATA:  g_sy_subrc LIKE sy-subrc.
*$@005 Ende

*$@011 #mbi 4.70 RoundSimu - Anfang
*                *** Layout-Struktur zum Festlegen der Layout-
*                *** Eigenschaften des ALV-Grid-Controls
DATA: g_s_layout_alv        TYPE lvc_s_layo,
*                *** Struktur, die für das ALV-Grid-Control benötigt
*                *** wird, um Varianten zu laden
      g_s_variant_alv       TYPE disvariant,
*                *** Strukturen zu Dynpros 0111
      g_s_0111_general      TYPE mdr1insingleround,
*                *** Strukturen zu Dynpro 0401
      g_s_0401_general      TYPE mdr1insingleround,
      g_s_0401_makt         LIKE makt,
      g_s_0401_mara         LIKE mara,
*                *** Strukturen zu Dynpro 0820
      g_s_0820_general      TYPE mdr1insingleround,
      g_s_0820_general_init TYPE mdr1insingleround,
      g_s_0820_rcpr_tmp     TYPE rcpr,
      g_s_0820_rcpr_init    TYPE rcpr,
      g_s_0820_results      TYPE mdr1outsingleround,
*                *** Strukturen zu Dynpro 0830
      g_s_0830_general      TYPE mdr1insingleround,
      g_s_0830_results      TYPE mdr1outsingleround,
      g_s_0830_qt_units     TYPE mdr1outallowedqtunit,
*                *** Strukturen zu Dynpro 0840
      g_s_0840_general      TYPE mdr1insingleround,
      g_s_0840_results      TYPE mdr1outsingleround.
*$@011 #mbi 4.70 RoundSimu - Ende

*----------------------------------------------------------------------*
*- interne Tabellen
*----------------------------------------------------------------------*

*DATA: BEGIN OF g_t_list1 OCCURS 1,
*        menge    LIKE eban-menge,      "immer in Bestell-ME
*        amenge   LIKE eban-menge,      "in Alternativ-ME
*        bstme    LIKE mara-meins,      "Bestell-ME
*        altme    LIKE mara-bstme,      "Alternativ-ME
*        restmng  LIKE eban-menge,      "Restmenge in Bestell-ME
*      END OF g_t_list1.
*
*DATA: g_list1 LIKE LINE OF g_t_list1.
*
** Cache für die 10 zuletzt verwendeten Mengeneinheiten
*CONSTANTS: c_mecache_size TYPE i VALUE 10.
*DATA: g_t_mecache TYPE y_mecacheline OCCURS c_mecache_size
*                  WITH HEADER LINE.
* die zuletzt benutzte ME
*DATA: g_lru_me TYPE y_mecacheline.

* hier werden die aufgetretenen Rundungsgründe gesammelt;
* bei jedem Aufruf des Bausteins md_einzelrundung wird die Tabelle
* neu aufgebaut
DATA: g_t_grund TYPE mdr1p_t_rundungsgrund WITH HEADER LINE.

**@003-Begin
*TYPES: BEGIN OF type_vkorg_vtweg,
*          vkorg  LIKE mvke-vkorg,
*          vtweg  LIKE mvke-vtweg,
*       END   OF type_vkorg_vtweg.
*
*TYPES: tab_vkorg_vtweg TYPE type_vkorg_vtweg OCCURS 0.
*
*DATA:  g_t_vkorg_vtweg_vz TYPE tab_vkorg_vtweg WITH HEADER LINE.
*DATA:  g_t_vkorg_vtweg_fi TYPE tab_vkorg_vtweg WITH HEADER LINE.
**@003-END

*$@005 Anfang
** Tabellen für die F4-Hilfe des DynPros 0500
*DATA: get_felder LIKE dynpfld OCCURS 2 WITH HEADER LINE,
*      upd_felder LIKE dynpfld OCCURS 2 WITH HEADER LINE.

* Pufferungs-Tabelle des FB 'MD_RDPR_READ'
DATA: g_t_rdpr_buffer  LIKE  rdpr  OCCURS 0  WITH HEADER LINE,
* Pufferung des letzten Rückgabewerts
      g_t_last_rdpr    LIKE  rdpr  OCCURS 0  WITH HEADER LINE,

* Pufferungs-Tabelle des FB 'MD_RDTX_READ'
      g_t_rdtx_buffer  LIKE  rdtx  OCCURS 0  WITH HEADER LINE,
      g_t_last_rdtx    LIKE  rdtx  OCCURS 0  WITH HEADER LINE.

*$@005 Ende

*$@007 Anfang
* globaler T006-Puffer!!!
DATA:
  g_t_t006        LIKE t006
                       OCCURS 0  WITH HEADER LINE.
*$@007 Ende

*$@011 #mbi 4.70 RoundSimu - Anfang
*                *** Tabelle zum Speichern der Simulationsdaten bei
*                *** keiner Anwendung und Intervall
DATA:
  g_t_simu_rounding_range  TYPE TABLE OF   mdr1alvsimurundprofil,

*                *** Tabelle zum Anzeigen der erlaubten logistischen ME
  g_t_allowed_qt_units     TYPE            mdr1toutallowedqtunit,

*                *** Tabelle zum Speichern der Rundungsregel
  g_t_rdrgl                TYPE TABLE OF   tw06s,

*                *** Tabelle zum Speichern der Schwell-/Rundungswerte
  g_t_rdpr                 TYPE TABLE OF   rdpr,

*                *** Tabelle zum Speichern der Auf-/Abschlagswerte
  g_t_markup_discount      TYPE TABLE OF   markup_discount_line_type,

*                *** Tabelle, die als Feldkatalog dient
  g_t_fieldcatalog         TYPE            lvc_t_fcat,

*                *** Tabelle für Dynpro 0401
  g_t_0401_qt_units        TYPE            mdr1toutallowedqtunit,

*                *** Tabellen für Dynpro 0820
  g_t_0820_round_reasons   TYPE            mdr1trundungsgrund,
  g_t_0820_qt_units        TYPE            mdr1toutallowedqtunit,

*                *** Tabelle für Dynpro 0830
*                *** - Tabelle gültige ME
  g_t_0830_qt_units        TYPE            mdr1toutallowedqtunit.

*----------------------------------------------------------------------*
*-  Referenzvariablen
*----------------------------------------------------------------------*

*                *** Referenzvariable, die auf die Tabelle zeigen soll,
*                *** die mittels des ALV angezeigt werden soll
DATA g_ref_to_table_alv_0850 TYPE REF TO data.

*----------------------------------------------------------------------*
*-  Feldsymbole
*----------------------------------------------------------------------*

*                *** Feld-Symbol, das den Inhalt der Referenzvariable
*                *** g_ref_to_table_alv_0850  zugewiesen bekommen soll.
FIELD-SYMBOLS <g_data_table_alv_0850> TYPE ANY.

*$@011 #mbi 4.70 RoundSimu - Ende

* Begin-of-Note-589767
* Enterprise 2.0-MAM
* BADI for modification of input parameters in rounding
* For example assign the site's unit of issue (MARC-AUSME)
* to default UoM in Sales Order in RETAIL ADD ON

DATA: badi_rounding_instance TYPE xfeld.
DATA: badi_rounding TYPE REF TO if_ex_lumer_badi_round_int.

* End-of-Note-589767
CONSTANTS: gc_cvp_raise_exc           type cvp_api_behavior value '2',
           gc_cvp_raise_exc_mass      type cvp_api_behavior value '4'.

*
* 
