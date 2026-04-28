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
             rawdata      TYPE string,
             email_err    TYPE abap_boolean,
             phone_err    TYPE abap_boolean,
             telefax_err  TYPE abap_boolean,
           END OF ty_import_raw,
           tt_raw TYPE STANDARD TABLE OF ty_import_raw WITH EMPTY KEY.

    TYPES: BEGIN OF ty_output,
             company       TYPE string,
             street        TYPE string,
             postcode      TYPE string,
             city          TYPE string,
             type          TYPE string,
             data1         TYPE string,
             data2         TYPE string,
             fax           TYPE string,
             phone         TYPE string,
             email         TYPE string,
             memo          TYPE string,
             raw_table     type tt_raw,
             company_Err   type abap_boolean,
             customers_id  type string,
           END OF ty_output,
           tt_output TYPE STANDARD TABLE OF ty_output WITH EMPTY KEY.

    data tt_customers type tt_output.


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

    "" Struktur für die Tabelle customers als Sortierte Tabelle
    TYPES tc_customer TYPE SORTED TABLE OF zcs1_customers WITH UNIQUE KEY company street postcode city.



    TYPES: BEGIN OF ty_errors,
             customers_id  type string,
             company       TYPE string,
             street        TYPE string,
             postcode      TYPE string,
             city          TYPE string,
             note_err      TYPE string,
           END OF ty_errors,
           tt_errors TYPE STANDARD TABLE OF ty_errors WITH EMPTY KEY.
   data tt_badi_error type tt_errors.



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

    data rt_output TYPE tt_output.

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

            data(valid_phone)   = me->is_tel_valid( data1_data2 ).
            data(valid_telefax) = me->is_tel_valid( data1_data2 ).
            data(valid_email)   = me->is_email_valid( data1 ).

            " -------------Phone is ''
            ls_member-type = COND #( WHEN ls_member-type = ''
                THEN |Phone|
                ELSE |{ ls_member-type }| ).

            " -------------Import raw data (keep all original lines)
            " -------------add phone_err;telefax_err;email_err
            data(phone_err)   = abap_false.
            data(telefax_err) = abap_false.
            data(email_err)   = abap_false.
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

            data(Phone)   = COND #( WHEN valid_phone   = abap_true
                THEN | { ls_member-type }:|
                ELSE | { ls_member-type }-ERR:| ).
            data(Telefax) = COND #( WHEN valid_telefax = abap_true
                THEN | { ls_member-type }:|
                ELSE | { ls_member-type }-ERR:| ).
            data(Email)   = COND #( WHEN valid_email   = abap_true
                THEN | { ls_member-type }:|
                ELSE | { ls_member-type }-ERR:| ).

            CASE ls_member-type.
              WHEN 'Phone'.
                IF lv_phone_done = abap_false and valid_phone = abap_true.
                  ls_out-phone  = data1_data2.
                  lv_phone_done = abap_true.
                ELSE.
                    if ls_out-phone <> data1_data2.
                        ls_out-memo = COND #( WHEN ls_out-memo IS INITIAL
                        THEN |{ Phone }{ data1_data2 }|
                        ELSE  |{ ls_out-memo };{ Phone }{ data1_data2 }| ).
                    endif.
                ENDIF.
              WHEN 'Telefax'.
                IF lv_fax_done = abap_false  and valid_telefax = abap_true.
                  ls_out-fax = data1_data2.
                  lv_fax_done    = abap_true.
                ELSE.
                    if ls_out-fax <> data1_data2.
                        ls_out-memo = COND #( WHEN ls_out-memo IS INITIAL
                         THEN |{ Telefax }{ data1_data2 }|
                         ELSE |{ ls_out-memo };{ Telefax }{ data1_data2 }| ).
                    endif.
                ENDIF.
              WHEN 'Email'.
                IF lv_email_done = abap_false  and valid_email = abap_true.
                  ls_out-email  = data1.
                  lv_email_done = abap_true.
                ELSE.
                    if ls_out-email <> data1.
                        ls_out-memo = COND #( WHEN ls_out-memo IS INITIAL
                        THEN |{ Email }{ data1 }|
                        ELSE |{ ls_out-memo };{ Email }{ data1 }| ).
                    endif.
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


ENDCLASS.
