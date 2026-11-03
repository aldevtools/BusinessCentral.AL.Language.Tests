// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-data-type
// Scope: in-scope
// Fixtures used: ALT TestFilter Row (60347)
//
// The page driven by the TestFilter surface suite: a plain editable List over its own source
// table, with no SourceTableView and no filters of its own, so every filter and every key the
// suite observes was put there by the test through TestFilter and by nothing else.
//
// The CONTROL NAMES ARE DELIBERATELY SPELLED DIFFERENTLY FROM THE TABLE FIELD NAMES where
// AL allows it -- the control over "Entry No." is named EntryNo. TestFilter's field argument
// resolves against the TABLE, so `Filter.GetFilter(EntryNo)` does not compile while
// `Filter.GetFilter("Entry No.")` does. If the two names were spelled alike, that distinction
// would be invisible and the suite could not tell which namespace the argument came from.
//
// The table's OffPage field has NO control here, on purpose. See the table's header.

page 60348 "ALT TestFilter List"
{
    PageType = List;
    SourceTable = "ALT TestFilter Row";
    ApplicationArea = All;
    Caption = 'ALT TestFilter List';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(EntryNo; Rec."Entry No.") { ApplicationArea = All; }
                field(Grp; Rec.Grp) { ApplicationArea = All; }
                field(Rank; Rec.Rank) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}
