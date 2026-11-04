// Fixture for TestQueryDataItemTableFilter.al. Two fields and nothing else: the Option is what
// the query's DataItemTableFilter restricts, and Code is the only projected column, so the
// filtered field is deliberately NOT part of the result set.
table 60497 "QDTF Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { DataClassification = CustomerContent; }
        field(2; Status; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = Open,Closed,Held;
        }
        field(3; Amount; Decimal) { DataClassification = CustomerContent; }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}
