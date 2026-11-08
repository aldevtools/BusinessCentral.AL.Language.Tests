namespace ALLanguage.IsolationProbe;

// Probe P5b (ADR-066 of al-runtime-rs): like P5's "LT RP P5 OnRun Raises" (61341), but the
// probe runners run it with `asserterror Codeunit.Run(...)` and no return value, which is
// closer to what Microsoft's "Test Runner - Mgt" does. "LT RP Runner Logic" (61333) arms the
// error right before that call. The id is above the reader's (61346) on purpose: P5b is read
// by "LT RP Reader B" (61349), which runs after this codeunit.
codeunit 61347 "LT RP P5b OnRun Raises"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        Log.Add(Codeunit::"LT RP P5b OnRun Raises", 'OnRun', 'X body', '');
        if Log.IsOnRunErrorArmed() then
            Error('P5b OnRun fails on purpose');
    end;

    [Test]
    procedure P5b_AfterFailedOnRun()
    begin
        Log.Add(Codeunit::"LT RP P5b OnRun Raises", 'P5b_AfterFailedOnRun', 'X body', '');
    end;

    var
        Log: Codeunit "LT RP Log";
}
