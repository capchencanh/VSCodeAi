*&---------------------------------------------------------------------*
*& Include          ZEIV_IN_GETDATA_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZSTANDARD_ZEIV01'.
  SET TITLEBAR 'ZTITLE_ZEIV01'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  PBO_200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
CLASS  handle_event DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS : handle_toolbar
      FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object.
    CLASS-METHODS : handle_top_of_page
      FOR EVENT top_of_page OF cl_gui_alv_grid
      IMPORTING e_dyndoc_id.
    CLASS-METHODS : handle_user_command
      FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
    CLASS-METHODS : handle_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row.
    CLASS-METHODS : handle_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_column_id
                e_row_id.

ENDCLASS.                    "HANDLE_EVENT DEFINITION
CLASS  handle_event IMPLEMENTATION.
  METHOD handle_toolbar.
*ADDING CHANGE BUTTONN TO THE ALV TOOLBAR *
    DATA : is_btn TYPE stb_button.
    is_btn-function   = '&CHE'.
    is_btn-icon       = icon_select_all.
    is_btn-text       = 'Check all'.
    is_btn-quickinfo  = 'Check all'.
    is_btn-butn_type  = '0'.
    is_btn-disabled   = ' '.
    APPEND is_btn TO e_object->mt_toolbar.

*ADDING CHANGE BUTTONN TO THE ALV TOOLBAR *
    CLEAR is_btn.
    is_btn-function   = '&UCH'.
    is_btn-icon       = icon_deselect_all.
    is_btn-text       = 'Uncheck all'.
    is_btn-quickinfo  = 'Uncheck all'.
    is_btn-butn_type  = '0'.
    is_btn-disabled   = ' '.
    APPEND is_btn TO e_object->mt_toolbar.

*ADDING CHANGE BUTTONN TO THE ALV TOOLBAR *
    CLEAR is_btn.
    is_btn-function   = '&SEN'.
    is_btn-icon       = icon_execute_object.
    is_btn-text       = 'Send Data'.
    is_btn-quickinfo  = 'Send Data'.
    is_btn-butn_type  = '0'.
    is_btn-disabled   = ' '.
    APPEND is_btn TO e_object->mt_toolbar.

  ENDMETHOD.                    "handle_toolbar
  METHOD handle_top_of_page.
*    PERFORM WRITE_HEADING.
  ENDMETHOD.
  METHOD handle_user_command .
    DATA: rc          TYPE i,
          lw_tc_abs   TYPE dmshb_x8,
          lw_gtdh_abs TYPE dmshb_x8.
    DATA: lw_ans(1) TYPE c.
*    FIELD-SYMBOLS: <FS_ALV_HD> TYPE ZEIV_ST_HEADER.

    CASE e_ucomm.
      WHEN '&CHE'.
        LOOP AT gt_header ASSIGNING <fs_header>.
          <fs_header>-check = 'X'.
        ENDLOOP.
      WHEN '&UCH'.
        LOOP AT gt_header ASSIGNING <fs_header>.
          <fs_header>-check = ''.
        ENDLOOP.
      WHEN '&SEN'.
        PERFORM send_data_inv.   "tri.nguyen2 - 15.12.2025 - Bỏ app trung gian
*        PERFORM SEND_DATA.
      WHEN OTHERS.
    ENDCASE.

    g_state-col = 'X'.
    g_state-row = 'X'.
    CALL METHOD alv_grid->refresh_table_display
      EXPORTING
        is_stable = g_state.

    g_state-col = 'X'.
    g_state-row = 'X'.
    CALL METHOD alv_grid_detail->refresh_table_display
      EXPORTING
        is_stable = g_state.
  ENDMETHOD.
  METHOD handle_double_click.
    DATA:
      lw_stprs         TYPE mbew-stprs,
      lw_vprsv         TYPE mbew-vprsv,
      lw_lfgja         TYPE mbew-lfgja,
      lw_lfmon         TYPE mbew-lfmon,
      lw_msg           TYPE char255,
      lw_matnr         TYPE matnr,
      lw_budat         TYPE budat,
      lw_curdat        TYPE budat,
      lw_vbeln         TYPE vbeln,
      lw_price         TYPE dmbtr,
      lw_stt           TYPE int4,
      lw_kposn         TYPE kposn,
      ls_style         TYPE lvc_s_styl,
      lt_style_disable TYPE lvc_t_styl.

*    FIELD-SYMBOLS: <FS_DT> TYPE ZEIV_ST_DETAIL.

    ls_style-style      = cl_gui_alv_grid=>mc_style_disabled.
    ls_style-fieldname  = 'EXT_MEINS'.
    INSERT ls_style INTO TABLE lt_style_disable.

    ls_style-style      = cl_gui_alv_grid=>mc_style_disabled.
    ls_style-fieldname  = 'EXT_MENGE'.
    INSERT ls_style INTO TABLE lt_style_disable.

    ls_style-style      = cl_gui_alv_grid=>mc_style_disabled.
    ls_style-fieldname  = 'EXT_PRICE'.
    INSERT ls_style INTO TABLE lt_style_disable.

    READ TABLE gt_header INTO gs_header INDEX e_row-index.
    IF sy-subrc = 0.
      CLEAR gt_detail.
      LOOP AT gt_detail_all INTO gs_detail_all WHERE bukrs = gs_header-bukrs AND
                                                     gjahr = gs_header-gjahr AND
                                                     belnr = gs_header-belnr.
        IF gs_header-blart+0(1) NE 'D'. "DA -> DZ
          gs_detail_all-style = lt_style_disable.
        ENDIF.
        APPEND gs_detail_all TO gt_detail.
      ENDLOOP.
    ENDIF.


    CALL METHOD alv_grid_detail->set_frontend_layout
      EXPORTING
        is_layout = gs_layout_detail.

    g_state-col = 'X'.
    g_state-row = 'X'.
    CALL METHOD alv_grid_detail->refresh_table_display
      EXPORTING
        is_stable = g_state.
  ENDMETHOD.
  METHOD handle_hotspot_click.
    PERFORM handle_hotspot_click USING e_column_id-fieldname
                                       e_row_id-index.
  ENDMETHOD.
ENDCLASS.
*&---------------------------------------------------------------------*
*& Module INIT_HEADER OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_header OUTPUT.
  DATA: lt_toolbar TYPE ui_functions,
        ls_toolbar TYPE ui_func.
  DATA: gv_alvgrid TYPE REF TO cl_gui_alv_grid.
  PERFORM build_fieldcat_header.
  DATA gs_variant TYPE disvariant.
  gs_layout-cwidth_opt = 'X'.
*  GS_LAYOUT-STYLEFNAME = 'STYLE'.

  IF g_custom_container IS INITIAL.
    gs_variant-report = sy-repid.
    CREATE OBJECT g_custom_container
      EXPORTING
        container_name = g_container.
    CREATE OBJECT alv_grid
      EXPORTING
        i_parent = g_custom_container.

    CREATE OBJECT go_evt.

    SET HANDLER  handle_event=>handle_toolbar       FOR alv_grid.
    SET HANDLER  handle_event=>handle_top_of_page   FOR alv_grid.
    SET HANDLER  handle_event=>handle_user_command  FOR alv_grid.
    SET HANDLER  handle_event=>handle_double_click  FOR alv_grid.
    SET HANDLER  handle_event=>handle_hotspot_click FOR alv_grid.

    ls_toolbar = cl_gui_alv_grid=>mc_fc_loc_copy_row.
    APPEND ls_toolbar TO lt_toolbar.

    ls_toolbar = cl_gui_alv_grid=>mc_fc_loc_append_row.
    APPEND ls_toolbar TO lt_toolbar.

    ls_toolbar = cl_gui_alv_grid=>mc_fc_loc_delete_row.
    APPEND ls_toolbar TO lt_toolbar.

    ls_toolbar = cl_gui_alv_grid=>mc_fc_loc_insert_row.
    APPEND ls_toolbar TO lt_toolbar.

    CALL METHOD alv_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_layout
        i_save               = 'A'
        is_variant           = gs_variant
        it_toolbar_excluding = lt_toolbar
      CHANGING
        it_outtab            = gt_header[]
        it_fieldcatalog      = gt_fieldcat_header[].

*   Register events
    CALL METHOD alv_grid->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_enter.

    CALL METHOD alv_grid->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

    SET HANDLER go_evt->handle_data_changed FOR alv_grid.

    CALL METHOD alv_grid->list_processing_events
      EXPORTING
        i_event_name = 'TOP_OF_PAGE'
        i_dyndoc_id  = dg_dyndoc_id.
  ELSE.
    CALL METHOD alv_grid->set_frontend_layout
      EXPORTING
        is_layout = gs_layout.

    CALL METHOD alv_grid->refresh_table_display
      EXPORTING
        is_stable = g_state.
    IF sy-subrc <> 0.
    ENDIF.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_DETAIL OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_detail OUTPUT.
  DATA: lt_toolbar_detail TYPE ui_functions,
        ls_toolbar_detail TYPE ui_func.
  PERFORM build_fieldcat_detail.
  DATA gs_variant_detail TYPE disvariant.

  gs_layout_detail-cwidth_opt = 'X'.

  IF g_custom_container_detail IS INITIAL.
    gs_variant_detail-report = sy-repid.
    CREATE OBJECT g_custom_container_detail
      EXPORTING
        container_name = g_container_detail.

    CREATE OBJECT alv_grid_detail
      EXPORTING
        i_parent = g_custom_container_detail.

    CREATE OBJECT go_evt_detail.

*    SET HANDLER  HANDLE_EVENT=>HANDLE_TOOLBAR      FOR ALV_GRID_DETAIL.
*    SET HANDLER  HANDLE_EVENT=>HANDLE_TOP_OF_PAGE  FOR ALV_GRID_DETAIL.
*    SET HANDLER  HANDLE_EVENT=>HANDLE_USER_COMMAND FOR ALV_GRID_DETAIL.
*    SET HANDLER  HANDLE_EVENT=>HANDLE_DOUBLE_CLICK FOR ALV_GRID_DETAIL.

    ls_toolbar = cl_gui_alv_grid=>mc_fc_loc_copy_row.
    APPEND ls_toolbar TO lt_toolbar_detail.

    ls_toolbar = cl_gui_alv_grid=>mc_fc_loc_append_row.
    APPEND ls_toolbar TO lt_toolbar_detail.

    ls_toolbar = cl_gui_alv_grid=>mc_fc_loc_delete_row.
    APPEND ls_toolbar TO lt_toolbar_detail.

    ls_toolbar = cl_gui_alv_grid=>mc_fc_loc_insert_row.
    APPEND ls_toolbar TO lt_toolbar_detail.

    CALL METHOD alv_grid_detail->set_table_for_first_display
      EXPORTING
        is_layout            = gs_layout_detail
        i_save               = 'A'
        is_variant           = gs_variant_detail
        it_toolbar_excluding = lt_toolbar_detail
      CHANGING
        it_outtab            = gt_detail[]
        it_fieldcatalog      = gt_fieldcat_detail[].

*   Register events
    CALL METHOD alv_grid_detail->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_enter.

    CALL METHOD alv_grid_detail->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

    SET HANDLER go_evt_detail->handle_data_changed FOR alv_grid_detail.

    CALL METHOD alv_grid_detail->list_processing_events
      EXPORTING
        i_event_name = 'TOP_OF_PAGE'
        i_dyndoc_id  = dg_dyndoc_id.
  ELSE.
    CALL METHOD alv_grid_detail->set_frontend_layout
      EXPORTING
        is_layout = gs_layout_detail.

    CALL METHOD alv_grid_detail->refresh_table_display
      EXPORTING
        is_stable = g_state.
    IF sy-subrc <> 0.
    ENDIF.
  ENDIF.
ENDMODULE.

*
*
