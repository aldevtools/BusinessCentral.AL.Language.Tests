// Fixture for query/TestQueryFlowFieldColumn.al — a query column backed by a FlowField.
table 60975 "QFF Header"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Total Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("QFF Line".Amount where("Header No." = field("No.")));
        }
        // A flow filter is a parameter to this table's FlowField formulas, not stored data.
        field(3; "Date Filter"; Date) { FieldClass = FlowFilter; }
        // Same aggregate as "Total Amount", narrowed by the "Date Filter" flow filter — the
        // FieldClass.FlowFilter where-condition shape.
        field(4; "Dated Amount"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("QFF Line".Amount where("Header No." = field("No."),
                                                     "Posting Date" = field("Date Filter")));
        }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}
