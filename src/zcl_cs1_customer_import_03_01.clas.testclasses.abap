CLASS ltcl_customer_import_valid DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS: gc_email_ok_1 TYPE string VALUE 'test.user@example.com',
               gc_email_ok_2 TYPE string VALUE 'info@sub.domain.de',
               gc_email_bad_1 TYPE string VALUE 'missing-at.de',
               gc_email_bad_2 TYPE string VALUE 'user@domain',
               gc_phone_ok_1 TYPE string VALUE '+49500000',
               gc_phone_ok_2 TYPE string VALUE '+49 (211) 123-456',
               gc_phone_bad_1 TYPE string VALUE '+49ABCD'.

    METHODS:
      email_accepts_valid FOR TESTING,           " 21
      email_rejects_no_at FOR TESTING,           " 19
      email_rejects_no_tld FOR TESTING,          " 20
      email_rejects_empty FOR TESTING,           " 19
      phone_accepts_e164 FOR TESTING,            " 20
      phone_accepts_german_fmt FOR TESTING,      " 24
      phone_rejects_letters FOR TESTING,         " 23
      phone_rejects_too_short FOR TESTING,       " 25
      phone_rejects_only_plus FOR TESTING,       " 23
      csv_parse_line_count_ok FOR TESTING.       " 23

ENDCLASS.

CLASS ltcl_customer_import_valid IMPLEMENTATION.

  METHOD email_accepts_valid.
    " Given + When + Then
    cl_abap_unit_assert=>assert_true(
      act = lcl_customer_import=>is_email_valid( gc_email_ok_1 )
      msg = |Email { gc_email_ok_1 } sollte gültig sein| ).

    cl_abap_unit_assert=>assert_true(
      act = lcl_customer_import=>is_email_valid( gc_email_ok_2 )
      msg = |Email { gc_email_ok_2 } sollte gültig sein| ).
  ENDMETHOD.

  METHOD email_rejects_no_at.
    cl_abap_unit_assert=>assert_false(
      act = lcl_customer_import=>is_email_valid( gc_email_bad_1 )
      msg = |Email ohne @ sollte ungültig sein: { gc_email_bad_1 }| ).
  ENDMETHOD.

  METHOD email_rejects_no_tld.
    cl_abap_unit_assert=>assert_false(
      act = lcl_customer_import=>is_email_valid( gc_email_bad_2 )
      msg = |Email ohne TLD sollte ungültig sein: { gc_email_bad_2 }| ).
  ENDMETHOD.

  METHOD email_rejects_empty.
    cl_abap_unit_assert=>assert_false(
      act = lcl_customer_import=>is_email_valid( '' )
      msg = 'Leerer String sollte als Email ungültig sein' ).
  ENDMETHOD.

  METHOD phone_accepts_e164.
    cl_abap_unit_assert=>assert_true(
      act = lcl_customer_import=>is_tel_valid( gc_phone_ok_1 )
      msg = |E.164 Format sollte gültig sein: { gc_phone_ok_1 }| ).
  ENDMETHOD.

  METHOD phone_accepts_german_fmt.
    cl_abap_unit_assert=>assert_true(
      act = lcl_customer_import=>is_tel_valid( gc_phone_ok_2 )
      msg = |Deutsches Format sollte gültig sein: { gc_phone_ok_2 }| ).
  ENDMETHOD.

  METHOD phone_rejects_letters.
    cl_abap_unit_assert=>assert_false(
      act = lcl_customer_import=>is_tel_valid( gc_phone_bad_1 )
      msg = |Telefon mit Buchstaben sollte ungültig sein: { gc_phone_bad_1 }| ).
  ENDMETHOD.

  METHOD phone_rejects_too_short.
    cl_abap_unit_assert=>assert_false(
      act = lcl_customer_import=>is_tel_valid( '123' )
      msg = 'Zu kurze Nummer sollte ungültig sein' ).
  ENDMETHOD.

  METHOD phone_rejects_only_plus.
    cl_abap_unit_assert=>assert_false(
      act = lcl_customer_import=>is_tel_valid( '+++' )
      msg = 'Nur Pluszeichen sollte ungültig sein' ).
  ENDMETHOD.

  METHOD csv_parse_line_count_ok.
    DATA(lo_cut) = NEW lcl_customer_import( ).
    CONSTANTS lc_expected_cnt TYPE i VALUE 208.

    lo_cut->parse_csv( ).
    lo_cut->parse_customers( ).
    DATA(lt_result) = lo_cut->return_table( ).
    DATA(lv_actual_cnt) = lines( lt_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_actual_cnt
      exp = lc_expected_cnt
      msg = |CSV Import: Erwartet { lc_expected_cnt } Zeilen, erhalten { lv_actual_cnt }| ).
  ENDMETHOD.

ENDCLASS.
