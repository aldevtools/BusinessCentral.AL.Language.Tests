// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70855
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonObject.Replace per value type (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70855 "LT P101 Object Replace"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Txt(A: JsonArray): Text
    var
        R: Text;
    begin
        A.WriteTo(R);
        exit(R);
    end;

    local procedure OTxt(O: JsonObject): Text
    var
        R: Text;
    begin
        O.WriteTo(R);
        exit(R);
    end;

    local procedure Three(var A: JsonArray)
    begin
        Clear(A);
        A.Add(1);
        A.Add(2);
        A.Add(3);
    end;

    [Test]
    procedure P101_Replace_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Bo: Boolean;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Bo := true;
        O.Replace('k', Bo);
        Observer.Observe('rep0', OTxt(O));
        Bo := false;
        O.Replace('k', Bo);
        Observer.Observe('rep1', OTxt(O));
        Bo := true;
        asserterror O.Replace('missing', Bo);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Bo := true;
        O.Replace('o', Bo);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":true}');
        Observer.Expect('rep1', '{"o":"orig","k":false}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":false}');
        Observer.Expect('rep_o', '{"k":false,"o":true}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Char()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ch: Char;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Ch := 65;
        O.Replace('k', Ch);
        Observer.Observe('rep0', OTxt(O));
        Ch := 0;
        O.Replace('k', Ch);
        Observer.Observe('rep1', OTxt(O));
        Ch := 8364;
        O.Replace('k', Ch);
        Observer.Observe('rep2', OTxt(O));
        Ch := 65;
        asserterror O.Replace('missing', Ch);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Ch := 65;
        O.Replace('o', Ch);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":65}');
        Observer.Expect('rep1', '{"o":"orig","k":0}');
        Observer.Expect('rep2', '{"o":"orig","k":8364}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":8364}');
        Observer.Expect('rep_o', '{"k":8364,"o":65}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Byte()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        By: Byte;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        By := 0;
        O.Replace('k', By);
        Observer.Observe('rep0', OTxt(O));
        By := 255;
        O.Replace('k', By);
        Observer.Observe('rep1', OTxt(O));
        By := 7;
        O.Replace('k', By);
        Observer.Observe('rep2', OTxt(O));
        By := 0;
        asserterror O.Replace('missing', By);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        By := 0;
        O.Replace('o', By);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":0}');
        Observer.Expect('rep1', '{"o":"orig","k":255}');
        Observer.Expect('rep2', '{"o":"orig","k":7}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":7}');
        Observer.Expect('rep_o', '{"k":7,"o":0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Integer()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ig: Integer;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Ig := 0;
        O.Replace('k', Ig);
        Observer.Observe('rep0', OTxt(O));
        Ig := -1;
        O.Replace('k', Ig);
        Observer.Observe('rep1', OTxt(O));
        Ig := 2147483647;
        O.Replace('k', Ig);
        Observer.Observe('rep2', OTxt(O));
        Ig := -2147483647;
        O.Replace('k', Ig);
        Observer.Observe('rep3', OTxt(O));
        Ig := 0;
        asserterror O.Replace('missing', Ig);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Ig := 0;
        O.Replace('o', Ig);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":0}');
        Observer.Expect('rep1', '{"o":"orig","k":-1}');
        Observer.Expect('rep2', '{"o":"orig","k":2147483647}');
        Observer.Expect('rep3', '{"o":"orig","k":-2147483647}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":-2147483647}');
        Observer.Expect('rep_o', '{"k":-2147483647,"o":0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Bi: BigInteger;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Bi := 0;
        O.Replace('k', Bi);
        Observer.Observe('rep0', OTxt(O));
        Bi := 2147483647;
        O.Replace('k', Bi);
        Observer.Observe('rep1', OTxt(O));
        Bi := Bi * 4 + 3;
        O.Replace('k', Bi);
        Observer.Observe('rep2', OTxt(O));
        Bi := -Bi;
        O.Replace('k', Bi);
        Observer.Observe('rep3', OTxt(O));
        Bi := 0;
        asserterror O.Replace('missing', Bi);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Bi := 0;
        O.Replace('o', Bi);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":0}');
        Observer.Expect('rep1', '{"o":"orig","k":2147483647}');
        Observer.Expect('rep2', '{"o":"orig","k":8589934591}');
        Observer.Expect('rep3', '{"o":"orig","k":-8589934591}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":-8589934591}');
        Observer.Expect('rep_o', '{"k":-8589934591,"o":0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        De: Decimal;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        De := 0;
        O.Replace('k', De);
        Observer.Observe('rep0', OTxt(O));
        De := 0.1;
        O.Replace('k', De);
        Observer.Observe('rep1', OTxt(O));
        De := -1.5;
        O.Replace('k', De);
        Observer.Observe('rep2', OTxt(O));
        De := 123456789.123456;
        O.Replace('k', De);
        Observer.Observe('rep3', OTxt(O));
        De := 0;
        asserterror O.Replace('missing', De);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        De := 0;
        O.Replace('o', De);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":0.0}');
        Observer.Expect('rep1', '{"o":"orig","k":0.1}');
        Observer.Expect('rep2', '{"o":"orig","k":-1.5}');
        Observer.Expect('rep3', '{"o":"orig","k":123456789.123456}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":123456789.123456}');
        Observer.Expect('rep_o', '{"k":123456789.123456,"o":0.0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Option()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Op: Option A,B,C;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Op := 0;
        O.Replace('k', Op);
        Observer.Observe('rep0', OTxt(O));
        Op := 2;
        O.Replace('k', Op);
        Observer.Observe('rep1', OTxt(O));
        Op := 0;
        asserterror O.Replace('missing', Op);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Op := 0;
        O.Replace('o', Op);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":0}');
        Observer.Expect('rep1', '{"o":"orig","k":2}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":2}');
        Observer.Expect('rep_o', '{"k":2,"o":0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Date()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Da: Date;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Da := 20240229D;
        O.Replace('k', Da);
        Observer.Observe('rep0', OTxt(O));
        Da := 0D;
        O.Replace('k', Da);
        Observer.Observe('rep1', OTxt(O));
        Da := 99991231D;
        O.Replace('k', Da);
        Observer.Observe('rep2', OTxt(O));
        Da := 20240229D;
        asserterror O.Replace('missing', Da);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Da := 20240229D;
        O.Replace('o', Da);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":"2024-02-29"}');
        Observer.Expect('rep1', '{"o":"orig","k":"0001-01-01"}');
        Observer.Expect('rep2', '{"o":"orig","k":"9999-12-31"}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":"9999-12-31"}');
        Observer.Expect('rep_o', '{"k":"9999-12-31","o":"2024-02-29"}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Time()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ti: Time;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Ti := 123456T;
        O.Replace('k', Ti);
        Observer.Observe('rep0', OTxt(O));
        Ti := 0T;
        O.Replace('k', Ti);
        Observer.Observe('rep1', OTxt(O));
        Ti := 235959T;
        O.Replace('k', Ti);
        Observer.Observe('rep2', OTxt(O));
        Ti := 123456T;
        asserterror O.Replace('missing', Ti);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Ti := 123456T;
        O.Replace('o', Ti);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":"12:34:56"}');
        Observer.Expect('rep1', '{"o":"orig","k":"00:00:00"}');
        Observer.Expect('rep2', '{"o":"orig","k":"23:59:59"}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":"23:59:59"}');
        Observer.Expect('rep_o', '{"k":"23:59:59","o":"12:34:56"}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Dt: DateTime;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Dt := CreateDateTime(20240229D, 123456T);
        O.Replace('k', Dt);
        Observer.Observe('rep0', OTxt(O));
        Dt := 0DT;
        O.Replace('k', Dt);
        Observer.Observe('rep1', OTxt(O));
        Dt := CreateDateTime(20240229D, 123456T);
        asserterror O.Replace('missing', Dt);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Dt := CreateDateTime(20240229D, 123456T);
        O.Replace('o', Dt);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":"2024-02-29T12:34:56.0000000Z"}');
        Observer.Expect('rep1', '{"o":"orig","k":"0001-01-01T00:00:00.0000000"}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":"0001-01-01T00:00:00.0000000"}');
        Observer.Expect('rep_o', '{"k":"0001-01-01T00:00:00.0000000","o":"2024-02-29T12:34:56.0000000Z"}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Duration()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Du: Duration;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Du := 1500;
        O.Replace('k', Du);
        Observer.Observe('rep0', OTxt(O));
        Du := 0;
        O.Replace('k', Du);
        Observer.Observe('rep1', OTxt(O));
        Du := -86400000;
        O.Replace('k', Du);
        Observer.Observe('rep2', OTxt(O));
        Du := 1500;
        asserterror O.Replace('missing', Du);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Du := 1500;
        O.Replace('o', Du);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":1500}');
        Observer.Expect('rep1', '{"o":"orig","k":0}');
        Observer.Expect('rep2', '{"o":"orig","k":-86400000}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":-86400000}');
        Observer.Expect('rep_o', '{"k":-86400000,"o":1500}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_Text()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Tx: Text;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Tx := '';
        O.Replace('k', Tx);
        Observer.Observe('rep0', OTxt(O));
        Tx := 'a"b\c';
        O.Replace('k', Tx);
        Observer.Observe('rep1', OTxt(O));
        Tx := 'Café €';
        O.Replace('k', Tx);
        Observer.Observe('rep2', OTxt(O));
        Tx := '';
        asserterror O.Replace('missing', Tx);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Tx := '';
        O.Replace('o', Tx);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":""}');
        Observer.Expect('rep1', '{"o":"orig","k":"a\"b\\c"}');
        Observer.Expect('rep2', '{"o":"orig","k":"Café €"}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":"Café €"}');
        Observer.Expect('rep_o', '{"k":"Café €","o":""}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_JsonToken()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Tk: JsonToken;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Tk.ReadFrom('5');
        O.Replace('k', Tk);
        Observer.Observe('rep0', OTxt(O));
        Tk.ReadFrom('{"x":1}');
        O.Replace('k', Tk);
        Observer.Observe('rep1', OTxt(O));
        Tk.ReadFrom('null');
        O.Replace('k', Tk);
        Observer.Observe('rep2', OTxt(O));
        Tk.ReadFrom('5');
        asserterror O.Replace('missing', Tk);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Tk.ReadFrom('5');
        O.Replace('o', Tk);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":5}');
        Observer.Expect('rep1', '{"o":"orig","k":{"x":1}}');
        Observer.Expect('rep2', '{"o":"orig","k":null}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":null}');
        Observer.Expect('rep_o', '{"k":null,"o":5}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_JsonArray()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ja: JsonArray;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Ja.ReadFrom('[1,2]');
        O.Replace('k', Ja);
        Observer.Observe('rep0', OTxt(O));
        Clear(Ja);
        O.Replace('k', Ja);
        Observer.Observe('rep1', OTxt(O));
        Ja.ReadFrom('[1,2]');
        asserterror O.Replace('missing', Ja);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Ja.ReadFrom('[1,2]');
        O.Replace('o', Ja);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":[1,2]}');
        Observer.Expect('rep1', '{"o":"orig","k":[]}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":[]}');
        Observer.Expect('rep_o', '{"k":[],"o":[1,2]}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_JsonObject()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Jo: JsonObject;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Jo.ReadFrom('{"x":1}');
        O.Replace('k', Jo);
        Observer.Observe('rep0', OTxt(O));
        Clear(Jo);
        O.Replace('k', Jo);
        Observer.Observe('rep1', OTxt(O));
        Jo.ReadFrom('{"x":1}');
        asserterror O.Replace('missing', Jo);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Jo.ReadFrom('{"x":1}');
        O.Replace('o', Jo);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":{"x":1}}');
        Observer.Expect('rep1', '{"o":"orig","k":{}}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":{}}');
        Observer.Expect('rep_o', '{"k":{},"o":{"x":1}}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Replace_JsonValue()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Jv: JsonValue;
    begin
        O.Add('k', 1);
        O.Add('o', 'orig');
        Jv.SetValue(7);
        O.Replace('k', Jv);
        Observer.Observe('rep0', OTxt(O));
        Jv.SetValue('s');
        O.Replace('k', Jv);
        Observer.Observe('rep1', OTxt(O));
        Jv.SetValue(7);
        asserterror O.Replace('missing', Jv);
        Observer.ObserveError('rep_missing');
        Observer.Observe('after_missing', OTxt(O));
        Jv.SetValue(7);
        O.Replace('o', Jv);
        Observer.Observe('rep_o', OTxt(O));
        Observer.Expect('rep0', '{"o":"orig","k":7}');
        Observer.Expect('rep1', '{"o":"orig","k":"s"}');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after_missing', '{"o":"orig","k":"s"}');
        Observer.Expect('rep_o', '{"k":"s","o":7}');
        Observer.Verify();
    end;

}
