FUNCTION ZCORE_FM_GET_LONG_TEXT.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_TDOBJECT) TYPE  TDOBJECT
*"     REFERENCE(I_TDNAME) TYPE  TDOBNAME
*"     REFERENCE(I_TDID) TYPE  TDID
*"     REFERENCE(I_TDSPRAS) TYPE  SPRAS DEFAULT 'E'
*"  EXPORTING
*"     REFERENCE(E_LONG_TEXT) TYPE  CHAR255
*"     REFERENCE(E_LONG_TEXT1) TYPE  CHAR512
*"     VALUE(E_TEXT_LINE1) TYPE  TDLINE
*"     VALUE(E_TEXT_LINE2) TYPE  TDLINE
*"     VALUE(E_TEXT_LINE3) TYPE  TDLINE
*"     REFERENCE(E_TEXT_STR) TYPE  STRING
*"--------------------------------------------------------------------
DATA: LT_TLINE TYPE TABLE OF TLINE,
        LS_TLINE TYPE          TLINE,
        LS_THEAD TYPE          THEAD.

  CLEAR E_LONG_TEXT.
  CLEAR E_LONG_TEXT1.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      CLIENT                  = SY-MANDT
      ID                      = I_TDID
      LANGUAGE                = I_TDSPRAS
      NAME                    = I_TDNAME
      OBJECT                  = I_TDOBJECT
    TABLES
      LINES                   = LT_TLINE
    EXCEPTIONS
      ID                      = 1
      LANGUAGE                = 2
      NAME                    = 3
      NOT_FOUND               = 4
      OBJECT                  = 5
      REFERENCE_CHECK         = 6
      WRONG_ACCESS_TO_ARCHIVE = 7
      OTHERS                  = 8.

  IF SY-SUBRC = 0.
    LOOP AT LT_TLINE INTO LS_TLINE.
      CONCATENATE E_LONG_TEXT LS_TLINE-TDLINE  INTO E_LONG_TEXT  SEPARATED BY SPACE.
      CONCATENATE E_LONG_TEXT1 LS_TLINE-TDLINE INTO E_LONG_TEXT1 SEPARATED BY SPACE.
    ENDLOOP.

  ENDIF.
  " MaiVTT5 add - Replace special character when use special character like &...
  IF E_LONG_TEXT CA '&' OR E_LONG_TEXT CA '<'. " Hien tai, test chi co ky tu & bi loi <(>&<)> khi in ra
    REPLACE ALL OCCURRENCES OF '<(>' IN E_LONG_TEXT WITH SPACE.
    REPLACE ALL OCCURRENCES OF '<)>' IN E_LONG_TEXT WITH SPACE.
    REPLACE ALL OCCURRENCES OF '<(>' IN E_LONG_TEXT1 WITH SPACE.
    REPLACE ALL OCCURRENCES OF '<)>' IN E_LONG_TEXT1 WITH SPACE.
  ENDIF.
  CONDENSE E_LONG_TEXT.
  CONDENSE E_LONG_TEXT1.

  READ TABLE LT_TLINE INTO LS_TLINE
  INDEX 1.
  IF SY-SUBRC EQ 0.
    E_TEXT_LINE1 = LS_TLINE-TDLINE.
  ENDIF.

  READ TABLE LT_TLINE INTO LS_TLINE
  INDEX 2.
  IF SY-SUBRC EQ 0.
    E_TEXT_LINE2 = LS_TLINE-TDLINE.
  ENDIF.

  READ TABLE LT_TLINE INTO LS_TLINE
  INDEX 3.
  IF SY-SUBRC EQ 0.
    E_TEXT_LINE3 = LS_TLINE-TDLINE.
  ENDIF.





ENDFUNCTION.

*
* 
