// Fixture for "PCN Tests" (60535): the header a modally-run card shows. Real (non-temporary),
// so a change the card makes to it can be read back after the modal round trip has finished.
table 60533 "PCN Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
