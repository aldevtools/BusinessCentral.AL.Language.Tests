// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-loadpackagedata-method
// Scope: in-scope
// Fixtures used: tests/al-language-xapp-a/PkgDataPartsFixture.al (tables 97991-97992, install codeunit 97998) with the data files TAB97991.navxdata; Probe Observer (69160).
// Probe (al-runner issue 6649): what NavApp.LoadPackageData does when the install part does not match the table's DataPerCompany: a shared table
//   (DataPerCompany = false) loaded from OnInstallAppPerCompany. (The per-company table loaded from OnInstallAppPerDatabase fails the publish.) The shared table is
//   loaded in the first company only (a later company logs `no load` under part company-later).
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
    procedure LoadPackageData_SharedTableInCompanyPart()
    var
        Row: Record "LT PkgParts Shared";
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Observer.Observe('load', LogText('company'));
        Observer.Observe('later companies', LogText('company-later'));
        if Row.FindSet() then
            repeat
                T += Row."No." + '=' + Row.Description + ';';
            until Row.Next() = 0;
        Observer.Observe('rows', T);
        Observer.Finish();
    end;
}
