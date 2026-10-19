**************************************************************************
*   Method attributes.                                                   *
**************************************************************************
*  Instantiation: Public
**************************************************************************

  METHOD if_ex_mb_migo_badi~mode_set.

    " DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926 CS.DuyHTK Add Begin 14.09.2026 16:04:38
  mv_tp_action = i_action.
  mv_tp_refdoc = i_refdoc.
    " DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926 CS.DuyHTK Add End 14.09.2026 16:04:38

  ENDMETHOD.

*
* 
