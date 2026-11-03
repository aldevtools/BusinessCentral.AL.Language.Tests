// Fixture for "QRO Query Order After Write" (68534): ordered against the primary key.
query 68534 "QRO Descending"
{
    QueryType = Normal;
    OrderBy = descending(EntryNo);

    elements
    {
        dataitem(Entry; "QRO Entry")
        {
            column(EntryNo; "Entry No.") { }
            column(Amount; Amount) { }
        }
    }
}
