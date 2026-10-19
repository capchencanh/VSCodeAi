FUNCTION ZCORE_FM_CHECK_BANF_EKORG.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(IT_EKORG) TYPE  ZCORE_TT_RSELOPTION_EKORG
*"--------------------------------------------------------------------
TYPES: BEGIN OF LTY_T024E,
           EKORG TYPE T024E-EKORG,
         END OF LTY_T024E,
         LTY_T_T024E  TYPE STANDARD TABLE OF  LTY_T024E.

  DATA:
        LT_EKORG TYPE          LTY_T_T024E,
        LS_EKORG TYPE          LTY_T024E,
        LS_DATA  TYPE          ZCORE_ST_RSELOPTION_EKORG.

  "Pur Org
  SELECT EKORG
    INTO TABLE LT_EKORG
    FROM T024E.
  LOOP AT LT_EKORG INTO LS_EKORG.
    AUTHORITY-CHECK OBJECT 'M_BANF_EKO'
             ID 'ACTVT' FIELD '03'
             ID 'EKORG' FIELD LS_EKORG-EKORG.
    IF SY-SUBRC = 0.
      LS_DATA-SIGN = 'I'.
      LS_DATA-OPTION = 'EQ'.
      LS_DATA-LOW = LS_EKORG-EKORG.
      APPEND LS_DATA TO IT_EKORG.
    ENDIF.
  ENDLOOP.





ENDFUNCTION.

*
* 
