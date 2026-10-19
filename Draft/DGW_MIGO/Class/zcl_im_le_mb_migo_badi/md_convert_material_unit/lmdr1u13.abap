FUNCTION f4_rdpr_rdprf.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_DYNPPROG) TYPE  SY-REPID
*"     REFERENCE(I_DYNPNR) TYPE  SY-DYNNR
*"     REFERENCE(I_RDPRF_DYNPR_FIELDNAME) TYPE  HELP_INFO-DYNPROFLD
*"     REFERENCE(I_WERKS_DYNPR_FIELDNAME) TYPE  DYNPREAD-FIELDNAME
*"     REFERENCE(I_READ_WERKS) TYPE  C
*"     REFERENCE(I_TAKE_WERKS) TYPE  C
*"  EXCEPTIONS
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       20.10.01  470  mbi         Grundversion
*-----------------------------------------------------------------------

  PERFORM f4help_rdpr_rdprf
              USING
                 i_dynpprog
                 i_dynpnr
                 i_rdprf_dynpr_fieldname
                 i_werks_dynpr_fieldname
                 i_read_werks
                 i_take_werks.

ENDFUNCTION.

*
* 
