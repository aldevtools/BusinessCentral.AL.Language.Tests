// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 80003
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a character taken from a Text or Code value by index (S[i]), plus or minus a one-character Text literal: S[i] - '0', S[i] + 'A',
// 'A' + S[1], and longer chains with a one-character and a longer literal. The statements that assign to an Integer compile, so the result is an
// Integer; Format shows the value. The Char variable form is in types/lt-af-char-literal/AfCharLiteralArithmetic.al.
// BC versions: 27, 28, 29

codeunit 80003 "LT AT Text Char Literal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AT_TextIndex_Minus_Literal()
    var
        Observer: Codeunit "Probe Observer";
        S: Text;
        I: Integer;
    begin
        S := '7B';
        I := S[1] - '0';
        Observer.Observe('S1 - 0', Format(I));
        I := S[2] - 'A';
        Observer.Observe('S2 - A', Format(I));
        I := '0' - S[1];
        Observer.Observe('0 - S1', Format(I));
        Observer.Observe('fmt S1 - 0', Format(S[1] - '0'));
        Observer.Observe('S1 - 0 + 1', Format(S[1] - '0' + 1));
        Observer.Observe('S1 - 0 = 7', Format(S[1] - '0' = 7));
        Observer.Expect('S1 - 0', '7');
        Observer.Expect('S2 - A', '1');
        Observer.Expect('0 - S1', '-7');
        Observer.Expect('fmt S1 - 0', '7');
        Observer.Expect('S1 - 0 + 1', '8');
        Observer.Expect('S1 - 0 = 7', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AT_TextIndex_Plus_Literal()
    var
        Observer: Codeunit "Probe Observer";
        S: Text;
        I: Integer;
    begin
        S := '7B';
        I := S[2] + 'A';
        Observer.Observe('S2 + A', Format(I));
        I := 'A' + S[1];
        Observer.Observe('A + S1', Format(I));
        Observer.Observe('fmt S2 + A', Format(S[2] + 'A'));
        Observer.Observe('fmt A + S1', Format('A' + S[1]));
        Observer.Expect('S2 + A', '131');
        Observer.Expect('A + S1', '120');
        Observer.Expect('fmt S2 + A', '131');
        Observer.Expect('fmt A + S1', '120');
        Observer.Verify();
    end;

    [Test]
    procedure AT_TextIndex_Chains()
    var
        Observer: Codeunit "Probe Observer";
        S: Text;
    begin
        S := '7B';
        Observer.Observe('a + S1 + b', Format('a' + S[1] + 'b'));
        Observer.Observe('ab + S1', Format('ab' + S[1]));
        Observer.Observe('S1 + ab', Format(S[1] + 'ab'));
        Observer.Observe('S1 + S2', Format(S[1] + S[2]));
        Observer.Observe('S1 + empty', Format(S[1] + ''));
        Observer.Expect('a + S1 + b', '250');
        Observer.Expect('ab + S1', 'ab7');
        Observer.Expect('S1 + ab', '7ab');
        Observer.Expect('S1 + S2', '121');
        Observer.Expect('S1 + empty', '7');
        Observer.Verify();
    end;

    [Test]
    procedure AT_CodeIndex_Minus_Literal()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[10];
        I: Integer;
    begin
        C := 'x9';
        I := C[2] - '0';
        Observer.Observe('C2 - 0', Format(I));
        I := C[1] - 'A';
        Observer.Observe('C1 - A', Format(I));
        Observer.Observe('fmt A + C1', Format('A' + C[1]));
        Observer.Expect('C2 - 0', '9');
        Observer.Expect('C1 - A', '23');
        Observer.Expect('fmt A + C1', '153');
        Observer.Verify();
    end;
}
