@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZCS1_CUSTORDERS'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_CUSTORDERS
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_CS1_CUSTORDERS
  association [1..1] to ZR_CS1_CUSTORDERS as _BaseEntity on $projection.ORDERID = _BaseEntity.ORDERID
{
  key Orderid,
  Customerid,
  OrderDate,
  @Semantics: {
    Amount.Currencycode: 'Currency'
  }
  OrderTotal,
  Discount,
  Info,
  Status,
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
  @Semantics: {
    Amount.Currencycode: 'CurrencyTarget'
  }
  OrderTotalTarget,
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
