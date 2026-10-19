FUNCTION ZCORE_FM_EXCEL_COLUMN_WIDTH.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_SHEET_NAME) TYPE  CHAR10
*"     REFERENCE(I_INDEX) TYPE  STRING
*"     REFERENCE(I_WIDTH) TYPE  CHAR10
*"     REFERENCE(I_ORDER) TYPE  I
*"  TABLES
*"      T_DATA
*"--------------------------------------------------------------------
data lw_row type string.
  data lw_sheet type char100.
  data lw_insdex type int4 value 1.

  " I_WIDTH => Pixel => Quy Doi Thanh Cm
  data: lw_width_cm type int4.
  data: lw_width_cm_c type char10.

  lw_width_cm = i_width * '3' / '4'.
  lw_width_cm_c = lw_width_cm.
  condense lw_width_cm_c no-gaps.

  concatenate 'ss:Name="' i_sheet_name '"' into lw_sheet.
  loop at t_data into lw_row.
    if lw_row cs lw_sheet.
       lw_insdex = sy-tabix.
    endif.
  endloop.

  lw_insdex = lw_insdex + i_order + 1.
  clear lw_row.
  concatenate '<Column ss:Index="' i_index '" ss:Width="' lw_width_cm_c '"/>' into lw_row.

  insert lw_row into t_data index lw_insdex.





ENDFUNCTION.


*Messages
*----------------------------------------------------------
*
* Message class: 00
*001   &1&2&3&4&5&6&7&8
*398   & & & &
*
* Message class: Hard coded
*   Template was not found !
*
* Message class: VZ
*000   & & & &

*
*
