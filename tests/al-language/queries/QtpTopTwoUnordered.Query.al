// Fixture for "QTP Query Top Property" (68650): TopNumberOfRows with no OrderBy.
query 68651 "QTP Top Two Unordered"
{
    QueryType = Normal;
    TopNumberOfRows = 2;

    elements
    {
        dataitem(Entry; "QRO Entry")
        {
            column(EntryNo; "Entry No.") { }
        }
    }
}
