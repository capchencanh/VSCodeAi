**************************************************************************
*   Method attributes.                                                   *
**************************************************************************
*  Instantiation: Public
**************************************************************************

  METHOD if_ex_mb_migo_badi~check_item.

    " DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926 CS.DuyHTK Add Begin 14.09.2026 16:09:23
DATA: ls_tp_check  TYPE zst_tp_migo_line,
        ls_tp_line   TYPE zst_tp_migo_line,
        ls_tp_return TYPE bapiret2,
        lv_tp_first  TYPE mb_line_id.

  IF mv_tp_action = zcl_mm_tp_mvt_check=>gc_migo-action_transfer_posting
 AND mv_tp_refdoc = zcl_mm_tp_mvt_check=>gc_migo-refdoc_other.

    READ TABLE mt_tp_line INTO ls_tp_check
         WITH TABLE KEY line_id = i_line_id.

    IF sy-subrc = 0 AND ls_tp_check-bwart IS NOT INITIAL.


      CLEAR lv_tp_first.
      LOOP AT mt_tp_line INTO ls_tp_line
           WHERE bwart = ls_tp_check-bwart.
        lv_tp_first = ls_tp_line-line_id.
        EXIT.
      ENDLOOP.


      IF lv_tp_first <> i_line_id.
        RETURN.
      ENDIF.

      ls_tp_return = zcl_mm_tp_mvt_check=>check_migo_item(
                       iv_action = mv_tp_action
                       iv_refdoc = mv_tp_refdoc
                       iv_bwart  = ls_tp_check-bwart ).

      IF ls_tp_return IS NOT INITIAL.
        APPEND ls_tp_return TO et_bapiret2.
      ENDIF.

    ENDIF.

  ENDIF.
    " DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926 CS.DuyHTK Add End 14.09.2026 16:09:23

  ENDMETHOD.

*
* 
