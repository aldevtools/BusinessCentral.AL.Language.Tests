// Fixture for query/TestQueryFlowFieldColumn.al — a query column backed by a FlowField.
table 60974 "QFF Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
        field(3; Amount; Decimal) { }
        // Used by "QFF Header"."Dated Amount", whose CalcFormula narrows the sum with the
        // header's "Date Filter" flow filter.
        field(4; "Posting Date"; Date) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
