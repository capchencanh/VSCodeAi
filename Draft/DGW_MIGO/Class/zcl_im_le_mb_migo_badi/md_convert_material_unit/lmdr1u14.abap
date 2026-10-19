FUNCTION f4_rdpr_werks.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_DYNPPROG) TYPE  SY-REPID
*"     REFERENCE(I_DYNPNR) TYPE  SY-DYNNR
*"  EXCEPTIONS
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       20.10.01  470  mbi         Grundversion
*-----------------------------------------------------------------------

  PERFORM f4help_rdpr_werks
              USING
                 i_dynpprog
                 i_dynpnr.

ENDFUNCTION.

*
* 
