// Fixture for "PCN Tests" (60535): the rows "PCN Lines Part" (60534) shows under one
// "PCN Header" (60533). Real (non-temporary), so whether a row the handler typed survives the
// close is answered by reading this table after the modal has gone.
table 60534 "PCN Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Reference; Text[30]) { }
    }

    keys
    {
        key(PK; "Header Code", "Line No.") { Clustered = true; }
    }
}
