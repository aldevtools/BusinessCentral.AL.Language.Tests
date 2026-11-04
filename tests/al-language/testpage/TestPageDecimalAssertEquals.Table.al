// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
// Scope: in-scope
// Fixtures used: (none -- backing table for the Decimal AssertEquals suite)

table 69931 "TPD Dec Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Amount; Decimal) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}
