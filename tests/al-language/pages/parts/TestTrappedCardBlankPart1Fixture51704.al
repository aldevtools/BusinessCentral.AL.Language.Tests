// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51704 "Draft Probe Card"
{
    PageType = Card;
    SourceTable = "Draft Probe Card Header";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Code; Rec.Code) { }
                field(Category; Rec.Category) { }
            }
            part(Details; "Draft Probe Detail Part")
            {
                SubPageLink = "Header Code" = field(Code);
            }
        }
    }
}
