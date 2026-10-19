FUNCTION ZCORE_FM_CONVERT_NUMBER.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_DMBTR) TYPE  BSPL_REPVAL OPTIONAL
*"     REFERENCE(I_CURR) TYPE  WAERS OPTIONAL
*"     REFERENCE(I_HIDE_ZERO) TYPE  C OPTIONAL
*"  EXPORTING
*"     REFERENCE(E_DMBTR)
*"--------------------------------------------------------------------
data: lw_dmbtr type char255.

  write i_dmbtr to lw_dmbtr no-sign currency i_curr.
  condense lw_dmbtr no-gaps.

  if i_hide_zero = 'X' and i_dmbtr = 0.
    clear: e_dmbtr.
  else.
    " Local currency
    if i_dmbtr < 0.
      concatenate '(' lw_dmbtr ')' into e_dmbtr.
    else.
      e_dmbtr = lw_dmbtr.
    endif.
  endif.





ENDFUNCTION.

*
* 
