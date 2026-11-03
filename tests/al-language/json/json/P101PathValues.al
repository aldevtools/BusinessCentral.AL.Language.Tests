// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70857
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonArray.Path, JsonObject.Path, JsonObject.Values, GetChar, GetTime (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70857 "LT P101 Path Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P101_ArrayPath()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Inner: JsonArray;
        O: JsonObject;
        T: JsonToken;
    begin
        Observer.Observe('empty_array_path', A.Path());
        A.Add(1);
        Inner.Add(2);
        A.Add(Inner);
        Observer.Observe('array_path_after_add', A.Path());
        Observer.Observe('inner_path_after_add', Inner.Path());
        A.Get(1, T);
        Observer.Observe('token_path', T.Path());
        Observer.Observe('token_as_array_path', T.AsArray().Path());
        O.Add('arr', A);
        Observer.Observe('array_path_after_object_add', A.Path());
        O.Get('arr', T);
        Observer.Observe('object_child_path', T.AsArray().Path());
        T.AsArray().Get(1, T);
        Observer.Observe('nested_path', T.AsArray().Path());
        Clear(A);
        Observer.Observe('cleared_path', A.Path());
        Observer.Expect('empty_array_path', '');
        Observer.Expect('array_path_after_add', '');
        Observer.Expect('inner_path_after_add', '[1]');
        Observer.Expect('token_path', '[1]');
        Observer.Expect('token_as_array_path', '[1]');
        Observer.Expect('array_path_after_object_add', 'arr');
        Observer.Expect('object_child_path', 'arr');
        Observer.Expect('nested_path', 'arr[1]');
        Observer.Expect('cleared_path', '');
        Observer.Verify();
    end;

    [Test]
    procedure P101_ObjectPath()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Inner: JsonObject;
        A: JsonArray;
        T: JsonToken;
    begin
        Observer.Observe('empty_object_path', O.Path());
        Inner.Add('x', 1);
        O.Add('inner', Inner);
        Observer.Observe('object_path', O.Path());
        Observer.Observe('inner_path_after_add', Inner.Path());
        O.Get('inner', T);
        Observer.Observe('child_path', T.AsObject().Path());
        A.Add(Inner);
        Observer.Observe('inner_path_in_array', Inner.Path());
        A.Get(0, T);
        Observer.Observe('array_child_path', T.AsObject().Path());
        O.ReadFrom('{"a":{"b":{"c":1}}}');
        O.Get('a', T);
        Observer.Observe('parsed_a', T.AsObject().Path());
        T.AsObject().Get('b', T);
        Observer.Observe('parsed_a_b', T.AsObject().Path());
        O.Add('key with space', Inner);
        O.Get('key with space', T);
        Observer.Observe('spaced_key_path', T.AsObject().Path());
        O.Add('dot.key', Inner);
        O.Get('dot.key', T);
        Observer.Observe('dotted_key_path', T.AsObject().Path());
        Observer.Expect('empty_object_path', '');
        Observer.Expect('object_path', '');
        Observer.Expect('inner_path_after_add', 'inner');
        Observer.Expect('child_path', 'inner');
        Observer.Expect('inner_path_in_array', 'inner');
        Observer.Expect('array_child_path', '[0]');
        Observer.Expect('parsed_a', 'a');
        Observer.Expect('parsed_a_b', 'a.b');
        Observer.Expect('spaced_key_path', '[''key with space'']');
        Observer.Expect('dotted_key_path', '[''dot.key'']');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Values()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        L: List of [JsonToken];
        T: JsonToken;
        I: Integer;
        R: Text;
    begin
        L := O.Values();
        Observer.Observe('empty_count', Format(L.Count()));
        O.ReadFrom('{"a":1,"b":"two","c":[3],"d":{"e":4},"f":null,"g":true}');
        L := O.Values();
        Observer.Observe('count', Format(L.Count()));
        for I := 1 to L.Count() do begin
            L.Get(I, T);
            T.WriteTo(R);
            Observer.Observe('value_' + Format(I), R);
            Observer.Observe('isvalue_' + Format(I), Format(T.IsValue()));
        end;
        O.Add('h', 8);
        Observer.Observe('count_after_add_snapshot', Format(L.Count()));
        L := O.Values();
        Observer.Observe('count_after_add', Format(L.Count()));
        O.Remove('a');
        L := O.Values();
        L.Get(1, T);
        T.WriteTo(R);
        Observer.Observe('first_after_remove', R);
        Observer.Expect('empty_count', '0');
        Observer.Expect('count', '6');
        Observer.Expect('value_1', '1');
        Observer.Expect('isvalue_1', 'Yes');
        Observer.Expect('value_2', '"two"');
        Observer.Expect('isvalue_2', 'Yes');
        Observer.Expect('value_3', '[3]');
        Observer.Expect('isvalue_3', 'No');
        Observer.Expect('value_4', '{"e":4}');
        Observer.Expect('isvalue_4', 'No');
        Observer.Expect('value_5', 'null');
        Observer.Expect('isvalue_5', 'Yes');
        Observer.Expect('value_6', 'true');
        Observer.Expect('isvalue_6', 'Yes');
        Observer.Expect('count_after_add_snapshot', '6');
        Observer.Expect('count_after_add', '7');
        Observer.Expect('first_after_remove', '"two"');
        Observer.Verify();
    end;

    [Test]
    procedure P101_ObjectGetChar()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ch: Char;
    begin
        Ch := 65;
        O.Add('c', Ch);
        Observer.Observe('char_a', Format(O.GetChar('c')));
        Observer.Observe('char_a_default_true', Format(O.GetChar('c', true)));
        Observer.Observe('missing_default_true', Format(O.GetChar('nope', true)));
        asserterror Observer.Observe('missing_default_false', Format(O.GetChar('nope', false)));
        Observer.ObserveError('missing_default_false');
        asserterror Observer.Observe('missing_nodefault', Format(O.GetChar('nope')));
        Observer.ObserveError('missing_nodefault');
        O.Add('i', 8364);
        Observer.Observe('int_as_char', Format(O.GetChar('i')));
        O.Add('t', 'xyz');
        asserterror Observer.Observe('text_as_char', Format(O.GetChar('t')));
        Observer.ObserveError('text_as_char');
        O.Add('b', true);
        asserterror Observer.Observe('bool_as_char', Format(O.GetChar('b')));
        Observer.ObserveError('bool_as_char');
        O.Add('n', 0);
        Observer.Observe('zero_as_char_code', Format(O.GetChar('n') = 0));
        Observer.Expect('char_a', 'A');
        Observer.Expect('char_a_default_true', 'A');
        Observer.Expect('missing_default_true', '\u0000');
        Observer.Expect('missing_default_false|text', 'There is no property with the ''nope'' key on the JSON object.');
        Observer.Expect('missing_default_false|code', 'JsonPropertyNotFound');
        Observer.Expect('missing_nodefault|text', 'There is no property with the ''nope'' key on the JSON object.');
        Observer.Expect('missing_nodefault|code', 'JsonPropertyNotFound');
        Observer.Expect('int_as_char', '€');
        Observer.Expect('text_as_char|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Char.');
        Observer.Expect('text_as_char|code', 'Conversion');
        Observer.Expect('bool_as_char|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Char.');
        Observer.Expect('bool_as_char|code', 'Conversion');
        Observer.Expect('zero_as_char_code', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P101_ArrayGetCharTime()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ch: Char;
        Ti: Time;
    begin
        Ch := 66;
        A.Add(Ch);
        Ti := 123456T;
        A.Add(Ti);
        A.Add('text');
        A.Add(5);
        Observer.Observe('char0', Format(A.GetChar(0)));
        Observer.Observe('int_as_char', Format(A.GetChar(3)));
        asserterror Observer.Observe('text_as_char', Format(A.GetChar(2)));
        Observer.ObserveError('text_as_char');
        asserterror Observer.Observe('char_oob', Format(A.GetChar(4)));
        Observer.ObserveError('char_oob');
        Observer.Observe('time1', Format(A.GetTime(1), 0, 9));
        asserterror Observer.Observe('time_of_text', Format(A.GetTime(2)));
        Observer.ObserveError('time_of_text');
        asserterror Observer.Observe('time_of_int', Format(A.GetTime(3)));
        Observer.ObserveError('time_of_int');
        asserterror Observer.Observe('time_oob', Format(A.GetTime(-1)));
        Observer.ObserveError('time_oob');
        Observer.Expect('char0', 'B');
        Observer.Expect('int_as_char', '\u0005');
        Observer.Expect('text_as_char|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Char.');
        Observer.Expect('text_as_char|code', 'Conversion');
        Observer.Expect('char_oob|text', 'Index out of bounds.');
        Observer.Expect('char_oob|code', 'IndexOutOfBounds');
        Observer.Expect('time1', '12:34:56');
        Observer.Expect('time_of_text|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('time_of_text|code', 'Conversion');
        Observer.Expect('time_of_int|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('time_of_int|code', 'Conversion');
        Observer.Expect('time_oob|text', 'Index out of bounds.');
        Observer.Expect('time_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;
}
