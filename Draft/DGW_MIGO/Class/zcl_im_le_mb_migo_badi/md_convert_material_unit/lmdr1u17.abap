FUNCTION md_purpar_determine.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_S_EINA) LIKE  EINA STRUCTURE  EINA
*"     REFERENCE(I_S_EINE) LIKE  EINE STRUCTURE  EINE
*"     REFERENCE(I_MATNR) LIKE  MARC-MATNR
*"     REFERENCE(I_WERKS) LIKE  MARC-WERKS
*"     REFERENCE(I_PURPAR) LIKE  RCPR-PURPAR
*"     REFERENCE(I_S_RESULTS) TYPE  MDR1OUTSINGLEROUND
*"  EXPORTING
*"     REFERENCE(E_S_PURPAR) TYPE  MDR1OUTSINGLEROUND
*"  CHANGING
*"     REFERENCE(C_S_MARC) LIKE  MARC STRUCTURE  MARC
*"  EXCEPTIONS
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       30.10.01  470  hwi         Grundversion
*-------------------------------------------------------------------


*                *** folgende Werte in Tabelle RCPR-PURPAR sind möglich:
  CONSTANTS: pur0 TYPE c VALUE '0',
             pur1 TYPE c VALUE '1',
             pur2 TYPE c VALUE '2',
             pur3 TYPE c VALUE '3'.

  CASE i_purpar.
    WHEN pur0.
*                *** herkömmliche Logik, schon aus 4.X mit x<7 bekannt
  IF NOT ( i_s_eina IS INITIAL ).   " I_S_EINA = LEER => I_S_EINE = LEER
*                *** Gelesene EINA/EINE-Eintrag für die Rundungsparamet.
*                *** nutzen
        e_s_purpar-rdprf      = i_s_eine-rdprf.
        e_s_purpar-bstrf      = 0.
        e_s_purpar-maxqt      = i_s_eine-bstma.
        e_s_purpar-minqt      = i_s_eine-minbm.
        e_s_purpar-mamiqtunit = i_s_eina-meins.
        e_s_purpar-mamiumrez  = i_s_eina-umrez.
        e_s_purpar-mamiumren  = i_s_eina-umren.
*                ***  => ??? EINA-MEINS <> LEER,
*                ***         wenn EINE-BSTMA <> 0 oder EINE-MINBM <> 0

      ENDIF.

*                *** Der MARC-Satz zum Abnehmer-Werk wird gelesen für
*                *** 1. die Abnehmergruppe
*                *** 2. für die Rundungsparameter bei nicht exist.
*                ***    EK-Infosatz
*                *** 3. Rundungswert immer aus MARC, da dieser nur dort
*                ***    pflegbar
      PERFORM read_marc_single  USING    i_matnr
                                         i_werks
                                CHANGING c_s_marc.
*                *** Rundungswert immer aus der MARC nehmen!!!
      e_s_purpar-bstrf      = c_s_marc-bstrf.
*                *** Gelesene Werte aus MARC als Rundungsparam. nutzen
  IF      ( i_s_eina IS INITIAL )      " wenn EINA = LEER => EINE = LEER
  AND NOT ( c_s_marc IS INITIAL ).
        e_s_purpar-rdprf      = c_s_marc-rdprf.
        e_s_purpar-bstrf      = c_s_marc-bstrf.
        e_s_purpar-maxqt      = c_s_marc-bstma. " Immer in Basis-ME
        e_s_purpar-minqt      = c_s_marc-bstmi. " Immer in Basis-ME
        e_s_purpar-mamiqtunit = i_s_results-meins.
        e_s_purpar-mamiumrez  = 1.
        e_s_purpar-mamiumren  = 1.
      ENDIF.

    WHEN pur1. " wie pur0, nur ohne Rundungswertkonstrukt
  IF NOT ( i_s_eina IS INITIAL ).   " I_S_EINA = LEER => I_S_EINE = LEER
*                *** Gelesene EINA/EINE-Eintrag für die Rundungsparamet.
*                *** nutzen
        e_s_purpar-rdprf      = i_s_eine-rdprf.
        e_s_purpar-bstrf      = 0.
        e_s_purpar-maxqt      = i_s_eine-bstma.
        e_s_purpar-minqt      = i_s_eine-minbm.
        e_s_purpar-mamiqtunit = i_s_eina-meins.
        e_s_purpar-mamiumrez  = i_s_eina-umrez.
        e_s_purpar-mamiumren  = i_s_eina-umren.

      ENDIF.

*                *** Der MARC-Satz zum Abnehmer-Werk wird gelesen für
*                *** 1. die Abnehmergruppe
*                *** 2. für die Rundungsparameter bei nicht exist.
*                ***    EK-Infosatz
      PERFORM read_marc_single  USING    i_matnr
                                         i_werks
                                CHANGING c_s_marc.
*                *** Gelesene Werte aus MARC als Rundungsparam. nutzen
  IF      ( i_s_eina IS INITIAL )      " wenn EINA = LEER => EINE = LEER
  AND NOT ( c_s_marc IS INITIAL ).
        e_s_purpar-rdprf      = c_s_marc-rdprf.
        e_s_purpar-bstrf      = c_s_marc-bstrf.
        e_s_purpar-maxqt      = c_s_marc-bstma. " Immer in Basis-ME
        e_s_purpar-minqt      = c_s_marc-bstmi. " Immer in Basis-ME
        e_s_purpar-mamiqtunit = i_s_results-meins.
        e_s_purpar-mamiumrez  = 1.
        e_s_purpar-mamiumren  = 1.
      ENDIF.

    WHEN pur2.   " nur MARC

*                *** Der MARC-Satz zum Abnehmer-Werk wird gelesen für
*                *** 1. die Abnehmergruppe
*
      PERFORM read_marc_single  USING    i_matnr
                                         i_werks
                                CHANGING c_s_marc.
*                *** Gelesene Werte aus MARC als Rundungsparam. nutzen

      IF NOT ( c_s_marc IS INITIAL ).
        e_s_purpar-rdprf      = c_s_marc-rdprf.
        e_s_purpar-bstrf      = c_s_marc-bstrf.
        e_s_purpar-maxqt      = c_s_marc-bstma. " Immer in Basis-ME
        e_s_purpar-minqt      = c_s_marc-bstmi. " Immer in Basis-ME
        e_s_purpar-mamiqtunit = i_s_results-meins.
        e_s_purpar-mamiumrez  = 1.
        e_s_purpar-mamiumren  = 1.
      ENDIF.

    WHEN pur3.   " nur Infosatz
  IF NOT ( i_s_eina IS INITIAL ).   " I_S_EINA = LEER => I_S_EINE = LEER
*                *** Gelesenen EINA/EINE-Eintrag für die Rundungsparam.
*                *** nutzen
        e_s_purpar-rdprf      = i_s_eine-rdprf.
        e_s_purpar-bstrf      = 0.
        e_s_purpar-maxqt      = i_s_eine-bstma.
        e_s_purpar-minqt      = i_s_eine-minbm.
        e_s_purpar-mamiqtunit = i_s_eina-meins.
        e_s_purpar-mamiumrez  = i_s_eina-umrez.
        e_s_purpar-mamiumren  = i_s_eina-umren.

      ENDIF.

  ENDCASE.

ENDFUNCTION.

*
* 
