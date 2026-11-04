// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-report-handlers
// Scope: in-scope
// Fixtures used: report 78217 and log codeunit 78216 (AeFixtureC.al, copies of report 73841 and of log 73840 of lt-report-requestpage), table 73806 (RptFixtures.al); Probe Observer (69160)
// Probe: what a [ReportHandler] function can do with the report variable it receives (Run, RunModal, UseRequestPage, SetTableView, SaveAs, RunRequestPage), each in a test of its own.
// Object id 78201.

codeunit 78201 "LT AE Report Handler Calls"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT AE Log C";
        Mode: Integer;

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

    [ReportHandler]
    procedure CallHandler(var R: Report "LT AE Request C")
    var
        Row: Record "LT RpT Row";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Params: Text;
    begin
        L.Add('handler mode=' + Format(Mode));
        case Mode of
            1:
                begin
                    R.UseRequestPage(false);
                    R.Run();
                end;
            2:
                begin
                    R.UseRequestPage(false);
                    R.RunModal();
                end;
            3:
                begin
                    Row.SetFilter(Id, '2..3');
                    R.SetTableView(Row);
                    R.UseRequestPage(false);
                    R.Run();
                end;
            4:
                begin
                    TempBlob.CreateOutStream(OutS);
                    R.SaveAs('', ReportFormat::Xml, OutS);
                    L.Add('saved length>0=' + Format(TempBlob.Length() > 0));
                end;
            5:
                begin
                    Params := R.RunRequestPage();
                    L.Add('params=[' + Params + ']');
                end;
            6:
                L.Add('use request page=' + Format(R.UseRequestPage()));
            7:
                Error('LT AE handler error');
        end;
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_RunsReport()
    begin
        Seed();
        Mode := 1;
        Report.Run(Report::"LT AE Request C");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler mode=1;OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_RunsReportModal()
    begin
        Seed();
        Mode := 2;
        Report.Run(Report::"LT AE Request C");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler mode=2;OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[];row 1;row 2;row 3;row 4;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_SetTableViewAndRun()
    begin
        Seed();
        Mode := 3;
        Report.Run(Report::"LT AE Request C");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler mode=3;OnPreReport text=[init] int=7 dec=1.5 bool=Yes date=2020-03-02 opt=B fixed=99;row pre filter=[2..3];row 2;row 3;OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_SaveAs()
    begin
        Seed();
        Mode := 4;
        asserterror Report.Run(Report::"LT AE Request C");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'Report 78217 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('run|code', 'ReportProcessingOnly');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler mode=4;');
        Observer.Verify();
    end;

    // Not a test: R.RunRequestPage() inside the handler calls the handler again until BC raises StackOverflow ("There is insufficient memory to execute this function. This can be
    // caused by recursive function calls."); the depth varies, so it is not an oracle and a deep recursion may end a session. Listed as a suspect in the hand-off note.
    procedure Handler_RunRequestPage()
    begin
        Seed();
        Mode := 5;
        asserterror Report.Run(Report::"LT AE Request C");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_UseRequestPageGetter()
    begin
        Seed();
        Mode := 6;
        Report.Run(Report::"LT AE Request C");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler mode=6;use request page=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CallHandler')]
    procedure Handler_RaisesError()
    begin
        Seed();
        Mode := 7;
        asserterror Report.Run(Report::"LT AE Request C");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'LT AE handler error');
        Observer.Expect('run|code', 'Dialog');
        Observer.Expect('log', 'OnInitReport;RP OnInit text=[init] int=7;handler mode=7;');
        Observer.Verify();
    end;
}
