FUNCTION mdr1_determine_round_params.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      CH_T_QT_UNITS TYPE  MDR1TOUTALLOWEDQTUNIT
*"  CHANGING
*"     VALUE(CH_S_MARA) TYPE  MARA OPTIONAL
*"     VALUE(CH_S_GENERAL) TYPE  MDR1INSINGLEROUND
*"     VALUE(CH_S_RESULTS) TYPE  MDR1OUTSINGLEROUND
*"     VALUE(CH_S_EINA) TYPE  EINA OPTIONAL
*"     VALUE(CH_S_EINE) TYPE  EINE OPTIONAL
*"     VALUE(CH_S_MARC) TYPE  MARC OPTIONAL
*"     VALUE(CH_S_MARC_2) TYPE  MARC OPTIONAL
*"     VALUE(CH_S_MVKE) TYPE  MVKE OPTIONAL
*"     VALUE(CH_S_KNMT) TYPE  KNMT OPTIONAL
*"     VALUE(CH_S_KNVV) TYPE  KNVV OPTIONAL
*"  EXCEPTIONS
*"      NO_ROUND
*"      ERROR
*"----------------------------------------------------------------------
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       07.09.01  470  mbi         Grundversion
*-----------------------------------------------------------------------

*                *** teste zunächst, ob die allgemeinen Materialdaten
*                *** aus der Tabelle Mara schon gelesen wurden. Falls
*                *** nicht, lese diese Daten zunächst.
"--------------------------------------------------------
" shall not be executable as long as Retail is hidden
*DATA: lv_is_s4h TYPE abap_bool.
*
*CALL METHOD cl_cos_utilities=>is_s4h
*  RECEIVING
*    rv_is_s4h = lv_is_s4h.
*
*IF lv_is_s4h = abap_true.
*
*  sy-subrc = 2.
*  sy-msgid = 'WTADDI'.
*  sy-msgno = '456'.
*  sy-msgty = 'E'.
*  sy-msgv1 = 'Feature not supported'.
*
*  WRITE: / 'Feature not supported'(004).
*  RETURN.
*ENDIF.
"----------------------------------------------------


  IF ch_s_mara IS INITIAL.

    PERFORM read_mara_single USING     ch_s_general-matnr
                             CHANGING  ch_s_mara.

  ENDIF.

  PERFORM read_data_u12   TABLES   ch_t_qt_units
                          USING    ch_s_mara
                          CHANGING ch_s_general
                                   ch_s_results
                                   ch_s_eina
                                   ch_s_eine
                                   ch_s_marc
                                   ch_s_marc_2
                                   ch_s_mvke
                                   ch_s_knmt
                                   ch_s_knvv.

ENDFUNCTION.

*
* 
