CLASS zcl_cs1_zipcode_import DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_cs1_zipcode_import IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DELETE FROM zcs1_zipcity.

    MODIFY zcs1_zipcity FROM TABLE @( VALUE #(
      ( client = sy-mandt postcode = '10115' city = 'Berlin' )
      ( client = sy-mandt postcode = '20095' city = 'Hamburg' )
      ( client = sy-mandt postcode = '80331' city = 'München' )
      ( client = sy-mandt postcode = '50667' city = 'Köln' )
      ( client = sy-mandt postcode = '60311' city = 'Frankfurt am Main' )
      ( client = sy-mandt postcode = '70173' city = 'Stuttgart' )
      ( client = sy-mandt postcode = '40213' city = 'Düsseldorf' )
      ( client = sy-mandt postcode = '44135' city = 'Dortmund' )
      ( client = sy-mandt postcode = '45127' city = 'Essen' )
      ( client = sy-mandt postcode = '04109' city = 'Leipzig' )
      ( client = sy-mandt postcode = '28195' city = 'Bremen' )
      ( client = sy-mandt postcode = '01067' city = 'Dresden' )
      ( client = sy-mandt postcode = '30159' city = 'Hannover' )
      ( client = sy-mandt postcode = '90402' city = 'Nürnberg' )
      ( client = sy-mandt postcode = '47051' city = 'Duisburg' )
      ( client = sy-mandt postcode = '44787' city = 'Bochum' )
      ( client = sy-mandt postcode = '42103' city = 'Wuppertal' )
      ( client = sy-mandt postcode = '33602' city = 'Bielefeld' )
      ( client = sy-mandt postcode = '53111' city = 'Bonn' )
      ( client = sy-mandt postcode = '48143' city = 'Münster' )
      ( client = sy-mandt postcode = '76133' city = 'Karlsruhe' )
      ( client = sy-mandt postcode = '68159' city = 'Mannheim' )
      ( client = sy-mandt postcode = '86150' city = 'Augsburg' )
      ( client = sy-mandt postcode = '65183' city = 'Wiesbaden' )
      ( client = sy-mandt postcode = '39104' city = 'Magdeburg' )
      ( client = sy-mandt postcode = '41061' city = 'Mönchengladbach' )
      ( client = sy-mandt postcode = '57072' city = 'Siegen' )
      ( client = sy-mandt postcode = '24103' city = 'Kiel' )
      ( client = sy-mandt postcode = '66111' city = 'Saarbrücken' )
      ( client = sy-mandt postcode = '93047' city = 'Regensburg' )
    ) ).
    COMMIT WORK.


    SELECT * FROM zcs1_zipcity INTO TABLE @DATA(lt_check).
    out->write( lt_check ).

  ENDMETHOD.
ENDCLASS.
