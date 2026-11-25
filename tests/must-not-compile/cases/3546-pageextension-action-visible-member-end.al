// @expect AL0107 | Syntax error, identifier expected
// End, unquoted after `.`, in a page extension action's Visible (al-runner issue 8650).
// Quoted, as "End", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53546 "MNC KP3546"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "End"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"End";
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

page 53546 "MNC KP3546 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3546";

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
            part(Lines; "MNC KP3546 Part")
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

page 58546 "MNC KP3546 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3546";

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

pageextension 53546 "MNC KP3546 Ext" extends "MNC KP3546 Card"
{
    actions
    {
        addlast(Processing)
        {
            action(Act2)
            {
                Visible = Rec.End > 0;

                trigger OnAction()
                begin
                end;
            }
        }
    }
}
