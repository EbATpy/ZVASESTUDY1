CLASS zcx_cs1_customer_failed DEFINITION

    "zcx_csv_import
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.
 DATA filename TYPE String READ-ONLY.


    DATA Email TYPE string READ-ONLY.
    DATA TelFax TYPE string READ-ONLY.
    DATA Tele TYPE string READ-ONLY.
    DATA CSV_File TYPE string READ-ONLY.
    DATA header TYPE string READ-ONLY.
    DATA customer TYPE string READ-ONLY.
    DATA company TYPE string READ-ONLY.

    DATA line_number TYPE i READ-ONLY.
    DATA column_name TYPE string READ-ONLY.

    CONSTANTS:
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

      begin of company_to_long,
        msgid type symsgid value 'Z01_MESSAGES',
        msgno type symsgno value '060',
        attr1 type scx_attrname value 'column_name',
        attr2 type scx_attrname value 'filename',
        attr3 type scx_attrname value 'attr3',
        attr4 type scx_attrname value 'attr4',
      end of company_to_long,

       BEGIN OF RegularExpression_Tele,
        msgid TYPE symsgid VALUE 'Z01_MESSAGES',
        msgno TYPE symsgno VALUE '070',
        attr1 TYPE scx_attrname VALUE 'Tele',
        attr2 TYPE scx_attrname VALUE 'column_name',
        attr3 TYPE scx_attrname VALUE 'attr3',
        attr4 TYPE scx_attrname VALUE 'attr4',
      END OF RegularExpression_Tele.



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
        header      LIKE header OPTIONAL
       customer    LIKE customer OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcx_cs1_customer_failed IMPLEMENTATION.
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


  ENDMETHOD.
ENDCLASS.
