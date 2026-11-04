// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// StrPos forms.
// BC versions: 29 (27 and 28 by CI)

codeunit 70510 "LT TxB StrPos"
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
    procedure StrPosBasic()
    begin
        Obs.Observe('a1', Format(StrPos('Hello World','World')));
        Obs.Observe('a2', Format(StrPos('Hello World','o')));
        Obs.Observe('a3', Format(StrPos('Hello World','O')));
        Obs.Observe('a4', Format(StrPos('Hello World','world')));
        Obs.Observe('a5', Format(StrPos('Hello World','x')));
        Obs.Observe('a6', Format(StrPos('Hello World','')));
        Obs.Observe('a7', Format(StrPos('','a')));
        Obs.Observe('a8', Format(StrPos('','')));
        Obs.Observe('a9', Format(StrPos('abc','abc')));
        Obs.Observe('a10', Format(StrPos('abc','abcd')));
        Obs.Observe('a11', Format(StrPos('abc','c')));
        Obs.Observe('a12', Format(StrPos('aaa','aa')));
        Obs.Observe('a13', Format(StrPos('a b',' ')));
        Obs.Observe('a14', Format(StrPos('日本語','語')));
        Obs.Observe('a15', Format(StrPos('äöü','ü')));
        Obs.Observe('a16', Format(StrPos('ÄÖÜ','ö')));
        Obs.Observe('a17', Format(StrPos('abc','  ')));
        Obs.Observe('a18', Format(StrPos('abc ','c ')));
        Obs.Observe('a19', Format(StrPos('abc','c ')));
        Obs.Observe('a20', Format(StrPos(' ','')));
        Obs.Observe('a21', Format(StrPos(' ',' ')));
        Obs.Expect('a1', '7');
        Obs.Expect('a2', '5');
        Obs.Expect('a3', '0');
        Obs.Expect('a4', '0');
        Obs.Expect('a5', '0');
        Obs.Expect('a6', '0');
        Obs.Expect('a7', '0');
        Obs.Expect('a8', '0');
        Obs.Expect('a9', '1');
        Obs.Expect('a10', '0');
        Obs.Expect('a11', '3');
        Obs.Expect('a12', '1');
        Obs.Expect('a13', '2');
        Obs.Expect('a14', '3');
        Obs.Expect('a15', '3');
        Obs.Expect('a16', '0');
        Obs.Expect('a17', '0');
        Obs.Expect('a18', '3');
        Obs.Expect('a19', '0');
        Obs.Expect('a20', '0');
        Obs.Expect('a21', '1');
        Obs.Verify();
    end;

    [Test]
    procedure StrPosTargets()
    begin
        C5 := 'Ab';
        T := 'xaby';
        Obs.Observe('code', Format(StrPos(T,C5)));
        Obs.Observe('codeupper', Format(StrPos('XAB',C5)));
        T5 := 'ab';
        Obs.Observe('t5', Format(StrPos(T,T5)));
        Obs.Observe('label', Format(StrPos(TLabel,'World')));
        Obs.Observe('labelc', Format(StrPos(CLabel,'c')));
        Obs.Observe('wild', Format(StrPos('a*b','*')));
        Obs.Observe('wild2', Format(StrPos('a?b','?')));
        Obs.Observe('pipe', Format(StrPos('a|b','|')));
        Obs.Observe('amp', Format(StrPos('a&b','&')));
        Obs.Observe('dot', Format(StrPos('a.b','.')));
        Obs.Observe('brk', Format(StrPos('a(b','(')));
        Obs.Expect('code', '0');
        Obs.Expect('codeupper', '2');
        Obs.Expect('t5', '2');
        Obs.Expect('label', '7');
        Obs.Expect('labelc', '3');
        Obs.Expect('wild', '2');
        Obs.Expect('wild2', '2');
        Obs.Expect('pipe', '2');
        Obs.Expect('amp', '2');
        Obs.Expect('dot', '2');
        Obs.Expect('brk', '2');
        Obs.Verify();
    end;

}
