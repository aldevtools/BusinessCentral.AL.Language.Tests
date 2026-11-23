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
        LocalInstallText: Text;
        SessionInstallText: Text;
        InstallError: Text;
        InstallApiFlags: Text;

    [Test]
    procedure Install_StringBuilder_PreservesAppendedText()
    // CLAIM: a fresh builder in the installation trigger appends and returns non-default text.
    begin
        Initialize();
        AssertText('', InstallError, 'Installation probe must complete.');
        AssertText('LOCAL-INSTALL', LocalInstallText, 'Install builder text.');
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
        AssertText('', InstallError, 'Installation probe must complete.');
        AssertText('SESSION-INSTALL', SessionInstallText, 'Install session held the builder.');
        AssertText('', Before, 'Test session must begin without the install builder.');
        AssertText('TEST-SESSION', After, 'Test session must hold its own non-default builder.');
    end;

    [Test]
    procedure Install_ApiConfigurationGetters_ReturnEnabledFlags()
    // CLAIM: the install-time API getters are enabled and IsAzure is false on the OnPrem CI host.
    begin
        Initialize();
        AssertText('', InstallError, 'Installation probe must complete.');
        AssertText('SN', InstallApiFlags, 'Services and subscriptions enabled; host is OnPrem.');
    end;

    local procedure AssertText(Expected: Text; Actual: Text; Context: Text)
    begin
        if Expected <> Actual then
            Error('%1: expected [%2], actual [%3].', Context, Expected, Actual);
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
        InstallApiFlags := Observation."API Flags";
        // Snapshot the install evidence before clearing the probe table, then restore it for repeated test runs.
        Saved := Observation;
        Observation.DeleteAll(false);
        Observation := Saved;
        Observation.Insert(false);
    end;
}
