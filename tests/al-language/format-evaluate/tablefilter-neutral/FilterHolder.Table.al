// local object: the field shape, enum members or page layout/trigger definition is the behavior under test.
table 69004 "FMT Filter Holder"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; Id; Integer) { }
        field(2; "Stored Filter"; TableFilter) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
