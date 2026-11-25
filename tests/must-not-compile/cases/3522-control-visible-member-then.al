// @expect AL0107 | Syntax error, identifier expected
// Then, unquoted after `.`, in a page control's Visible, `Visible = Rec.Then > 0;` (al-runner issue 8650).
// Quoted, as "Then", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53522 "MNC KP3522"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Then"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Then";
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

page 53522 "MNC KP3522 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3522";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.Then > 0;
                }
            }
            part(Lines; "MNC KP3522 Part")
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

page 58522 "MNC KP3522 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3522";

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
