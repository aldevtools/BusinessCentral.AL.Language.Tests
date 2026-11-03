// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained test codeunit 83550
// Corpus issue 672 (odd AL behavior leads, part G), item 47: a multiline text literal (@'...') in a source file with CRLF line
// endings. THIS FILE MUST KEEP CRLF LINE ENDINGS (the LF form is in misc/lt-expressions-statements/PLiteralExpressions.al).
// Does the literal hold CR LF or LF only? The Probe Observer writes CR and LF as \r and \n.
// Probe: values asserted below are what the corpus CI tiers (BC 27.5, 28.5, 29.0) produced.
// BC versions: 27, 28, 29

codeunit 83550 "LT BU Multiline CRLF"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LT_BU_Literal_MultilineTextCrlfSource()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        T2: Text;
        Code2: Integer;
    begin
        T := @'a
b';
        T2 := @'first
    second
third';
        Observer.Observe('two lines', T);
        Observer.Observe('two lines len', Format(StrLen(T)));
        Code2 := T[2];
        Observer.Observe('char 2 code', Format(Code2));
        Observer.Observe('three lines', T2);
        Observer.Observe('three lines len', Format(StrLen(T2)));
        Observer.Expect('two lines', 'a\r\nb');
        Observer.Expect('two lines len', '4');
        Observer.Expect('char 2 code', '13');
        Observer.Expect('three lines', 'first\r\n    second\r\nthird');
        Observer.Expect('three lines len', '24');
        Observer.Verify();
    end;
}
