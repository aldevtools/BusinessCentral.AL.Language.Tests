// Fixture for "QTP Query Top Property" (68650): TopNumberOfRows on two dataitems.
query 68652 "QTP Joined Top Two"
{
    QueryType = Normal;
    OrderBy = descending(EntryNo);
    TopNumberOfRows = 2;

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
