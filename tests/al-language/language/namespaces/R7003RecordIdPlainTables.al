// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordid/recordid-data-type
// Scope: in-scope
// Fixtures used: none (tables used by R7003RecordIdFormat9.al, codeunit 95688)
// Probe: al-runner issue 7003. Tables outside any namespace: a one-word name, a name with spaces and a name with a hyphen, for
// Format(RecordId, 0, 9).
// BC versions: 29 (27 and 28 by CI)

table 95685 "R7003Plain"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95686 "R7003 Plain Words"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95687 "R7003-PlainHyphen"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
