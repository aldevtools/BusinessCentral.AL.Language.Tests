// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90640
// Probe: written against al-runner issue 6300 (an Integer plus a one-character Text literal); every value asserted below is what the BC service tier produced.
// Facts: an Integer plus or minus a one-character Text literal compiles; the literal is read as a Char (its character code), so the result is Integer arithmetic.
// BC versions: 27, 28, 29

codeunit 90640 "LT WC Int Char Literal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WC_Integer_Plus_CharLiteral()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Num: Integer;
    begin
        Num := 1000;
        Observer.Observe('const 1000 + dash + 2', Format(1000 + '-' + 2));
        Observer.Observe('var 1000 + dash + 2', Format(Num + '-' + 2));
        I := Num + '-';
        Observer.Observe('Num + dash', Format(I));
        I := '-' + Num;
        Observer.Observe('dash + Num', Format(I));
        I := Num - 'A';
        Observer.Observe('Num - A', Format(I));
        I := 'A' - Num;
        Observer.Observe('A - Num', Format(I));
        I := Num + '0';
        Observer.Observe('Num + zero char', Format(I));
        Observer.Observe('in a Format call', Format(Num + '-' + Random(1)));
        Observer.Finish();
    end;

    [Test]
    procedure WC_Integer_CharLiteral_Compare()
    var
        Observer: Codeunit "Probe Observer";
        Num: Integer;
    begin
        Num := 45;
        Observer.Observe('Num = dash', Format(Num = '-'));
        Observer.Observe('Num > dash', Format(Num > '-'));
        Observer.Finish();
    end;
}
