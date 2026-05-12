CLASS zcl_statistics1_04 DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_statistics1_04.
    INTERFACES if_oo_adt_classrun.
    METHODS statistics.
ENDCLASS.

CLASS zcl_statistics1_04 IMPLEMENTATION.

  METHOD zif_statistics1_04~average_sales.
*  " 1. Jahre dynamisch aus der Service-Tabelle lesen
*    SELECT id_value
*      FROM zcs1_service
*      where id = 'DefaultJahr'
*      INTO TABLE @DATA(lt_service_years).
*
*    IF lt_service_years IS INITIAL OR it_cust_id IS INITIAL.
*      RETURN.
*    ENDIF.
*
*    " 2. Durchschnittlicher Umsatz über Kundenliste und Service-Jahre
*    SELECT AVG( order_total )
*      FROM zcs1_custorders
*      FOR ALL ENTRIES IN @it_cust_id
*      WHERE customerid = @it_cust_id-table_line
*        AND order_date       = @lt_service_years
*      INTO @rv_avg.

  ENDMETHOD.

  METHOD zif_statistics1_04~max_sales.
*     " Maximaler Einzelumsatz pro Kunde aus zcs1_custorders
*    SELECT MAX( order_total )
*      FROM zcs1_custorders
*      WHERE customer_id = @it_cust_id-table_line
*      INTO @rv_max.

  ENDMETHOD.

  METHOD zif_statistics1_04~day_sales.
*    " Jahr aus zcs1_service validieren und Durchschnitt berechnen
*    SELECT id_value
*      FROM zcs1_service
*      where id = 'DefaultJahr'
*      INTO TABLE @DATA(lt_service_years).
*
*    IF sy-subrc = 0.
*      SELECT SUM( order_total )
*        FROM zcs1_custorders
*        WHERE gjahr = @lt_service_years
*        INTO @DATA(lv_total_sum).
*
*      rv_day = lv_total_sum / 365.
*    ENDIF.

  ENDMETHOD.



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

    " 3. Variablen für Ergebnisse
    DATA: lv_max        TYPE zorder_total1,
          lv_avg        TYPE zorder_total1,
          lv_day        TYPE zorder_total1,
          lv_gjahr      TYPE gjahr          VALUE '2026',
          lv_customerid TYPE zcustomerid1   VALUE '000022'.

    TRY.
        " --- DER DYNAMISCHE TEIL ---

        " A. Objekt der Klasse erzeugen
        DATA: lo_object TYPE REF TO object.
        CREATE OBJECT lo_object TYPE (ls_stat-class_name).

        " B. Dynamische Interface-Referenz vorbereiten
        " Wir erzeugen eine Datenreferenz, die einen 'Pointer' auf das Interface hält
        DATA: lo_dynamic_intf_ref TYPE REF TO data.
        CREATE DATA lo_dynamic_intf_ref TYPE REF TO (ls_stat-interface_name).

        " C. Feldsymbol nutzen, um den 'Pointer' ansprechbar zu machen
        ASSIGN lo_dynamic_intf_ref->* TO FIELD-SYMBOL(<lo_stat_if_ptr>).

        " D. CAST: Das Objekt in das dynamische Interface 'zwingen'
        " Das Feldsymbol <lo_stat_if_ptr> hält jetzt die Interface-Instanz
        <lo_stat_if_ptr> ?= lo_object.

        " --- DER ENTSCHEIDENDE SCHRITT FÜR CLOUD ---
        " Wir weisen das Interface einer echten Objektreferenz zu,
        " um den Fehler 'Über Datenreferenzen können keine Methoden aufgerufen werden' zu umgehen.
        DATA: lo_stat_if TYPE REF TO object.
        lo_stat_if ?= <lo_stat_if_ptr>.

        " Wir bauen den Namen: 'ZIF_STATISTICS1~AVERAGE_SALES'
         DATA(lv_method_name) = |{ ls_stat-interface_name }~AVERAGE_SALES|.

        " E. Methodenaufrufe (jetzt über die Objektreferenz lo_stat_if möglich)
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_gjahr  = lv_gjahr
            iv_kunnr  = lv_customerid
          RECEIVING
            rv_avg = lv_avg.

       lv_method_name = |{ ls_stat-interface_name }~MAX_SALES|.
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_kunnr  = lv_customerid
          RECEIVING
            rv_max = lv_max.

        lv_method_name = |{ ls_stat-interface_name }~DAY_SALES|.
        CALL METHOD lo_stat_if->(lv_method_name)
          EXPORTING
            iv_gjahr  = lv_gjahr
          RECEIVING
            rv_day = lv_day.

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

ENDCLASS.
