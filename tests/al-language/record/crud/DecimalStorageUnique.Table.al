// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-unique-property
// Scope: in-scope
// Fixtures used: local table with an Integer primary key and a unique Decimal secondary key.
// Probe: collisions after Decimal storage are rejected on BC 27.5, 28.5 and 29.1.
// BC versions: 27, 28, 29
// local object: the probe needs a unique secondary key on a Decimal field.
table 70000 "REC Decimal Unique"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(70000; Id; Integer) { }
        field(1; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(UniqueAmount; Amount) { Unique = true; }
    }
}
