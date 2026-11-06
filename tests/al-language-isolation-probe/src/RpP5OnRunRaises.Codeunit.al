namespace ALLanguage.IsolationProbe;

// Probe P5 (ADR-066 of al-runtime-rs): OnRun raises an error, but only while a probe runner
// has armed it right before its `Ok := Codeunit.Run(...)` (the discovery runner 130452 also
// runs OnRun, and an error there would stop the whole test suite from being built). The
// reader (61346) reads Ok, the last error, and whether the method below ran at all.
codeunit 61341 "LT RP P5 OnRun Raises"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        Log.Add(Codeunit::"LT RP P5 OnRun Raises", 'OnRun', 'X body', '');
        if Log.IsOnRunErrorArmed() then
            Error('P5 OnRun fails on purpose');
    end;

    [Test]
    procedure P5_AfterFailedOnRun()
    begin
        Log.Add(Codeunit::"LT RP P5 OnRun Raises", 'P5_AfterFailedOnRun', 'X body', '');
    end;

    var
        Log: Codeunit "LT RP Log";
}
