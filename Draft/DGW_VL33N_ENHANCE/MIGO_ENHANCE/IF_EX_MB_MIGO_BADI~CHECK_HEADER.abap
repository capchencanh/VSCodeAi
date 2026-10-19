  METHOD IF_EX_MB_MIGO_BADI~CHECK_HEADER.
    FIELD-SYMBOLS <LFS_GODYNPRO> TYPE GODYNPRO.
    FIELD-SYMBOLS <LFS_GOHEAD>   TYPE GOHEAD.
    DATA LS_BAPIRET2 TYPE BAPIRET2.

    ASSIGN ('(SAPLMIGO)GODYNPRO') TO <LFS_GODYNPRO>.
    IF <LFS_GODYNPRO> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    IF     <LFS_GODYNPRO>-ACTION = 'A01'
       AND <LFS_GODYNPRO>-REFDOC = 'R04'.
      ASSIGN ('(SAPLMIGO)GOHEAD') TO <LFS_GOHEAD>.
      IF <LFS_GOHEAD> IS ASSIGNED.
        "KhoaLD comment begin 05.06.2026 15:17:34
*        " Get delivery XBLNR
*        SELECT SINGLE VBELN
*        " TODO: variable is assigned but never used (ABAP cleaner)
*          INTO @DATA(LW_VBELN)
*          FROM LIKP
*          WHERE VBELN     = @<LFS_GOHEAD>-XBLNR
*            AND ZZAPPROVE = @ABAP_TRUE.
*        " Kiểm tra đã duyệt hay chưa?
*        IF SY-SUBRC <> 0.
*          " Kiểm tra PO type bắt buộc duyệt?
*          SELECT SINGLE REL~BSART
*          " TODO: variable is assigned but never used (ABAP cleaner)
*            INTO @DATA(LW_BSART)
*            FROM ZINB_TB_RELEASE AS REL
*                   INNER JOIN
*                     EKKO ON EKKO~BSART = REL~BSART
*                       INNER JOIN
*                         LIPS ON LIPS~VGBEL = EKKO~EBELN
*            WHERE LIPS~VBELN = @<LFS_GOHEAD>-XBLNR.
*          IF SY-SUBRC = 0.
*            LS_BAPIRET2-ID         = 'ZMC_DGW'.
*            LS_BAPIRET2-NUMBER     = '003'.
*            LS_BAPIRET2-TYPE       = 'E'.
*            LS_BAPIRET2-MESSAGE_V1 = <LFS_GOHEAD>-XBLNR.
*            APPEND LS_BAPIRET2 TO ET_BAPIRET2.
*          ENDIF.
*        ENDIF.
        "KhoaLD comment end 05.06.2026 15:17:34

        "danhdh add begin 25.05.2026 09:19:51
        "2.12 Enhancement 12: Chặn nhập kho đối với Inbound chưa duyệt
*        IF ET_BAPIRET2 IS INITIAL.
          FIELD-SYMBOLS: <LFS_GOITEM> TYPE GOITEM.
          ASSIGN ('(SAPLMIGO)GOITEM') TO <LFS_GOITEM>.

          IF <LFS_GOITEM> IS ASSIGNED AND <LFS_GOHEAD>-XBLNR IS NOT INITIAL.      "KhoaLD add 05.06.2026 15:17:56   --> change <LFS_GOITEM>-VLIEF_AVIS ==> <LFS_GOHEAD>-XBLNR
            SELECT SINGLE MAP~ZZREL_CODE
            FROM LIPS
              INNER JOIN EKPO ON EKPO~EBELN = LIPS~VGBEL
              INNER JOIN EKKO ON EKKO~EBELN = EKPO~EBELN
              INNER JOIN ZMM_TB_MAP_VL06I AS MAP ON MAP~BSART = EKKO~BSART
            WHERE LIPS~VBELN = @<LFS_GOHEAD>-XBLNR  " change <LFS_GOITEM>-VLIEF_AVIS ==> <LFS_GOHEAD>-XBLNR "danhdh add 25.08.2026 13:33:54
            INTO @DATA(LV_REL_CODE).

            IF SY-SUBRC = 0.
              SELECT SINGLE ZZRL_CHUYENKT, ZZAPPROVE
              INTO (@DATA(LV_ZZRL), @DATA(LV_ZZAP))
              FROM LIKP
              WHERE VBELN = @<LFS_GOHEAD>-XBLNR . " change <LFS_GOITEM>-VLIEF_AVIS ==> <LFS_GOHEAD>-XBLNR "danhdh add 25.08.2026 13:33:54

              CASE LV_REL_CODE.
                WHEN '1'.
                  IF LV_ZZAP IS INITIAL.
                    LS_BAPIRET2-ID         = 'ZMC_DGW'.
                    LS_BAPIRET2-NUMBER     = '003'.
                    LS_BAPIRET2-TYPE       = 'E'.
                    LS_BAPIRET2-MESSAGE_V1 = <LFS_GOHEAD>-XBLNR . "change <LFS_GOITEM>-VLIEF_AVIS ==> <LFS_GOHEAD>-XBLNR "danhdh add 25.08.2026 13:33:59
                    APPEND LS_BAPIRET2 TO ET_BAPIRET2.
                  ENDIF.

                WHEN '2'.
                  IF LV_ZZRL IS INITIAL OR LV_ZZAP IS INITIAL.
                    LS_BAPIRET2-ID         = 'ZMC_DGW'.
                    LS_BAPIRET2-NUMBER     = '045'.
                    LS_BAPIRET2-TYPE       = 'E'.
                    LS_BAPIRET2-MESSAGE_V1 = <LFS_GOHEAD>-XBLNR . "change <LFS_GOITEM>-VLIEF_AVIS ==> <LFS_GOHEAD>-XBLNR "danhdh add 25.08.2026 13:34:08
                    APPEND LS_BAPIRET2 TO ET_BAPIRET2.
                  ENDIF.

                WHEN OTHERS.
              ENDCASE.
            ENDIF.
          ENDIF.

*        ENDIF.
        "danhdh add end 25.05.2026 09:19:51

        UNASSIGN <LFS_GOHEAD>.
      ENDIF.
    ENDIF.

* Enhance chặn reverse chứng từ nếu có Posting Date khác ngày hiện tại
* CuongHC 1.1.2025
    IF <LFS_GODYNPRO>-ACTION = 'A03'
         AND <LFS_GODYNPRO>-REFDOC = 'R02'.
      ASSIGN ('(SAPLMIGO)GOHEAD') TO <LFS_GOHEAD>.
      IF <LFS_GOHEAD> IS ASSIGNED AND <LFS_GOHEAD>-BUDAT <> SY-DATUM.
        LS_BAPIRET2-ID         = 'ZMC_DGW'.
        LS_BAPIRET2-NUMBER     = '039'.
        LS_BAPIRET2-TYPE       = 'E'.
        APPEND LS_BAPIRET2 TO ET_BAPIRET2.
      ENDIF.
      UNASSIGN <LFS_GOHEAD>.
    ENDIF.

    UNASSIGN <LFS_GODYNPRO>.
  ENDMETHOD.