// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: none (own objects).
// local object: the property under test sits on the page's own controls, fields and actions; the guards, the pages and the permission sets are the test.
// Objects for the writer Y94 probes (al-runtime-rs ADR-062 stage 4 gate, the page-open shapes the shadow run could not decide): actions that carry
// AccessByPermission and are listed with actionref in the Promoted area (every guard kind and letter, also from a page extension), a list page with
// repeater and group fields, a cue part with cue fields and cuegroup actions, controls and table fields that both state a guard, and a page that
// carries the property itself. One permission set per page and guard grant (base grants: the source table and the page itself).
// Object ids 95100-95139 (the ids of different object types do not collide).

table 95100 "LT Y94 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
        field(3; TfA; Integer) { AccessByPermission = tabledata "LT Y94 Guard A" = R; }
        field(4; TfB; Integer) { AccessByPermission = tabledata "LT Y94 Guard B" = R; }
        field(5; TfC; Integer) { AccessByPermission = tabledata "LT Y94 Guard B" = R; }
        field(6; TfD; Integer) { AccessByPermission = tabledata "LT Y94 Guard B" = R; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95101 "LT Y94 Guard A"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95102 "LT Y94 Guard B"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 95103 "LT Y94 Guard Cu"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

report 95104 "LT Y94 Rep"
{
    ProcessingOnly = true;
    UsageCategory = None;
}

query 95105 "LT Y94 Qry"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT Y94 Row")
        {
            column(Id; Id) { }
        }
    }
}

xmlport 95106 "LT Y94 Xml"
{
    Direction = Export;
    Format = Xml;
    Encoding = UTF8;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y94 Row")
            {
                fieldattribute(Id; Row.Id) { }
            }
        }
    }
}

page 95107 "LT Y94 Target"
{
    PageType = Card;
    SourceTable = "LT Y94 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
        }
    }
}

// A card whose guarded actions are also promoted with actionref (every guard kind), one guarded action that is not promoted, and a guarded field.
page 95108 "LT Y94 Ref Card"
{
    PageType = Card;
    SourceTable = "LT Y94 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(FldA; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PlainAct) { ApplicationArea = All; trigger OnAction() begin end; }
            action(TblRAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; trigger OnAction() begin end; }
            action(TblIAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = I; trigger OnAction() begin end; }
            action(TblRimdAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = RIMD; trigger OnAction() begin end; }
            action(PgAct) { ApplicationArea = All; AccessByPermission = page "LT Y94 Target" = X; trigger OnAction() begin end; }
            action(RepAct) { ApplicationArea = All; AccessByPermission = report "LT Y94 Rep" = X; trigger OnAction() begin end; }
            action(QryAct) { ApplicationArea = All; AccessByPermission = query "LT Y94 Qry" = X; trigger OnAction() begin end; }
            action(XmlAct) { ApplicationArea = All; AccessByPermission = xmlport "LT Y94 Xml" = X; trigger OnAction() begin end; }
            action(TblObjAct) { ApplicationArea = All; AccessByPermission = table "LT Y94 Guard A" = X; trigger OnAction() begin end; }
            action(CuAct) { ApplicationArea = All; AccessByPermission = codeunit "LT Y94 Guard Cu" = X; trigger OnAction() begin end; }
            action(BAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard B" = R; trigger OnAction() begin end; }
            action(NoRefAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; trigger OnAction() begin end; }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(PlainRef; PlainAct) { }
                actionref(TblRRef; TblRAct) { }
                actionref(TblIRef; TblIAct) { }
                actionref(TblRimdRef; TblRimdAct) { }
                actionref(PgRef; PgAct) { }
                actionref(RepRef; RepAct) { }
                actionref(QryRef; QryAct) { }
                actionref(XmlRef; XmlAct) { }
                actionref(TblObjRef; TblObjAct) { }
                actionref(CuRef; CuAct) { }
                actionref(BRef; BAct) { }
            }
        }
    }
}

// Adds a guarded field, a guarded action and a plain action to the card; the guarded action is promoted with an actionref added to the group.
pageextension 95109 "LT Y94 Ref Ext" extends "LT Y94 Ref Card"
{
    layout
    {
        addlast(Content)
        {
            field(FldExt; Rec.Id) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ExtAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; trigger OnAction() begin end; }
            action(ExtPlainAct) { ApplicationArea = All; trigger OnAction() begin end; }
        }
        addlast(Category_Process)
        {
            actionref(ExtRef; ExtAct) { }
            actionref(ExtPlainRef; ExtPlainAct) { }
        }
    }
}

// A list with a repeater and a group; guarded fields in both, guarded actions promoted directly under Promoted and in a group.
page 95110 "LT Y94 List"
{
    PageType = List;
    SourceTable = "LT Y94 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RPlain; Rec.Id) { ApplicationArea = All; }
                field(RGuardA; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; }
                field(RGuardB; Rec.Id) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard B" = R; }
            }
            group(Details)
            {
                field(GPlain; Rec.Id) { ApplicationArea = All; }
                field(GGuardA; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LPlainAct) { ApplicationArea = All; trigger OnAction() begin end; }
            action(LGuardAAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; trigger OnAction() begin end; }
            action(LGuardBAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard B" = R; trigger OnAction() begin end; }
            group(Inner)
            {
                action(LInnerAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; trigger OnAction() begin end; }
            }
        }
        area(Promoted)
        {
            actionref(LPlainRef; LPlainAct) { }
            actionref(LGuardARef; LGuardAAct) { }
            group(Category_Process)
            {
                actionref(LGuardBRef; LGuardBAct) { }
                actionref(LInnerRef; LInnerAct) { }
            }
        }
    }
}

// A cue part: cue fields and a cuegroup action carry the property.
page 95111 "LT Y94 Cue Part"
{
    PageType = CardPart;
    SourceTable = "LT Y94 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            cuegroup(Cues)
            {
                field(CuePlain; Rec.Id) { ApplicationArea = All; }
                field(CueGuardA; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; }
                field(CueGuardB; Rec.Id) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard B" = R; }

                actions
                {
                    action(CueAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; trigger OnAction() begin end; }
                    action(CuePlainAct) { ApplicationArea = All; trigger OnAction() begin end; }
                }
            }
        }
    }
}

// Controls and table fields that both state a guard. TfA, TfB, TfC and TfD carry a guard on the table field (A, B, B, B).
page 95112 "LT Y94 Conflict"
{
    PageType = Card;
    SourceTable = "LT Y94 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Plain; Rec.Id) { ApplicationArea = All; }
            field(CtlOnlyA; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; }
            field(FldOnlyA; Rec.TfA) { ApplicationArea = All; }
            field(FldOnlyB; Rec.TfD) { ApplicationArea = All; }
            field(CtlConflict; Rec.TfB) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard B" = R; }
            field(CtlSame; Rec.TfC) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard B" = R; }
        }
    }
}

// The page itself carries the property, and so do a field and a promoted action.
page 95113 "LT Y94 Page Level"
{
    PageType = Card;
    SourceTable = "LT Y94 Row";
    UsageCategory = Lists;
    AccessByPermission = tabledata "LT Y94 Guard A" = R;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(LvlGuardB; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard B" = R; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(LvlPlainAct) { ApplicationArea = All; trigger OnAction() begin end; }
            action(LvlGuardAct) { ApplicationArea = All; AccessByPermission = tabledata "LT Y94 Guard A" = R; trigger OnAction() begin end; }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(LvlPlainRef; LvlPlainAct) { }
                actionref(LvlGuardRef; LvlGuardAct) { }
            }
        }
    }
}

permissionset 95100 "LT Y94 Ref none"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X;
}

permissionset 95101 "LT Y94 Ref ar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        tabledata "LT Y94 Guard A" = R;
}

permissionset 95102 "LT Y94 Ref ai"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        tabledata "LT Y94 Guard A" = I;
}

permissionset 95103 "LT Y94 Ref arimd"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        tabledata "LT Y94 Guard A" = RIMD;
}

permissionset 95104 "LT Y94 Ref indr"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        tabledata "LT Y94 Guard A" = r;
}

permissionset 95105 "LT Y94 Ref br"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        tabledata "LT Y94 Guard B" = R;
}

permissionset 95106 "LT Y94 Ref abr"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        tabledata "LT Y94 Guard A" = R,
        tabledata "LT Y94 Guard B" = R;
}

permissionset 95107 "LT Y94 Ref cu"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        codeunit "LT Y94 Guard Cu" = X;
}

permissionset 95108 "LT Y94 Ref pg"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        page "LT Y94 Target" = X;
}

permissionset 95109 "LT Y94 Ref rep"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        report "LT Y94 Rep" = X;
}

permissionset 95110 "LT Y94 Ref qry"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        query "LT Y94 Qry" = X;
}

permissionset 95111 "LT Y94 Ref xml"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        xmlport "LT Y94 Xml" = X;
}

permissionset 95112 "LT Y94 Ref tbl"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        table "LT Y94 Guard A" = X;
}

permissionset 95113 "LT Y94 Ref wtdr"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        tabledata * = R;
}

permissionset 95114 "LT Y94 Ref wtdi"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        tabledata * = I;
}

permissionset 95115 "LT Y94 Ref wcu"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        codeunit * = X;
}

permissionset 95116 "LT Y94 Ref wpg"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        page * = X;
}

permissionset 95117 "LT Y94 Ref wrep"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        report * = X;
}

permissionset 95118 "LT Y94 Ref wqry"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        query * = X;
}

permissionset 95119 "LT Y94 Ref wxml"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        xmlport * = X;
}

permissionset 95120 "LT Y94 Ref wtbl"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        table * = X;
}

permissionset 95121 "LT Y94 Ref wsys"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Ref Card" = X,
        system * = X;
}

permissionset 95122 "LT Y94 List none"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 List" = X;
}

permissionset 95123 "LT Y94 List ar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 List" = X,
        tabledata "LT Y94 Guard A" = R;
}

permissionset 95124 "LT Y94 List br"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 List" = X,
        tabledata "LT Y94 Guard B" = R;
}

permissionset 95125 "LT Y94 List abr"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 List" = X,
        tabledata "LT Y94 Guard A" = R,
        tabledata "LT Y94 Guard B" = R;
}

permissionset 95126 "LT Y94 Cue none"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Cue Part" = X;
}

permissionset 95127 "LT Y94 Cue ar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Cue Part" = X,
        tabledata "LT Y94 Guard A" = R;
}

permissionset 95128 "LT Y94 Cue br"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Cue Part" = X,
        tabledata "LT Y94 Guard B" = R;
}

permissionset 95129 "LT Y94 Cue abr"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Cue Part" = X,
        tabledata "LT Y94 Guard A" = R,
        tabledata "LT Y94 Guard B" = R;
}

permissionset 95130 "LT Y94 Conf none"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Conflict" = X;
}

permissionset 95131 "LT Y94 Conf ar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Conflict" = X,
        tabledata "LT Y94 Guard A" = R;
}

permissionset 95132 "LT Y94 Conf br"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Conflict" = X,
        tabledata "LT Y94 Guard B" = R;
}

permissionset 95133 "LT Y94 Conf abr"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Conflict" = X,
        tabledata "LT Y94 Guard A" = R,
        tabledata "LT Y94 Guard B" = R;
}

permissionset 95134 "LT Y94 Lvl none"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Page Level" = X;
}

permissionset 95135 "LT Y94 Lvl ar"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Page Level" = X,
        tabledata "LT Y94 Guard A" = R;
}

permissionset 95136 "LT Y94 Lvl br"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y94 Row" = RIMD,
        page "LT Y94 Page Level" = X,
        tabledata "LT Y94 Guard B" = R;
}
