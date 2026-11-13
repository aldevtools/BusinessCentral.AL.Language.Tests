// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51761 "Document Repro Page 51761"
{
    PageType = Document;
    SourceTable = "Document Repro Row 51760";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Scan; InputText)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Payload := InputText;
                        Rec.Modify();
                    end;
                }
            }
        }
    }

    var
        InputText: Text[20];
}
