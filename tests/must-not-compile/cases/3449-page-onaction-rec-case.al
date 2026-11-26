// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, 'of' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The member is Rec's field written in a page action's OnAction, unquoted (al-runner issue 8635).
// Quoted, as "Case", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53449 "MNC KM3449"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Case"; Integer)
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

page 53449 "MNC KM3449 Card"
{
    PageType = Card;
    SourceTable = "MNC KM3449";

    layout
    {
        area(Content)
        {
            field("Case"; Rec."Case")
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
                    Rec.Case := 1;
                end;
            }
        }
    }
}
