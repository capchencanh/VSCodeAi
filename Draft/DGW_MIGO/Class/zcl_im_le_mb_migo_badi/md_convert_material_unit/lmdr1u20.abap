FUNCTION ZMD_CONVERT_MATERIAL_UNIT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_MATNR) LIKE  MARA-MATNR
*"     VALUE(I_IN_ME) LIKE  MARA-MEINS
*"     VALUE(I_OUT_ME) LIKE  MARA-MEINS
*"     VALUE(I_MENGE) LIKE  EKPO-MENGE
*"  EXPORTING
*"     VALUE(E_MENGE) TYPE  ATFLV
*"  EXCEPTIONS
*"      ERROR_IN_APPLICATION
*"      ERROR
*"----------------------------------------------------------------------
*{   INSERT         DS4K908156                                        1
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

*}   INSERT
ENDFUNCTION.

*
* 
