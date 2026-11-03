// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74410
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonValue ReadFrom each JSON scalar and invalid text, SelectToken, WriteTo
// BC versions: 29

codeunit 74410 "LT P88 Value ReadFrom"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryRead(Src: Text; var R: Text)
    var
        V: JsonValue;
        Txt: Text;
    begin
        V.ReadFrom(Src);
        V.WriteTo(Txt);
        R := 'null=' + Format(V.IsNull()) + ' undef=' + Format(V.IsUndefined()) + ' text=' + V.AsText() + ' json=' + Txt;
    end;

    local procedure Rd(Name: Text; Src: Text)
    var
        R: Text;
    begin
        if TryRead(Src, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure ReadFrom_Scalars()
    begin
        Rd('int', '42');
        Rd('negint', '-7');
        Rd('zero', '0');
        Rd('decimal', '1.50');
        Rd('exp', '1e3');
        Rd('bigint', '9007199254740993');
        Rd('true', 'true');
        Rd('false', 'false');
        Rd('null', 'null');
        Rd('string', '"hello"');
        Rd('string_empty', '""');
        Rd('string_escapes', '"a\"b\\c\n"');
        Rd('string_unicode', '"\u00fc"');
        Rd('string_date', '"2024-03-15"');
        Rd('string_datetime', '"2024-03-15T14:30:15Z"');
        Rd('leading_space', '  5  ');
        Observer.Expect('int', 'null=No undef=No text=42 json=42');
        Observer.Expect('negint', 'null=No undef=No text=-7 json=-7');
        Observer.Expect('zero', 'null=No undef=No text=0 json=0');
        Observer.Expect('decimal', 'null=No undef=No text=1.5 json=1.5');
        Observer.Expect('exp', 'null=No undef=No text=1000 json=1000.0');
        Observer.Expect('bigint', 'null=No undef=No text=9007199254740993 json=9007199254740993');
        Observer.Expect('true', 'null=No undef=No text=true json=true');
        Observer.Expect('false', 'null=No undef=No text=false json=false');
        Observer.Expect('null|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('null|code', 'Conversion');
        Observer.Expect('string', 'null=No undef=No text=hello json="hello"');
        Observer.Expect('string_empty', 'null=No undef=No text= json=""');
        Observer.Expect('string_escapes', 'null=No undef=No text=a"b\c\n json="a\"b\\c\n"');
        Observer.Expect('string_unicode', 'null=No undef=No text=ü json="ü"');
        Observer.Expect('string_date', 'null=No undef=No text=2024-03-15 json="2024-03-15"');
        Observer.Expect('string_datetime', 'null=No undef=No text=2024-03-15T14:30:15Z json="2024-03-15T14:30:15Z"');
        Observer.Expect('leading_space', 'null=No undef=No text=5 json=5');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_Invalid()
    begin
        Rd('empty', '');
        Rd('blank', ' ');
        Rd('bare_word', 'hello');
        Rd('single_quote', '''x''');
        Rd('unterminated', '"abc');
        Rd('two_values', '1 2');
        Rd('trailing_comma', '1,');
        Rd('upper_true', 'TRUE');
        Rd('nan', 'NaN');
        Rd('plus', '+1');
        Rd('leading_zero', '007');
        Observer.Expect('empty|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('empty|code', 'InvalidJsonData');
        Observer.Expect('blank|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('blank|code', 'InvalidJsonData');
        Observer.Expect('bare_word|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('bare_word|code', 'InvalidJsonData');
        Observer.Expect('single_quote', 'null=No undef=No text=x json="x"');
        Observer.Expect('unterminated|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('unterminated|code', 'InvalidJsonData');
        Observer.Expect('two_values', 'null=No undef=No text=1 json=1');
        Observer.Expect('trailing_comma', 'null=No undef=No text=1 json=1');
        Observer.Expect('upper_true|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('upper_true|code', 'InvalidJsonData');
        Observer.Expect('nan', 'null=No undef=No text=NaN json="NaN"');
        Observer.Expect('plus|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('plus|code', 'InvalidJsonData');
        Observer.Expect('leading_zero', 'null=No undef=No text=7 json=7');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_Containers()
    begin
        Rd('array', '[1,2]');
        Rd('object', '{"a":1}');
        Rd('empty_array', '[]');
        Rd('empty_object', '{}');
        Observer.Expect('array|text', 'JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('array|code', 'InvalidJsonType');
        Observer.Expect('object|text', 'JSON tokens of type ''Object'' are not supported by this implementation.');
        Observer.Expect('object|code', 'InvalidJsonType');
        Observer.Expect('empty_array|text', 'JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('empty_array|code', 'InvalidJsonType');
        Observer.Expect('empty_object|text', 'JSON tokens of type ''Object'' are not supported by this implementation.');
        Observer.Expect('empty_object|code', 'InvalidJsonType');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySel(V: JsonValue; P: Text; var R: Text)
    var
        T: JsonToken;
        Txt: Text;
        Found: Boolean;
    begin
        Found := V.SelectToken(P, T);
        T.WriteTo(Txt);
        R := Format(Found) + '|' + Txt;
    end;

    local procedure Sel(Name: Text; V: JsonValue; P: Text)
    var
        R: Text;
    begin
        if TrySel(V, P, R) then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure SelectToken_OnValue()
    var
        V: JsonValue;
    begin
        V.SetValue(42);
        Sel('sel_dollar', V, '$');
        Sel('sel_empty', V, '');
        Sel('sel_name', V, 'a');
        Sel('sel_idx0', V, '[0]');
        Sel('sel_wild', V, '*');
        Sel('sel_recursive', V, '$..a');
        Sel('sel_bad', V, '[');
        V.SetValue('text');
        Sel('sel_text_dollar', V, '$');
        V.SetValueToNull();
        Sel('sel_null_dollar', V, '$');
        Sel('sel_null_name', V, 'a');
        Observer.Expect('sel_dollar', 'Yes|42');
        Observer.Expect('sel_empty', 'Yes|42');
        Observer.Expect('sel_name', 'No|null');
        Observer.Expect('sel_idx0', 'No|null');
        Observer.Expect('sel_wild', 'No|null');
        Observer.Expect('sel_recursive', 'No|null');
        Observer.Expect('sel_bad', 'No|null');
        Observer.Expect('sel_text_dollar', 'Yes|"text"');
        Observer.Expect('sel_null_dollar', 'Yes|null');
        Observer.Expect('sel_null_name', 'No|null');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_OnValue()
    var
        V: JsonValue;
        Txt: Text;
    begin
        V.SetValue(42);
        V.WriteTo(Txt);
        Observer.Observe('int', Txt);
        V.SetValue('a "q" b');
        V.WriteTo(Txt);
        Observer.Observe('text', Txt);
        V.SetValue(true);
        V.WriteTo(Txt);
        Observer.Observe('bool', Txt);
        V.SetValue(1.10);
        V.WriteTo(Txt);
        Observer.Observe('decimal', Txt);
        V.SetValueToNull();
        V.WriteTo(Txt);
        Observer.Observe('null', Txt);
        Txt := 'previous';
        Clear(V);
        V.WriteTo(Txt);
        Observer.Observe('undefined_value', Txt);
        Observer.Observe('undefined_isnull', Format(V.IsNull()));
        Observer.Observe('undefined_isundefined', Format(V.IsUndefined()));
        Observer.Expect('int', '42');
        Observer.Expect('text', '"a \"q\" b"');
        Observer.Expect('bool', 'true');
        Observer.Expect('decimal', '1.10');
        Observer.Expect('null', 'null');
        Observer.Expect('undefined_value', 'null');
        Observer.Expect('undefined_isnull', 'Yes');
        Observer.Expect('undefined_isundefined', 'No');
        Observer.Verify();
    end;
}
