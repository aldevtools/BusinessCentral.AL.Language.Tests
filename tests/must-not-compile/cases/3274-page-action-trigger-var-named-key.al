// @expect AL0104 | Syntax error, 'begin' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The OnAction trigger of a page action declares a variable named Key, unquoted (al-runner issue 8539).
// Quoted, as "Key", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
page 53274 "MNC KV3274"
{
    PageType = Card;
    SourceTable = Customer;

    layout
    {
        area(Content)
        {
            field(No; Rec."No.") { }
        }
    }
    actions
    {
        area(Processing)
        {
            action(A)
            {
                trigger OnAction()
                var
                    Key: Integer;
                begin
                end;
            }
        }
    }
}
