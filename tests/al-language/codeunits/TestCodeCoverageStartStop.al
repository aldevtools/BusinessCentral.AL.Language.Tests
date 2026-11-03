// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: none (CODECOVERAGELOG is a System method; no table state involved)
// Note: pins what a BC service tier answers for the three AL spellings of
//       CODECOVERAGELOG. The platform records statement hits through a code
//       coverage recorder owned by the session, so the interesting claims are
//       the STATE TRANSITIONS the query form reports, and that the stop form is
//       tolerant of being called with nothing recording.
//
//       Written for AlRunner#3517, where the runner could not start recording at
//       all and raised a raw .NET ArgumentNullException instead. That is a runner
//       defect and is asserted runner-side; what belongs HERE is the BC behaviour
//       the runner is being measured against, which nothing in this corpus pinned.
//
//       The StopWithoutStart arm is the one most worth having: BC tolerates it
//       (the platform looks the recorder up and finds none), and a runner that
//       "fixed" a coverage problem by refusing every call on the surface would
//       still pass an assertion that only checked the start. Asserting the
//       tolerant direction is what makes the pair discriminating.
// BC versions: 24+

codeunit 60339 "Test Code Coverage Start Stop"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure QueryForm_WithNothingRecording_AnswersFalse()
    var
        IsActive: Boolean;
    begin
        // [GIVEN] a session with no code coverage started
        // [WHEN] the no-argument query form is called
        IsActive := CodeCoverageLog();

        // [THEN] it answers false rather than erroring
        Assert.IsFalse(IsActive, 'CODECOVERAGELOG() must answer false when nothing is recording.');
    end;

    [Test]
    procedure StopWithoutStart_IsTolerated()
    var
        IsActive: Boolean;
    begin
        // [GIVEN] a session with no code coverage started
        // [WHEN] recording is stopped anyway
        IsActive := CodeCoverageLog(false, false);

        // [THEN] BC tolerates it and reports the requested state back
        Assert.IsFalse(IsActive, 'CODECOVERAGELOG(FALSE) must return the requested state, FALSE.');

        // [THEN] and the session is still reported as not recording
        Assert.IsFalse(CodeCoverageLog(),
            'CODECOVERAGELOG() must still answer false after a stop that had nothing to stop.');
    end;

    [Test]
    procedure StartThenQuery_ReportsRecording()
    var
        IsActive: Boolean;
    begin
        // [WHEN] single-session recording is started
        IsActive := CodeCoverageLog(true, false);

        // [THEN] the call reports back the state that was requested
        Assert.IsTrue(IsActive, 'CODECOVERAGELOG(TRUE) must return the requested state, TRUE.');

        // [THEN] and the query form now reports that the session IS recording.
        // This is the assertion a runner cannot satisfy by refusing the surface,
        // and the one that says the start actually took.
        Assert.IsTrue(CodeCoverageLog(),
            'CODECOVERAGELOG() must answer true once recording has been started.');

        // [THEN] stopping returns the session to not-recording
        Assert.IsFalse(CodeCoverageLog(false, false),
            'CODECOVERAGELOG(FALSE) must return the requested state, FALSE.');
        Assert.IsFalse(CodeCoverageLog(),
            'CODECOVERAGELOG() must answer false again once recording has been stopped.');
    end;

    [Test]
    procedure StartOneArgOverload_BehavesAsSingleSession()
    var
        IsActive: Boolean;
    begin
        // [WHEN] the one-argument overload is used — the spelling BaseApp codeunit
        //        9990 "Code Coverage Mgt." itself uses
        IsActive := CodeCoverageLog(true);

        // [THEN] it behaves as the two-argument single-session form
        Assert.IsTrue(IsActive, 'CODECOVERAGELOG(TRUE) must return the requested state, TRUE.');
        Assert.IsTrue(CodeCoverageLog(),
            'CODECOVERAGELOG(TRUE) must start recording just as CODECOVERAGELOG(TRUE, FALSE) does.');

        // [THEN] and it stops through the same surface
        CodeCoverageLog(false);
        Assert.IsFalse(CodeCoverageLog(),
            'CODECOVERAGELOG(FALSE) must stop recording started by the one-argument overload.');
    end;
}
