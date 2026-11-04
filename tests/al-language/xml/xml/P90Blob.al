// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmltext/xmltext-data-type
// Scope: in-scope
// Fixtures used: none
// Probe: written against BC 29 (local service tier). Own blob table for the WriteTo(OutStream) probes of the P90 codeunits.
// Facts: fixture table
// BC versions: 29 (27 and 28 by CI)

table 70729 "LT P90 Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer)
        {
        }
        field(2; Data; Blob)
        {
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
