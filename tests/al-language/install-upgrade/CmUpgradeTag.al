// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-upgrading-extensions
// Scope: in-scope
// Fixtures used: Upgrade Tag (codeunit 9999, System Application), Probe Observer (69160); own codeunit 84836 (manual subscriber).
// Facts: corpus issue 669 (odd AL behavior leads, part D), item 44. Upgrade Tag called from a test session: HasUpgradeTag before and after
//   SetUpgradeTag, HasUpgradeTag for another company and for the database (''), SetAllUpgradeTags with a bound OnGetPerCompanyUpgradeTags
//   subscriber, and a company inserted while that subscriber is bound. Every test uses a new tag (a GUID), because the Upgrade Tags
//   table is internal to the System Application and rows left by an earlier run cannot be removed.
//   Not asserted: SetUpgradeTag twice. The duplicate insert is buffered: asserterror around the second call saw no error, and the
//   error "The record in table Upgrade Tags already exists. Identification fields and values: Tag='...',Company='...'" came later.
// BC versions: 27, 28, 29

codeunit 84835 "LT CM Upgrade Tag"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure NewTag(): Code[250]
    begin
        exit(CopyStr('LT-CM-' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 250));
    end;

    [Test]
    procedure Item44_HasAndSetUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Observer: Codeunit "Probe Observer";
        Tag: Code[250];
    begin
        Tag := NewTag();
        Observer.Observe('has before set', Format(UpgradeTag.HasUpgradeTag(Tag)));
        UpgradeTag.SetUpgradeTag(Tag);
        Observer.Observe('has after set', Format(UpgradeTag.HasUpgradeTag(Tag)));
        Observer.Observe('has for own company', Format(UpgradeTag.HasUpgradeTag(Tag, CopyStr(CompanyName(), 1, 30))));
        Observer.Observe('has for other company', Format(UpgradeTag.HasUpgradeTag(Tag, 'LT CM NO SUCH CO')));
        Observer.Observe('has for database', Format(UpgradeTag.HasUpgradeTag(Tag, '')));
        Observer.Expect('has before set', 'No');
        Observer.Expect('has after set', 'Yes');
        Observer.Expect('has for own company', 'Yes');
        Observer.Expect('has for other company', 'No');
        Observer.Expect('has for database', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Item44_SetAllUpgradeTags_WithSubscriber()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Subs: Codeunit "LT CM Upgrade Tag Subs";
        Observer: Codeunit "Probe Observer";
        Tag: Code[250];
    begin
        Tag := NewTag();
        Subs.SetTag(Tag);
        UpgradeTag.SetAllUpgradeTags();
        Observer.Observe('unbound: has after SetAllUpgradeTags', Format(UpgradeTag.HasUpgradeTag(Tag)));
        BindSubscription(Subs);
        UpgradeTag.SetAllUpgradeTags();
        Observer.Observe('bound: has after SetAllUpgradeTags', Format(UpgradeTag.HasUpgradeTag(Tag)));
        UpgradeTag.SetAllUpgradeTags();
        Observer.Observe('bound: SetAllUpgradeTags again', Format(UpgradeTag.HasUpgradeTag(Tag)));
        UnbindSubscription(Subs);
        Observer.Expect('unbound: has after SetAllUpgradeTags', 'No');
        Observer.Expect('bound: has after SetAllUpgradeTags', 'Yes');
        Observer.Expect('bound: SetAllUpgradeTags again', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Item44_NewCompany_GetsTheSubscriberTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Subs: Codeunit "LT CM Upgrade Tag Subs";
        Company: Record Company;
        Observer: Codeunit "Probe Observer";
        Tag: Code[250];
        NewName: Text[30];
    begin
        Tag := NewTag();
        NewName := CopyStr('LT CM ' + CopyStr(Tag, 7, 20), 1, 30);
        Subs.SetTag(Tag);
        BindSubscription(Subs);
        Company.Init();
        Company.Name := NewName;
        Company.Insert();
        UnbindSubscription(Subs);
        Observer.Observe('new company has the tag', Format(UpgradeTag.HasUpgradeTag(Tag, NewName)));
        Observer.Observe('own company has the tag', Format(UpgradeTag.HasUpgradeTag(Tag)));
        Observer.Expect('new company has the tag', 'Yes');
        Observer.Expect('own company has the tag', 'No');
        Observer.Verify();
    end;
}

codeunit 84836 "LT CM Upgrade Tag Subs"
{
    EventSubscriberInstance = Manual;

    var
        TagToAdd: Code[250];

    procedure SetTag(Tag: Code[250])
    begin
        TagToAdd := Tag;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure AddTag(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(TagToAdd);
    end;
}
