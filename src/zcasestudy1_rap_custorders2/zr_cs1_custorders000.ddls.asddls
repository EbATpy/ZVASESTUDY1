@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZCS1_CUSTORDERS000'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_CS1_CUSTORDERS000
  as select from zcs1_custorders as CUSTORDERS
{
  key orderid as Orderid,
  @Consumption.valueHelpDefinition: [
        { entity: { name: 'zcs1Customers_H', element: 'Customerid' } }]
  @EndUserText.label: 'KdNr:'
  cast( customerid as zcustomerid1 ) as Customerid, 
  order_date as OrderDate,
  @Semantics.amount.currencyCode: 'Currency'
  order_total as OrderTotal,
  discount as Discount,
  info as Info,
 @Consumption: {
    valueHelpDefinition: [ {
      entity.element: 'Status', 
      entity.name: 'zcs1_StatusVH', 
      useForValidation: true
    } ]
  }      
  status as Status,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_CurrencyStdVH', 
    entity.element: 'Currency', 
    useForValidation: true
  } ]
  currency as Currency,
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
