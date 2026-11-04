// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: TPMF Head (60416), TPMF Part (60417)
//
// ONE host page for BOTH arms of the modal-close part-flush suite. Both the RunModal arm and
// the TestPage.Close() arm drive this same page, so the only thing that differs between the
// two arms is HOW the page was closed — not the page, not the part, not the table.
//
// It has a SourceTable so that the host row's own write-back is observable alongside the
// part's, and hosts one editable ListPart over a table of its own.

page 60418 "TPMF Card"
{
    PageType = Card;
    SourceTable = "TPMF Head";
    ApplicationArea = All;
    Caption = 'TPMF Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
            }

            part(Lines; "TPMF Part")
            {
                ApplicationArea = All;
                Caption = 'Lines';
            }
        }
    }
}
