namespace ALLanguage.IsolationProbe;

// The database observable for "LT DJ Isol Writer" (61306) and "LT DJ Isol Reader" (61307):
// the writer inserts rows, the reader (the next test codeunit) looks for them. Only those
// two codeunits touch the table.
table 61301 "LT DJ Isol Cross Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[20]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}
