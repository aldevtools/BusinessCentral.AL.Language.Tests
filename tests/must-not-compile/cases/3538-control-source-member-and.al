// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// And, unquoted after `.`, in a page control's source expression, `field(Shown; Rec.And)` (al-runner issue 8650).
// Quoted, as "And", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53538 "MNC KP3538"
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

page 53538 "MNC KP3538 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3538";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                }
                field(Shown; Rec.And)
                {
                }
            }
            part(Lines; "MNC KP3538 Part")
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

page 58538 "MNC KP3538 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3538";

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
