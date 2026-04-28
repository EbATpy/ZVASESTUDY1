*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcl_setup_handler DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_system_setup1.

  PRIVATE SECTION.
    " Konstanten für beide Objekte
    CONSTANTS: c_obj_cust TYPE cl_numberrange_intervals=>nr_object VALUE 'ZCS_CUST1',
               c_obj_err  TYPE cl_numberrange_intervals=>nr_object VALUE 'ZCS_IDERR1',
               c_range_01 TYPE cl_numberrange_runtime=>nr_interval   VALUE '01'.

    METHODS setup_number_range
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out OPTIONAL.

    " Hilfsmethode, um Redundanz zu vermeiden
    METHODS create_interval
      IMPORTING iv_object TYPE cl_numberrange_intervals=>nr_object
                out       TYPE REF TO if_oo_adt_classrun_out OPTIONAL.

    METHODS setup_service_table
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out OPTIONAL.
ENDCLASS.

CLASS lcl_setup_handler IMPLEMENTATION.

  METHOD zif_system_setup1~run_setup.
    setup_number_range( out ).
    setup_service_table( out ).
  ENDMETHOD.

  METHOD setup_number_range.
    " Ruft die Erstellung für beide Objekte auf
    create_interval( iv_object = c_obj_cust out = out ).
    create_interval( iv_object = c_obj_err  out = out ).
  ENDMETHOD.

  METHOD create_interval.
    DATA: lt_intervals TYPE cl_numberrange_intervals=>nr_interval,
          lv_error     TYPE abap_bool.

    TRY.
        cl_numberrange_intervals=>read(
          EXPORTING object   = iv_object
          IMPORTING interval = lt_intervals ).

        IF NOT line_exists( lt_intervals[ nrrangenr = c_range_01 ] ).
          lt_intervals = VALUE #( ( nrrangenr  = c_range_01
                                    fromnumber = '000001'
                                    tonumber   = '999999' ) ).

          cl_numberrange_intervals=>create(
            EXPORTING interval  = lt_intervals
                      object    = iv_object
            IMPORTING error     = lv_error
                      error_inf = DATA(ls_error_inf) ).

          IF out IS BOUND.
            out->write( COND #( WHEN lv_error IS INITIAL
                                THEN |Objekt { iv_object }: Intervall { c_range_01 } erfolgreich erstellt.|
                                ELSE |Fehler bei { iv_object }: { ls_error_inf-msgnr }| ) ).
          ENDIF.
        ENDIF.
      CATCH cx_number_ranges INTO DATA(lx_error).
        IF out IS BOUND.
          out->write( |Fehler bei { iv_object }: { lx_error->get_text( ) }| ).
        ENDIF.
    ENDTRY.
  ENDMETHOD.

 METHOD setup_service_table.
    DATA: lt_intervals TYPE cl_numberrange_intervals=>nr_interval,
          lt_update    TYPE cl_numberrange_intervals=>nr_interval.

    " 1. Counts für beide Tabellen einzeln ermitteln
    SELECT COUNT(*) FROM zcs1_customers INTO @DATA(lv_cust_count).
    SELECT COUNT(*) FROM zcs1_import_err INTO @DATA(lv_err_count).

    " 2. Typen lokal definieren, damit VALUE den Typ eindeutig erkennt
    TYPES: BEGIN OF ty_reset_check,
             obj   TYPE cl_numberrange_intervals=>nr_object,
             count TYPE i,
           END OF ty_reset_check.
    TYPES tt_reset_checks TYPE STANDARD TABLE OF ty_reset_check WITH EMPTY KEY.

    " Tabelle mit den Prüfdaten befüllen
    DATA(lt_checks) = VALUE tt_reset_checks(
        ( obj = c_obj_cust count = lv_cust_count )
        ( obj = c_obj_err  count = lv_err_count )
    ).

    " 3. Über die Checks iterieren
    LOOP AT lt_checks INTO DATA(ls_check).
      " Nur zurücksetzen, wenn die jeweilige Tabelle leer ist
      IF ls_check-count = 0.
        TRY.
            cl_numberrange_intervals=>read(
              EXPORTING object   = ls_check-obj
              IMPORTING interval = lt_intervals ).

            IF line_exists( lt_intervals[ nrrangenr = c_range_01 ] ).
              DATA(ls_line) = lt_intervals[ nrrangenr = c_range_01 ].
              ls_line-nrlevel = 0.
              ls_line-procind = 'U'.

              lt_update = VALUE #( ( ls_line ) ).

              cl_numberrange_intervals=>update(
                EXPORTING object    = ls_check-obj
                          interval  = lt_update
                IMPORTING error     = DATA(lv_error)
                          error_inf = DATA(ls_error_info) ).

              IF out IS BOUND.
                IF lv_error IS INITIAL.
                  out->write( |Intervall { ls_check-obj } wurde auf 0 zurückgesetzt.| ).
                ELSE.
                  out->write( |Fehler beim Reset von { ls_check-obj }: { ls_error_info-msgnr }| ).
                ENDIF.
              ENDIF.
            ENDIF.
          CATCH cx_number_ranges INTO DATA(lx_error).
            IF out IS BOUND.
              out->write( |Exception bei { ls_check-obj }: { lx_error->get_text( ) }| ).
            ENDIF.
        ENDTRY.
      ELSE.
        IF out IS BOUND.
          out->write( |Intervall { ls_check-obj } nicht zurückgesetzt ({ ls_check-count } Einträge vorhanden).| ).
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


ENDCLASS.
