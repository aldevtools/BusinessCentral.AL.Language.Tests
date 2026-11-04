// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/requestpage/devenv-oninit-requestpage-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own report 90871, log codeunit 90872 (SingleInstance, used only by test codeunit 90873)
// Probe: written for al-runtime-rs assumption request-page-oninit-at-first-use (writer Y2). handlers/TestReportOnInitReportTiming.al pins that
//        OnInitReport runs at the first use of a report variable. This file reads WHEN the request page's OnInit runs: a procedure of the report
//        called before the run, then a run without and with the request page; the order of OnInitReport, the request page's OnInit and OnOpenPage,
//        the procedure body and OnPreReport, and the global both write.
// Facts (BC 29 SaaS sandbox; the corpus CI legs check the other majors): the first use of the report variable (a procedure call or the run) runs
//        OnInitReport, then the request page's OnInit, before the procedure body. The run does not run OnInit again, with or without the request
//        page; the value the procedure wrote survives into OnOpenPage, the handler and OnPreReport.
// BC versions: 27, 28, 29

report 90871 "LT Y2 RP OnInit"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ModeField; Mode)
                {
                    ApplicationArea = All;
                    Caption = 'Mode';
                }
            }
        }

        trigger OnInit()
        begin
            Log.Add('RP.OnInit mode=' + Format(Mode));
            Mode := 10;
        end;

        trigger OnOpenPage()
        begin
            Log.Add('RP.OnOpenPage mode=' + Format(Mode));
        end;
    }

    trigger OnInitReport()
    begin
        Log.Add('OnInitReport mode=' + Format(Mode));
    end;

    trigger OnPreReport()
    begin
        Log.Add('OnPreReport mode=' + Format(Mode));
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Log.Add('SetMode mode=' + Format(Mode));
        Mode := NewMode;
    end;

    var
        Log: Codeunit "LT Y2 RP Log";
        Mode: Integer;
}

codeunit 90872 "LT Y2 RP Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Joined(): Text
    begin
        exit(Lines);
    end;
}

codeunit 90873 "LT Y2 RP OnInit First Use"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y2 RP Log";

    [Test]
    procedure RequestPage_OnInit_ProcedureThenRunWithoutPage()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y2 RP OnInit";
    begin
        Log.Reset();
        Rep.SetMode(5);
        Observer.Observe('after procedure', Log.Joined());
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('after run', Log.Joined());
        Observer.Expect('after procedure', 'OnInitReport mode=0;RP.OnInit mode=0;SetMode mode=10;');
        Observer.Expect('after run', 'OnInitReport mode=0;RP.OnInit mode=0;SetMode mode=10;OnPreReport mode=5;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RequestPage_OnInit_ProcedureThenRunWithPage()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y2 RP OnInit";
    begin
        Log.Reset();
        Rep.SetMode(5);
        Observer.Observe('after procedure', Log.Joined());
        Rep.UseRequestPage(true);
        Rep.RunModal();
        Observer.Observe('after run', Log.Joined());
        Observer.Expect('after procedure', 'OnInitReport mode=0;RP.OnInit mode=0;SetMode mode=10;');
        Observer.Expect('after run', 'OnInitReport mode=0;RP.OnInit mode=0;SetMode mode=10;RP.OnOpenPage mode=5;handler mode=5;OnPreReport mode=5;');
        Observer.Verify();
    end;

    [Test]
    procedure RequestPage_OnInit_NoProcedureRunWithoutPage()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y2 RP OnInit";
    begin
        Log.Reset();
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('after run', Log.Joined());
        Observer.Expect('after run', 'OnInitReport mode=0;RP.OnInit mode=0;OnPreReport mode=10;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RequestPage_OnInit_NoProcedureRunWithPage()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y2 RP OnInit";
    begin
        Log.Reset();
        Rep.UseRequestPage(true);
        Rep.RunModal();
        Observer.Observe('after run', Log.Joined());
        Observer.Expect('after run', 'OnInitReport mode=0;RP.OnInit mode=0;RP.OnOpenPage mode=10;handler mode=10;OnPreReport mode=10;');
        Observer.Verify();
    end;

    [Test]
    procedure RequestPage_OnInit_TwoProceduresThenRun()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT Y2 RP OnInit";
    begin
        Log.Reset();
        Rep.SetMode(5);
        Rep.SetMode(6);
        Rep.UseRequestPage(false);
        Rep.Run();
        Observer.Observe('log', Log.Joined());
        Observer.Expect('log', 'OnInitReport mode=0;RP.OnInit mode=0;SetMode mode=10;SetMode mode=5;OnPreReport mode=6;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RP: TestRequestPage "LT Y2 RP OnInit")
    begin
        Log.Add('handler mode=' + RP.ModeField.Value());
        RP.OK().Invoke();
    end;
}
