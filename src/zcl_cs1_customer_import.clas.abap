CLASS zcl_cs1_customer_import DEFINITION
  PUBLIC

  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.
    INTERFACES zif_cs1_validation.

    METHODS main_programm
      IMPORTING io_out TYPE REF TO if_oo_adt_classrun_out OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.


ENDCLASS.



CLASS ZCL_CS1_CUSTOMER_IMPORT IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    main_programm( io_out = out ).
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    main_programm(  ).
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    CLEAR et_parameter_def.
    CLEAR et_parameter_val.
  ENDMETHOD.


  METHOD main_programm.

*    "" Datenbanktabelle deleten
*    DELETE FROM zcs1_customers.
*
*    IF sy-subrc = 0.
*      DATA(lv_counter) = 1.
*    ENDIF.
*
*    DELETE FROM zcs1_import_err.
*
*    IF sy-subrc = 0.
*      lv_counter = lv_counter + 1.
*    ENDIF.

    TRY.
        ""Der Aufruf der Methode dient zum erstmaligen Anlegen des Nummern Intervals
        "" und muss nur einmal aufgerufen werden


        zcl_cs1_setupclass=>init_setup( )->run_setup( io_out ).


        DATA(lo_csv_processor) = NEW lcl_customer_import( ).


        lo_csv_processor->parse_csv( ).
        "out->write( lo_csv_processor->return_table( ) ).

        lo_csv_processor->parse_customers( ).

        io_out->write( lo_csv_processor->return_table( ) ).

        lo_csv_processor->import_customers( ).
        io_out->write( '-------- return_table ----------' ).
        io_out->write( lo_csv_processor->return_table( ) ).

        lo_csv_processor->new_customer_tab( ).
        io_out->write( '-------- return_new_customer_tab_table ----------' ).
        io_out->write( lo_csv_processor->return_new_customer_tab_table( ) ).

        lo_csv_processor->email_err_tab( ).
        io_out->write( '--------  Email_Tele_Telfax_Error ----------' ).
        io_out->write( lo_csv_processor->Email_Tele_Telfax_Error( ) ).

        lo_csv_processor->company_err_tab( ).
        io_out->write( '-------- return_err_table ----------' ).
        io_out->write( lo_csv_processor->return_err_table( ) ).

*        io_out->write( lo_csv_processor->return_table( ) ).

        lo_csv_processor->call_badi( ).
*         out->write( lo_csv_processor-> ).

      CATCH cx_sy_open_sql_db cx_uuid_error.
        "handle exception
        ""+++++++++++++++++ NEU für Exception Class !!!!! muss auch noch ins original!!!
      CATCH zcx_cs1_customer_failed INTO DATA(lx_error).
        " Hier fängst du den Fehler ab, damit die Syntax-Fehlermeldung verschwindet
        io_out->write( |Fehler aufgetreten:| ).
        io_out->write( lx_error->get_text( ) ). " Die Nachricht aus ZCSV_MSG
        io_out->write( |Datei: { lx_error->filename } Zeile: { lx_error->line_number }| ).
    ENDTRY.
*    out->write( lt_customs ).
  ENDMETHOD.


  METHOD zif_cs1_validation~is_email_valid.
    rv_valid = lcl_customer_import=>is_email_valid( iv_email = CONV string( iv_email ) ).
  ENDMETHOD.


  METHOD zif_cs1_validation~is_phone_valid.
    rv_valid = lcl_customer_import=>is_tel_valid( iv_tel = CONV string( iv_phone ) ).
  ENDMETHOD.


  METHOD zif_cs1_validation~is_fax_valid.
    rv_valid = lcl_customer_import=>is_fax_valid( iv_tel = CONV string( iv_fax ) ).
  ENDMETHOD.


  METHOD zif_cs1_validation~latenumbering.
    TRY.
        rv_id = lcl_customer_import=>get_next_customer_id( ).
      CATCH cx_number_ranges.
        "handle exception
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
