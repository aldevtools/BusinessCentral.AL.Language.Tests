// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// And, unquoted after `.`, in a page control's Visible, `Visible = Rec.And > 0;` (al-runner issue 8650).
// Quoted, as "And", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53500 "MNC KP3500"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "And"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"And";
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

page 53500 "MNC KP3500 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3500";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.And > 0;
                }
            }
            part(Lines; "MNC KP3500 Part")
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

page 58500 "MNC KP3500 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3500";

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
