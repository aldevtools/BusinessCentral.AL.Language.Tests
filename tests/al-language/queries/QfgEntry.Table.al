// Fixture for query/TestQueryFilterElementGroupBy.al.
table 68601 "QFG Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
        field(3; "Posting Date"; Date) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
