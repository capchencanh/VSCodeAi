FUNCTION ZCORE_FM_EXCEL_TABLE.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_ROWINDEX) TYPE  P OPTIONAL
*"     VALUE(I_COLINDEX) TYPE  P OPTIONAL
*"     VALUE(I_MERGEACROSS) TYPE  INT1 OPTIONAL
*"     VALUE(I_MERGEDOWN) TYPE  INT1 OPTIONAL
*"     VALUE(I_STYLEID) TYPE  CHAR20 OPTIONAL
*"     VALUE(I_CONTENT) OPTIONAL
*"     VALUE(I_TYPEDATA) TYPE  CHAR1 OPTIONAL
*"     VALUE(I_HEIGHT) TYPE  P OPTIONAL
*"     VALUE(I_FORMULA) TYPE  CHAR1 OPTIONAL
*"     VALUE(I_ROWFROM) TYPE  P OPTIONAL
*"     VALUE(I_COLFROM) TYPE  P OPTIONAL
*"     VALUE(I_ROWTO) TYPE  P OPTIONAL
*"     VALUE(I_COLTO) TYPE  P OPTIONAL
*"     VALUE(I_FOR_STR) TYPE  STRING OPTIONAL
*"     VALUE(I_FLG_FIRST) TYPE  NUM1 DEFAULT '0'
*"     VALUE(I_SHEET_NAME) TYPE  CHAR40 OPTIONAL
*"     VALUE(I_DISPLAY_ZERO) TYPE  CHAR1 OPTIONAL
*"  TABLES
*"      T_DATA
*"--------------------------------------------------------------------
data: lpw_line          type string,
        lpw_indrowtemp    type char45,
        lpw_indcoltemp    type char45,
        lpw_merdowntemp   type char45,
        lpw_meracrosstemp type char45,
        lpw_styletemp     type char255,
        lpw_formulatemp   type char255,
        lpw_datatemp      type string,
        lpw_heighttemp    type char30,
        lpw_temp          type char20,
        lpw_rowfrom       type char20,
        lpw_colfrom       type char20,
        lpw_rowto         type char20,
        lpw_colto         type char20,
        lpw_content       type string,
        lpw_for_str       type string,
        lpw_number(16)    type p decimals 5.
* check style flag and set table flag.
  if gw_style_flg = 1.
*    MESSAGE E001.
  else.
    gw_table_flg = 0.
  endif.

* check row index, column index.
  if i_rowindex < gw_rowindex.
*    MESSAGE E002 WITH I_ROWINDEX.
  elseif i_rowindex > gw_rowindex.
    gw_colindex = 0.
  else.
    if i_colindex <= gw_colindex.
*      MESSAGE E003 WITH I_COLINDEX.
    else.
      gw_colindex = i_colindex.
    endif.
  endif.
* Add new by Longnd 04082010 *
*----------------------------*
  if i_flg_first = 1.
    gw_rowindex = 0.
  endif.
*----------------------------*
* if just have fill first row.
  if gw_rowindex = 0 and gw_colwidth_flg = '1'.
*   close tag style
    lpw_line = '</Styles>'.
    append lpw_line to t_data.
*   start worksheet tag.
    if i_sheet_name is initial .
      lpw_line = ' <Worksheet ss:Name="Sheet1">'.
    elseif i_sheet_name is not initial .
      concatenate ' <Worksheet ss:Name="' i_sheet_name '">' into lpw_line.
    endif.
    append lpw_line to t_data.
*   start table tag.
    lpw_line = '<Table> '.
    append lpw_line to t_data.
*   start first row tag
    lpw_indrowtemp = i_rowindex.
    condense lpw_indrowtemp.
    if i_height is not initial.
      lpw_heighttemp = i_height.
      condense lpw_heighttemp.
      concatenate '" ss:Height="' lpw_heighttemp into lpw_heighttemp.
    endif.
    clear lpw_line.
    concatenate '<Row ss:Index="'   lpw_indrowtemp lpw_heighttemp '">' into lpw_line.
    append lpw_line to t_data.
    gw_rowindex = i_rowindex.
  elseif gw_rowindex = 0 and gw_colwidth_flg = '0'.
    lpw_indrowtemp = i_rowindex.
    condense lpw_indrowtemp.
    if i_height is not initial.
      lpw_heighttemp = i_height.
      condense lpw_heighttemp.
      concatenate '" ss:Height="' lpw_heighttemp into lpw_heighttemp.
    endif.
    clear lpw_line.
    concatenate '<Row ss:Index="'   lpw_indrowtemp  lpw_heighttemp '">' into lpw_line.
    append lpw_line to t_data.
    gw_rowindex = i_rowindex.
  else.
    if gw_rowindex <> i_rowindex.
*     end previous row.
      lpw_line = '</Row>'.
      append lpw_line to t_data.
*     start new row tag
      lpw_indrowtemp = i_rowindex.
      condense lpw_indrowtemp.
      if i_height is not initial.
        lpw_heighttemp = i_height.
        condense lpw_heighttemp.
        concatenate '" ss:Height="' lpw_heighttemp into lpw_heighttemp.
      endif.
      clear lpw_line.
      concatenate '<Row ss:Index="'   lpw_indrowtemp lpw_heighttemp '">' into lpw_line.
      append lpw_line to t_data.
*     set row index
      gw_rowindex = i_rowindex.
    endif.
  endif.

* fill contain column tag.
* index column information
  lpw_temp = i_colindex.
  condense lpw_temp.
  concatenate  ' ss:Index="' lpw_temp '"' into lpw_indcoltemp.
* merge information
  if i_mergedown > 0.
    lpw_temp = i_mergedown.
    condense lpw_temp.
    concatenate ' ss:MergeDown="' lpw_temp '"' into lpw_merdowntemp.
  endif.

  if i_mergeacross > 0.
    lpw_temp = i_mergeacross.
    condense lpw_temp.
    concatenate ' ss:MergeAcross="' lpw_temp '"' into lpw_meracrosstemp.
  endif.

* style information.
  if i_styleid is not initial.
    lpw_temp = i_styleid.
    concatenate ' ss:StyleID="' lpw_temp '"' into lpw_styletemp.
  endif.

* formula information.
  if i_formula is not initial.
    if i_rowfrom < 0.
      i_rowfrom = -1 * i_rowfrom.
      lpw_rowfrom = i_rowfrom.
      condense lpw_rowfrom.
      concatenate '-' lpw_rowfrom into lpw_rowfrom.
    else.
      lpw_rowfrom = i_rowfrom.
    endif.

    if i_colfrom < 0.
      i_colfrom = -1 * i_colfrom.
      lpw_colfrom = i_colfrom.
      condense lpw_colfrom.
      concatenate '-' lpw_colfrom into lpw_colfrom.
    else.
      lpw_colfrom = i_colfrom.
    endif.

    if i_rowto < 0.
      i_rowto = -1 * i_rowto.
      lpw_rowto = i_rowto.
      condense lpw_rowto.
      concatenate '-' lpw_rowto into lpw_rowto.
    else.
      lpw_rowto = i_rowto.
    endif.

    if i_colto < 0.
      i_colto = -1 * i_colto.
      lpw_colto = i_colto.
      condense lpw_colto.
      concatenate '-' lpw_colto into lpw_colto.
    else.
      lpw_colto = i_colto.
    endif.
    condense:lpw_rowfrom , lpw_colfrom , lpw_rowto , lpw_colto .
    if i_formula = 'S'.
      concatenate ' ss:Formula="=SUM(R[' lpw_rowfrom  ']C[' lpw_colfrom ']:R[' lpw_rowto ']C[' lpw_colto '])"' into lpw_formulatemp.
    elseif i_formula = 'A'.
      concatenate ' ss:Formula="=AVERAGE(R[' lpw_rowfrom  ']C[' lpw_colfrom ']:R[' lpw_rowto ']C[' lpw_colto '])"' into lpw_formulatemp.
    endif.
  endif.
  " Fomular
  if i_for_str is not initial.
    " ss:Formula="=RC[-2]+RC[-1]"
    concatenate ' ss:Formula="=' i_for_str '"' into lpw_for_str.
  endif.
* data information.
  if i_typedata = 'N'.
    if i_content co ' .-0123456789'. " MaiVTT5 add
      lpw_number = i_content.
    if i_display_zero = 'X'.
      if lpw_number < 0.      "I_CONTENT < 0.
        i_content = -1 * i_content.
        lpw_content = i_content.
        concatenate '-' lpw_content into lpw_content.
        condense lpw_content no-gaps.
      elseif lpw_number >= 0.  "I_CONTENT >= 0.
        lpw_content = i_content.
        condense lpw_content.
      endif.
    else.
      if lpw_number < 0. " I_CONTENT < 0.
        i_content = -1 * i_content.
        lpw_content = i_content.
        concatenate '-' lpw_content into lpw_content.
        condense lpw_content no-gaps.
      elseif lpw_number > 0. "I_CONTENT > 0.
        lpw_content = i_content.
        condense lpw_content.
      endif.
    endif.
    endif.
  elseif i_typedata = 'D'.
    if i_content is not initial and i_content ne '00000000'.
      concatenate i_content+6(2) '/' i_content+4(2) '/' i_content+0(4) into lpw_content.
    endif.
  elseif i_typedata = 'T'.
    if i_content is not initial.
      concatenate i_content+0(2) 'h' i_content+2(2) into lpw_content. "'m' I_CONTENT+4(2) 's' INTO LPW_CONTENT.
    endif.
  else.
    lpw_content = i_content.
    condense lpw_content.
  endif.

  if lpw_content is not initial.
    if i_typedata = 'S' or i_typedata = 'D' or i_typedata = 'T'.
      concatenate '<Data ss:Type="String">' lpw_content '</Data>' into lpw_datatemp.
    else.
      concatenate '<Data ss:Type="Number">' lpw_content '</Data>' into lpw_datatemp.
    endif.
  endif.

* fill column.
  clear lpw_line.
  concatenate '<Cell' lpw_for_str lpw_indcoltemp  lpw_meracrosstemp lpw_merdowntemp lpw_styletemp lpw_formulatemp '>' lpw_datatemp '</Cell>' into lpw_line.
  append lpw_line to t_data.





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
