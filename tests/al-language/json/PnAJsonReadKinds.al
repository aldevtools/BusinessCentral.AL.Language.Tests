// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: JSON: ReadFrom of JSON of the wrong top-level kind (an array into a JsonObject) with the result unused
// Facts: JsonObject/JsonArray/JsonToken.ReadFrom with the wrong top-level kind, result used and result unused
// BC versions: 29 (27 and 28 by CI)

codeunit 70077 "LT PnA Json ReadKinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        JO: JsonObject;
        JA: JsonArray;
        JT: JsonToken;
        JV: JsonValue;

    [TryFunction]
    local procedure TryOp(Op: Integer; Src: Text)
    begin
        case Op of
            1:
                JO.ReadFrom(Src);
            2:
                JA.ReadFrom(Src);
            3:
                JT.ReadFrom(Src);
            4:
                JV.ReadFrom(Src);
        end;
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Op: Integer; Src: Text)
    begin
        Observer.Observe(Name, Format(TryOp(Op, Src)));
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure StatementForm_WrongKind()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'obj<-array', 1, '[1,2]');
        Probe(Observer, 'obj<-number', 1, '5');
        Probe(Observer, 'obj<-string', 1, '"x"');
        Probe(Observer, 'obj<-null', 1, 'null');
        Probe(Observer, 'obj<-true', 1, 'true');
        Probe(Observer, 'obj<-object', 1, '{"a":1}');
        Probe(Observer, 'arr<-object', 2, '{"a":1}');
        Probe(Observer, 'arr<-number', 2, '5');
        Probe(Observer, 'arr<-string', 2, '"x"');
        Probe(Observer, 'arr<-array', 2, '[1]');
        Probe(Observer, 'tok<-object', 3, '{"a":1}');
        Probe(Observer, 'tok<-array', 3, '[1]');
        Probe(Observer, 'tok<-number', 3, '5');
        Probe(Observer, 'val<-number', 4, '5');
        Probe(Observer, 'val<-object', 4, '{"a":1}');
        Probe(Observer, 'val<-array', 4, '[1]');
        Probe(Observer, 'val<-null', 4, 'null');
        Observer.Expect('obj<-array', 'No');
        Observer.Expect('obj<-array|text', 'JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('obj<-array|code', 'InvalidJsonType');
        Observer.Expect('obj<-number', 'No');
        Observer.Expect('obj<-number|text', 'JSON tokens of type ''Integer'' are not supported by this implementation.');
        Observer.Expect('obj<-number|code', 'InvalidJsonType');
        Observer.Expect('obj<-string', 'No');
        Observer.Expect('obj<-string|text', 'JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('obj<-string|code', 'InvalidJsonType');
        Observer.Expect('obj<-null', 'No');
        Observer.Expect('obj<-null|text', 'JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('obj<-null|code', 'InvalidJsonType');
        Observer.Expect('obj<-true', 'No');
        Observer.Expect('obj<-true|text', 'JSON tokens of type ''Boolean'' are not supported by this implementation.');
        Observer.Expect('obj<-true|code', 'InvalidJsonType');
        Observer.Expect('obj<-object', 'Yes');
        Observer.Expect('obj<-object|text', '');
        Observer.Expect('obj<-object|code', '');
        Observer.Expect('arr<-object', 'No');
        Observer.Expect('arr<-object|text', 'JSON tokens of type ''Object'' are not supported by this implementation.');
        Observer.Expect('arr<-object|code', 'InvalidJsonType');
        Observer.Expect('arr<-number', 'No');
        Observer.Expect('arr<-number|text', 'JSON tokens of type ''Integer'' are not supported by this implementation.');
        Observer.Expect('arr<-number|code', 'InvalidJsonType');
        Observer.Expect('arr<-string', 'No');
        Observer.Expect('arr<-string|text', 'JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('arr<-string|code', 'InvalidJsonType');
        Observer.Expect('arr<-array', 'Yes');
        Observer.Expect('arr<-array|text', '');
        Observer.Expect('arr<-array|code', '');
        Observer.Expect('tok<-object', 'Yes');
        Observer.Expect('tok<-object|text', '');
        Observer.Expect('tok<-object|code', '');
        Observer.Expect('tok<-array', 'Yes');
        Observer.Expect('tok<-array|text', '');
        Observer.Expect('tok<-array|code', '');
        Observer.Expect('tok<-number', 'Yes');
        Observer.Expect('tok<-number|text', '');
        Observer.Expect('tok<-number|code', '');
        Observer.Expect('val<-number', 'Yes');
        Observer.Expect('val<-number|text', '');
        Observer.Expect('val<-number|code', '');
        Observer.Expect('val<-object', 'No');
        Observer.Expect('val<-object|text', 'JSON tokens of type ''Object'' are not supported by this implementation.');
        Observer.Expect('val<-object|code', 'InvalidJsonType');
        Observer.Expect('val<-array', 'No');
        Observer.Expect('val<-array|text', 'JSON tokens of type ''Array'' are not supported by this implementation.');
        Observer.Expect('val<-array|code', 'InvalidJsonType');
        Observer.Expect('val<-null', 'Yes');
        Observer.Expect('val<-null|text', '');
        Observer.Expect('val<-null|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure StatementForm_InvalidText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'obj<-empty', 1, '');
        Probe(Observer, 'obj<-blank', 1, '   ');
        Probe(Observer, 'obj<-garbage', 1, 'not json');
        Probe(Observer, 'obj<-trailing', 1, '{"a":1} x');
        Probe(Observer, 'obj<-trailing-comma', 1, '{"a":1,}');
        Probe(Observer, 'obj<-single-quote', 1, '{''a'':1}');
        Probe(Observer, 'obj<-unclosed', 1, '{"a":1');
        Probe(Observer, 'arr<-unclosed', 2, '[1,');
        Probe(Observer, 'arr<-empty', 2, '');
        Probe(Observer, 'tok<-empty', 3, '');
        Observer.Expect('obj<-empty', 'No');
        Observer.Expect('obj<-empty|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('obj<-empty|code', 'InvalidJsonData');
        Observer.Expect('obj<-blank', 'No');
        Observer.Expect('obj<-blank|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('obj<-blank|code', 'InvalidJsonData');
        Observer.Expect('obj<-garbage', 'No');
        Observer.Expect('obj<-garbage|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('obj<-garbage|code', 'InvalidJsonData');
        Observer.Expect('obj<-trailing', 'Yes');
        Observer.Expect('obj<-trailing|text', '');
        Observer.Expect('obj<-trailing|code', '');
        Observer.Expect('obj<-trailing-comma', 'Yes');
        Observer.Expect('obj<-trailing-comma|text', '');
        Observer.Expect('obj<-trailing-comma|code', '');
        Observer.Expect('obj<-single-quote', 'Yes');
        Observer.Expect('obj<-single-quote|text', '');
        Observer.Expect('obj<-single-quote|code', '');
        Observer.Expect('obj<-unclosed', 'No');
        Observer.Expect('obj<-unclosed|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('obj<-unclosed|code', 'InvalidJsonData');
        Observer.Expect('arr<-unclosed', 'No');
        Observer.Expect('arr<-unclosed|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('arr<-unclosed|code', 'InvalidJsonData');
        Observer.Expect('arr<-empty', 'No');
        Observer.Expect('arr<-empty|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('arr<-empty|code', 'InvalidJsonData');
        Observer.Expect('tok<-empty', 'No');
        Observer.Expect('tok<-empty|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('tok<-empty|code', 'InvalidJsonData');
        Observer.Verify();
    end;

    [Test]
    procedure ResultUsed_WrongKind()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        A: JsonArray;
        T: JsonToken;
    begin
        Observer.Observe('obj<-array', Format(O.ReadFrom('[1,2]')));
        Observer.Observe('obj<-number', Format(O.ReadFrom('5')));
        Observer.Observe('obj<-garbage', Format(O.ReadFrom('not json')));
        Observer.Observe('arr<-object', Format(A.ReadFrom('{"a":1}')));
        Observer.Observe('tok<-garbage', Format(T.ReadFrom('not json')));
        Observer.Observe('obj<-empty-object', Format(O.ReadFrom('{}')));
        Observer.Observe('obj<-empty-object-keys', Format(O.Keys().Count()));
        Observer.Observe('obj<-array-then-keys', Format(O.ReadFrom('[1,2]')));
        Observer.Observe('obj-keys-after-failed-read', Format(O.Keys().Count()));
        Observer.Expect('obj<-array', 'No');
        Observer.Expect('obj<-number', 'No');
        Observer.Expect('obj<-garbage', 'No');
        Observer.Expect('arr<-object', 'No');
        Observer.Expect('tok<-garbage', 'No');
        Observer.Expect('obj<-empty-object', 'Yes');
        Observer.Expect('obj<-empty-object-keys', '0');
        Observer.Expect('obj<-array-then-keys', 'No');
        Observer.Expect('obj-keys-after-failed-read', '0');
        Observer.Verify();
    end;
}
