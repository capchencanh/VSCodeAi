*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_DSNVBH_TOP
*&---------------------------------------------------------------------*

TABLES: VBRK, VBRP, VBPA.

*&---------------------------------------------------------------------*
*& Cau truc ALV - 14 chi tieu theo FS muc 2.4
*& Dung DDIC that de dong bo voi context form in ZXLWB
*&---------------------------------------------------------------------*
TYPES: GTY_ALV TYPE ZST_SD_DSNVBH_LINE,
       GTT_ALV TYPE ZTT_SD_DSNVBH_LINE.

*&---------------------------------------------------------------------*
*& Cau truc trung gian doc tu Billing
*&---------------------------------------------------------------------*
TYPES: BEGIN OF GTY_BILL,
         VBELN    TYPE VBRK-VBELN,
         POSNR    TYPE VBRP-POSNR,
         FKART    TYPE VBRK-FKART,
         FKDAT    TYPE VBRK-FKDAT,
         VKORG    TYPE VBRK-VKORG,
         VTWEG    TYPE VBRK-VTWEG,
         KUNAG    TYPE VBRK-KUNAG,
         WAERK    TYPE VBRK-WAERK,
         VBTYP    TYPE VBRK-VBTYP,
         VKBUR    TYPE VBRP-VKBUR,
         VKBUR_TX TYPE TVKBT-BEZEI,
         MATNR    TYPE VBRP-MATNR,
         NETWR    TYPE VBRP-NETWR,
         KDGRP    TYPE KNVV-KDGRP,
       END OF GTY_BILL,
       GTT_BILL TYPE STANDARD TABLE OF GTY_BILL WITH EMPTY KEY.

*&---------------------------------------------------------------------*
*& Partner cua chung tu - 4 vai tro theo FS muc 2.1.1
*&---------------------------------------------------------------------*
TYPES: BEGIN OF GTY_PARTNER,
         VBELN TYPE VBPA-VBELN,
         PARVW TYPE VBPA-PARVW,
         PERNR TYPE VBPA-PERNR,
       END OF GTY_PARTNER,
       GTT_PARTNER TYPE STANDARD TABLE OF GTY_PARTNER WITH EMPTY KEY.

TYPES: BEGIN OF GTY_PFTEXT,
         PARVW TYPE TPART-PARVW,
         VTEXT TYPE TPART-VTEXT,
       END OF GTY_PFTEXT,
       GTT_PFTEXT TYPE STANDARD TABLE OF GTY_PFTEXT WITH EMPTY KEY.

TYPES: BEGIN OF GTY_ORG,
         VKORG TYPE VBRK-VKORG,
       END OF GTY_ORG,
       GTT_ORG TYPE STANDARD TABLE OF GTY_ORG WITH EMPTY KEY.

DATA: GT_ALV  TYPE GTT_ALV,
      GT_BILL TYPE GTT_BILL,
*     Context form in ZXLWB - DDIC that, khop voi ZXL_SD_DSNVBH
      GS_FORM TYPE ZST_SD_DSNVBH.

*&---------------------------------------------------------------------*
*& Partner Function: SE (Sales Employee/TDV), KM (ASM), ER (RSM),
*& VW (ho tro ban hang) - FS muc 2.1.1
*&---------------------------------------------------------------------*
CONSTANTS:
  GC_PARVW_SE  TYPE VBPA-PARVW VALUE 'SE',
  GC_PARVW_KM  TYPE VBPA-PARVW VALUE 'KM',
  GC_PARVW_ER  TYPE VBPA-PARVW VALUE 'ER',
  GC_PARVW_VW  TYPE VBPA-PARVW VALUE 'VW',
  GC_POSNR_HD  TYPE VBPA-POSNR VALUE '000000',
  GC_WAERK_VND TYPE VBRK-WAERK VALUE 'VND',
  GC_VBTYP_RET TYPE VBRK-VBTYP VALUE 'O',
  GC_FORMNAME  TYPE C LENGTH 30 VALUE 'ZXL_SD_DSNVBH'.

SELECTION-SCREEN BEGIN OF BLOCK BL1 WITH FRAME TITLE TEXT-B01.
SELECT-OPTIONS: S_VKORG FOR VBRK-VKORG OBLIGATORY,
                S_VTWEG FOR VBRK-VTWEG,
                S_FKDAT FOR VBRK-FKDAT OBLIGATORY,
                S_FKART FOR VBRK-FKART,
                S_VBELN FOR VBRK-VBELN,
                S_KUNAG FOR VBRK-KUNAG,
                S_MATNR FOR VBRP-MATNR.
SELECTION-SCREEN END OF BLOCK BL1.

SELECTION-SCREEN BEGIN OF BLOCK BL2 WITH FRAME TITLE TEXT-B02.
SELECT-OPTIONS: S_PERNR FOR VBPA-PERNR NO INTERVALS,
                S_PARVW FOR VBPA-PARVW NO INTERVALS.
SELECTION-SCREEN END OF BLOCK BL2.

* Hai lua chon ket xuat - FS muc 2.3
SELECTION-SCREEN BEGIN OF BLOCK BL3 WITH FRAME TITLE TEXT-B03.
PARAMETERS: P_ALV   RADIOBUTTON GROUP R1 DEFAULT 'X',
            P_PRINT RADIOBUTTON GROUP R1.
SELECTION-SCREEN END OF BLOCK BL3.

*&---------------------------------------------------------------------*
*& TODO - Cho BA xac nhan (FS V1.0 chua du thong tin):
*& 1. Nguon du lieu HRM cho chi tieu (4)(5)(6)(9)(10):
*&    Ten nhan vien, Ten/Ma phong ban HRM, Ten/Ma vi tri cong viec.
*&    FS muc 2.4 chi ghi "theo du lieu HRM", khong cho ten bang/field.
*&    -> Bo sung SELECT-OPTIONS S_ORGEH (Ma phong ban) va S_PLANS
*&       (Ma vi tri cong viec) vao BLOCK BL2 sau khi co nguon du lieu.
*& 2. Tham so "Ma san pham chu luc": FS muc 2.2.1 de trong toan bo
*&    mo ta/loai/dieu kien loc. Cho BA bo sung roi them vao BLOCK BL1.
*& 3. Comment BA trong FS: "Xoa 2 tham so 4,5" - chua ro xoa tham so
*&    nao do cot STT trong bang tham so FS de trong.
*&---------------------------------------------------------------------*
