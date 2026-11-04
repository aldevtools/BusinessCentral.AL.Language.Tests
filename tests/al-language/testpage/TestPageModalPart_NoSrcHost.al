// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: Test Page Modal PartList (60731)
//
// A modal Worksheet with NO SourceTable hosting a subpage part — the ordinary AL shape for
// a dialog whose header fields are bound to page globals while the rows live in a ListPart
// over its own table. The part declares no SubPageLink, so no parent record is involved in
// building or driving it. Sibling of "Test Page Modal NoSrc" (60730), which pinned the
// handler-dispatch half of this shape; this page pins the subpage-part half.

page 60732 "Test Page Modal Part NoSrc"
{
    PageType = Worksheet;
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

                    trigger OnValidate()
                    begin
                        CurrPage.Lines.Page.SetTag(SelectedMode);
                        CurrPage.Update(false);
                    end;
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
