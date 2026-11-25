// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'in' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, 'do' expected
// The member is a TestPage control, `Card.ForEach.SetValue(...)`, unquoted (al-runner issue 8635).
// Quoted, as "ForEach", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53451 "MNC KM3451"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "ForEach"; Integer)
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

page 53451 "MNC KM3451 Card"
{
    PageType = Card;
    SourceTable = "MNC KM3451";

    layout
    {
        area(Content)
        {
            field("ForEach"; Rec."ForEach")
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

codeunit 58451 "MNC KM3451 Test"
{
    Subtype = Test;

    [Test]
    procedure P()
    var
        Card: TestPage "MNC KM3451 Card";
    begin
        Card.OpenView();
        Card.ForEach.SetValue(1);
    end;
}
