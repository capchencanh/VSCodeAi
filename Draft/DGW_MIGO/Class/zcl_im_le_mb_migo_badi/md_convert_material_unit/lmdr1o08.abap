*----------------------------------------------------------------------*
***INCLUDE LMDR1O08 .
*----------------------------------------------------------------------*
***********************************************************************
*                       Dynpro 800
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  STATUS_0800  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0800 OUTPUT.

  SET PF-STATUS c_pf_status_s0800.                          " = 'S0800'.
  SET TITLEBAR  c_titelbar_800.                             " = '800'.

ENDMODULE.                 " STATUS_0800  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  modify_screen_0800  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE modify_screen_0800 OUTPUT.

*                *** Lege die Cursorposition dynamisch auf den
*                *** gedrückten Button fest.
  CASE c_yes.

    WHEN g_0800_no_appl.

      SET CURSOR FIELD c_g_0800_no_appl.  " = 'G_0800_NO_APPL'.

    WHEN g_0800_with_appl.

      SET CURSOR FIELD c_g_0800_with_appl. " = 'G_0800_WITH_APPL'.

  ENDCASE.

ENDMODULE.                 " modify_screen_0800  OUTPUT

***********************************************************************
*                       Dynpro 820
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  status_0820  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0820 OUTPUT.

  SET PF-STATUS  c_pf_status_s0820. " =  'S0820'.

*                *** Setze je nach Anwendung den Titel
  CASE g_s_0820_general-opcode.

    WHEN mdr1p_c_op_mm_normal.

      SET TITLEBAR c_titelbar_820
              WITH text-809.            " = 'Normalbestellung'.

    WHEN mdr1p_c_op_sd_auftrag.

      SET TITLEBAR  c_titelbar_820
              WITH text-810.            " = 'Kundenauftrag'.

    WHEN mdr1p_c_op_sd_lieferung.

      SET TITLEBAR  c_titelbar_820
              WITH text-811.            " = 'Lieferung'.

    WHEN mdr1p_c_op_mm_ub.

      SET TITLEBAR  c_titelbar_820
              WITH text-812.            " = 'Umlagerungsbestellung'.

    WHEN mdr1p_c_op_additionals.

      SET TITLEBAR  c_titelbar_820
              WITH text-813.            " = 'Verkaufshilfsmittel'.

  ENDCASE.

ENDMODULE.                 " status_0820  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  modify_screen_0820  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE modify_screen_0820 OUTPUT.

*                *** Modifiziere je nach Anwendung die Eingabe-
*                *** eigenschaften der Felder auf dem Dynpro.
  CASE g_s_0820_general-opcode.

    WHEN mdr1p_c_op_mm_normal
      OR mdr1p_c_op_mm_ub
      OR mdr1p_c_op_additionals.

      PERFORM set_screen_purchase_order_0820.

    WHEN mdr1p_c_op_sd_auftrag.

      PERFORM set_screen_sales_order_0820.

    WHEN mdr1p_c_op_sd_lieferung.

      PERFORM set_screen_delivery_0820.

  ENDCASE.

*                *** Unabhängig von der Anwendung

*                *** Ampel setzten
  LOOP AT SCREEN.

    CASE g_0820_light.

      WHEN c_green.

        CASE screen-name.

          WHEN c_greenlight.         " = 'GREENLIGHT'.

            screen-active = 1.

          WHEN c_redlight.           " = 'REDLIGHT'.

            screen-active = 0.

        ENDCASE.

      WHEN c_red.

        CASE screen-name.

          WHEN c_greenlight.         " = 'GREENLIGHT'.

            screen-active = 0.

          WHEN c_redlight.           " = 'REDLIGHT'.

            screen-active = 1.

        ENDCASE.

    ENDCASE.

*                *** weiße Fahne ausblenden (falls Steuerungsprofil bzw.
*                *** Rundungsparameter nicht verändert wurden)
    CASE screen-name.

      WHEN c_0820_control_initial.              " = 'CONTROL_INITIAL'

        IF g_0820_control_initial = c_yes.

          screen-active = 0.

        ENDIF.

      WHEN c_0820_rounding_initial.            " = 'ROUNDING_INITIAL'

        IF g_0820_rounding_initial = c_yes.

          screen-active = 0.

        ENDIF.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDMODULE.                 " modify_screen_0820  OUTPUT

***********************************************************************
*                       Dynpro 830
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  status_0830  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0830 OUTPUT.

  SET PF-STATUS  c_pf_status_s0830. " = 'S0830'.
  SET TITLEBAR   c_titelbar_830.                            " = '830'.

ENDMODULE.                 " status_0830  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  modify_screen_0830  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE modify_screen_0830 OUTPUT.

  CASE g_0830_mode_dynpro.

    WHEN c_0830_show_mode.

      PERFORM set_screen_show_0830    USING  g_s_0830_general.

    WHEN c_0830_change_mode.

      PERFORM set_screen_change_0830  USING  g_s_0830_general.

  ENDCASE.

ENDMODULE.                 " modify_screen_0830  OUTPUT

***********************************************************************
*                       Dynpro 840
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  status_0840  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0840 OUTPUT.

  SET PF-STATUS  c_pf_status_s0840. " = 'S0840'.
  SET TITLEBAR   c_titelbar_840.                            " = '840'.

ENDMODULE.                 " status_0840  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  modify_screen_0840  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE modify_screen_0840 OUTPUT.

  CASE g_0840_mode_dynpro.

    WHEN c_0840_show_mode.

      PERFORM set_screen_show_0840    USING  g_s_0840_general.

    WHEN c_0840_change_mode.

      PERFORM set_screen_change_0840  USING  g_s_0840_general.

  ENDCASE.

ENDMODULE.                 " modify_screen_0840  OUTPUT

***********************************************************************
*                       Dynpro 845
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  STATUS_0845  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0845 OUTPUT.

  SET PF-STATUS c_pf_status_s0845.                          " = 'S0845'
  SET TITLEBAR  c_titelbar_845                              " = '845'
          WITH  g_0845_rdprf.

ENDMODULE.                 " STATUS_0845  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  modify_screen_0845  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE modify_screen_0845 OUTPUT.

  CASE g_0845_rdmpo.

    WHEN c_rdmpo_abs.

*                *** Runden nach absoluten Schwellen-/Rundungswerten
      PERFORM set_screen_static_profil_0845.

    WHEN c_rdmpo_up_down.

*                *** Auf- und Abschlagsrundung
      PERFORM set_screen_up_down_0845.

    WHEN c_rdmpo_no.

*                *** Keine Rundung
      PERFORM set_screen_no_rounding_0845.

    WHEN c_rdmpo_bstme.
*                *** Vielfaches der Bestell-ME
*                **  => identisch zu keiner Rundung
      PERFORM set_screen_no_rounding_0845.

    WHEN c_rdmpo_opt
      OR c_rdmpo_opt_no_null.
*                *** Dynamische Rundungsprofile
      PERFORM set_screen_dynamic_profil_0845.

  ENDCASE.

ENDMODULE.                 " modify_screen_0845  OUTPUT

***********************************************************************
*                       Dynpro 850
***********************************************************************
*&---------------------------------------------------------------------*
*&      Module  STATUS_0850  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0850 OUTPUT.

  SET PF-STATUS c_pf_status_s0850.                          " = 'S0850'.

ENDMODULE.                 " STATUS_0850  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  create_objects_0850  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE create_objects_0850 OUTPUT.

  IF NOT ( g_custom_container_0850 IS INITIAL ).

*                *** initialisiere die Controls. Dies muß geschehen,
*                *** da es sonst Probleme mit der Anzeige gibt.
    CALL METHOD g_custom_container_0850->free.

    FREE g_custom_container_0850.
    FREE g_alv_grid_0850.

  ENDIF.

  CREATE OBJECT g_custom_container_0850
      EXPORTING container_name  = 'CONTAINER_0850'.

  CREATE OBJECT g_alv_grid_0850
      EXPORTING i_parent        = g_custom_container_0850.

ENDMODULE.                 " create_objects_0850  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  transfer_data_0850  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE transfer_data_0850 OUTPUT.

*                *** die globale Struktur zum laden der Varianten muß
*                *** mindestens die Report-ID enthalten. Zuvor jedoch
*                *** initialisieren.
  CLEAR g_s_variant_alv.
  g_s_variant_alv-report = sy-repid.

*                *** Zeiger dereferenzieren
  ASSIGN g_ref_to_table_alv_0850->*
      TO <g_data_table_alv_0850>.

*                *** übergebe die Daten dem ALV_Grid_Control
  CALL METHOD g_alv_grid_0850->set_table_for_first_display
    EXPORTING
      is_layout       = g_s_layout_alv
      is_variant      = g_s_variant_alv
      i_save          = c_save_alv
    CHANGING
      it_fieldcatalog = g_t_fieldcatalog
      it_outtab       = <g_data_table_alv_0850>.

ENDMODULE.                 " transfer_data_0850  OUTPUT

*
* 
