// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Streams (fixture table for the Streams and Blob probes)
// Facts: fixture only: table with a Blob field
// BC versions: 29 (27 and 28 by CI)

table 70087 "LT PnA Blob"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Data; Blob) { }
        field(3; Note; Text[30]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}
