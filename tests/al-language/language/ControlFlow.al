// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Control flow: for/foreach/while/repeat, case with text constants, in operator, exit values, short-circuit evaluation order, local recursion.
// Writer QX: a for loop over a Date (month and year boundaries, downto, empty ranges, 0D and closing date bounds, the value after the loop).
// BC versions: 29 (27 and 28 by CI)

codeunit 72515 "LT SyT Control Flow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Trace: Text;
        QxObserver: Codeunit "Probe Observer";

    local procedure T(Name: Text; Result: Boolean): Boolean
    begin
        Trace += Name + ';';
        exit(Result);
    end;

    local procedure TI(Name: Text; Result: Integer): Integer
    begin
        Trace += Name + ';';
        exit(Result);
    end;

    [Test]
    procedure ForLoop_VariableAfterLoop()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Count: Integer;
    begin
        for i := 1 to 3 do
            Count += 1;
        Observer.Observe('after to', Format(i) + '|' + Format(Count));
        Count := 0;
        for i := 3 downto 1 do
            Count += 1;
        Observer.Observe('after downto', Format(i) + '|' + Format(Count));
        Count := 0;
        for i := 5 to 4 do
            Count += 1;
        Observer.Observe('empty to', Format(i) + '|' + Format(Count));
        Count := 0;
        for i := 4 downto 5 do
            Count += 1;
        Observer.Observe('empty downto', Format(i) + '|' + Format(Count));
        Count := 0;
        for i := 2 to 2 do
            Count += 1;
        Observer.Observe('single', Format(i) + '|' + Format(Count));
        Count := 0;
        for i := -2 to 2 do
            Count += 1;
        Observer.Observe('negative start', Format(i) + '|' + Format(Count));
        Count := 0;
        for i := 1 to 10 do begin
            if i = 4 then
                break;
            Count += 1;
        end;
        Observer.Observe('break', Format(i) + '|' + Format(Count));
        Count := 0;
        for i := 1 to 5 do begin
            if i mod 2 = 0 then
                continue;
            Count += i;
        end;
        Observer.Observe('continue', Format(i) + '|' + Format(Count));
        Observer.Expect('after to', '3|3');
        Observer.Expect('after downto', '1|3');
        Observer.Expect('empty to', '5|0');
        Observer.Expect('empty downto', '4|0');
        Observer.Expect('single', '2|1');
        Observer.Expect('negative start', '2|5');
        Observer.Expect('break', '4|3');
        Observer.Expect('continue', '5|9');
        Observer.Verify();
    end;

    [Test]
    procedure ForLoop_BoundsAndModification()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Upper: Integer;
        Visited: Text;
    begin
        Upper := 3;
        for i := 1 to Upper do begin
            Upper := 10;
            Visited += Format(i) + ',';
        end;
        Observer.Observe('upper changed in loop', Visited + Format(Upper));
        Visited := '';
        for i := 1 to 6 do begin
            Visited += Format(i) + ',';
            if i = 2 then
                i := 4;
        end;
        Observer.Observe('variable changed in loop', Visited + Format(i));
        Trace := '';
        for i := TI('start', 1) to TI('end', 2) do
            Trace += 'body;';
        Observer.Observe('bounds evaluated once', Trace);
        Observer.Expect('upper changed in loop', '1,2,3,10');
        Observer.Expect('variable changed in loop', '1,2,5,6,6');
        Observer.Expect('bounds evaluated once', 'start;end;body;body;');
        Observer.Verify();
    end;

    [Test]
    procedure ForLoop_Types()
    var
        Observer: Codeunit "Probe Observer";
        Dec: Decimal;
        B: BigInteger;
        Count: Integer;
        Ch: Char;
        D: Date;
    begin
        Count := 0;
        for B := 1 to 3 do
            Count += 1;
        Observer.Observe('biginteger', Format(B) + '|' + Format(Count));
        Count := 0;
        for Dec := 1 to 3 do
            Count += 1;
        Observer.Observe('decimal', Format(Dec) + '|' + Format(Count));
        Count := 0;
        for Ch := 65 to 67 do
            Count += 1;
        Observer.Observe('char', Format(Ch, 0, 9) + '|' + Format(Count));
        Count := 0;
        for D := DMY2Date(1, 1, 2024) to DMY2Date(3, 1, 2024) do
            Count += 1;
        Observer.Observe('date', Format(D, 0, 9) + '|' + Format(Count));
        Observer.Expect('biginteger', '3|3');
        Observer.Expect('decimal', '3|3');
        Observer.Expect('char', 'C|3');
        Observer.Expect('date', '2024-01-03|3');
        Observer.Verify();
    end;

    [Test]
    procedure WhileRepeat_Semantics()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        i := 10;
        while i < 5 do
            i += 1;
        Observer.Observe('while false first', Format(i));
        i := 10;
        repeat
            i += 1;
        until i > 5;
        Observer.Observe('repeat once', Format(i));
        i := 0;
        repeat
            i += 1;
            if i = 3 then
                break;
        until false;
        Observer.Observe('repeat break', Format(i));
        i := 0;
        while true do begin
            i += 1;
            if i >= 4 then
                break;
        end;
        Observer.Observe('while break', Format(i));
        i := 0;
        repeat
            i += 1;
            if i < 3 then
                continue;
        until i >= 5;
        Observer.Observe('repeat continue', Format(i));
        Trace := '';
        i := 0;
        while T('cond' + Format(i), i < 2) do
            i += 1;
        Observer.Observe('while condition evaluations', Trace);
        Trace := '';
        i := 0;
        repeat
            i += 1;
        until T('until' + Format(i), i >= 2);
        Observer.Observe('until condition evaluations', Trace);
        Observer.Expect('while false first', '10');
        Observer.Expect('repeat once', '11');
        Observer.Expect('repeat break', '3');
        Observer.Expect('while break', '4');
        Observer.Expect('repeat continue', '5');
        Observer.Expect('while condition evaluations', 'cond0;cond1;cond2;');
        Observer.Expect('until condition evaluations', 'until1;until2;');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_Semantics()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        Item: Integer;
        Seen: Text;
        Empty: List of [Text];
        S: Text;
        Words: List of [Text];
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        foreach Item in L do
            Seen += Format(Item) + ',';
        Observer.Observe('items', Seen + '|' + Format(Item));
        Item := 55;
        foreach S in Empty do
            Item := 0;
        Observer.Observe('empty list leaves var', Format(Item));
        Words.Add('x');
        Words.Add('y');
        Seen := '';
        foreach S in Words do begin
            if S = 'x' then
                continue;
            Seen += S;
        end;
        Observer.Observe('continue', Seen + '|' + S);
        Seen := '';
        foreach S in Words do begin
            Seen += S;
            break;
        end;
        Observer.Observe('break', Seen);
        Observer.Expect('items', '1,2,3,|3');
        Observer.Expect('empty list leaves var', '55');
        Observer.Expect('continue', 'y|y');
        Observer.Expect('break', 'x');
        Observer.Verify();
    end;

    [Test]
    procedure Case_Semantics()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        Code5: Code[5];
        Int: Integer;
    begin
        Txt := 'abc';
        Observer.Observe('text match', CaseText(Txt));
        Observer.Observe('text case sensitive', CaseText('ABC'));
        Observer.Observe('text list', CaseText('b'));
        Observer.Observe('text list 2', CaseText('c'));
        Observer.Observe('text empty', CaseText(''));
        Observer.Observe('text no match', CaseText('zzz'));
        Observer.Observe('text trailing space', CaseText('abc '));
        Code5 := 'abc';
        Observer.Observe('code match', CaseCode(Code5));
        Code5 := 'ABC';
        Observer.Observe('code upper', CaseCode(Code5));
        Code5 := 'x';
        Observer.Observe('code else', CaseCode(Code5));
        Observer.Observe('int 1', CaseInt(1));
        Observer.Observe('int 2', CaseInt(2));
        Observer.Observe('int 3', CaseInt(3));
        Observer.Observe('int 7', CaseInt(7));
        Observer.Observe('int 15', CaseInt(15));
        Observer.Observe('int 20', CaseInt(20));
        Observer.Observe('int -5', CaseInt(-5));
        Observer.Observe('int 100', CaseInt(100));
        Int := 0;
        Trace := '';
        case TI('selector', 2) of
            TI('a', 1):
                Int := 1;
            TI('b', 2):
                Int := 2;
            TI('c', 3):
                Int := 3;
        end;
        Observer.Observe('evaluation order', Trace + Format(Int));
        Observer.Observe('bool true', CaseBool(true));
        Observer.Observe('bool false', CaseBool(false));
        Observer.Observe('case true form', CaseTrue(5));
        Observer.Observe('case true form 50', CaseTrue(50));
        Observer.Observe('case true form 500', CaseTrue(500));
        Observer.Expect('text match', 'abc!');
        Observer.Expect('text case sensitive', 'other');
        Observer.Expect('text list', 'b or c');
        Observer.Expect('text list 2', 'b or c');
        Observer.Expect('text empty', 'empty');
        Observer.Expect('text no match', 'other');
        Observer.Expect('text trailing space', 'other');
        Observer.Expect('code match', 'ABC!');
        Observer.Expect('code upper', 'ABC!');
        Observer.Expect('code else', 'other');
        Observer.Expect('int 1', 'one');
        Observer.Expect('int 2', 'two or three');
        Observer.Expect('int 3', 'two or three');
        Observer.Expect('int 7', 'five to ten');
        Observer.Expect('int 15', 'twelve to fifteen or seventeen');
        Observer.Expect('int 20', 'else');
        Observer.Expect('int -5', 'negative');
        Observer.Expect('int 100', 'else');
        Observer.Expect('evaluation order', 'selector;a;b;2');
        Observer.Expect('bool true', 'yes');
        Observer.Expect('bool false', 'no');
        Observer.Expect('case true form', 'small');
        Observer.Expect('case true form 50', 'medium');
        Observer.Expect('case true form 500', 'large');
        Observer.Verify();
    end;

    local procedure CaseText(Value: Text): Text
    begin
        case Value of
            'abc':
                exit('abc!');
            'b', 'c':
                exit('b or c');
            '':
                exit('empty');
            else
                exit('other');
        end;
    end;

    local procedure CaseCode(Value: Code[5]): Text
    begin
        case Value of
            'ABC':
                exit('ABC!');
            else
                exit('other');
        end;
    end;

    local procedure CaseInt(Value: Integer): Text
    begin
        case Value of
            1:
                exit('one');
            2, 3:
                exit('two or three');
            5 .. 10:
                exit('five to ten');
            12 .. 15, 17:
                exit('twelve to fifteen or seventeen');
            -10 .. -1:
                exit('negative');
            else
                exit('else');
        end;
    end;

    local procedure CaseBool(Value: Boolean): Text
    begin
        case Value of
            true:
                exit('yes');
            false:
                exit('no');
        end;
        exit('fell through');
    end;

    local procedure CaseTrue(Value: Integer): Text
    begin
        case true of
            Value < 10:
                exit('small');
            Value < 100:
                exit('medium');
            else
                exit('large');
        end;
    end;

    [Test]
    procedure InOperator()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Txt: Text;
        Opt: Option A,B,C,D;
        Ch: Char;
        Dt: Date;
    begin
        i := 5;
        Observer.Observe('in list true', Format(i in [1, 5, 9]));
        Observer.Observe('in list false', Format(i in [1, 2, 3]));
        Observer.Observe('in range', Format(i in [1 .. 10]));
        Observer.Observe('in range edge low', Format(1 in [1 .. 10]));
        Observer.Observe('in range edge high', Format(10 in [1 .. 10]));
        Observer.Observe('in range above', Format(11 in [1 .. 10]));
        Observer.Observe('in range below', Format(0 in [1 .. 10]));
        Observer.Observe('in mixed', Format(15 in [1, 3, 10 .. 20, 30]));
        Observer.Observe('in mixed gap', Format(25 in [1, 3, 10 .. 20, 30]));
        Observer.Observe('in reversed range', Format(5 in [10 .. 1]));
        Observer.Observe('in negative range', Format(-3 in [-5 .. -1]));
        Txt := 'b';
        Observer.Observe('text in', Format(Txt in ['a', 'b']));
        Txt := 'B';
        Observer.Observe('text in case', Format(Txt in ['a', 'b']));
        Observer.Observe('text range', Format('c' in ['a' .. 'e']));
        Observer.Observe('text range outside', Format('z' in ['a' .. 'e']));
        Observer.Observe('text range upper', Format('C' in ['a' .. 'e']));
        Opt := Opt::C;
        Observer.Observe('option in', Format(Opt in [Opt::B, Opt::C]));
        Observer.Observe('option range', Format(Opt in [Opt::A .. Opt::B]));
        Ch := 'x';
        Observer.Observe('char in', Format(Ch in ['x', 'y']));
        Dt := DMY2Date(5, 1, 2024);
        Observer.Observe('date in range', Format(Dt in [DMY2Date(1, 1, 2024) .. DMY2Date(31, 1, 2024)]));
        Observer.Observe('date outside range', Format(Dt in [DMY2Date(1, 2, 2024) .. DMY2Date(28, 2, 2024)]));
        Observer.Observe('decimal in range', Format(2.5 in [2 .. 3]));
        Observer.Observe('decimal in list', Format(2.5 in [2.5, 3]));
        Trace := '';
        Observer.Observe('evaluation', Format(TI('x', 3) in [TI('a', 1), TI('b', 3), TI('c', 5)]) + '|' + Trace);
        Observer.Expect('in list true', 'Yes');
        Observer.Expect('in list false', 'No');
        Observer.Expect('in range', 'Yes');
        Observer.Expect('in range edge low', 'Yes');
        Observer.Expect('in range edge high', 'Yes');
        Observer.Expect('in range above', 'No');
        Observer.Expect('in range below', 'No');
        Observer.Expect('in mixed', 'Yes');
        Observer.Expect('in mixed gap', 'No');
        Observer.Expect('in reversed range', 'No');
        Observer.Expect('in negative range', 'Yes');
        Observer.Expect('text in', 'Yes');
        Observer.Expect('text in case', 'No');
        Observer.Expect('text range', 'Yes');
        Observer.Expect('text range outside', 'No');
        Observer.Expect('text range upper', 'No');
        Observer.Expect('option in', 'Yes');
        Observer.Expect('option range', 'No');
        Observer.Expect('char in', 'Yes');
        Observer.Expect('date in range', 'Yes');
        Observer.Expect('date outside range', 'No');
        Observer.Expect('decimal in range', 'Yes');
        Observer.Expect('decimal in list', 'Yes');
        Observer.Expect('evaluation', 'Yes|x;a;b;');
        Observer.Verify();
    end;

    [Test]
    procedure BooleanShortCircuit()
    var
        Observer: Codeunit "Probe Observer";
        R: Boolean;
    begin
        Trace := '';
        R := T('a', false) and T('b', true);
        Observer.Observe('false and true', Format(R) + '|' + Trace);
        Trace := '';
        R := T('a', true) and T('b', true);
        Observer.Observe('true and true', Format(R) + '|' + Trace);
        Trace := '';
        R := T('a', true) or T('b', false);
        Observer.Observe('true or false', Format(R) + '|' + Trace);
        Trace := '';
        R := T('a', false) or T('b', false);
        Observer.Observe('false or false', Format(R) + '|' + Trace);
        Trace := '';
        R := T('a', true) xor T('b', true);
        Observer.Observe('true xor true', Format(R) + '|' + Trace);
        Trace := '';
        R := T('a', false) and T('b', true) or T('c', true);
        Observer.Observe('a and b or c', Format(R) + '|' + Trace);
        Trace := '';
        R := T('a', true) or T('b', true) and T('c', false);
        Observer.Observe('a or b and c', Format(R) + '|' + Trace);
        Trace := '';
        R := not T('a', true) and T('b', true);
        Observer.Observe('not a and b', Format(R) + '|' + Trace);
        Trace := '';
        R := (T('a', true) or T('b', true)) and (T('c', true) or T('d', true));
        Observer.Observe('(a or b) and (c or d)', Format(R) + '|' + Trace);
        Trace := '';
        if T('a', false) and T('b', true) then
            Trace += 'then;'
        else
            Trace += 'else;';
        Observer.Observe('if false and', Trace);
        Trace := '';
        if T('a', true) or T('b', true) then
            Trace += 'then;';
        Observer.Observe('if true or', Trace);
        Trace := '';
        R := T('a', TI('x', 1) = 1) and (TI('y', 5) > 3);
        Observer.Observe('nested calls', Format(R) + '|' + Trace);
        Trace := '';
        R := (TI('l', 1) + TI('r', 2)) = 3;
        Observer.Observe('arithmetic order', Format(R) + '|' + Trace);
        Trace := '';
        asserterror R := (TI('a', 1) = 2) and (1 div TI('zero', 0) = 1);
        Observer.ObserveError('af429');
        Observer.Observe('guarded division', Format(R) + '|' + Trace);
        asserterror R := (TI('a', 2) = 2) and (1 div TI('zero', 0) = 1);
        Observer.ObserveError('unguarded division');
        Observer.Expect('false and true', 'No|a;b;');
        Observer.Expect('true and true', 'Yes|a;b;');
        Observer.Expect('true or false', 'Yes|a;b;');
        Observer.Expect('false or false', 'No|a;b;');
        Observer.Expect('true xor true', 'No|a;b;');
        Observer.Expect('a and b or c', 'Yes|a;b;c;');
        Observer.Expect('a or b and c', 'Yes|a;b;c;');
        Observer.Expect('not a and b', 'No|a;b;');
        Observer.Expect('(a or b) and (c or d)', 'Yes|a;b;c;d;');
        Observer.Expect('if false and', 'a;b;else;');
        Observer.Expect('if true or', 'a;b;then;');
        Observer.Expect('nested calls', 'Yes|x;a;y;');
        Observer.Expect('arithmetic order', 'Yes|l;r;');
        Observer.Expect('af429|text', 'Attempted to divide by zero.');
        Observer.Expect('af429|code', 'AL:DivideByZero');
        Observer.Expect('guarded division', 'Yes|a;zero;');
        Observer.Expect('unguarded division|text', 'Attempted to divide by zero.');
        Observer.Expect('unguarded division|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [Test]
    procedure ArgumentEvaluationOrder()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Trace := '';
        Result := Format(TI('a', 1) + TI('b', 2) * TI('c', 3));
        Observer.Observe('arithmetic', Result + '|' + Trace);
        Trace := '';
        Result := Take3(TI('first', 1), TI('second', 2), TI('third', 3));
        Observer.Observe('arguments', Result + '|' + Trace);
        Trace := '';
        Result := StrSubstNo('%1 %2', TI('p1', 1), TI('p2', 2));
        Observer.Observe('strsubstno', Result + '|' + Trace);
        Trace := '';
        Result := Format(TI('l', 10) - TI('r', 3));
        Observer.Observe('subtraction', Result + '|' + Trace);
        Observer.Expect('arithmetic', '7|a;b;c;');
        Observer.Expect('arguments', '123|first;second;third;');
        Observer.Expect('strsubstno', '1 2|p1;p2;');
        Observer.Expect('subtraction', '7|l;r;');
        Observer.Verify();
    end;

    local procedure Take3(A: Integer; B: Integer; C: Integer): Text
    begin
        exit(Format(A) + Format(B) + Format(C));
    end;

    // ---- Writer QX (Microsoft's DemoTool: for ActualDate := AdjustDate(19011201D) to AdjustDate(19030126D) do): a for loop whose control
    // variable is a Date. The plain 3-day loop is pinned above (ForLoop_NonIntegerControlVariables, date). ----

    local procedure QxShift(D: Date): Date
    begin
        exit(CalcDate('<+122Y>', D));
    end;

    local procedure QxVisit(FromDate: Date; ToDate: Date; Down: Boolean): Text
    var
        D: Date;
        Visited: Text;
        Count: Integer;
    begin
        if Down then
            for D := FromDate downto ToDate do begin
                Count += 1;
                if Count <= 6 then
                    Visited += Format(D, 0, 9) + ',';
            end
        else
            for D := FromDate to ToDate do begin
                Count += 1;
                if Count <= 6 then
                    Visited += Format(D, 0, 9) + ',';
            end;
        exit('count=' + Format(Count) + ' first=' + Visited + ' after=' + Format(D, 0, 9));
    end;

    [TryFunction]
    local procedure QxTryVisit(FromDate: Date; ToDate: Date; Down: Boolean; var Result: Text)
    begin
        Result := QxVisit(FromDate, ToDate, Down);
    end;

    local procedure QxObserveVisit(Name: Text; FromDate: Date; ToDate: Date; Down: Boolean)
    var
        Result: Text;
    begin
        if QxTryVisit(FromDate, ToDate, Down, Result) then
            QxObserver.Observe(Name, Result)
        else
            QxObserver.ObserveError(Name);
    end;

    [Test]
    procedure QX_ForLoop_DateControlVariable()
    var
        D: Date;
        Count: Integer;
    begin
        QxObserveVisit('month and year boundary', DMY2Date(30, 12, 1902), DMY2Date(2, 1, 1903), false);
        QxObserveVisit('downto', DMY2Date(3, 1, 2024), DMY2Date(30, 12, 2023), true);
        QxObserveVisit('leap day', DMY2Date(27, 2, 2024), DMY2Date(1, 3, 2024), false);
        QxObserveVisit('empty range to', DMY2Date(5, 1, 2024), DMY2Date(1, 1, 2024), false);
        QxObserveVisit('empty range downto', DMY2Date(1, 1, 2024), DMY2Date(5, 1, 2024), true);
        QxObserveVisit('one day', DMY2Date(1, 1, 2024), DMY2Date(1, 1, 2024), false);
        QxObserveVisit('0D to 0D', 0D, 0D, false);
        QxObserveVisit('0D to a date', 0D, DMY2Date(2, 1, 1), false);
        QxObserveVisit('date downto 0D', DMY2Date(2, 1, 1), 0D, true);
        QxObserveVisit('to a closing date', DMY2Date(30, 12, 2023), ClosingDate(DMY2Date(31, 12, 2023)), false);
        QxObserveVisit('from a closing date', ClosingDate(DMY2Date(30, 12, 2023)), DMY2Date(1, 1, 2024), false);
        QxObserveVisit('date literals through a procedure', QxShift(19011201D), QxShift(19030126D), false);
        for D := 19011201D to 19011203D do
            Count += 1;
        QxObserver.Observe('date literal bounds', Format(Count) + '|' + Format(D, 0, 9));
        QxObserver.Expect('month and year boundary', 'count=4 first=1902-12-30,1902-12-31,1903-01-01,1903-01-02, after=1903-01-02');
        QxObserver.Expect('downto', 'count=5 first=2024-01-03,2024-01-02,2024-01-01,2023-12-31,2023-12-30, after=2023-12-30');
        QxObserver.Expect('leap day', 'count=4 first=2024-02-27,2024-02-28,2024-02-29,2024-03-01, after=2024-03-01');
        QxObserver.Expect('empty range to', 'count=0 first= after=2024-01-05');
        QxObserver.Expect('empty range downto', 'count=0 first= after=2024-01-01');
        QxObserver.Expect('one day', 'count=1 first=2024-01-01, after=2024-01-01');
        QxObserver.Expect('0D to 0D', 'count=1 first=, after=');
        QxObserver.Expect('0D to a date|text', 'The date is not valid.');
        QxObserver.Expect('0D to a date|code', 'DateInvalid');
        QxObserver.Expect('date downto 0D|text', 'The date is not valid.');
        QxObserver.Expect('date downto 0D|code', 'DateInvalid');
        QxObserver.Expect('to a closing date', 'count=2 first=2023-12-30,2023-12-31, after=2024-01-01');
        QxObserver.Expect('from a closing date|text', 'The operation cannot be performed on a closing date value.');
        QxObserver.Expect('from a closing date|code', 'ClosingDateOperation');
        QxObserver.Expect('date literals through a procedure', 'count=423 first=2023-12-01,2023-12-02,2023-12-03,2023-12-04,2023-12-05,2023-12-06, after=2025-01-26');
        QxObserver.Expect('date literal bounds', '3|1901-12-03');
        QxObserver.Verify();
    end;

}

codeunit 72516 "LT SyT Exit Recursion"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ReturnValueNotSet(): Integer
    begin
    end;

    local procedure ReturnTextNotSet(): Text
    begin
    end;

    local procedure ReturnBoolNotSet(): Boolean
    begin
    end;

    local procedure ReturnDecimalNotSet(): Decimal
    begin
    end;

    local procedure ReturnDateNotSet(): Date
    begin
    end;

    local procedure ReturnOptionNotSet(): Option A,B
    begin
    end;

    local procedure ExitTwice(): Integer
    begin
        exit(1);
        exit(2);
    end;

    local procedure NamedReturn() Result: Integer
    begin
        Result := 5;
        exit;
    end;

    local procedure NamedReturnOverridden() Result: Integer
    begin
        Result := 5;
        exit(6);
    end;

    local procedure NamedReturnText() Result: Text[3]
    begin
        Result := 'abc';
        exit('xyz');
    end;

    local procedure NamedTextTruncating() Result: Text[3]
    begin
        exit('toolong');
    end;

    local procedure ExitInLoop(): Integer
    var
        i: Integer;
    begin
        for i := 1 to 10 do
            if i = 4 then
                exit(i * 100);
        exit(-1);
    end;

    local procedure TypedExit(): Decimal
    begin
        exit(5);
    end;

    local procedure IntegerReturnsDecimal(): Integer
    begin
        exit(2.0);
    end;

    local procedure TextToCode(): Code[3]
    begin
        exit('abc');
    end;

    local procedure TextToCodeTooLong(): Code[3]
    begin
        exit('abcdef');
    end;

    local procedure Factorial(N: Integer): BigInteger
    begin
        if N <= 1 then
            exit(1);
        exit(N * Factorial(N - 1));
    end;

    local procedure Fibonacci(N: Integer): Integer
    begin
        if N < 2 then
            exit(N);
        exit(Fibonacci(N - 1) + Fibonacci(N - 2));
    end;

    local procedure Depth(N: Integer): Integer
    begin
        if N = 0 then
            exit(0);
        exit(1 + Depth(N - 1));
    end;

    local procedure IsEven(N: Integer): Boolean
    begin
        if N = 0 then
            exit(true);
        exit(IsOdd(N - 1));
    end;

    local procedure IsOdd(N: Integer): Boolean
    begin
        if N = 0 then
            exit(false);
        exit(IsEven(N - 1));
    end;

    local procedure ByValueRecursion(N: Integer; var Acc: Text)
    begin
        Acc += Format(N);
        if N > 0 then
            ByValueRecursion(N - 1, Acc);
        Acc += Format(N);
    end;

    [Test]
    procedure Exit_DefaultValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('integer', Format(ReturnValueNotSet()));
        Observer.Observe('text', '[' + ReturnTextNotSet() + ']');
        Observer.Observe('boolean', Format(ReturnBoolNotSet()));
        Observer.Observe('decimal', Format(ReturnDecimalNotSet()));
        Observer.Observe('date', Format(ReturnDateNotSet(), 0, 9));
        Observer.Observe('option', Format(ReturnOptionNotSet()));
        Observer.Expect('integer', '0');
        Observer.Expect('text', '[]');
        Observer.Expect('boolean', 'No');
        Observer.Expect('decimal', '0');
        Observer.Expect('date', '');
        Observer.Expect('option', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure Exit_Forms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('exit twice', Format(ExitTwice()));
        Observer.Observe('named exit;', Format(NamedReturn()));
        Observer.Observe('named exit(6)', Format(NamedReturnOverridden()));
        Observer.Observe('named text', NamedReturnText());
        Observer.Observe('in loop', Format(ExitInLoop()));
        Observer.Observe('typed decimal', Format(TypedExit()));
        Observer.Observe('integer from decimal', Format(IntegerReturnsDecimal()));
        Observer.Observe('text to code', TextToCode());
        asserterror Observer.Observe('too long', NamedTextTruncating());
        Observer.ObserveError('exit too long for Text[3]');
        asserterror Observer.Observe('too long', TextToCodeTooLong());
        Observer.ObserveError('exit too long for Code[3]');
        Observer.Expect('exit twice', '1');
        Observer.Expect('named exit;', '5');
        Observer.Expect('named exit(6)', '6');
        Observer.Expect('named text', 'xyz');
        Observer.Expect('in loop', '400');
        Observer.Expect('typed decimal', '5');
        Observer.Expect('integer from decimal', '2');
        Observer.Expect('text to code', 'ABC');
        Observer.Expect('exit too long for Text[3]|text', 'The length of the string is 7, but it must be less than or equal to 3 characters. Value: toolong');
        Observer.Expect('exit too long for Text[3]|code', 'StringLengthExceeded');
        Observer.Expect('exit too long for Code[3]|text', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('exit too long for Code[3]|code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure Recursion_Values()
    var
        Observer: Codeunit "Probe Observer";
        Acc: Text;
    begin
        Observer.Observe('factorial 1', Format(Factorial(1)));
        Observer.Observe('factorial 10', Format(Factorial(10)));
        Observer.Observe('factorial 20', Format(Factorial(20)));
        asserterror Observer.Observe('factorial 21', Format(Factorial(21)));
        Observer.ObserveError('factorial 21');
        Observer.Observe('fib 15', Format(Fibonacci(15)));
        Observer.Observe('depth 100', Format(Depth(100)));
        Observer.Observe('depth 500', Format(Depth(500)));
        Observer.Observe('is even 10', Format(IsEven(10)));
        Observer.Observe('is even 7', Format(IsEven(7)));
        ByValueRecursion(3, Acc);
        Observer.Observe('accumulate', Acc);
        Observer.Expect('factorial 1', '1');
        Observer.Expect('factorial 10', '3628800');
        Observer.Expect('factorial 20', '2432902008176640000');
        Observer.Expect('factorial 21|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('factorial 21|code', 'AL:Overflow');
        Observer.Expect('fib 15', '610');
        Observer.Expect('depth 100', '100');
        Observer.Expect('depth 500', '500');
        Observer.Expect('is even 10', 'Yes');
        Observer.Expect('is even 7', 'No');
        Observer.Expect('accumulate', '32100123');
        Observer.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 36: the end bound of a for loop is converted to the type of the
    // control variable. A BigInteger end bound above the Integer range on an Integer control variable, and a loop that ends at
    // the largest Integer (a safety counter stops it after 5 rounds).
    [Test]
    procedure LT_BU_ForLoop_BigIntegerEndBoundOnInteger()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Rounds: Integer;
    begin
        ClearLastError();
        if TryLoopToBig(100000000000000L, i, Rounds) then
            Observer.Observe('end 10^14', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('end 10^14', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        ClearLastError();
        if TryLoopToBig(2147483648L, i, Rounds) then
            Observer.Observe('end max+1', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('end max+1', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        ClearLastError();
        if TryLoopToBig(5L, i, Rounds) then
            Observer.Observe('end 5', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('end 5', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        ClearLastError();
        if TryLoopToIntMax(i, Rounds) then
            Observer.Observe('to int max', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('to int max', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        Observer.Expect('end 10^14', 'error:Overflow under conversion of System.Int64 value 100000000000000 to System.Int32.|ConversionCast|1000|0');
        Observer.Expect('end max+1', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast|1000|0');
        Observer.Expect('end 5', 'no error|1000|0');
        Observer.Expect('to int max', 'no error|2147483647|2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryLoopToBig(EndBound: BigInteger; var i: Integer; var Rounds: Integer)
    begin
        i := 0;
        Rounds := 0;
        for i := 1000 to EndBound do begin
            Rounds += 1;
            if Rounds = 5 then
                exit;
        end;
    end;

    [TryFunction]
    local procedure TryLoopToIntMax(var i: Integer; var Rounds: Integer)
    begin
        i := 0;
        Rounds := 0;
        for i := 2147483646 to 2147483647 do begin
            Rounds += 1;
            if Rounds = 5 then
                exit;
        end;
    end;
    // Writer PY-C (al-runtime-rs PR 346, probes-needed "Loops, continue and MaxStrLen"): a downto loop on an Integer counter whose BigInteger
    // end bound is below the Integer range, and a BigInteger start bound above it.
    [Test]
    procedure PYC_ForDownto_BigIntegerBoundOnInteger()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
        Rounds: Integer;
    begin
        ClearLastError();
        if TryDowntoBig(-3000000000L, i, Rounds) then
            Observer.Observe('downto -3e9', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('downto -3e9', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        ClearLastError();
        if TryDowntoBig(-2147483649L, i, Rounds) then
            Observer.Observe('downto min-1', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('downto min-1', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        ClearLastError();
        if TryDowntoBig(998L, i, Rounds) then
            Observer.Observe('downto 998', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('downto 998', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        ClearLastError();
        if TryDowntoFromBig(3000000000L, i, Rounds) then
            Observer.Observe('from 3e9 downto 1', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('from 3e9 downto 1', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        ClearLastError();
        if TryDowntoIntMin(i, Rounds) then
            Observer.Observe('downto int min', 'no error|' + Format(i) + '|' + Format(Rounds))
        else
            Observer.Observe('downto int min', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(i) + '|' + Format(Rounds));
        Observer.Expect('downto -3e9', 'error:Overflow under conversion of System.Int64 value -3000000000 to System.Int32.|ConversionCast|1000|0');
        Observer.Expect('downto min-1', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast|1000|0');
        Observer.Expect('downto 998', 'no error|998|3');
        Observer.Expect('from 3e9 downto 1', 'error:Overflow under conversion of System.Int64 value 3000000000 to System.Int32.|ConversionCast|0|0');
        Observer.Expect('downto int min', 'no error|-2147483648|2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDowntoBig(EndBound: BigInteger; var i: Integer; var Rounds: Integer)
    begin
        i := 0;
        Rounds := 0;
        for i := 1000 downto EndBound do begin
            Rounds += 1;
            if Rounds = 5 then
                exit;
        end;
    end;

    [TryFunction]
    local procedure TryDowntoFromBig(StartBound: BigInteger; var i: Integer; var Rounds: Integer)
    begin
        i := 0;
        Rounds := 0;
        for i := StartBound downto 1 do begin
            Rounds += 1;
            if Rounds = 5 then
                exit;
        end;
    end;

    [TryFunction]
    local procedure TryDowntoIntMin(var i: Integer; var Rounds: Integer)
    var
        Lowest: Integer;
    begin
        Lowest := -2147483647;
        Lowest -= 1;
        i := 0;
        Rounds := 0;
        for i := -2147483647 downto Lowest do begin
            Rounds += 1;
            if Rounds = 5 then
                exit;
        end;
    end;
}
