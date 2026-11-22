// @expect AL0122 | Cannot implicitly convert type 'None' to 'Text'
// A page that declares its own Caption() without a return value: the unqualified Caption() calls the own procedure, which returns nothing.
// CurrPage.Caption() on the same page reads the platform caption and compiles: tests/al-language/pages/lifecycle/CurrPageCaptionOwnSignature.al.
page 50000 "MNC Caption Page 50000"
{
    PageType = Card;
    Caption = 'Static';

    trigger OnOpenPage()
    var
        S: Text; I: Integer;
    begin
        S := Caption();
    end;

    procedure Caption()
    begin
    end;
}
