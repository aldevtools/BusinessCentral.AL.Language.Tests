// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdotnettype-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61438
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): GetDotNetType(Variant) holding each kind; an empty Variant
//
// GetDotNetType of a Variant holding an Integer, BigInteger, Decimal, Boolean, Text, Code, Date, DateTime, Guid, Duration and of an empty Variant (issue 154 item 1).
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Type"; VtType) { }
    }
}

codeunit 61438 "LT DotNetType Variant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInteger(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        V := 5;
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryBigInteger(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        B := 5; V := B;
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryDecimal(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        V := 1.5;
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryBoolean(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        V := true;
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryText(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        V := 'abc';
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryCode(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        C := 'ABC'; V := C;
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryDate(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        V := DMY2Date(2, 1, 2020);
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryDateTime(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        V := CreateDateTime(DMY2Date(2, 1, 2020), 030405T);
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryGuid(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        G := '{12345678-1234-1234-1234-123456789ABC}'; V := G;
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryDuration(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        U := 1000; V := U;
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    [TryFunction]
    local procedure TryEmpty(var FullName: Text; var Shown: Text)
    var
        V: Variant;
        B: BigInteger;
        C: Code[10];
        G: Guid;
        U: Duration;
        T: DotNet VtType;
    begin
        
        T := GetDotNetType(V);
        FullName := T.FullName;
        Shown := Format(T);
    end;

    local procedure Report(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; FullName: Text; Shown: Text)
    begin
        if Ok then
            Observer.Observe(Name, FullName + '|' + Shown)
        else
            Observer.Observe(Name + '_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure GetDotNetType_VariantHoldingAlValue_FullNameAndFormat()
    var
        Observer: Codeunit "Probe Observer";
        FullName: Text;
        Shown: Text;
    begin
        ClearLastError();
        Report(Observer, 'Integer', TryInteger(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'BigInteger', TryBigInteger(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'Decimal', TryDecimal(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'Boolean', TryBoolean(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'Text', TryText(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'Code', TryCode(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'Date', TryDate(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'DateTime', TryDateTime(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'Guid', TryGuid(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'Duration', TryDuration(FullName, Shown), FullName, Shown);
        ClearLastError();
        Report(Observer, 'Empty', TryEmpty(FullName, Shown), FullName, Shown);
        Observer.Expect('Integer', 'System.Int32|System.Int32');
        Observer.Expect('BigInteger', 'System.Decimal|System.Decimal');
        Observer.Expect('Decimal', 'System.Decimal|System.Decimal');
        Observer.Expect('Boolean', 'System.Boolean|System.Boolean');
        Observer.Expect('Text', 'System.String|System.String');
        Observer.Expect('Code', 'System.String|System.String');
        Observer.Expect('Date', 'System.DateTime|System.DateTime');
        Observer.Expect('DateTime', 'System.DateTime|System.DateTime');
        Observer.Expect('Guid', 'System.Guid|System.Guid');
        Observer.Expect('Duration', 'System.TimeSpan|System.TimeSpan');
        Observer.Expect('Empty', 'System.Object|System.Object');
        Observer.Verify();
    end;
}
