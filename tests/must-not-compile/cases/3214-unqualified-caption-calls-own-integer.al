// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Text'
// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Text'
// A page that declares its own Caption(): Integer: the unqualified Caption() calls the own procedure (Integer), with and without parentheses.
page 50000 "MNC Caption Page 50000"
{
    PageType = Card;
    Caption = 'Static';

    trigger OnOpenPage()
    var
        S: Text; I: Integer;
    begin
        S := Caption();
        S := Caption;
    end;

    procedure Caption(): Integer
    begin
        exit(5);
    end;
}
