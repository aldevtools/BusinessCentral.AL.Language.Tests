namespace ALLanguage.IsolationProbe;

// What the NEXT test codeunit sees of the rows "LT SD Isol Commit Error" (61310) wrote (AL Runner
// issues 5607 and 5609). This codeunit has the next id, so every runner runs it right after 61310.
// R1 expects the reading of TestIsolation = Disabled: E2's committed row and both rows of the
// passing E4 stay, E2's uncommitted row does not. A red row is the measurement: its message
// lists which keys exist.
// Measured on BC 27.5, 28.5 and 29.0 (writer SD, 2026-10-25), the same on all three and in two runs: the owner's
// Windows containers, each runner over the whole app through Test Suite Mgt.RunNextTest, one runner invocation per
// test codeunit (tools/windows-remote run.sh with WR_TEST_RUNNER; on 28.5 "Isol Probe Fixture" gave the same rows as
// the nightly's Run-TestsInBcContainer -testRunnerCodeunitId). Runner 61305 (no property) gave exactly the rows of
// 61304 (Disabled).
//   - Function and Codeunit: R1 sees E2-BEFORE=No E2-AFTER=No E4-COMMITTED=No E4-OPEN=No: the end of the test
//     codeunit undoes everything, Commit() included.
//   - Disabled and no property: R1 passes (E2's committed row and both rows of E4 stay, E2's open row does not).
codeunit 61311 "LT SD Isol Commit Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R1_NextCodeunitSeesRowsOfCommitError()
    var
        Row: Record "LT SD Isol Row";
        RowKey: Text;
        Observed: Text;
    begin
        foreach RowKey in 'E2-BEFORE|E2-AFTER|E4-COMMITTED|E4-OPEN'.Split('|') do begin
            if Observed <> '' then
                Observed += ' ';
            Observed += RowKey + '=' + Format(Row.Get(RowKey));
        end;
        if Observed <> 'E2-BEFORE=Yes E2-AFTER=No E4-COMMITTED=Yes E4-OPEN=Yes' then
            Error('R1, the next test codeunit: expected E2-BEFORE=Yes E2-AFTER=No E4-COMMITTED=Yes E4-OPEN=Yes, observed %1', Observed);
    end;
}
