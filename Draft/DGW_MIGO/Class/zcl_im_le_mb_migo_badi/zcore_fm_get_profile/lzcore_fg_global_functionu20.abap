FUNCTION ZCORE_FM_CHECK_MSEG_LGO.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(IT_LGORT) TYPE  ZCORE_TT_RSELOPTION_LGORT
*"--------------------------------------------------------------------
TYPES: BEGIN OF LTY_T001L,
           LGORT TYPE T001L-LGORT,
         END OF LTY_T001L,
         LTY_T_T001L  TYPE STANDARD TABLE OF  LTY_T001L.

  DATA:
        LT_T001L TYPE          LTY_T_T001L,
        LS_T001L TYPE          LTY_T001L,
        LS_DATA  TYPE          ZCORE_ST_RSELOPTION_LGORT.

  "Plant
  SELECT LGORT
  INTO TABLE LT_T001L
  FROM T001L.
  LOOP AT LT_T001L INTO LS_T001L.
    AUTHORITY-CHECK OBJECT 'M_MSEG_LGO'
             ID 'ACTVT' FIELD '03'
             ID 'LGORT' FIELD LS_T001L-LGORT.
    IF SY-SUBRC = 0.
      LS_DATA-SIGN = 'I'.
      LS_DATA-OPTION = 'EQ'.
      LS_DATA-LOW = LS_T001L-LGORT.
      APPEND LS_DATA TO IT_LGORT.
    ENDIF.
  ENDLOOP.





ENDFUNCTION.

*
* 
