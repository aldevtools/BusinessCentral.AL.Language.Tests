// Fixture for "QRO Query Order After Write" (68534).
table 68534 "QRO Entry"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Amount; Decimal) { }
        field(3; Processed; Boolean) { }
        field(4; "Group Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
