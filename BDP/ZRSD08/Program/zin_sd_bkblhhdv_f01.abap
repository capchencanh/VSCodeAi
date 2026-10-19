*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_BKBLHHDV_F01
*&---------------------------------------------------------------------*


*&---------------------------------------------------------------------*
*& Form SET_DEFAULT_DATE
*&---------------------------------------------------------------------*
FORM SET_DEFAULT_DATE.

  CLEAR S_FKDAT.
  S_FKDAT-SIGN   = 'I'.
  S_FKDAT-OPTION = 'BT'.
  S_FKDAT-LOW    = SY-DATUM.
  S_FKDAT-LOW+6(2) = '01'.        " Ngay dau thang hien tai
  S_FKDAT-HIGH   = SY-DATUM.      " Ngay hien tai
  APPEND S_FKDAT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_AUTHORITY
*& Phan quyen theo To chuc ban hang (V_VBRK_VKO) va Kenh phan phoi (M_IS_VTWEG)
*&---------------------------------------------------------------------*
FORM CHECK_AUTHORITY.

  IF S_VBELN[] IS INITIAL.
    RETURN.
  ENDIF.

  SELECT DISTINCT VKORG, VTWEG
    FROM VBRK
   WHERE VBELN IN @S_VBELN
     AND FKDAT IN @S_FKDAT
     AND FKART IN @S_FKART
    INTO TABLE @DATA(LT_ORG).

  LOOP AT LT_ORG ASSIGNING FIELD-SYMBOL(<LFS_ORG>).
    AUTHORITY-CHECK OBJECT 'V_VBRK_VKO'
             ID 'VKORG' FIELD <LFS_ORG>-VKORG
             ID 'ACTVT' FIELD '03'.
    IF SY-SUBRC <> 0.
      MESSAGE E001(ZMC_SD) WITH 'Khong co quyen voi to chuc ban hang'
                             <LFS_ORG>-VKORG.
    ENDIF.

*   M_IS_VTWEG khong co truong ACTVT
    AUTHORITY-CHECK OBJECT 'M_IS_VTWEG'
             ID 'MCINF' DUMMY
             ID 'VTWEG' FIELD <LFS_ORG>-VTWEG.
    IF SY-SUBRC <> 0.
      MESSAGE E001(ZMC_SD) WITH 'Khong co quyen voi kenh phan phoi'
                             <LFS_ORG>-VTWEG.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
FORM GET_DATA.

  PERFORM GET_BILLING_DATA.
  CHECK GT_ITEM IS NOT INITIAL.

  PERFORM GET_HEADER_DATA.
  PERFORM GET_TAX_SUMMARY.
  PERFORM CALC_TOTAL.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_ITEM_CATEGORY
*& Item Category duoc phep in len bang ke
*&---------------------------------------------------------------------*
FORM SET_ITEM_CATEGORY.

  SPLIT GC_PSTYV AT SPACE INTO TABLE DATA(LT_PSTYV).
  GR_PSTYV = VALUE #( FOR LV_PSTYV IN LT_PSTYV
                      ( SIGN = 'I' OPTION = 'EQ' LOW = LV_PSTYV ) ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_BILLING_DATA
*& 1 cau SELECT JOIN: dong hoa don + ten hang + don gia ZRT1 + thue MWST
*& + quy doi DVT + partner
*&---------------------------------------------------------------------*
FORM GET_BILLING_DATA.

  DATA: LV_STT   TYPE N LENGTH 4,
        LV_PRICE TYPE DECFLOAT34.

  PERFORM SET_ITEM_CATEGORY.

  SELECT A~VBELN, A~POSNR, A~MATNR, A~FKIMG, A~VRKME, A~NETWR,
         M~MEINS,
         C~KNUMV, C~BUKRS, C~FKART, C~VKORG, C~WAERK, C~KUNAG,
         T~MAKTX,
         P~KBETR, P~KPEIN, P~KMEIN,
         TX~KBETR AS TAX_KBETR, TX~KWERT AS TAX_KWERT,
         Q~UMREZ AS UMREZ_S, Q~UMREN AS UMREN_S,
         R~UMREZ AS UMREZ_P, R~UMREN AS UMREN_P,
         SB~KUNNR AS NHATHUOC, SB~ADRNR AS NHATHUOC_ADRNR,
         KS~ADRNR AS NHATHUOC_KNA1_ADRNR,
         RG~KUNNR AS PAYER, RG~ADRNR AS PAYER_ADRNR,
         K~ADRNR  AS PAYER_KNA1_ADRNR, K~STCD1 AS PAYER_STCD1
    FROM VBRP AS A
    INNER JOIN VBRK AS C ON C~VBELN = A~VBELN
    INNER JOIN MARA AS M ON M~MATNR = A~MATNR
    LEFT OUTER JOIN MAKT AS T
           ON T~MATNR = A~MATNR
          AND T~SPRAS = @SY-LANGU
    LEFT OUTER JOIN PRCD_ELEMENTS AS P
           ON P~KNUMV = C~KNUMV
          AND P~KPOSN = A~POSNR
          AND P~KSCHL = @GC_KSCHL_PR
    LEFT OUTER JOIN PRCD_ELEMENTS AS TX
           ON TX~KNUMV = C~KNUMV
          AND TX~KPOSN = A~POSNR
          AND TX~KSCHL = @GC_KSCHL_TX
    LEFT OUTER JOIN MARM AS Q
           ON Q~MATNR = A~MATNR
          AND Q~MEINH = A~VRKME
    LEFT OUTER JOIN MARM AS R
           ON R~MATNR = A~MATNR
          AND R~MEINH = P~KMEIN
    LEFT OUTER JOIN VBPA AS SB
           ON SB~VBELN = A~VBELN
          AND SB~POSNR = @GC_POSNR_HD
          AND SB~PARVW = @GC_PARVW_SB
    LEFT OUTER JOIN KNA1 AS KS
           ON KS~KUNNR = SB~KUNNR
    LEFT OUTER JOIN VBPA AS RG
           ON RG~VBELN = A~VBELN
          AND RG~POSNR = @GC_POSNR_HD
          AND RG~PARVW = @GC_PARVW_RG
    LEFT OUTER JOIN KNA1 AS K
           ON K~KUNNR = RG~KUNNR
   WHERE A~VBELN IN @S_VBELN
     AND A~PSTYV IN @GR_PSTYV
     AND C~FKDAT IN @S_FKDAT
     AND C~FKART IN @S_FKART
     AND C~VKORG IN @S_VKORG
     AND C~VTWEG IN @S_VTWEG
     AND SB~KUNNR IN @S_NHATH
     AND RG~KUNNR IN @S_PAYER
   ORDER BY A~VBELN, A~POSNR
    INTO CORRESPONDING FIELDS OF TABLE @GT_VBRP.

  IF SY-SUBRC <> 0.
    RETURN.
  ENDIF.

  LOOP AT GT_VBRP ASSIGNING FIELD-SYMBOL(<LFS_VBRP>).

    APPEND INITIAL LINE TO GT_ITEM ASSIGNING FIELD-SYMBOL(<LFS_ITEM>).
    <LFS_ITEM>-VBELN = <LFS_VBRP>-VBELN.
    <LFS_ITEM>-POSNR = <LFS_VBRP>-POSNR.
    <LFS_ITEM>-MATNR = <LFS_VBRP>-MATNR.
    <LFS_ITEM>-MAKTX = <LFS_VBRP>-MAKTX.
    <LFS_ITEM>-MEINS = <LFS_VBRP>-MEINS.
    <LFS_ITEM>-NETWR = <LFS_VBRP>-NETWR.
    <LFS_ITEM>-WAERK = <LFS_VBRP>-WAERK.

    LV_STT = LV_STT + 1.
    <LFS_ITEM>-STT = LV_STT.

*   Thue suat GTGT cua dong: KBETR luu thue suat nhan 10 (5% = 50)
    <LFS_ITEM>-TAXRATE = <LFS_VBRP>-TAX_KBETR / 10.

*   So luong theo DVT co so = q * y / x (x = UMREN, y = UMREZ)
    IF <LFS_VBRP>-VRKME = <LFS_VBRP>-MEINS OR <LFS_VBRP>-UMREN_S = 0.
      <LFS_ITEM>-MENGE = <LFS_VBRP>-FKIMG.
    ELSE.
      <LFS_ITEM>-MENGE = <LFS_VBRP>-FKIMG * <LFS_VBRP>-UMREZ_S / <LFS_VBRP>-UMREN_S.
    ENDIF.

*   Don gia theo DVT co so = ( r / n ) / ( y / x )
    IF <LFS_VBRP>-KPEIN <> 0.
      LV_PRICE = <LFS_VBRP>-KBETR / <LFS_VBRP>-KPEIN.
      IF <LFS_VBRP>-KMEIN <> <LFS_VBRP>-MEINS
     AND <LFS_VBRP>-UMREZ_P <> 0 AND <LFS_VBRP>-UMREN_P <> 0.
        LV_PRICE = LV_PRICE / ( <LFS_VBRP>-UMREZ_P / <LFS_VBRP>-UMREN_P ).
      ENDIF.
      <LFS_ITEM>-KBETR = LV_PRICE.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_HEADER_DATA
*& Phan dau bieu mau: cong ty, nha thuoc, loai hoa don, don vi mua hang
*&---------------------------------------------------------------------*
FORM GET_HEADER_DATA.

  DATA: LT_NHATHUOC TYPE SORTED TABLE OF VBPA-KUNNR WITH UNIQUE KEY TABLE_LINE,
        LT_BUYER    TYPE SORTED TABLE OF VBPA-KUNNR WITH UNIQUE KEY TABLE_LINE,
        LV_ADRNR    TYPE ADRC-ADDRNUMBER.

  READ TABLE GT_VBRP INTO DATA(LS_FIRST) INDEX 1.
  IF SY-SUBRC <> 0.
    RETURN.
  ENDIF.

  GS_HEAD-FKART   = LS_FIRST-FKART.
  GS_HEAD-WAERK   = LS_FIRST-WAERK.
  GS_HEAD-DATE_FR = S_FKDAT-LOW.
  GS_HEAD-DATE_TO = S_FKDAT-HIGH.
  GS_HEAD-PRTDATE = SY-DATUM.

* Gom nha thuoc / don vi mua hang: khach mua tai quay (Sold-to = nha thuoc) gom chung 1 nhom
  LOOP AT GT_VBRP ASSIGNING FIELD-SYMBOL(<LFS_ROW>).
    IF <LFS_ROW>-NHATHUOC IS NOT INITIAL.
      INSERT <LFS_ROW>-NHATHUOC INTO TABLE LT_NHATHUOC.
    ENDIF.
    INSERT COND VBPA-KUNNR( WHEN <LFS_ROW>-KUNAG = <LFS_ROW>-NHATHUOC
                            THEN GC_KEY_RETAIL
                            ELSE <LFS_ROW>-PAYER ) INTO TABLE LT_BUYER.
  ENDLOOP.

* Rang buoc: cung mot nha thuoc / don vi mua hang
  IF LINES( LT_NHATHUOC ) > 1.
    MESSAGE E001(ZMC_SD) WITH
      'Cac hoa don duoc chon khong cung mot nha thuoc.'
      'Mot bang ke chi in cho mot nha thuoc.'.
  ENDIF.
  IF LINES( LT_BUYER ) > 1.
    MESSAGE E001(ZMC_SD) WITH
      'Cac hoa don duoc chon khong cung mot don vi mua hang.'
      'Mot bang ke chi in cho mot don vi mua hang.'.
  ENDIF.

* Nha thuoc: ma + ten
  READ TABLE LT_NHATHUOC INTO DATA(LV_NHATHUOC) INDEX 1.
  IF SY-SUBRC = 0.
    GS_HEAD-NHATHUOC = LV_NHATHUOC.
    READ TABLE GT_VBRP INTO DATA(LS_NT) WITH KEY NHATHUOC = LV_NHATHUOC.
    LV_ADRNR = COND #( WHEN LS_NT-NHATHUOC_KNA1_ADRNR IS NOT INITIAL
                       THEN LS_NT-NHATHUOC_KNA1_ADRNR
                       ELSE LS_NT-NHATHUOC_ADRNR ).
    PERFORM GET_ADRC_NAME USING LV_ADRNR
                       CHANGING GS_HEAD-NHATHUOCNM.
  ENDIF.

* Ma cong ty theo to chuc ban hang cua hoa don (VBRK-VKORG -> TVKO)
  SELECT SINGLE A~BUKRS, B~ADRNR, B~STCEG
    FROM TVKO AS A
    INNER JOIN T001 AS B ON B~BUKRS = A~BUKRS
   WHERE A~VKORG = @LS_FIRST-VKORG
    INTO @DATA(LS_COMP).
  IF SY-SUBRC <> 0.
    SELECT SINGLE BUKRS, ADRNR, STCEG
      FROM T001
     WHERE BUKRS = @LS_FIRST-BUKRS
      INTO @LS_COMP.
  ENDIF.
  GS_HEAD-BUKRS  = LS_COMP-BUKRS.
  GS_HEAD-CTAXNO = LS_COMP-STCEG.
  CONCATENATE 'ZLOGO_' GS_HEAD-BUKRS INTO GS_HEAD-LOGO.
  PERFORM GET_ADRC_NAME       USING LS_COMP-ADRNR
                             CHANGING GS_HEAD-CNAME.
  PERFORM GET_COMPANY_ADDRESS USING LS_COMP-ADRNR
                             CHANGING GS_HEAD-CADDR.

* Dien giai loai hoa don
  SELECT SINGLE VTEXT
    FROM TVFKT
   WHERE SPRAS = @SY-LANGU
     AND FKART = @GS_HEAD-FKART
    INTO @GS_HEAD-FKARTX.

* Don vi mua hang: Sold-to = nha thuoc thi ban cho nguoi tieu dung (khong in MST, dia chi)
  IF LS_FIRST-KUNAG = LS_FIRST-NHATHUOC.
    GS_HEAD-PAYERNM = GC_TXT_RETAIL.
  ELSE.
    GS_HEAD-PAYERTAX = LS_FIRST-PAYER_STCD1.
    PERFORM GET_PAYER_INFO USING LS_FIRST-PAYER_KNA1_ADRNR
                                 LS_FIRST-PAYER_ADRNR.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_ADRC_NAME
*&---------------------------------------------------------------------*
FORM GET_ADRC_NAME USING IV_ADRNR TYPE ADRC-ADDRNUMBER
                CHANGING CV_NAME  TYPE CLIKE.

  DATA: LV_NATION TYPE ADRC-NATION.

  CLEAR CV_NAME.
  CHECK IV_ADRNR IS NOT INITIAL.

* Ban in tieng Anh doc dong ADRC co NATION = 'I'; con lai doc dong chuan
  IF SY-LANGU = 'E'.
    LV_NATION = GC_NATION_I.
  ELSE.
    CLEAR LV_NATION.
  ENDIF.

  SELECT SINGLE NAME1, NAME2, NAME3, NAME4
    FROM ADRC
    INTO @DATA(LS_ADRC)
   WHERE ADDRNUMBER = @IV_ADRNR
     AND DATE_FROM <= @SY-DATUM
     AND DATE_TO   >= @SY-DATUM
     AND NATION     = @LV_NATION.
  IF SY-SUBRC <> 0.
    RETURN.
  ENDIF.

  IF LS_ADRC-NAME2 IS INITIAL AND
     LS_ADRC-NAME3 IS INITIAL AND
     LS_ADRC-NAME4 IS INITIAL.
    CV_NAME = LS_ADRC-NAME1.
  ELSE.
    CONCATENATE LS_ADRC-NAME2 LS_ADRC-NAME3 LS_ADRC-NAME4
           INTO CV_NAME SEPARATED BY SPACE.
    CONDENSE CV_NAME.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_COMPANY_ADDRESS
*& Dia chi cong ty: so nha + duong - phuong/xa - quan/huyen/tinh
*&---------------------------------------------------------------------*
FORM GET_COMPANY_ADDRESS USING IV_ADRNR TYPE ADRC-ADDRNUMBER
                      CHANGING CV_ADDR  TYPE CLIKE.

  DATA: LT_PART   TYPE STANDARD TABLE OF STRING WITH EMPTY KEY,
        LV_NATION TYPE ADRC-NATION.

  CLEAR CV_ADDR.
  CHECK IV_ADRNR IS NOT INITIAL.

  IF SY-LANGU = 'E'.
    LV_NATION = GC_NATION_I.
  ENDIF.

  SELECT SINGLE HOUSE_NUM1, STREET, CITY2, CITY1
    FROM ADRC
    INTO @DATA(LS_ADRC)
   WHERE ADDRNUMBER = @IV_ADRNR
     AND DATE_FROM <= @SY-DATUM
     AND DATE_TO   >= @SY-DATUM
     AND NATION     = @LV_NATION.
  IF SY-SUBRC <> 0.
    RETURN.
  ENDIF.

  LT_PART = VALUE #( ( CONDENSE( |{ LS_ADRC-HOUSE_NUM1 } { LS_ADRC-STREET }| ) )
                     ( CONV #( LS_ADRC-CITY2 ) )
                     ( CONV #( LS_ADRC-CITY1 ) ) ).
  DELETE LT_PART WHERE TABLE_LINE IS INITIAL.

  CONCATENATE LINES OF LT_PART INTO CV_ADDR SEPARATED BY ` - `.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_PAYER_INFO
*& Uu tien 1: dia chi khach hang co du lieu chu (KNA1); uu tien 2: khach vang lai (VBPA-ADRNR)
*&---------------------------------------------------------------------*
FORM GET_PAYER_INFO USING IV_ADRNR_KNA1 TYPE ADRC-ADDRNUMBER
                          IV_ADRNR_VBPA TYPE ADRC-ADDRNUMBER.

  DATA LV_ADRNR TYPE ADRC-ADDRNUMBER.

  LV_ADRNR = COND #( WHEN IV_ADRNR_KNA1 IS NOT INITIAL
                     THEN IV_ADRNR_KNA1
                     ELSE IV_ADRNR_VBPA ).
  CHECK LV_ADRNR IS NOT INITIAL.

  PERFORM GET_ADRC_NAME    USING LV_ADRNR CHANGING GS_HEAD-PAYERNM.
  PERFORM GET_ADRC_ADDRESS USING LV_ADRNR CHANGING GS_HEAD-PAYERAD.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_ADRC_ADDRESS
*& Ghep dia chi: STREET, STR_SUPPL1/2, CITY2, CITY1, ten tinh, ten quoc gia
*&---------------------------------------------------------------------*
FORM GET_ADRC_ADDRESS USING IV_ADRNR TYPE ADRC-ADDRNUMBER
                   CHANGING CV_ADDR  TYPE CLIKE.

  DATA: LT_PART   TYPE STANDARD TABLE OF CHAR60,
        LV_NATION TYPE ADRC-NATION.

  CLEAR CV_ADDR.

  IF SY-LANGU = 'E'.
    LV_NATION = GC_NATION_I.
  ENDIF.

  SELECT SINGLE A~STREET, A~STR_SUPPL1, A~STR_SUPPL2, A~CITY2, A~CITY1,
                U~BEZEI AS REGION_TXT,
                T~LANDX AS COUNTRY_TXT
    FROM ADRC AS A
    LEFT OUTER JOIN T005U AS U
           ON U~SPRAS = @SY-LANGU
          AND U~LAND1 = A~COUNTRY
          AND U~BLAND = A~REGION
    LEFT OUTER JOIN T005T AS T
           ON T~SPRAS = @SY-LANGU
          AND T~LAND1 = A~COUNTRY
   WHERE A~ADDRNUMBER = @IV_ADRNR
     AND A~DATE_FROM <= @SY-DATUM
     AND A~DATE_TO   >= @SY-DATUM
     AND A~NATION     = @LV_NATION
    INTO @DATA(LS_ADRC).
  IF SY-SUBRC <> 0.
    RETURN.
  ENDIF.

  LT_PART = VALUE #( ( LS_ADRC-STREET )
                     ( CONV #( LS_ADRC-STR_SUPPL1 ) )
                     ( CONV #( LS_ADRC-STR_SUPPL2 ) )
                     ( CONV #( LS_ADRC-CITY2 ) )
                     ( CONV #( LS_ADRC-CITY1 ) )
                     ( CONV #( LS_ADRC-REGION_TXT ) )
                     ( CONV #( LS_ADRC-COUNTRY_TXT ) ) ).
  DELETE LT_PART WHERE TABLE_LINE IS INITIAL.

  CONCATENATE LINES OF LT_PART INTO CV_ADDR SEPARATED BY `, `.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_TAX_SUMMARY
*& Tong hop tien thue GTGT theo tung muc thue suat
*&---------------------------------------------------------------------*
FORM GET_TAX_SUMMARY.

  LOOP AT GT_VBRP ASSIGNING FIELD-SYMBOL(<LFS_VBRP>).

    DATA(LV_RATE) = CONV ZDE_TAXRATE( <LFS_VBRP>-TAX_KBETR / 10 ).

    READ TABLE GT_TAX ASSIGNING FIELD-SYMBOL(<LFS_TAX>)
         WITH KEY TAXRATE = LV_RATE.
    IF SY-SUBRC <> 0.
      APPEND VALUE #( TAXRATE = LV_RATE
                      WAERK   = <LFS_VBRP>-WAERK ) TO GT_TAX ASSIGNING <LFS_TAX>.
    ENDIF.

    <LFS_TAX>-TAXAMT = <LFS_TAX>-TAXAMT + <LFS_VBRP>-TAX_KWERT.

  ENDLOOP.

  SORT GT_TAX BY TAXRATE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CALC_TOTAL
*& Tong cong, tong tien thue, tong thanh toan, so tien bang chu
*&---------------------------------------------------------------------*
FORM CALC_TOTAL.

* Tong cong = cong Thanh tien cua cac dong in tren bang ke
  GS_HEAD-TOTAL = REDUCE VBRP-NETWR( INIT LV_T TYPE VBRP-NETWR
                                     FOR LS_L IN GT_ITEM
                                     NEXT LV_T = LV_T + LS_L-NETWR ).

* Tong tien thue = cong tien thue cac muc thue suat
  GS_HEAD-TAXAMT = REDUCE VBRP-NETWR( INIT LV_X TYPE VBRP-NETWR
                                      FOR LS_X IN GT_TAX
                                      NEXT LV_X = LV_X + LS_X-TAXAMT ).

* Tong thanh toan = tong cong + tong tien thue
  GS_HEAD-AMTPAY = GS_HEAD-TOTAL + GS_HEAD-TAXAMT.

  GS_HEAD-AMTWORD = ZCORE_CL_AMOUNT_IN_WORDS=>READ_AMOUNT(
                      I_AMOUNT      = CONV #( GS_HEAD-AMTPAY )
                      I_WAERS       = GS_HEAD-WAERK
                      I_IS_INTERNAL = ABAP_TRUE ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PRINT_FORM
*&---------------------------------------------------------------------*
*& Goi Smartform theo che do dau ra da chon o tham so
*&---------------------------------------------------------------------*
FORM PRINT_FORM.

  DATA: LV_FMNAME  TYPE RS38L_FNAM,
        LS_CTLOP   TYPE SSFCTRLOP,
        LS_OUTOPT  TYPE SSFCOMPOP,
        LS_JOBOUT  TYPE SSFCRESCL.

* Lay ten function module cua Smartform
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME           = GC_FORMNAME
    IMPORTING
      FM_NAME            = LV_FMNAME
    EXCEPTIONS
      NO_FORM            = 1
      NO_FUNCTION_MODULE = 2
      OTHERS             = 3.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE 'E' NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    RETURN.
  ENDIF.

* Thiet bi in lay tu user (SU3); khong co thi dung may in mac dinh
  SELECT SINGLE SPLD FROM USR01 WHERE BNAME = @SY-UNAME INTO @LS_OUTOPT-TDDEST.
  IF LS_OUTOPT-TDDEST IS INITIAL.
    LS_OUTOPT-TDDEST = GC_PRINTER.
  ENDIF.
  LS_OUTOPT-TDNEWID   = 'X'.
  LS_OUTOPT-TDIMMED   = 'X'.
  LS_CTLOP-LANGU      = SY-LANGU.
  LS_CTLOP-NO_DIALOG  = 'X'.

  CASE 'X'.
    WHEN P_PREV.          " Preview - xem truoc
      LS_CTLOP-PREVIEW    = 'X'.
      LS_OUTOPT-TDIMMED   = SPACE.
    WHEN P_PRNT.          " Direct Print - in ra may in
      LS_CTLOP-PREVIEW    = SPACE.
      LS_CTLOP-NO_DIALOG  = SPACE.
    WHEN P_PDF.           " PDF Export - xuat file PDF
      LS_CTLOP-PREVIEW    = SPACE.
      LS_CTLOP-GETOTF     = 'X'.
      LS_OUTOPT-TDIMMED   = SPACE.
  ENDCASE.

  CALL FUNCTION LV_FMNAME
    EXPORTING
      CONTROL_PARAMETERS = LS_CTLOP
      OUTPUT_OPTIONS     = LS_OUTOPT
      USER_SETTINGS      = SPACE
      IS_HEAD            = GS_HEAD
    IMPORTING
      JOB_OUTPUT_INFO    = LS_JOBOUT
    TABLES
      IT_ITEM            = GT_ITEM
      IT_TAX             = GT_TAX
    EXCEPTIONS
      FORMATTING_ERROR   = 1
      INTERNAL_ERROR     = 2
      SEND_ERROR         = 3
      USER_CANCELED      = 4
      OTHERS             = 5.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE 'E' NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    RETURN.
  ENDIF.

* PDF Export - chuyen OTF sang PDF va luu file
  IF P_PDF = 'X'.
    PERFORM EXPORT_PDF USING LS_JOBOUT.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form EXPORT_PDF
*&---------------------------------------------------------------------*
FORM EXPORT_PDF USING IS_JOBOUT TYPE SSFCRESCL.

  DATA: LV_BYTES TYPE I,
        LT_PDF   TYPE STANDARD TABLE OF TLINE,
        LT_OTF   TYPE STANDARD TABLE OF ITCOO,
        LV_PATH  TYPE STRING,
        LV_FULL  TYPE STRING,
        LV_NAME  TYPE STRING,
        LV_ACT   TYPE I.

  LT_OTF = IS_JOBOUT-OTFDATA.

  CALL FUNCTION 'CONVERT_OTF'
    EXPORTING
      FORMAT                = 'PDF'
    IMPORTING
      BIN_FILESIZE          = LV_BYTES
    TABLES
      OTF                   = LT_OTF
      LINES                 = LT_PDF
    EXCEPTIONS
      ERR_MAX_LINEWIDTH     = 1
      ERR_FORMAT            = 2
      ERR_CONV_NOT_POSSIBLE = 3
      OTHERS                = 4.
  IF SY-SUBRC <> 0.
    MESSAGE 'Loi chuyen doi OTF sang PDF' TYPE 'E'.
    RETURN.
  ENDIF.

  CONCATENATE 'ZRSD08_' SY-DATUM '_' SY-UZEIT '.pdf' INTO LV_NAME.

  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG
    EXPORTING
      DEFAULT_FILE_NAME    = LV_NAME
      DEFAULT_EXTENSION    = 'pdf'
      FILE_FILTER          = 'PDF Files (*.pdf)|*.pdf'
    CHANGING
      FILENAME             = LV_NAME
      PATH                 = LV_PATH
      FULLPATH             = LV_FULL
      USER_ACTION          = LV_ACT
    EXCEPTIONS
      OTHERS               = 1.
  IF SY-SUBRC <> 0 OR
     LV_ACT <> CL_GUI_FRONTEND_SERVICES=>ACTION_OK.
    RETURN.
  ENDIF.

  CALL METHOD CL_GUI_FRONTEND_SERVICES=>GUI_DOWNLOAD
    EXPORTING
      BIN_FILESIZE = LV_BYTES
      FILENAME     = LV_FULL
      FILETYPE     = 'BIN'
    CHANGING
      DATA_TAB     = LT_PDF
    EXCEPTIONS
      OTHERS       = 1.
  IF SY-SUBRC <> 0.
    MESSAGE 'Loi luu file PDF' TYPE 'E'.
  ELSE.
    MESSAGE 'Da xuat file PDF thanh cong' TYPE 'S'.
  ENDIF.

ENDFORM.
