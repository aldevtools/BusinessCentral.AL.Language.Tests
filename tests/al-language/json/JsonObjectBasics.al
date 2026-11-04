// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 72500
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72500 "LT JsT Object Basics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure AddAndGet()
    var
        O: JsonObject;
        T: JsonToken;
        B: Boolean;
    begin
        Observer.Observe('empty_count', Format(O.Keys().Count()));
        Observer.Observe('add_returns', Format(O.Add('a', 1)));
        Observer.Observe('add_text', Format(O.Add('b', 'x')));
        Observer.Observe('add_bool', Format(O.Add('c', true)));
        Observer.Observe('add_dec', Format(O.Add('d', 1.5)));
        Observer.Observe('count', Format(O.Keys().Count()));
        Observer.Observe('get_a', Format(O.Get('a', T)));
        Observer.Observe('get_a_value', Format(T.AsValue().AsInteger()));
        Observer.Observe('get_missing', Format(O.Get('zz', T)));
        Observer.Observe('contains_a', Format(O.Contains('a')));
        Observer.Observe('contains_A', Format(O.Contains('A')));
        Observer.Observe('contains_empty', Format(O.Contains('')));
        asserterror O.Add('a', 2);
        Observer.ObserveError('add_dup_int');
        asserterror O.Add('b', 'other');
        Observer.ObserveError('add_dup_text');
        Observer.Observe('count_after_dup', Format(O.Keys().Count()));
        Observer.Observe('text', Format(O));
        Observer.Expect('empty_count', '0');
        Observer.Expect('add_returns', 'Yes');
        Observer.Expect('add_text', 'Yes');
        Observer.Expect('add_bool', 'Yes');
        Observer.Expect('add_dec', 'Yes');
        Observer.Expect('count', '4');
        Observer.Expect('get_a', 'Yes');
        Observer.Expect('get_a_value', '1');
        Observer.Expect('get_missing', 'No');
        Observer.Expect('contains_a', 'Yes');
        Observer.Expect('contains_A', 'No');
        Observer.Expect('contains_empty', 'No');
        Observer.Expect('add_dup_int|text', 'The JSON object already contains the key ''a''.');
        Observer.Expect('add_dup_int|code', 'DuplicateJsonProperty');
        Observer.Expect('add_dup_text|text', 'The JSON object already contains the key ''b''.');
        Observer.Expect('add_dup_text|code', 'DuplicateJsonProperty');
        Observer.Expect('count_after_dup', '4');
        Observer.Expect('text', '{"a":1,"b":"x","c":true,"d":1.5}');
        Observer.Verify();
    end;

    [Test]
    procedure AddKeysEdge()
    var
        O: JsonObject;
        T: JsonToken;
        Txt: Text;
    begin
        Observer.Observe('add_empty_key', Format(O.Add('', 1)));
        Observer.Observe('contains_empty', Format(O.Contains('')));
        Observer.Observe('get_empty', Format(O.Get('', T)));
        Observer.Observe('add_space_key', Format(O.Add(' ', 2)));
        Observer.Observe('add_case_A', Format(O.Add('A', 3)));
        Observer.Observe('add_case_a', Format(O.Add('a', 4)));
        Observer.Observe('add_dot_key', Format(O.Add('a.b', 5)));
        Observer.Observe('add_unicode_key', Format(O.Add('äöü€', 6)));
        Observer.Observe('add_quote_key', Format(O.Add('q"uote', 7)));
        Observer.Observe('count', Format(O.Keys().Count()));
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('add_empty_key', 'Yes');
        Observer.Expect('contains_empty', 'Yes');
        Observer.Expect('get_empty', 'Yes');
        Observer.Expect('add_space_key', 'Yes');
        Observer.Expect('add_case_A', 'Yes');
        Observer.Expect('add_case_a', 'Yes');
        Observer.Expect('add_dot_key', 'Yes');
        Observer.Expect('add_unicode_key', 'Yes');
        Observer.Expect('add_quote_key', 'Yes');
        Observer.Expect('count', '7');
        Observer.Expect('text', '{"":1," ":2,"A":3,"a":4,"a.b":5,"äöü€":6,"q\"uote":7}');
        Observer.Verify();
    end;

    [Test]
    procedure AddTokenAndNull()
    var
        O: JsonObject;
        Inner: JsonObject;
        Arr: JsonArray;
        V: JsonValue;
        T: JsonToken;
        Txt: Text;
    begin
        Inner.Add('i', 1);
        Arr.Add(1);
        V.SetValueToNull();
        Observer.Observe('add_obj', Format(O.Add('o', Inner)));
        Observer.Observe('add_arr', Format(O.Add('a', Arr)));
        Observer.Observe('add_null_value', Format(O.Add('n', V)));
        Observer.Observe('add_jsontoken', Format(O.Add('t', Inner.AsToken())));
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        O.Get('n', T);
        Observer.Observe('n_isvalue', Format(T.IsValue()));
        Observer.Observe('n_isnull', Format(T.AsValue().IsNull()));
        Observer.Observe('n_isundefined', Format(T.AsValue().IsUndefined()));
        Observer.Expect('add_obj', 'Yes');
        Observer.Expect('add_arr', 'Yes');
        Observer.Expect('add_null_value', 'Yes');
        Observer.Expect('add_jsontoken', 'Yes');
        Observer.Expect('text', '{"o":{"i":1},"a":[1],"n":null,"t":{"i":1}}');
        Observer.Expect('n_isvalue', 'Yes');
        Observer.Expect('n_isnull', 'Yes');
        Observer.Expect('n_isundefined', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AddDefaultValues()
    var
        O: JsonObject;
        D: Date;
        DT: DateTime;
        Tm: Time;
        Dur: Duration;
        Big: BigInteger;
        C: Code[10];
        Txt: Text;
    begin
        O.Add('date', D);
        O.Add('datetime', DT);
        O.Add('time', Tm);
        O.Add('duration', Dur);
        O.Add('big', Big);
        O.Add('code', C);
        O.Add('text_empty', '');
        O.Add('int_zero', 0);
        O.Add('dec_zero', 0.0);
        O.Add('bool_false', false);
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('text', '{"date":"0001-01-01","datetime":"0001-01-01T00:00:00.0000000","time":"00:00:00","duration":0,"big":0,"code":"","text_empty":"","int_zero":0,"dec_zero":0.0,"bool_false":false}');
        Observer.Verify();
    end;

    [Test]
    procedure AddTypedValues()
    var
        O: JsonObject;
        Txt: Text;
        Big: BigInteger;
        C: Code[10];
        Ch: Char;
    begin
        Evaluate(Big, '9223372036854775807');
        C := 'abc';
        Ch := 65;
        O.Add('date', DMY2Date(1, 2, 2020));
        O.Add('datetime', CreateDateTime(DMY2Date(1, 2, 2020), 123456T));
        O.Add('time', 123456T);
        O.Add('duration', 90000);
        O.Add('big', Big);
        O.Add('code', C);
        O.Add('char', Ch);
        O.Add('int_min', -2147483647);
        O.Add('int_max', 2147483647);
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('text', '{"date":"2020-02-01","datetime":"2020-02-01T12:34:56.0000000Z","time":"12:34:56","duration":90000,"big":9223372036854775807,"code":"ABC","char":65,"int_min":-2147483647,"int_max":2147483647}');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveAndReplace()
    var
        O: JsonObject;
        T: JsonToken;
        Txt: Text;
    begin
        O.Add('a', 1);
        O.Add('b', 2);
        O.Add('c', 3);
        Observer.Observe('remove_a', Format(O.Remove('a')));
        Observer.Observe('remove_a_again', Format(O.Remove('a')));
        Observer.Observe('remove_missing', Format(O.Remove('zz')));
        Observer.Observe('count', Format(O.Keys().Count()));
        Observer.Observe('replace_b', Format(O.Replace('b', 'two')));
        O.Get('b', T);
        Observer.Observe('b_value', T.AsValue().AsText());
        asserterror O.Replace('zz', 1);
        Observer.ObserveError('replace_missing');
        Observer.Observe('replace_c_token', Format(O.Replace('c', O.AsToken())));
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('remove_a', 'Yes');
        Observer.Expect('remove_a_again', 'No');
        Observer.Expect('remove_missing', 'No');
        Observer.Expect('count', '2');
        Observer.Expect('replace_b', 'Yes');
        Observer.Expect('b_value', 'two');
        Observer.Expect('replace_missing|text', 'There is no property with the ''zz'' key on the JSON object.');
        Observer.Expect('replace_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('replace_c_token', 'Yes');
        Observer.Expect('text', '{"b":"two","c":{"b":"two"}}');
        Observer.Verify();
    end;

    [Test]
    procedure KeysOrder()
    var
        O: JsonObject;
        K: Text;
        Ks: List of [Text];
        All: Text;
    begin
        O.Add('z', 1);
        O.Add('a', 2);
        O.Add('m', 3);
        Ks := O.Keys();
        Observer.Observe('keys_count', Format(Ks.Count()));
        foreach K in Ks do
            All += K + ',';
        Observer.Observe('keys', All);
        O.Remove('a');
        O.Add('a', 4);
        Clear(All);
        foreach K in O.Keys() do
            All += K + ',';
        Observer.Observe('keys_after_readd', All);
        Observer.Observe('empty_keys', Format(Ks.Count()));
        Clear(O);
        Observer.Observe('cleared_keys', Format(O.Keys().Count()));
        Observer.Expect('keys_count', '3');
        Observer.Expect('keys', 'z,a,m,');
        Observer.Expect('keys_after_readd', 'z,m,a,');
        Observer.Expect('empty_keys', '3');
        Observer.Expect('cleared_keys', '0');
        Observer.Verify();
    end;

    [Test]
    procedure CloneAndReference()
    var
        O: JsonObject;
        Cl: JsonObject;
        Same: JsonObject;
        Inner: JsonObject;
        T: JsonToken;
        Txt: Text;
        Txt2: Text;
    begin
        O.Add('a', 1);
        Inner.Add('x', 1);
        O.Add('inner', Inner);
        Cl := O.Clone().AsObject();
        Same := O;
        O.Add('b', 2);
        Cl.Add('c', 3);
        Inner.Add('y', 2);
        O.WriteTo(Txt);
        Cl.WriteTo(Txt2);
        Observer.Observe('orig', Txt);
        Observer.Observe('clone', Txt2);
        Same.WriteTo(Txt);
        Observer.Observe('assigned_copy', Txt);
        Cl.Get('inner', T);
        T.AsObject().Add('z', 3);
        O.WriteTo(Txt);
        Observer.Observe('orig_after_clone_inner', Txt);
        O.Get('inner', T);
        T.AsObject().Add('w', 4);
        Inner.WriteTo(Txt);
        Observer.Observe('inner_var_after_token_edit', Txt);
        Observer.Expect('orig', '{"a":1,"inner":{"x":1,"y":2},"b":2}');
        Observer.Expect('clone', '{"a":1,"inner":{"x":1},"c":3}');
        Observer.Expect('assigned_copy', '{"a":1,"inner":{"x":1,"y":2},"b":2}');
        Observer.Expect('orig_after_clone_inner', '{"a":1,"inner":{"x":1,"y":2},"b":2}');
        Observer.Expect('inner_var_after_token_edit', '{"x":1,"y":2,"w":4}');
        Observer.Verify();
    end;

    [Test]
    procedure PathAndSelect()
    var
        O: JsonObject;
        Inner: JsonObject;
        Arr: JsonArray;
        T: JsonToken;
        Ts: List of [JsonToken];
        I: Integer;
    begin
        Inner.Add('name', 'n1');
        Arr.Add(Inner);
        Arr.Add(10);
        O.Add('arr', Arr);
        O.Add('k', 'v');
        Observer.Observe('path_root', O.AsToken().Path());
        O.Get('arr', T);
        Observer.Observe('path_arr', T.Path());
        Arr.Get(0, T);
        Observer.Observe('path_arr0', T.Path());
        Arr.Get(1, T);
        Observer.Observe('path_arr1', T.Path());
        Observer.Observe('select_k', Format(O.SelectToken('k', T)));
        Observer.Observe('select_k_val', T.AsValue().AsText());
        Observer.Observe('select_missing', Format(O.SelectToken('nope', T)));
        Observer.Observe('select_arr0_name', Format(O.SelectToken('arr[0].name', T)));
        Observer.Observe('select_arr0_name_val', T.AsValue().AsText());
        Observer.Observe('select_arr1', Format(O.SelectToken('arr[1]', T)));
        Observer.Observe('select_arr_oob', Format(O.SelectToken('arr[5]', T)));
        Observer.Observe('select_dollar', Format(O.SelectToken('$.k', T)));
        Observer.Observe('select_dollar_arr', Format(O.SelectToken('$.arr[1]', T)));
        Observer.Observe('select_neg', Format(O.SelectToken('arr[-1]', T)));
        Observer.Observe('select_wild', Format(O.SelectToken('arr[*]', T)));
        Observer.Observe('select_empty', Format(O.SelectToken('', T)));
        Observer.Observe('select_dollar_only', Format(O.SelectToken('$', T)));
        Observer.Observe('select_bracket_name', Format(O.SelectToken('[''k'']', T)));
        Observer.Observe('select_recursive', Format(O.SelectToken('$..name', T)));
        Observer.Observe('select_bad', Format(O.SelectToken('arr[', T)));
        Observer.Expect('path_root', '');
        Observer.Expect('path_arr', 'arr');
        Observer.Expect('path_arr0', 'arr[0]');
        Observer.Expect('path_arr1', 'arr[1]');
        Observer.Expect('select_k', 'Yes');
        Observer.Expect('select_k_val', 'v');
        Observer.Expect('select_missing', 'No');
        Observer.Expect('select_arr0_name', 'Yes');
        Observer.Expect('select_arr0_name_val', 'n1');
        Observer.Expect('select_arr1', 'Yes');
        Observer.Expect('select_arr_oob', 'No');
        Observer.Expect('select_dollar', 'Yes');
        Observer.Expect('select_dollar_arr', 'Yes');
        Observer.Expect('select_neg', 'No');
        Observer.Expect('select_wild', 'No');
        Observer.Expect('select_empty', 'Yes');
        Observer.Expect('select_dollar_only', 'Yes');
        Observer.Expect('select_bracket_name', 'Yes');
        Observer.Expect('select_recursive', 'Yes');
        Observer.Expect('select_bad', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SelectTokenErrors()
    var
        O: JsonObject;
        Arr: JsonArray;
        T: JsonToken;
    begin
        Arr.Add(1);
        Arr.Add(2);
        O.Add('a', Arr);
        asserterror O.SelectToken('a[*]', T);
        Observer.ObserveError('select_token_wild_single');
        O.SelectToken('a[0:1]', T);
        Observer.Observe('select_token_slice', 'no error');
        O.SelectToken('$..a', T);
        Observer.Observe('select_token_recursive', 'no error');
        asserterror O.SelectToken('a[x]', T);
        Observer.ObserveError('select_token_bad_index');
        asserterror O.SelectToken('a[(', T);
        Observer.ObserveError('select_token_unclosed');
        Observer.Expect('select_token_wild_single|text', 'The set of tokens matching the JSON path ''a[*]'' contains more than one element.');
        Observer.Expect('select_token_wild_single|code', 'InvalidJsonPathSelection');
        Observer.Expect('select_token_slice', 'no error');
        Observer.Expect('select_token_recursive', 'no error');
        Observer.Expect('select_token_bad_index|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('select_token_bad_index|code', 'InvalidOperation');
        Observer.Expect('select_token_unclosed|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('select_token_unclosed|code', 'InvalidOperation');
        Observer.Verify();
    end;

    // Writer QV (AL Runner issue 5680): JsonObject.Remove of a key the object does not hold, in statement form (the Boolean result is not
    // used), directly and in a procedure that takes the object by var; then the statement form on a key that exists.
    local procedure QvRemoveKey(var O: JsonObject; KeyName: Text)
    begin
        O.Remove(KeyName);
    end;

    [TryFunction]
    local procedure QvTryRemoveStatement(var O: JsonObject; KeyName: Text)
    begin
        O.Remove(KeyName);
    end;

    [Test]
    procedure QV_RemoveMissingKey_StatementForm()
    var
        O: JsonObject;
        Empty: JsonObject;
        Txt: Text;
    begin
        O.Add('a', 1);
        ClearLastError();
        O.Remove('missing');
        Observer.Observe('direct', 'no error|' + GetLastErrorText());
        O.WriteTo(Txt);
        Observer.Observe('after direct', Txt);
        QvRemoveKey(O, 'missing');
        O.WriteTo(Txt);
        Observer.Observe('after var procedure', Txt);
        Observer.Observe('try statement', Format(QvTryRemoveStatement(O, 'missing')));
        Observer.ObserveError('try statement error');
        Observer.Observe('value form', Format(O.Remove('missing')));
        Empty.Remove('a');
        Empty.WriteTo(Txt);
        Observer.Observe('empty object', Txt);
        O.Remove('a');
        O.WriteTo(Txt);
        Observer.Observe('existing statement', Txt);
        Observer.Expect('direct', 'no error|');
        Observer.Expect('after direct', '{"a":1}');
        Observer.Expect('after var procedure', '{"a":1}');
        Observer.Expect('try statement', 'Yes');
        Observer.Expect('try statement error|text', '');
        Observer.Expect('try statement error|code', '');
        Observer.Expect('value form', 'No');
        Observer.Expect('empty object', '{}');
        Observer.Expect('existing statement', '{}');
        Observer.Verify();
    end;

    // al-runner issue 6924 (item 3.8): a value passed to a Variant parameter and added to a JsonObject the way a JSON helper does it: a type switch on
    // the Variant (IsChar first, then IsText and IsCode), the Char branch reads the Variant into a Char variable and adds that. Next to it the direct
    // Add of a Char variable, a Text variable and a one-character literal. Result: the branch the switch took and the JSON text of WriteTo.
    local procedure QwAddVariant(var O: JsonObject; KeyName: Text; Value: Variant): Text
    var
        Ch: Char;
        T: Text;
    begin
        case true of
            Value.IsChar():
                begin
                    Ch := Value;
                    O.Add(KeyName, Ch);
                    exit('char');
                end;
            Value.IsText(), Value.IsCode():
                begin
                    T := Value;
                    O.Add(KeyName, T);
                    exit('text');
                end;
        end;
        exit('other');
    end;

    [Test]
    procedure QW_Add_CharAndText_ThroughVariant()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ch: Char;
        T: Text;
        C1: Code[1];
        Txt: Text;
    begin
        Ch := ',';
        T := 'x';
        C1 := '.';
        Observer.Observe('branch literal comma', QwAddVariant(O, 'lit', ','));
        Observer.Observe('branch text var', QwAddVariant(O, 'txt', T));
        Observer.Observe('branch char var', QwAddVariant(O, 'chr', Ch));
        Observer.Observe('branch code1 var', QwAddVariant(O, 'code1', C1));
        O.WriteTo(Txt);
        Observer.Observe('through variant', Txt);
        Clear(O);
        O.Add('chr', Ch);
        O.Add('txt', T);
        O.Add('lit', ',');
        O.Add('code1', C1);
        O.WriteTo(Txt);
        Observer.Observe('direct', Txt);
        Observer.Finish();
    end;
}
