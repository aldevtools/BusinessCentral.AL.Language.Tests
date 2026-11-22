// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Integer'
// A page that declares its own Caption(): Integer: a read of CurrPage.Caption is Text (the platform caption), so it cannot go to an Integer.
// CurrPage.Caption := 'X' beside the same procedure compiles: tests/al-language/pages/lifecycle/CurrPageCaptionOwnPublic.al.
page 50000 "MNC Caption Page 50000"
{
    PageType = Card;
    Caption = 'Static';

    trigger OnOpenPage()
    var
        S: Text; I: Integer;
    begin
        I := CurrPage.Caption;
    end;

    procedure Caption(): Integer
    begin
        exit(5);
    end;
}
