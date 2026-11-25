// @expect AL0107 | Syntax error, identifier expected
// Do, unquoted after `.`, in a page control's Visible, `Visible = Rec.Do > 0;` (al-runner issue 8650).
// Quoted, as "Do", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53505 "MNC KP3505"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Do"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Do";
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

page 53505 "MNC KP3505 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3505";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.Do > 0;
                }
            }
            part(Lines; "MNC KP3505 Part")
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

page 58505 "MNC KP3505 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3505";

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
