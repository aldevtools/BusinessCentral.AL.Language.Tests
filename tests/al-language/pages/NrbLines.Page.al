// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-new-method
// Scope: in-scope
// Fixtures used: NRB Line (60650), NRB Lines (60651)
//
// The editable line grid under test. "No. Validated" is a control here even though nothing
// on the page ever sets it directly -- a TestPage can only read a field that is a control,
// and this suite's whole second claim is reading what New() did to it. "No." is a control
// too, read-only in effect because it is never SetValue()'d anywhere in this suite -- any
// value it carries on a New() row came from the SubPageLink, never from the test.

page 60651 "NRB Lines"
{
    PageType = ListPart;
    SourceTable = "NRB Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
                field("No. Validated"; Rec."No. Validated")
                {
                    ApplicationArea = All;
                }
                field("Never Validated"; Rec."Never Validated")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
