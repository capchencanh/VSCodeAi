*&---------------------------------------------------------------------*
*&  Include           ZFI_IN_GL_BCLCTTGT_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM INIT .
*  LW_TXT01 = 'Month'.
*  LW_TXT02 = 'Quater'.
*  LW_TXT11 = 'Mid Year'.
  LW_TXT03 = 'Year'.
*  LW_TXT04 = 'Layout'.
*  LW_TXT05 = 'Smartforms'.
*  LW_TXT06 = 'Excel'.
  LW_TXT07 = 'Scaling'.
  LW_TXT08 = 'VND'.
  LW_TXT09 = '1.000 VND'.
  LW_TXT10 = '1.000.000 VND'.
  LW_TXT12 = 'Language'.
  LW_TXT13 = 'Vietnamese'.
  LW_TXT14 = 'English'.
*  LW_TXT15 = 'Nhiều tháng'.
  %_S_BUKRS_%_APP_%-TEXT    = 'Company code'.
  %_P_VERSN_%_APP_%-TEXT    = 'Financial Statement Version'.
  %_P_BUPEJ_%_APP_%-TEXT    = 'Fiscal Year'.
  %_P_CJAHR_%_APP_%-TEXT    = 'Compare Fiscal Year'.
  %_P_PER_%_APP_%-TEXT      = 'Period'.

  P_BUPEJ = SY-DATUM(4).
  P_CJAHR = P_BUPEJ - 1.

  LW_TXT97 = 'Định dạng số:'.
  LW_TXT98 = 'Kiểu mặc định'.
  LW_TXT99 = 'Kiểu Việt Nam'.


ENDFORM.                    " INIT
*&---------------------------------------------------------------------*
*&      Form  CHECK_CONDITION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_CONDITION .
  " Check BUKRS authorization
  CALL FUNCTION 'ZCORE_AUTHORIZATION_BUKRS'
    EXPORTING
      I_BUKRS = S_BUKRS-LOW.

*  IF P_TYPE_M = 'X'.
*    IF P_PER < 1 OR P_PER > 12.
*      MESSAGE 'Value of Periods for Month: 1 - 12' TYPE 'E'.
*    ENDIF.
*  ENDIF.
*  IF P_TYPE_Q = 'X'.
*    IF P_PER < 1 OR P_PER > 4.
*      MESSAGE 'Value of Peroids for Quater: 1 - 4' TYPE 'E'.
*    ENDIF.
*  ENDIF.

  IF P_BUPEJ = P_CJAHR.
    MESSAGE 'Compare Fiscal Year and Fiscal Year should have different value!' TYPE 'E'.
  ENDIF.

  "PhatTT add begin 10.03.2026 20:42:19
*  IF  P_TYPE_N = 'X'.
*    IF P_PER < 1 OR P_PER > 2.
*      MESSAGE 'Value of Peroids for Quater: 1 - 2' TYPE 'S' DISPLAY LIKE 'E'.
*      LEAVE SCREEN.
*    ENDIF.
*  ENDIF.
  "PhatTT add end 10.03.2026 20:42:22
ENDFORM.                    " CHECK_CONDITION
*&---------------------------------------------------------------------*
*&      Form  GET_PARAMETER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_PARAMETER .
  DATA: LW_NUMBER TYPE         CHAR10,
        LS_BUKRS  LIKE LINE OF S_BUKRS,
        LW_PER    TYPE CHAR2.

  LW_NUMBER = S_BUKRS-LOW.

  " Get Information => LOGO
  CONCATENATE 'LOGO_' LW_NUMBER INTO GS_PARAMETER-LOGO.

  SELECT
    BUKRS
    INTO TABLE GT_COMCODE
    FROM T001
    WHERE BUKRS IN S_BUKRS.

  " Get Period Information
  CLEAR: GT_MONAT, GS_MONAT.
*  IF P_TYPE_M = 'X'.    "Month
*
*    "PhatTT add begin 10.03.2026 15:13:12
*    GS_MONAT-SIGN     = 'I'.
*    GS_MONAT-OPTION   = 'BT'.
*    IF P_BUPEJ = '2025'.
*      " Period
*      GS_MONAT-LOW      = P_PER.
*    ELSE.
*      GS_MONAT-LOW      = P_PER.
*      IF P_PER = 12.
*        GS_MONAT-HIGH = 16.
*      ELSE.
*        GS_MONAT-HIGH = P_PER.
*      ENDIF.
*    ENDIF.
*    "PhatTT add end 10.03.2026 15:13:17
*
****    " Period
****    GS_MONAT-SIGN     = 'I'.
****    GS_MONAT-OPTION   = 'BT'.
****    GS_MONAT-LOW      = P_PER.
****    IF P_PER = 12.
****      GS_MONAT-HIGH = 16.
****    ELSE.
****      GS_MONAT-HIGH = P_PER.
****    ENDIF.
*    APPEND GS_MONAT TO GT_MONAT.
*  ENDIF.

*  IF P_TYPE_Q = 'X'.     "Quarter
*    " Period
*    GS_MONAT-SIGN     = 'I'.
*    GS_MONAT-OPTION   = 'BT'.
*    "PhatTT add begin 10.03.2026 15:31:57
*    IF P_BUPEJ = '2025'.
*      IF P_PER = 1.
*        GS_MONAT-LOW = 1.
*        GS_MONAT-HIGH = 3.
*      ELSEIF P_PER = 2.
*        GS_MONAT-LOW = 4.
*        GS_MONAT-HIGH = 6.
*      ELSEIF P_PER = 3.
*        GS_MONAT-LOW = 7.
*        GS_MONAT-HIGH = 9.
*      ELSEIF P_PER = 4.
*        GS_MONAT-LOW = 10.
*        GS_MONAT-HIGH = 12.
*      ENDIF.
*    ELSE.
*      IF P_PER = 1.
*        GS_MONAT-LOW = 1.
*        GS_MONAT-HIGH = 3.
*      ELSEIF P_PER = 2.
*        GS_MONAT-LOW = 4.
*        GS_MONAT-HIGH = 6.
*      ELSEIF P_PER = 3.
*        GS_MONAT-LOW = 7.
*        GS_MONAT-HIGH = 9.
*      ELSEIF P_PER = 4.
*        GS_MONAT-LOW = 10.
*        GS_MONAT-HIGH = 16.
*      ENDIF.
*    ENDIF.
*
*    "PhatTT add end 10.03.2026 15:32:01
*****    IF P_PER = 1.
*****      GS_MONAT-LOW = 1.
*****      GS_MONAT-HIGH = 3.
*****    ELSEIF P_PER = 2.
*****      GS_MONAT-LOW = 4.
*****      GS_MONAT-HIGH = 6.
*****    ELSEIF P_PER = 3.
*****      GS_MONAT-LOW = 7.
*****      GS_MONAT-HIGH = 9.
*****    ELSEIF P_PER = 4.
*****      GS_MONAT-LOW = 10.
*****      GS_MONAT-HIGH = 16.
*****    ENDIF.
*    APPEND GS_MONAT TO GT_MONAT.
*  ENDIF.

*  IF P_TYPE_N = 'X'.    "Mid year
****    " Period
****    GS_MONAT-SIGN     = 'I'.
****    GS_MONAT-OPTION   = 'BT'.
****    IF P_PER = 1.
****      GS_MONAT-LOW = 1.
****      GS_MONAT-HIGH = 6.
****    ELSEIF P_PER = 2.
****      GS_MONAT-LOW = 7.
****      GS_MONAT-HIGH = 16.
****    ENDIF.
*    "PhatTT add begin 10.03.2026 15:16:32
*
*    GS_MONAT-SIGN     = 'I'.
*    GS_MONAT-OPTION   = 'BT'.
*    IF P_BUPEJ = '2025'.
*      " Period
*      IF P_PER = 1.
*        GS_MONAT-LOW = 1.
*        GS_MONAT-HIGH = 6.
*      ELSEIF P_PER = 2.
*        GS_MONAT-LOW = 7.
*        GS_MONAT-HIGH = 12.
*      ENDIF.
*    ELSE.
*      " Period
*      IF P_PER = 1.
*        GS_MONAT-LOW = 1.
*        GS_MONAT-HIGH = 6.
*      ELSEIF P_PER = 2.
*        GS_MONAT-LOW = 7.
*        GS_MONAT-HIGH = 16.
*      ENDIF.
*    ENDIF.
*    "PhatTT add end 10.03.2026 15:16:34
*
*    APPEND GS_MONAT TO GT_MONAT.
*  ENDIF.

  IF P_TYPE_Y = 'X'.
    GS_MONAT-SIGN     = 'I'.
    GS_MONAT-OPTION   = 'BT'.

    "PhatTT add begin 10.03.2026 15:33:49
    IF P_BUPEJ = '2025'.
      GS_MONAT-LOW      = 1.
      GS_MONAT-HIGH     = 12.
    ELSE.
      GS_MONAT-LOW      = 1.
      GS_MONAT-HIGH     = 16.
    ENDIF.
    "PhatTT add end 10.03.2026 15:33:51

***    GS_MONAT-LOW      = 1.
***    GS_MONAT-HIGH     = 16.
    APPEND GS_MONAT TO GT_MONAT.
  ENDIF.

*  IF P_TYPE_S = 'X'. "thuong.duong_start add 24.04.24
*    GS_MONAT-SIGN     = 'I'.
*    GS_MONAT-OPTION   = 'BT'.
*    GS_MONAT-LOW      = S_PER-LOW.
*
*    "PhatTT add begin 10.03.2026 15:36:29
*    GS_MONAT-HIGH      = S_PER-HIGH.
*    "PhatTT add end 10.03.2026 15:36:35
*
****    GS_MONAT-HIGH     = COND #( WHEN S_PER-HIGH NE 12 THEN S_PER-HIGH
****                                WHEN S_PER-HIGH EQ 12 OR S_PER-LOW EQ 12 THEN 16 ).
*    APPEND GS_MONAT TO GT_MONAT.
*  ENDIF.

  IF P_VN IS NOT INITIAL.
    " Get Information => COMPANY_NAME, ADDRESS, TAX
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        I_NUMBER  = LW_NUMBER
        I_KIND    = 'C'
      IMPORTING
        E_ADDRESS = GS_PARAMETER-ADDRESS
        E_NAME    = GS_PARAMETER-NAME.

    " Get Information => ISO
***    GS_PARAMETER-ISO_LINE01 = 'Mẫu số B 03-DN'.
***    GS_PARAMETER-ISO_LINE02 = '(Ban hành kèm theo TT số 200/2014/TT-BTC ngày 22/12/2014 của Bộ Tài Chính)'.

    "PhatTT add begin 09.03.2026 14:07:29

    IF P_VERSN = 'ZCF2'.
      GS_PARAMETER-ISO_LINE01 = 'Mẫu số B 03 - DN'.
      GS_PARAMETER-ISO_LINE02 = '(Kèm theo Thông tư số 99/2025/TT-BTC ngày 27 tháng 10 năm 2025 của Bộ trưởng Bộ Tài chính)'.
    ELSE.
      GS_PARAMETER-ISO_LINE01 = 'Mẫu số B 03-DN'.
*      GS_PARAMETER-ISO_LINE02 = '(Ban hành kèm theo TT số 200/2014/TT-BTC ngày 22/12/2014 của Bộ Tài Chính)'.
      GS_PARAMETER-ISO_LINE02 = '(Kèm theo Thông tư số 99/2025/TT-BTC ngày 27 tháng 10 năm 2025 của Bộ trưởng Bộ Tài chính)'.
    ENDIF.
    "PhatTT add end 09.03.2026 14:07:46

*    GS_PARAMETER-ISO_LINE3 = 'ngày 20/03/2006 của Bộ trưởng BTC)'.

    " Get Information => TITLE_REPORT
*    GS_PARAMETER-TITLE_REPORT     = 'BÁO CÁO LƯU CHUYỂN TIỀN TỆ '.

    "danhdh add begin 03.06.2026 16:21:33
    IF P_VERSN = 'ZCF5'.
      GS_PARAMETER-TITLE_REPORT = 'BÁO CÁO LƯU CHUYỂN TIỀN TỆ HỢP NHẤT'.
    ELSE.
      GS_PARAMETER-TITLE_REPORT = 'BÁO CÁO LƯU CHUYỂN TIỀN TỆ '.
    ENDIF.
    "danhdh add end 03.06.2026 16:21:33


    " Get Information => PARAMETER
    LW_PER = P_PER.
    IF STRLEN( LW_PER  ) < 2.
      CONCATENATE '0' LW_PER  INTO LW_PER .
    ENDIF.

*    GS_PARAMETER-PARAMETER01 = '(Theo phương pháp gián tiếp)(*)'.

    "danhdh add begin 27.05.2026 13:27:23
    IF P_VERSN = 'ZCF3' OR P_VERSN = 'ZCF5'.
      GS_PARAMETER-PARAMETER01 = '(Theo phương pháp trực tiếp)(*)'.
    ELSE.
      GS_PARAMETER-PARAMETER01 = '(Theo phương pháp gián tiếp)(*)'.
    ENDIF.
    "danhdh add end 27.05.2026 13:27:23


    CASE 'X'.
*      WHEN P_TYPE_M.
*        CONCATENATE 'Tháng' LW_PER 'năm' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*      WHEN P_TYPE_Q.
*        CONCATENATE 'Quý' LW_PER 'năm' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*      WHEN P_TYPE_N.
*        IF P_PER EQ 1.
*          CONCATENATE 'Sáu tháng đầu năm' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*        ELSE.
*          CONCATENATE 'Sáu tháng cuối năm' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*        ENDIF.
      WHEN P_TYPE_Y.
        CONCATENATE 'Năm' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*      WHEN P_TYPE_S. "thuong.duong_start add 12.04.24
*        PERFORM GET_DESCRIPTION_PERIOD USING 'VI' CHANGING GS_PARAMETER-PARAMETER02 .
    ENDCASE.

    CASE 'X'.
      WHEN P_SCAL2.
        CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER'
          EXPORTING
            I_DMBTR = '1000'
            I_CURR  = 'VND'
          IMPORTING
            E_DMBTR = GS_PARAMETER-PARAMETER03.
      WHEN P_SCAL3.
        CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER'
          EXPORTING
            I_DMBTR = '1000000'
            I_CURR  = 'VND'
          IMPORTING
            E_DMBTR = GS_PARAMETER-PARAMETER03.
    ENDCASE.
    CONCATENATE 'Đơn vị tiền tệ:' GS_PARAMETER-PARAMETER03 'VND' INTO GS_PARAMETER-PARAMETER03 SEPARATED BY SPACE.

    " Get Information => HEADER
    GS_PARAMETER-HEADER01  = 'Chỉ tiêu'.
    GS_PARAMETER-HEADER02  = 'Mã số'.
    GS_PARAMETER-HEADER03  = 'Thuyết minh'.

    CASE 'X'.
*      WHEN P_TYPE_M.
*        CONCATENATE 'Tháng' LW_PER INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*      WHEN P_TYPE_Q.
*        CONCATENATE 'Quý' LW_PER INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*      WHEN P_TYPE_N.
*        IF P_PER EQ 1.
*          CONCATENATE 'Sáu tháng đầu năm' P_BUPEJ INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*        ELSE.
*          CONCATENATE 'Sáu tháng cuối năm' P_BUPEJ INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*        ENDIF.
      WHEN P_TYPE_Y.
        CONCATENATE 'Năm' P_BUPEJ INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*      WHEN P_TYPE_S. "thuong.duong_start add 24.04.24
*        PERFORM GET_DESCRIPTION_PERIOD USING 'VI' CHANGING GS_PARAMETER-HEADER04.
    ENDCASE.

* 000(Update)Start----------------------------------------------
*    GS_PARAMETER-HEADER05  = 'Năm nay'.
*    GS_PARAMETER-HEADER06  = 'Năm trước'.
    CONCATENATE 'Năm' P_BUPEJ INTO GS_PARAMETER-HEADER05 SEPARATED BY SPACE.
    CONCATENATE 'Năm' P_CJAHR INTO GS_PARAMETER-HEADER06 SEPARATED BY SPACE.
* 000(Update)End------------------------------------------------

    " Get Information => SIGN
    GS_PARAMETER-SIGN01    = 'Ngày ..... tháng ..... năm  .......'.
    GS_PARAMETER-SIGN02    = 'Người lập'.
    GS_PARAMETER-SIGN03    = 'Kế toán trưởng'.

***    IF LW_NUMBER EQ '1000' OR LW_NUMBER EQ '1300'.
***      GS_PARAMETER-SIGN04 = 'Tổng giám đốc'.
***    ELSE.
***      GS_PARAMETER-SIGN04 = 'Giám đốc'.
***    ENDIF.

    "PhatTT add begin 16.03.2026 16:00:17
    IF P_VERSN = 'ZCF2'.
      GS_PARAMETER-SIGN04 = 'Người đại diện theo pháp luật'.
    ELSE.
      IF LW_NUMBER EQ '1000' OR LW_NUMBER EQ '1300'.
        GS_PARAMETER-SIGN04 = 'Tổng giám đốc'.
      ELSE.
        GS_PARAMETER-SIGN04 = 'Giám đốc'.
      ENDIF.
    ENDIF.
    "PhatTT add end 16.03.2026 16:00:21


    GS_PARAMETER-SIGN05    = '(Ký, họ tên)'.
    GS_PARAMETER-SIGN06    = '(Ký, họ tên, đóng dấu)'.
    IF GW_EX EQ 'X'.
      GS_PARAMETER-HEADER01  = 'Chỉ tiêu'.
      GS_PARAMETER-HEADER02  = 'Mã số'.
      GS_PARAMETER-HEADER03  = 'Thuyết minh'.
* 000(Update)Start----------------------------------------------
*      GS_PARAMETER-HEADER05  = 'Năm nay'.
*      GS_PARAMETER-HEADER06  = 'Năm trước'.
      CONCATENATE 'Năm' P_BUPEJ INTO GS_PARAMETER-HEADER05 SEPARATED BY SPACE.
      CONCATENATE 'Năm' P_CJAHR INTO GS_PARAMETER-HEADER06 SEPARATED BY SPACE.
* 000(Update)End------------------------------------------------
    ENDIF.
    " Get Information => REPORT_CODE
    GS_PARAMETER-REPORT_CODE = ''.
  ELSE.
    " Get Information => COMPANY_NAME, ADDRESS, TAX
    CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
      EXPORTING
        I_NUMBER       = LW_NUMBER
        I_KIND         = 'C'
      IMPORTING
        E_ADDRESS_EN   = GS_PARAMETER-ADDRESS
        E_NAME_N_TITLE = GS_PARAMETER-NAME.

    " Get Information => ISO
    GS_PARAMETER-ISO_LINE01 = 'Form B 03-DN'.
    GS_PARAMETER-ISO_LINE02 = '(Issued under Circular No. 200/2014/TT-BTC date 22/12/2014 of Ministry of Finance)'.
*    GS_PARAMETER-ISO_LINE3 = 'ngày 20/03/2006 của Bộ trưởng BTC)'.

    " Get Information => TITLE_REPORT
    GS_PARAMETER-TITLE_REPORT  = 'CASH FLOW STATEMENT'.

    " Get Information => PARAMETER
    LW_PER = P_PER.
    IF STRLEN( LW_PER  ) < 2.
      CONCATENATE '0' LW_PER  INTO LW_PER .
    ENDIF.

    GS_PARAMETER-PARAMETER01 = '(Under the indirect method) (*)'.

    CASE 'X'.
*      WHEN P_TYPE_M.
*        CONCATENATE 'Month' LW_PER 'year' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*      WHEN P_TYPE_Q.
*        CONCATENATE 'Quater' LW_PER 'year' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*      WHEN P_TYPE_N.
*        IF P_PER EQ 1.
*          CONCATENATE 'The first six months of the year' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*        ELSE.
*          CONCATENATE 'The last six months of the year' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*        ENDIF.
      WHEN P_TYPE_Y.
        CONCATENATE 'Year' P_BUPEJ INTO GS_PARAMETER-PARAMETER02 SEPARATED BY SPACE.
*      WHEN P_TYPE_S. "Thuong.duong_start add 12.04.24
*        PERFORM GET_DESCRIPTION_PERIOD USING 'EN' CHANGING GS_PARAMETER-PARAMETER02.
    ENDCASE.
    CASE 'X'.
      WHEN P_SCAL2.
        CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER'
          EXPORTING
            I_DMBTR = '1000'
            I_CURR  = 'VND'
          IMPORTING
            E_DMBTR = GS_PARAMETER-PARAMETER03.
      WHEN P_SCAL3.
        CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER'
          EXPORTING
            I_DMBTR = '1000000'
            I_CURR  = 'VND'
          IMPORTING
            E_DMBTR = GS_PARAMETER-PARAMETER03.
    ENDCASE.
    CONCATENATE 'Unit:' GS_PARAMETER-PARAMETER03 'VND' INTO GS_PARAMETER-PARAMETER03 SEPARATED BY SPACE.

    " Get Information => HEADER
    GS_PARAMETER-HEADER01 = 'Items'.
    GS_PARAMETER-HEADER02 = 'Code'.
    GS_PARAMETER-HEADER03 = 'Explanation'.

    CASE 'X'.
*      WHEN P_TYPE_M.
*        CONCATENATE 'Month' LW_PER INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*      WHEN P_TYPE_Q.
*        CONCATENATE 'Quater' LW_PER INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*      WHEN P_TYPE_N.
*        IF P_PER EQ 1.
*          CONCATENATE 'The first six months of the year' P_BUPEJ INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*        ELSE.
*          CONCATENATE 'The last six months of the year' P_BUPEJ INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*        ENDIF.
      WHEN P_TYPE_Y.
        CONCATENATE 'Year' P_BUPEJ INTO GS_PARAMETER-HEADER04 SEPARATED BY SPACE.
*      WHEN P_TYPE_S. "thuong.duong_start add 24.04.24
*        PERFORM GET_DESCRIPTION_PERIOD USING 'EN' CHANGING GS_PARAMETER-PARAMETER02.
    ENDCASE.

* 000(UPDATE)START----------------------------------------------
*    GS_PARAMETER-HEADER05  = 'This year'.
*    GS_PARAMETER-HEADER06  = 'Previous year'.
    CONCATENATE 'Year' P_BUPEJ INTO GS_PARAMETER-HEADER05 SEPARATED BY SPACE.
    CONCATENATE 'Year' P_CJAHR INTO GS_PARAMETER-HEADER06 SEPARATED BY SPACE.
* 000(Update)End------------------------------------------------

    " Get Information => SIGN
    GS_PARAMETER-SIGN01    = 'Date ..... month ..... year .......'.
    GS_PARAMETER-SIGN02    = 'Created by'.
    GS_PARAMETER-SIGN03    = 'Chief Accountant'.

    IF LW_NUMBER EQ '1000' OR LW_NUMBER EQ '1300'.
      GS_PARAMETER-SIGN04 = 'General Director'.
    ELSE.
      GS_PARAMETER-SIGN04 = 'Director'.
    ENDIF.

    GS_PARAMETER-SIGN05    = '(Sign. & Full name)'.
    GS_PARAMETER-SIGN06    = '(Sign., Full name, seal)'.
    IF GW_EX EQ 'X'.
      GS_PARAMETER-HEADER01  = 'Items'.
      GS_PARAMETER-HEADER02  = 'Code'.
      GS_PARAMETER-HEADER03  = 'Explanation'.
* 000(UPDATE)START----------------------------------------------
*    GS_PARAMETER-HEADER05  = 'This year'.
*    GS_PARAMETER-HEADER06  = 'Previous year'.
      CONCATENATE 'Year' P_BUPEJ INTO GS_PARAMETER-HEADER05 SEPARATED BY SPACE.
      CONCATENATE 'Year' P_CJAHR INTO GS_PARAMETER-HEADER06 SEPARATED BY SPACE.
* 000(Update)End------------------------------------------------
    ENDIF.
    " Get Information => REPORT_CODE
    GS_PARAMETER-REPORT_CODE = ''.
  ENDIF.
ENDFORM.                    " GET_PARAMETER
*&---------------------------------------------------------------------*
*&      Form  FILL_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FILL_DATA .
  DATA: LW_ENG TYPE CHAR1.


  "danhdh add begin 28.05.2026 11:52:09
  DATA: LT_MONAT_Q TYPE RSELOPTION,
        LS_MONAT_Q LIKE LINE OF LT_MONAT_Q,
        LV_Q       TYPE I.
  CLEAR GT_DATA_QUARTER.
  "danhdh add end 28.05.2026 11:52:09


  "danhdh add begin 03.06.2026 09:53:26
  DATA: LV_HAS_DATA TYPE CHAR1.
  "danhdh add end 03.06.2026 09:53:26

  IF P_EN EQ 'X'.
    LW_ENG = 'X'.
  ENDIF.



  LOOP AT GT_COMCODE INTO GS_COMCODE.


    "danhdh add begin 03.06.2026 09:55:09
    CLEAR LV_HAS_DATA.
    SELECT SINGLE @ABAP_TRUE
      FROM ACDOCA
      INTO @LV_HAS_DATA
      WHERE RBUKRS = @GS_COMCODE-BUKRS
        AND GJAHR  IN ( @P_BUPEJ, @P_CJAHR ).

    IF LV_HAS_DATA IS INITIAL.
      CONTINUE.
    ENDIF.
    "danhdh add end 03.06.2026 09:55:09

*    DELETE GT_BUKRS INDEX 1. :v
    CLEAR GT_BUKRS[]. "danhdh add 03.06.2026 09:55:47
    GS_BUKRS-SIGN = 'I'.
    GS_BUKRS-OPTION = 'EQ'.
    GS_BUKRS-LOW = GS_COMCODE-BUKRS.

    APPEND GS_BUKRS TO GT_BUKRS.
    CLEAR: GS_BUKRS.


    "danhdh add begin 28.05.2026 11:52:24
    "Chia ra 4 Quý
    IF GW_EX EQ 'X'.
      DO 4 TIMES.
        LV_Q = SY-INDEX.
        CLEAR: LT_MONAT_Q, LS_MONAT_Q.
        LS_MONAT_Q-SIGN = 'I'.
        LS_MONAT_Q-OPTION = 'BT'.

        CASE LV_Q.
          WHEN 1. LS_MONAT_Q-LOW = 1.  LS_MONAT_Q-HIGH = 3.
          WHEN 2. LS_MONAT_Q-LOW = 4.  LS_MONAT_Q-HIGH = 6.
          WHEN 3. LS_MONAT_Q-LOW = 7.  LS_MONAT_Q-HIGH = 9.
          WHEN 4. LS_MONAT_Q-LOW = 10. LS_MONAT_Q-HIGH = 16.
        ENDCASE.
        APPEND LS_MONAT_Q TO LT_MONAT_Q.

        CALL FUNCTION 'ZCORE_FM_J3RFF4V'
          EXPORTING
            IT_BUKRS      = GT_BUKRS
            IW_VERSN      = P_VERSN
            IW_BUPEJ      = P_BUPEJ
            IW_CJAHR      = P_CJAHR
            IT_MONAT      = LT_MONAT_Q
            IW_RLDNR      = '0L'
            IW_ENG        = LW_ENG
          TABLES
            ET_GL_J3RFF4V = LT_DATA_SYSTEM.

        LOOP AT LT_DATA_SYSTEM INTO GS_DATA_SYSTEM.
          MOVE-CORRESPONDING GS_DATA_SYSTEM TO GS_DATA_QUARTER.
          GS_DATA_QUARTER-QUARTER = LV_Q.
          APPEND GS_DATA_QUARTER TO GT_DATA_QUARTER.
        ENDLOOP.
        CLEAR LT_DATA_SYSTEM.
      ENDDO.

    ELSE.

      "danhdh add end 28.05.2026 11:52:24

      " Submit Function Lay Du Lieu Tu Bao Cao Chuan
      CALL FUNCTION 'ZCORE_FM_J3RFF4V'
        EXPORTING
          IT_BUKRS      = GT_BUKRS
          IW_VERSN      = P_VERSN
          IW_BUPEJ      = P_BUPEJ
          IW_CJAHR      = P_CJAHR
          IT_MONAT      = GT_MONAT
          IW_RLDNR      = '0L'
          IW_ENG        = LW_ENG
        TABLES
          ET_GL_J3RFF4V = LT_DATA_SYSTEM.
      APPEND LINES OF LT_DATA_SYSTEM TO GT_DATA_SYSTEM.
      CLEAR LT_DATA_SYSTEM.

    ENDIF. "danhdh add 28.05.2026 12:02:29

  ENDLOOP.

ENDFORM.                    " FILL_DATA
*&---------------------------------------------------------------------*
*&      Form  DATA_PROCESSING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DATA_PROCESSING .
  DATA:
    LW_STROW   TYPE J_3RFF4ROW,
    LW_FLAG    TYPE CHAR1,
    LW_REPVAL  TYPE BSPL_REPVAL,
    LW_COMPVAL TYPE BSPL_COMPVAL.
  FIELD-SYMBOLS:
        <FS_DATA>   LIKE ZFI_ST_J3RFF4V.


  "danhdh add begin 28.05.2026 13:04:00
  IF GW_EX EQ 'X'.
    SORT GT_DATA_QUARTER BY STROW QUARTER.
    LOOP AT GT_DATA_QUARTER INTO GS_DATA_QUARTER.
      READ TABLE GT_BCLCTTGT ASSIGNING <FS_BCLCTTGT> WITH KEY STROW = GS_DATA_QUARTER-STROW.
      IF SY-SUBRC <> 0.
        CLEAR GS_BCLCTTGT.

        MOVE-CORRESPONDING GS_DATA_QUARTER TO GS_BCLCTTGT.
        CLEAR: GS_BCLCTTGT-REPVAL, GS_BCLCTTGT-COMPVAL.

        GS_BCLCTTGT-STROW = GS_DATA_QUARTER-STROW.
        GS_BCLCTTGT-FLAG  = 'X'.
        APPEND GS_BCLCTTGT TO GT_BCLCTTGT.
        READ TABLE GT_BCLCTTGT ASSIGNING <FS_BCLCTTGT> WITH KEY STROW = GS_DATA_QUARTER-STROW.
      ENDIF.

      " Cộng dồn theo cột Quý
      CASE GS_DATA_QUARTER-QUARTER.
        WHEN 1.
          <FS_BCLCTTGT>-REPVAL_Q1  = <FS_BCLCTTGT>-REPVAL_Q1  + GS_DATA_QUARTER-REPVAL.
          <FS_BCLCTTGT>-COMPVAL_Q1 = <FS_BCLCTTGT>-COMPVAL_Q1 + GS_DATA_QUARTER-COMPVAL.
        WHEN 2.
          <FS_BCLCTTGT>-REPVAL_Q2  = <FS_BCLCTTGT>-REPVAL_Q2  + GS_DATA_QUARTER-REPVAL.
          <FS_BCLCTTGT>-COMPVAL_Q2 = <FS_BCLCTTGT>-COMPVAL_Q2 + GS_DATA_QUARTER-COMPVAL.
        WHEN 3.
          <FS_BCLCTTGT>-REPVAL_Q3  = <FS_BCLCTTGT>-REPVAL_Q3  + GS_DATA_QUARTER-REPVAL.
          <FS_BCLCTTGT>-COMPVAL_Q3 = <FS_BCLCTTGT>-COMPVAL_Q3 + GS_DATA_QUARTER-COMPVAL.
        WHEN 4.
          <FS_BCLCTTGT>-REPVAL_Q4  = <FS_BCLCTTGT>-REPVAL_Q4  + GS_DATA_QUARTER-REPVAL.
          <FS_BCLCTTGT>-COMPVAL_Q4 = <FS_BCLCTTGT>-COMPVAL_Q4 + GS_DATA_QUARTER-COMPVAL.
      ENDCASE.

      <FS_BCLCTTGT>-COMPVAL = <FS_BCLCTTGT>-COMPVAL + GS_DATA_QUARTER-COMPVAL.
      <FS_BCLCTTGT>-REPVAL  = <FS_BCLCTTGT>-REPVAL  + GS_DATA_QUARTER-REPVAL.
    ENDLOOP.

  ELSE.
    "danhdh add end 28.05.2026 13:04:00

    SORT GT_DATA_SYSTEM BY STROW.

    LOOP AT GT_DATA_SYSTEM ASSIGNING  <FS_DATA>.
      LW_COMPVAL = LW_COMPVAL + <FS_DATA>-COMPVAL.
      LW_REPVAL  = LW_REPVAL  + <FS_DATA>-REPVAL.

      AT END OF STROW.
        <FS_DATA>-COMPVAL =  LW_COMPVAL.
        <FS_DATA>-REPVAL  =  LW_REPVAL.
        <FS_DATA>-FLAG    =  'X'.
        CLEAR: LW_COMPVAL, LW_REPVAL.
      ENDAT.

    ENDLOOP.

    DELETE GT_DATA_SYSTEM WHERE FLAG <> 'X'.

    LOOP AT GT_DATA_SYSTEM INTO GS_DATA_SYSTEM.
      AT NEW STROW.
        LW_COMPVAL = 0.
        LW_REPVAL  = 0.
        LW_STROW   = GS_DATA_SYSTEM-STROW.
      ENDAT.

      IF LW_STROW = GS_DATA_SYSTEM-STROW.
        LW_COMPVAL = LW_COMPVAL + GS_DATA_SYSTEM-COMPVAL.
        LW_REPVAL  = LW_REPVAL  + GS_DATA_SYSTEM-REPVAL.
      ENDIF.

      GS_DATA_SYSTEM-COMPVAL = LW_COMPVAL.
      GS_DATA_SYSTEM-REPVAL  = LW_REPVAL.

      MOVE-CORRESPONDING GS_DATA_SYSTEM TO GS_BCLCTTGT.
      APPEND GS_BCLCTTGT TO GT_BCLCTTGT.
      CLEAR: GS_BCLCTTGT.
    ENDLOOP.

  ENDIF. "danhdh add 28.05.2026 13:06:49


  " Sort Output Data
  SORT GT_BCLCTTGT BY STROW.
  LOOP AT GT_BCLCTTGT ASSIGNING <FS_BCLCTTGT>. "INTO GS_BCLCTTGT.
    AT END OF STROW.
      LW_FLAG = 'X'.
    ENDAT.
    " If STROW = '001', '201', '301' => Update Null For STROW
    IF <FS_BCLCTTGT>-STROW = '001' OR <FS_BCLCTTGT>-STROW = '201' OR <FS_BCLCTTGT>-STROW = '301'  OR <FS_BCLCTTGT>-STROW = '019'.
      <FS_BCLCTTGT>-STROW = ''.
    ENDIF.
    " Update STROW = STROW+2(2)
    <FS_BCLCTTGT>-STROW = <FS_BCLCTTGT>-STROW+2(2).
    <FS_BCLCTTGT>-FLAG = LW_FLAG.
    CLEAR LW_FLAG.

    " XU LY DISPLAY NUMBER
    " Chia cho P_SCAL
    IF P_SCAL1 EQ 'X'.
      <FS_BCLCTTGT>-REPVAL = <FS_BCLCTTGT>-REPVAL / 1.
      <FS_BCLCTTGT>-COMPVAL = <FS_BCLCTTGT>-COMPVAL / 1.

      "danhdh add begin 28.05.2026 13:07:11
      IF GW_EX EQ 'X'.
        <FS_BCLCTTGT>-REPVAL_Q1 = <FS_BCLCTTGT>-REPVAL_Q1 / 1. <FS_BCLCTTGT>-COMPVAL_Q1 = <FS_BCLCTTGT>-COMPVAL_Q1 / 1.
        <FS_BCLCTTGT>-REPVAL_Q2 = <FS_BCLCTTGT>-REPVAL_Q2 / 1. <FS_BCLCTTGT>-COMPVAL_Q2 = <FS_BCLCTTGT>-COMPVAL_Q2 / 1.
        <FS_BCLCTTGT>-REPVAL_Q3 = <FS_BCLCTTGT>-REPVAL_Q3 / 1. <FS_BCLCTTGT>-COMPVAL_Q3 = <FS_BCLCTTGT>-COMPVAL_Q3 / 1.
        <FS_BCLCTTGT>-REPVAL_Q4 = <FS_BCLCTTGT>-REPVAL_Q4 / 1. <FS_BCLCTTGT>-COMPVAL_Q4 = <FS_BCLCTTGT>-COMPVAL_Q4 / 1.
      ENDIF.
      "danhdh add end 28.05.2026 13:07:11

    ELSEIF P_SCAL2 EQ 'X'.
      <FS_BCLCTTGT>-REPVAL = <FS_BCLCTTGT>-REPVAL / 1000.
      <FS_BCLCTTGT>-COMPVAL = <FS_BCLCTTGT>-COMPVAL / 1000.


      "danhdh add begin 28.05.2026 13:07:36
      IF GW_EX EQ 'X'.
        <FS_BCLCTTGT>-REPVAL_Q1 = <FS_BCLCTTGT>-REPVAL_Q1 / 1000. <FS_BCLCTTGT>-COMPVAL_Q1 = <FS_BCLCTTGT>-COMPVAL_Q1 / 1000.
        <FS_BCLCTTGT>-REPVAL_Q2 = <FS_BCLCTTGT>-REPVAL_Q2 / 1000. <FS_BCLCTTGT>-COMPVAL_Q2 = <FS_BCLCTTGT>-COMPVAL_Q2 / 1000.
        <FS_BCLCTTGT>-REPVAL_Q3 = <FS_BCLCTTGT>-REPVAL_Q3 / 1000. <FS_BCLCTTGT>-COMPVAL_Q3 = <FS_BCLCTTGT>-COMPVAL_Q3 / 1000.
        <FS_BCLCTTGT>-REPVAL_Q4 = <FS_BCLCTTGT>-REPVAL_Q4 / 1000. <FS_BCLCTTGT>-COMPVAL_Q4 = <FS_BCLCTTGT>-COMPVAL_Q4 / 1000.
      ENDIF.
      "danhdh add end 28.05.2026 13:07:36

    ELSEIF P_SCAL3 EQ 'X'.
      <FS_BCLCTTGT>-REPVAL = <FS_BCLCTTGT>-REPVAL / 1000000.
      <FS_BCLCTTGT>-COMPVAL = <FS_BCLCTTGT>-COMPVAL / 1000000.

      "danhdh add begin 28.05.2026 13:09:04
      IF GW_EX EQ 'X'.
        <FS_BCLCTTGT>-REPVAL_Q1 = <FS_BCLCTTGT>-REPVAL_Q1 / 1000000. <FS_BCLCTTGT>-COMPVAL_Q1 = <FS_BCLCTTGT>-COMPVAL_Q1 / 1000000.
        <FS_BCLCTTGT>-REPVAL_Q2 = <FS_BCLCTTGT>-REPVAL_Q2 / 1000000. <FS_BCLCTTGT>-COMPVAL_Q2 = <FS_BCLCTTGT>-COMPVAL_Q2 / 1000000.
        <FS_BCLCTTGT>-REPVAL_Q3 = <FS_BCLCTTGT>-REPVAL_Q3 / 1000000. <FS_BCLCTTGT>-COMPVAL_Q3 = <FS_BCLCTTGT>-COMPVAL_Q3 / 1000000.
        <FS_BCLCTTGT>-REPVAL_Q4 = <FS_BCLCTTGT>-REPVAL_Q4 / 1000000. <FS_BCLCTTGT>-COMPVAL_Q4 = <FS_BCLCTTGT>-COMPVAL_Q4 / 1000000.
      ENDIF.
      "danhdh add end 28.05.2026 13:09:04

    ENDIF.



    " Chuyen so am thanh dang (value)
    CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER'
      EXPORTING
        I_DMBTR = <FS_BCLCTTGT>-REPVAL
        I_CURR  = 'VND'
      IMPORTING
        E_DMBTR = <FS_BCLCTTGT>-C_REPVAL.
    CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER'
      EXPORTING
        I_DMBTR = <FS_BCLCTTGT>-COMPVAL
        I_CURR  = 'VND'
      IMPORTING
        E_DMBTR = <FS_BCLCTTGT>-C_COMPVAL.


    "danhdh add begin 28.05.2026 13:10:47
    IF GW_EX EQ 'X'.
      CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER' EXPORTING I_DMBTR = <FS_BCLCTTGT>-REPVAL_Q1 IMPORTING E_DMBTR = <FS_BCLCTTGT>-C_REPVAL_Q1.
      CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER' EXPORTING I_DMBTR = <FS_BCLCTTGT>-REPVAL_Q2 IMPORTING E_DMBTR = <FS_BCLCTTGT>-C_REPVAL_Q2.
      CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER' EXPORTING I_DMBTR = <FS_BCLCTTGT>-REPVAL_Q3 IMPORTING E_DMBTR = <FS_BCLCTTGT>-C_REPVAL_Q3.
      CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER' EXPORTING I_DMBTR = <FS_BCLCTTGT>-REPVAL_Q4 IMPORTING E_DMBTR = <FS_BCLCTTGT>-C_REPVAL_Q4.

      CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER' EXPORTING I_DMBTR = <FS_BCLCTTGT>-COMPVAL_Q1 IMPORTING E_DMBTR = <FS_BCLCTTGT>-C_COMPVAL_Q1.
      CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER' EXPORTING I_DMBTR = <FS_BCLCTTGT>-COMPVAL_Q2 IMPORTING E_DMBTR = <FS_BCLCTTGT>-C_COMPVAL_Q2.
      CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER' EXPORTING I_DMBTR = <FS_BCLCTTGT>-COMPVAL_Q3 IMPORTING E_DMBTR = <FS_BCLCTTGT>-C_COMPVAL_Q3.
      CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER' EXPORTING I_DMBTR = <FS_BCLCTTGT>-COMPVAL_Q4 IMPORTING E_DMBTR = <FS_BCLCTTGT>-C_COMPVAL_Q4.
    ENDIF.
    "danhdh add end 28.05.2026 13:10:47


    " Nhan cho 100 de xuat excel
    IF GW_EX EQ 'X'.
      <FS_BCLCTTGT>-REPVAL  = <FS_BCLCTTGT>-REPVAL  * 100.
      <FS_BCLCTTGT>-COMPVAL = <FS_BCLCTTGT>-COMPVAL * 100.

      "danhdh add begin 28.05.2026 13:11:02
      <FS_BCLCTTGT>-REPVAL_Q1 = <FS_BCLCTTGT>-REPVAL_Q1 * 100. <FS_BCLCTTGT>-COMPVAL_Q1 = <FS_BCLCTTGT>-COMPVAL_Q1 * 100.
      <FS_BCLCTTGT>-REPVAL_Q2 = <FS_BCLCTTGT>-REPVAL_Q2 * 100. <FS_BCLCTTGT>-COMPVAL_Q2 = <FS_BCLCTTGT>-COMPVAL_Q2 * 100.
      <FS_BCLCTTGT>-REPVAL_Q3 = <FS_BCLCTTGT>-REPVAL_Q3 * 100. <FS_BCLCTTGT>-COMPVAL_Q3 = <FS_BCLCTTGT>-COMPVAL_Q3 * 100.
      <FS_BCLCTTGT>-REPVAL_Q4 = <FS_BCLCTTGT>-REPVAL_Q4 * 100. <FS_BCLCTTGT>-COMPVAL_Q4 = <FS_BCLCTTGT>-COMPVAL_Q4 * 100.
      "danhdh add end 28.05.2026 13:11:02

    ENDIF.

  ENDLOOP.

  DELETE GT_BCLCTTGT WHERE FLAG <> 'X'.
ENDFORM.                    " DATA_PROCESSING
*&---------------------------------------------------------------------*
*&      Form  EXPORT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM EXPORT_DATA .
*  IF GW_SF EQ 'X'.
*    PERFORM EXPORT_SMARTFORMS.
*  ELSEIF GW_EX EQ 'X'.
  IF GW_EX EQ 'X'.
    CONCATENATE 'MST:' GS_PARAMETER-TAX '- ÐT: ' GS_PARAMETER-TEL_NUMBER '- Fax:' GS_PARAMETER-FAX_NUMBER INTO GS_PARAMETER-TAX SEPARATED BY SPACE.
    PERFORM EXPORT_EXCEL.
  ENDIF.
ENDFORM.                    " EXPORT_DATA
*&---------------------------------------------------------------------*
*&      Form  CONVERT_NUMBER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CONVERT_NUMBER .
  DATA: LW_INDEX      TYPE INT4.

  LOOP AT GT_BCLCTTGT INTO GS_BCLCTTGT.

    LW_INDEX = SY-TABIX.

    " Chia cho P_SCAL
    IF P_SCAL1 EQ 'X'.
      GS_BCLCTTGT-REPVAL = GS_BCLCTTGT-REPVAL / 1.
      GS_BCLCTTGT-COMPVAL = GS_BCLCTTGT-COMPVAL / 1.
    ELSEIF P_SCAL2 EQ 'X'.
      GS_BCLCTTGT-REPVAL = GS_BCLCTTGT-REPVAL / 1000.
      GS_BCLCTTGT-COMPVAL = GS_BCLCTTGT-COMPVAL / 1000.
    ELSEIF P_SCAL3 EQ 'X'.
      GS_BCLCTTGT-REPVAL = GS_BCLCTTGT-REPVAL / 1000000.
      GS_BCLCTTGT-COMPVAL = GS_BCLCTTGT-COMPVAL / 1000000.
    ENDIF.

    " Chuyen so am thanh dang (value)
    CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER'
      EXPORTING
        I_DMBTR = GS_BCLCTTGT-REPVAL
        I_CURR  = 'VND'
      IMPORTING
        E_DMBTR = GS_BCLCTTGT-C_REPVAL.
    CALL FUNCTION 'ZCORE_FM_CONVERT_NUMBER'
      EXPORTING
        I_DMBTR = GS_BCLCTTGT-COMPVAL
        I_CURR  = 'VND'
      IMPORTING
        E_DMBTR = GS_BCLCTTGT-C_COMPVAL.

    " Nhan cho 100 de xuat excel
    GS_BCLCTTGT-REPVAL  = GS_BCLCTTGT-REPVAL  * 100.
    GS_BCLCTTGT-COMPVAL = GS_BCLCTTGT-COMPVAL * 100.

    " Modify
    MODIFY GT_BCLCTTGT FROM GS_BCLCTTGT INDEX LW_INDEX
           TRANSPORTING REPVAL COMPVAL C_REPVAL C_COMPVAL.

  ENDLOOP.
ENDFORM.                    " CONVERT_NUMBER
*&---------------------------------------------------------------------*
*&      Form  EXPORT_EXCEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM EXPORT_EXCEL .
  CALL FUNCTION 'ZCORE_FM_EXPORT_EXCEL_XML'
    EXPORTING
*     REPORT_NAME     = 'ZFI_PG_BCLCTTGT'
*     REPORT_NAME     = 'ZFI_PG_BCLCTTGT_ZGL11' "danhdh add 28.05.2026 14:56:11
*     REPORT_NAME     = 'ZFI_PG_BCLCTTGT_ZGL11_1' "danhdh add 29.05.2026 14:56:11
      REPORT_NAME     = 'ZFI_PG_BCLCTTGT_ZGL12' "danhdh add 03.06.2026 11:52:17
      STRUCT_NAME     = 'ZFI_ST_GL_BCLCTTGT'
      IW_PARAMETER    = GS_PARAMETER
      FIELD_COMPARE   = 'GROUP'
    TABLES
      IT_TABLE_DETAIL = GT_BCLCTTGT.
ENDFORM.                    " EXPORT_EXCEL
*&---------------------------------------------------------------------*
*&      Form  EXPORT_SMARTFORMS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM EXPORT_SMARTFORMS .
*  DATA: P_FORM  TYPE TDSFNAME VALUE 'ZFI_SF_GL_BCLCTTGT',
*        FM_NAME TYPE RS38L_FNAM.
*  DATA : WA_CPARAM          TYPE SSFCTRLOP,
*         WA_OUTPUT          TYPE SSFCOMPOP,
*         WA_JOB_OUTPUT_INFO TYPE SSFCRESCL.
*
*  WA_CPARAM-NO_DIALOG = 'X'.
*  WA_CPARAM-PREVIEW   = 'X'.
*  WA_OUTPUT-TDDEST    = 'LP01'.
*  WA_OUTPUT-TDNOPREV  = 'X'.
*  WA_OUTPUT-TDIMMED   = 'X'.
*  WA_OUTPUT-TDDELETE  = 'X'.
*
*  CALL FUNCTION 'SSF_OPEN'
*    EXPORTING
*      CONTROL_PARAMETERS = WA_CPARAM
*      OUTPUT_OPTIONS     = WA_OUTPUT
*      USER_SETTINGS      = SPACE
*    EXCEPTIONS
*      FORMATTING_ERROR   = 1
*      INTERNAL_ERROR     = 2
*      SEND_ERROR         = 3
*      USER_CANCELED      = 4
*      OTHERS             = 5.
*
*  IF SY-SUBRC <> 0.
*    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.
*
*  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
*    EXPORTING
*      FORMNAME           = P_FORM
*    IMPORTING
*      FM_NAME            = FM_NAME
*    EXCEPTIONS
*      NO_FORM            = 1
*      NO_FUNCTION_MODULE = 2
*      OTHERS             = 3.
*  IF SY-SUBRC <> 0.
*    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*    EXIT.
*  ENDIF.
*
*  WA_CPARAM-NO_OPEN       = 'X'.
*  WA_CPARAM-NO_CLOSE      = 'X'.
*
**  LOOP AT GT_BCLCTTGT WHERE BUKRS IN S_BUKRS.
*
*  IF P_VND = 'X'.
*    LOOP AT GT_BCLCTTGT INTO GS_BCLCTTGT .
*      REPLACE ALL OCCURRENCES OF ',' IN GS_BCLCTTGT-C_REPVAL  WITH '#'.
*      REPLACE ALL OCCURRENCES OF '.' IN GS_BCLCTTGT-C_REPVAL   WITH ','.
*      REPLACE ALL OCCURRENCES OF '#' IN GS_BCLCTTGT-C_REPVAL   WITH '.'.
*
*      REPLACE ALL OCCURRENCES OF ',' IN GS_BCLCTTGT-C_COMPVAL  WITH '#'.
*      REPLACE ALL OCCURRENCES OF '.' IN GS_BCLCTTGT-C_COMPVAL   WITH ','.
*      REPLACE ALL OCCURRENCES OF '#' IN GS_BCLCTTGT-C_COMPVAL   WITH '.'.
*
*      MODIFY GT_BCLCTTGT FROM GS_BCLCTTGT.
*    ENDLOOP.
*  ENDIF.
*
*  CALL FUNCTION FM_NAME
*    EXPORTING
*      CONTROL_PARAMETERS = WA_CPARAM
*      OUTPUT_OPTIONS     = WA_OUTPUT
*      USER_SETTINGS      = SPACE
*      GS_PARAMETER       = GS_PARAMETER
*    TABLES
*      IT_TABLE           = GT_BCLCTTGT
*    EXCEPTIONS
*      FORMATTING_ERROR   = 1
*      INTERNAL_ERROR     = 2
*      SEND_ERROR         = 3
*      USER_CANCELED      = 4
*      OTHERS             = 5.
*
*  IF SY-SUBRC <> 0.
*    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.
*  CLEAR: GT_BCLCTTGT[], GT_BCLCTTGT.
*
**  ENDLOOP.
*
*  CALL FUNCTION 'SSF_CLOSE'
*    IMPORTING
*      JOB_OUTPUT_INFO  = WA_JOB_OUTPUT_INFO
*    EXCEPTIONS
*      FORMATTING_ERROR = 1
*      INTERNAL_ERROR   = 2
*      SEND_ERROR       = 3
*      OTHERS           = 4.
*  IF SY-SUBRC <> 0.
*    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.
*ENDFORM.                    " EXPORT_SMARTFORMS
**&---------------------------------------------------------------------*
**& Form SET_SCREEN
**&---------------------------------------------------------------------*
FORM SET_SCREEN .
*  LOOP AT SCREEN.
*    IF P_TYPE_S IS INITIAL.
*      IF SCREEN-GROUP1 = 'MD2'.
*        SCREEN-INVISIBLE = 1.
*        SCREEN-INPUT = 0.
*      ENDIF.
*      IF SCREEN-GROUP1 = 'MD1'.
*        SCREEN-ACTIVE = 1.
*      ENDIF.
*    ELSE.
*      IF SCREEN-GROUP1 = 'MD1'.
*        SCREEN-INVISIBLE = 1.
*        SCREEN-INPUT = 0.
*      ENDIF.
*      IF SCREEN-GROUP1 = 'MD2'.
*        SCREEN-ACTIVE = 1.
*      ENDIF.
*    ENDIF.
*    MODIFY SCREEN.
*  ENDLOOP.

  LOOP AT SCREEN.
    IF SCREEN-GROUP1 = 'MD2'.
      SCREEN-INVISIBLE = 1.
      SCREEN-INPUT = 0.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DESCRIPTION_PERIOD
*&---------------------------------------------------------------------*
FORM GET_DESCRIPTION_PERIOD  USING    LW_LANGUAGE
                             CHANGING P_RESULT TYPE CHAR255.
  IF S_PER-LOW = 1 AND S_PER-HIGH - S_PER-LOW + 1 = 9.
    P_RESULT = COND #( WHEN LW_LANGUAGE = 'VI' THEN |Chín tháng đầu năm { P_BUPEJ }|
                       WHEN LW_LANGUAGE = 'EN' THEN |The first nine months of year { P_BUPEJ }| ).
  ELSE.
    P_RESULT = COND #( WHEN LW_LANGUAGE = 'VI' THEN |Tháng { S_PER-LOW } tới tháng { S_PER-HIGH } năm { P_BUPEJ }|
                       WHEN LW_LANGUAGE = 'EN' THEN |From { S_PER-LOW } to { S_PER-HIGH } of year { P_BUPEJ }| ).
  ENDIF.
ENDFORM.

*
*
