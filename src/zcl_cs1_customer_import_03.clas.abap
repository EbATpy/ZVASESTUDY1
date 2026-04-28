CLASS zcl_cs1_customer_import_03 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .


  PROTECTED SECTION.
  PRIVATE SECTION.


ENDCLASS.

CLASS zcl_cs1_customer_import_03 IMPLEMENTATION.

METHOD if_oo_adt_classrun~main.


        DATA(obj) = NEW lcl_customer_import( ).

        obj->parse_csv( ).

        "out->write( obj->return_table( ) ).

        obj->parse_customers( ).

        out->write( obj->return_table( ) ).

        "obj->import_customers( ).
         "out->write( obj->return_table( ) ).

        "obj->company_err_tab( ).

        "out->write( obj->return_err_table( ) ).
*       out->write( obj-> ).


  ENDMETHOD.

ENDCLASS.
