// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/moduleinfo/moduleinfo-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); "LT X3 XB Install Log" (61140) written by the install codeunit "LT X3 XB Install" (61141) of cross-app
//   fixture B (al-language-xapp-b/X3XbFirstInstall.al), which calls "LT X3 XA Env Info" (61130) of fixture A (al-language-xapp-a/X3XaEnvInfo.al).
// Probe: al-runner issue 6367 (writer X3). ModuleInfo.DataVersion() and AppVersion() of an app during its own first install, read
//   (a) by the installing app's own code (GetCurrentModuleInfo, GetModuleInfo(own id)) and
//   (b) by a helper in a dependency app: GetModuleInfo(installing app id), GetCallerModuleInfo, and the helper app's own DataVersion;
//   in OnInstallAppPerCompany (PC) and OnInstallAppPerDatabase (PD).
// A version that is not 0.0.0.0 is reported relative to the test-time AppVersion of fixture B (the corpus apps' versions are not asserted).
// Measured (BC 29 SaaS sandbox, fresh install after uninstall with data): during fixture B's first install every reader gets DataVersion 0.0.0.0
//   (Major() 0) for fixture B, its own code AND the dependency's GetModuleInfo(B id) and GetCallerModuleInfo; AppVersion is the normal app version
//   everywhere; the dependency's own DataVersion is its AppVersion (it was installed before). After the install, B's DataVersion is its AppVersion.
// BC versions: 27, 28, 29
codeunit 90800 "LT X3 First Install Versions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FixtureBId(): Guid
    begin
        exit('c87ced6d-11a6-4ad2-87c7-ac10083d0a2f');
    end;

    local procedure Seen(RowCode: Code[40]): Text
    var
        Row: Record "LT X3 XB Install Log";
        Info: ModuleInfo;
    begin
        if not Row.Get(RowCode) then
            exit('<missing>');
        if Row.Txt = '0.0.0.0' then
            exit(Row.Txt);
        NavApp.GetModuleInfo(FixtureBId(), Info);
        if Row.Txt = Format(Info.AppVersion()) then
            exit('test-time AppVersion');
        exit('other: ' + Row.Txt);
    end;

    local procedure ObserveTrigger(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        Observer.Observe(Prefix + ' own GetCurrentModuleInfo DataVersion', Seen(CopyStr(Prefix + ' OWN CURRENT DATA', 1, 40)));
        Observer.Observe(Prefix + ' own GetCurrentModuleInfo AppVersion', Seen(CopyStr(Prefix + ' OWN CURRENT APP', 1, 40)));
        Observer.Observe(Prefix + ' own GetModuleInfo(own id) DataVersion', Seen(CopyStr(Prefix + ' OWN BYID DATA', 1, 40)));
        Observer.Observe(Prefix + ' own GetModuleInfo(own id) AppVersion', Seen(CopyStr(Prefix + ' OWN BYID APP', 1, 40)));
        Observer.Observe(Prefix + ' dependency GetModuleInfo(B id) DataVersion', Seen(CopyStr(Prefix + ' LIB DATA', 1, 40)));
        Observer.Observe(Prefix + ' dependency GetModuleInfo(B id) AppVersion', Seen(CopyStr(Prefix + ' LIB APP', 1, 40)));
        Observer.Observe(Prefix + ' dependency DataVersion().Major()', RawRow(CopyStr(Prefix + ' LIB DATA MAJOR', 1, 40)));
        Observer.Observe(Prefix + ' dependency GetCallerModuleInfo DataVersion', Seen(CopyStr(Prefix + ' LIB CALLER DATA', 1, 40)));
        Observer.Observe(Prefix + ' dependency GetCallerModuleInfo AppVersion', Seen(CopyStr(Prefix + ' LIB CALLER APP', 1, 40)));
        Observer.Observe(Prefix + ' dependency own DataVersion is its test-time AppVersion', OwnLibDataIsAppVersion(CopyStr(Prefix + ' LIB OWN DATA', 1, 40)));
    end;

    local procedure RawRow(RowCode: Code[40]): Text
    var
        Row: Record "LT X3 XB Install Log";
    begin
        if not Row.Get(RowCode) then
            exit('<missing>');
        exit(Row.Txt);
    end;

    local procedure OwnLibDataIsAppVersion(RowCode: Code[40]): Text
    var
        Row: Record "LT X3 XB Install Log";
        Info: ModuleInfo;
    begin
        if not Row.Get(RowCode) then
            exit('<missing>');
        NavApp.GetModuleInfo('cd6a4292-f27b-4af9-89bc-15a5956f5c71', Info);
        exit(Format(Row.Txt = Format(Info.AppVersion())));
    end;

    [Test]
    procedure FirstInstall_PerCompany_OwnCodeAndDependency()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTrigger(Observer, 'PC');
        Observer.Expect('PC own GetCurrentModuleInfo DataVersion', '0.0.0.0');
        Observer.Expect('PC own GetCurrentModuleInfo AppVersion', 'test-time AppVersion');
        Observer.Expect('PC own GetModuleInfo(own id) DataVersion', '0.0.0.0');
        Observer.Expect('PC own GetModuleInfo(own id) AppVersion', 'test-time AppVersion');
        Observer.Expect('PC dependency GetModuleInfo(B id) DataVersion', '0.0.0.0');
        Observer.Expect('PC dependency GetModuleInfo(B id) AppVersion', 'test-time AppVersion');
        Observer.Expect('PC dependency DataVersion().Major()', '0');
        Observer.Expect('PC dependency GetCallerModuleInfo DataVersion', '0.0.0.0');
        Observer.Expect('PC dependency GetCallerModuleInfo AppVersion', 'test-time AppVersion');
        Observer.Expect('PC dependency own DataVersion is its test-time AppVersion', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FirstInstall_PerDatabase_OwnCodeAndDependency()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveTrigger(Observer, 'PD');
        Observer.Expect('PD own GetCurrentModuleInfo DataVersion', '0.0.0.0');
        Observer.Expect('PD own GetCurrentModuleInfo AppVersion', 'test-time AppVersion');
        Observer.Expect('PD own GetModuleInfo(own id) DataVersion', '0.0.0.0');
        Observer.Expect('PD own GetModuleInfo(own id) AppVersion', 'test-time AppVersion');
        Observer.Expect('PD dependency GetModuleInfo(B id) DataVersion', '0.0.0.0');
        Observer.Expect('PD dependency GetModuleInfo(B id) AppVersion', 'test-time AppVersion');
        Observer.Expect('PD dependency DataVersion().Major()', '0');
        Observer.Expect('PD dependency GetCallerModuleInfo DataVersion', '0.0.0.0');
        Observer.Expect('PD dependency GetCallerModuleInfo AppVersion', 'test-time AppVersion');
        Observer.Expect('PD dependency own DataVersion is its test-time AppVersion', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AfterInstall_TestTime_DataVersionIsAppVersion()
    var
        Observer: Codeunit "Probe Observer";
        Info: ModuleInfo;
    begin
        NavApp.GetModuleInfo(FixtureBId(), Info);
        Observer.Observe('fixture B DataVersion equals AppVersion at test time', Format(Format(Info.DataVersion()) = Format(Info.AppVersion())));
        Observer.Observe('fixture B DataVersion is 0.0.0.0 at test time', Format(Format(Info.DataVersion()) = '0.0.0.0'));
        Observer.Expect('fixture B DataVersion equals AppVersion at test time', 'Yes');
        Observer.Expect('fixture B DataVersion is 0.0.0.0 at test time', 'No');
        Observer.Verify();
    end;
}
