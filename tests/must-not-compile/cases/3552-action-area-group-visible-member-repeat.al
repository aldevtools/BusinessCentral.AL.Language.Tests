// @expect AL0107 | Syntax error, identifier expected
// Repeat, unquoted after `.`, in a group's Visible in a page's actions area (al-runner issue 8650).
// Quoted, as "Repeat", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53552 "MNC KP3552"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Repeat"; Integer)
        {
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

page 53552 "MNC KP3552 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3552";

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
            part(Lines; "MNC KP3552 Part")
            {
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(Grp)
            {
                Visible = Rec.Repeat > 0;
                action(Inner)
                {
                    trigger OnAction()
                    begin
                    end;
                }
            }
            action(Act)
            {
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

page 58552 "MNC KP3552 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3552";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                }
            }
        }
    }
}
