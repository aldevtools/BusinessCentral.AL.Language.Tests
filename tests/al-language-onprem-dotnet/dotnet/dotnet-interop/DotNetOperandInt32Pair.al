// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61410
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): two DotNet Int32 variables as operands (= between two DotNet objects is AL0175 for classes, see TestDotNetValueKindsContracts.al)
//
// A DotNet System.Int32 value as an operand (issue 154 item 3). Every statement is wrapped in a TryFunction and observed as ok:<Format of the result> or error:<text>|<code>.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Int32"; PIntDn) { }
        type("System.Convert"; PIntConv) { }
    }
}

codeunit 61410 "LT DotNetOp Int32Pair"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOp1(var Result: Text)
    var
        N: DotNet PIntDn;
        N2: DotNet PIntDn;
        Conv: DotNet PIntConv;
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
        Result := Format(N = N2);
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
        N: DotNet PIntDn;
        N2: DotNet PIntDn;
        Conv: DotNet PIntConv;
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
        Result := Format(N <> N2);
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
        N: DotNet PIntDn;
        N2: DotNet PIntDn;
        Conv: DotNet PIntConv;
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
        Result := Format(N + N2);
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
        N: DotNet PIntDn;
        N2: DotNet PIntDn;
        Conv: DotNet PIntConv;
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
        Result := Format(N < N2);
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
        N: DotNet PIntDn;
        N2: DotNet PIntDn;
        Conv: DotNet PIntConv;
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
        Result := Format(N2 - N);
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

    [Test]
    procedure Pair_DotNetOperands()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('eq_pair', Out1());
        Observer.Observe('ne_pair', Out2());
        Observer.Observe('plus_pair', Out3());
        Observer.Observe('lt_pair', Out4());
        Observer.Observe('minus_pair', Out5());
        Observer.Expect('eq_pair', 'ok:No');
        Observer.Expect('ne_pair', 'ok:Yes');
        Observer.Expect('plus_pair', 'ok:12');
        Observer.Expect('lt_pair', 'ok:Yes');
        Observer.Expect('minus_pair', 'ok:2');
        Observer.Verify();
    end;
}
