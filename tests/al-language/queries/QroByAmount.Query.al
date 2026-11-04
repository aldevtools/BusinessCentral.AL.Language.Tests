// Fixture for "QRO Query Order After Write" (68534): ordered by a non-key column with ties.
query 68535 "QRO By Amount"
{
    QueryType = Normal;
    OrderBy = ascending(Amount);

    elements
    {
        dataitem(Entry; "QRO Entry")
        {
            column(EntryNo; "Entry No.") { }
            column(Amount; Amount) { }
        }
    }
}
