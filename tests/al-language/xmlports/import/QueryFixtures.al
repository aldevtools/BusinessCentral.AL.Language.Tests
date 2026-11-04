// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: own tables of Fixtures.al (73406-73409)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Query fixtures (tag XpT), not test codeunits.
// BC versions: 29 (27 and 28 by CI)

query 73440 "LT XpT Q Items"
{
    QueryType = Normal;
    elements
    {
        dataitem(ItemRow; "LT XpT Item")
        {
            column(ItemNo; Id) { }
            column(ItemName; Name) { }
            column(QtyCol; Qty) { }
            column(AmountCol; Amount) { }
            column(CategoryCol; Category) { }
            column(ActiveCol; Active) { }
        }
    }
}

query 73441 "LT XpT Q Agg Group"
{
    QueryType = Normal;
    elements
    {
        dataitem(ItemRow; "LT XpT Item")
        {
            column(CategoryCol; Category) { }
            column(Cnt) { Method = Count; }
            column(SumQty; Qty) { Method = Sum; }
            column(MinQty; Qty) { Method = Min; }
            column(MaxQty; Qty) { Method = Max; }
            column(AvgAmount; Amount) { Method = Average; }
        }
    }
}

query 73447 "LT XpT Q Agg Total"
{
    QueryType = Normal;
    elements
    {
        dataitem(ItemRow; "LT XpT Item")
        {
            column(Cnt) { Method = Count; }
            column(SumQty; Qty) { Method = Sum; }
            column(MinQty; Qty) { Method = Min; }
            column(MaxQty; Qty) { Method = Max; }
            column(AvgAmount; Amount) { Method = Average; }
        }
    }
}

query 73442 "LT XpT Q Inner"
{
    QueryType = Normal;
    elements
    {
        dataitem(ItemRow; "LT XpT Item")
        {
            column(ItemNo; Id) { }
            column(ItemName; Name) { }
            dataitem(LineRow; "LT XpT Line")
            {
                DataItemLink = ItemId = ItemRow.Id;
                SqlJoinType = InnerJoin;
                column(LineId; Id) { }
                column(Descr; Descr) { }
                column(LineQty; Qty) { }
            }
        }
    }
}

query 73443 "LT XpT Q Left"
{
    QueryType = Normal;
    elements
    {
        dataitem(ItemRow; "LT XpT Item")
        {
            column(ItemNo; Id) { }
            column(ItemName; Name) { }
            dataitem(LineRow; "LT XpT Line")
            {
                DataItemLink = ItemId = ItemRow.Id;
                SqlJoinType = LeftOuterJoin;
                column(LineId; Id) { }
                column(Descr; Descr) { }
                column(LineQty; Qty) { }
            }
        }
    }
}

query 73444 "LT XpT Q Top Order"
{
    QueryType = Normal;
    TopNumberOfRows = 2;
    OrderBy = descending(QtyCol);
    elements
    {
        dataitem(ItemRow; "LT XpT Item")
        {
            column(ItemNo; Id) { }
            column(QtyCol; Qty) { }
        }
    }
}

query 73445 "LT XpT Q ColFilter"
{
    QueryType = Normal;
    elements
    {
        dataitem(ItemRow; "LT XpT Item")
        {
            DataItemTableFilter = Active = const(true), Qty = filter(>= 20);
            column(ItemNo; Id) { }
            column(QtyCol; Qty) { }
        }
    }
}

query 73446 "LT XpT Q Count Filter"
{
    QueryType = Normal;
    elements
    {
        dataitem(ItemRow; "LT XpT Item")
        {
            filter(QtyFilter; Qty) { }
            column(Cnt) { Method = Count; }
        }
    }
}
