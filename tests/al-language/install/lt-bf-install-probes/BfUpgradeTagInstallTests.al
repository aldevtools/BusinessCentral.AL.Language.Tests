// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-upgrading-extensions
// Scope: in-scope
// Fixtures used: QzXeObjects.al in tests/al-language-xapp-e (61170-61175; the install codeunit 61174 wrote "LT UT Install Log" when this app was installed), Probe Observer (69160), Upgrade Tag (9999).
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
        // Measured on the BC 29 SaaS sandbox (2026-10-29): in both companies the tag was not set and the OnCompanyInitialize subscriber had not run when the
        // install code started, and the tag was set after SetUpgradeTag. The subscriber's rows (0) are not asserted afterwards: other tests may initialize companies.
        Observer.Expect('install row session company', 'has tag before=No|init row exists=No|has tag after set=Yes|init rows all companies=0|tag is this app''s=Yes');
        Observer.Expect('install row other company', 'has tag before=No|init row exists=No|has tag after set=Yes|init rows all companies=0|tag is this app''s=Yes');
        Observer.Expect('install rows', '2');
        Observer.Expect('tag set after install, session company', 'Yes');
        Observer.Expect('tag set after install, other company', 'Yes');
        Observer.Verify();
    end;
}
