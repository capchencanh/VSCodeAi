FUNCTION ZCORE_FM_GET_LONG_TEXT.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_TDOBJECT)
*"     REFERENCE(I_TDNAME)
*"     REFERENCE(I_TDID)
*"     REFERENCE(I_TDSPRAS) DEFAULT 'E'
*"  EXPORTING
*"     REFERENCE(E_LONG_TEXT)
*"     VALUE(E_TEXT_LINE1)
*"     VALUE(E_TEXT_LINE2)
*"     VALUE(E_TEXT_LINE3)
*"  TABLES
*"      ET_TLINE STRUCTURE  TLINE OPTIONAL
*"--------------------------------------------------------------------
TYPES:
    BEGIN OF LTY_LTEXT,
      TDOBJECT TYPE TDOBJECT,
      TDNAME   TYPE TDOBNAME,
      TDID     TYPE TDID,
      TDSPRAS  TYPE SPRAS,
    END OF LTY_LTEXT.
  DATA: LT_TLINE TYPE TABLE OF TLINE,
        LS_TLINE TYPE TLINE,
        LS_THEAD TYPE THEAD,
        LS_LTEXT TYPE LTY_LTEXT.
  REFRESH: LT_TLINE.
  CLEAR:
  LS_LTEXT,
  E_LONG_TEXT,
  E_TEXT_LINE1,
  E_TEXT_LINE2,
  E_TEXT_LINE3.

  LS_LTEXT-TDOBJECT = I_TDOBJECT.
  LS_LTEXT-TDNAME   = I_TDNAME  .
  LS_LTEXT-TDID     = I_TDID    .
  LS_LTEXT-TDSPRAS  = I_TDSPRAS .

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      CLIENT                  = SY-MANDT
      ID                      = LS_LTEXT-TDID
      LANGUAGE                = LS_LTEXT-TDSPRAS
      NAME                    = LS_LTEXT-TDNAME
      OBJECT                  = LS_LTEXT-TDOBJECT
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
    ET_TLINE[] = LT_TLINE.

    LOOP AT LT_TLINE INTO LS_TLINE.
      CONCATENATE E_LONG_TEXT LS_TLINE-TDLINE  INTO E_LONG_TEXT  SEPARATED BY SPACE.
    ENDLOOP.
  ELSE.
*    CASE SY-SUBRC.
*      WHEN 1. RAISE ID                     .
*      WHEN 2. RAISE LANGUAGE               .
*      WHEN 3. RAISE NAME                   .
*      WHEN 4. RAISE NOT_FOUND              .
*      WHEN 5. RAISE OBJECT                 .
*      WHEN 6. RAISE REFERENCE_CHECK        .
*      WHEN 7. RAISE WRONG_ACCESS_TO_ARCHIVE.
*    ENDCASE.
  ENDIF.
  " MaiVTT5 add - Replace special character when use special character like &...
  IF E_LONG_TEXT CA '&'. " Hien tai, test chi co ky tu & bi loi <(>&<)> khi in ra
    REPLACE ALL OCCURRENCES OF '<(>' IN E_LONG_TEXT WITH SPACE.
    REPLACE ALL OCCURRENCES OF '<)>' IN E_LONG_TEXT WITH SPACE.
  ENDIF.
  CONDENSE E_LONG_TEXT.

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


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   You are not authorized with company code !
*
* Message class: WMOD
*030   Error reading database table &1

*
*
