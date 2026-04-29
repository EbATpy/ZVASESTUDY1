CLASS lhc_zr_cs1_customers DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION IMPORTING  REQUEST requested_authorizations FOR customers RESULT result,
      validateEmail FOR VALIDATE ON SAVE IMPORTING keys FOR customers~validateEmail,
      validatePhone FOR VALIDATE ON SAVE IMPORTING keys FOR customers~validatePhone,
      validateFax   FOR VALIDATE ON SAVE IMPORTING keys FOR customers~validateFax.
ENDCLASS.

CLASS lhc_zr_cs1_customers IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD validateEmail.
    READ ENTITIES OF zr_cs1_customers IN LOCAL MODE
      ENTITY customers
      FIELDS ( Email ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).
    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Email = ''. ENDIF.
      RETURN.
      IF lo_validator->zif_cs1_validation~is_email_valid( ls_customer-Email ) = abap_false.
        APPEND VALUE #( %tky = ls_customer-%tky ) TO failed-customers.
        APPEND VALUE #( %tky        = ls_customer-%tky
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
      FIELDS ( Email ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).
    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Phone = ''. ENDIF.
      RETURN.
      IF lo_validator->zif_cs1_validation~is_phone_valid( ls_customer-Phone ) = abap_false.
        APPEND VALUE #( %tky = ls_customer-%tky ) TO failed-customers.
        APPEND VALUE #( %tky        = ls_customer-%tky
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
      FIELDS ( Email ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_customers).
    LOOP AT lt_customers INTO DATA(ls_customer) WHERE Email IS NOT INITIAL.
      DATA(lo_validator) = NEW zcl_cs1_customer_import( ).
      IF ls_customer-Fax = ''. ENDIF.
      RETURN.
      IF lo_validator->zif_cs1_validation~is_fax_valid( ls_customer-Fax ) = abap_false.
        APPEND VALUE #( %tky = ls_customer-%tky ) TO failed-customers.
        APPEND VALUE #( %tky        = ls_customer-%tky
                        %state_area = 'VALIDATE_Phone'
                        %msg        = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text     = |Fax: { ls_customer-Phone } ist ungültig expected format:e.g. +494055448899| )
                        %element-Fax = if_abap_behv=>mk-on
                      ) TO reported-customers.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
