// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 90340
// Probe (outside issues 6172, 6175): (1) Evaluate(DateTime, RFC 1123 text such as an HTTP Last-Modified header, 0) and the same with format 9 and without format: return value, value, error text.
//   (2) Evaluate(JsonArray, text): which texts succeed (an array, an array of objects, an empty array, an object, a scalar, invalid JSON, empty text), the content after success, the error text.
//   Evaluate into DateTime from the usual forms is in types/lt-evaluate-format-lasterror-setview/P86Eval.al.
// BC versions: 27-29

codeunit 90340 "LT UF Evaluate Json Rfc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DateTime_Rfc1123()
    var
        Observer: Codeunit "Probe Observer";
        Stamp: DateTime;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Evaluate(Stamp, 'Fri, 05 Sep 2025 14:23:45 GMT', 0);
        Observer.Observe('format 0 result', Format(Ok));
        Observer.Observe('format 0 value', Format(Stamp, 0, 9));
        Observer.ObserveError('format 0');
        Clear(Stamp);
        ClearLastError();
        Ok := Evaluate(Stamp, 'Fri, 05 Sep 2025 14:23:45 GMT', 9);
        Observer.Observe('format 9 result', Format(Ok));
        Observer.Observe('format 9 value', Format(Stamp, 0, 9));
        Observer.ObserveError('format 9');
        Clear(Stamp);
        ClearLastError();
        Ok := Evaluate(Stamp, 'Fri, 05 Sep 2025 14:23:45 GMT');
        Observer.Observe('no format result', Format(Ok));
        Observer.Observe('no format value', Format(Stamp, 0, 9));
        Observer.ObserveError('no format');
        Clear(Stamp);
        ClearLastError();
        Ok := Evaluate(Stamp, 'Fri, 05 Sep 2025 14:23:45 +0000', 0);
        Observer.Observe('offset result', Format(Ok));
        Observer.Observe('offset value', Format(Stamp, 0, 9));
        Observer.ObserveError('offset');
        Clear(Stamp);
        ClearLastError();
        Ok := Evaluate(Stamp, '05 Sep 2025 14:23:45', 0);
        Observer.Observe('no weekday result', Format(Ok));
        Observer.Observe('no weekday value', Format(Stamp, 0, 9));
        Observer.ObserveError('no weekday');
        Clear(Stamp);
        ClearLastError();
        Ok := Evaluate(Stamp, 'Mon, 05 Sep 2025 14:23:45 GMT', 0);
        Observer.Observe('wrong weekday result', Format(Ok));
        Observer.Observe('wrong weekday value', Format(Stamp, 0, 9));
        Observer.ObserveError('wrong weekday');
        Observer.Expect('format 0 result', 'Yes');
        Observer.Expect('format 0 value', '2025-09-05T14:23:45Z');
        Observer.Expect('format 0|text', '');
        Observer.Expect('format 0|code', '');
        Observer.Expect('format 9 result', 'No');
        Observer.Expect('format 9 value', '');
        Observer.Expect('format 9|text', '');
        Observer.Expect('format 9|code', '');
        Observer.Expect('no format result', 'Yes');
        Observer.Expect('no format value', '2025-09-05T14:23:45Z');
        Observer.Expect('no format|text', '');
        Observer.Expect('no format|code', '');
        Observer.Expect('offset result', 'Yes');
        Observer.Expect('offset value', '2025-09-05T14:23:45Z');
        Observer.Expect('offset|text', '');
        Observer.Expect('offset|code', '');
        Observer.Expect('no weekday result', 'No');
        Observer.Expect('no weekday value', '');
        Observer.Expect('no weekday|text', 'The date is not valid.');
        Observer.Expect('no weekday|code', 'DateInvalid');
        Observer.Expect('wrong weekday result', 'No');
        Observer.Expect('wrong weekday value', '');
        Observer.Expect('wrong weekday|text', '');
        Observer.Expect('wrong weekday|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure JsonArray_Texts()
    var
        Observer: Codeunit "Probe Observer";
        Arr: JsonArray;
        Token: JsonToken;
        Texts: List of [Text];
        Item: Text;
        Index: Integer;
        Ok: Boolean;
        Out: Text;
    begin
        Texts.Add('[{"name":"a","value":"1"}]');
        Texts.Add('[1,2,3]');
        Texts.Add('[]');
        Texts.Add(' [ "x" ] ');
        Texts.Add('{"a":1}');
        Texts.Add('5');
        Texts.Add('"text"');
        Texts.Add('null');
        Texts.Add('[1,');
        Texts.Add('');
        Texts.Add('not json');
        foreach Item in Texts do begin
            Index += 1;
            ClearLastError();
            Clear(Arr);
            Arr.Add('previous');
            Ok := Evaluate(Arr, Item);
            Observer.Observe('text ' + Format(Index) + ' result', Format(Ok));
            Arr.WriteTo(Out);
            Observer.Observe('text ' + Format(Index) + ' content', Out);
            Observer.Observe('text ' + Format(Index) + ' count', Format(Arr.Count()));
            Observer.ObserveError('text ' + Format(Index));
        end;
        Observer.Expect('text 1 result', 'Yes');
        Observer.Expect('text 1 content', '[{"name":"a","value":"1"}]');
        Observer.Expect('text 1 count', '1');
        Observer.Expect('text 1|text', '');
        Observer.Expect('text 1|code', '');
        Observer.Expect('text 2 result', 'Yes');
        Observer.Expect('text 2 content', '[1,2,3]');
        Observer.Expect('text 2 count', '3');
        Observer.Expect('text 2|text', '');
        Observer.Expect('text 2|code', '');
        Observer.Expect('text 3 result', 'Yes');
        Observer.Expect('text 3 content', '[]');
        Observer.Expect('text 3 count', '0');
        Observer.Expect('text 3|text', '');
        Observer.Expect('text 3|code', '');
        Observer.Expect('text 4 result', 'Yes');
        Observer.Expect('text 4 content', '["x"]');
        Observer.Expect('text 4 count', '1');
        Observer.Expect('text 4|text', '');
        Observer.Expect('text 4|code', '');
        Observer.Expect('text 5 result', 'No');
        Observer.Expect('text 5 content', '["previous"]');
        Observer.Expect('text 5 count', '1');
        Observer.Expect('text 5|text', 'JSON tokens of type ''Object'' are not supported by this implementation.');
        Observer.Expect('text 5|code', 'InvalidJsonType');
        Observer.Expect('text 6 result', 'No');
        Observer.Expect('text 6 content', '["previous"]');
        Observer.Expect('text 6 count', '1');
        Observer.Expect('text 6|text', 'JSON tokens of type ''Integer'' are not supported by this implementation.');
        Observer.Expect('text 6|code', 'InvalidJsonType');
        Observer.Expect('text 7 result', 'No');
        Observer.Expect('text 7 content', '["previous"]');
        Observer.Expect('text 7 count', '1');
        Observer.Expect('text 7|text', 'JSON tokens of type ''String'' are not supported by this implementation.');
        Observer.Expect('text 7|code', 'InvalidJsonType');
        Observer.Expect('text 8 result', 'No');
        Observer.Expect('text 8 content', '["previous"]');
        Observer.Expect('text 8 count', '1');
        Observer.Expect('text 8|text', 'JSON tokens of type ''Null'' are not supported by this implementation.');
        Observer.Expect('text 8|code', 'InvalidJsonType');
        Observer.Expect('text 9 result', 'No');
        Observer.Expect('text 9 content', '["previous"]');
        Observer.Expect('text 9 count', '1');
        Observer.Expect('text 9|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('text 9|code', 'InvalidJsonData');
        Observer.Expect('text 10 result', 'No');
        Observer.Expect('text 10 content', '["previous"]');
        Observer.Expect('text 10 count', '1');
        Observer.Expect('text 10|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('text 10|code', 'InvalidJsonData');
        Observer.Expect('text 11 result', 'No');
        Observer.Expect('text 11 content', '["previous"]');
        Observer.Expect('text 11 count', '1');
        Observer.Expect('text 11|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('text 11|code', 'InvalidJsonData');
        Observer.Verify();
    end;

    [Test]
    procedure JsonArray_UsedAfterEvaluate()
    var
        Observer: Codeunit "Probe Observer";
        Arr: JsonArray;
        Obj: JsonObject;
        Token: JsonToken;
        Out: Text;
    begin
        Evaluate(Arr, '[{"name":"a","value":"1"}]');
        Obj.Add('parameters', Arr);
        Obj.WriteTo(Out);
        Observer.Observe('object', Out);
        Arr.Get(0, Token);
        Observer.Observe('first is object', Format(Token.IsObject()));
        Observer.Expect('object', '{"parameters":[{"name":"a","value":"1"}]}');
        Observer.Expect('first is object', 'Yes');
        Observer.Verify();
    end;
}
