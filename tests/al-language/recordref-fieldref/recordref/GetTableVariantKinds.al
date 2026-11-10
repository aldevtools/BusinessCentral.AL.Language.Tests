// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-gettable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), ALT Universal (60000); self-contained codeunit 97435
// Probe: from al-runner issue 7586 item 2 (RecordRef.GetTable of an unassigned Variant, met in Microsoft's test apps).
// Area: RecordRef.GetTable(Variant) by what the Variant holds:
//   - nothing (never assigned), nothing after Clear, the copy of an unassigned Variant, an unassigned Variant received as a parameter;
//   - a value that is not a record: Integer, Text, Boolean, Guid, Date, RecordId of an existing row;
//   - a Record (the control case).
//   For the unassigned Variant the call is written three ways, one test each: as a plain statement, under asserterror, and in a
//   TryFunction. Only one of the first two can end in Finish(): the other one fails with what BC did, and that failure is the reading.
//   Also read: what a RecordRef that was open on a table holds after a GetTable that failed, and Record := Variant for an unassigned
//   Variant.
// Already pinned elsewhere, not repeated: GetTable of a Variant that holds a Record (TestRecordRefVariantGetTable.al) or a RecordRef
//   (AsRecRefGetTable.al), the temporary flag and the company (TestRecordVariantIsTemporary.al, CwVariantChangeCompany.al).
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

codeunit 97435 "RRF GetTable Variant Kinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "ALT Universal";
    begin
        Row.DeleteAll();
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryGetTable(var RecRef: RecordRef; V: Variant)
    begin
        RecRef.GetTable(V);
    end;

    [TryFunction]
    local procedure TryNumber(var RecRef: RecordRef; var Number: Integer)
    begin
        Number := RecRef.Number();
    end;

    [TryFunction]
    local procedure TryRecordFromVariant(var Row: Record "ALT Universal"; V: Variant)
    begin
        Row := V;
    end;

    local procedure State(var RecRef: RecordRef): Text
    var
        Number: Integer;
    begin
        if TryNumber(RecRef, Number) then
            exit('number=' + Format(Number));
        exit('number raises ' + GetLastErrorCode() + ':' + GetLastErrorText());
    end;

    local procedure Outcome(V: Variant): Text
    var
        RecRef: RecordRef;
        Result: Text;
    begin
        ClearLastError();
        if TryGetTable(RecRef, V) then
            Result := 'ok'
        else
            Result := 'error:' + GetLastErrorCode() + '|' + GetLastErrorText();
        exit(Result + '|' + State(RecRef));
    end;

    local procedure OutcomeOfParameter(V: Variant): Text
    begin
        exit(Outcome(V));
    end;

    [Test]
    procedure GetTable_UnassignedVariant_Statement()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        V: Variant;
    begin
        Initialize();
        RecRef.GetTable(V);
        Observer.Observe('after statement', State(RecRef));
        Observer.Finish();
    end;

    [Test]
    procedure GetTable_UnassignedVariant_AssertError()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        V: Variant;
    begin
        Initialize();
        asserterror RecRef.GetTable(V);
        Observer.ObserveError('gettable');
        Observer.Observe('after asserterror', State(RecRef));
        Observer.Expect('gettable|text', 'Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('gettable|code', 'NotInitialized');
        Observer.Expect('after asserterror', 'number=0');
        Observer.Verify();
    end;

    [Test]
    procedure GetTable_UnassignedVariant_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Copy: Variant;
        Cleared: Variant;
    begin
        Initialize();
        Observer.Observe('never assigned', Outcome(V));
        Copy := V;
        Observer.Observe('copy of unassigned', Outcome(Copy));
        Cleared := 5;
        Clear(Cleared);
        Observer.Observe('cleared', Outcome(Cleared));
        Observer.Observe('as parameter', OutcomeOfParameter(V));
        Observer.Expect('never assigned', 'error:NotInitialized|Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.|number=0');
        Observer.Expect('copy of unassigned', 'error:NotInitialized|Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.|number=0');
        Observer.Expect('cleared', 'error:NotInitialized|Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.|number=0');
        Observer.Expect('as parameter', 'error:NotInitialized|Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.|number=0');
        Observer.Verify();
    end;

    [Test]
    procedure GetTable_VariantWithAValue_TryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        V: Variant;
        G: Guid;
    begin
        Initialize();
        Row."Entry No." := 1;
        Row.Insert();
        V := 5;
        Observer.Observe('integer', Outcome(V));
        V := 'ALT Universal';
        Observer.Observe('text', Outcome(V));
        V := true;
        Observer.Observe('boolean', Outcome(V));
        V := G;
        Observer.Observe('guid', Outcome(V));
        V := DMY2Date(1, 2, 2020);
        Observer.Observe('date', Outcome(V));
        V := Row.RecordId();
        Observer.Observe('recordid', Outcome(V));
        V := Row;
        Observer.Observe('record', Outcome(V));
        Observer.Expect('integer', 'error:Conversion|Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavInteger to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.|number=0');
        Observer.Expect('text', 'error:Conversion|Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.|number=0');
        Observer.Expect('boolean', 'error:Conversion|Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavBoolean to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.|number=0');
        Observer.Expect('guid', 'error:Conversion|Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavGuid to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.|number=0');
        Observer.Expect('date', 'error:Conversion|Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavDate to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.|number=0');
        Observer.Expect('recordid', 'error:Conversion|Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordId to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.|number=0');
        Observer.Expect('record', 'ok|number=60000');
        Observer.Verify();
    end;

    [Test]
    procedure GetTable_UnassignedVariant_OnAnOpenRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        V: Variant;
    begin
        Initialize();
        RecRef.Open(Database::"ALT Universal");
        Observer.Observe('before', State(RecRef));
        ClearLastError();
        if TryGetTable(RecRef, V) then
            Observer.Observe('gettable', 'ok')
        else
            Observer.Observe('gettable', 'error:' + GetLastErrorCode() + '|' + GetLastErrorText());
        Observer.Observe('after', State(RecRef));
        Observer.Expect('before', 'number=60000');
        Observer.Expect('gettable', 'error:NotInitialized|Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('after', 'number=60000');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_UnassignedVariant()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ALT Universal";
        V: Variant;
    begin
        Initialize();
        Row."Entry No." := 7;
        ClearLastError();
        if TryRecordFromVariant(Row, V) then
            Observer.Observe('assign', 'ok')
        else
            Observer.Observe('assign', 'error:' + GetLastErrorCode() + '|' + GetLastErrorText());
        Observer.Observe('entry no after', Format(Row."Entry No."));
        Observer.Expect('assign', 'error:NotInitialized|Microsoft.Dynamics.Nav.Runtime.NavVariant variable not initialized.');
        Observer.Expect('entry no after', '7');
        Observer.Verify();
    end;
}
