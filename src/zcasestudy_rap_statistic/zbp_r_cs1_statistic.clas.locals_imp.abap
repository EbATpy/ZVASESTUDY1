CLASS lhc_zr_cs1_statistic DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ZrCs1Statistic
        RESULT result,
      SetExclusiveActive FOR DETERMINE ON MODIFY
        IMPORTING keys FOR ZrCs1Statistic~SetExclusiveActive.
ENDCLASS.

CLASS lhc_zr_cs1_statistic IMPLEMENTATION.

  METHOD get_global_authorizations.

  ENDMETHOD.

METHOD SetExclusiveActive.
  READ ENTITIES OF zr_cs1_statistic IN LOCAL MODE
    ENTITY ZrCs1Statistic
      FIELDS ( StatID Active ClassName InterfaceName )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_changed).

  LOOP AT lt_changed INTO DATA(ls_changed) WHERE Active = abap_true.

    SELECT FROM zcs1_statistic
      FIELDS stat_id, class_name, interface_name
      WHERE active  = @abap_true  " <- StatID Filter entfernt
      INTO TABLE @DATA(lt_others).

    DELETE lt_others WHERE stat_id        = ls_changed-StatID
                       AND class_name     = ls_changed-ClassName
                       AND interface_name = ls_changed-InterfaceName.

    CHECK lt_others IS NOT INITIAL.


    MODIFY ENTITIES OF zr_cs1_statistic IN LOCAL MODE
      ENTITY ZrCs1Statistic
        UPDATE FIELDS ( Active )
        WITH VALUE #( FOR ls_other IN lt_others
                      ( %tky     = VALUE #( StatID = ls_other-stat_id )
                        Active   = abap_false
                        %control = VALUE #( Active = if_abap_behv=>mk-on ) ) )
        REPORTED DATA(lt_reported).

  ENDLOOP.

ENDMETHOD.


ENDCLASS.
