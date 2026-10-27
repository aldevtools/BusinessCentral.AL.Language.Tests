// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope (OnPrem DotNet app)
// Fixtures used: Probe Observer (69160); own dotnet aliases LtSgE*; test codeunit 99421 (writer SG)
// Probe: a DotNet enum value stored into AL types: Integer (from a DotNet enum variable, from a property that returns an enum, a flags
// value, Newtonsoft JToken.Type), BigInteger, Text, Variant; passed as an Integer argument; compared with an Integer.
// Decimal := enum does not compile (AL0122 Cannot implicitly convert type 'DotNet "System.DayOfWeek"' to 'Decimal', all three legs).
// Observed on the corpus CI matrix (27.5, 28.5, 29.0).
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.DayOfWeek"; LtSgEDayOfWeek) { }
        type("System.DateTime"; LtSgEDateTime) { }
        type("System.Globalization.NumberStyles"; LtSgENumberStyles) { }
    }
    assembly("Newtonsoft.Json")
    {
        type("Newtonsoft.Json.Linq.JToken"; LtSgEJToken) { }
        type("Newtonsoft.Json.Linq.JTokenType"; LtSgEJTokenType) { }
    }
}

codeunit 99421 "LT SG DotNet Enum Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TakesInteger(Value: Integer): Text
    begin
        exit(Format(Value));
    end;

    [TryFunction]
    local procedure TryToInteger(Day: DotNet LtSgEDayOfWeek; var Result: Integer)
    begin
        Result := Day;
    end;

    [Test]
    procedure SG_DotNetEnum_IntoInteger()
    var
        Observer: Codeunit "Probe Observer";
        Day: DotNet LtSgEDayOfWeek;
        When: DotNet LtSgEDateTime;
        Styles: DotNet LtSgENumberStyles;
        Number: Integer;
        Big: BigInteger;
        Txt: Text;
        V: Variant;
    begin
        Day := Day.Wednesday;
        Number := Day;
        Observer.Observe('variable Wednesday', Format(Number));
        When := When.DateTime(2024, 1, 14);
        Number := When.DayOfWeek;
        Observer.Observe('property DayOfWeek of a Sunday', Format(Number));
        Styles := Styles.AllowCurrencySymbol;
        Number := Styles;
        Observer.Observe('flags AllowCurrencySymbol', Format(Number));
        Styles := Styles.Number;
        Number := Styles;
        Observer.Observe('flags Number', Format(Number));
        Big := Day;
        Observer.Observe('BigInteger', Format(Big));
        Txt := Format(Day);
        Observer.Observe('Format', Txt);
        V := Day;
        Observer.Observe('Variant IsInteger', Format(V.IsInteger()));
        Observer.Observe('Variant IsDotNet', Format(V.IsDotNet()));
        Observer.Observe('argument', TakesInteger(Day));
        Observer.Observe('Integer = enum', Format(Number = Styles));
        ClearLastError();
        Observer.Observe('try ok', Format(TryToInteger(Day, Number)));
        Observer.Observe('try value', Format(Number));
        Observer.Finish();
    end;

    [Test]
    procedure SG_DotNetEnum_JTokenTypeIntoInteger()
    var
        Observer: Codeunit "Probe Observer";
        Token: DotNet LtSgEJToken;
        Kind: DotNet LtSgEJTokenType;
        Number: Integer;
    begin
        Token := Token.Parse('{"a":1}');
        Number := Token.Type;
        Observer.Observe('object', Format(Number));
        Token := Token.Parse('[1]');
        Number := Token.Type;
        Observer.Observe('array', Format(Number));
        Token := Token.Parse('"x"');
        Number := Token.Type;
        Observer.Observe('string', Format(Number));
        Kind := Token.Type;
        Observer.Observe('format of the enum', Format(Kind));
        Number := Kind;
        Observer.Observe('through a variable', Format(Number));
        Observer.Finish();
    end;
}
