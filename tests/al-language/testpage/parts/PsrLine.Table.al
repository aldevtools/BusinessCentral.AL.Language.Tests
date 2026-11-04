// Fixture for "PSR Page Saved Row Tests" (60412): the lines "PSR Lines Part" (60413) shows under
// one "PSR Header" (60412).
table 60413 "PSR Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header Code"; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; "Saved Field"; Text[30]) { }
        field(4; "Later Field"; Text[30]) { }
    }

    keys
    {
        key(PK; "Header Code", "Line No.") { Clustered = true; }
    }
}
