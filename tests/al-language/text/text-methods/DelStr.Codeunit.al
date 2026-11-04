// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// DelStr forms and errors.
// BC versions: 29 (27 and 28 by CI)

codeunit 70502 "LT TxB DelStr"
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
    procedure DelStrBasic()
    begin
        T := 'Hello World';
        Obs.Observe('a1', Format(DelStr(T,1)));
        Obs.Observe('a2', Format(DelStr(T,6)));
        Obs.Observe('a3', Format(DelStr(T,12)));
        Obs.Observe('a4', Format(DelStr(T,11)));
        Obs.Observe('a5', Format(DelStr(T,1,5)));
        Obs.Observe('a6', Format(DelStr(T,1,0)));
        Obs.Observe('a7', Format(DelStr(T,7,100)));
        Obs.Observe('a8', Format(DelStr(T,3,3)));
        Obs.Observe('a9', Format(DelStr(T,11,1)));
        Obs.Observe('a10', Format(DelStr(T,11,5)));
        Obs.Observe('a11', Format(DelStr(T,12,1)));
        Obs.Observe('a12', Format(DelStr(T,1,11)));
        Obs.Observe('a13', Format(DelStr(T,1,12)));
        Obs.Observe('a14', Format(DelStr('',1)));
        Obs.Observe('a15', Format(DelStr('',1,5)));
        Obs.Expect('a1', '');
        Obs.Expect('a2', 'Hello');
        Obs.Expect('a3', 'Hello World');
        Obs.Expect('a4', 'Hello Worl');
        Obs.Expect('a5', ' World');
        Obs.Expect('a6', 'Hello World');
        Obs.Expect('a7', 'Hello ');
        Obs.Expect('a8', 'He World');
        Obs.Expect('a9', 'Hello Worl');
        Obs.Expect('a10', 'Hello Worl');
        Obs.Expect('a11', 'Hello World');
        Obs.Expect('a12', '');
        Obs.Expect('a13', '');
        Obs.Expect('a14', '');
        Obs.Expect('a15', '');
        Obs.Verify();
    end;

    [Test]
    procedure DelStrErrors()
    begin
        T := 'Hello World';
        asserterror T2 := DelStr(T,0);
        Obs.ObserveError('pos0');
        asserterror T2 := DelStr(T,0,2);
        Obs.ObserveError('pos0len');
        asserterror T2 := DelStr(T,-1);
        Obs.ObserveError('posneg');
        asserterror T2 := DelStr(T,1,-1);
        Obs.ObserveError('lenneg');
        T2 := DelStr(T,13);
        Obs.Observe('posbeyond', 'no error');
        T2 := DelStr(T,13,1);
        Obs.Observe('posbeyondlen', 'no error');
        T2 := DelStr('',2);
        Obs.Observe('emptypos2', 'no error');
        asserterror T2 := DelStr('',0);
        Obs.ObserveError('emptypos0');
        T2 := DelStr(T,2147483647);
        Obs.Observe('posbig', 'no error');
        Obs.Expect('pos0|text', 'The value of DELSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2048.');
        Obs.Expect('pos0|code', 'OutsidePermittedRange');
        Obs.Expect('pos0len|text', 'The value of DELSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Obs.Expect('pos0len|code', 'OutsidePermittedRange');
        Obs.Expect('posneg|text', 'The value of DELSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2048.');
        Obs.Expect('posneg|code', 'OutsidePermittedRange');
        Obs.Expect('lenneg|text', 'The value of DELSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Obs.Expect('lenneg|code', 'OutsidePermittedRange');
        Obs.Expect('posbeyond', 'no error');
        Obs.Expect('posbeyondlen', 'no error');
        Obs.Expect('emptypos2', 'no error');
        Obs.Expect('emptypos0|text', 'The value of DELSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2048.');
        Obs.Expect('emptypos0|code', 'OutsidePermittedRange');
        Obs.Expect('posbig', 'no error');
        Obs.Verify();
    end;

    [Test]
    procedure DelStrTargets()
    begin
        T := 'Hello World';
        T5 := DelStr(T,6);
        Obs.Observe('t5', Format(T5));
        C5 := DelStr(T,6);
        Obs.Observe('c5', Format(C5));
        asserterror T5 := DelStr(T,1,1);
        Obs.ObserveError('t5over');
        asserterror C5 := DelStr(T,1,1);
        Obs.ObserveError('c5over');
        C5 := DelStr('  abc',1,2);
        Obs.Observe('trimmed', Format(C5));
        Obs.Observe('unicode', Format(DelStr('äöü',2,1)));
        Obs.Expect('t5', 'Hello');
        Obs.Expect('c5', 'HELLO');
        Obs.Expect('t5over|text', 'The length of the string is 10, but it must be less than or equal to 5 characters. Value: ello World');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('c5over|text', 'The length of the string is 10, but it must be less than or equal to 5 characters. Value: ello World');
        Obs.Expect('c5over|code', 'StringLengthExceeded');
        Obs.Expect('trimmed', 'ABC');
        Obs.Expect('unicode', 'äü');
        Obs.Verify();
    end;

    [Test]
    procedure DelStrDecimalPos1()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 2;
        Obs.Observe('d1_2', RunPos(D, R));
        D := 2.4;
        Obs.Observe('d1_2.4', RunPos(D, R));
        D := 2.5;
        Obs.Observe('d1_2.5', RunPos(D, R));
        D := 2.6;
        Obs.Observe('d1_2.6', RunPos(D, R));
        D := 0.5;
        Obs.Observe('d1_0.5', RunPos(D, R));
        D := -1.5;
        Obs.Observe('d1_-1.5', RunPos(D, R));
        Obs.Expect('d1_2', '[a]');
        Obs.Expect('d1_2.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.');
        Obs.Expect('d1_2.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('d1_2.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.6 to System.Int32.');
        Obs.Expect('d1_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Expect('d1_-1.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.');
        Obs.Verify();
    end;

    [Test]
    procedure DelStrDecimalPosLen1()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 2;
        D2 := 3;
        Obs.Observe('d2_2_3', RunPosLen(D, D2, R));
        D := 2;
        D2 := 3.4;
        Obs.Observe('d2_2_3.4', RunPosLen(D, D2, R));
        D := 2;
        D2 := 3.6;
        Obs.Observe('d2_2_3.6', RunPosLen(D, D2, R));
        D := 2.5;
        D2 := 3;
        Obs.Observe('d2_2.5_3', RunPosLen(D, D2, R));
        D := 2.5;
        D2 := 3.4;
        Obs.Observe('d2_2.5_3.4', RunPosLen(D, D2, R));
        D := 2.5;
        D2 := 3.6;
        Obs.Observe('d2_2.5_3.6', RunPosLen(D, D2, R));
        Obs.Expect('d2_2_3', '[aef]');
        Obs.Expect('d2_2_3.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.4 to System.Int32.');
        Obs.Expect('d2_2_3.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.6 to System.Int32.');
        Obs.Expect('d2_2.5_3', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('d2_2.5_3.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('d2_2.5_3.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryPos(Pos: Decimal; var Res: Text)
    begin
        Res := '[' + DelStr('abcdef', Pos) + ']';
    end;

    local procedure RunPos(Pos: Decimal; var Res: Text): Text
    begin
        ClearLastError();
        if TryPos(Pos, Res) then
            exit(Res);
        exit('ERR ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryPosLen(Pos: Decimal; Len: Decimal; var Res: Text)
    begin
        Res := '[' + DelStr('abcdef', Pos, Len) + ']';
    end;

    local procedure RunPosLen(Pos: Decimal; Len: Decimal; var Res: Text): Text
    begin
        ClearLastError();
        if TryPosLen(Pos, Len, Res) then
            exit(Res);
        exit('ERR ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

}
