namespace ALLanguage.IsolationProbe;

// The database observable of writer SD's fixtures (AL Runner issues 5607 and 5609): each fixture
// pair uses its own key prefix. Only the "LT SD ..." codeunits of this app touch the table.
table 61304 "LT SD Isol Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[30]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}
