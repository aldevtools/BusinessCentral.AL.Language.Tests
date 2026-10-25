namespace ALLanguage.IsolationProbe;

// The database observable for "LT DJ Isol Commit" (61308). Value holds a GUID made in the
// test that wrote the row, so a row left by an earlier run cannot pass for this run's row.
table 61302 "LT DJ Isol Commit Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[20]) { }
        field(2; Value; Guid) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}
