// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51772 "Refresh Probe Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Batch; Code[10]) { }
        field(3; VisibleKind; Boolean) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
