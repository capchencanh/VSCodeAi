*&---------------------------------------------------------------------*
*& Report ZPG_SD_PDVHMN - Bao cao theo doi phe duyet don hang vuot han muc no (ZRSD25)
*&---------------------------------------------------------------------*
REPORT ZPG_SD_PDVHMN MESSAGE-ID ZMC_SD.

INCLUDE ZIN_SD_PDVHMN_TOP.
INCLUDE ZIN_SD_PDVHMN_F01.
INCLUDE ZIN_SD_PDVHMN_F02.

INITIALIZATION.
  PERFORM SET_DEFAULT_DATE.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR S_REASON-LOW.
  PERFORM F4_REASON.

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

  PERFORM DISPLAY_ALV.
