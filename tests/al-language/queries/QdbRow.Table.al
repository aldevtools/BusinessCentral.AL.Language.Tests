// Fixture for TestQueryDataItemTableFilterDatabaseConst.al: one row per Kind value.
table 69980 "QDB Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Kind; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
