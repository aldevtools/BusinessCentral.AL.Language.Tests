// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope (OnPrem only: Report.SaveAsPdf, SaveAsWord, SaveAsHtml and SaveAsXml with a file name are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), SAE Helper and the reports SAE Word Two, SAE Word Three, SAE Rdlc Two of the AL Language Coverage Tests app (reports/saveas-empty-items/SaeFixtures.al)
// Probe (al-runner issue 8668): SaveAs to a file name (Report.SaveAsPdf, SaveAsWord, SaveAsHtml, SaveAsXml) of reports with two or three top-level data items, empty and filled:
//   whether the call completed, what it returned, the error, and whether the file exists afterwards.
// BC versions: 27 - 29
// Results (observed on BC 27.5 only; 28.5 and 29.0 need CI observation): SaveAs to a file name behaves like the stream form: empty Word reports raise ReportResultEmpty for Pdf, Word, Html and leave no file; Xml writes a file; RDLC with two empty items returns without a file for Pdf and Word, and Html raises ReportUnsupportedFormat.

codeunit 98055 "SAE File Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "SAE Helper";

    [TryFunction]
    local procedure TrySave(ReportId: Integer; Fmt: Integer; FileName: Text; var Ok: Boolean)
    begin
        case Fmt of
            1:
                Ok := Report.SaveAsPdf(ReportId, FileName);
            2:
                Ok := Report.SaveAsWord(ReportId, FileName);
            3:
                Ok := Report.SaveAsHtml(ReportId, FileName);
            4:
                Ok := Report.SaveAsXml(ReportId, FileName);
        end;
    end;

    local procedure FileFacts(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; Fmt: Integer; Extension: Text)
    var
        FileName: Text;
        Completed: Boolean;
        Ok: Boolean;
    begin
        FileName := TemporaryPath() + 'sae-8668-' + Name + Extension;
        if File.Exists(FileName) then
            File.Erase(FileName);
        ClearLastError();
        Completed := TrySave(ReportId, Fmt, FileName, Ok);
        Observer.Observe(Name + ' completed', Format(Completed));
        Observer.Observe(Name + ' returned', Format(Ok));
        Observer.ObserveError(Name + ' err');
        Observer.Observe(Name + ' file exists', Format(File.Exists(FileName)));
        if File.Exists(FileName) then
            File.Erase(FileName);
    end;

    local procedure AllFiles(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    begin
        FileFacts(Observer, 'pdf', ReportId, 1, '.pdf');
        FileFacts(Observer, 'word', ReportId, 2, '.docx');
        FileFacts(Observer, 'html', ReportId, 3, '.html');
        FileFacts(Observer, 'xml', ReportId, 4, '.xml');
    end;

    [Test]
    procedure SaveAsFile_WordTwo_EE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        AllFiles(Observer, Report::"SAE Word Two");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'No');
        Observer.Expect('pdf err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('pdf err|code', 'ReportResultEmpty');
        Observer.Expect('pdf file exists', 'No');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'No');
        Observer.Expect('word err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('word err|code', 'ReportResultEmpty');
        Observer.Expect('word file exists', 'No');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('html err|code', 'ReportResultEmpty');
        Observer.Expect('html file exists', 'No');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml file exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsFile_WordTwo_ER()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 1, 0);
        AllFiles(Observer, Report::"SAE Word Two");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf file exists', 'Yes');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word file exists', 'Yes');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html file exists', 'Yes');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml file exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsFile_WordTwo_RR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 1, 0);
        AllFiles(Observer, Report::"SAE Word Two");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf file exists', 'Yes');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word file exists', 'Yes');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'Yes');
        Observer.Expect('html err|text', '');
        Observer.Expect('html err|code', '');
        Observer.Expect('html file exists', 'Yes');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml file exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsFile_WordThree_EEE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        AllFiles(Observer, Report::"SAE Word Three");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'No');
        Observer.Expect('pdf err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('pdf err|code', 'ReportResultEmpty');
        Observer.Expect('pdf file exists', 'No');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'No');
        Observer.Expect('word err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('word err|code', 'ReportResultEmpty');
        Observer.Expect('word file exists', 'No');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The report couldn’t be generated, because it was empty. Adjust your filters and try again.');
        Observer.Expect('html err|code', 'ReportResultEmpty');
        Observer.Expect('html file exists', 'No');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml file exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAsFile_RdlcTwo_EE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        AllFiles(Observer, Report::"SAE Rdlc Two");
        Observer.Expect('pdf completed', 'Yes');
        Observer.Expect('pdf returned', 'Yes');
        Observer.Expect('pdf err|text', '');
        Observer.Expect('pdf err|code', '');
        Observer.Expect('pdf file exists', 'No');
        Observer.Expect('word completed', 'Yes');
        Observer.Expect('word returned', 'Yes');
        Observer.Expect('word err|text', '');
        Observer.Expect('word err|code', '');
        Observer.Expect('word file exists', 'No');
        Observer.Expect('html completed', 'Yes');
        Observer.Expect('html returned', 'No');
        Observer.Expect('html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('html err|code', 'ReportUnsupportedFormat');
        Observer.Expect('html file exists', 'No');
        Observer.Expect('xml completed', 'Yes');
        Observer.Expect('xml returned', 'Yes');
        Observer.Expect('xml err|text', '');
        Observer.Expect('xml err|code', '');
        Observer.Expect('xml file exists', 'Yes');
        Observer.Verify();
    end;
}
