@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZCS1_CUSTOMERS'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_CS1_CUSTOMERS
  as select from zcs1_customers as CUSTOMERS
    association [0..*] to zcs1_custorders as _Orders on $projection.Customerid = _Orders.customerid  
{
  key customerid as Customerid,
  salutation as Salutation,
  last_name as LastName,
  first_name as FirstName,
  company as Company,
  street as Street,
  city as City,
  country as Country,
  postcode as Postcode,
  acc_lock as AccLock,
  last_date as LastDate,
  @Semantics.amount.currencyCode: 'Currency'
  sales_volume as SalesVolume,
  @Semantics.amount.currencyCode: 'CurrencyTarget'
  sales_volume_target as SalesVolumeTarget,
  change_rate_date as ChangeRateDate,
  fax as Fax,
  phone as Phone,
  email as Email,
  url as Url,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_CurrencyStdVH', 
    entity.element: 'Currency', 
    useForValidation: true
  } ]
  currency as Currency,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_CurrencyStdVH', 
    entity.element: 'Currency', 
    useForValidation: true
  } ]
  currency_target as CurrencyTarget,
  language as Language,
  weblogin as Weblogin,
  webpw as Webpw,
  memo as Memo,
  _Orders.orderid as OrderID,
  _Orders,
  
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt
}
