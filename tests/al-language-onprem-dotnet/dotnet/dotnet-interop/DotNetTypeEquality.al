// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdotnettype-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61442
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): Type.Equals(Type) on two GetDotNetType results held in DotNet Type variables
//
// Relations between the GetDotNetType results of two AL values, compared with Type.Equals through DotNet variables (issue 154 item 1).
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Type"; EqType) { }
        type("System.String"; EqStr) { }
    }
}

codeunit 61442 "LT DotNetType Equality"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInt_Int(var Result: Text)
    var
        A: Integer;
        B: Integer;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryInt_BigInt(var Result: Text)
    var
        A: Integer;
        B: BigInteger;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryInt_Dec(var Result: Text)
    var
        A: Integer;
        B: Decimal;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryDec_Dec(var Result: Text)
    var
        A: Decimal;
        B: Decimal;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryInt_Text(var Result: Text)
    var
        A: Integer;
        B: Text;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryText_Text(var Result: Text)
    var
        A: Text;
        B: Text;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryText_Code(var Result: Text)
    var
        A: Text;
        B: Code[20];
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryText_Code_Same(var Result: Text)
    var
        A: Code[20];
        B: Code[20];
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryBool_Bool(var Result: Text)
    var
        A: Boolean;
        B: Boolean;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryBool_Int(var Result: Text)
    var
        A: Boolean;
        B: Integer;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryDate_Date(var Result: Text)
    var
        A: Date;
        B: Date;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryDate_DateTime(var Result: Text)
    var
        A: Date;
        B: DateTime;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryDateTime_DateTime(var Result: Text)
    var
        A: DateTime;
        B: DateTime;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryTime_DateTime(var Result: Text)
    var
        A: Time;
        B: DateTime;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryGuid_Guid(var Result: Text)
    var
        A: Guid;
        B: Guid;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryGuid_Text(var Result: Text)
    var
        A: Guid;
        B: Text;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        TA := GetDotNetType(A);
        TB := GetDotNetType(B);
        Result := Format(TA.Equals(TB)) + '|' + Format(TB.Equals(TA));
    end;

    [TryFunction]
    local procedure TryAgainstClrString(var Result: Text)
    var
        T: Text;
        S: DotNet EqStr;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        S := 'abc';
        TA := GetDotNetType(T);
        TB := S.GetType();
        Result := 'text_vs_clr_string=' + Format(TA.Equals(TB)) + ' fullnames=' + TA.FullName + '/' + TB.FullName;
    end;

    [TryFunction]
    local procedure TryVariantVsDirect(var Result: Text)
    var
        I: Integer;
        V: Variant;
        TA: DotNet EqType;
        TB: DotNet EqType;
    begin
        V := 5;
        TA := GetDotNetType(I);
        TB := GetDotNetType(V);
        Result := Format(TA.Equals(TB)) + '|self=' + Format(TA.Equals(TA));
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Result: Text)
    begin
        if Ok then
            Observer.Observe(Name, Result)
        else
            Observer.Observe(Name + '_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure TypeEquals_AlValuePairs_ResultBothWays()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        ClearLastError();
        Report(Observer, 'Int_Int', TryInt_Int(Result), Result);
        Report(Observer, 'Int_BigInt', TryInt_BigInt(Result), Result);
        Report(Observer, 'Int_Dec', TryInt_Dec(Result), Result);
        Report(Observer, 'Dec_Dec', TryDec_Dec(Result), Result);
        Report(Observer, 'Int_Text', TryInt_Text(Result), Result);
        Report(Observer, 'Text_Text', TryText_Text(Result), Result);
        Report(Observer, 'Text_Code', TryText_Code(Result), Result);
        Report(Observer, 'Text_Code_Same', TryText_Code_Same(Result), Result);
        Report(Observer, 'Bool_Bool', TryBool_Bool(Result), Result);
        Report(Observer, 'Bool_Int', TryBool_Int(Result), Result);
        Report(Observer, 'Date_Date', TryDate_Date(Result), Result);
        Report(Observer, 'Date_DateTime', TryDate_DateTime(Result), Result);
        Report(Observer, 'DateTime_DateTime', TryDateTime_DateTime(Result), Result);
        Report(Observer, 'Time_DateTime', TryTime_DateTime(Result), Result);
        Report(Observer, 'Guid_Guid', TryGuid_Guid(Result), Result);
        Report(Observer, 'Guid_Text', TryGuid_Text(Result), Result);
        Observer.Expect('Int_Int', 'Yes|Yes');
        Observer.Expect('Int_BigInt', 'No|No');
        Observer.Expect('Int_Dec', 'No|No');
        Observer.Expect('Dec_Dec', 'Yes|Yes');
        Observer.Expect('Int_Text', 'No|No');
        Observer.Expect('Text_Text', 'Yes|Yes');
        Observer.Expect('Text_Code', 'Yes|Yes');
        Observer.Expect('Text_Code_Same', 'Yes|Yes');
        Observer.Expect('Bool_Bool', 'Yes|Yes');
        Observer.Expect('Bool_Int', 'No|No');
        Observer.Expect('Date_Date', 'Yes|Yes');
        Observer.Expect('Date_DateTime', 'Yes|Yes');
        Observer.Expect('DateTime_DateTime', 'Yes|Yes');
        Observer.Expect('Time_DateTime', 'Yes|Yes');
        Observer.Expect('Guid_Guid', 'Yes|Yes');
        Observer.Expect('Guid_Text', 'No|No');
        Observer.Verify();
    end;

    [Test]
    procedure TypeEquals_VariantAndClrString_Result()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        ClearLastError();
        Report(Observer, 'text_vs_clr_string', TryAgainstClrString(Result), Result);
        ClearLastError();
        Report(Observer, 'variant_vs_direct', TryVariantVsDirect(Result), Result);
        Observer.Expect('text_vs_clr_string', 'text_vs_clr_string=Yes fullnames=System.String/System.String');
        Observer.Expect('variant_vs_direct', 'Yes|self=Yes');
        Observer.Verify();
    end;
}
