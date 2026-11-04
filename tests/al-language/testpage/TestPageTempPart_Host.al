// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: TP SrcTemp Part Row (60804), TP SrcTemp Part (60805)
//
// Hosts the temporary-source-table ListPart and pushes rows into it from OnOpenPage — the
// Worksheet header-seeds-lines pattern, here with a part whose rowset only ever exists as a
// temporary buffer inside the part's own instance.

page 60806 "TP SrcTemp Host"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            part(Lines; "TP SrcTemp Part")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    var
        TempRow: Record "TP SrcTemp Part Row" temporary;
    begin
        TempRow."Entry No." := 1;
        TempRow.Name := 'A';
        TempRow.Insert();
        CurrPage.Lines.Page.SetRows(TempRow);
    end;
}
