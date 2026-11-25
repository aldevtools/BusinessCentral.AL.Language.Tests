// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ',' expected
// For, unquoted after `.`, in a page control's CaptionClass, `Format(Rec.For)` (al-runner issue 8650).
// Quoted, as "For", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53534 "MNC KP3534"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "For"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"For";
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

page 53534 "MNC KP3534 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3534";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    CaptionClass = Format(Rec.For);
                }
            }
            part(Lines; "MNC KP3534 Part")
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

page 58534 "MNC KP3534 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3534";

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
