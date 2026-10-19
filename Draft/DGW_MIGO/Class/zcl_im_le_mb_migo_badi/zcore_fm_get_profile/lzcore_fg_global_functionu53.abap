FUNCTION ZFTR_CORR_SWIFT_DELETE_ENDZERO.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(C_VALUE) TYPE  C
*"--------------------------------------------------------------------
DATA :  UP_LEN              LIKE DTA_M3X-LEN,
          H_OFF               TYPE I,
          H_CHAR                    ,
          H_ZERO                    .

  IF C_VALUE CA ',' OR C_VALUE CA '.'.
    H_OFF = STRLEN( C_VALUE ) .
    H_OFF = H_OFF - 1.
    H_CHAR = C_VALUE+H_OFF(1).
    WHILE H_CHAR EQ '0'.
      REPLACE H_CHAR WITH '' INTO H_ZERO.
      C_VALUE+H_OFF(1) = H_ZERO.
      CONDENSE C_VALUE.
      UP_LEN = STRLEN( C_VALUE ).
      H_OFF = UP_LEN .
      H_OFF = H_OFF - 1.
      H_CHAR = C_VALUE+H_OFF(1).
      CHECK NOT  H_CHAR EQ ',' OR H_CHAR EQ '.'.
    ENDWHILE.
    IF H_CHAR EQ ',' OR H_CHAR EQ '.'.
      REPLACE H_CHAR WITH '' INTO H_ZERO.
      C_VALUE+H_OFF(1) = H_ZERO.
      CONDENSE C_VALUE.
    ENDIF.
  ENDIF.





ENDFUNCTION.

*
* 
