*-------------------------------------------------------------------
***INCLUDE LMDR1I01 .
*-------------------------------------------------------------------
*- @001  04.04.01  470  mwe         Unicode-Änderungen
*-                                  - Parameter typisieren
*-                                  - entfernen von veraltertem Codeing
*-       01.01.02  4.70 mwe         Altes Coding auskommentiert
*-                                  (ohne Änderungsmarke)
*&---------------------------------------------------------------------*
*&      Module  HANDLE_EXIT  INPUT
*&---------------------------------------------------------------------*
MODULE handle_exit INPUT.
* muß ich hier noch die Datenübernahme 'einleiten' über den Returncode
  g_fcode = ok_code.
  CLEAR ok_code.

* Abbruch melden
  g_retcode = 1.

  CASE g_fcode.
    WHEN c_fc_back.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN c_fc_exit.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN c_fc_canc.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.                             " HANDLE_EXIT  INPUT
*&---------------------------------------------------------------------*
*&      Module  OK_CODE  INPUT
*&---------------------------------------------------------------------*
MODULE ok_code INPUT.

  g_fcode = ok_code.
  CLEAR ok_code.

  CASE sy-dynnr.

    WHEN c_dynpro_erfassung.
      PERFORM fcode_erfassung.

    WHEN c_dynpro_f4_amounts.
      PERFORM fcode_f4_amounts.

  ENDCASE.

ENDMODULE.                             " OK_CODE  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_BSTME  INPUT
*&---------------------------------------------------------------------*
MODULE check_altme INPUT.
  g_u01-kz_altme = c_yes.               "Feld wurde geändert
ENDMODULE.                             " CHECK_ALTME  INPUT
**&---------------------------------------------------------------------
*
**&      Module  HELP_ALTME  INPUT
**&---------------------------------------------------------------------
*
*MODULE help_altme INPUT.
*  PERFORM f4_altme.
*ENDMODULE.                             " HELP_ALTME  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_AMENGE  INPUT
*&---------------------------------------------------------------------*
MODULE check_amenge INPUT.
  g_u01-kz_amenge = c_yes.              "Feld wurde geändert
ENDMODULE.                             " CHECK_AMENGE  INPUT
**&---------------------------------------------------------------------
*
**&      Module  GET_LIST1  INPUT
**&---------------------------------------------------------------------
*
*MODULE get_list1 INPUT.
*  READ TABLE g_t_list1 INTO g_list1 INDEX 1.
*  g_u01-kz_amenge  = c_nein.
*  g_u01-kz_altme   = c_nein.
*  g_u01-kz_restmng = c_nein.
*ENDMODULE.                             " GET_LIST1  INPUT
**&---------------------------------------------------------------------
*
**&      Module  PUT_LIST1  INPUT
**&---------------------------------------------------------------------
*
*MODULE put_list1 INPUT.
*  g_t_list1 = g_list1.
*  MODIFY g_t_list1 INDEX 1.
*ENDMODULE.                             " PUT_LIST1  INPUT
**&---------------------------------------------------------------------
*
**&      Module  CHECK_RESTMNG  INPUT
**&---------------------------------------------------------------------
*
*MODULE check_restmng INPUT.
*  g_u01-kz_restmng = c_ja.             "Feld wurde geändert
*ENDMODULE.                             " CHECK_RESTMNG  INPUT
**&---------------------------------------------------------------------
*
**&      Module  VERBUND_PLAUSIS  INPUT
**&---------------------------------------------------------------------
*
*MODULE verbund_plausis INPUT.
*  IF     g_u01-kz_amenge  = c_nein AND
*         g_u01-kz_altme   = c_nein AND
*         g_u01-kz_restmng = c_nein.
*    EXIT.
*  ELSEIF g_u01-kz_amenge  = c_ja   AND
*         g_u01-kz_altme   = c_nein AND
*         g_u01-kz_restmng = c_nein.
*    PERFORM check_amenge.
*  ELSEIF g_u01-kz_amenge  = c_nein AND
*         g_u01-kz_altme   = c_ja   AND
*         g_u01-kz_restmng = c_nein.
*    PERFORM check_altme.
*  ELSEIF g_u01-kz_amenge  = c_nein AND
*         g_u01-kz_altme   = c_nein AND
*         g_u01-kz_restmng = c_ja.
*    PERFORM check_restmng.
*  ELSE.
**   mind. 2 der 3 Felder sind verändert => einfach Werte übernehmen
*    g_list1-altme   = g_t_list1-altme.
*    g_list1-restmng = g_t_list1-restmng.
*    PERFORM check_amenge.
*  ENDIF.
*
*  CLEAR g_u01-kz_amenge.
*  CLEAR g_u01-kz_altme.
*  CLEAR g_u01-kz_restmng.
*ENDMODULE.                             " VERBUND_PLAUSIS  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  CALCULATE_F4_AMOUNTS INPUT
*&---------------------------------------------------------------------*
MODULE calculate_f4_amounts INPUT.

  IF  g_u01-kz_amenge  = c_yes OR
      g_u01-kz_altme   = c_yes.
*$@001 Anfang MWE-ENTW-470-UNICODE
*    PERFORM CALCULATE_F4_AMOUNTS CHANGING G_F4_AMOUNTS.
    PERFORM calculate_f4_amounts  USING    g_f4_data-matnr
                                           g_f4_data-werk
                                           space
                                           g_f4_data-vabme
                                  CHANGING g_f4_amounts.
*$@001 Ende MWE-ENTW-470-UNICODE

  ENDIF.

  CLEAR g_u01-kz_amenge.
  CLEAR g_u01-kz_altme.
ENDMODULE.                             " CALCULATE_F4_AMOUNTS INPUT

*&---------------------------------------------------------------------*
*&      Module  HELP_MEINS INPUT
*&---------------------------------------------------------------------*
MODULE help_meins INPUT.
  PERFORM f4_meins.
ENDMODULE.                             " HELP_MEINS  INPUT



*---------------------------------------------------------------------*
*       MODULE PLAUSI_MEINS INPUT                                     *
*---------------------------------------------------------------------*
MODULE plausi_meins INPUT.
* ist eingegebene ME überhaupt erlaubt ... ?
  IF g_u01-kz_altme   = c_yes.
    PERFORM plausi_meins.
  ENDIF.
ENDMODULE.                             " PLAUSI_MEINS  INPUT

*
* 
