// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: none
// Facts: table used by the FieldRef.Value conversion probes (FVC); one field of each source type.

table 75980 "FVC Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; IntF; Integer) { }
        field(3; BigF; BigInteger) { }
        field(4; DtF; DateTime) { }
        field(5; DateF; Date) { }
        field(6; TimeF; Time) { }
        field(7; DurF; Duration) { }
        field(8; DecF; Decimal) { }
        field(9; BoolF; Boolean) { }
        field(10; CodeF; Code[20]) { }
        field(11; TextF; Text[50]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
