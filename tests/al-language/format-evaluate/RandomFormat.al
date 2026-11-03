// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Random, Randomize, SetSeed relations; Format and Evaluate of every type.
// BC versions: 29 (27 and 28 by CI)

codeunit 72508 "LT SyT Random"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Random_Range()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        V: Integer;
        Min: Integer;
        Max: Integer;
    begin
        Min := 1000;
        Max := -1;
        for i := 1 to 300 do begin
            V := Random(10);
            if V < Min then
                Min := V;
            if V > Max then
                Max := V;
        end;
        Observer.Observe('min >= 1', Format(Min >= 1));
        Observer.Observe('max <= 10', Format(Max <= 10));
        Observer.Observe('Random(1)', Format(Random(1)));
        Observer.Observe('Random(1) again', Format(Random(1)));
        Observer.Expect('min >= 1', 'Yes');
        Observer.Expect('max <= 10', 'Yes');
        Observer.Expect('Random(1)', '1');
        Observer.Expect('Random(1) again', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Random_InvalidRange()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := Random(0);
        Observer.Observe('Random 0', 'no error');
        V := Random(-5);
        Observer.Observe('Random -5', 'no error');
        Observer.Observe('Random(2147483647) >= 1', Format(Random(2147483647) >= 1));
        Observer.Expect('Random 0', 'no error');
        Observer.Expect('Random -5', 'no error');
        Observer.Expect('Random(2147483647) >= 1', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Randomize_SameSeed_SameSequence()
    var
        Observer: Codeunit "Probe Observer";
        A: array[5] of Integer;
        B: array[5] of Integer;
        i: Integer;
        Same: Boolean;
    begin
        Randomize(42);
        for i := 1 to 5 do
            A[i] := Random(1000000);
        Randomize(42);
        for i := 1 to 5 do
            B[i] := Random(1000000);
        Same := true;
        for i := 1 to 5 do
            if A[i] <> B[i] then
                Same := false;
        Observer.Observe('same sequence', Format(Same));
        Randomize(43);
        Same := true;
        for i := 1 to 5 do
            if Random(1000000) <> A[i] then
                Same := false;
        Observer.Observe('other seed same sequence', Format(Same));
        Observer.Expect('same sequence', 'Yes');
        Observer.Expect('other seed same sequence', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Randomize_Zero_And_Negative()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
    begin
        Randomize(0);
        A := Random(1000000);
        Randomize(0);
        B := Random(1000000);
        Observer.Observe('seed 0 equal', Format(A = B));
        Randomize(-1);
        A := Random(1000000);
        Randomize(-1);
        B := Random(1000000);
        Observer.Observe('seed -1 equal', Format(A = B));
        Randomize(2147483647);
        A := Random(1000000);
        Randomize(2147483647);
        B := Random(1000000);
        Observer.Observe('seed max equal', Format(A = B));
        Observer.Expect('seed 0 equal', 'Yes');
        Observer.Expect('seed -1 equal', 'Yes');
        Observer.Expect('seed max equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Random_Spread()
    var
        Observer: Codeunit "Probe Observer";
        Seen: Dictionary of [Integer, Boolean];
        i: Integer;
    begin
        Randomize(5);
        for i := 1 to 200 do
            Seen.Set(Random(3), true);
        Observer.Observe('distinct values', Format(Seen.Count()));
        Observer.Observe('has 1', Format(Seen.ContainsKey(1)));
        Observer.Observe('has 2', Format(Seen.ContainsKey(2)));
        Observer.Observe('has 3', Format(Seen.ContainsKey(3)));
        Observer.Observe('has 0', Format(Seen.ContainsKey(0)));
        Observer.Observe('has 4', Format(Seen.ContainsKey(4)));
        Observer.Expect('distinct values', '3');
        Observer.Expect('has 1', 'Yes');
        Observer.Expect('has 2', 'Yes');
        Observer.Expect('has 3', 'Yes');
        Observer.Expect('has 0', 'No');
        Observer.Expect('has 4', 'No');
        Observer.Verify();
    end;
}

codeunit 72509 "LT SyT Format Basic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Format_Integer()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 1234567;
        Observer.Observe('default', Format(I));
        Observer.Observe('0', Format(I, 0));
        Observer.Observe('0 neg', Format(-I, 0));
        Observer.Observe('1', Format(I, 0, 0));
        Observer.Observe('len 3', Format(I, 3));
        Observer.Observe('len 10', Format(I, 10));
        Observer.Observe('len -10', Format(I, -10));
        Observer.Observe('<Sign><Integer>', Format(I, 0, '<Sign><Integer>'));
        Observer.Observe('<Sign,1><Integer>', Format(I, 0, '<Sign,1><Integer>'));
        Observer.Observe('<Integer Thousand>', Format(I, 0, '<Integer Thousand>'));
        asserterror Observer.Observe('<Integer,10,0>', Format(I, 0, '<Integer,10,0>'));
        Observer.ObserveError('af148');
        Observer.Observe('<Integer,10><Filler Character,0>', Format(I, 0, '<Integer,10><Filler Character,0>'));
        Observer.Observe('<Integer,3>', Format(I, 0, '<Integer,3>'));
        Observer.Observe('<Precision,2:2><Standard Format,0>', Format(I, 0, '<Precision,2:2><Standard Format,0>'));
        Observer.Observe('<Standard Format,1>', Format(I, 0, '<Standard Format,1>'));
        Observer.Observe('<Standard Format,2>', Format(I, 0, '<Standard Format,2>'));
        Observer.Observe('<Standard Format,9>', Format(I, 0, '<Standard Format,9>'));
        Observer.Observe('format 9 arg', Format(I, 0, 9));
        Observer.Observe('format 1 arg', Format(I, 0, 1));
        Observer.Observe('format 2 arg', Format(I, 0, 2));
        Observer.Observe('min', Format(-2147483647 - 1));
        Observer.Observe('max', Format(2147483647));
        Observer.Expect('default', '1234567');
        Observer.Expect('0', '1234567');
        Observer.Expect('0 neg', '-1234567');
        Observer.Expect('1', '1234567');
        Observer.Expect('len 3', '123');
        Observer.Expect('len 10', '   1234567');
        Observer.Expect('len -10', '1234567');
        Observer.Expect('<Sign><Integer>', '1234567');
        Observer.Expect('<Sign,1><Integer>', ' 1234567');
        Observer.Expect('<Integer Thousand>', '1,234,567');
        Observer.Expect('af148|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Integer,10,0>');
        Observer.Expect('af148|code', 'InvalidFormatString');
        Observer.Expect('<Integer,10><Filler Character,0>', '0001234567');
        Observer.Expect('<Integer,3>', '***');
        Observer.Expect('<Precision,2:2><Standard Format,0>', '1234567');
        Observer.Expect('<Standard Format,1>', '1234567');
        Observer.Expect('<Standard Format,2>', '1234567');
        Observer.Expect('<Standard Format,9>', '1234567');
        Observer.Expect('format 9 arg', '1234567');
        Observer.Expect('format 1 arg', '1234567');
        Observer.Expect('format 2 arg', '1234567');
        Observer.Expect('min', '-2147483648');
        Observer.Expect('max', '2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 1234567.891;
        Observer.Observe('default', Format(D));
        Observer.Observe('0', Format(D, 0, 0));
        Observer.Observe('1', Format(D, 0, 1));
        Observer.Observe('2', Format(D, 0, 2));
        Observer.Observe('9', Format(D, 0, 9));
        Observer.Observe('<Precision,2:2>', Format(D, 0, '<Precision,2:2><Standard Format,0>'));
        Observer.Observe('<Precision,0:0>', Format(D, 0, '<Precision,0:0><Standard Format,0>'));
        Observer.Observe('<Precision,4:6>', Format(D, 0, '<Precision,4:6><Standard Format,0>'));
        Observer.Observe('<Integer><Decimals>', Format(D, 0, '<Integer><Decimals>'));
        Observer.Observe('<Integer Thousand><Decimals,3>', Format(D, 0, '<Integer Thousand><Decimals,3>'));
        Observer.Observe('<Sign><Integer><Decimals>', Format(-D, 0, '<Sign><Integer><Decimals>'));
        Observer.Observe('<Sign,1>', Format(-D, 0, '<Sign,1><Integer><Decimals>'));
        Observer.Observe('<Sign,2>', Format(-D, 0, '<Sign,2><Integer><Decimals>'));
        Observer.Observe('<Sign,3>', Format(-D, 0, '<Sign,3><Integer><Decimals>'));
        Observer.Observe('zero', Format(0.0));
        Observer.Observe('zero 9', Format(0.0, 0, 9));
        Observer.Observe('0.1', Format(0.1));
        Observer.Observe('-0.1', Format(-0.1));
        Observer.Observe('1e-5', Format(0.00001));
        Observer.Observe('1e-5 9', Format(0.00001, 0, 9));
        asserterror Observer.Observe('big', Format(123456789012345678.123456789));
        Observer.ObserveError('af191');
        asserterror Observer.Observe('big 9', Format(123456789012345678.123456789, 0, 9));
        Observer.ObserveError('af193');
        Observer.Observe('len 8', Format(D, 8));
        Observer.Observe('len 20', Format(D, 20));
        Observer.Expect('default', '1,234,567.891');
        Observer.Expect('0', '1,234,567.891');
        Observer.Expect('1', '1234567.891');
        Observer.Expect('2', '1234567.891');
        Observer.Expect('9', '1234567.891');
        Observer.Expect('<Precision,2:2>', '1,234,567.89');
        Observer.Expect('<Precision,0:0>', '1,234,568');
        Observer.Expect('<Precision,4:6>', '1,234,567.8910');
        Observer.Expect('<Integer><Decimals>', '1234567.891');
        Observer.Expect('<Integer Thousand><Decimals,3>', '1,234,567***');
        Observer.Expect('<Sign><Integer><Decimals>', '-1234567.891');
        Observer.Expect('<Sign,1>', '-1234567.891');
        Observer.Expect('<Sign,2>', ' -1234567.891');
        Observer.Expect('<Sign,3>', '  -1234567.891');
        Observer.Expect('zero', '0');
        Observer.Expect('zero 9', '0');
        Observer.Expect('0.1', '0.1');
        Observer.Expect('-0.1', '-0.1');
        Observer.Expect('1e-5', '0.00001');
        Observer.Expect('1e-5 9', '0.00001');
        Observer.Expect('af191|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 123,456,789,012,345,678. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af191|code', 'OutsidePermittedRange');
        Observer.Expect('af193|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 123,456,789,012,345,678. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af193|code', 'OutsidePermittedRange');
        Observer.Expect('len 8', '1,234,56');
        Observer.Expect('len 20', '       1,234,567.891');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Boolean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('true', Format(true));
        Observer.Observe('false', Format(false));
        Observer.Observe('true 0', Format(true, 0, 0));
        Observer.Observe('true 1', Format(true, 0, 1));
        Observer.Observe('true 2', Format(true, 0, 2));
        Observer.Observe('true 9', Format(true, 0, 9));
        Observer.Observe('false 9', Format(false, 0, 9));
        Observer.Observe('false 1', Format(false, 0, 1));
        Observer.Observe('true len 2', Format(true, 2));
        Observer.Observe('true len 10', Format(true, 10));
        Observer.Observe('true <Standard Format,0>', Format(true, 0, '<Standard Format,0>'));
        Observer.Observe('true <Standard Format,1>', Format(true, 0, '<Standard Format,1>'));
        Observer.Observe('true text', Format(true, 0, 'x'));
        Observer.Expect('true', 'Yes');
        Observer.Expect('false', 'No');
        Observer.Expect('true 0', 'Yes');
        Observer.Expect('true 1', 'Yes');
        Observer.Expect('true 2', '1');
        Observer.Expect('true 9', 'true');
        Observer.Expect('false 9', 'false');
        Observer.Expect('false 1', 'No');
        Observer.Expect('true len 2', 'Ye');
        Observer.Expect('true len 10', 'Yes       ');
        Observer.Expect('true <Standard Format,0>', 'Yes');
        Observer.Expect('true <Standard Format,1>', 'Yes');
        Observer.Expect('true text', 'x');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Text_Code_Char()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[10];
        T: Text;
        Ch: Char;
    begin
        C := 'abc';
        T := 'Hello';
        Ch := 65;
        Observer.Observe('text', Format(T));
        Observer.Observe('text len 3', Format(T, 3));
        Observer.Observe('text len 10', Format(T, 10));
        Observer.Observe('text len -10', Format(T, -10));
        Observer.Observe('text 9', Format(T, 0, 9));
        Observer.Observe('text 1', Format(T, 0, 1));
        Observer.Observe('text 2', Format(T, 0, 2));
        Observer.Observe('empty', Format(''));
        Observer.Observe('empty len 5', Format('', 5));
        Observer.Observe('code', Format(C));
        Observer.Observe('code 9', Format(C, 0, 9));
        Observer.Observe('char', Format(Ch));
        Observer.Observe('char 9', Format(Ch, 0, 9));
        Observer.Observe('text format string', Format(T, 0, '<Text>'));
        Observer.Observe('<Text,3>', Format(T, 0, '<Text,3>'));
        Observer.Observe('<Text,10>', Format(T, 0, '<Text,10>'));
        Observer.Observe('<Filler Character,*><Text,10>', Format(T, 0, '<Filler Character,*><Text,10>'));
        Observer.Observe('quote', Format('a"b'));
        Observer.Observe('unicode', Format('äöü€'));
        Observer.Expect('text', 'Hello');
        Observer.Expect('text len 3', 'Hel');
        Observer.Expect('text len 10', 'Hello     ');
        Observer.Expect('text len -10', 'Hello');
        Observer.Expect('text 9', 'Hello');
        Observer.Expect('text 1', 'Hello');
        Observer.Expect('text 2', 'Hello');
        Observer.Expect('empty', '');
        Observer.Expect('empty len 5', '     ');
        Observer.Expect('code', 'ABC');
        Observer.Expect('code 9', 'ABC');
        Observer.Expect('char', 'A');
        Observer.Expect('char 9', 'A');
        Observer.Expect('text format string', 'Hello');
        Observer.Expect('<Text,3>', 'Hel');
        Observer.Expect('<Text,10>', 'Hello     ');
        Observer.Expect('<Filler Character,*><Text,10>', 'Hello*****');
        Observer.Expect('quote', 'a"b');
        Observer.Expect('unicode', 'äöü€');
        Observer.Verify();
    end;

    [Test]
    procedure Format_DateTimeTypes()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        T: Time;
        DT: DateTime;
        Dur: Duration;
    begin
        D := DMY2Date(5, 3, 2024);
        T := 143025.123T;
        DT := CreateDateTime(D, T);
        Dur := 90061001;
        Observer.Observe('date', Format(D));
        Observer.Observe('date 0', Format(D, 0, 0));
        Observer.Observe('date 1', Format(D, 0, 1));
        Observer.Observe('date 2', Format(D, 0, 2));
        Observer.Observe('date 3', Format(D, 0, 3));
        Observer.Observe('date 4', Format(D, 0, 4));
        Observer.Observe('date 5', Format(D, 0, 5));
        Observer.Observe('date 6', Format(D, 0, 6));
        Observer.Observe('date 7', Format(D, 0, 7));
        asserterror Observer.Observe('date 8', Format(D, 0, 8));
        Observer.ObserveError('af275');
        Observer.Observe('date 9', Format(D, 0, 9));
        Observer.Observe('date <Day,2>.<Month,2>.<Year4>', Format(D, 0, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Observe('date <Day>/<Month>/<Year>', Format(D, 0, '<Day>/<Month>/<Year>'));
        Observer.Observe('date <Month Text> <Day>', Format(D, 0, '<Month Text> <Day>'));
        Observer.Observe('date <Closing><Day,2>', Format(D, 0, '<Closing><Day,2>'));
        Observer.Observe('date <Weekday Text>', Format(D, 0, '<Weekday Text>'));
        Observer.Observe('date <Week>', Format(D, 0, '<Week>'));
        Observer.Observe('date <Month Text,3>', Format(D, 0, '<Month Text,3>'));
        Observer.Observe('date 0D', Format(0D));
        Observer.Observe('date 0D 9', Format(0D, 0, 9));
        Observer.Observe('date closing', Format(ClosingDate(D), 0, 9));
        Observer.Observe('date closing 0', Format(ClosingDate(D)));
        Observer.Observe('time 9', Format(T, 0, 9));
        Observer.Observe('time 0', Format(T, 0, 0));
        Observer.Observe('time 1', Format(T, 0, 1));
        Observer.Observe('time 2', Format(T, 0, 2));
        Observer.Observe('time 0T', Format(0T));
        Observer.Observe('time 0T 9', Format(0T, 0, 9));
        Observer.Observe('time <Hours24>:<Minutes,2>:<Seconds,2>', Format(T, 0, '<Hours24>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('time <Hours12>:<Minutes,2> <AM/PM>', Format(T, 0, '<Hours12>:<Minutes,2> <AM/PM>'));
        Observer.Observe('time <Thousands,3>', Format(T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('datetime 9', Format(DT, 0, 9));
        Observer.Observe('datetime 0', Format(DT, 0, 0));
        Observer.Observe('datetime 1', Format(DT, 0, 1));
        Observer.Observe('datetime 2', Format(DT, 0, 2));
        Observer.Observe('datetime 0DT', Format(0DT));
        Observer.Observe('datetime 0DT 9', Format(0DT, 0, 9));
        Observer.Observe('datetime fmt', Format(DT, 0, '<Day,2>.<Month,2>.<Year4> <Hours24,2>:<Minutes,2>'));
        Observer.Observe('duration', Format(Dur));
        Observer.Observe('duration 9', Format(Dur, 0, 9));
        Observer.Observe('duration 0', Format(Dur, 0, 0));
        Observer.Observe('duration 1', Format(Dur, 0, 1));
        Observer.Observe('duration 0', Format(0 * Dur));
                Observer.Expect('date', '03/05/24');
                Observer.Expect('date 0', '03/05/24');
                Observer.Expect('date 1', '03/05/24');
                Observer.Expect('date 2', '030524D');
                Observer.Expect('date 3', '24/03/05');
                Observer.Expect('date 4', 'March 5, 2024');
                Observer.Expect('date 5', '030524');
                Observer.Expect('date 6', '240305');
                Observer.Expect('date 7', 'Mar 5, 2024');
                Observer.Expect('af275|text', 'Standard format number 8 does not exist for the type ''Date''.');
                Observer.Expect('af275|code', 'InvalidStandardFormat');
                Observer.Expect('date 9', '2024-03-05');
                Observer.Expect('date <Day,2>.<Month,2>.<Year4>', '05.03.2024');
                Observer.Expect('date <Day>/<Month>/<Year>', '5/3/24');
                Observer.Expect('date <Month Text> <Day>', 'March 5');
                Observer.Expect('date <Closing><Day,2>', '05');
                Observer.Expect('date <Weekday Text>', 'Tuesday');
                Observer.Expect('date <Week>', '10');
                Observer.Expect('date <Month Text,3>', 'Mar');
                Observer.Expect('date 0D', '');
                Observer.Expect('date 0D 9', '');
                Observer.Expect('date closing', '2024-03-05');
                Observer.Expect('date closing 0', 'C03/05/24');
                Observer.Expect('time 9', '14:30:25.123');
                Observer.Expect('time 0', ' 2:30:25 PM');
                Observer.Expect('time 1', ' 2:30:25.123 PM');
                Observer.Expect('time 2', '143025.123T');
                Observer.Expect('time 0T', '');
                Observer.Expect('time 0T 9', '');
                Observer.Expect('time <Hours24>:<Minutes,2>:<Seconds,2>', '14:30:25');
                Observer.Expect('time <Hours12>:<Minutes,2> <AM/PM>', '2:30 PM');
                Observer.Expect('time <Thousands,3>', '14:30:25.123');
                Observer.Expect('datetime 9', '2024-03-05T14:30:25.123Z');
                Observer.Expect('datetime 0', '03/05/24 02:30 PM');
                Observer.Expect('datetime 1', '03/05/24 02:30:25.123 PM');
                Observer.Expect('datetime 2', '03/05/24 02:30 PM');
                Observer.Expect('datetime 0DT', '');
                Observer.Expect('datetime 0DT 9', '');
                Observer.Expect('datetime fmt', '05.03.2024 14:30');
                Observer.Expect('duration', '1 day 1 hour 1 minute 1 second 1 millisecond');
                Observer.Expect('duration 9', 'P1DT1H1M1.001S');
                Observer.Expect('duration 0', '1 day 1 hour 1 minute 1 second 1 millisecond');
                Observer.Expect('duration 1', '1 day 1 hour 1 minute 1 second 1 millisecond');
                Observer.Expect('duration 0', '0');
                Observer.Verify();
    end;

    [Test]
    procedure Format_OtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        B: BigInteger;
        G: Guid;
        Opt: Option A,"B C",D;
        DF: DateFormula;
        Bl: Boolean;
    begin
        Evaluate(B, '9223372036854775807');
        Observer.Observe('biginteger', Format(B));
        Observer.Observe('biginteger neg', Format(-B));
        Observer.Observe('biginteger 9', Format(B, 0, 9));
        Observer.Observe('biginteger <Integer Thousand>', Format(B, 0, '<Integer Thousand>'));
        Observer.Observe('guid empty', Format(G));
        Observer.Observe('guid empty 9', Format(G, 0, 9));
        Observer.Observe('guid empty len 5', Format(G, 5));
        Opt := Opt::"B C";
        Observer.Observe('option', Format(Opt));
        Observer.Observe('option 9', Format(Opt, 0, 9));
        Observer.Observe('option 2', Format(Opt, 0, 2));
        Observer.Observe('option 1', Format(Opt, 0, 1));
        Observer.Observe('option 0', Format(Opt, 0, 0));
        Observer.Observe('option len 2', Format(Opt, 2));
        Evaluate(DF, '1M+CM');
        Observer.Observe('dateformula', Format(DF));
        Observer.Observe('dateformula 9', Format(DF, 0, 9));
        Clear(DF);
        Observer.Observe('dateformula empty', Format(DF));
        Observer.Observe('dateformula empty 9', Format(DF, 0, 9));
        Observer.Observe('bool var', Format(Bl));
        Observer.Expect('biginteger', '9223372036854775807');
        Observer.Expect('biginteger neg', '-9223372036854775807');
        Observer.Expect('biginteger 9', '9223372036854775807');
        Observer.Expect('biginteger <Integer Thousand>', '9,223,372,036,854,775,807');
        Observer.Expect('guid empty', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('guid empty 9', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('guid empty len 5', '{0000');
        Observer.Expect('option', 'B C');
        Observer.Expect('option 9', '1');
        Observer.Expect('option 2', '1');
        Observer.Expect('option 1', 'B C');
        Observer.Expect('option 0', 'B C');
        Observer.Expect('option len 2', 'B ');
        Observer.Expect('dateformula', '1M+CM');
        Observer.Expect('dateformula 9', '1M+CM');
        Observer.Expect('dateformula empty', '');
        Observer.Expect('dateformula empty 9', '');
        Observer.Expect('bool var', 'No');
        Observer.Verify();
    end;
}
