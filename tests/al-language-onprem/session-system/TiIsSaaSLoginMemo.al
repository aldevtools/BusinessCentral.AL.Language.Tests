// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-environment
// Scope: in-scope (OnPrem app: the "Environment Info Test Library" procedures are Scope = OnPrem)
// Fixtures used: Probe Observer (69160); XApp A tests/al-language-xapp-a/TiXaIsSaaSLogin.al (subscriber 98488 of "System Initialization".OnAfterLogin
//   calls EnvironmentInformation.IsSaaS(), which fills the memo globals of "Environment Information Impl.").
// Probe (al-runner issue 8239): the first statement of the test is SetTestabilitySandbox(true), then IsSaaS(). IsSaaS() fills its memo with
//   IsSandbox() or the membership entitlement setting on its first call; with TestabilitySandbox set, an empty memo gives Yes. No means the
//   memo the login filled stayed in the test session; Yes means an empty memo or a tier that is a sandbox anyway.
// BC result (measured on BC 28.5 and 27.5): IsSaaS() and IsSandbox() are Yes after SetTestabilitySandbox(true) and still Yes after
//   SetTestabilitySandbox(false). The corpus hosts are sandboxes (IsSandbox() is natively Yes), so this cell does NOT tell the login memo
//   apart from an empty memo: it pins only these values on a sandbox tier.
// BC versions: 27 - 29
codeunit 98994 "LT TI IsSaaS Login Memo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IsSaaS_AfterSetTestabilitySandbox_FirstStatement()
    var
        EnvInfo: Codeunit "Environment Information";
        EnvTestLib: Codeunit "Environment Info Test Library";
        Observer: Codeunit "Probe Observer";
    begin
        EnvTestLib.SetTestabilitySandbox(true);
        Observer.Observe('sandbox_true_is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe('sandbox_true_is_sandbox', Format(EnvInfo.IsSandbox()));
        EnvTestLib.SetTestabilitySandbox(false);
        Observer.Observe('sandbox_false_is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe('sandbox_false_is_sandbox', Format(EnvInfo.IsSandbox()));
        Observer.Expect('sandbox_true_is_saas', 'Yes');
        Observer.Expect('sandbox_true_is_sandbox', 'Yes');
        Observer.Expect('sandbox_false_is_saas', 'Yes');
        Observer.Expect('sandbox_false_is_sandbox', 'Yes');
        Observer.Verify();
    end;
}
