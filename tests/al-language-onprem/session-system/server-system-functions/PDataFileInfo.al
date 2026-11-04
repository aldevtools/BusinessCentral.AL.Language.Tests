// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-datafileinformation-method
// Scope: in-scope (OnPrem app only: Database.DataFileInformation)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61249
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: reads a file header; only a nonexistent and a blank path are used, ShowDialog is always false
//
// DataFileInformation(false, FileName, ...) with a blank and a nonexistent file name: outcome, error text start and code, and the out parameters afterwards.
// BC versions: 29 (27 and 28 by CI)
codeunit 61249 "LT P109 DataFileInfo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInfo(FileName: Text; var Description: Text; var HasApp: Boolean; var HasAppData: Boolean; var HasGlobal: Boolean; var TenantId: Text; var ExportDate: DateTime)
    var
        Company: Record Company;
    begin
        Database.DataFileInformation(false, FileName, Description, HasApp, HasAppData, HasGlobal, TenantId, ExportDate, Company);
    end;

    local procedure Outcome(FileName: Text): Text
    var
        Description: Text;
        HasApp: Boolean;
        HasAppData: Boolean;
        HasGlobal: Boolean;
        TenantId: Text;
        ExportDate: DateTime;
    begin
        if TryInfo(FileName, Description, HasApp, HasAppData, HasGlobal, TenantId, ExportDate) then
            exit('ok desc=' + Description + ' app=' + Format(HasApp) + ' appdata=' + Format(HasAppData) + ' global=' + Format(HasGlobal) + ' tenant=' + TenantId + ' date=' + Format(ExportDate));
        exit('error:' + CopyStr(GetLastErrorText(), 1, 60) + '|' + GetLastErrorCode() + ' desc=' + Description + ' app=' + Format(HasApp) + ' appdata=' + Format(HasAppData) + ' global=' + Format(HasGlobal) + ' tenant=' + TenantId + ' date=' + Format(ExportDate));
    end;

    [Test]
    procedure P109_DataFileInformation_NoFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('blank', Outcome(''));
        Observer.Observe('nonexistent', Outcome('/ltp109-no-such-dir/none.navdata'));
        Observer.Observe('nonexistent_relative', Outcome('ltp109-no-such-file.navdata'));
        // Linux container differs from Windows BC (run 39125184978 / 39125190236): DataFileInformation raises NotSupportedFileDialogProvider ("feature not supported (AL File function.)") on Windows; Linux returns an empty result without error. Not asserted.
        Observer.Ignore('blank');
        Observer.Ignore('nonexistent');
        Observer.Ignore('nonexistent_relative');
        Observer.Verify();
    end;
}
