// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-example
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe (al-runner issue 7142, writer r7142): columns 9 to 15 of platform table "NAV App Installed App" (2000000153) for an installed app:
//   "Compatibility Major/Minor/Build/Revision" (9-12), "Content Hash" (13), "Hash Algorithm" (14) and "Extension Type" (15).
//   Read for this app, for the fixture app it depends on, and for Microsoft's System Application and Base Application.
//   "Content Hash" is reported only as blank or not blank, and the version only as whether its build part is 0.
// Facts (27.5, 28.5 and 29.0 CI containers, the same on each): the four compatibility parts are 0 for every one of these apps, also for
//   System Application and Base Application, whose version parts are not 0: they do not follow the version. "Content Hash" is not blank,
//   "Hash Algorithm" is 1 and "Extension Type" is 2 for all four. The reporter's version text Major.Minor.CompatibilityBuild.CompatibilityRevision
//   therefore ends in .0.0.
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
        ExpectApp(Observer, false);
        Observer.Verify();
    end;

    [Test]
    procedure R7142_FixtureApp_CompatibilityColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveApp(Observer, AppId(FixtureAppIdTok));
        ExpectApp(Observer, false);
        Observer.Verify();
    end;

    [Test]
    procedure R7142_SystemApplication_CompatibilityColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveApp(Observer, AppId(SystemAppIdTok));
        ExpectApp(Observer, true);
        Observer.Verify();
    end;

    [Test]
    procedure R7142_BaseApplication_CompatibilityColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveApp(Observer, AppId(BaseAppIdTok));
        ExpectApp(Observer, true);
        Observer.Verify();
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
        Observer.Expect('built text equals the four version parts', 'Yes');
        Observer.Verify();
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
        Observer.Observe('version build is zero', Format(Installed."Version Build" = 0));
        Observer.Observe('content hash blank', Format(Installed."Content Hash" = ''));
        Observer.Observe('hash algorithm', Format(Installed."Hash Algorithm"));
        Observer.Observe('extension type', Format(Installed."Extension Type"));
    end;

    local procedure Part(Compatibility: Integer; Version: Integer): Text
    begin
        exit(Format(Compatibility));
    end;

    local procedure ExpectApp(var Observer: Codeunit "Probe Observer"; Microsoft: Boolean)
    begin
        Observer.Expect('found', 'Yes');
        Observer.Expect('compatibility major', '0');
        Observer.Expect('compatibility minor', '0');
        Observer.Expect('compatibility build', '0');
        Observer.Expect('compatibility revision', '0');
        Observer.Expect('version build is zero', Format(not Microsoft));
        Observer.Expect('content hash blank', 'No');
        Observer.Expect('hash algorithm', '1');
        Observer.Expect('extension type', '2');
    end;
}
