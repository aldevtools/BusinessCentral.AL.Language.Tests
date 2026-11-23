// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: OnPrem DotNet, installation and test-session object lifetime
// BC versions: 27.5, 28.5, 29.0
// local object: dedicated installation observation and SingleInstance owner keep this probe isolated.
// Related: AL Runner issue 8954. Native results pending.

codeunit 99454 "LT Install Builder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LocalInstallText: Text;
        SessionInstallText: Text;
        InstallError: Text;

    [Test]
    procedure Install_StringBuilder_PreservesAppendedText()
    // CLAIM: a fresh builder in the installation trigger appends and returns non-default text.
    begin
        Initialize();
        Assert.AreEqual('', InstallError, 'Installation probe must complete.');
        Assert.AreEqual('LOCAL-INSTALL', LocalInstallText, 'Install builder text.');
    end;

    [Test]
    procedure Install_StringBuilder_SingleInstanceIsFreshInTest()
    // CLAIM: an install-session SingleInstance DotNet object is absent from the test session.
    var
        State: Codeunit "LT Install Builder State";
        Before: Text;
        After: Text;
    begin
        Initialize();
        Before := State.ReadValue();
        State.SetValue('TEST-SESSION');
        After := State.ReadValue();
        State.ResetValue();
        Assert.AreEqual('', InstallError, 'Installation probe must complete.');
        Assert.AreEqual('SESSION-INSTALL', SessionInstallText, 'Install session held the builder.');
        Assert.AreEqual('', Before, 'Test session must begin without the install builder.');
        Assert.AreEqual('TEST-SESSION', After, 'Test session must hold its own non-default builder.');
    end;

    local procedure Initialize()
    var
        Observation: Record "LT Install Builder Obs";
        Saved: Record "LT Install Builder Obs";
    begin
        Observation.Get('BUILDER');
        LocalInstallText := Observation."Local Text";
        SessionInstallText := Observation."Session Text";
        InstallError := Observation."Probe Error";
        // Snapshot the install evidence before clearing the probe table, then restore it for repeated test runs.
        Saved := Observation;
        Observation.DeleteAll(false);
        Observation := Saved;
        Observation.Insert(false);
    end;
}
