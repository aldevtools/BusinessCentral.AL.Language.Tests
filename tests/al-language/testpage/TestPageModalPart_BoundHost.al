// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal PartList (60731)
//
// The control arm for the modal-part suite: identical to "Test Page Modal Part NoSrc"
// (60732) except that this host DOES have a SourceTable. The same part read must work on
// both hosts — a fix aimed at the no-SourceTable shape must not disturb the bound one.

page 60733 "Test Page Modal Part Bound"
{
    PageType = Worksheet;
    SourceTable = "Test Page Modal Handler Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Mode; SelectedMode)
                {
                    ApplicationArea = All;
                    Caption = 'Mode';
                }
            }

            part(Lines; "Test Page Modal PartList")
            {
                ApplicationArea = All;
                Caption = 'Lines';
            }
        }
    }

    var
        SelectedMode: Text;
}
