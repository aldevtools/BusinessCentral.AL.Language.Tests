// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtablefilter-property
// Scope: in-scope
// Fixtures used: none; objects for the writer SQ tests in TestQueryDataItemTableFilter.al (codeunit 60503)
// Facts: a query DataItemTableFilter (and a ColumnFilter) with an empty filter term filter('') on a Code and a Text field, next to const('')
// and filter('A'|''): which rows the query returns.
// BC versions: 27-29

table 89589 "LT SQ Qf Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Code"; Code[10]) { }
        field(3; Txt; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 89590 "LT SQ Qf Code Filter Empty"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT SQ Qf Row")
        {
            DataItemTableFilter = "Code" = filter('');
            column(RowId; Id) { }
        }
    }
}

query 89591 "LT SQ Qf Txt Filter Empty"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT SQ Qf Row")
        {
            DataItemTableFilter = Txt = filter('');
            column(RowId; Id) { }
        }
    }
}

query 89592 "LT SQ Qf Code Const Empty"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT SQ Qf Row")
        {
            DataItemTableFilter = "Code" = const('');
            column(RowId; Id) { }
        }
    }
}

query 89593 "LT SQ Qf Code Filter Or"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT SQ Qf Row")
        {
            DataItemTableFilter = "Code" = filter('A'|'');
            column(RowId; Id) { }
        }
    }
}

query 89594 "LT SQ Qf Column Filter Empty"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT SQ Qf Row")
        {
            column(RowId; Id) { }
            column(RowCode; "Code") { ColumnFilter = RowCode = filter(''); }
        }
    }
}
