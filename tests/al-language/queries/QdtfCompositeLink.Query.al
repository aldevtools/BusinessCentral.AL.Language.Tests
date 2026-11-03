// A DataItemLink naming TWO field equalities. Both halves must constrain the join: the parent
// key is ("No.", "Variant Code"), so honouring only the first would match a line to every
// header sharing its "No.".
query 60502 "QDTF Composite Link"
{
    QueryType = Normal;
    OrderBy = ascending(HdrDescr);

    elements
    {
        dataitem(Hdr; "QDTF Header")
        {
            column(HdrDescr; Descr) { }

            dataitem(Ln; "QDTF Line")
            {
                DataItemLink = "Header No." = Hdr."No.", "Variant Code" = Hdr."Variant Code";
                SqlJoinType = InnerJoin;

                column(LineTag; Tag) { }
            }
        }
    }
}
