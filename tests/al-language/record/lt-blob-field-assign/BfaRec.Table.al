table 95950 "LT BFA Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Integer) { DataClassification = SystemMetadata; }
        field(2; Body; Blob) { DataClassification = SystemMetadata; }
        field(3; Other; Blob) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}
