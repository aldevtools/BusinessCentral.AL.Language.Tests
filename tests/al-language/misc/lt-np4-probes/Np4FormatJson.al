// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-asinteger-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Writer NP4 (NP lane, 2026-10-30), codeunit 93401. Probe: (1) Format of a Decimal with the format string '<Precision,3:3><Sign><Integer><Decimals><Comma,.>' and other
//   <Comma,x> characters (the existing tests pin only the form with a comma); (2) JsonValue.AsInteger of decimal values with a fraction (set with SetValue
//   and read from text): the integer it gives or the error text.
// BC versions: 27, 28, 29

codeunit 93401 "LT NP4 Format Json"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure F(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Decimal; Fmt: Text)
    begin
        Observer.Observe(Name, '[' + Format(Value, 0, Fmt) + ']');
    end;

    [Test]
    procedure NP4_Format_Precision33_CommaDot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        F(Observer, 'pos', 1234.5678, '<Precision,3:3><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'whole', 1234, '<Precision,3:3><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'half', 1234.5, '<Precision,3:3><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'neg', -1234.5678, '<Precision,3:3><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'small', 0.1234, '<Precision,3:3><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'zero', 0, '<Precision,3:3><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'big', 1234567.891, '<Precision,3:3><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'round', 1.0005, '<Precision,3:3><Sign><Integer><Decimals><Comma,.>');
        Observer.Finish();
    end;

    [Test]
    procedure NP4_Format_Precision33_OtherCommaChars()
    var
        Observer: Codeunit "Probe Observer";
    begin
        F(Observer, 'comma', 1234.5678, '<Precision,3:3><Sign><Integer><Decimals><Comma,,>');
        F(Observer, 'semicolon', 1234.5678, '<Precision,3:3><Sign><Integer><Decimals><Comma,;>');
        F(Observer, 'space', 1234.5678, '<Precision,3:3><Sign><Integer><Decimals><Comma, >');
        F(Observer, 'letter', 1234.5678, '<Precision,3:3><Sign><Integer><Decimals><Comma,x>');
        F(Observer, 'dot_2_2', 1234.5678, '<Precision,2:2><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'dot_0_3', 1234.5678, '<Precision,0:3><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'dot_3_5', 1234.5678, '<Precision,3:5><Sign><Integer><Decimals><Comma,.>');
        F(Observer, 'dot_integer_sep', 1234567.891, '<Precision,3:3><Sign><Integer Thousand><Decimals><Comma,.>');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAsInteger(Value: JsonValue; var Result: Integer)
    begin
        Result := Value.AsInteger();
    end;

    local procedure Int(var Observer: Codeunit "Probe Observer"; Name: Text; Value: JsonValue)
    var
        R: Integer;
    begin
        if TryAsInteger(Value, R) then
            Observer.Observe(Name, 'ok|' + Format(R))
        else begin
            Observer.Observe(Name, CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode(), 1, 500));
            ClearLastError();
        end;
    end;

    local procedure FromText(Txt: Text): JsonValue
    var
        Token: JsonToken;
    begin
        Token.ReadFrom(Txt);
        exit(Token.AsValue());
    end;

    [Test]
    procedure NP4_JsonValue_AsInteger_SetValueDecimal()
    var
        Observer: Codeunit "Probe Observer";
        V: JsonValue;
    begin
        V.SetValue(1324.55);
        Int(Observer, 'set 1324.55', V);
        V.SetValue(2.5);
        Int(Observer, 'set 2.5', V);
        V.SetValue(1.5);
        Int(Observer, 'set 1.5', V);
        V.SetValue(0.5);
        Int(Observer, 'set 0.5', V);
        V.SetValue(0.4);
        Int(Observer, 'set 0.4', V);
        V.SetValue(-0.5);
        Int(Observer, 'set -0.5', V);
        V.SetValue(-1.5);
        Int(Observer, 'set -1.5', V);
        V.SetValue(-2.5);
        Int(Observer, 'set -2.5', V);
        V.SetValue(-1324.55);
        Int(Observer, 'set -1324.55', V);
        V.SetValue(3.4999);
        Int(Observer, 'set 3.4999', V);
        Observer.Finish();
    end;

    [Test]
    procedure NP4_JsonValue_AsInteger_FromText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Int(Observer, 'text 1324.55', FromText('1324.55'));
        Int(Observer, 'text 2.5', FromText('2.5'));
        Int(Observer, 'text 1.5', FromText('1.5'));
        Int(Observer, 'text 0.4', FromText('0.4'));
        Int(Observer, 'text -1.5', FromText('-1.5'));
        Int(Observer, 'text -0.4', FromText('-0.4'));
        Int(Observer, 'text 7', FromText('7'));
        Int(Observer, 'text 1e2', FromText('1e2'));
        Observer.Finish();
    end;
}
