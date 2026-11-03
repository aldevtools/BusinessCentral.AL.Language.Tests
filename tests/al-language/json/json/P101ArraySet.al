// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70852
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonArray.Set per value type (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70852 "LT P101 Array Set"
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
    procedure P101_Set_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Bo: Boolean;
    begin
        Three(A);
        Bo := true;
        A.Set(0, Bo);
        Observer.Observe('set0', Txt(A));
        Bo := false;
        A.Set(1, Bo);
        Observer.Observe('set1', Txt(A));
        Bo := true;
        asserterror A.Set(A.Count(), Bo);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[true,2,3]');
        Observer.Expect('set1', '[true,false,3]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Char()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ch: Char;
    begin
        Three(A);
        Ch := 65;
        A.Set(0, Ch);
        Observer.Observe('set0', Txt(A));
        Ch := 0;
        A.Set(1, Ch);
        Observer.Observe('set1', Txt(A));
        Ch := 8364;
        A.Set(2, Ch);
        Observer.Observe('set2', Txt(A));
        Ch := 65;
        asserterror A.Set(A.Count(), Ch);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[65,2,3]');
        Observer.Expect('set1', '[65,0,3]');
        Observer.Expect('set2', '[65,0,8364]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Byte()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        By: Byte;
    begin
        Three(A);
        By := 0;
        A.Set(0, By);
        Observer.Observe('set0', Txt(A));
        By := 255;
        A.Set(1, By);
        Observer.Observe('set1', Txt(A));
        By := 7;
        A.Set(2, By);
        Observer.Observe('set2', Txt(A));
        By := 0;
        asserterror A.Set(A.Count(), By);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[0,2,3]');
        Observer.Expect('set1', '[0,255,3]');
        Observer.Expect('set2', '[0,255,7]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Integer()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ig: Integer;
    begin
        Three(A);
        Ig := 0;
        A.Set(0, Ig);
        Observer.Observe('set0', Txt(A));
        Ig := -1;
        A.Set(1, Ig);
        Observer.Observe('set1', Txt(A));
        Ig := 2147483647;
        A.Set(2, Ig);
        Observer.Observe('set2', Txt(A));
        Ig := -2147483647;
        A.Set(0, Ig);
        Observer.Observe('set3', Txt(A));
        Ig := 0;
        asserterror A.Set(A.Count(), Ig);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[0,2,3]');
        Observer.Expect('set1', '[0,-1,3]');
        Observer.Expect('set2', '[0,-1,2147483647]');
        Observer.Expect('set3', '[-2147483647,-1,2147483647]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Bi: BigInteger;
    begin
        Three(A);
        Bi := 0;
        A.Set(0, Bi);
        Observer.Observe('set0', Txt(A));
        Bi := 2147483647;
        A.Set(1, Bi);
        Observer.Observe('set1', Txt(A));
        Bi := Bi * 4 + 3;
        A.Set(2, Bi);
        Observer.Observe('set2', Txt(A));
        Bi := -Bi;
        A.Set(0, Bi);
        Observer.Observe('set3', Txt(A));
        Bi := 0;
        asserterror A.Set(A.Count(), Bi);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[0,2,3]');
        Observer.Expect('set1', '[0,2147483647,3]');
        Observer.Expect('set2', '[0,2147483647,8589934591]');
        Observer.Expect('set3', '[-8589934591,2147483647,8589934591]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        De: Decimal;
    begin
        Three(A);
        De := 0;
        A.Set(0, De);
        Observer.Observe('set0', Txt(A));
        De := 0.1;
        A.Set(1, De);
        Observer.Observe('set1', Txt(A));
        De := -1.5;
        A.Set(2, De);
        Observer.Observe('set2', Txt(A));
        De := 123456789.123456;
        A.Set(0, De);
        Observer.Observe('set3', Txt(A));
        De := 0;
        asserterror A.Set(A.Count(), De);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[0.0,2,3]');
        Observer.Expect('set1', '[0.0,0.1,3]');
        Observer.Expect('set2', '[0.0,0.1,-1.5]');
        Observer.Expect('set3', '[123456789.123456,0.1,-1.5]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Option()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Op: Option A,B,C;
    begin
        Three(A);
        Op := 0;
        A.Set(0, Op);
        Observer.Observe('set0', Txt(A));
        Op := 2;
        A.Set(1, Op);
        Observer.Observe('set1', Txt(A));
        Op := 0;
        asserterror A.Set(A.Count(), Op);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[0,2,3]');
        Observer.Expect('set1', '[0,2,3]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Date()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Da: Date;
    begin
        Three(A);
        Da := 20240229D;
        A.Set(0, Da);
        Observer.Observe('set0', Txt(A));
        Da := 0D;
        A.Set(1, Da);
        Observer.Observe('set1', Txt(A));
        Da := 99991231D;
        A.Set(2, Da);
        Observer.Observe('set2', Txt(A));
        Da := 20240229D;
        asserterror A.Set(A.Count(), Da);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '["2024-02-29",2,3]');
        Observer.Expect('set1', '["2024-02-29","0001-01-01",3]');
        Observer.Expect('set2', '["2024-02-29","0001-01-01","9999-12-31"]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Time()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ti: Time;
    begin
        Three(A);
        Ti := 123456T;
        A.Set(0, Ti);
        Observer.Observe('set0', Txt(A));
        Ti := 0T;
        A.Set(1, Ti);
        Observer.Observe('set1', Txt(A));
        Ti := 235959T;
        A.Set(2, Ti);
        Observer.Observe('set2', Txt(A));
        Ti := 123456T;
        asserterror A.Set(A.Count(), Ti);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '["12:34:56",2,3]');
        Observer.Expect('set1', '["12:34:56","00:00:00",3]');
        Observer.Expect('set2', '["12:34:56","00:00:00","23:59:59"]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Dt: DateTime;
    begin
        Three(A);
        Dt := CreateDateTime(20240229D, 123456T);
        A.Set(0, Dt);
        Observer.Observe('set0', Txt(A));
        Dt := 0DT;
        A.Set(1, Dt);
        Observer.Observe('set1', Txt(A));
        Dt := CreateDateTime(20240229D, 123456T);
        asserterror A.Set(A.Count(), Dt);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '["2024-02-29T12:34:56.0000000Z",2,3]');
        Observer.Expect('set1', '["2024-02-29T12:34:56.0000000Z","0001-01-01T00:00:00.0000000",3]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Duration()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Du: Duration;
    begin
        Three(A);
        Du := 1500;
        A.Set(0, Du);
        Observer.Observe('set0', Txt(A));
        Du := 0;
        A.Set(1, Du);
        Observer.Observe('set1', Txt(A));
        Du := -86400000;
        A.Set(2, Du);
        Observer.Observe('set2', Txt(A));
        Du := 1500;
        asserterror A.Set(A.Count(), Du);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[1500,2,3]');
        Observer.Expect('set1', '[1500,0,3]');
        Observer.Expect('set2', '[1500,0,-86400000]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_Text()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tx: Text;
    begin
        Three(A);
        Tx := '';
        A.Set(0, Tx);
        Observer.Observe('set0', Txt(A));
        Tx := 'a"b\c';
        A.Set(1, Tx);
        Observer.Observe('set1', Txt(A));
        Tx := 'Café €';
        A.Set(2, Tx);
        Observer.Observe('set2', Txt(A));
        Tx := '';
        asserterror A.Set(A.Count(), Tx);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '["",2,3]');
        Observer.Expect('set1', '["","a\"b\\c",3]');
        Observer.Expect('set2', '["","a\"b\\c","Café €"]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_JsonToken()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tk: JsonToken;
    begin
        Three(A);
        Tk.ReadFrom('5');
        A.Set(0, Tk);
        Observer.Observe('set0', Txt(A));
        Tk.ReadFrom('{"x":1}');
        A.Set(1, Tk);
        Observer.Observe('set1', Txt(A));
        Tk.ReadFrom('null');
        A.Set(2, Tk);
        Observer.Observe('set2', Txt(A));
        Tk.ReadFrom('5');
        asserterror A.Set(A.Count(), Tk);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[5,2,3]');
        Observer.Expect('set1', '[5,{"x":1},3]');
        Observer.Expect('set2', '[5,{"x":1},null]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_JsonArray()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ja: JsonArray;
    begin
        Three(A);
        Ja.ReadFrom('[1,2]');
        A.Set(0, Ja);
        Observer.Observe('set0', Txt(A));
        Clear(Ja);
        A.Set(1, Ja);
        Observer.Observe('set1', Txt(A));
        Ja.ReadFrom('[1,2]');
        asserterror A.Set(A.Count(), Ja);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[[1,2],2,3]');
        Observer.Expect('set1', '[[1,2],[],3]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_JsonObject()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jo: JsonObject;
    begin
        Three(A);
        Jo.ReadFrom('{"x":1}');
        A.Set(0, Jo);
        Observer.Observe('set0', Txt(A));
        Clear(Jo);
        A.Set(1, Jo);
        Observer.Observe('set1', Txt(A));
        Jo.ReadFrom('{"x":1}');
        asserterror A.Set(A.Count(), Jo);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[{"x":1},2,3]');
        Observer.Expect('set1', '[{"x":1},{},3]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Set_JsonValue()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jv: JsonValue;
    begin
        Three(A);
        Jv.SetValue(7);
        A.Set(0, Jv);
        Observer.Observe('set0', Txt(A));
        Jv.SetValue('s');
        A.Set(1, Jv);
        Observer.Observe('set1', Txt(A));
        Jv.SetValue(7);
        asserterror A.Set(A.Count(), Jv);
        Observer.ObserveError('set_oob');
        Observer.Expect('set0', '[7,2,3]');
        Observer.Expect('set1', '[7,"s",3]');
        Observer.Expect('set_oob|text', 'Index out of bounds.');
        Observer.Expect('set_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

}
