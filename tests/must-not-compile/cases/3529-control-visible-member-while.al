// @expect AL0107 | Syntax error, identifier expected
// While, unquoted after `.`, in a page control's Visible, `Visible = Rec.While > 0;` (al-runner issue 8650).
// Quoted, as "While", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53529 "MNC KP3529"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "While"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"While";
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

page 53529 "MNC KP3529 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3529";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.While > 0;
                }
            }
            part(Lines; "MNC KP3529 Part")
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

page 58529 "MNC KP3529 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3529";

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
