// Fixture for TestQueryDataItemTableFilterDatabaseConst.al: the shape of Base Application's query
// "Qty. Reserved From Item Ledger" — one Sum column, a filter() element, and an inner-joined second
// dataitem over the same table — with a Database:: const in the second dataitem's table filter.
query 69981 "QDB Scalar Join"
{
    QueryType = Normal;

    elements
    {
        dataitem(ForSide; "QDB Entry")
        {
            DataItemTableFilter = Positive = const(false);

            filter(ItemNo; "Item No.")
            {
            }
            column(TotalQuantity; Quantity)
            {
                Method = Sum;
            }
            dataitem(FromSide; "QDB Entry")
            {
                DataItemLink = "Entry No." = ForSide."Entry No.";
                SqlJoinType = InnerJoin;
                DataItemTableFilter = Positive = const(true), "Source Type" = const(Database::"QDB Row");
            }
        }
    }
}
