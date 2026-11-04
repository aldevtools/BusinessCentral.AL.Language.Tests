// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getdotnettype-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61437
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (compile): GetDotNetType(Expression: Any) on every AL scalar kind; DotNet System.Type alias GsType
//
// GetDotNetType of an AL Integer, BigInteger, Decimal, Boolean, Byte, Char, Option, Text, Code, Date, Time, DateTime, Duration, Guid (issue 154 item 1): Type.FullName, Type.Name and Format of the Type, or the error.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Type"; GsType) { }
    }
}

codeunit 61437 "LT DotNetType Scalars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInteger(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Integer;
        T: DotNet GsType;
    begin
        X := 5;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutInteger(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryInteger(FullName, ShortName, Shown) then begin
            Observer.Observe('Integer_fullname', FullName);
            Observer.Observe('Integer_name', ShortName);
            Observer.Observe('Integer_format', Shown);
        end else
            Observer.Observe('Integer_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryBigInteger(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: BigInteger;
        T: DotNet GsType;
    begin
        X := 5;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutBigInteger(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryBigInteger(FullName, ShortName, Shown) then begin
            Observer.Observe('BigInteger_fullname', FullName);
            Observer.Observe('BigInteger_name', ShortName);
            Observer.Observe('BigInteger_format', Shown);
        end else
            Observer.Observe('BigInteger_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDecimal(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Decimal;
        T: DotNet GsType;
    begin
        X := 1.5;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutDecimal(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryDecimal(FullName, ShortName, Shown) then begin
            Observer.Observe('Decimal_fullname', FullName);
            Observer.Observe('Decimal_name', ShortName);
            Observer.Observe('Decimal_format', Shown);
        end else
            Observer.Observe('Decimal_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryBoolean(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Boolean;
        T: DotNet GsType;
    begin
        X := true;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutBoolean(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryBoolean(FullName, ShortName, Shown) then begin
            Observer.Observe('Boolean_fullname', FullName);
            Observer.Observe('Boolean_name', ShortName);
            Observer.Observe('Boolean_format', Shown);
        end else
            Observer.Observe('Boolean_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryByte(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Byte;
        T: DotNet GsType;
    begin
        X := 7;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutByte(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryByte(FullName, ShortName, Shown) then begin
            Observer.Observe('Byte_fullname', FullName);
            Observer.Observe('Byte_name', ShortName);
            Observer.Observe('Byte_format', Shown);
        end else
            Observer.Observe('Byte_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryChar(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Char;
        T: DotNet GsType;
    begin
        X := 65;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutChar(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryChar(FullName, ShortName, Shown) then begin
            Observer.Observe('Char_fullname', FullName);
            Observer.Observe('Char_name', ShortName);
            Observer.Observe('Char_format', Shown);
        end else
            Observer.Observe('Char_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryOption(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Option A,B,C;
        T: DotNet GsType;
    begin
        X := X::B;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutOption(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryOption(FullName, ShortName, Shown) then begin
            Observer.Observe('Option_fullname', FullName);
            Observer.Observe('Option_name', ShortName);
            Observer.Observe('Option_format', Shown);
        end else
            Observer.Observe('Option_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryText(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Text;
        T: DotNet GsType;
    begin
        X := 'abc';
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutText(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryText(FullName, ShortName, Shown) then begin
            Observer.Observe('Text_fullname', FullName);
            Observer.Observe('Text_name', ShortName);
            Observer.Observe('Text_format', Shown);
        end else
            Observer.Observe('Text_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryCode(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Code[20];
        T: DotNet GsType;
    begin
        X := 'ABC';
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutCode(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryCode(FullName, ShortName, Shown) then begin
            Observer.Observe('Code_fullname', FullName);
            Observer.Observe('Code_name', ShortName);
            Observer.Observe('Code_format', Shown);
        end else
            Observer.Observe('Code_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDate(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Date;
        T: DotNet GsType;
    begin
        X := DMY2Date(2, 1, 2020);
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutDate(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryDate(FullName, ShortName, Shown) then begin
            Observer.Observe('Date_fullname', FullName);
            Observer.Observe('Date_name', ShortName);
            Observer.Observe('Date_format', Shown);
        end else
            Observer.Observe('Date_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryTime(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Time;
        T: DotNet GsType;
    begin
        X := 030405T;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutTime(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryTime(FullName, ShortName, Shown) then begin
            Observer.Observe('Time_fullname', FullName);
            Observer.Observe('Time_name', ShortName);
            Observer.Observe('Time_format', Shown);
        end else
            Observer.Observe('Time_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDateTime(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: DateTime;
        T: DotNet GsType;
    begin
        X := CreateDateTime(DMY2Date(2, 1, 2020), 030405T);
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutDateTime(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryDateTime(FullName, ShortName, Shown) then begin
            Observer.Observe('DateTime_fullname', FullName);
            Observer.Observe('DateTime_name', ShortName);
            Observer.Observe('DateTime_format', Shown);
        end else
            Observer.Observe('DateTime_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDuration(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Duration;
        T: DotNet GsType;
    begin
        X := 1000;
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutDuration(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryDuration(FullName, ShortName, Shown) then begin
            Observer.Observe('Duration_fullname', FullName);
            Observer.Observe('Duration_name', ShortName);
            Observer.Observe('Duration_format', Shown);
        end else
            Observer.Observe('Duration_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryGuid(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Guid;
        T: DotNet GsType;
    begin
        X := '{12345678-1234-1234-1234-123456789ABC}';
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutGuid(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryGuid(FullName, ShortName, Shown) then begin
            Observer.Observe('Guid_fullname', FullName);
            Observer.Observe('Guid_name', ShortName);
            Observer.Observe('Guid_format', Shown);
        end else
            Observer.Observe('Guid_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEmptyText(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Text;
        T: DotNet GsType;
    begin
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutEmptyText(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryEmptyText(FullName, ShortName, Shown) then begin
            Observer.Observe('EmptyText_fullname', FullName);
            Observer.Observe('EmptyText_name', ShortName);
            Observer.Observe('EmptyText_format', Shown);
        end else
            Observer.Observe('EmptyText_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEmptyDate(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Date;
        T: DotNet GsType;
    begin
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutEmptyDate(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryEmptyDate(FullName, ShortName, Shown) then begin
            Observer.Observe('EmptyDate_fullname', FullName);
            Observer.Observe('EmptyDate_name', ShortName);
            Observer.Observe('EmptyDate_format', Shown);
        end else
            Observer.Observe('EmptyDate_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryZeroInteger(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Integer;
        T: DotNet GsType;
    begin
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutZeroInteger(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryZeroInteger(FullName, ShortName, Shown) then begin
            Observer.Observe('ZeroInteger_fullname', FullName);
            Observer.Observe('ZeroInteger_name', ShortName);
            Observer.Observe('ZeroInteger_format', Shown);
        end else
            Observer.Observe('ZeroInteger_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEmptyGuid(var FullName: Text; var ShortName: Text; var Shown: Text)
    var
        X: Guid;
        T: DotNet GsType;
    begin
        T := GetDotNetType(X);
        FullName := T.FullName;
        ShortName := T.Name;
        Shown := Format(T);
    end;

    local procedure OutEmptyGuid(var Observer: Codeunit "Probe Observer")
    var
        FullName: Text;
        ShortName: Text;
        Shown: Text;
    begin
        ClearLastError();
        if TryEmptyGuid(FullName, ShortName, Shown) then begin
            Observer.Observe('EmptyGuid_fullname', FullName);
            Observer.Observe('EmptyGuid_name', ShortName);
            Observer.Observe('EmptyGuid_format', Shown);
        end else
            Observer.Observe('EmptyGuid_error', GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure GetDotNetType_NumericAndBoolean_FullNameNameFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OutInteger(Observer);
        OutBigInteger(Observer);
        OutDecimal(Observer);
        OutBoolean(Observer);
        OutByte(Observer);
        OutChar(Observer);
        OutOption(Observer);
        Observer.Expect('Integer_fullname', 'System.Int32');
        Observer.Expect('Integer_name', 'Int32');
        Observer.Expect('Integer_format', 'System.Int32');
        Observer.Expect('BigInteger_fullname', 'System.Int64');
        Observer.Expect('BigInteger_name', 'Int64');
        Observer.Expect('BigInteger_format', 'System.Int64');
        Observer.Expect('Decimal_fullname', 'System.Decimal');
        Observer.Expect('Decimal_name', 'Decimal');
        Observer.Expect('Decimal_format', 'System.Decimal');
        Observer.Expect('Boolean_fullname', 'System.Boolean');
        Observer.Expect('Boolean_name', 'Boolean');
        Observer.Expect('Boolean_format', 'System.Boolean');
        Observer.Expect('Byte_fullname', 'System.Byte');
        Observer.Expect('Byte_name', 'Byte');
        Observer.Expect('Byte_format', 'System.Byte');
        Observer.Expect('Char_fullname', 'System.Char');
        Observer.Expect('Char_name', 'Char');
        Observer.Expect('Char_format', 'System.Char');
        Observer.Expect('Option_fullname', 'System.Int32');
        Observer.Expect('Option_name', 'Int32');
        Observer.Expect('Option_format', 'System.Int32');
        Observer.Verify();
    end;

    [Test]
    procedure GetDotNetType_TextAndTemporal_FullNameNameFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OutText(Observer);
        OutCode(Observer);
        OutDate(Observer);
        OutTime(Observer);
        OutDateTime(Observer);
        OutDuration(Observer);
        OutGuid(Observer);
        Observer.Expect('Text_fullname', 'System.String');
        Observer.Expect('Text_name', 'String');
        Observer.Expect('Text_format', 'System.String');
        Observer.Expect('Code_fullname', 'System.String');
        Observer.Expect('Code_name', 'String');
        Observer.Expect('Code_format', 'System.String');
        Observer.Expect('Date_fullname', 'System.DateTime');
        Observer.Expect('Date_name', 'DateTime');
        Observer.Expect('Date_format', 'System.DateTime');
        Observer.Expect('Time_fullname', 'System.DateTime');
        Observer.Expect('Time_name', 'DateTime');
        Observer.Expect('Time_format', 'System.DateTime');
        Observer.Expect('DateTime_fullname', 'System.DateTime');
        Observer.Expect('DateTime_name', 'DateTime');
        Observer.Expect('DateTime_format', 'System.DateTime');
        Observer.Expect('Duration_fullname', 'System.TimeSpan');
        Observer.Expect('Duration_name', 'TimeSpan');
        Observer.Expect('Duration_format', 'System.TimeSpan');
        Observer.Expect('Guid_fullname', 'System.Guid');
        Observer.Expect('Guid_name', 'Guid');
        Observer.Expect('Guid_format', 'System.Guid');
        Observer.Verify();
    end;

    [Test]
    procedure GetDotNetType_DefaultValues_FullName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        OutEmptyText(Observer);
        OutEmptyDate(Observer);
        OutZeroInteger(Observer);
        OutEmptyGuid(Observer);
        Observer.Expect('EmptyText_fullname', 'System.String');
        Observer.Expect('EmptyText_name', 'String');
        Observer.Expect('EmptyText_format', 'System.String');
        Observer.Expect('EmptyDate_fullname', 'System.DateTime');
        Observer.Expect('EmptyDate_name', 'DateTime');
        Observer.Expect('EmptyDate_format', 'System.DateTime');
        Observer.Expect('ZeroInteger_fullname', 'System.Int32');
        Observer.Expect('ZeroInteger_name', 'Int32');
        Observer.Expect('ZeroInteger_format', 'System.Int32');
        Observer.Expect('EmptyGuid_fullname', 'System.Guid');
        Observer.Expect('EmptyGuid_name', 'Guid');
        Observer.Expect('EmptyGuid_format', 'System.Guid');
        Observer.Verify();
    end;
}
