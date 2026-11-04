// Fixture table for TestPageTemporalSetValue_Tests: one row carrying a Date, a DateTime and a
// Time, so a TestPage control write can be read back as a typed value rather than as text.
table 60667 "ALT Temporal Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; "The Date"; Date) { DataClassification = CustomerContent; }
        field(3; "The DateTime"; DateTime) { DataClassification = CustomerContent; }
        field(4; "The Time"; Time) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
