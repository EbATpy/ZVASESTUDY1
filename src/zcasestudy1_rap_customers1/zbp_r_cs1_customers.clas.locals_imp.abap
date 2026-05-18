CLASS lhc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION IMPORTING  REQUEST requested_authorizations FOR customers RESULT result,
      validateEmail          FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateEmail,
      validatePhone          FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validatePhone,
      validateFax            FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateFax,
      Determinate_getCity    FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~Determinate_getCity,
      validateCurrencyTarget FOR VALIDATE  ON SAVE   IMPORTING keys FOR customers~validateCurrencyTarget,
      SalesVolume            FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~SalesVolume,
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
        FIELDS ( CurrencyTarget )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).

    " 2. Hilfstabelle für die Datenbank-Abfrage (Existenzprüfung)
    DATA(lt_curr_filter) = lt_customers.
    DELETE lt_curr_filter WHERE CurrencyTarget IS INITIAL.
    SORT lt_curr_filter BY CurrencyTarget.
    DELETE ADJACENT DUPLICATES FROM lt_curr_filter COMPARING CurrencyTarget.

    " 3. Hashed Table gegen die Suchhilfe-View I_CurrencyStdVH
    TYPES: BEGIN OF ty_s_currency,
             Currency TYPE I_CurrencyStdVH-Currency,
           END OF ty_s_currency.
    DATA lt_valid_currencies TYPE HASHED TABLE OF ty_s_currency WITH UNIQUE KEY Currency.

    " 4. Einmaliger DB-Zugriff gegen die Suchhilfe
    IF lt_curr_filter IS NOT INITIAL.
      SELECT Currency FROM I_CurrencyStdVH
        FOR ALL ENTRIES IN @lt_curr_filter
        WHERE Currency = @lt_curr_filter-CurrencyTarget
        INTO TABLE @lt_valid_currencies.
    ENDIF.

    " 5. Validierungsschleife
    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<ls_customer>).

      " Check 1: Pflichtfeldprüfung
      IF <ls_customer>-CurrencyTarget IS INITIAL.
        " failed stoppt den Speicherprozess (Save-Sequenz bricht ab)
        APPEND VALUE #( %tky = <ls_customer>-%tky ) TO failed-customers.

        " reported steuert die Fehlermeldung und die rote Markierung am Feld (%element)
        APPEND VALUE #( %tky = <ls_customer>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Bitte wählen Sie eine Zielwährung aus.' )
                        %element-currencytarget = if_abap_behv=>mk-on ) TO reported-customers.
        CONTINUE.
      ENDIF.

      " Check 2: Existenzprüfung gegen Suchhilfeeinträge (I_CurrencyStdVH)
      IF NOT line_exists( lt_valid_currencies[ Currency = <ls_customer>-CurrencyTarget ] ).
        " failed stoppt den Speicherprozess (Save-Sequenz bricht ab)
        APPEND VALUE #( %tky = <ls_customer>-%tky ) TO failed-customers.

        " reported steuert die Fehlermeldung und die rote Markierung am Feld (%element)
        APPEND VALUE #( %tky = <ls_customer>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Währung { <ls_customer>-CurrencyTarget } entspricht keinem gültigen Suchhilfeeintrag!| )
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

    " Lokale Tabelle für das Massen-Update vorbereiten
    DATA lt_customers_update TYPE TABLE FOR UPDATE zr_cs1_customers\\customers.

    " --- SCHRITT 2: DER LOOP (BERECHNUNG & SAMMELN) ---
    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<fs_customer>).

      IF <fs_customer>-SalesVolume    IS INITIAL OR
         <fs_customer>-Currency       IS INITIAL OR
         <fs_customer>-CurrencyTarget IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA lv_converted_amount TYPE zr_cs1_customers-SalesVolumeTarget.

      TRY.
          " Währungsumrechnung durchführen
          cl_exchange_rates=>convert_to_foreign_currency(
            EXPORTING
              local_amount     = <fs_customer>-SalesVolume
              local_currency   = <fs_customer>-Currency
              foreign_currency = <fs_customer>-CurrencyTarget
              date             = lv_today
            IMPORTING
              foreign_amount   = lv_converted_amount
          ).

          " Datensatz für das Massen-Update am Ende der Methode sammeln
          APPEND VALUE #( %tky              = <fs_customer>-%tky
                          SalesVolumeTarget = lv_converted_amount
                          %control-SalesVolumeTarget = if_abap_behv=>mk-on ) TO lt_customers_update.

        CATCH cx_exchange_rates INTO DATA(lx_rates).
          " Fehlermeldung ausgeben, falls kein Umrechnungskurs vorhanden ist
          APPEND VALUE #( %tky = <fs_customer>-%tky
                          %msg = zcx_cs1_customer_failed=>new_message(
                                   i_textid   = zcx_cs1_customer_failed=>Umrechnungsfehler
                                   i_severity = if_abap_behv_message=>severity-error
                                   i_v1       = <fs_customer>-CurrencyTarget
                                   i_v4       = |{ <fs_customer>-SalesVolume }| )
                        ) TO reported-customers.
      ENDTRY.
    ENDLOOP.

    " --- SCHRITT 3: EINMALIGES MASSEN-UPDATE AUẞERHALB DES LOOPS ---
    IF lt_customers_update IS NOT INITIAL.
      MODIFY ENTITIES OF zr_cs1_customers IN LOCAL MODE
         ENTITY customers
           UPDATE FIELDS ( SalesVolumeTarget )
           WITH lt_customers_update
         FAILED DATA(ls_modify_failed)
         REPORTED DATA(ls_modify_reported).

      " Eventuelle Framework-Fehler des Updates (z.B. Sperren) im globalen reported-Objekt sammeln
      IF ls_modify_reported-customers IS NOT INITIAL.
        reported-customers = CORRESPONDING #( BASE ( reported-customers ) ls_modify_reported-customers ).
      ENDIF.
    ENDIF.

    " --- SCHRITT 4: BUFFER REFRESH ---
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

    " =========================================================================
    " 1. DATEN BESCHAFFEN
    " =========================================================================
    " Liest die ausgewählten Kundendaten aus der RAP-Entität (Fiori UI Auswahl)
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_customers)
        FAILED failed
        REPORTED reported.


    " =========================================================================
    " 2. DYNAMIK / CONFIGURATION HOLEN
    " =========================================================================
    " Holt die zugewiesene Berechnungs-Klasse und das Interface aus dem Customizing
    SELECT SINGLE FROM zcs1_statistic
      FIELDS class_name, interface_name
      WHERE active = @abap_true
      INTO @DATA(ls_stat).

    " Abbruch, wenn kein aktiver Eintrag in der Steuertabelle konfiguriert ist
    IF sy-subrc <> 0 OR ls_stat-class_name IS INITIAL.
      APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                    text     = 'Kein aktiver Eintrag in ZCS1_STATISTIC gefunden' ) )
             TO reported-customers.
      RETURN.
    ENDIF.


    " =========================================================================
    " --- CLOUD-GOVERNANCE: DYNAMISCHE TYP-PRÜFUNG VOR DEM LOOP ---
    " =========================================================================
    DATA lo_class_descr TYPE REF TO cl_abap_classdescr.
    DATA lo_intf_descr  TYPE REF TO cl_abap_objectdescr.
    DATA lo_typedescr_class TYPE REF TO cl_abap_typedescr.
    DATA lo_typedescr_intf  TYPE REF TO cl_abap_typedescr.

    " -------------------------------------------------------------------------
    " A. Klassen-Prüfung (Verhindert den kritischen Kernel-Absturz TYPE_NOT_RELEASED)
    " -------------------------------------------------------------------------
    TRY.
        " Prüft über RTTS, ob das Objekt im System überhaupt bekannt ist
        cl_abap_typedescr=>describe_by_name(
          EXPORTING p_name         = ls_stat-class_name
          RECEIVING p_descr_ref    = lo_typedescr_class
          EXCEPTIONS type_not_found = 1 OTHERS         = 2
        ).

        " Fall 1: Klasse physisch nicht im System vorhanden
        IF sy-subrc = 1 OR lo_typedescr_class IS INITIAL.
          APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |Klasse { ls_stat-class_name } existiert nicht im System!| ) )
                 TO reported-customers.
          RETURN.
        ENDIF.

        " Fall 2: Typ existiert im DDIC (z.B. Struktur), ist aber keine ABAP-Klasse
        IF lo_typedescr_class->kind <> cl_abap_typedescr=>kind_class.
          APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |Typ-Konflikt: { ls_stat-class_name } ist vorhanden, aber keine Klasse.| ) )
                 TO reported-customers.
          RETURN.
        ENDIF.

        " Sicherer Cast auf die Klasseneigenschaften
        lo_class_descr = CAST cl_abap_classdescr( lo_typedescr_class ).

        " Fall 3: Klasse ist geschützt (PROTECTED/PRIVATE) und kann nicht von außen instantiiert werden
        IF lo_class_descr->create_visibility <> cl_abap_classdescr=>public.
          APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |Klasse { ls_stat-class_name } ist nicht öffentlich instanziierbar.| ) )
                 TO reported-customers.
          RETURN.
        ENDIF.

      CATCH cx_sy_move_cast_error.
        APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Der Typ { ls_stat-class_name } konnte nicht verarbeitet werden.| ) )
               TO reported-customers.
        RETURN.
      CATCH cx_root.
        " Sichert ABAP Cloud ab: Greift bei nicht freigegebenen Objekten (z.B. SAP-Standardklassen ohne API-Zulassung)
        APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text = |Klasse { ls_stat-class_name } nicht freigegeben (Cloud API)| ) )
               TO reported-customers.
        RETURN.
    ENDTRY.


    " -------------------------------------------------------------------------
    " B. Interface-Prüfung (Analog zur Klassen-Prüfung)
    " -------------------------------------------------------------------------
    TRY.
        cl_abap_typedescr=>describe_by_name(
          EXPORTING p_name         = ls_stat-interface_name
          RECEIVING p_descr_ref    = lo_typedescr_intf
          EXCEPTIONS type_not_found = 1 OTHERS         = 2
        ).

        " Fall 1: Interface existiert nicht
        IF sy-subrc = 1 OR lo_typedescr_intf IS INITIAL.
          APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |Interface { ls_stat-interface_name } existiert nicht im System!| ) )
                 TO reported-customers.
          RETURN.
        ENDIF.

        " Fall 2: Der Name gehört zu einer Klasse/Struktur, nicht zu einem Interface
        IF lo_typedescr_intf->kind <> cl_abap_typedescr=>kind_intf.
          APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |Typ-Konflikt: { ls_stat-interface_name } ist vorhanden, aber kein Interface.| ) )
                 TO reported-customers.
          RETURN.
        ENDIF.

        lo_intf_descr = CAST cl_abap_objectdescr( lo_typedescr_intf ).

      CATCH cx_sy_move_cast_error.
        APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Der Typ { ls_stat-interface_name } konnte nicht verarbeitet werden.| ) )
               TO reported-customers.
        RETURN.
      CATCH cx_root.
        " Das Interface ist im System gesperrt
        APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |Interface { ls_stat-interface_name } ist für ABAP Cloud gesperrt.| ) )
               TO reported-customers.
        RETURN.
    ENDTRY.


    " -------------------------------------------------------------------------
    " C. Methoden im Interface prüfen
    " -------------------------------------------------------------------------
    " Definiert die Pflichtmethoden, die zwingend vorhanden sein müssen
    DATA(lt_required_methods) = VALUE string_table( ( `AVERAGE_SALES` ) ( `MAX_SALES` ) ( `DAY_SALES` ) ).

    LOOP AT lt_required_methods INTO DATA(lv_check_method).
      " Im System wird die Methode in der Klasse als 'INTERFACE~METHODE' registriert
      DATA(lv_class_method_fullname) = |{ ls_stat-interface_name }~{ lv_check_method }|.

      " Prüfen, ob die Methode in der Klasse existiert
      READ TABLE lo_class_descr->methods WITH KEY name = to_upper( lv_class_method_fullname ) TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        " Fehler exakt benennen: Interface ist zwar da, aber die Methode fehlt in dieser Klasse
        APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = |{ ls_stat-class_name }: Methode { lv_check_method } fehlt!| ) )
               TO reported-customers.
        RETURN.
      ENDIF.
    ENDLOOP.


    " -------------------------------------------------------------------------
    " D. RTTS: Referenztyp für Cloud-konforme Pointer vorbereiten
    " -------------------------------------------------------------------------
    " Da 'CREATE DATA ... TYPE REF TO (variable_interface)' in Cloud verboten ist,
    " generieren wir hier den Referenztyp dynamisch über ein RTTS-Metadaten-Handle.
    DATA(lo_ref_descr) = cl_abap_refdescr=>create( lo_intf_descr ).


    " =========================================================================
    " 3. VERARBEITUNG PRO KUNDE (Hauptschleife)
    " =========================================================================
    LOOP AT lt_customers INTO DATA(ls_customer).

      " Lokale Ergebnisspeicher für den aktuellen Kundendurchlauf
      DATA: lv_max   TYPE zorder_total1,
            lv_avg   TYPE zorder_total1,
            lv_day   TYPE zorder_total1,
            lv_gjahr TYPE gjahr VALUE '2026'.

      TRY.
          " Instanziiert die Customizing-Klasse dynamisch zur Laufzeit
          DATA lo_object TYPE REF TO object.
          CREATE OBJECT lo_object TYPE (ls_stat-class_name).

          " ---------------------------------------------------------------------
          " Prüfung: Implementiert die gewählte Klasse das Interface?
          " ---------------------------------------------------------------------
          DATA(lv_interface_implemented) = abap_false.

          " Durchläuft die Liste aller von der Klasse implementierten Schnittstellen
          LOOP AT lo_class_descr->interfaces INTO DATA(ls_implemented_interface).
            IF ls_implemented_interface-name = ls_stat-interface_name.
              lv_interface_implemented = abap_true.
              EXIT.
            ENDIF.
          ENDLOOP.

          " Fall: Klasse und Interface passen im Customizing nicht zusammen
          IF lv_interface_implemented = abap_false.
            APPEND VALUE #( %tky = ls_customer-%tky
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text = |Konfigurationsfehler: Die Klasse { ls_stat-class_name } implementiert das Interface { ls_stat-interface_name } nicht!| ) )
                   TO reported-customers.
            APPEND VALUE #( %tky = ls_customer-%tky ) TO failed-customers.
            CONTINUE. " Überspringt diesen Kunden und läuft weiter
          ENDIF.

          " ---------------------------------------------------------------------
          " Cloud-konformer Pointer-Zuweisung (Downcast)
          " ---------------------------------------------------------------------
          " Erzeugt die Datenreferenz basierend auf dem vorab erstellten Interface-Typ-Handle
          DATA lo_dyn_intf_ref TYPE REF TO data.
          CREATE DATA lo_dyn_intf_ref TYPE HANDLE lo_ref_descr.

          " Entreferenziert den Daten-Pointer in ein Feldsymbol (Typ: REF TO [Interface])
          ASSIGN lo_dyn_intf_ref->* TO FIELD-SYMBOL(<lo_intf_ptr>).

          " Castet die generische Objektinstanz auf die Interface-Variable
          <lo_intf_ptr> ?= lo_object.

          " Weist das typisierte Feldsymbol der ausführbaren Objektreferenz zu
          DATA lo_stat_if TYPE REF TO object.
          lo_stat_if = <lo_intf_ptr>.

          " ---------------------------------------------------------------------
          " DYNAMISCHE METHODENAUFRUFE
          " ---------------------------------------------------------------------
          " Aufruf 1: Durchschnittlicher Umsatz
          DATA(lv_method_name) = |{ ls_stat-interface_name }~AVERAGE_SALES|.
          CALL METHOD lo_stat_if->(lv_method_name)
            EXPORTING
              iv_gjahr = lv_gjahr
              iv_kunnr = ls_customer-customerid
            RECEIVING
              rv_avg   = lv_avg.

          " Aufruf 2: Maximaler Umsatz
          lv_method_name = |{ ls_stat-interface_name }~MAX_SALES|.
          CALL METHOD lo_stat_if->(lv_method_name)
            EXPORTING
              iv_kunnr = ls_customer-customerid
            RECEIVING
              rv_max   = lv_max.

          " Aufruf 3: Tagesumsatz
          lv_method_name = |{ ls_stat-interface_name }~DAY_SALES|.
          CALL METHOD lo_stat_if->(lv_method_name)
            EXPORTING
              iv_gjahr = lv_gjahr
            RECEIVING
              rv_day   = lv_day.

          " =========================================================================
          " 4. ERGEBNIS AN FIORI UI SENDEN (Erfolgsfall)
          " =========================================================================
          " Schreibt die berechneten Werte als formatierte Erfolgsmeldung an die UI-Zeile
          APPEND VALUE #( %tky = ls_customer-%tky
                          %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-success
                                   text = |Max { lv_max DECIMALS = 2 } | &&

                                          |Ø { lv_avg DECIMALS = 2 } Tag { lv_day DECIMALS = 2 } | ) )
                 TO reported-customers.

          " -------------------------------------------------------------------------
          " LAUFZEIT-FEHLERBEHANDLUNG IM LOOP
          " -------------------------------------------------------------------------
        CATCH cx_sy_create_object_error INTO DATA(lx_create).
          " Fängt Fehler ab, wenn die Instanziierung der Klasse fehlschlägt (z.B. im Constructor)
          APPEND VALUE #( %tky = ls_customer-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text = |Instanz-Fehler: { lx_create->get_text( ) }| ) )
                 TO reported-customers.
          APPEND VALUE #( %tky = ls_customer-%tky ) TO failed-customers.

        CATCH cx_sy_dyn_call_error INTO DATA(lx_call).
          " Fängt Abweichungen bei den Parametern ab (z.B. wenn sich ein Typ im Interface geändert hat)
          APPEND VALUE #( %tky = ls_customer-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text = |{ ls_stat-class_name }: Methode { lv_check_method } fehlt!| ) )
                 TO reported-customers.
          APPEND VALUE #( %tky = ls_customer-%tky ) TO failed-customers.
      ENDTRY.

    ENDLOOP.

    " =========================================================================
    " 5. UI-REFRESH TRIGGERN
    " =========================================================================
    " Zwingend erforderlich für RAP Actions: Meldet dem Fiori Elements Frontend,
    " welche Tabellenzeilen sich geändert haben und neu geladen werden müssen.
    result = VALUE #( FOR cust IN lt_customers ( %tky = cust-%tky %param = cust ) ).




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
