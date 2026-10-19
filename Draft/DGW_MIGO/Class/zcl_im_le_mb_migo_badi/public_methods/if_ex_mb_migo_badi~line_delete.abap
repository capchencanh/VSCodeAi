**************************************************************************
*   Method attributes.                                                   *
**************************************************************************
*  Instantiation: Public
**************************************************************************

  METHOD if_ex_mb_migo_badi~line_delete.
    DELETE mt_tp_line WHERE line_id = i_line_id. " DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926 CS.DuyHTK Add Line 14.09.2026 16:06:50
  ENDMETHOD.

*
* 
