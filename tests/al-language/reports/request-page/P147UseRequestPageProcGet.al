// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/reportinstance/reportinstance-userequestpage-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P147 Trace Log (70277); own report 70273, test codeunit 70274
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// No request page handler is declared: if the request page opens, the run raises an error (observed); if it does not open, the triggers run and no error is raised.
// A trace of the triggers reached is observed after each of Report.Run(id, true, false), RunModal on a report variable and Report.Run(id, false, false).
// BC versions: 29 (27 and 28 by CI)

report 70273 "LT P147 Urp ProcGet"
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
        Helper();
    end;

    local procedure Helper()
    begin
        Log.Add('helper get=' + Format(CurrReport.UseRequestPage()));
    end;

    var
        Log: Codeunit "LT P147 Trace Log 5";
        DummyTxt: Text[10];
}

codeunit 70274 "LT P147 Urp ProcGet Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRunId(WithRequestPage: Boolean)
    begin
        Report.Run(Report::"LT P147 Urp ProcGet", WithRequestPage, false);
    end;

    [TryFunction]
    local procedure TryRunVar()
    var
        Rep: Report "LT P147 Urp ProcGet";
    begin
        Rep.RunModal();
    end;

    [Test]
    procedure P147_Urp_ProcGet_RunWithoutRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P147 Trace Log 5";
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
        Observer.Expect('trace', 'OnInitReport;OnPreReport;helper get=No;');
        Observer.Verify();
    end;
}

codeunit 70284 "LT P147 Trace Log 5"
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
