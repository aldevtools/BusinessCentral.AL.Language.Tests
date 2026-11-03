// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-data-type
// Scope: in-scope
// Fixtures used: ALT TestFilter Row (60347)
//
// OnOpenPage filters Grp in filter group 0 FIRST and then, with a different value, in filter
// group 2, and returns with group 0 active. So group 0 is written before group 2. Driven by
// codeunit 60919.

page 67960 "ALT TestFilter Grp Both List"
{
    PageType = List;
    SourceTable = "ALT TestFilter Row";
    ApplicationArea = All;
    Caption = 'ALT TestFilter Grp Both List';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(0);
        Rec.SetRange(Grp, 'A');
        Rec.FilterGroup(2);
        Rec.SetFilter(Grp, 'A|B');
        Rec.FilterGroup(0);
    end;
}
