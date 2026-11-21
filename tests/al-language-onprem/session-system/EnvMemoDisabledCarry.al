// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-environment
// Scope: in-scope (OnPrem app: the "Environment Info Test Library" procedures are Scope = OnPrem)
// Fixtures used: Probe Observer (69160); XApp A tests/al-language-xapp-a/TiXaIsSaaSLogin.al (subscriber 98488 of
//   "System Initialization".OnAfterLogin calls EnvironmentInformation.IsSaaS(); every CI job publishes XApp A, so a login IsSaaS
//   subscriber is always in the workspace here); self-contained codeunits 98955-98964.
// Probe (AL Runner, disabled-reach-login check 2): "Environment Information Impl." (3702, SingleInstance) holds the testability
//   flags (Sandbox, SoftwareAsAService, Preview, EarlyPreview) and the IsSaaS / IsSandbox memo that the login fills. Does what one
//   test codeunit leaves in 3702 reach the NEXT test codeunit, and does the RequiredTestIsolation (Disabled or Codeunit) of the
//   setter or of the reader change that? Each pair is a setter codeunit (sets all four flags to true, then calls IsSaaS and IsSandbox,
//   which fills the memo) followed by a reader codeunit (the next id; reads first, then sets all four flags back to false). The
//   codeunits run in id order: 98955 control, 98956 / 98957 Disabled -> Disabled, 98958 / 98959 Disabled -> Codeunit,
//   98960 / 98961 Codeunit -> Disabled, 98962 / 98963 Codeunit -> Codeunit. IsPreview and IsEarlyPreview are No on the corpus
//   tiers without a flag, so they show whether the flags carried. IsSaaS and IsSandbox are Yes on these sandbox tiers either way
//   (PVEnvironmentTestability.al), so they do NOT tell a carried memo from a fresh one; they are observed for completeness only.
//   IsSaaSInfrastructure is read only after the SaaS flag was set in the same test (its native value differs per tier).
// BC versions: 27 - 29
codeunit 98964 "LT DM Env Probe"
{
    procedure SetFlags(Value: Boolean)
    var
        EnvTestLib: Codeunit "Environment Info Test Library";
    begin
        EnvTestLib.SetTestabilitySandbox(Value);
        EnvTestLib.SetTestabilitySoftwareAsAService(Value);
        EnvTestLib.SetTestabilityPreview(Value);
        EnvTestLib.SetTestabilityEarlyPreview(Value);
    end;

    procedure ObserveFlags(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        EnvInfo: Codeunit "Environment Information";
    begin
        Observer.Observe(Prefix + '_is_preview', Format(EnvInfo.IsPreview()));
        Observer.Observe(Prefix + '_is_early_preview', Format(EnvInfo.IsEarlyPreview()));
        Observer.Observe(Prefix + '_is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe(Prefix + '_is_sandbox', Format(EnvInfo.IsSandbox()));
    end;
}

codeunit 98955 "LT DM Control Read"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure Control_NoSetterBefore_Read()
    var
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.ObserveFlags(Observer, 'control');
        Observer.Finish();
    end;
}

codeunit 98956 "LT DM Disabled Set"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure DisabledSet_T1_SetFlags_FillMemo()
    var
        EnvInfo: Codeunit "Environment Information";
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.SetFlags(true);
        Observer.Observe('after_set_is_saas_infrastructure', Format(EnvInfo.IsSaaSInfrastructure()));
        EnvProbe.ObserveFlags(Observer, 'after_set');
        Observer.Finish();
    end;

    [Test]
    procedure DisabledSet_T2_NextTest_Read()
    var
        EnvInfo: Codeunit "Environment Information";
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.ObserveFlags(Observer, 'next_test');
        Observer.Observe('next_test_is_saas_infrastructure', Format(EnvInfo.IsSaaSInfrastructure()));
        Observer.Finish();
    end;
}

codeunit 98957 "LT DM Disabled Read"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure DisabledRead_AfterDisabledSet()
    var
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.ObserveFlags(Observer, 'next_codeunit');
        EnvProbe.SetFlags(false);
        EnvProbe.ObserveFlags(Observer, 'after_reset');
        Observer.Finish();
    end;
}

codeunit 98958 "LT DM Disabled Set B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure DisabledSetB_SetFlags_FillMemo()
    var
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.SetFlags(true);
        EnvProbe.ObserveFlags(Observer, 'after_set');
        Observer.Finish();
    end;
}

codeunit 98959 "LT DM Codeunit Read"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure CodeunitRead_AfterDisabledSet()
    var
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.ObserveFlags(Observer, 'next_codeunit');
        EnvProbe.SetFlags(false);
        EnvProbe.ObserveFlags(Observer, 'after_reset');
        Observer.Finish();
    end;
}

codeunit 98960 "LT DM Codeunit Set"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure CodeunitSet_SetFlags_FillMemo()
    var
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.SetFlags(true);
        EnvProbe.ObserveFlags(Observer, 'after_set');
        Observer.Finish();
    end;
}

codeunit 98961 "LT DM Disabled Read B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    [Test]
    procedure DisabledReadB_AfterCodeunitSet()
    var
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.ObserveFlags(Observer, 'next_codeunit');
        EnvProbe.SetFlags(false);
        EnvProbe.ObserveFlags(Observer, 'after_reset');
        Observer.Finish();
    end;
}

codeunit 98962 "LT DM Codeunit Set B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure CodeunitSetB_SetFlags_FillMemo()
    var
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.SetFlags(true);
        EnvProbe.ObserveFlags(Observer, 'after_set');
        Observer.Finish();
    end;
}

codeunit 98963 "LT DM Codeunit Read B"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    [Test]
    procedure CodeunitReadB_AfterCodeunitSet()
    var
        EnvProbe: Codeunit "LT DM Env Probe";
        Observer: Codeunit "Probe Observer";
    begin
        EnvProbe.ObserveFlags(Observer, 'next_codeunit');
        EnvProbe.SetFlags(false);
        EnvProbe.ObserveFlags(Observer, 'after_reset');
        Observer.Finish();
    end;
}
