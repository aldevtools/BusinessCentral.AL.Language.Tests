// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: CU P7 State (96121), CU P7 Row (96120)
//
// Probe P7 of ADR-066 (al-runtime-rs), second half: reads what "CU P7 A Setter" (96122), the
// previous test codeunit, left in the SingleInstance state and in the table.

codeunit 96123 "CU P7 B Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        State: Codeunit "CU P7 State";
    begin
        State.NoteRan('B.OnRun');
    end;

    [Test]
    procedure P7B_ReadsWhatThePreviousTestCodeunitLeft()
    // CLAIM: see the assertions.
    var
        State: Codeunit "CU P7 State";
        Row: Record "CU P7 Row";
    begin
        Error('P7 OBS B ran=%1 value=%2 COMMITTED=%3 OPEN=%4', State.GetRan(), State.GetValue(),
          Row.Get('COMMITTED'), Row.Get('OPEN'));
    end;
}
