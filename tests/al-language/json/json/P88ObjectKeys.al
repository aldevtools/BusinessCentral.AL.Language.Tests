// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74408
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonObject Add existing key, Replace missing key, Remove, Keys, key edge cases
// BC versions: 29

codeunit 74408 "LT P88 Object Keys"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Txt(O: JsonObject): Text
    var
        R: Text;
    begin
        O.WriteTo(R);
        exit(R);
    end;

    [Test]
    procedure Add_ExistingKey()
    var
        O: JsonObject;
    begin
        O.Add('k', 1);
        asserterror O.Add('k', 2);
        Observer.ObserveError('add_same_type');
        asserterror O.Add('k', 'text');
        Observer.ObserveError('add_other_type');
        asserterror O.Add('k', true);
        Observer.ObserveError('add_boolean');
        O.Add('K', 3);
        Observer.Observe('add_other_case', 'no error');
        Observer.Observe('after_errors', Txt(O));
        Observer.Observe('count', Format(O.Keys().Count()));
        Observer.Expect('add_same_type|text', 'The JSON object already contains the key ''k''.');
        Observer.Expect('add_same_type|code', 'DuplicateJsonProperty');
        Observer.Expect('add_other_type|text', 'The JSON object already contains the key ''k''.');
        Observer.Expect('add_other_type|code', 'DuplicateJsonProperty');
        Observer.Expect('add_boolean|text', 'The JSON object already contains the key ''k''.');
        Observer.Expect('add_boolean|code', 'DuplicateJsonProperty');
        Observer.Expect('add_other_case', 'no error');
        Observer.Expect('after_errors', '{"k":1,"K":3}');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Add_ExistingKey_Containers()
    var
        O: JsonObject;
        Ja: JsonArray;
        Jo: JsonObject;
        Jv: JsonValue;
        T: JsonToken;
    begin
        O.Add('k', 1);
        Ja.Add(1);
        Jo.Add('x', 1);
        Jv.SetValue(5);
        T := Jv.AsToken();
        asserterror O.Add('k', Ja);
        Observer.ObserveError('add_array');
        asserterror O.Add('k', Jo);
        Observer.ObserveError('add_object');
        asserterror O.Add('k', Jv);
        Observer.ObserveError('add_value');
        asserterror O.Add('k', T);
        Observer.ObserveError('add_token');
        Observer.Observe('after_errors', Txt(O));
        Observer.Expect('add_array|text', 'The JSON object already contains the key ''k''.');
        Observer.Expect('add_array|code', 'DuplicateJsonProperty');
        Observer.Expect('add_object|text', 'The JSON object already contains the key ''k''.');
        Observer.Expect('add_object|code', 'DuplicateJsonProperty');
        Observer.Expect('add_value|text', 'The JSON object already contains the key ''k''.');
        Observer.Expect('add_value|code', 'DuplicateJsonProperty');
        Observer.Expect('add_token|text', 'The JSON object already contains the key ''k''.');
        Observer.Expect('add_token|code', 'DuplicateJsonProperty');
        Observer.Expect('after_errors', '{"k":1}');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_ExistingAndMissing()
    var
        O: JsonObject;
    begin
        O.Add('a', 1);
        O.Add('b', 2);
        O.Add('c', 3);
        O.Replace('b', 'two');
        Observer.Observe('replace_b', Txt(O));
        O.Replace('c', 3.5);
        Observer.Observe('replace_c', Txt(O));
        O.Replace('a', true);
        Observer.Observe('replace_a', Txt(O));
        asserterror O.Replace('zzz', 1);
        Observer.ObserveError('replace_missing');
        asserterror O.Replace('B', 1);
        Observer.ObserveError('replace_other_case');
        asserterror O.Replace('', 1);
        Observer.ObserveError('replace_empty_key');
        Observer.Observe('after_errors', Txt(O));
        Observer.Observe('count', Format(O.Keys().Count()));
        Observer.Expect('replace_b', '{"a":1,"c":3,"b":"two"}');
        Observer.Expect('replace_c', '{"a":1,"b":"two","c":3.5}');
        Observer.Expect('replace_a', '{"b":"two","c":3.5,"a":true}');
        Observer.Expect('replace_missing|text', 'There is no property with the ''zzz'' key on the JSON object.');
        Observer.Expect('replace_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('replace_other_case|text', 'There is no property with the ''B'' key on the JSON object.');
        Observer.Expect('replace_other_case|code', 'JsonPropertyNotFound');
        Observer.Expect('replace_empty_key|text', 'There is no property with the '''' key on the JSON object.');
        Observer.Expect('replace_empty_key|code', 'JsonPropertyNotFound');
        Observer.Expect('after_errors', '{"b":"two","c":3.5,"a":true}');
        Observer.Expect('count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_EmptyObject()
    var
        O: JsonObject;
    begin
        asserterror O.Replace('a', 1);
        Observer.ObserveError('replace_in_empty');
        Observer.Observe('text', Txt(O));
        Observer.Expect('replace_in_empty|text', 'There is no property with the ''a'' key on the JSON object.');
        Observer.Expect('replace_in_empty|code', 'JsonPropertyNotFound');
        Observer.Expect('text', '{}');
        Observer.Verify();
    end;

    [Test]
    procedure Replace_ContainerOrder()
    var
        O: JsonObject;
        Jo: JsonObject;
        Ja: JsonArray;
    begin
        O.ReadFrom('{"first":1,"second":2,"third":3}');
        Jo.Add('n', 1);
        Ja.Add('x');
        O.Replace('second', Jo);
        Observer.Observe('replace_with_object', Txt(O));
        O.Replace('first', Ja);
        Observer.Observe('replace_with_array', Txt(O));
        Observer.Expect('replace_with_object', '{"first":1,"third":3,"second":{"n":1}}');
        Observer.Expect('replace_with_array', '{"third":3,"second":{"n":1},"first":["x"]}');
        Observer.Verify();
    end;

    [Test]
    procedure Add_KeyEdgeCases()
    var
        O: JsonObject;
        Keys: List of [Text];
        K: Text;
        R: Text;
    begin
        O.Add('', 1);
        Observer.Observe('empty_key', Txt(O));
        O.Add(' ', 2);
        O.Add('with "quote"', 3);
        O.Add('back\slash', 4);
        O.Add('ünï', 5);
        O.Add('a.b', 6);
        O.Add('[0]', 7);
        Observer.Observe('edge_keys', Txt(O));
        Keys := O.Keys();
        foreach K in Keys do
            R += '<' + K + '>';
        Observer.Observe('keys', R);
        Observer.Observe('count', Format(O.Keys().Count()));
        Observer.Observe('contains_empty', Format(O.Contains('')));
        Observer.Observe('contains_other_case', Format(O.Contains('A.B')));
        Observer.Expect('empty_key', '{"":1}');
        Observer.Expect('edge_keys', '{"":1," ":2,"with \"quote\"":3,"back\\slash":4,"ünï":5,"a.b":6,"[0]":7}');
        Observer.Expect('keys', '<>< ><with "quote"><back\slash><ünï><a.b><[0]>');
        Observer.Expect('count', '7');
        Observer.Expect('contains_empty', 'Yes');
        Observer.Expect('contains_other_case', 'No');
        Observer.Verify();
    end;
}
