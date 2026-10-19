*&---------------------------------------------------------------------*
*& Report ZPG_SD_BKBLHHDV
*&---------------------------------------------------------------------*
*&  Mo ta  : Bang ke ban le hang hoa dich vu (Tcode ZRSD08) - Bidiphar
*&  FS     : BIDIPHAR_FS_SD_ZRSD08_BangKeBanLeHangHoaDichVu_V1.0
*&  Nguoi lap : [CS]_DanhDH
*&
*&  Chuong trinh chi IN bieu mau; khong tao / sua / xoa chung tu SAP.
*&  Mot bang ke in cho MOT don vi mua hang cua MOT nha thuoc.
*&---------------------------------------------------------------------*
REPORT ZPG_SD_BKBLHHDV MESSAGE-ID ZMC_SD.

INCLUDE ZIN_SD_BKBLHHDV_TOP.
INCLUDE ZIN_SD_BKBLHHDV_F01.

*---------------------------------------------------------------------*
INITIALIZATION.
*---------------------------------------------------------------------*
* Mac dinh: tu ngay dau thang hien tai den ngay hien tai
  PERFORM SET_DEFAULT_DATE.

*---------------------------------------------------------------------*
AT SELECTION-SCREEN.
*---------------------------------------------------------------------*
* Kiem tra quyen truoc khi doc du lieu
  PERFORM CHECK_AUTHORITY.

*---------------------------------------------------------------------*
START-OF-SELECTION.
*---------------------------------------------------------------------*
  PERFORM GET_DATA.

  IF GT_ITEM IS INITIAL.
    MESSAGE 'Khong tim thay du lieu voi dieu kien da chon' TYPE 'S'
            DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
END-OF-SELECTION.
*---------------------------------------------------------------------*
  PERFORM PRINT_FORM.
