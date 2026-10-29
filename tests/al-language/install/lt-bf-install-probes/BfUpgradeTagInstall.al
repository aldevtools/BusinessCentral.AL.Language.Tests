// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-upgrading-extensions
// Scope: in-scope
// Fixtures used: Upgrade Tag (codeunit 9999, System Application), Company-Initialize (codeunit 2, event OnCompanyInitialize).
// Probe: what an app sees of the upgrade tags and of the company initialization when it is installed fresh into companies that already exist.
//   74074 subscribes to OnGetPerCompanyUpgradeTags and adds the tag of this app. 74075 subscribes to OnCompanyInitialize and writes one row.
//   74076 (install codeunit) logs per company: HasUpgradeTag(tag) before anything, whether the OnCompanyInitialize row of that company exists,
//   then sets the tag and logs HasUpgradeTag again.
//   The tag is derived from the PackageId of the app, so a second install of the same source (a database that keeps the Upgrade Tags table, which
//   the System Application keeps internal and no uninstall clears) starts with a tag nobody has set.
// Install code must never fail (check-install-triggers.py): only `if Insert() then;` into DataPerCompany = false tables; the tag calls do not write
//   anything else. Tests: BfUpgradeTagInstallTests.al.
// BC versions: 27 - 29

table 74072 "LT UT Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Company"; Text[60]) { }
        field(3; "Tag"; Text[250]) { }
        field(4; "Has Tag Before"; Boolean) { }
        field(5; "Init Row Exists"; Boolean) { }
        field(6; "Has Tag After Set"; Boolean) { }
        field(7; "Init Rows All Companies"; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 74073 "LT UT Init Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Company"; Text[60]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 74074 "LT UT Tag Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure AddTag(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        Helper: Codeunit "LT UT Helper";
    begin
        PerCompanyUpgradeTags.Add(Helper.TagName());
    end;
}

codeunit 74075 "LT UT Init Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure LogInit()
    var
        Row: Record "LT UT Init Log";
    begin
        Row.Init();
        Row."Company" := CopyStr(CompanyName(), 1, MaxStrLen(Row."Company"));
        if Row.Insert() then;
    end;
}

codeunit 74077 "LT UT Helper"
{
    procedure TagName(): Code[250]
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(CopyStr('LT-UT-' + DelChr(Format(Info.PackageId), '=', '{}-'), 1, 250));
    end;
}

codeunit 74076 "LT UT Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Helper: Codeunit "LT UT Helper";
        InitRow: Record "LT UT Init Log";
        Row: Record "LT UT Install Log";
        Tag: Code[250];
    begin
        Tag := Helper.TagName();
        Row.Init();
        Row."Company" := CopyStr(CompanyName(), 1, MaxStrLen(Row."Company"));
        Row."Tag" := Tag;
        Row."Has Tag Before" := UpgradeTag.HasUpgradeTag(Tag);
        InitRow.SetRange("Company", CompanyName());
        Row."Init Row Exists" := not InitRow.IsEmpty();
        InitRow.Reset();
        Row."Init Rows All Companies" := InitRow.Count();
        UpgradeTag.SetUpgradeTag(Tag);
        Row."Has Tag After Set" := UpgradeTag.HasUpgradeTag(Tag);
        if Row.Insert() then;
    end;
}
