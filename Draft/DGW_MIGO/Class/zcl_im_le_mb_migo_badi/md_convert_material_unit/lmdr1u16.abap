FUNCTION md_customizing_read.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  EXPORTING
*"     REFERENCE(E_RCPR) LIKE  RCPR STRUCTURE  RCPR
*"     REFERENCE(E_RCTR) LIKE  RCTR STRUCTURE  RCTR
*"  CHANGING
*"     REFERENCE(C_P_S_GENERAL) TYPE  MDR1INSINGLEROUND
*"  EXCEPTIONS
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       30.10.01  470  hwi         Grundversion
*-------------------------------------------------------------------

* Anfang Steuerungsprofil bestimmen

* 1.Versuch mit Kundendaten und Tcode.

  PERFORM change_appl_to_cust USING c_p_s_general-opcode
      CHANGING c_p_s_general-rappl.

  SELECT SINGLE * FROM rctr INTO e_rctr
  WHERE rappl = c_p_s_general-rappl
  AND tcode = c_p_s_general-tcode.

  IF sy-subrc <> 0.
* kein Kundeneintrag bezüglich Tcode gefunden
* --> 2. Versuch mit SAP-Daten
    PERFORM change_appl_to_sap USING c_p_s_general-opcode
      CHANGING c_p_s_general-rappl.

    SELECT SINGLE * FROM rctr INTO e_rctr
    WHERE rappl = c_p_s_general-rappl
    AND tcode = c_p_s_general-tcode.

    IF sy-subrc <> 0.
* kein SAPeintrag bezüglich Tcode gefunden
* --> 3. Versuch mit Kundendaten ohne Tcode
      PERFORM change_appl_to_cust USING c_p_s_general-opcode
      CHANGING c_p_s_general-rappl.

      SELECT SINGLE * FROM rctr INTO e_rctr
      WHERE rappl = c_p_s_general-rappl
      AND tcode = ''.

      IF sy-subrc <> 0.
* kein allgemeiner Kundeneintrag gefunden
* --> 4. Versuch mit allgemeinen SAP-Daten
        PERFORM change_appl_to_sap USING c_p_s_general-opcode
        CHANGING c_p_s_general-rappl.

        SELECT SINGLE * FROM rctr INTO e_rctr
        WHERE rappl = c_p_s_general-rappl
        AND tcode = ''.

        IF sy-subrc <> 0.
          MESSAGE e001(rpugen) WITH    'MD_SINGLE_ROUNDING'
                               RAISING error.
        ENDIF.

      ENDIF.
    ENDIF.
  ENDIF.


* Ende Steuerungsprofil bestimmen


* Anfang Steuerungsprofil lesen
* das Steuerungsprofil ist nun auf jeden Fall bekannt, mit diesem
* bestimmen wir in Tabelle RCPR die 'Rundungseigenschaften'

  SELECT SINGLE * FROM rcpr INTO e_rcpr
  WHERE cprof = e_rctr-cprof.

  IF sy-subrc <> 0.
    MESSAGE e001(rpugen) WITH    'MD_CUSTOMIZING_READ'
                         RAISING error.
  ENDIF.

* Ende Steuerungsprofil lesen

ENDFUNCTION.

*
* 
