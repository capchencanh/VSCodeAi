FUNCTION ZCORE_FM_CHECK_MSEG_WMB.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(IT_WERKS) TYPE  ZCORE_TT_RSELOPTION_WERKS
*"--------------------------------------------------------------------
TYPES: BEGIN OF LTY_T001W,
           WERKS TYPE T001W-WERKS,
         END OF LTY_T001W,
         LTY_T_T001W  TYPE STANDARD TABLE OF  LTY_T001W.

  DATA:
        LT_WERKS TYPE          LTY_T_T001W,
        LS_WERKS TYPE          LTY_T001W,
        LS_DATA  TYPE          ZCORE_ST_RSELOPTION_WERKS.

  "Plant
  SELECT WERKS
  INTO TABLE LT_WERKS
  FROM T001W.
  LOOP AT LT_WERKS INTO LS_WERKS.
    AUTHORITY-CHECK OBJECT 'M_MSEG_WMB'
             ID 'ACTVT' FIELD '03'
             ID 'WERKS' FIELD LS_WERKS-WERKS.
    IF SY-SUBRC = 0.
      LS_DATA-SIGN = 'I'.
      LS_DATA-OPTION = 'EQ'.
      LS_DATA-LOW = LS_WERKS-WERKS.
      APPEND LS_DATA TO IT_WERKS.
    ENDIF.
  ENDLOOP.





ENDFUNCTION.

*
* 
