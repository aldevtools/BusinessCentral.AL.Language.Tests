// @expect AL0322 | Procedure calls is not valid for client expressions. Client expressions can only use simple data types and field references.
// The Visible property of a page FIELD is a client expression: a method call on Rec (Rec.IsEmpty()) does not compile there, while a cuegroup
// Visible takes it (pages/lt-y65-cue-visible/Y65CueVisible.al GrpEmpty; al-runner issue 6675, writer Y65).
table 50000 "MNC Field Visible Method"
{
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; CueA; Integer) { }
    }
}

page 50000 "MNC Field Visible Method"
{
    PageType = CardPart;
    SourceTable = "MNC Field Visible Method";

    layout
    {
        area(Content)
        {
            cuegroup(Cues)
            {
                field(CueA; Rec.CueA)
                {
                    ApplicationArea = All;
                    Visible = not Rec.IsEmpty();
                }
            }
        }
    }
}
