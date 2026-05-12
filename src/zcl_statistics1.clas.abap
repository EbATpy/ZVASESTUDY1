CLASS zcl_statistics1 DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_statistics1.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_statistics1 IMPLEMENTATION.

  METHOD zif_statistics1~average_sales.
    DATA(lv_date_from) = |{ iv_gjahr }0101|.
    DATA(lv_date_to)   = |{ iv_gjahr }1231|.

    SELECT AVG( order_total )
      FROM zcs1_custorders
      WHERE order_date BETWEEN @lv_date_from AND @lv_date_to
        AND customerid = @iv_kunnr  " <- Neu: Filter auf Kunde
      INTO @rv_avg.
  ENDMETHOD.

  METHOD zif_statistics1~max_sales.
    SELECT MAX( order_total )
      FROM zcs1_custorders
      WHERE customerid = @iv_kunnr
      INTO @rv_max.
  ENDMETHOD.

  METHOD zif_statistics1~day_sales.
    DATA: lv_gjahr_string TYPE zid_value1,
          lv_gjahr        TYPE gjahr,
          lv_first_day    TYPE d,
          lv_last_day     TYPE d,
          lv_user_langu   TYPE sy-langu.

    " Alle Spalten (*) auslesen, wo die ID übereinstimmt

    SELECT SINGLE id_value, active
      FROM zcs1_service
      WHERE id = 'DefaultJahrStatistik'
      INTO @DATA(ls_service).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    lv_gjahr = COND #( WHEN ls_service-id_value IS NOT INITIAL
                             THEN ls_service-id_value
                             ELSE cl_abap_context_info=>get_system_date( ) ).

    DATA lv_land TYPE land1.

    IF ls_service-active = abap_false.
      lv_land = 'US'.
    ELSE.
      lv_land = 'DE'.
    ENDIF.


    " 3. Entscheidung der Geschäftsjahresvariante
    IF lv_land = 'US'.
      lv_first_day = |{ lv_gjahr }0701|. " US-Start April (Beispiel)
      lv_last_day  = |{ lv_gjahr + 1 }0630|.
    ELSE.
      lv_first_day = |{ lv_gjahr }0101|. " Standard-Start Januar
      lv_last_day  = |{ lv_gjahr }1231|.
    ENDIF.

    " 4. Zeitliche Begrenzung: Nicht in die Zukunft rechnen
    IF lv_last_day > lv_today.
      lv_last_day = lv_today.
    ENDIF.

    " Falls das gewählte Jahr noch gar nicht begonnen hat
    IF lv_first_day > lv_today.
      rv_day = 0.
      RETURN.
    ENDIF.

    " 5. Tage berechnen
    DATA(lv_days) = lv_last_day - lv_first_day + 1.

    " 6. Durchschnitt berechnen
    IF lv_days > 0.
      SELECT SUM( order_total )
        FROM zcs1_custorders
        WHERE order_date BETWEEN @lv_first_day AND @lv_last_day
        INTO @rv_day.

      rv_day = rv_day / lv_days.
    ENDIF.


*    DATA(lv_date_from) = |{ iv_gjahr }0101|.
*    DATA(lv_date_to)   = |{ iv_gjahr }1231|.
*
*    SELECT AVG( order_total )
*      FROM zcs1_custorders
*      WHERE order_date BETWEEN @lv_date_from AND @lv_date_to
*      INTO @rv_day.
*    rv_day = rv_day / 365.



  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.



  ENDMETHOD.

ENDCLASS.
