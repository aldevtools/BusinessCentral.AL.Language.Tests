namespace ALLanguage.IsolationProbe;

// Probes P2 and P3 (ADR-066 of al-runtime-rs). "LT RP Reader" (61346) reads, for each method,
// the IsSuccess OnAfterTestRun got and the GetLastErrorText() it saw:
//   P2_Passes     passes.
//   P2_Fails      FAILS ON PURPOSE with the fixed text below, under both probe runners.
//   P2_Caught     raises an error that asserterror catches, so it passes.
// P3: this codeunit declares OnRun (it records that it ran), "LT RP P3 No OnRun" (61338) does
// not. The reader reads which FunctionName the triggers got for it.
codeunit 61337 "LT RP P2 Outcomes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        Log.Add(Codeunit::"LT RP P2 Outcomes", 'OnRun', 'X body', '');
    end;

    [Test]
    procedure P2_Passes()
    begin
    end;

    [Test]
    procedure P2_Fails()
    begin
        Error('P2 fails on purpose');
    end;

    [Test]
    procedure P2_Caught()
    begin
        asserterror Error('P2 error caught by asserterror');
    end;

    var
        Log: Codeunit "LT RP Log";
}
