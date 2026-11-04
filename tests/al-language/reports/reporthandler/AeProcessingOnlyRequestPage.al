// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Fixtures used: log codeunit 78213 (AeFixtureP.al, a copy of log 73840 of lt-report-requestpage); Probe Observer (69160); reports 78211 and 78212 below
// Probe: al-runtime-rs corpus topic 206 item 14 (corpus issue 632): a ProcessingOnly report with request page fields and no dataset, run from a test with UseRequestPage(true)
//   by Run and RunModal, without a handler and with a RequestPageHandler; and a ProcessingOnly report that has no requestpage section at all.
//   Report 78211 is the fixture report of lt-report-requestpage with the dataset removed and nothing else changed.
// Object ids 78210 - 78212.

report 78211 "LT AE Plain Request"
{
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(General)
                {
                    field(IntCtl; IntVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Integer Control';
                    }
                    field(TextCtl; TextVal)
                    {
                        ApplicationArea = All;
                        Caption = 'Text Control';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage int=' + Format(IntVal));
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage int=' + Format(IntVal));
        end;
    }

    var
        IntVal: Integer;
        TextVal: Text[30];
        L: Codeunit "LT AE Log P";

    trigger OnInitReport()
    begin
        IntVal := 5;
        L.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('OnPreReport int=' + Format(IntVal) + ' text=[' + TextVal + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('OnPostReport');
    end;
}

report 78212 "LT AE No Request Page"
{
    ProcessingOnly = true;

    var
        L: Codeunit "LT AE Log P";

    trigger OnInitReport()
    begin
        L.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('OnPreReport');
    end;

    trigger OnPostReport()
    begin
        L.Add('OnPostReport');
    end;
}

codeunit 78210 "LT AE Processing Only"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        L: Codeunit "LT AE Log P";

    [Test]
    procedure Plain_NoHandler_Run()
    begin
        L.Take();
        asserterror Report.Run(Report::"LT AE Plain Request");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'Unhandled UI: RequestPage 78211');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('log', 'OnInitReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_NoHandler_RunModal_UseRequestPageTrue()
    var
        Rpt: Report "LT AE Plain Request";
    begin
        L.Take();
        Rpt.UseRequestPage(true);
        asserterror Rpt.RunModal();
        Observer.ObserveError('run modal');
        Observer.Observe('log', L.Take());
        Observer.Expect('run modal|text', 'Unhandled UI: RequestPage 78211');
        Observer.Expect('run modal|code', 'MissingUIHandler');
        Observer.Expect('log', 'OnInitReport;');
        Observer.Verify();
    end;

    [Test]
    procedure Plain_NoHandler_UseRequestPageFalse()
    var
        Rpt: Report "LT AE Plain Request";
    begin
        L.Take();
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;OnPreReport int=5 text=[];OnPostReport;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure Plain_Handler_RunModal()
    var
        Rpt: Report "LT AE Plain Request";
    begin
        L.Take();
        Rpt.UseRequestPage(true);
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnOpenPage int=5;h int=[5] text=[];RP OnClosePage int=9;OnPreReport int=9 text=[typed];OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OkHandler(var RP: TestRequestPage "LT AE Plain Request")
    begin
        L.Add('h int=[' + RP.IntCtl.Value() + '] text=[' + RP.TextCtl.Value() + ']');
        RP.IntCtl.SetValue(9);
        RP.TextCtl.SetValue('typed');
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure Plain_Handler_Cancel()
    var
        Rpt: Report "LT AE Plain Request";
    begin
        L.Take();
        Rpt.UseRequestPage(true);
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnOpenPage int=5;RP OnClosePage int=5;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RP: TestRequestPage "LT AE Plain Request")
    begin
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('LeaveOpenHandler')]
    procedure Plain_Handler_StaticRun_ReturnWithoutClosing()
    begin
        L.Take();
        Report.Run(Report::"LT AE Plain Request");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnOpenPage int=5;h returning;RP OnClosePage int=5;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure LeaveOpenHandler(var RP: TestRequestPage "LT AE Plain Request")
    begin
        L.Add('h returning');
    end;

    [Test]
    procedure NoRequestPage_NoHandler_Run()
    begin
        L.Take();
        asserterror Report.Run(Report::"LT AE No Request Page");
        Observer.ObserveError('run');
        Observer.Observe('log', L.Take());
        Observer.Expect('run|text', 'Unhandled UI: RequestPage 78212');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('log', 'OnInitReport;');
        Observer.Verify();
    end;

    [Test]
    procedure NoRequestPage_NoHandler_RunModal_UseRequestPageTrue()
    var
        Rpt: Report "LT AE No Request Page";
    begin
        L.Take();
        Rpt.UseRequestPage(true);
        asserterror Rpt.RunModal();
        Observer.ObserveError('run modal');
        Observer.Observe('log', L.Take());
        Observer.Expect('run modal|text', 'Unhandled UI: RequestPage 78212');
        Observer.Expect('run modal|code', 'MissingUIHandler');
        Observer.Expect('log', 'OnInitReport;');
        Observer.Verify();
    end;
}
