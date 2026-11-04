// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 85780
// Probe: corpus issue 671 items 46, 48, 49, 50, 52, 53, 54, 55 (odd JSON behavior leads from microsoft/AL issues and Learn).
// Facts: JsonArray.Get past the end in Boolean form; labels and AppendLine text in WriteTo; last error after a Boolean SelectToken;
//   YAML round trip of a nested list; AsText of a value with quotes; SelectToken through an array without an index;
//   filter paths with zero, one and several matches; Contains/Get on a default JsonObject.
// BC versions: 27, 28, 29

codeunit 85780 "LT DC Json Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblNewline: Label 'line1\nline2', Locked = true;
        LblBackslash: Label 'a\b', Locked = true;

    local procedure Three(var A: JsonArray)
    begin
        Clear(A);
        A.Add(1);
        A.Add(2);
        A.Add(3);
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    // Observes the Boolean that Get returns (or nothing when Get raises), then always raises so the caller's asserterror records the outcome.
    local procedure GetBool(Name: Text; A: JsonArray; Index: Integer)
    var
        T: JsonToken;
        Ok: Boolean;
    begin
        Ok := A.Get(Index, T);
        Observer.Observe(Name, Format(Ok));
        Error('no error');
    end;

    local procedure GetIfNot(Name: Text; A: JsonArray; Index: Integer)
    var
        T: JsonToken;
    begin
        if not A.Get(Index, T) then
            Observer.Observe(Name, 'if not: false')
        else
            Observer.Observe(Name, 'if not: true');
        Error('no error');
    end;

    local procedure SelectBool(Name: Text; O: JsonObject; Path: Text)
    var
        T: JsonToken;
        Txt: Text;
    begin
        if O.SelectToken(Path, T) then begin
            T.WriteTo(Txt);
            Observer.Observe(Name, 'true ' + Txt);
        end else
            Observer.Observe(Name, 'false');
        Error('no error');
    end;

    local procedure SelectStatement(Name: Text; O: JsonObject; Path: Text)
    var
        T: JsonToken;
        Txt: Text;
    begin
        O.SelectToken(Path, T);
        T.WriteTo(Txt);
        Observer.Observe(Name, 'selected ' + Txt);
        Error('no error');
    end;

    [Test]
    procedure Item46_ArrayGetPastEnd_BooleanForm()
    var
        A: JsonArray;
    begin
        Three(A);
        asserterror GetBool('ok_get_3', A, 3);
        Observer.ObserveError('ok_get_3');
        asserterror GetIfNot('ifnot_get_3', A, 3);
        Observer.ObserveError('ifnot_get_3');
        asserterror GetBool('ok_get_2', A, 2);
        Observer.ObserveError('ok_get_2');
        asserterror GetBool('ok_get_minus1', A, -1);
        Observer.ObserveError('ok_get_minus1');
        Observer.Expect('ok_get_3', 'No');
        Observer.Expect('ok_get_3|text', 'no error');
        Observer.Expect('ok_get_3|code', 'Dialog');
        Observer.Expect('ifnot_get_3', 'if not: false');
        Observer.Expect('ifnot_get_3|text', 'no error');
        Observer.Expect('ifnot_get_3|code', 'Dialog');
        Observer.Expect('ok_get_2', 'Yes');
        Observer.Expect('ok_get_2|text', 'no error');
        Observer.Expect('ok_get_2|code', 'Dialog');
        Observer.Expect('ok_get_minus1', 'No');
        Observer.Expect('ok_get_minus1|text', 'no error');
        Observer.Expect('ok_get_minus1|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Item48_AddLabelAndAppendLine_WriteTo()
    var
        O: JsonObject;
        TB: TextBuilder;
        T: JsonToken;
        Txt: Text;
    begin
        Observer.Observe('label_len', Format(StrLen(LblNewline)));
        O.Add('lbl', LblNewline);
        O.Add('lbl_bs', LblBackslash);
        TB.AppendLine('x');
        TB.Append('y');
        O.Add('tb', TB.ToText());
        O.Add('txt_lf', 'p' + Lf() + 'q');
        O.WriteTo(Txt);
        Observer.Observe('writeto', Txt);
        O.Get('lbl', T);
        Observer.Observe('lbl_astext', T.AsValue().AsText());
        O.Get('tb', T);
        Observer.Observe('tb_astext_len', Format(StrLen(T.AsValue().AsText())));
        Observer.Expect('label_len', '12');
        Observer.Expect('writeto', '{"lbl":"line1\\nline2","lbl_bs":"a\\b","tb":"x\r\ny","txt_lf":"p\nq"}');
        Observer.Expect('lbl_astext', 'line1\nline2');
        Observer.Expect('tb_astext_len', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Item49_SelectTokenBoolean_LastError()
    var
        O: JsonObject;
        A: JsonArray;
        T: JsonToken;
    begin
        O.ReadFrom('{"k":"v","arr":[1,2]}');
        ClearLastError();
        if O.SelectToken('$.missing', T) then;
        Observer.Observe('missing|text', GetLastErrorText());
        Observer.Observe('missing|code', GetLastErrorCode());
        ClearLastError();
        if O.SelectToken('$.arr[*]', T) then;
        Observer.Observe('several|text', GetLastErrorText());
        Observer.Observe('several|code', GetLastErrorCode());
        ClearLastError();
        if O.SelectToken('$.k', T) then;
        Observer.Observe('found|text', GetLastErrorText());
        Observer.Observe('found|code', GetLastErrorCode());
        ClearLastError();
        if O.Get('nokey', T) then;
        Observer.Observe('object_get_missing|text', GetLastErrorText());
        Observer.Observe('object_get_missing|code', GetLastErrorCode());
        ClearLastError();
        Three(A);
        if A.Get(5, T) then;
        Observer.Observe('array_get_5|text', GetLastErrorText());
        Observer.Observe('array_get_5|code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('missing|text', '');
        Observer.Expect('missing|code', '');
        Observer.Expect('several|text', '');
        Observer.Expect('several|code', '');
        Observer.Expect('found|text', '');
        Observer.Expect('found|code', '');
        Observer.Expect('object_get_missing|text', '');
        Observer.Expect('object_get_missing|code', '');
        Observer.Expect('array_get_5|text', '');
        Observer.Expect('array_get_5|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Item50_YamlRoundTrip_NestedList()
    var
        O: JsonObject;
        Yaml: Text;
        Json: Text;
    begin
        O.ReadFromYaml('steps:' + Lf() + '  - a' + Lf() + '  - b');
        O.WriteTo(Json);
        Observer.Observe('indented_json', Json);
        O.WriteToYaml(Yaml);
        Observer.Observe('indented_yaml', Yaml);
        Clear(O);
        O.ReadFromYaml('steps:' + Lf() + '- a' + Lf() + '- b');
        O.WriteToYaml(Yaml);
        Observer.Observe('flush_yaml', Yaml);
        Clear(O);
        O.ReadFromYaml('job:' + Lf() + '  steps:' + Lf() + '    - a' + Lf() + '    - name: b' + Lf() + '      run: c');
        O.WriteTo(Json);
        Observer.Observe('deep_json', Json);
        O.WriteToYaml(Yaml);
        Observer.Observe('deep_yaml', Yaml);
        Observer.Expect('indented_json', '{"steps":["a","b"]}');
        Observer.Expect('indented_yaml', 'steps:\r\n- a\r\n- b\r\n');
        Observer.Expect('flush_yaml', 'steps:\r\n- a\r\n- b\r\n');
        Observer.Expect('deep_json', '{"job":{"steps":["a",{"name":"b","run":"c"}]}}');
        Observer.Expect('deep_yaml', 'job:\r\n  steps:\r\n  - a\r\n  - name: b\r\n    run: c\r\n');
        Observer.Verify();
    end;

    [Test]
    procedure Item52_AsTextWithQuotes()
    var
        O: JsonObject;
        R: JsonObject;
        T: JsonToken;
        Txt: Text;
    begin
        O.Add('Test', 'Version="1.1.0.1"');
        O.Add('bs', 'C:\temp\x');
        O.Add('ltgt', '<a href="x">');
        O.SelectToken('Test', T);
        Observer.Observe('quotes_astext', T.AsValue().AsText());
        T.WriteTo(Txt);
        Observer.Observe('quotes_value_writeto', Txt);
        O.SelectToken('bs', T);
        Observer.Observe('bs_astext', T.AsValue().AsText());
        O.SelectToken('ltgt', T);
        Observer.Observe('ltgt_astext', T.AsValue().AsText());
        O.WriteTo(Txt);
        Observer.Observe('object_writeto', Txt);
        R.ReadFrom(Txt);
        R.Get('Test', T);
        Observer.Observe('reread_astext', T.AsValue().AsText());
        R.Get('bs', T);
        Observer.Observe('reread_bs_astext', T.AsValue().AsText());
        Observer.Expect('quotes_astext', 'Version="1.1.0.1"');
        Observer.Expect('quotes_value_writeto', '"Version=\"1.1.0.1\""');
        Observer.Expect('bs_astext', 'C:\temp\x');
        Observer.Expect('ltgt_astext', '<a href="x">');
        Observer.Expect('object_writeto', '{"Test":"Version=\"1.1.0.1\"","bs":"C:\\temp\\x","ltgt":"<a href=\"x\">"}');
        Observer.Expect('reread_astext', 'Version="1.1.0.1"');
        Observer.Expect('reread_bs_astext', 'C:\temp\x');
        Observer.Verify();
    end;

    [Test]
    procedure Item53_SelectTokenThroughArrayWithoutIndex()
    var
        O: JsonObject;
    begin
        O.ReadFrom('{"translations":[{"text":"Hi"}]}');
        asserterror SelectBool('bool_dollar', O, '$.translations.text');
        Observer.ObserveError('bool_dollar');
        asserterror SelectBool('bool_plain', O, 'translations.text');
        Observer.ObserveError('bool_plain');
        asserterror SelectBool('bool_index', O, '$.translations[0].text');
        Observer.ObserveError('bool_index');
        asserterror SelectStatement('stmt_dollar', O, '$.translations.text');
        Observer.ObserveError('stmt_dollar');
        asserterror SelectStatement('stmt_missing', O, '$.missing');
        Observer.ObserveError('stmt_missing');
        asserterror SelectStatement('stmt_index', O, '$.translations[0].text');
        Observer.ObserveError('stmt_index');
        Observer.Expect('bool_dollar', 'false');
        Observer.Expect('bool_dollar|text', 'no error');
        Observer.Expect('bool_dollar|code', 'Dialog');
        Observer.Expect('bool_plain', 'false');
        Observer.Expect('bool_plain|text', 'no error');
        Observer.Expect('bool_plain|code', 'Dialog');
        Observer.Expect('bool_index', 'true "Hi"');
        Observer.Expect('bool_index|text', 'no error');
        Observer.Expect('bool_index|code', 'Dialog');
        Observer.Expect('stmt_dollar|text', 'The JSON path ''$.translations.text'' does not match any tokens.');
        Observer.Expect('stmt_dollar|code', 'InvalidJsonPathSelection');
        Observer.Expect('stmt_missing|text', 'The JSON path ''$.missing'' does not match any tokens.');
        Observer.Expect('stmt_missing|code', 'InvalidJsonPathSelection');
        Observer.Expect('stmt_index', 'selected "Hi"');
        Observer.Expect('stmt_index|text', 'no error');
        Observer.Expect('stmt_index|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Item54_SelectTokenFilterMatches()
    var
        O: JsonObject;
        A: JsonArray;
        T: JsonToken;
        Txt: Text;
    begin
        O.ReadFrom('{"a":[{"id":1,"name":"x"},{"id":2,"name":"y"},{"id":2,"name":"z"}]}');
        asserterror SelectBool('one_bool', O, '$.a[?(@.id==1)].name');
        Observer.ObserveError('one_bool');
        asserterror SelectBool('zero_bool', O, '$.a[?(@.id==9)].name');
        Observer.ObserveError('zero_bool');
        asserterror SelectBool('two_bool', O, '$.a[?(@.id==2)].name');
        Observer.ObserveError('two_bool');
        asserterror SelectStatement('one_stmt', O, '$.a[?(@.id==1)].name');
        Observer.ObserveError('one_stmt');
        asserterror SelectStatement('zero_stmt', O, '$.a[?(@.id==9)].name');
        Observer.ObserveError('zero_stmt');
        asserterror SelectStatement('two_stmt', O, '$.a[?(@.id==2)].name');
        Observer.ObserveError('two_stmt');
        asserterror SelectBool('single_quotes', O, '$[''a''][0][''name'']');
        Observer.ObserveError('single_quotes');
        asserterror SelectBool('double_quotes', O, '$["a"][1]["name"]');
        Observer.ObserveError('double_quotes');
        asserterror SelectBool('filter_text_single_quotes', O, '$.a[?(@.name==''z'')].id');
        Observer.ObserveError('filter_text_single_quotes');
        A.ReadFrom('[1,[2,3]]');
        Observer.Observe('array_empty_path', Format(A.SelectToken('', T)));
        T.WriteTo(Txt);
        Observer.Observe('array_empty_path_token', Txt);
        Observer.Observe('array_dollar', Format(A.SelectToken('$', T)));
        T.WriteTo(Txt);
        Observer.Observe('array_dollar_token', Txt);
        Observer.Observe('array_nested', Format(A.SelectToken('[1][0]', T)));
        T.WriteTo(Txt);
        Observer.Observe('array_nested_token', Txt);
        Observer.Expect('one_bool', 'true "x"');
        Observer.Expect('one_bool|text', 'no error');
        Observer.Expect('one_bool|code', 'Dialog');
        Observer.Expect('zero_bool', 'false');
        Observer.Expect('zero_bool|text', 'no error');
        Observer.Expect('zero_bool|code', 'Dialog');
        Observer.Expect('two_bool', 'false');
        Observer.Expect('two_bool|text', 'no error');
        Observer.Expect('two_bool|code', 'Dialog');
        Observer.Expect('one_stmt', 'selected "x"');
        Observer.Expect('one_stmt|text', 'no error');
        Observer.Expect('one_stmt|code', 'Dialog');
        Observer.Expect('zero_stmt|text', 'The JSON path ''$.a[?(@.id==9)].name'' does not match any tokens.');
        Observer.Expect('zero_stmt|code', 'InvalidJsonPathSelection');
        Observer.Expect('two_stmt|text', 'The set of tokens matching the JSON path ''$.a[?(@.id==2)].name'' contains more than one element.');
        Observer.Expect('two_stmt|code', 'InvalidJsonPathSelection');
        Observer.Expect('single_quotes', 'true "x"');
        Observer.Expect('single_quotes|text', 'no error');
        Observer.Expect('single_quotes|code', 'Dialog');
        Observer.Expect('double_quotes', 'false');
        Observer.Expect('double_quotes|text', 'no error');
        Observer.Expect('double_quotes|code', 'Dialog');
        Observer.Expect('filter_text_single_quotes', 'true 2');
        Observer.Expect('filter_text_single_quotes|text', 'no error');
        Observer.Expect('filter_text_single_quotes|code', 'Dialog');
        Observer.Expect('array_empty_path', 'Yes');
        Observer.Expect('array_empty_path_token', '[1,[2,3]]');
        Observer.Expect('array_dollar', 'Yes');
        Observer.Expect('array_dollar_token', '[1,[2,3]]');
        Observer.Expect('array_nested', 'Yes');
        Observer.Expect('array_nested_token', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Item55_DefaultObjectContainsGet()
    var
        O: JsonObject;
        A: JsonArray;
        V: JsonValue;
        T: JsonToken;
        Txt: Text;
        I: Integer;
    begin
        Observer.Observe('contains', Format(O.Contains('a')));
        Observer.Observe('get', Format(O.Get('a', T)));
        asserterror Txt := O.GetText('a');
        Observer.ObserveError('gettext');
        Observer.Observe('array_get0', Format(A.Get(0, T)));
        asserterror Txt := V.AsText();
        Observer.ObserveError('value_astext');
        asserterror I := V.AsInteger();
        Observer.ObserveError('value_asinteger');
        Observer.Expect('contains', 'No');
        Observer.Expect('get', 'No');
        Observer.Expect('gettext|text', 'There is no property with the ''a'' key on the JSON object.');
        Observer.Expect('gettext|code', 'JsonPropertyNotFound');
        Observer.Expect('array_get0', 'No');
        Observer.Expect('value_astext|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavText.');
        Observer.Expect('value_astext|code', 'Conversion');
        Observer.Expect('value_asinteger|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.');
        Observer.Expect('value_asinteger|code', 'Conversion');
        Observer.Verify();
    end;
}

#if BC28PLUS
// JsonToken.SelectTokens needs runtime 17 (BC 28 and 29); on BC 27 (runtime 16.1) the compiler refuses it: must-not-compile case 1824.
codeunit 85781 "LT DC Token SelectTokens"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Render(L: List of [JsonToken]): Text
    var
        T: JsonToken;
        Txt: Text;
        R: Text;
    begin
        foreach T in L do begin
            T.WriteTo(Txt);
            R += Txt + ';';
        end;
        exit(Format(L.Count()) + ':' + R);
    end;

    [Test]
    procedure Item59_TokenSelectTokens()
    var
        O: JsonObject;
        T: JsonToken;
        V: JsonToken;
        L: List of [JsonToken];
        B: Boolean;
    begin
        O.ReadFrom('{"order_line":[{"line_no":10000},{"line_no":30000},{"line_no":40000}],"x":1}');
        T := O.AsToken();
        B := T.SelectTokens('order_line[?(@.line_no > 20000)]', L);
        Observer.Observe('filter', Format(B) + ' ' + Render(L));
        B := T.SelectTokens('$.nope', L);
        Observer.Observe('nomatch', Format(B) + ' ' + Render(L));
        ClearLastError();
        B := T.SelectTokens('order_line[', L);
        Observer.Observe('invalid', Format(B) + ' ' + Render(L));
        Observer.ObserveError('invalid');
        O.Get('x', V);
        B := V.SelectTokens('$', L);
        Observer.Observe('value_dollar', Format(B) + ' ' + Render(L));
        B := V.SelectTokens('$.a', L);
        Observer.Observe('value_child', Format(B) + ' ' + Render(L));
        Observer.Expect('filter', 'Yes 2:{"line_no":30000};{"line_no":40000};');
        Observer.Expect('nomatch', 'Yes 0:');
        Observer.Expect('invalid', 'No 0:');
        Observer.Expect('invalid|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('invalid|code', 'InvalidOperation');
        Observer.Expect('value_dollar', 'Yes 1:1;');
        Observer.Expect('value_child', 'Yes 0:');
        Observer.Verify();
    end;
}
#endif
