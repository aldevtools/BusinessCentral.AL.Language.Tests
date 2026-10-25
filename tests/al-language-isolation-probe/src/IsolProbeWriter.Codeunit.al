namespace ALLanguage.IsolationProbe;

// What a test runner keeps between the tests of one test codeunit and for the NEXT test
// codeunit (corpus issue 645, items 2 and 4). "LT DJ Isol Reader" (61307) runs after this
// codeunit (higher id) and reads what it wrote.
//
// Run by the Windows nightly under all four runners of this app: Function (61300), Codeunit
// (61301), no property (61305) and Disabled (61304), in that order. OnRun first empties the
// table, so a row from an earlier run cannot answer for this one.
//   OnRun inserts W-ONRUN; W1 inserts W-PASS; W2 inserts W-FAIL and then FAILS ON PURPOSE,
//   with the fixed message below, in every run: it is the failing test whose writes W4 and
//   R3 look for.
// Each assertion states the reading expected under TestIsolation = Disabled: nothing is rolled
// back except the failing test's own writes. A red row is the measurement:
//   W3 no W-PASS row     -> the database was rolled back after W1 (expected under Function).
//   W4 found W-FAIL      -> the failing test's writes were kept.
//   W5 no W-ONRUN row    -> the rollback also discarded what OnRun wrote.
codeunit 61306 "LT DJ Isol Writer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        CrossRow.DeleteAll();
        CrossRow."Key" := 'W-ONRUN';
        CrossRow.Insert();
    end;

    [Test]
    procedure W1_InsertsPassRow()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        CrossRow."Key" := 'W-PASS';
        CrossRow.Insert();
        if not CrossRow.Get('W-PASS') then
            Error('W1 could not read back the row it inserted');
    end;

    [Test]
    procedure W2_InsertsFailRowThenFailsOnPurpose()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        CrossRow."Key" := 'W-FAIL';
        CrossRow.Insert();
        Error('W2 fails on purpose after inserting W-FAIL');
    end;

    [Test]
    procedure W3_PassRowStillThere()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        if not CrossRow.Get('W-PASS') then
            Error('The row W1 inserted is gone in W3: the database was rolled back after W1 (expected under TestIsolation = Function, not Disabled)');
    end;

    [Test]
    procedure W4_FailRowRolledBack()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        if CrossRow.Get('W-FAIL') then
            Error('The row W2 inserted before it failed is still there in W4: the failing test''s writes were kept');
    end;

    [Test]
    procedure W5_OnRunRowStillThere()
    var
        CrossRow: Record "LT DJ Isol Cross Row";
    begin
        if not CrossRow.Get('W-ONRUN') then
            Error('The row OnRun inserted is gone in W5: a rollback returned to the state before OnRun');
    end;
}
