FUNCTION ZCORE_FM_REPLACE_NUMBER.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(P_DECIMAL) TYPE  CHAR1
*"     REFERENCE(P_VALUE) TYPE  CHAR32
*"  EXPORTING
*"     REFERENCE(E_VALUE_NUMBER) TYPE  CHAR32
*"--------------------------------------------------------------------
data: g_desktop(20) type c,
        i type i.

  types:  begin of datelist,
            sign(20),
          end of datelist.

  data: gd(1).

  data: itdatelist type standard table of datelist with header line.

  i = -5.

  do 100 times.
    i = i + 1.
    call function 'GUI_GET_DESKTOP_INFO'
      exporting
        type = i
      changing
        return = g_desktop.
    itdatelist-sign = g_desktop.
    append itdatelist.
  enddo.


  if p_decimal = '.'.
    gd = ','.
  else.
    gd = '.'.
  endif.

  e_value_number = p_value.

  replace all occurrences of gd in e_value_number  with ''.
  replace all occurrences of p_decimal in e_value_number  with '.'.





ENDFUNCTION.

*
* 
