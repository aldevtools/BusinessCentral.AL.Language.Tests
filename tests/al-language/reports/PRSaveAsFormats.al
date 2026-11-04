// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// Report.SaveAs of a report with DefaultLayout = RDLC but no layout file: Xml answers true and writes; Pdf, Html, Word and Excel answer false, write nothing and set
// "Report <id> does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom." in GetLastErrorText.
// Fixtures used: PR Oid Row (69543), self-contained report 69547, codeunit 69549
// BC versions: 27.5

report 69547 "PR Save Report"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Row; "PR Oid Row")
        {
            column(IdCol; Id) { }
        }
    }
}

codeunit 69549 "PR Save As Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "PR Oid Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    local procedure Size(var TempBlob: Codeunit "Temp Blob"): Text
    begin
        exit(Format(TempBlob.Length() > 0));
    end;

    [Test]
    procedure SaveAs_Formats_OfReportWithoutLayoutFile()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        TempBlob.CreateOutStream(OutS);
        Ok := Report.SaveAs(Report::"PR Save Report", '', ReportFormat::Xml, OutS);
        Observer.Observe('xml', Format(Ok) + ' written=' + Size(TempBlob));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Ok := Report.SaveAs(Report::"PR Save Report", '', ReportFormat::Pdf, OutS);
        Observer.Observe('pdf', Format(Ok) + ' written=' + Size(TempBlob));
        Observer.Observe('pdf_error', GetLastErrorText());
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Ok := Report.SaveAs(Report::"PR Save Report", '', ReportFormat::Html, OutS);
        Observer.Observe('html', Format(Ok) + ' written=' + Size(TempBlob));
        Observer.Observe('html_error', GetLastErrorText());
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Ok := Report.SaveAs(Report::"PR Save Report", '', ReportFormat::Word, OutS);
        Observer.Observe('word', Format(Ok) + ' written=' + Size(TempBlob));
        Observer.Observe('word_error', GetLastErrorText());
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Ok := Report.SaveAs(Report::"PR Save Report", '', ReportFormat::Excel, OutS);
        Observer.Observe('excel', Format(Ok) + ' written=' + Size(TempBlob));
        Observer.Observe('excel_error', GetLastErrorText());
        Observer.Expect('xml', 'Yes written=Yes');
        Observer.Expect('pdf', 'No written=No');
        Observer.Expect('pdf_error', 'Report 69547 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('html', 'No written=No');
        Observer.Expect('html_error', 'Report 69547 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('word', 'No written=No');
        Observer.Expect('word_error', 'Report 69547 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('excel', 'No written=No');
        Observer.Expect('excel_error', 'Report 69547 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Verify();
    end;
}
