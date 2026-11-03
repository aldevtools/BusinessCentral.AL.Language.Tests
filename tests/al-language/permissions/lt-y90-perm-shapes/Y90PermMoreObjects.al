// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none (own objects; table 61184 "LT Y19 XA Row" of the cross-app fixture xapp-a as a table of another app).
// Objects for the second part of the writer Y90 probes: Execute on a first touch of each object kind, InherentPermissions on a procedure and on a codeunit,
// the license ceiling for G/L Entry, Access Control and tenant permission sets. Object ids 94880-94899.

table 94880 "LT Y90 Tbl Exec"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94881 "LT Y90 X Cu Var"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94882 "LT Y90 X Cu Run"
{
    trigger OnRun()
    begin
    end;
}

report 94883 "LT Y90 X Rep"
{
    ProcessingOnly = true;
    UsageCategory = None;

    trigger OnPreReport()
    begin
    end;
}

page 94884 "LT Y90 X Page"
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
}

query 94885 "LT Y90 X Query"
{
    elements
    {
        dataitem(Row; "LT Y90 Row")
        {
            column(Id; Id) { }
        }
    }
}

xmlport 94886 "LT Y90 X Xml"
{
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y90 Row")
            {
                fieldelement(Id; Row.Id) { }
            }
        }
    }
}

// InherentPermissions on procedures: own table, a table of another app, a Base Application table; a plain procedure for contrast.
codeunit 94887 "LT Y90 Inherit Proc"
{
    [InherentPermissions(PermissionObjectType::TableData, Database::"LT Y90 Guard", 'I')]
    procedure InsertOwn()
    var
        Guard: Record "LT Y90 Guard";
    begin
        Guard.Id := 1;
        Guard.Insert();
    end;

    procedure InsertOwnPlain()
    var
        Guard: Record "LT Y90 Guard";
    begin
        Guard.Id := 1;
        Guard.Insert();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"LT Y19 XA Row", 'I')]
    procedure InsertOtherApp()
    var
        Other: Record "LT Y19 XA Row";
    begin
        Other.Id := 90;
        Other.Insert();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::Customer, 'R')]
    procedure ReadCustomer()
    var
        Customer: Record Customer;
    begin
        if Customer.FindFirst() then;
    end;
}

// InherentPermissions as an object property: callable by anyone.
codeunit 94888 "LT Y90 Inh Prop Yes"
{
    InherentPermissions = X;

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94889 "LT Y90 Inh Prop No"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

// A codeunit that modifies G/L Entry with its own indirect permission.
codeunit 94890 "LT Y90 GL Mod"
{
    Permissions = tabledata "G/L Entry" = m;

    procedure ModifyFirst()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindFirst();
        GLEntry.Modify();
    end;
}

permissionset 94891 "LT Y90 X Data"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        tabledata "LT Y90 Tbl Exec" = RIMD;
}

permissionset 94892 "LT Y90 L M"
{
    Assignable = true;
    Permissions =
        tabledata "G/L Entry" = RM,
        codeunit "LT Y90 GL Mod" = X;
}

permissionset 94893 "LT Y90 L m"
{
    Assignable = true;
    Permissions =
        tabledata "G/L Entry" = Rm,
        codeunit "LT Y90 GL Mod" = X;
}

permissionset 94894 "LT Y90 I Base"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y90 Row" = RIMD,
        codeunit "LT Y90 Inherit Proc" = X;
}
