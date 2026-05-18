CLASS zcl_statistics1_04 DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_statistics1_04.
    INTERFACES if_oo_adt_classrun.
    INTERFACES zif_statistics1.
    METHODS statistics.
ENDCLASS.



CLASS ZCL_STATISTICS1_04 IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    " 2. Customizing lesen
    SELECT SINGLE FROM zcs1_statistic
      FIELDS class_name, interface_name
      WHERE stat_id = 'DEFAULT'
        AND active   = @abap_true
      INTO @DATA(ls_stat).

    IF sy-subrc <> 0.
      out->write( 'Kein Customizing gefunden.' ).
      RETURN.
    ENDIF.
    TRY.

        " 3. Variablen für Ergebnisse
        DATA: lv_max        TYPE zorder_total1,
              lv_avg        TYPE zorder_total1,
              lv_day        TYPE zorder_total1,
              lv_gjahr      TYPE gjahr          VALUE '2026',
              lv_customerid TYPE zcustomerid1   VALUE '000022'.

        " --- DER DYNAMISCHE TEIL ---
        " 1. Instanz der Klasse erzeugen
        DATA lo_object TYPE REF TO object.
        TRY.
            CREATE OBJECT lo_object TYPE (ls_stat-class_name).
          CATCH cx_sy_create_object_error.
            out->write( |Klasse konnte nicht instanziiert werden: { ls_stat-class_name }| ).
            RETURN.
        ENDTRY.

        " 2. RTTS: Interface-Typbeschreibung holen und auf Typ prüfen
        DATA lo_intf_descr TYPE REF TO cl_abap_objectdescr.

        TRY.
            DATA(lo_generic_descr) = cl_abap_typedescr=>describe_by_name( ls_stat-interface_name ).

            " Prüfen, ob der Typ existiert und ein Interface ist
            IF lo_generic_descr IS NOT BOUND OR
               lo_generic_descr->kind <> cl_abap_typedescr=>kind_intf.
              out->write( |Der Name ist kein gültiges Interface: { ls_stat-interface_name }| ).
              RETURN.
            ENDIF.

            " Sicherer Cast auf die Object-/Interface-Beschreibung
            lo_intf_descr = CAST cl_abap_objectdescr( lo_generic_descr ).

          CATCH cx_sy_move_cast_error.
            out->write( |Interface existiert nicht oder Typkonflikt: { ls_stat-interface_name }| ).
            RETURN.
        ENDTRY.

        " 2. RTTS: Prüfen, ob die Methode im Interface definiert ist
        READ TABLE lo_intf_descr->methods
          WITH KEY name = 'AVERAGE_SALES'
          TRANSPORTING NO FIELDS.

        IF sy-subrc <> 0.
          out->write( 'Methode AVERAGE_SALES fehlt im Interface!' ).
          RETURN.
        ENDIF.

        " 3. RTTS: Dynamischen Referenztyp auf das Interface erzeugen
        DATA(lo_ref_descr) = cl_abap_refdescr=>create( lo_intf_descr ).

        " 4. RTTC: Datenobjekt vom Typ 'REF TO (Interface)' generieren
        DATA lo_dyn_intf_ref TYPE REF TO data.
        CREATE DATA lo_dyn_intf_ref TYPE HANDLE lo_ref_descr.

        " 5. Feldsymbol zuweisen und Downcast ausführen
        ASSIGN lo_dyn_intf_ref->* TO FIELD-SYMBOL(<lo_intf_ptr>).

        TRY.
            <lo_intf_ptr> ?= lo_object.
          CATCH cx_sy_move_cast_error.
            out->write( |Die Klasse { ls_stat-class_name } implementiert das Interface { ls_stat-interface_name } nicht.| ).
            RETURN.
        ENDTRY.

        " 6. Direktes Instanziieren einer Objektreferenz für den Methodenaufruf
        DATA lo_stat_if TYPE REF TO object.
        lo_stat_if = <lo_intf_ptr>.

****************************************ALTER TEIL **************************
*        " A. Objekt der Klasse erzeugen
*        DATA: lo_object TYPE REF TO object.
*        CREATE OBJECT lo_object TYPE (ls_stat-class_name).
*
*        " B. Dynamische Interface-Referenz vorbereiten
*        " Wir erzeugen eine Datenreferenz, die einen 'Pointer' auf das Interface hält
*        DATA: lo_dynamic_intf_ref TYPE REF TO data.
*        CREATE DATA lo_dynamic_intf_ref TYPE REF TO (ls_stat-interface_name).
*
*        " C. Feldsymbol nutzen, um den 'Pointer' ansprechbar zu machen
*        ASSIGN lo_dynamic_intf_ref->* TO FIELD-SYMBOL(<lo_stat_if_ptr>).
*
*        " D. CAST: Das Objekt in das dynamische Interface 'zwingen'
*        " Das Feldsymbol <lo_stat_if_ptr> hält jetzt die Interface-Instanz
*        <lo_stat_if_ptr> ?= lo_object.
*
*        " --- DER ENTSCHEIDENDE SCHRITT FÜR CLOUD ---
*        " Wir weisen das Interface einer echten Objektreferenz zu,
*        " um den Fehler 'Über Datenreferenzen können keine Methoden aufgerufen werden' zu umgehen.
*        DATA: lo_stat_if TYPE REF TO object.
*        lo_stat_if ?= <lo_stat_if_ptr>.
***************************************************************************************************
        " Wir bauen den Namen: 'ZIF_STATISTICS1~AVERAGE_SALES'
        DATA(lv_method_name) = |{ ls_stat-interface_name }~AVERAGE_SALES|.

        " E. Methodenaufrufe (jetzt über die Objektreferenz lo_stat_if möglich)
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_gjahr = lv_gjahr
            iv_kunnr = lv_customerid
          RECEIVING
            rv_avg   = lv_avg.

        lv_method_name = |{ ls_stat-interface_name }~MAX_SALES|.
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_kunnr = lv_customerid
          RECEIVING
            rv_max   = lv_max.

        lv_method_name = |{ ls_stat-interface_name }~DAY_SALES|.
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_gjahr = lv_gjahr
          RECEIVING
            rv_day   = lv_day.

        " Ausgabe der Ergebnisse
        out->write( |Klasse: { ls_stat-class_name } / Interface: { ls_stat-interface_name }| ).
        out->write( |Average Sales: { lv_avg }| ).
        out->write( |Max Sales: { lv_max }| ).
        out->write( |Day Sales: { lv_day }| ).

      CATCH cx_sy_create_object_error INTO DATA(lx_create).
        out->write( |Fehler beim Erzeugen der Klasse: { lx_create->get_text( ) }| ).

      CATCH cx_sy_create_data_error.
        out->write( |Fehler: Interface { ls_stat-interface_name } existiert nicht.| ).

      CATCH cx_sy_move_cast_error.
        out->write( |Fehler: Klasse { ls_stat-class_name } implementiert { ls_stat-interface_name } nicht.| ).

      CATCH cx_sy_dyn_call_error INTO DATA(lx_call).
        out->write( |Fehler beim Methodenaufruf (Methode evtl. nicht vorhanden): { lx_call->get_text( ) }| ).

      CATCH cx_root INTO DATA(lx_root).
        out->write( |Unerwarteter Fehler: { lx_root->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.


  METHOD statistics.
  ENDMETHOD.


  METHOD zif_statistics1~max_sales.
    SELECT MAX( order_total )
      FROM zcs1_custorders
      WHERE customerid = @iv_kunnr
      INTO @rv_max.
  ENDMETHOD.
ENDCLASS.
