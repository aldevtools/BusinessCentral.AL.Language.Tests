// Fixture for "QRW Query Read After Write Tests" (68530): one dataitem, with an OrderBy.
query 68530 "QRW Entries Ordered"
{
    QueryType = Normal;
    OrderBy = ascending(EntryNo);

    elements
    {
        dataitem(Entry; "QRW Entry")
        {
            column(EntryNo; "Entry No.") { }
            column(Amount; Amount) { }
        }
    }
}
