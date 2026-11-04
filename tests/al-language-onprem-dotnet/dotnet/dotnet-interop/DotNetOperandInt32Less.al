// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61407
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): the order operators < > <= >= with a DotNet Int32 variable
//
// A DotNet System.Int32 value as an operand (issue 154 item 3). Every statement is wrapped in a TryFunction and observed as ok:<Format of the result> or error:<text>|<code>.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Int32"; LIntDn) { }
        type("System.Convert"; LIntConv) { }
    }
}

codeunit 61407 "LT DotNetOp Int32Less"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOp1(var Result: Text)
    var
        N: DotNet LIntDn;
        N2: DotNet LIntDn;
        Conv: DotNet LIntConv;
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
        Result := Format(N < 6);
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
        N: DotNet LIntDn;
        N2: DotNet LIntDn;
        Conv: DotNet LIntConv;
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
        Result := Format(N < 5);
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
        N: DotNet LIntDn;
        N2: DotNet LIntDn;
        Conv: DotNet LIntConv;
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
        Result := Format(N > 4);
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
        N: DotNet LIntDn;
        N2: DotNet LIntDn;
        Conv: DotNet LIntConv;
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
        Result := Format(N > 5);
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
        N: DotNet LIntDn;
        N2: DotNet LIntDn;
        Conv: DotNet LIntConv;
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
        Result := Format(N <= 5);
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
        N: DotNet LIntDn;
        N2: DotNet LIntDn;
        Conv: DotNet LIntConv;
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
        Result := Format(N >= 6);
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
        N: DotNet LIntDn;
        N2: DotNet LIntDn;
        Conv: DotNet LIntConv;
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
        Result := Format(4 < N);
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
        N: DotNet LIntDn;
        N2: DotNet LIntDn;
        Conv: DotNet LIntConv;
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
        Result := Format(N < I);
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

    [Test]
    procedure Compare_Order()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('lt_greater', Out1());
        Observer.Observe('lt_equal', Out2());
        Observer.Observe('gt_smaller', Out3());
        Observer.Observe('gt_equal', Out4());
        Observer.Observe('le_equal', Out5());
        Observer.Observe('ge_greater', Out6());
        Observer.Observe('lt_reversed', Out7());
        Observer.Observe('lt_variable', Out8());
        Observer.Expect('lt_greater', 'ok:Yes');
        Observer.Expect('lt_equal', 'ok:No');
        Observer.Expect('gt_smaller', 'ok:Yes');
        Observer.Expect('gt_equal', 'ok:No');
        Observer.Expect('le_equal', 'ok:Yes');
        Observer.Expect('ge_greater', 'ok:No');
        Observer.Expect('lt_reversed', 'ok:Yes');
        Observer.Expect('lt_variable', 'ok:No');
        Observer.Verify();
    end;
}
