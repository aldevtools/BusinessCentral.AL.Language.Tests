// @expect AL0169 | The option value 'NoLocks' is not valid. Check the enum definition for valid values.
// NoLocks is a TransactionType value, not a ReadState value (the values are ReadUncommitted, ReadCommitted, ReadShared and the default).
table 50000 "MNC TJ Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50001 "MNC TJ Query"
{
    QueryType = Normal;
    ReadState = NoLocks;

    elements
    {
        dataitem(T; "MNC TJ Table")
        {
            column(Id; Id) { }
        }
    }
}
