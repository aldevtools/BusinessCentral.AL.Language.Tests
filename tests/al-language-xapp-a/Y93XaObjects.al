// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-object
// Scope: in-scope
// Fixtures used: none (own objects; xapp-a objects 61170-61171 and 61173-61175 in Y93XaObjects.al).
// Objects in xapp-a for the writer Y93 probe (outside issue 6867, owner question 2026-11-03): does a wildcard grant in a permission set (codeunit *, page *, table *,
//   tabledata *, report *, query *, xmlport *, system *) apply to every object of the installation or only to the objects of the app that declares the set?
//   Every object that is called is used by ONE case only: Execute is checked the first time a session loads an object, so a second case on the same object
//   would measure the first load, not the set.
// Object ids 94980-94999 (per object type; the permission sets use 94980-94998).


table 61173 "LT Y93 XA Row"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 61174 "LT Y93 XA Tab 1"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

table 61175 "LT Y93 XA Tab 2"
{
    DataClassification = SystemMetadata;

    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

codeunit 61170 "LT Y93 XA Cu 1"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 61170 "LT Y93 XA Page 1"
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

report 61170 "LT Y93 XA Report 1"
{
    ProcessingOnly = true;
    UsageCategory = None;

    trigger OnPreReport()
    begin
    end;
}

query 61170 "LT Y93 XA Query 1"
{
    elements
    {
        dataitem(Row; "LT Y93 XA Row")
        {
            column(Id; Id) { }
        }
    }
}

xmlport 61170 "LT Y93 XA Xml 1"
{
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y93 XA Row")
            {
                fieldelement(Id; Row.Id) { }
            }
        }
    }
}

codeunit 61171 "LT Y93 XA Cu 2"
{
    procedure Ping(): Text
    begin
        exit('ping');
    end;
}

page 61171 "LT Y93 XA Page 2"
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

report 61171 "LT Y93 XA Report 2"
{
    ProcessingOnly = true;
    UsageCategory = None;

    trigger OnPreReport()
    begin
    end;
}

query 61171 "LT Y93 XA Query 2"
{
    elements
    {
        dataitem(Row; "LT Y93 XA Row")
        {
            column(Id; Id) { }
        }
    }
}

xmlport 61171 "LT Y93 XA Xml 2"
{
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT Y93 XA Row")
            {
                fieldelement(Id; Row.Id) { }
            }
        }
    }
}

// The same wildcards as LT Y93 W All, declared in xapp-a.
permissionset 61170 "LT Y93 XA All"
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
