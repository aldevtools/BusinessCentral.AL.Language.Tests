// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-editable-method
// Scope: in-scope
// Fixtures used: Test Page Editable Row (60685)
//
// Backing table for the TestPage editable/enabled suite.

table 60685 "Test Page Editable Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Note; Text[50]) { }
        // Stands in for any "this row is owned by someone else" discriminator — a scope
        // enum, an ownership flag, a posted/open state. The page turns it into editability.
        field(4; Locked; Boolean) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
