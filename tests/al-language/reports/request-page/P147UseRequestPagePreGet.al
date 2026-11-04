// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-userequestpage-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P147 Trace Log (70277); own report 70271, test codeunit 70272
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// No request page handler is declared: if the request page opens, the run raises an error (observed); if it does not open, the triggers run and no error is raised.
// A trace of the triggers reached is observed after each of Report.Run(id, true, false), RunModal on a report variable and Report.Run(id, false, false).
// BC versions: 29 (27 and 28 by CI)

report 70271 "LT P147 Urp PreGet"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Dummy; DummyTxt)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        Log.Add('OnInitReport');
    end;

    trigger OnPreReport()
    begin
        Log.Add('OnPreReport');
        Log.Add('get=' + Format(CurrReport.UseRequestPage()));
    end;


    var
        Log: Codeunit "LT P147 Trace Log 3";
        DummyTxt: Text[10];
}

codeunit 70272 "LT P147 Urp PreGet Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRunId(WithRequestPage: Boolean)
    begin
        Report.Run(Report::"LT P147 Urp PreGet", WithRequestPage, false);
    end;

    [TryFunction]
    local procedure TryRunVar()
    var
        Rep: Report "LT P147 Urp PreGet";
    begin
        Rep.RunModal();
    end;

    [Test]
    procedure P147_Urp_PreGet_RunWithoutRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P147 Trace Log 3";
        Ok: Boolean;
    begin
        Log.Clear();
        Ok := TryRunId(false);
        Observer.Observe('ran without error', Format(Ok));
        Observer.ObserveError('Report.Run(id, false, false) error');
        Observer.Observe('trace', Log.Get());
        Observer.Expect('ran without error', 'Yes');
        Observer.Expect('Report.Run(id, false, false) error|text', '');
        Observer.Expect('Report.Run(id, false, false) error|code', '');
        Observer.Expect('trace', 'OnInitReport;OnPreReport;get=No;');
        Observer.Verify();
    end;
    // Writer PW: docs/probes-needed.md "Report runs and SaveAs": CurrReport.UseRequestPage() in OnPreReport of a static Report.RunModal with
    // RequestWindow false (P147_Urp_PreGet_RunWithoutRequestPage pins the static Report.Run).
    [TryFunction]
    local procedure PwTryRunModalId(WithRequestPage: Boolean; TwoArguments: Boolean)
    begin
        if TwoArguments then
            Report.RunModal(Report::"LT P147 Urp PreGet", WithRequestPage)
        else
            Report.RunModal(Report::"LT P147 Urp PreGet", WithRequestPage, false);
    end;

    [TryFunction]
    local procedure PwTryRunVarNoRp()
    var
        Rep: Report "LT P147 Urp PreGet";
    begin
        Rep.UseRequestPage(false);
        Rep.RunModal();
    end;

    [Test]
    procedure PW_Urp_PreGet_RunModalWithoutRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P147 Trace Log 3";
    begin
        Log.Clear();
        Observer.Observe('runmodal(id, false, false)', Format(PwTryRunModalId(false, false)));
        Observer.ObserveError('runmodal(id, false, false)');
        Observer.Observe('trace 1', Log.Get());
        Log.Clear();
        Observer.Observe('runmodal(id, false)', Format(PwTryRunModalId(false, true)));
        Observer.ObserveError('runmodal(id, false)');
        Observer.Observe('trace 2', Log.Get());
        Log.Clear();
        Observer.Observe('variable UseRequestPage(false) RunModal', Format(PwTryRunVarNoRp()));
        Observer.ObserveError('variable');
        Observer.Observe('trace 3', Log.Get());
        Observer.Expect('runmodal(id, false, false)', 'Yes');
        Observer.Expect('runmodal(id, false, false)|text', '');
        Observer.Expect('runmodal(id, false, false)|code', '');
        Observer.Expect('trace 1', 'OnInitReport;OnPreReport;get=No;');
        Observer.Expect('runmodal(id, false)', 'Yes');
        Observer.Expect('runmodal(id, false)|text', '');
        Observer.Expect('runmodal(id, false)|code', '');
        Observer.Expect('trace 2', 'OnInitReport;OnPreReport;get=No;');
        Observer.Expect('variable UseRequestPage(false) RunModal', 'Yes');
        Observer.Expect('variable|text', '');
        Observer.Expect('variable|code', '');
        Observer.Expect('trace 3', 'OnInitReport;OnPreReport;get=No;');
        Observer.Verify();
    end;
}

codeunit 70282 "LT P147 Trace Log 3"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Get(): Text
    begin
        exit(Entries);
    end;
}
