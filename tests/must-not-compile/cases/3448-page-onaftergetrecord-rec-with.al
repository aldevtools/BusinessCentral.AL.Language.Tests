// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, 'do' expected
// The member is Rec's field written in a page's OnAfterGetRecord, unquoted (al-runner issue 8635).
// Quoted, as "With", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53448 "MNC KM3448"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "With"; Integer)
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

page 53448 "MNC KM3448 Card"
{
    PageType = Card;
    SourceTable = "MNC KM3448";

    layout
    {
        area(Content)
        {
            field("With"; Rec."With")
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

    trigger OnAfterGetRecord()
    begin
        Rec.With := 1;
    end;
}
