FUNCTION md_rdtx_read.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"       IMPORTING
*"             VALUE(I_OPCODE) LIKE  SY-INPUT
*"             VALUE(I_RDPRF) LIKE  RDTX-RDPRF OPTIONAL
*"             VALUE(I_WERKS) LIKE  RDTX-WERKS OPTIONAL
*"             VALUE(I_SPRAS) LIKE  RDTX-SPRAS OPTIONAL
*"             VALUE(I_BUFFER_SIZE) TYPE  INT4 DEFAULT 0
*"             VALUE(I_BUFFER_ON) TYPE  C DEFAULT 'X'
*"             VALUE(I_READ_WITH_BUFFER) TYPE  C DEFAULT 'X'
*"       TABLES
*"              E_T_RDTX STRUCTURE  RDTX
*"       EXCEPTIONS
*"              NO_ENTRY_FOUND
*"              INVALID_OPCODE
*"              BAD_PARAMS
*"----------------------------------------------------------------------

*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       16.04.98  4.0c welterm     Grundversion für das Lesen der
*-                                  Rundungsprofile-Kurztexte aus
*-                                  der RDTX.
*-----------------------------------------------------------------------

*                *** Initialisierung:
  CLEAR: e_t_rdtx[],            " - Rückgabewerte
         g_u05.                 " - globale Struktur der Eingabepar.
*                ***              - die globalen Daten zur Pufferung
*                ***                werden nur beim 1. Mal initialisiert
  IF g_first_time_rdtx = c_yes.
    PERFORM init_global_data_rdtx.
  ENDIF.

*                *** Eingabewerte in globaler Struktur merken
  g_u05-i_opcode            =  i_opcode.
  g_u05-i_rdprf             =  i_rdprf.
  g_u05-i_werks             =  i_werks.
  g_u05-i_spras             =  i_spras.
  g_u05-i_buffer_on         =  i_buffer_on.
  g_u05-i_read_with_buffer  =  i_read_with_buffer.
  g_u05-i_buffer_size       =  i_buffer_size.

*                *** Duchführung unterschiedlicher Schritte bei ver-
*                *** schiedenen Steuerungscodes:
  CASE i_opcode.

    WHEN c_buffer_refrech.
*                *** Lösche alle Einträge im Puffer (=> zurück wie
*                *** beim 1. Aufruf)
      PERFORM init_global_data_rdtx.

    WHEN c_single_read.
*                *** Lese genau einer Rundungsprofil-Kurztexte
      PERFORM single_read_rdtx USING   g_u05.
*                *** Das Ergebnis steht in der globalen Tabelle:
*                *** g_t_last_rdtx => Fülle Rückgabe damit
      e_t_rdtx[] = g_t_last_rdtx[].

    WHEN c_read_all.
*                *** Lese viele Rundungsprofil-Kurztexte gleich-
*                *** zeitig
      PERFORM read_all_rdtx USING   g_u05.
*                *** Das Ergebnis steht in der globalen Tabelle:
*                *** g_t_last_rdtx => Fülle Rückgabe damit
      e_t_rdtx[] = g_t_last_rdtx[].

    WHEN OTHERS.
*                *** Falscher Steuerungscode
      MESSAGE e071 WITH 'MD_RDTX_READ' i_opcode
              RAISING invalid_opcode.

  ENDCASE.


ENDFUNCTION.

*
* 
