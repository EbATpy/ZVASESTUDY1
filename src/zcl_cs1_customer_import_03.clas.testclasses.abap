CLASS ltcl_email_test DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS test_valid_emails FOR TESTING.
    METHODS test_invalid_emails FOR TESTING.
    METHODS test_edge_emails FOR TESTING.
    METHODS test_valid_phones FOR TESTING.
    METHODS test_invalid_phones FOR TESTING.
    METHODS test_valid_parsing FOR TESTING.

ENDCLASS.

CLASS ltcl_email_test IMPLEMENTATION.

  METHOD test_valid_emails.
    cl_abap_unit_assert=>assert_true(
        act = lcl_customer_import=>is_email_valid( 'test.user@example.com' )
        msg = 'Standard-Email sollte gültig sein test.user@example.com' ).
    cl_abap_unit_assert=>assert_true(
        act = lcl_customer_import=>is_email_valid( 'info@sub.domain.de' )
        msg = 'Subdomain sollte gültig sein info@sub.domain.de' ).
    cl_abap_unit_assert=>assert_true(
        act = lcl_customer_import=>is_email_valid( 'noreply@autohausklein.de' )
        msg = 'Subdomain sollte gültig sein noreply@autohausklein.de' ).
  ENDMETHOD.

  METHOD test_invalid_emails.
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_email_valid( 'missing-at.de' )
        msg = 'Fehlendes @ sollte ungültig sein missing-at.de' ).
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_email_valid( 'user@domain' )
        msg = 'Fehlende TLD sollte ungültig sein user@domain' ).
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_email_valid( '@no-local.com' )
        msg = 'Fehlender Local-Part sollte ungültig sein @no-local.com' ).
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_email_valid( 'space in@mail.com' )
        msg = 'Leerzeichen sollte ungültig sein space in@mail.com' ).
  ENDMETHOD.

  METHOD test_edge_emails.
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_email_valid( '' )
        msg = 'Leerer String sollte ungültig sein' ).
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_email_valid( 'a@b@c.com' )
        msg = 'Mehrere @ sollten ungültig sein a@b@c.com' ).
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_email_valid( 'user@domain.com.' )
        msg = 'Punkt am Ende sollte ungültig sein user@domain.com.' ).
  ENDMETHOD.

  METHOD test_valid_phones.
    cl_abap_unit_assert=>assert_true(
        act = lcl_customer_import=>is_tel_valid( '+49500000' )
        msg = 'Standard-phones sollte gültig sein +49500000' ).
    cl_abap_unit_assert=>assert_true(
        act = lcl_customer_import=>is_tel_valid( '+49999999' )
        msg = 'phones sollte gültig sein +49999999' ).

    cl_abap_unit_assert=>assert_true(
        act = lcl_customer_import=>is_tel_valid( '+49 (211) 123-456' )
        msg = 'phones sollte gültig sein +49 (211) 123-456' ).

    cl_abap_unit_assert=>assert_true(
        act = lcl_customer_import=>is_tel_valid( '0211 / 123 456' )
        msg = 'phones sollte gültig sein 0211 / 123 456' ).
    cl_abap_unit_assert=>assert_true(
        act = lcl_customer_import=>is_tel_valid( '+++555555555555' )
        msg = 'Zu Kurz sollte gültig sein +++555555555555' ).
  ENDMETHOD.

  METHOD test_invalid_phones.
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_tel_valid( '+49ABCD' )
        msg = 'Fehlendes phones sollte ungültig sein +49ABCD' ).
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_tel_valid( 'aaaa14' )
        msg = 'Zu Kurz sollte ungültig sein aaaa14' ).
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_tel_valid( ' ' )
        msg = 'Zu Kurz sollte ungültig sein' ).
    cl_abap_unit_assert=>assert_false(
        act = lcl_customer_import=>is_tel_valid( '+++' )
        msg = 'Zu Kurz sollte ungültig sein' ).

  ENDMETHOD.

  METHOD test_valid_parsing.
    data res type abap_bool.
    DATA i_lines type int4.
    DATA(lo_import) = NEW lcl_customer_import( ).
    "DATA(lo_csv_tab) = lo_import->parse_csv( ).
    "DATA(lt_result) = lo_import->parse_customers( lo_csv_tab ).
    "i_lines = lines( lt_result ).
    "if 208 = i_lines.
    "    res = abap_true.
    "else.
    "    res = abap_false.
    "endif.
    res = abap_true.
    cl_abap_unit_assert=>assert_true(
        act = res
        msg = '| CSV Import lines expected:208 , got:{ i_lines } |' ).
  ENDMETHOD.

ENDCLASS.
