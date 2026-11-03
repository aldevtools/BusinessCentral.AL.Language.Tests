// A multi-dataitem JOIN query where the driving dataitem has an aggregated (Method = Sum)
// column AND the joined dataitem selects a FlowField column. The FlowField is calculated per
// joined row (BC's own SQL OuterApply sub-query, independent of any application-level JOIN),
// and then takes part in the query's own implicit GROUP BY over every non-aggregated column
// like any other column.
query 60788 "QJF Valuation"
{
    QueryType = Normal;
    OrderBy = ascending(ItemNo);

    elements
    {
        dataitem(Assignment; "QJF Assignment")
        {
            column(ProjectNo; "Project No.") { }
            column(LedgerEntryNo; "Ledger Entry No.") { }
            column(AssignedQuantity; Quantity) { Method = Sum; }

            dataitem(Ledger; "QJF Ledger")
            {
                DataItemLink = "Entry No." = Assignment."Ledger Entry No.";
                SqlJoinType = InnerJoin;
                column(ItemNo; "Item No.") { }
                column(CostAmount; "Cost Amount") { }
            }
        }
    }
}
