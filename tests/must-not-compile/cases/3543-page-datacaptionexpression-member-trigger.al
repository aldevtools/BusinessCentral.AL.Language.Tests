// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ',' expected
// Trigger, unquoted after `.`, in a page's DataCaptionExpression, `Format(Rec.Trigger)` (al-runner issue 8650).
// Quoted, as "Trigger", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53543 "MNC KP3543"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Trigger"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Trigger";
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

page 53543 "MNC KP3543 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3543";
    DataCaptionExpression = Format(Rec.Trigger);

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
            part(Lines; "MNC KP3543 Part")
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

page 58543 "MNC KP3543 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3543";

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
