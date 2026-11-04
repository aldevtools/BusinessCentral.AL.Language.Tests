// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-next-method
// Scope: in-scope
// Fixtures used: Test Page New Row Line Row (60737)
//
// Backing table and pages for the TestPage new-row-line suite.
//
// The five pages differ ONLY in the two properties that gate the implicit new-row line
// (Editable, InsertAllowed) and in how they are hosted (standalone list vs. ListPart on a
// modal card). That is deliberate: the suite's whole value is the CONTRAST between them,
// so every other property must be identical or the arms stop being comparable.

// Editable and insert-allowed, both by AL default. This is the page the new-row line exists on.
page 60738 "Test Page New Row Line List"
{
    PageType = List;
    SourceTable = "ALT Shape 02";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

// Editable = false suppresses the new-row line even under OpenEdit.
page 60739 "Test Page New Row Line RO"
{
    PageType = List;
    SourceTable = "ALT Shape 02";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

// InsertAllowed = false suppresses it too — the page is editable, but there is nothing to
// insert INTO, so the client offers no blank line.
page 60740 "Test Page New Row Line NoIns"
{
    PageType = List;
    SourceTable = "ALT Shape 02";
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 60741 "Test Page New Row Line Part"
{
    PageType = ListPart;
    SourceTable = "ALT Shape 02";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(RowNo; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 60742 "Test Page New Row Line Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            part(Lines; "Test Page New Row Line Part")
            {
                ApplicationArea = All;
            }
        }
    }
}

// A second host over the SAME part, used only to open that part inside a read-only host.
// Editable = false on the host is what must reach the part.
page 60744 "Test Page New Row Ln Host RO"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = false;

    layout
    {
        area(Content)
        {
            part(Lines; "Test Page New Row Line Part")
            {
                ApplicationArea = All;
            }
        }
    }
}
