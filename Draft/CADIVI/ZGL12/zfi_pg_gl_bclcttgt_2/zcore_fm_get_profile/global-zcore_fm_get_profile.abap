function-pool zcore_fg_global_function.     "MESSAGE-ID ..

* INCLUDE LZCORE_FG_GLOBAL_FUNCTIOND...      " Local class definition

* DISPLAY_ALV_SCR
data:
  go_alv_docking    type ref to cl_gui_docking_container,
  go_alv_grid       type ref to cl_gui_alv_grid,
  l_t_import        type table of zcore_st_get_profile,
  l_s_import        type          zcore_st_get_profile.

* DATA_UPDATE_TABLE, GET_ORIGINAL_DATA
types:
  begin of gty_key_fields,
    tabname           type tabname,
    fieldname         type lvc_fname,
    value             type char255,
  end of gty_key_fields,
  gty_t_key_fields    type table of gty_key_fields,
  begin of gty_s_ranges_tab,
    sign(1)     type c,
    option(2)   type c,
    low(255)    type c,
    high(255)   type c,
    end of gty_s_ranges_tab,
  begin of gty_selection,
    field_name  like dd03d-fieldname,           "Field name
    ranges_tab  type gty_s_ranges_tab occurs 0, "Range table
    log_cond(3) type c,                         "Logical condition
  end of gty_selection.
data:
  gw_tabname          type tabname,
  gt_fieldcat         type lvc_t_fcat,
  gt_keyfields        type gty_t_key_fields,
  gt_selection        type table of gty_selection, "Logical condition
  gt_where_clauses  type rsds_where_tab.        "Where clause.
field-symbols:
  <gft_data_table> type table,
  <gf_data_str>    type any,
  <gft_data_org>   type table.
* ALV data
data:
  gt_header                     type slis_t_listheader,
  gw_callback_program           like  sy-repid,
  gw_callback_pf_status_set     type  slis_formname,
  gw_callback_user_command      type  slis_formname,
  gw_callback_top_of_page       type  slis_formname,
  gw_callback_html_end_of_list  type  slis_formname.

field-symbols : <fs_profile> type zcore_st_get_profile.

*
*
