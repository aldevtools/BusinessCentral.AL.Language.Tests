// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordid/recordid-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects table 72030, codeunit 72031
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Builtins refused until a probe pins them: RecordId.GetRecord() - Probe wanted: A RecordId of an existing and of a deleted row
// Facts: what RecordId.GetRecord answers for an existing row, a deleted row, a never inserted key, and whether it sets filters on the result
// BC versions: 29 (27 and 28 by CI)

table 72030 "LT PnD Rid Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72031 "LT PnD RecordId GetRecord"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(V: Variant): Text
    var
        RecRef: RecordRef;
    begin
        if V.IsRecord then
            exit('record');
        if V.IsRecordRef then begin
            RecRef := V;
            exit('recordref table ' + Format(RecRef.Number()) + ' filters=' + RecRef.GetFilters() + ' count=' + Format(RecRef.Count()));
        end;
        exit('other');
    end;

    [Test]
    procedure GetRecord_ExistingRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rid Row";
        RecRef: RecordRef;
        RecId: RecordId;
        V: Variant;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        RecId := Row.RecordId;
        V := RecId.GetRecord();
        Observer.Observe('kind', Describe(V));
        RecRef.GetTable(V);
        Observer.Observe('table', Format(RecRef.Number()));
        Observer.Observe('hasFilter', Format(RecRef.HasFilter()));
        Observer.Observe('filters', RecRef.GetFilters());
        Observer.Observe('idField', Format(RecRef.Field(1).Value()));
        Observer.Observe('nameField', Format(RecRef.Field(2).Value()));
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Expect('kind', 'recordref table 72030 filters= count=1');
        Observer.Expect('table', '72030');
        Observer.Expect('hasFilter', 'No');
        Observer.Expect('filters', '');
        Observer.Expect('idField', '1');
        Observer.Expect('nameField', '');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure GetRecord_RowChangedAfterTakingTheId()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rid Row";
        RecRef: RecordRef;
        RecId: RecordId;
        V: Variant;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'before';
        Row.Insert();
        RecId := Row.RecordId;
        Row.Name := 'after';
        Row.Modify();
        V := RecId.GetRecord();
        RecRef.GetTable(V);
        Observer.Observe('nameField', Format(RecRef.Field(2).Value()));
        Observer.Expect('nameField', '');
        Observer.Verify();
    end;

    [Test]
    procedure GetRecord_DeletedRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rid Row";
        RecRef: RecordRef;
        RecId: RecordId;
        V: Variant;
    begin
        Row.DeleteAll();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        RecId := Row.RecordId;
        Row.Delete();
        V := RecId.GetRecord();
        Observer.Observe('deleted', 'no error');
        V := RecId.GetRecord();
        Observer.Observe('kindAfter', Describe(V));
        Observer.Expect('deleted', 'no error');
        Observer.Expect('kindAfter', 'recordref table 72030 filters= count=0');
        Observer.Verify();
    end;

    [Test]
    procedure GetRecord_NeverInsertedKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rid Row";
        RecRef: RecordRef;
        RecId: RecordId;
        V: Variant;
    begin
        Row.DeleteAll();
        Row.Id := 77;
        RecId := Row.RecordId;
        V := RecId.GetRecord();
        Observer.Observe('neverInserted', 'no error');
        V := RecId.GetRecord();
        Observer.Observe('kindAfter', Describe(V));
        Observer.Expect('neverInserted', 'no error');
        Observer.Expect('kindAfter', 'recordref table 72030 filters= count=0');
        Observer.Verify();
    end;

    [Test]
    procedure GetRecord_UndefinedRecordId()
    var
        Observer: Codeunit "Probe Observer";
        RecId: RecordId;
        V: Variant;
    begin
        asserterror V := RecId.GetRecord();
        Observer.ObserveError('emptyRecordId');
        Observer.Observe('tableNo', Format(RecId.TableNo()));
        Observer.Expect('emptyRecordId|text', 'The record is not open.');
        Observer.Expect('emptyRecordId|code', 'RecordNotOpened');
        Observer.Expect('tableNo', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GetRecord_DoesNotChangeTheSourceRecordFilters()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Rid Row";
        Other: Record "LT PnD Rid Row";
        RecRef: RecordRef;
        RecId: RecordId;
        V: Variant;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Other.SetRange(Id, 2);
        RecId := Row.RecordId;
        Observer.Observe('rowId', Format(Row.Id));
        V := RecId.GetRecord();
        RecRef.GetTable(V);
        Observer.Observe('resultId', Format(RecRef.Field(1).Value()));
        Observer.Observe('otherFilters', Other.GetFilters());
        Observer.Observe('rowFilters', Row.GetFilters());
        Observer.Expect('rowId', '2');
        Observer.Expect('resultId', '2');
        Observer.Expect('otherFilters', 'Id: 2');
        Observer.Expect('rowFilters', '');
        Observer.Verify();
    end;
}
