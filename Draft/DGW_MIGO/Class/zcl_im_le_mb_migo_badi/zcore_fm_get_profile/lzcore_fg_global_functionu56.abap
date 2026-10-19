FUNCTION ZCORE_AUTHORIZATION_GSBER.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_GSBER) TYPE  GSBER OPTIONAL
*"  TABLES
*"      IT_GSBER STRUCTURE  ZCORE_ST_RSELOPTION_GSBER OPTIONAL
*"--------------------------------------------------------------------
if i_GSBER is not initial.
  authority-check object 'F_BKPF_GSB'
     ID 'GSBER' FIELD i_GSBER
     ID 'ACTVT' FIELD '03'.
  if sy-subrc ne 0.
    message 'You are not authorized with Business Area!' type 'E'.
  endif.
endif.

*if it_GSBER[] is not initial.
  select
    MANDT,
    GSBER
  from TGSB
  where GSBER in @it_GSBER[]
  into table @DATA(lt_GSBER).
  REFRESH it_GSBER.
  loop at lt_GSBER into DATA(lS_GSBER).
    authority-check object 'F_BKPF_GSB'
             id 'GSBER' field lS_GSBER-GSBER
             id 'ACTVT' field '03'.
    if sy-subrc ne 0.
      message 'You are not authorized with Business Area!' type 'E'.
    ELSE.
      IT_GSBER-sign   = 'I'.
      IT_GSBER-option = 'EQ'.
      IT_GSBER-loW    = lS_GSBER-GSBER.
      APPEND IT_GSBER.
    endif.
  endloop.
*endif.





ENDFUNCTION.

*
* 
