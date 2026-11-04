// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// IncStr forms, carry, errors.
// BC versions: 29 (27 and 28 by CI)

codeunit 70505 "LT TxB IncStr"
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
    procedure IncStrBasic()
    begin
        Obs.Observe('a1', Format(IncStr('1')));
        Obs.Observe('a2', Format(IncStr('9')));
        Obs.Observe('a3', Format(IncStr('99')));
        Obs.Observe('a4', Format(IncStr('009')));
        Obs.Observe('a5', Format(IncStr('0099')));
        Obs.Observe('a6', Format(IncStr('A1')));
        Obs.Observe('a7', Format(IncStr('A9')));
        Obs.Observe('a8', Format(IncStr('A99')));
        Obs.Observe('a9', Format(IncStr('A-001')));
        Obs.Observe('a10', Format(IncStr('A-009')));
        Obs.Observe('a11', Format(IncStr('1A')));
        Obs.Observe('a12', Format(IncStr('1A9')));
        Obs.Observe('a13', Format(IncStr('1-2-3')));
        Obs.Observe('a14', Format(IncStr('A01B02')));
        Obs.Observe('a15', Format(IncStr('00')));
        Obs.Observe('a16', Format(IncStr('0')));
        Obs.Observe('a17', Format(IncStr('abc9')));
        Obs.Observe('a18', Format(IncStr('Z999')));
        Obs.Observe('a19', Format(IncStr('a1b')));
        Obs.Observe('a20', Format(IncStr('999999999')));
        Obs.Observe('a21', Format(IncStr('9999999999')));
        Obs.Observe('a22', Format(IncStr('12345678901234567890')));
        Obs.Observe('a23', Format(IncStr('99999999999999999999')));
        Obs.Expect('a1', '2');
        Obs.Expect('a2', '10');
        Obs.Expect('a3', '100');
        Obs.Expect('a4', '010');
        Obs.Expect('a5', '0100');
        Obs.Expect('a6', 'A2');
        Obs.Expect('a7', 'A10');
        Obs.Expect('a8', 'A100');
        Obs.Expect('a9', 'A-002');
        Obs.Expect('a10', 'A-010');
        Obs.Expect('a11', '2A');
        Obs.Expect('a12', '1A10');
        Obs.Expect('a13', '1-2-4');
        Obs.Expect('a14', 'A01B03');
        Obs.Expect('a15', '01');
        Obs.Expect('a16', '1');
        Obs.Expect('a17', 'abc10');
        Obs.Expect('a18', 'Z1000');
        Obs.Expect('a19', 'a2b');
        Obs.Expect('a20', '1000000000');
        Obs.Expect('a21', '10000000000');
        Obs.Expect('a22', '12345678901234567891');
        Obs.Expect('a23', '100000000000000000000');
        Obs.Verify();
    end;

    [Test]
    procedure IncStrNoDigits()
    begin
        Obs.Observe('a1', Format(IncStr('')));
        Obs.Observe('a2', Format(IncStr(' ')));
        Obs.Observe('a3', Format(IncStr('A')));
        Obs.Observe('a4', Format(IncStr('ABC')));
        Obs.Observe('a5', Format(IncStr('-')));
        Obs.Observe('a6', Format(IncStr('日本')));
        Obs.Observe('a7', Format(IncStr('äö')));
        T := IncStr('');
        Obs.Observe('empty', 'no error');
        T := IncStr('ABC');
        Obs.Observe('nodigits', 'no error');
        T := IncStr(' ');
        Obs.Observe('blank', 'no error');
        Obs.Expect('a1', '');
        Obs.Expect('a2', '');
        Obs.Expect('a3', '');
        Obs.Expect('a4', '');
        Obs.Expect('a5', '');
        Obs.Expect('a6', '');
        Obs.Expect('a7', '');
        Obs.Expect('empty', 'no error');
        Obs.Expect('nodigits', 'no error');
        Obs.Expect('blank', 'no error');
        Obs.Verify();
    end;

    [Test]
    procedure IncStrWithBlanks()
    begin
        Obs.Observe('a1', Format(IncStr(' 1')));
        Obs.Observe('a2', Format(IncStr('1 ')));
        Obs.Observe('a3', Format(IncStr('A1 ')));
        Obs.Observe('a4', Format(IncStr('A 1')));
        Obs.Observe('a5', Format(IncStr(' 9')));
        Obs.Observe('a6', Format(IncStr('9 ')));
        Obs.Observe('a7', Format(StrLen(IncStr('9 '))));
        Obs.Observe('a8', Format(IncStr('A-9-')));
        Obs.Expect('a1', ' 2');
        Obs.Expect('a2', '2 ');
        Obs.Expect('a3', 'A2 ');
        Obs.Expect('a4', 'A 2');
        Obs.Expect('a5', ' 10');
        Obs.Expect('a6', '10 ');
        Obs.Expect('a7', '3');
        Obs.Expect('a8', 'A-10-');
        Obs.Verify();
    end;

    [Test]
    procedure IncStrIncrement()
    begin
        Obs.Observe('a1', Format(IncStr('1',0)));
        Obs.Observe('a2', Format(IncStr('1',1)));
        Obs.Observe('a3', Format(IncStr('1',2)));
        Obs.Observe('a4', Format(IncStr('1',10)));
        Obs.Observe('a5', Format(IncStr('9',1)));
        Obs.Observe('a6', Format(IncStr('9',2)));
        Obs.Observe('a7', Format(IncStr('A099',1)));
        Obs.Observe('a8', Format(IncStr('A099',2)));
        Obs.Observe('a9', Format(IncStr('A099',901)));
        Obs.Observe('a10', Format(IncStr('A099',900)));
        Obs.Observe('a11', Format(IncStr('5',-1)));
        Obs.Observe('a12', Format(IncStr('5',-5)));
        asserterror Obs.Observe('a13', Format(IncStr('5',-6)));
        Obs.ObserveError('af102');
        Obs.Observe('a14', Format(IncStr('A001',-1)));
        asserterror Obs.Observe('a15', Format(IncStr('A001',-2)));
        Obs.ObserveError('af105');
        Obs.Observe('a16', Format(IncStr('A010',-1)));
        Obs.Observe('a17', Format(IncStr('A100',-1)));
        Obs.Observe('a18', Format(IncStr('A100',-100)));
        asserterror Obs.Observe('a19', Format(IncStr('A100',-101)));
        Obs.ObserveError('af110');
        Obs.Observe('a20', Format(IncStr('001',-1)));
        Obs.Observe('a21', Format(IncStr('1',-1)));
        asserterror Obs.Observe('a22', Format(IncStr('0',-1)));
        Obs.ObserveError('af114');
        Obs.Observe('a23', Format(IncStr('10',-1)));
        Obs.Expect('a1', '1');
        Obs.Expect('a2', '2');
        Obs.Expect('a3', '3');
        Obs.Expect('a4', '11');
        Obs.Expect('a5', '10');
        Obs.Expect('a6', '11');
        Obs.Expect('a7', 'A100');
        Obs.Expect('a8', 'A101');
        Obs.Expect('a9', 'A1000');
        Obs.Expect('a10', 'A999');
        Obs.Expect('a11', '4');
        Obs.Expect('a12', '0');
        Obs.Expect('af102|text', 'The result of incrementing cannot be negative.');
        Obs.Expect('af102|code', 'InvalidOperation');
        Obs.Expect('a14', 'A000');
        Obs.Expect('af105|text', 'The result of incrementing cannot be negative.');
        Obs.Expect('af105|code', 'InvalidOperation');
        Obs.Expect('a16', 'A009');
        Obs.Expect('a17', 'A099');
        Obs.Expect('a18', 'A000');
        Obs.Expect('af110|text', 'The result of incrementing cannot be negative.');
        Obs.Expect('af110|code', 'InvalidOperation');
        Obs.Expect('a20', '000');
        Obs.Expect('a21', '0');
        Obs.Expect('af114|text', 'The result of incrementing cannot be negative.');
        Obs.Expect('af114|code', 'InvalidOperation');
        Obs.Expect('a23', '09');
        Obs.Verify();
    end;

    [Test]
    procedure IncStrIncrementErrors()
    begin
        T := IncStr('ABC',0);
        Obs.Observe('noDigits0', 'no error');
        T := IncStr('ABC',5);
        Obs.Observe('noDigits5', 'no error');
        asserterror T := IncStr('0',-1);
        Obs.ObserveError('neg');
        asserterror T := IncStr('A0',-1);
        Obs.ObserveError('negA');
        asserterror T := IncStr('A5',-1000);
        Obs.ObserveError('negbig');
        T := IncStr('1',2147483647);
        Obs.Observe('big', 'no error');
        asserterror T := IncStr('1',-2147483647);
        Obs.ObserveError('intmin');
        Obs.Observe('bigok', Format(IncStr('0',2147483647)));
        Obs.Observe('longnum', Format(IncStr('99999999999999999999',-1)));
        Obs.Expect('noDigits0', 'no error');
        Obs.Expect('noDigits5', 'no error');
        Obs.Expect('neg|text', 'The result of incrementing cannot be negative.');
        Obs.Expect('neg|code', 'InvalidOperation');
        Obs.Expect('negA|text', 'The result of incrementing cannot be negative.');
        Obs.Expect('negA|code', 'InvalidOperation');
        Obs.Expect('negbig|text', 'The result of incrementing cannot be negative.');
        Obs.Expect('negbig|code', 'InvalidOperation');
        Obs.Expect('big', 'no error');
        Obs.Expect('intmin|text', 'The result of incrementing cannot be negative.');
        Obs.Expect('intmin|code', 'InvalidOperation');
        Obs.Expect('bigok', '2147483647');
        Obs.Expect('longnum', '99999999999999999998');
        Obs.Verify();
    end;

    [Test]
    procedure IncStrTargets()
    begin
        T5 := IncStr('A99');
        Obs.Observe('t5', Format(T5));
        asserterror T5 := IncStr('A99999');
        Obs.ObserveError('t5over');
        C5 := IncStr('a99');
        Obs.Observe('c5', Format(C5));
        asserterror C5 := IncStr('ab999');
        Obs.ObserveError('c5over');
        C5 := IncStr('ab9');
        Obs.Observe('c5carry', Format(C5));
        C10 := IncStr('X-0009');
        Obs.Observe('c10', Format(C10));
        C5 := 'A09';
        C5 := IncStr(C5);
        Obs.Observe('c5var', Format(C5));
        C5 := IncStr(C5,10);
        Obs.Observe('c5var2', Format(C5));
        asserterror C5 := IncStr('A9999',1);
        Obs.ObserveError('c5overinc');
        Obs.Expect('t5', 'A100');
        Obs.Expect('t5over|text', 'The length of the string is 7, but it must be less than or equal to 5 characters. Value: A100000');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('c5', 'A100');
        Obs.Expect('c5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: ab1000');
        Obs.Expect('c5over|code', 'StringLengthExceeded');
        Obs.Expect('c5carry', 'AB10');
        Obs.Expect('c10', 'X-0010');
        Obs.Expect('c5var', 'A10');
        Obs.Expect('c5var2', 'A20');
        Obs.Expect('c5overinc|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: A10000');
        Obs.Expect('c5overinc|code', 'StringLengthExceeded');
        Obs.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 44: Learn says IncStr treats a decimal point as a separator and
    // increments only the last integer part ('a99.99b' becomes 'a99.100b').
    [Test]
    procedure LT_BU_IncStr_DecimalPoint()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('a99.99b', IncStr('a99.99b'));
        Observer.Observe('1.5', IncStr('1.5'));
        Observer.Observe('a99.99', IncStr('a99.99'));
        Observer.Observe('-1.5', IncStr('-1.5'));
        Observer.Observe('1.9', IncStr('1.9'));
        Observer.Observe('1,5', IncStr('1,5'));
        Observer.Observe('-1', IncStr('-1'));
        Observer.Observe('1.5 minus 1', IncStr('1.5', -1));
        Observer.Expect('a99.99b', 'a99.100b');
        Observer.Expect('1.5', '1.6');
        Observer.Expect('a99.99', 'a99.100');
        Observer.Expect('-1.5', '-1.6');
        Observer.Expect('1.9', '1.10');
        Observer.Expect('1,5', '1,6');
        Observer.Expect('-1', '-2');
        Observer.Expect('1.5 minus 1', '1.4');
        Observer.Verify();
    end;
}
