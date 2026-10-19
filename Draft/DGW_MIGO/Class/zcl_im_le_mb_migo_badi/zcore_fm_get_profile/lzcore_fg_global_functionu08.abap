FUNCTION ZCORE_CONVERT_TO_JULIAN_DATE.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(DATUM) TYPE  DATUM
*"  EXPORTING
*"     REFERENCE(JULIAN) TYPE  NUMC3
*"--------------------------------------------------------------------
DATA: DATE_AUX TYPE D.

* First day of the year
  CONCATENATE DATUM(4) '0101' INTO DATE_AUX.

  JULIAN = DATUM - DATE_AUX.

  JULIAN = JULIAN + 1.





ENDFUNCTION.

*
* 
