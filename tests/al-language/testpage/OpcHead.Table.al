// Fixture for "Opc Close Part Flush Tests" (60438): the host row "Opc Close Card" (60423) is
// opened on. A real (non-temporary) table, so the test can seed a row for OpenEdit to land on
// -- the part is where the temporary-source question lives, not the host.
table 60421 "Opc Head"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Descr"; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
