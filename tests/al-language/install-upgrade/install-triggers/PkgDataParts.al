// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-loadpackagedata-method
// Scope: in-scope
// Fixtures used: tests/al-language-xapp-a/PkgDataPartsFixture.al (tables 97990-97992, install codeunit 97999) with the data files TAB97990 and
//   TAB97991.navxdata; Probe Observer (69160).
// Probe (al-runner issue 6649): what NavApp.LoadPackageData does when the install part does not match the table's DataPerCompany: a per-company
//   table loaded from OnInstallAppPerDatabase, and a shared table (DataPerCompany = false) loaded from OnInstallAppPerCompany. Each load runs in a
//   TryFunction in the install code; the log says `ok` or the error code and text. The shared table is loaded only while it is empty, so a later
//   company logs `skipped, it had rows`.
// BC versions: 27 - 29
codeunit 97980 "LT PkgParts Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure LogText(PartName: Text): Text
    var
        Log: Record "LT PkgParts Log";
        T: Text;
    begin
        Log.SetRange(Part, PartName);
        if Log.FindSet() then
            repeat
                T += Log.Subject + ' -> ' + Log.Detail + ';';
            until Log.Next() = 0;
        exit(T);
    end;

    [Test]
    procedure LoadPackageData_CompanyTableInDatabasePart()
    var
        Row: Record "LT PkgParts Company";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('load', LogText('database'));
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + ';';
            until Row.Next() = 0;
        Observer.Observe('rows in this company', T);
        Observer.Finish();
    end;

    [Test]
    procedure LoadPackageData_SharedTableInCompanyPart()
    var
        Row: Record "LT PkgParts Shared";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('load', LogText('company'));
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Finish();
    end;
}
