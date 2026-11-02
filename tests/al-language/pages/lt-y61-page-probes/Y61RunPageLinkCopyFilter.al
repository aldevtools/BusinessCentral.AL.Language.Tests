// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpagelink-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 93240 (Y61Log.al); tables 93250-93251, pages 93256-93258, mode codeunit 93247
//   (SingleInstance, used only by test codeunit 93246), test codeunit 93246
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: what the filter-copy and filter-read methods answer on Rec itself in the OnOpenPage of a ListPlus page that an action opens
//   through RunPageLink = Code = field(Code) (and Code + a FlowFilter "Date Filter" = field("Date Filter")): Rec.CopyFilter of the linked
//   field and of a FlowFilter the link does not set into another record (also over a filter that record had), Other.CopyFilters(Rec),
//   Other.Copy(Rec), Rec.HasFilter, GetFilter, GetView, FilterGroup, Count, FindFirst, and Rec passed by var to a procedure of a part
//   page that sets its own filter and copies the host's "Date Filter" (the part's rows). Each probe runs in a TryFunction of the page and
//   logs its value, or the error text and code. Date filter texts are in the format of the CI (en-US).
// Neighbours: handlers/QzRunPageLinkOnOpen.al (fields and GetFilters of Rec, a by-value copy), pages/lt-y41-page-probes/Y41RunPageLinkOnOpen.al.
// Measured (27.5, 28.5, 29.0 and SaaS 29 alike): Rec carries the link filter 'Code: P1' and nothing else: CopyFilter of the linked field hands
//   'P1' (over the target's own filter), CopyFilter of the FlowFilter the link does not set CLEARS the target's filter, CopyFilters and
//   Copy hand 'Code: P1' (count 1), HasFilter Yes, GetView 'VERSION(1) SORTING(Field1) WHERE(Field1=1(P1))', FilterGroup 0, Count 1,
//   FindFirst finds P1. With the FlowFilter in the link Rec also has the host's "Date Filter". The part sees Rec's filters through the var
//   parameter, but the filter it sets on its own Rec in the host's OnOpenPage does not narrow its rows (all rows and a new line shown).
// BC versions: all (CI)

table 93250 "LT Y61 RL P"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; "Date Filter"; Date) { FieldClass = FlowFilter; }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

table 93251 "LT Y61 RL Q"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Parent Code"; Code[20]) { }
        field(2; Name; Code[10]) { }
        field(3; "Date Filter"; Date) { FieldClass = FlowFilter; }
    }

    keys { key(PK; "Parent Code", Name) { Clustered = true; } }
}

codeunit 93247 "LT Y61 RL Mode"
{
    SingleInstance = true;

    var
        Mode: Text;

    procedure SetMode(Value: Text)
    begin
        Mode := Value;
    end;

    procedure GetMode(): Text
    begin
        exit(Mode);
    end;
}

page 93257 "LT Y61 RL Part"
{
    PageType = ListPart;
    SourceTable = "LT Y61 RL Q";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(ParentCtl; Rec."Parent Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    procedure UpdateForm(var HostRec: Record "LT Y61 RL P"): Text
    begin
        Rec.SetRange("Parent Code", HostRec.Code);
        HostRec.CopyFilter("Date Filter", Rec."Date Filter");
        exit('part filters=' + Rec.GetFilters() + ';part host filters=' + HostRec.GetFilters());
    end;
}

page 93256 "LT Y61 RL Target"
{
    PageType = ListPlus;
    SourceTable = "LT Y61 RL P";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
            part(Sub; "LT Y61 RL Part")
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Lines: Text;

    trigger OnOpenPage()
    var
        Log: Record "LT Y61 Log";
        ModeCu: Codeunit "LT Y61 RL Mode";
        Mode: Text;
    begin
        Mode := ModeCu.GetMode();
        Log.AddLine('open code=' + Rec.Code);
        Lines := '';
        if not TryProbe(Mode) then
            Lines += 'error ' + Mode + ' text=' + GetLastErrorText() + ' code=' + GetLastErrorCode();
        ClearLastError();
        Log.AddLine(Lines);
    end;

    // A TryFunction may not write to the database (the log table): the probe collects its lines in Lines.
    local procedure Add(Line: Text)
    begin
        if Lines <> '' then
            Lines += ';';
        Lines += Line;
    end;

    [TryFunction]
    local procedure TryProbe(Mode: Text)
    var
        Other: Record "LT Y61 RL Q";
        Other2: Record "LT Y61 RL P";
    begin
        case Mode of
            'copyfilter-code':
                begin
                    Other.SetRange("Parent Code", 'ZZ');
                    Add('before=' + Other.GetFilter("Parent Code"));
                    Rec.CopyFilter(Code, Other."Parent Code");
                    Add('after=' + Other.GetFilter("Parent Code") + ' hasfilter=' + Format(Other.HasFilter()) + ' count=' + Format(Other.Count()));
                end;
            'copyfilter-date':
                begin
                    Other.SetRange("Date Filter", 20240101D, 20240131D);
                    Add('before=' + Other.GetFilter("Date Filter"));
                    Rec.CopyFilter("Date Filter", Other."Date Filter");
                    Add('after=' + Other.GetFilter("Date Filter") + ' hasfilter=' + Format(Other.HasFilter()));
                    Other.Reset();
                    Rec.CopyFilter("Date Filter", Other."Date Filter");
                    Add('fresh=' + Other.GetFilter("Date Filter") + ' hasfilter=' + Format(Other.HasFilter()));
                end;
            'part':
                Add(CurrPage.Sub.Page.UpdateForm(Rec));
            'copyfilters':
                begin
                    Other2.SetRange(Name, 'zz');
                    Other2.CopyFilters(Rec);
                    Add('copyfilters filters=' + Other2.GetFilters() + ' count=' + Format(Other2.Count()));
                end;
            'copy':
                begin
                    Other2.Copy(Rec);
                    Add('copy code=' + Other2.Code + ' filters=' + Other2.GetFilters() + ' count=' + Format(Other2.Count()));
                end;
            'reads':
                begin
                    Add('hasfilter=' + Format(Rec.HasFilter()));
                    Add('getfilter code=' + Rec.GetFilter(Code));
                    Add('getfilter date=' + Rec.GetFilter("Date Filter"));
                    Add('view=' + Rec.GetView(false));
                    Add('filtergroup=' + Format(Rec.FilterGroup()));
                    Add('count=' + Format(Rec.Count()));
                    Add('findfirst=' + Format(Rec.FindFirst()) + ' code=' + Rec.Code + ' name=' + Rec.Name);
                end;
            'flowlink':
                begin
                    Add('getfilter date=' + Rec.GetFilter("Date Filter"));
                    Rec.CopyFilter("Date Filter", Other."Date Filter");
                    Add('date after=' + Other.GetFilter("Date Filter"));
                    Rec.CopyFilter(Code, Other."Parent Code");
                    Add('code after=' + Other.GetFilter("Parent Code"));
                end;
        end;
    end;
}

page 93258 "LT Y61 RL Host"
{
    PageType = Card;
    SourceTable = "LT Y61 RL P";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Open)
            {
                ApplicationArea = All;
                RunObject = page "LT Y61 RL Target";
                RunPageLink = Code = field(Code);
            }
            action(OpenWithDate)
            {
                ApplicationArea = All;
                RunObject = page "LT Y61 RL Target";
                RunPageLink = Code = field(Code), "Date Filter" = field("Date Filter");
            }
        }
    }
}

codeunit 93246 "LT Y61 RunPageLink CopyFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        ModeCu: Codeunit "LT Y61 RL Mode";

    local procedure Seed()
    var
        P: Record "LT Y61 RL P";
        Q: Record "LT Y61 RL Q";
        Log: Record "LT Y61 Log";
    begin
        ClearLastError();
        Observer.Discard();
        P.DeleteAll();
        Q.DeleteAll();
        P.Code := 'P1';
        P.Name := 'one';
        P.Insert();
        P.Code := 'P2';
        P.Name := 'two';
        P.Insert();
        AddQ('P1', 'A');
        AddQ('P1', 'B');
        AddQ('P2', 'C');
        Log.ClearLog();
    end;

    local procedure AddQ(Parent: Code[20]; Name: Code[10])
    var
        Q: Record "LT Y61 RL Q";
    begin
        Q."Parent Code" := Parent;
        Q.Name := Name;
        Q.Insert();
    end;

    local procedure OpenTarget(Mode: Text; WithDate: Boolean; var Target: TestPage "LT Y61 RL Target")
    var
        P: Record "LT Y61 RL P";
        Log: Record "LT Y61 Log";
        Host: TestPage "LT Y61 RL Host";
    begin
        ModeCu.SetMode(Mode);
        P.SetRange("Date Filter", 20240301D, 20240331D);
        P.Get('P1');
        Host.Trap();
        Page.Run(Page::"LT Y61 RL Host", P);
        Log.ClearLog();
        Target.Trap();
        if WithDate then
            Host.OpenWithDate.Invoke()
        else
            Host.Open.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Observe('shown code', Target.CodeCtl.Value());
        Host.Close();
    end;

    [Test]
    procedure G616_CopyFilter_LinkedField_ToOther()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('copyfilter-code', false, Target);
        Target.Close();
        Observer.Expect('log', 'open code=P1;before=ZZ;after=P1 hasfilter=Yes count=2');
        Observer.Expect('shown code', 'P1');
        Observer.Verify();
    end;

    [Test]
    procedure G616_CopyFilter_FlowFilterNotLinked_ToOther()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('copyfilter-date', false, Target);
        Target.Close();
        Observer.Expect('log', 'open code=P1;before=01/01/24..01/31/24;after= hasfilter=No;fresh= hasfilter=No');
        Observer.Expect('shown code', 'P1');
        Observer.Verify();
    end;

    [Test]
    procedure G616_PartUpdateForm_VarRec()
    var
        Target: TestPage "LT Y61 RL Target";
        Rows: Text;
    begin
        Seed();
        OpenTarget('part', false, Target);
        if Target.Sub.First() then
            repeat
                Rows += Target.Sub.ParentCtl.Value() + '/' + Target.Sub.NameCtl.Value() + ',';
            until not Target.Sub.Next();
        Observer.Observe('part rows', Rows);
        Target.Close();
        Observer.Expect('log', 'open code=P1;part filters=Parent Code: P1;part host filters=Code: P1');
        Observer.Expect('shown code', 'P1');
        Observer.Expect('part rows', 'P1/A,P1/B,P2/C,/,');
        Observer.Verify();
    end;

    [Test]
    procedure G616_PartUpdateForm_FlowFilterLink()
    var
        Target: TestPage "LT Y61 RL Target";
        Rows: Text;
    begin
        Seed();
        OpenTarget('part', true, Target);
        if Target.Sub.First() then
            repeat
                Rows += Target.Sub.ParentCtl.Value() + '/' + Target.Sub.NameCtl.Value() + ',';
            until not Target.Sub.Next();
        Observer.Observe('part rows', Rows);
        Target.Close();
        Observer.Expect('log', 'open code=P1;part filters=Parent Code: P1, Date Filter: 03/01/24..03/31/24;part host filters=Code: P1, Date Filter: 03/01/24..03/31/24');
        Observer.Expect('shown code', 'P1');
        Observer.Expect('part rows', 'P1/A,P1/B,P2/C,/,');
        Observer.Verify();
    end;

    [Test]
    procedure G616_CopyFilters_ToOther()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('copyfilters', false, Target);
        Target.Close();
        Observer.Expect('log', 'open code=P1;copyfilters filters=Code: P1 count=1');
        Observer.Expect('shown code', 'P1');
        Observer.Verify();
    end;

    [Test]
    procedure G616_Copy_ToOther()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('copy', false, Target);
        Target.Close();
        Observer.Expect('log', 'open code=P1;copy code=P1 filters=Code: P1 count=1');
        Observer.Expect('shown code', 'P1');
        Observer.Verify();
    end;

    [Test]
    procedure G616_HasFilter_GetView_FilterGroup_Count_FindFirst()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('reads', false, Target);
        Target.Close();
        Observer.Expect('log', 'open code=P1;hasfilter=Yes;getfilter code=P1;getfilter date=;view=VERSION(1) SORTING(Field1) WHERE(Field1=1(P1));filtergroup=0;count=1;findfirst=Yes code=P1 name=one');
        Observer.Expect('shown code', 'P1');
        Observer.Verify();
    end;

    [Test]
    procedure G616_FlowFilterLink_CopyFilter()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('flowlink', true, Target);
        Target.Close();
        Observer.Expect('log', 'open code=P1;getfilter date=03/01/24..03/31/24;date after=03/01/24..03/31/24;code after=P1');
        Observer.Expect('shown code', 'P1');
        Observer.Verify();
    end;
}
