**************************************************************************
*   Method attributes.                                                   *
**************************************************************************
*  Instantiation: Public
**************************************************************************

  METHOD if_ex_mb_migo_badi~reset.
    CLEAR: mt_tp_line, mv_tp_action, mv_tp_refdoc. " DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926 CS.DuyHTK Add Line 14.09.2026 16:08:50
  ENDMETHOD.

*
* 
