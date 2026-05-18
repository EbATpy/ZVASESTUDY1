CLASS zcl_cs1_customer_import_03_01 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.
    INTERFACES zif_cs1_validation.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS main_programm
      IMPORTING iv_out TYPE REF TO if_oo_adt_classrun_out OPTIONAL.

ENDCLASS.



CLASS ZCL_CS1_CUSTOMER_IMPORT_03_01 IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    main_programm( iv_out = out ).
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    main_programm( ).
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    CLEAR et_parameter_def.
    CLEAR et_parameter_val.
  ENDMETHOD.


  METHOD main_programm.
    TRY.
        zcl_cs1_setupclass=>init_setup( )->run_setup( iv_out ).
        DATA(lo_csv_processor) = NEW lcl_customer_import( ).
        lo_csv_processor->parse_csv( ).
        lo_csv_processor->parse_customers( ).
        iv_out->write( lo_csv_processor->return_table( ) ).
        lo_csv_processor->import_customers( ).
        iv_out->write( '-------- return_table ----------' ).
        iv_out->write( lo_csv_processor->return_table( ) ).
        lo_csv_processor->new_customer_tab( ).
        iv_out->write( '-------- return_new_customer_tab_table ----------' ).
        iv_out->write( lo_csv_processor->return_new_customer_tab_table( ) ).
        lo_csv_processor->email_err_tab( ).
        iv_out->write( '--------  Email_Tele_Telfax_Error ----------' ).
        iv_out->write( lo_csv_processor->email_tele_telfax_error( ) ).
        lo_csv_processor->company_err_tab( ).
        iv_out->write( '-------- return_err_table ----------' ).
        iv_out->write( lo_csv_processor->return_err_table( ) ).
        lo_csv_processor->call_badi( ).
      CATCH cx_sy_open_sql_db cx_uuid_error.
        "handle exception
      CATCH zcx_cs1_customer_failed INTO DATA(lx_error).
        iv_out->write( |Fehler aufgetreten:| ).
        iv_out->write( lx_error->get_text( ) ).
        iv_out->write( |Datei: { lx_error->filename } Zeile: { lx_error->line_number }| ).
    ENDTRY.
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
