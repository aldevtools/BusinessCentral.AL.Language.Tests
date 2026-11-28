// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (AL Runner: the login under RequiredTestIsolation = Disabled, cells 7-10 after LgnDisabledLoginWrites.al): what a later
//   test codeunit sees of the login after a Disabled codeunit changed the login's rows, when the later codeunit runs under
//   "Test Runner - Isol. Codeunit" (130450) with and without handler functions, when it is a hub codeunit under Function
//   isolation, and which state the session's one login leaves in a SingleInstance memo.
// Harness (see codeunits/run-onrun/RqIsolationModes.al): on BC 28+ legs a codeunit without handlers and with TestPermissions =
//   Disabled runs through the TestRunnerHub with its RequiredTestIsolation, in ascending id order; every other codeunit runs
//   afterwards under 130450 through the websocket test runner. BC 27 legs run every codeunit under 130450; the observing tests
//   assert nothing there (#else branches).
// Fixture: this file's login subscriber (OnAfterLogin, OnRegisterAssistedSetup) writes one row per call into table 87414 in
//   every session except background and child sessions, counts the calls in a SingleInstance memo (87418) and keeps there the
//   row count of table 87416 at the newest login. Disabled codeunits take a committed snapshot (table 87415) in a first test
//   that never fails; later codeunits compare with it.
// Cells: 87420 A1 (Disabled, inserts one row into table 87416) -> 87421 Codeunit isolation (cell 10); 87422 Function isolation
//   after A1 (cell 9); 87424 A2 (Disabled, inserts an EXTRA row and deletes the session's LOGIN row) -> 87425 with a
//   MessageHandler (cell 7), 87426 TestPermissions = NonRestrictive (cell 8), 87427 no TestPermissions (Restrictive; cell 8).
// Measured on BC 28.5 (28.5.54976.59048) and 29.0 (29.0.54011.59052), local BC on Linux legs that mirror the CI legs (2026-11-28),
//   same values on both:
//   - Order: the 130450 codeunits (87425-87427) ran after the hub codeunits (A2's snapshot found: Yes).
//   - Cells 7 and 8 (all three 130450 shapes alike): the codeunit runs in ANOTHER session than the hub codeunits. That session
//     raised its own login: OnAfterLogin 1 call in it (one LOGIN row of that session, written after A2's snapshot), but
//     OnRegisterAssistedSetup 0 calls. It sees A2's changes to the login rows: the hub session's LOGIN row A2 deleted is gone (0
//     LOGIN rows of the hub session), the EXTRA row A2 inserted is there. Its login's memo counts the row A1 committed (memo minus
//     T rows before A1: 1).
//   - Cell 9 (hub, Function isolation after Disabled A1): same session, 0 login calls since A1's snapshot, the session's 1 LOGIN
//     row. A test that deletes that LOGIN row and inserts a row of its own: in the next test the LOGIN row is back and the
//     inserted row is gone (rolled back to the state at the test's start, which holds A1's committed row of table 87416).
//   - Cell 10 (hub, Codeunit isolation after Disabled A1): the memo still holds the count of the session's one login, taken
//     before A1 inserted its row (memo minus T rows before A1: 0), while the table now has A1's row (1). No login runs before the
//     codeunit.
//   - In A2 itself (Disabled), the next test sees its delete and insert (LOGIN rows of the session: 0, EXTRA row there).
// BC 27.5: not asserted. The local BC 27.5 leg runs these codeunits through the hub; the CI 27 legs run them under 130450 (needs CI).
// Object ids 87414-87427.
// BC versions: 27.5, 28.5, 29.0

// local object: one row per login event of a test session; the rows must outlive the test codeunit that wrote them
table 87414 "LGN HL Login Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Session Id"; Integer) { }
        field(3; Kind; Code[10]) { }
        field(4; "T Rows Seen"; Integer) { }
        field(5; "Call No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// local object: what one test codeunit leaves for a later one; it must be committed and read by a later codeunit
table 87415 "LGN HL Mark"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
        field(2; Value; Integer) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// local object: the table whose row count the login keeps in its memo; only the Disabled codeunit A1 writes it
table 87416 "LGN HL T Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// local object: the subscribers exist to be run by the login of a test session; when they run is the subject.
// They write in every session except background and child sessions (StartSession of other tests) and never fail.
codeunit 87417 "LGN HL Login Subs"
{
    local procedure Note(EventKind: Code[10])
    var
        Row: Record "LGN HL Login Row";
        TRow: Record "LGN HL T Row";
        Memo: Codeunit "LGN HL Login Memo";
    begin
        if CurrentClientType() in [ClientType::Background, ClientType::ChildSession] then
            exit;
        Row.Init();
        Row."Session Id" := SessionId();
        Row.Kind := EventKind;
        Row."T Rows Seen" := TRow.Count();
        Row."Call No." := Memo.Add(EventKind, Row."T Rows Seen");
        Row.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure AfterLogin()
    begin
        Note('LOGIN');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure RegisterAssistedSetup()
    begin
        Note('REGISTER');
    end;
}

// singleinstance-shared-on-purpose: the subject is the session state one login leaves for every test codeunit of the session;
// the memo is filled only by the login subscriber, never reset, and every test reads it relative to a committed mark.
codeunit 87418 "LGN HL Login Memo"
{
    SingleInstance = true;

    var
        LoginCalls: Integer;
        RegisterCalls: Integer;
        TRowsAtLogin: Integer;

    procedure Add(EventKind: Code[10]; TRows: Integer): Integer
    begin
        if EventKind = 'LOGIN' then begin
            LoginCalls += 1;
            TRowsAtLogin := TRows;
            exit(LoginCalls);
        end;
        RegisterCalls += 1;
        exit(RegisterCalls);
    end;

    procedure Calls(EventKind: Code[10]): Integer
    begin
        if EventKind = 'LOGIN' then
            exit(LoginCalls);
        exit(RegisterCalls);
    end;

    // T rows the newest login of this session counted; -1 when no login ran in this session.
    procedure TRows(): Integer
    begin
        if LoginCalls = 0 then
            exit(-1);
        exit(TRowsAtLogin);
    end;
}

// What the Function isolation codeunit's delete test saw; read by its next test (survives the rollback of the test).
codeunit 87423 "LGN HL Fn Log"
{
    SingleInstance = true;

    var
        RowsBefore: Integer;
        RowsAfter: Integer;
        DeletedEntry: Integer;
        NewEntryNo: Integer;

    procedure Set(Before: Integer; After: Integer; Deleted: Integer; Added: Integer)
    begin
        RowsBefore := Before;
        RowsAfter := After;
        DeletedEntry := Deleted;
        NewEntryNo := Added;
    end;

    procedure Before(): Integer
    begin
        exit(RowsBefore);
    end;

    procedure After(): Integer
    begin
        exit(RowsAfter);
    end;

    procedure Deleted(): Integer
    begin
        exit(DeletedEntry);
    end;

    procedure NewEntry(): Integer
    begin
        exit(NewEntryNo);
    end;
}

// The reads and writes every test codeunit of this file shares.
codeunit 87419 "LGN HL Probe"
{
    procedure LiveCalls(EventKind: Code[10]): Integer
    var
        Memo: Codeunit "LGN HL Login Memo";
    begin
        exit(Memo.Calls(EventKind));
    end;

    procedure MemoTRows(): Integer
    var
        Memo: Codeunit "LGN HL Login Memo";
    begin
        exit(Memo.TRows());
    end;

    procedure TRows(): Integer
    var
        TRow: Record "LGN HL T Row";
    begin
        exit(TRow.Count());
    end;

    procedure InsertT()
    var
        TRow: Record "LGN HL T Row";
    begin
        TRow.Init();
        TRow.Insert();
    end;

    procedure AllRows(): Integer
    var
        Row: Record "LGN HL Login Row";
    begin
        exit(Row.Count());
    end;

    procedure SessionRows(SessionNo: Integer; EventKind: Code[10]): Integer
    var
        Row: Record "LGN HL Login Row";
    begin
        Row.SetRange("Session Id", SessionNo);
        Row.SetRange(Kind, EventKind);
        exit(Row.Count());
    end;

    procedure SessionRowsAfter(SessionNo: Integer; EventKind: Code[10]; EntryNo: Integer): Integer
    var
        Row: Record "LGN HL Login Row";
    begin
        Row.SetFilter("Entry No.", '>%1', EntryNo);
        Row.SetRange("Session Id", SessionNo);
        Row.SetRange(Kind, EventKind);
        exit(Row.Count());
    end;

    procedure MaxEntry(): Integer
    var
        Row: Record "LGN HL Login Row";
    begin
        if Row.FindLast() then
            exit(Row."Entry No.");
        exit(0);
    end;

    procedure RowExists(EntryNo: Integer): Boolean
    var
        Row: Record "LGN HL Login Row";
    begin
        if EntryNo <= 0 then
            exit(false);
        exit(Row.Get(EntryNo));
    end;

    // Deletes the LOGIN rows of the session; returns the entry number of the last one deleted (0 without one).
    procedure DeleteSessionLogin(SessionNo: Integer): Integer
    var
        Row: Record "LGN HL Login Row";
        EntryNo: Integer;
    begin
        Row.SetRange("Session Id", SessionNo);
        Row.SetRange(Kind, 'LOGIN');
        if Row.FindLast() then
            EntryNo := Row."Entry No.";
        Row.DeleteAll();
        exit(EntryNo);
    end;

    // Inserts a row of kind EXTRA for the session; returns its entry number.
    procedure InsertExtra(): Integer
    var
        Row: Record "LGN HL Login Row";
    begin
        Row.Init();
        Row."Session Id" := SessionId();
        Row.Kind := 'EXTRA';
        Row.Insert();
        exit(Row."Entry No.");
    end;

    procedure Put(MarkKey: Code[30]; NewValue: Integer)
    var
        Mark: Record "LGN HL Mark";
    begin
        if Mark.Get(MarkKey) then begin
            Mark.Value := NewValue;
            Mark.Modify();
        end else begin
            Mark."Key" := MarkKey;
            Mark.Value := NewValue;
            Mark.Insert();
        end;
    end;

    // The value of the mark; -1 when it does not exist.
    procedure Get(MarkKey: Code[30]): Integer
    var
        Mark: Record "LGN HL Mark";
    begin
        if Mark.Get(MarkKey) then
            exit(Mark.Value);
        exit(-1);
    end;

    procedure Has(MarkKey: Code[30]): Boolean
    var
        Mark: Record "LGN HL Mark";
    begin
        exit(Mark.Get(MarkKey));
    end;

    // Snapshot of a Disabled codeunit, taken in its first test (which never fails).
    procedure Snap(Prefix: Code[10])
    begin
        Put(Prefix + ' S', SessionId());
        Put(Prefix + ' CALLS', LiveCalls('LOGIN'));
        Put(Prefix + ' REGS', LiveCalls('REGISTER'));
        Put(Prefix + ' MAX', MaxEntry());
        Put(Prefix + ' SROWS', SessionRows(SessionId(), 'LOGIN'));
        Put(Prefix + ' TROWS', TRows());
        Put(Prefix + ' MEMO', MemoTRows());
    end;

    local procedure SinceText(Live: Integer; MarkKey: Code[30]; SameSession: Boolean): Text
    begin
        if not SameSession then
            exit('other session');
        exit(Format(Live - Get(MarkKey)));
    end;

    // The login as a later codeunit sees it, relative to the snapshot of a Disabled codeunit.
    procedure ObserveSince(var Observer: Codeunit "Probe Observer"; Prefix: Code[10])
    var
        SameSession: Boolean;
    begin
        SameSession := SessionId() = Get(Prefix + ' S');
        Observer.Observe('snapshot found', Format(Has(Prefix + ' MAX')));
        Observer.Observe('same session as the snapshot', Format(SameSession));
        Observer.Observe('OnAfterLogin calls in this session', Format(LiveCalls('LOGIN')));
        Observer.Observe('OnRegisterAssistedSetup calls in this session', Format(LiveCalls('REGISTER')));
        Observer.Observe('OnAfterLogin calls since the snapshot', SinceText(LiveCalls('LOGIN'), Prefix + ' CALLS', SameSession));
        Observer.Observe('OnRegisterAssistedSetup calls since the snapshot', SinceText(LiveCalls('REGISTER'), Prefix + ' REGS', SameSession));
        Observer.Observe('LOGIN rows of this session', Format(SessionRows(SessionId(), 'LOGIN')));
        Observer.Observe('REGISTER rows of this session', Format(SessionRows(SessionId(), 'REGISTER')));
        Observer.Observe('LOGIN rows of this session written after the snapshot', Format(SessionRowsAfter(SessionId(), 'LOGIN', Get(Prefix + ' MAX'))));
        Observer.Observe('LOGIN rows of the snapshot session', Format(SessionRows(Get(Prefix + ' S'), 'LOGIN')));
        Observer.Observe('LOGIN rows of the snapshot session at the snapshot', Format(Get(Prefix + ' SROWS')));
    end;

    // The memo of this session's login against the T rows before and after the Disabled codeunit A1 inserted one.
    procedure ObserveMemo(var Observer: Codeunit "Probe Observer")
    var
        Memo: Integer;
    begin
        Memo := MemoTRows();
        Observer.Observe('A1 snapshot found', Format(Has('A1 TROWS')));
        Observer.Observe('T rows A1 inserted', Format(Get('A1 TAFTER') - Get('A1 TROWS')));
        Observer.Observe('T rows now minus T rows before A1', Format(TRows() - Get('A1 TROWS')));
        if Memo < 0 then
            Observer.Observe('memo of this session''s login', 'no login in this session')
        else
            Observer.Observe('memo of this session''s login minus T rows before A1', Format(Memo - Get('A1 TROWS')));
        Observer.Observe('memo at A1 snapshot minus T rows before A1', Format(Get('A1 MEMO') - Get('A1 TROWS')));
    end;

    // What a later codeunit sees of the changes the Disabled codeunit A2 made to the login rows.
    procedure ObserveA2Changes(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('A2 deleted a LOGIN row', Format(Get('A2 DELETED') > 0));
        Observer.Observe('LOGIN row A2 deleted is there', Format(RowExists(Get('A2 DELETED'))));
        Observer.Observe('EXTRA row A2 inserted is there', Format(RowExists(Get('A2 EXTRA'))));
    end;
}

// Cell 10 (memo) setup: a Disabled codeunit that inserts one T row after the session's login.
codeunit 87420 "LGN HL A1"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN HL Probe";

    [Test]
    procedure HL_A1_Snap()
    begin
        Probe.Snap('A1');
        Probe.InsertT();
        Probe.Put('A1 TAFTER', Probe.TRows());
    end;

    [Test]
    procedure HL_A1_Session()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if BC28PLUS
        Observer.Observe('OnAfterLogin calls in this session at the snapshot', Format(Probe.Get('A1 CALLS')));
        Observer.Observe('LOGIN rows of this session at the snapshot', Format(Probe.Get('A1 SROWS')));
        Observer.Observe('memo at the snapshot minus T rows at the snapshot', Format(Probe.Get('A1 MEMO') - Probe.Get('A1 TROWS')));
        Observer.Observe('T rows A1 inserted', Format(Probe.Get('A1 TAFTER') - Probe.Get('A1 TROWS')));
        Observer.Observe('memo now minus T rows before A1', Format(Probe.MemoTRows() - Probe.Get('A1 TROWS')));
        Observer.Expect('OnAfterLogin calls in this session at the snapshot', '1');
        Observer.Expect('LOGIN rows of this session at the snapshot', '1');
        Observer.Expect('memo at the snapshot minus T rows at the snapshot', '0');
        Observer.Expect('T rows A1 inserted', '1');
        Observer.Expect('memo now minus T rows before A1', '0');
        Observer.Verify();
#else
        // BC 27 legs run every test codeunit under "Test Runner - Isol. Codeunit" (130450): not asked here.
#endif
    end;
}

// Cell 10: the next hub codeunit (Codeunit isolation) reads the memo of the session's one login.
codeunit 87421 "LGN HL Memo B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Probe: Codeunit "LGN HL Probe";

    [Test]
    procedure HL_MemoB_AfterA1()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if BC28PLUS
        Probe.ObserveSince(Observer, 'A1');
        Probe.ObserveMemo(Observer);
        Observer.Expect('snapshot found', 'Yes');
        Observer.Expect('same session as the snapshot', 'Yes');
        Observer.Expect('OnAfterLogin calls in this session', '1');
        Observer.Expect('OnRegisterAssistedSetup calls in this session', '1');
        Observer.Expect('OnAfterLogin calls since the snapshot', '0');
        Observer.Expect('OnRegisterAssistedSetup calls since the snapshot', '0');
        Observer.Expect('LOGIN rows of this session', '1');
        Observer.Expect('REGISTER rows of this session', '1');
        Observer.Expect('LOGIN rows of this session written after the snapshot', '0');
        Observer.Expect('LOGIN rows of the snapshot session', '1');
        Observer.Expect('LOGIN rows of the snapshot session at the snapshot', '1');
        Observer.Expect('A1 snapshot found', 'Yes');
        Observer.Expect('T rows A1 inserted', '1');
        Observer.Expect('T rows now minus T rows before A1', '1');
        Observer.Expect('memo of this session''s login minus T rows before A1', '0');
        Observer.Expect('memo at A1 snapshot minus T rows before A1', '0');
        Observer.Verify();
#else
        // BC 27 legs run every test codeunit under "Test Runner - Isol. Codeunit" (130450): not asked here.
#endif
    end;
}

// Cell 9: a hub codeunit under Function isolation after the Disabled codeunit A1.
codeunit 87422 "LGN HL Fn B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    var
        Probe: Codeunit "LGN HL Probe";

    [Test]
    procedure HL_FnB_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if BC28PLUS
        Probe.ObserveSince(Observer, 'A1');
        Observer.Expect('snapshot found', 'Yes');
        Observer.Expect('same session as the snapshot', 'Yes');
        Observer.Expect('OnAfterLogin calls in this session', '1');
        Observer.Expect('OnRegisterAssistedSetup calls in this session', '1');
        Observer.Expect('OnAfterLogin calls since the snapshot', '0');
        Observer.Expect('OnRegisterAssistedSetup calls since the snapshot', '0');
        Observer.Expect('LOGIN rows of this session', '1');
        Observer.Expect('REGISTER rows of this session', '1');
        Observer.Expect('LOGIN rows of this session written after the snapshot', '0');
        Observer.Expect('LOGIN rows of the snapshot session', '1');
        Observer.Expect('LOGIN rows of the snapshot session at the snapshot', '1');
        Observer.Verify();
#else
        // BC 27 legs run every test codeunit under "Test Runner - Isol. Codeunit" (130450): not asked here.
#endif
    end;

    // Deletes the session's LOGIN row and inserts a row of its own; never fails.
    [Test]
    procedure HL_FnB_Delete()
    var
        Log: Codeunit "LGN HL Fn Log";
        Before: Integer;
        Deleted: Integer;
        Added: Integer;
    begin
        Before := Probe.SessionRows(SessionId(), 'LOGIN');
        Deleted := Probe.DeleteSessionLogin(SessionId());
        Added := Probe.InsertExtra();
        Log.Set(Before, Probe.SessionRows(SessionId(), 'LOGIN'), Deleted, Added);
    end;

    [Test]
    procedure HL_FnB_AfterDelete()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LGN HL Fn Log";
    begin
#if BC28PLUS
        Observer.Observe('LOGIN rows of this session before the delete', Format(Log.Before()));
        Observer.Observe('LOGIN rows of this session right after the delete', Format(Log.After()));
        Observer.Observe('LOGIN rows of this session in the next test', Format(Probe.SessionRows(SessionId(), 'LOGIN')));
        Observer.Observe('deleted LOGIN row is back', Format(Probe.RowExists(Log.Deleted())));
        Observer.Observe('row the delete test inserted is there', Format(Probe.RowExists(Log.NewEntry())));
        Observer.Observe('OnAfterLogin calls since the A1 snapshot', Format(Probe.LiveCalls('LOGIN') - Probe.Get('A1 CALLS')));
        Observer.Observe('T rows now minus T rows before A1', Format(Probe.TRows() - Probe.Get('A1 TROWS')));
        Observer.Expect('LOGIN rows of this session before the delete', '1');
        Observer.Expect('LOGIN rows of this session right after the delete', '0');
        Observer.Expect('LOGIN rows of this session in the next test', '1');
        Observer.Expect('deleted LOGIN row is back', 'Yes');
        Observer.Expect('row the delete test inserted is there', 'No');
        Observer.Expect('OnAfterLogin calls since the A1 snapshot', '0');
        Observer.Expect('T rows now minus T rows before A1', '1');
        Observer.Verify();
#else
        // BC 27 legs run every test codeunit under "Test Runner - Isol. Codeunit" (130450): not asked here.
#endif
    end;
}

// Cells 7 and 8 setup: a Disabled codeunit whose tests change the login rows: one EXTRA row more, the session's LOGIN row deleted.
codeunit 87424 "LGN HL A2"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LGN HL Probe";

    [Test]
    procedure HL_A2_Snap()
    begin
        Probe.Snap('A2');
    end;

    [Test]
    procedure HL_A2_Change()
    begin
        Probe.Put('A2 EXTRA', Probe.InsertExtra());
        Probe.Put('A2 DELETED', Probe.DeleteSessionLogin(SessionId()));
    end;

    [Test]
    procedure HL_A2_NextTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if BC28PLUS
        Observer.Observe('LOGIN rows of this session at the snapshot', Format(Probe.Get('A2 SROWS')));
        Observer.Observe('OnAfterLogin calls since the A1 snapshot', Format(Probe.Get('A2 CALLS') - Probe.Get('A1 CALLS')));
        Probe.ObserveA2Changes(Observer);
        Observer.Observe('LOGIN rows of this session', Format(Probe.SessionRows(SessionId(), 'LOGIN')));
        Observer.Expect('LOGIN rows of this session at the snapshot', '1');
        Observer.Expect('OnAfterLogin calls since the A1 snapshot', '0');
        Observer.Expect('A2 deleted a LOGIN row', 'Yes');
        Observer.Expect('LOGIN row A2 deleted is there', 'No');
        Observer.Expect('EXTRA row A2 inserted is there', 'Yes');
        Observer.Expect('LOGIN rows of this session', '0');
        Observer.Verify();
#else
        // BC 27 legs run every test codeunit under "Test Runner - Isol. Codeunit" (130450): not asked here.
#endif
    end;
}

// Cell 7: a codeunit with handler functions (runner 130450 on the BC 28+ legs) after A2.
codeunit 87425 "LGN HL WS Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LGN HL Probe";

    [Test]
    [HandlerFunctions('HlMessageHandler')]
    procedure HL_WSH_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('HL probe');
#if BC28PLUS
        Probe.ObserveSince(Observer, 'A2');
        Probe.ObserveA2Changes(Observer);
        Probe.ObserveMemo(Observer);
        Observer.Expect('snapshot found', 'Yes');
        Observer.Expect('same session as the snapshot', 'No');
        Observer.Expect('OnAfterLogin calls in this session', '1');
        Observer.Expect('OnRegisterAssistedSetup calls in this session', '0');
        Observer.Expect('OnAfterLogin calls since the snapshot', 'other session');
        Observer.Expect('OnRegisterAssistedSetup calls since the snapshot', 'other session');
        Observer.Expect('LOGIN rows of this session', '1');
        Observer.Expect('REGISTER rows of this session', '0');
        Observer.Expect('LOGIN rows of this session written after the snapshot', '1');
        Observer.Expect('LOGIN rows of the snapshot session', '0');
        Observer.Expect('LOGIN rows of the snapshot session at the snapshot', '1');
        Observer.Expect('A2 deleted a LOGIN row', 'Yes');
        Observer.Expect('LOGIN row A2 deleted is there', 'No');
        Observer.Expect('EXTRA row A2 inserted is there', 'Yes');
        Observer.Expect('A1 snapshot found', 'Yes');
        Observer.Expect('T rows A1 inserted', '1');
        Observer.Expect('T rows now minus T rows before A1', '1');
        Observer.Expect('memo of this session''s login minus T rows before A1', '1');
        Observer.Expect('memo at A1 snapshot minus T rows before A1', '0');
        Observer.Verify();
#else
        // BC 27 legs run every test codeunit under "Test Runner - Isol. Codeunit" (130450): not asked here.
#endif
    end;

    [MessageHandler]
    procedure HlMessageHandler(Msg: Text[1024])
    begin
    end;
}

// Cell 8: a codeunit without handler functions and TestPermissions = NonRestrictive (runner 130450 on the BC 28+ legs).
codeunit 87426 "LGN HL WS NonRestr"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Probe: Codeunit "LGN HL Probe";

    [Test]
    procedure HL_WSN_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if BC28PLUS
        Probe.ObserveSince(Observer, 'A2');
        Probe.ObserveA2Changes(Observer);
        Probe.ObserveMemo(Observer);
        Observer.Expect('snapshot found', 'Yes');
        Observer.Expect('same session as the snapshot', 'No');
        Observer.Expect('OnAfterLogin calls in this session', '1');
        Observer.Expect('OnRegisterAssistedSetup calls in this session', '0');
        Observer.Expect('OnAfterLogin calls since the snapshot', 'other session');
        Observer.Expect('OnRegisterAssistedSetup calls since the snapshot', 'other session');
        Observer.Expect('LOGIN rows of this session', '1');
        Observer.Expect('REGISTER rows of this session', '0');
        Observer.Expect('LOGIN rows of this session written after the snapshot', '1');
        Observer.Expect('LOGIN rows of the snapshot session', '0');
        Observer.Expect('LOGIN rows of the snapshot session at the snapshot', '1');
        Observer.Expect('A2 deleted a LOGIN row', 'Yes');
        Observer.Expect('LOGIN row A2 deleted is there', 'No');
        Observer.Expect('EXTRA row A2 inserted is there', 'Yes');
        Observer.Expect('A1 snapshot found', 'Yes');
        Observer.Expect('T rows A1 inserted', '1');
        Observer.Expect('T rows now minus T rows before A1', '1');
        Observer.Expect('memo of this session''s login minus T rows before A1', '1');
        Observer.Expect('memo at A1 snapshot minus T rows before A1', '0');
        Observer.Verify();
#else
        // BC 27 legs run every test codeunit under "Test Runner - Isol. Codeunit" (130450): not asked here.
#endif
    end;
}

// Cell 8, second shape: no handler functions and no TestPermissions property (Restrictive, runner 130450 on the BC 28+ legs).
codeunit 87427 "LGN HL WS Restr"
{
    Subtype = Test;

    var
        Probe: Codeunit "LGN HL Probe";

    [Test]
    procedure HL_WSR_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
#if BC28PLUS
        Probe.ObserveSince(Observer, 'A2');
        Probe.ObserveA2Changes(Observer);
        Probe.ObserveMemo(Observer);
        Observer.Expect('snapshot found', 'Yes');
        Observer.Expect('same session as the snapshot', 'No');
        Observer.Expect('OnAfterLogin calls in this session', '1');
        Observer.Expect('OnRegisterAssistedSetup calls in this session', '0');
        Observer.Expect('OnAfterLogin calls since the snapshot', 'other session');
        Observer.Expect('OnRegisterAssistedSetup calls since the snapshot', 'other session');
        Observer.Expect('LOGIN rows of this session', '1');
        Observer.Expect('REGISTER rows of this session', '0');
        Observer.Expect('LOGIN rows of this session written after the snapshot', '1');
        Observer.Expect('LOGIN rows of the snapshot session', '0');
        Observer.Expect('LOGIN rows of the snapshot session at the snapshot', '1');
        Observer.Expect('A2 deleted a LOGIN row', 'Yes');
        Observer.Expect('LOGIN row A2 deleted is there', 'No');
        Observer.Expect('EXTRA row A2 inserted is there', 'Yes');
        Observer.Expect('A1 snapshot found', 'Yes');
        Observer.Expect('T rows A1 inserted', '1');
        Observer.Expect('T rows now minus T rows before A1', '1');
        Observer.Expect('memo of this session''s login minus T rows before A1', '1');
        Observer.Expect('memo at A1 snapshot minus T rows before A1', '0');
        Observer.Verify();
#else
        // BC 27 legs run every test codeunit under "Test Runner - Isol. Codeunit" (130450): not asked here.
#endif
    end;
}
