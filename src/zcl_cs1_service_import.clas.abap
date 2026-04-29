CLASS zcl_cs1_service_import DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.




CLASS zcl_cs1_service_import IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DATA lt_service TYPE  zcs1_service.

*"    lt_service = VALUE #(
*    ( id = 'CLIENT'              id_value =  '^\d{3}$'                                                      active = 'X' )
*    ( id = 'CUSTOMERID'          id_value =  '^[A-Za-z0-9]{6}$'                                             active = 'X' )
*    ( id = 'SALUTATION'          id_value =  '^[A-Za-z0-9@#!]{15}$'                                         active = 'X' )
*    ( id = 'LAST_NAME'           id_value =  '^[A-Za-z0-9@#!]{25}$'                                         active = 'X' )
*    ( id = 'FIRST_NAME'          id_value =  '^[A-Za-z0-9@#!]{20}$'                                         active = 'X' )
*    ( id = 'COMPANY'             id_value =  '^[A-Za-z0-9@#!]{60}$'                                         active = 'X' )
*    ( id = 'STREET'              id_value =  '^[A-Za-z0-9@#!]{50}$'                                         active = 'X' )
*    ( id = 'CITY'                id_value =  '^[A-Za-z0-9@#!]{30}$'                                         active = 'X' )
*    ( id = 'COUNTRY'             id_value =  '^[A-Z]{2}$'                                                   active = 'X' )
*    ( id = 'COUNTRY'             id_value =  '^[A-Za-z0-9]{8}$'                                             active = 'X' )
*    ( id = 'ACC_LOCK'            id_value =  '^(X)?$'                                                       active = 'X' )
*    ( id = 'LAST_DATE'           id_value =  '^\d{4}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$'               active = 'X' )
*    ( id = 'SALES_VOLUME'        id_value =  '^\d{1,7}(\.\d{1,2})?$'                                        active = 'X' )
*    ( id = 'SALES_VOLUME_TARGET' id_value =  '^\d{1,7}(\.\d{1,2})?$'                                        active = 'X' )
*    ( id = 'CHANGE_RATE_DATE'    id_value =  '^\d{4}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$'               active = 'X' )
*    ( id = 'fax'                 id_value =  '^\+49[1-9]\d{5,13}$'                                          active = 'X' )
*    ( id = 'phone'               id_value =  '^\+49[1-9]\d{5,13}$'                                          active = 'X' )
*    ( id = 'email'               id_value =  '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'             active = 'X' )
*    ( id = 'URL'                 id_value =  '^(https?://)?([\da-z\.-]+)\.([a-z\.]{2,6})([/\w \.-]*)*/?$'   active = 'X' )
*    ( id = 'CURRENCY'            id_value =  '^[A-Z]{3}$'                                                   active = 'X' )
*    ( id = 'CURRENCY_TARGET'     id_value =  '^[A-Z]{3}$'                                                   active = 'X' )
*    ( id = 'LANGUAGE'            id_value =  '^[A-Z]{1}$'                                                   active = 'X' )
*    ( id = 'WEBLOGIN'            id_value =  '^[A-Za-z0-9@#!]{60}$'                                         active = 'X' )
*    ( id = 'WEBPW'               id_value =  '^[A-Za-z0-9@#!]{60}$'                                         active = 'X' )
*    ( id = 'MEMO'                id_value =  '^[A-Za-z0-9@#!]{60}$'                                         active = 'X' ) ).
"
  ENDMETHOD.

ENDCLASS.
