// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: CmInstallObjects.al in this folder (install codeunit 93329, tables 93330-93332, 93336), Probe Observer (69160).
// Probe (writer Y64, al-runner issues 6643 and 6649): what install codeunit 93329 recorded: AllObj / AllObjWithCaption rows of type TableData of
//   Base Application tables during OnInstallAppPerCompany and OnInstallAppPerDatabase, the reporter's setup row (a field whose OnValidate reads
//   AllObjWithCaption for TableData 5050, validated during the per-company install), and NavApp.LoadPackageData in install code. The install
//   writes one row per company; the tests read the row of the current company.
// BC versions: 27-29

codeunit 93333 "LT Y64 Install Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seen(Co: Text; Code: Code[30]): Text
    var
        S: Record "LT Y64 Install Seen";
    begin
        if not S.Get(Co, Code) then
            exit('<missing>');
        exit(S.Txt);
    end;

    local procedure Here(Code: Code[30]): Text
    begin
        exit(Seen(CopyStr(CompanyName(), 1, 30), Code));
    end;

    [Test]
    procedure Y64_Install_AllObjTableData_PerCompany()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('context', Here('CONTEXT'));
        Observer.Observe('allobjcap tabledata 5050', Here('ALLOBJCAP TABLEDATA 5050'));
        Observer.Observe('allobj tabledata 5050', Here('ALLOBJ TABLEDATA 5050'));
        Observer.Observe('allobjcap table 5050', Here('ALLOBJCAP TABLE 5050'));
        Observer.Observe('allobjcap tabledata own', Here('ALLOBJCAP TABLEDATA OWN'));
        Observer.Observe('allobjcap tabledata 18', Here('ALLOBJCAP TABLEDATA 18'));
        Observer.Finish();
    end;

    [Test]
    procedure Y64_Install_AllObjTableData_PerDatabase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('context', Seen('<db>', 'CONTEXT'));
        Observer.Observe('allobjcap tabledata 5050', Seen('<db>', 'ALLOBJCAP TABLEDATA 5050'));
        Observer.Observe('allobj tabledata 5050', Seen('<db>', 'ALLOBJ TABLEDATA 5050'));
        Observer.Finish();
    end;

    [Test]
    procedure Y64_Install_SetupValidate_ReporterShape()
    var
        Observer: Codeunit "Probe Observer";
        MySetup: Record "LT Y64 Install Setup";
    begin
        Observer.Observe('validate in install', Here('SETUP VALIDATE'));
        Observer.Observe('setup row', Format(MySetup.Get(Database::Contact)) + '|' + MySetup.TableName);
        Clear(MySetup);
        MySetup.Validate("Table ID", Database::Contact);
        Observer.Observe('validate in test', MySetup.TableName);
        Observer.Finish();
    end;

    [Test]
    procedure Y64_Install_LoadPackageData()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y64 Install Pkg Row";
        DbRow: Record "LT Y64 Install Pkg Db Row";
    begin
        Observer.Observe('per company own table', Here('LOAD OWN TABLE'));
        Observer.Observe('per database table', Seen('<db>', 'LOAD DB TABLE'));
        Observer.Observe('rows now', Format(Row.Count()) + '|' + Format(DbRow.Count()));
        Observer.Finish();
    end;
}
