// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoincrement-property
// Scope: in-scope (Cloud-compatible)
//
// The one row the page-save data-layer suite drives. Two fields: an AutoIncrement key, so the
// platform (not the test, and not the page) is the only thing that can give a saved row a
// positive "Entry No.", and one Text field a page control can edit. Nothing else, so nothing
// about the table can absorb or explain a difference the suite measures.
//
// The system fields (SystemCreatedAt/By, SystemModifiedAt/By) are not declared here -- every
// table gets them -- and they are the other half of what this suite reads.

table 60560 "ALT Page Save Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; Description; Text[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
