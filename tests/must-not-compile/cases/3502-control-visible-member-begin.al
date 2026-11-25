// @expect AL0107 | Syntax error, identifier expected
// Begin, unquoted after `.`, in a page control's Visible, `Visible = Rec.Begin > 0;` (al-runner issue 8650).
// Quoted, as "Begin", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53502 "MNC KP3502"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Begin"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Begin";
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

page 53502 "MNC KP3502 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3502";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.Begin > 0;
                }
            }
            part(Lines; "MNC KP3502 Part")
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

page 58502 "MNC KP3502 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3502";

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
