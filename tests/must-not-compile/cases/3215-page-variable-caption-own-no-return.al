// @expect AL0122 | Cannot implicitly convert type 'None' to 'Text'
// A Page variable of a page that declares its own Caption() without a return value: P.Caption() names the own procedure, so it has no value
// (inside the page, CurrPage.Caption() reads the platform caption: tests/al-language/pages/lifecycle/CurrPageCaptionOwnSignature.al).
page 50000 "MNC Caption Page 50000"
{
    PageType = Card;
    Caption = 'Static';

    trigger OnOpenPage()
    var
        S: Text; I: Integer;
    begin
        S := CurrPage.Caption();
    end;

    procedure Caption()
    begin
    end;
}

codeunit 50001 "MNC Caption Caller"
{
    procedure Read(): Text
    var
        P: Page "MNC Caption Page 50000";
        S: Text;
    begin
        S := P.Caption();
        exit(S);
    end;
}
