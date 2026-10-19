FUNCTION ZCORE_FM_EXCEL_HEADER.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      T_DATA
*"--------------------------------------------------------------------
refresh t_data.
  data : lpw_line type string.
  lpw_line = '<?xml version="1.0"?>'.
  append lpw_line to t_data.
  lpw_line = '<?mso-application progid="Excel.Sheet"?>'.
  append lpw_line to t_data.
  lpw_line = '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'.
  append lpw_line to t_data.
  lpw_line = ' xmlns:o="urn:schemas-microsoft-com:office:office"'.
  append lpw_line to t_data.
  lpw_line = ' xmlns:x="urn:schemas-microsoft-com:office:excel"'.
  append lpw_line to t_data.
  lpw_line = ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'.
  append lpw_line to t_data.
  lpw_line = ' xmlns:html="http://www.w3.org/TR/REC-html40">'.
  append lpw_line to t_data.
  lpw_line = ' <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">'.
  append lpw_line to t_data.
  lpw_line = ' </DocumentProperties>'.
  append lpw_line to t_data.
  lpw_line = ' <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">'.
  append lpw_line to t_data.
  lpw_line = ' </ExcelWorkbook>'.
  append lpw_line to t_data.
  gw_header_flg = 0.





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
