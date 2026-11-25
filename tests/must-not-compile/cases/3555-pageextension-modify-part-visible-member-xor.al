// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// Xor, unquoted after `.`, in a page extension's Visible on a base part (`modify`) (al-runner issue 8650).
// Quoted, as "Xor", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53555 "MNC KP3555"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Xor"; Integer)
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

page 53555 "MNC KP3555 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3555";

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
            part(Lines; "MNC KP3555 Part")
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

page 58555 "MNC KP3555 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3555";

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

pageextension 53555 "MNC KP3555 Ext" extends "MNC KP3555 Card"
{
    layout
    {
        modify(Lines)
        {
            Visible = Rec.Xor > 0;
        }
    }
}
