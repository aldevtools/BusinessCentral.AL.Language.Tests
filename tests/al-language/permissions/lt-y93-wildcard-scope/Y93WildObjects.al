// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope
// Fixtures used: none (own objects; xapp-a objects 61170-61171 and 61173-61175 in Y93XaObjects.al).
// Objects for the writer Y93 probe (outside issue 6867, owner question 2026-11-03): does a wildcard grant in a permission set (codeunit *, page *, table *,
//   tabledata *, report *, query *, xmlport *, system *) apply to every object of the installation or only to the objects of the app that declares the set?
//   Every object that is called is used by ONE case only: Execute is checked the first time a session loads an object, so a second case on the same object
//   would measure the first load, not the set.
// Object ids 94980-94999 (per object type; the permission sets use 94980-94998).


table 94980 "LT Y93 Row"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

// A table that a set grants by wildcard and narrows by name.
table 94981 "LT Y93 Row Narrow"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 94982 "LT Y93 Tab M1"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

table 94983 "LT Y93 Tab M2"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94980 "LT Y93 Cu M1"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94981 "LT Y93 Cu M2"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94982 "LT Y93 Cu M3"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94983 "LT Y93 Cu M4"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94984 "LT Y93 Cu M5"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94985 "LT Y93 Cu M6"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94986 "LT Y93 Cu M7"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 94987 "LT Y93 Cu M8"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

// Inserts into one own table, one table of xapp-a and one table of Base Application with its own indirect permission.
codeunit 94988 "LT Y93 Cu Ind"
{
    Permissions = tabledata "LT Y93 Row" = i, tabledata "LT Y93 XA Row" = i, tabledata "Unit of Measure" = i;

    procedure InsertOwn()
    var
        Row: Record "LT Y93 Row";
    begin
        Row.Id := 1;
        Row.Insert();
    end;

    procedure InsertXapp()
    var
        Row: Record "LT Y93 XA Row";
    begin
        Row.Id := 1;
        Row.Insert();
    end;

    procedure InsertBase()
    var
        Uom: Record "Unit of Measure";
    begin
        Uom.Code := 'Y93';
        Uom.Insert();
    end;
}

codeunit 94989 "LT Y93 Cu Q1"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94982 "LT Y93 Open 1"
{
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Shown; Shown) { ApplicationArea = All; }
        }
    }

    var
        Shown: Text;

    trigger OnOpenPage()
    var
        Callee: Codeunit "LT Y93 Cu Q1";
    begin
        Shown := Callee.Ping();
    end;
}

codeunit 94990 "LT Y93 Cu Q2"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94983 "LT Y93 Open 2"
{
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Shown; Shown) { ApplicationArea = All; }
        }
    }

    var
        Shown: Text;

    trigger OnOpenPage()
    var
        Callee: Codeunit "LT Y93 Cu Q2";
    begin
        Shown := Callee.Ping();
    end;
}

codeunit 94991 "LT Y93 Cu Q3"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94984 "LT Y93 Open 3"
{
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Shown; Shown) { ApplicationArea = All; }
        }
    }

    var
        Shown: Text;

    trigger OnOpenPage()
    var
        Callee: Codeunit "LT Y93 Cu Q3";
    begin
        Shown := Callee.Ping();
    end;
}

codeunit 94992 "LT Y93 Cu Q4"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94985 "LT Y93 Open 4"
{
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Shown; Shown) { ApplicationArea = All; }
        }
    }

    var
        Shown: Text;

    trigger OnOpenPage()
    var
        Callee: Codeunit "LT Y93 Cu Q4";
    begin
        Shown := Callee.Ping();
    end;
}

codeunit 94993 "LT Y93 Cu Q5"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 94986 "LT Y93 Open 5"
{
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Shown; Shown) { ApplicationArea = All; }
        }
    }

    var
        Shown: Text;

    trigger OnOpenPage()
    var
        Callee: Codeunit "LT Y93 Cu Q5";
    begin
        Shown := Callee.Ping();
    end;
}

page 94980 "LT Y93 Page M1"
{
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Shown; Shown) { ApplicationArea = All; }
        }
    }

    var
        Shown: Text;
}

report 94980 "LT Y93 Report M1"
{
    ProcessingOnly = true;
    UsageCategory = None;

    trigger OnPreReport()
    begin
    end;
}

query 94980 "LT Y93 Query M1"
{
    elements
    {
        dataitem(Row; "LT Y93 Row")
        {
            column(Id; Id) { }
        }
    }
}

xmlport 94980 "LT Y93 Xml M1"
{
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y93 Row")
            {
                fieldelement(Id; Row.Id) { }
            }
        }
    }
}

page 94981 "LT Y93 Page M2"
{
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Shown; Shown) { ApplicationArea = All; }
        }
    }

    var
        Shown: Text;
}

report 94981 "LT Y93 Report M2"
{
    ProcessingOnly = true;
    UsageCategory = None;

    trigger OnPreReport()
    begin
    end;
}

query 94981 "LT Y93 Query M2"
{
    elements
    {
        dataitem(Row; "LT Y93 Row")
        {
            column(Id; Id) { }
        }
    }
}

xmlport 94981 "LT Y93 Xml M2"
{
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y93 Row")
            {
                fieldelement(Id; Row.Id) { }
            }
        }
    }
}

permissionset 94980 "LT Y93 W Cu"
{
    Assignable = true;
    Permissions =
        codeunit * = X;
}

permissionset 94981 "LT Y93 W Page"
{
    Assignable = true;
    Permissions =
        page * = X;
}

permissionset 94982 "LT Y93 W Table"
{
    Assignable = true;
    Permissions =
        table * = X;
}

permissionset 94983 "LT Y93 W Data"
{
    Assignable = true;
    Permissions =
        tabledata * = RIMD;
}

permissionset 94984 "LT Y93 W Report"
{
    Assignable = true;
    Permissions =
        report * = X;
}

permissionset 94985 "LT Y93 W Query"
{
    Assignable = true;
    Permissions =
        query * = X;
}

permissionset 94986 "LT Y93 W Xml"
{
    Assignable = true;
    Permissions =
        xmlport * = X;
}

permissionset 94987 "LT Y93 W Sys"
{
    Assignable = true;
    Permissions =
        system * = X;
}

permissionset 94988 "LT Y93 W All"
{
    Assignable = true;
    Permissions =
        codeunit * = X,
        page * = X,
        table * = X,
        tabledata * = RIMD,
        report * = X,
        query * = X,
        xmlport * = X,
        system * = X;
}

permissionset 94989 "LT Y93 W Ind"
{
    Assignable = true;
    Permissions =
        tabledata * = rimd;
}

permissionset 94990 "LT Y93 W Ind Cu"
{
    Assignable = true;
    Permissions =
        tabledata * = rimd,
        codeunit * = X;
}

permissionset 94991 "LT Y93 W Mix Data"
{
    Assignable = true;
    Permissions =
        tabledata * = RIMD,
        tabledata "LT Y93 Row Narrow" = R;
}

permissionset 94992 "LT Y93 W Mix Cu"
{
    Assignable = true;
    Permissions =
        codeunit * = X,
        codeunit "LT Y93 Cu M3" = x;
}

permissionset 94993 "LT Y93 Ex Cu"
{
    Assignable = true;
    Permissions =
        codeunit "LT Y93 Cu M4" = X;
}

permissionset 94994 "LT Y93 Ex Data"
{
    Assignable = true;
    Permissions =
        tabledata "LT Y93 Row" = I;
}

permissionset 94995 "LT Y93 W Excl"
{
    Assignable = true;
    IncludedPermissionSets = "LT Y93 W All";
    ExcludedPermissionSets = "LT Y93 Ex Cu", "LT Y93 Ex Data";
}

permissionset 94996 "LT Y93 W Rep Cu"
{
    Assignable = true;
    Permissions =
        report * = X,
        codeunit * = X;
}

permissionset 94997 "LT Y93 W Qry Data"
{
    Assignable = true;
    Permissions =
        query * = X,
        tabledata * = RIMD;
}

permissionset 94998 "LT Y93 W Xml Data"
{
    Assignable = true;
    Permissions =
        xmlport * = X,
        tabledata * = RIMD;
}
