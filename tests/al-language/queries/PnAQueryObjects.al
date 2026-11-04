// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Query (fixture objects for the Query probes)
// Facts: fixture only: table 70123, queries 70124-70126
// BC versions: 29 (27 and 28 by CI)

table 70123 "LT PnA Q Src"
{
    fields
    {
        field(1; Entry; Integer) { }
        field(2; Grp; Code[10]) { }
        field(3; Name; Text[30]) { }
        field(4; Qty; Integer) { }
        field(5; Amt; Decimal) { }
        field(6; Big; BigInteger) { }
        field(7; Dur; Duration) { }
    }
    keys
    {
        key(PK; Entry) { Clustered = true; }
    }
}

query 70124 "LT PnA Q Plain"
{
    QueryType = Normal;
    OrderBy = ascending(Qty);

    elements
    {
        dataitem(S; "LT PnA Q Src")
        {
            column(Entry; Entry) { }
            column(Txt; Name) { }
            column(Qty; Qty) { }
            column(Amt; Amt) { }
            filter(Grp; Grp) { }
        }
    }
}

query 70125 "LT PnA Q Agg"
{
    QueryType = Normal;
    OrderBy = ascending(Grp);

    elements
    {
        dataitem(S; "LT PnA Q Src")
        {
            column(Grp; Grp) { }
            column(Cnt) { Method = Count; }
            column(SumQty; Qty) { Method = Sum; }
            column(AvgQty; Qty) { Method = Average; }
            column(SumAmt; Amt) { Method = Sum; }
            column(AvgAmt; Amt) { Method = Average; }
            column(MinAmt; Amt) { Method = Min; }
            column(MaxAmt; Amt) { Method = Max; }
        }
    }
}

query 70126 "LT PnA Q Agg2"
{
    QueryType = Normal;
    OrderBy = ascending(Grp);

    elements
    {
        dataitem(S; "LT PnA Q Src")
        {
            column(Grp; Grp) { }
            column(SumBig; Big) { Method = Sum; }
            column(AvgBig; Big) { Method = Average; }
            column(SumDur; Dur) { Method = Sum; }
            column(AvgDur; Dur) { Method = Average; }
        }
    }
}

// Writer PW: filter elements before, between and after the columns, column names that differ from the field names (GetFilters order probe).
query 86143 "LT PW Q Mixed"
{
    QueryType = Normal;

    elements
    {
        dataitem(S; "LT PnA Q Src")
        {
            filter(FGrp; Grp) { }
            column(Qty; Qty) { }
            column(Entry; Entry) { }
            filter(FAmt; Amt) { }
            column(Txt; Name) { }
        }
    }
}
