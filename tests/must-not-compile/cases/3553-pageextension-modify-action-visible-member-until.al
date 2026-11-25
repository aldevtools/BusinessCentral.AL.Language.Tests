// @expect AL0107 | Syntax error, identifier expected
// Until, unquoted after `.`, in a page extension's Visible on a base action (`modify`) (al-runner issue 8650).
// Quoted, as "Until", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53553 "MNC KP3553"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Until"; Integer)
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

page 53553 "MNC KP3553 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3553";

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
            part(Lines; "MNC KP3553 Part")
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

page 58553 "MNC KP3553 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3553";

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

pageextension 53553 "MNC KP3553 Ext" extends "MNC KP3553 Card"
{
    actions
    {
        modify(Act)
        {
            Visible = Rec.Until > 0;
        }
    }
}
