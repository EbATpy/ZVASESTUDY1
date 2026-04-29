CLASS lcl_customer_import DEFINITION.

  PUBLIC SECTION.


    TYPES: BEGIN OF ty_import,
             company  TYPE string,
             street   TYPE string,
             postcode TYPE string,
             city     TYPE string,
             type     TYPE string,
             data1    TYPE string,
             data2    TYPE string,
           END OF ty_import,
           tt_import TYPE STANDARD TABLE OF ty_import WITH EMPTY KEY.

    TYPES: BEGIN OF ty_import_raw,
             rawdata     TYPE string,
             email_err   TYPE abap_boolean,
             phone_err   TYPE abap_boolean,
             telefax_err TYPE abap_boolean,
           END OF ty_import_raw,
           tt_raw TYPE STANDARD TABLE OF ty_import_raw WITH EMPTY KEY.

    TYPES: BEGIN OF ty_output,
             company      TYPE string,
             street       TYPE string,
             postcode     TYPE string,
             city         TYPE string,
             type         TYPE string,
             data1        TYPE string,
             data2        TYPE string,
             fax          TYPE string,
             phone        TYPE string,
             email        TYPE string,
             memo         TYPE string,
             raw_table    TYPE tt_raw,
             company_Err  TYPE abap_boolean,
             Email_Err    TYPE abap_boolean,
             Tele_Err     TYPE abap_boolean,
             TelFax_Err   TYPE abap_boolean,
             customers_id TYPE string,
           END OF ty_output,
           tt_output TYPE STANDARD TABLE OF ty_output WITH EMPTY KEY.

    DATA tt_customers TYPE tt_output.


    METHODS parse_csv.
    METHODS parse_customers.

    METHODS return_table
      RETURNING VALUE(rv_table) TYPE tt_output.

    CLASS-METHODS is_email_valid
      IMPORTING iv_email        TYPE string
      RETURNING VALUE(rv_valid) TYPE abap_bool.

    CLASS-METHODS is_tel_valid
      IMPORTING iv_tel          TYPE string
      RETURNING VALUE(rv_valid) TYPE abap_bool.

    " Methode zum Ziehen der nächsten Customer-ID
    CLASS-METHODS get_next_customer_id
      RETURNING
        VALUE(rv_customerid) TYPE zcustomerid1
      RAISING
        cx_number_ranges.
    "" Struktur für die Tabelle customers als Sortierte Tabelle
    TYPES tc_customer TYPE SORTED TABLE OF zcs1_customers WITH UNIQUE KEY company street postcode city.

    "" Metghode zum import der Tabelle mit unique Werten bestehend aus den keys
    METHODS import_customers
      ""+++++++++++++++++ NEU für Exception Class !!!!! muss auch noch ins original!!!
      RAISING zcx_cs1_customer_failed.

    TYPES: BEGIN OF ty_errors,
             customers_id TYPE string,
             company      TYPE string,
             street       TYPE string,
             postcode     TYPE string,
             city         TYPE string,
             note_err     TYPE string,
           END OF ty_errors,
           tt_errors TYPE STANDARD TABLE OF ty_errors WITH EMPTY KEY.
    DATA tt_badi_error TYPE tt_errors.

    METHODS Company_Err_Tab.

    METHODS return_err_table
      RETURNING VALUE(itab_error) TYPE tt_errors.

    METHODS New_Customer_Tab.

    DATA tt_badi_new TYPE tt_errors.

    METHODS return_New_Customer_Tab_table
      RETURNING VALUE(itab_new) TYPE tt_errors.

    METHODS call_badi.

    METHODS Email_err_tab.

    DATA lt_customers TYPE tt_output.
    DATA  get_error_note  TYPE String.
     DATA column_name TYPE string.

 METHODS Email_Tele_Telfax_Error
 RETURNING VALUE(ETT_Erroer) TYPE tt_errors.


  PRIVATE SECTION.
    CLASS-METHODS split_csv_line
      IMPORTING iv_line        TYPE string
      RETURNING VALUE(rt_cols) TYPE string_table.





ENDCLASS.


CLASS lcl_customer_import IMPLEMENTATION.

  METHOD parse_csv.
    DATA lt_initial_rows TYPE tt_output.
    SELECT import FROM ztl_00_casestudy INTO TABLE @DATA(lt_source).
    LOOP AT lt_source INTO DATA(ls_source) WHERE import IS NOT INITIAL.
      DATA(ls_test)    = VALUE ty_output( ).
      DATA(lt_columns) = split_csv_line( CONV string( ls_source-import ) ).
      ls_test-company    = VALUE #( lt_columns[ 1 ] OPTIONAL ).
      ls_test-street     = VALUE #( lt_columns[ 2 ] OPTIONAL ).
      ls_test-postcode   = VALUE #( lt_columns[ 3 ] OPTIONAL ).
      ls_test-city       = VALUE #( lt_columns[ 4 ] OPTIONAL ).
      ls_test-type       = VALUE #( lt_columns[ 5 ] OPTIONAL ).
      ls_test-data1      = VALUE #( lt_columns[ 6 ] OPTIONAL ).
      ls_test-data2      = VALUE #( lt_columns[ 7 ] OPTIONAL ).
      "------------------------------------
      DATA(ls_raw)       = VALUE ty_import_raw( ).
      ls_raw-rawdata     = ls_source-import.
      APPEND ls_raw TO ls_test-raw_table.
      "------------------------------------
      DATA(lv_index) = sy-tabix.
      APPEND ls_test TO lt_initial_rows.
    ENDLOOP.
    MOVE-CORRESPONDING lt_initial_rows TO me->tt_customers.
  ENDMETHOD.

  METHOD return_table.
    rv_table = me->tt_customers.
  ENDMETHOD.

  METHOD split_csv_line.
    SPLIT iv_line AT ';' INTO TABLE DATA(lt_raw).
    LOOP AT lt_raw INTO DATA(lv_col).
      REPLACE ALL OCCURRENCES OF PCRE '^""|^"|"$|""$' IN lv_col WITH ''.
      REPLACE ALL OCCURRENCES OF PCRE '^ | $' IN lv_col WITH ''.
      REPLACE ALL OCCURRENCES OF PCRE '^\s+|\s+$' IN lv_col WITH ''.
      APPEND lv_col TO rt_cols.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse_customers.

    DATA rt_output TYPE tt_output.

    DATA(lt_data) = VALUE tt_output( FOR ls IN me->tt_customers (
                           company      = condense( val = ls-company )
                           street       = condense( val = ls-street )
                           postcode     = condense( val = ls-postcode )
                           city         = condense( val = ls-city )
                           type         = condense( val = ls-type )
                           data1        = condense( val = ls-data1 )
                           data2        = condense( val = ls-data2 )
                           fax          = ls-fax
                           phone        = ls-phone
                           email        = ls-email
                           memo         = ls-memo
                           raw_table    = ls-raw_table
                           company_err  = ls-company_err
                           customers_id = ls-customers_id
                           ) ).

    SORT lt_data BY company street postcode city.
    LOOP AT lt_data INTO DATA(ls_line) GROUP BY ( company  = ls_line-company
                                                  street   = ls_line-street
                                                  postcode = ls_line-postcode
                                                  city     = ls_line-city )
                                      INTO DATA(ls_key).

      DATA(ls_out) = VALUE ty_output( company      = ls_key-company
                                      street       = ls_key-street
                                      postcode     = ls_key-postcode
                                      city         = ls_key-city ).

      DATA(lv_phone_done) = abap_false.
      DATA(lv_fax_done)   = abap_false.
      DATA(lv_email_done) = abap_false.

      LOOP AT GROUP ls_key INTO DATA(ls_member).

        DATA(data1_data2) =  |{ ls_member-data1 }{ ls_member-data2 }| .
        DATA(data1)       =  |{ ls_member-data1 }| .

        data1_data2 = replace( val = data1_data2 pcre = '[^\d]'   with = ''      occ = 0 ).
        data1_data2 = replace( val = data1_data2 pcre = `^0(\d+)` with = `+49$1` occ = 1 ).

        DATA(valid_phone)   = me->is_tel_valid( data1_data2 ).
        DATA(valid_telefax) = me->is_tel_valid( data1_data2 ).
        DATA(valid_email)   = me->is_email_valid( data1 ).

        " -------------Phone is ''
        ls_member-type = COND #( WHEN ls_member-type = ''
            THEN |Phone|
            ELSE |{ ls_member-type }| ).

        " -------------Import raw data (keep all original lines)
        " -------------add phone_err;telefax_err;email_err
        DATA(phone_err)   = abap_false.
        DATA(telefax_err) = abap_false.
        DATA(email_err)   = abap_false.
        CASE ls_member-type.
          WHEN 'Phone'.
            phone_err   = xsdbool( valid_phone = abap_false ).
            telefax_err = abap_false.
            email_err   = abap_false.
          WHEN 'Telefax'.
            phone_err   = abap_false.
            telefax_err = xsdbool( valid_telefax = abap_false ).
            email_err   = abap_false.
          WHEN 'Email'.
            phone_err   = abap_false.
            telefax_err = abap_false.
            email_err   = xsdbool( valid_email = abap_false ).
          WHEN OTHERS.
            phone_err   = abap_false.
            telefax_err = abap_false.
            email_err   = abap_false.
        ENDCASE.
        MODIFY ls_member-raw_table FROM VALUE #( email_err   = email_err
                                                 phone_err   = phone_err
                                                 telefax_err = telefax_err )
               INDEX 1
               TRANSPORTING email_err
                            phone_err
                            telefax_err.
        APPEND LINES OF ls_member-raw_table TO ls_out-raw_table.
        " -------------

        DATA(Phone)   = COND #( WHEN valid_phone   = abap_true
            THEN | { ls_member-type }:|
            ELSE | { ls_member-type }-ERR:| ).
        DATA(Telefax) = COND #( WHEN valid_telefax = abap_true
            THEN | { ls_member-type }:|
            ELSE | { ls_member-type }-ERR:| ).
        DATA(Email)   = COND #( WHEN valid_email   = abap_true
            THEN | { ls_member-type }:|
            ELSE | { ls_member-type }-ERR:| ).

        CASE ls_member-type.
          WHEN 'Phone'.
            IF lv_phone_done = abap_false AND valid_phone = abap_true.
              ls_out-phone  = data1_data2.
              lv_phone_done = abap_true.
            ELSE.
              IF ls_out-phone <> data1_data2.
                ls_out-memo = COND #( WHEN ls_out-memo IS INITIAL
                THEN |{ Phone }{ data1_data2 }|
                ELSE  |{ ls_out-memo };{ Phone }{ data1_data2 }| ).
              ENDIF.
            ENDIF.
          WHEN 'Telefax'.
            IF lv_fax_done = abap_false  AND valid_telefax = abap_true.
              ls_out-fax = data1_data2.
              lv_fax_done    = abap_true.
            ELSE.
              IF ls_out-fax <> data1_data2.
                ls_out-memo = COND #( WHEN ls_out-memo IS INITIAL
                 THEN |{ Telefax }{ data1_data2 }|
                 ELSE |{ ls_out-memo };{ Telefax }{ data1_data2 }| ).
              ENDIF.
            ENDIF.
          WHEN 'Email'.
            IF lv_email_done = abap_false  AND valid_email = abap_true.
              ls_out-email  = data1.
              lv_email_done = abap_true.
            ELSE.
              IF ls_out-email <> data1.
                ls_out-memo = COND #( WHEN ls_out-memo IS INITIAL
                THEN |{ Email }{ data1 }|
                ELSE |{ ls_out-memo };{ Email }{ data1 }| ).
              ENDIF.
            ENDIF.
          WHEN OTHERS.
            ls_out-memo = COND #( WHEN ls_out-memo IS INITIAL
            THEN |{ ls_member-type }:{ data1_data2 }|
            ELSE |{ ls_out-memo };{ ls_member-type }:{ data1_data2 }| ).
        ENDCASE.

      ENDLOOP.

      APPEND ls_out TO rt_output.

    ENDLOOP.

    MOVE-CORRESPONDING rt_output TO me->tt_customers.
    "me->tt_customers = rt_output.

  ENDMETHOD.

  METHOD is_email_valid.
    "   name@domain.de
    "    │  │  │     └─ de
    "    │  │  └─ domain
    "    │  └─ @
    "    └─ name
    DATA(lv_regex) = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'.
    rv_valid = xsdbool( matches( val = iv_email pcre = lv_regex ) ).
  ENDMETHOD.

  METHOD is_tel_valid.
    "   +49 40 1234567
    "    │   │  └─ Teilnehmernummer
    "    │   └─ Ortsnetzkennzahl Hamburg = 40
    "    └─ Ländervorwahl Deutschland = 49
    DATA(lv_regex) = '^\+49[1-9]\d{5,13}$'.
    rv_valid = xsdbool( matches( val = iv_tel pcre = lv_regex ) ).
  ENDMETHOD.

  METHOD import_customers.
    DATA gt_customers TYPE SORTED TABLE OF zcs1_customers WITH UNIQUE KEY company street postcode city.
    DATA gs_customers LIKE LINE OF gt_customers.
    DATA lv_country TYPE land1.
    DATA lv_currency TYPE zcurrency1.
    DATA lv_currency_target1 TYPE zcurrency_target1.
    DATA lv_last_date TYPE zlast_date1.


    DATA lt_failed_strings TYPE string_table.
    DATA lv_final_count TYPE i.

    ""+++++++++++++++++ NEU für Exception Class !!!!! muss auch noch ins original!!!++++++++++
    CONSTANTS lc_method_name TYPE string VALUE '=>IMPORT_CUSTOMERS'.

    ""+++++++++++++++++ NEU für Exception Class !!!!! muss auch noch ins original!!!++++++++++
    " Höchste vorhandene ID aus der Fehlertabelle holen
    " Später durch get_next_id Methode ersetzen!
    SELECT MAX( id ) FROM zcs1_import_err INTO @DATA(lv_max_err_id).
    DATA(lv_next_err_id_num) = CONV i( lv_max_err_id ) + 1.

    "" Hier werden die Standarddaten aus der Tabelle eingelesen
    SELECT * FROM zcs1_service INTO TABLE @DATA(lt_service).

    "" Country
    lv_country = VALUE #( lt_service[ id = 'country' active = 'X' ]-id_value
                                DEFAULT 'D' ).
    "" Currency
    lv_currency = VALUE #( lt_service[ id = 'currency' active = 'X' ]-id_value
                                DEFAULT 'EUR' ).
    "" Currency_target1
    lv_currency_target1 = VALUE #( lt_service[ id = 'currency_target' active = 'X' ]-id_value
                                    DEFAULT 'USD' ).
    "" AktDatum für Last_date Statt sy-datum vielleicht mit cl_abap_context_info=>get_system_date( ) die Methode ging aber nicht
    lv_last_date = VALUE #( lt_service[ id = 'AktDatum' active = 'X' ]-id_value
                               DEFAULT cl_abap_context_info=>get_system_date( ) ).


    LOOP AT me->tt_customers  INTO DATA(ls_import).
      TRY.
          MOVE-CORRESPONDING ls_import TO gs_customers.

          "" Schon mal die Standartwerte hier festsetzen später noch mit Service Tabelle
          gs_customers-country = lv_country.
          gs_customers-currency = lv_currency.
          gs_customers-currency_target = lv_currency_target1.
          gs_customers-last_date = lv_last_date.

          " Prüfen, ob der Kunde unter dieser Adresse schon existiert
          SELECT SINGLE customerid
            FROM zcs1_customers
            WHERE company  = @gs_customers-company
              AND last_name   = @gs_customers-last_name
              AND first_name   = @gs_customers-first_name
              AND street   = @gs_customers-street
              AND postcode = @gs_customers-postcode
              AND city     = @gs_customers-city
            INTO @DATA(lv_existing_id).

          IF sy-subrc <> 0.
            "" FALL 1: Customer existiert nicht, anfügen
            gs_customers-customerid = lcl_customer_import=>get_next_customer_id( ).

            MODIFY me->tt_customers FROM VALUE #( customers_id = gs_customers-customerid )
                TRANSPORTING customers_id WHERE company = ls_import-company
                                            AND  street = ls_import-street
                                            AND postcode = ls_import-postcode
                                            AND city = ls_import-city.

            INSERT zcs1_customers FROM @gs_customers.

            ""+++++++++++++++++ NEU für Exception Class !!!!! muss auch noch ins original!!!++++++++++
            " 1. Feldlängen-Prüfung via RTTI (Beispiel für Feld 'COMPANY')
            " Wir holen uns die Beschreibung der Struktur von ls_cust, die auf zcs1_customers geht!
            DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( gs_customers ) ).

            " Wir prüfen die Länge der 'COMPANY' (Länge in ABAP ist in Bytes/Zeichen)
            " Es muss COMPANY übergeben werden nicht company wie in der Tabelle!
            DATA(lv_max_len) = lo_struct->get_component_type( 'COMPANY' )->length / cl_abap_char_utilities=>charsize.
*          DATA(lv_max_cust) = strlen( ls_import-company ).

            IF strlen( ls_import-company ) > lv_max_len.
              " hier die Raise exeption einarbeiten und aufrufen
              RAISE EXCEPTION TYPE zcx_cs1_customer_failed
                EXPORTING
                  textid      = zcx_cs1_customer_failed=>company_to_long
                  column_name = 'COMPANY'
                  filename    = lc_method_name.
*                    line_number  = sy-tabix.
            ENDIF.
          ELSE.
            " FALL 2: Vorhanden -> Bestehende ID zuweisen und MODIFY
            gs_customers-customerid = lv_existing_id.
            MODIFY zcs1_customers FROM @gs_customers.

          ENDIF.

          INSERT gs_customers INTO TABLE gt_customers.

        CATCH cx_number_ranges INTO DATA(lx_nr_err).
          DATA(ls_err) = |Nummernkreisfehler: { lx_nr_err->get_text( ) }|.

          " Ausnahme Klasse zcx_cs1_customer_failed => zcl_cs1_customer_failed
        CATCH zcx_cs1_customer_failed INTO DATA(lx_cust_err).
          " Wenn zur Ausnahme kommt werden die Daten hier an dieser Stelle weggeschrieben
          " Text für die Description auslesen
*            DATA(lv_full_text) = |{ gs_customers-customerid }; { gs_customers-company }; { gs_customers-street }; { gs_customers-postcode }; { gs_customers-city }; | && |-> { lx_cust_err->get_text( ) }|.
          DATA(lv_full_text) = |Customer-ID: { gs_customers-customerid }; { gs_customers-company }; | && |-> { lx_cust_err->get_text( ) }|.

          "Fehlertext für das BAdI wegschreiben in die globale Tabelle markieren
          MODIFY me->tt_customers FROM VALUE #( company_Err = abap_true )
              TRANSPORTING company_Err WHERE company = ls_import-company
                                          AND  street = ls_import-street
                                          AND postcode = ls_import-postcode
                                          AND city = ls_import-city.

          INSERT zcs1_import_err FROM @( VALUE #(
                 " Hier hast du die ID (entweder neu oder existierend)
                                   id  = lv_next_err_id_num
                           description = lv_full_text ) ).

          " ID setzen, muss raus wenn get_next_id Methode implementiert ist!
          lv_next_err_id_num = lv_next_err_id_num + 1.

      ENDTRY.


    ENDLOOP.

  ENDMETHOD.


  METHOD get_next_customer_id.
    DATA: lv_number          TYPE cl_numberrange_runtime=>nr_number,
          lv_returned_number TYPE cl_numberrange_runtime=>nr_number.

    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr = '01'
            object      = 'ZCS_CUST1'
          IMPORTING
            number      = lv_returned_number
        ).

        " Wir nutzen die zurückgegebene Nummer
        " ALPHA = OUT entfernt führende Nullen (z.B. '000001' -> '1')
        rv_customerid = |{ lv_returned_number ALPHA = OUT }|.

      CATCH cx_number_ranges INTO DATA(lx_error).
        " Im Fehlerfall: Entweder leer lassen oder Fehler loggen
        " rv_customerid bleibt dann initial.
    ENDTRY.

  ENDMETHOD.

  METHOD company_err_tab.

    me->tt_badi_error = VALUE #( BASE tt_badi_error
          FOR ls IN me->tt_customers
          WHERE ( company_err = abap_true )
          ( customers_id = ls-customers_id
                company  = ls-company
                street   = ls-street
                postcode = ls-postcode
                city     = ls-city
                note_err = 'Company Name > 60' )
                         ).


  ENDMETHOD.

  METHOD return_err_table.
    itab_error = me->tt_badi_error.
  ENDMETHOD.

  METHOD new_customer_tab.
    me->tt_badi_new = VALUE #( BASE tt_badi_new
        FOR ls IN me->tt_customers
        WHERE ( customers_id IS NOT INITIAL )
        ( customers_id = ls-customers_id
              company  = ls-company
              street   = ls-street
              postcode = ls-postcode
              city     = ls-city
              note_err = 'New Customer' )
                       ).
  ENDMETHOD.

  METHOD return_new_customer_tab_table.
    itab_new = me->tt_badi_new.
  ENDMETHOD.





  METHOD call_badi.
    " Für das BAdi am ende der Methode
    DATA lo_badi TYPE REF TO ZCS1_BADIdef_IMPORT_CUSTOMERS. "hier Schritt1

    DATA(tt_badi1) = VALUE string_table( FOR <ls> IN me->tt_badi_new (
                        |{ <ls>-customers_id } { <ls>-company } { <ls>-street } { <ls>-postcode } { <ls>-city } { <ls>-note_err }| )
                                                                    ).

    DATA(tt_badi2) = VALUE string_table( FOR <ls> IN me->tt_badi_error (
                        |{ <ls>-customers_id } { <ls>-company } { <ls>-street } { <ls>-postcode } { <ls>-city } { <ls>-note_err }| )
                                                                    ).
    """"""""""""    me->tt_badi_error noch auf die korrekte Tabelle mit Rohdaten ändern
    DATA(tt_badi3) = VALUE string_table( FOR <ls> IN me->tt_badi_error (
                        |{ <ls>-customers_id } { <ls>-company } { <ls>-street } { <ls>-postcode } { <ls>-city } { <ls>-note_err }| )
                                                                    ).
    TRY.
        GET BADI lo_badi.
      CATCH cx_root INTO DATA(lx_error).
    ENDTRY.

    TRY.
        " WICHTIG: CALL BADI hat keine runden Klammern ( ) um die gesamte Exporting-Liste!
        CALL BADI lo_badi->after_import
          EXPORTING
            it_new   = tt_badi1
            it_error = tt_badi2
            it_raw   = tt_badi3.

      CATCH cx_root INTO DATA(lx_errorcall_badi).
    ENDTRY.

  ENDMETHOD.

  METHOD Email_err_tab.


    DATA lt_customers TYPE tt_output.
    lt_customers = me->tt_customers.



    LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<ls_customer>).
      " Erste Ebene: ty_output
      DATA(lv_company) = <ls_customer>-company.
      " Zweite Ebene: raw_table auslesen
      LOOP AT <ls_customer>-raw_table ASSIGNING FIELD-SYMBOL(<ls_raw>).
        DATA(lv_rawdata)   = <ls_raw>-rawdata.
        DATA(lv_email_err) = <ls_raw>-email_err.
        DATA(lv_phone_err) = <ls_raw>-phone_err.
        DATA(lv_fax_err)   = <ls_raw>-telefax_err.

        TRY.

            IF lv_email_err IS NOT INITIAL.
              RAISE EXCEPTION TYPE zcx_cs1_customer_failed
                EXPORTING
                  textid      = zcx_cs1_customer_failed=>regularexpression_email
                  column_name = 'Email'
                  filename    = column_name.



            ELSEIF  lv_phone_err IS NOT INITIAL.
              RAISE EXCEPTION TYPE zcx_cs1_customer_failed
                EXPORTING
                  textid      = zcx_cs1_customer_failed=>regularexpression_email
                  column_name = 'Tele'
                  filename    = column_name.



            ELSEIF  lv_phone_err IS NOT INITIAL.
              RAISE EXCEPTION TYPE zcx_cs1_customer_failed
                EXPORTING
                  textid      = zcx_cs1_customer_failed=>RegularExpression_TelFax
                  column_name = 'Telefax'
                  filename    = column_name.

            ENDIF.


         CATCH
            zcx_cs1_customer_failed INTO DATA(lx_exception).
              DATA(lv_error_note) = lx_exception->get_text( ).

         ENDTRY.

              me->tt_badi_error = VALUE #( BASE tt_badi_error
                       FOR ls1 IN me->tt_customers
                       WHERE ( email_err = abap_true )
                    ( note_err = lv_error_note )
                     ).

              me->tt_badi_error = VALUE #( BASE tt_badi_error
                     FOR ls2 IN me->tt_customers
                    WHERE ( Tele_err = abap_true )
                            (  note_err = lv_error_note ) ).

              me->tt_badi_error = VALUE #( BASE tt_badi_error
                    FOR ls3 IN me->tt_customers
                   WHERE ( Telfax_err = abap_true )
                            ( note_err = lv_error_note ) ).




          ENDLOOP.
        ENDLOOP.
*

*
*      LOOP AT lt_customers ASSIGNING FIELD-SYMBOL(<ls_customer>).
*        " Erste Ebene: ty_output
*        DATA(lv_company) = <ls_customer>-company.
*        " Zweite Ebene: raw_table auslesen
*        LOOP AT <ls_customer>-raw_table ASSIGNING FIELD-SYMBOL(<ls_raw>).
*          DATA(lv_rawdata)   = <ls_raw>-rawdata.
*          DATA(lv_email_err) = <ls_raw>-email_err.
*          DATA(lv_phone_err) = <ls_raw>-phone_err.
*          DATA(lv_fax_err)   = <ls_raw>-telefax_err.
*
*
*          IF lv_email_err IS NOT INITIAL.
*
*          TRY.
*            RAISE EXCEPTION TYPE zcx_cs1_customer_failed
*              EXPORTING
*                textid      = zcx_cs1_customer_failed=>regularexpression_email
*                column_name = 'Email'
*                filename    = lv_email_err.
*          CATCH zcx_cs1_customer_failed INTO DATA(lx_exception).
*           lv_error_note = lx_exception->get_error_note( ).
*
*            me->tt_badi_error = VALUE #( BASE tt_badi_error
*              FOR ls IN me->tt_customers
*              WHERE ( email_err = abap_true )
*               note_err = get_error_note  ).
*
*
*
*
*          ELSEIF  lv_phone_err IS NOT INITIAL.
*          TRY.
*            RAISE EXCEPTION TYPE zcx_cs1_customer_failed
*              EXPORTING
*                textid      = zcx_cs1_customer_failed=>regularexpression_email
*                column_name = 'Tele'
*                filename    = lc_method_name.
*          CATCH zcx_cs1_customer_failed INTO lx_exception.
*           lv_error_note = lx_exception->get_error_note( ).
*
*            me->tt_badi_error = VALUE #( BASE tt_badi_error
*              FOR ls2 IN me->tt_customers
*             WHERE ( Tele_err = abap_true )
*             note_err = lv_error_note  ).
*
*
*
*
*          ELSEIF  lv_phone_err IS NOT INITIAL.
*          TRY.
*            RAISE EXCEPTION TYPE zcx_cs1_customer_failed
*              EXPORTING
*                textid      = zcx_cs1_customer_failed=>RegularExpression_TelFax
*                column_name = 'Telefax'
*                filename    = lc_method_name.
*
*         CATCH zcx_cs1_customer_failed INTO lx_exception.
*           lv_error_note = lx_exception->get_error_note( ).
*
*            me->tt_badi_error = VALUE #( BASE tt_badi_error
*          FOR ls2 IN me->tt_customers
*         WHERE ( Telefax_err = abap_true )
*                  note_err = lv_error_note ) .
*
*          ENDIF.
*
*
*        ENDLOOP.
*      ENDLOOP.
**
*
      ENDMETHOD.

  METHOD  Email_Tele_Telfax_Error.
    ETT_Erroer = me->tt_badi_new.
  ENDMETHOD.

ENDCLASS.
