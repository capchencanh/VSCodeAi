**************************************************************************
*   Class attributes.                                                    *
**************************************************************************
*  Instantiation: Public
*  Message class: 
*  State: Implemented
*  Final Indicator: X
*  R/3 Release: 757

**************************************************************************
*   Public section of class.                                             *
**************************************************************************
CLASS zcl_im_le_mb_migo_badi DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_badi_interface.
    INTERFACES if_ex_mb_migo_badi.

**************************************************************************
*   Private section of class.                                            *
**************************************************************************
private section.

  data MV_TP_ACTION type GOACTION .
  data MV_TP_REFDOC type REFDOC .
  data MT_TP_LINE type ZTT_TP_MIGO_LINE .

**************************************************************************
*   Protected section of class.                                          *
**************************************************************************


**************************************************************************
*   Types section of class.                                              *
**************************************************************************
*"* dummy include to reduce generation dependencies between
*"* class ZCL_IM_LE_MB_MIGO_BADI and it's users.
*"* touched if any type reference has been changed


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   Số lượng của giao dịch nhỏ hơn số lượng trên Reservation, vui lòng kiểm t
*
* Message class: ZMC_CTK
*020   Material document &1 reversed!
*094   Không được nhập kho bằng số PO

*
* 
