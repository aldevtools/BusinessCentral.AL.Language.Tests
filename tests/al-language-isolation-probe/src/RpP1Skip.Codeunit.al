namespace ALLanguage.IsolationProbe;

// Probe P1 (ADR-066 of al-runtime-rs): the probe runners answer false in OnBeforeTestRun for
// P1_Skipped. "LT RP Reader" (61346) reads whether its body ran and whether, and with which
// IsSuccess, OnAfterTestRun was called. P1_Runs is the control: the runner answers true.
// Both bodies only record that they ran; they assert nothing.
codeunit 61336 "LT RP P1 Skip"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P1_Skipped()
    begin
        Log.Add(Codeunit::"LT RP P1 Skip", 'P1_Skipped', 'X body', '');
    end;

    [Test]
    procedure P1_Runs()
    begin
        Log.Add(Codeunit::"LT RP P1 Skip", 'P1_Runs', 'X body', '');
    end;

    var
        Log: Codeunit "LT RP Log";
}
