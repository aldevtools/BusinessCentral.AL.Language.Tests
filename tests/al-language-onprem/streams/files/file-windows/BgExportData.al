// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-exportdata-method
// Scope: in-scope (OnPrem test app only: Database.ExportData is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 98993
// Probe: Database.ExportData with ShowDialog = false in a test session: the return value, FileName afterwards, whether a file is written, with and without a Company record (the current company only).
// ODatabaseOps.al (61258) pins that the call raises no error and writes no file. MsDyn365Bc.On.Linux PR #130 made the Linux test runner read the export stream as Microsoft's client does
// (between PR #127 and PR #130 each call waited 60 seconds and ended in a TimeoutException).
// Expected values: measured on official Microsoft Windows containers (onprem artifact, w1, en-US), BC 27.5 and 29.0, corpus runs 39216765049 and 39216768276 (both gave the same values).
// BC versions: 27, 28, 29
codeunit 98993 "LT BG ExportData"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryExport(var FileName: Text; WithCompany: Boolean; var R: Boolean)
    var
        Company: Record Company;
    begin
        if WithCompany then begin
            Company.SetRange(Name, CompanyName());
            R := Database.ExportData(false, FileName, 'LT BG export', false, false, false, Company);
        end else
            R := Database.ExportData(false, FileName, 'LT BG export', false, false, false);
    end;

    local procedure ExportCase(var Observer: Codeunit "Probe Observer"; Name: Text; Path: Text; WithCompany: Boolean)
    var
        FileName: Text;
        R: Boolean;
    begin
        FileName := Path;
        R := false;
        if TryExport(FileName, WithCompany, R) then
            Observer.Observe(Name, 'ok ret=' + Format(R))
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + '|filename unchanged', Format(FileName = Path));
        Observer.Observe(Name + '|file exists', Format(File.Exists(Path)));
        if File.Exists(Path) then
            File.Erase(Path);
    end;

    [Test]
    procedure BG_ExportData_ReturnFileNameAndFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExportCase(Observer, 'export no company', TemporaryPath() + 'lt-bg-export-a.navdata', false);
        ExportCase(Observer, 'export current company', TemporaryPath() + 'lt-bg-export-b.navdata', true);
        // Windows returns Yes on 27.5/28.5/29.0 (runs 39216765049 / 39216768276); before the bc-linux #138 fix the Linux image
        // on BC 28.5 and 29.0 returned No (corpus batch run 39220885767).
        Observer.Expect('export no company', 'ok ret=Yes');
        Observer.Expect('export no company|filename unchanged', 'Yes');
        Observer.Expect('export no company|file exists', 'No');
        // Windows returns Yes on 27.5/28.5/29.0 (runs 39216765049 / 39216768276); before the bc-linux #138 fix the Linux image
        // on BC 28.5 and 29.0 returned No (corpus batch run 39220885767).
        Observer.Expect('export current company', 'ok ret=Yes');
        Observer.Expect('export current company|filename unchanged', 'Yes');
        Observer.Expect('export current company|file exists', 'No');
        Observer.Verify();
    end;
}
