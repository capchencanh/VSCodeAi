*----------------------------------------------------------------------*
***INCLUDE LMDR1F08 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       16.04.98  4.0c welterm     Grundversion: Unterprogramme zu FB
*-                                  MD_RDTX_READ
*-----------------------------------------------------------------------
*&---------------------------------------------------------------------*
*&      Form  INIT_GLOBAL_DATA_RDTX
*&---------------------------------------------------------------------*
*       Initialisierung der globalen Daten für die Pufferung
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM init_global_data_rdtx.

  g_first_time_rdtx = c_no.     "   => beim nächsten Aufruf keine Init.

  CLEAR: g_last_rdtx_rdprf,     "   => letztes gelesene Rundungsprofil
         g_last_rdtx_werks,     "   => letztes berücksichtigte Werk
         g_t_last_rdtx[].       "   => Definition des letzten Rundungsp.

  CLEAR: g_buffer_size_rdtx,    "   => Anzahl der Rundungspr. im Puffer
         g_t_rdtx_buffer[].     "   => gepufferte Definitionen von RDTX

ENDFORM.                               " INIT_GLOBAL_DATA_RDTX

*&---------------------------------------------------------------------*
*&      Form  SINGLE_READ_RDTX
*&---------------------------------------------------------------------*
*       Bestimme genau einen Rundungsprofil-Kurztext
*----------------------------------------------------------------------*
*      -->P_G_U05  Eingabeparameter des FB
*----------------------------------------------------------------------*
FORM single_read_rdtx USING value(p_g_u05) LIKE g_u05.

  DATA:  l_entry_found      TYPE  c.

  CLEAR:  l_entry_found.

*                *** 1. Plausi-Prüfung
  PERFORM check_input_single_rdtx USING p_g_u05.

  IF p_g_u05-i_read_with_buffer = c_yes.
*                *** 2. Mit Pufferung lesen => suche Eintrag im Puffer
    PERFORM read_buffer_rdtx  USING     p_g_u05
                              CHANGING  l_entry_found.
  ENDIF.

  IF l_entry_found = c_no.
*                *** 3. Lese direkt von der DB
    PERFORM read_db_rdtx  USING  p_g_u05.
  ENDIF.


ENDFORM.                               " SINGLE_READ_RDTX

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_SINGLE_RDTX
*&---------------------------------------------------------------------*
*       Führe Plausiprüfung auf den Eingabewerten des FB für
*       das Lesen eines einzelnen Rundungsprofils durch
*----------------------------------------------------------------------*
*      -->P_G_U05  Eingabeparameter des FB
*----------------------------------------------------------------------*
FORM check_input_single_rdtx USING value(p_g_u05) LIKE g_u05.

*                *** 1. allgemeine Plausi-Prüfung
  PERFORM check_input_general_rdtx USING p_g_u05.

*                *** 2. Spezielle Prüfungen
*                ***    - Rundungsprofil muss gefüllt sein
  IF p_g_u05-i_rdprf IS INITIAL.
    MESSAGE e004(rpugen) WITH 'MD_READ_RDTX'
                              'i_rdprf'
                               p_g_u05-i_rdprf
                         RAISING bad_params.
  ENDIF.

*                ***    - Sprachkennzeichen muss gefüllt sein
  IF p_g_u05-i_spras IS INITIAL.
    MESSAGE e004(rpugen) WITH 'MD_READ_RDTX'
                              'i_spras'
                              p_g_u05-i_spras
                         RAISING bad_params.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_SINGLE_RDTX

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_GENERAL_RDTX
*&---------------------------------------------------------------------*
*       Allgemeine Eingabeprüfungen
*----------------------------------------------------------------------*
*      -->P_G_U05
*----------------------------------------------------------------------*
FORM check_input_general_rdtx USING  value(p_g_u05) LIKE g_u05.

  IF NOT (   p_g_u05-i_read_with_buffer = c_yes
          OR p_g_u05-i_read_with_buffer = c_no ).
    MESSAGE e004(rpugen) WITH 'MD_READ_RDTX'
                              'i_read_with_buffer'
                              p_g_u05-i_read_with_buffer
            RAISING bad_params.
  ENDIF.

  IF NOT (   p_g_u05-i_buffer_on = c_yes
          OR p_g_u05-i_buffer_on = c_no ).
    MESSAGE e004(rpugen) WITH 'MD_READ_RDTX'
                              'i_buffer_on'
                              p_g_u05-i_buffer_on
                         RAISING bad_params.
  ENDIF.

  IF p_g_u05-i_buffer_size  <  0.
    MESSAGE e004(rpugen) WITH 'MD_READ_RDTX'
                              'i_buffer_size'
                              p_g_u05-i_buffer_size
                         RAISING bad_params.
  ENDIF.

*                *** Die Kombination eingeschalteter Puffer und direkt
*                *** Lesen von der DB ist nicht erlaubt!!!
  IF     p_g_u05-i_buffer_on = c_yes
     AND p_g_u05-i_read_with_buffer = c_no.
    MESSAGE e076 RAISING bad_params.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_GENERAL_RDTX

*&---------------------------------------------------------------------*
*&      Form  READ_BUFFER_RDTX
*&---------------------------------------------------------------------*
*       Lese aus den gepufferten Daten:
*       1. Vergleich mit dem letzten gelesenen Kurztext
*       2. Suche in den gepufferten Daten
*----------------------------------------------------------------------*
*      -->P_G_U05  text
*      <--P_ENTRY_FOUND  text
*----------------------------------------------------------------------*
FORM read_buffer_rdtx USING    value(p_g_u05)        LIKE g_u05
                      CHANGING value(p_entry_found)  TYPE c.

  DATA:  l_t_save_last_rdtx LIKE   g_t_last_rdtx
                            OCCURS 0 WITH HEADER LINE.

  CLEAR:  l_t_save_last_rdtx[].


  IF     p_g_u05-i_rdprf = g_last_rdtx_rdprf
     AND p_g_u05-i_werks = g_last_rdtx_werks
     AND p_g_u05-i_spras = g_last_rdtx_spras.
*                *** Rundungsprofil entspricht dem letzten ge-
*                *** lesenen Rundungsprofil
    p_entry_found = c_yes.

  ELSE.
*                *** Suche im Puffer:

*                *** Sicherung des letzten gelesenen RundProfils
    CLEAR l_t_save_last_rdtx[].
    l_t_save_last_rdtx[] = g_t_last_rdtx[].
    CLEAR g_t_last_rdtx[].

*                *** Durchsuche den Puffer
    LOOP AT g_t_rdtx_buffer
      WHERE rdprf = p_g_u05-i_rdprf
        AND werks = p_g_u05-i_werks
        AND spras = p_g_u05-i_spras.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdtx.
      MOVE-CORRESPONDING g_t_rdtx_buffer TO g_t_last_rdtx.
      APPEND g_t_last_rdtx.

    ENDLOOP.

    IF p_entry_found = c_yes.
*                *** Restliche Daten des letzten gelesenen RundProfils
*                *** merken
      g_last_rdtx_werks = p_g_u05-i_werks.
      g_last_rdtx_rdprf = p_g_u05-i_rdprf.
      g_last_rdtx_spras = p_g_u05-i_spras.
    ELSE.
*                *** Kein gepufferter Eintrag gefunden
*                ***  => für letzten gelesenen Kurztext alte Situation
*                ***     wiederherstellen
      g_t_last_rdtx[] = l_t_save_last_rdtx[].
    ENDIF.

  ENDIF.

ENDFORM.                               " READ_BUFFER_RDTX

*&---------------------------------------------------------------------*
*&      Form  READ_DB_RDTX
*&---------------------------------------------------------------------*
*       Lese direkt von der DB
*----------------------------------------------------------------------*
*      -->P_G_U05
*----------------------------------------------------------------------*
FORM read_db_rdtx USING value(p_g_u05) LIKE g_u05.

  DATA:  l_t_save_last_rdtx LIKE   g_t_last_rdtx
                            OCCURS 0 WITH HEADER LINE.

*                *** Sicherung des letzten gelesenen RundProfils
  CLEAR l_t_save_last_rdtx[].
  l_t_save_last_rdtx[] = g_t_last_rdtx[].
  CLEAR g_t_last_rdtx[].

*                *** Lese RundProfil von der DB
  SELECT       *
    FROM       rdtx
    INTO TABLE g_t_last_rdtx           " in letzer gelesener Kurztext
   WHERE       werks = p_g_u05-i_werks
     AND       rdprf = p_g_u05-i_rdprf
     AND       spras = p_g_u05-i_spras.

  IF sy-subrc <> 0.
*                *** => für letztes gelesenes RundProfil alte Situation
*                ***    wiederherstellen
    g_t_last_rdtx[] = l_t_save_last_rdtx[].
*                ***    Fehlermeldung
    MESSAGE e007(rpudb) WITH p_g_u05-i_rdprf
                             p_g_u05-i_werks
                             p_g_u05-i_spras
                        RAISING no_entry_found.
  ENDIF.

*                *** Restliche Daten des letzten gelesenen RundProfils
*                *** merken
  g_last_rdtx_werks = p_g_u05-i_werks.
  g_last_rdtx_rdprf = p_g_u05-i_rdprf.
  g_last_rdtx_spras = p_g_u05-i_spras.

  IF p_g_u05-i_buffer_on    =  c_yes.
*                *** gelesene Daten auch in Puffer übernehmen
    PERFORM fill_up_buffer_rdtx USING p_g_u05.
  ENDIF.

ENDFORM.                               " READ_DB_RDTX

*&---------------------------------------------------------------------*
*&      Form  FILL_UP_BUFFER_RDTX
*&---------------------------------------------------------------------*
*       Die gelesenen Daten aus der DB werden in den Puffer
*       übernommen.
*----------------------------------------------------------------------*
*      -->P_G_U05
*----------------------------------------------------------------------*
FORM fill_up_buffer_rdtx USING value(p_g_u05) LIKE g_u05.

  DATA: l_rdprf LIKE rdtx-rdprf,
        l_werks LIKE rdtx-werks,
        l_spras LIKE rdtx-spras.

  CLEAR: l_rdprf,
         l_werks,
         l_spras.

  IF p_g_u05-i_buffer_size  >  0.
*                *** 1. Eingeschränkte Puffergröße berücksichtigen:
    PERFORM check_buffer_size_rdtx USING p_g_u05.
  ENDIF.

*                *** 2. neuer Eintrag in den Puffer übernehmen
  LOOP AT g_t_last_rdtx.

    CLEAR g_t_rdtx_buffer.
    MOVE-CORRESPONDING g_t_last_rdtx TO g_t_rdtx_buffer.
    APPEND g_t_rdtx_buffer.

    IF    l_rdprf <> g_t_last_rdtx-rdprf
       OR l_werks <> g_t_last_rdtx-werks
       OR l_spras <> g_t_last_rdtx-spras.
*                *** 3. Puffergröße um ein RundProfil-Eintrag erhöhen
      g_buffer_size_rdtx = g_buffer_size_rdtx + 1.
      l_rdprf = g_t_last_rdtx-rdprf.
      l_werks = g_t_last_rdtx-werks.
      l_spras = g_t_last_rdtx-spras.
    ENDIF.

  ENDLOOP.

ENDFORM.                               " FILL_UP_BUFFER_RDTX

*&---------------------------------------------------------------------*
*&      Form  CHECK_BUFFER_SIZE_RDTX
*&---------------------------------------------------------------------*
*       Überprüfe ob die vorgeschriebene Puffergröße durch
*       einen neuen Satz eingehalten werden kann.
*----------------------------------------------------------------------*
*      -->P_G_U05
*----------------------------------------------------------------------*
FORM check_buffer_size_rdtx USING  value(p_g_u05) LIKE g_u05.

*                *** Wenn maximale Puffergröße erreicht oder über-
*                *** schritten ist, lösche die ältesten Einträge
*                *** (Kurztexte) bis der neue Kurztext
*                *** ohne Puffergrößenüberschreitung gepuffert
*                *** werden kann.
  WHILE g_buffer_size_rdtx  >= p_g_u05-i_buffer_size.
*                *** Der 1. Eintrag im Puffer ist immmer der älteste
    DELETE g_t_rdtx_buffer INDEX 1.
*                *** Puffergröße wird um ein Profil-Eintrag kleiner
    g_buffer_size_rdtx = g_buffer_size_rdtx - 1.

  ENDWHILE.

ENDFORM.                               " CHECK_BUFFER_SIZE_RDTX

*&---------------------------------------------------------------------*
*&      Form  READ_ALL_RDTX
*&---------------------------------------------------------------------*
*       Bestimme viele Rundungsprofil-Definition
*----------------------------------------------------------------------*
*      -->P_G_U05  Eingabeparameter des FB
*----------------------------------------------------------------------*
FORM read_all_rdtx USING value(p_g_u05) LIKE g_u05.

  DATA:  l_entry_found      TYPE  c.

  CLEAR:  l_entry_found.

*                *** 1. Eingabe Plausi-Prüfung
  PERFORM check_input_all_rdtx USING p_g_u05.

  IF p_g_u05-i_read_with_buffer = c_yes.
*                *** 2. Mit Pufferung lesen => suche Einträge im Puffer
    PERFORM read_buffer_all_rdtx USING     p_g_u05
                                 CHANGING  l_entry_found.
  ENDIF.

  IF l_entry_found = c_no.
*                *** 3. Lese direkt von der DB
    PERFORM read_db_all_rdtx  USING  p_g_u05.
  ENDIF.

ENDFORM.                               " READ_ALL_RDTX

*&---------------------------------------------------------------------*
*&      Form  CHECK_INPUT_ALL_RDTX
*&---------------------------------------------------------------------*
*       Eingabe-Prüfung bei lesen von allen Rundungsprofilen
*----------------------------------------------------------------------*
*      -->P_G_U05
*----------------------------------------------------------------------*
FORM check_input_all_rdtx USING value(p_g_u05) LIKE g_u05.

*                *** 1. allgemeine Plausi-Prüfung
  PERFORM check_input_general_rdtx USING p_g_u05.

*                *** 2. Spezielle Prüfungen
*                ***    - Rundungsprofil und Sprache
*                ***      dürfen nicht gleichzeitig belegt sein
  IF    ( NOT p_g_u05-i_rdprf IS INITIAL )
    AND ( NOT p_g_u05-i_spras IS INITIAL ).
    MESSAGE e078  RAISING bad_params.
  ENDIF.

*                ***    - Puffergröße muss auf 0 stehen
*                ***      => keine Beschränkung
  IF p_g_u05-i_buffer_size <> 0.
    MESSAGE e004(rpugen) WITH 'MD_READ_RDTX'
                              'i_buffer_size'
                              p_g_u05-i_buffer_size
                         RAISING bad_params.
  ENDIF.

ENDFORM.                               " CHECK_INPUT_ALL_RDTX

*&---------------------------------------------------------------------*
*&      Form  READ_BUFFER_ALL_RDTX
*&---------------------------------------------------------------------*
*       Lese alle Einträge aus dem Puffer
*----------------------------------------------------------------------*
*      -->P_G_U05
*      <--P_ENTRY_FOUND
*----------------------------------------------------------------------*
FORM read_buffer_all_rdtx USING    value(p_g_u05)       LIKE g_u05
                          CHANGING value(p_entry_found) TYPE c.

  DATA:  l_t_save_last_rdtx LIKE   g_t_last_rdtx
                            OCCURS 0 WITH HEADER LINE.

*                *** Sicherung des letzten gelesenen RundProfils
  CLEAR l_t_save_last_rdtx[].
  l_t_save_last_rdtx[] = g_t_last_rdtx[].
  CLEAR g_t_last_rdtx[].

*                ***    Fallunterscheidung: Kombinationsmöglichkeiten
*                ***    werks  rdprf  spras |    Fall
*                ***    --------------------|-----------
*                ***    init   init   init  | => a)
*                ***    init   init   bele  | => b)
*                ***    init   bele   init  | => c)
*                ***    init   bele   bele  | => Fehler => siehe Check_.
*                ***    bele   init   init  | => e)
*                ***    bele   init   bele  | => d)
*                ***    bele   bele   init  | => f)
*                ***    bele   bele   bele  | => Fehler => siehe Check_.

  IF         p_g_u05-i_rdprf IS INITIAL
         AND p_g_u05-i_werks IS INITIAL
         AND p_g_u05-i_spras IS INITIAL.
*                *** a) Alle RundProfile
    IF g_buffer_size > 0.
      g_t_last_rdtx[] = g_t_rdtx_buffer[].     " komplett kopieren
      p_entry_found = c_yes.
    ENDIF.

  ELSEIF     ( NOT p_g_u05-i_rdprf IS INITIAL )
         AND p_g_u05-i_werks IS INITIAL.
*                *** b) Alle Werksprofile-Kurzte. zu dem gleichen Profil
    LOOP AT g_t_rdtx_buffer
      WHERE rdprf = p_g_u05-i_rdprf.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdtx.
      MOVE-CORRESPONDING g_t_rdtx_buffer TO g_t_last_rdtx.
      APPEND g_t_last_rdtx.

    ENDLOOP.

  ELSEIF     ( NOT p_g_u05-i_spras IS INITIAL )
         AND p_g_u05-i_werks IS INITIAL.
*                *** c) alle Rundungsprofile-Kurztexte zu einer Sprache
    LOOP AT g_t_rdtx_buffer
      WHERE spras = p_g_u05-i_spras.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdtx.
      MOVE-CORRESPONDING g_t_rdtx_buffer TO g_t_last_rdtx.
      APPEND g_t_last_rdtx.

    ENDLOOP.

  ELSEIF     ( NOT p_g_u05-i_spras IS INITIAL )
         AND ( NOT p_g_u05-i_werks IS INITIAL ).
*                *** d) alle Werksprofile-Kurztexte in einer Sprache
    LOOP AT g_t_rdtx_buffer
      WHERE spras = p_g_u05-i_spras
        AND werks = p_g_u05-i_werks.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdtx.
      MOVE-CORRESPONDING g_t_rdtx_buffer TO g_t_last_rdtx.
      APPEND g_t_last_rdtx.

    ENDLOOP.

  ELSEIF     p_g_u05-i_rdprf IS INITIAL
         AND p_g_u05-i_spras IS INITIAL
         AND ( NOT p_g_u05-i_werks IS INITIAL ).
*                *** e) Alle Prpofil-Kurztexte zu einem Werk

    LOOP AT g_t_rdtx_buffer
      WHERE werks = p_g_u05-i_werks.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdtx.
      MOVE-CORRESPONDING g_t_rdtx_buffer TO g_t_last_rdtx.
      APPEND g_t_last_rdtx.

    ENDLOOP.

  ELSE.
*                *** f) alle Kurztexte zu einem Werk und
*                ***    Profil

    LOOP AT g_t_rdtx_buffer
      WHERE werks = p_g_u05-i_werks
        AND rdprf = p_g_u05-i_rdprf.

*                *** Satz gefunden => Abspeichern im letzten gelsenen
*                ***                  Rundungsprofils
      p_entry_found = c_yes.
      CLEAR g_t_last_rdtx.
      MOVE-CORRESPONDING g_t_rdtx_buffer TO g_t_last_rdtx.
      APPEND g_t_last_rdtx.

    ENDLOOP.

  ENDIF.

  IF p_entry_found = c_yes.
*                *** Restliche Daten des letzten gelesenen Kurztext
*                *** löschen!!!!
    CLEAR: g_last_rdtx_werks,
           g_last_rdtx_rdprf,
           g_last_rdtx_spras.
  ELSE.
*                *** Kein gepufferter Eintrag gefunden
*                ***  => für letzten gelesenen Kurztext alte Situation
*                ***     wiederherstellen
    g_t_last_rdtx[] = l_t_save_last_rdtx[].

  ENDIF.


ENDFORM.                               " READ_BUFFER_ALL_RDTX

*&---------------------------------------------------------------------*
*&      Form  READ_DB_ALL_RDTX
*&---------------------------------------------------------------------*
*       Lese alle Profile direkt von der DB
*----------------------------------------------------------------------*
*      -->P_G_U05
*----------------------------------------------------------------------*
FORM read_db_all_rdtx USING  value(p_g_u05) LIKE g_u05.

  DATA:  l_t_save_last_rdtx LIKE   g_t_last_rdtx
                            OCCURS 0 WITH HEADER LINE.

*                *** Sicherung des letzten gelesenen RundProfils
  CLEAR l_t_save_last_rdtx[].
  l_t_save_last_rdtx[] = g_t_last_rdtx[].
  CLEAR g_t_last_rdtx[].

*                ***    Fallunterscheidung: Kombinationsmöglichkeiten
*                ***    werks  rdprf  spras |    Fall
*                ***    --------------------|-----------
*                ***    init   init   init  | => a)
*                ***    init   init   bele  | => b)
*                ***    init   bele   init  | => c)
*                ***    init   bele   bele  | => Fehler => siehe Check_.
*                ***    bele   init   init  | => e)
*                ***    bele   init   bele  | => d)
*                ***    bele   bele   init  | => f)
*                ***    bele   bele   bele  | => Fehler => siehe Check_.

  IF         p_g_u05-i_rdprf IS INITIAL
         AND p_g_u05-i_werks IS INITIAL
         AND p_g_u05-i_spras IS INITIAL.
*                *** a) Alle Kurztexte
    SELECT       *
      FROM       rdtx
      INTO TABLE g_t_last_rdtx.

  ELSEIF     ( NOT p_g_u05-i_rdprf IS INITIAL )
         AND p_g_u05-i_werks IS INITIAL.
*                *** b) Alle Werksprofile-Kurzte. zu dem gleichen Profil
    SELECT       *
      FROM       rdtx
      INTO TABLE g_t_last_rdtx
     WHERE       rdprf = p_g_u05-i_rdprf.

  ELSEIF     ( NOT p_g_u05-i_spras IS INITIAL )
         AND p_g_u05-i_werks IS INITIAL.
*                *** c) alle Kurztexte in einer Sprache
    SELECT       *
      FROM       rdtx
      INTO TABLE g_t_last_rdtx
     WHERE       spras = p_g_u05-i_spras.

  ELSEIF     ( NOT p_g_u05-i_spras IS INITIAL )
         AND ( NOT p_g_u05-i_werks IS INITIAL ).
*                *** d) alle Werksprofile-Kuztexte in einer Sprache
    SELECT       *
      FROM       rdtx
      INTO TABLE g_t_last_rdtx
     WHERE       werks = p_g_u05-i_werks
       AND       spras = p_g_u05-i_spras.

  ELSEIF     p_g_u05-i_rdprf IS INITIAL
         AND p_g_u05-i_spras IS INITIAL
         AND ( NOT p_g_u05-i_werks IS INITIAL ).
*                *** e) Alle Profil-Kurztexte zu einem Werk
    SELECT       *
      FROM       rdtx
      INTO TABLE g_t_last_rdtx
     WHERE       werks = p_g_u05-i_werks.

  ELSE.
*                *** f) alle Kiuztexte  zu einem Werk und
*                ***    Profil
    SELECT       *
      FROM       rdtx
      INTO TABLE g_t_last_rdtx
     WHERE       werks = p_g_u05-i_werks
       AND       rdprf = p_g_u05-i_rdprf.

  ENDIF.

  IF sy-subrc <> 0.
*                *** => für letztes gelesenes RundProfil alte Situation
*                ***    wiederherstellen
    g_t_last_rdtx[] = l_t_save_last_rdtx[].
*                ***    Fehlermeldung
    MESSAGE e007(rpudb) WITH p_g_u05-i_rdprf
                             p_g_u05-i_werks
                             p_g_u05-i_spras
                        RAISING no_entry_found.
  ENDIF.

*                *** Restliche Daten des letzten gelesenen RundProfils
*                *** löschen
  CLEAR: g_last_rdtx_werks,
         g_last_rdtx_rdprf,
         g_last_rdtx_spras.

  IF p_g_u05-i_buffer_on    =  c_yes.
*                *** gelesene Daten auch in Puffer übernehmen
    PERFORM fill_up_buffer_rdtx USING p_g_u05.
  ENDIF.

ENDFORM.                               " READ_DB_ALL_RDTX

*
* 
