*----------------------------------------------------------------------*
***INCLUDE LMDR1FF4 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       26.09.01  470  mbi         Grundversion
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  f4help_rdpr_werks
*&---------------------------------------------------------------------*
*       Routine, die die F4-Hilfe des Dynprofeldes 'RDPR-WERKS' des
*       Dynpros '0500' kapselt.
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM f4help_rdpr_werks
  USING
    p_dynpprog TYPE sy-repid
    p_dynpnr  TYPE sy-dynnr.

  TYPES:
*                *** Spalten, die bei Aufruf der F4-Hilfe angezeigt
*                *** werden sollen.
    BEGIN OF l_s_value_type,
      werks LIKE rdpr-werks,
      name  LIKE t001w-name1,
    END OF l_s_value_type.

*                *** interne Tabelle und Arbeitsbereich für Selektion
*                *** der Daten
  DATA: l_t_rdpr TYPE TABLE OF rdpr,
        l_s_rdpr LIKE rdpr.

*                *** Deklaration von Variablen, die dem Funktions-
*                *** baustein 'F4IF_INT_TABLE_VALUE_REQUEST' übergeben
*                *** werden. Zur Beschreibung der Parameter, siehe
*                *** dessen Funktionsbausteindokumentation (FG: SDHI)
  DATA: l_retfield           TYPE  dfies-fieldname,
        l_dynpprog           TYPE  sy-repid,
        l_dynpnr             TYPE  sy-dynnr,
        l_dynprofield        TYPE  help_info-dynprofld,
        l_value_org          TYPE  ddbool_d,
        l_callback_program   TYPE  sy-repid,
        l_callback_form      TYPE  sy-xform,
        l_s_value            TYPE  l_s_value_type,
        l_t_value            TYPE  TABLE OF l_s_value_type,
        l_s_dynpfld_mapping  TYPE  dselc,
        l_t_dynpfld_mapping  TYPE  TABLE OF dselc.

*                *** Daten, die vorab schon feststehen.
  l_retfield     =  c_fieldname_werks.   " = 'WERKS'.
  l_dynpprog     =  p_dynpprog.
  l_dynpnr       =  p_dynpnr.
  l_dynprofield  =  c_dynprofield_werks. " = 'WERKS'.
  l_value_org    =  c_ddbool_s.          " = 'S'.

*                *** Selektion der Daten von der Datenbank, die bei
*                *** Aufruf der F4-Hilfe angezeigt werden sollen.

*                *** Werke selektieren, denen ein Rundungsprofil
*                *** zugeordnet ist. (Beachte: NICHT mit DISTINCT
*                *** selektieren, da sonst die Pufferung der Tabelle
*                *** RDPR umgangen wird!)
  SELECT * FROM rdpr INTO TABLE l_t_rdpr.

  SORT l_t_rdpr BY werks ASCENDING.

  DELETE ADJACENT DUPLICATES FROM l_t_rdpr COMPARING werks.

  LOOP AT l_t_rdpr INTO l_s_rdpr.

    l_s_value-werks = l_s_rdpr-werks.

*                *** selektiere den Namen zu dem aktuellen Werk.
    SELECT SINGLE  name1
      INTO         l_s_value-name
      FROM t001w
     WHERE werks = l_s_value-werks.

    APPEND l_s_value
        TO l_t_value.

  ENDLOOP.

*                *** Formroutine aufrufen, die wiederum den Funktions-
*                *** baustein 'F4IF_INT_TABLE_VALUE_REQUEST' aufruft.
  PERFORM call_f4help_value_request
                   TABLES
                      l_t_value
                      l_t_dynpfld_mapping
                   USING
                      l_retfield
                      l_dynpprog
                      l_dynpnr
                      l_dynprofield
                      l_value_org
                      l_callback_program
                      l_callback_form.

ENDFORM.                    " f4help_rdpr_werks

*&---------------------------------------------------------------------*
*&      Form  f4help_rdpr_rdprf
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*  -->p_dynpprog                Aufrufendes Programm
*  -->p_dynpnr                  Dynpronummer
*  -->p_rdprf_dynpr_fieldname   Name des Dynprofeldes, in dem das
*                               Rundungsprofil gespeichert wird
*  -->p_werks_dynpr_fieldname   Name des Dynprofeldes, in dem das Werk
*                               gespeichert ist/wird
*  -->p_read_werks              Ankreuzfeld: Wenn dieses Kennzeichen
*                               gesetzt ist, werden falls das Werk ge-
*                               füllt ist, nur Rundungsprofile angezeigt
*                               , die sich auf dieses Werk beziehen.
*  -->p_take_werks              Ankreuzfeld: Wenn dieses Kennzeichen
*                               gesetzt ist, wird das Werk zum Rundungs-
*                               profil, das ausgewählt wird, in das
*                               Dynprofeld zum Werk übernommen.
*----------------------------------------------------------------------*
FORM f4help_rdpr_rdprf
  USING
    p_dynpprog              TYPE  sy-repid
    p_dynpnr                TYPE  sy-dynnr
    p_rdprf_dynpr_fieldname TYPE  help_info-dynprofld
    p_werks_dynpr_fieldname TYPE  dynpread-fieldname
    p_read_werks            TYPE  c
    p_take_werks            TYPE  c.

  TYPES:
    BEGIN OF l_s_value_type,
*                *** Spalten, die bei Aufruf der F4-Hilfe angezeigt
*                *** werden sollen.
      rdprf LIKE rdpr-rdprf,
      werks LIKE rdpr-werks,
      bez   LIKE rdtx-text40,

    END OF l_s_value_type.

*                *** interne Tabelle und Arbeitsbereich für Selektion
*                *** der Daten
  DATA: l_t_rdpr TYPE TABLE OF rdpr,
        l_s_rdpr LIKE rdpr.

*                *** Deklaration von Variablen, die dem Funktions-
*                *** baustein 'F4IF_INT_TABLE_VALUE_REQUEST' übergeben
*                *** werden. Zur Beschreibung der Parameter, siehe
*                *** dessen Funktionsbausteindokumentation (FG: SDHI)
  DATA:
    l_retfield           TYPE          dfies-fieldname,
    l_dynpprog           TYPE          sy-repid,
    l_dynpnr             TYPE          sy-dynnr,
    l_dynprofield        TYPE          help_info-dynprofld,
    l_value_org          TYPE          ddbool_d,
    l_callback_program   TYPE          sy-repid,
    l_callback_form      TYPE          sy-xform,
    l_s_value            TYPE          l_s_value_type,
    l_t_value            TYPE TABLE OF l_s_value_type,
    l_s_dynpfld_mapping  TYPE          dselc,
    l_t_dynpfld_mapping  TYPE TABLE OF dselc,
*                *** Deklaration von Variablen, die dem Funktions-
*                *** baustein 'DYNP_VALUES_READ' übergeben werden.
    l_s_dynpread         TYPE          dynpread,
    l_t_dynpread         TYPE TABLE OF dynpread.

*                *** Daten, die vorab schon feststehen.
  l_retfield     =  c_fieldname_rdprf.  " = 'RDPRF'.
  l_dynpprog     =  p_dynpprog.
  l_dynpnr       =  p_dynpnr.
  l_dynprofield  =  p_rdprf_dynpr_fieldname.
  l_value_org    =  c_ddbool_s.         " = 'S'.

  IF p_read_werks = c_yes.

*                *** Der Inhalt des Dynprofeldes p_werks_dynpr_fieldname
*                *** soll in das namensgleiche ABAP-Datenfeld
*                *** transportiert werden.
    l_s_dynpread-fieldname = p_werks_dynpr_fieldname.

    APPEND l_s_dynpread
        TO l_t_dynpread.

*                *** Der Aufruf dieses Funktionsbausteins ist nötig, da
*                *** zum Zeitpunkt 'PROCESS ON VALUE REQUEST' der Dynpro
*                *** -Ablauflogik KEINE Daten vom Dynpro zu den ABAP-
*                *** Datenfeldern transportiert werden, unsere F4-Hilfe
*                *** aber von dem Inhalt des Dynprofeldes 'RDPR-WERKS'
*                *** abhängig sein soll, d.h. falls in diesem Feld schon
*                *** ein Werk eingegeben wurde, sollen nur noch die
*                *** Rundungsprofile zu diesem Werk angezeigt werden.
    CLEAR: sy-subrc,
           sy-msgid.

    CALL FUNCTION 'DYNP_VALUES_READ'
      EXPORTING
        dyname                         = p_dynpprog
        dynumb                         = p_dynpnr
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
*                *** p_werks_dynpr_fieldname.
*                *** Tabelle hat nur eine Zeile, da nur der Inhalt
*                *** EINES Dynprofeldes gelesen wurde.
    READ TABLE l_t_dynpread
         INDEX 1
          INTO l_s_dynpread.

  ENDIF.

*                *** Falls das Dynprofeld p_werks_dynpr_fieldname leer
*                *** ist, werden alle Rundungsprofile selektiert,
*                *** unabhängig vom Werk.
  IF l_s_dynpread-fieldvalue IS INITIAL.

    IF p_take_werks = c_yes.

*                *** Angabe der Spalten, deren Inhalte bei Selektion
*                *** einer Zeile zusätzlich in entsprechende Dynpro-
*                *** felder transportiert werden soll, außer dem Feld,
*                *** auf das sich die F4-Hilfe bezieht (p_retfield)

*                *** Die Spalten der Tabelle l_t_value werden intern
*                *** mit 'F0001', 'F0002' usw. durchnummeriert, falls
*                *** dem Fkt.baustein 'F4IF_INT_TABLE_VALUE_REQUEST'
*                *** weder DDIC_STRUCTURE noch FIELD_TAB mitgegeben
*                *** werden (siehe Doku !!). In unserem Fall soll der
*                *** Inhalt von Spalte 2 (siehe Aufbau der Zeilen-
*                *** struktur der Tabelle !), also das Werk...
      l_s_dynpfld_mapping-fldname = c_fldname_f0002.   " = 'F0002'.

*                *** ... in das Dynprofeld p_werks_dynpr_fieldname
*                *** gestellt werden.
      l_s_dynpfld_mapping-dyfldname = p_werks_dynpr_fieldname.

      APPEND l_s_dynpfld_mapping
          TO l_t_dynpfld_mapping.

    ENDIF.

*                *** Selektion der Daten von der Datenbank, die bei
*                *** Aufruf der F4-Hilfe angezeigt werden sollen.

*                *** Rundungsprofile und zugehörige Werke selektieren,
*                *** die laut Tabelle 'RDPR' existieren. (Beachte:
*                *** NICHT mit DISTINCT selektieren, da sonst die
*                *** Pufferung der Tabelle rdpr umgangen wird!)
    SELECT * FROM rdpr INTO TABLE l_t_rdpr.

    SORT l_t_rdpr BY rdprf werks ASCENDING.

    DELETE ADJACENT DUPLICATES FROM l_t_rdpr COMPARING rdprf werks.

    LOOP AT l_t_rdpr INTO l_s_rdpr.

      l_s_value-rdprf = l_s_rdpr-rdprf.
      l_s_value-werks = l_s_rdpr-werks.

*                *** selektiere den Namen des aktuellen Rundungsprofils.
      SELECT SINGLE text40
        INTO        l_s_value-bez
        FROM        rdtx
       WHERE        rdprf = l_s_value-rdprf
         AND        spras = sy-langu
         AND        werks = l_s_value-werks.

      APPEND l_s_value
          TO l_t_value.

    ENDLOOP.

*                *** Formroutine aufrufen, die wiederum den Funktions-
*                *** baustein 'F4IF_INT_TABLE_VALUE_REQUEST' aufruft.
    PERFORM call_f4help_value_request
                TABLES
                   l_t_value
                   l_t_dynpfld_mapping
                USING
                   l_retfield
                   l_dynpprog
                   l_dynpnr
                   l_dynprofield
                   l_value_org
                   l_callback_program
                   l_callback_form.

  ELSE.

*                *** Falls das Dynprofeld p_werks_dynpr_fieldname NICHT
*                *** leer ist,
*                *** werden alle Rundungsprofile selektiert, die zu
*                *** diesem Werk gehören.

*                *** speichere das Werk
    l_s_value-werks = l_s_dynpread-fieldvalue.

*                *** Selektion der Daten von der Datenbank, die bei
*                *** Aufruf der F4-Hilfe angezeigt werden sollen.

*                *** Rundungsprofile zum Werk selektieren (Beachte:
*                *** NICHT mit DISTINCT selektieren, da sonst die
*                *** Pufferung der Tabelle rdpr umgangen wird!).
   SELECT * FROM rdpr INTO TABLE l_t_rdpr WHERE werks = l_s_value-werks.

    SORT l_t_rdpr BY rdprf ASCENDING.

    DELETE ADJACENT DUPLICATES FROM l_t_rdpr COMPARING rdprf.

    LOOP AT l_t_rdpr INTO l_s_rdpr.

      l_s_value-rdprf = l_s_rdpr-rdprf.

*                *** ... und den Namen des Rundungsprofil.
      SELECT SINGLE text40
        INTO        l_s_value-bez
        FROM        rdtx
        WHERE       rdprf = l_s_value-rdprf
          AND       spras = sy-langu
          AND       werks = l_s_value-werks.

      IF NOT sy-subrc EQ 0.                     "   insert note 1033202
        CLEAR l_s_value-bez.
      ENDIF.
        APPEND l_s_value
          TO l_t_value.

    ENDLOOP.

*                *** Formroutine aufrufen, die wiederum den Funktions-
*                *** baustein 'F4IF_INT_TABLE_VALUE_REQUEST' aufruft.
    PERFORM call_f4help_value_request
                   TABLES
                      l_t_value
                      l_t_dynpfld_mapping
                   USING
                      l_retfield
                      l_dynpprog
                      l_dynpnr
                      l_dynprofield
                      l_value_org
                      l_callback_program
                      l_callback_form.

  ENDIF.

ENDFORM.                    " f4help_rdpr_rdprf

*
* 
