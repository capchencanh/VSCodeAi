*----------------------------------------------------------------------*
***INCLUDE LMDR1F05 .
*----------------------------------------------------------------------*
*-----------------------------------------------------------------------
*- Änderungen:
*- Marke Datum     Rel. Autor       Text
*- @xxx  xx.xx.xx  xxxx xxxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-       08.04.98  4.0c welterm     Alg. für die neue Rundungsmethode
*-                                  4 = Auf- und Abschlag
*- @002  29.07.98  4.5B Doneyer     Fehler beim Auf-Abschlagsrunden
*- @003  24.09.01  470  mbi         Entfernen von nicht mehr
*-                                  durchlaufenem Coding, das aufgrund
*-                                  der Überarbeitung des Bausteins zur
*-                                  Simulation von Rundungsprofilen
*-                                  (MD_SIMU_DYN_RUND_PROFIL) entstanden
*-                                  ist
*-----------------------------------------------------------------------

*$@003 mbi 4.70 - Anfang
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  ROUNDING_UP_AND_DOWN
*$*&--------------------------------------------------------------------
*$-*
*$*       Führe das Runden mit Auf- und Abschlag surch
*$*---------------------------------------------------------------------
*$-*
*$*      -->P_G_U02  Eingabeparameter des FB  (by reference)
*$*      <--P_G_U02  Ausgabeparameter des FB  (by reference)
*$*---------------------------------------------------------------------
*$-*
*$FORM ROUNDING_UP_AND_DOWN
*$                    CHANGING P_G_U02 LIKE G_U02.
*$
*$  DATA: L_RDPR LIKE RDPR OCCURS 0
*$               WITH HEADER LINE.
*$
*$  CLEAR L_RDPR[].
*$
*$*                *** Bestimme alle Einträge zu dem Rundungsprofil
*$  PERFORM READ_PROFIL_ITEMS TABLES L_RDPR
*$                            USING  P_G_U02.
*$
*$*                *** Sortiere die Sätze des Rundungsprofils
*$*                *** nach den Schwellenwerten abszteigend =>
*$*                ***  Beginn mit den größten Werten
*$  SORT L_RDPR BY BDMNG DESCENDING.
*$
*$*                *** Bestimme den größten Schwellenwert der kleiner
*$oder
*$*                *** gleich der Eingabemenge ist
*$  LOOP AT L_RDPR.
*$
*$    IF P_G_U02-I_MENGE >= L_RDPR-BDMNG.
*$
*$*                *** Schwellenwert gefunden => Wende Auf oder Abschlag
*$*                ***                           des Schwellenwerts
*$*                ***                           auf die Menge an
*$*@002-Anfang
*$*     P_G_U02-E_MENGE =   P_G_U02-I_MENGE
*$      P_G_U02-E_MENGE =   P_G_U02-E_MENGE
*$*@002-Ende
*$                        * ( 1 + ( L_RDPR-VORMG / 100 ) ).
*$*                *** Rundungsgrund setzen
*$      PERFORM RUNDUNGSGRUND USING MDR1P_C_AUF_AB_SCHLAG.
*$
*$*                *** Beende die Schleife
*$      EXIT.
*$
*$    ENDIF.
*$
*$  ENDLOOP.
*$
*$ENDFORM.                    " ROUNDING_UP_AND_DOWN
*$@003 mbi 4.70 - Ende

*$@003 mbi 4.70 - Anfang
*$
*$*&--------------------------------------------------------------------
*$-*
*$*&      Form  READ_PROFIL_ITEMS
*$*&--------------------------------------------------------------------
*$-*
*$*       Lese alle Einträge
*$*---------------------------------------------------------------------
*$-*
*$*      -->P_G_U02    Eingabeparameter des FB
*$*      <--P_L_RDPR   Einträge zu dem aktuellen Profil
*$*---------------------------------------------------------------------
*$-*
*$FORM READ_PROFIL_ITEMS TABLES   P_T_RDPR        STRUCTURE  RDPR
*$                       USING    VALUE(P_G_U02)  LIKE       G_U02.
*$
*$  DATA L_WERKS LIKE RDPR-WERKS.
*$
*$  CLEAR P_T_RDPR[].
*$
*$*                *** 1. Lesen des Rundungsprofils zum Werk komplett
*$  PERFORM CALL_T_MD_RDPR_READ TABLES    P_T_RDPR
*$                              USING     P_G_U02-I_WERK
*$                                        P_G_U02-I_RDPRF.
*$
*$*                *** 2. Lesen des Rundungsprofils ohne Werk,
*$*                ***    wenn mit Werk kein Satz existiert
*$  IF SY-SUBRC <> 0.
*$
*$    CLEAR: L_WERKS.
*$
*$    PERFORM CALL_T_MD_RDPR_READ TABLES    P_T_RDPR
*$                                USING     L_WERKS            " =
*$SPACES
*$                                          P_G_U02-I_RDPRF.
*$
*$    IF SY-SUBRC <> 0.
*$      MESSAGE E063 RAISING RDPR_NOT_FOUND.
*$    ENDIF.
*$
*$  ENDIF.
*$
*$ENDFORM.                    " READ_PROFIL_ITEMS
*$@003 mbi 4.70 - Ende

*
* 
