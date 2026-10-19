FUNCTION ZCORE_FM_CHECK_BANF_EKGRP.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(IT_EKGRP) TYPE  ZCORE_TT_RSELOPTION_EKGRP
*"--------------------------------------------------------------------
TYPES: BEGIN OF LTY_T024,
           EKGRP TYPE T024-EKGRP,
         END OF LTY_T024,
         LTY_T_T024  TYPE STANDARD TABLE OF  LTY_T024.

  DATA:
        LT_EKGRP TYPE          LTY_T_T024,
        LS_EKGRP TYPE          LTY_T024,
        LS_DATA  TYPE          ZCORE_ST_RSELOPTION_EKGRP.

  "Pur. Group
  SELECT EKGRP
    INTO TABLE LT_EKGRP
    FROM T024.
  LOOP AT LT_EKGRP INTO LS_EKGRP.
    AUTHORITY-CHECK OBJECT 'M_BANF_EKG'
             ID 'ACTVT' FIELD '03'
             ID 'EKGRP' FIELD LS_EKGRP-EKGRP.
    IF SY-SUBRC = 0.
      LS_DATA-SIGN = 'I'.
      LS_DATA-OPTION = 'EQ'.
      LS_DATA-LOW = LS_EKGRP-EKGRP.
      APPEND LS_DATA TO IT_EKGRP.
    ENDIF.
  ENDLOOP.





ENDFUNCTION.

*
* 
