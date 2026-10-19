FUNCTION ZCORE_FM_CURR_CONVERT_COMPUTE.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_WAERS) TYPE  WAERS
*"  EXPORTING
*"     REFERENCE(E_DECIMAL) TYPE  I
*"     REFERENCE(E_SHIFT) TYPE  I
*"     REFERENCE(E_NUMBER) TYPE  I
*"--------------------------------------------------------------------
data: ls_tcurx type tcurx.
  select single *
    into ls_tcurx
    from tcurx
    where currkey = i_waers.
  if sy-subrc = 0.
    e_decimal = ls_tcurx-currdec.
    e_shift = 2 - ls_tcurx-currdec.
  else.
    e_decimal = 2.
    e_shift = 0.
  endif.

  e_number = 10 ** e_shift.





ENDFUNCTION.

*
* 
