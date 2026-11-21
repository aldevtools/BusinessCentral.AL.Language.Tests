// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51712 "Next Refresh Header"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Reference; Text[40]) { }
        field(3; Result; Text[40]) { }
        field(4; Active; Boolean) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
