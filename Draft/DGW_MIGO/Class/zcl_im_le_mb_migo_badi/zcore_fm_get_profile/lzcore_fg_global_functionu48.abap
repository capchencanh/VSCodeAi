FUNCTION ZFM_AUTHORIZATION_WERKS.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      GT_DATA
*"--------------------------------------------------------------------
TYPES: BEGIN OF LTY_AUTH,
           WERKS TYPE MSEG-WERKS,
         END OF LTY_AUTH.
  DATA: LT_AUTH TYPE TABLE OF LTY_AUTH,
        LS_AUTH TYPE LTY_AUTH.
  DATA: LW_WHERE TYPE STRING.

  MOVE-CORRESPONDING GT_DATA[] TO LT_AUTH[].
  SORT LT_AUTH.
  DELETE ADJACENT DUPLICATES FROM LT_AUTH COMPARING ALL FIELDS.

  LW_WHERE = `WERKS EQ LS_AUTH-WERKS`.
  " Check phân quyền theo kho
  LOOP AT LT_AUTH INTO LS_AUTH.
    AUTHORITY-CHECK OBJECT 'M_MSEG_WMB'
     ID 'ACTVT' FIELD '03'
     ID 'WERKS' FIELD LS_AUTH-WERKS.
    IF SY-SUBRC <> 0.
      DELETE GT_DATA WHERE (LW_WHERE).
    ENDIF.
  ENDLOOP.





ENDFUNCTION.

*
* 
