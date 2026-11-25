// @expect AL0107 | Syntax error, identifier expected
// To, unquoted after `.`, in a page control's Visible, `Visible = Rec.To > 0;` (al-runner issue 8650).
// Quoted, as "To", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53524 "MNC KP3524"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "To"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"To";
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}

page 53524 "MNC KP3524 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3524";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.To > 0;
                }
            }
            part(Lines; "MNC KP3524 Part")
            {
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Act)
            {
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 58524 "MNC KP3524 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3524";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.")
                {
                }
            }
        }
    }
}
