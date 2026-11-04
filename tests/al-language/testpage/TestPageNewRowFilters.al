// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-new-method
// Scope: in-scope
// Fixtures used: Test Page New Row Flt Parent (60707), Test Page New Row Flt Child (60708)
//
// Parent side of the filter-carry-onto-new-row suite.

table 60707 "Test Page New Row Flt Parent"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Label; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
