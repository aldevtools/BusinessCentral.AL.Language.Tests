// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope (OnPrem only: Report.SaveAsPdf is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), PR Save Report (69547) and PR Oid Row from the AL Language Coverage Tests app; self-contained codeunit 61292
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// Report.SaveAsPdf(ReportId, FileName) of a report that has no layout file answers false without raising (also inside a TryFunction) and sets
// "Report <id> does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom." in GetLastErrorText (the same text as SaveAs for Pdf).
// BC versions: 27.5
codeunit 61292 "PX SaveAsPdf Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySave(FileName: Text; var Result: Boolean)
    begin
        Result := Report.SaveAsPdf(Report::"PR Save Report", FileName);
    end;

    [Test]
    procedure SaveAsPdf_ReportWithoutLayoutFile()
    var
        Row: Record "PR Oid Row";
        Ok: Boolean;
        Done: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        ClearLastError();
        Done := TrySave(TemporaryPath() + 'px-save-as-pdf.pdf', Ok);
        Observer.Observe('completed', Format(Done));
        Observer.Observe('answer', Format(Ok));
        Observer.Observe('error', GetLastErrorText());
        Observer.Expect('completed', 'Yes');
        Observer.Expect('answer', 'No');
        Observer.Expect('error', 'Report 69547 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Verify();
    end;
}
