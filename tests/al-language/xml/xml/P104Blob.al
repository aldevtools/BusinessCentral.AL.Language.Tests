// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table LT P104 Blob where an OutStream is written
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: fixture table for the WriteTo(OutStream) probes of the P104 codeunits
// BC versions: 29 (27 and 28 by CI)

table 71800 "LT P104 Blob"
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
