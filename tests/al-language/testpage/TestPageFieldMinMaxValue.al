// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minvalue-property
// Scope: in-scope
// Fixtures used: Test Page MinMax Row (60908)
//
// Backing table for the TestPage MinValue/MaxValue suite. One bounded Decimal field and one
// bounded Integer field, each MinValue = 0, so both the below-min and above-max sides can be
// exercised for both numeric shapes with a single seeded row.

table 60908 "Test Page MinMax Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Completion; Decimal)
        {
            MinValue = 0;
            MaxValue = 100;
        }
        field(3; Score; Integer)
        {
            MinValue = 0;
            MaxValue = 10;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
