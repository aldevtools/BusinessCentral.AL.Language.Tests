// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: none (objects read by AwTests.al)
// Objects for corpus issue 648 (platform tables on a fresh tenant): a per-company table for Record Link, a table declared
// ObsoleteState = Moved, a source table and pages whose SourceTableView combines SORTING, ORDER and two conditions, a page with
// two action containers, nested groups and actionrefs, and a report with Excel layouts that declare ExcelLayoutMultipleDataSheets
// true, false and nothing, a Pending layout (ObsoleteState = Removed on a layout does not compile: must-not-compile case 1180), and layouts with and without a Caption. Object ids 80300-80330.

table 80300 "LT AW Link Host"
{
    DataClassification = SystemMetadata;
    DataPerCompany = true;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 80301 "LT AW Moved Table"
{
    DataClassification = SystemMetadata;
    ObsoleteState = Moved;
    ObsoleteReason = 'Moved to another app';
    ObsoleteTag = '1.0';
    MovedTo = '11111111-2222-3333-4444-555555555555';

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 80302 "LT AW View Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Code; Code[20]) { }
        field(3; Amount; Decimal) { }
        field(4; Status; Option) { OptionMembers = Open,Released,Closed; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(CodeAmount; Code, Amount) { }
        key(ByAmount; Amount) { }
    }
}

page 80310 "LT AW View Asc"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AW View Src";
    SourceTableView = sorting(Code, Amount) order(ascending) where(Id = filter(1 .. 10), Code = const('A'));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(Id; Rec.Id) { } }
        }
    }
}

page 80311 "LT AW View Desc"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AW View Src";
    SourceTableView = sorting(Amount) order(descending) where(Status = const(Released), Amount = filter(> 0));

    layout
    {
        area(Content)
        {
            repeater(Rows) { field(Id; Rec.Id) { } }
        }
    }
}

page 80312 "LT AW Actions"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT AW View Src";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
        }
    }

    actions
    {
        area(Processing)
        {
            group(GOuter)
            {
                Caption = 'Outer';
                action(A1)
                {
                    Caption = 'A one';
                    trigger OnAction()
                    begin
                    end;
                }
                group(GInner)
                {
                    Caption = 'Inner';
                    action(A2)
                    {
                        Caption = 'A two';
                        trigger OnAction()
                        begin
                        end;
                    }
                }
            }
            action(A3)
            {
                Caption = 'A three';
                trigger OnAction()
                begin
                end;
            }
        }
        area(Navigation)
        {
            action(N1)
            {
                Caption = 'N one';
                RunObject = page "LT AW View Asc";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(A1Ref; A1) { }
            }
            actionref(A3Ref; A3) { }
        }
    }
}

report 80320 "LT AW Layouts"
{
    UsageCategory = None;
    DefaultRenderingLayout = XlOmit;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Number; Number) { }
        }
    }

    rendering
    {
        layout(XlTrue)
        {
            Type = Excel;
            LayoutFile = './metadata/platform-tables/AwXlTrue.xlsx';
            ExcelLayoutMultipleDataSheets = true;
        }
        layout(XlFalse)
        {
            Type = Excel;
            LayoutFile = './metadata/platform-tables/AwXlFalse.xlsx';
            ExcelLayoutMultipleDataSheets = false;
        }
        layout(XlOmit)
        {
            Type = Excel;
            LayoutFile = './metadata/platform-tables/AwXlOmit.xlsx';
        }
        layout(XlPending)
        {
            Type = Excel;
            LayoutFile = './metadata/platform-tables/AwXlPending.xlsx';
            ObsoleteState = Pending;
            ObsoleteReason = 'Pending';
            ObsoleteTag = '1.0';
        }
        layout(XlCaptioned)
        {
            Type = Excel;
            LayoutFile = './metadata/platform-tables/AwXlCaptioned.xlsx';
            Caption = 'LT AW captioned layout';
        }
    }
}
