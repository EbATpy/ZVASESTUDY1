CLASS lcl_customer_import DEFINITION.

  PUBLIC SECTION.

    METHODS constructor.

    CLASS-DATA mt_is_email_valid_regex     TYPE string_table.
    CLASS-DATA mt_is_tel_valid_lv_clean    TYPE string_table.
    CLASS-DATA mt_is_tel_valid_lv_regex_1  TYPE string_table.
    CLASS-DATA mt_is_tel_valid_lv_regex_2  TYPE string_table.
    CLASS-DATA mt_split_csv_line_sep       TYPE string_table.
    CLASS-DATA mt_split_csv_line_replace1  TYPE string_table.
    CLASS-DATA mt_split_csv_line_replace2  TYPE string_table.
    CLASS-DATA mt_split_csv_line_replace3  TYPE string_table.
    CLASS-DATA mt_parse_customers_replace1 TYPE string_table.
    CLASS-DATA mt_parse_customers_replace2 TYPE string_table.
    CLASS-DATA mt_import_customers_webpass  TYPE string_table.
    CLASS-DATA mt_import_customers_acc_lock TYPE string_table.
    CLASS-DATA mt_import_customers_language TYPE string_table.
    CLASS-DATA mt_import_customers_country  TYPE string_table.
    CLASS-DATA mt_import_customers_curr     TYPE string_table.
    CLASS-DATA mt_import_customers_curr_t   TYPE string_table.
    CLASS-DATA mt_statistics1_land          TYPE string_table.

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
             company_err  TYPE abap_boolean,
             email_err    TYPE abap_boolean,
             tele_err     TYPE abap_boolean,
             telfax_err   TYPE abap_boolean,
             customers_id TYPE string,
           END OF ty_output,
           tt_output TYPE STANDARD TABLE OF ty_output WITH EMPTY KEY.

    TYPES: BEGIN OF ty_errors,
             customers_id TYPE string,
             company      TYPE string,
             street       TYPE string,
             postcode     TYPE string,
             city         TYPE string,
             note_err     TYPE string,
           END OF ty_errors,
           tt_errors TYPE STANDARD TABLE OF ty_errors WITH EMPTY KEY.

    METHODS parse_csv.
    METHODS parse_customers.
    METHODS import_customers RAISING zcx_cs1_customer_failed.
    METHODS company_err_tab.
    METHODS new_customer_tab.
    METHODS call_badi.
    METHODS email_err_tab.
    METHODS write_import_err IMPORTING iv_description TYPE string.
    METHODS refresh_service.
    METHODS delete_import_err.

    METHODS return_table RETURNING VALUE(rt_table) TYPE tt_output.
    METHODS return_err_table RETURNING VALUE(rt_error) TYPE tt_errors.
    METHODS return_new_customer_tab_table RETURNING VALUE(rt_new) TYPE tt_errors.
    METHODS email_tele_telfax_error RETURNING VALUE(rt_error) TYPE tt_errors.

    CLASS-METHODS is_email_valid
      IMPORTING iv_email        TYPE string
      RETURNING VALUE(rv_valid) TYPE abap_bool.

    CLASS-METHODS is_tel_valid
      IMPORTING iv_tel          TYPE string
      RETURNING VALUE(rv_valid) TYPE abap_bool.

    CLASS-METHODS is_fax_valid
      IMPORTING iv_tel          TYPE string
      RETURNING VALUE(rv_valid) TYPE abap_bool.

    CLASS-METHODS get_next_customer_id
      RETURNING VALUE(rv_customerid) TYPE zcustomerid1
      RAISING   cx_number_ranges.

    CLASS-METHODS get_next_id
      RETURNING VALUE(rv_id) TYPE zid1
      RAISING   cx_number_ranges.

  PRIVATE SECTION.

    METHODS split_csv_line
      IMPORTING iv_line        TYPE string
      RETURNING VALUE(rt_cols) TYPE string_table.

    METHODS get_service_data
      IMPORTING iv_name         TYPE string
      RETURNING VALUE(rt_table) TYPE string_table.

    DATA mt_customers  TYPE tt_output.
    DATA mt_badi_error TYPE tt_errors.
    DATA mt_badi_new   TYPE tt_errors.
    DATA mt_service    TYPE STANDARD TABLE OF zcs1_service1 WITH EMPTY KEY.
    DATA mv_error_note TYPE string.
    DATA mv_column_name TYPE string.



ENDCLASS.

CLASS lcl_customer_import IMPLEMENTATION.

  METHOD constructor.
    me->refresh_service( ).
  ENDMETHOD.

  METHOD refresh_service.
    CLEAR: me->mt_service.
    SELECT * FROM zcs1_service1 INTO TABLE @me->mt_service.

    mt_is_email_valid_regex     = me->get_service_data( iv_name = 'mt_is_email_valid_regex' ).
    mt_is_tel_valid_lv_clean    = me->get_service_data( iv_name = 'mt_is_tel_valid_lv_clean' ).
    mt_is_tel_valid_lv_regex_1  = me->get_service_data( iv_name = 'mt_is_tel_valid_lv_regex_1' ).
    mt_is_tel_valid_lv_regex_2  = me->get_service_data( iv_name = 'mt_is_tel_valid_lv_regex_2' ).
    mt_split_csv_line_sep       = me->get_service_data( iv_name = 'mt_split_csv_line_sep' ).
    mt_split_csv_line_replace1  = me->get_service_data( iv_name = 'mt_split_csv_line_replace1' ).
    mt_split_csv_line_replace2  = me->get_service_data( iv_name = 'mt_split_csv_line_replace2' ).
    mt_split_csv_line_replace3  = me->get_service_data( iv_name = 'mt_split_csv_line_replace3' ).
    mt_parse_customers_replace1 = me->get_service_data( iv_name = 'mt_parse_customers_replace1' ).
    mt_parse_customers_replace2 = me->get_service_data( iv_name = 'mt_parse_customers_replace2' ).
    mt_import_customers_webpass  = me->get_service_data( iv_name = 'mt_import_customers_webpass' ).
    mt_import_customers_acc_lock = me->get_service_data( iv_name = 'mt_import_customers_acc_lock' ).
    mt_import_customers_language = me->get_service_data( iv_name = 'mt_import_customers_language' ).
    mt_import_customers_country  = me->get_service_data( iv_name = 'mt_import_customers_country' ).
    mt_import_customers_curr     = me->get_service_data( iv_name = 'mt_import_customers_curr' ).
    mt_import_customers_curr_t   = me->get_service_data( iv_name = 'mt_import_customers_curr_t' ).
    mt_statistics1_land          = me->get_service_data( iv_name = 'mt_statistics1_land' ).

  ENDMETHOD.

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
      DATA(ls_raw)       = VALUE ty_import_raw( rawdata = ls_source-import ).
      APPEND ls_raw TO ls_test-raw_table.
      APPEND ls_test TO lt_initial_rows.
    ENDLOOP.
    MOVE-CORRESPONDING lt_initial_rows TO me->mt_customers.
  ENDMETHOD.

  METHOD return_table.
    rt_table = me->mt_customers.
  ENDMETHOD.

  METHOD split_csv_line.
    SPLIT iv_line AT mt_split_csv_line_sep[ 1 ] INTO TABLE DATA(lt_raw).
    LOOP AT lt_raw INTO DATA(lv_col).
      REPLACE ALL OCCURRENCES OF PCRE mt_split_csv_line_replace1[ 1 ] IN lv_col WITH mt_split_csv_line_replace1[ 2 ].
      REPLACE ALL OCCURRENCES OF PCRE mt_split_csv_line_replace2[ 1 ] IN lv_col WITH mt_split_csv_line_replace2[ 2 ].
      REPLACE ALL OCCURRENCES OF PCRE mt_split_csv_line_replace3[ 1 ] IN lv_col WITH mt_split_csv_line_replace3[ 2 ].
      APPEND lv_col TO rt_cols.
    ENDLOOP.
  ENDMETHOD.

METHOD parse_customers.

  DATA lt_customers_merged TYPE tt_output.

  DATA(lt_customers_condensed) = VALUE tt_output(
    FOR ls_customer_raw IN me->mt_customers (
      company      = condense( val = ls_customer_raw-company )
      street       = condense( val = ls_customer_raw-street )
      postcode     = condense( val = ls_customer_raw-postcode )
      city         = condense( val = ls_customer_raw-city )
      type         = condense( val = ls_customer_raw-type )
      data1        = condense( val = ls_customer_raw-data1 )
      data2        = condense( val = ls_customer_raw-data2 )
      fax          = ls_customer_raw-fax
      phone        = ls_customer_raw-phone
      email        = ls_customer_raw-email
      memo         = ls_customer_raw-memo
      raw_table    = ls_customer_raw-raw_table
      company_err  = ls_customer_raw-company_err
      customers_id = ls_customer_raw-customers_id ) ).

  SORT lt_customers_condensed BY company street postcode city.

  LOOP AT lt_customers_condensed INTO DATA(ls_customer_current)
       GROUP BY ( company  = ls_customer_current-company
                  street   = ls_customer_current-street
                  postcode = ls_customer_current-postcode
                  city     = ls_customer_current-city )
       INTO DATA(ls_customer_group_key).

    DATA(ls_customer_merged) = VALUE ty_output(
      company  = ls_customer_group_key-company
      street   = ls_customer_group_key-street
      postcode = ls_customer_group_key-postcode
      city     = ls_customer_group_key-city ).

    DATA(lv_phone_already_set) = abap_false.
    DATA(lv_fax_already_set)   = abap_false.
    DATA(lv_email_already_set) = abap_false.

    LOOP AT GROUP ls_customer_group_key INTO DATA(ls_contact_detail).
      DATA(lv_contact_number_full) = |{ ls_contact_detail-data1 }{ ls_contact_detail-data2 }|.
      DATA(lv_contact_email)       = |{ ls_contact_detail-data1 }|.

      lv_contact_number_full = replace( val = lv_contact_number_full pcre = '[^\d]' with = '' occ = 0 ).
      lv_contact_number_full = replace( val = lv_contact_number_full pcre = `^0(\d+)` with = `+49$1` occ = 1 ).

      DATA(lv_is_phone_valid) = me->is_tel_valid( lv_contact_number_full ).
      DATA(lv_is_fax_valid)   = me->is_fax_valid( lv_contact_number_full ).
      DATA(lv_is_email_valid) = me->is_email_valid( lv_contact_email ).

      ls_contact_detail-type = COND #( WHEN ls_contact_detail-type = ''
                                       THEN |Phone|
                                       ELSE |{ ls_contact_detail-type }| ).

      DATA(lv_has_phone_error) = abap_false.
      DATA(lv_has_fax_error)   = abap_false.
      DATA(lv_has_email_error) = abap_false.

      CASE ls_contact_detail-type.
        WHEN 'Phone'.
          lv_has_phone_error = xsdbool( lv_is_phone_valid = abap_false ).
        WHEN 'Telefax'.
          lv_has_fax_error   = xsdbool( lv_is_fax_valid = abap_false ).
        WHEN 'Email'.
          lv_has_email_error = xsdbool( lv_is_email_valid = abap_false ).
      ENDCASE.

      MODIFY ls_contact_detail-raw_table FROM VALUE #( email_err   = lv_has_email_error
                                                       phone_err   = lv_has_phone_error
                                                       telefax_err = lv_has_fax_error )
             INDEX 1 TRANSPORTING email_err phone_err telefax_err.
      APPEND LINES OF ls_contact_detail-raw_table TO ls_customer_merged-raw_table.

      DATA(lv_phone_label) = COND #( WHEN lv_is_phone_valid = abap_true
                                     THEN | { ls_contact_detail-type }:|
                                     ELSE | { ls_contact_detail-type }-ERR:| ).
      DATA(lv_fax_label)   = COND #( WHEN lv_is_fax_valid = abap_true
                                     THEN | { ls_contact_detail-type }:|
                                     ELSE | { ls_contact_detail-type }-ERR:| ).
      DATA(lv_email_label) = COND #( WHEN lv_is_email_valid = abap_true
                                     THEN | { ls_contact_detail-type }:|
                                     ELSE | { ls_contact_detail-type }-ERR:| ).

      CASE ls_contact_detail-type.
        WHEN 'Phone'.
          IF lv_phone_already_set = abap_false AND lv_is_phone_valid = abap_true.
            ls_customer_merged-phone = lv_contact_number_full.
            lv_phone_already_set     = abap_true.
          ELSEIF ls_customer_merged-phone <> lv_contact_number_full.
            ls_customer_merged-memo = COND #( WHEN ls_customer_merged-memo IS INITIAL
              THEN |{ lv_phone_label }{ lv_contact_number_full }|
              ELSE |{ ls_customer_merged-memo };{ lv_phone_label }{ lv_contact_number_full }| ).
          ENDIF.
        WHEN 'Telefax'.
          IF lv_fax_already_set = abap_false AND lv_is_fax_valid = abap_true.
            ls_customer_merged-fax = lv_contact_number_full.
            lv_fax_already_set     = abap_true.
          ELSEIF ls_customer_merged-fax <> lv_contact_number_full.
            ls_customer_merged-memo = COND #( WHEN ls_customer_merged-memo IS INITIAL
               THEN |{ lv_fax_label }{ lv_contact_number_full }|
               ELSE |{ ls_customer_merged-memo };{ lv_fax_label }{ lv_contact_number_full }| ).
          ENDIF.
        WHEN 'Email'.
          IF lv_email_already_set = abap_false AND lv_is_email_valid = abap_true.
            ls_customer_merged-email = lv_contact_email.
            lv_email_already_set     = abap_true.
          ELSEIF ls_customer_merged-email <> lv_contact_email.
            ls_customer_merged-memo = COND #( WHEN ls_customer_merged-memo IS INITIAL
              THEN |{ lv_email_label }{ lv_contact_email }|
              ELSE |{ ls_customer_merged-memo };{ lv_email_label }{ lv_contact_email }| ).
          ENDIF.
        WHEN OTHERS.
          ls_customer_merged-memo = COND #( WHEN ls_customer_merged-memo IS INITIAL
            THEN |{ ls_contact_detail-type }:{ lv_contact_number_full }|
            ELSE |{ ls_customer_merged-memo };{ ls_contact_detail-type }:{ lv_contact_number_full }| ).
      ENDCASE.
    ENDLOOP.
    APPEND ls_customer_merged TO lt_customers_merged.
  ENDLOOP.

  MOVE-CORRESPONDING lt_customers_merged TO me->mt_customers.
ENDMETHOD.
  METHOD is_email_valid.
    DATA(lv_regex) = mt_is_email_valid_regex[ 1 ].
    rv_valid = xsdbool( matches( val = iv_email pcre = lv_regex ) ).
  ENDMETHOD.

  METHOD is_tel_valid.
    DATA(lv_clean) = replace( val  = iv_tel
                              pcre = mt_is_tel_valid_lv_clean[ 1 ]
                              with  = mt_is_tel_valid_lv_clean[ 2 ]
                              occ   = 0 ).

    DATA(lv_regex_1) = mt_is_tel_valid_lv_regex_1[ 1 ].
    DATA(lv_valid_1) = xsdbool( matches( val = lv_clean pcre = lv_regex_1 ) ).
    DATA(lv_regex_2) = mt_is_tel_valid_lv_regex_2[ 1 ].
    DATA(lv_valid_2) = xsdbool( matches( val = lv_clean pcre = lv_regex_2 ) ).

    rv_valid = xsdbool( lv_valid_1 = abap_true OR lv_valid_2 = abap_true ).
  ENDMETHOD.

  METHOD is_fax_valid.
    rv_valid = is_tel_valid( iv_tel ).
  ENDMETHOD.

  METHOD import_customers.
    DATA lt_customers TYPE SORTED TABLE OF zcs1_customers WITH UNIQUE KEY company street postcode city.
    DATA ls_customers LIKE LINE OF lt_customers.
    CONSTANTS lc_method_name TYPE string VALUE '=>IMPORT_CUSTOMERS'.
    SELECT * FROM zcs1_customers INTO TABLE @lt_customers.

    LOOP AT me->mt_customers ASSIGNING FIELD-SYMBOL(<ls_import>).
      TRY.
          MOVE-CORRESPONDING <ls_import> TO ls_customers.
          ls_customers-country         = mt_import_customers_country[ 1 ].
          ls_customers-currency        = mt_import_customers_curr[ 1 ].
          ls_customers-currency_target = mt_import_customers_curr_t[ 1 ].
          ls_customers-last_date       = cl_abap_context_info=>get_system_date( ).
          ls_customers-language        = mt_import_customers_language[ 1 ].
          ls_customers-acc_lock        = mt_import_customers_acc_lock[ 1 ].
          ls_customers-webpw           = mt_import_customers_webpass[ 1 ].

          ASSIGN lt_customers[ company  = ls_customers-company
                               street   = ls_customers-street
                               postcode = ls_customers-postcode
                               city     = ls_customers-city ] TO FIELD-SYMBOL(<ls_existing>).

          IF sy-subrc <> 0.
            ls_customers-customerid = lcl_customer_import=>get_next_customer_id( ).

            MODIFY me->mt_customers FROM VALUE #( customers_id = ls_customers-customerid )
                TRANSPORTING customers_id WHERE company = <ls_import>-company
                                            AND street = <ls_import>-street
                                            AND postcode = <ls_import>-postcode
                                            AND city = <ls_import>-city.

            INSERT ls_customers INTO TABLE lt_customers.

            DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( ls_customers ) ).
            DATA(lv_max_len) = lo_struct->get_component_type( 'COMPANY' )->length / cl_abap_char_utilities=>charsize.

            IF strlen( <ls_import>-company ) > lv_max_len.
              RAISE EXCEPTION TYPE zcx_cs1_customer_failed
                EXPORTING
                  textid      = zcx_cs1_customer_failed=>company_to_long
                  column_name = 'COMPANY'
                  filename    = lc_method_name.
            ENDIF.
          ENDIF.

          INSERT ls_customers INTO TABLE lt_customers.

        CATCH cx_number_ranges INTO DATA(lx_nr_err).
          DATA(lv_err) = |Nummernkreisfehler: { lx_nr_err->get_text( ) }|.

        CATCH zcx_cs1_customer_failed INTO DATA(lx_cust_err).
          DATA(lv_full_text) = |Customer-ID: { ls_customers-customerid }; { ls_customers-company }; | && |-> { lx_cust_err->get_text( ) }|.

          MODIFY me->mt_customers FROM VALUE #( company_err = abap_true )
              TRANSPORTING company_err WHERE company = <ls_import>-company
                                          AND street = <ls_import>-street
                                          AND postcode = <ls_import>-postcode
                                          AND city = <ls_import>-city.
          TRY.
              INSERT zcs1_import_err FROM @( VALUE #( id  = lcl_customer_import=>get_next_id( )
                                                      description = lv_full_text ) ).
            CATCH cx_number_ranges INTO DATA(lx_nr_err2).
              DATA(lv_err2) = |Nummernkreisfehler: { lx_nr_err2->get_text( ) }|.
          ENDTRY.
      ENDTRY.
    ENDLOOP.

    IF lt_customers IS NOT INITIAL.
      MODIFY zcs1_customers FROM TABLE @lt_customers.
    ENDIF.

  ENDMETHOD.

  METHOD get_next_customer_id.
    DATA lv_returned_number TYPE cl_numberrange_runtime=>nr_number.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING nr_range_nr = '01' object = 'ZCS_CUST1'
          IMPORTING number      = lv_returned_number ).
        rv_customerid = |{ lv_returned_number ALPHA = IN }|.
      CATCH cx_number_ranges INTO DATA(lx_error).
    ENDTRY.
  ENDMETHOD.

  METHOD get_next_id.
    DATA lv_returned_number TYPE cl_numberrange_runtime=>nr_number.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING nr_range_nr = '01' object = 'ZCS_IDERR1'
          IMPORTING number      = lv_returned_number ).
        rv_id = |{ lv_returned_number ALPHA = IN }|.
      CATCH cx_number_ranges INTO DATA(lx_error).
    ENDTRY.
  ENDMETHOD.

  METHOD company_err_tab.
    me->mt_badi_error = VALUE #( BASE mt_badi_error
          FOR ls_line IN me->mt_customers
          WHERE ( company_err = abap_true )
          ( customers_id = ls_line-customers_id
            company      = ls_line-company
            street       = ls_line-street
            postcode     = ls_line-postcode
            city         = ls_line-city
            note_err     = 'Company Name > 60' ) ).
  ENDMETHOD.

  METHOD return_err_table.
    rt_error = me->mt_badi_error.
  ENDMETHOD.

  METHOD new_customer_tab.
    me->mt_badi_new = VALUE #( BASE mt_badi_new
        FOR ls_line IN me->mt_customers
        WHERE ( customers_id IS NOT INITIAL )
        ( customers_id = ls_line-customers_id
          company      = ls_line-company
          street       = ls_line-street
          postcode     = ls_line-postcode
          city         = ls_line-city
          note_err     = 'New Customer' ) ).
  ENDMETHOD.

  METHOD return_new_customer_tab_table.
    rt_new = me->mt_badi_new.
  ENDMETHOD.

  METHOD call_badi.
    DATA lo_badi TYPE REF TO zcs1_badidef_import_customers.
    DATA(lt_badi1) = VALUE string_table( FOR ls_line IN me->mt_badi_new (
                        |{ ls_line-customers_id } { ls_line-company } { ls_line-street } { ls_line-postcode } { ls_line-city } { ls_line-note_err }| ) ).
    DATA(lt_badi2) = VALUE string_table( FOR ls_line IN me->mt_badi_error (
                        |{ ls_line-customers_id } { ls_line-company } { ls_line-street } { ls_line-postcode } { ls_line-city } { ls_line-note_err }| ) ).
    DATA(lt_badi3) = VALUE string_table( FOR ls_line IN me->mt_badi_error (
                        |{ ls_line-customers_id } { ls_line-company } { ls_line-street } { ls_line-postcode } { ls_line-city } { ls_line-note_err }| ) ).
    TRY.
        GET BADI lo_badi.
      CATCH cx_root INTO DATA(lx_error).
    ENDTRY.
    TRY.
        CALL BADI lo_badi->after_import
          EXPORTING it_new   = lt_badi1
                    it_error = lt_badi2
                    it_raw   = lt_badi3.
      CATCH cx_root INTO DATA(lx_errorcall_badi).
    ENDTRY.
  ENDMETHOD.

  METHOD write_import_err.
    TRY.
        INSERT zcs1_import_err FROM @( VALUE #( id  = lcl_customer_import=>get_next_id( )
                                                description = iv_description ) ).
      CATCH cx_number_ranges INTO DATA(lx_nr_err2).
        DATA(lv_err2) = |Nummernkreisfehler: { lx_nr_err2->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.

  METHOD email_err_tab.
    LOOP AT me->mt_customers ASSIGNING FIELD-SYMBOL(<ls_customer>).
      LOOP AT <ls_customer>-raw_table ASSIGNING FIELD-SYMBOL(<ls_raw>).
        DATA(lv_rawdata)   = <ls_raw>-rawdata.
        DATA(lv_email_err) = <ls_raw>-email_err.
        DATA(lv_phone_err) = <ls_raw>-phone_err.
        DATA(lv_fax_err)   = <ls_raw>-telefax_err.

        DATA lv_medium TYPE string.
        IF lv_email_err = abap_true.
          lv_medium = 'Telefon'.
          <ls_customer>-tele_err = abap_true.
        ELSEIF lv_phone_err = abap_true.
          lv_medium = 'Telefax'.
          <ls_customer>-telfax_err = abap_true.
        ELSEIF lv_fax_err = abap_true.
          lv_medium = 'Email'.
          <ls_customer>-email_err = abap_true.
        ENDIF.

        IF lv_email_err = abap_true OR lv_phone_err = abap_true OR lv_fax_err = abap_true.
          TRY.
              RAISE EXCEPTION TYPE zcx_cs1_customer_failed
                EXPORTING
                  textid     = zcx_cs1_customer_failed=>RegularExpression_Medium
                  medium     = lv_medium
                  MediumData = lv_rawdata.
            CATCH zcx_cs1_customer_failed INTO DATA(lx_exception).
              DATA(lv_error_note) = lx_exception->get_text( ).
              write_import_err( lv_error_note ).
              APPEND VALUE #( customers_id = <ls_customer>-customers_id
                              company      = <ls_customer>-company
                              street       = <ls_customer>-street
                              postcode     = <ls_customer>-postcode
                              city         = <ls_customer>-city
                              note_err     = lv_error_note ) TO me->mt_badi_error.
          ENDTRY.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD email_tele_telfax_error.
    rt_error = me->mt_badi_error.
  ENDMETHOD.

  METHOD delete_import_err.
    DELETE FROM zcs1_import_err.
  ENDMETHOD.

  METHOD get_service_data.
    DATA lv_value TYPE string.
    CLEAR: rt_table.
    READ TABLE me->mt_service INTO DATA(ls_found) WITH KEY id = iv_name.
    IF sy-subrc = 0.
      lv_value = COND #( WHEN ls_found-active = abap_true THEN ls_found-user_value ELSE ls_found-default_value ).
      SPLIT lv_value AT '###SC###' INTO TABLE rt_table.
      LOOP AT rt_table ASSIGNING FIELD-SYMBOL(<lv_val>).
        <lv_val> = condense( <lv_val> ).
      ENDLOOP.
      APPEND '' TO rt_table.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
