// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61408
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): the IN operator with a DotNet Int32 variable on the left
//
// A DotNet System.Int32 value as an operand (issue 154 item 3). Every statement is wrapped in a TryFunction and observed as ok:<Format of the result> or error:<text>|<code>.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Int32"; NIntDn) { }
        type("System.Convert"; NIntConv) { }
    }
}

codeunit 61408 "LT DotNetOp Int32In"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOp1(var Result: Text)
    var
        N: DotNet NIntDn;
        N2: DotNet NIntDn;
        Conv: DotNet NIntConv;
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
        Result := Format(N in [1, 5]);
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
        N: DotNet NIntDn;
        N2: DotNet NIntDn;
        Conv: DotNet NIntConv;
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
        Result := Format(N in [1, 2]);
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
        N: DotNet NIntDn;
        N2: DotNet NIntDn;
        Conv: DotNet NIntConv;
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
        Result := Format(N in [1 .. 9]);
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
        N: DotNet NIntDn;
        N2: DotNet NIntDn;
        Conv: DotNet NIntConv;
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
        Result := Format(N in [1 .. 4]);
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
        N: DotNet NIntDn;
        N2: DotNet NIntDn;
        Conv: DotNet NIntConv;
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
        Result := Format(N in [5]);
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
    procedure In_Sets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('in_hit', Out1());
        Observer.Observe('in_miss', Out2());
        Observer.Observe('in_range_hit', Out3());
        Observer.Observe('in_range_miss', Out4());
        Observer.Observe('in_single', Out5());
        Observer.Expect('in_hit', 'ok:Yes');
        Observer.Expect('in_miss', 'ok:No');
        Observer.Expect('in_range_hit', 'ok:Yes');
        Observer.Expect('in_range_miss', 'ok:No');
        Observer.Expect('in_single', 'ok:Yes');
        Observer.Verify();
    end;
}
