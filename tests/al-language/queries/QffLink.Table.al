// Fixture for query/TestQueryFlowFieldColumn.al — a JOIN whose non-driving side selects a
// FlowField column.
table 60953 "QFF Link"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
