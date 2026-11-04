//sub:report
// The request page of Report.Run and Report.RunRequestPage: order of the triggers, what the handler sees, a handler that does not close the page,
// and the actions of the page for a report that is not ProcessingOnly (md:211, md:214, md:215).

codeunit 67727 "W3 Order Log"
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

report 67728 "W3 Order Rpt"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            DataItemTableView = where(Id = filter(1..3));
            RequestFilterFields = Id;

            trigger OnPreDataItem()
            begin
                L.Add('Row pre filter=[' + Row.GetFilter(Id) + ']');
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('Row ' + Format(Row.Id));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('Row post');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(OptCtl; OptVal)
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnInit()
        begin
            L.Add('RP OnInit opt=' + Format(OptVal));
        end;

        trigger OnOpenPage()
        begin
            L.Add('RP OnOpenPage opt=' + Format(OptVal));
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            L.Add('RP OnQueryClosePage action=' + Format(CloseAction) + ' opt=' + Format(OptVal));
            exit(true);
        end;

        trigger OnClosePage()
        begin
            L.Add('RP OnClosePage opt=' + Format(OptVal));
        end;
    }

    var
        OptVal: Integer;
        L: Codeunit "W3 Order Log";

    trigger OnInitReport()
    begin
        OptVal := 11;
        L.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        L.Add('OnPreReport opt=' + Format(OptVal) + ' filter=[' + Row.GetFilter(Id) + ']');
    end;

    trigger OnPostReport()
    begin
        L.Add('OnPostReport');
    end;
}

// Not ProcessingOnly, no layout: the request page has the standard actions of a report that renders.
report 67729 "W3 NonProc Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }

            trigger OnPreDataItem()
            begin
                L.Add('Row pre');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; CtlVal)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        CtlVal: Integer;
        L: Codeunit "W3 Order Log";

    trigger OnPreReport()
    begin
        L.Add('OnPreReport preview=' + Format(CurrReport.Preview()));
    end;
}

codeunit 67730 "W3 Order Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "W3 Order Log";
        Runner: Codeunit "W3 Runner";

    local procedure Seed()
    var
        Row: Record "W3 Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 5 do begin
            Row.Id := I;
            Row.Insert();
        end;
        Commit();
        L.Take();
    end;

    [TryFunction]
    local procedure TryOkVisible(var RP: TestRequestPage "W3 NonProc Rpt"; var Answer: Boolean)
    begin
        Answer := RP.OK().Visible();
    end;

    [TryFunction]
    local procedure TryCancelVisible(var RP: TestRequestPage "W3 NonProc Rpt"; var Answer: Boolean)
    begin
        Answer := RP.Cancel().Visible();
    end;

    [TryFunction]
    local procedure TryPreviewVisible(var RP: TestRequestPage "W3 NonProc Rpt"; var Answer: Boolean)
    begin
        Answer := RP.Preview().Visible();
    end;

    [TryFunction]
    local procedure TryPrintVisible(var RP: TestRequestPage "W3 NonProc Rpt"; var Answer: Boolean)
    begin
        Answer := RP.Print().Visible();
    end;

    [TryFunction]
    local procedure TryInvokePreview(var RP: TestRequestPage "W3 NonProc Rpt")
    begin
        RP.Preview().Invoke();
    end;

    [TryFunction]
    local procedure TryInvokePrint(var RP: TestRequestPage "W3 NonProc Rpt")
    begin
        RP.Print().Invoke();
    end;

    [TryFunction]
    local procedure TryInvokeSchedule(var RP: TestRequestPage "W3 NonProc Rpt")
    begin
        RP.Schedule().Invoke();
    end;

    [TryFunction]
    local procedure TryCancel(var RP: TestRequestPage "W3 NonProc Rpt")
    begin
        RP.Cancel().Invoke();
    end;

    local procedure ActionsLog(var RP: TestRequestPage "W3 NonProc Rpt")
    var
        Answer: Boolean;
    begin
        if TryOkVisible(RP, Answer) then
            L.Add('OK visible=' + Format(Answer))
        else
            L.Add('OK error=' + GetLastErrorText());
        if TryCancelVisible(RP, Answer) then
            L.Add('Cancel visible=' + Format(Answer))
        else
            L.Add('Cancel error=' + GetLastErrorText());
        if TryPreviewVisible(RP, Answer) then
            L.Add('Preview visible=' + Format(Answer))
        else
            L.Add('Preview error=' + GetLastErrorText());
        if TryPrintVisible(RP, Answer) then
            L.Add('Print visible=' + Format(Answer))
        else
            L.Add('Print error=' + GetLastErrorText());
    end;

    // md:214: order of the triggers of a run that shows the page, what the handler sees, and the filter the handler sets.
    [Test]
    [HandlerFunctions('OrderHandler')]
    procedure Run_OrderOfReportAndRequestPageTriggers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 Order Rpt");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit opt=11;RP OnOpenPage opt=11;handler opt=11 view=[1..3];RP OnQueryClosePage action=OK opt=5;RP OnClosePage opt=5;OnPreReport opt=5 filter=[2..5];Row pre filter=[2..5];Row 2;Row 3;Row post;OnPostReport;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OrderHandler(var RP: TestRequestPage "W3 Order Rpt")
    begin
        L.Add('handler opt=' + RP.OptCtl.Value() + ' view=[' + RP.Row.GetFilter(Id) + ']');
        RP.Row.SetFilter(Id, '2..5');
        RP.OptCtl.SetValue(5);
        RP.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('OrderHandler')]
    procedure RunRequestPage_OrderOfReportAndRequestPageTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := Report.RunRequestPage(Report::"W3 Order Rpt");
        Observer.Observe('log', L.Take());
        Observer.Observe('parameters returned', Format(Parameters <> ''));
        Observer.Expect('log', 'OnInitReport;RP OnInit opt=11;RP OnOpenPage opt=11;handler opt=11 view=[1..3];RP OnQueryClosePage action=OK opt=5;RP OnClosePage opt=5;');
        Observer.Expect('parameters returned', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure Run_Cancel_TriggersThatRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Report.Run(Report::"W3 Order Rpt");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit opt=11;RP OnOpenPage opt=11;RP OnQueryClosePage action=Cancel opt=11;RP OnClosePage opt=11;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure CancelHandler(var RP: TestRequestPage "W3 Order Rpt")
    begin
        RP.Cancel().Invoke();
    end;

    // md:214: the caller's SetTableView is in force before the handler reads the view.
    [Test]
    [HandlerFunctions('OrderHandler')]
    procedure Run_SetTableViewOfTheCaller_BeforeTheHandler()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "W3 Order Rpt";
        Row: Record "W3 Row";
    begin
        Seed();
        Row.SetFilter(Id, '4..5');
        Rpt.SetTableView(Row);
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'OnInitReport;RP OnInit opt=11;RP OnOpenPage opt=11;handler opt=11 view=[4..5];RP OnQueryClosePage action=OK opt=5;RP OnClosePage opt=5;OnPreReport opt=5 filter=[2..5];Row pre filter=[2..5];Row 2;Row 3;Row post;OnPostReport;');
        Observer.Verify();
    end;

    // md:215: the handler returns without OK or Cancel.
    [Test]
    [HandlerFunctions('LeaveOpenHandler')]
    procedure Run_HandlerLeavesThePageOpen()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Order Rpt", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'OnInitReport;RP OnInit opt=11;RP OnOpenPage opt=11;handler returns opt=11;RP OnQueryClosePage action=Cancel opt=11;RP OnClosePage opt=11;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure LeaveOpenHandler(var RP: TestRequestPage "W3 Order Rpt")
    begin
        L.Add('handler returns opt=' + RP.OptCtl.Value());
    end;

    [Test]
    [HandlerFunctions('LeaveOpenHandler')]
    procedure RunRequestPage_HandlerLeavesThePageOpen()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 Order Rpt", 2, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('result empty', Format(Result = ''));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('result empty', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'OnInitReport;RP OnInit opt=11;RP OnOpenPage opt=11;handler returns opt=11;RP OnQueryClosePage action=Cancel opt=11;RP OnClosePage opt=11;');
        Observer.Verify();
    end;

    // md:211: the actions of the page that Report.Run opens and of the page that RunRequestPage opens, for a report that is not ProcessingOnly.
    [Test]
    [HandlerFunctions('ActionsHandler')]
    procedure Run_NonProcessingOnly_ActionsOfThePage()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 NonProc Rpt", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('error|code', 'TestActionNotFound');
        Observer.Expect('log', 'OK error=The built-in action = OK is not found on the page.;Cancel visible=Yes;Preview visible=No;Print visible=Yes;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ActionsHandler(var RP: TestRequestPage "W3 NonProc Rpt")
    begin
        ActionsLog(RP);
        if not TryCancel(RP) then
            L.Add('Cancel invoke error=' + GetLastErrorText());
    end;

    [Test]
    [HandlerFunctions('ActionsHandler')]
    procedure RunRequestPage_NonProcessingOnly_ActionsOfThePage()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 NonProc Rpt", 2, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('result empty', Format(Result = ''));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('result empty', 'Yes');
        Observer.Expect('error|text', 'The built-in action = Print is not found on the page.');
        Observer.Expect('error|code', 'TestActionNotFound');
        Observer.Expect('log', 'OK visible=Yes;Cancel visible=Yes;Preview error=The built-in action = Preview is not found on the page.;Print error=The built-in action = Print is not found on the page.;');
        Observer.Verify();
    end;

    // md:215: the Preview, Print and Schedule actions of the request page (not registered in the runtime).
    [Test]
    [HandlerFunctions('PreviewHandler')]
    procedure Run_PreviewActionOfTheRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 NonProc Rpt", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Report 67729 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('error|code', 'ReportNoLayout');
        Observer.Expect('log', 'Preview invoked;Cancel after preview error=The TestPage is not open.;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PreviewHandler(var RP: TestRequestPage "W3 NonProc Rpt")
    begin
        if TryInvokePreview(RP) then
            L.Add('Preview invoked')
        else
            L.Add('Preview error=' + GetLastErrorText());
        if not TryCancel(RP) then
            L.Add('Cancel after preview error=' + GetLastErrorText());
    end;

    [Test]
    [HandlerFunctions('PrintHandler')]
    procedure Run_PrintActionOfTheRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 NonProc Rpt", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Report 67729 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('error|code', 'ReportNoLayout');
        Observer.Expect('log', 'Print invoked;Cancel after print error=The TestPage is not open.;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure PrintHandler(var RP: TestRequestPage "W3 NonProc Rpt")
    begin
        if TryInvokePrint(RP) then
            L.Add('Print invoked')
        else
            L.Add('Print error=' + GetLastErrorText());
        if not TryCancel(RP) then
            L.Add('Cancel after print error=' + GetLastErrorText());
    end;

    [Test]
    [HandlerFunctions('ScheduleHandler')]
    procedure Run_ScheduleActionOfTheRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        Ok: Boolean;
    begin
        Seed();
        Ok := Runner.Exec(Report::"W3 NonProc Rpt", 0, '', Result);
        Observer.Observe('ok', Format(Ok));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Unhandled UI: ModalPage 682');
        Observer.Expect('error|code', 'MissingUIHandler');
        Observer.Expect('log', 'Schedule invoked;Cancel after schedule error=The TestPage is not open.;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ScheduleHandler(var RP: TestRequestPage "W3 NonProc Rpt")
    begin
        if TryInvokeSchedule(RP) then
            L.Add('Schedule invoked')
        else
            L.Add('Schedule error=' + GetLastErrorText());
        if not TryCancel(RP) then
            L.Add('Cancel after schedule error=' + GetLastErrorText());
    end;
}
