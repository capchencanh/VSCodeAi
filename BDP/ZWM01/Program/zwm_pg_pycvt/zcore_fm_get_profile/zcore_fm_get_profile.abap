FUNCTION ZCORE_FM_GET_PROFILE.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_NUMBER)
*"     REFERENCE(I_KIND)
*"     REFERENCE(I_BUKRS) OPTIONAL
*"     REFERENCE(I_BELNR) OPTIONAL
*"     REFERENCE(I_GJAHR) OPTIONAL
*"     REFERENCE(I_NATION) OPTIONAL
*"     REFERENCE(I_COUNTRY) OPTIONAL
*"     REFERENCE(I_ADRNR) OPTIONAL
*"     REFERENCE(I_PARVW) OPTIONAL
*"  EXPORTING
*"     REFERENCE(E_NAME)
*"     REFERENCE(E_ADDRESS)
*"     REFERENCE(E_TAX)
*"     REFERENCE(E_TEL_NUMBER)
*"     REFERENCE(E_FAX_NUMBER)
*"     REFERENCE(E_EMAIL)
*"     REFERENCE(E_NAME1)
*"     REFERENCE(E_TITLE)
*"     REFERENCE(E_REMARK)
*"     REFERENCE(E_ONECUS)
*"     REFERENCE(E_PARTNER)
*"     REFERENCE(E_CITY)
*"     REFERENCE(E_MOB_NUMBER)
*"     REFERENCE(E_BANKN)
*"     REFERENCE(E_BRANCH)
*"     REFERENCE(E_COUNTRY)
*"     REFERENCE(E_CMND)
*"--------------------------------------------------------------------
DATA: LS_PROFILE TYPE ZST_PROFILE.
  CLEAR:
  LS_PROFILE.

  LS_PROFILE-NUMBER       = I_NUMBER.
  LS_PROFILE-KIND         = I_KIND.
  LS_PROFILE-PARVW        = I_PARVW.
  LS_PROFILE-NATION       = I_NATION.
  LS_PROFILE-BUKRS        = I_BUKRS.
  LS_PROFILE-BELNR        = I_BELNR.
  LS_PROFILE-GJAHR        = I_GJAHR.
  LS_PROFILE-GET_COUNTRY  = I_COUNTRY.
  LS_PROFILE-ADRNR        = I_ADRNR.

  CALL FUNCTION 'ZCORE_FM_GET_PROFILE_MULT'
    IMPORTING
      ES_HEAD = LS_PROFILE.

  E_NAME         = LS_PROFILE-NAME         .
  E_ADDRESS      = LS_PROFILE-ADDRESS      .
  E_TAX          = LS_PROFILE-TAX          .
  E_TEL_NUMBER   = LS_PROFILE-TEL_NUMBER   .
  E_FAX_NUMBER   = LS_PROFILE-FAX_NUMBER   .
  E_EMAIL        = LS_PROFILE-EMAIL        .
  E_NAME1        = LS_PROFILE-NAME1        .
  E_TITLE        = LS_PROFILE-TITLE        .
  E_REMARK       = LS_PROFILE-REMARK       .
  E_ONECUS       = LS_PROFILE-ONECUS       .
  E_PARTNER      = LS_PROFILE-PARTNER      .
  E_CITY         = LS_PROFILE-CITY1        .
  E_MOB_NUMBER   = LS_PROFILE-MOBILE_NUMBER.
  E_BANKN        = LS_PROFILE-BANKN        .
  E_BRANCH       = LS_PROFILE-BRANCH       .
  E_COUNTRY      = LS_PROFILE-COUNTRY      .
  E_CMND         = LS_PROFILE-CMND      .





ENDFUNCTION.


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   You are not authorized with company code !
*
* Message class: WMOD
*030   Error reading database table &1

*
*
