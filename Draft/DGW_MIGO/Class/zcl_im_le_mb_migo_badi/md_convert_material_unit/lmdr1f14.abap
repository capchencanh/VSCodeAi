*----------------------------------------------------------------------*
***INCLUDE LMDR1F14 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  AUTHORITY_CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM AUTHORITY_CHECK .

* authority check for external calls only
  DATA l_external_call  TYPE sap_bool.

  CALL METHOD ('CL_RFC')=>('CHECK_RFC_EXTERNAL')
     RECEIVING
       external_call    = l_external_call
     EXCEPTIONS
       kernel_too_old   = 1
       unexpected_error = 2
       OTHERS           = 3.

   IF sy-subrc <> 0.
      l_external_call = abap_true.
   ENDIF.

   IF l_external_call = abap_true.
*   Call was performed via direct external RFC (other system, client or user)
*   Perform authorization check

     AUTHORITY-CHECK OBJECT 'M_MATE_STA'
        ID 'ACTVT' FIELD '03'
        ID 'STATM' FIELD 'K'.
    IF SY-SUBRC NE 0.
      MESSAGE e853(M3).
    ENDIF.
     EXIT.
   ENDIF.

ENDFORM.                    " AUTHORITY_CHECK

*
* 
