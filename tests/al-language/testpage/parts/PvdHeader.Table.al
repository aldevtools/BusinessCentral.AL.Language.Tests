// Fixture for codeunit 69140 "PVD Provider Tests". "Line No." exists on the host on purpose: it is
// the decoy a FIELD link would read if it were resolved against the host instead of the Provider.
table 69140 "PVD Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
