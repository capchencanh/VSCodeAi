FUNCTION ZFM_GET_DESCRIPTION_NEW.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_STRUCTURE_NAME) OPTIONAL
*"  TABLES
*"      GT_DATA
*"--------------------------------------------------------------------
************************************************************************
************* DYNAMIC CALL FUNCTION ************************************
  TYPES:
* CALL FUNCTION ... PARAMETER-TABLE
    BEGIN OF ABAP_FUNC_PARMBIND,
      VALUE      TYPE REF TO DATA,
      TABLES_WA  TYPE REF TO DATA,
      KIND       TYPE I,
      NAME       TYPE ABAP_PARMNAME,
      FIELDNNAME TYPE FORFIELD,
    END OF ABAP_FUNC_PARMBIND,
    ABAP_FUNC_PARMBIND_TAB TYPE SORTED TABLE OF ABAP_FUNC_PARMBIND
                           WITH UNIQUE KEY KIND NAME,

* CALL FUNCTION ... EXCEPTION-TABLE
    BEGIN OF ABAP_FUNC_EXCPBIND,
      MESSAGE TYPE REF TO DATA,
      VALUE   TYPE I,
      NAME    TYPE ABAP_EXCPNAME,
    END OF ABAP_FUNC_EXCPBIND,
    ABAP_FUNC_EXCPBIND_TAB TYPE HASHED TABLE OF ABAP_FUNC_EXCPBIND
                           WITH UNIQUE KEY NAME.

  DATA: L_TABLEDESCR_REF TYPE REF TO CL_ABAP_TABLEDESCR,
        L_DESCR_REF      TYPE REF TO CL_ABAP_STRUCTDESCR,
        WA_TABLE         TYPE ABAP_COMPDESCR.

  DATA: LS_DATA TYPE ABAP_FUNC_PARMBIND,
        LT_DATA TYPE ABAP_FUNC_PARMBIND_TAB.

  FIELD-SYMBOLS:
    <LT_TABLE> TYPE STANDARD TABLE.

  IF I_STRUCTURE_NAME IS NOT INITIAL.
    SELECT *
    INTO TABLE @DATA(LT_DD03L)
    FROM DD03L
    WHERE TABNAME    EQ @I_STRUCTURE_NAME AND
          CHECKTABLE NE @SPACE.
  ENDIF.

  L_TABLEDESCR_REF ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( GT_DATA[] ).
  L_DESCR_REF ?= L_TABLEDESCR_REF->GET_TABLE_LINE_TYPE( ).

  " Build internal table get data
  LOOP AT L_DESCR_REF->COMPONENTS INTO WA_TABLE WHERE TYPE_KIND = 'C'.
    WRITE: / WA_TABLE-NAME,WA_TABLE-TYPE_KIND,
           WA_TABLE-LENGTH,WA_TABLE-DECIMALS.

    SELECT *
    INTO TABLE @DATA(LT_DD08L)
    FROM DD08L
    WHERE FIELDNAME = @WA_TABLE-NAME AND
          AS4LOCAL  = 'A' AND
          FRKART    = 'TEXT'.
    IF SY-SUBRC = 0.
      " Number of entries > 2
      " Get from structure
      IF LINES( LT_DD08L ) > 1.
        READ TABLE LT_DD03L INTO DATA(LS_DD03L)
          WITH KEY FIELDNAME = WA_TABLE-NAME.
        IF SY-SUBRC = 0.
          READ TABLE LT_DD08L INTO DATA(LS_DD08L)
            WITH KEY CHECKTABLE = LS_DD03L-CHECKTABLE.
          IF SY-SUBRC = 0.
            DATA(LW_TABLETEXT) = LS_DD08L-TABNAME.
          ELSE.
            READ TABLE LT_DD08L INTO LS_DD08L
              INDEX 1.
            IF SY-SUBRC = 0.
              LW_TABLETEXT = LS_DD08L-TABNAME.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
        READ TABLE LT_DD08L INTO LS_DD08L
          INDEX 1.
        IF SY-SUBRC = 0.
          LW_TABLETEXT = LS_DD08L-TABNAME.
        ENDIF.
      ENDIF.
*   create and initialize application parameters
      IF LW_TABLETEXT IS NOT INITIAL.
        CREATE DATA LS_DATA-VALUE TYPE TABLE OF (LW_TABLETEXT).
        ASSIGN LS_DATA-VALUE->* TO <LT_TABLE>.

        DATA(LW_WHERE) = 'SPRAS EQ SY-LANGU'.
        SELECT *
        INTO TABLE <LT_TABLE>
        FROM (LW_TABLETEXT)
        WHERE (LW_WHERE).
*   parameter name
        LS_DATA-NAME       = LW_TABLETEXT.
        LS_DATA-FIELDNNAME = WA_TABLE-NAME.
*   parameter kind: only CHANGING parameters permitted in func.modules
*   of content provider flow logic
        LS_DATA-KIND = ABAP_FUNC_CHANGING.
        INSERT LS_DATA INTO TABLE LT_DATA.
      ENDIF.
    ENDIF.
    REFRESH: LT_DD08L.
    CLEAR: LW_TABLETEXT.
  ENDLOOP.
  BREAK-POINT.
  " Trường hợp có truyền vào field cần lấy





ENDFUNCTION.

*
* 
