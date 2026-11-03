// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-requiredtestisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-integer-integer-string-table-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (AL Runner issues 5607 and 5609), the neighbours of QuCommitIsolation.al in this folder: what a test codeunit's OnRun
// trigger, Session.StartSession and handler functions do under each test isolation.
//
// Lever and harness (see QuCommitIsolation.al): on BC 28 and later the Linux legs run a test codeunit without
// [HandlerFunctions] and with TestPermissions = Disabled through the service tier's TestRunnerHub, which takes the isolation
// from RequiredTestIsolation; every other codeunit, and on BC 27 every codeunit, runs under "Test Runner - Isol. Codeunit"
// (130450, TestIsolation = Codeunit). The hub leg runs before the 130450 leg. So:
//   - Hub group (RQ_C*, RQ_F*, RQ_D*): RequiredTestIsolation Codeunit, Function, Disabled under the hub (BC 28+).
//   - 130450 group (RQ_WF*, RQ_WD*): RequiredTestIsolation Function and Disabled with handler functions, run by the Codeunit
//     test runner. Every test of these codeunits carries a handler and uses it, so the pair stays in the same leg.
// A test runner codeunit of our own (TestIsolation = Function or Disabled) cannot be started from a test, and the corpus CI
// runner is fixed to 130450, so runner-level TestIsolation is not asked here.
//
// One pair of test codeunits per isolation: A (OnRun writes, tests write and observe) and B (the next codeunit id, reads what
// A left). Every key has the prefix of its pair. Writers delete before they insert, so a rerun of a codeunit reads the same.
// The first test of each hub A codeunit writes and never fails; what it saw goes to a SingleInstance log the second test reads.
//
// Measured on BC 27.5, 28.5 and 29.0 (Linux legs):
//   - OnRun of a test codeunit runs once, before its first test, under every isolation and both runners (onrun_calls 1 in
//     the first and the second test), with no write transaction open at its start. The test codeunit is one instance for
//     all its tests: globals set by OnRun and by an earlier test are still set in a later test, under Function isolation too.
//   - OnRun's writes, the committed one and the one left open, are seen by the tests of the codeunit (every isolation).
//   - Hub, Codeunit isolation: the later tests see everything; the next codeunit sees nothing, OnRun's committed write
//     included (C11). Hub, Function isolation: OnRun's writes survive into every test, a test's own write does not reach
//     the next test (F02), and the next codeunit sees none of it, OnRun's committed write included (F11). Hub, Disabled
//     isolation: everything persists into the later tests and the next codeunit (D11).
//   - Session.StartSession inside a test: allowed only under Disabled isolation on the hub (the session runs, ends and its
//     row is seen by the test, the next test and the next codeunit: D03, D04, D11). Under Codeunit and Function isolation,
//     and under the 130450 runner whatever RequiredTestIsolation says, it fails with "Sessions can only be started in
//     tests that are run by a TestRunner that has TestIsolation set to Disabled." (TestStartSessionNotAllowed).
//   - Under the 130450 runner, RequiredTestIsolation = Function and = Disabled change nothing, on BC 28+ too, and raise no
//     error: a later test sees the earlier tests' writes, committed or not (WF03, WD03), the next codeunit sees none of
//     them (WF11, WD11), StartSession is refused (WF04, WD04). MessageHandler and ConfirmHandler work as usual.
//   - BC 27 legs (130450 for every codeunit): OnRun runs outside the codeunit isolation, so its writes, committed and
//     open, reach the next codeunit (C11, F11, D11 #else branches); the hub on BC 28+ rolls them back (Codeunit, Function).
//     The BC28PLUS guards mark this difference of the test HARNESS (130450 against the hub), not of the platform version.
// Object ids 88500-88515.
// BC versions: 27.5, 28.5, 29.0

table 88500 "LT RQ Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

// The writers and readers every pair shares.
codeunit 88501 "LT RQ Probe"
{
    procedure Put(RowKey: Text)
    var
        Row: Record "LT RQ Row";
    begin
        if Row.Get(RowKey) then
            Row.Delete();
        Row."Key" := CopyStr(RowKey, 1, MaxStrLen(Row."Key"));
        Row.Insert();
    end;

    procedure Has(RowKey: Text): Text
    var
        Row: Record "LT RQ Row";
    begin
        exit(Format(Row.Get(RowKey)));
    end;

    procedure Tx(): Text
    begin
        exit(Format(Database.IsInWriteTransaction()));
    end;

    // The OnRun trigger of every A codeunit: a write, a Commit, a second write left open.
    procedure OnRunWrites(P: Text)
    begin
        Put(P + '-ORCM');
        Commit();
        Put(P + '-ORNC');
    end;

    procedure ObserveOnRunRows(P: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('onrun_committed_row', Has(P + '-ORCM'));
        Observer.Observe('onrun_open_row', Has(P + '-ORNC'));
    end;

    // Starts a background session that inserts <P>-SES, waits up to 30 seconds for it to end and observes what the test sees.
    // The test itself writes nothing to the table; the session deletes an old row before it inserts.
    procedure ObserveStartSession(P: Text; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT RQ Row";
        SessionId: Integer;
        Started: Boolean;
        Tries: Integer;
    begin
        Row."Key" := CopyStr(P + '-SES', 1, MaxStrLen(Row."Key"));
        ClearLastError();
        Started := TryStart(SessionId, Row);
        Observer.Observe('start_ok', Format(Started));
        Observer.ObserveError('start');
        Observer.Observe('session_id_positive', Format(SessionId > 0));
        if not Started then
            exit;
        while Session.IsSessionActive(SessionId) and (Tries < 300) do begin
            Sleep(100);
            Tries += 1;
        end;
        Observer.Observe('session_ended', Format(not Session.IsSessionActive(SessionId)));
        Observer.Observe('session_row', Has(P + '-SES'));
    end;

    [TryFunction]
    local procedure TryStart(var SessionId: Integer; var Row: Record "LT RQ Row")
    begin
        Session.StartSession(SessionId, Codeunit::"LT RQ Session Writer", CompanyName(), Row);
    end;
}

// Run in a background session with a record: inserts it.
codeunit 88502 "LT RQ Session Writer"
{
    TableNo = "LT RQ Row";

    trigger OnRun()
    var
        Row: Record "LT RQ Row";
    begin
        if Row.Get(Rec."Key") then
            Row.Delete();
        Row."Key" := Rec."Key";
        Row.Insert();
    end;
}

// What the OnRun trigger and the first test of "LT RQ Codeunit A" saw (survives every rollback; used by that codeunit only).
codeunit 88503 "LT RQ Codeunit Log"
{
    SingleInstance = true;

    var
        Hits: Integer;
        Names: List of [Text];
        Values: List of [Text];

    procedure Hit()
    begin
        Hits += 1;
    end;

    procedure Count(): Integer
    begin
        exit(Hits);
    end;

    procedure Note(Name: Text; Value: Text)
    begin
        Names.Add(Name);
        Values.Add(Value);
    end;

    procedure ObserveNotes(var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
    begin
        Observer.Observe('notes', Format(Names.Count()));
        for i := 1 to Names.Count() do
            Observer.Observe(Names.Get(i), Values.Get(i));
    end;
}

// What the OnRun trigger and the first test of "LT RQ Function A" saw (survives every rollback; used by that codeunit only).
codeunit 88504 "LT RQ Function Log"
{
    SingleInstance = true;

    var
        Hits: Integer;
        Names: List of [Text];
        Values: List of [Text];

    procedure Hit()
    begin
        Hits += 1;
    end;

    procedure Count(): Integer
    begin
        exit(Hits);
    end;

    procedure Note(Name: Text; Value: Text)
    begin
        Names.Add(Name);
        Values.Add(Value);
    end;

    procedure ObserveNotes(var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
    begin
        Observer.Observe('notes', Format(Names.Count()));
        for i := 1 to Names.Count() do
            Observer.Observe(Names.Get(i), Values.Get(i));
    end;
}

// What the OnRun trigger and the first test of "LT RQ Disabled A" saw (survives every rollback; used by that codeunit only).
codeunit 88505 "LT RQ Disabled Log"
{
    SingleInstance = true;

    var
        Hits: Integer;
        Names: List of [Text];
        Values: List of [Text];

    procedure Hit()
    begin
        Hits += 1;
    end;

    procedure Count(): Integer
    begin
        exit(Hits);
    end;

    procedure Note(Name: Text; Value: Text)
    begin
        Names.Add(Name);
        Values.Add(Value);
    end;

    procedure ObserveNotes(var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
    begin
        Observer.Observe('notes', Format(Names.Count()));
        for i := 1 to Names.Count() do
            Observer.Observe(Names.Get(i), Values.Get(i));
    end;
}

codeunit 88506 "LT RQ Codeunit A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    begin
        Log.Hit();
        OnRunGlobal += 1;
        Log.Note('onrun_tx_at_start', Probe.Tx());
        Probe.OnRunWrites('RC');
    end;

    var
        Probe: Codeunit "LT RQ Probe";
        Log: Codeunit "LT RQ Codeunit Log";
        OnRunGlobal: Integer;
        TestGlobal: Integer;

    // Writes and never fails: what it sees goes to the log, the next test observes it.
    [Test]
    procedure RQ_C01_FirstTest()
    begin
        Log.Note('t1_tx_at_start', Probe.Tx());
        Log.Note('t1_onrun_calls', Format(Log.Count()));
        Log.Note('t1_onrun_global', Format(OnRunGlobal));
        Log.Note('t1_onrun_committed_row', Probe.Has('RC-ORCM'));
        Log.Note('t1_onrun_open_row', Probe.Has('RC-ORNC'));
        TestGlobal := 1;
        Probe.Put('RC-T1');
    end;

    [Test]
    procedure RQ_C02_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.ObserveNotes(Observer);
        Observer.Observe('tx_at_start', Probe.Tx());
        Observer.Observe('onrun_calls', Format(Log.Count()));
        Observer.Observe('onrun_global', Format(OnRunGlobal));
        Observer.Observe('test_global', Format(TestGlobal));
        Probe.ObserveOnRunRows('RC', Observer);
        Observer.Observe('first_test_row', Probe.Has('RC-T1'));
        Observer.Expect('notes', '6');
        Observer.Expect('onrun_tx_at_start', 'No');
        Observer.Expect('t1_tx_at_start', 'No');
        Observer.Expect('t1_onrun_calls', '1');
        Observer.Expect('t1_onrun_global', '1');
        Observer.Expect('t1_onrun_committed_row', 'Yes');
        Observer.Expect('t1_onrun_open_row', 'Yes');
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('onrun_global', '1');
        Observer.Expect('test_global', '1');
        Observer.Expect('onrun_committed_row', 'Yes');
        Observer.Expect('onrun_open_row', 'Yes');
        Observer.Expect('first_test_row', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RQ_C03_StartSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveStartSession('RC', Observer);
        Observer.Expect('start_ok', 'No');
        Observer.Expect('start|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('start|code', 'TestStartSessionNotAllowed');
        Observer.Expect('session_id_positive', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RQ_C04_AfterStartSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('session_row', Probe.Has('RC-SES'));
        Observer.Expect('session_row', 'No');
        Observer.Verify();
    end;
}

codeunit 88507 "LT RQ Codeunit B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure RQ_C11_NextCodeunitSees()
    var
        Probe: Codeunit "LT RQ Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tx_at_start', Probe.Tx());
        Probe.ObserveOnRunRows('RC', Observer);
        Observer.Observe('first_test_row', Probe.Has('RC-T1'));
        Observer.Observe('session_row', Probe.Has('RC-SES'));
#if BC28PLUS
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_committed_row', 'No');
        Observer.Expect('onrun_open_row', 'No');
        Observer.Expect('first_test_row', 'No');
        Observer.Expect('session_row', 'No');
#else
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_committed_row', 'Yes');
        Observer.Expect('onrun_open_row', 'Yes');
        Observer.Expect('first_test_row', 'No');
        Observer.Expect('session_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 88508 "LT RQ Function A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    trigger OnRun()
    begin
        Log.Hit();
        OnRunGlobal += 1;
        Log.Note('onrun_tx_at_start', Probe.Tx());
        Probe.OnRunWrites('RF');
    end;

    var
        Probe: Codeunit "LT RQ Probe";
        Log: Codeunit "LT RQ Function Log";
        OnRunGlobal: Integer;
        TestGlobal: Integer;

    // Writes and never fails: what it sees goes to the log, the next test observes it.
    [Test]
    procedure RQ_F01_FirstTest()
    begin
        Log.Note('t1_tx_at_start', Probe.Tx());
        Log.Note('t1_onrun_calls', Format(Log.Count()));
        Log.Note('t1_onrun_global', Format(OnRunGlobal));
        Log.Note('t1_onrun_committed_row', Probe.Has('RF-ORCM'));
        Log.Note('t1_onrun_open_row', Probe.Has('RF-ORNC'));
        TestGlobal := 1;
        Probe.Put('RF-T1');
    end;

    [Test]
    procedure RQ_F02_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.ObserveNotes(Observer);
        Observer.Observe('tx_at_start', Probe.Tx());
        Observer.Observe('onrun_calls', Format(Log.Count()));
        Observer.Observe('onrun_global', Format(OnRunGlobal));
        Observer.Observe('test_global', Format(TestGlobal));
        Probe.ObserveOnRunRows('RF', Observer);
        Observer.Observe('first_test_row', Probe.Has('RF-T1'));
#if BC28PLUS
        Observer.Expect('notes', '6');
        Observer.Expect('onrun_tx_at_start', 'No');
        Observer.Expect('t1_tx_at_start', 'No');
        Observer.Expect('t1_onrun_calls', '1');
        Observer.Expect('t1_onrun_global', '1');
        Observer.Expect('t1_onrun_committed_row', 'Yes');
        Observer.Expect('t1_onrun_open_row', 'Yes');
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('onrun_global', '1');
        Observer.Expect('test_global', '1');
        Observer.Expect('onrun_committed_row', 'Yes');
        Observer.Expect('onrun_open_row', 'Yes');
        Observer.Expect('first_test_row', 'No');
#else
        Observer.Expect('notes', '6');
        Observer.Expect('onrun_tx_at_start', 'No');
        Observer.Expect('t1_tx_at_start', 'No');
        Observer.Expect('t1_onrun_calls', '1');
        Observer.Expect('t1_onrun_global', '1');
        Observer.Expect('t1_onrun_committed_row', 'Yes');
        Observer.Expect('t1_onrun_open_row', 'Yes');
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('onrun_global', '1');
        Observer.Expect('test_global', '1');
        Observer.Expect('onrun_committed_row', 'Yes');
        Observer.Expect('onrun_open_row', 'Yes');
        Observer.Expect('first_test_row', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure RQ_F03_StartSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveStartSession('RF', Observer);
        Observer.Expect('start_ok', 'No');
        Observer.Expect('start|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('start|code', 'TestStartSessionNotAllowed');
        Observer.Expect('session_id_positive', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RQ_F04_AfterStartSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('session_row', Probe.Has('RF-SES'));
        Observer.Expect('session_row', 'No');
        Observer.Verify();
    end;
}

codeunit 88509 "LT RQ Function B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    procedure RQ_F11_NextCodeunitSees()
    var
        Probe: Codeunit "LT RQ Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tx_at_start', Probe.Tx());
        Probe.ObserveOnRunRows('RF', Observer);
        Observer.Observe('first_test_row', Probe.Has('RF-T1'));
        Observer.Observe('session_row', Probe.Has('RF-SES'));
#if BC28PLUS
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_committed_row', 'No');
        Observer.Expect('onrun_open_row', 'No');
        Observer.Expect('first_test_row', 'No');
        Observer.Expect('session_row', 'No');
#else
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_committed_row', 'Yes');
        Observer.Expect('onrun_open_row', 'Yes');
        Observer.Expect('first_test_row', 'No');
        Observer.Expect('session_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 88510 "LT RQ Disabled A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    begin
        Log.Hit();
        OnRunGlobal += 1;
        Log.Note('onrun_tx_at_start', Probe.Tx());
        Probe.OnRunWrites('RD');
    end;

    var
        Probe: Codeunit "LT RQ Probe";
        Log: Codeunit "LT RQ Disabled Log";
        OnRunGlobal: Integer;
        TestGlobal: Integer;

    // Writes and never fails: what it sees goes to the log, the next test observes it.
    [Test]
    procedure RQ_D01_FirstTest()
    begin
        Log.Note('t1_tx_at_start', Probe.Tx());
        Log.Note('t1_onrun_calls', Format(Log.Count()));
        Log.Note('t1_onrun_global', Format(OnRunGlobal));
        Log.Note('t1_onrun_committed_row', Probe.Has('RD-ORCM'));
        Log.Note('t1_onrun_open_row', Probe.Has('RD-ORNC'));
        TestGlobal := 1;
        Probe.Put('RD-T1');
    end;

    [Test]
    procedure RQ_D02_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.ObserveNotes(Observer);
        Observer.Observe('tx_at_start', Probe.Tx());
        Observer.Observe('onrun_calls', Format(Log.Count()));
        Observer.Observe('onrun_global', Format(OnRunGlobal));
        Observer.Observe('test_global', Format(TestGlobal));
        Probe.ObserveOnRunRows('RD', Observer);
        Observer.Observe('first_test_row', Probe.Has('RD-T1'));
        Observer.Expect('notes', '6');
        Observer.Expect('onrun_tx_at_start', 'No');
        Observer.Expect('t1_tx_at_start', 'No');
        Observer.Expect('t1_onrun_calls', '1');
        Observer.Expect('t1_onrun_global', '1');
        Observer.Expect('t1_onrun_committed_row', 'Yes');
        Observer.Expect('t1_onrun_open_row', 'Yes');
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_calls', '1');
        Observer.Expect('onrun_global', '1');
        Observer.Expect('test_global', '1');
        Observer.Expect('onrun_committed_row', 'Yes');
        Observer.Expect('onrun_open_row', 'Yes');
        Observer.Expect('first_test_row', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RQ_D03_StartSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe.ObserveStartSession('RD', Observer);
#if BC28PLUS
        Observer.Expect('start_ok', 'Yes');
        Observer.Expect('start|text', '');
        Observer.Expect('start|code', '');
        Observer.Expect('session_id_positive', 'Yes');
        Observer.Expect('session_ended', 'Yes');
        Observer.Expect('session_row', 'Yes');
#else
        Observer.Expect('start_ok', 'No');
        Observer.Expect('start|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('start|code', 'TestStartSessionNotAllowed');
        Observer.Expect('session_id_positive', 'No');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure RQ_D04_AfterStartSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('session_row', Probe.Has('RD-SES'));
#if BC28PLUS
        Observer.Expect('session_row', 'Yes');
#else
        Observer.Expect('session_row', 'No');
#endif
        Observer.Verify();
    end;
}

codeunit 88511 "LT RQ Disabled B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure RQ_D11_NextCodeunitSees()
    var
        Probe: Codeunit "LT RQ Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tx_at_start', Probe.Tx());
        Probe.ObserveOnRunRows('RD', Observer);
        Observer.Observe('first_test_row', Probe.Has('RD-T1'));
        Observer.Observe('session_row', Probe.Has('RD-SES'));
#if BC28PLUS
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_committed_row', 'Yes');
        Observer.Expect('onrun_open_row', 'Yes');
        Observer.Expect('first_test_row', 'Yes');
        Observer.Expect('session_row', 'Yes');
#else
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('onrun_committed_row', 'Yes');
        Observer.Expect('onrun_open_row', 'Yes');
        Observer.Expect('first_test_row', 'No');
        Observer.Expect('session_row', 'No');
#endif
        Observer.Verify();
    end;
}

// RequiredTestIsolation = Function with handler functions: run by the Codeunit test runner (130450).
codeunit 88512 "LT RQ Handlers Function A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    var
        Probe: Codeunit "LT RQ Probe";
        MessageHits: Integer;
        ConfirmHits: Integer;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure RQ_WF01_InsertNoCommit()
    begin
        Probe.Put('WF-NC');
        Message('LT RQ message');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure RQ_WF02_InsertCommit()
    begin
        Probe.Put('WF-CM');
        Commit();
        Message('LT RQ message');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure RQ_WF03_NextTestSees()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tx_at_start', Probe.Tx());
        Observer.Observe('no_commit_row', Probe.Has('WF-NC'));
        Observer.Observe('committed_row', Probe.Has('WF-CM'));
        Observer.Observe('message_hits_before', Format(MessageHits));
        Observer.Observe('confirm', Format(Confirm('LT RQ confirm?', false)));
        Observer.Observe('confirm_hits', Format(ConfirmHits));
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'Yes');
        Observer.Expect('committed_row', 'Yes');
        Observer.Expect('message_hits_before', '2');
        Observer.Expect('confirm', 'Yes');
        Observer.Expect('confirm_hits', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure RQ_WF04_StartSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT RQ message');
        Probe.ObserveStartSession('WF', Observer);
        Observer.Expect('start_ok', 'No');
        Observer.Expect('start|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('start|code', 'TestStartSessionNotAllowed');
        Observer.Expect('session_id_positive', 'No');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
        MessageHits += 1;
    end;

    [ConfirmHandler]
    procedure ConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmHits += 1;
        Reply := true;
    end;
}

codeunit 88513 "LT RQ Handlers Function B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure RQ_WF11_NextCodeunitSees()
    var
        Probe: Codeunit "LT RQ Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT RQ message');
        Observer.Observe('tx_at_start', Probe.Tx());
        Observer.Observe('no_commit_row', Probe.Has('WF-NC'));
        Observer.Observe('committed_row', Probe.Has('WF-CM'));
        Observer.Observe('session_row', Probe.Has('WF-SES'));
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'No');
        Observer.Expect('committed_row', 'No');
        Observer.Expect('session_row', 'No');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
    end;
}

// RequiredTestIsolation = Disabled with handler functions: run by the Codeunit test runner (130450).
codeunit 88514 "LT RQ Handlers Disabled A"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        Probe: Codeunit "LT RQ Probe";
        MessageHits: Integer;
        ConfirmHits: Integer;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure RQ_WD01_InsertNoCommit()
    begin
        Probe.Put('WD-NC');
        Message('LT RQ message');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure RQ_WD02_InsertCommit()
    begin
        Probe.Put('WD-CM');
        Commit();
        Message('LT RQ message');
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    procedure RQ_WD03_NextTestSees()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('tx_at_start', Probe.Tx());
        Observer.Observe('no_commit_row', Probe.Has('WD-NC'));
        Observer.Observe('committed_row', Probe.Has('WD-CM'));
        Observer.Observe('message_hits_before', Format(MessageHits));
        Observer.Observe('confirm', Format(Confirm('LT RQ confirm?', false)));
        Observer.Observe('confirm_hits', Format(ConfirmHits));
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'Yes');
        Observer.Expect('committed_row', 'Yes');
        Observer.Expect('message_hits_before', '2');
        Observer.Expect('confirm', 'Yes');
        Observer.Expect('confirm_hits', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure RQ_WD04_StartSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT RQ message');
        Probe.ObserveStartSession('WD', Observer);
        Observer.Expect('start_ok', 'No');
        Observer.Expect('start|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('start|code', 'TestStartSessionNotAllowed');
        Observer.Expect('session_id_positive', 'No');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
        MessageHits += 1;
    end;

    [ConfirmHandler]
    procedure ConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmHits += 1;
        Reply := true;
    end;
}

codeunit 88515 "LT RQ Handlers Disabled B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    [HandlerFunctions('MsgHandler')]
    procedure RQ_WD11_NextCodeunitSees()
    var
        Probe: Codeunit "LT RQ Probe";
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT RQ message');
        Observer.Observe('tx_at_start', Probe.Tx());
        Observer.Observe('no_commit_row', Probe.Has('WD-NC'));
        Observer.Observe('committed_row', Probe.Has('WD-CM'));
        Observer.Observe('session_row', Probe.Has('WD-SES'));
        Observer.Expect('tx_at_start', 'No');
        Observer.Expect('no_commit_row', 'No');
        Observer.Expect('committed_row', 'No');
        Observer.Expect('session_row', 'No');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure MsgHandler(Msg: Text[1024])
    begin
    end;
}
