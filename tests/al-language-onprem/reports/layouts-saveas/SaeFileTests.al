// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope (OnPrem only: Report.SaveAsPdf, SaveAsWord, SaveAsHtml and SaveAsXml with a file name are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), SAE Helper and the reports SAE Word Two, SAE Word Three, SAE Rdlc Two of the AL Language Coverage Tests app (reports/saveas-empty-items/SaeFixtures.al)
// Probe (al-runner issue 8668): SaveAs to a file name (Report.SaveAsPdf, SaveAsWord, SaveAsHtml, SaveAsXml) of reports with two or three top-level data items, empty and filled:
//   whether the call completed, what it returned, the error, and whether the file exists afterwards.
// BC versions: 27 - 29

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
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsFile_WordTwo_ER()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 1, 0);
        AllFiles(Observer, Report::"SAE Word Two");
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsFile_WordTwo_RR()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(1, 1, 0);
        AllFiles(Observer, Report::"SAE Word Two");
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsFile_WordThree_EEE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        AllFiles(Observer, Report::"SAE Word Three");
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsFile_RdlcTwo_EE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Fill(0, 0, 0);
        AllFiles(Observer, Report::"SAE Rdlc Two");
        Observer.Finish();
    end;
}
