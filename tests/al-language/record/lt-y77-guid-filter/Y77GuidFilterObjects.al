// Scope: in-scope
// Tables, query and log of the Y77 probes: a Guid value given as the filter argument of Record.SetFilter / SetRange, Query.SetFilter and FieldRef.SetFilter / SetRange. Object ids 94100-94129.

table 94100 "LT Y77 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; G; Guid) { }
        field(3; T; Text[50]) { }
        field(4; C; Code[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

query 94101 "LT Y77 Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "LT Y77 Row")
        {
            column(No; "No.") { }
            column(G; G) { }
            column(T; T) { }
            column(C; C) { }
        }
    }
}
