// Fixture for query/TestQueryJoinFlowFieldGroupBy.al — the source table of "QJF Ledger"."Cost
// Amount" FlowField.
table 60787 "QJF Value Entry"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Ledger Entry No."; Integer) { }
        field(3; "Cost Amount"; Decimal) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
