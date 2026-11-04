// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testtype-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (issue 612): codeunit TestType and RequiredTestIsolation, control add-in MaximumHeight and MaximumWidth, enum AssignmentCompatibilityReason,
// permission set ExcludedPermissionSets, profile ProfileDescriptionML, and the query properties EntityCaption, EntityCaptionML, EntitySetCaption,
// EntitySetCaptionML and HelpLink. TestHandlers and ContextSensitiveHelpPage cannot be used in this app (runtime 16.0, no contextSensitiveHelpUrl in
// the manifest): see the must-not-compile cases 0780-0795. Object ids 75020-75049.

codeunit 75020 "LT X Iso None"
{
    Subtype = Test;
    TestType = UnitTest;
    RequiredTestIsolation = None;
}

codeunit 75021 "LT X Iso Disabled"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
}

codeunit 75022 "LT X Iso Codeunit"
{
    Subtype = Test;
    TestType = Uncategorized;
    RequiredTestIsolation = Codeunit;
}

codeunit 75023 "LT X Iso Function"
{
    Subtype = Test;
    TestType = AITest;
    RequiredTestIsolation = Function;
}

codeunit 75024 "LT X Iso Default"
{
    Subtype = Test;
}

controladdin "LT X AddIn Max"
{
    MaximumHeight = 500;
    MaximumWidth = 600;
    MinimumHeight = 100;
    MinimumWidth = 120;
    RequestedHeight = 300;
    RequestedWidth = 400;

    event Ready();
}

controladdin "LT X AddIn Zero"
{
    MaximumHeight = 0;
    MaximumWidth = 0;
}

page 75025 "LT X AddIn Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            usercontrol(Max; "LT X AddIn Max")
            {
                ApplicationArea = All;
            }
            usercontrol(Zero; "LT X AddIn Zero")
            {
                ApplicationArea = All;
            }
        }
    }
}

enum 75026 "LT X Compat Target"
{
    Extensible = true;
    AssignmentCompatibility = true;
    AssignmentCompatibilityReason = 'Kept for older code that assigned the source enum.';

    value(0; None) { }
    value(1; First) { }
    value(2; Second) { }
}

enum 75027 "LT X Compat Source"
{
    value(0; None) { }
    value(1; First) { }
    value(2; Second) { }
}

codeunit 75028 "LT X Compat Assign"
{
    procedure Assign(Source: Enum "LT X Compat Source") Target: Enum "LT X Compat Target"
    begin
#pragma warning disable AL0592
        Target := Source;
#pragma warning restore AL0592
    end;
}

table 75029 "LT X Perm Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

permissionset 75030 "LT X PS Base"
{
    Assignable = true;
    Permissions = tabledata "LT X Perm Table" = RIM;
}

permissionset 75031 "LT X PS Neg"
{
    Assignable = true;
    Permissions = tabledata "LT X Perm Table" = IM;
}

permissionset 75032 "LT X PS Main"
{
    Assignable = true;
    IncludedPermissionSets = "LT X PS Base";
    ExcludedPermissionSets = "LT X PS Neg";
}

permissionset 75033 "LT X PS Control"
{
    Assignable = true;
    IncludedPermissionSets = "LT X PS Base";
}

page 75034 "LT X Role Center"
{
    PageType = RoleCenter;
    ApplicationArea = All;
    UsageCategory = None;
}

profile "LT X Profile Desc"
{
    Caption = 'LT X Profile Caption';
    Description = 'internal text';
    ProfileDescriptionML = ENU = 'English profile text', DEU = 'Deutscher Profiltext';
    RoleCenter = "LT X Role Center";
}

table 75035 "LT X Query Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

query 75036 "LT X Api Plain"
{
    QueryType = API;
    Caption = 'LT X Api Plain Caption';
    APIPublisher = 'ltx';
    APIGroup = 'props';
    APIVersion = 'v1.0';
    EntityName = 'ltxPlainItem';
    EntitySetName = 'ltxPlainItems';
    EntityCaption = 'Plain Item';
    EntitySetCaption = 'Plain Items';
    HelpLink = 'https://example.com/help';

    elements
    {
        dataitem(Source; "LT X Query Source")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }
}

query 75037 "LT X Api Ml"
{
    QueryType = API;
    APIPublisher = 'ltx';
    APIGroup = 'props';
    APIVersion = 'v1.0';
    EntityName = 'ltxMlItem';
    EntitySetName = 'ltxMlItems';
    EntityCaptionML = ENU = 'Ml Item', DEU = 'Ml Artikel';
    EntitySetCaptionML = ENU = 'Ml Items', DEU = 'Ml Artikel Mehrzahl';

    elements
    {
        dataitem(Source; "LT X Query Source")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }
}

codeunit 75039 "LT X Object Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CurrentAppId(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id);
    end;

    local procedure CodeunitFacts(CodeunitId: Integer): Text
    var
        Meta: Record "CodeUnit Metadata";
    begin
        Meta.Get(CodeunitId);
        exit(Meta.Name + '|subtype=' + Format(Meta.SubType) + '|testtype=' + Format(Meta.TestType) + '|isolation=' + Format(Meta.RequiredTestIsolation) +
            '|testtype_ord=' + Format(Meta.TestType, 0, 2) + '|isolation_ord=' + Format(Meta.RequiredTestIsolation, 0, 2));
    end;

    [Test]
    procedure TestCodeunits_TestTypeAndRequiredTestIsolation_InMetadata()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('none_unittest', CodeunitFacts(Codeunit::"LT X Iso None"));
        Observer.Observe('disabled_integration', CodeunitFacts(Codeunit::"LT X Iso Disabled"));
        Observer.Expect('none_unittest', 'LT X Iso None|subtype=Test|testtype=UnitTest|isolation=None|testtype_ord=1|isolation_ord=0');
        Observer.Expect('disabled_integration', 'LT X Iso Disabled|subtype=Test|testtype=IntegrationTest|isolation=Disabled|testtype_ord=2|isolation_ord=1');
        Observer.Verify();
    end;

    [Test]
    procedure TestCodeunits_TestTypeAndRequiredTestIsolation_InMetadata2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('codeunit_uncategorized', CodeunitFacts(Codeunit::"LT X Iso Codeunit"));
        Observer.Observe('function_ai', CodeunitFacts(Codeunit::"LT X Iso Function"));
        Observer.Expect('codeunit_uncategorized', 'LT X Iso Codeunit|subtype=Test|testtype=Uncategorized|isolation=Codeunit|testtype_ord=3|isolation_ord=2');
        Observer.Expect('function_ai', 'LT X Iso Function|subtype=Test|testtype=AITest|isolation=Function|testtype_ord=4|isolation_ord=3');
        Observer.Verify();
    end;

    [Test]
    procedure TestCodeunits_TestTypeAndRequiredTestIsolation_InMetadata3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('defaults', CodeunitFacts(Codeunit::"LT X Iso Default"));
        Observer.Observe('this_codeunit', CodeunitFacts(Codeunit::"LT X Object Props Tests"));
        Observer.Expect('defaults', 'LT X Iso Default|subtype=Test|testtype=UnitTest|isolation=None|testtype_ord=1|isolation_ord=0');
        Observer.Expect('this_codeunit', 'LT X Object Props Tests|subtype=Test|testtype=UnitTest|isolation=None|testtype_ord=1|isolation_ord=0');
        Observer.Verify();
    end;

    [Test]
    procedure ControlAddIn_MaximumHeightAndWidth_PageOpens()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT X AddIn Page";
    begin
        Pg.OpenView();
        Observer.Observe('opened', 'yes');
        Pg.Close();
        Observer.Expect('opened', 'yes');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_AssignmentCompatibilityReason_AssignmentWorks()
    var
        Observer: Codeunit "Probe Observer";
        Assigner: Codeunit "LT X Compat Assign";
        Source: Enum "LT X Compat Source";
        Target: Enum "LT X Compat Target";
    begin
        Source := Source::Second;
        Target := Assigner.Assign(Source);
        Observer.Observe('target_after_assign', Format(Target));
        Observer.Observe('target_ordinal', Format(Target.AsInteger()));
        Source := Source::None;
        Target := Assigner.Assign(Source);
        Observer.Observe('target_none', Format(Target));
        Observer.Expect('target_after_assign', 'Second');
        Observer.Expect('target_ordinal', '2');
        Observer.Expect('target_none', 'None');
        Observer.Verify();
    end;

    local procedure ExpandedFacts(RoleId: Text): Text
    var
        Expanded: Record "Expanded Permission";
    begin
        Expanded.SetRange("App ID", CurrentAppId());
        Expanded.SetRange("Role ID", RoleId);
        Expanded.SetRange("Object Type", Expanded."Object Type"::"Table Data");
        Expanded.SetRange("Object ID", Database::"LT X Perm Table");
        if not Expanded.FindFirst() then
            exit('no row');
        exit('R=' + Format(Expanded."Read Permission") + ' I=' + Format(Expanded."Insert Permission") + ' M=' + Format(Expanded."Modify Permission") +
            ' D=' + Format(Expanded."Delete Permission") + ' count=' + Format(Expanded.Count()));
    end;

    [Test]
    procedure PermissionSet_ExcludedPermissionSets_RemovedFromEffectiveSet()
    var
        Observer: Codeunit "Probe Observer";
        Relation: Record "Metadata Permission Set Rel.";
        Declared: Record "Metadata Permission";
    begin
        Observer.Observe('base', ExpandedFacts('LT X PS BASE'));
        Observer.Observe('neg', ExpandedFacts('LT X PS NEG'));
        Observer.Observe('main_includes_base_excludes_neg', ExpandedFacts('LT X PS MAIN'));
        Observer.Observe('control_includes_base_only', ExpandedFacts('LT X PS CONTROL'));
        Relation.SetRange("App ID", CurrentAppId());
        Relation.SetRange("Role ID", 'LT X PS MAIN');
        Observer.Observe('main_relation_count', Format(Relation.Count()));
        if Relation.FindSet() then
            repeat
                Observer.Observe('main_relation_' + Relation."Related Role ID", Format(Relation.Type));
            until Relation.Next() = 0;
        Declared.SetRange("App ID", CurrentAppId());
        Declared.SetRange("Role ID", 'LT X PS MAIN');
        Observer.Observe('main_declared_permissions', Format(Declared.Count()));
        Observer.Expect('base', 'R=Yes I=Yes M=Yes D=  count=1');
        Observer.Expect('neg', 'R=  I=Yes M=Yes D=  count=1');
        Observer.Expect('main_includes_base_excludes_neg', 'R=Yes I=  M=  D=  count=1');
        Observer.Expect('control_includes_base_only', 'R=Yes I=Yes M=Yes D=  count=1');
        Observer.Expect('main_relation_count', '2');
        Observer.Expect('main_relation_LT X PS BASE', 'Include');
        Observer.Expect('main_relation_LT X PS NEG', 'Exclude');
        Observer.Expect('main_declared_permissions', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Profile_ProfileDescriptionML_DescriptionPerLanguage()
    var
        Observer: Codeunit "Probe Observer";
        AllProfile: Record "All Profile";
        OldLanguage: Integer;
        Language: Integer;
        Name: Text;
    begin
        OldLanguage := GlobalLanguage();
        foreach Language in LanguageList() do begin
            GlobalLanguage(Language);
            case Language of
                1033:
                    Name := 'enu';
                1031:
                    Name := 'deu';
                else
                    Name := 'fra';
            end;
            AllProfile.Reset();
            AllProfile.SetRange("App ID", CurrentAppId());
            AllProfile.SetRange("Profile ID", 'LT X Profile Desc');
            if AllProfile.FindFirst() then begin
                Observer.Observe(Name + '_description', AllProfile.Description);
                Observer.Observe(Name + '_caption', AllProfile.Caption);
            end else
                Observer.Observe(Name + '_row', 'missing');
        end;
        GlobalLanguage(OldLanguage);
        Observer.Expect('enu_description', 'English profile text');
        Observer.Expect('enu_caption', 'LT X Profile Caption');
        Observer.Expect('deu_description', 'Deutscher Profiltext');
        Observer.Expect('deu_caption', 'LT X Profile Caption');
        Observer.Expect('fra_description', 'English profile text');
        Observer.Expect('fra_caption', 'LT X Profile Caption');
        Observer.Verify();
    end;

    local procedure QueryFacts(QueryId: Integer): Text
    var
        Meta: Record "Query Metadata";
    begin
        if not Meta.Get(QueryId) then
            exit('no row');
        exit('caption=' + Meta.Caption + '|name=' + Meta.Name + '|entity=' + Meta.EntityName + '|set=' + Meta.EntitySetName + '|publisher=' + Meta.APIPublisher +
            '|group=' + Meta.APIGroup + '|version=' + Meta.APIVersion);
    end;

    [Test]
    procedure Query_EntityCaptions_ApiMetadataPerLanguage()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Observer.Observe('enu_plain', QueryFacts(Query::"LT X Api Plain"));
        Observer.Observe('enu_ml', QueryFacts(Query::"LT X Api Ml"));
        GlobalLanguage(OldLanguage);
        Observer.Expect('enu_plain', 'caption=LT X Api Plain Caption|name=LT X Api Plain|entity=ltxPlainItem|set=ltxPlainItems|publisher=ltx|group=props|version=v1.0');
        Observer.Expect('enu_ml', 'caption=LT X Api Ml|name=LT X Api Ml|entity=ltxMlItem|set=ltxMlItems|publisher=ltx|group=props|version=v1.0');
        Observer.Verify();
    end;

    [Test]
    procedure Query_EntityCaptions_ApiMetadataPerLanguageDeu()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1031);
        Observer.Observe('deu_plain', QueryFacts(Query::"LT X Api Plain"));
        Observer.Observe('deu_ml', QueryFacts(Query::"LT X Api Ml"));
        GlobalLanguage(OldLanguage);
        Observer.Expect('deu_plain', 'caption=LT X Api Plain Caption|name=LT X Api Plain|entity=ltxPlainItem|set=ltxPlainItems|publisher=ltx|group=props|version=v1.0');
        Observer.Expect('deu_ml', 'caption=LT X Api Ml|name=LT X Api Ml|entity=ltxMlItem|set=ltxMlItems|publisher=ltx|group=props|version=v1.0');
        Observer.Verify();
    end;

    [Test]
    procedure Query_EntityCaptions_ApiMetadataPerLanguageFra()
    var
        Observer: Codeunit "Probe Observer";
        OldLanguage: Integer;
    begin
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1036);
        Observer.Observe('fra_plain', QueryFacts(Query::"LT X Api Plain"));
        Observer.Observe('fra_ml', QueryFacts(Query::"LT X Api Ml"));
        GlobalLanguage(OldLanguage);
        Observer.Expect('fra_plain', 'caption=LT X Api Plain Caption|name=LT X Api Plain|entity=ltxPlainItem|set=ltxPlainItems|publisher=ltx|group=props|version=v1.0');
        Observer.Expect('fra_ml', 'caption=LT X Api Ml|name=LT X Api Ml|entity=ltxMlItem|set=ltxMlItems|publisher=ltx|group=props|version=v1.0');
        Observer.Verify();
    end;

    [Test]
    procedure Query_HelpLinkAndEntityCaptions_ReadsUnchanged()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT X Query Source";
        PlainQuery: Query "LT X Api Plain";
        MlQuery: Query "LT X Api Ml";
        Rows: Text;
    begin
        Source.DeleteAll();
        Source.Id := 1;
        Source.Name := 'one';
        Source.Insert();
        Source.Id := 2;
        Source.Name := 'two';
        Source.Insert();
        PlainQuery.Open();
        while PlainQuery.Read() do
            Rows += Format(PlainQuery.Id) + '=' + PlainQuery.Name + ';';
        PlainQuery.Close();
        Observer.Observe('plain_rows', Rows);
        Rows := '';
        MlQuery.Open();
        while MlQuery.Read() do
            Rows += Format(MlQuery.Id) + '=' + MlQuery.Name + ';';
        MlQuery.Close();
        Observer.Observe('ml_rows', Rows);
        Observer.Expect('plain_rows', '1=one;2=two;');
        Observer.Expect('ml_rows', '1=one;2=two;');
        Observer.Verify();
    end;

    local procedure LanguageList() Languages: List of [Integer]
    begin
        Languages.Add(1033);
        Languages.Add(1031);
        Languages.Add(1036);
    end;
}
