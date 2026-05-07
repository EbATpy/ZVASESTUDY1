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


    IF abap_true = abap_false. "deactiviert

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

      RETURN.

      DATA lt_customers TYPE TABLE OF zcs1_customers.

      lt_customers = VALUE #(
         ( client = sy-mandt customerid = '000001' first_name = 'Max'  last_name = 'Muster' )
         ( client = sy-mandt customerid = '000002' first_name = 'Maxi' last_name = 'Musterfrau' )
         ( client = sy-mandt customerid = '000005' first_name = 'Max'  last_name = 'Muster' )
                               ).
      " 3. Einfügen in die Tabelle
      INSERT zcs1_customers FROM TABLE @lt_customers.

      IF sy-subrc = 0.
        lv_counter = lv_counter + 1.
      ENDIF.
      out->write( lv_counter ).


*    lt_service = VALUE #(
*          ( id = 'RegularExpression' id_value = '222'     active = 'X' )
*          ( id = 'COUNTRY'           id_value = 'DE'      active = 'X' )
*          ( id = 'CURRENCY'          id_value = 'EUR'     active = 'X' )
*          ( id = 'LANGUAGE'          id_value = 'DE'      active = 'X' )
*                          ).
    ENDIF.


    IF abap_true = abap_true. "activiert


      DELETE  FROM  zcs1_custorders.

INSERT zcs1_custorders FROM TABLE @( VALUE #(
  " AUDI Autohaus ... 000003
  ( client = '100' orderid = '000006' customerid = '000003' order_date = '20260429' order_total = '4200.00' discount = '1.00' status = 'BA' )
  ( client = '100' orderid = '000007' customerid = '000003' order_date = '20260429' order_total = '2800.00' discount = '1.00' status = 'BB' )
  ( client = '100' orderid = '000008' customerid = '000003' order_date = '20260429' order_total = '4200.00' discount = '1.00' status = 'BN' )
  ( client = '100' orderid = '000009' customerid = '000003' order_date = '20260429' order_total = '2800.00' discount = '1.00' status = 'BO' )

  " AUTO-DIREKT A... 000004
  ( client = '100' orderid = '000010' customerid = '000004' order_date = '20260429' order_total = '7100.00' discount = '3.00' status = 'BO' ) " war 000008

  " Adomeit Herbert 000005
  ( client = '100' orderid = '000011' customerid = '000005' order_date = '20260429' order_total = '1500.00' discount = '1.00'  status = 'BN' ) " war 000009
  ( client = '100' orderid = '000012' customerid = '000005' order_date = '20260429' order_total = '2300.00' discount = '2.00'  status = 'BA' ) " war 000010

  " Ahlfeld Werner 000006
  ( client = '100' orderid = '000013' customerid = '000006' order_date = '20260429' order_total = '999.00' discount = '1.00'  status = 'BA' ) " war 000011

  " Ariana Automo... 000007
  ( client = '100' orderid = '000014' customerid = '000007' order_date = '20260429' order_total = '4500.00' discount = '2.00'  status = 'BO' ) " war 000012
  ( client = '100' orderid = '000015' customerid = '000007' order_date = '20260429' order_total = '1200.00' discount = '1.00'  status = 'BA' ) " war 000013

  " Autohaus Albert... 000008
  ( client = '100' orderid = '000016' customerid = '000008' order_date = '20260429' order_total = '6200.00' discount = '3.00'  status = 'BA' ) " war 000014

  " Autohaus Bargt... 000009
  ( client = '100' orderid = '000017' customerid = '000009' order_date = '20260429' order_total = '3100.00' discount = '1.00'  status = 'BA' ) " war 000015

  " Autohaus Barm... 000010
  ( client = '100' orderid = '000018' customerid = '000010' order_date = '20260429' order_total = '8000.00' discount = '4.00'  status = 'BN' ) " war 000016

  " Autohaus Bergst... 000011
  ( client = '100' orderid = '000019' customerid = '000011' order_date = '20260429' order_total = '1750.00' discount = '1.00'  status = 'BO' ) " war 000017

  " Autohaus Bergst... 000012
  ( client = '100' orderid = '000020' customerid = '000012' order_date = '20260429' order_total = '5000.00' discount = '2.00'  status = 'BN' ) " war 000018
  ( client = '100' orderid = '000021' customerid = '000012' order_date = '20260429' order_total = '2200.00' discount = '1.00'  status = 'BB' ) " war 000019
) ).


    ENDIF.


  ENDMETHOD.
ENDCLASS.
