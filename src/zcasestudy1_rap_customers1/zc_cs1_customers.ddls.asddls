@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZCS1_CUSTOMERS'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_CUSTOMERS
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_CS1_CUSTOMERS
  association [1..1] to ZR_CS1_CUSTOMERS as _BaseEntity on $projection.CUSTOMERID = _BaseEntity.CUSTOMERID
{
  key Customerid,
  Salutation,
  LastName,
  FirstName,
  Company,
  Street,
  City,
  Country,
  Postcode,
  AccLock,
  LastDate,
  @Semantics: {
    Amount.Currencycode: 'Currency'
  }
  SalesVolume,
  @Semantics: {
    Amount.Currencycode: 'CurrencyTarget'
  }
  SalesVolumeTarget,
  ChangeRateDate,
  Fax,
  Phone,
  Email,
  Url,
  @Consumption: {
    Valuehelpdefinition: [ {
      Entity.Element: 'Currency', 
      Entity.Name: 'I_CurrencyStdVH', 
      Useforvalidation: true
    } ]
  }
  Currency,
  @Consumption: {
    Valuehelpdefinition: [ {
      Entity.Element: 'Currency', 
      Entity.Name: 'I_CurrencyStdVH', 
      Useforvalidation: true
    } ]
  }
  CurrencyTarget,
  Language,
  Weblogin,
  Webpw,
  Memo,
  @Semantics: {
    User.Createdby: true
  }
  CreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  CreatedAt,
  @Semantics: {
    User.Localinstancelastchangedby: true
  }
  LocalLastChangedBy,
  @Semantics: {
    Systemdatetime.Localinstancelastchangedat: true
  }
  LocalLastChangedAt,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  _BaseEntity
}
