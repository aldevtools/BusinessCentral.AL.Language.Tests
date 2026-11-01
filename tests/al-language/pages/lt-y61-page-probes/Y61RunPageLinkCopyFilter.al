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
//   logs its value, or the error text and code.
// Neighbours: handlers/QzRunPageLinkOnOpen.al (fields and GetFilters of Rec, a by-value copy), pages/lt-y41-page-probes/Y41RunPageLinkOnOpen.al.
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

    procedure UpdateForm(var HostRec: Record "LT Y61 RL P")
    var
        Log: Record "LT Y61 Log";
    begin
        Rec.SetRange("Parent Code", HostRec.Code);
        HostRec.CopyFilter("Date Filter", Rec."Date Filter");
        Log.AddLine('part filters=' + Rec.GetFilters());
        Log.AddLine('part host filters=' + HostRec.GetFilters());
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

    trigger OnOpenPage()
    var
        Log: Record "LT Y61 Log";
        ModeCu: Codeunit "LT Y61 RL Mode";
        Mode: Text;
    begin
        Mode := ModeCu.GetMode();
        Log.AddLine('open code=' + Rec.Code);
        if not TryProbe(Mode) then
            Log.AddLine('error ' + Mode + ' text=' + GetLastErrorText() + ' code=' + GetLastErrorCode());
        ClearLastError();
    end;

    [TryFunction]
    local procedure TryProbe(Mode: Text)
    var
        Log: Record "LT Y61 Log";
        Other: Record "LT Y61 RL Q";
        Other2: Record "LT Y61 RL P";
    begin
        case Mode of
            'copyfilter-code':
                begin
                    Other.SetRange("Parent Code", 'ZZ');
                    Log.AddLine('before=' + Other.GetFilter("Parent Code"));
                    Rec.CopyFilter(Code, Other."Parent Code");
                    Log.AddLine('after=' + Other.GetFilter("Parent Code") + ' hasfilter=' + Format(Other.HasFilter()) + ' count=' + Format(Other.Count()));
                end;
            'copyfilter-date':
                begin
                    Other.SetRange("Date Filter", 20240101D, 20240131D);
                    Log.AddLine('before=' + Other.GetFilter("Date Filter"));
                    Rec.CopyFilter("Date Filter", Other."Date Filter");
                    Log.AddLine('after=' + Other.GetFilter("Date Filter") + ' hasfilter=' + Format(Other.HasFilter()));
                    Other.Reset();
                    Rec.CopyFilter("Date Filter", Other."Date Filter");
                    Log.AddLine('fresh=' + Other.GetFilter("Date Filter") + ' hasfilter=' + Format(Other.HasFilter()));
                end;
            'part':
                CurrPage.Sub.Page.UpdateForm(Rec);
            'copyfilters':
                begin
                    Other2.SetRange(Name, 'zz');
                    Other2.CopyFilters(Rec);
                    Log.AddLine('copyfilters filters=' + Other2.GetFilters() + ' count=' + Format(Other2.Count()));
                end;
            'copy':
                begin
                    Other2.Copy(Rec);
                    Log.AddLine('copy code=' + Other2.Code + ' filters=' + Other2.GetFilters() + ' count=' + Format(Other2.Count()));
                end;
            'reads':
                begin
                    Log.AddLine('hasfilter=' + Format(Rec.HasFilter()));
                    Log.AddLine('getfilter code=' + Rec.GetFilter(Code));
                    Log.AddLine('getfilter date=' + Rec.GetFilter("Date Filter"));
                    Log.AddLine('view=' + Rec.GetView(false));
                    Log.AddLine('filtergroup=' + Format(Rec.FilterGroup()));
                    Log.AddLine('count=' + Format(Rec.Count()));
                    Log.AddLine('findfirst=' + Format(Rec.FindFirst()) + ' code=' + Rec.Code + ' name=' + Rec.Name);
                end;
            'flowlink':
                begin
                    Log.AddLine('getfilter date=' + Rec.GetFilter("Date Filter"));
                    Rec.CopyFilter("Date Filter", Other."Date Filter");
                    Log.AddLine('date after=' + Other.GetFilter("Date Filter"));
                    Rec.CopyFilter(Code, Other."Parent Code");
                    Log.AddLine('code after=' + Other.GetFilter("Parent Code"));
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
        Observer.Finish();
    end;

    [Test]
    procedure G616_CopyFilter_FlowFilterNotLinked_ToOther()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('copyfilter-date', false, Target);
        Target.Close();
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure G616_CopyFilters_ToOther()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('copyfilters', false, Target);
        Target.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G616_Copy_ToOther()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('copy', false, Target);
        Target.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G616_HasFilter_GetView_FilterGroup_Count_FindFirst()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('reads', false, Target);
        Target.Close();
        Observer.Finish();
    end;

    [Test]
    procedure G616_FlowFilterLink_CopyFilter()
    var
        Target: TestPage "LT Y61 RL Target";
    begin
        Seed();
        OpenTarget('flowlink', true, Target);
        Target.Close();
        Observer.Finish();
    end;
}
