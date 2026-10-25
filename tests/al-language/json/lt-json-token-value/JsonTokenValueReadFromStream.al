// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-readfrom-instream-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonToken.ReadFrom(InStream) and JsonValue.ReadFrom(InStream) of a stream holding a number, true, null, a string, an object, an array, an empty stream and a lone E4 byte
// Settles docs/probes-needed.md row "JSON on streams" (Probe fixes): ReadFrom(InStream) of 5, true, null for the token and value types
// RISKY (own file): JsonValue.ReadFrom(InStream) is assumed to exist in runtime 16; if it does not compile only this file drops
// BC versions: 29 (27 and 28 by CI)

codeunit 74315 "LT P166 Json Token Stream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryReadToken(var InS: InStream; var Tok: JsonToken; var Result: Boolean)
    begin
        Result := Tok.ReadFrom(InS);
    end;

    [TryFunction]
    local procedure TryReadValue(var InS: InStream; var Val: JsonValue; var Result: Boolean)
    begin
        Result := Val.ReadFrom(InS);
    end;

    local procedure Fill(var TempBlob: Codeunit "Temp Blob"; Value: Text; Extra: Integer)
    var
        OutS: OutStream;
        B: Byte;
        i: Integer;
        Code: Integer;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            B := Code;
            OutS.Write(B);
        end;
        if Extra > 0 then begin
            B := Extra;
            OutS.Write(B);
        end;
    end;

    local procedure ReadToken(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text; Extra: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Tok: JsonToken;
        Result: Boolean;
        Text: Text;
        Passed: Boolean;
    begin
        Fill(TempBlob, Value, Extra);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Passed := TryReadToken(InS, Tok, Result);
        Observer.Observe(Name + '_noError', Format(Passed));
        if Passed then begin
            Observer.Observe(Name + '_result', Format(Result));
            Tok.WriteTo(Text);
            Observer.Observe(Name + '_json', Text);
            Observer.Observe(Name + '_isValue', Format(Tok.IsValue()));
        end else
            Observer.ObserveError(Name);
    end;

    local procedure ReadValue(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Val: JsonValue;
        Result: Boolean;
        Text: Text;
        Passed: Boolean;
    begin
        Fill(TempBlob, Value, 0);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Passed := TryReadValue(InS, Val, Result);
        Observer.Observe(Name + '_noError', Format(Passed));
        if Passed then begin
            Observer.Observe(Name + '_result', Format(Result));
            Val.WriteTo(Text);
            Observer.Observe(Name + '_json', Text);
            Observer.Observe(Name + '_isNull', Format(Val.IsNull()));
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure JsonToken_ReadFromStream_Scalars()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadToken(Observer, 'number', '5', 0);
        ReadToken(Observer, 'true', 'true', 0);
        ReadToken(Observer, 'null', 'null', 0);
        ReadToken(Observer, 'string', '"s"', 0);
        Observer.Expect('number_noError', 'Yes');
        Observer.Expect('number_result', 'Yes');
        Observer.Expect('number_json', '5');
        Observer.Expect('number_isValue', 'Yes');
        Observer.Expect('true_noError', 'Yes');
        Observer.Expect('true_result', 'Yes');
        Observer.Expect('true_json', 'true');
        Observer.Expect('true_isValue', 'Yes');
        Observer.Expect('null_noError', 'Yes');
        Observer.Expect('null_result', 'Yes');
        Observer.Expect('null_json', 'null');
        Observer.Expect('null_isValue', 'Yes');
        Observer.Expect('string_noError', 'Yes');
        Observer.Expect('string_result', 'Yes');
        Observer.Expect('string_json', '"s"');
        Observer.Expect('string_isValue', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure JsonToken_ReadFromStream_ContainersAndEdges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadToken(Observer, 'object', '{"a":1}', 0);
        ReadToken(Observer, 'array', '[1,2]', 0);
        ReadToken(Observer, 'empty', '', 0);
        ReadToken(Observer, 'loneE4', '{"a":"', 228);
        Observer.Expect('object_noError', 'Yes');
        Observer.Expect('object_result', 'Yes');
        Observer.Expect('object_json', '{"a":1}');
        Observer.Expect('object_isValue', 'No');
        Observer.Expect('array_noError', 'Yes');
        Observer.Expect('array_result', 'Yes');
        Observer.Expect('array_json', '[1,2]');
        Observer.Expect('array_isValue', 'No');
        Observer.Expect('empty_noError', 'Yes');
        Observer.Expect('empty_result', 'No');
        Observer.Expect('empty_json', 'null');
        Observer.Expect('empty_isValue', 'Yes');
        Observer.Expect('loneE4_noError', 'Yes');
        Observer.Expect('loneE4_result', 'No');
        Observer.Expect('loneE4_json', 'null');
        Observer.Expect('loneE4_isValue', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_ReadFromStream_Scalars()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadValue(Observer, 'number', '5');
        ReadValue(Observer, 'true', 'true');
        ReadValue(Observer, 'null', 'null');
        ReadValue(Observer, 'string', '"s"');
        Observer.Expect('number_noError', 'Yes');
        Observer.Expect('number_result', 'Yes');
        Observer.Expect('number_json', '5');
        Observer.Expect('number_isNull', 'No');
        Observer.Expect('true_noError', 'Yes');
        Observer.Expect('true_result', 'Yes');
        Observer.Expect('true_json', 'true');
        Observer.Expect('true_isNull', 'No');
        Observer.Expect('null_noError', 'Yes');
        Observer.Expect('null_result', 'Yes');
        Observer.Expect('null_json', 'null');
        Observer.Expect('null_isNull', 'Yes');
        Observer.Expect('string_noError', 'Yes');
        Observer.Expect('string_result', 'Yes');
        Observer.Expect('string_json', '"s"');
        Observer.Expect('string_isNull', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure JsonValue_ReadFromStream_ContainersAndEdges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadValue(Observer, 'object', '{"a":1}');
        ReadValue(Observer, 'array', '[1]');
        ReadValue(Observer, 'empty', '');
        Observer.Expect('object_noError', 'Yes');
        Observer.Expect('object_result', 'No');
        Observer.Expect('object_json', 'null');
        Observer.Expect('object_isNull', 'Yes');
        Observer.Expect('array_noError', 'Yes');
        Observer.Expect('array_result', 'No');
        Observer.Expect('array_json', 'null');
        Observer.Expect('array_isNull', 'Yes');
        Observer.Expect('empty_noError', 'Yes');
        Observer.Expect('empty_result', 'No');
        Observer.Expect('empty_json', 'null');
        Observer.Expect('empty_isNull', 'Yes');
        Observer.Verify();
    end;

    // Writer SN (2026-10-25, runtime hand-off refuse-json-streams "JsonValue.ReadFrom(InStream) of 5 / null into a fresh vs a filled JsonValue"):
    // P101Streams.al:117/:126 read '42' and 'null' into a JsonValue that already holds a value; JsonValue_ReadFromStream_Scalars reads into a fresh one.
    local procedure ReadValueInto(var Observer: Codeunit "Probe Observer"; Name: Text; Prefill: Integer; Value: Text; WithEncoding: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Val: JsonValue;
        Result: Boolean;
        Text: Text;
        Passed: Boolean;
    begin
        case Prefill of
            1:
                Val.SetValue('hello');
            2:
                Val.SetValue(7);
            3:
                Val.SetValueToNull();
            4:
                Val.ReadFrom('8');
        end;
        Fill(TempBlob, Value, 0);
        if WithEncoding then
            TempBlob.CreateInStream(InS, TextEncoding::UTF8)
        else
            TempBlob.CreateInStream(InS);
        Passed := TryReadValue(InS, Val, Result);
        Observer.Observe(Name + '_noError', Format(Passed));
        if Passed then begin
            Observer.Observe(Name + '_result', Format(Result));
            Val.WriteTo(Text);
            Observer.Observe(Name + '_json', Text);
            Observer.Observe(Name + '_isNull', Format(Val.IsNull()));
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure JsonValue_ReadFromStream_IntoValueHoldingText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadValueInto(Observer, 'number', 1, '5', true);
        ReadValueInto(Observer, 'null', 1, 'null', true);
        ReadValueInto(Observer, 'string', 1, '"s"', true);
        ReadValueInto(Observer, 'true', 1, 'true', true);
        ReadValueInto(Observer, 'number_noenc', 1, '42', false);
        Observer.Finish();
    end;

    [Test]
    procedure JsonValue_ReadFromStream_IntoValueHoldingNumberOrNull()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadValueInto(Observer, 'num_number', 2, '5', true);
        ReadValueInto(Observer, 'num_string', 2, '"s"', true);
        ReadValueInto(Observer, 'null_number', 3, '5', true);
        ReadValueInto(Observer, 'null_null', 3, 'null', true);
        ReadValueInto(Observer, 'read_number', 4, '5', true);
        ReadValueInto(Observer, 'read_null', 4, 'null', true);
        Observer.Finish();
    end;

    [Test]
    procedure JsonValue_ReadFromStream_FreshWithoutEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadValueInto(Observer, 'number', 0, '42', false);
        ReadValueInto(Observer, 'null', 0, 'null', false);
        ReadValueInto(Observer, 'string', 0, '"s"', false);
        Observer.Finish();
    end;

    [Test]
    procedure JsonValue_ReadFromStream_TwiceIntoSameValue()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Val: JsonValue;
        Text: Text;
    begin
        Fill(TempBlob, '5', 0);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('first', Format(Val.ReadFrom(InS)));
        Fill(TempBlob, '6', 0);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('second', Format(Val.ReadFrom(InS)));
        Val.WriteTo(Text);
        Observer.Observe('json', Text);
        Clear(Val);
        Fill(TempBlob, '7', 0);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('after_clear', Format(Val.ReadFrom(InS)));
        Val.WriteTo(Text);
        Observer.Observe('json_after_clear', Text);
        Observer.Finish();
    end;
}
