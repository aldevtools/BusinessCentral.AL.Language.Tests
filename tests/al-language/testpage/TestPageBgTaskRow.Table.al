// Fixture table for TestPageBgTask_Tests.al.

table 60790 "Test Page BgTask Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Handle; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
