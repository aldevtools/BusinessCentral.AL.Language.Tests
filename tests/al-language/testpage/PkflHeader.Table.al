// Fixture host table for TestPageSubpagePartFieldLink.al: the header side of a
// card-with-lines shape whose parts link by field(...) onto line fields that are, and are
// not, part of the line table's primary key.
table 60641 "PKFL Header"
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
