// Scope: in-scope
// Fixtures for "LT DD Stream Leads" (codeunit 85841): a table with a Blob and a Media field.
// Topic: corpus issue 671 (odd AL behavior leads, part F), items 61 to 75.
// BC versions: 27.5, 28.5, 29.0

table 85840 "LT DD Blob Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Pic; Media) { }
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
