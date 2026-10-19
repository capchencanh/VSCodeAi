*----------------------------------------------------------------------*
*   INCLUDE LMDR1FCC                                                   *
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.01.99  99A  mwe         Grundversion
*- @001  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @002  07.04.00  46C  mwe         Bei User-Exits keine Export-
*-                                  Parameter nutzen
*-                                  Korrekur zu Hinweis: 212981
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  CALL_USER_EXIT_001
*&---------------------------------------------------------------------*
*       Aufruf eines USER-EXITS für das Entfernen von ungültigen
*       Dezimalstellen
*----------------------------------------------------------------------*
*  -->  p_i_quantity        Menge mit gültigen und ungültigen Dezimal-
*                           stellen
*  -->  p_i_unit            Mengeneinheit der Eingabe-Menge
*  -->  p_i_valid_deci      Anzahl der gültigen Dezimalstellen
*  <--  p_e_valid_quantity  Menge mit gültigen Dezimalstellen
*  <--  p_l_user_exit_valid_deci
*                           vom User-Exit neu bestimmte Anzahl der
*                           gültigen Nachkommastellen
*----------------------------------------------------------------------*
FORM call_user_exit_001
          USING
            value(p_i_quantity)             TYPE mdr1p_p_16_dec_14
            value(p_i_unit)                 LIKE marm-meinh
            value(p_i_valid_deci)           LIKE t006-andec
          CHANGING
*$@002 Anfang MWE-HW-212981
*$            value(p_e_valid_quantity)       TYPE mdr1p_p_16_dec_14
            value(p_l_valid_quantity)       TYPE mdr1p_p_16_dec_14
*$@002 Ende MWE-HW-212981
            value(p_l_user_exit_valid_deci) LIKE t006-andec.

*                *** Initialisierung von Sy-subrc!!!
  CLEAR: sy-subrc,
         sy-msgid.

  CALL CUSTOMER-FUNCTION '001'
       EXPORTING
         i_quantity           = p_i_quantity
         i_unit               = p_i_unit
         i_valid_deci         = p_i_valid_deci
*$@002 Anfang MWE-HW-212981
*$       IMPORTING
*$         e_valid_quantity     = p_e_valid_quantity
*$       CHANGING
*$         ch_new_valid_deci    = p_l_user_exit_valid_deci
       CHANGING
         ch_new_valid_deci    = p_l_user_exit_valid_deci
         ch_valid_quantity    = p_l_valid_quantity
*$@002 Ende MWE-HW-212981
       EXCEPTIONS
         error                = 1      " schwerer Fehler
         error_message        = 98     " Ausnahme mit Meldung
         OTHERS               = 99 .

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).

*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING user_exit_error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e003(rpugen) WITH '001'
                                'MD_RM_INVALID_DECI_PLACE'
                           RAISING user_exit_error.
    ENDIF.
  ENDIF.

ENDFORM.                               " CALL_USER_EXIT_001

*&---------------------------------------------------------------------*
*&      Form  CALL_USER_EXIT_002
*&---------------------------------------------------------------------*
*       Individuelle Bestimmung der entsprechenden ME
*----------------------------------------------------------------------*
*      -->P_T_QT_UNITS   Bestimmte Default-Werte
*      -->P_S_GENERAL    allgemeine Eingabestruktur
*      -->P_S_MARA
*      -->P_S_EINA
*      -->P_S_EINE
*      -->P_S_MARC
*      -->P_S_MARC_2
*      -->P_S_MVKE
*      -->P_S_KNMT
*      -->P_S_KNVV
*      <--P_T_QT_UNITS   individuell neu bestimmte Werte
*----------------------------------------------------------------------*
FORM call_user_exit_002
                  TABLES
                    p_t_qt_units  TYPE  mdr1p_t_out_allowed_qt_unit
                  USING
                    p_s_general   TYPE  mdr1p_s_in_allowed_qt_unit
                    p_s_mara      TYPE  mara
                    p_s_eina      TYPE  eina
                    p_s_eine      TYPE  eine
                    p_s_marc      TYPE  marc
                    p_s_marc_2    TYPE  marc
                    p_s_mvke      TYPE  mvke
                    p_s_knmt      TYPE  knmt
                    p_s_knvv      TYPE  knvv.

*                *** vor USER-EXIT-Aufruf muß Sy-Subrc = 0 sein!
  CLEAR: sy-subrc,
         sy-msgid.

*                *** Aufruf des User-Exits (002)
  CALL CUSTOMER-FUNCTION '002'
       EXPORTING
            i_s_general  =  p_s_general
            i_s_mara     =  p_s_mara
            i_s_eina     =  p_s_eina
            i_s_eine     =  p_s_eine
            i_s_marc     =  p_s_marc
            i_s_marc_2   =  p_s_marc_2
            i_s_mvke     =  p_s_mvke
            i_s_knmt     =  p_s_knmt
            i_s_knvv     =  p_s_knvv
       TABLES
            o_t_qt_units = p_t_qt_units
       EXCEPTIONS
            error          = 1         " schwerer Fehler
            error_message  = 98        " Ausnahme bei Meldungen
            OTHERS         = 99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e003(rpugen)  WITH '002'
                            'MD_ALLOWED_QUANTITY_UNIT'
              RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " CALL_USER_EXIT_002

*&---------------------------------------------------------------------*
*&      Form  call_user_exit_003
*&---------------------------------------------------------------------*
*       Durchführung einer individuellen Rundungsmethode, die dem
*       bestimmten Rundungsprofil zugeordnet ist
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_RESULTS       Bestimmte Rundungsparameter
*      <--P_S_RESULTS       Rundungsparameter und Rundungswergebnis
*      <--p_t_round_reasons RUndungsgründe
*----------------------------------------------------------------------*
FORM call_user_exit_003
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

*                *** vor USER-EXIT-Aufruf muß Sy-Subrc = 0 sein!
  CLEAR: sy-subrc,
         sy-msgid.

*                *** Aufruf des User-Exits (003)
  CALL CUSTOMER-FUNCTION '003'
       EXPORTING
            i_s_general        = p_s_general
       TABLES
            ch_t_qt_units      = p_t_qt_units
            ch_t_round_reasons = p_t_round_reasons
       CHANGING
            ch_s_results       = p_s_results
       EXCEPTIONS
            error              =  1    " schwerer Fehler
            error_message      =  98   " Ausnahme bei Meldungen
            OTHERS             =  99
  .

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e003(rpugen)  WITH '003'
                            'MD_SINGLE_ROUNDING'
              RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " call_user_exit_003

*&---------------------------------------------------------------------*
*&      Form  CALL_USER_EXIT_004
*&---------------------------------------------------------------------*
*       Durchführung einer kundenindividuellen Korrektur der Rundungs-
*       Werte
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_T_ROUND_REASONS Rundungsgründe
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_EINA
*      -->P_S_EINE
*      -->P_S_MARC
*      -->P_S_MARC_2
*      -->P_S_MVKE
*      -->P_S_KNMT
*      -->P_S_KNVV
*      -->P_S_RESULTS       Rundungsparameter und Rundungs-Ergebnis
*      <--P_S_RESULTS       zusätzliche Rundungsgründe zur Korrektur
*      <--P_S_RESULTS       Rundungsparameter und korrigiertes RundErge.
*----------------------------------------------------------------------*
FORM call_user_exit_004
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                     p_t_round_reasons TYPE mdr1p_t_rundungsgrund
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                     p_s_eina          TYPE eina
                     p_s_eine          TYPE eine
                     p_s_marc          TYPE marc
                     p_s_marc_2        TYPE marc
                     p_s_mvke          TYPE mvke
                     p_s_knmt          TYPE knmt
                     p_s_knvv          TYPE knvv
                   CHANGING
                     p_s_results       TYPE mdr1p_s_out_single_round.

*                *** vor USER-EXIT-Aufruf muß Sy-Subrc = 0 sein!
  CLEAR: sy-subrc,
         sy-msgid.

*                *** Aufruf des User-Exits (004)
  CALL CUSTOMER-FUNCTION '004'
       EXPORTING
            i_s_general        = p_s_general
            i_s_eina           = p_s_eina
            i_s_eine           = p_s_eine
            i_s_marc_2         = p_s_marc_2
            i_s_marc           = p_s_marc
            i_s_mvke           = p_s_mvke
            i_s_knmt           = p_s_knmt
            i_s_knvv           = p_s_knvv
       TABLES
            ch_t_qt_units      = p_t_qt_units
            ch_t_round_reasons = p_t_round_reasons
       CHANGING
            ch_s_results       = p_s_results
       EXCEPTIONS
            error              =  1    " schwerer Fehler
            error_message      =  98   " Ausnahme bei Meldungen
            OTHERS             =  99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e003(rpugen)  WITH '004'
                            'MD_SINGLE_ROUNDING'
              RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " CALL_USER_EXIT_004

*&---------------------------------------------------------------------*
*&      Form  CALL_USER_EXIT_005
*&---------------------------------------------------------------------*
*       Durchführung einer kundenindividuellen Korrektur der Rundungs-
*       Parameter
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_MARA          MARA-Eintrag
*      -->P_S_EINA          bestimmter EINA-EIntrag
*      -->P_S_EINE          bestimmter EINE-Eintrag
*      -->P_S_MARC          bestimmter MARC-EIntrag
*      -->P_S_MARC_2        bestimmter MARC_2-E..
*      -->P_S_MVKE          bestimmter MVKE-...
*      -->P_S_KNMT          bestimmter KNMT-...
*      -->P_S_KNVV          bestimmter KNVV-...
*      <--p_t_qt_units      korrigierte erlaubte ME
*      <--P_S_EINA          korregierter EINA-EIntrag
*      <--P_S_EINE          korregierter EINE-Eintrag
*      <--P_S_MARC          korregierter MARC-EIntrag
*      <--P_S_MARC_2        korregierter MARC_2-E..
*      <--P_S_MVKE          korregierter MVKE-...
*      <--P_S_KNMT          korregierter KNMT-...
*      <--P_S_KNVV          korregierter KNVV-...
*      <--P_S_RESULTS       bestimmte Rundungsparameter
*      <--P_S_RESULTS       korregierte Rundungsparameter.
*----------------------------------------------------------------------*
FORM call_user_exit_005
                   TABLES
                     p_t_qt_units      TYPE mdr1p_t_out_allowed_qt_unit
                   USING
                     p_s_general       TYPE mdr1p_s_in_single_round
                     p_s_mara          TYPE mara
                   CHANGING
                     p_s_eina          TYPE eina
                     p_s_eine          TYPE eine
                     p_s_marc          TYPE marc
                     p_s_marc_2        TYPE marc
                     p_s_mvke          TYPE mvke
                     p_s_knmt          TYPE knmt
                     p_s_knvv          TYPE knvv
                     p_s_results       TYPE mdr1p_s_out_single_round.

*                *** vor USER-EXIT-Aufruf muß Sy-Subrc = 0 sein!
  CLEAR: sy-subrc,
         sy-msgid.

*                *** Aufruf des User-Exits (005)
  CALL CUSTOMER-FUNCTION '005'
       EXPORTING
            i_s_general        = p_s_general
            i_s_mara           = p_s_mara
       TABLES
            ch_t_qt_units      = p_t_qt_units
       CHANGING
            ch_s_eina           = p_s_eina
            ch_s_eine           = p_s_eine
            ch_s_marc_2         = p_s_marc_2
            ch_s_marc           = p_s_marc
            ch_s_mvke           = p_s_mvke
            ch_s_knmt           = p_s_knmt
            ch_s_knvv           = p_s_knvv
            ch_s_results        = p_s_results
       EXCEPTIONS
            error               =  1   " schwerer Fehler
            error_message       =  98  " Ausnahme bei Meldungen
            OTHERS              =  99.

  IF sy-subrc <> 0.
    IF NOT ( sy-msgid IS INITIAL ).
*                *** Reiche die Fehlermeldung durch und setzte Ausnahme
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING error.
    ELSE.
*                *** sonst: eigene Meldung und Ausnahme!
      MESSAGE e003(rpugen)  WITH '005'
                            'MD_SINGLE_ROUNDING'
              RAISING error.
    ENDIF.
  ENDIF.

ENDFORM.                               " CALL_USER_EXIT_005


* Begin-of-Note-589767

*&---------------------------------------------------------------------*
*&      Form  CALL_BADI_ROUNDING
*&---------------------------------------------------------------------*
*
*       BADI for modification of input parameters in rounding
*       For example assign the site's unit of issue (MARC-AUSME)
*       to default UoM in Sales Order in RETAIL ADD ON
*
*----------------------------------------------------------------------*
*      -->p_t_qt_units      erlaubte ME
*      -->P_S_GENERAL       allgemeine Eingabestruktur
*      -->P_S_MARA          MARA-Eintrag
*      -->P_S_EINA          bestimmter EINA-EIntrag
*      -->P_S_EINE          bestimmter EINE-Eintrag
*      -->P_S_MARC          bestimmter MARC-EIntrag
*      -->P_S_MARC_2        bestimmter MARC_2-E..
*      -->P_S_MVKE          bestimmter MVKE-...
*      -->P_S_KNMT          bestimmter KNMT-...
*      -->P_S_KNVV          bestimmter KNVV-...
*      <--p_t_qt_units      korrigierte erlaubte ME
*      <--P_S_EINA          korregierter EINA-EIntrag
*      <--P_S_EINE          korregierter EINE-Eintrag
*      <--P_S_MARC          korregierter MARC-EIntrag
*      <--P_S_MARC_2        korregierter MARC_2-E..
*      <--P_S_MVKE          korregierter MVKE-...
*      <--P_S_KNMT          korregierter KNMT-...
*      <--P_S_KNVV          korregierter KNVV-...
*      <--P_S_RESULTS       bestimmte Rundungsparameter
*      <--P_S_RESULTS       korregierte Rundungsparameter.
*----------------------------------------------------------------------*

FORM call_badi_rounding
                 TABLES    p_t_qt_units TYPE mdr1p_t_out_allowed_qt_unit
                  USING    p_s_general  TYPE mdr1p_s_in_single_round
                           p_s_mara     TYPE mara
                  CHANGING p_s_eina     TYPE eina
                           p_s_eine     TYPE eine
                           p_s_marc     TYPE marc
                           p_s_marc_2   TYPE marc
                           p_s_mvke     TYPE mvke
                           p_s_knmt     TYPE knmt
                           p_s_knvv     TYPE knvv
                           p_s_results  TYPE mdr1p_s_out_single_round.

  CLASS cl_exithandler DEFINITION LOAD.

  IF badi_rounding_instance IS INITIAL.

    CALL METHOD cl_exithandler=>get_instance
      EXPORTING
        exit_name              = 'LUMER_BADI_ROUND_INT'
        null_instance_accepted = c_yes  "no instance when no active impl
      CHANGING
        instance               = badi_rounding.


    badi_rounding_instance = c_yes.

  ENDIF.

  IF NOT ( badi_rounding IS INITIAL ).



    CALL METHOD badi_rounding->modify_inputdata      "Call Add-Ins
      EXPORTING
          i_s_general      = p_s_general
          i_s_mara         = p_s_mara
      CHANGING
          ch_t_qt_units  = p_t_qt_units[]
          ch_s_eina      = p_s_eina
          ch_s_eine      = p_s_eine
          ch_s_marc_2    = p_s_marc_2
          ch_s_marc      = p_s_marc
          ch_s_mvke      = p_s_mvke
          ch_s_knmt      = p_s_knmt
          ch_s_knvv      = p_s_knvv
          ch_s_results   = p_s_results
      EXCEPTIONS
      error  = 1
      OTHERS = 99.

    IF sy-subrc <> 0.
      MESSAGE e006(rpugen)  WITH 'MODIFY_INPUTDATA'.
      EXIT.
    ENDIF.

  ENDIF.
ENDFORM.                               " CALL_BADI_ROUNDING

* End-of-Note-589767

*
* 
