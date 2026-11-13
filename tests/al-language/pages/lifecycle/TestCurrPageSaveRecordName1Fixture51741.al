// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51741 "Probe Line"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; ParentId; Code[20]) { }
        field(2; LineNo; Integer) { }
        field(3; ItemNo; Code[20]) { }
    }
    keys { key(PK; ParentId, LineNo) { Clustered = true; } }
}
