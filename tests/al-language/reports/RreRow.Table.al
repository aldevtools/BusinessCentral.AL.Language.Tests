// Migrated from AL Runner tests/runner-extras/report-run-execution (RreSrc.al).
// Backing table with real stored rows, so the control experiment does not depend on
// any virtual-table provider.
table 60866 "RRE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
