*----------------------------------------------------------------------*
* Program ID: ZPG_SD_DSNVBH
* Program Name: Bao cao doanh so nhan vien ban hang
*
* Program Summary: Bao cao doanh so nhan vien ban hang (ZRHR02)
*
*
* Creation Date : 06.10.2026                     Created by： DanhDH
* Coding Standards Version 7
* Development Version:
* Available Condition:
*----------------------------------------------------------------------*
* CitekTechnology JSC.
* (C) CopyrightCitekTechnology JSC.
* All Rights Reserved
*----------------------------------------------------------------------*
REPORT ZPG_SD_DSNVBH MESSAGE-ID ZMC_SD.

INCLUDE ZIN_SD_DSNVBH_TOP.
INCLUDE ZIN_SD_DSNVBH_F01.
INCLUDE ZIN_SD_DSNVBH_F02.

INITIALIZATION.
  PERFORM SET_DEFAULT_DATE.

AT SELECTION-SCREEN.
  IF SY-UCOMM = 'ONLI'.
    PERFORM CHECK_AUTHORITY.
  ENDIF.

START-OF-SELECTION.
  PERFORM GET_DATA.

  IF GT_ALV IS INITIAL.
    MESSAGE 'Khong tim thay du lieu voi dieu kien da chon' TYPE 'S'
            DISPLAY LIKE 'E'. "#EC NOTEXT
    RETURN.
  ENDIF.

  IF P_PRINT = ABAP_TRUE.
    PERFORM PRINT_FORM.
  ELSE.
    PERFORM DISPLAY_ALV.
  ENDIF.
