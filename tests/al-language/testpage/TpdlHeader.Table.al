// Fixture header table for TestPagePartDraftLineLink.al. The host card's source table; its
// "No." is what the part's SubPageLink reads.
table 60996 "TPDL Header"
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
