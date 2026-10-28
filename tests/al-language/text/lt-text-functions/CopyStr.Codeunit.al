// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// CopyStr forms, ranges, negative, targets.
// BC versions: 29 (27 and 28 by CI)

codeunit 70501 "LT TxB CopyStr"
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
    procedure CopyStrTwoArgs()
    begin
        T := 'Hello World';
        Obs.Observe('a1', Format(CopyStr(T,1)));
        Obs.Observe('a2', Format(CopyStr(T,7)));
        Obs.Observe('a3', Format(CopyStr(T,11)));
        Obs.Observe('a4', Format(CopyStr(T,12)));
        Obs.Observe('a5', Format(CopyStr(T,13)));
        Obs.Observe('a6', Format(CopyStr(T,100)));
        Obs.Observe('a7', Format(CopyStr('',1)));
        Obs.Observe('a8', Format(CopyStr('',2)));
        Obs.Observe('a9', Format(CopyStr(T,1,0)));
        Obs.Expect('a1', 'Hello World');
        Obs.Expect('a2', 'World');
        Obs.Expect('a3', 'd');
        Obs.Expect('a4', '');
        Obs.Expect('a5', '');
        Obs.Expect('a6', '');
        Obs.Expect('a7', '');
        Obs.Expect('a8', '');
        Obs.Expect('a9', '');
        Obs.Verify();
    end;

    [Test]
    procedure CopyStrThreeArgs()
    begin
        T := 'Hello World';
        Obs.Observe('a1', Format(CopyStr(T,1,5)));
        Obs.Observe('a2', Format(CopyStr(T,7,5)));
        Obs.Observe('a3', Format(CopyStr(T,7,100)));
        Obs.Observe('a4', Format(CopyStr(T,1,11)));
        Obs.Observe('a5', Format(CopyStr(T,1,12)));
        Obs.Observe('a6', Format(CopyStr(T,11,1)));
        Obs.Observe('a7', Format(CopyStr(T,11,2)));
        Obs.Observe('a8', Format(CopyStr(T,12,1)));
        Obs.Observe('a9', Format(CopyStr(T,2,0)));
        Obs.Observe('a10', Format(CopyStr(T,5,1)));
        Obs.Observe('a11', Format(CopyStr(T,3,3)));
        Obs.Expect('a1', 'Hello');
        Obs.Expect('a2', 'World');
        Obs.Expect('a3', 'World');
        Obs.Expect('a4', 'Hello World');
        Obs.Expect('a5', 'Hello World');
        Obs.Expect('a6', 'd');
        Obs.Expect('a7', 'd');
        Obs.Expect('a8', '');
        Obs.Expect('a9', '');
        Obs.Expect('a10', 'o');
        Obs.Expect('a11', 'llo');
        Obs.Verify();
    end;

    [Test]
    procedure CopyStrErrors()
    begin
        T := 'Hello World';
        asserterror T2 := CopyStr(T,0);
        Obs.ObserveError('pos0');
        asserterror T2 := CopyStr(T,0,3);
        Obs.ObserveError('pos0len');
        asserterror T2 := CopyStr(T,-1);
        Obs.ObserveError('posneg');
        asserterror T2 := CopyStr(T,-1,3);
        Obs.ObserveError('posneglen');
        asserterror T2 := CopyStr(T,1,-1);
        Obs.ObserveError('lenneg');
        asserterror T2 := CopyStr(T,3,-5);
        Obs.ObserveError('lenneg5');
        asserterror T2 := CopyStr('',0);
        Obs.ObserveError('emptypos0');
        asserterror T2 := CopyStr('',1,-1);
        Obs.ObserveError('emptylenneg');
        T2 := CopyStr(T,1,2147483647);
        Obs.Observe('lenbig', 'no error');
        asserterror Obs.Observe('lenbigok', Format(CopyStr(T,2,2147483647)));
        Obs.ObserveError('af81');
        T2 := CopyStr(T,2147483647);
        Obs.Observe('posmax', 'no error');
        asserterror T2 := CopyStr(T,-2147483647);
        Obs.ObserveError('posmin');
        Obs.Expect('pos0|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2048.');
        Obs.Expect('pos0|code', 'OutsidePermittedRange');
        Obs.Expect('pos0len|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Obs.Expect('pos0len|code', 'OutsidePermittedRange');
        Obs.Expect('posneg|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2048.');
        Obs.Expect('posneg|code', 'OutsidePermittedRange');
        Obs.Expect('posneglen|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 2,147,483,647.');
        Obs.Expect('posneglen|code', 'OutsidePermittedRange');
        Obs.Expect('lenneg|text', 'The value of COPYSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Obs.Expect('lenneg|code', 'OutsidePermittedRange');
        Obs.Expect('lenneg5|text', 'The value of COPYSTR parameter 3 is outside of the permitted range. The current value is: -5. The permitted range is: from 0 to 2,147,483,647.');
        Obs.Expect('lenneg5|code', 'OutsidePermittedRange');
        Obs.Expect('emptypos0|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2048.');
        Obs.Expect('emptypos0|code', 'OutsidePermittedRange');
        Obs.Expect('emptylenneg|text', 'The value of COPYSTR parameter 3 is outside of the permitted range. The current value is: -1. The permitted range is: from 0 to 2,147,483,647.');
        Obs.Expect('emptylenneg|code', 'OutsidePermittedRange');
        Obs.Expect('lenbig', 'no error');
        Obs.Expect('af81|text', 'The value of COPYSTR parameter 3 is outside of the permitted range. The current value is: 2,147,483,647. The permitted range is: from 0 to 2,147,483,646.');
        Obs.Expect('af81|code', 'OutsidePermittedRange');
        Obs.Expect('posmax', 'no error');
        Obs.Expect('posmin|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: -2147483647. The permitted range is: from 1 to 2048.');
        Obs.Expect('posmin|code', 'OutsidePermittedRange');
        Obs.Verify();
    end;





    [Test]
    procedure CopyStrTargets()
    begin
        T := 'Hello World';
        T5 := CopyStr(T,1,5);
        Obs.Observe('t5', Format(T5));
        C5 := CopyStr(T,7,5);
        Obs.Observe('c5', Format(C5));
        C5 := CopyStr(T,1,3);
        Obs.Observe('c5short', Format(C5));
        C10 := CopyStr('  ab cd  ',1);
        Obs.Observe('c10blank', Format(C10));
        Obs.Observe('c10len', Format(StrLen(C10)));
        asserterror T5 := CopyStr(T,1,6);
        Obs.ObserveError('t5over');
        asserterror C5 := CopyStr(T,1);
        Obs.ObserveError('c5over');
        T5 := '';
        T5 := CopyStr(T,1,MaxStrLen(T5));
        Obs.Observe('maxcopy', Format(T5));
        C5 := CopyStr(T,1,MaxStrLen(C5));
        Obs.Observe('maxcopyc', Format(C5));
        Obs.Observe('fromlabel', Format(CopyStr(TLabel,7)));
        Obs.Observe('fromlabelc', Format(CopyStr(CLabel,2,1)));
        Obs.Expect('t5', 'Hello');
        Obs.Expect('c5', 'WORLD');
        Obs.Expect('c5short', 'HEL');
        Obs.Expect('c10blank', 'AB CD');
        Obs.Expect('c10len', '5');
        Obs.Expect('t5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: Hello ');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('c5over|text', 'The length of the string is 11, but it must be less than or equal to 5 characters. Value: Hello World');
        Obs.Expect('c5over|code', 'StringLengthExceeded');
        Obs.Expect('maxcopy', 'Hello');
        Obs.Expect('maxcopyc', 'HELLO');
        Obs.Expect('fromlabel', 'World');
        Obs.Expect('fromlabelc', 'b');
        Obs.Verify();
    end;

    [Test]
    procedure CopyStrUnicodeAndBlanks()
    begin
        Obs.Observe('a1', Format(CopyStr('äöüß',2,2)));
        Obs.Observe('a2', Format(CopyStr('日本語',2)));
        Obs.Observe('a3', Format(CopyStr('  a  ',1,2)));
        Obs.Observe('a4', Format(CopyStr('  a  ',4)));
        Obs.Observe('a5', Format(StrLen(CopyStr('  a  ',4))));
        Obs.Observe('a6', Format(CopyStr('abc',2,1)+CopyStr('abc',1,1)));
        Obs.Observe('a7', Format(CopyStr(UpperCase('abc'),2)));
        Obs.Observe('a8', Format(CopyStr(Format(123456),3,2)));
        Obs.Expect('a1', 'öü');
        Obs.Expect('a2', '本語');
        Obs.Expect('a3', '  ');
        Obs.Expect('a4', '  ');
        Obs.Expect('a5', '2');
        Obs.Expect('a6', 'ba');
        Obs.Expect('a7', 'BC');
        Obs.Expect('a8', '34');
        Obs.Verify();
    end;

    [Test]
    procedure CopyStrDecimalPos1()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 3;
        Obs.Observe('c1_3', RunPos(D, R));
        D := 3.0;
        Obs.Observe('c1_3.0', RunPos(D, R));
        D := 3.4;
        Obs.Observe('c1_3.4', RunPos(D, R));
        D := 3.5;
        Obs.Observe('c1_3.5', RunPos(D, R));
        D := 3.6;
        Obs.Observe('c1_3.6', RunPos(D, R));
        D := -1.5;
        Obs.Observe('c1_-1.5', RunPos(D, R));
        D := 0.5;
        Obs.Observe('c1_0.5', RunPos(D, R));
        Obs.Expect('c1_3', '[cdef]');
        Obs.Expect('c1_3.0', '[cdef]');
        Obs.Expect('c1_3.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.4 to System.Int32.');
        Obs.Expect('c1_3.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.5 to System.Int32.');
        Obs.Expect('c1_3.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.6 to System.Int32.');
        Obs.Expect('c1_-1.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.');
        Obs.Expect('c1_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Verify();
    end;

    [Test]
    procedure CopyStrDecimalPosLen1()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 2;
        D2 := 3;
        Obs.Observe('c2_2_3', RunPosLen(D, D2, R));
        D := 2;
        D2 := 3.4;
        Obs.Observe('c2_2_3.4', RunPosLen(D, D2, R));
        D := 2;
        D2 := 3.5;
        Obs.Observe('c2_2_3.5', RunPosLen(D, D2, R));
        D := 2;
        D2 := 3.6;
        Obs.Observe('c2_2_3.6', RunPosLen(D, D2, R));
        D := 2;
        D2 := 0.5;
        Obs.Observe('c2_2_0.5', RunPosLen(D, D2, R));
        D := 2.5;
        D2 := 3;
        Obs.Observe('c2_2.5_3', RunPosLen(D, D2, R));
        D := 2.5;
        D2 := 3.4;
        Obs.Observe('c2_2.5_3.4', RunPosLen(D, D2, R));
        D := 2.5;
        D2 := 3.5;
        Obs.Observe('c2_2.5_3.5', RunPosLen(D, D2, R));
        D := 2.5;
        D2 := 3.6;
        Obs.Observe('c2_2.5_3.6', RunPosLen(D, D2, R));
        D := 2.5;
        D2 := 0.5;
        Obs.Observe('c2_2.5_0.5', RunPosLen(D, D2, R));
        D := 0.5;
        D2 := 3;
        Obs.Observe('c2_0.5_3', RunPosLen(D, D2, R));
        D := 0.5;
        D2 := 3.4;
        Obs.Observe('c2_0.5_3.4', RunPosLen(D, D2, R));
        Obs.Expect('c2_2_3', '[bcd]');
        Obs.Expect('c2_2_3.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.4 to System.Int32.');
        Obs.Expect('c2_2_3.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.5 to System.Int32.');
        Obs.Expect('c2_2_3.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.6 to System.Int32.');
        Obs.Expect('c2_2_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Expect('c2_2.5_3', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('c2_2.5_3.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('c2_2.5_3.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('c2_2.5_3.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('c2_2.5_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('c2_0.5_3', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Expect('c2_0.5_3.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Verify();
    end;

    [Test]
    procedure CopyStrDecimalPosLen2()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 0.5;
        D2 := 3.5;
        Obs.Observe('c2_0.5_3.5', RunPosLen(D, D2, R));
        D := 0.5;
        D2 := 3.6;
        Obs.Observe('c2_0.5_3.6', RunPosLen(D, D2, R));
        D := 0.5;
        D2 := 0.5;
        Obs.Observe('c2_0.5_0.5', RunPosLen(D, D2, R));
        Obs.Expect('c2_0.5_3.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Expect('c2_0.5_3.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Expect('c2_0.5_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryPos(Pos: Decimal; var Res: Text)
    begin
        Res := '[' + CopyStr('abcdef', Pos) + ']';
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
        Res := '[' + CopyStr('abcdef', Pos, Len) + ']';
    end;

    local procedure RunPosLen(Pos: Decimal; Len: Decimal; var Res: Text): Text
    begin
        ClearLastError();
        if TryPosLen(Pos, Len, Res) then
            exit(Res);
        exit('ERR ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

    [Test]
    procedure CopyStrDecimalLiteral()
    var
        T: Text;
    begin
        T := CopyStr('abcdef', 2.0, 3.0);
        Obs.Observe('whole', '[' + T + ']');
        asserterror T := CopyStr('abcdef', 2.4, 3);
        Obs.ObserveError('e0');
        asserterror T := CopyStr('abcdef', 2, 3.5);
        Obs.ObserveError('e1');
        asserterror T := CopyStr('abcdef', 0.5);
        Obs.ObserveError('e2');
        Obs.Expect('whole', '[bcd]');
        Obs.Expect('e0|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.');
        Obs.Expect('e0|code', 'ConversionCast');
        Obs.Expect('e1|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.5 to System.Int32.');
        Obs.Expect('e1|code', 'ConversionCast');
        Obs.Expect('e2|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Expect('e2|code', 'ConversionCast');
        Obs.Verify();
    end;

}
