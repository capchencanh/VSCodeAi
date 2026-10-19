FUNCTION ZCORE_FM_READ_AMOUNT_CURRENCY.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_AMOUNT) TYPE  BSPL_REPVAL
*"     REFERENCE(I_WAERS) TYPE  WAERS
*"     REFERENCE(I_LANG) TYPE  LAND1 DEFAULT 'VI'
*"  EXPORTING
*"     REFERENCE(E_IN_WORDS) TYPE  CHAR255
*"--------------------------------------------------------------------
*TABLES : SPELL.
  DATA: T_SPELL      LIKE SPELL OCCURS 0 WITH HEADER LINE,
        AMOUNT       TYPE NUM20,
        WAERS_TEXT   TYPE LTEXT,
        LW_DONVI     TYPE CHAR15 VALUE 'đồng chẵn'.
  DATA: LW_DECIMAL   TYPE  I,
        LW_SHIFT     TYPE  I,
        LW_NUMBER    TYPE  I.
  DATA: LW_DENOMINATOR TYPE CHAR20.

  CLEAR E_IN_WORDS.


  CALL FUNCTION 'ZCORE_FM_CURR_CONVERT_COMPUTE'
    EXPORTING
      I_WAERS   = I_WAERS
    IMPORTING
      E_DECIMAL = LW_DECIMAL
      E_SHIFT   = LW_SHIFT
      E_NUMBER  = LW_NUMBER.
  IF I_LANG EQ 'EN'.
    CALL FUNCTION 'SPELL_AMOUNT'
      EXPORTING
        AMOUNT    = I_AMOUNT
        LANGUAGE  = 'E'
        CURRENCY  = I_WAERS
      IMPORTING
        IN_WORDS  = T_SPELL
      EXCEPTIONS
        NOT_FOUND = 1
        TOO_LARGE = 2
        OTHERS    = 3.
    E_IN_WORDS    = T_SPELL-WORD.
    IF LW_SHIFT EQ 2 OR ( T_SPELL-DECWORD IS INITIAL OR T_SPELL-DECWORD EQ 'ZERO' ).
      IF I_WAERS EQ 'USD'.
        CONCATENATE E_IN_WORDS 'dollars' INTO E_IN_WORDS SEPARATED BY SPACE.
      ENDIF.
    ELSE.
*digits  denominator
*     1  tenths
*     2  hundredths or one-hundredths
*     3  thousandths or one-thousandths
*     4  ten-thousandths
*     5  hundred-thousandths or one-hundred-thousandths
*     6  millionths
      IF I_WAERS EQ 'USD'.
        CONCATENATE E_IN_WORDS 'dollars and' T_SPELL-DECWORD 'cents' INTO E_IN_WORDS SEPARATED BY SPACE.
      ELSE.
      IF LW_SHIFT = 1.
        LW_DENOMINATOR = 'tenths'.
      ELSE.
        LW_DENOMINATOR = 'hundredths'.
      ENDIF.
      CONCATENATE E_IN_WORDS 'and' T_SPELL-DECWORD LW_DENOMINATOR INTO E_IN_WORDS SEPARATED BY SPACE.
      ENDIF.
    ENDIF.
    TRANSLATE E_IN_WORDS TO LOWER CASE.
    SELECT SINGLE LTEXT
      INTO WAERS_TEXT
      FROM TCURT WHERE
      WAERS EQ I_WAERS
      AND SPRAS EQ 'E'.
    IF SY-SUBRC <> 0.
      WAERS_TEXT = I_WAERS.
    ENDIF.
  ELSE."tieng viet
    IF LW_DECIMAL = 0.
      AMOUNT = ABS( I_AMOUNT ) * LW_NUMBER.
      PERFORM DOC_PHAN_NGUYEN USING AMOUNT E_IN_WORDS.
    ELSEIF I_WAERS = 'USD'.
      PERFORM DOC_SO_THAP_PHAN_USD USING I_AMOUNT E_IN_WORDS.
    ELSE.
      PERFORM DOC_SO_THAP_PHAN USING I_AMOUNT E_IN_WORDS.
    ENDIF.
    CASE I_WAERS.
      WHEN 'VND'.
        WAERS_TEXT = LW_DONVI.
      WHEN 'USD'.
        WAERS_TEXT = ''.
      WHEN 'EUR'.
        WAERS_TEXT = 'euros'.
      WHEN OTHERS.
        SELECT SINGLE KTEXT
          INTO WAERS_TEXT
          FROM TCURT
          WHERE WAERS = I_WAERS AND SPRAS = SY-LANGU.
        IF SY-SUBRC <> 0.
          WAERS_TEXT = I_WAERS.
        ENDIF.
    ENDCASE.
  ENDIF.
  IF I_LANG EQ 'EN' AND I_WAERS EQ 'USD'.
  ELSE.
    CONCATENATE E_IN_WORDS WAERS_TEXT INTO E_IN_WORDS SEPARATED BY SPACE.
  ENDIF.
  TRANSLATE E_IN_WORDS(1) TO UPPER CASE.
  CONDENSE E_IN_WORDS.





ENDFUNCTION.

*
* 
