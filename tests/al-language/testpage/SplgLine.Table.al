// Fixture for "SPLG Tests" (60232): the rows the SPLG parts show through their SubPageLink.
table 60232 "SPLG Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Header Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }

    keys
    {
        key(PK; "Header Code", "Line No.") { Clustered = true; }
    }
}
