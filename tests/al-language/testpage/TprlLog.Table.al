// Fixture log table for TestPageActionRunPageLink.al. Separate from the tables the pages under
// test are bound to on purpose: a handler runs WHILE the host page is open, and writing into
// the host's or the target's own source table mid-invoke would move a rowset under it.
table 60464 "TPRL Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry"; Code[20]) { }
        // Every Descr the target page showed, in the order it showed them, joined by ','.
        // Recorded as a whole rowset rather than a count so an assertion names concrete
        // values -- 'H2-L1,H2-L2' -- instead of a number several wrong rowsets share.
        field(2; Detail; Text[250]) { }
        field(3; "Row Count"; Integer) { }
        // The Descr the target was ALREADY positioned on when the handler was entered,
        // before the handler moved anything.
        field(4; "Initial Row"; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry") { Clustered = true; }
    }
}
