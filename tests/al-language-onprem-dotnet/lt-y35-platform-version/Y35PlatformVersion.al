// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet) whose compile finds the BC service tier assemblies (see lt-bb-dotnet/BbNavHelpers.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; DotNet alias LtBbTenantSettings
//   (NavTenantSettingsHelper, declared in lt-bb-dotnet/BbNavHelpers.al); codeunit "Application System Constants" (System Application)
// Probe (gap cycle 3, C3-04): what NavTenantSettingsHelper.GetPlatformVersion() returns, the shape the Base Application reaches it in
//   (CRMIntegrationManagement CheckSolutionVersionOutdated: Version.CompareTo(GetPlatformVersion()); LibraryCRMIntegration
//   GetLastestSDKVersion: CompareTo against 16.0.11346.0 and 21.0.43087.0): the version parts, how it compares, and how it relates to
//   Application System Constants.PlatformFileVersion(). The build and revision numbers change with the container build, so only their
//   relation to PlatformFileVersion is asserted.
// BC versions: 27.5, 28.5, 29.0
dotnet
{
    assembly("mscorlib")
    {
        type("System.Version"; LtY35Version) { }
    }
}

codeunit 99478 "LT Y35 Platform Version"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryGetPlatformVersion(var Version: DotNet LtY35Version)
    var
        Helper: DotNet LtBbTenantSettings;
    begin
        Version := Helper.GetPlatformVersion();
    end;

    [Test]
    procedure C304_GetPlatformVersion()
    var
        Version: DotNet LtY35Version;
        Other: DotNet LtY35Version;
        AppConstants: Codeunit "Application System Constants";
        Shown: Text;
    begin
        if not TryGetPlatformVersion(Version) then begin
            Observer.ObserveError('get');
            Observer.Finish();
        end;
        Observer.Observe('is_null', Format(IsNull(Version)));
        Observer.Observe('major', Format(Version.Major));
        Observer.Observe('minor', Format(Version.Minor));
        Observer.Observe('build_positive', Format(Version.Build > 0));
        Observer.Observe('revision_not_negative', Format(Version.Revision >= 0));
        Shown := Version.ToString();
        Observer.Observe('raw_tostring', Shown);
        Observer.Observe('raw_platform_file_version', AppConstants.PlatformFileVersion());
        Observer.Observe('tostring_equals_platform_file_version', Format(Shown = AppConstants.PlatformFileVersion()));
        Observer.Observe('format_equals_tostring', Format(Format(Version) = Shown));
        Other := Other.Parse('21.0.43087.0');
        Observer.Observe('compare_21_0_43087_0', Format(Version.CompareTo(Other)));
        Observer.Observe('older_compare_platform', Format(Other.CompareTo(Version)));
        Other := Other.Parse(Shown);
        Observer.Observe('compare_parsed_self', Format(Version.CompareTo(Other)));
        Observer.Observe('equals_parsed_self', Format(Version.Equals(Other)));
        Observer.Finish();
    end;
}
