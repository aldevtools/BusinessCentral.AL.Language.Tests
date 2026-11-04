// Fixture for codeunit 69140 "PVD Provider Tests": the rows the Provider part shows.
table 69141 "PVD Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }
}
