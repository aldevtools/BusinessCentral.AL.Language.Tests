// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51703 "Draft Probe Card Header"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Category; Code[20]) { }
    }
    keys { key(PK; Code) { Clustered = true; } }

    trigger OnInsert()
    begin
        if Code = '' then
            Code := 'NEW';
    end;
}
