// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70856
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonValue.SetValue per value type (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70856 "LT P101 Value SetValue"
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
    procedure P101_SetValue_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Bo: Boolean;
        R: Text;
    begin
        Jv.SetValue(1);
        Bo := true;
        Jv.SetValue(Bo);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Bo := false;
        Jv.SetValue(Bo);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Observer.Expect('json0', 'true');
        Observer.Expect('text0', 'true');
        Observer.Expect('json1', 'false');
        Observer.Expect('text1', 'false');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Char()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Ch: Char;
        R: Text;
    begin
        Jv.SetValue(1);
        Ch := 65;
        Jv.SetValue(Ch);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Ch := 0;
        Jv.SetValue(Ch);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Ch := 8364;
        Jv.SetValue(Ch);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        Observer.Expect('json0', '65');
        Observer.Expect('text0', '65');
        Observer.Expect('json1', '0');
        Observer.Expect('text1', '0');
        Observer.Expect('json2', '8364');
        Observer.Expect('text2', '8364');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Byte()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        By: Byte;
        R: Text;
    begin
        Jv.SetValue(1);
        By := 0;
        Jv.SetValue(By);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        By := 255;
        Jv.SetValue(By);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        By := 7;
        Jv.SetValue(By);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        Observer.Expect('json0', '0');
        Observer.Expect('text0', '0');
        Observer.Expect('json1', '255');
        Observer.Expect('text1', '255');
        Observer.Expect('json2', '7');
        Observer.Expect('text2', '7');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Integer()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Ig: Integer;
        R: Text;
    begin
        Jv.SetValue(1);
        Ig := 0;
        Jv.SetValue(Ig);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Ig := -1;
        Jv.SetValue(Ig);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Ig := 2147483647;
        Jv.SetValue(Ig);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        Ig := -2147483647;
        Jv.SetValue(Ig);
        Jv.WriteTo(R);
        Observer.Observe('json3', R);
        Observer.Observe('text3', Jv.AsText());
        Observer.Expect('json0', '0');
        Observer.Expect('text0', '0');
        Observer.Expect('json1', '-1');
        Observer.Expect('text1', '-1');
        Observer.Expect('json2', '2147483647');
        Observer.Expect('text2', '2147483647');
        Observer.Expect('json3', '-2147483647');
        Observer.Expect('text3', '-2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Bi: BigInteger;
        R: Text;
    begin
        Jv.SetValue(1);
        Bi := 0;
        Jv.SetValue(Bi);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Bi := 2147483647;
        Jv.SetValue(Bi);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Bi := Bi * 4 + 3;
        Jv.SetValue(Bi);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        Bi := -Bi;
        Jv.SetValue(Bi);
        Jv.WriteTo(R);
        Observer.Observe('json3', R);
        Observer.Observe('text3', Jv.AsText());
        Observer.Expect('json0', '0');
        Observer.Expect('text0', '0');
        Observer.Expect('json1', '2147483647');
        Observer.Expect('text1', '2147483647');
        Observer.Expect('json2', '8589934591');
        Observer.Expect('text2', '8589934591');
        Observer.Expect('json3', '-8589934591');
        Observer.Expect('text3', '-8589934591');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        De: Decimal;
        R: Text;
    begin
        Jv.SetValue(1);
        De := 0;
        Jv.SetValue(De);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        De := 0.1;
        Jv.SetValue(De);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        De := -1.5;
        Jv.SetValue(De);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        De := 123456789.123456;
        Jv.SetValue(De);
        Jv.WriteTo(R);
        Observer.Observe('json3', R);
        Observer.Observe('text3', Jv.AsText());
        Observer.Expect('json0', '0.0');
        Observer.Expect('text0', '0');
        Observer.Expect('json1', '0.1');
        Observer.Expect('text1', '0.1');
        Observer.Expect('json2', '-1.5');
        Observer.Expect('text2', '-1.5');
        Observer.Expect('json3', '123456789.123456');
        Observer.Expect('text3', '123456789.123456');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Option()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Op: Option A,B,C;
        R: Text;
    begin
        Jv.SetValue(1);
        Op := 0;
        Jv.SetValue(Op);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Op := 2;
        Jv.SetValue(Op);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Observer.Expect('json0', '0');
        Observer.Expect('text0', '0');
        Observer.Expect('json1', '2');
        Observer.Expect('text1', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Date()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Da: Date;
        R: Text;
    begin
        Jv.SetValue(1);
        Da := 20240229D;
        Jv.SetValue(Da);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Da := 0D;
        Jv.SetValue(Da);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Da := 99991231D;
        Jv.SetValue(Da);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        Observer.Expect('json0', '"2024-02-29"');
        Observer.Expect('text0', '2024-02-29');
        Observer.Expect('json1', '"0001-01-01"');
        Observer.Expect('text1', '0001-01-01');
        Observer.Expect('json2', '"9999-12-31"');
        Observer.Expect('text2', '9999-12-31');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Time()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Ti: Time;
        R: Text;
    begin
        Jv.SetValue(1);
        Ti := 123456T;
        Jv.SetValue(Ti);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Ti := 0T;
        Jv.SetValue(Ti);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Ti := 235959T;
        Jv.SetValue(Ti);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        Observer.Expect('json0', '"12:34:56"');
        Observer.Expect('text0', '12:34:56');
        Observer.Expect('json1', '"00:00:00"');
        Observer.Expect('text1', '00:00:00');
        Observer.Expect('json2', '"23:59:59"');
        Observer.Expect('text2', '23:59:59');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Dt: DateTime;
        R: Text;
    begin
        Jv.SetValue(1);
        Dt := CreateDateTime(20240229D, 123456T);
        Jv.SetValue(Dt);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Dt := 0DT;
        Jv.SetValue(Dt);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Observer.Expect('json0', '"2024-02-29T12:34:56.0000000Z"');
        Observer.Expect('text0', '2024-02-29T12:34:56.0000000Z');
        Observer.Expect('json1', '"0001-01-01T00:00:00.0000000"');
        Observer.Expect('text1', '0001-01-01T00:00:00.0000000');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Duration()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Du: Duration;
        R: Text;
    begin
        Jv.SetValue(1);
        Du := 1500;
        Jv.SetValue(Du);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Du := 0;
        Jv.SetValue(Du);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Du := -86400000;
        Jv.SetValue(Du);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        Observer.Expect('json0', '1500');
        Observer.Expect('text0', '1500');
        Observer.Expect('json1', '0');
        Observer.Expect('text1', '0');
        Observer.Expect('json2', '-86400000');
        Observer.Expect('text2', '-86400000');
        Observer.Verify();
    end;

    [Test]
    procedure P101_SetValue_Text()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Tx: Text;
        R: Text;
    begin
        Jv.SetValue(1);
        Tx := '';
        Jv.SetValue(Tx);
        Jv.WriteTo(R);
        Observer.Observe('json0', R);
        Observer.Observe('text0', Jv.AsText());
        Tx := 'a"b\c';
        Jv.SetValue(Tx);
        Jv.WriteTo(R);
        Observer.Observe('json1', R);
        Observer.Observe('text1', Jv.AsText());
        Tx := 'Café €';
        Jv.SetValue(Tx);
        Jv.WriteTo(R);
        Observer.Observe('json2', R);
        Observer.Observe('text2', Jv.AsText());
        Observer.Expect('json0', '""');
        Observer.Expect('text0', '');
        Observer.Expect('json1', '"a\"b\\c"');
        Observer.Expect('text1', 'a"b\c');
        Observer.Expect('json2', '"Café €"');
        Observer.Expect('text2', 'Café €');
        Observer.Verify();
    end;

}
