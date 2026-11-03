// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testrunner-codeunits
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT BA TP Probe (80751)
// Corpus issue 658, the environment of the corpus CI's test runner:
// - which of Microsoft's test framework codeunits are installed (AllObj): the runners 130450 / 130451, "ALTestRunner Reset
//   Environment" 130453, "Test Runner - Mgt" 130454, the command line page's codeunits, and the Tests-TestLibraries codeunits
//   130301 "Reset State Before Test Run", 130302 "Set State Test Run" (the one that lowers permissions for a test whose
//   TestPermissions is not Disabled), 132218 "Permission Test Catalog" and 132553 "Block Changes to System Tables";
// - whether 130453's OnBeforeTestMethodRun subscriber runs before each test: it calls ApplicationArea(''), so an application
//   area set by the first test is gone in the second one.
// Probe: observed values; every literal asserted below is what the BC tier produced.
// BC versions: 27, 28, 29
codeunit 80761 "LT BA TP Env"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('BaTpEnvMsg')]
    procedure BaTpEnv_InstalledFrameworkCodeunits()
    var
        Observer: Codeunit "Probe Observer";
        Probe: Codeunit "LT BA TP Probe";
    begin
        Message('LT BA');
        Observer.Observe('installed', Installed('130450,130451,130452,130453,130454,130455,130301,130302,132218,132553,130440'));
        Observer.Observe('runner', Probe.RunnerFrames());
        Observer.Expect('installed', '130450=yes 130451=yes 130452=yes 130453=yes 130454=yes 130455=yes 130301=no 130302=no 132218=no 132553=no 130440=no ');
        Observer.Expect('runner', '130450,130454,');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BaTpEnvMsg')]
    procedure BaTpEnv_AppArea1_Set()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT BA');
        ApplicationArea('#Basic');
        Observer.Observe('area', ApplicationArea());
        Observer.Expect('area', '#Basic');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BaTpEnvMsg')]
    procedure BaTpEnv_AppArea2_SeenByNextTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT BA');
        Observer.Observe('area', ApplicationArea());
        ApplicationArea('');
        Observer.Expect('area', '');
        Observer.Verify();
    end;

    // Writer QD (al-runtime-rs, AllObj rows of the test libraries): whether Library Assert (130002), Library Variable Storage (131004)
    // and Any (130500) are installed in the corpus environment, and the app that holds each.
    [Test]
    [HandlerFunctions('BaTpEnvMsg')]
    procedure QD_BaTpEnv_InstalledTestLibraries()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('LT BA');
        Observer.Observe('installed', Installed('130002,131004,130500'));
        Observer.Observe('apps', QdApps('130002,131004,130500'));
        Observer.Expect('installed', '130002=no 131004=no 130500=yes ');
        Observer.Expect('apps', '130002= 131004= 130500=Any/Any/Microsoft ');
        Observer.Verify();
    end;

    local procedure QdApps(IdList: Text): Text
    var
        AllObj: Record AllObj;
        InstalledApp: Record "NAV App Installed App";
        IdText: Text;
        Id: Integer;
        Result: Text;
    begin
        foreach IdText in IdList.Split(',') do begin
            Evaluate(Id, IdText);
            Result += IdText + '=';
            if AllObj.Get(AllObj."Object Type"::Codeunit, Id) then begin
                Result += AllObj."Object Name" + '/';
                InstalledApp.SetRange("Package ID", AllObj."App Package ID");
                if InstalledApp.FindFirst() then
                    Result += InstalledApp.Name + '/' + InstalledApp.Publisher
                else
                    Result += '<no app>';
            end;
            Result += ' ';
        end;
        exit(Result);
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

    [MessageHandler]
    procedure BaTpEnvMsg(Msg: Text[1024])
    begin
    end;
}
