FUNCTION ZCORE_FM_CHECK_VSTEL.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(IT_VSTEL) TYPE  ZCORE_TT_RSELOPTION_VSTEL
*"--------------------------------------------------------------------
TYPES: BEGIN OF LTY_TVST,
           VSTEL TYPE TVST-VSTEL,
         END OF LTY_TVST,
         LTY_T_TVST  TYPE STANDARD TABLE OF  LTY_TVST.

  DATA:
        LT_VSTEL TYPE          LTY_T_TVST,
        LS_VSTEL TYPE          LTY_TVST,
        LS_DATA  TYPE          ZCORE_ST_RSELOPTION_VSTEL.

  "Pur Org
  SELECT VSTEL
    INTO TABLE LT_VSTEL
    FROM TVST.
  LOOP AT LT_VSTEL INTO LS_VSTEL.
    AUTHORITY-CHECK OBJECT 'V_LIKP_VST'
             ID 'ACTVT' FIELD '03'
             ID 'VSTEL' FIELD LS_VSTEL-VSTEL.
    IF SY-SUBRC = 0.
      LS_DATA-SIGN = 'I'.
      LS_DATA-OPTION = 'EQ'.
      LS_DATA-LOW = LS_VSTEL-VSTEL.
      APPEND LS_DATA TO IT_VSTEL.
    ENDIF.
  ENDLOOP.





ENDFUNCTION.

*
* 
