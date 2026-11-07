// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtablefilter-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-columnfilter-property
// Scope: in-scope
// Fixtures used: none; objects for the writer VQ tests in TestQueryDataItemTableFilter.al (codeunit 60503)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a query DataItemTableFilter and ColumnFilter that name an enum member with the qualified form "Enum"::Member, inside filter(...) and
// const(...), with an OR of two members, with a quoted member name, and on a table field that has the same name as its enum type.
// BC versions: 27-29

enum 97120 "LT VQ Q Kind"
{
    Extensible = true;
    value(0; Alpha) { }
    value(1; Beta) { }
    value(2; "Gamma Delta") { }
}

table 97121 "LT VQ Q Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT VQ Q Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 97144 "LT VQ Q Same"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT VQ Q Kind") { }
        field(3; "LT VQ Q Kind"; Enum "LT VQ Q Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 97122 "LT VQ Q Dit Filter"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Row")
        {
            DataItemTableFilter = Kind = filter("LT VQ Q Kind"::Beta);
            column(RowId; Id) { }
            column(Kind; Kind)
            {
                
            }
        }
    }
}

query 97123 "LT VQ Q Dit Const"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Row")
        {
            DataItemTableFilter = Kind = const("LT VQ Q Kind"::Beta);
            column(RowId; Id) { }
            column(Kind; Kind)
            {
                
            }
        }
    }
}

query 97124 "LT VQ Q Dit Or"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Row")
        {
            DataItemTableFilter = Kind = filter("LT VQ Q Kind"::Alpha|"LT VQ Q Kind"::Beta);
            column(RowId; Id) { }
            column(Kind; Kind)
            {
                
            }
        }
    }
}

query 97125 "LT VQ Q Dit Quoted"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Row")
        {
            DataItemTableFilter = Kind = filter("LT VQ Q Kind"::"Gamma Delta");
            column(RowId; Id) { }
            column(Kind; Kind)
            {
                
            }
        }
    }
}

query 97126 "LT VQ Q Dit Same"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Same")
        {
            DataItemTableFilter = "LT VQ Q Kind" = filter("LT VQ Q Kind"::Beta);
            column(RowId; Id) { }
            column(SameCol; "LT VQ Q Kind")
            {
                
            }
        }
    }
}

query 97127 "LT VQ Q Dit SameConst"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Same")
        {
            DataItemTableFilter = "LT VQ Q Kind" = const("LT VQ Q Kind"::Beta);
            column(RowId; Id) { }
            column(SameCol; "LT VQ Q Kind")
            {
                
            }
        }
    }
}

query 97128 "LT VQ Q Col Plain"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Row")
        {
            
            column(RowId; Id) { }
            column(Kind; Kind)
            {
                ColumnFilter = Kind = filter(Beta);
            }
        }
    }
}

query 97129 "LT VQ Q Col PlainConst"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Row")
        {
            
            column(RowId; Id) { }
            column(Kind; Kind)
            {
                ColumnFilter = Kind = const(Beta);
            }
        }
    }
}

query 97130 "LT VQ Q Dit Plain"
{
    QueryType = Normal;
    OrderBy = ascending(RowId);

    elements
    {
        dataitem(Row; "LT VQ Q Row")
        {
            DataItemTableFilter = Kind = filter(Beta);
            column(RowId; Id) { }
            column(Kind; Kind)
            {
                
            }
        }
    }
}
