// Fixture for "QRW Query Read After Write Tests" (68530).
table 68530 "QRW Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Amount; Decimal) { }
        field(3; Processed; Boolean) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
