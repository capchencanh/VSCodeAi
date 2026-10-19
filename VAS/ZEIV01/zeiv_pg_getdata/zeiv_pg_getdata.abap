*&---------------------------------------------------------------------*
*& Report ZEIV_PG_GETDATA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZEIV_PG_GETDATA.
INCLUDE ZEIV_IN_GETDATA_TOP.
INCLUDE ZEIV_IN_GETDATA_F01.
INCLUDE ZEIV_IN_GETDATA_O01.
INCLUDE ZEIV_IN_GETDATA_I01.
INCLUDE ZEIV_IN_GETDATA_D01.
*-----------------------------------------------------------------------*
*     A T  S E L E T I O N - S C R E E N  O U T P U T
* ----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  PERFORM CHECK_CONDITION.

START-OF-SELECTION.
  PERFORM GET_DATA.
  PERFORM SUMBIT_PROGRAM.
  CALL SCREEN 0100.

*GUI Texts
*----------------------------------------------------------
* ZTITLE_ZEIV01 --> Send data from SAP to BKAV

*Text elements
*----------------------------------------------------------
* 001 Options:


*Selection texts
*----------------------------------------------------------
* P_BUKRS         Company Code
* P_KG         In theo đvt KG
* P_NEW         New
* P_UPD         Update
* R_FI         FI Document
* R_MM         Return to Vendor
* R_SD         Billing
* S_BELNR         Document Number
* S_BLART         Document Type
* S_BUDAT         Posting Date
* S_GJAHR D       .
* S_KUNNR D       .
* S_LIFNR D       .
* S_VBELN         Billing Number


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   NO DATA
*
* Message class: ZMC_EINV
*010   Finished Processing

*
*
