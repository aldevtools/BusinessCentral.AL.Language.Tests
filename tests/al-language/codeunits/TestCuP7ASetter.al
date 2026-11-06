// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: CU P7 State (96121), CU P7 Row (96120)
//
// Probe P7 of ADR-066 (al-runtime-rs), first half: what one test codeunit leaves for the next
// one in the same test run. This codeunit writes; "CU P7 B Reader" (96123) reads. The CI runs
// the codeunits of a shard in ID order, in one session per runner (the TestRunnerHub leg and
// the websocket leg are two sessions; both codeunits have no handler functions and
// TestPermissions = Disabled, so they take the same leg).
//
// OnRun records the call in the SingleInstance state; the first test sets a value, inserts a
// committed row (Commit() after it) and an uncommitted row; the second test reads all of it
// back inside this codeunit.

codeunit 96122 "CU P7 A Setter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        State: Codeunit "CU P7 State";
    begin
        State.NoteRan('A.OnRun');
    end;

    [Test]
    procedure P7A_SetsSingleInstanceValueAndInsertsRows()
    // CLAIM: a test method can set SingleInstance state and insert rows, with and without Commit.
    var
        State: Codeunit "CU P7 State";
        Row: Record "CU P7 Row";
    begin
        State.NoteRan('A.T1');
        State.SetValue(7);
        Row."Key" := 'COMMITTED';
        if Row.Insert() then;
        Commit();
        Row."Key" := 'OPEN';
        if Row.Insert() then;
    end;

    [Test]
    procedure P7A_SecondTestSeesFirstTestsStateAndRows()
    // CLAIM: what the first test of this codeunit left is read back by the second.
    var
        State: Codeunit "CU P7 State";
        Row: Record "CU P7 Row";
    begin
        Error('P7 OBS A.T2 ran=%1 value=%2 COMMITTED=%3 OPEN=%4', State.GetRan(), State.GetValue(),
          Row.Get('COMMITTED'), Row.Get('OPEN'));
    end;
}
