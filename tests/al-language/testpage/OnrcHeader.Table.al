// Fixture header table for TestPagePartOnNewRecordCount.al -- the host card's source table,
// whose "No." the part's SubPageLink reads. Deliberately a copy of "TPDL Header"'s shape rather
// than a reuse of it: codeunit 60996's fixtures measure WHETHER OnNewRecord runs, and giving
// their part page a logging side effect would change what those eight tests are measuring.
table 60354 "ONRC Header"
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
