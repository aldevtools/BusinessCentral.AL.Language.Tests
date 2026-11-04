// Fixture for TestQueryDataItemTableFilterDatabaseConst.al: a demand row (Positive = false) and a
// supply row (Positive = true) share an Entry No., like Base Application's Reservation Entry.
table 69981 "QDB Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Positive; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Item No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(4; Quantity; Decimal)
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Source Type"; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.", Positive)
        {
            Clustered = true;
        }
    }
}
