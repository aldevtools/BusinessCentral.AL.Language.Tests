// Migrated from AL Runner tests/runner-extras/query-join (src/Tables.al).
table 60861 "QJ Customer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Name"; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
