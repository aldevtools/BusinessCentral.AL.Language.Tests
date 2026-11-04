// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own report 74452 and SingleInstance log 74453 (used only by test codeunit 74454)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: does the call raise (error text start and code) or run like with SystemPrinter false; how many OnPreReport / OnAfterGetRecord / OnPostReport triggers ran; the variable form RunModal after UseRequestPage(false).
// BC versions: 29 (27 and 28 by CI)

codeunit 74453 "LT RunSP Log"
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

report 74452 "LT RunSP Report"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

            trigger OnAfterGetRecord()
            begin
                Log.Add('row' + Format(Num.Number));
            end;
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('pre');
    end;

    trigger OnPostReport()
    begin
        Log.Add('post');
    end;

    var
        Log: Codeunit "LT RunSP Log";
}

codeunit 74454 "LT RunSP Printer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRun(RequestWindow: Boolean; SystemPrinter: Boolean)
    begin
        Report.Run(Report::"LT RunSP Report", RequestWindow, SystemPrinter);
    end;

    [TryFunction]
    local procedure TryRunModal(RequestWindow: Boolean; SystemPrinter: Boolean)
    begin
        Report.RunModal(Report::"LT RunSP Report", RequestWindow, SystemPrinter);
    end;

    [TryFunction]
    local procedure TryVariableRunModal()
    var
        Rpt: Report "LT RunSP Report";
    begin
        Rpt.UseRequestPage(false);
        Rpt.RunModal();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error:' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure ReportRun_SystemPrinterFalse_Result()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RunSP Log";
    begin
        Log.Take();
        Observer.Observe('run_false', Outcome(TryRun(false, false)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('run_false', 'ok');
        Observer.Expect('log', 'pre;row1;row2;post;');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRun_SystemPrinterTrue_Result()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RunSP Log";
    begin
        Log.Take();
        Observer.Observe('run_true', Outcome(TryRun(false, true)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('run_true', 'ok');
        Observer.Expect('log', 'pre;row1;row2;post;');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRunModal_SystemPrinterFalse_Result()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RunSP Log";
    begin
        Log.Take();
        Observer.Observe('runmodal_false', Outcome(TryRunModal(false, false)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('runmodal_false', 'ok');
        Observer.Expect('log', 'pre;row1;row2;post;');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRunModal_SystemPrinterTrue_Result()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RunSP Log";
    begin
        Log.Take();
        Observer.Observe('runmodal_true', Outcome(TryRunModal(false, true)));
        Observer.Observe('log', Log.Take());
        Observer.Expect('runmodal_true', 'ok');
        Observer.Expect('log', 'pre;row1;row2;post;');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRunModal_VariableForm_Result()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RunSP Log";
    begin
        Log.Take();
        Observer.Observe('variable_runmodal', Outcome(TryVariableRunModal()));
        Observer.Observe('log', Log.Take());
        Observer.Expect('variable_runmodal', 'ok');
        Observer.Expect('log', 'pre;row1;row2;post;');
        Observer.Verify();
    end;
}
