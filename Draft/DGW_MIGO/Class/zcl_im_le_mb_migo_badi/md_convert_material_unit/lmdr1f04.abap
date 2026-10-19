*----------------------------------------------------------------------*
***INCLUDE LMDR1F04 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       12.03.98  4.0c welterm     Aufrufstelle Runde Menge von
*-                                  Verkaufshilfsmittel
*- @001  04.04.01  470  mwe         Unicode-Änderungen
*-                                  Entfernen von nicht mehr
*-                                  durchlaufenem Codeing
*- @002  01.01.02  470  mwe         Coding des FB
*-                                  MD_SIMU_DYN_RUND_PROFIL
*-                                  in dieses Include übernommen
*-----------------------------------------------------------------------

*$@002 Anfang
*&---------------------------------------------------------------------*
*&      Form  SIM_CHECK_PARAMS
*&---------------------------------------------------------------------*
*       Je nach Aufrufstelle (= OpCode) werden die entsprechenden
*       Eingabeparameter auf Korrektheit überprüft
*----------------------------------------------------------------------*
FORM sim_check_params.

  CASE g_u03-u02-i_opcode.

    WHEN mdr1p_c_op_maintain_rdpf.     " Aufruf bei Pflege Profil = '6'

*                *** Bei dem Aufruf bei der Pflege der Rundungsprofile
*                *** muessen die folgenden Parameter gefuellt sein
*                *** (Pflichtparameter):
*                ***    - i_werk   (Default: SPACES => keine Plausi)
*                ***    - i_rdpr   (Rundungsprofil)
*                ***    - i_rdprf  (Rundungsprofil-Bezeichner)
      IF    g_u03-u02-i_rdprf  IS  INITIAL
         OR g_u03-u02-i_rdpr   IS  INITIAL.
        RAISE bad_params.
      ENDIF.

*                *** Der Profil-Eintrag (i_rpdr) muss mit dem Profil-
*                *** Bezeichner und dem Werk uebereinstimmen!
      IF    g_u03-u02-i_rdpr-rdprf  <>  g_u03-u02-i_rdprf
         OR g_u03-u02-i_rdpr-werks  <>  g_u03-u02-i_werk.
        RAISE bad_profil.
      ENDIF.

    WHEN OTHERS.

      RAISE invalid_opcode.

  ENDCASE.

ENDFORM.                               " SIM_CHECK_PARAMS

*&---------------------------------------------------------------------*
*&      Form  SIM_MAINTAIN_RDPF
*&---------------------------------------------------------------------*
*       Fuehre die Simulation eines Rungsprofils beim Aufruf in
*       der Pflege von Rundungsprofilen (Prog SAPL0WCL, Transaktion
*       OWD1) durch.
*----------------------------------------------------------------------*
FORM sim_maintain_rdpf.

*                *** Vorbelegung der Ausgabefelder des Dynpros
*                *** mit den belegten Importparametern (Plausi
*                *** erfolgte in sim_check_param).
  rdpr         =  g_u03-u02-i_rdpr.    " Def. Rundungsprofil
  rdtx-text40  =  g_u03-i_text40.      " Name des Rundungsprofils
  t001w-name1  =  g_u03-i_name1.       " Name des Werks

  PERFORM initialization_0401.

  g_0401_rdprf    =  rdpr-rdprf.
  g_0401_werks    =  rdpr-werks.
*                *** Zur Sicherheit auch das Ausgabe-Feld für das Werk
*                *** korrekt belegen.
  g_0401_werks    =  g_u03-u02-i_werk.
*                *** Aufruf des neuen Eingabedynpros 401
  CALL SCREEN 0401
       STARTING AT 2 13.

ENDFORM.                               " SIM_PFLEGE_RDPF
*$@002 Ende


*$@001 Anfang MWE-ENTW-470-UNICODE
**&---------------------------------------------------------------------
*
**&      Form  ROUNDING_FOR_ADDITIONALS
**&---------------------------------------------------------------------
*
**       Für die Rundung für Verkaufshilfsmittel durch
**----------------------------------------------------------------------
*
**      -->P_G_U02  die Eingabeparameter des FB
**      <--P_G_U02  die Rückgabeparameter des FB (by reference)
**----------------------------------------------------------------------
*
*FORM ROUNDING_FOR_ADDITIONALS
*                        CHANGING  P_G_U02  LIKE G_U02.
*
**                *** Initialisierung der globalen und lokalen
**                *** Variablen
*  CLEAR: MARC,
*         MARA.
*
**                *** Default-Belegung der Ausgabe-Parameteren
**                *** (wichtig wenn keine Rundung durchgeführt
**                ***  wird)
*  P_G_U02-E_LMENGE = G_U02-I_MENGE.
*  P_G_U02-E_LOGME  = G_U02-I_MEINS.
*  P_G_U02-E_MENGE  = G_U02-I_MENGE.
*
*
**                *** Prüfe zuerst die Eingabewerte
*  PERFORM CHECK_IN_FOR_ADDIT  USING  P_G_U02.
*
**                *** Bestimme das Rundungsprofil, wenn es noch nicht
**                *** als Eingabewert vorliegt
*  IF P_G_U02-I_RDPRF IS INITIAL.
*    PERFORM RDPRF_FOR_ADDIT   CHANGING  P_G_U02.
*  ENDIF.
*
**                *** Führe die Rundung mit dem bestimmten Rundungs-
**                *** profil durch
*  PERFORM RUNDE USING  P_G_U02-I_RDPRF   " Eingabe oder MARC
*                       P_G_U02-I_MAX     " aus MARC oder leer
*                       P_G_U02-I_MIN     " aus MARC oder leer
*                       0                 " kein Rundungswert berücks.
*                       P_G_U02-I_MEINS.  " BestellME = BasisME
*
*
*ENDFORM.                    " ROUNDING_FOR_ADDITIONALS
*
**&---------------------------------------------------------------------
*
**&      Form  CHECK_IN_FOR_ADDIT
**&---------------------------------------------------------------------
*
**       Führe die Prüfung der Eingabewerte bei dem Aufruf
**       des FB für die Rundung von Verkaufshilfsmittel durch.
**----------------------------------------------------------------------
*
**      -->P_G_U02  text
**----------------------------------------------------------------------
*
*FORM CHECK_IN_FOR_ADDIT
*                     USING  VALUE(P_G_U02)  LIKE G_U02 .
*
**                *** Das Werk muss gefüllt sein
*  IF P_G_U02-I_WERK IS INITIAL.
*    MESSAGE E066 RAISING BAD_PARAMS.
*  ENDIF.
*
**                *** Der Artikel muss gefüllt sein
*  IF P_G_U02-I_MATNR IS INITIAL.
*    MESSAGE E065 RAISING BAD_PARAMS.
*  ENDIF.
*
**                *** Lese die Stammdatentabelle MARA zu dem Material
**                *** Bestimme Basismengeneinheit
**                *** => gelesene Werte stehen in der MARA-Struktur
*  PERFORM READ_MARA USING P_G_U02-I_MATNR.
*
*  IF SY-SUBRC <> 0.
*    MESSAGE E068  WITH P_G_U02-I_MATNR
*                  RAISING MATERIAL_NOT_FOUND.
*  ENDIF.
*
**                *** Die Eingabemengeneinheit muss die Basismengen
**                *** Einheit sein
*  IF P_G_U02-I_MEINS <> MARA-MEINS.
*    MESSAGE E069  WITH P_G_U02-I_MEINS  MARA-MEINS
*                  RAISING BAD_PARAMS.
*  ENDIF.
*
*ENDFORM.                    " CHECK_IN_FOR_ADDIT
*
**&---------------------------------------------------------------------
*
**&      Form  RDPRF_FOR_ADDIT
**&---------------------------------------------------------------------
*
**       Bestimme das Rundungsprofil für die Rundung
**       von Verkaufshilfsmittel aus der MARC
**----------------------------------------------------------------------
*
**      -->P_G_U02 (by reference)
**      <--P_G_U02 (by reference)
**----------------------------------------------------------------------
*
*FORM RDPRF_FOR_ADDIT
*                   CHANGING  P_G_U02 LIKE G_U02.
*
**                *** Lese die MARC mit einem FB, das Ergebnis befindet
**                *** sich in der Struktur MARC
*  PERFORM READ_MARC  USING  P_G_U02-I_MATNR
*                            P_G_U02-I_WERK.
*
*  IF SY-SUBRC <> 0.
*    MESSAGE E067 WITH P_G_U02-I_WERK P_G_U02-I_MATNR
*                 RAISING RDPRF_NOT_FOUND.
*  ENDIF.
*
*  IF MARC-RDPRF IS INITIAL.
*    MESSAGE E070 WITH P_G_U02-I_WERK P_G_U02-I_MATNR
*                 RAISING RDPRF_NOT_FOUND.
*  ENDIF.
*
*  P_G_U02-I_RDPRF       =  MARC-RDPRF.
*  P_G_U02-I_MAX         =  MARC-BSTMA.
*  P_G_U02-I_MIN         =  MARC-BSTMI.
*
*ENDFORM.                    " RDPRF_FOR_ADDIT
*$@001 Ende MWE-ENTW-470-UNICODE

*
* 
