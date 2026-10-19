*&---------------------------------------------------------------------*
*& Class ZCL_WM_UOM_CONVERT
*&   Quy doi so luong tu DVT co so sang 1 DVT khac khai bao tren vat tu.
*&   Dung chung cho cac bao cao kho (ZWM2D, ZWM11, ZMM60): sua class nay
*&   phai kiem thu hoi quy ca ba bao cao.
*&---------------------------------------------------------------------*
CLASS ZCL_WM_UOM_CONVERT DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF TY_ITEM,
        MATNR    TYPE MATNR,
        MEINS    TYPE MEINS,
        MENGE    TYPE MENGE_D,
        MENGE_CV TYPE MENGE_D,
        FOUND    TYPE ABAP_BOOL,
      END OF TY_ITEM,
      TT_ITEM TYPE STANDARD TABLE OF TY_ITEM WITH EMPTY KEY.

*   Quy doi tung dong; FOUND = abap_false khi vat tu khong khai bao DVT dich
*   (khong quy doi bac cau, khong suy dien he so).
    CLASS-METHODS CONVERT_ITEMS
      IMPORTING IV_UNIT_TO TYPE MEINS
      CHANGING  CT_ITEMS   TYPE TT_ITEM.

ENDCLASS.


CLASS ZCL_WM_UOM_CONVERT IMPLEMENTATION.

  METHOD CONVERT_ITEMS.

    TYPES: BEGIN OF LTY_KEY,
             MATNR TYPE MATNR,
           END OF LTY_KEY.

    DATA: LT_KEY TYPE SORTED TABLE OF LTY_KEY WITH UNIQUE KEY MATNR,
          LT_HAS TYPE HASHED TABLE OF LTY_KEY WITH UNIQUE KEY MATNR,
          LV_OUT TYPE MENGE_D.

    CHECK CT_ITEMS IS NOT INITIAL.

*   Vat tu nao co khai bao DVT dich: doc 1 lan cho ca danh sach
    LOOP AT CT_ITEMS ASSIGNING FIELD-SYMBOL(<LFS_ITEM>).
      INSERT VALUE #( MATNR = <LFS_ITEM>-MATNR ) INTO TABLE LT_KEY.
    ENDLOOP.

    SELECT M~MATNR
      FROM @LT_KEY AS K
      INNER JOIN MARM AS M ON M~MATNR = K~MATNR
      WHERE M~MEINH = @IV_UNIT_TO
      GROUP BY M~MATNR
      INTO TABLE @LT_HAS.

    LOOP AT CT_ITEMS ASSIGNING <LFS_ITEM>.
      CLEAR: <LFS_ITEM>-MENGE_CV, <LFS_ITEM>-FOUND.

      READ TABLE LT_HAS WITH TABLE KEY MATNR = <LFS_ITEM>-MATNR TRANSPORTING NO FIELDS.
      CHECK SY-SUBRC = 0.

      IF <LFS_ITEM>-MEINS = IV_UNIT_TO.
        <LFS_ITEM>-MENGE_CV = <LFS_ITEM>-MENGE.
        <LFS_ITEM>-FOUND    = ABAP_TRUE.
        CONTINUE.
      ENDIF.

      CLEAR LV_OUT.
      CALL FUNCTION 'MD_CONVERT_MATERIAL_UNIT'
        EXPORTING
          I_MATNR              = <LFS_ITEM>-MATNR
          I_IN_ME              = <LFS_ITEM>-MEINS
          I_OUT_ME             = IV_UNIT_TO
          I_MENGE              = <LFS_ITEM>-MENGE
        IMPORTING
          E_MENGE              = LV_OUT
        EXCEPTIONS
          ERROR_IN_APPLICATION = 1
          ERROR                = 2
          OTHERS               = 3.
      IF SY-SUBRC = 0.
        <LFS_ITEM>-MENGE_CV = LV_OUT.
        <LFS_ITEM>-FOUND    = ABAP_TRUE.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
