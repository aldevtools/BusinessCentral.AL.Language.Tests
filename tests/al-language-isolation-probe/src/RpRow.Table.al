namespace ALLanguage.IsolationProbe;

// The database observable of the runner-trigger probes (ADR-066 of al-runtime-rs, probes P4,
// P6 and P7). Only the codeunits 61330..61346 of this app touch it. Keys start with the tag of
// the runner that wrote them (C = 61330, F = 61331, D = no runner of this probe, for example
// the discovery runner 130452), so the two runs of one nightly never answer for each other.
table 61330 "LT RP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[50]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}
