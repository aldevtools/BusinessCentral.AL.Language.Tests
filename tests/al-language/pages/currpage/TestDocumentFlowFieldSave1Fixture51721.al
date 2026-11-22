// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51721 "Action Header Document"
{
    PageType = Document;
    SourceTable = "Action Header Row";
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { }
                field(Description; Rec.Description) { }
            }
        }
    }
}
