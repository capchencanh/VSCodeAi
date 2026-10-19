FUNCTION md_convert_material_unit.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(I_MATNR) LIKE  MARA-MATNR
*"     VALUE(I_IN_ME) LIKE  MARA-MEINS
*"     VALUE(I_OUT_ME) LIKE  MARA-MEINS
*"     VALUE(I_MENGE) LIKE  EKPO-MENGE
*"  EXPORTING
*"     VALUE(E_MENGE) LIKE  EKPO-MENGE
*"  EXCEPTIONS
*"      ERROR_IN_APPLICATION
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*- @001  05.03.99  99A  mwe         Neue Konvertierungs-Routine benutzen
*- @002  18.11.99  46C  mwe         Korrektur auf Grund falscher
*-                                  F-Darstellung
*-                                  Ersetze F
*-                                    durch mdr1p_p_16_dec_14
*-                                  (ohne Änderungsmarken!!!)
*-                                  Korrekur zu Hinweis: 185005
*- @003  04.05.00  46C  mwe         Basis-ME bei Material (Standard)
*-                                  nicht in der MARM eingetragen
*-                                  Korrektur zu Hinweis: 300836
*- @004  27.06.01  470  mwe         Programmabruch wegen zu großen
*-                                  Umrechnungsfaktoren
*-                                  Korrektur zu Hinweis: 430276
*-       12.09.01  470  mbi         Schnittstelle RFC-fähig gemacht
*-                                  (ohne Änderungsmarke!)
*  @005  05.03.02  470  hwi         Korrektur zur Mengenumrechnung -
*                                   Exponent eingebaut
*  @006  26.02.04  470  hwi         Korrektur zur Mengenumrechnung -
*                                   Datenüberlauf, Kurzdump verhindert,
*                                   siehe HW 710399
*-----------------------------------------------------------------------

*$@001 Anfang

  STATICS: s_s_last_mara  LIKE mara.

  DATA: l_i_menge_f  TYPE mdr1p_p_16_dec_14,
        l_e_menge_f  TYPE mdr1p_p_16_dec_14,
        l_umrez      TYPE mdr1p_p_16_dec_14,
        l_umren      TYPE mdr1p_p_16_dec_14,
*$@004 Anfang HW-430276-MWE
        l_umrezf     TYPE f,
        l_umrenf     TYPE f,
*$@004 Ende HW-430276-MWE
        l_addko      LIKE t006-addko.
  PERFORM AUTHORITY_CHECK.
  l_i_menge_f  =  i_menge.
  l_e_menge_f  =  i_menge.

*                *** 1. Bestimme die Basis-ME des Materials aus der MARA
*                ***    wenn nötig
  IF i_matnr <> s_s_last_mara-matnr.

    PERFORM read_mara_single USING     i_matnr
                             CHANGING  s_s_last_mara.
  ENDIF.

*                *** 2. Wandele die Eingabe-Menge zuerst in Basis-ME
*                ***    um, wenn nötig!
  IF i_in_me <> s_s_last_mara-meins.

    CLEAR: l_umrez,
           l_umren,
*$@004 Anfang HW-430276-MWE
           l_umrezf,
           l_umrenf,
*$@004 Ende HW-430276-MWE
           l_addko.

    PERFORM get_units_factors_general USING     i_matnr
                                                i_in_me
*$@003 Anfang MWE-HW-300836
                                                s_s_last_mara-meins
*$@003 Ende MWE-HW-300836
                                      CHANGING  l_umrez
                                                l_umren
*$@004 Anfang HW-430276-MWE
                                                l_umrezf
                                                l_umrenf
*$@004 Ende HW-430276-MWE
                                                l_addko.
    IF l_umrez IS INITIAL
    OR l_umren IS INITIAL.
      MESSAGE e094    WITH i_matnr
                           i_in_me
              RAISING error_in_application.
    ENDIF.

    PERFORM conv2unit_rule_1 USING     l_i_menge_f
                                       l_addko
                                       l_umrez
                                       l_umren
*$@004 Anfang HW-430276-MWE
                                       l_umrezf
                                       l_umrenf
*$@004 Ende HW-430276-MWE
                             CHANGING  l_e_menge_f.
  ENDIF.

*                *** 3. Wandele die Eingabe-Menge in Basis-ME dann
*                ***    in die Ausgabe-ME um, wenn nötig
  IF i_out_me <> s_s_last_mara-meins.

    CLEAR: l_umrez,
           l_umren,
*$@004 Anfang HW-430276-MWE
           l_umrezf,
           l_umrenf,
*$@004 Ende HW-430276-MWE
           l_addko.

    PERFORM get_units_factors_general USING     i_matnr
                                                i_out_me
*$@003 Anfang MWE-HW-300836
                                                s_s_last_mara-meins
*$@003 Ende MWE-HW-300836
                                      CHANGING  l_umrez
                                                l_umren
*$@004 Anfang HW-430276-MWE
                                                l_umrezf
                                                l_umrenf
*$@004 Ende HW-430276-MWE
                                                l_addko.

    IF l_umrez IS INITIAL
    OR l_umren IS INITIAL.
      MESSAGE e094    WITH i_matnr
* Begin note 849832
*                           i_in_me
                            i_out_me
* End note 849832

              RAISING error_in_application.
    ENDIF.

    PERFORM conv2unit_rule_2 USING     l_e_menge_f   " immer in Basis-ME
                                       l_addko
                                       l_umrez
                                       l_umren
*$@004 Anfang HW-430276-MWE
                                       l_umrezf
                                       l_umrenf
*$@004 Ende HW-430276-MWE
                             CHANGING  l_e_menge_f.

  ENDIF.
*$@006 Anfang
  IF L_E_MENGE_F > 9999999999.
    RAISE ERROR_IN_APPLICATION.
  ENDIF.
*$@006 Ende

  e_menge = l_e_menge_f.

*$  DATA: L_MENGE TYPE F.
*$
*$  MOVE I_MENGE TO L_MENGE.
*$
*$ PERFORM READ_MARA USING I_MATNR.
*$
*$  IF SY-SUBRC = 0.
*$    PERFORM CONV2UNIT USING L_MENGE
*$                            I_IN_ME
*$                            I_OUT_ME.
*$    MOVE L_MENGE TO E_MENGE.
*$  ELSE.
*$    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*$            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4
*$    RAISING ERROR_IN_APPLICATION.
*$  ENDIF.
*$@001 Ende

ENDFUNCTION.


*Messages
*----------------------------------------------------------
*
* Message class: 6R
*000   Plant & does not exist
*007   For material &, no unit of measure &
*017   No other units of measure exist
*018   Plant & does not exist
*020   Rounding profile & does not exist
*057   "To qty" cannot be less than "from qty"
*059   Unit of measure does not exist for this material
*066   A valid plant has not been entered
*067   No entry exists in MARC for plant &1 and material &2.
*069   The quantity entered (in &1) must also be entered in the base unit &2
*070   No rounding profile for plant &1 and material &2 maintained in MARC
*071   Function module &1 called with an invalid control code &2
*074   The rounding method and rounding profile are not to be entered
*076   Direct reading from database with buffering switched on is not allowed
*078   The rounding profile and language key are not to be entered
*079   Simulation not possible. No data exists for entry
*082   At least one of the entry parameters <= 0 when &1 called up!
*083   At least one of the entry parameters < 0 when &1 called up!
*093   Rounding not possible due to missing rounding parameters!
*094   There is no conversion factor for material &1 and unit of measure &2!
*
* Message class: CZ
*096   For sales org. &1, distribution channel &2 is not allowed
*097   For sales org. & division & is not allowed
*098   Division & does not exist
*
* Message class: LUMER
*000   Enter rounding profile for application-independent simulation
*001   Enter the application for application-dependent simulation
*002   Enter material
*003   Do not simulate more than &1 values due to long response times
*004   Replace old function module call for &1 with &2
*
* Message class: M3
*118   Sales organization & does not exist
*122   Distribution channel & does not exist
*200   Material & does not exist in plant &
*240   Customer & does not exist
*593   Enter either a rounding value or rounding profile
*687   Rounding profile & does not exist
*853   No authorization for this transaction
*
* Message class: MW
*114   Item category & does not exist
*
* Message class: RPUDB
*001   Definition for unit of measure group &1 not found
*002   General material data for material &1 not found
*003   Supplier master data for supplier &1 not found
*005   Unit of measure &1 not defined for material &2
*007   No short text maintained for rounding profile &1, plant &2 in language &3
*008   Rounding profile &1 not defined in plant &2
*
* Message class: RPUGEN
*001   Error occurred in function module &1
*002   FM &1 called with wrong or missing input parameter values
*003   Error occurred in user exit &1 of function module &2
*004   FM &1 called with invalid input parameters (&2 = &3)
*006   Error in method &1
*
* Message class: VO
*738   Material &: sales data for &/& is missing

*
* 
