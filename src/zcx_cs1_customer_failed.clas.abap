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

    DATA filename TYPE String READ-ONLY.


    DATA Email TYPE string READ-ONLY.
    DATA TelFax TYPE string READ-ONLY.
    DATA Tele TYPE string READ-ONLY.
    DATA CSV_File TYPE string READ-ONLY.
    DATA header TYPE string READ-ONLY.
    DATA customer TYPE string READ-ONLY.
    DATA company TYPE string READ-ONLY.
    DATA Pasing TYPE string READ-ONLY.

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

      BEGIN OF RegularExpression_Email,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '010',
        attr1 TYPE scx_attrname VALUE 'Email',
        attr2 TYPE scx_attrname VALUE 'column_name',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF RegularExpression_Email,

      BEGIN OF RegularExpression_TelFax,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '020',
        attr1 TYPE scx_attrname VALUE 'TelFax',
        attr2 TYPE scx_attrname VALUE 'column_name',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF RegularExpression_TelFax,

      BEGIN OF CSV_File_Import,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '030',
        attr1 TYPE scx_attrname VALUE ' CSV_File',
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
      END OF RegularExpression_Tele,

      BEGIN OF RegularExpression_Pasing,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '080',
        attr1 TYPE scx_attrname VALUE 'Pasing',
        attr2 TYPE scx_attrname VALUE 'column_name',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF RegularExpression_Pasing.

    " Statische Fabrikmethode hinzufügen

    CLASS-METHODS new_message
  IMPORTING
    i_textid   LIKE if_t100_message=>t100key
    i_severity TYPE if_abap_behv_message=>t_severity DEFAULT if_abap_behv_message=>severity-error
    i_v1       TYPE simple OPTIONAL
    i_v2       TYPE simple OPTIONAL
    i_v3       TYPE simple OPTIONAL
    i_v4       TYPE simple OPTIONAL
  RETURNING
    VALUE(ro_obj) TYPE REF TO zcx_cs1_customer_failed.



    METHODS constructor
      IMPORTING
        textid      LIKE if_t100_message=>t100key OPTIONAL
        previous    LIKE previous OPTIONAL
        column_name LIKE column_name OPTIONAL
        filename    LIKE filename OPTIONAL
        Email       LIKE Email OPTIONAL
        TelFax      LIKE TelFax OPTIONAL
        Tele        LIKE Tele OPTIONAL
        CSV_File    LIKE CSV_File OPTIONAL
        Pasing      LIKE Pasing OPTIONAL
        customer    LIKE customer OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcx_cs1_customer_failed IMPLEMENTATION.

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
    me->Email = Email.
    me->TelFax = TelFax.
    me->Tele = Tele.
    me->CSV_File = CSV_File.
    me->header = header.
    me->customer = customer.
    me->column_name = column_name.
    me->Pasing = Pasing.


  ENDMETHOD.
ENDCLASS.
