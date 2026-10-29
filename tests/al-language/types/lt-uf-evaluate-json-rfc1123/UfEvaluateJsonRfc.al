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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
