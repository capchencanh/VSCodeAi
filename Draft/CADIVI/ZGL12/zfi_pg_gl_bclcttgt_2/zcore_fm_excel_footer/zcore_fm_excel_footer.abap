FUNCTION ZCORE_FM_EXCEL_FOOTER.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_FREEZEHORIZONTAL) TYPE  P OPTIONAL
*"     REFERENCE(I_FREEZEVERTICAL) TYPE  P OPTIONAL
*"     REFERENCE(I_FILE_NAME) TYPE  STRING OPTIONAL
*"     REFERENCE(I_LANDSCAPE) TYPE  CHAR1 OPTIONAL
*"  TABLES
*"      T_DATA
*"--------------------------------------------------------------------
DATA: LW_FILENAME      TYPE STRING,
        LPW_FREETEMP     TYPE CHAR10,
        LPW_DEFAULT_FILE_NAME     TYPE STRING,
        LPW_ACTIVEPANE   TYPE STRING.
  DATA: LPW_FILE_NAME    TYPE STRING,
        LPW_USER_ACTION  TYPE I.
  DATA: LW_INDEX         TYPE INT4,
        LW_STRING        TYPE STRING.
  IF GW_TABLE_FLG = 1.
*  MESSAGE E004.
  ENDIF.

  DATA : LPW_LINE TYPE STRING.
  APPEND LPW_LINE TO T_DATA.
* end lastest row
  LPW_LINE = '</Row>'.
* end table tag.
  APPEND LPW_LINE TO T_DATA.
  LPW_LINE = '</Table>'.
  APPEND LPW_LINE TO T_DATA.
*--------------------------------------------------------------------*
* fill footer tag.
  LOOP AT T_DATA[] INTO LW_STRING.
    IF LW_STRING CS '<PageSetup>' .
      LW_INDEX = SY-TABIX + 1.
    ENDIF.
  ENDLOOP.

  IF LW_INDEX <= 1.
    LPW_LINE = '  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'.
    APPEND LPW_LINE TO T_DATA.
    IF I_LANDSCAPE IS NOT INITIAL.
      LPW_LINE = '<PageSetup>'.
      APPEND LPW_LINE TO T_DATA.
      LPW_LINE = '<Layout x:Orientation="Landscape"/>'.
      APPEND LPW_LINE TO T_DATA.
      LPW_LINE = '<Header x:Margin="0.3"/>'.
      APPEND LPW_LINE TO T_DATA.
      LPW_LINE = '<Footer x:Margin="0.3"/>'.
      APPEND LPW_LINE TO T_DATA.
      LPW_LINE = '<PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>'.
      APPEND LPW_LINE TO T_DATA.
      LPW_LINE = '</PageSetup>'.
      APPEND LPW_LINE TO T_DATA.
    ENDIF.


    LPW_LINE = '   <Selected/>'.
*   fill freeze information.
    IF I_FREEZEHORIZONTAL IS NOT INITIAL OR I_FREEZEVERTICAL IS NOT INITIAL.
      LPW_LINE = '<FreezePanes/>'.
      APPEND LPW_LINE TO T_DATA.
      LPW_LINE = '   <FrozenNoSplit/>'.
      APPEND LPW_LINE TO T_DATA.
      IF I_FREEZEHORIZONTAL IS NOT INITIAL.
        CLEAR : LPW_LINE.
        LPW_FREETEMP = I_FREEZEHORIZONTAL.
        CONDENSE LPW_FREETEMP.
        CONCATENATE '<SplitHorizontal>' LPW_FREETEMP '</SplitHorizontal>' INTO LPW_LINE.
        APPEND LPW_LINE TO T_DATA.
        CLEAR LPW_LINE.
        CONCATENATE '<TopRowBottomPane>' LPW_FREETEMP '</TopRowBottomPane>' INTO LPW_LINE.
        APPEND LPW_LINE TO T_DATA.
        LPW_ACTIVEPANE = '   <ActivePane>2</ActivePane>'.
      ENDIF.
      IF I_FREEZEVERTICAL IS NOT INITIAL.
        CLEAR : LPW_LINE.
        LPW_FREETEMP = I_FREEZEVERTICAL.
        CONDENSE LPW_FREETEMP.
        CONCATENATE '<SplitVertical>' LPW_FREETEMP '</SplitVertical>' INTO LPW_LINE.
        APPEND LPW_LINE TO T_DATA.
        CLEAR LPW_LINE.
        CONCATENATE '<LeftColumnRightPane>' LPW_FREETEMP '</LeftColumnRightPane>' INTO LPW_LINE.
        APPEND LPW_LINE TO T_DATA.
        LPW_ACTIVEPANE = '   <ActivePane>1</ActivePane>'.
      ENDIF.
      IF I_FREEZEHORIZONTAL IS NOT INITIAL AND I_FREEZEVERTICAL IS NOT INITIAL.
        LPW_ACTIVEPANE = '   <ActivePane>0</ActivePane>'.
      ENDIF.
      APPEND LPW_ACTIVEPANE TO T_DATA.
    ENDIF.

*   Close tag
    APPEND LPW_LINE TO T_DATA.
    LPW_LINE = '  </WorksheetOptions>'.
  ELSEIF LW_INDEX > 0.
    LPW_LINE = '<Layout x:Orientation="Landscape"/>'.
    INSERT LPW_LINE INTO T_DATA INDEX LW_INDEX.
  ENDIF.
*--------------------------------------------------------------------*

  APPEND LPW_LINE TO T_DATA.
  LPW_LINE = ' </Worksheet>'.
  APPEND LPW_LINE TO T_DATA.
  LPW_LINE = '</Workbook>'.
  APPEND LPW_LINE TO T_DATA.
  CLEAR : GW_ROWINDEX.





ENDFUNCTION.


*Messages
*----------------------------------------------------------
*
* Message class: 00
*001   &1&2&3&4&5&6&7&8
*398   & & & &
*
* Message class: Hard coded
*   Template was not found !
*
* Message class: VZ
*000   & & & &

*
*
