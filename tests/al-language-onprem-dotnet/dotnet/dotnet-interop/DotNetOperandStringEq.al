// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61401
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): operands = <> + - * / between a DotNet String variable and an AL value
//
// A DotNet System.String value as an operand (issue 154 item 3). Every statement is wrapped in a TryFunction and observed as ok:<Format of the result> or error:<text>|<code>.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.String"; EStrDn) { }
    }
}

codeunit 61401 "LT DotNetOp StringEq"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryOp1(var Result: Text)
    var
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S = 'abc');
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S = 'ABC');
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S = T);
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format('abc' = S);
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S = C);
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S <> 'abd');
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S <> 'abc');
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(Nothing = '');
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(Nothing <> '');
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S + 'x');
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format('x' + S);
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S + T);
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S + C);
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(Nothing + 'x');
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
        S: DotNet EStrDn;
        S2: DotNet EStrDn;
        Nothing: DotNet EStrDn;
        T: Text;
        C: Code[10];
        I: Integer;
    begin
        S := 'abc';
        S2 := 'abd';
        T := 'abc';
        C := 'ABC';
        I := 1;
        Result := Format(S + '-' + T);
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
    procedure Equal_TextShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('eq_same', Out1());
        Observer.Observe('eq_other_case', Out2());
        Observer.Observe('eq_text_variable', Out3());
        Observer.Observe('eq_reversed', Out4());
        Observer.Observe('eq_code_variable', Out5());
        Observer.Observe('ne_other', Out6());
        Observer.Observe('ne_same', Out7());
        Observer.Observe('eq_unassigned_empty', Out8());
        Observer.Observe('ne_unassigned_empty', Out9());
        Observer.Expect('eq_same', 'ok:Yes');
        Observer.Expect('eq_other_case', 'ok:No');
        Observer.Expect('eq_text_variable', 'ok:Yes');
        Observer.Expect('eq_reversed', 'ok:Yes');
        Observer.Expect('eq_code_variable', 'ok:No');
        Observer.Expect('ne_other', 'ok:Yes');
        Observer.Expect('ne_same', 'ok:No');
        Observer.Expect('eq_unassigned_empty', 'ok:Yes');
        Observer.Expect('ne_unassigned_empty', 'ok:No');
        Observer.Verify();
    end;

    [Test]
    procedure Plus_TextShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('plus_text', Out10());
        Observer.Observe('plus_reversed', Out11());
        Observer.Observe('plus_text_variable', Out12());
        Observer.Observe('plus_code_variable', Out13());
        Observer.Observe('plus_unassigned', Out14());
        Observer.Observe('plus_chain', Out15());
        Observer.Expect('plus_text', 'ok:abcx');
        Observer.Expect('plus_reversed', 'ok:xabc');
        Observer.Expect('plus_text_variable', 'ok:abcabc');
        Observer.Expect('plus_code_variable', 'ok:abcABC');
        Observer.Expect('plus_unassigned', 'ok:x');
        Observer.Expect('plus_chain', 'ok:abc-abc');
        Observer.Verify();
    end;
}
