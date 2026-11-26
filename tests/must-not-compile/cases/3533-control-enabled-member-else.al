// @expect AL0107 | Syntax error, identifier expected
// Else, unquoted after `.`, in a page control's Enabled (al-runner issue 8650).
// Quoted, as "Else", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53533 "MNC KP3533"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Else"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Else";
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

page 53533 "MNC KP3533 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3533";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Enabled = Rec.Else > 0;
                }
            }
            part(Lines; "MNC KP3533 Part")
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

page 58533 "MNC KP3533 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3533";

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
