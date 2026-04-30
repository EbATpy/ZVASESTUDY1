CLASS lhc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION IMPORTING  REQUEST requested_authorizations FOR customers RESULT result,
      validateEmail FOR VALIDATE ON SAVE IMPORTING keys FOR customers~validateEmail,
      validatePhone FOR VALIDATE ON SAVE IMPORTING keys FOR customers~validatePhone,
      validateFax   FOR VALIDATE ON SAVE IMPORTING keys FOR customers~validateFax,
      getCity       FOR DETERMINE ON SAVE   IMPORTING keys FOR customers~getCity,
      trimEmail     FOR DETERMINE ON MODIFY IMPORTING keys FOR customers~trimEmail.

ENDCLASS.

CLASS lhc_zr_cs1_customers IMPLEMENTATION.

  METHOD getcity.
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
        UPDATE FIELDS ( City Country )
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

ENDCLASS.

CLASS lsc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS adjust_numbers REDEFINITION.
ENDCLASS.

CLASS lsc_zr_cs1_customers IMPLEMENTATION.
  METHOD adjust_numbers.
    DATA(lo_num) = NEW zcl_cs1_customer_import( ).

    LOOP AT mapped-customers ASSIGNING FIELD-SYMBOL(<ls_mapped>)
         WHERE CustomerId IS INITIAL.

      DATA(lv_next) = lo_num->zif_cs1_validation~latenumbering( ).
      <ls_mapped>-CustomerId = |{ lv_next ALPHA = IN }|.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
