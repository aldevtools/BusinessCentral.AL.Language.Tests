// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-example
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe (al-runner issue 7142, writer r7142): columns 9 to 15 of platform table "NAV App Installed App" (2000000153) for an installed app:
//   "Compatibility Major/Minor/Build/Revision" (9-12), "Content Hash" (13), "Hash Algorithm" (14) and "Extension Type" (15).
//   Read for this app, for the fixture app it depends on, and for Microsoft's System Application and Base Application.
//   A compatibility part is reported as 'version' when it equals the same part of the app's own version (columns 5-8), else as its value,
//   so no app or platform version is asserted. "Content Hash" is reported only as blank or not blank.
// BC versions: 27.0+

codeunit 95990 "LT R7142 Installed Compat"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureAppIdTok: Label '{f1e2d3c4-b5a6-7890-fedc-ba9876543210}', Locked = true;
        SystemAppIdTok: Label '{63ca2fa4-4f03-4f2b-a480-172fef340d3f}', Locked = true;
        BaseAppIdTok: Label '{437dbf0e-84ff-417a-965d-ed2bb9650972}', Locked = true;

    [Test]
    procedure R7142_ThisApp_CompatibilityColumns()
    var
        Observer: Codeunit "Probe Observer";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        ObserveApp(Observer, ThisModule.Id());
        Observer.Finish();
    end;

    [Test]
    procedure R7142_FixtureApp_CompatibilityColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveApp(Observer, AppId(FixtureAppIdTok));
        Observer.Finish();
    end;

    [Test]
    procedure R7142_SystemApplication_CompatibilityColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveApp(Observer, AppId(SystemAppIdTok));
        Observer.Finish();
    end;

    [Test]
    procedure R7142_BaseApplication_CompatibilityColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveApp(Observer, AppId(BaseAppIdTok));
        Observer.Finish();
    end;

    [Test]
    procedure R7142_ThisApp_VersionTextAsInstallCodeBuildsIt()
    // The reporter's install code: StrSubstNo('%1.%2.%3.%4', Major, Minor, Compatibility Build, Compatibility Revision).
    var
        Observer: Codeunit "Probe Observer";
        Installed: Record "NAV App Installed App";
        ThisModule: ModuleInfo;
        Built: Text;
        FromVersion: Text;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Installed.Get(ThisModule.Id());
        Built := StrSubstNo('%1.%2.%3.%4', Installed."Version Major", Installed."Version Minor", Installed."Compatibility Build", Installed."Compatibility Revision");
        FromVersion := StrSubstNo('%1.%2.%3.%4', Installed."Version Major", Installed."Version Minor", Installed."Version Build", Installed."Version Revision");
        Observer.Observe('built text equals the four version parts', Format(Built = FromVersion));
        Observer.Finish();
    end;

    local procedure AppId(IdText: Text): Guid
    var
        Id: Guid;
    begin
        Evaluate(Id, IdText);
        exit(Id);
    end;

    local procedure ObserveApp(var Observer: Codeunit "Probe Observer"; Id: Guid)
    var
        Installed: Record "NAV App Installed App";
    begin
        Observer.Observe('found', Format(Installed.Get(Id)));
        Observer.Observe('compatibility major', Part(Installed."Compatibility Major", Installed."Version Major"));
        Observer.Observe('compatibility minor', Part(Installed."Compatibility Minor", Installed."Version Minor"));
        Observer.Observe('compatibility build', Part(Installed."Compatibility Build", Installed."Version Build"));
        Observer.Observe('compatibility revision', Part(Installed."Compatibility Revision", Installed."Version Revision"));
        Observer.Observe('content hash blank', Format(Installed."Content Hash" = ''));
        Observer.Observe('hash algorithm', Format(Installed."Hash Algorithm"));
        Observer.Observe('extension type', Format(Installed."Extension Type"));
    end;

    local procedure Part(Compatibility: Integer; Version: Integer): Text
    begin
        if Compatibility = Version then
            exit('version');
        exit(Format(Compatibility));
    end;
}
