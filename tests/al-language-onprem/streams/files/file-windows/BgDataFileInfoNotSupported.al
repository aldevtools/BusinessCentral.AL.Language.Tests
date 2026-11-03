// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-datafileinformation-method
// Scope: in-scope (OnPrem test app only: Database.DataFileInformation and Database.ImportData are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 98992
// Probe: Database.DataFileInformation and Database.ImportData with ShowDialog = false in a test session. ODatabaseOps.al (61258) and PDataFileInfo.al (61249) observe these calls but leave them unasserted.
// An official Windows container raised NotSupportedFileDialogProvider for each of them on BC 27.5 and 29.0 (corpus runs 39125184978 and 39125190236); the Linux image raises the same since
// MsDyn365Bc.On.Linux PR #127 (before, Linux returned an empty result without an error). Only missing files and blank names are used.
// Expected values: measured on official Microsoft Windows containers (onprem artifact, w1, en-US), BC 27.5 and 29.0, corpus runs 39216765049 and 39216768276 (both gave the same values).
// BC versions: 27, 28, 29
codeunit 98992 "LT BG DataFileInfo Refused"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInfo(Path: Text; var Desc: Text; var HasApp: Boolean; var HasAppData: Boolean; var HasGlobal: Boolean; var TenantId: Text)
    var
        FileName: Text;
        Company: Record Company;
        ExportDate: DateTime;
    begin
        FileName := Path;
        Database.DataFileInformation(false, FileName, Desc, HasApp, HasAppData, HasGlobal, TenantId, ExportDate, Company);
    end;

    [TryFunction]
    local procedure TryImport(Path: Text)
    var
        FileName: Text;
    begin
        FileName := Path;
        Database.ImportData(false, FileName);
    end;

    local procedure InfoCase(var Observer: Codeunit "Probe Observer"; Name: Text; Path: Text)
    var
        Desc: Text;
        HasApp: Boolean;
        HasAppData: Boolean;
        HasGlobal: Boolean;
        TenantId: Text;
    begin
        Desc := 'untouched';
        TenantId := 'untouched';
        HasApp := true;
        HasAppData := true;
        HasGlobal := true;
        if TryInfo(Path, Desc, HasApp, HasAppData, HasGlobal, TenantId) then
            Observer.Observe(Name, 'no error')
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + '|outputs', StrSubstNo('desc=[%1] app=%2 appdata=%3 global=%4 tenant=[%5]', Desc, HasApp, HasAppData, HasGlobal, TenantId));
    end;

    local procedure ImportCase(var Observer: Codeunit "Probe Observer"; Name: Text; Path: Text)
    begin
        if TryImport(Path) then
            Observer.Observe(Name, 'no error')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure BG_DataFileInformation_RaisesNotSupported()
    var
        Observer: Codeunit "Probe Observer";
    begin
        InfoCase(Observer, 'info missing temp', TemporaryPath() + 'lt-bg-missing.navdata');
        InfoCase(Observer, 'info blank', '');
        InfoCase(Observer, 'info missing absolute', '/lt-bg-no-such-dir/none.navdata');
        InfoCase(Observer, 'info missing relative', 'lt-bg-no-such-file.navdata');
        Observer.Expect('info missing temp|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('info missing temp|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Expect('info missing temp|outputs', 'desc=[untouched] app=Yes appdata=Yes global=Yes tenant=[untouched]');
        Observer.Expect('info blank|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('info blank|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Expect('info blank|outputs', 'desc=[untouched] app=Yes appdata=Yes global=Yes tenant=[untouched]');
        Observer.Expect('info missing absolute|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('info missing absolute|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Expect('info missing absolute|outputs', 'desc=[untouched] app=Yes appdata=Yes global=Yes tenant=[untouched]');
        Observer.Expect('info missing relative|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('info missing relative|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Expect('info missing relative|outputs', 'desc=[untouched] app=Yes appdata=Yes global=Yes tenant=[untouched]');
        Observer.Verify();
    end;

    [Test]
    procedure BG_ImportData_RaisesNotSupported()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ImportCase(Observer, 'import missing temp', TemporaryPath() + 'lt-bg-missing.navdata');
        ImportCase(Observer, 'import blank', '');
        ImportCase(Observer, 'import missing relative', 'lt-bg-no-such-file.navdata');
        Observer.Expect('import missing temp|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('import missing temp|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Expect('import blank|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('import blank|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Expect('import missing relative|text', 'The operation cannot complete because it uses a feature that is not supported (AL File function.)');
        Observer.Expect('import missing relative|code', 'NotSupportedFileDialogProvider:NotSupportedFileDialogProvider');
        Observer.Verify();
    end;
}
