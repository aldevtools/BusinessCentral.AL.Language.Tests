// Migrated from AL Runner tests/runner-extras/testpage-subpage-part (TspSrc.al).
table 60850 "TSP Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ReportId; Integer) { }
        field(2; LineNo; Integer) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; ReportId, LineNo) { Clustered = true; }
    }
}
