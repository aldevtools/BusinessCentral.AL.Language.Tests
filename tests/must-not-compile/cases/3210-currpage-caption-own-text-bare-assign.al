// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// A page that declares its own Caption(): Text: the bare `Caption := 'X'` names the own procedure, not the page caption (AL0129).
// CurrPage.Caption := 'X' on the same page compiles: tests/al-language/pages/lifecycle/CurrPageCaptionOwnPublic.al.
page 50000 "MNC Caption Page 50000"
{
    PageType = Card;
    Caption = 'Static';

    trigger OnOpenPage()
    var
        S: Text; I: Integer;
    begin
        Caption := 'X';
    end;

    procedure Caption(): Text
    begin
        exit('Own');
    end;
}
