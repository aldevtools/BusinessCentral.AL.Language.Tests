// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// StrLen of text, code, empty, unicode, trailing blanks, long text.
// BC versions: 29 (27 and 28 by CI)

codeunit 70500 "LT TxB StrLen"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        T: Text;
        T2: Text;
        T5: Text[5];
        C5: Code[5];
        C10: Code[10];
        I: Integer;
        D: Decimal;
        TLabel: Label 'Hello World', Locked = true;
        CLabel: Label 'abc', Locked = true, MaxLength = 10;

    [Test]
    procedure StrLenBasic()
    begin
        Obs.Observe('a1', Format(StrLen('')));
        Obs.Observe('a2', Format(StrLen('a')));
        Obs.Observe('a3', Format(StrLen('Hello')));
        Obs.Observe('a4', Format(StrLen('  ')));
        Obs.Observe('a5', Format(StrLen(' a ')));
        Obs.Observe('a6', Format(StrLen('abc   ')));
        Obs.Observe('a7', Format(StrLen('äöü')));
        Obs.Observe('a8', Format(StrLen('日本語')));
        Obs.Observe('a9', Format(StrLen('a'+'b')));
        Obs.Observe('a10', Format(StrLen(PadStr('',100,'x'))));
        Obs.Observe('a11', Format(StrLen(TLabel)));
        Obs.Observe('a12', Format(StrLen(CLabel)));
        Obs.Expect('a1', '0');
        Obs.Expect('a2', '1');
        Obs.Expect('a3', '5');
        Obs.Expect('a4', '2');
        Obs.Expect('a5', '3');
        Obs.Expect('a6', '6');
        Obs.Expect('a7', '3');
        Obs.Expect('a8', '3');
        Obs.Expect('a9', '2');
        Obs.Expect('a10', '100');
        Obs.Expect('a11', '11');
        Obs.Expect('a12', '3');
        Obs.Verify();
    end;

    [Test]
    procedure StrLenVariables()
    begin
        T := 'abc  ';
        C5 := '  ab ';
        T5 := 'abcde';
        Obs.Observe('t', Format(StrLen(T)));
        Obs.Observe('c', Format(StrLen(C5)));
        Obs.Observe('t5', Format(StrLen(T5)));
        T := '';
        Obs.Observe('empty', Format(StrLen(T)));
        Clear(C5);
        Obs.Observe('clear', Format(StrLen(C5)));
        T := PadStr('',2000,'a');
        Obs.Observe('long', Format(StrLen(T)));
        T := T + T;
        Obs.Observe('long2', Format(StrLen(T)));
        Obs.Observe('lowerc', Format(StrLen(LowerCase('ABC'))));
        Obs.Observe('fmt', Format(StrLen(Format(12345))));
        Obs.Observe('fmtneg', Format(StrLen(Format(-1.5))));
        Obs.Expect('t', '5');
        Obs.Expect('c', '2');
        Obs.Expect('t5', '5');
        Obs.Expect('empty', '0');
        Obs.Expect('clear', '0');
        Obs.Expect('long', '2000');
        Obs.Expect('long2', '4000');
        Obs.Expect('lowerc', '3');
        Obs.Expect('fmt', '5');
        Obs.Expect('fmtneg', '4');
        Obs.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 43: Learn says a Code variable holds at most 1024 characters; the
    // compiler accepts up to Code[2048] (Code[2049] is AL0530, tests/must-not-compile/cases/1534). How much does each hold?
    [Test]
    procedure LT_BU_StrLen_LongCodeVariables()
    var
        Observer: Codeunit "Probe Observer";
        C1025: Code[1025];
        C2048: Code[2048];
    begin
        C1025 := PadStr('', 1025, 'a');
        Observer.Observe('code1025 len', Format(StrLen(C1025)));
        Observer.Observe('code1025 max', Format(MaxStrLen(C1025)));
        Observer.Observe('code1025 upper', Format(C1025 = PadStr('', 1025, 'A')));
        C2048 := PadStr('', 2048, 'b');
        Observer.Observe('code2048 len', Format(StrLen(C2048)));
        Observer.Observe('code2048 max', Format(MaxStrLen(C2048)));
        C2048 := ' ' + PadStr('', 2046, 'c') + ' ';
        Observer.Observe('code2048 trimmed len', Format(StrLen(C2048)));
        asserterror C1025 := PadStr('', 1026, 'a');
        Observer.ObserveError('code1025 overflow');
        Observer.Expect('code1025 len', '1025');
        Observer.Expect('code1025 max', '1025');
        Observer.Expect('code1025 upper', 'Yes');
        Observer.Expect('code2048 len', '2048');
        Observer.Expect('code2048 max', '2048');
        Observer.Expect('code2048 trimmed len', '2046');
        Observer.Expect('code1025 overflow|text', 'The length of the string is 1026, but it must be less than or equal to 1025 characters. Value: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa...');
        Observer.Expect('code1025 overflow|code', 'StringLengthExceeded');
        Observer.Verify();
    end;
}
