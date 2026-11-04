// Fixture for TestPageModalQueryClose_Tests.al.
/// <summary>
/// The row the persist arm writes through. Separate from "MQC Trace" so the write and the
/// trigger-sequence observation cannot be confused for one another.
/// </summary>
table 60272 "MQC Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Set ID"; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
