CLASS zcl_cs1_insert_other_tables DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cs1_insert_other_tables IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA lt_service TYPE TABLE OF zcs1_service.

*    "" Datenbanktabelle deleten
**    DELETE FROM zcs1_customers where customerid = '208'.
*    DELETE FROM zcs1_customers WHERE customerid IN ('208', '207', '206').
    DELETE FROM zcs1_customers.

    IF sy-subrc = 0.
      DATA(lv_counter) = 1.
    ENDIF.

    DATA(lv_dat) = cl_abap_context_info=>get_system_date( ).
    out->write( lv_dat ).

    DELETE FROM zcs1_import_err.

    IF sy-subrc = 0.
      lv_counter = lv_counter + 1.
    ENDIF.
*    RETURN.
*
*    lt_service = VALUE #(
*          ( id = 'RegularExpression' id_value = '222'     active = 'X' )
*          ( id = 'COUNTRY'           id_value = 'DE'      active = 'X' )
*          ( id = 'CURRENCY'          id_value = 'EUR'     active = 'X' )
*          ( id = 'LANGUAGE'          id_value = 'DE'      active = 'X' )
*                          ).


  ENDMETHOD.
ENDCLASS.
