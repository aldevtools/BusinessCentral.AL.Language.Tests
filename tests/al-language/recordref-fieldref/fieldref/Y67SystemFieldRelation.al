// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-relation-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 93634, codeunit 93633 (writer Y67, gap cycle 6 follow-up)
// Probe: the relation of the system fields (SystemId 2000000000, SystemCreatedAt, SystemCreatedBy, SystemModifiedAt, SystemModifiedBy) as AL sees
//   it: FieldRef.Relation of each system field of an own table and of Customer (a Base Application table), the Field virtual table row of each
//   (Type, Class, RelationTableNo, RelationFieldNo, Enabled, IsPartOfPrimaryKey), FieldRef.Relation of an own Guid field whose TableRelation names
//   the SystemId of another table and of a field that relates to the table's own SystemId, and Field.Get for the system field numbers.
// BC versions: 27, 28, 29

table 93634 "LT Y67 SF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Ref; Guid) { TableRelation = "LT Y67 SF Row".SystemId; }
        field(3; CustRef; Guid) { TableRelation = Customer.SystemId; }
        field(4; Plain; Guid) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93633 "LT Y67 SF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RefFacts(TableId: Integer; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FRef: FieldRef;
    begin
        RecRef.Open(TableId);
        FRef := RecRef.Field(FieldNo);
        exit(FRef.Name + ': rel=' + Format(FRef.Relation) + ' type=' + Format(FRef.Type) + ' class=' + Format(FRef.Class) + ' enabled=' + Format(FRef.Active) + ' len=' + Format(FRef.Length));
    end;

    local procedure FieldFacts(TableId: Integer; FieldNo: Integer): Text
    var
        Fld: Record Field;
    begin
        if not Fld.Get(TableId, FieldNo) then
            exit('no Field row');
        exit(Fld.FieldName + ': type=' + Format(Fld.Type) + ' class=' + Format(Fld.Class) + ' relTable=' + Format(Fld.RelationTableNo) + ' relField=' + Format(Fld.RelationFieldNo) + ' enabled=' + Format(Fld.Enabled) + ' pk=' + Format(Fld.IsPartOfPrimaryKey) + ' len=' + Format(Fld.Len));
    end;

    [TryFunction]
    local procedure TryRef(TableId: Integer; FieldNo: Integer; var Result: Text)
    begin
        Result := RefFacts(TableId, FieldNo);
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; TableId: Integer; FieldNo: Integer)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryRef(TableId, FieldNo, Result) then
            Observer.Observe(Name + ' ref', Result)
        else
            Observer.Observe(Name + ' ref', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe(Name + ' field', FieldFacts(TableId, FieldNo));
    end;

    [Test]
    procedure SystemFields_OwnTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'own SystemId', Database::"LT Y67 SF Row", 2000000000);
        Show(Observer, 'own CreatedAt', Database::"LT Y67 SF Row", 2000000001);
        Show(Observer, 'own CreatedBy', Database::"LT Y67 SF Row", 2000000002);
        Observer.Expect('own SystemId ref', '$systemId: rel=0 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('own SystemId field', '$systemId: type=GUID class=Normal relTable=0 relField=0 enabled=Yes pk=No len=16');
        Observer.Expect('own CreatedAt ref', 'SystemCreatedAt: rel=0 type=DateTime class=Normal enabled=Yes len=8');
        Observer.Expect('own CreatedAt field', 'SystemCreatedAt: type=DateTime class=Normal relTable=0 relField=0 enabled=Yes pk=No len=8');
        Observer.Expect('own CreatedBy ref', 'SystemCreatedBy: rel=2000000120 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('own CreatedBy field', 'SystemCreatedBy: type=GUID class=Normal relTable=2000000120 relField=0 enabled=Yes pk=No len=16');
        Observer.Verify();
    end;

    [Test]
    procedure SystemFields_OwnTable_More()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'own ModifiedAt', Database::"LT Y67 SF Row", 2000000003);
        Show(Observer, 'own ModifiedBy', Database::"LT Y67 SF Row", 2000000004);
        Observer.Expect('own ModifiedAt ref', 'SystemModifiedAt: rel=0 type=DateTime class=Normal enabled=Yes len=8');
        Observer.Expect('own ModifiedAt field', 'SystemModifiedAt: type=DateTime class=Normal relTable=0 relField=0 enabled=Yes pk=No len=8');
        Observer.Expect('own ModifiedBy ref', 'SystemModifiedBy: rel=2000000120 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('own ModifiedBy field', 'SystemModifiedBy: type=GUID class=Normal relTable=2000000120 relField=0 enabled=Yes pk=No len=16');
        Observer.Verify();
    end;

    [Test]
    procedure SystemFields_Customer()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'cust SystemId', Database::Customer, 2000000000);
        Show(Observer, 'cust CreatedBy', Database::Customer, 2000000002);
        Show(Observer, 'cust ModifiedBy', Database::Customer, 2000000004);
        Observer.Expect('cust SystemId ref', '$systemId: rel=0 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('cust SystemId field', '$systemId: type=GUID class=Normal relTable=0 relField=0 enabled=Yes pk=No len=16');
        Observer.Expect('cust CreatedBy ref', 'SystemCreatedBy: rel=2000000120 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('cust CreatedBy field', 'SystemCreatedBy: type=GUID class=Normal relTable=2000000120 relField=0 enabled=Yes pk=No len=16');
        Observer.Expect('cust ModifiedBy ref', 'SystemModifiedBy: rel=2000000120 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('cust ModifiedBy field', 'SystemModifiedBy: type=GUID class=Normal relTable=2000000120 relField=0 enabled=Yes pk=No len=16');
        Observer.Verify();
    end;

    [Test]
    procedure RelationToSystemId_Fields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'Ref (own SystemId)', Database::"LT Y67 SF Row", 2);
        Show(Observer, 'CustRef (Customer.SystemId)', Database::"LT Y67 SF Row", 3);
        Show(Observer, 'Plain', Database::"LT Y67 SF Row", 4);
        Observer.Expect('Ref (own SystemId) ref', 'Ref: rel=93634 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('Ref (own SystemId) field', 'Ref: type=GUID class=Normal relTable=93634 relField=2000000000 enabled=Yes pk=No len=16');
        Observer.Expect('CustRef (Customer.SystemId) ref', 'CustRef: rel=18 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('CustRef (Customer.SystemId) field', 'CustRef: type=GUID class=Normal relTable=18 relField=2000000000 enabled=Yes pk=No len=16');
        Observer.Expect('Plain ref', 'Plain: rel=0 type=GUID class=Normal enabled=Yes len=16');
        Observer.Expect('Plain field', 'Plain: type=GUID class=Normal relTable=0 relField=0 enabled=Yes pk=No len=16');
        Observer.Verify();
    end;
}
