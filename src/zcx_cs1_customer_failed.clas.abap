CLASS zcx_cs1_customer_failed DEFINITION

    "zcx_csv_import
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_abap_behv_message.

    DATA filename   TYPE String READ-ONLY.
    DATA MediumData TYPE string READ-ONLY.
    DATA Medium     TYPE string READ-ONLY.
    DATA CSV_File   TYPE string READ-ONLY.
    DATA header     TYPE string READ-ONLY.
    DATA customer   TYPE string READ-ONLY.
    DATA company    TYPE string READ-ONLY.
    DATA Parsing    TYPE string READ-ONLY.

    DATA line_number TYPE i READ-ONLY.
    DATA column_name TYPE string READ-ONLY.

    CONSTANTS:
      " --- RAP spezifische Meldungen (nutzen IF_T100_DYN_MSG) ---
      BEGIN OF CurrencyTarget_missing,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF CurrencyTarget_missing,

      " --- RAP spezifische Meldungen (nutzen IF_T100_DYN_MSG) ---
      BEGIN OF Umrechnungsfehler,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF Umrechnungsfehler,

      " --- RAP spezifische Meldungen (nutzen IF_T100_DYN_MSG) ---
      BEGIN OF KD_Order_Sales_Volume,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF KD_Order_Sales_Volume,

      BEGIN OF RegularExpression_Medium,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '010',
        attr1 TYPE scx_attrname VALUE 'Medium',
        attr2 TYPE scx_attrname VALUE 'MediumData',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF RegularExpression_Medium,

      BEGIN OF CSV_File_Import,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '080',
        attr1 TYPE scx_attrname VALUE 'Parsing',
        attr2 TYPE scx_attrname VALUE 'column_name',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF CSV_File_Import,

      BEGIN OF invalid_header,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '040',
        attr1 TYPE scx_attrname VALUE ' header',
        attr2 TYPE scx_attrname VALUE 'column_name',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF invalid_header,

      BEGIN OF customer_missing,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '050',
        attr1 TYPE scx_attrname VALUE ' customer',
        attr2 TYPE scx_attrname VALUE 'column_name',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF customer_missing,

      BEGIN OF company_to_long,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '060',
        attr1 TYPE scx_attrname VALUE 'column_name',
        attr2 TYPE scx_attrname VALUE 'filename',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF company_to_long,

      BEGIN OF RegularExpression_Tele,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '070',
        attr1 TYPE scx_attrname VALUE 'Tele',
        attr2 TYPE scx_attrname VALUE 'column_name',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF RegularExpression_Tele.


    " Statische Fabrikmethode hinzufügen

    CLASS-METHODS new_message
      IMPORTING
        i_textid      LIKE if_t100_message=>t100key
        i_severity    TYPE if_abap_behv_message=>t_severity DEFAULT if_abap_behv_message=>severity-error
        i_v1          TYPE simple OPTIONAL
        i_v2          TYPE simple OPTIONAL
        i_v3          TYPE simple OPTIONAL
        i_v4          TYPE simple OPTIONAL
      RETURNING
        VALUE(ro_obj) TYPE REF TO zcx_cs1_customer_failed.



    METHODS constructor
      IMPORTING
        textid      LIKE if_t100_message=>t100key OPTIONAL
        previous    LIKE previous OPTIONAL
        column_name LIKE column_name OPTIONAL
        filename    LIKE filename OPTIONAL
        Medium      LIKE Medium OPTIONAL
        MediumData  LIKE MediumData OPTIONAL
        CSV_File    LIKE CSV_File OPTIONAL
        Parsing     LIKE Parsing OPTIONAL
        customer    LIKE customer OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCX_CS1_CUSTOMER_FAILED IMPLEMENTATION.


  METHOD new_message.
    " 1. Instanz erstellen (Konstruktor nutzt meist nur textid und previous)
    ro_obj = NEW zcx_cs1_customer_failed(
      textid   = i_textid ).

    " 2. Schweregrad dem Interface-Attribut zuweisen
    ro_obj->if_abap_behv_message~m_severity = i_severity.

    " 3. Variablen für den T100-Text zuweisen
    ro_obj->if_t100_dyn_msg~msgv1 = |{ i_v1 }|.
    ro_obj->if_t100_dyn_msg~msgv2 = |{ i_v2 }|.
    ro_obj->if_t100_dyn_msg~msgv3 = |{ i_v3 }|.
    ro_obj->if_t100_dyn_msg~msgv4 = |{ i_v4 }|.

  ENDMETHOD.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
    me->filename = filename.
    me->Medium = Medium.
    me->MediumData = MediumData.
    me->CSV_File = CSV_File.
    me->header = header.
    me->customer = customer.
    me->column_name = column_name.
    me->Parsing = Parsing.


  ENDMETHOD.
ENDCLASS.
