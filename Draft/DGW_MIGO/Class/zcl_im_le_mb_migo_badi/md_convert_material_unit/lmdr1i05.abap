*----------------------------------------------------------------------*
***INCLUDE LMDR1I05 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       25.03.98  4.0c welterm     Erweiterungen für 40c:
*-                                  - neue Transaktion zum Aufruf
*-                                    der Simulation
*- @001  24.09.01  4.70 mbi         Änderung der Implementation der F4-
*-                                  Hilfe für das Feld 'RDPR-RDPRF' des
*-                                  Dynpros '0500', da Coding veraltert.
*- @002  26.09.01  4.70 mbi         Implementierung einer F4-Hilfe für
*-                                  das Feld 'RDPR-WERKS' des Dynpros
*-                                  '0500'.
*- @003  02.10.01  4.70 mbi         Implementierung der Transaktion
*-                                  'WLB8' mittels des neuen FB
*-                                  'MDR1_SIMU_ROUNDING'.
*-       01.01.02  4.70 mwe         Altes Coding auskommentiert
*-                                  (ohne Änderungsmarke)
*-----------------------------------------------------------------------

**&---------------------------------------------------------------------
*
**&      Module  EXIT_0500  INPUT
**&---------------------------------------------------------------------
*
**       Abbruch der Verarbeitung in DynPro 0500
**----------------------------------------------------------------------
*
*MODULE exit_0500 INPUT.
*
**$@003 mbi 4.70 - Anfang
**$  SET SCREEN 0.
*  SET SCREEN 0800.
**$@003 mbi 4.70 - Ende
*  LEAVE SCREEN.
*
*ENDMODULE.                             " EXIT_0500  INPUT
*
**&---------------------------------------------------------------------
*
**&      Module  CHECK_INPUT_WERKS_0500  INPUT
**&---------------------------------------------------------------------
*
**       Wird im Dynpro 0500 ein Werk eingeben, so wird geprüft
*
**       ob das Werk in der Tabelle T001W enthalten ist. Ist dies
*
**       nicht der Fall wird eine Fehlermeldung ausgegeben und das
**       Werk ist zur Eingabe bereit.
**----------------------------------------------------------------------
*
*MODULE check_input_werks_0500 INPUT.
*
*  IF NOT rdpr-werks IS INITIAL.
*
*    SELECT SINGLE  *  FROM t001w
*            WHERE  werks = rdpr-werks.
*
*    IF sy-subrc <> 0.
*      MESSAGE e000(6r) WITH rdpr-werks .
*    ENDIF.
*
*  ENDIF.
*
*ENDMODULE.                             " CHECK_INPUT_WERKS_0500  INPUT
*
**&---------------------------------------------------------------------
*
**&      Module  SAVE_OK_CODE_0500  INPUT
**&---------------------------------------------------------------------
*
**       Das feld ok_code wird im save_ok_code gerettet. Der ok_code
*
**       wird anschließend initialisiert.
*
**----------------------------------------------------------------------
*
*MODULE save_ok_code_0500 INPUT.
*
*  save_ok_code = ok_code.
*  CLEAR ok_code.
*
*ENDMODULE.                             " SAVE_OK_CODE_0500  INPUT
*
**&---------------------------------------------------------------------
*
**&      Module  CHECK_ALL_INPUT_0500  INPUT
**&---------------------------------------------------------------------
*
**       Es werden die beiden Eingabefelder gegen die Tabelle RDPR
*
**       geprüft.
*
**----------------------------------------------------------------------
*
*MODULE check_all_input_0500 INPUT.
*
*  IF   save_ok_code = c_fc_simu
*     OR save_ok_code = c_fc_cont.
*
*    SELECT  *  FROM rdpr
*     WHERE  rdprf = rdpr-rdprf
*       AND  werks = rdpr-werks.
*    ENDSELECT.
*
*    IF sy-subrc <> 0.
*      MESSAGE e079(6r).
*    ENDIF.
*
*    SELECT  *  FROM rdtx
*     WHERE werks = rdpr-werks
*       AND rdprf = rdpr-rdprf
*       AND spras = sy-langu.
*    ENDSELECT.
*
*    IF sy-subrc <> 0.
*      rdtx-spras = sy-langu.
*      rdtx-werks = rdpr-werks.
*      rdtx-rdprf = rdpr-rdprf.
*      CLEAR rdtx-text40.
*    ENDIF.
*
*  ENDIF.
*
*ENDMODULE.                             " CHECK_ALL_INPUT_0500  INPUT
**&---------------------------------------------------------------------
*
**&      Module  USER_COMMAND_0500  INPUT
**&---------------------------------------------------------------------
*
**       Führe die Funktionscodes durch => UAfruf dem Simulations-FB
**----------------------------------------------------------------------
*
*MODULE user_command_0500 INPUT.
*
*  IF save_ok_code = c_fc_simu.
*
**$@003 mbi 4.70 - Anfang
**$    CALL FUNCTION 'MD_SIMU_DYN_RUND_PROFIL'
**$      EXPORTING
**$        i_opcode       = '6'          " Steuerungs-Code
**$        i_werk         = rdpr-werks   " Werk des RundProfil
**$        i_rdpr         = rdpr         " Def. des RundProfil
**$        i_rdprf        = rdpr-rdprf   " Bez. RundProfil
**$        i_text40       = rdtx-text40  " Name Rundprofil
**$        i_name1        = t001w-name1  " Name des Werks
**$      EXCEPTIONS
**$        invalid_opcode = 1
**$        bad_params     = 6
**$        bad_profil     = 10
**$        OTHERS         = 11.
**$
**$    IF sy-subrc <> 0.
**$      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
**$         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**$    ENDIF.
*
**                *** Initialisiere Dynpro 0401
*    PERFORM initialization_0401.
*
*    g_0401_rdprf   =  rdpr-rdprf.
*    g_0401_werks   =  rdpr-werks.
*
*    LEAVE TO SCREEN 0401.
**$@003 mbi 4.70 - Ende
*
*  ENDIF.
*
*ENDMODULE.                             " USER_COMMAND_0500  INPUT
*
**&---------------------------------------------------------------------
*
**&      Module  F4_HEPL_FOR_RDPRF_0500  INPUT
**&---------------------------------------------------------------------
*
**       Dieses Modul realisiert eine Eingabehilfe fuer die
*
**       Felder RDPR-RDPRF und RDPR-WERKS
*
**----------------------------------------------------------------------
*
*MODULE f4_hepl_rdprf_0500 INPUT.
*
**$@001 mbi 4.70 - Anfang
**$  CLEAR GET_FELDER[].
**$  CLEAR UPD_FELDER[].
**$
**$  GET_FELDER-TABNAME   = 'RDPR'.
**$  GET_FELDER-FIELDNAME = 'WERKS'.
**$  APPEND GET_FELDER.
**$
**$  UPD_FELDER-TABNAME   = 'RDPR'.
**$  UPD_FELDER-FIELDNAME = 'RDPRF'.
**$  APPEND UPD_FELDER.
**$
**$  UPD_FELDER-TABNAME   = 'RDPR'.
**$  UPD_FELDER-FIELDNAME = 'WERKS'.
**$  APPEND UPD_FELDER.
**$
**$  CALL FUNCTION 'HELP_VALUES_GET_EXTEND'
**$       EXPORTING
**$*          DISPLAY      = ' '
**$          DYNAME       = 'SAPLMDR1'
**$          DYNUMB       = '0500'
**$          FIELDNAME    = 'RDPRF'
**$*          INPUT_VALUE  = ' '
**$          TABNAME      = 'RDPR'
**$          SHRINK       = 'X'
**$       IMPORTING
**$          RETURNCODE   = G_SY_SUBRC
**$*          SELECTION    =
**$*          SELECT_VALUE =
**$*          SELECT_INDEX =
**$       TABLES
**$          GETFIELDS    = GET_FELDER
**$          UPDFIELDS    = UPD_FELDER
**$       EXCEPTIONS
**$          OTHERS       = 1.
**$
**$  IF G_SY_SUBRC = C_SY_NOTFOUND.
**$    MESSAGE E037(6R).
**$  ENDIF.
**$
**$  IF SY-SUBRC = 1.
**$    MESSAGE E037(6R).
**$  ENDIF.
*
*  g_dynpprog = sy-repid.
*  g_dynpnr = sy-dynnr.
*
*  PERFORM f4help_rdpr_rdprf
*    USING
*      g_dynpprog
*      g_dynpnr
*      'RDPRF'
*      'RDPR-WERKS'
*      c_yes
*      c_yes.
**$@001 mbi 4.70 - Ende
*
**$@002 mbi 4.70 - Anfang
*ENDMODULE.                             " F4_HEPL_FOR_RDPRF_0500  INPUT
**&---------------------------------------------------------------------
*
**&      Module  f4_help_werks_0500  INPUT
**&---------------------------------------------------------------------
*
**       text
**----------------------------------------------------------------------
*
*MODULE f4_help_werks_0500 INPUT.
*
*  g_dynpprog = sy-repid.
*  g_dynpnr = sy-dynnr.
*
*  PERFORM f4help_rdpr_werks
*    USING
*      g_dynpprog
*      g_dynpnr.
*
*ENDMODULE.                 " f4_help_werks_0500  INPUT
**$@002 mbi 4.70 - Ende

*
* 
