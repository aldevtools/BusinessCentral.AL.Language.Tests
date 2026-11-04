// Fixture for "QRW Query Read After Write" (68530): no OrderBy, and the primary key is not a
// column of the query.
query 68532 "QRW Amounts"
{
    QueryType = Normal;

    elements
    {
        dataitem(Entry; "QRW Entry")
        {
            column(Amount; Amount) { }
        }
    }
}
