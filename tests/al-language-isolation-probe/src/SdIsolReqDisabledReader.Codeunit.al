namespace ALLanguage.IsolationProbe;

// What the NEXT test codeunit sees of the row "LT SD Isol Req Disabled" (61314, RequiredTestIsolation
// = Disabled) inserted (AL Runner issues 5607 and 5609). This codeunit sets no RequiredTestIsolation.
// N1 expects the reading of TestIsolation = Disabled (the row stays). A red row is the measurement.
// Measured on BC 27.5, 28.5 and 29.0 (writer SD, 2026-10-25), the same on all three and in two runs: the owner's
// Windows containers, each runner over the whole app through Test Suite Mgt.RunNextTest, one runner invocation per
// test codeunit (tools/windows-remote run.sh with WR_TEST_RUNNER; on 28.5 "Isol Probe Fixture" gave the same rows as
// the nightly's Run-TestsInBcContainer -testRunnerCodeunitId). Runner 61305 (no property) gave exactly the rows of
// 61304 (Disabled).
//   - N1 fails under Function and Codeunit ("observed ...=No (rolled back at the end of codeunit 61314)") and passes
//     under Disabled and no property, whatever RequiredTestIsolation codeunit 61314 sets.
codeunit 61315 "LT SD Isol Req Disabled Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure N1_NextCodeunitSeesRD1()
    var
        Row: Record "LT SD Isol Row";
    begin
        if not Row.Get('RD-1') then
            Error('N1 after RequiredTestIsolation = Disabled: expected RD-1=Yes, observed RD-1=No (rolled back at the end of codeunit 61314)');
    end;
}
