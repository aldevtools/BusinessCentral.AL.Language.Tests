namespace ALLanguage.IsolationProbe;

// Pins "test-codeunit-onrun-rows" of al-runtime-rs: how Microsoft's Test Runner (runner codeunit
// 130450, the way BcContainerHelper and AL-Go run tests) reports the OnRun trigger of a test
// codeunit. Run only by the Windows nightly, under 130450 (-testRunnerCodeunitId 130450, test
// codeunits 97010..97019). The Linux legs never compile this app, and they run through
// TestRunnerHub, which reports a raising OnRun as a failure, so these shapes cannot live in
// tests/al-language.
//
// Observed on BC 28.4 by the Windows nightly through 130450 (run 42801814970, 2026-11-10):
//   - OnRun raises: the codeunit is Skipped, its test methods are listed with the blank result
//     ' ' (the first member of the Result option of "Test Method Line": not executed), there is
//     no 'OnRun' row, and the run stays green.
//   - OnRun does not raise: the methods run, there is no 'OnRun' row.
//   - OnRun calls a test method: the body of that method runs three times in the session: once
//     from OnRun in the discovery pass (130452 lets OnRun run), once from OnRun when 130450 runs
//     the codeunit, and once as a test method. The others run too, and there is no 'OnRun' row.
// The same, and the two shapes below, observed on BC 27.5, 28.5 and 29.0 (2026-11-11) through 130450
// in one web-service session that does the discovery pass and the run, as page 130455 does in the
// one client session of Run-TestsInBcContainer:
//   - "LT SW OnRun Writes": OnRun inserts a row on each call. The discovery pass writes row 1 and
//     it stays (130452 has no test isolation). The run's OnRun writes row 2. The test method sees
//     rows 1 and 2. After the codeunit, 130450 has rolled back row 2; row 1 is still there.
//   - "LT SW OnRun Raises Discovery": OnRun raises only on its first call, the discovery pass. The
//     suite is still built, but the codeunit gets no method rows. The run calls OnRun again (it does
//     not raise), runs no method, and the codeunit row is Skipped.
// Older readings: the oldest major (corpus probe RlOnRunError, commit c69419f6) and the newest
// (al-runner issue 5859).
//
// OnRun also runs in the AL Test Tool's discovery pass (runner 130452). So "LT SW OnRun Raises"
// raises only from its second call in the session: the first call is the discovery pass. If discovery and the run were different
// sessions, the raising shape would not be measured and the reader below fails on its own
// expectation, with the observed rows in the message.
//
// The reader has the highest id, so the runner reaches it last and the rows of the other test
// codeunits are final. Under any other runner it fails with "<no rows>".

// singleinstance-shared-on-purpose: counts OnRun calls and body runs across test codeunits; the reader reads it in a later codeunit.
codeunit 97014 "LT SW OnRun State"
{
    SingleInstance = true;

    procedure BumpRaisesCalls(): Integer
    begin
        RaisesCalls += 1;
        exit(RaisesCalls);
    end;

    procedure BumpCalledFromOnRun()
    begin
        CalledFromOnRunCount += 1;
    end;

    procedure CalledFromOnRunRuns(): Integer
    begin
        exit(CalledFromOnRunCount);
    end;

    procedure BumpWritesCalls(): Integer
    begin
        WritesCalls += 1;
        exit(WritesCalls);
    end;

    procedure WritesCallsSoFar(): Integer
    begin
        exit(WritesCalls);
    end;

    procedure SetWritesSeen(Seen: Text)
    begin
        WritesSeen := Seen;
    end;

    procedure WritesSeenByMethod(): Text
    begin
        if WritesSeen = '' then
            exit('<method did not run>');
        exit(WritesSeen);
    end;

    // The Entry No. of every row of "LT SW OnRun Log", in key order.
    procedure LogRows(): Text
    var
        Log: Record "LT SW OnRun Log";
        Result: Text;
    begin
        if Log.FindSet() then
            repeat
                if Result <> '' then
                    Result += ',';
                Result += Format(Log."Entry No.");
            until Log.Next() = 0;
        if Result = '' then
            exit('<none>');
        exit(Result);
    end;

    procedure BumpRaisesDiscoveryCalls(): Integer
    begin
        RaisesDiscoveryCalls += 1;
        exit(RaisesDiscoveryCalls);
    end;

    procedure RaisesDiscoveryCallsSoFar(): Integer
    begin
        exit(RaisesDiscoveryCalls);
    end;

    procedure MarkRaisesDiscoveryMethodRan()
    begin
        RaisesDiscoveryMethodRan := true;
    end;

    procedure RaisesDiscoveryMethodHasRun(): Boolean
    begin
        exit(RaisesDiscoveryMethodRan);
    end;

    var
        RaisesCalls: Integer;
        CalledFromOnRunCount: Integer;
        WritesCalls: Integer;
        WritesSeen: Text;
        RaisesDiscoveryCalls: Integer;
        RaisesDiscoveryMethodRan: Boolean;
}

table 97010 "LT SW OnRun Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 97013 "LT SW OnRun Writes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Record "LT SW OnRun Log";
        Call: Integer;
    begin
        // One row per OnRun call, keyed by the call number: the discovery pass writes row 1.
        Call := State.BumpWritesCalls();
        Log."Entry No." := Call;
        Log.Note := 'OnRun call ' + Format(Call);
        Log.Insert();
    end;

    [Test]
    procedure Writes_AfterOnRun()
    begin
        State.SetWritesSeen('OnRun calls ' + Format(State.WritesCallsSoFar()) + ', rows ' + State.LogRows());
    end;

    var
        State: Codeunit "LT SW OnRun State";
}

codeunit 97015 "LT SW OnRun Raises Discovery"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // Only the first call raises; the first call is the discovery pass.
        if State.BumpRaisesDiscoveryCalls() = 1 then
            Error('LT SW onrun raises in the discovery pass on purpose');
    end;

    [Test]
    procedure RaisesDiscovery_AfterOnRun()
    begin
        State.MarkRaisesDiscoveryMethodRan();
    end;

    var
        State: Codeunit "LT SW OnRun State";
}

codeunit 97010 "LT SW OnRun Raises"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // The first call is the discovery pass; every later one raises.
        if State.BumpRaisesCalls() > 1 then
            Error('LT SW onrun raises on purpose');
    end;

    [Test]
    procedure Raises_AfterOnRun()
    begin
    end;

    var
        State: Codeunit "LT SW OnRun State";
}

codeunit 97011 "LT SW OnRun Quiet"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure Quiet_AfterOnRun()
    begin
    end;
}

codeunit 97012 "LT SW OnRun Calls Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        CalledFromOnRun();
    end;

    [Test]
    procedure CalledFromOnRun()
    begin
        State.BumpCalledFromOnRun();
    end;

    [Test]
    procedure Other_Test()
    begin
    end;

    var
        State: Codeunit "LT SW OnRun State";
}

codeunit 97018 "LT SW OnRun Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OnRunRaises_CodeunitSkipped_MethodNotExecuted_NoOnRunRow()
    begin
        Expect('codeunit row', 'Skipped', CodeunitResult(Codeunit::"LT SW OnRun Raises"));
        Expect('function rows', 'Raises_AfterOnRun: ', Functions(Codeunit::"LT SW OnRun Raises"));
    end;

    [Test]
    procedure OnRunQuiet_MethodRuns_NoOnRunRow()
    begin
        Expect('function rows', 'Quiet_AfterOnRun:Success', Functions(Codeunit::"LT SW OnRun Quiet"));
    end;

    [Test]
    procedure OnRunCallsTestMethod_BodyRunsThreeTimes_OthersRun_NoOnRunRow()
    begin
        Expect('function rows', 'CalledFromOnRun:Success ; Other_Test:Success', Functions(Codeunit::"LT SW OnRun Calls Test"));
        // Discovery-pass OnRun, the run's OnRun, the test method itself.
        Expect('runs of CalledFromOnRun', '3', Format(State.CalledFromOnRunRuns()));
    end;

    [Test]
    procedure OnRunWrites_DiscoveryRowAndRollback()
    begin
        Expect('seen by the method; rows after the codeunit', 'OnRun calls 2, rows 1,2; after: OnRun calls 2, rows 1',
            State.WritesSeenByMethod() + '; after: OnRun calls ' + Format(State.WritesCallsSoFar()) + ', rows ' + State.LogRows());
    end;

    [Test]
    procedure OnRunRaisesInDiscovery_Rows()
    begin
        Expect('codeunit row; function rows; OnRun calls; method ran', 'Skipped; <no rows>; 2; No',
            CodeunitResult(Codeunit::"LT SW OnRun Raises Discovery") + '; ' + Functions(Codeunit::"LT SW OnRun Raises Discovery") + '; ' +
            Format(State.RaisesDiscoveryCallsSoFar()) + '; ' + Format(State.RaisesDiscoveryMethodHasRun()));
    end;

    // The function rows of a codeunit, in key order: <function>:<result>. The line of the codeunit
    // itself is not in this list, and neither is any row for OnRun if the runner makes none.
    local procedure Functions(CodeunitId: Integer): Text
    var
        RecRef: RecordRef;
        Result: Text;
    begin
        RecRef.Open(130450);
        RecRef.Field(4).SetRange(CodeunitId);
        if RecRef.FindSet() then
            repeat
                if Format(RecRef.Field(3).Value()) <> 'Codeunit' then begin
                    if Result <> '' then
                        Result += ' ; ';
                    Result += Format(RecRef.Field(6).Value()) + ':' + Format(RecRef.Field(8).Value());
                end;
            until RecRef.Next() = 0;
        if Result = '' then
            exit('<no rows>');
        exit(Result);
    end;

    local procedure CodeunitResult(CodeunitId: Integer): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(130450);
        RecRef.Field(4).SetRange(CodeunitId);
        if RecRef.FindSet() then
            repeat
                if Format(RecRef.Field(3).Value()) = 'Codeunit' then
                    exit(Format(RecRef.Field(8).Value()));
            until RecRef.Next() = 0;
        exit('<no codeunit row>');
    end;

    local procedure Expect(What: Text; Expected: Text; Observed: Text)
    begin
        if Expected <> Observed then
            Error('%1: expected [%2], observed [%3]', What, Expected, Observed);
    end;

    var
        State: Codeunit "LT SW OnRun State";
}
