FUNCTION ZCORE_FM_GET_COA.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_BUKRS) TYPE  BUKRS OPTIONAL
*"  EXPORTING
*"     REFERENCE(E_KTOPL) TYPE  KTOPL
*"     REFERENCE(E_KKTPL) TYPE  KKTPL
*"     REFERENCE(E_RLDNR) TYPE  RLDNR
*"     REFERENCE(E_RLDNR_NAME) TYPE  CHAR30
*"     REFERENCE(E_WAERS) TYPE  WAERS
*"  TABLES
*"      IT_BUKRS STRUCTURE  ZCORE_ST_RSELOPTION_BUKRS OPTIONAL
*"--------------------------------------------------------------------
" Get COA Information
  select single
    t004~ktopl
    t004~kktpl
    t001~waers
  into
   (E_KTOPL,
    E_KKTPL,
    E_WAERS)
  from t001 inner join t004 on t001~ktopl = t004~ktopl
  where t001~bukrs = i_bukrs
    or  t001~bukrs in it_bukrs.

  select single
    t881~rldnr
    t881t~name
  into
   (E_RLDNR,
    E_RLDNR_NAME)
  from t881 inner join t881t on t881~rldnr = t881t~rldnr
  where t881~glflex eq  '1'
    and t881~depld  eq  ' '
    and t881~rldnr  eq  '0L'.





ENDFUNCTION.

*
*
