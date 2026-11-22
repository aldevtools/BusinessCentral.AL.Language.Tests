// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldcaption-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

using System.Reflection;

// local object: this object defines the page, record, or trigger behavior that the test exercises.
table 51880 "Probe Literal Caption Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Payload; Text[20]) { CaptionClass = 'PRB503,Literal'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
