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
      " Falls leer, wird 0 angenommen.
      DATA(lv_discount_perc) = COND zorder_total1( WHEN <fs_order>-Discount IS INITIAL THEN 0
                                                   ELSE <fs_order>-Discount ).

      " NETTO-BERECHNUNG: Betrag * (1 - Prozentsatz/100)
      " CONV stellt sicher, dass kaufmännisch auf 2 Stellen gerundet wird (Festpunktarithmetik)
      DATA(lv_net_local) = CONV zorder_total1( <fs_order>-OrderTotal * ( 1 - ( lv_discount_perc / 100 ) ) ).

      " Default auf USD, falls nichts eingegeben wurde
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

          " --- REKURSIONSSCHUTZ: Nur MODIFY, wenn sich Werte geändert haben ---
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

      " C) AGGREGATION: Alle Bestellungen des Kunden für die Gesamtsumme lesen
      SELECT order_total, discount, order_total_target
        FROM zcs1_custorders
        WHERE customerid = @<fs_order>-customerid
        INTO TABLE @DATA(lt_all_orders).

      DATA(lv_cust_sum_local) = VALUE zorder_total1( ).
      DATA(lv_cust_sum_target) = VALUE zorder_total1( ).

      " Summiere über alle gefundenen Datensätze des Kunden
      LOOP AT lt_all_orders INTO DATA(ls_row).
        " RABATT-LOGIK auch hier prozentual anwenden (abgefangen mit 0 falls leer)
        DATA(lv_row_disc_perc) = COND zorder_total1( WHEN ls_row-discount IS INITIAL THEN 0 ELSE ls_row-discount ).

        " Addition der Netto-Werte (Lokal) und der bereits umgerechneten Werte (Target)
        lv_cust_sum_local  += ls_row-order_total * ( 1 - ( lv_row_disc_perc / 100 ) ).
        lv_cust_sum_target += ls_row-order_total_target.
      ENDLOOP.

      " D) UPDATE KUNDE (EML Paketübergreifend)
      MODIFY ENTITIES OF zr_cs1_customers
        ENTITY customers
          UPDATE FIELDS ( SalesVolume SalesVolumeTarget )
          WITH VALUE #( ( Customerid        = <fs_order>-Customerid
                          SalesVolume       = lv_cust_sum_local
                          SalesVolumeTarget = lv_cust_sum_target ) )
        FAILED DATA(ls_cust_failed)
        REPORTED DATA(ls_cust_reported).

      " Fehler-Mapping vom Kunden zurück auf die Bestellung
      IF ls_cust_failed IS NOT INITIAL.
        CLEAR reported_record.
        reported_record-%tky = <fs_order>-%tky.
        " Element auf die ID mappen, die das Problem verursacht
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
