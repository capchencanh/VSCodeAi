*&---------------------------------------------------------------------*
*&  Include           ZIN_SD_DSNVBH_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form SET_DEFAULT_DATE
*& Ngay hoa don mac dinh = thang hien tai (FS muc 2.2.1 tham so 3)
*&---------------------------------------------------------------------*
FORM SET_DEFAULT_DATE.

  CLEAR S_FKDAT.
  S_FKDAT-SIGN     = 'I'.
  S_FKDAT-OPTION   = 'BT'.
  S_FKDAT-LOW      = SY-DATUM.
  S_FKDAT-LOW+6(2) = '01'.
  S_FKDAT-HIGH     = SY-DATUM.
  APPEND S_FKDAT.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_AUTHORITY
*& Phan quyen theo to chuc ban hang - FS muc 2.5
*&---------------------------------------------------------------------*
FORM CHECK_AUTHORITY.

  DATA LT_ORG TYPE GTT_ORG.

  SELECT DISTINCT VKORG
    FROM VBRK
   WHERE FKDAT IN @S_FKDAT
     AND VKORG IN @S_VKORG
    INTO TABLE @LT_ORG.

  LOOP AT LT_ORG ASSIGNING FIELD-SYMBOL(<LFS_ORG>).

    AUTHORITY-CHECK OBJECT 'V_VBRK_VKO'
             ID 'VKORG' FIELD <LFS_ORG>-VKORG
             ID 'ACTVT' FIELD '03'.
    IF SY-SUBRC <> 0.
      MESSAGE E001(ZMC_SD) WITH 'Khong co quyen voi to chuc ban hang'
                                <LFS_ORG>-VKORG. "#EC NOTEXT
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
FORM GET_DATA.

  PERFORM GET_BILLING.

  CHECK GT_BILL IS NOT INITIAL.

  PERFORM BUILD_ALV.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_BILLING
*& Doc chung tu hoa don - FS muc 2.2 "Du lieu duoc lay tu Billing
*& Document tren man hinh Tcode VF03"
*&---------------------------------------------------------------------*
FORM GET_BILLING.

  SELECT K~VBELN, P~POSNR, K~FKART, K~FKDAT,
         K~VKORG, K~VTWEG, K~KUNAG, K~WAERK, K~VBTYP,
         P~VKBUR, B~BEZEI AS VKBUR_TX,
         P~MATNR, P~NETWR,
         V~KDGRP
    FROM VBRP AS P
    INNER JOIN VBRK AS K ON K~VBELN = P~VBELN
    LEFT OUTER JOIN TVKBT AS B ON B~VKBUR = P~VKBUR
                              AND B~SPRAS = @SY-LANGU
    LEFT OUTER JOIN KNVV AS V ON V~KUNNR = K~KUNAG
                             AND V~VKORG = K~VKORG
                             AND V~VTWEG = K~VTWEG
   WHERE K~FKDAT IN @S_FKDAT
     AND K~VKORG IN @S_VKORG
     AND K~VTWEG IN @S_VTWEG
     AND K~FKART IN @S_FKART
     AND K~VBELN IN @S_VBELN
     AND K~KUNAG IN @S_KUNAG
     AND K~WAERK  = @GC_WAERK_VND
     AND K~FKSTO <> @ABAP_TRUE
     AND P~MATNR IN @S_MATNR
    INTO CORRESPONDING FIELDS OF TABLE @GT_BILL. "#EC CI_BUFFJOIN

ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_ALV
*& Moi Partner Function tren chung tu sinh ra mot dong bao cao
*& (FS muc 2.1.1: "the hien dong thoi 4 Partner Function")
*&---------------------------------------------------------------------*
FORM BUILD_ALV.

  DATA: LT_PARTNER TYPE GTT_PARTNER,
        LT_PFTEXT  TYPE GTT_PFTEXT,
        LS_PFTEXT  TYPE GTY_PFTEXT,
        LV_SIGN    TYPE I.

  SELECT A~VBELN, A~PARVW, A~PERNR
    FROM VBPA AS A
    INNER JOIN @GT_BILL AS B ON B~VBELN = A~VBELN
   WHERE A~POSNR = @GC_POSNR_HD
     AND A~PARVW IN ( @GC_PARVW_SE, @GC_PARVW_KM,
                      @GC_PARVW_ER, @GC_PARVW_VW )
     AND A~PARVW IN @S_PARVW
     AND A~PERNR IN @S_PERNR
     AND A~PERNR <> @SPACE
    INTO TABLE @LT_PARTNER.

  CHECK LT_PARTNER IS NOT INITIAL.

  SORT LT_PARTNER BY VBELN PARVW.

  SELECT PARVW, VTEXT
    FROM TPART
   WHERE SPRAS = @SY-LANGU
    INTO TABLE @LT_PFTEXT.
  SORT LT_PFTEXT BY PARVW.

  LOOP AT GT_BILL ASSIGNING FIELD-SYMBOL(<LFS_B>).

* Hoa don tra lai tru vao doanh so - FS muc 2.4 chi tieu (14)
    IF <LFS_B>-VBTYP = GC_VBTYP_RET.
      LV_SIGN = -1.
    ELSE.
      LV_SIGN = 1.
    ENDIF.

    LOOP AT LT_PARTNER ASSIGNING FIELD-SYMBOL(<LFS_P>)
         WHERE VBELN = <LFS_B>-VBELN.

      APPEND INITIAL LINE TO GT_ALV ASSIGNING FIELD-SYMBOL(<LFS_A>).

      <LFS_A>-PERNR    = <LFS_P>-PERNR.
      <LFS_A>-PARVW    = <LFS_P>-PARVW.
      <LFS_A>-VKBUR    = <LFS_B>-VKBUR.
      <LFS_A>-VKBUR_TX = <LFS_B>-VKBUR_TX.
      <LFS_A>-WAERK    = <LFS_B>-WAERK.
      <LFS_A>-NETWR    = <LFS_B>-NETWR * LV_SIGN.

* Thang ap dung = thang/nam cua Billing date - FS chi tieu (11)
      <LFS_A>-PERIOD   = |{ <LFS_B>-FKDAT+4(2) }/{ <LFS_B>-FKDAT(4) }|.

      READ TABLE LT_PFTEXT INTO LS_PFTEXT
           WITH KEY PARVW = <LFS_P>-PARVW BINARY SEARCH.
      IF SY-SUBRC = 0.
        <LFS_A>-PARVW_TX = LS_PFTEXT-VTEXT.
      ENDIF.

    ENDLOOP.

  ENDLOOP.

  PERFORM GET_HR_INFO.
  PERFORM GET_PRODUCT_GROUP.
  PERFORM SUM_BY_KEY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_HR_INFO
*&---------------------------------------------------------------------*
FORM GET_HR_INFO.

*&---------------------------------------------------------------------*
*& TODO - CHO BA XAC NHAN NGUON DU LIEU HRM
*&
*& FS muc 2.4 chi ghi "theo du lieu HRM" cho 5 chi tieu, khong cho
*& ten bang/field ky thuat (khac voi chi tieu (8)(11) co ghi ro
*& [Tcode] VF03 / [Field] Sales Office, Billing Date):
*&   (4)  Ten nhan vien       -> <LFS_A>-ENAME
*&   (5)  Ten phong ban HRM   -> <LFS_A>-ORGEH_TX
*&   (6)  Ma phong ban HRM    -> <LFS_A>-ORGEH
*&   (9)  Ten vi tri cong viec-> <LFS_A>-PLANS_TX
*&   (10) Ma vi tri cong viec -> <LFS_A>-PLANS
*&
*& Kiem tra tren DEV client 200: bang PA0001 co 0 ban ghi nen khong
*& the tu xac dinh nguon du lieu.
*&
*& Khi co nguon du lieu: doc theo GT_ALV-PERNR va gan 5 field tren.
*&---------------------------------------------------------------------*

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_PRODUCT_GROUP
*&---------------------------------------------------------------------*
FORM GET_PRODUCT_GROUP.

*&---------------------------------------------------------------------*
*& TODO - CHO BA XAC NHAN
*&
*& FS muc 3.1: "Ma nhom san pham = Nhom san pham phan tich (lay tu
*& field Z_SPCL trong Basic Data3) + Distribution Channel +
*& Customer Group", khai bao tai man hinh ZRHR02B.
*&
*& Hai diem chan:
*& 1. Field Z_SPCL khong ton tai tren DEV client 200 (da kiem tra:
*&    MARA chi co ZZBRAND/ZZGROUP/ZZSUB_GROUP...; CABN khong co
*&    characteristic nao bat dau bang Z). Chinh BA cung da comment
*&    trong FS "Update lai ten Field tren Master data cua Ma".
*& 2. Bang Z cua man hinh khai bao ZRHR02B chua duoc tao.
*&
*& Khi co du thong tin: doc bang mapping theo bo khoa
*& (VTWEG + KDGRP + nhom san pham phan tich) co hieu luc tai ngay
*& bao cao, gan vao <LFS_A>-SPGRP va <LFS_A>-SPGRP_TX.
*&---------------------------------------------------------------------*

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SUM_BY_KEY
*& Cong don doanh so theo nhan vien + vai tro + thang + nhom san pham
*&---------------------------------------------------------------------*
FORM SUM_BY_KEY.

  DATA: LT_SUM TYPE GTT_ALV,
        LV_STT TYPE N LENGTH 6.

  SORT GT_ALV BY PERNR PARVW PERIOD SPGRP VKBUR.

  LOOP AT GT_ALV ASSIGNING FIELD-SYMBOL(<LFS_A>).

    READ TABLE LT_SUM ASSIGNING FIELD-SYMBOL(<LFS_S>)
         WITH KEY PERNR  = <LFS_A>-PERNR
                  PARVW  = <LFS_A>-PARVW
                  PERIOD = <LFS_A>-PERIOD
                  SPGRP  = <LFS_A>-SPGRP
                  VKBUR  = <LFS_A>-VKBUR.

    IF SY-SUBRC = 0.
      <LFS_S>-NETWR = <LFS_S>-NETWR + <LFS_A>-NETWR.
    ELSE.
      APPEND <LFS_A> TO LT_SUM.
    ENDIF.

  ENDLOOP.

  CLEAR GT_ALV.
  GT_ALV = LT_SUM.

  LOOP AT GT_ALV ASSIGNING <LFS_A>.
    LV_STT = LV_STT + 1.
    <LFS_A>-STT = LV_STT.
  ENDLOOP.

ENDFORM.
