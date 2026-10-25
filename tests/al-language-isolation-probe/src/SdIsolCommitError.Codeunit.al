namespace ALLanguage.IsolationProbe;

// What a test that calls Commit() and then fails leaves behind, under the TEST RUNNER's
// TestIsolation for the whole run (AL Runner issues 5607 and 5609). Run under every runner of
// this app: Function (61300), Codeunit (61301), Disabled (61304) and no property (61305).
// "LT SD Isol Commit Reader" (61311, the next codeunit id) reads the same keys afterwards.
//
//   E1 empties the table (only runners whose writes persist leave rows behind, and the nightly
//      runs those last). It never fails.
//   E2 inserts E2-BEFORE, calls Commit(), inserts E2-AFTER and then FAILS ON PURPOSE with the
//      fixed text below, under every runner: its failure message is part of the measurement.
//   E3 states what the next test sees of E2's rows.
//   E4 inserts E4-COMMITTED, calls Commit(), inserts E4-OPEN and passes.
//   E5 states what the next test sees of E4's rows.
// E3 and E5 expect the reading of TestIsolation = Disabled (the committed row stays, the failed
// test's uncommitted row does not; a passing test keeps both). A red row is the measurement: its
// message lists which keys exist.
// Measured on BC 27.5, 28.5 and 29.0 (writer SD, 2026-10-25), the same on all three and in two runs: the owner's
// Windows containers, each runner over the whole app through Test Suite Mgt.RunNextTest, one runner invocation per
// test codeunit (tools/windows-remote run.sh with WR_TEST_RUNNER; on 28.5 "Isol Probe Fixture" gave the same rows as
// the nightly's Run-TestsInBcContainer -testRunnerCodeunitId). Runner 61305 (no property) gave exactly the rows of
// 61304 (Disabled).
//   - E2 fails with its own text, "E2 fails on purpose after Commit", under every runner: nothing is added to it.
//   - Function (61300): E3 sees E2-BEFORE=No E2-AFTER=No, E5 sees E4-COMMITTED=No E4-OPEN=No: every test is rolled
//     back, the part before its Commit() too.
//   - Codeunit (61301): E3 sees E2-BEFORE=Yes E2-AFTER=No (the failed test is undone back to its Commit()), E5 sees
//     both rows of E4 (passes).
//   - Disabled (61304) and no property (61305): as Codeunit inside this codeunit (E3 and E5 pass).
codeunit 61310 "LT SD Isol Commit Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure E1_EmptiesTheTable()
    var
        Row: Record "LT SD Isol Row";
    begin
        Row.DeleteAll();
    end;

    [Test]
    procedure E2_InsertsCommitsInsertsThenFails()
    begin
        InsertRow('E2-BEFORE');
        Commit();
        InsertRow('E2-AFTER');
        Error('E2 fails on purpose after Commit');
    end;

    [Test]
    procedure E3_NextTestSeesE2Rows()
    begin
        Expect('E2-BEFORE=Yes E2-AFTER=No', State('E2-BEFORE|E2-AFTER'), 'E3, the test after E2');
    end;

    [Test]
    procedure E4_InsertsCommitsInsertsAndPasses()
    begin
        InsertRow('E4-COMMITTED');
        Commit();
        InsertRow('E4-OPEN');
    end;

    [Test]
    procedure E5_NextTestSeesE4Rows()
    begin
        Expect('E4-COMMITTED=Yes E4-OPEN=Yes', State('E4-COMMITTED|E4-OPEN'), 'E5, the test after E4');
    end;

    local procedure InsertRow(RowKey: Code[30])
    var
        Row: Record "LT SD Isol Row";
    begin
        Row."Key" := RowKey;
        Row.Insert();
    end;

    // "K1=Yes K2=No" for the keys of a |-separated list, in that order.
    local procedure State(Keys: Text): Text
    var
        Row: Record "LT SD Isol Row";
        RowKey: Text;
        Result: Text;
    begin
        foreach RowKey in Keys.Split('|') do begin
            if Result <> '' then
                Result += ' ';
            Result += RowKey + '=' + Format(Row.Get(RowKey));
        end;
        exit(Result);
    end;

    local procedure Expect(Expected: Text; Observed: Text; Where: Text)
    begin
        if Observed <> Expected then
            Error('%1: expected %2, observed %3', Where, Expected, Observed);
    end;
}
