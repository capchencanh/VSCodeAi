*&---------------------------------------------------------------------*
*& Report ZPG_SD_THCPVC - Bao cao tong hop chi phi van chuyen (ZRSD26)
*&---------------------------------------------------------------------*
REPORT ZPG_SD_THCPVC MESSAGE-ID ZMC_SD.

INCLUDE ZIN_SD_THCPVC_TOP.
INCLUDE ZIN_SD_THCPVC_PBO.
INCLUDE ZIN_SD_THCPVC_PAI.
INCLUDE ZIN_SD_THCPVC_F01.
INCLUDE ZIN_SD_THCPVC_F02.

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

  CALL SCREEN 0100.
