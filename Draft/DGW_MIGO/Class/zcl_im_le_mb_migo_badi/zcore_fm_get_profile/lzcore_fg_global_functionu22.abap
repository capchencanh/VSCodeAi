FUNCTION ZCORE_FM_CHECK_NUMBER.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(P_DECIMAL) TYPE  CHAR1
*"     REFERENCE(P_VALUE) TYPE  CHAR32
*"  EXPORTING
*"     REFERENCE(E_IS_NUMBER)
*"--------------------------------------------------------------------
constants: c_char(13) type c value ',.1234567890'.

  e_is_number = ''.

  types:  begin of split,
            part(900) type c,
          end of split.

  data: itsplit type table of split with header line,
        i       type i value 0.

  if p_value co c_char.
    if strlen( p_value ) > 18.
      e_is_number = 'X'.
    endif.

    split p_value at p_decimal into table itsplit.

    loop at itsplit.
      i = i + 1.
    endloop.

    if i > 2.
      e_is_number = 'X'.
    endif.
  else.
    e_is_number = 'X'.
  endif.





ENDFUNCTION.

*
* 
