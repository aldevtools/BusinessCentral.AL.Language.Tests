// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-userequestpage-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// local object: the report's own triggers are under test (log 62300, reports 62301 and 62302).
// Area: reading UseRequestPage inside a running report (al-runner issues 7413 and 7414).
//   Spellings: bare without parentheses (`UseRequestPage`), bare with parentheses (`UseRequestPage()`), `CurrReport.UseRequestPage()`.
//   Triggers: OnInitReport, request page OnOpenPage, OnPreReport, OnPreDataItem, OnAfterGetRecord, OnPostDataItem, OnPostReport.
//   Callers: a report variable with Run and RunModal, with the default, after UseRequestPage(false) and after UseRequestPage(true);
//   static Report.Run and Report.RunModal with RequestWindow false and true; Report.Execute with empty parameters and with the
//   parameters RunRequestPage returned; a report with the property UseRequestPage = false.
// Already pinned elsewhere: the bare getter with parentheses and CurrReport.UseRequestPage() in OnPreReport
//   (reports/bare-report-member/Y36BareReportMember.al, reports/request-page/P147UseRequestPagePreGet.al). Not pinned before: the
//   data item triggers, OnPostReport, the request page trigger, the spelling without parentheses, Execute.
// No test writes to the database before a run that opens the request page (a write before it stops the transaction).
// BC versions: 27-29
codeunit 62300 "RPT UseRp Read Log"
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

report 62301 "RPT UseRp Read A"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            begin
                // The shape of issue 7413: read with parentheses in a condition of a data item trigger.
                if not UseRequestPage() or not GuiAllowed() then
                    L.Add('predataitem cond=first')
                else
                    L.Add('predataitem cond=second');
                L.Add('predataitem ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('aftergetrecord ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
            end;

            trigger OnPostDataItem()
            begin
                L.Add('postdataitem ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(FlagCtl; Flag)
                {
                    ApplicationArea = All;
                    Caption = 'Flag';
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('rp open ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
        end;
    }

    trigger OnInitReport()
    begin
        L.Add('init ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
    end;

    trigger OnPreReport()
    begin
        // The shape of issue 7414: read without parentheses in a condition of OnPreReport.
        if not UseRequestPage then
            L.Add('pre cond=not')
        else
            L.Add('pre cond=else');
        L.Add('pre ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
    end;

    trigger OnPostReport()
    begin
        L.Add('post ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
    end;

    var
        Flag: Boolean;
        L: Codeunit "RPT UseRp Read Log";

    local procedure Three(Bare: Boolean; Called: Boolean; Curr: Boolean): Text
    begin
        exit(Format(Bare) + '/' + Format(Called) + '/' + Format(Curr));
    end;
}

report 62302 "RPT UseRp Read B"
{
    ProcessingOnly = true;
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(One; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            begin
                L.Add('predataitem ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
            end;

            trigger OnAfterGetRecord()
            begin
                L.Add('aftergetrecord ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(FlagCtl; Flag)
                {
                    ApplicationArea = All;
                    Caption = 'Flag';
                }
            }
        }

        trigger OnOpenPage()
        begin
            L.Add('rp open ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
        end;
    }

    trigger OnPreReport()
    begin
        L.Add('pre ' + Three(UseRequestPage, UseRequestPage(), CurrReport.UseRequestPage()));
    end;

    var
        Flag: Boolean;
        L: Codeunit "RPT UseRp Read Log";

    local procedure Three(Bare: Boolean; Called: Boolean; Curr: Boolean): Text
    begin
        exit(Format(Bare) + '/' + Format(Called) + '/' + Format(Curr));
    end;
}

codeunit 62303 "RPT UseRp Read Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "RPT UseRp Read Log";

    local procedure Start()
    begin
        L.Take();
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryRunVar(SetIt: Boolean; NewValue: Boolean; Modal: Boolean)
    var
        Rpt: Report "RPT UseRp Read A";
    begin
        if SetIt then
            Rpt.UseRequestPage(NewValue);
        if Modal then
            Rpt.RunModal()
        else
            Rpt.Run();
    end;

    [TryFunction]
    local procedure TryRunStatic(ReportId: Integer; RequestWindow: Boolean; Modal: Boolean)
    begin
        if Modal then
            Report.RunModal(ReportId, RequestWindow)
        else
            Report.Run(ReportId, RequestWindow);
    end;

    [TryFunction]
    local procedure TryExecute(ReportId: Integer; Parameters: Text)
    begin
        Report.Execute(ReportId, Parameters);
    end;

    [TryFunction]
    local procedure TryRunVarB(SetIt: Boolean; NewValue: Boolean)
    var
        Rpt: Report "RPT UseRp Read B";
    begin
        if SetIt then
            Rpt.UseRequestPage(NewValue);
        Rpt.RunModal();
    end;

    [Test]
    procedure UseRp_Read_VariableSetFalse_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('ok', Format(TryRunVar(true, false, false)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'init Yes/Yes/Yes;pre cond=not;pre No/No/No;predataitem cond=first;predataitem No/No/No;aftergetrecord No/No/No;postdataitem No/No/No;post No/No/No;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRp_Read_VariableSetFalse_RunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('ok', Format(TryRunVar(true, false, true)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'init Yes/Yes/Yes;pre cond=not;pre No/No/No;predataitem cond=first;predataitem No/No/No;aftergetrecord No/No/No;postdataitem No/No/No;post No/No/No;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRp_Read_StaticRunFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('ok', Format(TryRunStatic(Report::"RPT UseRp Read A", false, false)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'init Yes/Yes/Yes;pre cond=not;pre No/No/No;predataitem cond=first;predataitem No/No/No;aftergetrecord No/No/No;postdataitem No/No/No;post No/No/No;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRp_Read_StaticRunModalFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('ok', Format(TryRunStatic(Report::"RPT UseRp Read A", false, true)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'init Yes/Yes/Yes;pre cond=not;pre No/No/No;predataitem cond=first;predataitem No/No/No;aftergetrecord No/No/No;postdataitem No/No/No;post No/No/No;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandlerA')]
    procedure UseRp_Read_VariableDefault_Run_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "RPT UseRp Read A";
    begin
        Start();
        Rpt.Run();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'init Yes/Yes/Yes;rp open Yes/Yes/Yes;handler ok;pre cond=else;pre Yes/Yes/Yes;predataitem cond=second;predataitem Yes/Yes/Yes;aftergetrecord Yes/Yes/Yes;postdataitem Yes/Yes/Yes;post Yes/Yes/Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandlerA')]
    procedure UseRp_Read_VariableDefault_RunModal_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "RPT UseRp Read A";
    begin
        Start();
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'init Yes/Yes/Yes;rp open Yes/Yes/Yes;handler ok;pre cond=else;pre Yes/Yes/Yes;predataitem cond=second;predataitem Yes/Yes/Yes;aftergetrecord Yes/Yes/Yes;postdataitem Yes/Yes/Yes;post Yes/Yes/Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandlerA')]
    procedure UseRp_Read_VariableSetTrue_RunModal_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "RPT UseRp Read A";
    begin
        Start();
        Rpt.UseRequestPage(true);
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'init Yes/Yes/Yes;rp open Yes/Yes/Yes;handler ok;pre cond=else;pre Yes/Yes/Yes;predataitem cond=second;predataitem Yes/Yes/Yes;aftergetrecord Yes/Yes/Yes;postdataitem Yes/Yes/Yes;post Yes/Yes/Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandlerA')]
    procedure UseRp_Read_StaticRunTrue_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.Run(Report::"RPT UseRp Read A", true);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'init Yes/Yes/Yes;rp open Yes/Yes/Yes;handler ok;pre cond=else;pre Yes/Yes/Yes;predataitem cond=second;predataitem Yes/Yes/Yes;aftergetrecord Yes/Yes/Yes;postdataitem Yes/Yes/Yes;post Yes/Yes/Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandlerA')]
    procedure UseRp_Read_StaticRunModalTrue_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Report.RunModal(Report::"RPT UseRp Read A", true);
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'init Yes/Yes/Yes;rp open Yes/Yes/Yes;handler ok;pre cond=else;pre Yes/Yes/Yes;predataitem cond=second;predataitem Yes/Yes/Yes;aftergetrecord Yes/Yes/Yes;postdataitem Yes/Yes/Yes;post Yes/Yes/Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelHandlerA')]
    procedure UseRp_Read_VariableDefault_RunModal_RequestPageCancel()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "RPT UseRp Read A";
    begin
        Start();
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'init Yes/Yes/Yes;rp open Yes/Yes/Yes;handler cancel;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRp_Read_ExecuteEmptyParameters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('ok', Format(TryExecute(Report::"RPT UseRp Read A", '')));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'init Yes/Yes/Yes;pre cond=not;pre No/No/No;predataitem cond=first;predataitem No/No/No;aftergetrecord No/No/No;postdataitem No/No/No;post No/No/No;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandlerA')]
    procedure UseRp_Read_RunRequestPageThenExecute()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Start();
        Parameters := Report.RunRequestPage(Report::"RPT UseRp Read A");
        Observer.Observe('request page log', L.Take());
        Observer.Observe('has parameters', Format(Parameters <> ''));
        Observer.Observe('ok', Format(TryExecute(Report::"RPT UseRp Read A", Parameters)));
        Observer.ObserveError('error');
        Observer.Observe('execute log', L.Take());
        Observer.Expect('request page log', 'init Yes/Yes/Yes;rp open Yes/Yes/Yes;handler ok;');
        Observer.Expect('has parameters', 'Yes');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('execute log', 'init Yes/Yes/Yes;rp open No/No/No;pre cond=not;pre No/No/No;predataitem cond=first;predataitem No/No/No;aftergetrecord No/No/No;postdataitem No/No/No;post No/No/No;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRp_Read_PropertyFalse_VariableDefault_RunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start();
        Observer.Observe('ok', Format(TryRunVarB(false, false)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('error|text', '');
        Observer.Expect('error|code', '');
        Observer.Expect('log', 'pre No/No/No;predataitem No/No/No;aftergetrecord No/No/No;');
        Observer.Verify();
    end;

    [Test]
    procedure UseRp_Read_PropertyFalse_StaticRunTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // No handler is declared: if BC opens the request page here, the error is the observation.
        Start();
        Observer.Observe('ok', Format(TryRunStatic(Report::"RPT UseRp Read B", true, false)));
        Observer.ObserveError('error');
        Observer.Observe('log', L.Take());
        Observer.Expect('ok', 'No');
        Observer.Expect('error|text', 'Unhandled UI: RequestPage 62302');
        Observer.Expect('error|code', 'MissingUIHandler');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandlerB')]
    procedure UseRp_Read_PropertyFalse_VariableSetTrue_RunModal_RequestPageOk()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "RPT UseRp Read B";
    begin
        Start();
        Rpt.UseRequestPage(true);
        Rpt.RunModal();
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'rp open Yes/Yes/Yes;handler ok;pre Yes/Yes/Yes;predataitem Yes/Yes/Yes;aftergetrecord Yes/Yes/Yes;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OkHandlerA(var RP: TestRequestPage "RPT UseRp Read A")
    begin
        L.Add('handler ok');
        RP.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancelHandlerA(var RP: TestRequestPage "RPT UseRp Read A")
    begin
        L.Add('handler cancel');
        RP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure OkHandlerB(var RP: TestRequestPage "RPT UseRp Read B")
    begin
        L.Add('handler ok');
        RP.OK().Invoke();
    end;
}
