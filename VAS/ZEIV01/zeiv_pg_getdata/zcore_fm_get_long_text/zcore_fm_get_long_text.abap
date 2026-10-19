FUNCTION ZCORE_FM_GET_LONG_TEXT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_TDOBJECT) TYPE  TDOBJECT
*"     REFERENCE(I_TDNAME) TYPE  TDOBNAME
*"     REFERENCE(I_TDID) TYPE  TDID
*"     REFERENCE(I_TDSPRAS) TYPE  SPRAS DEFAULT 'E'
*"  EXPORTING
*"     REFERENCE(E_LONG_TEXT) TYPE  CHAR255
*"     REFERENCE(E_TEXT_STR) TYPE  STRING
*"----------------------------------------------------------------------
  DATA: LT_TLINE TYPE TABLE OF TLINE,
        LS_TLINE TYPE          TLINE,
        LS_THEAD TYPE          THEAD.

  CLEAR E_LONG_TEXT.

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
*      concatenate e_long_text ls_tline-tdline into e_long_text separated by space.
      CONCATENATE E_TEXT_STR LS_TLINE-TDLINE INTO E_TEXT_STR SEPARATED BY SPACE.
    ENDLOOP.
  ENDIF.
*  " MaiVTT5 add - Replace special character when use special character like &...
*  IF E_LONG_TEXT CA '&'. " Hien tai, test chi co ky tu & bi loi <(>&<)> khi in ra
*    REPLACE ALL OCCURRENCES OF '<(>' IN E_LONG_TEXT WITH SPACE.
*    REPLACE ALL OCCURRENCES OF '<)>' IN E_LONG_TEXT WITH SPACE.
*  ENDIF.
*  CONDENSE E_LONG_TEXT.

  IF E_TEXT_STR CA '&'. " Hien tai, test chi co ky tu & bi loi <(>&<)> khi in ra
    REPLACE ALL OCCURRENCES OF '<(>' IN E_TEXT_STR WITH SPACE.
    REPLACE ALL OCCURRENCES OF '<)>' IN E_TEXT_STR WITH SPACE.
  ENDIF.
  CONDENSE E_TEXT_STR.
  E_LONG_TEXT = E_TEXT_STR.
ENDFUNCTION.


*Messages
*----------------------------------------------------------
*
* Message class: ALSMEX
*037   Error during import of clipboard contents
*
* Message class: Hard coded
*   You are not authorized with company code !
*
* Message class: KX
*001   & & & &

*
*
