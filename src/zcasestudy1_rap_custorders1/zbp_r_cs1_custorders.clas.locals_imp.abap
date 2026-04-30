CLASS lhc_zr_cs1_custorders DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR custorders
        RESULT result,

      getOrderTotal FOR DETERMINE ON SAVE
        IMPORTING
            keys FOR custorders~getOrderTotal,

      CurrencyTarget FOR VALIDATE ON SAVE
            IMPORTING keys FOR CUSTORDERS~CurrencyTarget.
ENDCLASS.

CLASS lhc_zr_cs1_custorders IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.



   METHOD getOrderTotal.
    " Lokale Variablen für das Fehler-Handling
    DATA reported_record LIKE LINE OF reported-custorders.

    " 1. Daten der betroffenen Bestellungen aus dem Buffer lesen
    READ ENTITIES OF zr_cs1_custorders IN LOCAL MODE
      ENTITY custorders
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders ASSIGNING FIELD-SYMBOL(<fs_order>).

      " A) VORBEREITUNG: Prozentualen Discount prüfen und berechnen
      DATA(lv_discount_perc) = COND zorder_total1( WHEN <fs_order>-Discount IS INITIAL THEN 0
                                                   ELSE <fs_order>-Discount ).

      DATA(lv_net_local) = CONV zorder_total1( <fs_order>-OrderTotal * ( 1 - ( lv_discount_perc / 100 ) ) ).

      DATA(lv_target_curr) = COND zcurrency_target1( WHEN <fs_order>-CurrencyTarget IS INITIAL THEN 'USD'
                                                     ELSE <fs_order>-CurrencyTarget ).
      " B) WÄHRUNGSUMRECHNUNG
      TRY.
          DATA lv_order_target_val TYPE zorder_total1.

          cl_exchange_rates=>convert_to_foreign_currency(
            EXPORTING
              date             = <fs_order>-OrderDate
              foreign_currency = lv_target_curr
              local_amount     = lv_net_local
              local_currency   = <fs_order>-Currency
            IMPORTING
              foreign_amount   = lv_order_target_val
          ).

          " --- REKURSIONSSCHUTZ ---
          IF <fs_order>-OrderTotalTarget <> lv_order_target_val OR
             <fs_order>-CurrencyTarget   <> lv_target_curr.

              MODIFY ENTITIES OF zr_cs1_custorders IN LOCAL MODE
                ENTITY custorders
                  UPDATE FIELDS ( OrderTotalTarget CurrencyTarget )
                  WITH VALUE #( ( %tky              = <fs_order>-%tky
                                  OrderTotalTarget  = lv_order_target_val
                                  CurrencyTarget    = lv_target_curr ) ).
          ENDIF.

        CATCH cx_exchange_rates INTO DATA(lx_ex).
          CLEAR reported_record.
          reported_record-%tky = <fs_order>-%tky.
          reported_record-%element-currencytarget = if_abap_behv=>mk-on.
          reported_record-%msg = zcx_cs1_customer_failed=>new_message(
                          i_textid   = zcx_cs1_customer_failed=>Umrechnungsfehler
                          i_severity = if_abap_behv_message=>severity-error
                          i_v1       = <fs_order>-currency
                          i_v2       = lv_target_curr
                          i_v3       = <fs_order>-orderdate
                          i_v4       = <fs_order>-orderid ).
          APPEND reported_record TO reported-custorders.
          CONTINUE.
      ENDTRY.

      " C) AGGREGATION: DB-Daten mit aktuellem Puffer mischen
      " Wir brauchen die OrderID im SELECT, um die aktuelle Zeile im Loop zu identifizieren
      SELECT orderid, order_total, discount, order_total_target
        FROM zcs1_custorders
        WHERE customerid = @<fs_order>-customerid
        INTO TABLE @DATA(lt_all_orders).

      DATA(lv_cust_sum_local) = VALUE zorder_total1( ).
      DATA(lv_cust_sum_target) = VALUE zorder_total1( ).

      " Flag, um zu prüfen, ob der aktuelle Datensatz in der DB gefunden wurde
      DATA(lv_current_order_found) = abap_false.

      LOOP AT lt_all_orders ASSIGNING FIELD-SYMBOL(<fs_row_sum>).
        " ÄNDERUNG: Falls die Zeile die aktuelle Bestellung ist, Puffer-Werte erzwingen
        IF <fs_row_sum>-orderid = <fs_order>-orderid.
          lv_current_order_found = abap_true.
          <fs_row_sum>-order_total = <fs_order>-OrderTotal.
          <fs_row_sum>-discount = <fs_order>-Discount.
          <fs_row_sum>-order_total_target = lv_order_target_val.
        ENDIF.

        DATA(lv_row_disc_perc) = COND zorder_total1( WHEN <fs_row_sum>-discount IS INITIAL THEN 0 ELSE <fs_row_sum>-discount ).
        lv_cust_sum_local  += <fs_row_sum>-order_total * ( 1 - ( lv_row_disc_perc / 100 ) ).
        lv_cust_sum_target += <fs_row_sum>-order_total_target.
      ENDLOOP.

      " ÄNDERUNG: Falls die Bestellung brandneu ist (noch nicht in DB), manuell addieren
      IF lv_current_order_found = abap_false.
        lv_cust_sum_local  += lv_net_local.
        lv_cust_sum_target += lv_order_target_val.
      ENDIF.

      " D) UPDATE KUNDE
      MODIFY ENTITIES OF zr_cs1_customers
        ENTITY customers
          UPDATE FIELDS ( SalesVolume SalesVolumeTarget )
          WITH VALUE #( ( Customerid        = <fs_order>-Customerid
                          SalesVolume       = lv_cust_sum_local
                          SalesVolumeTarget = lv_cust_sum_target ) )
        FAILED DATA(ls_cust_failed)
        REPORTED DATA(ls_cust_reported).

      IF ls_cust_failed IS NOT INITIAL.
        CLEAR reported_record.
        reported_record-%tky = <fs_order>-%tky.
        reported_record-%element-customerid = if_abap_behv=>mk-on.
        reported_record-%msg = zcx_cs1_customer_failed=>new_message(
                                 i_textid   = zcx_cs1_customer_failed=>KD_Order_Sales_Volume
                                 i_severity = if_abap_behv_message=>severity-error
                                 i_v1       = <fs_order>-customerid
                                 i_v2       = <fs_order>-orderid ).
        APPEND reported_record TO reported-custorders.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD CurrencyTarget.
    " 1. Betroffene Daten lesen
    READ ENTITIES OF ZR_CS1_CUSTORDERS IN LOCAL MODE
      ENTITY CUSTORDERS
        FIELDS ( CurrencyTarget )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders INTO DATA(ls_order).
      " 2. Prüfen, ob die Zielwährung gefüllt ist
      IF ls_order-CurrencyTarget IS INITIAL.
        " Hier ist FAILED erlaubt!
        APPEND VALUE #( %tky = ls_order-%tky ) TO failed-custorders.

        " Fehlermeldung ausgeben
        APPEND VALUE #( %tky = ls_order-%tky
                %msg = zcx_cs1_customer_failed=>new_message(
                         i_textid   = zcx_cs1_customer_failed=>CurrencyTarget_missing " Nutzt deine Konstante
                         i_severity = if_abap_behv_message=>severity-error )
                %element-currencytarget = if_abap_behv=>mk-on )
          TO reported-custorders.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
