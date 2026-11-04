// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: none (fixtures only: tables 84280-84283, enums 84280-84281, pages 84280-84296, codeunit 84280)
// Facts: fixtures only, for the TestPage leads of corpus issue #667 (items 49-64) tested in CdTestPageLeads.al.
// BC versions: all (CI)

enum 84280 "LT CD Status"
{
    Extensible = false;
    value(0; Open) { Caption = 'Open'; }
    value(1; Released) { Caption = 'Released'; }
}

enum 84281 "LT CD Kind"
{
    Extensible = false;
    value(0; First) { Caption = 'First'; }
    value(1; Second) { Caption = 'Second'; }
    value(2; Third) { Caption = 'Third'; }
}

table 84280 "LT CD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Status; Enum "LT CD Status") { }
        field(4; Locked; Text[30])
        {
            Editable = false;
            trigger OnValidate()
            var
                Log: Codeunit "LT CD Log";
            begin
                Log.Add('locked-onvalidate:' + Locked);
            end;
        }
        field(5; C1; Code[1]) { ValuesAllowed = '', 'A', 'N'; }
        field(6; Grp; Code[10]) { }
        field(7; D; Date) { }
        field(8; T; Text[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(GrpId; Grp, Id) { }
    }
}

// A table without DataCaptionFields (item 50: what a card caption falls back to).
table 84281 "LT CD NoCap"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// Lines whose primary key starts with an enum field (item 61) and a header that links lines through an enum field (items 59, 64).
table 84282 "LT CD Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Kind; Enum "LT CD Kind") { }
        field(2; No; Integer) { }
        field(3; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; Kind, No) { Clustered = true; }
    }
}

table 84283 "LT CD Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT CD Kind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// A plain text log the pages write to (one session; every test clears it first).
codeunit 84280 "LT CD Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Clear()
    begin
        Entries := '';
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

// Item 49: a card whose OnOpenPage calls CurrPage.Editable(false).
page 84280 "LT CD Lock Card"
{
    PageType = Card;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Lock Card';

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
            field(NoteCtl; Note) { ApplicationArea = All; Caption = 'Note'; }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable(false);
    end;

    var
        Note: Text[30];
}

// Item 50: a card over a table without DataCaptionFields.
page 84281 "LT CD NoCap Card"
{
    PageType = Card;
    SourceTable = "LT CD NoCap";
    ApplicationArea = All;
    Caption = 'CD NoCap';

    layout
    {
        area(Content)
        {
            field(CodeCtl; Rec."Code") { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }
}

// Item 51: Visible bound to page variables on a field, a group and an action, changed by an action after the page opened.
page 84282 "LT CD Vis Card"
{
    PageType = Card;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Vis Card';

    layout
    {
        area(Content)
        {
            field(NameCtl; Rec.Name) { ApplicationArea = All; Visible = ShowField; }
            group(Grp)
            {
                Visible = ShowGroup;
                field(IdInGroup; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(HideAll)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ShowField := false;
                    ShowGroup := false;
                    ShowAction := false;
                end;
            }
            action(HideAllUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ShowField := false;
                    ShowGroup := false;
                    ShowAction := false;
                    CurrPage.Update(false);
                end;
            }
            action(Target)
            {
                ApplicationArea = All;
                Visible = ShowAction;
                trigger OnAction()
                begin
                end;
            }
        }
    }

    trigger OnInit()
    begin
        ShowField := true;
        ShowGroup := true;
        ShowAction := true;
    end;

    var
        ShowField: Boolean;
        ShowGroup: Boolean;
        ShowAction: Boolean;
}

// Items 52, 54, 55, 56: a card with a control over the Editable = false field, an Editable expression over a page variable set
// in OnAfterGetCurrRecord and one over a field of Rec, a page-variable control and the ValuesAllowed field.
page 84283 "LT CD Status Card"
{
    PageType = Card;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Status Card';

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(StatusCtl; Rec.Status) { ApplicationArea = All; }
            field(NameByVar; Rec.Name) { ApplicationArea = All; Editable = IsOpen; }
            field(TByRec; Rec.T) { ApplicationArea = All; Editable = (Rec.Status = Rec.Status::Open); }
            field(NoteCtl; Note) { ApplicationArea = All; Caption = 'Note'; }
            field(C1Ctl; Rec.C1) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Release)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::Released;
                    Rec.Modify();
                end;
            }
            action(ReleaseUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::Released;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
            action(ReopenUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::Open;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
    end;

    var
        IsOpen: Boolean;
        Note: Text[30];
}

// Item 53: actions in area(Prompting), one without RunObject and one with.
page 84284 "LT CD Prompting Card"
{
    PageType = Card;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Prompting Card';

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Prompting)
        {
            action(PromptNoRun)
            {
                ApplicationArea = All;
                Caption = 'Prompt without RunObject';
                trigger OnAction()
                var
                    Log: Codeunit "LT CD Log";
                begin
                    Log.Add('prompt-no-run');
                end;
            }
            action(PromptWithRun)
            {
                ApplicationArea = All;
                Caption = 'Prompt with RunObject';
                RunObject = page "LT CD Prompt Dialog";
            }
        }
        area(Processing)
        {
            action(Plain)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 84285 "LT CD Prompt Dialog"
{
    PageType = PromptDialog;
    ApplicationArea = All;
    Caption = 'CD Prompt Dialog';
    Extensible = false;

    layout
    {
        area(Prompt)
        {
            field(InputCtl; Input) { ApplicationArea = All; ShowCaption = false; }
        }
    }

    var
        Input: Text;
}

// Item 57: labels in a NavigatePage with Visible = (2 = 3) and Visible = not Ok, and one inside a group with Visible = not Ok.
page 84286 "LT CD Navigate"
{
    PageType = NavigatePage;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Navigate';

    layout
    {
        area(Content)
        {
            group(Step)
            {
                Visible = Step1;
                field(OkCtl; Ok) { ApplicationArea = All; Caption = 'Ok'; }
                label(ConstExprLabel) { ApplicationArea = All; Caption = 'Constant expression label'; Visible = (2 = 3); }
                label(VarLabel) { ApplicationArea = All; Caption = 'Variable label'; Visible = not Ok; }
                group(LabelGroup)
                {
                    ShowCaption = false;
                    Visible = not Ok;
                    label(GroupedLabel) { ApplicationArea = All; Caption = 'Grouped label'; }
                }
            }
        }
    }

    trigger OnInit()
    begin
        Step1 := true;
    end;

    var
        Ok: Boolean;
        Step1: Boolean;
}

// Item 58: SourceTableView with filter(0D), and const on text, integer and datetime fields.
page 84287 "LT CD Filter0D List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Filter0D List';
    SourceTableView = where(D = filter(0D));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

page 84288 "LT CD ConstOthers List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD ConstOthers List';
    SourceTableView = where(T = const(''), Status = const(Open));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }
}

// Items 59, 64: a header card with a list part linked through an enum field; the part logs its filter groups in OnOpenPage.
page 84289 "LT CD Head Card"
{
    PageType = Card;
    SourceTable = "LT CD Head";
    ApplicationArea = All;
    Caption = 'CD Head Card';

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(KindCtl; Rec.Kind) { ApplicationArea = All; }
            part(Lines; "LT CD Line Part")
            {
                ApplicationArea = All;
                SubPageLink = Kind = field(Kind);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LinesByField)
            {
                ApplicationArea = All;
                RunObject = page "LT CD Line List";
                RunPageLink = Kind = field(Kind);
            }
            action(LinesByConst)
            {
                ApplicationArea = All;
                RunObject = page "LT CD Line List";
                RunPageLink = Kind = const(Second);
            }
        }
    }
}

page 84290 "LT CD Line Part"
{
    PageType = ListPart;
    SourceTable = "LT CD Line";
    ApplicationArea = All;
    Caption = 'CD Line Part';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
                field(NoCtl; Rec.No) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT CD Log";
        Group: Integer;
        Saved: Integer;
        Seen: Text;
    begin
        Saved := Rec.FilterGroup();
        for Group := 0 to 10 do begin
            Rec.FilterGroup(Group);
            if Rec.GetFilters() <> '' then
                Seen += 'g' + Format(Group) + '=' + Rec.GetFilters() + ' ';
        end;
        Rec.FilterGroup(Saved);
        Log.Add('part-onopenpage:' + Seen.TrimEnd());
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT CD Log";
        Saved: Integer;
    begin
        Saved := Rec.FilterGroup();
        Rec.FilterGroup(4);
        Log.Add('part-aftergetcurr:g4=' + Rec.GetFilters());
        Rec.FilterGroup(Saved);
    end;
}

page 84291 "LT CD Line List"
{
    PageType = List;
    SourceTable = "LT CD Line";
    ApplicationArea = All;
    Caption = 'CD Line List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(KindCtl; Rec.Kind) { ApplicationArea = All; }
                field(NoCtl; Rec.No) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

// Item 60: a list sorted descending by its SourceTableView, and one sorted descending by Ascending(false) in OnOpenPage; an action
// hands the selection to another record variable.
page 84292 "LT CD Desc List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD Desc List';
    SourceTableView = sorting(Id) order(descending);

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Sel)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Target: Record "LT CD Row";
                    SelHelper: Codeunit "LT CD Sel";
                begin
                    CurrPage.SetSelectionFilter(Target);
                    SelHelper.Report(Target);
                end;
            }
        }
    }
}

page 84293 "LT CD AscFalse List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD AscFalse List';

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Sel)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Target: Record "LT CD Row";
                    SelHelper: Codeunit "LT CD Sel";
                begin
                    CurrPage.SetSelectionFilter(Target);
                    SelHelper.Report(Target);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Ascending(false);
    end;
}

codeunit 84281 "LT CD Sel"
{
    // Logs what CurrPage.SetSelectionFilter gave the target: its filters, row count, marked-only state, and the loop of the
    // Microsoft AL issue 5257 (FindSet, then Mark() of each row).
    procedure Report(var Target: Record "LT CD Row")
    var
        Log: Codeunit "LT CD Log";
        Marked: Text;
    begin
        Log.Add('filters=' + Target.GetFilters() + ' count=' + Format(Target.Count()) + ' markedonly=' + Format(Target.MarkedOnly())
            + ' asc=' + Format(Target.Ascending()));
        if Target.FindSet() then
            repeat
                if Target.Mark() then
                    Marked += Format(Target.Id) + ',';
            until Target.Next() = 0;
        Log.Add('marked=' + Marked);
    end;
}

// Item 62: filters set in OnOpenPage in filter group 2 and in filter group 4.
page 84294 "LT CD FG2 List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD FG2 List';

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } field(GrpCtl; Rec.Grp) { ApplicationArea = All; } }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Grp, 'A');
        Rec.FilterGroup(0);
    end;
}

page 84295 "LT CD FG4 List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD FG4 List';

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } field(GrpCtl; Rec.Grp) { ApplicationArea = All; } }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(4);
        Rec.SetRange(Grp, 'A');
        Rec.FilterGroup(0);
    end;
}

// Item 63: FilterGroup(-1) with two SetRange calls on different fields in OnOpenPage, and the same two calls in FilterGroup(4).
page 84296 "LT CD OrGroup List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD OrGroup List';

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT CD Log";
    begin
        Rec.FilterGroup(-1);
        Rec.SetRange(Grp, 'A');
        Rec.SetRange(Name, 'n3');
        Log.Add('g-1=' + Rec.GetFilters() + ' count=' + Format(Rec.Count()));
        Rec.FilterGroup(0);
    end;
}

page 84297 "LT CD AndGroup4 List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD AndGroup4 List';

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(4);
        Rec.SetRange(Grp, 'A');
        Rec.SetRange(Name, 'n3');
        Rec.FilterGroup(0);
    end;
}

// Item 64: OnOpenPage SetCurrentKey on a two-field key, then SetAscending on its second field.
page 84298 "LT CD SortKey List"
{
    PageType = List;
    SourceTable = "LT CD Row";
    ApplicationArea = All;
    Caption = 'CD SortKey List';

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(IdCtl; Rec.Id) { ApplicationArea = All; } }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Grp, Id);
        Rec.SetAscending(Id, false);
    end;
}
