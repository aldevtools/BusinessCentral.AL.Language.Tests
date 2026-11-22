// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51742 "Probe Shadow"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; LineNo; Integer) { }
        field(2; Value; Code[20]) { }
    }
    keys { key(PK; LineNo) { Clustered = true; } }
}
