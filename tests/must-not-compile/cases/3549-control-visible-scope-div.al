// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// Div, unquoted after `::` (an option field's member), in a page control's Visible, `Visible = Rec.Div > 0;` (al-runner issue 8650).
// Quoted, as "Div", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53549 "MNC KP3549"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Div"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Div";
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

page 53549 "MNC KP3549 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3549";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.Opt::Div > 0;
                }
            }
            part(Lines; "MNC KP3549 Part")
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

page 58549 "MNC KP3549 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3549";

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
