// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none (own objects).
// Objects for the writer Y90 permission probes (al-runtime-rs ADR-062, shapes left open by Y84 and the shadow run over Microsoft's tests): a page whose
// guarded actions are also promoted with actionref, pages whose trigger runs a codeunit (one fresh page and codeunit per case, because Execute is checked
// the first time a session loads an object), pages with an unguarded part, a table with FlowFields over system tables, and the permission sets.
// Object ids 94780-94829.

table 94780 "LT Y90 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
        field(3; GuardCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y90 Guard");
        }
        field(4; LangCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Language Selection");
        }
        field(5; LayoutCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Report Layout List");
        }
        field(6; RelCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Table Relations Metadata");
        }
        field(7; AppCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("NAV App Installed App");
        }
        field(8; LangExists; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("Language Selection");
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 94781 "LT Y90 Guard"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

// Guard object of the ABP cases that name a codeunit.
codeunit 94828 "LT Y90 Guard Cu"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

// A card whose actions carry AccessByPermission and are also promoted with actionref.
page 94782 "LT Y90 Ref Card"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PlainAct) { ApplicationArea = All; trigger OnAction() begin end; }
            action(GuardAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y90 Guard" = R; trigger OnAction() begin end; }
            action(GuardActRimd) { ApplicationArea = All; AccessByPermission = tabledata "LT Y90 Guard" = RIMD; trigger OnAction() begin end; }
            action(CuAct) { ApplicationArea = All; AccessByPermission = codeunit "LT Y90 Guard Cu" = X; trigger OnAction() begin end; }
            group(Grp)
            {
                action(InGrpAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y90 Guard" = R; trigger OnAction() begin end; }
            }
        }
        area(Creation)
        {
            action(CreateAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y90 Guard" = R; trigger OnAction() begin end; }
        }
        area(Navigation)
        {
            action(NavAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y90 Guard" = R; trigger OnAction() begin end; }
        }
        area(Reporting)
        {
            action(RepAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y90 Guard" = R; trigger OnAction() begin end; }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(PlainRef; PlainAct) { }
                actionref(GuardRef; GuardAct) { }
                actionref(GuardRimdRef; GuardActRimd) { }
                actionref(CuRef; CuAct) { }
                actionref(InGrpRef; InGrpAct) { }
                actionref(CreateRef; CreateAct) { }
                actionref(NavRef; NavAct) { }
                actionref(RepRef; RepAct) { }
            }
        }
    }
}

page 94783 "LT Y90 Open 1"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    Caption = 'LT Y90 Shown Caption';

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Target: Codeunit "LT Y90 Target 1";
    begin
        if Target.Ping() = '' then;
    end;
}

codeunit 94792 "LT Y90 Target 1"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94784 "LT Y90 Open 2"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Target: Codeunit "LT Y90 Target 2";
    begin
        if Target.Ping() = '' then;
    end;
}

codeunit 94793 "LT Y90 Target 2"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94785 "LT Y90 Open 3"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Target: Codeunit "LT Y90 Target 3";
    begin
        if Target.Ping() = '' then;
    end;
}

codeunit 94794 "LT Y90 Target 3"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94786 "LT Y90 Open 4"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Target: Codeunit "LT Y90 Target 4";
    begin
        if Target.Ping() = '' then;
    end;
}

codeunit 94795 "LT Y90 Target 4"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94787 "LT Y90 Open 5"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Target: Codeunit "LT Y90 Target 5";
    begin
        if Target.Ping() = '' then;
    end;
}

codeunit 94796 "LT Y90 Target 5"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94788 "LT Y90 Open 6"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Target: Codeunit "LT Y90 Target 6";
    begin
        if Target.Ping() = '' then;
    end;
}

codeunit 94797 "LT Y90 Target 6"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94789 "LT Y90 Open 7"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnInit()
    var
        Target: Codeunit "LT Y90 Target 7";
    begin
        if Target.Ping() = '' then;
    end;
}

codeunit 94798 "LT Y90 Target 7"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94790 "LT Y90 Open 8"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnAfterGetRecord()
    var
        Target: Codeunit "LT Y90 Target 8";
    begin
        if Target.Ping() = '' then;
    end;
}

codeunit 94799 "LT Y90 Target 8"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94791 "LT Y90 Open 9"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;
    

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        Codeunit.Run(Codeunit::"LT Y90 Target 9");
    end;
}

codeunit 94800 "LT Y90 Target 9"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94802 "LT Y90 Part A"
{
    PageType = ListPart;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCol; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

// Card with a part that has no AccessByPermission.
page 94801 "LT Y90 Card A"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT Y90 Part A") { ApplicationArea = All; }
        }
    }
}

page 94804 "LT Y90 Part B"
{
    PageType = ListPart;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCol; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

// Card with a part that has no AccessByPermission.
page 94803 "LT Y90 Card B"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT Y90 Part B") { ApplicationArea = All; }
        }
    }
}

page 94806 "LT Y90 Part C"
{
    PageType = ListPart;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCol; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

// Card with a part that has no AccessByPermission.
page 94805 "LT Y90 Card C"
{
    PageType = Card;
    SourceTable = "LT Y90 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT Y90 Part C") { ApplicationArea = All; }
        }
    }
}

permissionset 94811 "LT Y90 P Pages"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Open 1" = X,
        page "LT Y90 Open 2" = X,
        page "LT Y90 Open 3" = X,
        page "LT Y90 Open 4" = X,
        page "LT Y90 Open 5" = X,
        page "LT Y90 Open 6" = X,
        page "LT Y90 Open 7" = X,
        page "LT Y90 Open 8" = X,
        page "LT Y90 Open 9" = X,
        page "LT Y90 Card A" = X,
        page "LT Y90 Card B" = X,
        page "LT Y90 Card C" = X;
}

permissionset 94812 "LT Y90 P PagesCuStar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Open 1" = X,
        page "LT Y90 Open 2" = X,
        page "LT Y90 Open 3" = X,
        page "LT Y90 Open 4" = X,
        page "LT Y90 Open 5" = X,
        page "LT Y90 Open 6" = X,
        page "LT Y90 Open 7" = X,
        page "LT Y90 Open 8" = X,
        page "LT Y90 Open 9" = X,
        page "LT Y90 Card A" = X,
        page "LT Y90 Card B" = X,
        page "LT Y90 Card C" = X,
        codeunit * = X;
}

permissionset 94813 "LT Y90 P PagesStar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page * = X;
}

permissionset 94814 "LT Y90 P StarStar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page * = X,
        codeunit * = X;
}

permissionset 94815 "LT Y90 P CuStar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        codeunit * = X;
}

permissionset 94816 "LT Y90 P Parts"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Open 1" = X,
        page "LT Y90 Open 2" = X,
        page "LT Y90 Open 3" = X,
        page "LT Y90 Open 4" = X,
        page "LT Y90 Open 5" = X,
        page "LT Y90 Open 6" = X,
        page "LT Y90 Open 7" = X,
        page "LT Y90 Open 8" = X,
        page "LT Y90 Open 9" = X,
        page "LT Y90 Card A" = X,
        page "LT Y90 Card B" = X,
        page "LT Y90 Card C" = X,
        page "LT Y90 Part B" = X,
        page "LT Y90 Part C" = X;
}

permissionset 94817 "LT Y90 A None"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Ref Card" = X;
}

permissionset 94818 "LT Y90 A R"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Ref Card" = X,
        tabledata "LT Y90 Guard" = R;
}

permissionset 94819 "LT Y90 A RIMD"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Ref Card" = X,
        tabledata "LT Y90 Guard" = RIMD;
}

permissionset 94820 "LT Y90 A Ind R"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Ref Card" = X,
        tabledata "LT Y90 Guard" = r;
}

permissionset 94821 "LT Y90 A Cu"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Ref Card" = X,
        codeunit "LT Y90 Guard Cu" = X;
}

permissionset 94822 "LT Y90 S None"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD;
}

permissionset 94823 "LT Y90 S R"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        tabledata "Language Selection" = R,
        tabledata "Report Layout List" = R,
        tabledata "Table Relations Metadata" = R,
        tabledata "NAV App Installed App" = R;
}

permissionset 94824 "LT Y90 S RIMD"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        tabledata "Language Selection" = RIMD,
        tabledata "Report Layout List" = RIMD,
        tabledata "Table Relations Metadata" = RIMD,
        tabledata "NAV App Installed App" = RIMD;
}

permissionset 94825 "LT Y90 E Mixed"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        tabledata "LT Y90 Guard" = RiMd;
}

permissionset 94826 "LT Y90 P Parts2"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Open 1" = X,
        page "LT Y90 Open 2" = X,
        page "LT Y90 Open 3" = X,
        page "LT Y90 Open 4" = X,
        page "LT Y90 Open 5" = X,
        page "LT Y90 Open 6" = X,
        page "LT Y90 Open 7" = X,
        page "LT Y90 Open 8" = X,
        page "LT Y90 Open 9" = X,
        page "LT Y90 Card A" = X,
        page "LT Y90 Card B" = X,
        page "LT Y90 Card C" = X,
        page "LT Y90 Part B" = X,
        page "LT Y90 Part C" = X,
        system * = X;
}

permissionset 94827 "LT Y90 P Parts3"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Open 1" = X,
        page "LT Y90 Open 2" = X,
        page "LT Y90 Open 3" = X,
        page "LT Y90 Open 4" = X,
        page "LT Y90 Open 5" = X,
        page "LT Y90 Open 6" = X,
        page "LT Y90 Open 7" = X,
        page "LT Y90 Open 8" = X,
        page "LT Y90 Open 9" = X,
        page "LT Y90 Card A" = X,
        page "LT Y90 Card B" = X,
        page "LT Y90 Card C" = X,
        page "LT Y90 Part B" = X,
        page "LT Y90 Part C" = X,
        codeunit * = X;
}

permissionset 94829 "LT Y90 P PagesSys"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        page "LT Y90 Open 1" = X,
        page "LT Y90 Open 2" = X,
        page "LT Y90 Open 3" = X,
        page "LT Y90 Open 4" = X,
        page "LT Y90 Open 5" = X,
        page "LT Y90 Open 6" = X,
        page "LT Y90 Open 7" = X,
        page "LT Y90 Open 8" = X,
        page "LT Y90 Open 9" = X,
        page "LT Y90 Card A" = X,
        page "LT Y90 Card B" = X,
        page "LT Y90 Card C" = X,
        system * = X,
        codeunit "LT Y90 Target 6" = X;
}
