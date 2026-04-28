CLASS zcl_cs1_setupclass DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
     " Die einzige öffentliche Methode zum Starten
    CLASS-METHODS init_setup
      RETURNING VALUE(ro_setup) TYPE REF TO zif_system_setup1.

    INTERFACES if_oo_adt_classrun .


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cs1_setupclass IMPLEMENTATION.
  METHOD init_setup.
    ro_setup = NEW lcl_setup_handler( ).
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    " Hier startest du den Prozess
    init_setup( )->run_setup( out ).
  ENDMETHOD.

ENDCLASS.
