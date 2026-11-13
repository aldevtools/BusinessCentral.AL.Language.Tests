// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51763 "Document Repro With Part 51763"
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
            part(Lines; "Document Repro Lines 51765")
            {
                ApplicationArea = All;
                SubPageLink = HeaderId = field(Id);
            }
            part(SecondLines; "Document Repro Lines 51765")
            {
                ApplicationArea = All;
                SubPageLink = HeaderId = field(Id);
            }
            part(ThirdLines; "Document Repro Lines 51765")
            {
                ApplicationArea = All;
                SubPageLink = HeaderId = field(Id);
            }
            part(FourthLines; "Document Repro Lines 51765")
            {
                ApplicationArea = All;
                SubPageLink = HeaderId = field(Id);
            }
            part(HeaderCard; "Probe Packing Header Card")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
            part(HiddenLines; "Document Repro Lines 51765")
            {
                ApplicationArea = All;
                Visible = false;
                SubPageLink = HeaderId = field(Id);
            }
        }
    }

    var
        InputText: Text[20];
}
