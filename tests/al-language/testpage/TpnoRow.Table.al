// Fixture table behind "TPNO Row Card" (67040) — see TestPageNeverOpened_Tests.al.
table 67040 "TPNO Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
