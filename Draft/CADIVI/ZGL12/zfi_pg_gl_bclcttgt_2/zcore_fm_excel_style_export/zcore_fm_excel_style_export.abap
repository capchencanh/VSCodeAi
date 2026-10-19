FUNCTION ZCORE_FM_EXCEL_STYLE_EXPORT.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REPORT_NAME) TYPE  ZDE_REPORT_NAME
*"  TABLES
*"      T_DATA
*"      T_STYLE STRUCTURE  ZTB_READ_EXCEL
*"--------------------------------------------------------------------
" <Font Bold><Font Italic><Font Size><Horizontal Alignment><Vertical Alignment>_<Border Style>_<Fill>_<Decimal>
  " <Font Bold>             => 1 digit  => B(Bold) / N(Null)
  " <Font Italic>           => 1 digit  => I(Italic) / N(Null)
  " <Font Size>             => 2 digit  => 10 / 16
  " <Horizontal Alignment>  => 1 digit  => L(Left) / R(Right) / C(Center) / J(Justify)
  " <Vertical Alignment>    => 1 digit  => L(Left) / R(Right) / C(Center) / J(Justify)
  " <Border Style>          => 1 digit  => B(Border) / N(Null)
  " <Fill>                  => 1 digit  => Color (Null, R, G, B, Y)
  " <Decimal>               => 1 digit  => 1, 2, 3, 4, 5 (Optional, Automatically assign based on domain)
* HIEUTP2 UPDATE USE STYLE TEMPLATE EXPORT 13.06.2014
  DATA: LW_LINE         TYPE TABLE OF STRING.

  DATA: LT_BOLD    TYPE TABLE OF CHAR1 WITH HEADER LINE,
        LT_ITALIC  TYPE TABLE OF CHAR1 WITH HEADER LINE,
        LT_SIZE    TYPE TABLE OF CHAR2 WITH HEADER LINE,
        LT_H_ALIGN TYPE TABLE OF CHAR1 WITH HEADER LINE,
        LT_V_ALIGN TYPE TABLE OF CHAR1 WITH HEADER LINE,
        LT_BORDER  TYPE TABLE OF CHAR4 WITH HEADER LINE,
        LT_FILL    TYPE TABLE OF CHAR10 WITH HEADER LINE,
        LW_COLOR   TYPE CHAR10,
        LT_DECIMAL TYPE TABLE OF CHAR1 WITH HEADER LINE.

  DATA:
        LW_STYLE TYPE TABLE OF CHAR20 WITH HEADER LINE,
*        LW_STYLE TYPE CHAR20,
        LW_COUNT TYPE INT4 VALUE 0.
  DATA: LT_STYLES       TYPE TABLE OF CHAR20 WITH HEADER LINE,
        LT_BOLD_USED    TYPE TABLE OF CHAR1 WITH HEADER LINE,
        LT_ITALIC_USED  TYPE TABLE OF CHAR1 WITH HEADER LINE,
        LT_SIZE_USED    TYPE TABLE OF CHAR2 WITH HEADER LINE,
        LT_H_ALIGN_USED TYPE TABLE OF CHAR1 WITH HEADER LINE,
        LT_V_ALIGN_USED TYPE TABLE OF CHAR1 WITH HEADER LINE.
  " Append Font Bold              => Khai Bao Danh Muc FONT BOLD
  LT_BOLD = 'B'.        " Bold
  APPEND LT_BOLD.
  LT_BOLD = 'N'.        " No Bold
  APPEND LT_BOLD.

  " Append Font Italic            => Khai Bao Danh Muc FONT ITALIC
  LT_ITALIC = 'I'.      " Italic
  APPEND LT_ITALIC.
  LT_ITALIC = 'N'.      " No Italic
  APPEND LT_ITALIC.

  " Append Font Size              => Khai Bao Danh Muc FONT SIZE
  LT_SIZE = '08'.
  APPEND LT_SIZE.
  LT_SIZE = '09'.
  APPEND LT_SIZE.
  LT_SIZE = '10'.
  APPEND LT_SIZE.
  LT_SIZE = '11'.
  APPEND LT_SIZE.
  LT_SIZE = '12'.
  APPEND LT_SIZE.
  LT_SIZE = '13'.
  APPEND LT_SIZE.
  LT_SIZE = '14'.
  APPEND LT_SIZE.
  LT_SIZE = '15'.
  APPEND LT_SIZE.
  LT_SIZE = '16'.
  APPEND LT_SIZE.

  " Append Horizontal Alignment   => Khai Bao Danh Muc HORIZONTAL ALIGNMENT
  LT_H_ALIGN = 'L'.
  APPEND LT_H_ALIGN.
  LT_H_ALIGN = 'R'.
  APPEND LT_H_ALIGN.
  LT_H_ALIGN = 'C'.
  APPEND LT_H_ALIGN.
  LT_H_ALIGN = 'J'.
  APPEND LT_H_ALIGN.

  " Append Vertical Alignment     => Khai Bao Danh Muc VERTICAL ALIGNMENT
  LT_V_ALIGN = 'T'.
  APPEND LT_V_ALIGN.
  LT_V_ALIGN = 'B'.
  APPEND LT_V_ALIGN.
  LT_V_ALIGN = 'C'.
  APPEND LT_V_ALIGN.
  LT_V_ALIGN = 'J'.
  APPEND LT_V_ALIGN.

  " Append Border                 => Khai Bao Danh Muc BORDER
  LT_BORDER = ''.       " No Border
  APPEND LT_BORDER.
  "hieutp2 update border
*  LT_BORDER = 'A'.      " Border
*  APPEND LT_BORDER.

  " Append Decimal                => Khai Bao Danh Muc DECIMAL
  LT_DECIMAL = ''.      " Null
  APPEND LT_DECIMAL.
  LT_DECIMAL = '1'.     " 1
  APPEND LT_DECIMAL.
  LT_DECIMAL = '2'.     " 2
  APPEND LT_DECIMAL.
  LT_DECIMAL = '3'.     " 3
  APPEND LT_DECIMAL.
  LT_DECIMAL = '4'.     " 4
  APPEND LT_DECIMAL.
  LT_DECIMAL = '5'.     " 5
  APPEND LT_DECIMAL.

  " Append Fill                   => Khai Bao Danh Muc FILL
  LT_FILL = ''.         " Black
  APPEND LT_FILL.
  LT_FILL = '#FF0000'.  " Red
  APPEND LT_FILL.
  LT_FILL = '#008000'.  " Green
  APPEND LT_FILL.
  LT_FILL = '#0000FF'.  " Blue
  APPEND LT_FILL.
  LT_FILL = '#FFFF00'.  " Yellow
  APPEND LT_FILL.
  LT_FILL = '#FFA500'.  " Orange
  APPEND LT_FILL.
  LT_FILL = '#C0C0C0'.  " Silver
  APPEND LT_FILL.
  LT_FILL = '#FABF8F'.  " Orange_Lighter40%
  APPEND LT_FILL.

  " Select Styles which use in Report
  SELECT DISTINCT STYLE
  INTO TABLE LT_STYLES
  FROM ZTB_READ_EXCEL
  WHERE STYLE <> ''
    AND ZTB_READ_EXCEL~REPORT_NAME = I_REPORT_NAME.
  SORT LT_STYLES.
  APPEND 'NN10CC' TO LT_STYLES.
  DELETE ADJACENT DUPLICATES FROM LT_STYLES.
  LOOP AT LT_STYLES.
    LT_BOLD_USED = LT_STYLES+0(1).
    APPEND LT_BOLD_USED.
    LT_ITALIC_USED = LT_STYLES+1(1).
    APPEND LT_ITALIC_USED.
    LT_SIZE_USED = LT_STYLES+2(2).
    APPEND LT_SIZE_USED.
    LT_H_ALIGN_USED = LT_STYLES+4(1).
    APPEND LT_H_ALIGN_USED.
    LT_V_ALIGN_USED = LT_STYLES+4(1).
    APPEND LT_V_ALIGN_USED.
    "hieutp2 update border
    IF LT_STYLES+7 IS NOT INITIAL.
      LT_BORDER = LT_STYLES+7.      " Border
      APPEND LT_BORDER.
    ENDIF.
  ENDLOOP.

  SORT LT_BOLD_USED.
  SORT LT_ITALIC_USED.
  SORT LT_SIZE_USED.
  SORT LT_H_ALIGN_USED.
  SORT LT_V_ALIGN_USED.
  SORT LT_BORDER."hieutp2 update border
  DELETE ADJACENT DUPLICATES FROM LT_BOLD_USED.
  DELETE ADJACENT DUPLICATES FROM LT_ITALIC_USED.
  DELETE ADJACENT DUPLICATES FROM LT_SIZE_USED.
  DELETE ADJACENT DUPLICATES FROM LT_H_ALIGN_USED.
  DELETE ADJACENT DUPLICATES FROM LT_V_ALIGN_USED.
  DELETE ADJACENT DUPLICATES FROM LT_BORDER."hieutp2 update border

  " Delete Styles which is not used
  LOOP AT LT_BOLD.
    READ TABLE LT_BOLD_USED WITH KEY LT_BOLD.
    IF SY-SUBRC <> 0.
      DELETE LT_BOLD.
    ENDIF.
  ENDLOOP.
  LOOP AT LT_ITALIC.
    READ TABLE LT_ITALIC_USED WITH KEY LT_ITALIC.
    IF SY-SUBRC <> 0.
      DELETE LT_ITALIC.
    ENDIF.
  ENDLOOP.
  LOOP AT LT_SIZE.
    READ TABLE LT_SIZE_USED WITH KEY LT_SIZE.
    IF SY-SUBRC <> 0.
      DELETE LT_SIZE.
    ENDIF.
  ENDLOOP.
  LOOP AT LT_H_ALIGN.
    READ TABLE LT_H_ALIGN_USED WITH KEY LT_H_ALIGN.
    IF SY-SUBRC <> 0.
      DELETE LT_H_ALIGN.
    ENDIF.
  ENDLOOP.
  LOOP AT LT_V_ALIGN.
    READ TABLE LT_V_ALIGN_USED WITH KEY LT_V_ALIGN.
    IF SY-SUBRC <> 0.
      DELETE LT_V_ALIGN.
    ENDIF.
  ENDLOOP.

  " To Hop Cac Thuoc Tinh Style
  LOOP AT LT_BOLD.
    LOOP AT LT_ITALIC.
      LOOP AT LT_SIZE.
        LOOP AT LT_H_ALIGN.
          LOOP AT LT_V_ALIGN.
            LOOP AT LT_BORDER.
              LOOP AT LT_DECIMAL.
                LOOP AT LT_FILL.
                  CONCATENATE LT_BOLD LT_ITALIC LT_SIZE LT_H_ALIGN LT_V_ALIGN INTO LW_STYLE.
                  IF LT_BORDER <> '' OR LT_DECIMAL <> '' OR LT_FILL <> ''.
                    CONCATENATE LW_STYLE '_' LT_BORDER INTO LW_STYLE.
                  ENDIF.
                  IF LT_DECIMAL <> '' OR LT_FILL <> ''.
                    CONCATENATE LW_STYLE '_' LT_DECIMAL INTO LW_STYLE.
                  ENDIF.
                  " Quy Doi Ma Mau Thanh Ky Tu Trong Style => Ky Tu Style La Null, R, G, B, Y, O, S
                  IF LT_FILL <> ''.
                    IF LT_FILL = ''.              " NULL
                      LW_COLOR = ''.
                    ELSEIF LT_FILL = '#FF0000'.   " Red
                      LW_COLOR = 'R'.
                    ELSEIF LT_FILL = '#008000'.   " Green
                      LW_COLOR = 'G'.
                    ELSEIF LT_FILL = '#0000FF'.   " Blue
                      LW_COLOR = 'B'.
                    ELSEIF LT_FILL = '#FFFF00'.   " Yellow
                      LW_COLOR = 'Y'.
                    ELSEIF LT_FILL = '#FFA500'.   " Orance
                      LW_COLOR = 'O'.
                    ELSEIF LT_FILL = '#C0C0C0'.   " Silver
                      LW_COLOR = 'S'.
                    ELSEIF LT_FILL = '#FABF8F'.   " Orange_Lighter40%
                      LW_COLOR = 'L'.
                    ENDIF.
                    CONCATENATE LW_STYLE '_' LW_COLOR INTO LW_STYLE.
                  ENDIF.
                  READ TABLE T_STYLE WITH KEY STYLE = LW_STYLE."hieutp2 update 13.06.2014
                  IF SY-SUBRC = 0.
                    READ TABLE LW_STYLE WITH KEY LW_STYLE.
                    IF SY-SUBRC <> 0.
                      LW_COUNT = LW_COUNT + 1.
                      " Goi FM Tao Style
                      IF LW_COUNT = 1.
                        CLEAR: LW_LINE[], LW_LINE.
                        CALL FUNCTION 'ZCORE_FM_EXCEL_STYLE'
                          EXPORTING
                            I_STYLEID     = LW_STYLE
                            I_FLG_FIRST   = '1'
                            I_FONTBOLD    = LT_BOLD
                            I_FONTITALIC  = LT_ITALIC
                            I_FONTSIZE    = LT_SIZE
                            I_ALIGNMENT_H = LT_H_ALIGN
                            I_ALIGNMENT_V = LT_V_ALIGN
                            I_WRAPTEXT    = '1'
                            I_BORDER      = LT_BORDER
                            I_BODYCOLOR   = LT_FILL
                            I_NUMBER      = LT_DECIMAL
                            I_FONTNAME    = 'T' "DatPT25
                          TABLES
                            T_DATA        = LW_LINE.
                        APPEND LINES OF LW_LINE TO T_DATA.
                        APPEND LW_STYLE.
                      ELSE.
                        CLEAR: LW_LINE[], LW_LINE.
                        CALL FUNCTION 'ZCORE_FM_EXCEL_STYLE'
                          EXPORTING
                            I_STYLEID     = LW_STYLE
                            I_FONTBOLD    = LT_BOLD
                            I_FONTITALIC  = LT_ITALIC
                            I_FONTSIZE    = LT_SIZE
                            I_ALIGNMENT_H = LT_H_ALIGN
                            I_ALIGNMENT_V = LT_V_ALIGN
                            I_WRAPTEXT    = '1'
                            I_BORDER      = LT_BORDER
                            I_BODYCOLOR   = LT_FILL
                            I_NUMBER      = LT_DECIMAL
                            I_FONTNAME    = 'T' "DatPT25
                          TABLES
                            T_DATA        = LW_LINE.
                        APPEND LINES OF LW_LINE TO T_DATA.
                        APPEND LW_STYLE.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                ENDLOOP.
              ENDLOOP.
            ENDLOOP.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.





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
