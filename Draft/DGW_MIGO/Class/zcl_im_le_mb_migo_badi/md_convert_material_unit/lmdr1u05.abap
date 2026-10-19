FUNCTION md_rdpr_read.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"       IMPORTING
*"             VALUE(I_OPCODE) LIKE  SY-INPUT
*"             VALUE(I_RDPRF) LIKE  RDPR-RDPRF OPTIONAL
*"             VALUE(I_WERKS) LIKE  RDPR-WERKS OPTIONAL
*"             VALUE(I_RDMPO) LIKE  RDPR-RDMPO OPTIONAL
*"             VALUE(I_BUFFER_ON) TYPE  C DEFAULT 'X'
*"             VALUE(I_READ_WITH_BUFFER) TYPE  C DEFAULT 'X'
*"             VALUE(I_BUFFER_SIZE) TYPE  INT4 DEFAULT 0
*"       TABLES
*"              E_T_RDPR STRUCTURE  RDPR
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
*-                                  Rundungsprofile-Definition aus
*-                                  der RDPR.
*-----------------------------------------------------------------------

*                *** Initialisierung:
  CLEAR: e_t_rdpr[],            " - Rückgabewerte
         g_u04.                 " - globale Struktur der Eingabepar.
*                ***              - die globalen Daten zur Pufferung
*                ***                werden nur beim 1. Mal initialisiert
  IF g_first_time = c_yes.
    PERFORM init_global_data_rdpr.
  ENDIF.

*                *** Eingabewerte in globaler Struktur merken
  g_u04-i_opcode            =  i_opcode.
  g_u04-i_rdprf             =  i_rdprf.
  g_u04-i_werks             =  i_werks.
  g_u04-i_rdmpo             =  i_rdmpo.
  g_u04-i_buffer_on         =  i_buffer_on.
  g_u04-i_read_with_buffer  =  i_read_with_buffer.
  g_u04-i_buffer_size       =  i_buffer_size.

*                *** Duchführung unterschiedlicher Schritte bei ver-
*                *** schiedenen Steuerungscodes:
  CASE i_opcode.

    WHEN c_buffer_refrech.
*                *** Lösche alle Einträge im Puffer (=> zurück wie
*                *** beim 1. Aufruf)
      PERFORM init_global_data_rdpr.

    WHEN c_single_read.
*                *** Lese genau einer Rundungsprofil-Definition
      PERFORM single_read_rdpr USING   g_u04.
*                *** Das Ergebnis steht in der globalen Tabelle:
*                *** g_t_last_rdpr => Fülle Rückgabe damit
      e_t_rdpr[] = g_t_last_rdpr[].

    WHEN c_read_all.
*                *** Lese viele Rundungsprofil-Definitionen gleich-
*                *** zeitig
      PERFORM read_all_rdpr USING   g_u04.
*                *** Das Ergebnis steht in der globalen Tabelle:
*                *** g_t_last_rdpr => Fülle Rückgabe damit
      e_t_rdpr[] = g_t_last_rdpr[].

    WHEN OTHERS.
*                *** Falscher Steuerungscode
      MESSAGE e071 WITH 'MD_RDPR_READ' i_opcode
              RAISING invalid_opcode.

  ENDCASE.


ENDFUNCTION.

*
* 
