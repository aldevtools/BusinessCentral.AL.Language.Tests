// @expect AL0107 | Syntax error, identifier expected
// While, unquoted after `.`, in a page extension's Visible on a base group (`modify`) (al-runner issue 8650).
// Quoted, as "While", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53554 "MNC KP3554"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "While"; Integer)
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

page 53554 "MNC KP3554 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3554";

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
            part(Lines; "MNC KP3554 Part")
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

page 58554 "MNC KP3554 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3554";

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

pageextension 53554 "MNC KP3554 Ext" extends "MNC KP3554 Card"
{
    layout
    {
        modify(General)
        {
            Visible = Rec.While > 0;
        }
    }
}
