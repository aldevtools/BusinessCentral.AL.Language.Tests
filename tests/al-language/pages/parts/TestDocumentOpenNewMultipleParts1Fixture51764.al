// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51764 "Document Repro Line 51764"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; HeaderId; Integer) { }
        field(2; Id; Integer) { }
    }
    keys { key(PK; HeaderId, Id) { Clustered = true; } }
}
