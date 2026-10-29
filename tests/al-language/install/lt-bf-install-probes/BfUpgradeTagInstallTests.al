// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-upgrading-extensions
// Scope: in-scope
// Fixtures used: BfUpgradeTagInstall.al in this folder (74072-74077; the install codeunit 74076 wrote "LT UT Install Log" when this app was installed), Probe Observer (69160), Upgrade Tag (9999).
// Probe: corpus issue 812: per company of the database, what the install code of a freshly installed app saw of the upgrade tag and of OnCompanyInitialize.
// BC versions: 27 - 29
codeunit 74078 "LT UT Install Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if Company = CompanyName() then
            exit('session company');
        exit('other company');
    end;

    [Test]
    procedure InstallRun_UpgradeTagAndCompanyInitialize_PerCompany()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UT Install Log";
        Companies: Record Company;
        UpgradeTag: Codeunit "Upgrade Tag";
        Helper: Codeunit "LT UT Helper";
        InitRow: Record "LT UT Init Log";
    begin
        Row.SetCurrentKey(Id);
        if Row.FindSet() then
            repeat
                Observer.Observe('install row ' + Tag(Row."Company"), 'has tag before=' + Format(Row."Has Tag Before") + '|init row exists=' + Format(Row."Init Row Exists")
                    + '|has tag after set=' + Format(Row."Has Tag After Set") + '|init rows all companies=' + Format(Row."Init Rows All Companies") + '|tag is this app''s=' + Format(Row."Tag" = Helper.TagName()));
            until Row.Next() = 0;
        Observer.Observe('install rows', Format(Row.Count()));
        if Companies.FindSet() then
            repeat
                Observer.Observe('tag set after install, ' + Tag(Companies.Name), Format(UpgradeTag.HasUpgradeTag(Helper.TagName(), Companies.Name)));
            until Companies.Next() = 0;
        Observer.Observe('init rows now', Format(InitRow.Count()));
        Observer.Finish();
    end;
}
