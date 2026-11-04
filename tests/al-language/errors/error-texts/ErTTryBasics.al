// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 70064
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TryFunction return values and errors
// BC versions: 29 (27 and 28 by CI)

codeunit 70067 "LT ErT Try Basics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOk()
    begin
    end;

    [TryFunction]
    local procedure TryErr()
    begin
        Error('boom');
    end;

    [TryFunction]
    local procedure TryErrCode(Code: Integer)
    var
        a: Integer;
        d: Decimal;
    begin
        case Code of
            1:
                a := 1 div (Code - 1);
            2:
                d := 1 / (Code - 2);
            3:
                Evaluate(a, 'abc');
            4:
                a := 2147483647 + Code;
            5:
                Error('five');
        end;
    end;

    [TryFunction]
    local procedure TryVar(var Txt: Text; var Num: Integer)
    begin
        Txt := Txt + 'x';
        Num := Num + 1;
        if Num > 2 then
            Error('too many %1', Num);
    end;

    [TryFunction]
    local procedure TryVarErrAfterAssign(var Txt: Text)
    begin
        Txt := 'assigned';
        Error('after assign');
    end;

    [TryFunction]
    local procedure TryNested(Depth: Integer)
    begin
        if Depth = 0 then
            Error('bottom');
        TryNested(Depth - 1);
    end;

    [TryFunction]
    local procedure TryInnerCatch()
    begin
        if not TryErr() then
            Error('outer after inner: %1', GetLastErrorText());
    end;

    [Test]
    procedure TryReturnValues()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Ok := TryOk();
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('okErrText', GetLastErrorText());
        Observer.Observe('okErrCode', GetLastErrorCode());
        Ok := TryErr();
        Observer.Observe('err', Format(Ok));
        Observer.Observe('errText', GetLastErrorText());
        Observer.Observe('errCode', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('clearedText', GetLastErrorText());
        Observer.Observe('clearedCode', GetLastErrorCode());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('okErrText', '');
        Observer.Expect('okErrCode', '');
        Observer.Expect('err', 'No');
        Observer.Expect('errText', 'boom');
        Observer.Expect('errCode', 'Dialog');
        Observer.Expect('clearedText', '');
        Observer.Expect('clearedCode', '');
        Observer.Verify();
    end;

    [Test]
    procedure TryRuntimeErrorCodes()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 5 do begin
            Observer.Observe('r' + Format(i), Format(TryErrCode(i)));
            Observer.Observe('r' + Format(i) + 'Text', GetLastErrorText());
            Observer.Observe('r' + Format(i) + 'Code', GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Expect('r1', 'No');
        Observer.Expect('r1Text', 'Attempted to divide by zero.');
        Observer.Expect('r1Code', 'AL:DivideByZero');
        Observer.Expect('r2', 'No');
        Observer.Expect('r2Text', 'Attempted to divide by zero.');
        Observer.Expect('r2Code', 'AL:DivideByZero');
        Observer.Expect('r3', 'No');
        Observer.Expect('r3Text', 'The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('r3Code', 'Evaluate');
        Observer.Expect('r4', 'No');
        Observer.Expect('r4Text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('r4Code', 'AL:Overflow');
        Observer.Expect('r5', 'No');
        Observer.Expect('r5Text', 'five');
        Observer.Expect('r5Code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure TryWithVarParameters()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
        Num: Integer;
        i: Integer;
    begin
        for i := 1 to 3 do begin
            Observer.Observe('call' + Format(i), Format(TryVar(Txt, Num)));
            Observer.Observe('txt' + Format(i), Txt);
            Observer.Observe('num' + Format(i), Format(Num));
        end;
        Observer.Observe('lastText', GetLastErrorText());
        Observer.Expect('call1', 'Yes');
        Observer.Expect('txt1', 'x');
        Observer.Expect('num1', '1');
        Observer.Expect('call2', 'Yes');
        Observer.Expect('txt2', 'xx');
        Observer.Expect('num2', '2');
        Observer.Expect('call3', 'No');
        Observer.Expect('txt3', 'xxx');
        Observer.Expect('num3', '3');
        Observer.Expect('lastText', 'too many 3');
        Observer.Verify();
    end;

    [Test]
    procedure TryVarAssignedBeforeError()
    var
        Observer: Codeunit "Probe Observer";
        Txt: Text;
    begin
        Txt := 'initial';
        Observer.Observe('result', Format(TryVarErrAfterAssign(Txt)));
        Observer.Observe('txt', Txt);
        Observer.Observe('errText', GetLastErrorText());
        Observer.Expect('result', 'No');
        Observer.Expect('txt', 'assigned');
        Observer.Expect('errText', 'after assign');
        Observer.Verify();
    end;

    [Test]
    procedure TryNestedRecursion()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('depth0', Format(TryNested(0)));
        Observer.Observe('depth3', Format(TryNested(3)));
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('innerCatch', Format(TryInnerCatch()));
        Observer.Observe('innerCatchText', GetLastErrorText());
        Observer.Expect('depth0', 'No');
        Observer.Expect('depth3', 'No');
        Observer.Expect('text', 'bottom');
        Observer.Expect('innerCatch', 'No');
        Observer.Expect('innerCatchText', 'outer after inner: boom');
        Observer.Verify();
    end;

    [Test]
    procedure TryResultIgnoredStillClearsOrKeeps()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror TryErr();
        Observer.ObserveError('af158');
        Observer.Observe('afterIgnoredCall', GetLastErrorText());
        TryOk();
        Observer.Observe('afterOkCall', GetLastErrorText());
        Observer.Expect('af158|text', 'boom');
        Observer.Expect('af158|code', 'Dialog');
        Observer.Expect('afterIgnoredCall', '');
        Observer.Expect('afterOkCall', '');
        Observer.Verify();
    end;
}
