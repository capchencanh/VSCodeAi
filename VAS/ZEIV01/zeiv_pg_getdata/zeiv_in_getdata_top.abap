*&---------------------------------------------------------------------*
*& Include          ZEIV_IN_GETDATA_TOP
*&---------------------------------------------------------------------*
TABLES: T001, T003, BKPF, VBRK, BSEG.

SELECTION-SCREEN BEGIN OF BLOCK B1 WITH FRAME.
  PARAMETERS:
    P_BUKRS TYPE BUKRS OBLIGATORY MEMORY ID BUK.  "Company Code
*  P_VKORG TYPE VKORG.
  SELECT-OPTIONS:
    S_GJAHR   FOR BKPF-GJAHR DEFAULT SY-DATUM+0(4) NO-EXTENSION,  "Fiscal year
    S_KUNNR   FOR BSEG-KUNNR,
    S_LIFNR   FOR BSEG-LIFNR,
*  S_XBLNR   FOR BKPF-XBLNR, "Reference number
    S_BLART   FOR T003-BLART, "Document type
    S_BUDAT   FOR BKPF-BUDAT, "Posting date
    S_BELNR   FOR BKPF-BELNR,
    S_VBELN   FOR VBRK-VBELN MATCHCODE OBJECT VMCF.
**SELECT-OPTIONS:
**  S_XBLNR   FOR BKPF-XBLNR, "Reference number

  PARAMETERS:
    P_SUBMIT TYPE CHECKBOX NO-DISPLAY,
    P_CAL    TYPE CHECKBOX NO-DISPLAY.
SELECTION-SCREEN END OF BLOCK B1.

SELECTION-SCREEN BEGIN OF BLOCK B2 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    R_FI TYPE CHECKBOX RADIOBUTTON GROUP R1  USER-COMMAND CMD,
*  R_CS TYPE CHECKBOX RADIOBUTTON GROUP R1,
    R_MM TYPE CHECKBOX RADIOBUTTON GROUP R1,
    R_SD TYPE CHECKBOX RADIOBUTTON GROUP R1 DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK B2.

SELECTION-SCREEN BEGIN OF BLOCK B3 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    P_NEW TYPE CHECKBOX RADIOBUTTON GROUP R2 DEFAULT 'X',
    P_UPD TYPE CHECKBOX RADIOBUTTON GROUP R2.
SELECTION-SCREEN END OF BLOCK B3.

SELECTION-SCREEN BEGIN OF BLOCK B4 WITH FRAME .
  PARAMETERS:
    P_KG TYPE CHECKBOX AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK B4.

DATA: GT_ACDOCA     TYPE TABLE OF ACDOCA,
      GS_ACDOCA     TYPE          ACDOCA,
      GT_HEADER     TYPE TABLE OF ZEIV_ST_GETDATA,
      GS_HEADER     TYPE          ZEIV_ST_GETDATA,
      GT_EIV_HD     TYPE TABLE OF ZTB_EB_HEADER,
      GS_EIV_HD     TYPE          ZTB_EB_HEADER,
      GT_DETAIL     TYPE TABLE OF ZEB_ST_DETAIL,
      GS_DETAIL     TYPE          ZEB_ST_DETAIL,
      GT_DETAIL_ALL TYPE TABLE OF ZEB_ST_DETAIL,
      GS_DETAIL_ALL TYPE          ZEB_ST_DETAIL,
      GT_RESULT     TYPE TABLE OF STRING.

DATA: GR_KUNNR      TYPE RANGE OF KUNNR WITH HEADER LINE.

FIELD-SYMBOLS: <FS_HEADER> TYPE ZEIV_ST_GETDATA,
               <FS_DETAIL> TYPE ZEB_ST_DETAIL.

DATA:
  GT_FIELDCAT_HEADER        TYPE LVC_T_FCAT,
  GT_FIELDCAT_DETAIL        TYPE LVC_T_FCAT,
  GT_FIELDCAT               TYPE LVC_T_FCAT,
  G_CUSTOM_CONTAINER        TYPE REF TO   CL_GUI_CUSTOM_CONTAINER,
  G_CUSTOM_CONTAINER_DETAIL TYPE REF TO   CL_GUI_CUSTOM_CONTAINER,
  G_CONTAINER               TYPE          SCRFNAME VALUE 'CC_HEADER',
  G_CONTAINER_DETAIL        TYPE          SCRFNAME VALUE 'CC_DETAIL',
  ALV_GRID                  TYPE REF TO   CL_GUI_ALV_GRID,
  ALV_GRID_DETAIL           TYPE REF TO   CL_GUI_ALV_GRID,
  GW_CHECK                  TYPE I VALUE 0,
  G_STATE                   TYPE LVC_S_STBL,
  GS_LAYOUT                 TYPE LVC_S_LAYO,
  GS_LAYOUT_DETAIL          TYPE LVC_S_LAYO,
  CUSTOM_CONTAINER          TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
  SPLITTER                  TYPE REF TO CL_GUI_SPLITTER_CONTAINER,
  GRAPHIC_PARENT1           TYPE REF TO CL_GUI_CONTAINER,
  GRAPHIC_PARENT2           TYPE REF TO CL_GUI_CONTAINER,
  DG_DYNDOC_ID              TYPE REF TO CL_DD_DOCUMENT,
  LS_STYLE                  TYPE LVC_S_STYL,
  LT_STYLE_DISABLE          TYPE LVC_T_STYL.

DATA: OK_CODE      TYPE OK_CODE.

DATA: IT_EXCLUDING TYPE SLIS_T_EXTAB,
      GS_STABLE    TYPE LVC_S_STBL VALUE 'XX'.
DATA  REF_GRID TYPE REF TO CL_GUI_ALV_GRID.
DATA  REF_GRID1 TYPE REF TO CL_GUI_ALV_GRID.
FIELD-SYMBOLS: <FS_FIELDCAT> TYPE LVC_S_FCAT.

*-----------------------------------------------------------------------
* Class Definition
*-----------------------------------------------------------------------
CLASS CL_EVT DEFINITION DEFERRED.
*-----------------------------------------------------------------------
* Internal Table definition
*-----------------------------------------------------------------------

DATA: GO_EVT TYPE REF TO CL_EVT.              "Event for header
*----------------------------------------------------------------------*
* Class CL_EVT Definition
*----------------------------------------------------------------------*
CLASS CL_EVT DEFINITION.

  PUBLIC SECTION.
    METHODS:
    HANDLE_DATA_CHANGED FOR EVENT DATA_CHANGED_FINISHED
      OF CL_GUI_ALV_GRID IMPORTING E_MODIFIED
                                   ET_GOOD_CELLS.
ENDCLASS.
*----------------------------------------------------------------------*
* Class CL_EVT Implementation
*----------------------------------------------------------------------*
CLASS CL_EVT IMPLEMENTATION.

  METHOD HANDLE_DATA_CHANGED.
*    PERFORM DATA_CHANGED_PROC USING E_MODIFIED
*                                    ET_GOOD_CELLS.
  ENDMETHOD.
ENDCLASS.


*-----------------------------------------------------------------------
* Class Definition
*-----------------------------------------------------------------------
CLASS CL_EVT_DETAIL DEFINITION DEFERRED.
*-----------------------------------------------------------------------
* Internal Table definition
*-----------------------------------------------------------------------

DATA: GO_EVT_DETAIL TYPE REF TO CL_EVT_DETAIL.              "Event for header
*----------------------------------------------------------------------*
* Class CL_EVT Definition
*----------------------------------------------------------------------*
CLASS CL_EVT_DETAIL DEFINITION.

  PUBLIC SECTION.
    METHODS:
    HANDLE_DATA_CHANGED FOR EVENT DATA_CHANGED_FINISHED
      OF CL_GUI_ALV_GRID IMPORTING E_MODIFIED
                                   ET_GOOD_CELLS.
ENDCLASS.
*----------------------------------------------------------------------*
* Class CL_EVT Implementation
*----------------------------------------------------------------------*
CLASS CL_EVT_DETAIL IMPLEMENTATION.

  METHOD HANDLE_DATA_CHANGED.
    PERFORM DATA_CHANGED_PROC_DETAIL USING E_MODIFIED
                                    ET_GOOD_CELLS.
  ENDMETHOD.
ENDCLASS.

*
*
