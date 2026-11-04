// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-changecompany-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 79800 (ArFixtures.al)
// Probe: corpus issue 643 item 4 (the field values part); every literal asserted below is what the BC service tier produced on the corpus CI matrix.
// Facts: what ChangeCompany does to the field values a Record holds, and what Find('=') and Insert do with them in the other company.
// Already pinned: filters, current key and marks across ChangeCompany, and Copy / SetTable between records of two companies
// (record/TestChangeCompanyFiltersCopyDeleteContracts.al, codeunit 68391).
// Creating a company takes about a minute on the Linux tier: one codeunit, one test.
// BC versions: 27, 28, 29

codeunit 79851 "LT AR Change Company Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        CompanyTok: Label 'LT AR CHG VALUES', Locked = true;

    [Test]
    procedure ChangeCompany_FieldValues()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record Company;
        Row: Record "LT AR Row";
        Other: Record "LT AR Row";
    begin
        if Company.Get(CompanyTok) then
            Company.Delete(true);
        Company.Init();
        Company.Name := CompanyTok;
        Company.Insert();
        Commit();

        Row.DeleteAll();
        Row.Init();
        Row.Id := 7;
        Row.Name := 'home';
        Row.Insert();
        Row.Get(7);
        Observer.Observe('changed', Format(Row.ChangeCompany(CompanyTok)));
        Observer.Observe('values', Format(Row.Id) + '|' + Row.Name);
        Observer.Observe('find', Format(Row.Find('=')));
        Observer.Observe('values after find', Format(Row.Id) + '|' + Row.Name);
        Row.Id := 7;
        Row.Name := 'home';
        Row.Insert();
        Other.ChangeCompany(CompanyTok);
        Observer.Observe('other company row', Format(Other.Get(7)) + '|' + Other.Name);
        Observer.Observe('back', Format(Row.ChangeCompany(CompanyName())));
        Observer.Observe('values back', Format(Row.Id) + '|' + Row.Name);
        Observer.Observe('home count', Format(Row.Count()));
        Other.DeleteAll();
        Row.DeleteAll();
        if Company.Get(CompanyTok) then
            Company.Delete(true);
        Commit();
        Observer.Expect('changed', 'Yes');
        Observer.Expect('values', '7|home');
        Observer.Expect('find', 'No');
        Observer.Expect('values after find', '7|home');
        Observer.Expect('other company row', 'Yes|home');
        Observer.Expect('back', 'Yes');
        Observer.Expect('values back', '7|home');
        Observer.Expect('home count', '1');
        Observer.Verify();
    end;
}
