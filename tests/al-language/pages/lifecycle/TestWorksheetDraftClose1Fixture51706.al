// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51706 "Draft Probe Header"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Batch; Code[10]) { }
        field(2; "Line No."; Integer) { }
        field(3; Item; Code[20]) { }
        field(4; Quantity; Integer) { }
    }
    keys { key(PK; Batch, "Line No.") { Clustered = true; } }
}
