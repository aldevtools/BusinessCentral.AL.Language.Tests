// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none (own objects; Permissions Mock from the dependency).
// Objects for the al-runtime-rs ADR-062 permission probes P14-P22 (writer Y24, stages 2 and 3): own tables with FlowFields, a card
// page, a page with AccessByPermission, queries, xmlports and reports with and without a Permissions property, codeunits that run
// objects with and without Execute grants in their Permissions property, permission sets.
// Object ids 91936-91949 and 91957-91974; test codeunits 91975-91977, the helper 91978 and the stage 4 helper 91979 (called by
// tests/al-language-testlibraries/lt-y24-runner-perms/Y24RunnerPerms.al, which has no Permissions Mock dependency).

table 91936 "LT Y24 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Value; Integer) { }
        field(3; Name; Text[30]) { }
        // A temporary record's Blob takes xmlport output without any codeunit of another app.
        field(4; Data; Blob) { }
    }
    keys { key(PK; Id) { Clustered = true; } }

    // P20: a table procedure that touches no data.
    procedure Describe(): Text
    begin
        exit('tp');
    end;
}

table 91937 "LT Y24 FF Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Amount; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// P15: one FlowField per CalcFormula kind over "LT Y24 FF Child".
table 91938 "LT Y24 FF Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; LookupAmount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("LT Y24 FF Child".Amount where(ParentId = field(Id)));
        }
        field(3; HasChild; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT Y24 FF Child" where(ParentId = field(Id)));
        }
        field(4; SumAmount; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT Y24 FF Child".Amount where(ParentId = field(Id)));
        }
        field(5; CountChild; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y24 FF Child" where(ParentId = field(Id)));
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

// P18 and P20: a plain card over "LT Y24 Row".
page 91939 "LT Y24 Row Card"
{
    PageType = Card;
    SourceTable = "LT Y24 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(ValueCtl; Rec.Value) { ApplicationArea = All; }
        }
    }
}

// P15: the FlowFields on a card.
page 91940 "LT Y24 FF Parent Card"
{
    PageType = Card;
    SourceTable = "LT Y24 FF Parent";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(SumCtl; Rec.SumAmount) { ApplicationArea = All; }
        }
    }
}

// P16 and P20: queries over "LT Y24 Row" without and with Permissions = r.
query 91941 "LT Y24 Row Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT Y24 Row")
        {
            column(Id; Id) { }
        }
    }
}

query 91942 "LT Y24 Row Query Perm"
{
    QueryType = Normal;
    Permissions = tabledata "LT Y24 Row" = r;

    elements
    {
        dataitem(Row; "LT Y24 Row")
        {
            column(Id; Id) { }
        }
    }
}

// P16 and P20: xmlports over "LT Y24 Row" without and with Permissions = r.
xmlport 91943 "LT Y24 Row Xml"
{
    Direction = Export;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y24 Row")
            {
                fieldattribute(Id; Row.Id) { }
            }
        }
    }
}

xmlport 91944 "LT Y24 Row Xml Perm"
{
    Direction = Export;
    Format = Xml;
    Permissions = tabledata "LT Y24 Row" = r;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y24 Row")
            {
                fieldattribute(Id; Row.Id) { }
            }
        }
    }
}

// P17: a report with a dataset (Report.SaveAs Xml), without and with Permissions = r.
report 91945 "LT Y24 Row Rep"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT Y24 Row")
        {
            column(IdC; Id) { }
        }
    }
}

report 91946 "LT Y24 Row Rep Perm"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;
    UsageCategory = None;
    Permissions = tabledata "LT Y24 Row" = r;

    dataset
    {
        dataitem(Row; "LT Y24 Row")
        {
            column(IdC; Id) { }
        }
    }
}

// P20: the codeunit whose execution is checked.
codeunit 91947 "LT Y24 Exec Target"
{
    trigger OnRun()
    begin
    end;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

// P19: ReadPermission and WritePermission inside an object whose Permissions property names the table.
codeunit 91948 "LT Y24 Perm Reader"
{
    Permissions = tabledata "LT Y24 Row" = rimd;

    procedure ReadWrite(): Text
    var
        Row: Record "LT Y24 Row";
    begin
        exit(Format(Row.ReadPermission()) + '/' + Format(Row.WritePermission()));
    end;
}

// P20: runs each object kind from a codeunit that the exact set "LT Y24 TD Granter" grants Execute on. A Permissions property cannot name
// an Execute grant (only tabledata entries compile: tests/must-not-compile/cases/2360, 2361), so the probe asks whether Execute on the
// calling codeunit covers the objects it runs.
codeunit 91949 "LT Y24 Exec Granter"
{

    procedure Run(Which: Integer): Text
    var
        Row: Record "LT Y24 Row";
        Target: Codeunit "LT Y24 Exec Target";
        ProcRep: Report "LT Y24 Proc Rep";
        TempRow: Record "LT Y24 Row" temporary;
        Qry: Query "LT Y24 Row Query";
        OutS: OutStream;
    begin
        case Which of
            1:
                begin
                    Codeunit.Run(Codeunit::"LT Y24 Exec Target");
                    exit('run');
                end;
            2:
                exit(Target.Ping());
            3:
                begin
                    ProcRep.UseRequestPage(false);
                    ProcRep.RunModal();
                    exit(ProcRep.Seen());
                end;
            4:
                begin
                    Page.Run(Page::"LT Y24 Row Card");
                    exit('page');
                end;
            6:
                begin
                    TempRow.Data.CreateOutStream(OutS);
                    Xmlport.Export(Xmlport::"LT Y24 Row Xml", OutS);
                    exit('xml ' + Format(TempRow.Data.Length()));
                end;
            7:
                begin
                    Qry.Open();
                    exit('query ' + Format(Qry.Read()));
                end;
            8:
                exit(Row.Describe());
        end;
    end;
}

// ---- permission sets ----

// Grants nothing on the Y24 tables (one grant so that the set is not empty).
permissionset 91957 "LT Y24 None"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 Trig B" = R;
}

permissionset 91958 "LT Y24 Ind R"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = r;
}

permissionset 91959 "LT Y24 Ind RIMD"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = rimd;
}

permissionset 91960 "LT Y24 I"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = I;
}

permissionset 91961 "LT Y24 IM"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = IM;
}

permissionset 91962 "LT Y24 IMD"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = IMD;
}

permissionset 91963 "LT Y24 RIMD"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = RIMD;
}

permissionset 91964 "LT Y24 R"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = R;
}

// P15: read on the parent, nothing on the CalcFormula table.
permissionset 91965 "LT Y24 FF Parent R"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 FF Parent" = R;
}

// P15: read on the parent, indirect read on the CalcFormula table.
permissionset 91966 "LT Y24 FF Child Ind"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y24 FF Parent" = R,
        tabledata "LT Y24 FF Child" = r;
}

// P20 (SetExactPermissionSet): table data grants only, no object grants.
permissionset 91967 "LT Y24 TD Only"
{
    Assignable = true;
    Permissions = tabledata "LT Y24 Row" = RIMD;
}

// P20: table data, Execute on "LT Y24 Exec Granter" only.
permissionset 91968 "LT Y24 TD Granter"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y24 Row" = RIMD,
        codeunit "LT Y24 Exec Granter" = X;
}

// P21: a page with AccessByPermission on two fields and an action.
page 91969 "LT Y24 ABP Card"
{
    PageType = Card;
    SourceTable = "LT Y24 Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(PlainCtl; Rec.Id) { ApplicationArea = All; }
            field(GuardRCtl; Rec.Value) { ApplicationArea = All; AccessByPermission = tabledata "LT Y24 FF Child" = R; }
            field(GuardICtl; Rec.Name) { ApplicationArea = All; AccessByPermission = tabledata "LT Y24 FF Child" = I; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PlainAct)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                end;
            }
            action(GuardXAct)
            {
                ApplicationArea = All;
                AccessByPermission = codeunit "LT Y24 Exec Target" = X;
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

// P17 and P21: a processing-only report that counts the rows it reads; its request page has a field guarded by AccessByPermission.
report 91970 "LT Y24 Proc Rep"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT Y24 Row")
        {
            trigger OnAfterGetRecord()
            begin
                SeenIds += Format(Row.Id) + ';';
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(PlainOpt; PlainOption) { ApplicationArea = All; }
                field(GuardROpt; GuardOption) { ApplicationArea = All; AccessByPermission = tabledata "LT Y24 FF Child" = R; }
            }
        }
    }

    var
        SeenIds: Text;
        PlainOption: Boolean;
        GuardOption: Boolean;

    procedure Seen(): Text
    begin
        exit('seen ' + SeenIds);
    end;
}

// P17: the same report with Permissions = r on the row table.
report 91971 "LT Y24 Proc Rep Perm"
{
    ProcessingOnly = true;
    UsageCategory = None;
    Permissions = tabledata "LT Y24 Row" = r;

    dataset
    {
        dataitem(Row; "LT Y24 Row")
        {
            trigger OnAfterGetRecord()
            begin
                SeenIds += Format(Row.Id) + ';';
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(PlainOpt; PlainOption) { ApplicationArea = All; }
            }
        }
    }

    var
        SeenIds: Text;
        PlainOption: Boolean;

    procedure Seen(): Text
    begin
        exit('seen ' + SeenIds);
    end;
}

// P21: grants the guarded fields' table (R and I) besides the row table.
permissionset 91972 "LT Y24 ABP Grant"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y24 Row" = RIMD,
        tabledata "LT Y24 FF Child" = RI;
}

// P21 (SetExactPermissionSet): the page and the row table, without and with Execute on the codeunit that guards the action.
permissionset 91973 "LT Y24 ABP Exact NoX"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y24 Row" = RIMD,
        page "LT Y24 ABP Card" = X;
}

permissionset 91974 "LT Y24 ABP Exact X"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y24 Row" = RIMD,
        page "LT Y24 ABP Card" = X,
        codeunit "LT Y24 Exec Target" = X;
}

// Helpers shared by the Y24 test codeunits (not SingleInstance, no state).
codeunit 91978 "LT Y24 Perm Helper"
{
    // Rows 1 (10, 'a') and 2 (20, 'b') in "LT Y24 Row"; parents 1 and 2; children of parent 1 with amounts 5 and 7.
    procedure Seed()
    var
        Row: Record "LT Y24 Row";
        Parent: Record "LT Y24 FF Parent";
        Child: Record "LT Y24 FF Child";
    begin
        Row.DeleteAll();
        Parent.DeleteAll();
        Child.DeleteAll();
        InsertRow(1, 10, 'a');
        InsertRow(2, 20, 'b');
        Parent.Id := 1;
        Parent.Insert();
        Parent.Id := 2;
        Parent.Insert();
        Child.Id := 1;
        Child.ParentId := 1;
        Child.Amount := 5;
        Child.Insert();
        Child.Id := 2;
        Child.ParentId := 1;
        Child.Amount := 7;
        Child.Insert();
    end;

    procedure SeedEmpty()
    var
        Row: Record "LT Y24 Row";
    begin
        Seed();
        Row.DeleteAll();
    end;

    local procedure InsertRow(NewId: Integer; NewValue: Integer; NewName: Text[30])
    var
        Row: Record "LT Y24 Row";
    begin
        Row.Id := NewId;
        Row.Value := NewValue;
        Row.Name := NewName;
        Row.Insert();
    end;

    // The rows of "LT Y24 Row" as "id=value;..." (the inherent read works under any mocked set).
    [InherentPermissions(PermissionObjectType::TableData, Database::"LT Y24 Row", 'R')]
    procedure DescribeRows(): Text
    var
        Row: Record "LT Y24 Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '=' + Format(Row.Value) + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    // P23 (stage 4): row 81640 in "LT Y24 Row", inserted through the inherent permission whatever sets are assigned.
    [InherentPermissions(PermissionObjectType::TableData, Database::"LT Y24 Row", 'RIMD')]
    procedure SeedRunnerRow()
    var
        Row: Record "LT Y24 Row";
    begin
        Row.Id := 81640;
        if Row.Insert() then;
    end;
}

// P25 (stage 4): the Permissions Mock calls of "Library - Lower Permissions" (Tests-TestLibraries 27.5 source, codeunit 132217):
// SetO365Basic = Set('D365 Basic'), Assign('Test Tables'), Assign('D365 Basic'), Assign('LOCAL') when that set exists; AddO365Setup =
// Assign('D365 Setup'). The library does nothing when the mock is not started. Permissions Mock is SingleInstance, so these calls act on
// the session's mock that Microsoft's test runner started.
codeunit 91979 "LT Y24 Lower Calls"
{
    procedure IsStarted(): Boolean
    var
        Mock: Codeunit "Permissions Mock";
    begin
        exit(Mock.IsStarted());
    end;

    procedure SetO365Basic()
    var
        Mock: Codeunit "Permissions Mock";
#pragma warning disable AL0432
        PermissionSet: Record "Permission Set";
#pragma warning restore AL0432
    begin
        if not Mock.IsStarted() then
            exit;
        Mock.Set('D365 Basic');
        Mock.Assign('Test Tables');
        Mock.Assign('D365 Basic');
        if PermissionSet.Get('LOCAL') then
            Mock.Assign('LOCAL');
    end;

    procedure AddO365Setup()
    var
        Mock: Codeunit "Permissions Mock";
    begin
        if not Mock.IsStarted() then
            exit;
        Mock.Assign('D365 Setup');
    end;
}
