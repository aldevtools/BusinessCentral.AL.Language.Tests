// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects table 72055, codeunit 72056
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: All buckets with test data (issue 10): A field declared ObsoleteState = Removed in RecordRef - Probe wanted: A table with a removed field: FieldCount, FieldExist, Field(n) and FieldIndex loops, and the error text
// Facts: RecordRef over a table with a field with ObsoleteState = Removed (and one Pending for comparison): FieldCount, FieldExist, Field(n), FieldIndex over all indexes, field names and numbers, error text and code; Record-level behaviour of a row in that table
// BC versions: 29 (27 and 28 by CI)

table 72055 "LT PnD Removed Field"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; OldField; Integer)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Probe: removed field';
            ObsoleteTag = '1.0';
        }
        field(4; PendingField; Integer)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Probe: pending field';
            ObsoleteTag = '1.0';
        }
        field(5; LastField; Text[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72056 "LT PnD Removed Field Ref"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryField(var RecRef: RecordRef; No: Integer; var Res: Text)
    var
        FldRef: FieldRef;
    begin
        FldRef := RecRef.Field(No);
        Res := FldRef.Name() + '/' + Format(FldRef.Number()) + '/' + Format(FldRef.Type());
    end;

    [TryFunction]
    local procedure TryFieldIndex(var RecRef: RecordRef; Idx: Integer; var Res: Text)
    var
        FldRef: FieldRef;
    begin
        FldRef := RecRef.FieldIndex(Idx);
        Res := FldRef.Name() + '/' + Format(FldRef.Number());
    end;

    local procedure FieldText(var RecRef: RecordRef; No: Integer): Text
    var
        Res: Text;
    begin
        if TryField(RecRef, No, Res) then
            exit(Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure IndexText(var RecRef: RecordRef; Idx: Integer): Text
    var
        Res: Text;
    begin
        if TryFieldIndex(RecRef, Idx, Res) then
            exit(Res);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Counts_AndExistence()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(Database::"LT PnD Removed Field");
        Observer.Observe('fieldCount', Format(RecRef.FieldCount()));
        for i := 1 to 6 do
            Observer.Observe('exist' + Format(i), Format(RecRef.FieldExist(i)));
        Observer.Expect('fieldCount', '4');
        Observer.Expect('exist1', 'Yes');
        Observer.Expect('exist2', 'Yes');
        Observer.Expect('exist3', 'No');
        Observer.Expect('exist4', 'Yes');
        Observer.Expect('exist5', 'Yes');
        Observer.Expect('exist6', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FieldByNumber()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(Database::"LT PnD Removed Field");
        for i := 1 to 6 do
            Observer.Observe('field' + Format(i), FieldText(RecRef, i));
        Observer.Expect('field1', 'Id/1/Integer');
        Observer.Expect('field2', 'Name/2/Text');
        Observer.Expect('field3', 'error:Field OldField (3) of table LT PnD Removed Field (72055) is obsoleted, reason: Probe: removed field|MetadataObsolete');
        Observer.Expect('field4', 'PendingField/4/Integer');
        Observer.Expect('field5', 'LastField/5/Text');
        Observer.Expect('field6', 'error:The supplied field number ''6'' cannot be found in the ''LT PnD Removed Field'' table.|FieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure FieldByIndex()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.Open(Database::"LT PnD Removed Field");
        for i := 0 to 6 do
            Observer.Observe('index' + Format(i), IndexText(RecRef, i));
        Observer.Expect('index0', 'timestamp/0');
        Observer.Expect('index1', 'Id/1');
        Observer.Expect('index2', 'Name/2');
        Observer.Expect('index3', 'PendingField/4');
        Observer.Expect('index4', 'LastField/5');
        Observer.Expect('index5', '$systemId/2000000000');
        Observer.Expect('index6', 'SystemCreatedAt/2000000001');
        Observer.Verify();
    end;

    [Test]
    procedure Row_ReadThroughRecordAndRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Removed Field";
        RecRef: RecordRef;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'abc';
        Row.LastField := 'last';
        Row.Insert();
        RecRef.GetTable(Row);
        Observer.Observe('name', FieldText(RecRef, 2));
        Observer.Observe('nameValue', Format(RecRef.Field(2).Value()));
        Observer.Observe('lastValue', Format(RecRef.Field(5).Value()));
        Observer.Observe('pendingValue', Format(RecRef.Field(4).Value()));
        Observer.Observe('removedField', FieldText(RecRef, 3));
        Observer.Expect('name', 'Name/2/Text');
        Observer.Expect('nameValue', 'abc');
        Observer.Expect('lastValue', 'last');
        Observer.Expect('pendingValue', '0');
        Observer.Expect('removedField', 'error:Field OldField (3) of table LT PnD Removed Field (72055) is obsoleted, reason: Probe: removed field|MetadataObsolete');
        Observer.Verify();
    end;
}
