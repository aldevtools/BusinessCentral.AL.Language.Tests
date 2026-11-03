// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdotnettype-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61441
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): GetDotNetType(DotNet variable); X.GetType() on an unassigned variable; DotNet System.Object alias
//
// GetDotNetType of an assigned DotNet variable (String, StringBuilder, DateTime, enum, TimeSpan, Guid), of an unassigned one, of a Variant holding a DotNet object and of CLR results converted to AL kinds (issue 154 item 1).
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Type"; OdType) { }
        type("System.String"; OdStr) { }
        type("System.Text.StringBuilder"; OdBuilder) { }
        type("System.DateTime"; OdDtm) { }
        type("System.DayOfWeek"; OdDay) { }
        type("System.TimeSpan"; OdSpan) { }
        type("System.Guid"; OdGuid) { }
        type("System.Convert"; OdConv) { }
        type("System.Object"; OdObj) { }
    }
}

codeunit 61441 "LT DotNetType OfDotNet"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryString(var FullName: Text; var ShortName: Text; var Shown: Text; var SameAsGetType: Text)
    var
        X: DotNet OdStr;
        T: DotNet OdType;
        Own: DotNet OdType;
    begin
        X := 'abc';
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
        Own := X.GetType();
        SameAsGetType := Format(T.Equals(Own));
    end;

    [TryFunction]
    local procedure TryStringBuilder(var FullName: Text; var ShortName: Text; var Shown: Text; var SameAsGetType: Text)
    var
        X: DotNet OdBuilder;
        T: DotNet OdType;
        Own: DotNet OdType;
    begin
        X := X.StringBuilder();
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
        Own := X.GetType();
        SameAsGetType := Format(T.Equals(Own));
    end;

    [TryFunction]
    local procedure TryDateTime(var FullName: Text; var ShortName: Text; var Shown: Text; var SameAsGetType: Text)
    var
        X: DotNet OdDtm;
        T: DotNet OdType;
        Own: DotNet OdType;
    begin
        X := X.DateTime(2020, 1, 2, 3, 4, 5);
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
        Own := X.GetType();
        SameAsGetType := Format(T.Equals(Own));
    end;

    [TryFunction]
    local procedure TryEnum(var FullName: Text; var ShortName: Text; var Shown: Text; var SameAsGetType: Text)
    var
        X: DotNet OdDay;
        T: DotNet OdType;
        Own: DotNet OdType;
    begin
        X := X.Monday;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
        Own := X.GetType();
        SameAsGetType := Format(T.Equals(Own));
    end;

    [TryFunction]
    local procedure TryTimeSpan(var FullName: Text; var ShortName: Text; var Shown: Text; var SameAsGetType: Text)
    var
        X: DotNet OdSpan;
        T: DotNet OdType;
        Own: DotNet OdType;
    begin
        X := X.Parse('00:01:30');
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
        Own := X.GetType();
        SameAsGetType := Format(T.Equals(Own));
    end;

    [TryFunction]
    local procedure TryGuid(var FullName: Text; var ShortName: Text; var Shown: Text; var SameAsGetType: Text)
    var
        X: DotNet OdGuid;
        T: DotNet OdType;
        Own: DotNet OdType;
    begin
        X := X.NewGuid();
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
        Own := X.GetType();
        SameAsGetType := Format(T.Equals(Own));
    end;

    [TryFunction]
    local procedure TryUnassigned(var FullName: Text; var ShortName: Text; var Shown: Text; var SameAsGetType: Text)
    var
        X: DotNet OdObj;
        T: DotNet OdType;
        Own: DotNet OdType;
    begin
        
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
        Own := X.GetType();
        SameAsGetType := Format(T.Equals(Own));
    end;

    [TryFunction]
    local procedure TryConvResult(var FullName: Text)
    var
        Conv: DotNet OdConv;
        I: Integer;
        V: Variant;
        T: DotNet OdType;
    begin
        I := Conv.ToInt32('5');
        T := GetDotNetType(I);
        FullName := 'assigned_to_integer=' + T.FullName;
        V := Conv.ToInt32('5');
        T := GetDotNetType(V);
        FullName += ' variant=' + T.FullName;
        V := Conv.ToString(5);
        T := GetDotNetType(V);
        FullName += ' string_variant=' + T.FullName;
    end;

    [TryFunction]
    local procedure TryVariantHoldingDotNet(var FullName: Text)
    var
        Builder: DotNet OdBuilder;
        V: Variant;
        T: DotNet OdType;
    begin
        Builder := Builder.StringBuilder();
        V := Builder;
        T := GetDotNetType(V);
        FullName := T.FullName;
    end;

    [Test]
    procedure GetDotNetType_DotNetVariable_FullNameNameFormatEqualsGetType()
    var
        Observer: Codeunit "Probe Observer";
        FullName: Text;
        ShortName: Text;
        Shown: Text;
        Same: Text;
    begin
        ClearLastError();
        if TryString(FullName, ShortName, Shown, Same) then
            Observer.Observe('String', FullName + '|' + ShortName + '|' + Shown + '|equals_gettype=' + Same)
        else
            Observer.Observe('String_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryStringBuilder(FullName, ShortName, Shown, Same) then
            Observer.Observe('StringBuilder', FullName + '|' + ShortName + '|' + Shown + '|equals_gettype=' + Same)
        else
            Observer.Observe('StringBuilder_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryDateTime(FullName, ShortName, Shown, Same) then
            Observer.Observe('DateTime', FullName + '|' + ShortName + '|' + Shown + '|equals_gettype=' + Same)
        else
            Observer.Observe('DateTime_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryEnum(FullName, ShortName, Shown, Same) then
            Observer.Observe('Enum', FullName + '|' + ShortName + '|' + Shown + '|equals_gettype=' + Same)
        else
            Observer.Observe('Enum_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryTimeSpan(FullName, ShortName, Shown, Same) then
            Observer.Observe('TimeSpan', FullName + '|' + ShortName + '|' + Shown + '|equals_gettype=' + Same)
        else
            Observer.Observe('TimeSpan_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryGuid(FullName, ShortName, Shown, Same) then
            Observer.Observe('Guid', FullName + '|' + ShortName + '|' + Shown + '|equals_gettype=' + Same)
        else
            Observer.Observe('Guid_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryUnassigned(FullName, ShortName, Shown, Same) then
            Observer.Observe('Unassigned', FullName + '|' + ShortName + '|' + Shown + '|equals_gettype=' + Same)
        else
            Observer.Observe('Unassigned_error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('String', 'System.String|String|System.String|equals_gettype=Yes');
        Observer.Expect('StringBuilder', 'System.Text.StringBuilder|StringBuilder|System.Text.StringBuilder|equals_gettype=Yes');
        Observer.Expect('DateTime', 'System.DateTime|DateTime|System.DateTime|equals_gettype=Yes');
        Observer.Expect('Enum', 'System.DayOfWeek|DayOfWeek|System.DayOfWeek|equals_gettype=Yes');
        Observer.Expect('TimeSpan', 'System.TimeSpan|TimeSpan|System.TimeSpan|equals_gettype=Yes');
        Observer.Expect('Guid', 'System.Guid|Guid|System.Guid|equals_gettype=Yes');
        Observer.Expect('Unassigned_error', 'A DotNet variable has not been instantiated. Attempting to call System.Object.GetType in CodeUnit LT DotNetType OfDotNet: TryUnassigned|DotNetVariableNotCreated');
        Observer.Verify();
    end;

    [Test]
    procedure GetDotNetType_ClrResultAndVariantHoldingDotNet_FullName()
    var
        Observer: Codeunit "Probe Observer";
        FullName: Text;
    begin
        ClearLastError();
        if TryConvResult(FullName) then
            Observer.Observe('clr_results', FullName)
        else
            Observer.Observe('clr_results_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryVariantHoldingDotNet(FullName) then
            Observer.Observe('variant_holding_dotnet', FullName)
        else
            Observer.Observe('variant_holding_dotnet_error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('clr_results', 'assigned_to_integer=System.Int32 variant=System.Int32 string_variant=System.String');
        Observer.Expect('variant_holding_dotnet_error', 'GetDotNetType() does not support the type Microsoft.Dynamics.Nav.Runtime.NavVariant.|NotSupportedType');
        Observer.Verify();
    end;
}
