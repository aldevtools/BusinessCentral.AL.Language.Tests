// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61411
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): operands = <> + - * / between a DotNet Decimal variable and an AL value
//
// A DotNet System.Decimal value as an operand (issue 154 item 3). Every statement is wrapped in a TryFunction and observed as ok:<Format of the result> or error:<text>|<code>.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Decimal"; EDecDn) { }
        type("System.Convert"; EDecConv) { }
    }
}

codeunit 61411 "LT DotNetOp DecimalEq"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOp1(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D = 1.5);
    end;

    local procedure Out1(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp1(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp2(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D = 2);
    end;

    local procedure Out2(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp2(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp3(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D <> 2.5);
    end;

    local procedure Out3(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp3(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp4(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D <> 1.5);
    end;

    local procedure Out4(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp4(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp5(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D = Dc);
    end;

    local procedure Out5(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp5(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp6(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D = I);
    end;

    local procedure Out6(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp6(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp7(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(1.5 = D);
    end;

    local procedure Out7(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp7(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp8(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D + 1);
    end;

    local procedure Out8(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp8(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp9(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(1 + D);
    end;

    local procedure Out9(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp9(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp10(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D + Dc);
    end;

    local procedure Out10(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp10(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp11(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D - 1);
    end;

    local procedure Out11(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp11(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp12(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D * 2);
    end;

    local procedure Out12(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp12(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp13(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D / 2);
    end;

    local procedure Out13(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp13(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp14(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(3 / D);
    end;

    local procedure Out14(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp14(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp15(var Result: Text)
    var
        D: DotNet EDecDn;
        D2: DotNet EDecDn;
        Conv: DotNet EDecConv;
        I: Integer;
        Dc: Decimal;
        T: Text;
    begin
        D := Conv.ToDecimal('1.5');
        D2 := Conv.ToDecimal('2.5');
        I := 2;
        Dc := 1.5;
        T := 'x';
        Result := Format(D);
    end;

    local procedure Out15(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp15(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Equal_DecimalShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('eq_same', Out1());
        Observer.Observe('eq_other', Out2());
        Observer.Observe('ne_other', Out3());
        Observer.Observe('ne_same', Out4());
        Observer.Observe('eq_decimal_variable', Out5());
        Observer.Observe('eq_integer_variable', Out6());
        Observer.Observe('eq_reversed', Out7());
        Observer.Expect('eq_same', 'ok:Yes');
        Observer.Expect('eq_other', 'ok:No');
        Observer.Expect('ne_other', 'ok:Yes');
        Observer.Expect('ne_same', 'ok:No');
        Observer.Expect('eq_decimal_variable', 'ok:Yes');
        Observer.Expect('eq_integer_variable', 'ok:No');
        Observer.Expect('eq_reversed', 'ok:Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Arithmetic_DecimalShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('plus', Out8());
        Observer.Observe('plus_reversed', Out9());
        Observer.Observe('plus_variable', Out10());
        Observer.Observe('minus', Out11());
        Observer.Observe('times', Out12());
        Observer.Observe('divide', Out13());
        Observer.Observe('divide_reversed', Out14());
        Observer.Observe('format', Out15());
        Observer.Expect('plus', 'ok:2.5');
        Observer.Expect('plus_reversed', 'ok:2.5');
        Observer.Expect('plus_variable', 'ok:3');
        Observer.Expect('minus', 'ok:0.5');
        Observer.Expect('times', 'ok:3');
        Observer.Expect('divide', 'ok:0.75');
        Observer.Expect('divide_reversed', 'ok:2');
        Observer.Expect('format', 'ok:1.5');
        Observer.Verify();
    end;
}
