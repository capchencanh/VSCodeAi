FUNCTION ZCORE_FM_UNSIGN_UNICODE_VN.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(STRING)
*"--------------------------------------------------------------------
DATA : LW_LEN    TYPE I,
         LW_INDEX  TYPE I,
         LW_CHAR,
         LW_STRING TYPE STRING.

  IF GT_REPLACE[] IS INITIAL.
    PERFORM GET_REPLACE_DATE.
  ENDIF.

  LW_LEN = STRLEN( STRING ).
  WHILE LW_INDEX < LW_LEN.
    LW_CHAR  = STRING+LW_INDEX(1).
    LOOP AT GT_REPLACE.
      SEARCH GT_REPLACE-CHAR FOR LW_CHAR.
      IF SY-SUBRC EQ 0.
        LW_CHAR = GT_REPLACE-UNSIGN.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF LW_CHAR NE ' '.
      CONCATENATE LW_STRING
                LW_CHAR
           INTO LW_STRING.
    ELSE.
      CONCATENATE LW_STRING
                LW_CHAR
           INTO LW_STRING SEPARATED BY SPACE.
    ENDIF.
    LW_INDEX = LW_INDEX + 1.
  ENDWHILE.
*  TRANSLATE LW_STRING TO UPPER CASE.
  CONDENSE LW_STRING.
  STRING = LW_STRING.





ENDFUNCTION.

*
* 
