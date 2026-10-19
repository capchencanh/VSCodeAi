**************************************************************************
*   Method attributes.                                                   *
**************************************************************************
*  Instantiation: Public
**************************************************************************

  METHOD IF_EX_MB_MIGO_BADI~POST_DOCUMENT.
    " - Hiện trạng: Chuẩn hệ thống SAP ở Tcode MIGO cho phép post thiếu số lượng reservation
    " - Yêu cầu: Không cho phép post thiếu số lượng của Reservation trên MIGO
    " - Mô tả: • Vào Tcode MIGO -> Chọn Transaction/ Event: Good Receipt/ Good Issue/ Transfer Posting có tham chiếu tới Reservation.
    "          • Nếu người dùng nhập số lượng giao dịch nhỏ hơn số lượng trên Reservation thì thông báo lỗi.
    " - Create on: 17.01.2024
    " - Create by: hieunpt
    TYPES:
      BEGIN OF LTY_MSEG,
        RSNUM TYPE RSNUM,
        RSPOS TYPE RSPOS,
        MATNR TYPE MATNR,
        XAUTO TYPE XAUTO,
        ERFME TYPE ERFME,
        ERFMG TYPE ERFMG,
        BWART TYPE BWART,
      END OF LTY_MSEG.

    DATA: LT_MSEG      TYPE TABLE OF LTY_MSEG,
          LV_MENGE_IN  TYPE MENGE_D,
          LV_MENGE_OUT TYPE MENGE_D.

    FIELD-SYMBOLS <LFS_GODYNPRO> TYPE GODYNPRO.

    ASSIGN ('(SAPLMIGO)GODYNPRO') TO <LFS_GODYNPRO>.
    IF <LFS_GODYNPRO> IS ASSIGNED.
      IF (    <LFS_GODYNPRO>-ACTION = 'A01'
           OR <LFS_GODYNPRO>-ACTION = 'A07'
           OR <LFS_GODYNPRO>-ACTION = 'A08' ) AND <LFS_GODYNPRO>-REFDOC = 'R09'.

        MOVE-CORRESPONDING IT_MSEG TO LT_MSEG.
        DELETE LT_MSEG WHERE XAUTO = 'X'.

        LOOP AT LT_MSEG INTO DATA(LS_MSEG).
          DATA(LS_MSEG_TMP) = LS_MSEG.

          AT END OF RSPOS.
            SUM.
            LS_MSEG_TMP-ERFMG = LS_MSEG-ERFMG.
            SELECT SINGLE BDMNG, MEINS FROM RESB
              INTO ( @DATA(LV_BDMNG), @DATA(LV_MEINS) )
              WHERE RSNUM = @LS_MSEG_TMP-RSNUM
                AND RSPOS = @LS_MSEG_TMP-RSPOS.
            IF SY-SUBRC = 0.
              LV_MENGE_IN = LS_MSEG_TMP-ERFMG.
              CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
                EXPORTING
                  I_MATNR              = LS_MSEG_TMP-MATNR
                  I_IN_ME              = LS_MSEG_TMP-ERFME
                  I_OUT_ME             = LV_MEINS
                  I_MENGE              = LV_MENGE_IN
                IMPORTING
                  E_MENGE              = LV_MENGE_OUT
                EXCEPTIONS
                  ERROR_IN_APPLICATION = 1
                  ERROR                = 2
                  OTHERS               = 3.
              IF SY-SUBRC = 0 AND LV_MENGE_OUT < LV_BDMNG.
                ROLLBACK WORK.
                MESSAGE 'Số lượng của giao dịch nhỏ hơn số lượng trên Reservation, vui lòng kiểm tra lại!' TYPE 'E'.
              ENDIF.
              CLEAR: LV_MENGE_IN, LV_MENGE_OUT.
            ENDIF.
          ENDAT.
        ENDLOOP.
      ELSEIF <LFS_GODYNPRO>-ACTION = 'A03'.
        DATA(LW_AUTH_FLAG) = ABAP_FALSE.
        MOVE-CORRESPONDING IT_MSEG TO LT_MSEG.
        SELECT *
          FROM ZTB_CANC_CW
          WHERE USER_NAME EQ @SY-UNAME
          INTO TABLE @DATA(LT_USER).
        IF SY-SUBRC EQ 0.
          LW_AUTH_FLAG = ABAP_TRUE.
        ENDIF.

        LOOP AT LT_MSEG INTO LS_MSEG.
          IF ( LS_MSEG-BWART EQ 'Y33' OR LS_MSEG-BWART EQ 'Y24' )
             AND LW_AUTH_FLAG = ABAP_FALSE.
            ROLLBACK WORK.
            MESSAGE |User chưa được phân quyền để hủy Mat.Doc voi với Movement Type { LS_MSEG-BWART }| TYPE 'E'.
          ENDIF.
        ENDLOOP.

      ENDIF.
      UNASSIGN <LFS_GODYNPRO>.
    ENDIF.
  ENDMETHOD.

*
* 
