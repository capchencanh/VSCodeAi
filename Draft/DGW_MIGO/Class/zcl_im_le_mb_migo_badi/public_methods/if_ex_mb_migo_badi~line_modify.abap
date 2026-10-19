**************************************************************************
*   Method attributes.                                                   *
**************************************************************************
*  Instantiation: Public
**************************************************************************

  METHOD IF_EX_MB_MIGO_BADI~LINE_MODIFY.
    " Không cho phép cancellation material document reversed
    DATA LS_MSEG    TYPE MSEG.
    DATA LV_MBLNR   LIKE LS_MSEG-SMBLN.
    DATA LV_SMBLN   LIKE LS_MSEG-SMBLN.
    DATA LW_CUSNAME TYPE CHAR255.

    CHECK CS_GOITEM-SMBLN = CS_GOITEM-MBLNR.

    LV_MBLNR = CS_GOITEM-MBLNR.

    SELECT SINGLE SMBLN INTO LV_SMBLN
      FROM MSEG
      WHERE MBLNR = LV_MBLNR.

    IF LV_SMBLN IS NOT INITIAL.
      MESSAGE S020(ZMC_CTK) WITH LV_MBLNR DISPLAY LIKE 'E'.
      LEAVE SCREEN.
    ENDIF.
    " ---------------------------------------------------------------------------
    " Mapping Customer from ZMB21
    " ---------------------------------------------------------------------------
    " IF  CS_GOITEM-MBLNR IS INITIAL
    " AND CS_GOITEM-RSNUM IS NOT INITIAL.
    "   SELECT SINGLE
    "     RESB~MATNR        ,
    "     RESB~CHARG        ,
    "     RESB~SOBKZ        ,
    "     RESB~ZZKUNNR
    "     FROM RESB
    "     WHERE RSNUM = @CS_GOITEM-RSNUM
    "       AND RSPOS = @CS_GOITEM-RSPOS
    "   INTO @DATA(LS_RESB).
    "   IF SY-SUBRC = 0.
    "     "Customer
    "     IF ( CS_GOITEM-SOBKZ = 'B' OR CS_GOITEM-SOBKZ = 'W' )
    "        AND CS_GOITEM-KUNNR IS INITIAL.
    "       CS_GOITEM-KUNNR       = LS_RESB-ZZKUNNR.
    "       CS_GOITEM-UMMAT_KUNNR = CS_GOITEM-KUNNR.
    "
    "       CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
    "         EXPORTING
    "           I_NUMBER = CS_GOITEM-KUNNR
    "           I_KIND   = 'D'
    "         IMPORTING
    "           E_NAME1  = LW_CUSNAME.
    "       CS_GOITEM-CUSTNAME = LW_CUSNAME.
    "     ENDIF.
    "   ENDIF.
    " ENDIF.

    " 25.11.2023
    IF     CS_GOITEM-MBLNR IS INITIAL
       AND CS_GOITEM-RSNUM IS NOT INITIAL.

      SELECT SINGLE RESB~MATNR,
                    RESB~CHARG,
                    RESB~Z_KDAUF_R,
                    RESB~Z_KDPOS_R,
                    RESB~Z_MOVE_MAT,
                    RESB~Z_MOVE_BATCH,
                    RESB~Z_BWTAR,
                    RESB~SOBKZ,
                    RESB~ZzKUNNR,
                    RESB~Z_EXBWR,
                    RESB~BWART
        FROM RESB
        WHERE RSNUM = @CS_GOITEM-RSNUM
          AND RSPOS = @CS_GOITEM-RSPOS
        INTO @DATA(LS_RESB).
      IF SY-SUBRC <> 0.
        RETURN.
      ENDIF.

      " Customer
      IF ( CS_GOITEM-SOBKZ = 'B' OR CS_GOITEM-SOBKZ = 'W' )
         AND CS_GOITEM-KUNNR IS INITIAL.
        CS_GOITEM-KUNNR       = LS_RESB-ZzKUNNR.
        CS_GOITEM-UMMAT_KUNNR = CS_GOITEM-KUNNR.

        CALL FUNCTION 'ZCORE_FM_GET_PROFILE'
          EXPORTING
            I_NUMBER = CS_GOITEM-KUNNR
            I_KIND   = 'D'
          IMPORTING
            E_NAME1  = LW_CUSNAME.
        CS_GOITEM-CUSTNAME = LW_CUSNAME.
      ENDIF.

      " Valuation Type
      IF CS_GOITEM-BWTAR IS INITIAL.
        CS_GOITEM-BWTAR = LS_RESB-Z_BWTAR.
      ENDIF.
      IF CS_GOITEM-UMBAR IS INITIAL.
        CS_GOITEM-UMBAR = LS_RESB-Z_BWTAR.
      ENDIF.

      IF CS_GOITEM-BWART = '309'. " Chuyển CHARG
        IF LS_RESB-Z_MOVE_BATCH IS NOT INITIAL.
          CS_GOITEM-UMCHA = LS_RESB-Z_MOVE_BATCH.
        ENDIF.

      ELSEIF CS_GOITEM-BWART = 'Z42'.
        IF LS_RESB-ZzKUNNR IS NOT INITIAL.
          CS_GOITEM-KUNNR = LS_RESB-ZzKUNNR.
        ENDIF.
*        IF SY-UNAME = 'CT.ABAP'.
*          BREAK-POINT.
*        ENDIF.
        IF LS_RESB-Z_MOVE_MAT IS NOT INITIAL.
          CS_GOITEM-UMMAT = LS_RESB-Z_MOVE_MAT.
        ENDIF.

        IF LS_RESB-Z_MOVE_BATCH IS NOT INITIAL.
          CS_GOITEM-UMCHA = LS_RESB-Z_MOVE_BATCH.
        ENDIF.
      ENDIF.

      IF LS_RESB-Z_EXBWR IS NOT INITIAL.
        SELECT SINGLE
          T156~BUSTR
        FROM T156
          WHERE T156~BWART = @LS_RESB-BWART
        INTO @DATA(LS_BUSTR).

        IF SY-SUBRC = 0 AND LS_BUSTR = '501'.
          CS_GOITEM-EXBWR = LS_RESB-Z_EXBWR.
        ENDIF.
      ENDIF.



    ENDIF.

    " DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926 CS.DuyHTK Add Begin 14.09.2026 16:06:01
    DATA ls_tp_line TYPE zst_tp_migo_line.

  ls_tp_line-line_id = i_line_id.
  ls_tp_line-bwart   = cs_goitem-bwart.

  READ TABLE mt_tp_line TRANSPORTING NO FIELDS
       WITH TABLE KEY line_id = ls_tp_line-line_id.
  IF sy-subrc = 0.
    MODIFY TABLE mt_tp_line FROM ls_tp_line.
  ELSE.
    INSERT ls_tp_line INTO TABLE mt_tp_line.
  ENDIF.

    " DGW_CR 10.2026 Triển khai CR Chặn nhập xuất kho không tham chiếu chứng từ #34926 CS.DuyHTK Add End 14.09.2026 16:06:01

  ENDMETHOD.

*
* 
