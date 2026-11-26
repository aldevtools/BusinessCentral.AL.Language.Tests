// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51715 "Next Refresh Lines"
{
    PageType = ListPart;
    SourceTable = "Next Refresh Line";
    ApplicationArea = All;
    InsertAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Detail; Rec.Text) { }
            }
        }
    }
}
