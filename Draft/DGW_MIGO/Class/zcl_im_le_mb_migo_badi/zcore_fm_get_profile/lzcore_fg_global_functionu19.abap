FUNCTION ZCORE_FM_CHECK_LGNUM_LGNUM.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(IT_LGNUM) TYPE  ZCORE_TT_RSELOPTION_LGNUM
*"--------------------------------------------------------------------
TYPES: BEGIN OF LTY_T300,
           LGNUM TYPE T300-LGNUM,
         END OF LTY_T300,
         LTY_T_T300  TYPE STANDARD TABLE OF  LTY_T300.

  DATA:
        LT_LGNUM TYPE          LTY_T_T300,
        LS_LGNUM TYPE          LTY_T300,
        LS_DATA  TYPE          ZCORE_ST_RSELOPTION_LGNUM.

  "Pur. Group
  SELECT LGNUM
    INTO TABLE LT_LGNUM
    FROM T300.
  LOOP AT LT_LGNUM INTO LS_LGNUM.
    AUTHORITY-CHECK OBJECT 'L_LGNUM'
             ID 'ACTVT' FIELD '03'
             ID 'LGNUM' FIELD LS_LGNUM-LGNUM.
    IF SY-SUBRC = 0.
      LS_DATA-SIGN = 'I'.
      LS_DATA-OPTION = 'EQ'.
      LS_DATA-LOW = LS_LGNUM-LGNUM.
      APPEND LS_DATA TO IT_LGNUM.
    ENDIF.
  ENDLOOP.





ENDFUNCTION.

*
* 
