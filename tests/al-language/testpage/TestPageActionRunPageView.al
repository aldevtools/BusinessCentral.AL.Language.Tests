// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpageview-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: ARPV Row (67002), ARPV Probe (67003), ARPV Target (67004), ARPV Host (67005),
//                ARPV Skills Probe (67008), Assert (60021) -- and Base Application pages
//                6018 "Skill Codes" and 6019 "Resource Skills"
//
/// <summary>
/// Pins what an ACTION's RunPageView does to the page it opens: which rows the page shows, in
/// what order, and which filter group the view's filter lands in.
///
/// RunPageView is the action-side sibling of a part's SubPageView (TestPartSubPageView.al) and
/// sits beside RunPageLink (TestActionRunPageLinkFilterGroup.al) on the same action. The corpus
/// covered the link and the part view, and mentioned RunPageView nowhere.
///
/// Written by agent stma-auto-3, an automated implementation agent acting on the account
/// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4974, which
/// measured that the runner reads an action's RunPageView nowhere.
///
/// EVERY ARM ASSERTS ONE STRING carrying the row the opened page stood on, the rows it showed,
/// AND the state its OnOpenPage saw: the filter group Rec is in when OnOpenPage starts (fg=,
/// read before anything changes it -- a filter an OnOpenPage then sets lands in that group), the
/// view's filter in groups 0, 2, 3 and 4, the current key and the sort direction. One
/// assertion, so a failure prints everything BC did rather than stopping at the first
/// difference.
///
/// The rows are read by walking the opened TestPage in the page handler; the state is read by
/// the target's own OnOpenPage through a SingleInstance probe. Four seeded rows:
///     entry 1 KEEP rank 30, entry 2 DROP rank 5, entry 3 KEEP rank 10, entry 4 KEEP rank 20
/// so primary-key order (1,2,3,4), the KEEP filter (1,3,4) and rank order within KEEP (3,4,1)
/// all differ from one another.
///
/// The last arm reaches the same property on a PRECOMPILED Base Application page: "Skill
/// Codes" declares
///     RunObject = Page "Resource Skills"; RunPageLink = "Skill Code" = field(Code);
///     RunPageView = sorting("Skill Code") where(Type = const(Resource));
/// so a Resource Skill of Type Item under the same skill code is excluded by the view alone.
/// </summary>

table 67002 "ARPV Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Bucket; Code[10]) { }
        field(3; Rank; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ByRank; Rank) { }
    }
}

codeunit 67003 "ARPV Probe"
{
    SingleInstance = true;

    var
        OpenState: Text;
        Shown: Text;

    procedure Reset()
    begin
        OpenState := '';
        Shown := '';
    end;

    procedure RecordOpenState(NewState: Text)
    begin
        OpenState := NewState;
    end;

    procedure RecordShown(NewShown: Text)
    begin
        Shown := NewShown;
    end;

    procedure Observed(): Text
    begin
        exit(Shown + '|' + OpenState);
    end;
}

page 67004 "ARPV Target"
{
    PageType = List;
    SourceTable = "ARPV Row";
    ApplicationArea = All;
    Caption = 'ARPV Target';
    // Not editable, so walking the rows cannot meet a trailing blank new row.
    Editable = false;
    // No SourceTableView: the subject is the ACTION's view, and a page view would confound it.

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Bucket; Rec.Bucket) { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Probe: Codeunit "ARPV Probe";
        F0: Text;
        F2: Text;
        F3: Text;
        F4: Text;
        StartGroup: Text;
    begin
        // First, before any FilterGroup(n) call moves it.
        StartGroup := Format(Rec.FilterGroup());
        Rec.FilterGroup(0);
        F0 := Rec.GetFilter(Bucket);
        Rec.FilterGroup(2);
        F2 := Rec.GetFilter(Bucket);
        Rec.FilterGroup(3);
        F3 := Rec.GetFilter(Bucket);
        Rec.FilterGroup(4);
        F4 := Rec.GetFilter(Bucket);
        Rec.FilterGroup(0);
        Probe.RecordOpenState(
            'fg=' + StartGroup + '|g0=' + F0 + '|g2=' + F2 + '|g3=' + F3 + '|g4=' + F4 +
            '|key=' + Rec.CurrentKey() + '|asc=' + Format(Rec.Ascending()));
    end;
}

page 67005 "ARPV Host"
{
    PageType = Card;
    SourceTable = "ARPV Row";
    ApplicationArea = All;
    Caption = 'ARPV Host';

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
            field(Bucket; Rec.Bucket) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenPlain)
            {
                ApplicationArea = All;
                Caption = 'Open Plain';
                RunObject = page "ARPV Target";
            }
            action(OpenFiltered)
            {
                ApplicationArea = All;
                Caption = 'Open Filtered';
                RunObject = page "ARPV Target";
                RunPageView = where(Bucket = const('KEEP'));
            }
            action(OpenSortedFiltered)
            {
                ApplicationArea = All;
                Caption = 'Open Sorted Filtered';
                RunObject = page "ARPV Target";
                RunPageView = sorting(Rank) where(Bucket = const('KEEP'));
            }
            action(OpenDescending)
            {
                ApplicationArea = All;
                Caption = 'Open Descending';
                RunObject = page "ARPV Target";
                RunPageView = sorting("Entry No.") order(descending);
            }
            action(OpenOnRecSorted)
            {
                ApplicationArea = All;
                Caption = 'Open On Rec Sorted';
                RunObject = page "ARPV Target";
                RunPageOnRec = true;
                RunPageView = sorting(Rank) where(Bucket = const('KEEP'));
            }
            action(OpenLinkedSorted)
            {
                ApplicationArea = All;
                Caption = 'Open Linked Sorted';
                RunObject = page "ARPV Target";
                RunPageLink = Bucket = field(Bucket);
                RunPageView = sorting(Rank);
            }
        }
    }
}

codeunit 67006 "ARPV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "ARPV Row";
        Probe: Codeunit "ARPV Probe";
    begin
        Probe.Reset();
        Row.DeleteAll();
        AddRow(1, 'KEEP', 30);
        AddRow(2, 'DROP', 5);
        AddRow(3, 'KEEP', 10);
        AddRow(4, 'KEEP', 20);
    end;

    local procedure AddRow(EntryNo: Integer; NewBucket: Code[10]; NewRank: Integer)
    var
        Row: Record "ARPV Row";
    begin
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Bucket := NewBucket;
        Row.Rank := NewRank;
        Row.Insert();
    end;

    local procedure OpenHost(var Host: TestPage "ARPV Host"; EntryNo: Integer)
    begin
        Seed();
        Host.OpenEdit();
        Host.GoToKey(EntryNo);
    end;

    [Test]
    [HandlerFunctions('ArpvTargetHandler')]
    procedure NoRunPageView_ShowsEveryRowInKeyOrder()
    // The control: the same host, rows and target, with no view. Every row, primary-key order,
    // no filter anywhere -- so what the other arms show is the view's doing.
    var
        Host: TestPage "ARPV Host";
        Probe: Codeunit "ARPV Probe";
    begin
        OpenHost(Host, 1);
        Host.OpenPlain.Invoke();
        Host.Close();

        Assert.AreEqual(
            'cur=1;rows=1,2,3,4|fg=0|g0=|g2=|g3=|g4=|key=Entry No.|asc=Yes', Probe.Observed(),
            'An action with no RunPageView opens its page on every row, in primary-key order.');
    end;

    [Test]
    [HandlerFunctions('ArpvTargetHandler')]
    procedure RunPageView_Where_FiltersTheOpenedPage()
    var
        Host: TestPage "ARPV Host";
        Probe: Codeunit "ARPV Probe";
    begin
        OpenHost(Host, 1);
        Host.OpenFiltered.Invoke();
        Host.Close();

        Assert.AreEqual(
            'cur=1;rows=1,3,4|fg=0|g0=|g2=|g3=KEEP|g4=|key=Entry No.|asc=Yes', Probe.Observed(),
            'An action''s RunPageView where() filters the page it opens.');
    end;

    [Test]
    [HandlerFunctions('ArpvTargetHandler')]
    procedure RunPageView_SortingAndWhere_FiltersAndOrdersTheOpenedPage()
    var
        Host: TestPage "ARPV Host";
        Probe: Codeunit "ARPV Probe";
    begin
        OpenHost(Host, 1);
        Host.OpenSortedFiltered.Invoke();
        Host.Close();

        Assert.AreEqual(
            'cur=3;rows=3,4,1|fg=0|g0=|g2=|g3=KEEP|g4=|key=Rank|asc=Yes', Probe.Observed(),
            'An action''s RunPageView sorting() orders, and its where() filters, the page it opens.');
    end;

    [Test]
    [HandlerFunctions('ArpvTargetHandler')]
    procedure RunPageView_OrderDescending_ReversesTheOpenedPage()
    var
        Host: TestPage "ARPV Host";
        Probe: Codeunit "ARPV Probe";
    begin
        OpenHost(Host, 1);
        Host.OpenDescending.Invoke();
        Host.Close();

        Assert.AreEqual(
            'cur=4;rows=4,3,2,1|fg=0|g0=|g2=|g3=|g4=|key=Entry No.|asc=No', Probe.Observed(),
            'An action''s RunPageView order(descending) opens the page in descending order.');
    end;

    [Test]
    [HandlerFunctions('ArpvTargetHandler')]
    procedure RunPageView_WithRunPageOnRec_OpensOnTheHostRowInsideTheView()
    // RunPageOnRec hands the target the host's row; the view still filters and orders it.
    // Host on entry 4, which is neither the first row by key nor by rank.
    var
        Host: TestPage "ARPV Host";
        Probe: Codeunit "ARPV Probe";
    begin
        OpenHost(Host, 4);
        Host.OpenOnRecSorted.Invoke();
        Host.Close();

        Assert.AreEqual(
            'cur=4;rows=3,4,1|fg=0|g0=|g2=|g3=KEEP|g4=|key=Rank|asc=Yes', Probe.Observed(),
            'RunPageOnRec opens the page on the host row, with the RunPageView filter and order applied.');
    end;

    [Test]
    [HandlerFunctions('ArpvTargetHandler')]
    procedure RunPageView_SortingWithRunPageLink_SortsTheLinkedRows()
    // The link filters to the host row's bucket (group 0, TestActionRunPageLinkFilterGroup.al);
    // the view carries no where(), only the order. Host on entry 1, a KEEP row.
    var
        Host: TestPage "ARPV Host";
        Probe: Codeunit "ARPV Probe";
    begin
        OpenHost(Host, 1);
        Host.OpenLinkedSorted.Invoke();
        Host.Close();

        Assert.AreEqual(
            'cur=3;rows=3,4,1|fg=0|g0=KEEP|g2=|g3=|g4=|key=Rank|asc=Yes', Probe.Observed(),
            'RunPageLink filters and RunPageView sorts the same opened page.');
    end;

    [PageHandler]
    procedure ArpvTargetHandler(var Target: TestPage "ARPV Target")
    var
        Probe: Codeunit "ARPV Probe";
        Shown: Text;
        Guard: Integer;
    begin
        // The row the page opened on, before First() moves it.
        Shown := 'cur=' + Target."Entry No.".Value() + ';rows=';
        if Target.First() then
            repeat
                if Guard > 0 then
                    Shown += ',';
                Shown += Target."Entry No.".Value();
                Guard += 1;
            until (not Target.Next()) or (Guard >= 10);
        Probe.RecordShown(Shown);
        Target.Close();
    end;
}

codeunit 67008 "ARPV Skills Probe"
{
    // Bound only by the arm that reads it, so no other test opening Resource Skills sees it.
    EventSubscriberInstance = Manual;

    var
        State: Text;

    [EventSubscriber(ObjectType::Page, Page::"Resource Skills", 'OnOpenPageEvent', '', false, false)]
    local procedure ReadFilterGroups(var Rec: Record "Resource Skill")
    begin
        // First, before any FilterGroup(n) call below moves it.
        State := 'fg=' + Format(Rec.FilterGroup());
        ReadGroup(Rec, 0);
        ReadGroup(Rec, 2);
        ReadGroup(Rec, 3);
        ReadGroup(Rec, 4);
        Rec.FilterGroup(0);
    end;

    local procedure ReadGroup(var Rec: Record "Resource Skill"; Group: Integer)
    begin
        Rec.FilterGroup(Group);
        State += '|g' + Format(Group) + ':type=' + Rec.GetFilter(Type) + ',skill=' + Rec.GetFilter("Skill Code");
    end;

    procedure Observed(): Text
    begin
        exit(State);
    end;
}

codeunit 67007 "ARPV Precompiled Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ResourceSkillsShown: Text;

    [Test]
    [HandlerFunctions('ResourceSkillsHandler')]
    procedure PrecompiledRunPageView_Where_ExcludesRowsOutsideTheView()
    // Base Application page 6018 "Skill Codes", action "&Resource Skills". The link narrows the
    // target to this skill code; the view's where(Type = const(Resource)) is the only thing that
    // excludes the Item row seeded under the same code.
    var
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        Host: TestPage "Skill Codes";
    begin
        ResourceSkillsShown := '';
        if SkillCode.Get('ARPVSK') then
            SkillCode.Delete();
        SkillCode.Init();
        SkillCode.Code := 'ARPVSK';
        SkillCode.Insert();
        ResourceSkill.SetRange("Skill Code", 'ARPVSK');
        ResourceSkill.DeleteAll();
        AddResourceSkill(ResourceSkill.Type::Resource, 'ARPV-R2');
        AddResourceSkill(ResourceSkill.Type::Item, 'ARPV-I1');
        AddResourceSkill(ResourceSkill.Type::Resource, 'ARPV-R1');
        Assert.AreEqual(3, ResourceSkill.Count(), 'three resource skills are seeded under the skill code, one of them an Item');

        Host.OpenView();
        Host.GoToKey('ARPVSK');
        Host."&Resource Skills".Invoke();
        Host.Close();

        Assert.AreEqual(
            'ARPV-R1,ARPV-R2', ResourceSkillsShown,
            'The precompiled action''s RunPageView where(Type = const(Resource)) excludes the Item row.');
    end;

    [Test]
    [HandlerFunctions('ResourceSkillsHandler')]
    procedure PrecompiledRunPageView_WhereLandsInFilterGroup3_LinkInGroup0()
    // WHICH GROUP each filter lands in on the precompiled route, read from the target page's
    // OnOpenPageEvent: the link's "Skill Code" in 0, the view's Type in 3 -- the same split the
    // source-compiled arms measure on ARPV Target.
    var
        Probe: Codeunit "ARPV Skills Probe";
        Host: TestPage "Skill Codes";
    begin
        SeedSkills();
        BindSubscription(Probe);

        Host.OpenView();
        Host.GoToKey('ARPVSK');
        Host."&Resource Skills".Invoke();
        Host.Close();
        UnbindSubscription(Probe);

        Assert.AreEqual(
            'fg=0|g0:type=,skill=ARPVSK|g2:type=,skill=|g3:type=Resource,skill=|g4:type=,skill=',
            Probe.Observed(),
            'The precompiled action''s RunPageLink lands in FilterGroup(0) and its RunPageView where() in FilterGroup(3).');
    end;

    local procedure SeedSkills()
    var
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
    begin
        ResourceSkillsShown := '';
        if SkillCode.Get('ARPVSK') then
            SkillCode.Delete();
        SkillCode.Init();
        SkillCode.Code := 'ARPVSK';
        SkillCode.Insert();
        ResourceSkill.SetRange("Skill Code", 'ARPVSK');
        ResourceSkill.DeleteAll();
        AddResourceSkill(ResourceSkill.Type::Resource, 'ARPV-R2');
        AddResourceSkill(ResourceSkill.Type::Item, 'ARPV-I1');
        AddResourceSkill(ResourceSkill.Type::Resource, 'ARPV-R1');
    end;

    local procedure AddResourceSkill(SkillType: Enum "Resource Skill Type"; No: Code[20])
    var
        ResourceSkill: Record "Resource Skill";
    begin
        ResourceSkill.Init();
        ResourceSkill.Type := SkillType;
        ResourceSkill."No." := No;
        ResourceSkill."Skill Code" := 'ARPVSK';
        ResourceSkill.Insert();
    end;

    [PageHandler]
    procedure ResourceSkillsHandler(var ResourceSkills: TestPage "Resource Skills")
    var
        Guard: Integer;
    begin
        if ResourceSkills.First() then
            repeat
                if ResourceSkills."No.".Value() <> '' then begin
                    if ResourceSkillsShown <> '' then
                        ResourceSkillsShown += ',';
                    ResourceSkillsShown += ResourceSkills."No.".Value();
                end;
                Guard += 1;
            until (not ResourceSkills.Next()) or (Guard >= 10);
        ResourceSkills.Close();
    end;
}
