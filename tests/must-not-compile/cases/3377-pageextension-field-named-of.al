// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property 'Rec' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// A page extension field control is named Of, unquoted: `field(Of; Rec.Amount)` (al-runner issue 8634).
// Quoted, as "Of", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53377 "MNC KS3377"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Amount; Integer)
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

page 53377 "MNC KS3377 Page"
{
    PageType = Card;
    SourceTable = "MNC KS3377";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
            }
        }
        area(FactBoxes)
        {
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
        area(Promoted)
        {
        }
    }
}

pageextension 53377 "MNC KS3377 Ext" extends "MNC KS3377 Page"
{
    layout
    {
        addlast(Content)
        {
            field(Of; Rec.Amount)
            {
            }
        }
    }
}
