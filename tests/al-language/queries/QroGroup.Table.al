// Fixture for "QRO Query Order After Write" (68534): the parent of a joined query.
table 68535 "QRO Group"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}
