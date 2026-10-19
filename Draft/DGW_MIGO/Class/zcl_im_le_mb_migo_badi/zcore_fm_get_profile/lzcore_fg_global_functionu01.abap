FUNCTION ZCORE_AUTHORIZATION_BUKRS.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_BUKRS) TYPE  BUKRS OPTIONAL
*"  TABLES
*"      IT_BUKRS STRUCTURE  ZCORE_ST_RSELOPTION_BUKRS OPTIONAL
*"--------------------------------------------------------------------
data: lt_bukrs type table of  t001,
      ls_bukrs type           t001.

if i_bukrs is not initial.
  authority-check object 'F_BKPF_BUK'
           id 'BUKRS' field i_bukrs
           id 'ACTVT' field '03'.
  if sy-subrc ne 0.
    message 'You are not authorized with company code !' type 'E'.
  endif.
endif.

if it_bukrs is not initial.
  select bukrs
  into corresponding fields of table lt_bukrs
  from t001
  where bukrs in it_bukrs.

  loop at lt_bukrs into ls_bukrs.
    authority-check object 'F_BKPF_BUK'
             id 'BUKRS' field ls_bukrs-bukrs
             id 'ACTVT' field '03'.
    if sy-subrc ne 0.
      message 'You are not authorized with company code !' type 'E'.
    endif.
  endloop.
endif.





ENDFUNCTION.

*
* 
