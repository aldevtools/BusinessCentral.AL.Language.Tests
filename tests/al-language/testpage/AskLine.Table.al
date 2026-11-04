// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Line (60916)
//
// Line table for the AutoSplitKey / action-invoke suite.
//
// The shape is load-bearing: a two-field primary key whose LAST field is an Integer is
// precisely what AutoSplitKey acts on, and "Line No." is deliberately NOT auto-assigned by
// anything in this table — no OnInsert, no number series. Whatever value it ends up with
// came from the page property, which is the whole claim.

table 60916 "ASK Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.", "Line No.") { Clustered = true; }
    }
}
