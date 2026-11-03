// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: TXT Row (60428), TXT Log (60429)
//
// A tableextension may declare OnBeforeInsert / OnAfterInsert and the six siblings for
// Modify, Delete and Rename. Nothing in the corpus pinned that they RUN, so this suite does.
//
// Two tables rather than one: a trigger writing to TXT Row would be writing to the very
// record whose write raised it. TXT Log is written instead, one row per raise, in order.

table 60428 "TXT Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Payload; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 60429 "TXT Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Trigger Name"; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
