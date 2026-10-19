*----------------------------------------------------------------------*
***INCLUDE LMDR1F06 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       12.03.98  4.0c mwe         Wichtige Unterprogramme für alle
*-                                  Funktionsbausteine dieser Funktions-
*-                                  gruppe
*- @001  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @002  24.09.01  470  mbi         Entfernen von nicht mehr
*-                                  durchlaufenem Coding, das aufgrund
*-                                  der Überarbeitung des Bausteins zur
*-                                  Simulation von Rundungsprofilen
*-                                  (MD_SIMU_DYN_RUND_PROFIL) entstanden
*-                                  ist
*-       01.01.02  4.70 mwe         Altes Coding auskommentiert bzw.
*-                                  in INCLUDEs LMDR1FCF und LMDR1FGE
*-                                  verschoben
*-                                  (ohne Änderungsmarke)
*-----------------------------------------------------------------------
**&---------------------------------------------------------------------
*
**&      Form  FALID_OUTPUT_FOR_UNITS
**&---------------------------------------------------------------------
*
**       Es werden nur für die entsprechende Mengeneiheit gültige
**       Dezimalstellen zurückgegeben.
**----------------------------------------------------------------------
*
**      -->P_G_U02 (by reference)
**      <--P_G_U02 (by reference)
**---------------------------------------------------------------
*FORM FALID_OUTPUT_FOR_UNITS USING    P_G_U02 LIKE G_U02.
*
** lokale Daten
*  DATA: L_SAVE TYPE mdr1p_p_16_dec_14.                          " @002
*
** - bei der logistischen Menge
*  L_SAVE   = G_U02-E_LMENGE.
*  PERFORM USE_DECAN  USING G_U02-E_LMENGE
*                           G_U02-E_LOGME.
*  IF G_U02-E_LMENGE <> L_SAVE.
*    PERFORM RUNDUNGSGRUND USING MDR1P_C_DECIMALS.
*  ENDIF.
*
** - bei der Ausgabemenge (in Eingabemengeneinheit)
*  L_SAVE   = G_U02-E_MENGE.
*  PERFORM USE_DECAN  USING G_U02-E_MENGE
*                           G_U02-I_MEINS.
*  IF G_U02-E_MENGE <> L_SAVE.
*    PERFORM RUNDUNGSGRUND USING MDR1P_C_DECIMALS.
*  ENDIF.
*
*ENDFORM.                    " FALID_OUTPUT_FOR_UNITS
*
**&---------------------------------------------------------------------
*
**&      Form  CALL_MD_RDTX_READ
**&---------------------------------------------------------------------
*
**       Lesen der RDTX mit einem FB
**----------------------------------------------------------------------
*
**      -->p_spras     Sprache
**      -->p_rdprf     Rundungsprofil
**      -->p_werks     Werk
**      <--e_rdtx      RDTX-Eintrag
**----------------------------------------------------------------------
*
*FORM CALL_MD_RDTX_READ USING    VALUE(P_SPRAS)  LIKE RDTX-SPRAS
*                                VALUE(P_RDPRF)  LIKE RDTX-RDPRF
*                                VALUE(P_WERKS)  LIKE RDTX-WERKS
*                       CHANGING VALUE(E_RDTX)   LIKE RDTX.
*
*  DATA: L_T_RDTX LIKE RDTX OCCURS 0 WITH HEADER LINE.
*
*  CLEAR: E_RDTX,
*         L_T_RDTX[].
*
*  CALL FUNCTION 'MD_RDTX_READ'
*       EXPORTING
*            I_OPCODE           = '1'     " einzelner Eintrag lesen
*            I_RDPRF            = P_RDPRF
*            I_WERKS            = P_WERKS
*            I_SPRAS            = P_SPRAS
*            I_BUFFER_SIZE      = 0       " beliebig viele Einträge puff
.
*            I_BUFFER_ON        = c_yes   " gelesene Eint. puffern
*            I_READ_WITH_BUFFER = c_yes   " Lesen mit Pufferung
*       TABLES
*            E_T_RDTX           = L_T_RDTX
*       EXCEPTIONS
*            NO_ENTRY_FOUND     = 1
*            INVALID_OPCODE     = 2
*            BAD_PARAMS         = 3
*            OTHERS             = 4.
** Fehler wird in der Aufrufstelle abgefangen
*
*  IF SY-SUBRC = 0.
** Der Kuztext steht in der L_t_rdtx im 1. Eintrag
*    READ TABLE L_T_RDTX INDEX 1.
*    MOVE-CORRESPONDING L_T_RDTX TO E_RDTX.
*  ENDIF.
*
*ENDFORM.                    " CALL_MD_RDTX_READ
*
*
*$@002 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  CALL_MD_RDPR_READ
*$*&--------------------------------------------------------------------
*$-*
*$*       Lese die RDPR mit einem FB
*$*---------------------------------------------------------------------
*$-*
*$*      -->P_WERKS  Werk
*$*      -->P_RDPRF  Rundungsprofil
*$*      <--E_RDPR   Definition des Rundungsprofile
*$*---------------------------------------------------------------------
*$-*
*$FORM CALL_MD_RDPR_READ USING    VALUE(P_WERKS) LIKE RDPR-WERKS
*$                                VALUE(P_RDPRF) LIKE RDPR-RDPRF
*$                       CHANGING VALUE(E_RDPR)  LIKE RDPR.
*$
*$  DATA: L_T_RDPR LIKE RDPR OCCURS 0 WITH HEADER LINE.
*$
*$  CLEAR: E_RDPR,
*$         L_T_RDPR[].
*$
*$  CALL FUNCTION 'MD_RDPR_READ'
*$       EXPORTING
*$            I_OPCODE           = '1'     " einzelner Eintrag lesen
*$            I_RDPRF            = P_RDPRF
*$            I_WERKS            = P_WERKS
*$*           I_RDMPO            =
*$            I_BUFFER_ON        = 'X'     " gelesene Eint. puffern
*$           I_READ_WITH_BUFFER = 'X'     " Lesen mit Pufferung
*$            I_BUFFER_SIZE      = 0       " beliebig viele Einträge
*$puff.
*$       TABLES
*$            E_T_RDPR           = L_T_RDPR
*$       EXCEPTIONS
*$            NO_ENTRY_FOUND     = 1
*$            INVALID_OPCODE     = 2
*$          BAD_PARAMS         = 3
*$            OTHERS             = 4.
*$
*$* Fehler wird in der Aufrufstelle abgefangen
*$
*$  IF SY-SUBRC = 0.
*$* Rundungsprofil-Definition aus dem 1. Eintrag der Rückgabetabelle
*$* wird ausgegeben
*$    READ TABLE L_T_RDPR INDEX 1.
*$    MOVE-CORRESPONDING  L_T_RDPR TO E_RDPR.
*$  ENDIF.
*$
*$ENDFORM.                    " CALL_MD_RDPR_READ
*$@002 mbi 4.70 - Ende
*
*$@002 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  CALL_T_MD_RDPR_READ
*$*&--------------------------------------------------------------------
*$-*
*$*       Lese die RDPR mit einem FB mit Rückgabe Tabelle
*$*---------------------------------------------------------------------
*$-*
*$*      -->P_WERK  text
*$*      -->P_RDPRF  text
*$*      <--P_T_RDPR  text
*$*---------------------------------------------------------------------
*$-*
*$FORM CALL_T_MD_RDPR_READ TABLES   P_T_RDPR       STRUCTURE  RDPR
*$                         USING    VALUE(P_WERKS) LIKE       RDPR-WERKS
*$                                  VALUE(P_RDPRF) LIKE
*$RDPR-RDPRF.
*$
*$  CLEAR: P_T_RDPR[].
*$
*$  CALL FUNCTION 'MD_RDPR_READ'
*$       EXPORTING
*$            I_OPCODE           = '1'     " einzelner Eintrag lesen
*$            I_RDPRF            = P_RDPRF
*$            I_WERKS            = P_WERKS
*$*           I_RDMPO            =
*$            I_BUFFER_ON        = 'X'     " gelesene Eint. puffern
*$            I_READ_WITH_BUFFER = 'X'     " Lesen mit Pufferung
*$            I_BUFFER_SIZE      = 0       " beliebig viele Einträge
*$puff.
*$       TABLES
*$            E_T_RDPR           = P_T_RDPR
*$       EXCEPTIONS
*$            NO_ENTRY_FOUND     = 1
*$            INVALID_OPCODE     = 2
*$            BAD_PARAMS         = 3
*$            OTHERS             = 4.
*$
*$* Fehler wird in der Aufrufstelle abgefangen
*$
*$ENDFORM.                    " CALL_T_MD_RDPR_READ
*$@002 mbi 4.70 - Ende
*
**&---------------------------------------------------------------------
*
**&      Form  ENTER_ROUNDING_REASON
**&---------------------------------------------------------------------
*
**       Dieses Unterprogramm legt ein weiteren Eintrag
**       in eine Tabelle der Rundungsgründe an
**----------------------------------------------------------------------
*
**      -->P_T_ROUNDING_REASONS    Tabelle der bereits gesammelten
**                                 Rundungsgründe
**      -->P_I_ROUNDING_REASON     neuer Rundungsgrund
**      <--P_T_ROUNDING_REASONS    Tabelle der Rundungsgründe mit dem
**                                 weiteren Eintrag für den neuen
**                                 Rundungsgrund
**----------------------------------------------------------------------
*
*FORM ENTER_ROUNDING_REASON
*                     TABLES
*                       P_T_ROUNDING_REASONS TYPE MDR1P_T_RUNDUNGSGRUND
*                     USING
*                       P_I_ROUNDING_REASON  TYPE C.
*
**                *** Initialisiere die Kopfdaten der Tabelle
*  CLEAR: P_T_ROUNDING_REASONS.
*
**                *** Füge neuen Rundungsgrund hinzu
*  P_T_ROUNDING_REASONS-KZGRUND = P_I_ROUNDING_REASON.
*  APPEND P_T_ROUNDING_REASONS.
*
*ENDFORM.                    " ENTER_ROUNDING_REASON

*
* 
