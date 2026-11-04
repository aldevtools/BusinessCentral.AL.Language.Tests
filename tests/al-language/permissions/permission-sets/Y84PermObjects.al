// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-accessbypermission-property
// Scope: in-scope
// Fixtures used: none (own objects; LT Y24 objects 91936-91978 as guard targets).
// Objects for the writer Y84 permission probes (al-runtime-rs ADR-062 stage 3): AccessByPermission on page fields, actions and parts with every letter
// and every object kind, on the page object, on the report object, on a table field and on request page fields; trigger, page and subscriber
// code that runs an object the session may not execute; permission sets that grant the guard table in each letter and level.
// Object ids 94380-94421 and 94500-94506. An object that runs code is checked for Execute the first time the session loads it, so every Execute case uses
// objects (U1 - U5, T1, T2, the pages and the subscriber) that no other case uses before it.

table 94380 "LT Y84 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
        field(3; Name; Text[30]) { }
        // Table field level: every page field bound to it is guarded.
        field(4; TfGuard; Integer) { AccessByPermission = tabledata "LT Y84 Guard" = R; }
        field(5; GuardCount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y84 Guard");
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 94381 "LT Y84 Guard"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 94383 "LT Y84 ABP Part"
{
    PageType = ListPart;
    SourceTable = "LT Y84 Row";
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

page 94382 "LT Y84 ABP Card"
{
    PageType = Card;
    SourceTable = "LT Y84 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(PlainCtl; Rec.Id) { ApplicationArea = All; }
            field(TfCtl; Rec.TfGuard) { ApplicationArea = All; }
            field(FlowCtl; Rec.GuardCount) { ApplicationArea = All; }
            field(GR; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = R; }
            field(GI; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = I; }
            field(GM; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = M; }
            field(GD; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = D; }
            field(GIM; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = IM; }
            field(GRIMD; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = RIMD; }
            field(GLowR; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = r; }
            field(GLowRIMD; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = rimd; }
            field(ObjCu; Rec.Name) { ApplicationArea = All; AccessByPermission = codeunit "LT Y24 Exec Target" = X; }
            field(ObjQry; Rec.Name) { ApplicationArea = All; AccessByPermission = query "LT Y24 Row Query" = X; }
            field(ObjXp; Rec.Name) { ApplicationArea = All; AccessByPermission = xmlport "LT Y24 Row Xml" = X; }
            field(ObjRep; Rec.Name) { ApplicationArea = All; AccessByPermission = report "LT Y24 Proc Rep" = X; }
            field(ObjPg; Rec.Name) { ApplicationArea = All; AccessByPermission = page "LT Y24 Row Card" = X; }
            field(ObjTbl; Rec.Name) { ApplicationArea = All; AccessByPermission = table "LT Y24 Row" = X; }
            field(ObjSys; Rec.Name) { ApplicationArea = All; AccessByPermission = system "Allow Action Export To Excel" = X; }
            field(ObjCuLow; Rec.Name) { ApplicationArea = All; AccessByPermission = codeunit "LT Y24 Exec Target" = x; }
            part(PlainPart; "LT Y84 ABP Part") { ApplicationArea = All; }
            part(GuardPart; "LT Y84 ABP Part") { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = R; }
            part(GuardObjPart; "LT Y84 ABP Part") { ApplicationArea = All; AccessByPermission = codeunit "LT Y24 Exec Target" = X; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PlainAct) { ApplicationArea = All; trigger OnAction() begin end; }
            action(ActR) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = R; trigger OnAction() begin end; }
            action(ActI) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = I; trigger OnAction() begin end; }
            action(ActM) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = M; trigger OnAction() begin end; }
            action(ActD) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = D; trigger OnAction() begin end; }
            action(ActRIMD) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = RIMD; trigger OnAction() begin end; }
            action(ActCu) { ApplicationArea = All; AccessByPermission = codeunit "LT Y24 Exec Target" = X; trigger OnAction() begin end; }
            action(ActQry) { ApplicationArea = All; AccessByPermission = query "LT Y24 Row Query" = X; trigger OnAction() begin end; }
            action(ActXp) { ApplicationArea = All; AccessByPermission = xmlport "LT Y24 Row Xml" = X; trigger OnAction() begin end; }
            action(ActRep) { ApplicationArea = All; AccessByPermission = report "LT Y24 Proc Rep" = X; trigger OnAction() begin end; }
            action(ActPg) { ApplicationArea = All; AccessByPermission = page "LT Y24 Row Card" = X; trigger OnAction() begin end; }
            action(ActTbl) { ApplicationArea = All; AccessByPermission = table "LT Y24 Row" = X; trigger OnAction() begin end; }
            action(ActSys) { ApplicationArea = All; AccessByPermission = system "Allow Action Export To Excel" = X; trigger OnAction() begin end; }
        }
    }
}

// The page object itself carries AccessByPermission.
page 94384 "LT Y84 ABP Page Level"
{
    PageType = Card;
    SourceTable = "LT Y84 Row";
    UsageCategory = Administration;
    AccessByPermission = tabledata "LT Y84 Guard" = R;

    layout
    {
        area(Content)
        {
            field(PlainCtl; Rec.Id) { ApplicationArea = All; }
        }
    }
}

// Processing-only report whose request page fields are guarded.
report 94385 "LT Y84 ABP Rep"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(PlainOpt; PlainOption) { ApplicationArea = All; }
                field(ROpt; GuardOption) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = R; }
                field(IOpt; GuardOption) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = I; }
                field(MOpt; GuardOption) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = M; }
                field(DOpt; GuardOption) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = D; }
                field(RIMDOpt; GuardOption) { ApplicationArea = All; AccessByPermission = tabledata "LT Y84 Guard" = RIMD; }
                field(CuOpt; GuardOption) { ApplicationArea = All; AccessByPermission = codeunit "LT Y24 Exec Target" = X; }
            }
        }
    }

    var
        PlainOption: Boolean;
        GuardOption: Boolean;

    trigger OnPreReport()
    begin
        PlainOption := true;
    end;
}

// The report object itself carries AccessByPermission.
report 94386 "LT Y84 ABP Rep Level"
{
    ProcessingOnly = true;
    UsageCategory = Administration;
    AccessByPermission = tabledata "LT Y84 Guard" = R;
}

// Execute denial inside table triggers: Mode 1 runs a codeunit, Mode 2 calls a procedure of one.
table 94387 "LT Y84 Trig Tbl"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Mode; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        Touch();
    end;

    trigger OnModify()
    begin
        Touch();
    end;

    trigger OnDelete()
    begin
        Touch();
    end;

    local procedure Touch()
    var
        Target: Codeunit "LT Y84 Target 2";
    begin
        case Mode of
            1:
                Codeunit.Run(Codeunit::"LT Y84 Target 1");
            2:
                if Target.Ping() = '' then;
        end;
    end;
}

table 94506 "LT Y84 Trig Tbl 2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Mode; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        Touch();
    end;

    trigger OnModify()
    begin
        Touch();
    end;

    trigger OnDelete()
    begin
        Touch();
    end;

    local procedure Touch()
    var
        Target: Codeunit "LT Y84 Target 2";
    begin
        case Mode of
            1:
                Codeunit.Run(Codeunit::"LT Y84 Target 1");
            2:
                if Target.Ping() = '' then;
        end;
    end;
}

table 94388 "LT Y84 Sub Tbl"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 94389 "LT Y84 Trig Open"
{
    PageType = Card;
    SourceTable = "LT Y84 Sub Tbl";
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
        Target: Codeunit "LT Y84 Target 3";
    begin
        if Target.Ping() = '' then;
    end;
}

page 94390 "LT Y84 Trig Action"
{
    PageType = Card;
    SourceTable = "LT Y84 Sub Tbl";
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
            action(RunIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"LT Y84 Target 4");
                end;
            }
        }
    }
}

// Event subscriber that runs another codeunit (bound manually by the test).
codeunit 94391 "LT Y84 Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT Y84 Sub Tbl", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSub(var Rec: Record "LT Y84 Sub Tbl"; RunTrigger: Boolean)
    var
        Target: Codeunit "LT Y84 Target 5";
    begin
        if Target.Ping() = '' then;
    end;
}

// Fresh Execute targets, one per case.
codeunit 94500 "LT Y84 Target 1"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94501 "LT Y84 Target 2"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94502 "LT Y84 Target 3"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94503 "LT Y84 Target 4"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94504 "LT Y84 Target 5"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

permissionset 94396 "LT Y84 C R"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = R;
}

permissionset 94397 "LT Y84 C I"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = I;
}

permissionset 94398 "LT Y84 C M"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = M;
}

permissionset 94399 "LT Y84 C D"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = D;
}

permissionset 94400 "LT Y84 C IM"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = IM;
}

permissionset 94401 "LT Y84 C RIMD"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = RIMD;
}

permissionset 94402 "LT Y84 C Ind R"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = r;
}

permissionset 94403 "LT Y84 C Ind I"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = i;
}

permissionset 94404 "LT Y84 C Ind RIMD"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        tabledata "LT Y84 Guard" = rimd;
}

permissionset 94405 "LT Y84 C None"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD;
}

permissionset 94406 "LT Y84 X Some"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        page "LT Y84 ABP Card" = X,
        codeunit "LT Y24 Exec Target" = X,
        query "LT Y24 Row Query" = X;
}

permissionset 94407 "LT Y84 X Other"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        page "LT Y84 ABP Card" = X,
        report "LT Y24 Proc Rep" = X,
        xmlport "LT Y24 Row Xml" = X,
        page "LT Y24 Row Card" = X,
        table "LT Y24 Row" = X,
        system "Allow Action Export To Excel" = X;
}

permissionset 94408 "LT Y84 X Ind"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        page "LT Y84 ABP Card" = X,
        codeunit "LT Y24 Exec Target" = x,
        query "LT Y24 Row Query" = x,
        xmlport "LT Y24 Row Xml" = x,
        report "LT Y24 Proc Rep" = x,
        page "LT Y24 Row Card" = x,
        table "LT Y24 Row" = x;
}

permissionset 94409 "LT Y84 X None"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Row" = RIMD,
        page "LT Y84 ABP Card" = X;
}

permissionset 94410 "LT Y84 T Tab"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Trig Tbl 2" = RIMD;
}

permissionset 94411 "LT Y84 T TabX"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Trig Tbl" = RIMD,
        table "LT Y84 Trig Tbl" = X;
}

permissionset 94412 "LT Y84 T Both"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Trig Tbl" = RIMD,
        table "LT Y84 Trig Tbl" = X,
        codeunit "LT Y84 Target 1" = X,
        codeunit "LT Y84 Target 2" = X;
}

permissionset 94414 "LT Y84 P Page"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Sub Tbl" = RIMD,
        page "LT Y84 Trig Open" = X;
}

permissionset 94415 "LT Y84 P Both"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Sub Tbl" = RIMD,
        page "LT Y84 Trig Open" = X,
        codeunit "LT Y84 Target 3" = X;
}

permissionset 94416 "LT Y84 A Page"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Sub Tbl" = RIMD,
        page "LT Y84 Trig Action" = X;
}

permissionset 94417 "LT Y84 A Both"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Sub Tbl" = RIMD,
        page "LT Y84 Trig Action" = X,
        codeunit "LT Y84 Target 4" = X;
}

permissionset 94418 "LT Y84 S Tab"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Sub Tbl" = RIMD;
}

permissionset 94419 "LT Y84 S Sub"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Sub Tbl" = RIMD,
        codeunit "LT Y84 Subscriber" = X;
}

permissionset 94420 "LT Y84 S Both"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y84 Sub Tbl" = RIMD,
        codeunit "LT Y84 Subscriber" = X,
        codeunit "LT Y84 Target 5" = X;
}

