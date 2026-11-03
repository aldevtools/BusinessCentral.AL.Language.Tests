// Fixture for "QTP Query Top Property" (68650): TopNumberOfRows set on the object.
query 68650 "QTP Top Two"
{
    QueryType = Normal;
    OrderBy = descending(EntryNo);
    TopNumberOfRows = 2;

    elements
    {
        dataitem(Entry; "QRO Entry")
        {
            column(EntryNo; "Entry No.") { }
        }
    }
}
