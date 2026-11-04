// Fixture for "SPLG Tests" (60232): the host row a part's SubPageLink reads its values from.
table 60231 "SPLG Header"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Sel Line No."; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
