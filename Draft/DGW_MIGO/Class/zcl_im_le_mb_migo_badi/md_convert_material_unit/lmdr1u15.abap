FUNCTION mdr1_simu_rounding.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_S_GENERAL) TYPE  MDR1INSINGLEROUND OPTIONAL
*"  EXCEPTIONS
*"      ERROR
*"      BAD_PARAMS
*"      BAD_PROFIL
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       01.10.01  4.70 mbi         Grundversion
*-----------------------------------------------------------------------

  IF i_s_general IS INITIAL.
*                *** Default-Verzweigung in Auswahldynpro 0800,
*                *** wenn keine Aufrufparameter belegt sind:
*                *** - Aufruf durch Simulationstransaktion WLB8
    PERFORM call_dynpro_0800.
  ELSE.
*                *** Beim Aufruf aus einer Anwendung mit
*                *** gesetzten Parametern:
*                *** - Aufruf in F4_ORDER_QUNATITY
    PERFORM call_dynpro_0820  USING  i_s_general.

  ENDIF.

ENDFUNCTION.

*
* 
