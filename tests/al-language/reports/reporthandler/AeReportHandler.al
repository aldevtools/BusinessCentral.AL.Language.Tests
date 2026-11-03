// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-report-handlers
// Scope: in-scope
// Fixtures used: reports 78215 and 78218 and log codeunit 78214 (AeFixtureH.al, copies of reports 73841 and 73843 and of log 73840 of lt-report-requestpage), table 73806 (RptFixtures.al); Probe Observer (69160). Log 78214 is Taken at the start of each test.
// Probe: al-runtime-rs corpus topic 206 items 9 and 11 (corpus issue 632): [ReportHandler] functions for a report run from a test (Run, RunModal, Execute, SaveAs,
//   RunRequestPage, a handler of another report, ReportHandler and RequestPageHandler on the same test), and SetFilter(Field, '') on a data item filter of a TestRequestPage.
// A [HandlerFunctions] entry that the test never executes fails the test: "The following UI handlers were not executed: <name>" (seen for every handler of a run that does not call it; not assertable from AL).
// Object ids 78200, 78201.

codeunit 78200 "LT AE Report Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT AE Log H";

    local procedure Seed()
    var
        Row: Record "LT RpT Row";
        I: Integer;
    begin
        Row.DeleteAll();
        L.Take();
        for I := 1 to 4 do begin
            Row.Id := I;
            Row.Grp := 1;
            Row.Insert();
        end;
        Commit();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_StaticCall()
    begin
        Seed();
        Report.Run(Report::"LT AE Request H");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler;');
        Observer.Verify();
    end;

    [ReportHandler]
    procedure PlainHandler(var R: Report "LT AE Request H")
    begin
        L.Add('handler');
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_VariableRun()
    var
        Rpt: Report "LT AE Request H";
    begin
        Seed();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_VariableRunModal()
    var
        Rpt: Report "LT AE Request H";
    begin
        Seed();
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_UseRequestPageFalse()
    var
        Rpt: Report "LT AE Request H";
    begin
        Seed();
        Rpt.UseRequestPage(false);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_UseRequestPageTrue()
    var
        Rpt: Report "LT AE Request H";
    begin
        Seed();
        Rpt.UseRequestPage(true);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure Run_Twice_HandlerCalledTwice()
    begin
        Seed();
        Report.Run(Report::"LT AE Request H");
        Report.Run(Report::"LT AE Request H");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler;OnInitReport;RP OnInit text=[init] int=7;handler;');
        Observer.Verify();
    end;

    [Test]
    procedure Execute_WithReportHandler()
    begin
        Seed();
        Report.Execute(Report::"LT AE Request H", '');
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_WithReportHandler()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Ok := Report.SaveAs(Report::"LT AE Request H", '', ReportFormat::Xml, OutS);
        Observer.Observe('result', Format(Ok));
        Observer.Observe('log', L.Take());
        Observer.Observe('length', Format(TempBlob.Length()));
        Observer.Expect('result', 'No');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;');
        Observer.Expect('length', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PlainHandler')]
    procedure RunRequestPage_WithReportHandler()
    var
        Params: Text;
    begin
        Seed();
        Params := Report.RunRequestPage(Report::"LT AE Request H");
        Observer.Observe('params', Params);
        Observer.Observe('log', L.Take());
        Observer.Expect('params', '');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler;');
        Observer.Verify();
    end;

    [Test]
    procedure Run_UseRequestPageFalseReport_NoHandlerCall()
    var
        Rpt: Report "LT AE Request Skipped H";
    begin
        Seed();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'Skipped OnPreReport val=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SetFilterHandler')]
    procedure TestRequestPage_SetFilterEmpty_ClearsFilter()
    begin
        Seed();
        Report.Run(Report::"LT AE Request H");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;start=[];range=[2..3];cleared=[];or=[1|4];cleared again=[];RP OnQueryClosePage action=OK text=[init];RP OnClosePage text=[init];OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetFilterHandler(var RP: TestRequestPage "LT AE Request H")
    begin
        L.Add('start=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '2..3');
        L.Add('range=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '');
        L.Add('cleared=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '1|4');
        L.Add('or=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '');
        L.Add('cleared again=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetFilterOnlyEmptyHandler')]
    procedure TestRequestPage_SetFilterEmpty_OnUntouchedFilter()
    begin
        Seed();
        Report.Run(Report::"LT AE Request H");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;empty=[];RP OnQueryClosePage action=OK text=[init];RP OnClosePage text=[init];OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetFilterOnlyEmptyHandler(var RP: TestRequestPage "LT AE Request H")
    begin
        RP.Row.SetFilter(Id, '');
        L.Add('empty=[' + RP.Row.GetFilter(Id) + ']');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetFilterTextHandler')]
    procedure TestRequestPage_SetFilterEmpty_ThenReportRows()
    begin
        Seed();
        Report.Run(Report::"LT AE Request H");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;RP OnOpenPage text=[init] int=7;RP OnQueryClosePage action=OK text=[init];RP OnClosePage text=[init];OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SetFilterTextHandler(var RP: TestRequestPage "LT AE Request H")
    begin
        RP.Row.SetFilter(Id, '2..3');
        RP.Row.SetFilter(Id, '');
        RP.OK().Invoke();
    end;
}
