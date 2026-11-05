// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordid/recordid-data-type
// Scope: in-scope
// Fixtures used: none (tables used by R7003RecordIdFormat9.al, codeunit 95688)
// Probe: al-runner issue 7003. Namespaced tables whose names have no space (letters and digits, an underscore, a hyphen, a dot, a slash) and
// one whose name has spaces, for Format(RecordId, 0, 9).
// BC versions: 29 (27 and 28 by CI)

namespace LT.R7003.Data;

table 95680 "R7003Row"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95681 "R7003_Under"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95682 "R7003-Hyphen"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95683 "R7003.Dot"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95684 "R7003/Slash"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 95689 "R7003 Ns Words"
{
    DataClassification = SystemMetadata;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
