// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61406
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): operands = <> + - * / between a DotNet Int32 variable and an AL value
//
// A DotNet System.Int32 value as an operand (issue 154 item 3). Every statement is wrapped in a TryFunction and observed as ok:<Format of the result> or error:<text>|<code>.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Int32"; EIntDn) { }
        type("System.Convert"; EIntConv) { }
    }
}

codeunit 61406 "LT DotNetOp Int32Eq"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOp1(var Result: Text)
    var
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N = 5);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N = 6);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N <> 6);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N <> 5);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N = I);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(5 = N);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N = B);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N = Dc);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N + 1);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(1 + N);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N + I);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N - 1);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(10 - N);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N * 2);
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
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N / 2);
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

    [TryFunction]
    local procedure TryOp16(var Result: Text)
    var
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N div 2);
    end;

    local procedure Out16(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp16(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp17(var Result: Text)
    var
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N mod 2);
    end;

    local procedure Out17(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp17(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp18(var Result: Text)
    var
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N + 0.5);
    end;

    local procedure Out18(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp18(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOp19(var Result: Text)
    var
        N: DotNet EIntDn;
        N2: DotNet EIntDn;
        Conv: DotNet EIntConv;
        I: Integer;
        B: BigInteger;
        Dc: Decimal;
        T: Text;
    begin
        N := Conv.ToInt32('5');
        N2 := Conv.ToInt32('7');
        I := 5;
        B := 5;
        Dc := 5;
        T := 'x';
        Result := Format(N);
    end;

    local procedure Out19(): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryOp19(R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Equal_IntegerShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('eq_same', Out1());
        Observer.Observe('eq_other', Out2());
        Observer.Observe('ne_other', Out3());
        Observer.Observe('ne_same', Out4());
        Observer.Observe('eq_integer_variable', Out5());
        Observer.Observe('eq_reversed', Out6());
        Observer.Observe('eq_biginteger', Out7());
        Observer.Observe('eq_decimal', Out8());
        Observer.Expect('eq_same', 'ok:Yes');
        Observer.Expect('eq_other', 'ok:No');
        Observer.Expect('ne_other', 'ok:Yes');
        Observer.Expect('ne_same', 'ok:No');
        Observer.Expect('eq_integer_variable', 'ok:Yes');
        Observer.Expect('eq_reversed', 'ok:Yes');
        Observer.Expect('eq_biginteger', 'ok:Yes');
        Observer.Expect('eq_decimal', 'ok:Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Arithmetic_IntegerShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('plus', Out9());
        Observer.Observe('plus_reversed', Out10());
        Observer.Observe('plus_variable', Out11());
        Observer.Observe('minus', Out12());
        Observer.Observe('minus_reversed', Out13());
        Observer.Observe('times', Out14());
        Observer.Observe('divide', Out15());
        Observer.Observe('div', Out16());
        Observer.Observe('mod', Out17());
        Observer.Observe('plus_decimal', Out18());
        Observer.Observe('format', Out19());
        Observer.Expect('plus', 'ok:6');
        Observer.Expect('plus_reversed', 'ok:6');
        Observer.Expect('plus_variable', 'ok:10');
        Observer.Expect('minus', 'ok:4');
        Observer.Expect('minus_reversed', 'ok:5');
        Observer.Expect('times', 'ok:10');
        Observer.Expect('divide', 'ok:2.5');
        Observer.Expect('div', 'ok:2');
        Observer.Expect('mod', 'ok:1');
        Observer.Expect('plus_decimal', 'ok:5.5');
        Observer.Expect('format', 'ok:5');
        Observer.Verify();
    end;
}
