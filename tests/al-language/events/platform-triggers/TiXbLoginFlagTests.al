// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XApp B tests/al-language-xapp-b/TiXbLoginFlag.al (SingleInstance codeunit 98476 with one Boolean,
//   subscriber 98477 of "System Initialization".OnAfterLogin sets it to true).
// Probe (al-runner issue 8239): what the test session reads of a Boolean global that a dependency app's OnAfterLogin subscriber set in that
//   app's SingleInstance codeunit. Cells: first read in the first test; the second test after the first set it to false.
// BC result: (filled in after the measurement)
// BC versions: 27 - 29
// singleinstance-shared-on-purpose: the XApp B instance is the probe.
codeunit 73606 "LT TI XB Login Flag Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure XbFlag_T1_FirstRead_ThenSetFalse()
    var
        Observer: Codeunit "Probe Observer";
        LoginFlag: Codeunit "LT TI XB Login Flag";
    begin
        Observer.Observe('flag', Format(LoginFlag.GetFlag()));
        LoginFlag.SetFlag(false);
        Observer.Finish();
    end;

    [Test]
    procedure XbFlag_T2_AfterSetFalse()
    var
        Observer: Codeunit "Probe Observer";
        LoginFlag: Codeunit "LT TI XB Login Flag";
    begin
        Observer.Observe('flag', Format(LoginFlag.GetFlag()));
        Observer.Finish();
    end;
}
