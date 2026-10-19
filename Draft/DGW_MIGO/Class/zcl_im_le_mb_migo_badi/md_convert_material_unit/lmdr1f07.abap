*----------------------------------------------------------------------*
***INCLUDE LMDR1F07 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       16.04.98  4.0c welterm     Grundversion: Unterprogramme zu FB
*-                                  MD_RDPR_READ
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  INIT_GLOBAL_DATA_RDPR
*&---------------------------------------------------------------------*
*       Initialisierung der globalen Daten für die Pufferung
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM init_global_data_rdpr.

  g_first_time = c_no.        "   => beim nächsten Aufruf keine Init.

  CLEAR: g_last_rdprf,        "   => letztes gelesene Rundungsprofil
         g_last_werks,        "   => letztes berücksichtigte Werk
         g_t_last_rdpr[].     "   => Definition des letzten Rundungsp.

  CLEAR: g_buffer_size,       "   => Anzahl der Rundungspr. im Puffer
         g_t_rdpr_buffer[].   "   => gepufferte Definitionen von RDPR

ENDFORM.                               " INIT_GLOBAL_DATA_RDPR

*&---------------------------------------------------------------------*
*&      Form  SINGLE_READ_RDPR
*&---------------------------------------------------------------------*
*       Bestimme genau eine Rundungsprofil-Definition
*----------------------------------------------------------------------*
*      -->P_G_U04          Eingabeparameter des FB
*----------------------------------------------------------------------*
FORM single_read_rdpr USING
                        value(p_g_u04) LIKE g_u04.

  DATA:  l_entry_found      TYPE  c.

  CLEAR:  l_entry_found.

*                *** 1. Plausi-Prüfung
  PERFORM check_input_single_rdpr USING p_g_u04.

  IF p_g_u04-i_read_with_buffer = c_yes.
*                *** 2. Mit Pufferung lesen => suche Eintrag im Puffer
    PERFORM read_buffer_rdpr  USING     p_g_u04
                              CHANGING  l_entry_found.
  ENDIF.

  IF l_entry_found = c_no.
*                *** 3. Lese direkt von der DB
    PERFORM read_db_rdpr  USING  p_g_u04.
  ENDIF.

ENDFORM.                               " SINGLE_READ_RDPR

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_SINGLE_RDPR
*&---------------------------------------------------------------------*
*       Führe Plausiprüfung auf den Eingabewerten des FB für
*       das Lesen eines einzelnen Rundungsprofils durch
*----------------------------------------------------------------------*
*      -->P_G_U04  Eingabeparameter des FB
*----------------------------------------------------------------------*
FORM check_input_single_rdpr USING value(p_g_u04) LIKE g_u04.

*                *** 1. allgemeine Plausi-Prüfung
  PERFORM check_input_general_rdpr USING p_g_u04.

*                *** 2. Spezielle Prüfungen
*                ***    - Rundungsprofil muss gefüllt sein
  IF p_g_u04-i_rdprf IS INITIAL.
    MESSAGE e004(rpugen) WITH 'MD_READ_RDPR'
                              'i_rdprf'
                              p_g_u04-i_rdprf
                         RAISING bad_params.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_SINGLE_RDPR

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_GENERAL_RDPR
*&---------------------------------------------------------------------*
*       Allgemeine Eingabeprüfungen
*----------------------------------------------------------------------*
*      -->P_G_U04
*----------------------------------------------------------------------*
FORM check_input_general_rdpr USING value(p_g_u04) LIKE g_u04.

  IF NOT (   p_g_u04-i_read_with_buffer = c_yes
          OR p_g_u04-i_read_with_buffer = c_no ).
    MESSAGE e004(rpugen) WITH 'MD_READ_RDPR'
                              'i_read_with_buffer'
                              p_g_u04-i_read_with_buffer
                         RAISING bad_params.
  ENDIF.

  IF NOT (   p_g_u04-i_buffer_on = c_yes
          OR p_g_u04-i_buffer_on = c_no ).
    MESSAGE e004(rpugen) WITH 'MD_READ_RDPR'
                              'i_buffer_on'
                              p_g_u04-i_buffer_on
                         RAISING bad_params.
  ENDIF.

  IF p_g_u04-i_buffer_size  <  0.
    MESSAGE e004(rpugen) WITH 'MD_READ_RDPR'
                              'i_buffer_size'
                              p_g_u04-i_buffer_size
                         RAISING bad_params.
  ENDIF.

*                *** Die Kombination eingeschalteter Puffer und direkt
*                *** Lesen von der DB ist nicht erlaubt!!!
  IF     p_g_u04-i_buffer_on = c_yes
     AND p_g_u04-i_read_with_buffer = c_no.
    MESSAGE e076 RAISING bad_params.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_GENERAL_RDPR

*&---------------------------------------------------------------------*
*&      Form  READ_BUFFER_RDPR
*&---------------------------------------------------------------------*
*       Lese aus den gepufferten Daten:
*       1. Vergleich mit dem letzten gelesenen Profil
*       2. Suche in den gepufferten Daten
*----------------------------------------------------------------------*
*      -->P_G_U04
*      <--P_ENTRY_FOUND
*----------------------------------------------------------------------*
FORM read_buffer_rdpr USING    value(p_g_u04)       LIKE g_u04
                      CHANGING value(p_entry_found) TYPE c.

  DATA:  l_t_save_last_rdpr LIKE  g_t_last_rdpr
                            OCCURS 0 WITH HEADER LINE.

  CLEAR:  l_t_save_last_rdpr[].


  IF     p_g_u04-i_rdprf = g_last_rdprf
     AND p_g_u04-i_werks = g_last_werks.
*                *** Rundungsprofil entspricht dem letzten ge-
*                *** lesenen Rundungsprofil
    p_entry_found = c_yes.

  ELSE.
*                *** Suche im Puffer:

*                *** Sicherung des letzten gelesenen RundProfils
    CLEAR l_t_save_last_rdpr[].
    l_t_save_last_rdpr[] = g_t_last_rdpr[].
    CLEAR g_t_last_rdpr[].

*                *** Durchsuche den Puffer
    LOOP AT g_t_rdpr_buffer
      WHERE rdprf = p_g_u04-i_rdprf
        AND werks = p_g_u04-i_werks.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdpr.
      MOVE-CORRESPONDING g_t_rdpr_buffer TO g_t_last_rdpr.
      APPEND g_t_last_rdpr.

    ENDLOOP.

    IF p_entry_found = c_yes.
*                *** Restliche Daten des letzten gelesenen RundProfils
*                *** merken
      g_last_werks = p_g_u04-i_werks.
      g_last_rdprf = p_g_u04-i_rdprf.
    ELSE.
*                *** Kein gepufferter Eintrag gefunden
*                ***  => für letztes gelesenes RundProfil alte Situation
*                ***     wiederherstellen
      g_t_last_rdpr[] = l_t_save_last_rdpr[].
    ENDIF.
  ENDIF.

ENDFORM.                               " READ_BUFFER_RDPR

*&---------------------------------------------------------------------*
*&      Form  READ_DB_RDPR
*&---------------------------------------------------------------------*
*       Lese direkt von der DB
*----------------------------------------------------------------------*
*      -->P_G_U04
*----------------------------------------------------------------------*
FORM read_db_rdpr USING  value(p_g_u04) LIKE  g_u04.

  DATA:  l_t_save_last_rdpr LIKE   g_t_last_rdpr
                            OCCURS 0 WITH HEADER LINE.

*                *** Sicherung des letzten gelesenen RundProfils
  CLEAR l_t_save_last_rdpr[].
  l_t_save_last_rdpr[] = g_t_last_rdpr[].
  CLEAR g_t_last_rdpr[].

*                *** Lese RundProfil von der DB
  SELECT       *
    FROM       rdpr
    INTO TABLE g_t_last_rdpr           " in letzes gelesenes RundProf
   WHERE       werks = p_g_u04-i_werks
     AND       rdprf = p_g_u04-i_rdprf.

  IF sy-subrc <> 0.
*                *** => für letztes gelesenes RundProfil alte Situation
*                ***    wiederherstellen
    g_t_last_rdpr[] = l_t_save_last_rdpr[].
*                ***    Fehlermeldung
    MESSAGE e008(rpudb) WITH p_g_u04-i_rdprf
                             p_g_u04-i_werks
                        RAISING no_entry_found.
  ENDIF.

*                *** Restliche Daten des letzten gelesenen RundProfils
*                *** merken
  g_last_werks = p_g_u04-i_werks.
  g_last_rdprf = p_g_u04-i_rdprf.

  IF p_g_u04-i_buffer_on    =  c_yes.
*                *** gelesene Daten auch in Puffer übernehmen
    PERFORM fill_up_buffer_rdpr USING p_g_u04.
  ENDIF.

ENDFORM.                               " READ_DB_RDPR

*&---------------------------------------------------------------------*
*&      Form  FILL_UP_BUFFER_RDPR
*&---------------------------------------------------------------------*
*       Die gelesenen Daten aus der DB werden in den Puffer
*       übernommen.
*----------------------------------------------------------------------*
*      -->P_G_U04
*----------------------------------------------------------------------*
FORM fill_up_buffer_rdpr USING  value(p_g_u04) LIKE g_u04.

  DATA: l_rdprf LIKE rdpr-rdprf,
        l_werks LIKE rdpr-werks.

  CLEAR: l_rdprf,
         l_werks.

  IF p_g_u04-i_buffer_size  >  0.
*                *** 1. Eingeschränkte Puffergröße berücksichtigen:
    PERFORM check_buffer_size_rdpr USING p_g_u04.
  ENDIF.

*                *** 2. neuer Eintrag in den Puffer übernehmen
  LOOP AT g_t_last_rdpr.

    CLEAR g_t_rdpr_buffer.
    MOVE-CORRESPONDING g_t_last_rdpr TO g_t_rdpr_buffer.
    APPEND g_t_rdpr_buffer.

    IF    l_rdprf <> g_t_last_rdpr-rdprf
       OR l_werks <> g_t_last_rdpr-werks.
*                *** 3. Puffergröße um ein RundProfil-Eintrag erhöhen
      g_buffer_size = g_buffer_size + 1.
      l_rdprf = g_t_last_rdpr-rdprf.
      l_werks = g_t_last_rdpr-werks.
    ENDIF.

  ENDLOOP.

ENDFORM.                               " FILL_UP_BUFFER_RDPR

*&---------------------------------------------------------------------*
*&      Form  CHECK_BUFFER_SIZE_RDPR
*&---------------------------------------------------------------------*
*       Überprüfe ob die vorgeschriebene Puffergröße durch
*       einen neuen Satz eingehalten werden kann.
*----------------------------------------------------------------------*
*      -->P_G_U04
*----------------------------------------------------------------------*
FORM check_buffer_size_rdpr USING  value(p_g_u04) LIKE g_u04.

  DATA:  l_rdprf            LIKE  rdpr-rdprf,
         l_werks            LIKE  rdpr-werks.

*                *** Wenn maximale Puffergröße erreicht oder über-
*                *** schritten ist, lösche die ältesten Einträge
*                *** (Rundungsprofile) bis das neue Rundungsprofil
*                *** ohne Puffergrößen überschreitung gepuffert
*                *** werden kann:
*                *** Wichtig: die Puffergröße bezieht sich immer
*                ***          auf die Anzahl der Rundungsprofile
*                ***          im Puffer und nicht auf die Anzahl der
*                ***          Einträge in der internen Tabelle.
*                ***          Es kann zu einem Rundungsprofil mehrere
*                ***          Einträge in der internen Tabelle (Puffer)
*                ***          geben!!!!!!!!!!!!!
  WHILE g_buffer_size  >= p_g_u04-i_buffer_size.
*                *** Der 1. Eintrag im Puffer ist immmer der älteste
    READ TABLE g_t_rdpr_buffer INDEX 1.
*                *** Fülle Hilfsfelder mit dem gelesenen Profil
    CLEAR: l_rdprf,
           l_werks.
    l_rdprf = g_t_rdpr_buffer-rdprf.
    l_werks = g_t_rdpr_buffer-werks.
*                *** Lösche alle Einträge zu dem gelesenen Profil aus
*                *** dem Puffer.
    LOOP AT g_t_rdpr_buffer
      WHERE rdprf = l_rdprf
        AND werks = l_werks.

      DELETE g_t_rdpr_buffer.

    ENDLOOP.
*                *** Puffergröße wird um ein Profil-Eintrag kleiner
    g_buffer_size = g_buffer_size - 1.

  ENDWHILE.

ENDFORM.                               " CHECK_BUFFER_SIZE_RDPR

*&---------------------------------------------------------------------*
*&      Form  READ_ALL_RDPR
*&---------------------------------------------------------------------*
*       Bestimme viele Rundungsprofil-Definition
*----------------------------------------------------------------------*
*      -->P_G_U04          Eingabeparameter des FB
*----------------------------------------------------------------------*
FORM read_all_rdpr USING
                     value(p_g_u04) LIKE g_u04.

  DATA:  l_entry_found      TYPE  c.

  CLEAR:  l_entry_found.

*                *** 1. Eingabe Plausi-Prüfung
  PERFORM check_input_all_rdpr USING p_g_u04.

  IF p_g_u04-i_read_with_buffer = c_yes.
*                *** 2. Mit Pufferung lesen => suche Einträge im Puffer
    PERFORM read_buffer_all_rdpr USING     p_g_u04
                                 CHANGING  l_entry_found.
  ENDIF.

  IF l_entry_found = c_no.
*                *** 3. Lese direkt von der DB
    PERFORM read_db_all_rdpr  USING  p_g_u04.
  ENDIF.

ENDFORM.                               " READ_ALL_RDPR

*&---------------------------------------------------------------------*
*&      Form  READ_BUFFER_ALL_RDPR
*&---------------------------------------------------------------------*
*       Lese alle Einträge aus dem Puffer
*----------------------------------------------------------------------*
*      -->P_G_U04
*      <--P_ENTRY_FOUND
*----------------------------------------------------------------------*
FORM read_buffer_all_rdpr USING    value(p_g_u04)        LIKE g_u04
                          CHANGING value(p_entry_found)  TYPE c.

  DATA:  l_t_save_last_rdpr LIKE   g_t_last_rdpr
                            OCCURS 0 WITH HEADER LINE.

*                *** Sicherung des letzten gelesenen RundProfils
  CLEAR l_t_save_last_rdpr[].
  l_t_save_last_rdpr[] = g_t_last_rdpr[].
  CLEAR g_t_last_rdpr[].

*                ***    Fallunterscheidung: Kombinationsmöglichkeiten
*                ***    werks  rdprf  rdmpo |    Fall
*                ***    --------------------|-----------
*                ***    init   init   init  | => a)
*                ***    init   init   bele  | => b)
*                ***    init   bele   init  | => c)
*                ***    init   bele   bele  | => Fehler => siehe Check_.
*                ***    bele   init   init  | => e)
*                ***    bele   init   bele  | => d)
*                ***    bele   bele   init  | => f)
*                ***    bele   bele   bele  | => Fehler => siehe Check_.

  IF         p_g_u04-i_rdprf IS INITIAL
         AND p_g_u04-i_werks IS INITIAL
         AND p_g_u04-i_rdmpo = c_rdmpo_init.
*                *** a) Alle RundProfile
    IF g_buffer_size > 0.
      g_t_last_rdpr[] = g_t_rdpr_buffer[].     " komplett kopieren
      p_entry_found = c_yes.
    ENDIF.

  ELSEIF     ( NOT p_g_u04-i_rdprf IS INITIAL )
         AND p_g_u04-i_werks IS INITIAL.
*                *** b) Alle Werksprofile zu dem gleichen Profil
    LOOP AT g_t_rdpr_buffer
      WHERE rdprf = p_g_u04-i_rdprf.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdpr.
      MOVE-CORRESPONDING g_t_rdpr_buffer TO g_t_last_rdpr.
      APPEND g_t_last_rdpr.

    ENDLOOP.

  ELSEIF     ( NOT p_g_u04-i_rdmpo = c_rdmpo_init )
         AND p_g_u04-i_werks IS INITIAL.
*                *** c) alle Rundungsprofile zu einer Rundungsmethode
    LOOP AT g_t_rdpr_buffer
      WHERE rdmpo = p_g_u04-i_rdmpo.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdpr.
      MOVE-CORRESPONDING g_t_rdpr_buffer TO g_t_last_rdpr.
      APPEND g_t_last_rdpr.

    ENDLOOP.

  ELSEIF     ( NOT p_g_u04-i_rdmpo = c_rdmpo_init )
         AND ( NOT p_g_u04-i_werks IS INITIAL ).
*                *** d) alle Werksprofile zu einer Rundungsmethode
    LOOP AT g_t_rdpr_buffer
      WHERE rdmpo = p_g_u04-i_rdmpo
        AND werks = p_g_u04-i_werks.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdpr.
      MOVE-CORRESPONDING g_t_rdpr_buffer TO g_t_last_rdpr.
      APPEND g_t_last_rdpr.

    ENDLOOP.

  ELSEIF     p_g_u04-i_rdprf IS INITIAL
         AND p_g_u04-i_rdmpo = c_rdmpo_init
         AND ( NOT p_g_u04-i_werks IS INITIAL ).
*                *** e) Alle Profile zu einem Werk

    LOOP AT g_t_rdpr_buffer
      WHERE werks = p_g_u04-i_werks.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdpr.
      MOVE-CORRESPONDING g_t_rdpr_buffer TO g_t_last_rdpr.
      APPEND g_t_last_rdpr.

    ENDLOOP.

  ELSE.
*                *** f) genau ein Rundungsprofil zu einem Werk und
*                ***    Profil
    PERFORM read_buffer_rdpr  USING     p_g_u04
                              CHANGING  p_entry_found.
  ENDIF.

  IF p_entry_found = c_yes.
*                *** Restliche Daten des letzten gelesenen RundProfils
*                *** löschen!!!!
    CLEAR: g_last_werks,
           g_last_rdprf.
  ELSE.
*                *** Kein gepufferter Eintrag gefunden
*                ***  => für letztes gelesenes RundProfil alte Situation
*                ***     wiederherstellen
    g_t_last_rdpr[] = l_t_save_last_rdpr[].

  ENDIF.

ENDFORM.                               " READ_BUFFER_ALL_RDPR

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_ALL_RDPR
*&---------------------------------------------------------------------*
*       Eingabe-Prüfung bei lesen von allen Rundungsprofilen
*----------------------------------------------------------------------*
*      -->P_G_U04
*----------------------------------------------------------------------*
FORM check_input_all_rdpr USING  value(p_g_u04) LIKE g_u04.

*                *** 1. allgemeine Plausi-Prüfung
  PERFORM check_input_general_rdpr USING p_g_u04.

*                *** 2. Spezielle Prüfungen
*                ***    - Rundungsprofil und Rundungsmethode
*                ***      dürfen nicht gleichzeitig belegt sein
  IF    ( NOT p_g_u04-i_rdprf IS INITIAL )
    AND ( NOT p_g_u04-i_rdmpo = c_rdmpo_init ).
    MESSAGE e074  RAISING bad_params.
  ENDIF.

*                ***    - Puffergröße muss auf 0 stehen
*                ***      => keine Beschränkung
  IF p_g_u04-i_buffer_size <> 0.
    MESSAGE e004(rpugen) WITH 'MD_READ_RDPR'
                              'i_buffer_size'
                              p_g_u04-i_buffer_size
                         RAISING bad_params.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_ALL_RDPR

*&---------------------------------------------------------------------*
*&      Form  READ_DB_ALL_RDPR
*&---------------------------------------------------------------------*
*       Lese alle Profile direkt von der DB
*----------------------------------------------------------------------*
*      -->P_G_U04
*----------------------------------------------------------------------*
FORM read_db_all_rdpr USING  value(p_g_u04) LIKE g_u04.

  DATA:  l_t_save_last_rdpr LIKE   g_t_last_rdpr
                            OCCURS 0 WITH HEADER LINE.

*                *** Sicherung des letzten gelesenen RundProfils
  CLEAR l_t_save_last_rdpr[].
  l_t_save_last_rdpr[] = g_t_last_rdpr[].
  CLEAR g_t_last_rdpr[].

*                ***    Fallunterscheidung: Kombinationsmöglichkeiten
*                ***    werks  rdprf  rdmpo |    Fall
*                ***    --------------------|-----------
*                ***    init   init   init  | => a)
*                ***    init   init   bele  | => b)
*                ***    init   bele   init  | => c)
*                ***    init   bele   bele  | => Fehler => siehe Check_.
*                ***    bele   init   init  | => e)
*                ***    bele   init   bele  | => d)
*                ***    bele   bele   init  | => f)
*                ***    bele   bele   bele  | => Fehler => siehe Check_.

  IF         p_g_u04-i_rdprf IS INITIAL
         AND p_g_u04-i_werks IS INITIAL
         AND p_g_u04-i_rdmpo = c_rdmpo_init.
*                *** a) Alle RundProfile
    SELECT       *
      FROM       rdpr
      INTO TABLE g_t_last_rdpr.

  ELSEIF     ( NOT p_g_u04-i_rdprf IS INITIAL )
         AND p_g_u04-i_werks IS INITIAL.
*                *** b) Alle Werksprofile zu dem gleichen Profil
    SELECT       *
      FROM       rdpr
      INTO TABLE g_t_last_rdpr
     WHERE       rdprf = p_g_u04-i_rdprf.

  ELSEIF     ( NOT p_g_u04-i_rdmpo = c_rdmpo_init )
         AND p_g_u04-i_werks IS INITIAL.
*                *** c) alle Rundungsprofile zu einer Rundungsmethode
    SELECT       *
      FROM       rdpr
      INTO TABLE g_t_last_rdpr
     WHERE       rdmpo = p_g_u04-i_rdmpo.

  ELSEIF     ( NOT p_g_u04-i_rdmpo = c_rdmpo_init )
         AND ( NOT p_g_u04-i_werks IS INITIAL ).
*                *** d) alle Werksprofile zu einer Rundungsmethode
    SELECT       *
      FROM       rdpr
      INTO TABLE g_t_last_rdpr
     WHERE       werks = p_g_u04-i_werks
       AND       rdmpo = p_g_u04-i_rdmpo.

  ELSEIF     p_g_u04-i_rdprf IS INITIAL
         AND p_g_u04-i_rdmpo = c_rdmpo_init
         AND ( NOT p_g_u04-i_werks IS INITIAL ).
*                *** e) Alle Profile zu einem Werk
    SELECT       *
      FROM       rdpr
      INTO TABLE g_t_last_rdpr
     WHERE       werks = p_g_u04-i_werks.

  ELSE.
*                *** f) genau ein Rundungsprofil zu einem Werk und
*                ***    Profil
    SELECT       *
      FROM       rdpr
      INTO TABLE g_t_last_rdpr
     WHERE       werks = p_g_u04-i_werks
       AND       rdprf = p_g_u04-i_rdprf.

  ENDIF.

  IF sy-subrc <> 0.
*                *** => für letztes gelesenes RundProfil alte Situation
*                ***    wiederherstellen
    g_t_last_rdpr[] = l_t_save_last_rdpr[].
*                ***    Fehlermeldung
    MESSAGE e008(rpudb) WITH p_g_u04-i_rdprf
                             p_g_u04-i_werks
                        RAISING no_entry_found.
  ENDIF.

*                *** Restliche Daten des letzten gelesenen RundProfils
*                *** löschen
  CLEAR: g_last_werks,
         g_last_rdprf.

  IF p_g_u04-i_buffer_on    =  c_yes.
*                *** gelesene Daten auch in Puffer übernehmen
    PERFORM fill_up_buffer_rdpr USING p_g_u04.
  ENDIF.


ENDFORM.                               " READ_DB_ALL_RDPR

*
* 
