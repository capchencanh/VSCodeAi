*&---------------------------------------------------------------------*
*& Program ID     ZFI_PG_GL_BCLCTTGT
*& Program Title  Báo cáo lưu chuyển tiền tệ gián tiếp
*&---------------------------------------------------------------------*
*& Version      Date          ABAPer      Action    Comments
*& 1.00         17/08/2015    DUYNC4       Create
*&---------------------------------------------------------------------*
* Modification ID    : M000
* ABAPer             : DatPT25
* Date               : 25.11.2015 09:31:20
* FS version         : 1.1
* Requested by       : Update
* Description        : Update header information : year
* Transport number   :
*&---------------------------------------------------------------------*

REPORT ZFI_PG_GL_BCLCTTGT_2.

INCLUDE ZFI_IN_GL_BCLCTTGT_2_TOP_N.
*INCLUDE ZFI_IN_GL_BCLCTTGT_TOP_N.
*INCLUDE ZFI_IN_GL_BCLCTTGT_TOP.
INCLUDE ZFI_IN_GL_BCLCTTGT_2_F01_N.
*INCLUDE ZFI_IN_GL_BCLCTTGT_F01_N.
*INCLUDE ZFI_IN_GL_BCLCTTGT_F01.

INITIALIZATION.
  PERFORM INIT.

AT SELECTION-SCREEN OUTPUT.
  PERFORM SET_SCREEN.

AT SELECTION-SCREEN.
  PERFORM CHECK_CONDITION.

START-OF-SELECTION.
* Parameter excecute
  PERFORM GET_PARAMETER.
* Get data
  PERFORM FILL_DATA.
* Data processing
  PERFORM DATA_PROCESSING.
* Export data
  PERFORM EXPORT_DATA.


*Selection texts
*----------------------------------------------------------
* S_PER         Period


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   Compare Fiscal Year and Fiscal Year should have different value!

*
*
