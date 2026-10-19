FUNCTION ZCORE_FM_STRING_SPLIT.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(STRING_VALUE) TYPE  CHAR255
*"     REFERENCE(SEARCH_START) TYPE  CHAR100
*"     REFERENCE(SEARCH_END) TYPE  CHAR100
*"  EXPORTING
*"     REFERENCE(OUT_STRING) TYPE  CHAR100
*"--------------------------------------------------------------------
data:
      lw_str_temp   type char30,
      lw_sea_int    type int1,
      lw_style_int  type int1.

  search string_value for search_start.

  if sy-subrc = 0 .
    lw_style_int = sy-fdpos +  strlen( search_start ).
    lw_str_temp = string_value+lw_style_int.
    search lw_str_temp for search_end.
    if sy-subrc = 0 .
      lw_style_int = sy-fdpos.
      out_string = lw_str_temp(lw_style_int).
    else.
      out_string = ''.
    endif.
  else.
    out_string = ''.
  endif.





ENDFUNCTION.


*Messages
*----------------------------------------------------------
*
* Message class: ALSMEX
*037   Error during import of clipboard contents
*
* Message class: Hard coded
*   You are not authorized with company code !
*
* Message class: KX
*001   & & & &

*
*
