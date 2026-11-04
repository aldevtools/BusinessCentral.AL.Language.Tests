// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-data-type
// Scope: in-scope
// Fixtures used: ALT TestFilter Row (60347)
//
// A list whose OnOpenPage has the shape of Base Application's GenJnlManagement.OpenJnlBatch
// (codeunit 230, called from page 251 "General Journal Batches"): a filter set in filter
// group 0, then filter group 2 left ACTIVE on Rec when the trigger returns. Driven by
// codeunit 60919.

page 60975 "ALT TestFilter Grp Left List"
{
    PageType = List;
    SourceTable = "ALT TestFilter Row";
    ApplicationArea = All;
    Caption = 'ALT TestFilter Grp Left List';
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
    end;
}
