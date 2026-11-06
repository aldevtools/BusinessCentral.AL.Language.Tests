namespace ALLanguage.IsolationProbe;

// Probe P3 (ADR-066 of al-runtime-rs): a test codeunit with no OnRun trigger. "LT RP Reader"
// (61346) reads whether the runner's triggers were called for an OnRun ('OnRun' or '') at all.
codeunit 61338 "LT RP P3 No OnRun"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P3_Passes()
    begin
    end;
}
