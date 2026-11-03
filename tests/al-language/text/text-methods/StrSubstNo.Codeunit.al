// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// StrSubstNo placeholders and arguments.
// BC versions: 29 (27 and 28 by CI)

codeunit 70511 "LT TxB StrSubstNo"
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
    procedure SubstNoPercent()
    begin
        Obs.Observe('a1', Format(StrSubstNo('%1','a')));
        Obs.Observe('a2', Format(StrSubstNo('%1 %2','a','b')));
        Obs.Observe('a3', Format(StrSubstNo('%2 %1','a','b')));
        Obs.Observe('a4', Format(StrSubstNo('%1%1','a')));
        Obs.Observe('a5', Format(StrSubstNo('x%1y','a')));
        Obs.Observe('a6', Format(StrSubstNo('%1 %2 %3','a','b','c')));
        Obs.Observe('a7', Format(StrSubstNo('%3','a','b','c')));
        Obs.Observe('a8', Format(StrSubstNo('no placeholder','a')));
        Obs.Observe('a9', Format(StrSubstNo('no placeholder')));
        Obs.Observe('a10', Format(StrSubstNo('%1')));
        Obs.Observe('a11', Format(StrSubstNo('%1 and %2','a')));
        Obs.Observe('a12', Format(StrSubstNo('%2','a')));
        Obs.Observe('a13', Format(StrSubstNo('%%','a')));
        Obs.Observe('a14', Format(StrSubstNo('%','a')));
        Obs.Observe('a15', Format(StrSubstNo('100%','a')));
        Obs.Observe('a16', Format(StrSubstNo('%a','x')));
        Obs.Observe('a17', Format(StrSubstNo('%0','x')));
        Obs.Observe('a18', Format(StrSubstNo('%1','')));
        Obs.Observe('a19', Format(StrSubstNo('','a')));
        Obs.Observe('a20', Format(StrSubstNo('%11','a')));
        Obs.Observe('a21', Format(StrSubstNo('%10','a')));
        Obs.Observe('a22', Format(StrSubstNo('%1',1)));
        Obs.Observe('a23', Format(StrSubstNo('%1',1.5)));
        Obs.Observe('a24', Format(StrSubstNo('%1',true)));
        Obs.Observe('a25', Format(StrSubstNo('%1',0D)));
        Obs.Observe('a26', Format(StrSubstNo('%1',-5)));
        Obs.Expect('a1', 'a');
        Obs.Expect('a2', 'a b');
        Obs.Expect('a3', 'b a');
        Obs.Expect('a4', 'aa');
        Obs.Expect('a5', 'xay');
        Obs.Expect('a6', 'a b c');
        Obs.Expect('a7', 'c');
        Obs.Expect('a8', 'no placeholder');
        Obs.Expect('a9', 'no placeholder');
        Obs.Expect('a10', '%1');
        Obs.Expect('a11', 'a and %2');
        Obs.Expect('a12', '%2');
        Obs.Expect('a13', '%%');
        Obs.Expect('a14', '%');
        Obs.Expect('a15', '100%');
        Obs.Expect('a16', '%a');
        Obs.Expect('a17', '%0');
        Obs.Expect('a18', '');
        Obs.Expect('a19', '');
        Obs.Expect('a20', '%11');
        Obs.Expect('a21', '%10');
        Obs.Expect('a22', '1');
        Obs.Expect('a23', '1.5');
        Obs.Expect('a24', 'Yes');
        Obs.Expect('a25', '');
        Obs.Expect('a26', '-5');
        Obs.Verify();
    end;

    [Test]
    procedure SubstNoTen()
    begin
        Obs.Observe('a1', Format(StrSubstNo('%1%2%3%4%5%6%7%8%9%10','a','b','c','d','e','f','g','h','i','j')));
        Obs.Observe('a2', Format(StrSubstNo('%10','a','b','c','d','e','f','g','h','i','j')));
        Obs.Observe('a3', Format(StrSubstNo('%10 %1','a','b','c','d','e','f','g','h','i','j')));
        Obs.Observe('a4', Format(StrSubstNo('%1','a','b','c','d','e','f','g','h','i','j')));
        Obs.Observe('a5', Format(StrSubstNo('%9','a','b','c','d','e','f','g','h','i','j')));
        Obs.Observe('a6', Format(StrSubstNo('%1 %2 %3 %4 %5 %6 %7 %8 %9 %10','1','2','3','4','5','6','7','8','9','10')));
        Obs.Observe('a7', Format(StrSubstNo('%10','1','2','3','4','5','6','7','8','9')));
        Obs.Observe('a8', Format(StrSubstNo('%5','1','2')));
        Obs.Expect('a1', 'abcdefghij');
        Obs.Expect('a2', 'j');
        Obs.Expect('a3', 'j a');
        Obs.Expect('a4', 'a');
        Obs.Expect('a5', 'i');
        Obs.Expect('a6', '1 2 3 4 5 6 7 8 9 10');
        Obs.Expect('a7', '%10');
        Obs.Expect('a8', '%5');
        Obs.Verify();
    end;

    [Test]
    procedure SubstNoHash()
    begin
        Obs.Observe('a1', Format(StrSubstNo('#1','a')));
        Obs.Observe('a2', Format(StrSubstNo('#1 #2','a','b')));
        Obs.Observe('a3', Format(StrSubstNo('#2 #1','a','b')));
        Obs.Observe('a4', Format(StrSubstNo('#1#1','a')));
        Obs.Observe('a5', Format(StrSubstNo('#1###','a')));
        Obs.Observe('a6', Format(StrSubstNo('#1######','a')));
        Obs.Observe('a7', Format(StrSubstNo('#####1','a')));
        Obs.Observe('a8', Format(StrSubstNo('#1','abcdef')));
        Obs.Observe('a9', Format(StrSubstNo('#1###','abcdef')));
        Obs.Observe('a10', Format(StrSubstNo('#1###','ab')));
        Obs.Observe('a11', Format(StrSubstNo('x#1###y','ab')));
        Obs.Observe('a12', Format(StrSubstNo('#1###','1')));
        Obs.Observe('a13', Format(StrSubstNo('#1###',1)));
        Obs.Observe('a14', Format(StrSubstNo('#1####',12)));
        Obs.Observe('a15', Format(StrSubstNo('#1','')));
        Obs.Observe('a16', Format(StrSubstNo('#1','a','b')));
        Obs.Observe('a17', Format(StrSubstNo('#2','a')));
        Obs.Observe('a18', Format(StrSubstNo('#','a')));
        Obs.Observe('a19', Format(StrSubstNo('##','a')));
        Obs.Observe('a20', Format(StrSubstNo('#1 %1','a')));
        Obs.Observe('a21', Format(StrSubstNo('%1 #1','a')));
        Obs.Observe('a22', Format(StrSubstNo('#1###',1.5)));
        Obs.Observe('a23', Format(StrSubstNo('#1###',true)));
        Obs.Expect('a1', 'a ');
        Obs.Expect('a2', 'a  b ');
        Obs.Expect('a3', 'b  a ');
        Obs.Expect('a4', 'a  1');
        Obs.Expect('a5', 'a    ');
        Obs.Expect('a6', 'a       ');
        Obs.Expect('a7', 'a     ');
        Obs.Expect('a8', '**');
        Obs.Expect('a9', '*****');
        Obs.Expect('a10', 'ab   ');
        Obs.Expect('a11', 'xab   y');
        Obs.Expect('a12', '1    ');
        Obs.Expect('a13', '1    ');
        Obs.Expect('a14', '12    ');
        Obs.Expect('a15', '  ');
        Obs.Expect('a16', 'a ');
        Obs.Expect('a17', '#2');
        Obs.Expect('a18', '#');
        Obs.Expect('a19', '##');
        Obs.Expect('a20', 'a  a');
        Obs.Expect('a21', 'a a ');
        Obs.Expect('a22', '1.5  ');
        Obs.Expect('a23', 'Yes  ');
        Obs.Verify();
    end;

    [Test]
    procedure SubstNoTypes()
    begin
        Obs.Observe('a1', Format(StrSubstNo('%1',123)));
        Obs.Observe('a2', Format(StrSubstNo('%1',-1)));
        Obs.Observe('a3', Format(StrSubstNo('%1',1234567.891)));
        Obs.Observe('a4', Format(StrSubstNo('%1',0)));
        Obs.Observe('a5', Format(StrSubstNo('%1',1.0)));
        Obs.Observe('a6', Format(StrSubstNo('%1',false)));
        Obs.Observe('a7', Format(StrSubstNo('%1','  a  ')));
        Obs.Observe('a8', Format(StrSubstNo('%1',TLabel)));
        Obs.Observe('a9', Format(StrSubstNo('%1',CLabel)));
        Obs.Observe('a10', Format(StrSubstNo('%1',123456789012L)));
        Obs.Observe('a11', Format(StrSubstNo('%1',DMY2Date(1,1,2020))));
        Obs.Observe('a12', Format(StrSubstNo('%1',0T)));
        Obs.Observe('a13', Format(StrSubstNo('%1',0D)));
        Obs.Observe('a14', Format(StrSubstNo('%1',0DT)));
        Obs.Observe('a15', Format(StrSubstNo('%1','é')));
        Obs.Expect('a1', '123');
        Obs.Expect('a2', '-1');
        Obs.Expect('a3', '1,234,567.891');
        Obs.Expect('a4', '0');
        Obs.Expect('a5', '1');
        Obs.Expect('a6', 'No');
        Obs.Expect('a7', '  a  ');
        Obs.Expect('a8', 'Hello World');
        Obs.Expect('a9', 'abc');
        Obs.Expect('a10', '123456789012');
        Obs.Expect('a11', '01/01/20');
        Obs.Expect('a12', '');
        Obs.Expect('a13', '');
        Obs.Expect('a14', '');
        Obs.Expect('a15', 'é');
        Obs.Verify();
    end;

    [Test]
    procedure SubstNoLengthAndTargets()
    begin
        T := PadStr('',3000,'x');
        T2 := StrSubstNo('%1',T);
        Obs.Observe('len3000', Format(StrLen(T2)));
        T2 := StrSubstNo('%1%1',T);
        Obs.Observe('lendouble', Format(StrLen(T2)));
        T5 := StrSubstNo('%1','abc');
        Obs.Observe('t5', Format(T5));
        asserterror T5 := StrSubstNo('%1','abcdef');
        Obs.ObserveError('t5over');
        C5 := StrSubstNo('%1','ab');
        Obs.Observe('c5', Format(C5));
        asserterror C5 := StrSubstNo('%1%2','abc','def');
        Obs.ObserveError('c5over');
        C10 := StrSubstNo('%1 %2','a','b');
        Obs.Observe('c10', Format(C10));
        Obs.Observe('emptyfmt', Format(StrSubstNo('')));
        Obs.Observe('lenEmpty', Format(StrLen(StrSubstNo('%1',''))));
        Obs.Expect('len3000', '3000');
        Obs.Expect('lendouble', '6000');
        Obs.Expect('t5', 'abc');
        Obs.Expect('t5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('c5', 'AB');
        Obs.Expect('c5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcdef');
        Obs.Expect('c5over|code', 'StringLengthExceeded');
        Obs.Expect('c10', 'A B');
        Obs.Expect('emptyfmt', '');
        Obs.Expect('lenEmpty', '0');
        Obs.Verify();
    end;

    [Test]
    procedure SubstNoErrors()
    begin
        T := StrSubstNo('%1','a','b','c','d','e','f','g','h','i','j','k');
        Obs.Observe('tooMany', 'no error');
        Obs.Observe('tenOk', Format(StrSubstNo('%1','a','b','c','d','e','f','g','h','i','j')));
        T := StrSubstNo('%0','a');
        Obs.Observe('pctzero', 'no error');
        Obs.Observe('pct11', Format(StrSubstNo('%11','a')));
        Obs.Observe('pct12', Format(StrSubstNo('%1','a')));
        Obs.Expect('tooMany', 'no error');
        Obs.Expect('tenOk', 'a');
        Obs.Expect('pctzero', 'no error');
        Obs.Expect('pct11', '%11');
        Obs.Expect('pct12', 'a');
        Obs.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 59: a placeholder repeated with other placeholders between the
    // repeats (Learn: 'Test %1 %3 %1' gives 'Test 555 777 555'; an old forum thread reported '%1%2%1' failing).
    [Test]
    procedure LT_BU_StrSubstNo_RepeatedNonAdjacent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('learn example', StrSubstNo('Test %1 %3 %1', 555, 666, 777));
        Observer.Observe('%1%2%1', StrSubstNo('%1%2%1', 9, 0));
        Observer.Observe('%2%1%3%1%4%1', StrSubstNo('%2%1%3%1%4%1', ';', '1', '2', '3'));
        Observer.Observe('%3 only', StrSubstNo('%3-%3', 'a', 'b', 'c'));
        Observer.Observe('#1 form', StrSubstNo('#1 #2 #1', 'x', 'y'));
        Observer.Expect('learn example', 'Test 555 777 555');
        Observer.Expect('%1%2%1', '909');
        Observer.Expect('%2%1%3%1%4%1', '1;2;3;');
        Observer.Expect('%3 only', 'c-c');
        Observer.Expect('#1 form', 'x  y  x ');
        Observer.Verify();
    end;
}
