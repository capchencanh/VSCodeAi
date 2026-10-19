*&---------------------------------------------------------------------*
*& Report ZPG_SD_BKBLHHDV_TEST
*&---------------------------------------------------------------------*
*& Test Smart Form ZSF_SD_BKBLHHDV bang data mau cua FS (khong doc SD).
*& Tien VND luu dang nhan 100 nhu VBRP-NETWR that: 352.000 VND = 3520.00
*&---------------------------------------------------------------------*
REPORT ZPG_SD_BKBLHHDV_TEST.

PARAMETERS P_ROWS TYPE I DEFAULT 3.   " >3: them dong de test xuong trang

DATA: GS_HEAD TYPE ZST_RSD08_HEAD,
      GT_ITEM TYPE ZTT_RSD08_ITEM,
      GT_TAX  TYPE ZTT_RSD08_TAX,
      LV_FM   TYPE RS38L_FNAM,
      LS_CTL  TYPE SSFCTRLOP,
      LS_OPT  TYPE SSFCOMPOP.

START-OF-SELECTION.

  GT_ITEM = VALUE #(
    ( POSNR = '000010' VBELN = '0090000001' STT = '0001' MATNR = 'BIRAGAN'
      MAKTX = 'Biragan 500 H/16'      MEINS = 'ST' MENGE = 160
      KBETR = '22.00'  NETWR = '3520.00'  TAXRATE = 5  WAERK = 'VND' )
    ( POSNR = '000020' VBELN = '0090000001' STT = '0002' MATNR = 'BIDICORBIC'
      MAKTX = 'Bidicorbic 500 L/100'  MEINS = 'KG' MENGE = 400
      KBETR = '4.30'   NETWR = '1720.00'  TAXRATE = 8  WAERK = 'VND' )
    ( POSNR = '000030' VBELN = '0090000001' STT = '0003' MATNR = 'BIRACIN'
      MAKTX = 'Biracin E H/1'         MEINS = 'L'   MENGE = 50
      KBETR = '117.70' NETWR = '5885.00'  TAXRATE = 10 WAERK = 'VND' ) ).

  DO P_ROWS - 3 TIMES.
    APPEND VALUE #( VBELN = '0090000001' STT = |{ sy-index + 3 WIDTH = 4 ALIGN = RIGHT PAD = '0' }|
                    MAKTX = |Hang hoa test so { sy-index + 3 } - ten dai de kiem tra xuong dong trong o|
                    MEINS = 'ST' MENGE = 1 KBETR = '10.00' NETWR = '10.00'
                    TAXRATE = 10 WAERK = 'VND' ) TO GT_ITEM.
  ENDDO.

  GS_HEAD-BUKRS      = '0001'.
  GS_HEAD-LOGO       = 'ZLOGO_0001'.
  GS_HEAD-CNAME      = 'CÔNG TY TNHH MTV THƯƠNG MẠI BIDIPHAR'.
  GS_HEAD-CADDR      = '498 Nguyễn Thái Học - Phường Quy Nhơn Nam - Tỉnh Gia Lai'.
  GS_HEAD-CTAXNO     = '4100259564'.
  GS_HEAD-NHATHUOC   = 'NT001'.
  GS_HEAD-NHATHUOCNM = 'Nhà thuốc Bidiphar số 1'.
  GS_HEAD-DATE_FR    = '20260801'.
  GS_HEAD-DATE_TO    = '20260818'.
  GS_HEAD-FKART      = 'ZF2'.
  GS_HEAD-FKARTX     = 'Invoice (ZF2)'.
  GS_HEAD-PAYERNM    = 'CÔNG TY CỔ PHẦN ĐẦU TƯ AN PHÁT'.
  GS_HEAD-PAYERTAX   = '0000224444'.
  GS_HEAD-PAYERAD    = 'Cụm Công nghiệp Tam Quan, Phường Tam Quan, Tỉnh Gia Lai, Việt Nam'.
  GS_HEAD-WAERK      = 'VND'.
  GS_HEAD-PRTDATE    = SY-DATUM.

* Tong hop thue theo muc thue suat
  LOOP AT GT_ITEM ASSIGNING FIELD-SYMBOL(<LFS_ITEM>).
    READ TABLE GT_TAX ASSIGNING FIELD-SYMBOL(<LFS_TAX>)
         WITH KEY TAXRATE = <LFS_ITEM>-TAXRATE.
    IF SY-SUBRC <> 0.
      APPEND VALUE #( TAXRATE = <LFS_ITEM>-TAXRATE
                      WAERK   = 'VND' ) TO GT_TAX ASSIGNING <LFS_TAX>.
    ENDIF.
    <LFS_TAX>-TAXAMT = <LFS_TAX>-TAXAMT + <LFS_ITEM>-NETWR * <LFS_ITEM>-TAXRATE / 100.
  ENDLOOP.
  SORT GT_TAX BY TAXRATE.

  GS_HEAD-TOTAL   = REDUCE #( INIT S = CONV NETWR_FP( 0 ) FOR L IN GT_ITEM NEXT S = S + L-NETWR ).
  GS_HEAD-TAXAMT  = REDUCE #( INIT S = CONV NETWR_FP( 0 ) FOR T IN GT_TAX NEXT S = S + T-TAXAMT ).
  GS_HEAD-AMTPAY  = GS_HEAD-TOTAL + GS_HEAD-TAXAMT.
  GS_HEAD-AMTWORD = ZCORE_CL_AMOUNT_IN_WORDS=>READ_AMOUNT(
                      I_AMOUNT      = CONV #( GS_HEAD-AMTPAY )
                      I_WAERS       = GS_HEAD-WAERK
                      I_IS_INTERNAL = ABAP_TRUE ).

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME = 'ZSF_SD_BKBLHHDV'
    IMPORTING
      FM_NAME  = LV_FM
    EXCEPTIONS
      OTHERS   = 1.
  IF SY-SUBRC <> 0.
    MESSAGE 'Khong tim thay form ZSF_SD_BKBLHHDV' TYPE 'E'.
  ENDIF.

* Thiet bi in lay tu user (SU3); chua co thi hien hop thoai de chon (vd LP01)
  SELECT SINGLE SPLD FROM USR01 WHERE BNAME = @SY-UNAME INTO @LS_OPT-TDDEST.
  IF LS_OPT-TDDEST IS NOT INITIAL.
    LS_CTL-NO_DIALOG = 'X'.
  ENDIF.
  LS_CTL-PREVIEW   = 'X'.

  CALL FUNCTION LV_FM
    EXPORTING
      CONTROL_PARAMETERS = LS_CTL
      OUTPUT_OPTIONS     = LS_OPT
      USER_SETTINGS      = SPACE
      IS_HEAD            = GS_HEAD
    TABLES
      IT_ITEM            = GT_ITEM
      IT_TAX             = GT_TAX
    EXCEPTIONS
      OTHERS             = 1.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE 'E' NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
