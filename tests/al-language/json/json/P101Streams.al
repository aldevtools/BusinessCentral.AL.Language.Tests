// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70858
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonObject Yaml, JsonValue and JsonToken stream ReadFrom/WriteTo (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70858 "LT P101 Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P101_ObjectYamlRoundtrip()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P101 Blob";
        O: JsonObject;
        O2: JsonObject;
        OutS: OutStream;
        InS: InStream;
        Yaml: Text;
        R: Text;
    begin
        Blob.DeleteAll();
        O.ReadFrom('{"a":1,"b":"two","c":[true,null],"d":{"e":2.5}}');
        Blob.Id := 1;
        Blob.Data.CreateOutStream(OutS);
        Observer.Observe('write_ok', Format(O.WriteToYaml(OutS)));
        Blob.Insert();
        Blob.CalcFields(Data);
        Observer.Observe('has_data', Format(Blob.Data.HasValue()));
        Blob.Data.CreateInStream(InS);
        InS.ReadText(Yaml);
        Observer.Observe('yaml_first_line', Yaml);
        Blob.Data.CreateInStream(InS);
        Observer.Observe('read_ok', Format(O2.ReadFromYaml(InS)));
        O2.WriteTo(R);
        Observer.Observe('roundtrip', R);
        Blob.DeleteAll();
        Observer.Expect('write_ok', 'Yes');
        Observer.Expect('has_data', 'Yes');
        Observer.Expect('yaml_first_line', 'a: 1');
        Observer.Expect('read_ok', 'Yes');
        Observer.Expect('roundtrip', '{"a":"1","b":"two","c":["true",null],"d":{"e":"2.5"}}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_ValueStreams()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P101 Blob";
        V: JsonValue;
        V2: JsonValue;
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
        R: Text;
    begin
        Blob.DeleteAll();
        V.SetValue('hello');
        Blob.Id := 1;
        Blob.Data.CreateOutStream(OutS);
        Observer.Observe('write_ok', Format(V.WriteTo(OutS)));
        Blob.Insert();
        Blob.Data.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('written', Txt);
        Blob.Data.CreateInStream(InS);
        Observer.Observe('read_ok', Format(V2.ReadFrom(InS)));
        V2.WriteTo(R);
        Observer.Observe('read_back', R);
        Observer.Observe('read_astext', V2.AsText());
        Blob.Data.CreateOutStream(OutS);
        OutS.WriteText('42');
        Blob.Id := 1; if not Blob.Insert() then Blob.Modify();
        Blob.Data.CreateInStream(InS);
        Observer.Observe('number_ok', Format(V2.ReadFrom(InS)));
        asserterror Observer.Observe('number_asint', Format(V2.AsInteger()));
        Observer.ObserveError('af123');
        Blob.Data.CreateOutStream(OutS);
        OutS.WriteText('{"a":1}');
        Blob.Id := 1; if not Blob.Insert() then Blob.Modify();
        Observer.Observe('af128', 'no error');
        Blob.Data.CreateInStream(InS);
        asserterror V2.ReadFrom(InS);
        Observer.ObserveError('object_into_value');
        Blob.Data.CreateOutStream(OutS);
        OutS.WriteText('[1]');
        Blob.Id := 1; if not Blob.Insert() then Blob.Modify();
        Observer.Observe('af136', 'no error');
        Blob.Data.CreateInStream(InS);
        asserterror V2.ReadFrom(InS);
        Observer.ObserveError('array_into_value');
        Blob.Data.CreateOutStream(OutS);
        OutS.WriteText('null');
        Blob.Id := 1; if not Blob.Insert() then Blob.Modify();
        Blob.Data.CreateInStream(InS);
        Observer.Observe('null_ok', Format(V2.ReadFrom(InS)));
        Observer.Observe('null_isnull', Format(V2.IsNull()));
        Blob.Data.CreateOutStream(OutS);
        OutS.WriteText('');
        Blob.Id := 1; if not Blob.Insert() then Blob.Modify();
        Blob.Data.CreateInStream(InS);
        asserterror V2.ReadFrom(InS);
        Observer.ObserveError('empty_into_value');
        Clear(V);
        Blob.Data.CreateOutStream(OutS);
        Observer.Observe('default_write_ok', Format(V.WriteTo(OutS)));
        Blob.DeleteAll();
        Observer.Expect('write_ok', 'Yes');
        Observer.Expect('written', '"hello"');
        Observer.Expect('read_ok', 'Yes');
        Observer.Expect('read_back', '"hello"');
        Observer.Expect('read_astext', 'hello');
        Observer.Expect('number_ok', 'No');
        Observer.Expect('af123|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.');
        Observer.Expect('af123|code', 'Conversion');
        Observer.Expect('af128', 'no error');
        Observer.Expect('object_into_value|text', 'JSON tokens of type ''Object'' are not supported by this implementation.');
        Observer.Expect('object_into_value|code', 'InvalidJsonType');
        Observer.Expect('af136', 'no error');
        Observer.Expect('array_into_value|text', 'JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('array_into_value|code', 'InvalidJsonType');
        Observer.Expect('null_ok', 'No');
        Observer.Expect('null_isnull', 'No');
        Observer.Expect('empty_into_value|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('empty_into_value|code', 'InvalidJsonData');
        Observer.Expect('default_write_ok', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P101_TokenStreams()
    var
        Observer: Codeunit "Probe Observer";
        Blob: Record "LT P101 Blob";
        T: JsonToken;
        T2: JsonToken;
        O: JsonObject;
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
        R: Text;
    begin
        Blob.DeleteAll();
        O.ReadFrom('{"a":[1,2,{"b":null}]}');
        T := O.AsToken();
        Blob.Id := 1;
        Blob.Data.CreateOutStream(OutS);
        Observer.Observe('write_ok', Format(T.WriteTo(OutS)));
        Blob.Insert();
        Blob.Data.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('written', Txt);
        Blob.Data.CreateInStream(InS);
        Observer.Observe('read_ok', Format(T2.ReadFrom(InS)));
        T2.WriteTo(R);
        Observer.Observe('read_back', R);
        Observer.Observe('is_object', Format(T2.IsObject()));
        Blob.Data.CreateOutStream(OutS);
        OutS.WriteText('"text"');
        Blob.Modify();
        Blob.Data.CreateInStream(InS);
        Observer.Observe('text_ok', Format(T2.ReadFrom(InS)));
        Observer.Observe('text_isvalue', Format(T2.IsValue()));
        Blob.Data.CreateOutStream(OutS);
        OutS.WriteText('{bad');
        Blob.Modify();
        Blob.Data.CreateInStream(InS);
        asserterror T2.ReadFrom(InS);
        Observer.ObserveError('bad_json');
        Blob.Data.CreateOutStream(OutS);
        OutS.WriteText('');
        asserterror Blob.Modify();
        Observer.ObserveError('af198');
        Blob.Data.CreateInStream(InS);
        asserterror T2.ReadFrom(InS);
        Observer.ObserveError('empty_json');
        Clear(T);
        Blob.Data.CreateOutStream(OutS);
        T.WriteTo(OutS);
        Observer.Observe('write_default_token', 'no error');
        Blob.DeleteAll();
        Observer.Expect('write_ok', 'Yes');
        Observer.Expect('written', '{"a":[1,2,{"b":null}]}');
        Observer.Expect('read_ok', 'Yes');
        Observer.Expect('read_back', '{"a":[1,2,{"b":null}]}');
        Observer.Expect('is_object', 'Yes');
        Observer.Expect('text_ok', 'Yes');
        Observer.Expect('text_isvalue', 'Yes');
        Observer.Expect('bad_json|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('bad_json|code', 'InvalidJsonData');
        Observer.Expect('af198|text', 'The LT P101 Blob does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af198|code', 'DB:RecordNotFound');
        Observer.Expect('empty_json|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('empty_json|code', 'InvalidJsonData');
        Observer.Expect('write_default_token', 'no error');
        Observer.Verify();
    end;
}
