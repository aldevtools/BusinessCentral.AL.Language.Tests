// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// Or, unquoted after `.`, in a page control's Visible, `Visible = Rec.Or > 0;` (al-runner issue 8650).
// Quoted, as "Or", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53519 "MNC KP3519"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Or"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Or";
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

page 53519 "MNC KP3519 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3519";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.Or > 0;
                }
            }
            part(Lines; "MNC KP3519 Part")
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

page 58519 "MNC KP3519 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3519";

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
