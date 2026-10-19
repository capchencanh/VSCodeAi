*&---------------------------------------------------------------------*
*&      Form  CHECK_CHAR_PARAM
*&---------------------------------------------------------------------*
*       Event 01 (Before saving the data in the database) của Table
*       Maintenance Generator ZTWM_CHAR_PARAM (function group ZFG_CHAR_PARAM).
*       Characteristic phải có trong CABN-ATNAM; mô tả (ATBEZ) lấy từ CABNT theo ngôn ngữ đăng nhập.
*----------------------------------------------------------------------*
FORM check_char_param.

  DATA: lv_atnam TYPE atnam,
        lv_atinn TYPE cabn-atinn,
        lv_atbez TYPE cabnt-atbez,
        lv_index TYPE sy-tabix.

  FIELD-SYMBOLS: <lfs_atnam> TYPE any,
                 <lfs_atbez> TYPE any.

  LOOP AT total.
    CHECK <action> = neuer_eintrag OR <action> = aendern.

    ASSIGN COMPONENT 'ATNAM' OF STRUCTURE <vim_total_struc> TO <lfs_atnam>.
    ASSIGN COMPONENT 'ATBEZ' OF STRUCTURE <vim_total_struc> TO <lfs_atbez>.
    lv_atnam = <lfs_atnam>.

    SELECT SINGLE atinn
      FROM cabn
      WHERE atnam = @lv_atnam
      INTO @lv_atinn.
    IF sy-subrc <> 0.
      vim_abort_saving = abap_true.
      MESSAGE s011(zwm11) WITH lv_atnam DISPLAY LIKE 'E'.
      sy-subrc = 4.
      RETURN.
    ENDIF.

    CLEAR lv_atbez.
    SELECT SINGLE atbez
      FROM cabnt
      WHERE atinn = @lv_atinn
        AND spras = @sy-langu
        AND adzhl = '0000'
      INTO @lv_atbez.
    IF lv_atbez IS NOT INITIAL.
      <lfs_atbez> = lv_atbez.
    ENDIF.
    MODIFY total.

    READ TABLE extract WITH KEY <vim_xtotal_key>.
    IF sy-subrc = 0.
      lv_index = sy-tabix.
    ELSE.
      CLEAR lv_index.
    ENDIF.
    <vim_extract_struc> = <vim_total_struc>.
    IF lv_index > 0.
      MODIFY extract INDEX lv_index.
    ENDIF.
  ENDLOOP.

  sy-subrc = 0.

ENDFORM.                    " CHECK_CHAR_PARAM
