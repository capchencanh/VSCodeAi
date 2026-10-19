*----------------------------------------------------------------------*
***INCLUDE LMDR1FAL .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       21.09.01  470  mbi         Grundversion
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  mask_columns
*&---------------------------------------------------------------------*
*       Routine um die Spalten des ALV-Grid individuell anzupassen
*----------------------------------------------------------------------*
*  -->  p_meinh
*  -->  p_t_fieldcatalog    Globaler Feldkatalog, der die
*                           Eigenschaften jeder Spalte des ALV-Grid
*                           beschreibt. Wird anfangs initialisiert.
*  <--  p_tfieldcatalog     Dito, aber nun mit Daten gefüllt.
*----------------------------------------------------------------------*
FORM mask_columns
  USING
    value(p_meinh)     LIKE  marm-meinh
  CHANGING
    p_t_fieldcatalog   TYPE  lvc_t_fcat.

  DATA:  l_wa_fieldcatalog    TYPE lvc_s_fcat,
         l_wa_fieldcatalog_2  TYPE lvc_s_fcat,
         l_meinh_konv         LIKE p_meinh.

*                *** initialisiere zunächst die globale Tabelle
  CLEAR p_t_fieldcatalog.

*                *** baue den Feldkatalog gemäß der DDIC Strukur
*                *** mdr1alvsimurundprofil auf
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE              =
      i_structure_name             = c_structure_name_alvsim
                                     "= 'MDR1ALVSIMURUNDPROFIL'
*     I_CLIENT_NEVER_DISPLAY       = 'X'
*     I_BYPASSING_BUFFER           =
*     I_INTERNAL_TABNAME           =
    CHANGING
      ct_fieldcat                  = p_t_fieldcatalog
    EXCEPTIONS
      inconsistent_interface       = 1
      program_error                = 2
      error_message                = 98
      OTHERS                       = 99.

  IF sy-subrc <> 0.
* ??? Fehlerbehandlung
  ENDIF.

*                *** Um die ME in der aktuellen Sprach anzuzeigen, muss
*                *** zuerst eine entsprechende Konvertierung mit WRITE
*                *** vorgenommen werden!
  WRITE p_meinh  TO  l_meinh_konv.

*                *** passe die einzelnen Feldkatalog-Einträge an
*                *** individuelle Bedürfnisse an
  LOOP AT p_t_fieldcatalog
     INTO l_wa_fieldcatalog.


    CASE l_wa_fieldcatalog-fieldname.

      WHEN c_fieldname_fromamount.   " ='FROMAMOUNT'.

*                *** schreibe die Eingabe-ME in die Spaltenüberschrift
        CONCATENATE l_wa_fieldcatalog-reptext ' [' l_meinh_konv '] '
               INTO l_wa_fieldcatalog-coltext.

*                *** schreibe die Eingabe-ME in die Spaltenüberschrift
      WHEN c_fieldname_toamount.     " = 'TOAMOUNT'

        CONCATENATE l_wa_fieldcatalog-reptext ' [' l_meinh_konv '] '
               INTO l_wa_fieldcatalog-coltext.

*                *** schreibe die Eingabe-ME in die Spaltenüberschrift
      WHEN c_fieldname_roundamount.  " = 'ROUNDAMOUNT'

        CONCATENATE l_wa_fieldcatalog-reptext ' [' l_meinh_konv '] '
               INTO l_wa_fieldcatalog-coltext.

*                *** hebe die Spalte farblich hervor
        l_wa_fieldcatalog-emphasize = c_emphsz_colour_c500. " ='C500'

      WHEN c_fieldname_inqtunit.     " = 'INQTUNIT'

*                *** die Spalte mit der Mengeneinheit wird nicht
*                *** ausgegeben, da die Mengeneinheit schon in der
*                *** Spaltenüberschrift steht
        l_wa_fieldcatalog-no_out = c_yes.

      WHEN c_fieldname_roundlogam.   " = 'ROUNDLOGAMOUNT'

        LOOP AT p_t_fieldcatalog
           INTO l_wa_fieldcatalog_2.

          IF l_wa_fieldcatalog_2-fieldname  =  c_fieldname_logqtunit.
*                *** füge in der Spaltenüberschrift den Namen
*                *** der Spalte mit der Runungs-ME ein
            CONCATENATE l_wa_fieldcatalog-reptext
                        ' [' l_wa_fieldcatalog_2-scrtext_s '] '
                   INTO l_wa_fieldcatalog-coltext.

*                *** hebe die Spalte farblich hervor
            l_wa_fieldcatalog-emphasize = c_emphsz_colour_c510.

            EXIT.

          ENDIF.

        ENDLOOP.

      WHEN c_fieldname_logqtunit.    " = 'LOGQTUNIT'

*                *** hebe die Spalte farblich hervor
        l_wa_fieldcatalog-emphasize = c_emphsz_colour_c510. " = 'C510'.

    ENDCASE.

    MODIFY p_t_fieldcatalog
      FROM l_wa_fieldcatalog.

  ENDLOOP.

ENDFORM.                    " mask_columns

*&---------------------------------------------------------------------*
*&      Form  set_layout_alv
*&---------------------------------------------------------------------*
*       Routine, um das Layout des ALV-Grid-Controls zu definieren
*----------------------------------------------------------------------*
*  -->  p_s_layout_alv        Globale Struktur, in der das Layout des
*                             ALV-Grid beschrieben werden kann. Wird
*                             am Anfang initialisiert.
*  <--  p_s_layout_alv        Dito, aber nun mit Daten gefüllt.
*----------------------------------------------------------------------*
FORM set_layout_alv
  CHANGING
    p_s_layout_alv TYPE lvc_s_layo.

*                *** initialisiere zunächst die globale Strukur
  CLEAR p_s_layout_alv.

*                *** lege nun das Layout des ALV-Grid-Controls fest

*                *** Titel zwischen Grid-Control und Toolbar
  p_s_layout_alv-grid_title = text-808. " = 'Ergebnisse der Simulation'.

*                *** optimiere die Spaltenbreite
  p_s_layout_alv-cwidth_opt = c_yes.

*                *** bestimme die Selektionsmöglichkeiten
  p_s_layout_alv-sel_mode   = c_sel_mode_d.

ENDFORM.                    " set_layout_alv

*&---------------------------------------------------------------------*
*&      Form  set_layout_alv_all_qt_units
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_LAYOUT_ALV  text
*----------------------------------------------------------------------*
FORM set_layout_alv_all_qt_units
  USING
    p_s_general      TYPE  mdr1insingleround
  CHANGING
    p_s_layout_alv   TYPE  lvc_s_layo.

*                *** initialisiere zunächst die globale Strukur
  CLEAR: p_s_layout_alv.

*                *** lege nun das Layout des ALV-Grid-Controls fest

*                *** Titel zwischen Grid-Control und Toolbar
  CONCATENATE  text-816
               ' '
               p_s_general-matnr
         INTO  p_s_layout_alv-grid_title.

*                *** optimiere die Spaltenbreite
  p_s_layout_alv-cwidth_opt = c_yes.

*                *** bestimme die Selektionsmöglichkeiten
  p_s_layout_alv-sel_mode = c_sel_mode_d.

ENDFORM.                    " set_layout_alv_all_qt_units

*&---------------------------------------------------------------------*
*&      Form  mask_columns_all_qt_units
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_T_FIELDCATALOG
*----------------------------------------------------------------------*
FORM mask_columns_all_qt_units
  CHANGING
    p_t_fieldcatalog TYPE lvc_t_fcat.

  DATA l_wa_fieldcatalog TYPE lvc_s_fcat.

*                *** initialisiere zunächst die globale Tabelle
  CLEAR p_t_fieldcatalog.

*                *** baue den Feldkatalog gemäß der DDIC Strukur
*                *** mdr1alvsimurundprofil auf
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE              =
      i_structure_name             = 'MDR1OUTALLOWEDQTUNIT'
*     I_CLIENT_NEVER_DISPLAY       = 'X'
*     I_BYPASSING_BUFFER           =
*     I_INTERNAL_TABNAME           =
    CHANGING
      ct_fieldcat                  = p_t_fieldcatalog
    EXCEPTIONS
      inconsistent_interface       = 1
      program_error                = 2
      error_message                = 98
      OTHERS                       = 99.

  IF sy-subrc <> 0.
* ??? Fehlerbehandlung
  ENDIF.

*                *** passe die einzelnen Feldkatalog-Einträge an
*                *** individuelle Bedürfnisse an
  LOOP AT p_t_fieldcatalog
     INTO l_wa_fieldcatalog.

    CASE l_wa_fieldcatalog-fieldname.

      WHEN 'MATNR'
        OR 'FLAGSIQTUNIT'
        OR 'ADDKO'
        OR 'DIMID'
        OR 'MSSIE'
        OR 'ZAEHL'
        OR 'NENNR'
        OR 'MSEHL'.

*                *** Spalten werden nicht angezeigt
        l_wa_fieldcatalog-no_out = c_yes.

      WHEN 'MEINH'.

*                *** Spalte ist Key-Spalte
        l_wa_fieldcatalog-key = c_yes.

      WHEN 'FLAGDEFQTUNIT'
        OR 'FLAGVENQTUNIT'
        OR 'FLAGBUYQTUNIT'
        OR 'FLAGALLQTUNIT'.

*                *** Ausgabe als Checkbox
        l_wa_fieldcatalog-checkbox = c_yes.

      WHEN 'UMREZ'
        OR 'UMREN'
        OR 'UMREZF'
        OR 'UMRENF'.

*                *** Keine Nullen ausgeben
        l_wa_fieldcatalog-no_zero = c_yes.

    ENDCASE.

    MODIFY p_t_fieldcatalog
      FROM l_wa_fieldcatalog.

  ENDLOOP.

ENDFORM.                    " mask_columns_all_qt_units
*&---------------------------------------------------------------------*
*&      Form  set_layout_alv_rdrgl_detail
*&---------------------------------------------------------------------*
*       Layout-Vorbereitung für ALV-Ausgabe für die Rundungsregeln
*----------------------------------------------------------------------*
*  <--  p_s_layout_alv
*----------------------------------------------------------------------*
FORM set_layout_alv_rdrgl_detail
  CHANGING
    p_s_layout_alv TYPE lvc_s_layo.

*                *** initialisiere zunächst die globale Strukur
  CLEAR p_s_layout_alv.

*                *** lege nun das Layout des ALV-Grid-Controls fest

*                *** Titel zwischen Grid-Control und Toolbar
  CONCATENATE  text-801 g_0845_rdrgl
         INTO  p_s_layout_alv-grid_title.

*                *** optimiere die Spaltenbreite
  p_s_layout_alv-cwidth_opt = c_yes.

*                *** bestimme die Selektionsmöglichkeiten
  p_s_layout_alv-sel_mode   = c_sel_mode_d.  " = 'D'.

ENDFORM.                    " set_layout_alv_rdrgl_detail

*&---------------------------------------------------------------------*
*&      Form  mask_columns_rdrgl_detail
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_T_FIELDCATALOG
*----------------------------------------------------------------------*
FORM mask_columns_rdrgl_detail
  CHANGING
    p_t_fieldcatalog    TYPE   lvc_t_fcat.

  DATA l_wa_fieldcatalog TYPE lvc_s_fcat.

*                *** initialisiere zunächst die globale Tabelle
  CLEAR: p_t_fieldcatalog,
         p_t_fieldcatalog[].

*                *** baue den Feldkatalog gemäß der Tabelle TW06S auf
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE              =
      i_structure_name             = c_structure_name_tw06s "= 'TW06S'
*     I_CLIENT_NEVER_DISPLAY       = 'X'
*     I_BYPASSING_BUFFER           =
*     I_INTERNAL_TABNAME           =
    CHANGING
      ct_fieldcat                  = p_t_fieldcatalog
    EXCEPTIONS
      inconsistent_interface       = 1
      program_error                = 2
      error_message                = 98
      OTHERS                       = 99.

  IF sy-subrc <> 0.
* ??? Fehlerbehandlung
  ENDIF.

*                *** passe die einzelnen Feldkatalog-Einträge an
*                *** individuelle Bedürfnisse an
  LOOP AT  p_t_fieldcatalog
     INTO  l_wa_fieldcatalog.

    CASE l_wa_fieldcatalog-fieldname.

      WHEN c_fieldname_mandt    " = 'MANDT'
        OR c_fieldname_rdrgl.   " = 'RDRGL'

*                *** Spalten werden nicht angezeigt
        l_wa_fieldcatalog-no_out = c_yes.

      WHEN c_fieldname_meins    " = 'MEINS'
        OR c_fieldname_swpauf   " = 'SWPAUF'
        OR c_fieldname_swpab.   " = 'SWPAB'.

*                *** Damit Spaltenname vollständig angezeigt wird
        l_wa_fieldcatalog-coltext = l_wa_fieldcatalog-scrtext_l.

    ENDCASE.

    MODIFY p_t_fieldcatalog
      FROM l_wa_fieldcatalog.

  ENDLOOP.

ENDFORM.                    " mask_columns_rdrgl_detail

*&---------------------------------------------------------------------*
*&      Form  set_layout_alv_thres_rvalues
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_LAYOUT_ALV  text
*----------------------------------------------------------------------*
FORM set_layout_alv_thres_rvalues
  CHANGING
    p_s_layout_alv TYPE lvc_s_layo.

*                *** initialisiere zunächst die globale Strukur
  CLEAR p_s_layout_alv.

*                *** lege nun das Layout des ALV-Grid-Controls fest

*                *** Titel zwischen Grid-Control und Toolbar
  p_s_layout_alv-grid_title = text-802.

*                *** optimiere die Spaltenbreite
  p_s_layout_alv-cwidth_opt = c_yes.

*                *** bestimme die Selektionsmöglichkeiten
  p_s_layout_alv-sel_mode   = c_sel_mode_d.  " = 'D'

ENDFORM.                    " set_layout_alv_thres_rvalues

*&---------------------------------------------------------------------*
*&      Form  mask_columns_threshold_rvalues
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_T_FIELDCATALOG  text
*----------------------------------------------------------------------*
FORM mask_columns_threshold_rvalues
  CHANGING
    p_t_fieldcatalog TYPE lvc_t_fcat.

  DATA l_wa_fieldcatalog TYPE lvc_s_fcat.

*                *** initialisiere zunächst die globale Tabelle
  CLEAR: p_t_fieldcatalog,
         p_t_fieldcatalog[].

*                *** baue den Feldkatalog gemäß der Tabelle TW06S auf
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE              =
      i_structure_name             = c_structure_name_rdpr "= 'RDPR'
*     I_CLIENT_NEVER_DISPLAY       = 'X'
*     I_BYPASSING_BUFFER           =
*     I_INTERNAL_TABNAME           =
    CHANGING
      ct_fieldcat                  = p_t_fieldcatalog
    EXCEPTIONS
      inconsistent_interface       = 1
      program_error                = 2
      error_message                = 98
      OTHERS                       = 99.

  IF sy-subrc <> 0.
* ??? Fehlerbehandlung
  ENDIF.

*                *** passe die einzelnen Feldkatalog-Einträge an
*                *** individuelle Bedürfnisse an
  LOOP AT p_t_fieldcatalog
     INTO l_wa_fieldcatalog.

    CASE l_wa_fieldcatalog-fieldname.

      WHEN c_fieldname_mandt        " = 'MANDT'
        OR c_fieldname_rdrgl        " = 'RDRGL'
        OR c_fieldname_werks_2      " = 'WERKS'
        OR c_fieldname_rdprf_2      " = 'RDPRF'
        OR c_fieldname_rdzae        " = 'RDZAE'
        OR c_fieldname_rdmpo        " = 'RDMPO'
        OR c_fieldname_chkmeli      " = 'CHKMELI'
        OR c_fieldname_chkmeku.     " = 'CHKMEKU'.

*                *** Spalten werden nicht angezeigt
        l_wa_fieldcatalog-no_out = c_yes.

      WHEN c_fieldname_bdmng        " = 'BDMNG'
        OR c_fieldname_vormg.       " = 'VORMG'.

*                *** Damit Spaltenname vollständig angezeigt wird
        l_wa_fieldcatalog-coltext = l_wa_fieldcatalog-scrtext_l.

    ENDCASE.

    MODIFY p_t_fieldcatalog
      FROM l_wa_fieldcatalog.

  ENDLOOP.

ENDFORM.                    " mask_columns_threshold_rvalues

*&---------------------------------------------------------------------*
*&      Form  set_layout_alv_markup_discount
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_S_LAYOUT_ALV  text
*----------------------------------------------------------------------*
FORM set_layout_alv_markup_discount
  CHANGING
    p_s_layout_alv TYPE lvc_s_layo.

*                *** initialisiere zunächst die globale Strukur
  CLEAR p_s_layout_alv.

*                *** lege nun das Layout des ALV-Grid-Controls fest

*                *** Titel zwischen Grid-Control und Toolbar
  p_s_layout_alv-grid_title = text-803.

*                *** optimiere die Spaltenbreite
  p_s_layout_alv-cwidth_opt = c_yes.

*                *** bestimme die Selektionsmöglichkeiten
  p_s_layout_alv-sel_mode   = c_sel_mode_d.  "= 'D'

ENDFORM.                    " set_layout_alv_markup_discount

*&---------------------------------------------------------------------*
*&      Form  mask_columns_markup_discount
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_T_FIELDCATALOG  text
*----------------------------------------------------------------------*
FORM mask_columns_markup_discount
  CHANGING
    p_t_fieldcatalog TYPE lvc_t_fcat.

  DATA: l_wa_fieldcatalog TYPE lvc_s_fcat.

*                *** initialisiere zunächst die globale Tabelle
  CLEAR: p_t_fieldcatalog.

*                *** Eintrag für Feld threshold_value
  l_wa_fieldcatalog-fieldname = c_fieldname_thersh. "= 'THRESHOLD_VALUE'
  l_wa_fieldcatalog-inttype   = c_yes.
  l_wa_fieldcatalog-coltext   = text-804.           "= 'Schwellwert'.

  APPEND l_wa_fieldcatalog
      TO p_t_fieldcatalog.

*                *** Eintrag für Feld percentage
  l_wa_fieldcatalog-fieldname = c_fieldname_precentage. "= 'PERCENTAGE'
  l_wa_fieldcatalog-inttype   = c_yes.
  l_wa_fieldcatalog-coltext   = text-805.               "= 'Prozent (%)'

  APPEND l_wa_fieldcatalog
      TO p_t_fieldcatalog.

*                *** Eintrag für Feld up
  l_wa_fieldcatalog-fieldname = c_fieldname_up.        "= 'UP'.
  l_wa_fieldcatalog-inttype   = c_yes.
  l_wa_fieldcatalog-coltext   = text-806.              " = 'Aufschlag'.
  l_wa_fieldcatalog-checkbox  = c_yes.

  APPEND l_wa_fieldcatalog
      TO p_t_fieldcatalog.

*                *** Eintrag für Feld down
  l_wa_fieldcatalog-fieldname = c_fieldname_down.      "= 'DOWN'.
  l_wa_fieldcatalog-inttype   = c_yes.
  l_wa_fieldcatalog-coltext   = text-807.              " = 'Abschlag'.
  l_wa_fieldcatalog-checkbox  = c_yes.

  APPEND l_wa_fieldcatalog
      TO p_t_fieldcatalog.

ENDFORM.                    " mask_columns_markup_discount

*
* 
