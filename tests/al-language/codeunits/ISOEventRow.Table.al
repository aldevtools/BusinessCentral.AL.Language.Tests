// Fixture for "Test Isolated Event Sub Error" (67103): the rows the isolated-event
// subscribers write, so the test can ask which of them survived.
table 67100 "ISO Event Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Source; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
