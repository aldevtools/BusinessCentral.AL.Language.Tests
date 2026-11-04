// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained namespace LT.P69.Data, table 71165, report 71166, query 71167, codeunits 71168 (log) and 71169
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): a dataitem whose table name is namespace qualified
// Facts: a table in a namespace used by a report dataitem, a query dataitem and a Record variable; with using and with the fully qualified name
// BC versions: 29 (27 and 28 by CI)

namespace LT.P69.Data;

table 71165 "LT P69 Ns Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}
