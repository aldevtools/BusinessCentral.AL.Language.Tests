// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-environment
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// "Environment Information" without any test library: IsSaaS Yes, IsOnPrem Yes, IsSandbox Yes, IsProduction No, GetEnvironmentName 'Sandbox' (the bc-linux container is a sandbox).
// Preview rings (AL Runner issue 6675): IsPreview and IsEarlyPreview of "Environment Information" without a testability flag; the role-center
//   pages "SO Processor Activities" and "O365 Activities" call ShowEarlyPreviewNotification in OnOpenPage, which reads IsEarlyPreview.
// Fixtures used: self-contained codeunit 69340 (the OnPrem app has the sandbox / production switch probe)
// BC versions: 27.5, 29.0

codeunit 69340 "PV Environment Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EnvironmentInformation_Default()
    var
        EnvInfo: Codeunit "Environment Information";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default_is_saas', Format(EnvInfo.IsSaaS()));
        Observer.Observe('default_is_onprem', Format(EnvInfo.IsOnPrem()));
        Observer.Observe('default_is_sandbox', Format(EnvInfo.IsSandbox()));
        Observer.Observe('default_is_production', Format(EnvInfo.IsProduction()));
        Observer.Observe('default_environment_name', '[' + EnvInfo.GetEnvironmentName() + ']');
        Observer.Expect('default_is_saas', 'Yes');
        Observer.Expect('default_is_onprem', 'Yes');
        Observer.Expect('default_is_sandbox', 'Yes');
        Observer.Expect('default_is_production', 'No');
        Observer.Expect('default_environment_name', '[Sandbox]');
        Observer.Verify();
    end;

#if BC28PLUS
    // IsPreview and IsEarlyPreview are new in System Application 28.0 (BC 27.5 fails to compile with AL0132 on IsPreview).
    [TryFunction]
    local procedure TryPreview(Early: Boolean; var Shown: Text)
    var
        EnvInfo: Codeunit "Environment Information";
    begin
        if Early then
            Shown := Format(EnvInfo.IsEarlyPreview())
        else
            Shown := Format(EnvInfo.IsPreview());
    end;
#endif

    [Test]
    procedure EnvironmentInformation_PreviewRings()
    var
        Observer: Codeunit "Probe Observer";
        Shown: Text;
    begin
#if BC28PLUS
        if TryPreview(false, Shown) then
            Observer.Observe('is_preview', Shown)
        else
            Observer.ObserveError('is_preview');
        if TryPreview(true, Shown) then
            Observer.Observe('is_early_preview', Shown)
        else
            Observer.ObserveError('is_early_preview');
        // Measured on BC 28.5 and 29.0 (corpus PR 1211 CI): a container is on no preview ring.
        Observer.Expect('is_preview', 'No');
        Observer.Expect('is_early_preview', 'No');
#endif
        Observer.Verify();
    end;
}
