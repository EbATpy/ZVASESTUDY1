@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZCS1_SERVICE1'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CS1_SERVICE1
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_CS1_SERVICE1
  association [1..1] to ZR_CS1_SERVICE1 as _BaseEntity on $projection.ID = _BaseEntity.ID
{
  key ID,
  Active,
  UserValue,
  DefaultValue,
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
