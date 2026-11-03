// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfrom-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonObject.ReadFrom(InStream) and JsonArray.ReadFrom(InStream) of a stream whose first token is a number, true, null, a string, an array / an object of the other kind, an empty stream, white space only, trailing text, a truncated document, and of bytes that are not valid UTF-8 (a lone E4, a truncated two-byte sequence, an overlong C0 80); the result of the call, the error text and code and the JSON read
// Settles docs/probes-needed.md row "JSON on streams" (Probe fixes): ReadFrom(InStream) of 5, true, null and of invalid UTF-8
// BC versions: 29 (27 and 28 by CI)

codeunit 74314 "LT P166 Json Stream Tokens"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryReadObject(var InS: InStream; var Obj: JsonObject; var Result: Boolean)
    begin
        Result := Obj.ReadFrom(InS);
    end;

    [TryFunction]
    local procedure TryReadArray(var InS: InStream; var Arr: JsonArray; var Result: Boolean)
    begin
        Result := Arr.ReadFrom(InS);
    end;

    local procedure Ascii(var Bytes: List of [Integer]; Value: Text)
    var
        i: Integer;
        Code: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            Bytes.Add(Code);
        end;
    end;

    local procedure Fill(var TempBlob: Codeunit "Temp Blob"; Bytes: List of [Integer])
    var
        OutS: OutStream;
        B: Byte;
        Value: Integer;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        foreach Value in Bytes do begin
            B := Value;
            OutS.Write(B);
        end;
    end;

    local procedure ReadObject(var Observer: Codeunit "Probe Observer"; Name: Text; Bytes: List of [Integer])
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Obj: JsonObject;
        Result: Boolean;
        Text: Text;
        Passed: Boolean;
    begin
        Fill(TempBlob, Bytes);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Passed := TryReadObject(InS, Obj, Result);
        Observer.Observe(Name + '_noError', Format(Passed));
        if Passed then begin
            Observer.Observe(Name + '_result', Format(Result));
            Obj.WriteTo(Text);
            Observer.Observe(Name + '_json', Text);
        end else
            Observer.ObserveError(Name);
    end;

    local procedure ReadArray(var Observer: Codeunit "Probe Observer"; Name: Text; Bytes: List of [Integer])
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Arr: JsonArray;
        Result: Boolean;
        Text: Text;
        Passed: Boolean;
    begin
        Fill(TempBlob, Bytes);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Passed := TryReadArray(InS, Arr, Result);
        Observer.Observe(Name + '_noError', Format(Passed));
        if Passed then begin
            Observer.Observe(Name + '_result', Format(Result));
            Arr.WriteTo(Text);
            Observer.Observe(Name + '_json', Text);
        end else
            Observer.ObserveError(Name);
    end;

    local procedure AsciiOf(Value: Text) Bytes: List of [Integer]
    begin
        Ascii(Bytes, Value);
    end;

    [Test]
    procedure JsonObject_ReadFromStream_ScalarFirstToken()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadObject(Observer, 'number', AsciiOf('5'));
        ReadObject(Observer, 'true', AsciiOf('true'));
        ReadObject(Observer, 'false', AsciiOf('false'));
        ReadObject(Observer, 'null', AsciiOf('null'));
        ReadObject(Observer, 'string', AsciiOf('"s"'));
        Observer.Expect('number_noError', 'Yes');
        Observer.Expect('number_result', 'No');
        Observer.Expect('number_json', '{}');
        Observer.Expect('true_noError', 'Yes');
        Observer.Expect('true_result', 'No');
        Observer.Expect('true_json', '{}');
        Observer.Expect('false_noError', 'Yes');
        Observer.Expect('false_result', 'No');
        Observer.Expect('false_json', '{}');
        Observer.Expect('null_noError', 'Yes');
        Observer.Expect('null_result', 'No');
        Observer.Expect('null_json', '{}');
        Observer.Expect('string_noError', 'Yes');
        Observer.Expect('string_result', 'No');
        Observer.Expect('string_json', '{}');
        Observer.Verify();
    end;

    [Test]
    procedure JsonObject_ReadFromStream_OtherShapes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadObject(Observer, 'array', AsciiOf('[1]'));
        ReadObject(Observer, 'object', AsciiOf('{"a":1}'));
        ReadObject(Observer, 'empty', AsciiOf(''));
        ReadObject(Observer, 'blank', AsciiOf('   '));
        ReadObject(Observer, 'trailing', AsciiOf('{"a":1} x'));
        ReadObject(Observer, 'truncated', AsciiOf('{"a":'));
        Observer.Expect('array_noError', 'Yes');
        Observer.Expect('array_result', 'No');
        Observer.Expect('array_json', '{}');
        Observer.Expect('object_noError', 'Yes');
        Observer.Expect('object_result', 'Yes');
        Observer.Expect('object_json', '{"a":1}');
        Observer.Expect('empty_noError', 'Yes');
        Observer.Expect('empty_result', 'No');
        Observer.Expect('empty_json', '{}');
        Observer.Expect('blank_noError', 'Yes');
        Observer.Expect('blank_result', 'No');
        Observer.Expect('blank_json', '{}');
        Observer.Expect('trailing_noError', 'Yes');
        Observer.Expect('trailing_result', 'Yes');
        Observer.Expect('trailing_json', '{"a":1}');
        Observer.Expect('truncated_noError', 'Yes');
        Observer.Expect('truncated_result', 'No');
        Observer.Expect('truncated_json', '{}');
        Observer.Verify();
    end;

    [Test]
    procedure JsonObject_ReadFromStream_InvalidUtf8()
    var
        Observer: Codeunit "Probe Observer";
        Bytes: List of [Integer];
    begin
        Ascii(Bytes, '{"a":"');
        Bytes.Add(228);
        Ascii(Bytes, '"}');
        ReadObject(Observer, 'loneE4', Bytes);
        Clear(Bytes);
        Ascii(Bytes, '{"a":"');
        Bytes.Add(195);
        Ascii(Bytes, '"}');
        ReadObject(Observer, 'truncatedC3', Bytes);
        Clear(Bytes);
        Ascii(Bytes, '{"a":"');
        Bytes.Add(192);
        Bytes.Add(128);
        Ascii(Bytes, '"}');
        ReadObject(Observer, 'overlongC080', Bytes);
        Clear(Bytes);
        Ascii(Bytes, '{"a":"');
        Bytes.Add(255);
        Ascii(Bytes, '"}');
        ReadObject(Observer, 'byteFF', Bytes);
        Observer.Expect('loneE4_noError', 'Yes');
        Observer.Expect('loneE4_result', 'Yes');
        Observer.Expect('loneE4_json', '{"a":"�"}');
        Observer.Expect('truncatedC3_noError', 'Yes');
        Observer.Expect('truncatedC3_result', 'Yes');
        Observer.Expect('truncatedC3_json', '{"a":"�"}');
        Observer.Expect('overlongC080_noError', 'Yes');
        Observer.Expect('overlongC080_result', 'Yes');
        Observer.Expect('overlongC080_json', '{"a":"��"}');
        Observer.Expect('byteFF_noError', 'Yes');
        Observer.Expect('byteFF_result', 'Yes');
        Observer.Expect('byteFF_json', '{"a":"�"}');
        Observer.Verify();
    end;

    [Test]
    procedure JsonArray_ReadFromStream_ScalarFirstToken()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadArray(Observer, 'number', AsciiOf('5'));
        ReadArray(Observer, 'true', AsciiOf('true'));
        ReadArray(Observer, 'null', AsciiOf('null'));
        ReadArray(Observer, 'string', AsciiOf('"s"'));
        ReadArray(Observer, 'object', AsciiOf('{"a":1}'));
        ReadArray(Observer, 'array', AsciiOf('[1,"x"]'));
        Observer.Expect('number_noError', 'Yes');
        Observer.Expect('number_result', 'No');
        Observer.Expect('number_json', '[]');
        Observer.Expect('true_noError', 'Yes');
        Observer.Expect('true_result', 'No');
        Observer.Expect('true_json', '[]');
        Observer.Expect('null_noError', 'Yes');
        Observer.Expect('null_result', 'No');
        Observer.Expect('null_json', '[]');
        Observer.Expect('string_noError', 'Yes');
        Observer.Expect('string_result', 'No');
        Observer.Expect('string_json', '[]');
        Observer.Expect('object_noError', 'Yes');
        Observer.Expect('object_result', 'No');
        Observer.Expect('object_json', '[]');
        Observer.Expect('array_noError', 'Yes');
        Observer.Expect('array_result', 'Yes');
        Observer.Expect('array_json', '[1,"x"]');
        Observer.Verify();
    end;

    [Test]
    procedure JsonArray_ReadFromStream_OtherShapes()
    var
        Observer: Codeunit "Probe Observer";
        Bytes: List of [Integer];
    begin
        ReadArray(Observer, 'empty', AsciiOf(''));
        ReadArray(Observer, 'blank', AsciiOf('  '));
        ReadArray(Observer, 'trailing', AsciiOf('[1] x'));
        ReadArray(Observer, 'truncated', AsciiOf('[1,'));
        Ascii(Bytes, '["');
        Bytes.Add(228);
        Ascii(Bytes, '"]');
        ReadArray(Observer, 'loneE4', Bytes);
        Observer.Expect('empty_noError', 'Yes');
        Observer.Expect('empty_result', 'No');
        Observer.Expect('empty_json', '[]');
        Observer.Expect('blank_noError', 'Yes');
        Observer.Expect('blank_result', 'No');
        Observer.Expect('blank_json', '[]');
        Observer.Expect('trailing_noError', 'Yes');
        Observer.Expect('trailing_result', 'Yes');
        Observer.Expect('trailing_json', '[1]');
        Observer.Expect('truncated_noError', 'Yes');
        Observer.Expect('truncated_result', 'No');
        Observer.Expect('truncated_json', '[]');
        Observer.Expect('loneE4_noError', 'Yes');
        Observer.Expect('loneE4_result', 'Yes');
        Observer.Expect('loneE4_json', '["�"]');
        Observer.Verify();
    end;
}
