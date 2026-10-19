  METHOD IF_EX_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK.
    TYPES:
      BEGIN OF LTY_LIPS_POSNR,
        VBELN TYPE VBELN_VL,
        POSNR TYPE POSNR_VL,
        VRKME TYPE VRKME,
        LFIMG TYPE LFIMG,
        UPDKZ TYPE UPDKZ_D,
      END OF LTY_LIPS_POSNR,
      BEGIN OF LTY_LIPS_UECHA,
        VBELN   TYPE VBELN_VL,
        UECHA   TYPE UECHA,
        POSNR   TYPE POSNR_VL,
        VRKME   TYPE VRKME,
        LFIMG   TYPE LFIMG,
        UPDKZ   TYPE UPDKZ_D,
        LGMNG   TYPE LGMNG,
        MEINS   TYPE MEINS,
        MATNR   TYPE MATNR,
        G_LFIMG TYPE LFIMG,
      END OF LTY_LIPS_UECHA.


    DATA:
      LW_KWMENG         TYPE KWMENG,
      LW_KWMENG_SUM     TYPE KWMENG,
      LW_LFIMG          TYPE LFIMG,
      LW_MSG            TYPE CHAR255,
      LS_LIKP           TYPE LIKPVB,
      LS_LIPS           TYPE LIPSVB,
      LW_OD_CUON_EDIT   TYPE CHAR01,
      LT_LIPS_POSNR     TYPE TABLE OF LTY_LIPS_POSNR,
      LS_LIPS_POSNR     TYPE LTY_LIPS_POSNR,
      LT_LIPS_POSNR_SUM TYPE TABLE OF LTY_LIPS_POSNR,
      LS_LIPS_POSNR_SUM TYPE LTY_LIPS_POSNR,
      LT_LIPS_UECHA     TYPE TABLE OF LTY_LIPS_UECHA,
      LS_LIPS_UECHA     TYPE LTY_LIPS_UECHA,
      LT_LIPS_UECHA_SUM TYPE TABLE OF LTY_LIPS_UECHA,
      LS_LIPS_UECHA_SUM TYPE LTY_LIPS_UECHA.

    DATA: LW_MENGE_LIMIT   TYPE MENGE_D,
          LW_MENGE_HIS     TYPE MENGE_D,
          LW_MENGE_REMAIN  TYPE MENGE_D,
          LT_LIPS_HIS      TYPE TABLE OF LTY_LIPS_UECHA,
          LT_LIPS_HIS_S    TYPE TABLE OF LTY_LIPS_UECHA,
          LS_LIPS_HIS      TYPE LTY_LIPS_UECHA,
          LS_LIPS_HIS_S    TYPE LTY_LIPS_UECHA,
          LS_EKPO          TYPE EKPO,
          LS_XLIKP         TYPE LIKPVB,
          LS_XLIPS         TYPE LIPSVB,
          LS_FINCHDEL      TYPE FINCHDEL,
          LW_OVER          TYPE C,
          LW_ERROR         TYPE C,
          LW_POSNR         TYPE POSNR_VL,
          LW_VBELN         TYPE VBELN_VL,
          LT_XLIPS_UECHA   TYPE TABLE OF LTY_LIPS_UECHA,
          LS_XLIPS_UECHA   TYPE LTY_LIPS_UECHA,
          LS_XLIPS_UECHA_S TYPE LTY_LIPS_UECHA,
          LT_XLIPS_UECHA_S TYPE TABLE OF LTY_LIPS_UECHA,
          LW_LGMNG         TYPE LGMNG,
          LW_MENGE_IN      TYPE BSTMG,
          LW_MENGE_OUT     TYPE BSTMG,
          LW_MEINS_IN      TYPE MEINS,
          LW_MEINS_OUT     TYPE MEINS.
    FIELD-SYMBOLS: <LF_XLIPS_UECHA> TYPE LTY_LIPS_UECHA.

    LOOP AT IT_XLIKP INTO LS_XLIKP
      WHERE LFART <> 'EL'   "Loại bỏ Inbound (EL)
        AND LFART <> 'LB'   "Loại bỏ DO for Sub contract
        AND LFART <> 'RLL'  "Loại bỏ Return to vendor
        AND LFART <> 'ELST'."Loại bỏ Delivery type Vận chuyển nội bộ
      IF IF_TRTYP = 'H'
      OR IF_TRTYP = 'V'.
        MOVE-CORRESPONDING IT_XLIPS TO LT_XLIPS_UECHA.
        DELETE LT_XLIPS_UECHA
          WHERE UPDKZ = 'D'.
        DELETE LT_XLIPS_UECHA WHERE VBELN <> LS_XLIKP-VBELN.
        "Assign UECHA for LT_XLIPS_UECHA
        LOOP AT LT_XLIPS_UECHA ASSIGNING <LF_XLIPS_UECHA>
          WHERE UECHA IS INITIAL.
          <LF_XLIPS_UECHA>-UECHA = <LF_XLIPS_UECHA>-POSNR.
        ENDLOOP.
        SORT LT_XLIPS_UECHA BY VBELN ASCENDING
                               UECHA ASCENDING.
        LOOP AT LT_XLIPS_UECHA INTO LS_XLIPS_UECHA.
          DATA(LS_XLIPS_UECHA_TEMP) = LS_XLIPS_UECHA.
          AT END OF UECHA.
            SUM.
            LS_XLIPS_UECHA_S-VBELN = LS_XLIPS_UECHA-VBELN.
            LS_XLIPS_UECHA_S-UECHA = LS_XLIPS_UECHA-UECHA.
            LS_XLIPS_UECHA_S-LGMNG = LS_XLIPS_UECHA-LGMNG.
            LS_XLIPS_UECHA_S-MATNR = LS_XLIPS_UECHA_TEMP-MATNR.
            LS_XLIPS_UECHA_S-MEINS = LS_XLIPS_UECHA_TEMP-MEINS.
            LS_XLIPS_UECHA_S-G_LFIMG = LS_XLIPS_UECHA_TEMP-G_LFIMG.
            APPEND LS_XLIPS_UECHA_S TO LT_XLIPS_UECHA_S.
          ENDAT.
        ENDLOOP.
        CLEAR: LW_OVER.
        LOOP AT IT_XLIPS INTO LS_XLIPS
          WHERE VBELN = LS_XLIKP-VBELN
            AND VGTYP = 'V'
            AND UECHA IS INITIAL.
          CLEAR: LS_EKPO, LS_LIPS_HIS, LW_MENGE_LIMIT, LW_MENGE_HIS, LW_LGMNG.
          REFRESH: LT_LIPS_HIS, LT_LIPS_HIS_S.
*          "OD quantity
*          READ TABLE LT_XLIPS_UECHA_S INTO LS_XLIPS_UECHA_S
*            WITH KEY VBELN = LS_XLIPS-VBELN
*                     UECHA = LS_XLIPS-POSNR BINARY SEARCH.
*          IF SY-SUBRC = 0.
*            LW_LGMNG = LS_XLIPS_UECHA_S-LGMNG.
*          ELSE.
*            LW_LGMNG = LS_XLIPS-LGMNG.
*          ENDIF.
*       Check Over Tolerance
          SELECT SINGLE
            EKPO~*
          FROM EKPO
            "KhoaLD add begin 18.04.2025 13:44:12
            "Update enhance theo PO type ZPO4 và ZPO5
            INNER JOIN EKKO ON EKKO~EBELN = EKPO~EBELN
                           AND EKKO~BSART IN ('ZPO4', 'ZPO5')
            "KhoaLD add end 18.04.2025 13:44:12
          INTO CORRESPONDING FIELDS OF @LS_EKPO
          WHERE EKPO~EBELN = @LS_XLIPS-VGBEL
            AND EKPO~EBELP = @LS_XLIPS-VGPOS.
*            AND UEBTK = SPACE.
          IF SY-SUBRC = 0.
            "Quantity Limit
            LW_MENGE_LIMIT = LS_EKPO-MENGE * ( 1 + LS_EKPO-UEBTO / 100 ).
            "Get delivery history
            SELECT
              LIPS~VBELN
              LIPS~UECHA
              LIPS~POSNR
              LIPS~VRKME
              LIPS~LFIMG
              LIPS~LGMNG
              LIPS~MATNR
            FROM LIPS
              JOIN LIKP ON LIPS~VBELN = LIKP~VBELN
            INTO CORRESPONDING FIELDS OF TABLE LT_LIPS_HIS
            WHERE LIPS~VGBEL = LS_XLIPS-VGBEL
              AND LIPS~VGPOS = LS_XLIPS-VGPOS
              AND LIKP~LFART <> 'LB'.
            IF SY-SUBRC = 0.
              "Assign UECHA for LT_XLIPS_UECHA
              LOOP AT LT_LIPS_HIS ASSIGNING <LF_XLIPS_UECHA>
                WHERE UECHA IS INITIAL.
                <LF_XLIPS_UECHA>-UECHA = <LF_XLIPS_UECHA>-POSNR.

                " START --> 14.08.24: tuan.nguyen4 convert OD unit => PO unit
                CLEAR: LW_MENGE_IN, LW_MENGE_OUT, LW_MEINS_IN, LW_MEINS_OUT.
                IF <LF_XLIPS_UECHA>-MEINS NE LS_EKPO-MEINS.
                  LW_MENGE_IN = <LF_XLIPS_UECHA>-LGMNG.
                  LW_MEINS_IN = <LF_XLIPS_UECHA>-MEINS.
                  LW_MEINS_OUT = LS_EKPO-MEINS.

                  CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
                    EXPORTING
                      I_MATNR              = <LF_XLIPS_UECHA>-MATNR
                      I_IN_ME              = LW_MEINS_IN
                      I_OUT_ME             = LW_MEINS_OUT
                      I_MENGE              = LW_MENGE_IN
                    IMPORTING
                      E_MENGE              = LW_MENGE_OUT
                    EXCEPTIONS
                      ERROR_IN_APPLICATION = 1
                      ERROR                = 2
                      OTHERS               = 3.
                  IF SY-SUBRC EQ 0.
                    <LF_XLIPS_UECHA>-LGMNG = LW_MENGE_OUT.
                  ENDIF.
                ENDIF.
                " END --> 14.08.24: tuan.nguyen4
              ENDLOOP.
              SORT LT_LIPS_HIS BY VBELN ASCENDING
                                  UECHA ASCENDING.
              LOOP AT LT_LIPS_HIS INTO LS_LIPS_HIS.
                AT END OF UECHA.
                  SUM.
                  LS_LIPS_HIS_S-VBELN = LS_LIPS_HIS-VBELN.
                  LS_LIPS_HIS_S-UECHA = LS_LIPS_HIS-UECHA.
                  LS_LIPS_HIS_S-LGMNG = LS_LIPS_HIS-LGMNG.
                  APPEND LS_LIPS_HIS_S TO LT_LIPS_HIS_S.
                ENDAT.
              ENDLOOP.
              IF IF_TRTYP = 'V'.
                DELETE LT_LIPS_HIS_S WHERE VBELN = LS_XLIPS-VBELN
                                       AND UECHA = LS_XLIPS-POSNR.
              ENDIF.
              LOOP AT LT_LIPS_HIS_S INTO LS_LIPS_HIS.
                "Quantity history
                LW_MENGE_HIS = LW_MENGE_HIS + LS_LIPS_HIS-LGMNG.
              ENDLOOP.
            ENDIF.
            "Quantity remain can post
            LW_MENGE_REMAIN = LW_MENGE_LIMIT - LW_MENGE_HIS.

            "OD quantity
            READ TABLE LT_XLIPS_UECHA_S INTO LS_XLIPS_UECHA_S
              WITH KEY VBELN = LS_XLIPS-VBELN
                       UECHA = LS_XLIPS-POSNR BINARY SEARCH.
            IF SY-SUBRC = 0.
              LW_LGMNG = LS_XLIPS_UECHA_S-LGMNG.
              " START --> 14.08.24: tuan.nguyen4 convert OD unit => PO unit
              CLEAR: LW_MENGE_IN, LW_MENGE_OUT, LW_MEINS_IN, LW_MEINS_OUT.
              IF LS_XLIPS_UECHA_S-MEINS NE LS_EKPO-MEINS.
*                  LW_LGMNG = LS_XLIPS_UECHA_S-G_LFIMG.
                LW_MENGE_IN = LW_LGMNG.
                LW_MEINS_IN = LS_XLIPS_UECHA_S-MEINS.
                LW_MEINS_OUT = LS_EKPO-MEINS.

                CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
                  EXPORTING
                    I_MATNR              = LS_XLIPS_UECHA_S-MATNR
                    I_IN_ME              = LW_MEINS_IN
                    I_OUT_ME             = LW_MEINS_OUT
                    I_MENGE              = LW_MENGE_IN
                  IMPORTING
                    E_MENGE              = LW_MENGE_OUT
                  EXCEPTIONS
                    ERROR_IN_APPLICATION = 1
                    ERROR                = 2
                    OTHERS               = 3.
                IF SY-SUBRC EQ 0.
                  LW_LGMNG = LW_MENGE_OUT.
                ENDIF.
              ENDIF.
              " END --> 14.08.24: tuan.nguyen4
            ELSE.
              LW_LGMNG = LS_XLIPS-LGMNG.
              " START --> 14.08.24: tuan.nguyen4 convert OD unit => PO unit
              CLEAR: LW_MENGE_IN, LW_MENGE_OUT, LW_MEINS_IN, LW_MEINS_OUT.
              IF LS_XLIPS-MEINS NE LS_EKPO-MEINS.
                LW_MENGE_IN = LW_LGMNG.
                LW_MEINS_IN = LS_XLIPS-MEINS.
                LW_MEINS_OUT = LS_EKPO-MEINS.

                CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
                  EXPORTING
                    I_MATNR              = LS_XLIPS-MATNR
                    I_IN_ME              = LW_MEINS_IN
                    I_OUT_ME             = LW_MEINS_OUT
                    I_MENGE              = LW_MENGE_IN
                  IMPORTING
                    E_MENGE              = LW_MENGE_OUT
                  EXCEPTIONS
                    ERROR_IN_APPLICATION = 1
                    ERROR                = 2
                    OTHERS               = 3.
                IF SY-SUBRC EQ 0.
                  LW_LGMNG = LW_MENGE_OUT.
                ENDIF.
              ENDIF.
              " END --> 14.08.24: tuan.nguyen4
            ENDIF.

            "Check quantity create OD
            IF LW_LGMNG NE LW_MENGE_REMAIN.
              LW_OVER = 'X'.
              LW_VBELN = LS_XLIPS-VBELN.
              LW_POSNR = LS_XLIPS-POSNR.
              EXIT.
            ENDIF.
          ENDIF.
        ENDLOOP.
        "Show error
        IF LW_OVER = 'X'.
          LW_ERROR = 'X'.
          CLEAR LS_FINCHDEL.
          LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
          LS_FINCHDEL-PRUEFUNG = '99'.
          LS_FINCHDEL-MSGTY    = 'E'.
          LS_FINCHDEL-MSGID    = 'ZMC_CTK'.
          LS_FINCHDEL-MSGNO    = '026'.
          LS_FINCHDEL-MSGV1    = LW_VBELN.
          LS_FINCHDEL-MSGV2    = LW_POSNR.
          INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " START --> 14.06.24: tuan.nguyen4
    IF SY-TCODE EQ 'VL32N' OR SY-TCODE EQ 'VL33N'. "danhdh add Vl33N 19.08.2026 14:48:14
      LOOP AT IT_XLIKP INTO LS_XLIKP.
        CLEAR LW_VBELN.
*     Không cho phép chỉnh sửa Inbound khi đã tick “Approve chuyển kho”
*    Check IB, nếu [Field] Aprrove chuyển kho (ZZAPPROVE) = X thì không cho phép chỉnh sửa IB.
*    Check IB, nếu [Field] Aprrove chuyển kho (ZZAPPROVE) = Null thì cho phép chỉnh sửa IB.

        IF LS_XLIKP-ZZAPPROVE = ABAP_TRUE  AND SY-UCOMM <> 'WABU_T'. "danhdh add AND SY-UCOMM <> 'WABU_T' 27.08.2026 10:01:35
          SELECT SINGLE VBELN
          INTO LW_VBELN
          FROM LIKP
          WHERE VBELN         = LS_XLIKP-VBELN
            AND ZZAPPROVE     = ABAP_TRUE.
          IF SY-SUBRC = 0.
            LW_ERROR = 'X'.
            CLEAR LS_FINCHDEL.
            LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
            LS_FINCHDEL-PRUEFUNG = '99'.
            LS_FINCHDEL-MSGTY    = 'E'.
            LS_FINCHDEL-MSGID    = 'ZMC_MM'.
            LS_FINCHDEL-MSGNO    = '039'.
            LS_FINCHDEL-MSGV1    = LW_VBELN.
            INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
          ENDIF.
        ENDIF.

*      Không cho phép chỉnh sửa Inbound khi đã tick “Approve chuyển kế toán”
*      Check IB, nếu [Field] Aprrove chuyển kế toán (ZZRL_CHUYENKT) = X thì không cho phép chỉnh sửa IB.
*      Check IB, nếu [Field] Aprrove chuyển kế toán (ZZRL_CHUYENKT) = Null thì cho phép chỉnh sửa IB.
        IF LS_XLIKP-ZZRL_CHUYENKT = ABAP_TRUE AND SY-UCOMM <> 'WABU_T'. "danhdh add AND SY-UCOMM <> 'WABU_T' 27.08.2026 10:01:35
          SELECT SINGLE VBELN
          INTO LW_VBELN
          FROM LIKP
          WHERE VBELN         = LS_XLIKP-VBELN
            AND ZZRL_CHUYENKT = ABAP_TRUE.
          IF SY-SUBRC = 0.
            LW_ERROR = 'X'.
            CLEAR LS_FINCHDEL.
            LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
            LS_FINCHDEL-PRUEFUNG = '99'.
            LS_FINCHDEL-MSGTY    = 'E'.
            LS_FINCHDEL-MSGID    = 'ZMC_MM'.
            LS_FINCHDEL-MSGNO    = '040'.
            LS_FINCHDEL-MSGV1    = LW_VBELN.
            INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
          ENDIF.
        ENDIF.


        "danhdh add begin 26.08.2026 11:50:29
        "2.19  Chan Goods Receipt doi voi Inbound chua duyet (VL32N, VL33N change mode)
        IF SY-UCOMM = 'WABU_T'. "danhdh add 31.08.2026 14:27:36
          SELECT SINGLE MAP~ZZREL_CODE
         FROM LIPS
           INNER JOIN EKPO ON EKPO~EBELN = LIPS~VGBEL
           INNER JOIN EKKO ON EKKO~EBELN = EKPO~EBELN
           INNER JOIN ZMM_TB_MAP_VL06I AS MAP ON MAP~BSART = EKKO~BSART
         WHERE LIPS~VBELN = @LS_XLIKP-VBELN
         INTO @DATA(LV_REL_CODE_GR).

          IF SY-SUBRC = 0.
            CASE LV_REL_CODE_GR.
              WHEN '1'.
                IF LS_XLIKP-ZZAPPROVE IS INITIAL.
                  LW_ERROR = 'X'.
                  CLEAR LS_FINCHDEL.
                  LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
                  LS_FINCHDEL-PRUEFUNG = '99'.
                  LS_FINCHDEL-MSGTY    = 'E'.
                  LS_FINCHDEL-MSGID    = 'ZMC_DGW'.
                  LS_FINCHDEL-MSGNO    = '003'.
                  LS_FINCHDEL-MSGV1    = LS_XLIKP-VBELN.
                  INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
                ENDIF.

              WHEN '2'.
                IF LS_XLIKP-ZZRL_CHUYENKT IS INITIAL OR LS_XLIKP-ZZAPPROVE IS INITIAL.
                  LW_ERROR = 'X'.
                  CLEAR LS_FINCHDEL.
                  LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
                  LS_FINCHDEL-PRUEFUNG = '99'.
                  LS_FINCHDEL-MSGTY    = 'E'.
                  LS_FINCHDEL-MSGID    = 'ZMC_DGW'.
                  LS_FINCHDEL-MSGNO    = '045'.
                  LS_FINCHDEL-MSGV1    = LS_XLIKP-VBELN.
                  INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
                ENDIF.

              WHEN OTHERS.
            ENDCASE.
          ENDIF. "danhdh add 31.08.2026 14:27:52
        ENDIF.
        "danhdh add end 26.08.2026 11:50:29
      ENDLOOP.
    ENDIF.
    " END   --> 14.06.24: tuan.nguyen4

    "KhoaLD add begin 07.10.2025 17:50:54
    "#31031: update enhance Incoterm
    IF SY-TCODE = 'VL31N' OR SY-TCODE = 'VL32N'.
      DATA: LV_EBELN TYPE EBELN.

      LOOP AT IT_XLIKP INTO LS_XLIKP.
        "check co OD tham chieu tu PO khong
        LOOP AT IT_XLIPS INTO LS_XLIPS WHERE VGBEL IS NOT INITIAL.
          LV_EBELN = LS_XLIPS-VGBEL.
          EXIT.
        ENDLOOP.
        IF SY-SUBRC = 0.
          SELECT SINGLE BSART
          FROM EKKO
          WHERE EBELN = @LV_EBELN
          INTO @DATA(LV_BSART).

          IF  LV_BSART <> 'EUB'
          AND LV_BSART <> 'ZPO7'
          AND LV_BSART <> 'ZPO5'
          AND LV_BSART <> 'ZPO4'
          AND LV_BSART <> 'UB2'
          AND LV_BSART <> 'ZPO6'
          AND LV_BSART <> 'UB'
          AND LV_BSART <> 'UD'.

            IF LS_XLIKP-INCOV IS INITIAL.
              LW_ERROR = 'X'.
              CLEAR LS_FINCHDEL.
              LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
              LS_FINCHDEL-PRUEFUNG = '99'.
              LS_FINCHDEL-MSGTY    = 'E'.
              LS_FINCHDEL-MSGID    = 'ZMC_ENH'.
              LS_FINCHDEL-MSGNO    = '007'.
              LS_FINCHDEL-MSGV1    = 'Incoterms version'.
              INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
            ENDIF.

            IF LS_XLIKP-INCO1 IS INITIAL.
              LW_ERROR = 'X'.
              CLEAR LS_FINCHDEL.
              LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
              LS_FINCHDEL-PRUEFUNG = '99'.
              LS_FINCHDEL-MSGTY    = 'E'.
              LS_FINCHDEL-MSGID    = 'ZMC_ENH'.
              LS_FINCHDEL-MSGNO    = '007'.
              LS_FINCHDEL-MSGV1    = 'Incoterms'.
              INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
            ENDIF.

            IF LS_XLIKP-INCO2_L IS INITIAL.
              CLEAR LS_FINCHDEL.
              LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
              LS_FINCHDEL-PRUEFUNG = '99'.
              LS_FINCHDEL-MSGTY    = 'E'.
              LS_FINCHDEL-MSGID    = 'ZMC_ENH'.
              LS_FINCHDEL-MSGNO    = '007'.
              LS_FINCHDEL-MSGV1    = 'Departure'.
              INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
            ENDIF.

            IF LS_XLIKP-INCO3_L IS INITIAL.
              LW_ERROR = 'X'.
              CLEAR LS_FINCHDEL.
              LS_FINCHDEL-VBELN    = LS_XLIKP-VBELN.
              LS_FINCHDEL-PRUEFUNG = '99'.
              LS_FINCHDEL-MSGTY    = 'E'.
              LS_FINCHDEL-MSGID    = 'ZMC_ENH'.
              LS_FINCHDEL-MSGNO    = '007'.
              LS_FINCHDEL-MSGV1    = 'Destination'.
              INSERT LS_FINCHDEL INTO TABLE CT_FINCHDEL.
            ENDIF.
          ENDIF.
        ENDIF.

      ENDLOOP.
    ENDIF.
    "KhoaLD add end 07.10.2025 17:50:54

    IF LW_ERROR = 'X'.
      RETURN.
    ENDIF.
  ENDMETHOD.