// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testrunner-codeunits
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BI TP Probe (81551)
// Corpus issue 658, the environment of this app's CI job (Tests-TestLibraries and Data Archive installed):
// - which of Microsoft's test framework codeunits are installed (AllObj): the runners 130450 / 130451, "ALTestRunner Reset
//   Environment" 130453, "Test Runner - Mgt" 130454, the command line page's codeunits, the Tests-TestLibraries codeunits
//   130301 "Reset State Before Test Run", 130302 "Set State Test Run", 132218 "Permission Test Catalog", 130011 "Backup
//   Management", and 132553 "Block Changes to System Tables" (Test Stability Tools app);
// - whether the app 'Data Archive' and 'Tests-TestLibraries' are installed (NAV App Installed App);
// - whether 130453's subscribers run between tests: an application area set by the first test is gone in the second one.
// Probe: observed values; every literal asserted below is what the BC tier produced (corpus CI job test-testlibraries,
// run 39223234414 on BC 29.0; 27.5 and 28.5 by the CI matrix).
// BC versions: 27, 28, 29
codeunit 81552 "LT BI TP Env"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('BiTpEnvMsg')]
    procedure BiTpEnv_InstalledFrameworkCodeunits()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BI TP Probe";
    begin
        Message('LT BI');
        Observer.Observe('installed', Installed('130450,130451,130452,130453,130454,130455,130301,130302,132218,132217,130011,132553,130440'));
        Observer.Observe('apps', InstalledApps());
        Observer.Observe('runner', Probe.RunnerFrames());
        Observer.Expect('installed', '130450=yes 130451=yes 130452=yes 130453=yes 130454=yes 130455=yes 130301=yes 130302=yes 132218=yes 132217=yes 130011=yes 132553=no 130440=yes ');
        Observer.Expect('apps', 'Tests-TestLibraries=yes Data Archive=yes Permissions Mock=yes Test Stability Tools=no ');
        Observer.Expect('runner', '130450,130454,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiTpEnvMsg')]
    procedure BiTpEnv_AppArea1_Set()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT BI');
        ApplicationArea('#Basic');
        Observer.Observe('area', ApplicationArea());
        Observer.Expect('area', '#Basic');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BiTpEnvMsg')]
    procedure BiTpEnv_AppArea2_SeenByNextTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT BI');
        Observer.Observe('area', ApplicationArea());
        ApplicationArea('');
        Observer.Expect('area', '');
        Observer.Verify();
    end;

    local procedure Installed(IdList: Text): Text
    var
        AllObj: Record AllObj;
        IdText: Text;
        Id: Integer;
        Result: Text;
    begin
        foreach IdText in IdList.Split(',') do begin
            Evaluate(Id, IdText);
            if AllObj.Get(AllObj."Object Type"::Codeunit, Id) then
                Result += IdText + '=yes '
            else
                Result += IdText + '=no ';
        end;
        exit(Result);
    end;

    local procedure InstalledApps(): Text
    var
        InstalledApp: Record "NAV App Installed App";
        Names: List of [Text];
        AppName: Text;
        Result: Text;
    begin
        Names.Add('Tests-TestLibraries');
        Names.Add('Data Archive');
        Names.Add('Permissions Mock');
        Names.Add('Test Stability Tools');
        foreach AppName in Names do begin
            InstalledApp.SetRange(Name, AppName);
            if InstalledApp.IsEmpty() then
                Result += AppName + '=no '
            else
                Result += AppName + '=yes ';
        end;
        exit(Result);
    end;

    [MessageHandler]
    procedure BiTpEnvMsg(Msg: Text[1024])
    begin
    end;
}
