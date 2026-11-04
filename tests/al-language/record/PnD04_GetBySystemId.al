// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getbysystemid-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects table 72034, codeunit 72035
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles docs/probes-needed.md row: Builtins refused until a probe pins them: Record.GetBySystemId(Guid) with the result unused, RecordRef.GetBySystemId - Open: the same miss on a Record, a never-opened RecordRef with the result unused
// Facts: GetBySystemId on a Record miss with the result unused, on a Record hit, on a null guid, and on a never-opened RecordRef with the result unused; the text between the braces is observed as Format(Guid) pieces
// BC versions: 29 (27 and 28 by CI)

table 72034 "LT PnD Sys Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72035 "LT PnD GetBySystemId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure MissingGuid(): Guid
    var
        G: Guid;
    begin
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        exit(G);
    end;

    [Test]
    procedure Record_Miss_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Sys Row";
    begin
        Row.DeleteAll();
        asserterror Row.GetBySystemId(MissingGuid());
        Observer.ObserveError('missUnused');
        Observer.Expect('missUnused|text', 'The LT PnD Sys Row does not exist. Identification fields and values: {x}');
        Observer.Expect('missUnused|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Record_Miss_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Sys Row";
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Insert();
        Observer.Observe('missUsed', Format(Row.GetBySystemId(MissingGuid())));
        Observer.Observe('bufferKept', Format(Row.Id));
        Observer.Expect('missUsed', 'No');
        Observer.Expect('bufferKept', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Record_Hit_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Sys Row";
        Other: Record "LT PnD Sys Row";
        Sid: Guid;
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Insert();
        Row.Id := 6;
        Row.Insert();
        Sid := Row.SystemId;
        Other.GetBySystemId(Sid);
        Observer.Observe('hitId', Format(Other.Id));
        Observer.Expect('hitId', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Record_Hit_IgnoresFilters()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Sys Row";
        Other: Record "LT PnD Sys Row";
        Sid: Guid;
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Insert();
        Sid := Row.SystemId;
        Other.SetRange(Id, 9);
        Observer.Observe('hit', Format(Other.GetBySystemId(Sid)));
        Observer.Observe('hitId', Format(Other.Id));
        Observer.Observe('filters', Other.GetFilters());
        Observer.Expect('hit', 'Yes');
        Observer.Expect('hitId', '5');
        Observer.Expect('filters', 'Id: 9');
        Observer.Verify();
    end;

    [Test]
    procedure Record_NullGuid()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnD Sys Row";
        NullGuid: Guid;
    begin
        Row.DeleteAll();
        Observer.Observe('nullUsed', Format(Row.GetBySystemId(NullGuid)));
        asserterror Row.GetBySystemId(NullGuid);
        Observer.ObserveError('nullUnused');
        Observer.Expect('nullUsed', 'No');
        Observer.Expect('nullUnused|text', 'The LT PnD Sys Row does not exist. Identification fields and values: {x}');
        Observer.Expect('nullUnused|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_Miss_ResultUnused_OpenedRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LT PnD Sys Row");
        RecRef.DeleteAll();
        asserterror RecRef.GetBySystemId(MissingGuid());
        Observer.ObserveError('missUnused');
        Observer.Observe('missUsed', Format(RecRef.GetBySystemId(MissingGuid())));
        Observer.Expect('missUnused|text', 'The LT PnD Sys Row does not exist. Identification fields and values: {x}');
        Observer.Expect('missUnused|code', 'DB:RecordNotFound');
        Observer.Expect('missUsed', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RecordRef_NeverOpened()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Observer.Observe('neverOpenedUsed', Format(RecRef.GetBySystemId(MissingGuid())));
        asserterror RecRef.GetBySystemId(MissingGuid());
        Observer.ObserveError('neverOpenedUnused');
        Observer.Expect('neverOpenedUsed', 'No');
        Observer.Expect('neverOpenedUnused|text', 'The record is not open.');
        Observer.Expect('neverOpenedUnused|code', 'RecordNotOpened');
        Observer.Verify();
    end;
}
