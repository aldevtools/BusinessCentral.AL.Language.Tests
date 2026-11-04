// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70854
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonObject.Add per value type (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70854 "LT P101 Object Add"
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
    procedure P101_Add_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Bo: Boolean;
    begin
        Bo := true;
        O.Add('k0', Bo);
        Observer.Observe('add0', OTxt(O));
        Bo := false;
        O.Add('k1', Bo);
        Observer.Observe('add1', OTxt(O));
        Bo := true;
        asserterror O.Add('k0', Bo);
        Observer.ObserveError('add_dup');
        O.Add('', Bo);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":true}');
        Observer.Expect('add1', '{"k0":true,"k1":false}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":true,"k1":false,"":true}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Char()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ch: Char;
    begin
        Ch := 65;
        O.Add('k0', Ch);
        Observer.Observe('add0', OTxt(O));
        Ch := 0;
        O.Add('k1', Ch);
        Observer.Observe('add1', OTxt(O));
        Ch := 8364;
        O.Add('k2', Ch);
        Observer.Observe('add2', OTxt(O));
        Ch := 65;
        asserterror O.Add('k0', Ch);
        Observer.ObserveError('add_dup');
        O.Add('', Ch);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":65}');
        Observer.Expect('add1', '{"k0":65,"k1":0}');
        Observer.Expect('add2', '{"k0":65,"k1":0,"k2":8364}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":65,"k1":0,"k2":8364,"":65}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Byte()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        By: Byte;
    begin
        By := 0;
        O.Add('k0', By);
        Observer.Observe('add0', OTxt(O));
        By := 255;
        O.Add('k1', By);
        Observer.Observe('add1', OTxt(O));
        By := 7;
        O.Add('k2', By);
        Observer.Observe('add2', OTxt(O));
        By := 0;
        asserterror O.Add('k0', By);
        Observer.ObserveError('add_dup');
        O.Add('', By);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":0}');
        Observer.Expect('add1', '{"k0":0,"k1":255}');
        Observer.Expect('add2', '{"k0":0,"k1":255,"k2":7}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":0,"k1":255,"k2":7,"":0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Integer()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ig: Integer;
    begin
        Ig := 0;
        O.Add('k0', Ig);
        Observer.Observe('add0', OTxt(O));
        Ig := -1;
        O.Add('k1', Ig);
        Observer.Observe('add1', OTxt(O));
        Ig := 2147483647;
        O.Add('k2', Ig);
        Observer.Observe('add2', OTxt(O));
        Ig := -2147483647;
        O.Add('k3', Ig);
        Observer.Observe('add3', OTxt(O));
        Ig := 0;
        asserterror O.Add('k0', Ig);
        Observer.ObserveError('add_dup');
        O.Add('', Ig);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":0}');
        Observer.Expect('add1', '{"k0":0,"k1":-1}');
        Observer.Expect('add2', '{"k0":0,"k1":-1,"k2":2147483647}');
        Observer.Expect('add3', '{"k0":0,"k1":-1,"k2":2147483647,"k3":-2147483647}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":0,"k1":-1,"k2":2147483647,"k3":-2147483647,"":0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Bi: BigInteger;
    begin
        Bi := 0;
        O.Add('k0', Bi);
        Observer.Observe('add0', OTxt(O));
        Bi := 2147483647;
        O.Add('k1', Bi);
        Observer.Observe('add1', OTxt(O));
        Bi := Bi * 4 + 3;
        O.Add('k2', Bi);
        Observer.Observe('add2', OTxt(O));
        Bi := -Bi;
        O.Add('k3', Bi);
        Observer.Observe('add3', OTxt(O));
        Bi := 0;
        asserterror O.Add('k0', Bi);
        Observer.ObserveError('add_dup');
        O.Add('', Bi);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":0}');
        Observer.Expect('add1', '{"k0":0,"k1":2147483647}');
        Observer.Expect('add2', '{"k0":0,"k1":2147483647,"k2":8589934591}');
        Observer.Expect('add3', '{"k0":0,"k1":2147483647,"k2":8589934591,"k3":-8589934591}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":0,"k1":2147483647,"k2":8589934591,"k3":-8589934591,"":0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        De: Decimal;
    begin
        De := 0;
        O.Add('k0', De);
        Observer.Observe('add0', OTxt(O));
        De := 0.1;
        O.Add('k1', De);
        Observer.Observe('add1', OTxt(O));
        De := -1.5;
        O.Add('k2', De);
        Observer.Observe('add2', OTxt(O));
        De := 123456789.123456;
        O.Add('k3', De);
        Observer.Observe('add3', OTxt(O));
        De := 0;
        asserterror O.Add('k0', De);
        Observer.ObserveError('add_dup');
        O.Add('', De);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":0.0}');
        Observer.Expect('add1', '{"k0":0.0,"k1":0.1}');
        Observer.Expect('add2', '{"k0":0.0,"k1":0.1,"k2":-1.5}');
        Observer.Expect('add3', '{"k0":0.0,"k1":0.1,"k2":-1.5,"k3":123456789.123456}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":0.0,"k1":0.1,"k2":-1.5,"k3":123456789.123456,"":0.0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Option()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Op: Option A,B,C;
    begin
        Op := 0;
        O.Add('k0', Op);
        Observer.Observe('add0', OTxt(O));
        Op := 2;
        O.Add('k1', Op);
        Observer.Observe('add1', OTxt(O));
        Op := 0;
        asserterror O.Add('k0', Op);
        Observer.ObserveError('add_dup');
        O.Add('', Op);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":0}');
        Observer.Expect('add1', '{"k0":0,"k1":2}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":0,"k1":2,"":0}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Date()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Da: Date;
    begin
        Da := 20240229D;
        O.Add('k0', Da);
        Observer.Observe('add0', OTxt(O));
        Da := 0D;
        O.Add('k1', Da);
        Observer.Observe('add1', OTxt(O));
        Da := 99991231D;
        O.Add('k2', Da);
        Observer.Observe('add2', OTxt(O));
        Da := 20240229D;
        asserterror O.Add('k0', Da);
        Observer.ObserveError('add_dup');
        O.Add('', Da);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":"2024-02-29"}');
        Observer.Expect('add1', '{"k0":"2024-02-29","k1":"0001-01-01"}');
        Observer.Expect('add2', '{"k0":"2024-02-29","k1":"0001-01-01","k2":"9999-12-31"}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":"2024-02-29","k1":"0001-01-01","k2":"9999-12-31","":"2024-02-29"}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Time()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ti: Time;
    begin
        Ti := 123456T;
        O.Add('k0', Ti);
        Observer.Observe('add0', OTxt(O));
        Ti := 0T;
        O.Add('k1', Ti);
        Observer.Observe('add1', OTxt(O));
        Ti := 235959T;
        O.Add('k2', Ti);
        Observer.Observe('add2', OTxt(O));
        Ti := 123456T;
        asserterror O.Add('k0', Ti);
        Observer.ObserveError('add_dup');
        O.Add('', Ti);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":"12:34:56"}');
        Observer.Expect('add1', '{"k0":"12:34:56","k1":"00:00:00"}');
        Observer.Expect('add2', '{"k0":"12:34:56","k1":"00:00:00","k2":"23:59:59"}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":"12:34:56","k1":"00:00:00","k2":"23:59:59","":"12:34:56"}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Dt: DateTime;
    begin
        Dt := CreateDateTime(20240229D, 123456T);
        O.Add('k0', Dt);
        Observer.Observe('add0', OTxt(O));
        Dt := 0DT;
        O.Add('k1', Dt);
        Observer.Observe('add1', OTxt(O));
        Dt := CreateDateTime(20240229D, 123456T);
        asserterror O.Add('k0', Dt);
        Observer.ObserveError('add_dup');
        O.Add('', Dt);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":"2024-02-29T12:34:56.0000000Z"}');
        Observer.Expect('add1', '{"k0":"2024-02-29T12:34:56.0000000Z","k1":"0001-01-01T00:00:00.0000000"}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":"2024-02-29T12:34:56.0000000Z","k1":"0001-01-01T00:00:00.0000000","":"2024-02-29T12:34:56.0000000Z"}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Duration()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Du: Duration;
    begin
        Du := 1500;
        O.Add('k0', Du);
        Observer.Observe('add0', OTxt(O));
        Du := 0;
        O.Add('k1', Du);
        Observer.Observe('add1', OTxt(O));
        Du := -86400000;
        O.Add('k2', Du);
        Observer.Observe('add2', OTxt(O));
        Du := 1500;
        asserterror O.Add('k0', Du);
        Observer.ObserveError('add_dup');
        O.Add('', Du);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":1500}');
        Observer.Expect('add1', '{"k0":1500,"k1":0}');
        Observer.Expect('add2', '{"k0":1500,"k1":0,"k2":-86400000}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":1500,"k1":0,"k2":-86400000,"":1500}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Text()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Tx: Text;
    begin
        Tx := '';
        O.Add('k0', Tx);
        Observer.Observe('add0', OTxt(O));
        Tx := 'a"b\c';
        O.Add('k1', Tx);
        Observer.Observe('add1', OTxt(O));
        Tx := 'Café €';
        O.Add('k2', Tx);
        Observer.Observe('add2', OTxt(O));
        Tx := '';
        asserterror O.Add('k0', Tx);
        Observer.ObserveError('add_dup');
        O.Add('', Tx);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":""}');
        Observer.Expect('add1', '{"k0":"","k1":"a\"b\\c"}');
        Observer.Expect('add2', '{"k0":"","k1":"a\"b\\c","k2":"Café €"}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":"","k1":"a\"b\\c","k2":"Café €","":""}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_JsonToken()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Tk: JsonToken;
    begin
        Tk.ReadFrom('5');
        O.Add('k0', Tk);
        Observer.Observe('add0', OTxt(O));
        Tk.ReadFrom('{"x":1}');
        O.Add('k1', Tk);
        Observer.Observe('add1', OTxt(O));
        Tk.ReadFrom('null');
        O.Add('k2', Tk);
        Observer.Observe('add2', OTxt(O));
        Tk.ReadFrom('5');
        asserterror O.Add('k0', Tk);
        Observer.ObserveError('add_dup');
        O.Add('', Tk);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":5}');
        Observer.Expect('add1', '{"k0":5,"k1":{"x":1}}');
        Observer.Expect('add2', '{"k0":5,"k1":{"x":1},"k2":null}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":5,"k1":{"x":1},"k2":null,"":5}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_JsonArray()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ja: JsonArray;
    begin
        Ja.ReadFrom('[1,2]');
        O.Add('k0', Ja);
        Observer.Observe('add0', OTxt(O));
        Clear(Ja);
        O.Add('k1', Ja);
        Observer.Observe('add1', OTxt(O));
        Ja.ReadFrom('[1,2]');
        asserterror O.Add('k0', Ja);
        Observer.ObserveError('add_dup');
        O.Add('', Ja);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":[1,2]}');
        Observer.Expect('add1', '{"k0":[1,2],"k1":[]}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":[1,2],"k1":[],"":[1,2]}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_JsonObject()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Jo: JsonObject;
    begin
        Jo.ReadFrom('{"x":1}');
        O.Add('k0', Jo);
        Observer.Observe('add0', OTxt(O));
        Clear(Jo);
        O.Add('k1', Jo);
        Observer.Observe('add1', OTxt(O));
        Jo.ReadFrom('{"x":1}');
        asserterror O.Add('k0', Jo);
        Observer.ObserveError('add_dup');
        O.Add('', Jo);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":{"x":1}}');
        Observer.Expect('add1', '{"k0":{"x":1},"k1":{}}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":{"x":1},"k1":{},"":{"x":1}}');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_JsonValue()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Jv: JsonValue;
    begin
        Jv.SetValue(7);
        O.Add('k0', Jv);
        Observer.Observe('add0', OTxt(O));
        Jv.SetValue('s');
        O.Add('k1', Jv);
        Observer.Observe('add1', OTxt(O));
        Jv.SetValue(7);
        asserterror O.Add('k0', Jv);
        Observer.ObserveError('add_dup');
        O.Add('', Jv);
        Observer.Observe('add_emptykey', OTxt(O));
        Observer.Expect('add0', '{"k0":7}');
        Observer.Expect('add1', '{"k0":7,"k1":"s"}');
        Observer.Expect('add_dup|text', 'The JSON object already contains the key ''k0''.');
        Observer.Expect('add_dup|code', 'DuplicateJsonProperty');
        Observer.Expect('add_emptykey', '{"k0":7,"k1":"s","":7}');
        Observer.Verify();
    end;

}
