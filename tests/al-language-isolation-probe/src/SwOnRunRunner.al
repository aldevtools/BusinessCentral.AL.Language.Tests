namespace ALLanguage.IsolationProbe;

// Pins "test-codeunit-onrun-rows" of al-runtime-rs: how Microsoft's Test Runner (runner codeunit
// 130450, the way BcContainerHelper and AL-Go run tests) reports the OnRun trigger of a test
// codeunit. Run only by the Windows nightly, under 130450 (-testRunnerCodeunitId 130450, test
// codeunits 97010..97019). The Linux legs never compile this app, and they run through
// TestRunnerHub, which reports a raising OnRun as a failure, so these shapes cannot live in
// tests/al-language.
//
// Measured on BC 28.5 through 130450 (Windows container, 2026-11-09), expected on every major:
//   - OnRun raises: the codeunit is Skipped, its test methods are listed with a blank result
//     (not executed), there is no 'OnRun' row, and the run stays green.
//   - OnRun does not raise: the methods run, there is no 'OnRun' row.
//   - OnRun calls a test method: that method runs once, the others run too, no 'OnRun' row.
// Older readings: the oldest major (corpus probe RlOnRunError, commit c69419f6) and the newest
// (al-runner issue 5859).
//
// OnRun also runs in the AL Test Tool's discovery pass (runner 130452), and an error there would
// stop the suite from being built. So "LT SW OnRun Raises" raises only from its second call in
// the session: the first call is the discovery pass. If discovery and the run were different
// sessions, the raising shape would not be measured and the reader below fails on its own
// expectation, with the observed rows in the message.
//
// The reader has the highest id, so the runner reaches it last and the rows of the other three
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

    var
        RaisesCalls: Integer;
        CalledFromOnRunCount: Integer;
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
        Expect('function rows', 'Raises_AfterOnRun:', Functions(Codeunit::"LT SW OnRun Raises"));
    end;

    [Test]
    procedure OnRunQuiet_MethodRuns_NoOnRunRow()
    begin
        Expect('function rows', 'Quiet_AfterOnRun:Success', Functions(Codeunit::"LT SW OnRun Quiet"));
    end;

    [Test]
    procedure OnRunCallsTestMethod_MethodRunsOnce_OthersRun_NoOnRunRow()
    begin
        Expect('function rows', 'CalledFromOnRun:Success ; Other_Test:Success', Functions(Codeunit::"LT SW OnRun Calls Test"));
        Expect('runs of CalledFromOnRun', '1', Format(State.CalledFromOnRunRuns()));
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
