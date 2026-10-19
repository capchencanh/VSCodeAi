*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_BKBLHHDV_TOP
*&---------------------------------------------------------------------*


*---------------------------------------------------------------------*
* Tables Definition
*---------------------------------------------------------------------*
TABLES: VBRK, VBPA.

*---------------------------------------------------------------------*
* Types Definition
*---------------------------------------------------------------------*
TYPES: GTY_HEAD TYPE ZST_RSD08_HEAD,
       GTY_ITEM TYPE ZST_RSD08_ITEM,
       GTY_TAX  TYPE ZST_RSD08_TAX,
       GTT_ITEM TYPE ZTT_RSD08_ITEM,
       GTT_TAX  TYPE ZTT_RSD08_TAX.

* Dong hoa don doc bang 1 SELECT JOIN o GET_BILLING_DATA
TYPES: BEGIN OF GTY_VBRP,
         VBELN               TYPE VBRP-VBELN,
         POSNR               TYPE VBRP-POSNR,
         MATNR               TYPE VBRP-MATNR,
         FKIMG               TYPE VBRP-FKIMG,
         VRKME               TYPE VBRP-VRKME,
         NETWR               TYPE VBRP-NETWR,
         MEINS               TYPE MARA-MEINS,
         KNUMV               TYPE VBRK-KNUMV,
         BUKRS               TYPE VBRK-BUKRS,
         FKART               TYPE VBRK-FKART,
         VKORG               TYPE VBRK-VKORG,
         WAERK               TYPE VBRK-WAERK,
         KUNAG               TYPE VBRK-KUNAG,   " Sold-to party
         MAKTX               TYPE MAKT-MAKTX,
         KBETR               TYPE PRCD_ELEMENTS-KBETR,
         KPEIN               TYPE PRCD_ELEMENTS-KPEIN,
         KMEIN               TYPE PRCD_ELEMENTS-KMEIN,
         TAX_KBETR           TYPE PRCD_ELEMENTS-KBETR,   " thue suat MWST cua dong
         TAX_KWERT           TYPE PRCD_ELEMENTS-KWERT,   " tien thue MWST cua dong
         UMREZ_S             TYPE MARM-UMREZ,
         UMREN_S             TYPE MARM-UMREN,
         UMREZ_P             TYPE MARM-UMREZ,
         UMREN_P             TYPE MARM-UMREN,
         NHATHUOC            TYPE VBPA-KUNNR,   " partner SB
         NHATHUOC_ADRNR      TYPE VBPA-ADRNR,
         NHATHUOC_KNA1_ADRNR TYPE KNA1-ADRNR,
         PAYER               TYPE VBPA-KUNNR,   " partner RG
         PAYER_ADRNR         TYPE VBPA-ADRNR,
         PAYER_KNA1_ADRNR    TYPE KNA1-ADRNR,
         PAYER_STCD1         TYPE KNA1-STCD1,
       END OF GTY_VBRP,
       GTT_VBRP TYPE STANDARD TABLE OF GTY_VBRP WITH EMPTY KEY.

*---------------------------------------------------------------------*
* Global Data
*---------------------------------------------------------------------*
DATA: GS_HEAD  TYPE GTY_HEAD,
      GT_ITEM  TYPE GTT_ITEM,
      GT_TAX   TYPE GTT_TAX,
      GT_VBRP  TYPE GTT_VBRP,
      GR_PSTYV TYPE RANGE OF VBRP-PSTYV.

* Constants
CONSTANTS: GC_PARVW_RG TYPE VBPA-PARVW VALUE 'RG',   " Payer
           GC_PARVW_SB TYPE VBPA-PARVW VALUE 'SB',   " Nha thuoc
           GC_POSNR_HD TYPE VBPA-POSNR VALUE '000000',
           GC_KSCHL_PR TYPE KSCHL      VALUE 'ZRT1', " Dieu kien gia ban le
           GC_KSCHL_TX TYPE KSCHL      VALUE 'MWST', " Dieu kien thue GTGT
           GC_NATION_I TYPE ADRC-NATION VALUE 'I',
           GC_FORMNAME TYPE TDSFNAME   VALUE 'ZSF_SD_BKBLHHDV',
           GC_PRINTER  TYPE RSPOPNAME  VALUE 'LP01',  " may in mac dinh khi user chua co may in o SU3
           GC_KEY_RETAIL TYPE VBPA-KUNNR VALUE '*',  " khoa gom don vi mua hang = nguoi tieu dung
           GC_TXT_RETAIL TYPE STRING   VALUE `Bán cho người tiêu dùng`,
           GC_PSTYV    TYPE STRING     VALUE 'ZT1A ZT1P ZT2A ZT2P ZT3A ZT3P ZT4A ZT4P ZT5A ZT6A ZT6P ZT7A ZT7P ZT8A ZT8P ZTAA ZTAP'
                                              & ' ZD1A ZD1P ZD2A ZD2P ZR1A ZR5A ZR6A ZR7A ZR8A ZRAA ZXNA ZXXA'
                                              & ' ZKBA ZKEA ZKRA ZKAA ZV1A ZV2A ZN1A'
                                              & ' ZP1A ZP4A'.   " Item Category duoc in

*---------------------------------------------------------------------*
* Selection Screen
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK BL1 WITH FRAME TITLE TEXT-B01.
SELECT-OPTIONS: S_VBELN FOR VBRK-VBELN OBLIGATORY.
SELECT-OPTIONS: S_FKDAT FOR VBRK-FKDAT OBLIGATORY.
SELECT-OPTIONS: S_FKART FOR VBRK-FKART OBLIGATORY.
SELECT-OPTIONS: S_VKORG FOR VBRK-VKORG.
SELECT-OPTIONS: S_VTWEG FOR VBRK-VTWEG.
SELECT-OPTIONS: S_NHATH FOR VBPA-KUNNR NO-EXTENSION NO INTERVALS.
SELECT-OPTIONS: S_PAYER FOR VBPA-KUNNR NO-EXTENSION NO INTERVALS.
SELECTION-SCREEN END OF BLOCK BL1.

SELECTION-SCREEN BEGIN OF BLOCK BL2 WITH FRAME TITLE TEXT-B02.
PARAMETERS: P_PREV TYPE CHAR1 RADIOBUTTON GROUP G1 DEFAULT 'X', " Preview
            P_PRNT TYPE CHAR1 RADIOBUTTON GROUP G1,             " Direct Print
            P_PDF  TYPE CHAR1 RADIOBUTTON GROUP G1.             " PDF Export
SELECTION-SCREEN END OF BLOCK BL2.
