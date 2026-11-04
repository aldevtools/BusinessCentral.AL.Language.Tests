// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: JSON: YAML: only a flat mapping of plain keys to numbers, Booleans and plain strings is written and read
// Facts: JsonObject.WriteToYaml / ReadFromYaml of flat, nested, array and quoting-needing content on the Cloud tier
// BC versions: 29 (27 and 28 by CI)

codeunit 70079 "LT PnA Json Yaml"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        JO: JsonObject;
        Yaml: Text;

    [TryFunction]
    local procedure TryWrite()
    begin
        Yaml := '';
        JO.WriteToYaml(Yaml);
    end;

    [TryFunction]
    local procedure TryRead(Src: Text)
    begin
        Clear(JO);
        JO.ReadFromYaml(Src);
    end;

    local procedure Write(var Observer: Codeunit "Probe Observer"; Name: Text; Json: Text)
    begin
        JO.ReadFrom(Json);
        Observer.Observe(Name, Format(TryWrite()) + '|' + Yaml);
        Observer.ObserveError(Name);
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    local procedure Read(var Observer: Codeunit "Probe Observer"; Name: Text; Src: Text)
    var
        Out: Text;
    begin
        Observer.Observe(Name, Format(TryRead(Src)));
        Observer.ObserveError(Name);
        JO.WriteTo(Out);
        Observer.Observe(Name + '-json', Out);
    end;

    [Test]
    procedure WriteToYaml_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Write(Observer, 'flat', '{"a":1,"b":true,"c":"txt"}');
        Write(Observer, 'empty', '{}');
        Write(Observer, 'nested', '{"a":{"b":1}}');
        Write(Observer, 'array', '{"a":[1,2,3]}');
        Write(Observer, 'array-of-objects', '{"a":[{"b":1},{"b":2}]}');
        Write(Observer, 'null', '{"a":null}');
        Write(Observer, 'decimal', '{"a":1.5}');
        Write(Observer, 'negative', '{"a":-3}');
        Observer.Expect('flat', 'Yes|a: 1\r\nb: true\r\nc: txt\r\n');
        Observer.Expect('flat|text', '');
        Observer.Expect('flat|code', '');
        Observer.Expect('empty', 'Yes|{}\r\n');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', '');
        Observer.Expect('nested', 'Yes|a:\r\n  b: 1\r\n');
        Observer.Expect('nested|text', '');
        Observer.Expect('nested|code', '');
        Observer.Expect('array', 'Yes|a:\r\n- 1\r\n- 2\r\n- 3\r\n');
        Observer.Expect('array|text', '');
        Observer.Expect('array|code', '');
        Observer.Expect('array-of-objects', 'Yes|a:\r\n- b: 1\r\n- b: 2\r\n');
        Observer.Expect('array-of-objects|text', '');
        Observer.Expect('array-of-objects|code', '');
        Observer.Expect('null', 'Yes|a: \r\n');
        Observer.Expect('null|text', '');
        Observer.Expect('null|code', '');
        Observer.Expect('decimal', 'Yes|a: 1.5\r\n');
        Observer.Expect('decimal|text', '');
        Observer.Expect('decimal|code', '');
        Observer.Expect('negative', 'Yes|a: -3\r\n');
        Observer.Expect('negative|text', '');
        Observer.Expect('negative|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToYaml_QuotingNeeds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Write(Observer, 'colon', '{"a":"x: y"}');
        Write(Observer, 'hash', '{"a":"x # y"}');
        Write(Observer, 'leading-space', '{"a":" x"}');
        Write(Observer, 'quote', '{"a":"say \"hi\""}');
        Write(Observer, 'numeric-text', '{"a":"123"}');
        Write(Observer, 'bool-text', '{"a":"true"}');
        Write(Observer, 'empty-text', '{"a":""}');
        Write(Observer, 'multiline', '{"a":"l1\nl2"}');
        Write(Observer, 'key-with-space', '{"a b":1}');
        Write(Observer, 'unicode', '{"a":"\u00e9"}');
        Observer.Expect('colon', 'Yes|a: ''x: y''\r\n');
        Observer.Expect('colon|text', '');
        Observer.Expect('colon|code', '');
        Observer.Expect('hash', 'Yes|a: ''x # y''\r\n');
        Observer.Expect('hash|text', '');
        Observer.Expect('hash|code', '');
        Observer.Expect('leading-space', 'Yes|a: '' x''\r\n');
        Observer.Expect('leading-space|text', '');
        Observer.Expect('leading-space|code', '');
        Observer.Expect('quote', 'Yes|a: say "hi"\r\n');
        Observer.Expect('quote|text', '');
        Observer.Expect('quote|code', '');
        Observer.Expect('numeric-text', 'Yes|a: 123\r\n');
        Observer.Expect('numeric-text|text', '');
        Observer.Expect('numeric-text|code', '');
        Observer.Expect('bool-text', 'Yes|a: true\r\n');
        Observer.Expect('bool-text|text', '');
        Observer.Expect('bool-text|code', '');
        Observer.Expect('empty-text', 'Yes|a: ''''\r\n');
        Observer.Expect('empty-text|text', '');
        Observer.Expect('empty-text|code', '');
        Observer.Expect('multiline', 'Yes|a: >-\r\n  l1\r\n\r\n  l2\r\n');
        Observer.Expect('multiline|text', '');
        Observer.Expect('multiline|code', '');
        Observer.Expect('key-with-space', 'Yes|a b: 1\r\n');
        Observer.Expect('key-with-space|text', '');
        Observer.Expect('key-with-space|code', '');
        Observer.Expect('unicode', 'Yes|a: é\r\n');
        Observer.Expect('unicode|text', '');
        Observer.Expect('unicode|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromYaml_Shapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Read(Observer, 'flat', 'a: 1' + Lf() + 'b: true' + Lf() + 'c: txt');
        Read(Observer, 'nested', 'a:' + Lf() + '  b: 1');
        Read(Observer, 'list', 'a:' + Lf() + '  - 1' + Lf() + '  - 2');
        Read(Observer, 'quoted', 'a: "x: y"');
        Read(Observer, 'empty', '');
        Read(Observer, 'garbage', ': : :');
        Observer.Expect('flat', 'Yes');
        Observer.Expect('flat|text', '');
        Observer.Expect('flat|code', '');
        Observer.Expect('flat-json', '{"a":"1","b":"true","c":"txt"}');
        Observer.Expect('nested', 'Yes');
        Observer.Expect('nested|text', '');
        Observer.Expect('nested|code', '');
        Observer.Expect('nested-json', '{"a":{"b":"1"}}');
        Observer.Expect('list', 'Yes');
        Observer.Expect('list|text', '');
        Observer.Expect('list|code', '');
        Observer.Expect('list-json', '{"a":["1","2"]}');
        Observer.Expect('quoted', 'Yes');
        Observer.Expect('quoted|text', '');
        Observer.Expect('quoted|code', '');
        Observer.Expect('quoted-json', '{"a":"x: y"}');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty|text', 'JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('empty|code', 'InvalidJsonType');
        Observer.Expect('empty-json', '{}');
        Observer.Expect('garbage', 'No');
        Observer.Expect('garbage|text', 'The data does not represent valid YAML.');
        Observer.Expect('garbage|code', 'YamlBadFormat');
        Observer.Expect('garbage-json', '{}');
        Observer.Verify();
    end;
}
