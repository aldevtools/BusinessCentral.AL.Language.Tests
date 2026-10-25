// @expect AL0264 | An application object of type 'Query' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'Query' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two queries with the same id.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50001 "MNC SH Query A"
{
    elements
    {
        dataitem(B; "MNC SH Base Table")
        {
            column(Id; Id) { }
        }
    }
}

query 50001 "MNC SH Query B"
{
    elements
    {
        dataitem(B; "MNC SH Base Table")
        {
            column(Id; Id) { }
        }
    }
}
