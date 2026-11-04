// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope
// Fixtures used: (none — this table exists only to give the card page below a SourceTable)
//
// Backing table for the Boolean-control spelling suite. Two Boolean fields so the true and the
// false spelling can be read off one row without either write touching the other, and Marker
// gives the row a non-Boolean field so a test can prove the page is positioned before asserting
// on a value whose two spellings are both short words.

table 60664 "TPB Bool Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Marker; Text[30]) { }
        field(3; TrueFlag; Boolean) { }
        field(4; FalseFlag; Boolean) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}
