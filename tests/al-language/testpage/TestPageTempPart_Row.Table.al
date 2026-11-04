// Fixture row for the SourceTableTemporary ListPart shape (issue #2201, AL Runner). A host's
// OnOpenPage inserts rows into the part's OWN temporary rowset through
// CurrPage.<part>.Page.SetRows(TempRow) — that only lands in the record the TestPage itself
// later reads if the two share ONE part page instance and, with it, one temporary Rec.

table 60804 "TP SrcTemp Part Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
