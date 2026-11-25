// Fixture for TableRelationNamespaceMetadata.al: the relation target lives in its own namespace of this app.
namespace ALLanguage.Coverage.FcRelTarget;

table 77808 "FC Rel Group"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
