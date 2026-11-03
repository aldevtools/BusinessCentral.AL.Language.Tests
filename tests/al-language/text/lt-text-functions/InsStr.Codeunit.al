// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// InsStr forms and errors.
// BC versions: 29 (27 and 28 by CI)

codeunit 70503 "LT TxB InsStr"
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
    procedure InsStrBasic()
    begin
        T := 'Hello World';
        Obs.Observe('a1', Format(InsStr(T,'X',1)));
        Obs.Observe('a2', Format(InsStr(T,'X',6)));
        Obs.Observe('a3', Format(InsStr(T,'X',11)));
        Obs.Observe('a4', Format(InsStr(T,'X',12)));
        Obs.Observe('a5', Format(InsStr(T,'X',13)));
        Obs.Observe('a6', Format(InsStr(T,'',3)));
        Obs.Observe('a7', Format(InsStr('','X',1)));
        Obs.Observe('a8', Format(InsStr('','X',2)));
        Obs.Observe('a9', Format(InsStr('','X',5)));
        Obs.Observe('a10', Format(InsStr(T,'ABC',100)));
        Obs.Observe('a11', Format(InsStr('ab','  ',2)));
        Obs.Observe('a12', Format(StrLen(InsStr('ab','  ',3))));
        Obs.Expect('a1', 'XHello World');
        Obs.Expect('a2', 'HelloX World');
        Obs.Expect('a3', 'Hello WorlXd');
        Obs.Expect('a4', 'Hello WorldX');
        Obs.Expect('a5', 'Hello WorldX');
        Obs.Expect('a6', 'Hello World');
        Obs.Expect('a7', 'X');
        Obs.Expect('a8', 'X');
        Obs.Expect('a9', 'X');
        Obs.Expect('a10', 'Hello WorldABC');
        Obs.Expect('a11', 'a  b');
        Obs.Expect('a12', '4');
        Obs.Verify();
    end;

    [Test]
    procedure InsStrErrors()
    begin
        T := 'Hello World';
        asserterror T2 := InsStr(T,'X',0);
        Obs.ObserveError('pos0');
        asserterror T2 := InsStr(T,'X',-1);
        Obs.ObserveError('posneg');
        asserterror T2 := InsStr('','X',0);
        Obs.ObserveError('emptypos0');
        T2 := InsStr(T,'X',2147483647);
        Obs.Observe('posbig', 'no error');
        T2 := InsStr('','X',2147483647);
        Obs.Observe('posbigempty', 'no error');
        Obs.Expect('pos0|text', 'The value of INSSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Obs.Expect('pos0|code', 'OutsidePermittedRange');
        Obs.Expect('posneg|text', 'The value of INSSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.');
        Obs.Expect('posneg|code', 'OutsidePermittedRange');
        Obs.Expect('emptypos0|text', 'The value of INSSTR parameter 3 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Obs.Expect('emptypos0|code', 'OutsidePermittedRange');
        Obs.Expect('posbig', 'no error');
        Obs.Expect('posbigempty', 'no error');
        Obs.Verify();
    end;

    [Test]
    procedure InsStrTargets()
    begin
        T := 'abc';
        T5 := InsStr(T,'XY',2);
        Obs.Observe('t5', Format(T5));
        asserterror T5 := InsStr(T,'XYZ',2);
        Obs.ObserveError('t5over');
        C5 := InsStr(T,'xy',2);
        Obs.Observe('c5', Format(C5));
        asserterror C5 := InsStr(T,'xyz',2);
        Obs.ObserveError('c5over');
        C5 := InsStr('ab',' ',3);
        Obs.Observe('c5trail', Format(C5));
        Obs.Observe('c5len', Format(StrLen(C5)));
        Obs.Observe('unicode', Format(InsStr('äü','ö',2)));
        Obs.Expect('t5', 'aXYbc');
        Obs.Expect('t5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: aXYZbc');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('c5', 'AXYBC');
        Obs.Expect('c5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: axyzbc');
        Obs.Expect('c5over|code', 'StringLengthExceeded');
        Obs.Expect('c5trail', 'AB');
        Obs.Expect('c5len', '2');
        Obs.Expect('unicode', 'äöü');
        Obs.Verify();
    end;

    [Test]
    procedure InsStrDecimalPos1()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 2;
        Obs.Observe('i_2', RunPos(D, R));
        D := 2.4;
        Obs.Observe('i_2.4', RunPos(D, R));
        D := 2.5;
        Obs.Observe('i_2.5', RunPos(D, R));
        D := 2.6;
        Obs.Observe('i_2.6', RunPos(D, R));
        D := 0.5;
        Obs.Observe('i_0.5', RunPos(D, R));
        D := -1.5;
        Obs.Observe('i_-1.5', RunPos(D, R));
        Obs.Expect('i_2', '[aXYbcdef]');
        Obs.Expect('i_2.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.');
        Obs.Expect('i_2.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('i_2.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.6 to System.Int32.');
        Obs.Expect('i_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Expect('i_-1.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryPos(Pos: Decimal; var Res: Text)
    begin
        Res := '[' + InsStr('abcdef', 'XY', Pos) + ']';
    end;

    local procedure RunPos(Pos: Decimal; var Res: Text): Text
    begin
        ClearLastError();
        if TryPos(Pos, Res) then
            exit(Res);
        exit('ERR ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

}
