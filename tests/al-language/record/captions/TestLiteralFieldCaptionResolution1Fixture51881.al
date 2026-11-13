// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldcaption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

using System.Reflection;

// local object: this object defines the page, record, or trigger behavior that the test exercises.
page 51881 "Probe Literal Caption Page"
{
    PageType = Card;
    SourceTable = "Probe Literal Caption Row";
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Payload; Rec.Payload) { ApplicationArea = All; }
                field(EditValue; EditValue) { ApplicationArea = All; }
            }
        }
    }
    var
        EditValue: Text[20];
}
