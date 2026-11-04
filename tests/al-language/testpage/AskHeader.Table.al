// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Header (60915)
//
// Header table for the AutoSplitKey / action-invoke suite. Its only job is to be the
// parent a SubPageLink points at, so the lines under test live in a filtered subpage
// exactly like a document's lines do.

table 60915 "ASK Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
