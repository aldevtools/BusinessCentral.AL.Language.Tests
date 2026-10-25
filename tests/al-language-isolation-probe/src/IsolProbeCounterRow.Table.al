namespace ALLanguage.IsolationProbe;

// The AutoIncrement and SystemRowVersion observable for "LT DJ Isol After Rollback" (61309).
// Only that codeunit touches the table.
table 61303 "LT DJ Isol Counter Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
