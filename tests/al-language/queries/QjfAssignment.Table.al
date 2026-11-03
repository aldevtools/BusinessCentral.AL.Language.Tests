// Fixture for query/TestQueryJoinFlowFieldGroupBy.al — the driving dataitem of a JOIN query
// that also has an aggregated (Method = Sum) column.
table 60785 "QJF Assignment"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Project No."; Code[20]) { }
        field(3; "Ledger Entry No."; Integer) { }
        field(4; Quantity; Decimal) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
