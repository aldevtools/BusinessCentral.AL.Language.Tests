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

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    var
        State: Codeunit "CU P7 State";
    begin
        State.NoteRan('B.OnRun');
    end;

    [Test]
    procedure P7B_ReadsWhatThePreviousTestCodeunitLeft()
    // CLAIM: SingleInstance state survives into the next test codeunit of the run (company scope),
    // and so does A's OnRun call record; rows A inserted do not, committed or not (the test
    // runner's codeunit isolation rolled them back). Measured identical on 27.5, 28.5, 29.0.
    var
        State: Codeunit "CU P7 State";
        Row: Record "CU P7 Row";
    begin
        // Guard: when neither the state nor A's call record is there, A did not run before this
        // codeunit in this session (a different shard or runner); that is not the answer asked for.
        if (State.GetRan() = '') and (State.GetValue() = 0) then
            Error('P7 precondition: CU P7 A Setter (96122) did not run before this codeunit in this session');
        Assert.AreEqual('A.OnRun;A.T1;B.OnRun', State.GetRan(), 'A ran first; B.OnRun ran before this test');
        Assert.AreEqual(7, State.GetValue(), 'SingleInstance value of A survived');
        Assert.IsFalse(Row.Get('COMMITTED'), 'row A committed is gone');
        Assert.IsFalse(Row.Get('OPEN'), 'row A left uncommitted is gone');
    end;
}
