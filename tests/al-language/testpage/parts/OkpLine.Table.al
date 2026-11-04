// Fixture for "OKP Ok Part Row Tests" (60760): the lines "OKP Lines Part" (60761) shows under
// one "OKP Header" (60760). A real (non-temporary) table, so a row the part writes can be read
// back from the test after the page has closed.
table 60761 "OKP Line"
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
