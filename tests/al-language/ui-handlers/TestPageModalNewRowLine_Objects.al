// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-next-method
// Scope: in-scope
// Fixtures used: Test Modal NRL Row (60297), Test Modal NRL Plain Row (60306)
//
// Backing tables and pages for the modal new-row-line suite (codeunit 60309).
//
// The four list pages differ ONLY in their declared Editable property and in whether
// OnOpenPage sets CurrPage.Editable := true. The two tables differ only in which page they
// name as LookupPageId, so Page.RunModal(0, Rec) can reach both a re-enabled page and a page
// with no Editable property at all.

table 60297 "Test Modal NRL Row"
{
    DataClassification = CustomerContent;
    LookupPageId = "Test Modal NRL ReEditable";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Closed; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 60306 "Test Modal NRL Plain Row"
{
    DataClassification = CustomerContent;
    LookupPageId = "Test Modal NRL Plain Lookup";

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Closed; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Declares Editable = false, then turns editing back on when it opens. This is the shape of
// Base Application page 5123 "Opportunity List".
page 60298 "Test Modal NRL ReEditable"
{
    PageType = List;
    SourceTable = "Test Modal NRL Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := true;
    end;
}

// No Editable property: editable and insert-allowed by AL default.
page 60299 "Test Modal NRL Plain"
{
    PageType = List;
    SourceTable = "Test Modal NRL Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
            }
        }
    }
}

// Declares Editable = false and leaves it that way.
page 60302 "Test Modal NRL NotEditable"
{
    PageType = List;
    SourceTable = "Test Modal NRL Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
            }
        }
    }
}

// Same as page 60299, over the second table, so Page.RunModal(0, Rec) can open a page that
// declares no Editable property.
page 60307 "Test Modal NRL Plain Lookup"
{
    PageType = List;
    SourceTable = "Test Modal NRL Plain Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
            }
        }
    }
}
