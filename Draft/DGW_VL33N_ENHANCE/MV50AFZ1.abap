***INCLUDE MV50AFZ1 .

************************************************************************
*                                                                      *
* This include is reserved for user modifications                      *
*                                                                      *
* Forms for delivery processing                                        *
*                                                                      *
* The name of modification modules should begin with 'ZZ'.             *
*                                                                      *
************************************************************************

*---------------------------------------------------------------------*
*       FORM ZZEXAMPLE                                                *
*---------------------------------------------------------------------*
*       text......................................                    *
*---------------------------------------------------------------------*
*FORM ZZEXAMPLE.

*  ...

*ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM USEREXIT_DELETE_DOCUMENT                                 *
*---------------------------------------------------------------------*
*       This userexit can be used to delete data in additional tables *
*       when a delivery is deleted.                                   *
*                                                                     *
*      This form is called in dialog at the end of form BELEG_LOESCHEN*
*      just before form BELEG_SICHERN is performed to delete the      *
*      datas on the database.                                         *
*                                                                     *
*---------------------------------------------------------------------*
FORM USEREXIT_DELETE_DOCUMENT.

ENDFORM.
*eject

*---------------------------------------------------------------------*
*       FORM USEREXIT_MOVE_FIELD_TO_LIKP                              *
*---------------------------------------------------------------------*
*       This userexit can be used to move some fields into the        *
*       delivery header workaerea LIKP.                               *
*       This form is called, when a header is created                 *
*       This form is called at the end of form LIKP_FUELLEN.          *
*                                                                     *
*---------------------------------------------------------------------*
FORM USEREXIT_MOVE_FIELD_TO_LIKP.

*  LIKP-zzfield = xxxx-zzfield2.

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""$"$\SE:(1) Form USEREXIT_MOVE_FIELD_TO_LIKP, End                                                                                                             A
*$*$-Start: (1)---------------------------------------------------------------------------------$*$*
ENHANCEMENT 1  ZENH_OD_PGIDDATEISBILLINGDATE.    "active version
  " Copy from PO to Inbound
  likp-zzshd    = ekko-zzshd.
  likp-zzserihd = ekko-zzserihd.
ENDENHANCEMENT.
*$*$-End:   (1)---------------------------------------------------------------------------------$*$*
ENDFORM.
*eject

*---------------------------------------------------------------------*
*       FORM USEREXIT_MOVE_FIELD_TO_LIPS                              *
*---------------------------------------------------------------------*
*       This userexit can be used to move some fields into the        *
*       delivery item workaerea LIPS                                  *
*       This form is called, when an item is created                  *
*                                                                     *
*                                                                     *
*       This form is called at the end of form LIPS_FUELLEN.          *
*                                                                     *
*---------------------------------------------------------------------*
FORM USEREXIT_MOVE_FIELD_TO_LIPS.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""$"$\SE:(2) Form USEREXIT_MOVE_FIELD_TO_LIPS, Start                                                                                                           A
*$*$-Start: (2)---------------------------------------------------------------------------------$*$*
ENHANCEMENT 4  ZENH_OD_PGIDDATEISBILLINGDATE.    "active version

ENDENHANCEMENT.
*$*$-End:   (2)---------------------------------------------------------------------------------$*$*

*  LIPS-zzfield = xxxx-zzfield2.

ENDFORM.
*eject


*---------------------------------------------------------------------*
*       FORM USEREXIT_NUMBER_RANGE                                    *
*---------------------------------------------------------------------*
*       This userexit can be used to determine the numberranges for   *
*       the internal document number.                                 *
*                                                                     *
*       US_RANGE_INTERN - internal number range                       *
*                                                                     *
*       This form is called from form BELEG_SICHERN                   *
*                                                                     *
*---------------------------------------------------------------------*
FORM USEREXIT_NUMBER_RANGE USING US_RANGE_INTERN.

* Example: Numer range from TVLK like in standard
* US_RANGE_INTERN = TVLK-NUMKI.

ENDFORM.
*eject

*---------------------------------------------------------------------*
*       FORM USEREXIT_READ_DOCUMENT                                   *
*---------------------------------------------------------------------*
*       This userexit can be used to read data in additional tables   *
*       when the program reads a delivery.                            *
*                                                                     *
*       This form is called at the end of form BELEG_LESEN.           *
*                                                                     *
*---------------------------------------------------------------------*
FORM USEREXIT_READ_DOCUMENT.

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""$"$\SE:(3) Form USEREXIT_READ_DOCUMENT, End                                                                                                                  A
*$*$-Start: (3)---------------------------------------------------------------------------------$*$*
ENHANCEMENT 2  ZENH_OD_PGIDDATEISBILLINGDATE.    "active version

ENDENHANCEMENT.
*$*$-End:   (3)---------------------------------------------------------------------------------$*$*
ENDFORM.
*eject

*---------------------------------------------------------------------*
*       FORM USEREXIT_SAVE_DOCUMENT                                   *
*---------------------------------------------------------------------*
*       This userexit can be used to save data in additional tables   *
*       when a document is saved.                                     *
*                                                                     *
*       If field T180-TRTYP contents 'H', the document will be        *
*       created, else it will be changed.                             *
*                                                                     *
*       This form is called at from form BELEG_SICHERN, before COMMIT *
*                                                                     *
*---------------------------------------------------------------------*
FORM USEREXIT_SAVE_DOCUMENT.

* Example:
* CALL FUNCTION 'ZZ_EXAMPLE'
*      IN UPDATE TASK
*      EXPORTING
*           ZZTAB = ZZTAB.

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""$"$\SE:(4) Form USEREXIT_SAVE_DOCUMENT, End                                                                                                                  A
*$*$-Start: (4)---------------------------------------------------------------------------------$*$*
ENHANCEMENT 3  ZENH_OD_PGIDDATEISBILLINGDATE.    "active version


ENDENHANCEMENT.
*$*$-End:   (4)---------------------------------------------------------------------------------$*$*
ENDFORM.
*eject
*---------------------------------------------------------------------*
*       FORM USEREXIT_SAVE_DOCUMENT_PREPARE                           *
*---------------------------------------------------------------------*
*       This userexit can be used for changes or checks, before a     *
*       document is saved.                                            *
*                                                                     *
*       If field T180-TRTYP contents 'H', the document will be        *
*       created, else it will be changed.                             *
*                                                                     *
*       This form is called at the beginning of form BELEG_SICHERN    *
*                                                                     *
*---------------------------------------------------------------------*
FORM USEREXIT_SAVE_DOCUMENT_PREPARE.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""$"$\SE:(5) Form USEREXIT_SAVE_DOCUMENT_PREPARE, Start                                                                                                        A
*$*$-Start: (5)---------------------------------------------------------------------------------$*$*
ENHANCEMENT 1  ZENH_OD_CHECK_PREPARE_SAVE.    "active version

    " 14.06.24: tuan.nguyen4 comment lai enhance nay
    " NGUYEN NHAN: USEREXIT_SAVE_DOCUMENT_PREPARE KO CHO ADD MESSAGE LOAI E => ENHANCE NAY CO XAI MESS LOAI E => DUMP: Screen: Illegal message in sap abap - ticket #23288
    " SOLUTION: CHUYEN PHAN CHECK NAY VAO ZCL_IM_LE_SHP_DELIVERY_PRO~DELIVERY_FINAL_CHECK

*  DATA: LW_VBELN TYPE VBELN.
**    Không cho phép chỉnh sửa Inbound khi đã tick “Approve chuyển kho”
**    Check IB, nếu [Field] Aprrove chuyển kho (ZZAPPROVE) = X thì không cho phép chỉnh sửa IB.
**    Check IB, nếu [Field] Aprrove chuyển kho (ZZAPPROVE) = Null thì cho phép chỉnh sửa IB.
*  IF SY-TCODE EQ 'VL32N'.
*    IF LIKP-ZZAPPROVE = ABAP_TRUE .
*      SELECT SINGLE VBELN
*      INTO LW_VBELN
*      FROM LIKP
*      WHERE VBELN         = LIKP-VBELN
*        AND ZZAPPROVE     = ABAP_TRUE.
*      IF SY-SUBRC = 0.
*        MESSAGE E039(ZMC_MM) WITH LIKP-VBELN.
*      ENDIF.
*    ENDIF.
**      Không cho phép chỉnh sửa Inbound khi đã tick “Approve chuyển kế toán”
**      Check IB, nếu [Field] Aprrove chuyển kế toán (ZZRL_CHUYENKT) = X thì không cho phép chỉnh sửa IB.
**      Check IB, nếu [Field] Aprrove chuyển kế toán (ZZRL_CHUYENKT) = Null thì cho phép chỉnh sửa IB.
*    IF LIKP-ZZRL_CHUYENKT = ABAP_TRUE .
*      SELECT SINGLE VBELN
*      INTO LW_VBELN
*      FROM LIKP
*      WHERE VBELN         = LIKP-VBELN
*        AND ZZRL_CHUYENKT = ABAP_TRUE.
*      IF SY-SUBRC = 0.
*        MESSAGE E040(ZMC_MM) WITH LIKP-VBELN.
*      ENDIF.
*    ENDIF.
*  ENDIF.

    SELECT SINGLE
      fkdat
      FROM vbfa
      INNER JOIN vbrk ON vbrk~vbeln = vbfa~vbeln
      WHERE vbfa~vbelv = @likp-vbeln AND vbfa~vbtyp_n = 'M' AND vbfa~vbtyp_v = 'J'
      INTO @DATA(lw_pgidate).
    IF sy-subrc = 0.
      xlikp-wadat_ist = lw_pgidate.
      likp-wadat_ist = lw_pgidate.
      likp-fkdat = lw_pgidate.
      xlikp-fkdat = lw_pgidate.
      LOOP AT xlikp[] ASSIGNING FIELD-SYMBOL(<lfs_likp>).
        <lfs_likp>-wadat_ist = lw_pgidate.
        <lfs_likp>-fkdat =  lw_pgidate.
      ENDLOOP.
    ENDIF.


ENDENHANCEMENT.
*$*$-End:   (5)---------------------------------------------------------------------------------$*$*

ENDFORM.
*eject


*---------------------------------------------------------------------*
*       FORM USEREXIT_REFRESH_DOCUMENT                                *
*---------------------------------------------------------------------*
*       It is always necessary to refresh user-specific data before   *
*       the next document will be processed.                          *
*       This can be done in this userexit.                            *
*       This userexit can be used to refresh user-specific data       *
*       when the processing of a delivery is finished                 *
*       - after the document is saved                                 *
*       - when you leave the document processing with F3 or F15       *
*       It may be necessary to refresh user-specific data before      *
*       the next document will be processed.                          *
*                                                                     *
*      This form is called in dialog at the end of form               *
*      BELEG_INITIALISIEREN                                           *
*                                                                     *
*---------------------------------------------------------------------*
FORM USEREXIT_REFRESH_DOCUMENT.

* clear: ZZ50A.
* refresh: zzitemtab.

ENDFORM.
*eject
************************************************************************
*&                                                                    &*
*&      Form  USER_EXIT_EARLY_UNLOCK_MM                               &*
*&                                                                    &*
************************************************************************
*       User-Exit to activate the functionality of note 1776807        *
*                                                                      *
*      <  CP_EARLY_UNL  ... Activation flag                          *
*                                                                      *
*  =>   This user exit should be used only to switch on the early MM   *
*       unlock for parallel GI processing.                             *
*  !!!  Please avoid to change any other variable, internal table, or  *
*  !!!  header lines of internal tables and especially do not give     *
*  !!!  messages here.                                                 *
************************************************************************
FORM USER_EXIT_EARLY_UNLOCK_MM CHANGING CP_EARLY_UNL TYPE XFELD.

*  IF XLIKP-VBTYP = CHARJ AND TVLK-AUFER = CHARX.
    CP_EARLY_UNL = 'X'.
*  ENDIF.

ENDFORM.                    " USER_EXIT_EARLY_UNLOCK_MM