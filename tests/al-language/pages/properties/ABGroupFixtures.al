// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: none (this file holds them)
// Probe: written against a BC service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27 to 29 (CI matrix)
// Facts: fixtures for the group property probes (issues 622 and 623): one table, one flag holder, one card page per container kind (fixed, grid, cuegroup)
// with Editable, Enabled and Visible as true, false and an expression, and a list page per kind with ShowAsTree and FileUploadAction.

table 77000 "LT AB Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Level; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 77001 "LT AB Flags"
{
    SingleInstance = true;

    procedure Set(NewEditable: Boolean; NewEnabled: Boolean; NewVisible: Boolean)
    begin
        EditableFlag := NewEditable;
        EnabledFlag := NewEnabled;
        VisibleFlag := NewVisible;
    end;

    procedure Get(var CurrEditable: Boolean; var CurrEnabled: Boolean; var CurrVisible: Boolean)
    begin
        CurrEditable := EditableFlag;
        CurrEnabled := EnabledFlag;
        CurrVisible := VisibleFlag;
    end;

    procedure SetVeto(NewVeto: Boolean)
    begin
        VetoFlag := NewVeto;
    end;

    procedure Veto(): Boolean
    begin
        exit(VetoFlag);
    end;

    var
        EditableFlag: Boolean;
        EnabledFlag: Boolean;
        VisibleFlag: Boolean;
        VetoFlag: Boolean;
}

page 77012 "LT AB Fixed Props"
{
    PageType = Card;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            fixed(FxTrue)
            {
                Editable = true;
                Enabled = true;
                Visible = true;
                field(FxTrueF; Rec.Name) { ApplicationArea = All; }
            }
            fixed(FxFalse)
            {
                Editable = false;
                Enabled = false;
                Visible = true;
                field(FxFalseF; Rec.Name) { ApplicationArea = All; }
            }
            fixed(FxHidden)
            {
                Visible = false;
                field(FxHiddenF; Rec.Name) { ApplicationArea = All; }
            }
            fixed(FxExpr)
            {
                Editable = EditableFlag;
                Enabled = EnabledFlag;
                field(FxExprF; Rec.Name) { ApplicationArea = All; }
            }
            fixed(FxVisExpr)
            {
                Visible = VisibleFlag;
                field(FxVisExprF; Rec.Name) { ApplicationArea = All; }
            }
            field(PlainF; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Flags: Codeunit "LT AB Flags";
    begin
        Flags.Get(EditableFlag, EnabledFlag, VisibleFlag);
    end;

    var
        EditableFlag: Boolean;
        EnabledFlag: Boolean;
        VisibleFlag: Boolean;
}

page 77015 "LT AB Fixed Tree List"
{
    PageType = List;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
            fixed(Tree)
            {
                ShowAsTree = true;
                FileUploadAction = UploadAct;
                field(TreeF; Rec.Name) { ApplicationArea = All; }
            }
            fixed(Plain)
            {
                FileUploadAction = PlainAct;
                field(PlainTreeF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction(UploadAct)
            {
                ApplicationArea = All;
                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
            action(PlainAct)
            {
                ApplicationArea = All;
            }
        }
    }
}

page 77022 "LT AB Grid Props"
{
    PageType = Card;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            grid(GrTrue)
            {
                Editable = true;
                Enabled = true;
                Visible = true;
                field(GrTrueF; Rec.Name) { ApplicationArea = All; }
            }
            grid(GrFalse)
            {
                Editable = false;
                Enabled = false;
                Visible = true;
                field(GrFalseF; Rec.Name) { ApplicationArea = All; }
            }
            grid(GrHidden)
            {
                Visible = false;
                field(GrHiddenF; Rec.Name) { ApplicationArea = All; }
            }
            grid(GrExpr)
            {
                Editable = EditableFlag;
                Enabled = EnabledFlag;
                field(GrExprF; Rec.Name) { ApplicationArea = All; }
            }
            grid(GrVisExpr)
            {
                Visible = VisibleFlag;
                field(GrVisExprF; Rec.Name) { ApplicationArea = All; }
            }
            field(PlainF; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Flags: Codeunit "LT AB Flags";
    begin
        Flags.Get(EditableFlag, EnabledFlag, VisibleFlag);
    end;

    var
        EditableFlag: Boolean;
        EnabledFlag: Boolean;
        VisibleFlag: Boolean;
}

page 77025 "LT AB Grid Tree List"
{
    PageType = List;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
            grid(Tree)
            {
                ShowAsTree = true;
                FileUploadAction = UploadAct;
                field(TreeF; Rec.Name) { ApplicationArea = All; }
            }
            grid(Plain)
            {
                FileUploadAction = PlainAct;
                field(PlainTreeF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction(UploadAct)
            {
                ApplicationArea = All;
                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
            action(PlainAct)
            {
                ApplicationArea = All;
            }
        }
    }
}

page 77032 "LT AB Cue Props"
{
    PageType = Card;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            cuegroup(CgTrue)
            {
                Editable = true;
                Enabled = true;
                Visible = true;
                field(CgTrueF; Rec.Name) { ApplicationArea = All; }
            }
            cuegroup(CgFalse)
            {
                Editable = false;
                Enabled = false;
                Visible = true;
                field(CgFalseF; Rec.Name) { ApplicationArea = All; }
            }
            cuegroup(CgHidden)
            {
                Visible = false;
                field(CgHiddenF; Rec.Name) { ApplicationArea = All; }
            }
            cuegroup(CgExpr)
            {
                Editable = EditableFlag;
                Enabled = EnabledFlag;
                field(CgExprF; Rec.Name) { ApplicationArea = All; }
            }
            cuegroup(CgVisExpr)
            {
                Visible = VisibleFlag;
                field(CgVisExprF; Rec.Name) { ApplicationArea = All; }
            }
            field(PlainF; Rec.Name) { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    var
        Flags: Codeunit "LT AB Flags";
    begin
        Flags.Get(EditableFlag, EnabledFlag, VisibleFlag);
    end;

    var
        EditableFlag: Boolean;
        EnabledFlag: Boolean;
        VisibleFlag: Boolean;
}

page 77035 "LT AB Cue Tree List"
{
    PageType = List;
    SourceTable = "LT AB Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
            cuegroup(Tree)
            {
                ShowAsTree = true;
                FileUploadAction = UploadAct;
                field(TreeF; Rec.Name) { ApplicationArea = All; }
            }
            cuegroup(Plain)
            {
                FileUploadAction = PlainAct;
                field(PlainTreeF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction(UploadAct)
            {
                ApplicationArea = All;
                trigger OnAction(Files: List of [FileUpload])
                begin
                end;
            }
            action(PlainAct)
            {
                ApplicationArea = All;
            }
        }
    }
}
