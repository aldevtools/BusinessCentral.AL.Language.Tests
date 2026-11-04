// Fixture for codeunit 69140 "PVD Provider Tests": the rows the Provider-linked part shows, keyed
// to a line by "Line Ref".
table 69142 "PVD Detail"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Line Ref"; Integer) { }
        field(3; Info; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
