// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: TP SrcTemp Part Row (60804)
//
// A ListPart declaring SourceTableTemporary = true — the SourceTable IS the part's own
// state, but a private, per-instance temporary buffer rather than a shared database table.
// The host populates it once, from OnOpenPage, through CurrPage.Lines.Page.SetRows; nothing
// else ever writes to it. That makes this the sharpest form of issue #2201's claim: unlike
// the page-globals CardPart shape (codeunit 60803), here the record ITSELF only exists on
// whichever object instance the host wrote through — a second, disconnected part page
// object has an EMPTY temporary table, not merely stale globals.

page 60805 "TP SrcTemp Part"
{
    PageType = ListPart;
    SourceTable = "TP SrcTemp Part Row";
    SourceTableTemporary = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteRow)
            {
                ApplicationArea = All;
                Image = Delete;

                trigger OnAction()
                begin
                    Rec.Delete();
                    CurrPage.Update();
                end;
            }
        }
    }

    // The in-page access path the host's own AL uses (CurrPage.Lines.Page.SetRows): replace
    // the part's temporary rowset with the caller's rows.
    internal procedure SetRows(var TempRow: Record "TP SrcTemp Part Row" temporary)
    begin
        Rec.DeleteAll();
        if TempRow.FindSet() then
            repeat
                Rec := TempRow;
                Rec.Insert();
            until TempRow.Next() = 0;
    end;
}
