**************************************************************************
*   Method attributes.                                                   *
**************************************************************************
*  Instantiation: Public
**************************************************************************

  METHOD IF_EX_MB_MIGO_BADI~PAI_HEADER.

    "tri.nguyen2 - 14.10.2025
    "--> Chặn PO có PO type có nằm trong khai báo ZMIGO_PO
    DATA: LV_PO(28)      TYPE C VALUE '(SAPLMIGO)GODYNPRO-PO_NUMBER',
          LV_ACTION(28)  TYPE C VALUE '(SAPLMIGO)GODYNPRO-ACTION',
          LV_REFDOC(28)  TYPE C VALUE '(SAPLMIGO)GODYNPRO-REFDOC',
          LV_RSNUM_F(40) TYPE C VALUE '(SAPLMIGO)GODYNPRO-RESERVATION_NUMBER'.

    FIELD-SYMBOLS <FS_PO>     TYPE ANY.
    FIELD-SYMBOLS <FS_ACTION> TYPE ANY.
    FIELD-SYMBOLS <FS_REFDOC> TYPE ANY.
    FIELD-SYMBOLS <FS_RSNUM>   TYPE ANY.

    ASSIGN (LV_PO)     TO <FS_PO>.
    ASSIGN (LV_ACTION) TO <FS_ACTION>.
    ASSIGN (LV_REFDOC) TO <FS_REFDOC>.
    ASSIGN (LV_RSNUM_F) TO <FS_RSNUM>.

    IF <FS_ACTION> = 'A01' AND <FS_REFDOC> = 'R01' AND <FS_PO> IS NOT INITIAL.
      SELECT SINGLE COUNT( * )
        FROM ZTB_MIGO_PO AS KB
        INNER JOIN EKKO ON EKKO~BSART = KB~BSART
        WHERE EKKO~EBELN EQ @<FS_PO>.
      IF SY-SUBRC <> 0.
        MESSAGE E094(ZMC_CTK).
      ENDIF.

      "PhatTT add begin 07.04.2026 16:52:59
    ELSEIF <FS_REFDOC> = 'R09'
     AND <FS_RSNUM> IS ASSIGNED
     AND <FS_RSNUM> IS NOT INITIAL.

      SELECT SINGLE @ABAP_TRUE
        FROM RKPF AS K
        INNER JOIN ZTB_MVT_RELEASE AS Z
          ON Z~BWART = K~BWART
        INTO @DATA(LV_BLOCK_POST)
        WHERE K~RSNUM      = @<FS_RSNUM>
          AND K~ZZRELEASE <> 'X'.

      IF LV_BLOCK_POST = ABAP_TRUE.
        MESSAGE 'Reservation chưa được duyệt!' TYPE 'E'.
        "PhatTT add end 07.04.2026 16:53:02
      ENDIF.
    ENDIF.
    "-"
  ENDMETHOD.

*
* 
