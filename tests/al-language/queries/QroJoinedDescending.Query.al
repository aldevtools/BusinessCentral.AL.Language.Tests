// Fixture for "QRO Query Order After Write" (68534): two dataitems, ordered against the key.
query 68536 "QRO Joined Descending"
{
    QueryType = Normal;
    OrderBy = descending(EntryNo);

    elements
    {
        dataitem(Entry; "QRO Entry")
        {
            column(EntryNo; "Entry No.") { }
            dataitem(Grp; "QRO Group")
            {
                DataItemLink = Code = Entry."Group Code";
                SqlJoinType = InnerJoin;
                column(GroupDescription; Description) { }
            }
        }
    }
}
