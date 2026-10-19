FUNCTION ZCORE_FM_CHECK_VBAK_VKORG.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(IT_VKORG) TYPE  ZCORE_TT_RSELOPTION_VKORG
*"--------------------------------------------------------------------
TYPES: BEGIN OF LTY_TVKO,
           VKORG TYPE TVKO-VKORG,
         END OF LTY_TVKO,
         LTY_T_TVKO  TYPE STANDARD TABLE OF  LTY_TVKO.

  DATA:
        LT_VKORG TYPE          LTY_T_TVKO,
        LS_VKORG TYPE          LTY_TVKO,
        LS_DATA  TYPE          ZCORE_ST_RSELOPTION_VKORG.

  "Sales Org
  SELECT VKORG
    INTO TABLE LT_VKORG
    FROM TVKO.
  LOOP AT LT_VKORG INTO LS_VKORG.
    AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
             ID 'ACTVT' FIELD '03'
             ID 'VKORG' FIELD LS_VKORG-VKORG.
    IF SY-SUBRC = 0.
      LS_DATA-SIGN = 'I'.
      LS_DATA-OPTION = 'EQ'.
      LS_DATA-LOW = LS_VKORG-VKORG.
      APPEND LS_DATA TO IT_VKORG.
    ENDIF.
  ENDLOOP.





ENDFUNCTION.

*
* 
