// Fixture for "QRW Query Read After Write Tests" (68530): the same dataitem, with no OrderBy.
query 68531 "QRW Entries Unordered"
{
    QueryType = Normal;

    elements
    {
        dataitem(Entry; "QRW Entry")
        {
            column(EntryNo; "Entry No.") { }
            column(Amount; Amount) { }
        }
    }
}
