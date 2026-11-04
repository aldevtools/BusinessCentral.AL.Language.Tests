// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: PXT Row (60654), PXT Log (60655)
//
// A pageextension may declare the page triggers its base page does not — OnOpenPage,
// OnAfterGetRecord and the other seven the compiler accepts there. Nothing in the corpus
// pinned that they RUN, so this suite does.
//
// Two tables rather than one: PXT List displays PXT Row, so a trigger writing to PXT Row
// would be writing to the rowset it is being raised over. PXT Log is written instead, one
// row per raise, carrying which trigger raised and what Rec held at the time.

table 60654 "PXT Row"
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

table 60655 "PXT Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Trigger Name"; Text[50]) { }
        field(3; "Row No."; Code[20]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
