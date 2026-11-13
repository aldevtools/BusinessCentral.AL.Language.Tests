// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51719 "Action Header Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Description; Text[50]) { }
        field(3; "Linked Code"; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Action Link Row".Code where(Id = field(Id)));
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
