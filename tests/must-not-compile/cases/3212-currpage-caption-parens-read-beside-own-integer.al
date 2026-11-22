// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Integer'
// A page that declares its own Caption(): Integer: CurrPage.Caption() with parentheses is Text as well (the platform caption, not the procedure).
page 50000 "MNC Caption Page 50000"
{
    PageType = Card;
    Caption = 'Static';

    trigger OnOpenPage()
    var
        S: Text; I: Integer;
    begin
        I := CurrPage.Caption();
    end;

    procedure Caption(): Integer
    begin
        exit(5);
    end;
}
