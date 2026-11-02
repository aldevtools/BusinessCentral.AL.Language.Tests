// @expect AL0322 | Array access is not valid for client expressions. Client expressions can only use simple data types and field references.
// The Visible property of a page FIELD is a client expression: an array element does not compile there, while a group, cuegroup, fixed, grid,
// repeater, part or action Visible takes it (al-runner issue 6675, writer Y65; a procedure call is must-not-compile 2000).
table 50000 "MNC Field Visible Array"
{
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; CueA; Integer) { }
    }
}

page 50000 "MNC Field Visible Array"
{
    PageType = CardPart;
    SourceTable = "MNC Field Visible Array";

    layout
    {
        area(Content)
        {
            cuegroup(Cues)
            {
                field(CueA; Rec.CueA)
                {
                    ApplicationArea = All;
                    Visible = ShowArr[1];
                }
            }
        }
    }

    var
        ShowArr: array[2] of Boolean;
}
