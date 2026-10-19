FUNCTION ZCORE_FM_GET_COMCODE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_NUMBER) TYPE  CHAR4
*"     REFERENCE(I_KIND) TYPE  CHAR1
*"  EXPORTING
*"     REFERENCE(E_BUKRS) TYPE  BUKRS
*"----------------------------------------------------------------------

DATA:
      LW_BUKRS       TYPE TVKO-BUKRS.

CASE I_KIND.
    WHEN 'O'. "LẤY COMPANY CODE THEO SALES ORG

    SELECT SINGLE
      TVKO~BUKRS " COMPANY CODE
    INTO
      LW_BUKRS
    FROM TVKO
    WHERE VKORG EQ I_NUMBER .


    "Company Code
    CLEAR E_BUKRS.
    E_BUKRS = LW_BUKRS.
    CONDENSE E_BUKRS.

    WHEN 'P'. "LẤY COMPANY CODE THEO PLANT

    CALL FUNCTION 'HRCA_PLANT_GET_COMPANYCODE'
      EXPORTING
        PLANT                       = I_NUMBER
     IMPORTING
        COMPANYCODE                 = E_BUKRS
*     EXCEPTIONS
*       NO_COMPANY_CODE_FOUND       = 1
*       PLANT_NOT_FOUND             = 2
*       OTHERS                      = 3
              .

    WHEN OTHERS.
ENDCASE.


ENDFUNCTION.


*Messages
*----------------------------------------------------------
*
* Message class: ALSMEX
*037   Error during import of clipboard contents
*
* Message class: Hard coded
*   You are not authorized with company code !
*
* Message class: KX
*001   & & & &

*
* 
