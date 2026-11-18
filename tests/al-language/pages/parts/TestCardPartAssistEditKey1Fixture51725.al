// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51725 "Linked Part Detail Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Before Assist"; Code[20]) { }
        field(3; Marker; Integer) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
