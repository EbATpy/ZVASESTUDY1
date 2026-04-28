CLASS zcl_cs1_customer_import_04 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

  PROTECTED SECTION.
  PRIVATE SECTION.


ENDCLASS.

CLASS zcl_cs1_customer_import_04 IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
      "" Datenbanktabelle deleten
        DELETE FROM zcs1_customers.
*    DELETE FROM zcs1_customers WHERE customerid IN ('208', '207', '206','205', '204', '203','202', '201', '200').


        if sy-subrc = 0.
           data(lv_counter) = 1.
        ENDIF.

         DELETE FROM zcs1_import_err.

        if sy-subrc = 0.
           lv_counter = lv_counter + 1.
        ENDIF.

    TRY.
        ""Der Aufruf der Methode dient zum erstmaligen Anlegen des Nummern Intervals
        "" und muss nur einmal aufgerufen werden.
        zcl_cs1_setupclass=>init_setup( )->run_setup( out ).
*        return.
        DATA(obj) = NEW lcl_customer_import( ).

        obj->parse_csv( ).

        "out->write( obj->return_table( ) ).

        obj->parse_customers( ).

*        out->write( obj->return_table( ) ).

         obj->import_customers( ).
         out->write( obj->return_table( ) ).

         obj->company_err_tab( ).
         out->write( obj->return_err_table( ) ).

         obj->new_customer_tab( ).
         out->write( obj->return_new_customer_tab_table( ) ).

         obj->call_badi( ).
*         out->write( obj-> ).

      CATCH cx_sy_open_sql_db cx_uuid_error.
        "handle exception
       ""+++++++++++++++++ NEU für Exception Class !!!!! muss auch noch ins original!!!
       CATCH zcx_cs1_customer_failed INTO DATA(lx_error).
        " Hier fängst du den Fehler ab, damit die Syntax-Fehlermeldung verschwindet
        out->write( |Fehler aufgetreten:| ).
        out->write( lx_error->get_text( ) ). " Die Nachricht aus ZCSV_MSG
        out->write( |Datei: { lx_error->filename } Zeile: { lx_error->line_number }| ).
    ENDTRY.
*    out->write( lt_customs ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.

  ENDMETHOD.

  METHOD if_apj_dt_exec_object~get_parameters.

  ENDMETHOD.

ENDCLASS.
