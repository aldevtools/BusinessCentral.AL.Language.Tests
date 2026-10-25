namespace ALLanguage.IsolationProbe;

// Session.StartSession inside a test, under the TEST RUNNER's TestIsolation for the whole run (AL
// Runner issue 5609). Under the TestRunnerHub and under 130450 this is pinned in
// tests/al-language/codeunit/lt-qu-commit-isolation/RqIsolationModes.al: only Disabled isolation
// allows it. Here the runner decides: Function (61300), Codeunit (61301), Disabled (61304), no
// property (61305).
//   S1 removes the row the session writes, commits and passes.
//   S2 starts "LT SD Isol Session Writer" (61319) through "LT SD Isol Session Starter" (61320, run
//      with Codeunit.Run so a refusal comes back as GetLastErrorText), waits up to 60 seconds for the
//      session to end and states: started, the error text if not, and whether the session's row is
//      there.
//   S3 states whether the session's row is still there in the next test.
// S2 and S3 expect the reading of TestIsolation = Disabled. A red row is the measurement.
// Measured on BC 27.5, 28.5 and 29.0 (writer SD, 2026-10-25), the same on all three and in two runs: the owner's
// Windows containers, each runner over the whole app through Test Suite Mgt.RunNextTest, one runner invocation per
// test codeunit (tools/windows-remote run.sh with WR_TEST_RUNNER; on 28.5 "Isol Probe Fixture" gave the same rows as
// the nightly's Run-TestsInBcContainer -testRunnerCodeunitId). Runner 61305 (no property) gave exactly the rows of
// 61304 (Disabled).
//   - Function and Codeunit: S2 sees started=No error=Sessions can only be started in tests that are run by a
//     TestRunner that has TestIsolation set to Disabled. S3 sees SESSION=No.
//   - Disabled and no property: S2 and S3 pass (the session starts, ends within the wait and its row is seen).
codeunit 61318 "LT SD Isol StartSession"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure S1_RemovesTheSessionRow()
    var
        Row: Record "LT SD Isol Row";
    begin
        if Row.Get('SESSION') then
            Row.Delete();
        Commit();
    end;

    [Test]
    procedure S2_StartSessionInATest()
    var
        Row: Record "LT SD Isol Row";
        Starter: Codeunit "LT SD Isol Session Starter";
        Observed: Text;
        Deadline: DateTime;
    begin
        if Starter.Run() then begin
            Deadline := CurrentDateTime() + 60000;
            while Session.IsSessionActive(Starter.GetSessionId()) and (CurrentDateTime() < Deadline) do
                Sleep(100);
            Observed := StrSubstNo('started=Yes ended=%1 row=%2', not Session.IsSessionActive(Starter.GetSessionId()), Row.Get('SESSION'));
        end else
            Observed := StrSubstNo('started=No error=%1', GetLastErrorText());
        if Observed <> 'started=Yes ended=Yes row=Yes' then
            Error('S2: expected started=Yes ended=Yes row=Yes, observed %1', Observed);
    end;

    [Test]
    procedure S3_NextTestSeesTheSessionRow()
    var
        Row: Record "LT SD Isol Row";
    begin
        if not Row.Get('SESSION') then
            Error('S3: expected SESSION=Yes, observed SESSION=No');
    end;
}
