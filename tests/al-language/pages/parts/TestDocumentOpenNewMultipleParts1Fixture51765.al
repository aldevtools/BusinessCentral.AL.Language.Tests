// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51765 "Document Repro Lines 51765"
{
    PageType = ListPart;
    SourceTable = "Document Repro Line 51764";
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        if Rec.Id < 0 then
            Error('Unexpected negative row.');
    end;

}
