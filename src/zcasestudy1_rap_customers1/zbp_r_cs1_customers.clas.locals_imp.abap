CLASS lhc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION IMPORTING  REQUEST requested_authorizations FOR customers RESULT result,
      validateEmail          FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateEmail,
      validatePhone          FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validatePhone,
      validateFax            FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateFax,
      Determinate_getCity    FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~Determinate_getCity,
      validateCurrencyTarget FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateCurrencyTarget,
      SalesVolume            FOR DETERMINE ON MODIFY   IMPORTING keys FOR customers~SalesVolume,
      setDefaults            FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~setDefaults,
      trimEmail              FOR DETERMINE ON MODIFY IMPORTING keys FOR customers~trimEmail,
      CancelOrders           FOR MODIFY              IMPORTING keys
                                                                 FOR ACTION customers~CancelOrders   RESULT result,
      ShowStatistics         FOR MODIFY              IMPORTING keys
                                                                 FOR ACTION customers~ShowStatistics RESULT result.

* validateVip FOR VALIDATE ON SAVE IMPORTING keys FOR CUSTOMERS~validateVip.
* setDefaultCurrencyTarget FOR DETERMINE ON MODIFY   IMPORTING keys FOR customers~setDefaultCurrencyTarget,
* updateOrdersOnCurrencyChange FOR DETERMINE ON SAVE IMPORTING keys FOR customers~updateOrdersOnCurrencyChange,

ENDCLASS.

CLASS lhc_zr_cs1_customers IMPLEMENTATION.

  METHOD Determinate_getCity.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
     ENTITY customers
     FIELDS ( postcode )
     WITH CORRESPONDING #( keys )
     RESULT DATA(lt_customers).

    DATA lt_update TYPE TABLE FOR UPDATE zr_cs1_customers.
    "" Version 2 mit ASSIGNING
    LOOP AT lt_customers  ASSIGNING FIELD-SYMBOL(<ls_customers>). "" <ls_customers> = customers
      " Nur suchen, wenn eine PLZ da ist
      IF <ls_customers>-postcode IS NOT INITIAL.
        SELECT SINGLE FROM zcs1_i_zipcity
          FIELDS city "", country
          WHERE postcode = @<ls_customers>-postcode
          INTO ( @DATA(lv_city) ). "", @DATA(lv_country) ).

        IF sy-subrc = 0.
          " Nur updaten, wenn die Werte in der UI noch nicht passen
          APPEND VALUE #( %tky = <ls_customers>-%tky
                          City = lv_city ) TO lt_update.
          ""Country = lv_country ) TO lt_update.
        ENDIF.
      ENDIF.
    ENDLOOP.

*    "" Version 1 mit into
*    LOOP AT lt_customers  INTO DATA(ls_customers).
*      " Nur suchen, wenn eine PLZ da ist
*      IF ls_customers-postcode IS NOT INITIAL.
*        SELECT SINGLE FROM ZCS04_I_Postcode
*          FIELDS city, country
*          WHERE postcode = @ls_customers-postcode
*          INTO ( @DATA(lv_city), @DATA(lv_country) ).
*
*        IF sy-subrc = 0.
*          " Nur updaten, wenn die Werte in der UI noch nicht passen
*          APPEND VALUE #( %tky = ls_customers-%tky
*                          City = lv_city
*                          Country = lv_country ) TO lt_update.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.

    " 2. Gesammeltes Update (außerhalb des Loops!)
    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
        ENTITY customers
        UPDATE FIELDS ( City ) "" Country rausgenommen
        WITH lt_update.
    ENDIF.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD validateEmail.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
      FIELDS ( Email ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).

    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Email = ''.RETURN. ENDIF.
      IF lo_validator->zif_cs1_validation~is_email_valid( ls_customer-Email ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #(    %tky        = ls_customer-%tky
                           %state_area = 'VALIDATE_EMAIL'
                           %msg        = new_message_with_text(
                              severity = if_abap_behv_message=>severity-error
                              text     = |E-Mail-Adresse: { ls_customer-Email } ist ungültig expected format test@test.de| )
                        %element-Email = if_abap_behv=>mk-on
                        ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validatePhone.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
      FIELDS ( Phone ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).
    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Phone IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Phone = ''.RETURN. ENDIF.
      IF lo_validator->zif_cs1_validation~is_phone_valid( ls_customer-Phone ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #(    %tky        = ls_customer-%tky
                           %state_area = 'VALIDATE_Phone'
                           %msg        = new_message_with_text(
                              severity = if_abap_behv_message=>severity-error
                              text     = |Phone: { ls_customer-Phone } ist ungültig expected format +494055448899| )
                        %element-Phone = if_abap_behv=>mk-on
                      ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateFax.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
      FIELDS ( Fax ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).
    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Fax IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Fax = ''.RETURN. ENDIF.
      IF lo_validator->zif_cs1_validation~is_fax_valid( ls_customer-Fax ) = abap_false.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific
                      ) TO failed-customers.
        APPEND VALUE #(  %tky        = ls_customer-%tky
                         %state_area = 'VALIDATE_Phone'
                         %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = |Fax: { ls_customer-Fax } ist ungültig expected format:e.g. +494055448899| )
                        %element-Fax = if_abap_behv=>mk-on
                      ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD trimEmail.

    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        FIELDS ( Email ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_customers).

    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lv_email) = ls_customer-Email.
      CONDENSE lv_email NO-GAPS.

      IF lv_email <> ls_customer-Email.
        MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
          ENTITY customers
            UPDATE FIELDS ( Email )
            WITH VALUE #( ( %tky  = ls_customer-%tky
                            Email = lv_email ) )
          FAILED   DATA(lt_failed)
          REPORTED DATA(lt_reported).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateCurrencyTarget.
    " 1. Daten der zu prüfenden Kunden einlesen
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        FIELDS ( CurrencyTarget SalesVolumeTarget ) " SalesVolumeTarget mitlesen für den Check
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    " 2. Hilfstabelle für die Datenbank-Abfrage (Existenzprüfung)
    DATA(lt_curr_filter) = lt_customers.
    DELETE lt_curr_filter WHERE CurrencyTarget IS INITIAL.
    SORT lt_curr_filter BY CurrencyTarget.
    DELETE ADJACENT DUPLICATES FROM lt_curr_filter COMPARING CurrencyTarget.

    " 3. Hashed Table für blitzschnellen Zugriff
    TYPES: BEGIN OF ty_s_currency,
             Currency TYPE I_Currency-Currency,
           END OF ty_s_currency.
    DATA lt_valid_currencies TYPE HASHED TABLE OF ty_s_currency WITH UNIQUE KEY Currency.

    " 4. Einmaliger DB-Zugriff für alle Währungen
    IF lt_curr_filter IS NOT INITIAL.
      SELECT Currency FROM I_Currency
        FOR ALL ENTRIES IN @lt_curr_filter
        WHERE Currency = @lt_curr_filter-CurrencyTarget
        INTO TABLE @lt_valid_currencies.
    ENDIF.

    " 5. Validierungsschleife
    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<ls_customer>).

      " --- SPEZIAL-LOGIK FÜR JPY ---
      " Wenn JPY gewählt wurde, ignorieren wir die Fehlermeldung bezüglich
      " der Nachkommastellen bewusst, damit die Determination 'SalesVolume'
      " den Wert im Hintergrund glattziehen kann.
      IF <ls_customer>-CurrencyTarget = 'JPY' AND ( <ls_customer>-SalesVolumeTarget MOD 1 ) <> 0.
        " Wir machen hier einfach NICHTS (kein APPEND to failed).
        " Die Determination übernimmt die Korrektur.
      ENDIF.

      " --- NORMALE FEHLERPRÜFUNG ---

      " Check 1: Pflichtfeldprüfung
      IF <ls_customer>-CurrencyTarget IS INITIAL.
        APPEND VALUE #( %tky = <ls_customer>-%tky ) TO failed-customers.
        APPEND VALUE #( %tky = <ls_customer>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Bitte wählen Sie eine Zielwährung aus.' )
                        %element-currencytarget = if_abap_behv=>mk-on ) TO reported-customers.
        CONTINUE.
      ENDIF.

      " Check 2: Existenzprüfung (z.B. gegen 'ZZZ')
      " Diese Fehlermeldung soll weiterhin erscheinen!
      IF NOT line_exists( lt_valid_currencies[ Currency = <ls_customer>-CurrencyTarget ] ).
        APPEND VALUE #( %tky = <ls_customer>-%tky ) TO failed-customers.
        APPEND VALUE #( %tky = <ls_customer>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Währung { <ls_customer>-CurrencyTarget } ist nicht zulässig!| )
                        %element-currencytarget = if_abap_behv=>mk-on ) TO reported-customers.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD SalesVolume.
    " --- SCHRITT 1: MASSENVERARBEITUNG (READ) ---
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        FIELDS ( SalesVolume Currency CurrencyTarget )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers)
      FAILED DATA(lt_failed_read).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    " --- SCHRITT 2: DER LOOP ---
    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<fs_customer>).

      IF <fs_customer>-SalesVolume IS INITIAL OR <fs_customer>-CurrencyTarget IS INITIAL.
        CONTINUE.
      ENDIF.

      " --- SCHRITT 3: UMRECHNUNG ---
      DATA lv_converted_amount TYPE zr_cs1_customers-SalesVolumeTarget.

      TRY.
          cl_exchange_rates=>convert_to_foreign_currency(
            EXPORTING
              local_amount     = <fs_customer>-SalesVolume
              local_currency   = <fs_customer>-Currency
              foreign_currency = <fs_customer>-CurrencyTarget
              date             = lv_today
            IMPORTING
              foreign_amount   = lv_converted_amount
          ).

          " Rundung für JPY
          IF <fs_customer>-CurrencyTarget = 'JPY'.
            lv_converted_amount = round( val = lv_converted_amount dec = 0 ).
          ENDIF.

          " --- SCHRITT 4: DIREKTER MODIFY PRO ZEILE ---
          " Durch die Verwendung von <fs_customer>-%tky stellen wir sicher,
          " dass exakt der Draft-Status (is_draft = '01') getroffen wird.
          MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
             ENTITY customers
               UPDATE FIELDS ( SalesVolumeTarget )
               WITH VALUE #( ( %tky              = <fs_customer>-%tky
                               SalesVolumeTarget = lv_converted_amount
                               %control-SalesVolumeTarget = if_abap_behv=>mk-on ) )
             FAILED DATA(ls_loop_failed)
             REPORTED DATA(ls_loop_reported).

          " Fehler sammeln (Korrekt für REPORTED Strukturen)
          IF ls_loop_reported-customers IS NOT INITIAL.
            reported-customers = CORRESPONDING #( BASE ( reported-customers ) ls_loop_reported-customers ).
          ENDIF.

        CATCH cx_exchange_rates INTO DATA(lx_rates).
          APPEND VALUE #( %tky = <fs_customer>-%tky
                          %msg = zcx_cs1_customer_failed=>new_message(
                                   i_textid   = zcx_cs1_customer_failed=>Umrechnungsfehler
                                   i_severity = if_abap_behv_message=>severity-error
                                   i_v1       = <fs_customer>-CurrencyTarget
                                   i_v4       = |{ <fs_customer>-SalesVolume }| )
                        ) TO reported-customers.
      ENDTRY.
    ENDLOOP.
    IF lt_customers IS NOT INITIAL.
      READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
        ENTITY customers
          FIELDS ( SalesVolumeTarget )
          WITH CORRESPONDING #( keys )
        RESULT DATA(lt_refresh_buffer).
    ENDIF.

  ENDMETHOD.

  METHOD setDefaults.
    " 1. Betroffene Instanzen lesen
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        FIELDS ( Language CurrencyTarget )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    " 2. Werte nur setzen, wenn sie noch leer sind (um User-Eingaben nicht zu überschreiben)
    MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        UPDATE FIELDS ( Language CurrencyTarget )
        WITH VALUE #( FOR customer IN lt_customers
                         WHERE ( Language IS INITIAL AND CurrencyTarget IS INITIAL )
                         ( %tky           = customer-%tky
                           Language       = 'D'
                           CurrencyTarget = 'EUR' ) )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.



*  METHOD setDefaultCurrencyTarget.
*    " 1. Betroffene Draft-Instanzen lesen
*    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
*      ENTITY customers
*        FIELDS ( CurrencyTarget ) WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_customers).
*
*    " 2. Default-Wert aus Service-Tabelle ermitteln
*    SELECT SINGLE id FROM zcs1_service
*      WHERE id = 'DefCurrencyTarget'
*      INTO @DATA(lv_default_currency).
*
*    IF sy-subrc <> 0 OR lv_default_currency IS INITIAL.
*      lv_default_currency = 'USD'.
*    ENDIF.
*
*    " 3. Update vorbereiten (nur wenn noch leer)
*    DATA lt_update TYPE TABLE FOR UPDATE zr_cs1_customers.
*    lt_update = VALUE #( FOR cust IN lt_customers WHERE ( CurrencyTarget IS INITIAL )
*                         ( %tky           = cust-%tky
*                           CurrencyTarget = lv_default_currency ) ).
*
*    " 4. Wert in den Draft schreiben
*    IF lt_update IS NOT INITIAL.
*      MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
*        ENTITY customers
*          UPDATE FIELDS ( CurrencyTarget )
*          WITH lt_update.
*    ENDIF.
*  ENDMETHOD.

*  METHOD updateOrdersOnCurrencyChange.
*    " 1. Kunden lesen
*    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
*      ENTITY Customers
*        FIELDS ( Customerid AccLock )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_customers).
*
*    LOOP AT lt_customers INTO DATA(ls_customer).
*      IF ls_customer-AccLock = abap_true.
*        CONTINUE.
*      ENDIF.
*
*      " 2. Alle Bestellungen lesen
*      READ ENTITIES OF zr_cs1_custorders
*        ENTITY custorders
*          FIELDS ( Orderid Customerid OrderTotalTarget )
*          WITH VALUE #( ( %tky-Orderid = '' ) )
*        RESULT DATA(lt_orders_all).
*
*      " 3. EXPLIZITE DEKLARATION (löst den VALUE-Fehler)
*      " Wir nutzen den exakten Typ der Quelltabelle
*      DATA lt_orders LIKE lt_orders_all.
*
*      CLEAR lt_orders.
*      lt_orders = VALUE #( FOR ord IN lt_orders_all
*                           WHERE ( Customerid = ls_customer-Customerid )
*                           ( ord ) ).
*
*      " 4. Update triggern
*      IF lt_orders IS NOT INITIAL.
*        MODIFY ENTITIES OF zr_cs1_custorders
*          ENTITY custorders
*            UPDATE FIELDS ( OrderTotalTarget )
*            WITH VALUE #( FOR ord IN lt_orders (
*                             %tky             = ord-%tky
*                             OrderTotalTarget = ord-OrderTotalTarget
*                          ) ).
*      ENDIF.
*    ENDLOOP.
*  ENDMETHOD.

*  METHOD validateVip.
*
*
*
*
*  ENDMETHOD.

  METHOD cancelorders.

    LOOP AT keys INTO DATA(ls_key).

      DATA(lv_customerid) = ls_key-%param-Customerid.

      IF lv_customerid IS INITIAL.
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text = 'Bitte einen Kunden auswählen' )
                      ) TO reported-customers.
        RETURN.
      ENDIF.

      " 1. Alle Orders vom Kunden lesen
      SELECT * FROM zcs1_custorders
        WHERE customerid = @lv_customerid
          AND status LIKE 'B%'
        INTO TABLE @DATA(lt_orders_to_update).

      IF lt_orders_to_update IS INITIAL.
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-information
                          text = |Keine Bestellungen für Kunde { lv_customerid } gefunden| )
                      ) TO reported-customers.
        CONTINUE.
      ENDIF.

      " 2. Erstes Zeichen von B auf S ändern
      LOOP AT lt_orders_to_update ASSIGNING FIELD-SYMBOL(<ls_order>).
        <ls_order>-status+0(1) = 'S'.   " BN -> SN, BN01 -> SN01
      ENDLOOP.

      " 2. Status per EML auf 'ST' updaten statt löschen
      MODIFY ENTITIES OF zr_cs1_custorders000
        ENTITY custorders
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR ls_order IN lt_orders_to_update
                      ( Orderid = ls_order-orderid
                        Status  = ls_order-status ) )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported)
        MAPPED DATA(lt_mapped).

      " 3. Fehler prüfen
      IF lt_failed-custorders IS NOT INITIAL.
        APPEND VALUE #( %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text = |Fehler beim Stornieren der Bestellungen| )
                      ) TO reported-customers.
        CONTINUE.
      ENDIF.

      " 4. Erfolgsmeldung
      APPEND VALUE #( %msg = new_message_with_text(
                        severity = if_abap_behv_message=>severity-success
                        text = |{ lines( lt_orders_to_update ) } Bestellungen für Kunde { lv_customerid } storniert| )
                    ) TO reported-customers.
    ENDLOOP.

    result = VALUE #( FOR key IN keys ( %cid = key-%cid ) ).

  ENDMETHOD.

  METHOD showstatistics.
    " Platzhalter für zweite Action
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS adjust_numbers REDEFINITION.
ENDCLASS.

CLASS lsc_zr_cs1_customers IMPLEMENTATION.
  METHOD adjust_numbers.
    DATA(lo_num) = NEW zcl_cs1_customer_import( ).
    LOOP AT mapped-customers ASSIGNING FIELD-SYMBOL(<ls_mapped>)
         USING KEY primary_key
         WHERE CustomerId IS INITIAL.
      DATA(lv_next) = lo_num->zif_cs1_validation~latenumbering( ).
      <ls_mapped>-CustomerId = |{ lv_next ALPHA = IN }|.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
