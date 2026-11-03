// Fixture for query/TestQueryJoinFlowFieldGroupBy.al — the joined (non-driving) dataitem of
// a JOIN query, selecting a FlowField column alongside the driving dataitem's aggregated
// (Method = Sum) column.
table 60786 "QJF Ledger"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Item No."; Code[20]) { }
        field(3; "Cost Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("QJF Value Entry"."Cost Amount" where("Ledger Entry No." = field("Entry No.")));
        }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
