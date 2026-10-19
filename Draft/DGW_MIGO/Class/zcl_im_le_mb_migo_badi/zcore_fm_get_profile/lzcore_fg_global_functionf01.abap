*----------------------------------------------------------------------*
***INCLUDE LZCORE_FG_GLOBAL_FUNCTIONF01.
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form GET_EMAIL_BP
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_NUMBER
*&      <-- E_EMAIL
*&---------------------------------------------------------------------*
FORM GET_EMAIL_BP_CUST  USING    P_NUMBER
                   CHANGING E_EMAIL
                            E_PARTNER.
  DATA:
    LV_SQL   TYPE STRING,
    LT_EMAIL TYPE TABLE OF ADR6-SMTP_ADDR WITH HEADER LINE.

  SELECT SINGLE
    BUT000~PARTNER
    INTO E_PARTNER
    FROM KNA1
          INNER JOIN CVI_CUST_LINK ON KNA1~KUNNR EQ CVI_CUST_LINK~CUSTOMER
          INNER JOIN BUT000 ON CVI_CUST_LINK~PARTNER_GUID EQ BUT000~PARTNER_GUID
    WHERE KNA1~KUNNR EQ P_NUMBER.

  IF SY-SUBRC EQ 0.

    SELECT
      ADR6~SMTP_ADDR
      INTO TABLE LT_EMAIL
      FROM BUT000
            INNER JOIN ADR6 ON ADR6~ADDRNUMBER EQ BUT000~ADDRCOMM
      WHERE BUT000~PARTNER EQ E_PARTNER.

    LOOP AT LT_EMAIL.
      IF STRLEN( E_EMAIL ) + STRLEN( LT_EMAIL ) < 100.
        IF E_EMAIL IS INITIAL.
          E_EMAIL = LT_EMAIL.
        ELSE.
          E_EMAIL = E_EMAIL && ',' && LT_EMAIL.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDIF.

ENDFORM.

FORM GET_EMAIL_BP_VEND  USING    P_NUMBER
                   CHANGING E_EMAIL
                            E_PARTNER.

  DATA:
    LV_SQL   TYPE STRING,
    LT_EMAIL TYPE TABLE OF ADR6-SMTP_ADDR WITH HEADER LINE.

  SELECT SINGLE
    BUT000~PARTNER
    INTO E_PARTNER
    FROM LFA1
          INNER JOIN CVI_VEND_LINK ON LFA1~LIFNR EQ CVI_VEND_LINK~VENDOR
          INNER JOIN BUT000 ON CVI_VEND_LINK~PARTNER_GUID EQ BUT000~PARTNER_GUID
    WHERE LFA1~LIFNR EQ P_NUMBER.

  IF SY-SUBRC EQ 0.

    SELECT
      ADR6~SMTP_ADDR
      INTO TABLE LT_EMAIL
      FROM BUT000
            INNER JOIN ADR6 ON ADR6~ADDRNUMBER EQ BUT000~ADDRCOMM
      WHERE BUT000~PARTNER EQ E_PARTNER.

    CLEAR E_EMAIL.
    LOOP AT LT_EMAIL.
      IF STRLEN( E_EMAIL ) + STRLEN( LT_EMAIL ) < 100.
        IF E_EMAIL IS INITIAL.
          E_EMAIL = LT_EMAIL.
        ELSE.
          E_EMAIL = E_EMAIL && ',' && LT_EMAIL.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_TAX_BP_CUST
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_NUMBER
*&      <-- E_TAX
*&---------------------------------------------------------------------*
FORM GET_TAX_BP_CUST  USING    P_NUMBER TYPE CHAR10
                      CHANGING E_TAX    TYPE CHAR255.

  DATA: LW_PARTNER TYPE BUT000-PARTNER.

  SELECT SINGLE
    BUT000~PARTNER
    INTO LW_PARTNER
    FROM CVI_CUST_LINK
*          INNER JOIN CVI_CUST_LINK ON KNA1~KUNNR EQ CVI_CUST_LINK~CUSTOMER
          INNER JOIN BUT000 ON CVI_CUST_LINK~PARTNER_GUID EQ BUT000~PARTNER_GUID
    WHERE CVI_CUST_LINK~CUSTOMER EQ P_NUMBER.
  IF SY-SUBRC = 0.
    SELECT SINGLE TAXNUM
    INTO E_TAX
    FROM DFKKBPTAXNUM
    WHERE PARTNER = LW_PARTNER.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_TAX_BP_VEND
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_NUMBER
*&      <-- E_TAX
*&---------------------------------------------------------------------*
FORM GET_TAX_BP_VEND   USING    P_NUMBER TYPE CHAR10
                      CHANGING  E_TAX  TYPE CHAR255.
  DATA: LW_PARTNER TYPE BUT000-PARTNER.

  SELECT SINGLE
    BUT000~PARTNER
    INTO LW_PARTNER
    FROM CVI_VEND_LINK
*          INNER JOIN CVI_CUST_LINK ON KNA1~KUNNR EQ CVI_CUST_LINK~CUSTOMER
          INNER JOIN BUT000 ON CVI_VEND_LINK~PARTNER_GUID EQ BUT000~PARTNER_GUID
    WHERE CVI_VEND_LINK~VENDOR EQ P_NUMBER.
  IF SY-SUBRC = 0.
    SELECT SINGLE TAXNUM
    INTO E_TAX
    FROM DFKKBPTAXNUM
    WHERE PARTNER = LW_PARTNER.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_TAX_BP_VEND
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM GET_BANK_BP_VEND   USING    P_NUMBER TYPE CHAR10
                        CHANGING E_BANKN    TYPE CHAR255
                                 E_BRANCH.



  SELECT
    BUT0BK~BKVID,
    BUT0BK~BANKN,
    BNKA~BRNCH
    INTO TABLE @DATA(LT_BUT0BK)
    FROM CVI_VEND_LINK
          INNER JOIN BUT000 ON CVI_VEND_LINK~PARTNER_GUID EQ BUT000~PARTNER_GUID
    INNER JOIN BUT0BK
    ON BUT0BK~PARTNER = BUT000~PARTNER
        INNER JOIN BNKA
        ON  BNKA~BANKL = BUT0BK~BANKL
        AND BNKA~BANKS = BUT0BK~BANKS

    WHERE CVI_VEND_LINK~VENDOR EQ @P_NUMBER.
  SORT LT_BUT0BK BY BKVID ASCENDING.

  READ TABLE LT_BUT0BK INTO DATA(LS_BUT0BK) INDEX 1.
  IF SY-SUBRC = 0.
    E_BANKN = LS_BUT0BK-BANKN.
    E_BRANCH = LS_BUT0BK-BRNCH.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_VALUE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_BATCH
*&      <-- LW_ATFLV
*&      <-- LW_ATWRT
*&---------------------------------------------------------------------*
FORM GET_VALUE  USING    P_GS_MCH1 TYPE ZST_BATCH
                CHANGING P_LW_ATFLV TYPE ATFLV
                         P_LW_ATWRT TYPE ATWRT.
  DATA: LW_DEC3(8) TYPE P DECIMALS 3,
        LW_DEC(8)  TYPE P.

  CLEAR:     P_LW_ATFLV, P_LW_ATWRT.
  IF P_GS_MCH1-ATFOR = 'CHAR'.
    P_LW_ATWRT = P_GS_MCH1-ATWRT.
  ELSEIF P_GS_MCH1-ATFOR = 'DATE'.
    P_LW_ATFLV = P_GS_MCH1-ATFLV.
    CALL FUNCTION 'CTCV_CONVERT_FLOAT_TO_DATE'
      EXPORTING
        FLOAT = P_LW_ATFLV
      IMPORTING
        DATE  = P_LW_ATWRT.
  ELSEIF P_GS_MCH1-ATFOR = 'NUM' AND P_GS_MCH1-ANZDZ = 0.
    LW_DEC     = P_GS_MCH1-ATFLV.
    P_LW_ATFLV = P_GS_MCH1-ATFLV.
    P_LW_ATWRT = LW_DEC.
  ELSE.
    LW_DEC3    = P_GS_MCH1-ATFLV.
    P_LW_ATFLV = P_GS_MCH1-ATFLV.
    P_LW_ATWRT = LW_DEC3.
  ENDIF.
ENDFORM.

*
* 
