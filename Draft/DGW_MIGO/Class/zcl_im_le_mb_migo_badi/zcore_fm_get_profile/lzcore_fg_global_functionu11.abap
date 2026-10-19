FUNCTION ZCORE_AUTHORIZATION_BUKRS_NEW.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_BUKRS) TYPE  BUKRS OPTIONAL
*"  EXPORTING
*"     VALUE(O_ERR) TYPE  CHAR1
*"  TABLES
*"      IT_BUKRS STRUCTURE  ZCORE_ST_RSELOPTION_BUKRS OPTIONAL
*"----------------------------------------------------------------------
  DATA: LT_BUKRS TYPE TABLE OF  T001,
        LS_BUKRS TYPE           T001.
  O_ERR = '0'.

  IF I_BUKRS IS NOT INITIAL.
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
             ID 'BUKRS' FIELD I_BUKRS
             ID 'ACTVT' FIELD '03'.
    IF SY-SUBRC NE 0.
      O_ERR = '1'.
      MESSAGE 'You are not authorized with company code !' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.
  ENDIF.

  IF IT_BUKRS IS NOT INITIAL.
    SELECT BUKRS
    INTO CORRESPONDING FIELDS OF TABLE LT_BUKRS
    FROM T001
    WHERE BUKRS IN IT_BUKRS.

    LOOP AT LT_BUKRS INTO LS_BUKRS.
      AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
               ID 'BUKRS' FIELD LS_BUKRS-BUKRS
               ID 'ACTVT' FIELD '03'.
      IF SY-SUBRC NE 0.
        O_ERR = '1'.
        MESSAGE 'You are not authorized with company code !' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.
    ENDLOOP.
  ENDIF.





ENDFUNCTION.

*
* 
