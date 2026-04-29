@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZCS1_CUSTOMERS'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_CS1_CUSTOMERS
  as select from zcs1_customers as CUSTOMERS
  
{
  key customerid as Customerid,
  salutation as Salutation,
  last_name as LastName,
  first_name as FirstName,
  company as Company,
  street as Street,
  city as City,
  
  @Consumption: {
    valueHelpDefinition: [ {
      entity.name: 'I_Country',
      entity.element: 'Country',       
      useForValidation: true
    } ]
  }
  country as Country,
  
  @Consumption.valueHelpDefinition: [{
    entity: {
        name: 'ZCS1_I_ZIPCITY', // Die Wertehilfe-Entität
        element: 'Postcode'    // Das Hauptfeld in der Wertehilfe
    },
    // Hier können mehrere Elemente gemappt werden
    additionalBinding: [
//        { localElement: 'Postcode', element: 'Postcode', usage: #FILTER_AND_RESULT },
        { localElement: 'City', element: 'City', usage: #RESULT }
//        { localElement: 'Country', element: 'Country', usage: #RESULT } // falls wir Country auch füllen wollen
    ]
}]
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
    entity.element: 'CurrencyTarget', 
    useForValidation: true
  } ]
  currency_target as CurrencyTarget,
  language as Language,
  weblogin as Weblogin,
  webpw as Webpw,
  memo as Memo,
  
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
