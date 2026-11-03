// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74409
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonObject Path, SelectTokens, WriteToYaml, ReadFromYaml
// BC versions: 29

codeunit 74409 "LT P88 Object Path Yaml"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Doc(var O: JsonObject)
    begin
        O.ReadFrom('{"a":[1,2,{"b":5}],"c":{"d":"x","e":[true,null]},"f":7}');
    end;

    local procedure NL(): Text
    var
        Lf: Text[1];
    begin
        Lf[1] := 10;
        exit(Lf);
    end;

    [TryFunction]
    local procedure TryYaml(O: JsonObject; var R: Text)
    begin
        O.WriteToYaml(R);
    end;

    local procedure Yaml(O: JsonObject): Text
    var
        R: Text;
    begin
        if TryYaml(O, R) then
            exit(R);
        exit('ERR:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryReadYaml(Y: Text; var R: Text)
    var
        O: JsonObject;
    begin
        O.ReadFromYaml(Y);
        O.WriteTo(R);
    end;

    local procedure ReadY(Y: Text): Text
    var
        R: Text;
    begin
        if TryReadYaml(Y, R) then
            exit(R);
        exit('ERR:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Path_Nested()
    var
        O: JsonObject;
        T: JsonToken;
        Inner: JsonToken;
    begin
        Doc(O);
        Observer.Observe('path_root', O.AsToken().Path());
        O.Get('a', T);
        Observer.Observe('path_a', T.Path());
        T.AsArray().Get(2, Inner);
        Observer.Observe('path_a_2', Inner.Path());
        Inner.AsObject().Get('b', T);
        Observer.Observe('path_a_2_b', T.Path());
        O.Get('c', T);
        Observer.Observe('path_c', T.Path());
        T.AsObject().Get('e', Inner);
        Observer.Observe('path_c_e', Inner.Path());
        Inner.AsArray().Get(1, T);
        Observer.Observe('path_c_e_1_null', T.Path());
        Observer.Observe('path_empty_object', Format(T.IsValue()));
        Observer.Expect('path_root', '');
        Observer.Expect('path_a', 'a');
        Observer.Expect('path_a_2', 'a[2]');
        Observer.Expect('path_a_2_b', 'a[2].b');
        Observer.Expect('path_c', 'c');
        Observer.Expect('path_c_e', 'c.e');
        Observer.Expect('path_c_e_1_null', 'c.e[1]');
        Observer.Expect('path_empty_object', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Path_SpecialKeys()
    var
        O: JsonObject;
        T: JsonToken;
    begin
        O.Add('a.b', 1);
        O.Add('with space', 2);
        O.Add('it''s', 3);
        O.Add('[0]', 4);
        O.Add('', 5);
        O.Get('a.b', T);
        Observer.Observe('path_dot_key', T.Path());
        O.Get('with space', T);
        Observer.Observe('path_space_key', T.Path());
        O.Get('it''s', T);
        Observer.Observe('path_apostrophe_key', T.Path());
        O.Get('[0]', T);
        Observer.Observe('path_bracket_key', T.Path());
        O.Get('', T);
        Observer.Observe('path_empty_key', T.Path());
        Observer.Expect('path_dot_key', '[''a.b'']');
        Observer.Expect('path_space_key', '[''with space'']');
        Observer.Expect('path_apostrophe_key', '[''it\''s'']');
        Observer.Expect('path_bracket_key', '[''[0]'']');
        Observer.Expect('path_empty_key', '');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToYaml_Scalars()
    var
        O: JsonObject;
    begin
        Observer.Observe('yaml_empty_object', Yaml(O));
        O.Add('s', 'text');
        O.Add('i', 42);
        O.Add('d', 1.5);
        O.Add('b', true);
        O.Add('n', 0);
        O.Add('neg', -7);
        O.Add('date', DMY2Date(15, 3, 2024));
        O.Add('time', 143015T);
        O.Add('datetime', CreateDateTime(DMY2Date(15, 3, 2024), 143015T));
        Observer.Observe('yaml_scalars', Yaml(O));
        Observer.Expect('yaml_empty_object', '{}\r\n');
        Observer.Expect('yaml_scalars', 's: text\r\ni: 42\r\nd: 1.5\r\nb: true\r\nn: 0\r\nneg: -7\r\ndate: 2024-03-15\r\ntime: 14:30:15\r\ndatetime: 2024-03-15T14:30:15.0000000Z\r\n');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToYaml_Nested()
    var
        O: JsonObject;
        Child: JsonObject;
        Arr: JsonArray;
        Empty: JsonObject;
        EmptyArr: JsonArray;
    begin
        Child.Add('x', 1);
        Child.Add('y', 'two');
        Arr.Add(1);
        Arr.Add('b');
        Arr.Add(Child);
        O.Add('child', Child);
        O.Add('list', Arr);
        O.Add('emptyobj', Empty);
        O.Add('emptylist', EmptyArr);
        Observer.Observe('yaml_nested', Yaml(O));
        Observer.Expect('yaml_nested', 'child:\r\n  x: 1\r\n  y: two\r\nlist:\r\n- 1\r\n- b\r\n- x: 1\r\n  y: two\r\nemptyobj: {}\r\nemptylist: []\r\n');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToYaml_SpecialText()
    var
        O: JsonObject;
    begin
        O.Add('empty', '');
        O.Add('space', ' ');
        O.Add('trailing', 'a ');
        O.Add('yes', 'yes');
        O.Add('null_text', 'null');
        O.Add('tilde', '~');
        O.Add('multiline', 'a' + NL() + 'b');
        O.Add('hash', '#c');
        O.Add('dash', '- x');
        O.Add('colon', 'a:b');
        O.Add('quote', 'say "hi"');
        O.Add('apos', 'it''s');
        O.Add('unicode', 'ünï ✓');
        Observer.Observe('yaml_special', Yaml(O));
        Observer.Expect('yaml_special', 'empty: ''''\r\nspace: '' ''\r\ntrailing: ''a ''\r\nyes: yes\r\nnull_text: null\r\ntilde: ~\r\nmultiline: >-\r\n  a\r\n\r\n  b\r\nhash: ''#c''\r\ndash: ''- x''\r\ncolon: a:b\r\nquote: say "hi"\r\napos: it''s\r\nunicode: ünï ✓\r\n');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToYaml_Null()
    var
        O: JsonObject;
        Jv: JsonValue;
        Arr: JsonArray;
    begin
        Jv.SetValueToNull();
        O.Add('nothing', Jv);
        Arr.Add(Jv);
        O.Add('list', Arr);
        Observer.Observe('yaml_null', Yaml(O));
        Observer.Expect('yaml_null', 'nothing: \r\nlist:\r\n- \r\n');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Shapes()
    begin
        Observer.Observe('read_empty', ReadY(''));
        Observer.Observe('read_one_line_flow', ReadY('{a: 1, b: x}'));
        Observer.Observe('read_json_text', ReadY('{"a":1}'));
        Observer.Observe('read_list_top', ReadY('- 1' + NL() + '- 2'));
        Observer.Observe('read_scalar_top', ReadY('hello'));
        Observer.Observe('read_key_value', ReadY('a: 1'));
        Observer.Observe('read_key_value_nl', ReadY('a: 1' + NL()));
        Observer.Observe('read_two_keys', ReadY('a: 1' + NL() + 'b: 2'));
        Observer.Observe('read_nested', ReadY('a:' + NL() + '  b: 1'));
        Observer.Observe('read_list_in_key', ReadY('a:' + NL() + '- 1' + NL() + '- 2'));
        Observer.Observe('read_quoted', ReadY('a: ''1'''));
        Observer.Observe('read_bool', ReadY('a: true'));
        Observer.Observe('read_null', ReadY('a: null'));
        Observer.Observe('read_bad', ReadY('a: [1, 2'));
        Observer.Observe('read_tab_indent', ReadY('a:' + NL() + '<TAB>b: 1'));
        Observer.Expect('read_empty', 'ERR:JSON tokens of type ''Null'' are not supported by this implementation.|InvalidJsonType');
        Observer.Expect('read_one_line_flow', '{"a":"1","b":"x"}');
        Observer.Expect('read_json_text', '{"a":"1"}');
        Observer.Expect('read_list_top', 'ERR:JSON tokens of type ''Array'' are not supported by this implementation.|InvalidJsonType');
        Observer.Expect('read_scalar_top', 'ERR:JSON tokens of type ''String'' are not supported by this implementation.|InvalidJsonType');
        Observer.Expect('read_key_value', '{"a":"1"}');
        Observer.Expect('read_key_value_nl', '{"a":"1"}');
        Observer.Expect('read_two_keys', '{"a":"1","b":"2"}');
        Observer.Expect('read_nested', '{"a":{"b":"1"}}');
        Observer.Expect('read_list_in_key', '{"a":["1","2"]}');
        Observer.Expect('read_quoted', '{"a":"1"}');
        Observer.Expect('read_bool', '{"a":"true"}');
        Observer.Expect('read_null', '{"a":null}');
        Observer.Expect('read_bad', 'ERR:The data does not represent valid YAML.|YamlBadFormat');
        Observer.Expect('read_tab_indent', '{"a":null,"<TAB>b":"1"}');
        Observer.Verify();
    end;
}
