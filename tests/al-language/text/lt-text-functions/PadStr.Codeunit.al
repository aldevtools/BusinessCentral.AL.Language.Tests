// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// PadStr forms and errors.
// BC versions: 29 (27 and 28 by CI)

codeunit 70504 "LT TxB PadStr"
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
    procedure PadStrBasic()
    begin
        Obs.Observe('a1', Format(PadStr('abc',6)));
        Obs.Observe('a2', Format(PadStr('abc',6,'x')));
        Obs.Observe('a3', Format(PadStr('abc',3)));
        Obs.Observe('a4', Format(PadStr('abc',2)));
        Obs.Observe('a5', Format(PadStr('abc',0)));
        Obs.Observe('a6', Format(PadStr('abc',1,'x')));
        Obs.Observe('a7', Format(PadStr('',3)));
        Obs.Observe('a8', Format(PadStr('',3,'x')));
        Obs.Observe('a9', Format(PadStr('',0)));
        asserterror Obs.Observe('a10', Format(PadStr('abc',6,'xy')));
        Obs.ObserveError('af37');
        asserterror Obs.Observe('a11', Format(PadStr('abc',6,'')));
        Obs.ObserveError('af39');
        asserterror Obs.Observe('a12', Format(PadStr('abc',-1)));
        Obs.ObserveError('af41');
        asserterror Obs.Observe('a13', Format(PadStr('abc',-5,'x')));
        Obs.ObserveError('af43');
        asserterror Obs.Observe('a14', Format(PadStr('',-1)));
        Obs.ObserveError('af45');
        Obs.Observe('a15', Format(StrLen(PadStr('abc',6))));
        Obs.Observe('a16', Format(StrLen(PadStr('abc',6,'x'))));
        asserterror Obs.Observe('a17', Format(StrLen(PadStr('abc',-1))));
        Obs.ObserveError('af49');
        asserterror Obs.Observe('a18', Format(PadStr('a',4,'bcd')));
        Obs.ObserveError('af51');
        Obs.Observe('a19', Format(PadStr('日',3,'本')));
        Obs.Observe('a20', Format(PadStr('abc',10,'0')));
        Obs.Expect('a1', 'abc   ');
        Obs.Expect('a2', 'abcxxx');
        Obs.Expect('a3', 'abc');
        Obs.Expect('a4', 'ab');
        Obs.Expect('a5', '');
        Obs.Expect('a6', 'a');
        Obs.Expect('a7', '   ');
        Obs.Expect('a8', 'xxx');
        Obs.Expect('a9', '');
        Obs.Expect('af37|text', 'The value of PADSTR parameter 3 is outside of the permitted range. The current value is: 2. The permitted range is: from 1 to 1.');
        Obs.Expect('af37|code', 'OutsidePermittedRange');
        Obs.Expect('af39|text', 'The value of PADSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 1.');
        Obs.Expect('af39|code', 'OutsidePermittedRange');
        Obs.Expect('af41|text', 'The value of PADSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Obs.Expect('af41|code', 'OutsidePermittedRange');
        Obs.Expect('af43|text', 'The value of PADSTR parameter 2 is outside of the permitted range. The current value is: -5. The permitted range is: from 0 to 2,147,483,647.');
        Obs.Expect('af43|code', 'OutsidePermittedRange');
        Obs.Expect('af45|text', 'The value of PADSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Obs.Expect('af45|code', 'OutsidePermittedRange');
        Obs.Expect('a15', '6');
        Obs.Expect('a16', '6');
        Obs.Expect('af49|text', 'The value of PADSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Obs.Expect('af49|code', 'OutsidePermittedRange');
        Obs.Expect('af51|text', 'The value of PADSTR parameter 3 is outside of the permitted range. The current value is: 3. The permitted range is: from 1 to 1.');
        Obs.Expect('af51|code', 'OutsidePermittedRange');
        Obs.Expect('a19', '日本本');
        Obs.Expect('a20', 'abc0000000');
        Obs.Verify();
    end;

    [Test]
    procedure PadStrTargets()
    begin
        T := 'abc';
        T5 := PadStr(T,5,'x');
        Obs.Observe('t5', Format(T5));
        asserterror T5 := PadStr(T,6,'x');
        Obs.ObserveError('t5over');
        C5 := PadStr(T,5,'x');
        Obs.Observe('c5', Format(C5));
        C5 := PadStr(T,5);
        Obs.Observe('c5blank', Format(C5));
        Obs.Observe('c5blanklen', Format(StrLen(C5)));
        asserterror C5 := PadStr(T,6,'x');
        Obs.ObserveError('c5over');
        asserterror T2 := PadStr('',1000,'ab');
        Obs.ObserveError('af67');
        Obs.Observe('long', Format(StrLen(T2)));
        Obs.Observe('longcopy', Format(CopyStr(T2,999,2)));
        C10 := PadStr('',10,'a');
        Obs.Observe('c10', Format(C10));
        Obs.Expect('t5', 'abcxx');
        Obs.Expect('t5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcxxx');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('c5', 'ABCXX');
        Obs.Expect('c5blank', 'ABC');
        Obs.Expect('c5blanklen', '3');
        Obs.Expect('c5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: abcxxx');
        Obs.Expect('c5over|code', 'StringLengthExceeded');
        Obs.Expect('af67|text', 'The value of PADSTR parameter 3 is outside of the permitted range. The current value is: 2. The permitted range is: from 1 to 1.');
        Obs.Expect('af67|code', 'OutsidePermittedRange');
        Obs.Expect('long', '0');
        Obs.Expect('longcopy', '');
        Obs.Expect('c10', 'AAAAAAAAAA');
        Obs.Verify();
    end;

    [Test]
    procedure PadStrDecimalLen1()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 3;
        Obs.Observe('p2_3', RunLen(D, R));
        D := 3.0;
        Obs.Observe('p2_3.0', RunLen(D, R));
        D := 3.4;
        Obs.Observe('p2_3.4', RunLen(D, R));
        D := 3.5;
        Obs.Observe('p2_3.5', RunLen(D, R));
        D := 3.6;
        Obs.Observe('p2_3.6', RunLen(D, R));
        D := -1.5;
        Obs.Observe('p2_-1.5', RunLen(D, R));
        D := 0.5;
        Obs.Observe('p2_0.5', RunLen(D, R));
        Obs.Expect('p2_3', '[ab ]');
        Obs.Expect('p2_3.0', '[ab ]');
        Obs.Expect('p2_3.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.4 to System.Int32.');
        Obs.Expect('p2_3.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.5 to System.Int32.');
        Obs.Expect('p2_3.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.6 to System.Int32.');
        Obs.Expect('p2_-1.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.');
        Obs.Expect('p2_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Verify();
    end;

    [Test]
    procedure PadStrDecimalFill1()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 3;
        Obs.Observe('p3_3', RunFill(D, R));
        D := 3.0;
        Obs.Observe('p3_3.0', RunFill(D, R));
        D := 3.4;
        Obs.Observe('p3_3.4', RunFill(D, R));
        D := 3.5;
        Obs.Observe('p3_3.5', RunFill(D, R));
        D := 3.6;
        Obs.Observe('p3_3.6', RunFill(D, R));
        D := -1.5;
        Obs.Observe('p3_-1.5', RunFill(D, R));
        D := 0.5;
        Obs.Observe('p3_0.5', RunFill(D, R));
        Obs.Expect('p3_3', '[abx]');
        Obs.Expect('p3_3.0', '[abx]');
        Obs.Expect('p3_3.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.4 to System.Int32.');
        Obs.Expect('p3_3.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.5 to System.Int32.');
        Obs.Expect('p3_3.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.6 to System.Int32.');
        Obs.Expect('p3_-1.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.');
        Obs.Expect('p3_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryLen(Len: Decimal; var Res: Text)
    begin
        Res := '[' + PadStr('ab', Len, ' ') + ']';
    end;

    local procedure RunLen(Len: Decimal; var Res: Text): Text
    begin
        ClearLastError();
        if TryLen(Len, Res) then
            exit(Res);
        exit('ERR ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryFill(Len: Decimal; var Res: Text)
    begin
        Res := '[' + PadStr('ab', Len, 'x') + ']';
    end;

    local procedure RunFill(Len: Decimal; var Res: Text): Text
    begin
        ClearLastError();
        if TryFill(Len, Res) then
            exit(Res);
        exit('ERR ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

}
