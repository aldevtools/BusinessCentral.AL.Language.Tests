// @expect AL0208 | The expression must be of Boolean type. Use a comparison or boolean expression.
// The Visible property of a cuegroup takes any Boolean expression (a page variable, Rec fields, a procedure call, a method call such as
// Rec.IsEmpty(): pages/lt-y65-cue-visible/Y65CueVisible.al), but not an Integer (al-runner issue 6675, writer Y65).
table 50000 "MNC Cue Visible Int"
{
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; CueA; Integer) { }
    }
}

page 50000 "MNC Cue Visible Int"
{
    PageType = CardPart;
    SourceTable = "MNC Cue Visible Int";

    layout
    {
        area(Content)
        {
            cuegroup(Cues)
            {
                Visible = 5;
                field(CueA; Rec.CueA) { ApplicationArea = All; }
            }
        }
    }
}
