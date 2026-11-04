// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// SelectStr forms and errors.
// BC versions: 29 (27 and 28 by CI)

codeunit 70506 "LT TxB SelectStr"
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
    procedure SelectStrBasic()
    begin
        Obs.Observe('a1', Format(SelectStr(1,'a,b,c')));
        Obs.Observe('a2', Format(SelectStr(2,'a,b,c')));
        Obs.Observe('a3', Format(SelectStr(3,'a,b,c')));
        Obs.Observe('a4', Format(SelectStr(1,'a')));
        Obs.Observe('a5', Format(SelectStr(1,'')));
        Obs.Observe('a6', Format(SelectStr(2,'a,')));
        Obs.Observe('a7', Format(SelectStr(1,',a')));
        Obs.Observe('a8', Format(SelectStr(2,',a')));
        Obs.Observe('a9', Format(SelectStr(2,'a,,c')));
        Obs.Observe('a10', Format(SelectStr(3,'a,,c')));
        Obs.Observe('a11', Format(SelectStr(2,'a, b ,c')));
        Obs.Observe('a12', Format(StrLen(SelectStr(2,'a, b ,c'))));
        Obs.Observe('a13', Format(SelectStr(2,'a;b,c;d')));
        Obs.Observe('a14', Format(SelectStr(1,'日,本')));
        Obs.Observe('a15', Format(SelectStr(2,'日,本')));
        Obs.Observe('a16', Format(SelectStr(3,'a,b,')));
        Obs.Observe('a17', Format(SelectStr(4,'a,b,,')));
        Obs.Observe('a18', Format(SelectStr(1,',')));
        Obs.Observe('a19', Format(SelectStr(2,',')));
        Obs.Expect('a1', 'a');
        Obs.Expect('a2', 'b');
        Obs.Expect('a3', 'c');
        Obs.Expect('a4', 'a');
        Obs.Expect('a5', '');
        Obs.Expect('a6', '');
        Obs.Expect('a7', '');
        Obs.Expect('a8', 'a');
        Obs.Expect('a9', '');
        Obs.Expect('a10', 'c');
        Obs.Expect('a11', ' b ');
        Obs.Expect('a12', '3');
        Obs.Expect('a13', 'c;d');
        Obs.Expect('a14', '日');
        Obs.Expect('a15', '本');
        Obs.Expect('a16', '');
        Obs.Expect('a17', '');
        Obs.Expect('a18', '');
        Obs.Expect('a19', '');
        Obs.Verify();
    end;

    [Test]
    procedure SelectStrErrors()
    begin
        asserterror T := SelectStr(0,'a,b,c');
        Obs.ObserveError('zero');
        asserterror T := SelectStr(-1,'a,b,c');
        Obs.ObserveError('neg');
        asserterror T := SelectStr(-1,'');
        Obs.ObserveError('negempty');
        asserterror T := SelectStr(4,'a,b,c');
        Obs.ObserveError('beyond');
        asserterror T := SelectStr(2,'a');
        Obs.ObserveError('beyondone');
        asserterror T := SelectStr(2,'');
        Obs.ObserveError('emptyfirst');
        asserterror T := SelectStr(0,'');
        Obs.ObserveError('zeroempty');
        asserterror T := SelectStr(2147483647,'a,b');
        Obs.ObserveError('big');
        asserterror T := SelectStr(-2147483647,'a,b');
        Obs.ObserveError('neg2');
        asserterror T := SelectStr(4,'a,b,');
        Obs.ObserveError('beyondtrail');
        Obs.Expect('zero|text', 'The SELECTSTR comma-string a,b,c does not contain a value for index 0.');
        Obs.Expect('zero|code', 'InvalidStringFormat');
        Obs.Expect('neg|text', 'The SELECTSTR comma-string a,b,c does not contain a value for index -1.');
        Obs.Expect('neg|code', 'InvalidStringFormat');
        Obs.Expect('negempty|text', 'The SELECTSTR comma-string  does not contain a value for index -1.');
        Obs.Expect('negempty|code', 'InvalidStringFormat');
        Obs.Expect('beyond|text', 'The SELECTSTR comma-string a,b,c does not contain a value for index 4.');
        Obs.Expect('beyond|code', 'InvalidStringFormat');
        Obs.Expect('beyondone|text', 'The SELECTSTR comma-string a does not contain a value for index 2.');
        Obs.Expect('beyondone|code', 'InvalidStringFormat');
        Obs.Expect('emptyfirst|text', 'The SELECTSTR comma-string  does not contain a value for index 2.');
        Obs.Expect('emptyfirst|code', 'InvalidStringFormat');
        Obs.Expect('zeroempty|text', 'The SELECTSTR comma-string  does not contain a value for index 0.');
        Obs.Expect('zeroempty|code', 'InvalidStringFormat');
        Obs.Expect('big|text', 'The SELECTSTR comma-string a,b does not contain a value for index 2147483647.');
        Obs.Expect('big|code', 'InvalidStringFormat');
        Obs.Expect('neg2|text', 'The SELECTSTR comma-string a,b does not contain a value for index -2147483647.');
        Obs.Expect('neg2|code', 'InvalidStringFormat');
        Obs.Expect('beyondtrail|text', 'The SELECTSTR comma-string a,b, does not contain a value for index 4.');
        Obs.Expect('beyondtrail|code', 'InvalidStringFormat');
        Obs.Verify();
    end;

    [Test]
    procedure SelectStrTargets()
    begin
        T := 'abc,defghi,j';
        T5 := SelectStr(1,T);
        Obs.Observe('t5', Format(T5));
        asserterror T5 := SelectStr(2,T);
        Obs.ObserveError('t5over');
        C5 := SelectStr(1,T);
        Obs.Observe('c5', Format(C5));
        C5 := SelectStr(3,T);
        Obs.Observe('c5j', Format(C5));
        asserterror C5 := SelectStr(2,T);
        Obs.ObserveError('c5over');
        Obs.Observe('fromlabel', Format(SelectStr(2,'x,y')));
        Obs.Expect('t5', 'abc');
        Obs.Expect('t5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: defghi');
        Obs.Expect('t5over|code', 'StringLengthExceeded');
        Obs.Expect('c5', 'ABC');
        Obs.Expect('c5j', 'J');
        Obs.Expect('c5over|text', 'The length of the string is 6, but it must be less than or equal to 5 characters. Value: defghi');
        Obs.Expect('c5over|code', 'StringLengthExceeded');
        Obs.Expect('fromlabel', 'y');
        Obs.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 48: Learn says SelectStr does not honor quotes ('a,b,"c,d",e' has
    // five elements and element 4 is 'd"') and that the string may be at most 391 characters long.
    [Test]
    procedure LT_BU_SelectStr_QuotesAndLength()
    var
        Observer: Codeunit "Probe Observer";
        Long: Text;
        R: Text;
    begin
        Observer.Observe('quoted 3', SelectStr(3, 'a,b,"c,d",e'));
        Observer.Observe('quoted 4', SelectStr(4, 'a,b,"c,d",e'));
        Observer.Observe('quoted 5', SelectStr(5, 'a,b,"c,d",e'));
        Observer.Observe('single quotes 3', SelectStr(3, 'a,b,''c,d'',e'));
        Long := PadStr('', 391, 'x');
        ClearLastError();
        if TrySelectStr(1, Long, R) then
            Observer.Observe('391 chars', Format(StrLen(R)))
        else
            Observer.Observe('391 chars', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Long := PadStr('', 392, 'x');
        ClearLastError();
        if TrySelectStr(1, Long, R) then
            Observer.Observe('392 chars', Format(StrLen(R)))
        else
            Observer.Observe('392 chars', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Long := PadStr('', 394, 'x') + ',' + 'tail';
        ClearLastError();
        if TrySelectStr(2, Long, R) then
            Observer.Observe('comma at 395 element 2', R)
        else
            Observer.Observe('comma at 395 element 2', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Long := PadStr('', 2000, 'y');
        ClearLastError();
        if TrySelectStr(1, Long, R) then
            Observer.Observe('2000 chars', Format(StrLen(R)))
        else
            Observer.Observe('2000 chars', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('quoted 3', '"c');
        Observer.Expect('quoted 4', 'd"');
        Observer.Expect('quoted 5', 'e');
        Observer.Expect('single quotes 3', '''c');
        Observer.Expect('391 chars', '391');
        Observer.Expect('392 chars', '392');
        Observer.Expect('comma at 395 element 2', 'tail');
        Observer.Expect('2000 chars', '2000');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySelectStr(Number: Integer; Value: Text; var R: Text)
    begin
        R := SelectStr(Number, Value);
    end;

    [Test]
    procedure SelectStrDecimalNum1()
    var
        D: Decimal;
        D2: Decimal;
        R: Text;
    begin
        D := 2;
        Obs.Observe('s_2', RunNum(D, R));
        D := 2.4;
        Obs.Observe('s_2.4', RunNum(D, R));
        D := 2.5;
        Obs.Observe('s_2.5', RunNum(D, R));
        D := 2.6;
        Obs.Observe('s_2.6', RunNum(D, R));
        D := 0.5;
        Obs.Observe('s_0.5', RunNum(D, R));
        D := -1.5;
        Obs.Observe('s_-1.5', RunNum(D, R));
        Obs.Expect('s_2', '[bb]');
        Obs.Expect('s_2.4', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.');
        Obs.Expect('s_2.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Obs.Expect('s_2.6', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.6 to System.Int32.');
        Obs.Expect('s_0.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Obs.Expect('s_-1.5', 'ERR ConversionCast: Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1.5 to System.Int32.');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryNum(Num: Decimal; var Res: Text)
    begin
        Res := '[' + SelectStr(Num, 'aa,bb,cc') + ']';
    end;

    local procedure RunNum(Num: Decimal; var Res: Text): Text
    begin
        ClearLastError();
        if TryNum(Num, Res) then
            exit(Res);
        exit('ERR ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

}
