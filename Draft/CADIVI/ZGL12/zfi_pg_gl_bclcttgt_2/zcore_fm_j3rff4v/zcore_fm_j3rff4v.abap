FUNCTION ZCORE_FM_J3RFF4V.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IT_BUKRS) TYPE  RSELOPTION
*"     REFERENCE(IW_VERSN) TYPE  J_3RFF4VERSN
*"     REFERENCE(IW_BUPEJ) TYPE  GJAHR
*"     REFERENCE(IW_CJAHR) TYPE  GJAHR
*"     REFERENCE(IT_MONAT) TYPE  RSELOPTION
*"     REFERENCE(IW_RLDNR) TYPE  FAGL_RLDNR OPTIONAL
*"     REFERENCE(IW_ENG) TYPE  CHAR1 DEFAULT ''
*"  TABLES
*"      ET_GL_J3RFF4V STRUCTURE  ZCORE_ST_J3RFF4V
*"--------------------------------------------------------------------
data   begin of lt_data_report occurs 0.
  data:  bukrs           like bseg-bukrs.
          include structure j_3rf_form4_alv.
  data:  gsber           like bseg-gsber,
         hide_strow      like j_3rf_form4_alv-strow,
         chapt           like j_3rff4data-chapt,
         header          type c,
         dec_total       type AFLEX17D2O22N, "summ9 DMBTR, " Version moi ( sau 7.3 chuyen tu DMBTR -> SUMM9
         dec_prev_total  type AFLEX17D2O22N, "summ9 DMBTR,
         end of lt_data_report.

  data: ls_data_report        like line of lt_data_report.

  data begin of lt_data_converted occurs 0.
  data: bukrs         type bukrs,
        gsber         type gsber,
        strow         type j_3rff4row_disp,
        text          type j_3rff4fig_descript,
        hide_strow    type j_3rf_form4_alv-strow,
        amount_total  type bspl_repval,
        amount_prev   type bspl_compval,
        end of lt_data_converted.

  data: ls_data_converted     like line of lt_data_converted.

  data: lw_sign               type char1.

  data: lt_gl_data        type table of zcore_st_j3rff4v,
        ls_gl_data        type          zcore_st_j3rff4v.
  data: lw_bukrs          type bukrs,
        lw_ktopl          type ktopl.
  data: lt_ztb_fse2       type standard table of ztb_fse2 with header line.

  " Get Chart of Account (Khong Co Truong Hop IT_BUKRS Ton Tai Nhieu Chart of Account khac nhau)
  call function 'ZCORE_FM_GET_COA'
    importing
      e_ktopl  = lw_ktopl
    tables
      it_bukrs = it_bukrs.

  " Lay du lieu tu bao cao chuan he thong
  submit zsap_pg_j_3rfform4 using selection-screen '1000'
         with sd_ktopl-low  = lw_ktopl
         with so_bukrs     in it_bukrs
         with p_vers        = iw_versn
         with bupej         = iw_bupej
         with cjahr         = iw_cjahr
         with monat        in it_monat
         with RLDNR         = iw_RLDNR "Added by DatPT25
         with x_show        = ''
         and return.
  import gt_output_list to lt_data_report from memory id 'ZGL_J3RFF4V_DATA'.

  "LOOP AT

  loop at lt_data_report into ls_data_report.
    ls_data_converted-bukrs = ls_data_report-bukrs.
    ls_data_converted-gsber = ls_data_report-gsber.
    ls_data_converted-strow = ls_data_report-strow.
    ls_data_converted-text = ls_data_report-text.
    ls_data_converted-hide_strow = ls_data_report-hide_strow.

    " Xu Ly Chuoi LS_DATA_REPORT-AMOUNT_TOTAL
    replace all occurrences of ',' in ls_data_report-amount_total with ''.
    replace all occurrences of '.' in ls_data_report-amount_total with ''.
    if ls_data_report-amount_total cs '-'.
      replace all occurrences of '-' in ls_data_report-amount_total with ''.
      ls_data_converted-amount_total = -1 * ls_data_report-amount_total / 100.
    else.
      ls_data_converted-amount_total = ls_data_report-amount_total / 100.
    endif.

    " Xu Ly Chuoi LS_DATA_REPORT-AMOUNT_PREV
    replace all occurrences of ',' in ls_data_report-amount_prev with ''.
    replace all occurrences of '.' in ls_data_report-amount_prev with ''.
    if ls_data_report-amount_prev cs '-'.
      replace all occurrences of '-' in ls_data_report-amount_prev with ''.
      ls_data_converted-amount_prev = -1 * ls_data_report-amount_prev / 100.
    else.
      ls_data_converted-amount_prev = ls_data_report-amount_prev / 100.
    endif.

    append ls_data_converted to lt_data_converted.
    clear ls_data_converted.
  endloop.

  " Map Du Lieu LT_DATA_REPORT
  " T-Code ZFSE2
  select *
    into table lt_ztb_fse2
    from ztb_fse2
    where versn = iw_versn.

  clear: lt_gl_data.
  loop at lt_data_converted into ls_data_converted.
    ls_gl_data-strow = ls_data_converted-strow.
    ls_gl_data-text = ls_data_converted-text.

    read table lt_ztb_fse2 with key versn = iw_versn
                                    ergsl = ls_gl_data-strow.
    if sy-subrc = 0.
      ls_gl_data-note         = lt_ztb_fse2-note.

      if iw_eng is not initial. "Update by DatPT25 - Get long description in English ( if necessary )
        ls_gl_data-description  = lt_ztb_fse2-des_en.
      else.
        ls_gl_data-description  = lt_ztb_fse2-description.
      endif.

      ls_gl_data-bold         = lt_ztb_fse2-bold.
      ls_gl_data-italic       = lt_ztb_fse2-italic.
    endif.

    if ls_gl_data-description <> ''.
      ls_gl_data-group_name = ls_gl_data-description.
    else.
      ls_gl_data-group_name = ls_gl_data-text.
    endif.

    if ls_gl_data-bold = '' and ls_gl_data-italic = ''.
      ls_gl_data-group = 1. " Not Bold, Not Italic
    endif.
    if ls_gl_data-bold = 'X' and ls_gl_data-italic = ''.
      ls_gl_data-group = 2. " Bold, Not Italic
    endif.
    if ls_gl_data-bold = '' and ls_gl_data-italic = 'X'.
      ls_gl_data-group = 3. " Not Bold, Italic
    endif.
    if ls_gl_data-bold = 'X' and ls_gl_data-italic = 'X'.
      ls_gl_data-group = 4. " Bold, Italic
    endif.

    ls_gl_data-waers = 'VND'.
    ls_gl_data-repval = ls_data_converted-amount_total.
    ls_gl_data-compval = ls_data_converted-amount_prev.

    append ls_gl_data to lt_gl_data.
    clear: ls_gl_data.
  endloop.

  " Delete Cac Chi Tieu Bat Dau Boi Dau @ (Cac Chi Tieu Bo)
  delete lt_gl_data where strow cp '@*'.

  " Export data
  append lines of lt_gl_data to et_gl_j3rff4v.





ENDFUNCTION.

*
*
