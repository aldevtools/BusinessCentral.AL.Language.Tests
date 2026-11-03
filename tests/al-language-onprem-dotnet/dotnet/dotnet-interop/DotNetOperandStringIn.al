// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61403
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): the IN operator with a DotNet String variable on the left
//
// A DotNet System.String value as an operand (issue 154 item 3). Every statement is wrapped in a TryFunction and observed as ok:<Format of the result> or error:<text>|<code>.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.String"; NStrDn) { }
    }
}

codeunit 61403 "LT DotNetOp StringIn"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOp1(var Result: Text)
    var
        S: DotNet NStrDn;
        S2: DotNet NStrDn;
        Nothing: DotNet NStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S in ['abc', 'x']);
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
        S: DotNet NStrDn;
        S2: DotNet NStrDn;
        Nothing: DotNet NStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S in ['x', 'y']);
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
        S: DotNet NStrDn;
        S2: DotNet NStrDn;
        Nothing: DotNet NStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S in ['ABC']);
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
        S: DotNet NStrDn;
        S2: DotNet NStrDn;
        Nothing: DotNet NStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S in ['abc']);
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
        S: DotNet NStrDn;
        S2: DotNet NStrDn;
        Nothing: DotNet NStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S in ['a' .. 'b']);
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
        Observer.Observe('in_case', Out3());
        Observer.Observe('in_single', Out4());
        Observer.Observe('in_range', Out5());
        Observer.Expect('in_hit', 'ok:Yes');
        Observer.Expect('in_miss', 'ok:No');
        Observer.Expect('in_case', 'ok:No');
        Observer.Expect('in_single', 'ok:Yes');
        Observer.Expect('in_range', 'ok:Yes');
        Observer.Verify();
    end;
}
