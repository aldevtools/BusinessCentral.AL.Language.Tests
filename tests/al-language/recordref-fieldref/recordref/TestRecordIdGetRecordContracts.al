// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordid/recordid-getrecord-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68961, codeunit 68962
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins RecordId.GetRecord(): it answers a RecordRef open on the RecordId's table with the primary key fields set and
// NOTHING else loaded (the Text field of an existing row reads blank; the row is not read); it answers the
// same for a row that does not exist (no error; Find() on it is false); every call gives a new RecordRef (a
// change through one is not seen by the next); the null RecordId raises "The record is not open." / RecordNotOpened.
// BC versions: 27.5

table 68961 "Probe GetRecord Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68962 "Probe RecordId GetRecord"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure GetRecord_ExistingRow_HasOnlyThePrimaryKey()
    var
        GrRec: Record "Probe GetRecord Table";
        Rid: RecordId;
        GrRef: RecordRef;
        Second: RecordRef;
    begin
        GrRec.DeleteAll();
        GrRec.Id := 1;
        GrRec.Txt := 'hello';
        GrRec.Insert();
        Rid := GrRec.RecordId;

        GrRef := Rid.GetRecord();

        Assert.AreEqual(Database::"Probe GetRecord Table", GrRef.Number(), 'Number');
        Assert.AreEqual('Probe GetRecord Table', GrRef.Name(), 'Name');
        Assert.IsFalse(GrRef.IsEmpty(), 'the table holds the row');
        Assert.AreEqual('1', Format(GrRef.Field(1).Value), 'primary key');
        Assert.AreEqual('', Format(GrRef.Field(2).Value), 'other fields are not loaded');

        Second := Rid.GetRecord();
        Second.Field(2).Value := 'changed';
        Assert.AreEqual('', Format(GrRef.Field(2).Value), 'independent of the first');
        Assert.AreEqual('', Format(Rid.GetRecord().Field(2).Value), 'and of the next call');
    end;

    [Test]
    procedure GetRecord_MissingRow_AndNullRecordId()
    var
        GrRec: Record "Probe GetRecord Table";
        Rid: RecordId;
        NullId: RecordId;
        GrRef: RecordRef;
    begin
        GrRec.DeleteAll();
        GrRec.Id := 1;
        GrRec.Insert();
        Rid := GrRec.RecordId;
        GrRec.Delete();

        GrRef := Rid.GetRecord();
        Assert.AreEqual('1', Format(GrRef.Field(1).Value), 'primary key of the missing row');
        Assert.IsFalse(GrRef.Find(), 'Find');
        Assert.AreEqual(Database::"Probe GetRecord Table", Rid.TableNo(), 'TableNo');

        asserterror GrRef := NullId.GetRecord();
        Assert.AreEqual('The record is not open.', GetLastErrorText(), 'text');
        Assert.AreEqual('RecordNotOpened', GetLastErrorCode(), 'code');
    end;

    // Corpus issue 668 item 47 (writer br): the SystemId field of the RecordRef that RecordId.GetRecord() answers, before and after
    // RecordRef.LoadFields(SystemIdNo), after SetRecFilter + FindFirst, and from RecordRef.Get(RecordId).
    local procedure BrSystemIdState(var RR: RecordRef; Expected: Guid): Text
    var
        G: Guid;
    begin
        G := RR.Field(RR.SystemIdNo()).Value;
        exit('null=' + Format(IsNullGuid(G)) + ' same=' + Format(G = Expected));
    end;

    [TryFunction]
    local procedure BrTryLoadSystemId(var RR: RecordRef)
    begin
        RR.LoadFields(RR.SystemIdNo());
    end;

    [Test]
    procedure GetRecord_SystemIdField_BeforeAndAfterLoading()
    var
        Observer: Codeunit "Probe Observer";
        GrRec: Record "Probe GetRecord Table";
        Rid: RecordId;
        GrRef: RecordRef;
        Fetched: RecordRef;
        Expected: Guid;
    begin
        GrRec.DeleteAll();
        GrRec.Id := 1;
        GrRec.Txt := 'hello';
        GrRec.Insert();
        Rid := GrRec.RecordId;
        Expected := GrRec.SystemId;

        GrRef := Rid.GetRecord();
        Observer.Observe('getrecord', BrSystemIdState(GrRef, Expected));
        ClearLastError();
        if BrTryLoadSystemId(GrRef) then
            Observer.Observe('loadfields', 'ok|' + BrSystemIdState(GrRef, Expected) + '|txt=' + Format(GrRef.Field(2).Value))
        else
            Observer.Observe('loadfields', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());

        GrRef := Rid.GetRecord();
        GrRef.SetRecFilter();
        Observer.Observe('setrecfilter findfirst', Format(GrRef.FindFirst()) + '|' + BrSystemIdState(GrRef, Expected) + '|txt=' + Format(GrRef.Field(2).Value));

        Fetched.Open(Database::"Probe GetRecord Table");
        Observer.Observe('recordref get', Format(Fetched.Get(Rid)) + '|' + BrSystemIdState(Fetched, Expected));
        Observer.Expect('getrecord', 'null=Yes same=No');
        Observer.Expect('loadfields', 'ok|null=Yes same=No|txt=');
        Observer.Expect('setrecfilter findfirst', 'Yes|null=No same=Yes|txt=hello');
        Observer.Expect('recordref get', 'Yes|null=No same=Yes');
        Observer.Verify();
    end;
}
