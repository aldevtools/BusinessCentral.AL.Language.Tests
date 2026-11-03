// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-method
// Scope: in-scope
// Fixtures used: Install StartSession Obs (60446), Install StartSession Marker (60447),
//                Install StartSession Probe (60445), Assert (60021)
//
// StartSession called from inside an install trigger does not start a session. BC checks
// session.AppInstallationContext in ALSession.ALStartSessionAsyncImpl and returns false before
// it opens a session or writes SessionId, outside the try block that turns errors into false.
//
// What is proved, per test:
//   * the install trigger ran and recorded its observation (precondition for the rest);
//   * StartSession answered false, and SessionId kept the caller's value (777);
//   * the form that ignores the return value raised no error, and also left SessionId alone;
//   * the worker never ran: its marker row is absent.
// Each observable alone has another explanation (false can come from a trapped dispatch
// error; an absent row can come from a dispatch that silently ran nothing), so they are
// asserted together.
//
// NOTE: deliberately no Initialize()/DeleteAll() - like the sibling install-trigger tests, these
// observe rows written before any test code ran, and clearing them would defeat the purpose.

codeunit 60449 "Test Install StartSession"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ObsCodeTok: Label 'STARTSESSION', Locked = true;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure TestInstall_StartSessionProbeRecorded()
    var
        Observation: Record "Install StartSession Obs";
    begin
        Assert.IsTrue(Observation.Get(ObsCodeTok),
          'OnInstallAppPerCompany must have written the STARTSESSION observation row');
    end;

    [Test]
    procedure TestInstall_StartSessionReturnsFalseAndLeavesSessionId()
    var
        Observation: Record "Install StartSession Obs";
    begin
        Observation.Get(ObsCodeTok);
        Assert.IsFalse(Observation."Returned",
          'StartSession must answer false while the app is being installed');
        Assert.AreEqual(777, Observation."Session Id After",
          'StartSession must not write SessionId when it skips the session during install');
    end;

    [Test]
    procedure TestInstall_StartSessionWithoutReturnValueRaisesNoError()
    var
        Observation: Record "Install StartSession Obs";
    begin
        Observation.Get(ObsCodeTok);
        Assert.IsTrue(Observation."Reached After Plain Call",
          'StartSession without a return value must not raise an error during install');
        Assert.AreEqual(777, Observation."Plain Session Id After",
          'StartSession without a return value must not write SessionId during install either');
    end;

    [Test]
    procedure TestInstall_StartSessionWorkerNeverRan()
    var
        Marker: Record "Install StartSession Marker";
    begin
        Assert.IsFalse(Marker.Get('RAN'),
          'the worker passed to StartSession during install must not have run');
        Assert.AreEqual(0, Marker.Count(),
          'no worker row may exist at all');
    end;
}
