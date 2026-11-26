// @expect AL0107 | Syntax error, identifier expected
// Do, unquoted after `.`, in a page action's Visible (al-runner issue 8650).
// Quoted, as "Do", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53539 "MNC KP3539"
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

page 53539 "MNC KP3539 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3539";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                }
            }
            part(Lines; "MNC KP3539 Part")
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
                    Visible = Rec.Do > 0;
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 58539 "MNC KP3539 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3539";

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
