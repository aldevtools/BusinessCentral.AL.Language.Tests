// Migrated from AL Runner tests/runner-extras/testpage-subpage-part (TspSrc.al).
table 60849 "TSP Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ReportId; Integer) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; ReportId) { Clustered = true; }
    }
}
