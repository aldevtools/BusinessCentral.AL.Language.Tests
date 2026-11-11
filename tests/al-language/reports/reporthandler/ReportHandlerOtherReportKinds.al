// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-handler-methods
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 96680, codeunit 96681, reports 96682-96684, codeunit 96685.
// Probe: from the trial report al-runner 6924 (a [ReportHandler] for a report that is not processing-only). The processing-only report with
//   a request page is pinned (reports/reporthandler/AeReportHandler.al:31-158). Observation form: every test ends in Observer.Finish(), so
//   its failure message holds BC's values.
// Area: a test binds a [ReportHandler] for (a) a report with a dataset column and a request page (not processing-only), (b) a
//   processing-only report without a request page, (c) a report with a dataset column and no request page. The test runs each with
//   Report.Run, Report.RunModal, and a report variable's Run. Observed: whether the handler is called, which report triggers and request
//   page triggers ran, and the error if the call fails.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

table 96680 "LT RHK Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 96681 "LT RHK Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 96682 "LT RHK Dataset Page"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RHK Row")
        {
            column(RowId; Id) { }

            trigger OnAfterGetRecord()
            begin
                Log.Add('a row');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(NoteCtl; Note) { ApplicationArea = All; }
            }
        }

        trigger OnInit()
        begin
            Log.Add('a page init');
        end;

        trigger OnOpenPage()
        begin
            Log.Add('a page open');
        end;
    }

    trigger OnInitReport()
    begin
        Log.Add('a init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('a pre');
    end;

    var
        Note: Text[30];
        Log: Codeunit "LT RHK Log";
}

report 96683 "LT RHK ProcOnly NoPage"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT RHK Row")
        {
            trigger OnAfterGetRecord()
            begin
                Log.Add('b row');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Log.Add('b init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('b pre');
    end;

    var
        Log: Codeunit "LT RHK Log";
}

report 96684 "LT RHK Dataset NoPage"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RHK Row")
        {
            column(RowId; Id) { }

            trigger OnAfterGetRecord()
            begin
                Log.Add('c row');
            end;
        }
    }

    trigger OnInitReport()
    begin
        Log.Add('c init');
    end;

    trigger OnPreReport()
    begin
        Log.Add('c pre');
    end;

    var
        Log: Codeunit "LT RHK Log";
}

codeunit 96685 "LT RHK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT RHK Log";

    local procedure Seed()
    var
        R: Record "LT RHK Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        Commit();
    end;

    [TryFunction]
    local procedure TryRun(ReportId: Integer; How: Text)
    var
        A: Report "LT RHK Dataset Page";
        B: Report "LT RHK ProcOnly NoPage";
        C: Report "LT RHK Dataset NoPage";
    begin
        case How of
            'run':
                Report.Run(ReportId);
            'runmodal':
                Report.RunModal(ReportId);
            'var run':
                case ReportId of
                    Report::"LT RHK Dataset Page":
                        A.Run();
                    Report::"LT RHK ProcOnly NoPage":
                        B.Run();
                    Report::"LT RHK Dataset NoPage":
                        C.Run();
                end;
        end;
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer)
    var
        How: Text;
        I: Integer;
    begin
        for I := 1 to 3 do begin
            case I of
                1:
                    How := 'run';
                2:
                    How := 'runmodal';
                3:
                    How := 'var run';
            end;
            Log.Take();
            ClearLastError();
            Observer.Observe(Name + ' ' + How, Format(TryRun(ReportId, How)));
            Observer.ObserveError(Name + ' ' + How);
            Observer.Observe(Name + ' ' + How + ' log', Log.Take());
        end;
    end;

    [Test]
    [HandlerFunctions('HandlerA')]
    procedure RHK_DatasetReportWithRequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunCase(Observer, 'a', Report::"LT RHK Dataset Page");
        Observer.Expect('a run', 'Yes');
        Observer.Expect('a run|text', '');
        Observer.Expect('a run|code', '');
        Observer.Expect('a run log', 'a init;a page init;handler a;');
        Observer.Expect('a runmodal', 'Yes');
        Observer.Expect('a runmodal|text', '');
        Observer.Expect('a runmodal|code', '');
        Observer.Expect('a runmodal log', 'a init;a page init;handler a;');
        Observer.Expect('a var run', 'Yes');
        Observer.Expect('a var run|text', '');
        Observer.Expect('a var run|code', '');
        Observer.Expect('a var run log', 'a init;a page init;handler a;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerB')]
    procedure RHK_ProcessingOnlyWithoutRequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunCase(Observer, 'b', Report::"LT RHK ProcOnly NoPage");
        Observer.Expect('b run', 'Yes');
        Observer.Expect('b run|text', '');
        Observer.Expect('b run|code', '');
        Observer.Expect('b run log', 'b init;handler b;');
        Observer.Expect('b runmodal', 'Yes');
        Observer.Expect('b runmodal|text', '');
        Observer.Expect('b runmodal|code', '');
        Observer.Expect('b runmodal log', 'b init;handler b;');
        Observer.Expect('b var run', 'Yes');
        Observer.Expect('b var run|text', '');
        Observer.Expect('b var run|code', '');
        Observer.Expect('b var run log', 'b init;handler b;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandlerC')]
    procedure RHK_DatasetReportWithoutRequestPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RunCase(Observer, 'c', Report::"LT RHK Dataset NoPage");
        Observer.Expect('c run', 'Yes');
        Observer.Expect('c run|text', '');
        Observer.Expect('c run|code', '');
        Observer.Expect('c run log', 'c init;handler c;');
        Observer.Expect('c runmodal', 'Yes');
        Observer.Expect('c runmodal|text', '');
        Observer.Expect('c runmodal|code', '');
        Observer.Expect('c runmodal log', 'c init;handler c;');
        Observer.Expect('c var run', 'Yes');
        Observer.Expect('c var run|text', '');
        Observer.Expect('c var run|code', '');
        Observer.Expect('c var run log', 'c init;handler c;');
        Observer.Verify();
    end;

    [ReportHandler]
    procedure HandlerA(var R: Report "LT RHK Dataset Page")
    begin
        Log.Add('handler a');
    end;

    [ReportHandler]
    procedure HandlerB(var R: Report "LT RHK ProcOnly NoPage")
    begin
        Log.Add('handler b');
    end;

    [ReportHandler]
    procedure HandlerC(var R: Report "LT RHK Dataset NoPage")
    begin
        Log.Add('handler c');
    end;
}
