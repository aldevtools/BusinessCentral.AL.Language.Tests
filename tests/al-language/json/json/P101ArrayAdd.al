// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70850
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonArray.Add per value type (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70850 "LT P101 Array Add"
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
        A: JsonArray;
        Bo: Boolean;
    begin
        Bo := true;
        A.Add(Bo);
        Observer.Observe('add0', Txt(A));
        Bo := false;
        A.Add(Bo);
        Observer.Observe('add1', Txt(A));
        Observer.Expect('add0', '[true]');
        Observer.Expect('add1', '[true,false]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Char()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ch: Char;
    begin
        Ch := 65;
        A.Add(Ch);
        Observer.Observe('add0', Txt(A));
        Ch := 0;
        A.Add(Ch);
        Observer.Observe('add1', Txt(A));
        Ch := 8364;
        A.Add(Ch);
        Observer.Observe('add2', Txt(A));
        Observer.Expect('add0', '[65]');
        Observer.Expect('add1', '[65,0]');
        Observer.Expect('add2', '[65,0,8364]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Byte()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        By: Byte;
    begin
        By := 0;
        A.Add(By);
        Observer.Observe('add0', Txt(A));
        By := 255;
        A.Add(By);
        Observer.Observe('add1', Txt(A));
        By := 7;
        A.Add(By);
        Observer.Observe('add2', Txt(A));
        Observer.Expect('add0', '[0]');
        Observer.Expect('add1', '[0,255]');
        Observer.Expect('add2', '[0,255,7]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Integer()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ig: Integer;
    begin
        Ig := 0;
        A.Add(Ig);
        Observer.Observe('add0', Txt(A));
        Ig := -1;
        A.Add(Ig);
        Observer.Observe('add1', Txt(A));
        Ig := 2147483647;
        A.Add(Ig);
        Observer.Observe('add2', Txt(A));
        Ig := -2147483647;
        A.Add(Ig);
        Observer.Observe('add3', Txt(A));
        Observer.Expect('add0', '[0]');
        Observer.Expect('add1', '[0,-1]');
        Observer.Expect('add2', '[0,-1,2147483647]');
        Observer.Expect('add3', '[0,-1,2147483647,-2147483647]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Bi: BigInteger;
    begin
        Bi := 0;
        A.Add(Bi);
        Observer.Observe('add0', Txt(A));
        Bi := 2147483647;
        A.Add(Bi);
        Observer.Observe('add1', Txt(A));
        Bi := Bi * 4 + 3;
        A.Add(Bi);
        Observer.Observe('add2', Txt(A));
        Bi := -Bi;
        A.Add(Bi);
        Observer.Observe('add3', Txt(A));
        Observer.Expect('add0', '[0]');
        Observer.Expect('add1', '[0,2147483647]');
        Observer.Expect('add2', '[0,2147483647,8589934591]');
        Observer.Expect('add3', '[0,2147483647,8589934591,-8589934591]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        De: Decimal;
    begin
        De := 0;
        A.Add(De);
        Observer.Observe('add0', Txt(A));
        De := 0.1;
        A.Add(De);
        Observer.Observe('add1', Txt(A));
        De := -1.5;
        A.Add(De);
        Observer.Observe('add2', Txt(A));
        De := 123456789.123456;
        A.Add(De);
        Observer.Observe('add3', Txt(A));
        Observer.Expect('add0', '[0.0]');
        Observer.Expect('add1', '[0.0,0.1]');
        Observer.Expect('add2', '[0.0,0.1,-1.5]');
        Observer.Expect('add3', '[0.0,0.1,-1.5,123456789.123456]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Option()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Op: Option A,B,C;
    begin
        Op := 0;
        A.Add(Op);
        Observer.Observe('add0', Txt(A));
        Op := 2;
        A.Add(Op);
        Observer.Observe('add1', Txt(A));
        Observer.Expect('add0', '[0]');
        Observer.Expect('add1', '[0,2]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Date()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Da: Date;
    begin
        Da := 20240229D;
        A.Add(Da);
        Observer.Observe('add0', Txt(A));
        Da := 0D;
        A.Add(Da);
        Observer.Observe('add1', Txt(A));
        Da := 99991231D;
        A.Add(Da);
        Observer.Observe('add2', Txt(A));
        Observer.Expect('add0', '["2024-02-29"]');
        Observer.Expect('add1', '["2024-02-29","0001-01-01"]');
        Observer.Expect('add2', '["2024-02-29","0001-01-01","9999-12-31"]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Time()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ti: Time;
    begin
        Ti := 123456T;
        A.Add(Ti);
        Observer.Observe('add0', Txt(A));
        Ti := 0T;
        A.Add(Ti);
        Observer.Observe('add1', Txt(A));
        Ti := 235959T;
        A.Add(Ti);
        Observer.Observe('add2', Txt(A));
        Observer.Expect('add0', '["12:34:56"]');
        Observer.Expect('add1', '["12:34:56","00:00:00"]');
        Observer.Expect('add2', '["12:34:56","00:00:00","23:59:59"]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Dt: DateTime;
    begin
        Dt := CreateDateTime(20240229D, 123456T);
        A.Add(Dt);
        Observer.Observe('add0', Txt(A));
        Dt := 0DT;
        A.Add(Dt);
        Observer.Observe('add1', Txt(A));
        Observer.Expect('add0', '["2024-02-29T12:34:56.0000000Z"]');
        Observer.Expect('add1', '["2024-02-29T12:34:56.0000000Z","0001-01-01T00:00:00.0000000"]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Duration()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Du: Duration;
    begin
        Du := 1500;
        A.Add(Du);
        Observer.Observe('add0', Txt(A));
        Du := 0;
        A.Add(Du);
        Observer.Observe('add1', Txt(A));
        Du := -86400000;
        A.Add(Du);
        Observer.Observe('add2', Txt(A));
        Observer.Expect('add0', '[1500]');
        Observer.Expect('add1', '[1500,0]');
        Observer.Expect('add2', '[1500,0,-86400000]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_Text()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tx: Text;
    begin
        Tx := '';
        A.Add(Tx);
        Observer.Observe('add0', Txt(A));
        Tx := 'a"b\c';
        A.Add(Tx);
        Observer.Observe('add1', Txt(A));
        Tx := 'Café €';
        A.Add(Tx);
        Observer.Observe('add2', Txt(A));
        Observer.Expect('add0', '[""]');
        Observer.Expect('add1', '["","a\"b\\c"]');
        Observer.Expect('add2', '["","a\"b\\c","Café €"]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_JsonToken()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tk: JsonToken;
    begin
        Tk.ReadFrom('5');
        A.Add(Tk);
        Observer.Observe('add0', Txt(A));
        Tk.ReadFrom('{"x":1}');
        A.Add(Tk);
        Observer.Observe('add1', Txt(A));
        Tk.ReadFrom('null');
        A.Add(Tk);
        Observer.Observe('add2', Txt(A));
        Observer.Expect('add0', '[5]');
        Observer.Expect('add1', '[5,{"x":1}]');
        Observer.Expect('add2', '[5,{"x":1},null]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_JsonArray()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ja: JsonArray;
    begin
        Ja.ReadFrom('[1,2]');
        A.Add(Ja);
        Observer.Observe('add0', Txt(A));
        Clear(Ja);
        A.Add(Ja);
        Observer.Observe('add1', Txt(A));
        Observer.Expect('add0', '[[1,2]]');
        Observer.Expect('add1', '[[1,2],[]]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_JsonObject()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jo: JsonObject;
    begin
        Jo.ReadFrom('{"x":1}');
        A.Add(Jo);
        Observer.Observe('add0', Txt(A));
        Clear(Jo);
        A.Add(Jo);
        Observer.Observe('add1', Txt(A));
        Observer.Expect('add0', '[{"x":1}]');
        Observer.Expect('add1', '[{"x":1},{}]');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Add_JsonValue()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jv: JsonValue;
    begin
        Jv.SetValue(7);
        A.Add(Jv);
        Observer.Observe('add0', Txt(A));
        Jv.SetValue('s');
        A.Add(Jv);
        Observer.Observe('add1', Txt(A));
        Observer.Expect('add0', '[7]');
        Observer.Expect('add1', '[7,"s"]');
        Observer.Verify();
    end;

}
