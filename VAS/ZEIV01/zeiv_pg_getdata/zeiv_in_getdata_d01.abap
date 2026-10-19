*----------------------------------------------------------------------*
***INCLUDE ZEIV_IN_GETDATA_D01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form BUILD_FIELDCAT_HEADER
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM BUILD_FIELDCAT_HEADER .
  DATA: LW_NO_OUT TYPE CHECKBOX.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      I_STRUCTURE_NAME       = 'ZEIV_ST_GETDATA'
    CHANGING
      CT_FIELDCAT            = GT_FIELDCAT_HEADER[]
    EXCEPTIONS
      INCONSISTENT_INTERFACE = 1
      PROGRAM_ERROR          = 2
      OTHERS                 = 3.

  IF P_BUKRS EQ '2000' AND ( R_FI EQ 'X' OR R_MM EQ 'X' ).
    LW_NO_OUT = ''.
  ELSE.
    LW_NO_OUT = 'X'.
  ENDIF.

  LOOP AT GT_FIELDCAT_HEADER ASSIGNING <FS_FIELDCAT>.
    CASE <FS_FIELDCAT>-FIELDNAME.
      WHEN 'CHECK'.
        <FS_FIELDCAT>-EDIT     = 'X'.
        <FS_FIELDCAT>-CHECKBOX = 'X'.
        <FS_FIELDCAT>-COL_POS  = 1.
        <FS_FIELDCAT>-REPTEXT   = 'Check'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Check'.
      WHEN 'BUDAT'.
        <FS_FIELDCAT>-REPTEXT   = 'Posting Date'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Posting Date'.
        <FS_FIELDCAT>-COL_POS = 2.
      WHEN 'BUKRS'.
        <FS_FIELDCAT>-COL_POS = 3.
      WHEN 'GJAHR'.
        <FS_FIELDCAT>-COL_POS = 4.
      WHEN 'BELNR'.
        <FS_FIELDCAT>-COL_POS = 5.
      WHEN 'KUNNR'.
        <FS_FIELDCAT>-COL_POS = 6.
      WHEN 'LIFNR'.
        <FS_FIELDCAT>-COL_POS = 7.
      WHEN 'BNAME'.
        <FS_FIELDCAT>-COL_POS = 8.
      WHEN 'BUNAM'.
        <FS_FIELDCAT>-COL_POS = 8.
      WHEN 'BCODE'.
        <FS_FIELDCAT>-COL_POS = 9.
      WHEN 'BADDR'.
        <FS_FIELDCAT>-COL_POS = 10.
      WHEN 'BBACC'.
        <FS_FIELDCAT>-COL_POS = 10.
      WHEN 'WAERK'.
        <FS_FIELDCAT>-REPTEXT   = 'Currency'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Currency'.
        <FS_FIELDCAT>-COL_POS = 11.
      WHEN 'AMOUNT'.
        <FS_FIELDCAT>-REPTEXT   = 'Net Amount'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Net Amount'.
        <FS_FIELDCAT>-COL_POS = 12.
      WHEN 'TAMOUNT'.
        <FS_FIELDCAT>-REPTEXT   = 'Tax amount'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Tax amount'.
        <FS_FIELDCAT>-COL_POS = 13.
      WHEN 'GROSS_AMOUNT'.
        <FS_FIELDCAT>-REPTEXT   = 'Total Amount in document currency'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Total Amount in document currency'.
        <FS_FIELDCAT>-COL_POS = 14.
      WHEN 'GROSS_AMOUNT_LC'.
        <FS_FIELDCAT>-REPTEXT   = 'Total Amount in local currency'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Total Amount in local currency'.
        <FS_FIELDCAT>-COL_POS = 15.
      WHEN 'KURRF'.
        <FS_FIELDCAT>-COL_POS = 16.
      WHEN 'EMAIL'.
        <FS_FIELDCAT>-COL_POS = 17.
      WHEN 'AWKEY'.
        <FS_FIELDCAT>-COL_POS = 18.
      WHEN 'TEN_TAU'.
        <FS_FIELDCAT>-COL_POS = 18.
        <FS_FIELDCAT>-NO_OUT  = LW_NO_OUT.
        <FS_FIELDCAT>-TECH    = LW_NO_OUT.
      WHEN 'QUOC_TICH'.
        <FS_FIELDCAT>-COL_POS = 19.
        <FS_FIELDCAT>-NO_OUT  = LW_NO_OUT.
        <FS_FIELDCAT>-TECH    = LW_NO_OUT.
      WHEN 'TRONG_TAI'.
        <FS_FIELDCAT>-COL_POS = 20.
        <FS_FIELDCAT>-NO_OUT  = LW_NO_OUT.
        <FS_FIELDCAT>-TECH    = LW_NO_OUT.
      WHEN 'NGAY_DEN'.
        <FS_FIELDCAT>-COL_POS = 21.
        <FS_FIELDCAT>-NO_OUT  = LW_NO_OUT.
        <FS_FIELDCAT>-TECH    = LW_NO_OUT.
      WHEN 'NGAY_DI'.
        <FS_FIELDCAT>-COL_POS = 22.
        <FS_FIELDCAT>-NO_OUT  = LW_NO_OUT.
        <FS_FIELDCAT>-TECH    = LW_NO_OUT.
      WHEN 'NOI_DAU'.
        <FS_FIELDCAT>-COL_POS = 23.
        <FS_FIELDCAT>-NO_OUT  = LW_NO_OUT.
        <FS_FIELDCAT>-TECH    = LW_NO_OUT.
      WHEN 'CAN_CU'.
        <FS_FIELDCAT>-COL_POS = 24.
        <FS_FIELDCAT>-NO_OUT  = LW_NO_OUT.
        <FS_FIELDCAT>-TECH    = LW_NO_OUT.
      WHEN 'LOAI_HANG'.
        <FS_FIELDCAT>-COL_POS = 25.
        <FS_FIELDCAT>-NO_OUT  = LW_NO_OUT.
        <FS_FIELDCAT>-TECH    = LW_NO_OUT.
      WHEN 'NOTE'.
        <FS_FIELDCAT>-COL_POS = 26.
      WHEN 'ORIGINALINVOICE'.
        <FS_FIELDCAT>-COL_POS = 27.
      WHEN 'FKDAT'.
        <FS_FIELDCAT>-COL_POS = 28.
      WHEN 'JSON_REQ'.
        <FS_FIELDCAT>-COL_POS = 29.
        <FS_FIELDCAT>-HOTSPOT = 'x'.
        <FS_FIELDCAT>-JUST    = 'C'.
        <FS_FIELDCAT>-REPTEXT = 'Show Json'.
      WHEN OTHERS.
        <FS_FIELDCAT>-TECH = 'X'.
        <FS_FIELDCAT>-NO_OUT = 'X'.
    ENDCASE.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form BUILD_FIELDCAT_DETAIL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM BUILD_FIELDCAT_DETAIL .
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      I_STRUCTURE_NAME       = 'ZEB_ST_DETAIL'
    CHANGING
      CT_FIELDCAT            = GT_FIELDCAT_DETAIL[]
    EXCEPTIONS
      INCONSISTENT_INTERFACE = 1
      PROGRAM_ERROR          = 2
      OTHERS                 = 3.
  LOOP AT GT_FIELDCAT_DETAIL ASSIGNING <FS_FIELDCAT>.
    CASE <FS_FIELDCAT>-FIELDNAME.
*      WHEN 'MATNR' OR 'REMARK' OR 'MANDT' OR 'BUKRS' OR 'GJAHR' OR 'BELNR' OR 'TXGRP'.
*        <FS_FIELDCAT>-TECH     = 'X'.
*        <FS_FIELDCAT>-NO_OUT   = 'X'.
      WHEN 'BUKRS'.
        <FS_FIELDCAT>-COL_POS = 1.
      WHEN 'GJAHR'.
        <FS_FIELDCAT>-COL_POS = 2.
      WHEN 'BELNR'.
        <FS_FIELDCAT>-COL_POS = 3.
      WHEN 'MATNR'.
        <FS_FIELDCAT>-OUTPUTLEN = '18'.
        <FS_FIELDCAT>-COL_POS = 4.
      WHEN 'INAME'.
        <FS_FIELDCAT>-REPTEXT   = 'Material Name'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Price'.
        <FS_FIELDCAT>-OUTPUTLEN = '40'.
        <FS_FIELDCAT>-COL_POS = 5.
      WHEN 'SGTXT'.
        <FS_FIELDCAT>-OUTPUTLEN = '20'.
        <FS_FIELDCAT>-COL_POS = 6.
      WHEN 'MENGE'.
        <FS_FIELDCAT>-COL_POS = 7.
      WHEN 'UNIT'.
        <FS_FIELDCAT>-COL_POS = 8.
      WHEN 'PRICE'.
        <FS_FIELDCAT>-COL_POS = 9.
        <FS_FIELDCAT>-REPTEXT   = 'Unit price'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Unit price'.
      WHEN 'AMOUNT'.
        <FS_FIELDCAT>-REPTEXT   = 'Net Amount'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Net Amount'.
        <FS_FIELDCAT>-COL_POS = 10.
      WHEN 'TAMOUNT'.
        <FS_FIELDCAT>-REPTEXT   = 'Tax amount'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Tax amount'.
        <FS_FIELDCAT>-COL_POS = 11.
      WHEN 'NET_AMOUNT'.
        <FS_FIELDCAT>-REPTEXT   = 'Net amount'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Net amount'.
        <FS_FIELDCAT>-COL_POS = 12.
      WHEN 'GROSS_AMOUNT'.
        <FS_FIELDCAT>-REPTEXT   = 'Gross amount in document currency'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Gross amount in document currency'.
        <FS_FIELDCAT>-COL_POS = 13.
      WHEN 'GROSS_AMOUNT_LC'.
        <FS_FIELDCAT>-REPTEXT   = 'Gross Amount in local currency'.
        <FS_FIELDCAT>-SCRTEXT_S = <FS_FIELDCAT>-SCRTEXT_M = <FS_FIELDCAT>-SCRTEXT_L = 'Gross Amount in local currency'.
        <FS_FIELDCAT>-COL_POS = 14.
      WHEN 'TAX'.
        <FS_FIELDCAT>-COL_POS = 15.
      WHEN 'ISDISCOUNT'.
        <FS_FIELDCAT>-COL_POS = 16.
      WHEN OTHERS.
        <FS_FIELDCAT>-TECH     = 'X'.
        <FS_FIELDCAT>-NO_OUT   = 'X'.
    ENDCASE.
  ENDLOOP.
ENDFORM.

*
*
