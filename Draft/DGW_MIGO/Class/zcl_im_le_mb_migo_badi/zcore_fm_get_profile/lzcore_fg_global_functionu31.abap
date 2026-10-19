FUNCTION ZCORE_FM_DRILL_DOWN.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_TABLENAME)
*"     REFERENCE(I_SELFIELD) TYPE  SLIS_SELFIELD
*"     REFERENCE(OPT_DISABLE_BELNR) TYPE  XDYNP OPTIONAL
*"     REFERENCE(OPT_DISABLE_KUNNR) TYPE  XDYNP OPTIONAL
*"     REFERENCE(OPT_DISABLE_LIFNR) TYPE  XDYNP OPTIONAL
*"     REFERENCE(OPT_DISABLE_MBLNR) TYPE  XDYNP OPTIONAL
*"     REFERENCE(OPT_DISABLE_MATNR) TYPE  XDYNP OPTIONAL
*"--------------------------------------------------------------------
data: lw_table    type text60.

  data: lw_bukrs    type bukrs,
        lw_gjahr    type gjahr,
        lw_mjahr    type mjahr,
        lw_kunnr    type kunnr,
        lw_lifnr    type lifnr,
        lw_belnr    type belnr_d,
        lw_mblnr    type mblnr,
        lw_matnr    type matnr.


  field-symbols: <lf_field>     type any,
                 <lf_structure> type any,
                 <lf_table>     type standard table.


  concatenate '(' sy-cprog ')' i_tablename into lw_table.
  assign (lw_table) to <lf_table>.
  if sy-subrc eq 0.
    read table <lf_table>
      assigning <lf_structure>
      index i_selfield-tabindex.
    if sy-subrc eq 0.
      assign component i_selfield-fieldname of structure <lf_structure> to <lf_field>.
      if sy-subrc ne 0.
        raise err_data.
      endif.
    else.
      raise err_data.
    endif.
  else.
    raise err_data.
  endif.




  " Drilldown Material Master Data (Transaction MM03)
  if i_selfield-fieldname = 'MATNR' and opt_disable_matnr = ''.
    lw_matnr = <lf_field>.

    set parameter id 'MAT'  field lw_matnr.
    call transaction 'MM03' and skip first screen.

    exit.
  endif.

  " Drilldown Customer Company Code Master Data (Transaction XD03)
  if i_selfield-fieldname = 'KUNNR' and opt_disable_kunnr = ''.
    lw_kunnr = <lf_field>.
    assign component 'BUKRS' of structure <lf_structure> to <lf_field>.
    if sy-subrc eq 0.
      lw_bukrs = <lf_field>.
    else.
      raise err_row.
    endif.

    set parameter id 'KUN'  field lw_kunnr.
    set parameter id 'BUK'  field lw_bukrs.
    call transaction 'XD03' and skip first screen.

    exit.
  endif.

  " Drilldown Vendor Company Code Master Data (Transaction XK03)
  if i_selfield-fieldname = 'LIFNR' and opt_disable_lifnr = ''.
    lw_lifnr = <lf_field>.
    assign component 'BUKRS' of structure <lf_structure> to <lf_field>.
    if sy-subrc eq 0.
      lw_bukrs = <lf_field>.
    else.
      raise err_row.
    endif.

    set parameter id 'LIF'  field lw_lifnr.
    set parameter id 'BUK'  field lw_bukrs.
    call transaction 'XK03'.

    exit.
  endif.




  " Drilldown Accounting Document (Transaction FB03)
  if i_selfield-fieldname = 'BELNR' and opt_disable_belnr = ''.
    lw_belnr = <lf_field>.
    assign component 'BUKRS' of structure <lf_structure> to <lf_field>.
    if sy-subrc eq 0.
      lw_bukrs = <lf_field>.
    else.
      raise err_row.
    endif.

    assign component 'GJAHR' of structure <lf_structure> to <lf_field>.
    if sy-subrc eq 0.
      lw_gjahr = <lf_field>.
    else.
      raise err_row.
    endif.

    set parameter id 'BLN'  field lw_belnr.
    set parameter id 'BUK'  field lw_bukrs.
    set parameter id 'GJR'  field lw_gjahr.
    call transaction 'FB03' and skip first screen.

    exit.
  endif.

  " Drilldown Material Document (Transaction MB03)
  if i_selfield-fieldname = 'MBLNR' and opt_disable_mblnr = ''.
    lw_mblnr = <lf_field>.
    assign component 'MJAHR' of structure <lf_structure> to <lf_field>.
    if sy-subrc eq 0.
      lw_mjahr = <lf_field>.
    else.
      raise err_row.
    endif.

    set parameter id 'MBN'  field lw_mblnr.
    set parameter id 'MJA'  field lw_mjahr.
    call transaction 'MB03' and skip first screen.

    exit.
  endif.





ENDFUNCTION.

*
* 
