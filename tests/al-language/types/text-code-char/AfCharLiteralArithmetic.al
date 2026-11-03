// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 78300
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a Char minus or plus a one-character Text literal compiles, with the literal read as a Char: the result type (an Integer, so the statements assign to an Integer variable),
// the value, the reverse order, and the sign of a negative result. A Char minus a Text variable does not compile (must-not-compile case 0500).
// BC versions: 27, 28, 29

codeunit 78300 "LT AF Char Literal Arithmetic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AF_Char_Literal_Arithmetic()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
        I: Integer;
        Big: Integer;
    begin
        Ch := 'C';
        I := Ch - 'A';
        Observer.Observe('C - A', Format(I));
        I := 'A' - Ch;
        Observer.Observe('A - C', Format(I));
        I := Ch + 'A';
        Observer.Observe('C + A', Format(I));
        I := 'A' + Ch;
        Observer.Observe('A + C', Format(I));
        I := Ch - 'a';
        Observer.Observe('C - a', Format(I));
        Big := Ch;
        Observer.Observe('C as integer', Format(Big));
        Observer.Observe('format(C - A)', Format(Ch - 'A'));
        Observer.Observe('format(A - C)', Format('A' - Ch));
        Observer.Observe('format(C + A)', Format(Ch + 'A'));
        Observer.Observe('format(A + C)', Format('A' + Ch));
        Observer.Observe('C - A + 1', Format(Ch - 'A' + 1));
        Observer.Observe('C - A = 2', Format(Ch - 'A' = 2));
        Observer.Observe('C + two-char text', Format(Ch + 'AB'));
        Observer.Observe('C + empty text', Format(Ch + ''));
        Observer.Observe('two-char text + C', Format('AB' + Ch));
        Observer.Expect('C - A', '2');
        Observer.Expect('A - C', '-2');
        Observer.Expect('C + A', '132');
        Observer.Expect('A + C', '132');
        Observer.Expect('C - a', '-30');
        Observer.Expect('C as integer', '67');
        Observer.Expect('format(C - A)', '2');
        Observer.Expect('format(A - C)', '-2');
        Observer.Expect('format(C + A)', '132');
        Observer.Expect('format(A + C)', '132');
        Observer.Expect('C - A + 1', '3');
        Observer.Expect('C - A = 2', 'Yes');
        Observer.Expect('C + two-char text', 'CAB');
        Observer.Expect('C + empty text', 'C');
        Observer.Expect('two-char text + C', 'ABC');
        Observer.Verify();
    end;
}
