// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-data-type
// Scope: in-scope
// Fixtures used: ALT TestFilter Row (60347)
//
// The counterpart of page 60975: OnOpenPage puts its filter in filter group 2 and returns
// with filter group 0 active. Driven by codeunit 60919.

page 60976 "ALT TestFilter Grp Hidden List"
{
    PageType = List;
    SourceTable = "ALT TestFilter Row";
    ApplicationArea = All;
    Caption = 'ALT TestFilter Grp Hidden List';
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
        Rec.FilterGroup(2);
        Rec.SetRange(Grp, 'A');
        Rec.FilterGroup(0);
    end;
}
