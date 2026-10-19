FUNCTION ZCORE_FM_CHECK_REVERSE_MM.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_MBLNR) TYPE  MBLNR
*"     REFERENCE(I_BUDAT) TYPE  BUDAT
*"     REFERENCE(I_ZEILE) TYPE  MBLPO
*"  EXPORTING
*"     REFERENCE(I_EXIST) TYPE  CHAR1
*"--------------------------------------------------------------------
* Global data declarations

  DATA:   IT_BUDAT  TYPE TABLE OF ZST_RSELOPTION_BUDAT WITH HEADER LINE,
          LW_LOWDAT TYPE SY-DATUM,
          LW_HIGDAT TYPE SY-DATUM,
          LT_MSEG   TYPE TABLE OF MSEG,
          LW_GJAHR  TYPE GJAHR,
          LW_MONAT  TYPE MONAT.

  LW_GJAHR = I_BUDAT+0(4).
  LW_MONAT = I_BUDAT+4(2).

  CONCATENATE LW_GJAHR LW_MONAT '01' INTO LW_LOWDAT.

  CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
    EXPORTING
      DAY_IN            = LW_LOWDAT
    IMPORTING
      LAST_DAY_OF_MONTH = LW_HIGDAT
    EXCEPTIONS
      DAY_IN_NO_DATE    = 1
      OTHERS            = 2.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
        WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
*
  IT_BUDAT-SIGN     = 'I'.
  IT_BUDAT-OPTION   = 'BT'.
  IT_BUDAT-LOW      = LW_LOWDAT.
  IT_BUDAT-HIGH     = LW_HIGDAT.
  APPEND IT_BUDAT.

  SELECT *
  INTO CORRESPONDING FIELDS OF TABLE LT_MSEG
  FROM MSEG
  WHERE
    ( ( MSEG~SMBLN   = I_MBLNR
      AND MSEG~SMBLP = I_ZEILE
      AND MSEG~SJAHR = LW_GJAHR
    )
    OR
    ( EXISTS ( SELECT RV~MBLNR
                FROM MSEG AS RV
                WHERE   RV~MBLNR        EQ MSEG~SMBLN
                      AND RV~ZEILE      EQ MSEG~SMBLP
                      AND RV~MJAHR      EQ MSEG~SJAHR
                      AND RV~BUDAT_MKPF IN IT_BUDAT
              )
      AND MSEG~MBLNR    = I_MBLNR
      AND MSEG~ZEILE    = I_ZEILE
      AND MSEG~MJAHR    = LW_GJAHR
    ) )
    AND MSEG~BUDAT_MKPF IN IT_BUDAT.

  IF LT_MSEG IS NOT INITIAL.
    I_EXIST = 'X'.
  ENDIF.



*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
* You are not authorized with this plant !





ENDFUNCTION.

*
* 
