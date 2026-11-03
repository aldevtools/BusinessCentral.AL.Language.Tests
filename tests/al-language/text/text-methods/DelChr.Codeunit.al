// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// DelChr positions and char sets.
// BC versions: 29 (27 and 28 by CI)

codeunit 70508 "LT TxB DelChr"
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
    procedure DelChrDefaultAll()
    begin
        Obs.Observe('a1', Format(DelChr('  abc  ')));
        Obs.Observe('a2', Format(DelChr(' a b ')));
        Obs.Observe('a3', Format(DelChr('abc')));
        Obs.Observe('a4', Format(DelChr('')));
        Obs.Observe('a5', Format(DelChr(' ')));
        Obs.Observe('a6', Format(DelChr('   ')));
        Obs.Observe('b1', Format(DelChr('  abc  ','=')));
        Obs.Observe('b2', Format(DelChr('  abc  ','=',' ')));
        Obs.Observe('b3', Format(DelChr('a b c','=',' ')));
        Obs.Observe('b4', Format(DelChr('aabbcc','=','a')));
        Obs.Observe('b5', Format(DelChr('aabbcc','=','ab')));
        Obs.Observe('b6', Format(DelChr('aabbcc','=','AB')));
        Obs.Observe('b7', Format(DelChr('aabbcc','=','')));
        Obs.Observe('b8', Format(DelChr('','=','a')));
        Obs.Observe('b9', Format(DelChr('abc','=','abc')));
        Obs.Observe('b10', Format(DelChr('a.b,c;d','=','.,;')));
        Obs.Observe('b11', Format(DelChr('日本語','=','本')));
        Obs.Observe('b12', Format(DelChr('äöü','=','ö')));
        Obs.Expect('a1', 'abc');
        Obs.Expect('a2', 'ab');
        Obs.Expect('a3', 'abc');
        Obs.Expect('a4', '');
        Obs.Expect('a5', '');
        Obs.Expect('a6', '');
        Obs.Expect('b1', 'abc');
        Obs.Expect('b2', 'abc');
        Obs.Expect('b3', 'abc');
        Obs.Expect('b4', 'bbcc');
        Obs.Expect('b5', 'cc');
        Obs.Expect('b6', 'aabbcc');
        Obs.Expect('b7', 'aabbcc');
        Obs.Expect('b8', '');
        Obs.Expect('b9', '');
        Obs.Expect('b10', 'abcd');
        Obs.Expect('b11', '日語');
        Obs.Expect('b12', 'äü');
        Obs.Verify();
    end;

    [Test]
    procedure DelChrLeading()
    begin
        Obs.Observe('a1', Format(DelChr('  abc  ','<')));
        Obs.Observe('a2', Format(DelChr('  abc  ','<',' ')));
        Obs.Observe('a3', Format(DelChr('xxabcxx','<','x')));
        Obs.Observe('a4', Format(DelChr('xxabcxx','<','xy')));
        Obs.Observe('a5', Format(DelChr('xyxyabc','<','xy')));
        Obs.Observe('a6', Format(DelChr('abc','<','x')));
        Obs.Observe('a7', Format(DelChr('xxx','<','x')));
        Obs.Observe('a8', Format(DelChr('','<','x')));
        Obs.Observe('a9', Format(DelChr('XXabc','<','x')));
        Obs.Observe('a10', Format(DelChr('0012','<','0')));
        Obs.Observe('a11', Format(DelChr('  ab','<','')));
        Obs.Observe('a12', Format(DelChr('x x abc','<','x')));
        Obs.Observe('a13', Format(DelChr('x x abc','<','x ')));
        Obs.Expect('a1', 'abc  ');
        Obs.Expect('a2', 'abc  ');
        Obs.Expect('a3', 'abcxx');
        Obs.Expect('a4', 'abcxx');
        Obs.Expect('a5', 'abc');
        Obs.Expect('a6', 'abc');
        Obs.Expect('a7', '');
        Obs.Expect('a8', '');
        Obs.Expect('a9', 'XXabc');
        Obs.Expect('a10', '12');
        Obs.Expect('a11', '  ab');
        Obs.Expect('a12', ' x abc');
        Obs.Expect('a13', 'abc');
        Obs.Verify();
    end;

    [Test]
    procedure DelChrTrailing()
    begin
        Obs.Observe('a1', Format(DelChr('  abc  ','>')));
        Obs.Observe('a2', Format(DelChr('  abc  ','>',' ')));
        Obs.Observe('a3', Format(DelChr('xxabcxx','>','x')));
        Obs.Observe('a4', Format(DelChr('xxabcxx','>','xy')));
        Obs.Observe('a5', Format(DelChr('abcyxyx','>','xy')));
        Obs.Observe('a6', Format(DelChr('abc','>','x')));
        Obs.Observe('a7', Format(DelChr('xxx','>','x')));
        Obs.Observe('a8', Format(DelChr('','>','x')));
        Obs.Observe('a9', Format(DelChr('abcXX','>','x')));
        Obs.Observe('a10', Format(DelChr('1200','>','0')));
        Obs.Observe('a11', Format(DelChr('ab  ','>','')));
        Obs.Observe('a12', Format(StrLen(DelChr('ab  ','>',' '))));
        Obs.Observe('a13', Format(DelChr('abc x x','>','x')));
        Obs.Observe('a14', Format(DelChr('abc x x','>','x ')));
        Obs.Expect('a1', '  abc');
        Obs.Expect('a2', '  abc');
        Obs.Expect('a3', 'xxabc');
        Obs.Expect('a4', 'xxabc');
        Obs.Expect('a5', 'abc');
        Obs.Expect('a6', 'abc');
        Obs.Expect('a7', '');
        Obs.Expect('a8', '');
        Obs.Expect('a9', 'abcXX');
        Obs.Expect('a10', '12');
        Obs.Expect('a11', 'ab  ');
        Obs.Expect('a12', '2');
        Obs.Expect('a13', 'abc x ');
        Obs.Expect('a14', 'abc');
        Obs.Verify();
    end;

    [Test]
    procedure DelChrBothAndInvalid()
    begin
        Obs.Observe('a1', Format(DelChr('  abc  ','<>')));
        Obs.Observe('a2', Format(DelChr('  abc  ','<>',' ')));
        Obs.Observe('a3', Format(DelChr('xxabcxx','<>','x')));
        Obs.Observe('a4', Format(DelChr('xaxbxcx','<>','x')));
        Obs.Observe('a5', Format(DelChr('xxx','<>','x')));
        Obs.Observe('a6', Format(DelChr('','<>','x')));
        Obs.Observe('a7', Format(DelChr('abc','<>','x')));
        Obs.Observe('a8', Format(DelChr('><abc><','<>','<>')));
        Obs.Observe('a9', Format(DelChr('  abc  ','><',' ')));
        Obs.Observe('a10', Format(DelChr('  a  b  ','<>',' ')));
        asserterror T := DelChr('abc','x','a');
        Obs.ObserveError('badpos');
        T := DelChr('abc','<<','a');
        Obs.Observe('badpos2', 'no error');
        T := DelChr('abc','==','a');
        Obs.Observe('badpos3', 'no error');
        T := DelChr('abc','','a');
        Obs.Observe('emptypos', 'no error');
        T := DelChr('abc','<=>','a');
        Obs.Observe('longpos', 'no error');
        T := DelChr('abc','<=','a');
        Obs.Observe('badpos4', 'no error');
        asserterror T := DelChr('abc','> ','a');
        Obs.ObserveError('badpos5');
        Obs.Expect('a1', 'abc');
        Obs.Expect('a2', 'abc');
        Obs.Expect('a3', 'abc');
        Obs.Expect('a4', 'axbxc');
        Obs.Expect('a5', '');
        Obs.Expect('a6', '');
        Obs.Expect('a7', 'abc');
        Obs.Expect('a8', 'abc');
        Obs.Expect('a9', 'abc');
        Obs.Expect('a10', 'a  b');
        Obs.Expect('badpos|text', 'Incorrect use of the where parameter.');
        Obs.Expect('badpos|code', 'ALSystemString');
        Obs.Expect('badpos2', 'no error');
        Obs.Expect('badpos3', 'no error');
        Obs.Expect('emptypos', 'no error');
        Obs.Expect('longpos', 'no error');
        Obs.Expect('badpos4', 'no error');
        Obs.Expect('badpos5|text', 'Incorrect use of the where parameter.');
        Obs.Expect('badpos5|code', 'ALSystemString');
        Obs.Verify();
    end;

    [Test]
    procedure DelChrTargets()
    begin
        T := '  abc  ';
        T5 := DelChr(T,'<>');
        Obs.Observe('t5', Format(T5));
        C5 := DelChr(T,'=','b');
        Obs.Observe('c5', Format(C5));
        C5 := DelChr('xxabcxx','<>','x');
        Obs.Observe('c5b', Format(C5));
        asserterror T5 := DelChr('abcdefgh','=','x');
        Obs.ObserveError('t5over');
        Obs.Observe('combo', Format(DelChr(DelChr('  a-b  ','<>'),'=','-')));
        Obs.Expect('t5', 'abc');
        Obs.Expect('c5', 'AC');
        Obs.Expect('c5b', 'ABC');
        Obs.Expect('t5over|text', 'The length of the string is 8, but it must be less than or equal to 5 characters. Value: abcdefgh');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('combo', 'ab');
        Obs.Verify();
    end;

}
