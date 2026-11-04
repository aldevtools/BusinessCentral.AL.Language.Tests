// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Test RunModal LookupPage Row (60995)
//
// Backing table for the static Page.RunModal(0, Record) / LookupPageId suite. Declares
// LookupPageId so a record of this type can resolve its own lookup page when the caller
// passes id 0.

table 60995 "Test RunModal LookupPage Row"
{
    DataClassification = CustomerContent;
    LookupPageId = "Test RunModal LookupPage List";

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
