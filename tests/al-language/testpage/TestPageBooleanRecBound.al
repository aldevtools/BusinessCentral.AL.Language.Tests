// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: (none — this table exists only to give the card page below a SourceTable)
//
// Backing table for the TestPage Rec-bound Boolean SetValue suite. Flag is the control under
// test; Value gives the page an unrelated field so a test can prove ONLY the boolean control's
// own field was touched.

table 60994 "TP Boolean Rec Bound Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Value; Text[30]) { }
        field(3; Flag; Boolean) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}
