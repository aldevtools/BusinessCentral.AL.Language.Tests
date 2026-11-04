// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-filters
// Scope: in-scope
// Fixtures for the QZ_* tests in codeunit "LT CG Query Leads" (CgQueryLeads.al): tables 87683 and 87684, queries 87685-87687.
// Facts: a query filter() element over a FlowField of the data item (Boolean exist, Integer count, Decimal sum) with a ColumnFilter,
//   and without a ColumnFilter but filtered at run time with SetFilter / SetRange; which header rows the query reads.

table 87683 "LT QZ Q Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; HasLines; Boolean) { FieldClass = FlowField; CalcFormula = exist("LT QZ Q Line" where("Header No." = field("No."))); }
        field(3; LineCount; Integer) { FieldClass = FlowField; CalcFormula = count("LT QZ Q Line" where("Header No." = field("No."))); }
        field(4; LineSum; Decimal) { FieldClass = FlowField; CalcFormula = sum("LT QZ Q Line".Amount where("Header No." = field("No."))); }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

table 87684 "LT QZ Q Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Amount; Decimal) { }
    }

    keys { key(PK; "Header No.", "Line No.") { Clustered = true; } }
}

query 87685 "LT QZ Q No Lines"
{
    QueryType = Normal;

    elements
    {
        dataitem(H; "LT QZ Q Header")
        {
            column(No; "No.") { }
            filter(HasLines; HasLines) { ColumnFilter = HasLines = const(false); }
        }
    }
}

query 87686 "LT QZ Q Many Lines"
{
    QueryType = Normal;

    elements
    {
        dataitem(H; "LT QZ Q Header")
        {
            column(No; "No.") { }
            filter(LineCount; LineCount) { ColumnFilter = LineCount = filter(> 1); }
            filter(LineSum; LineSum) { ColumnFilter = LineSum = filter(<> 0); }
        }
    }
}

query 87687 "LT QZ Q Open Filter"
{
    QueryType = Normal;

    elements
    {
        dataitem(H; "LT QZ Q Header")
        {
            column(No; "No.") { }
            filter(HasLines; HasLines) { }
            filter(LineSum; LineSum) { }
        }
    }
}
