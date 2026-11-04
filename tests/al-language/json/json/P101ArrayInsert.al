// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70851
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonArray.Insert per value type (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70851 "LT P101 Array Insert"
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
    procedure P101_Insert_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Bo: Boolean;
    begin
        Three(A);
        Bo := true;
        A.Insert(0, Bo);
        Observer.Observe('ins0', Txt(A));
        Bo := false;
        A.Insert(2, Bo);
        Observer.Observe('ins1', Txt(A));
        asserterror A.Insert(A.Count() + 1, Bo);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[true,1,2,3]');
        Observer.Expect('ins1', '[true,1,false,2,3]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Char()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ch: Char;
    begin
        Three(A);
        Ch := 65;
        A.Insert(0, Ch);
        Observer.Observe('ins0', Txt(A));
        Ch := 0;
        A.Insert(2, Ch);
        Observer.Observe('ins1', Txt(A));
        Ch := 8364;
        A.Insert(A.Count(), Ch);
        Observer.Observe('ins2', Txt(A));
        asserterror A.Insert(A.Count() + 1, Ch);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[65,1,2,3]');
        Observer.Expect('ins1', '[65,1,0,2,3]');
        Observer.Expect('ins2', '[65,1,0,2,3,8364]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Byte()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        By: Byte;
    begin
        Three(A);
        By := 0;
        A.Insert(0, By);
        Observer.Observe('ins0', Txt(A));
        By := 255;
        A.Insert(2, By);
        Observer.Observe('ins1', Txt(A));
        By := 7;
        A.Insert(A.Count(), By);
        Observer.Observe('ins2', Txt(A));
        asserterror A.Insert(A.Count() + 1, By);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[0,1,2,3]');
        Observer.Expect('ins1', '[0,1,255,2,3]');
        Observer.Expect('ins2', '[0,1,255,2,3,7]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Integer()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ig: Integer;
    begin
        Three(A);
        Ig := 0;
        A.Insert(0, Ig);
        Observer.Observe('ins0', Txt(A));
        Ig := -1;
        A.Insert(2, Ig);
        Observer.Observe('ins1', Txt(A));
        Ig := 2147483647;
        A.Insert(A.Count(), Ig);
        Observer.Observe('ins2', Txt(A));
        Ig := -2147483647;
        A.Insert(0, Ig);
        Observer.Observe('ins3', Txt(A));
        asserterror A.Insert(A.Count() + 1, Ig);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[0,1,2,3]');
        Observer.Expect('ins1', '[0,1,-1,2,3]');
        Observer.Expect('ins2', '[0,1,-1,2,3,2147483647]');
        Observer.Expect('ins3', '[-2147483647,0,1,-1,2,3,2147483647]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Bi: BigInteger;
    begin
        Three(A);
        Bi := 0;
        A.Insert(0, Bi);
        Observer.Observe('ins0', Txt(A));
        Bi := 2147483647;
        A.Insert(2, Bi);
        Observer.Observe('ins1', Txt(A));
        Bi := Bi * 4 + 3;
        A.Insert(A.Count(), Bi);
        Observer.Observe('ins2', Txt(A));
        Bi := -Bi;
        A.Insert(0, Bi);
        Observer.Observe('ins3', Txt(A));
        asserterror A.Insert(A.Count() + 1, Bi);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[0,1,2,3]');
        Observer.Expect('ins1', '[0,1,2147483647,2,3]');
        Observer.Expect('ins2', '[0,1,2147483647,2,3,8589934591]');
        Observer.Expect('ins3', '[-8589934591,0,1,2147483647,2,3,8589934591]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        De: Decimal;
    begin
        Three(A);
        De := 0;
        A.Insert(0, De);
        Observer.Observe('ins0', Txt(A));
        De := 0.1;
        A.Insert(2, De);
        Observer.Observe('ins1', Txt(A));
        De := -1.5;
        A.Insert(A.Count(), De);
        Observer.Observe('ins2', Txt(A));
        De := 123456789.123456;
        A.Insert(0, De);
        Observer.Observe('ins3', Txt(A));
        asserterror A.Insert(A.Count() + 1, De);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[0.0,1,2,3]');
        Observer.Expect('ins1', '[0.0,1,0.1,2,3]');
        Observer.Expect('ins2', '[0.0,1,0.1,2,3,-1.5]');
        Observer.Expect('ins3', '[123456789.123456,0.0,1,0.1,2,3,-1.5]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Option()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Op: Option A,B,C;
    begin
        Three(A);
        Op := 0;
        A.Insert(0, Op);
        Observer.Observe('ins0', Txt(A));
        Op := 2;
        A.Insert(2, Op);
        Observer.Observe('ins1', Txt(A));
        asserterror A.Insert(A.Count() + 1, Op);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[0,1,2,3]');
        Observer.Expect('ins1', '[0,1,2,2,3]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Date()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Da: Date;
    begin
        Three(A);
        Da := 20240229D;
        A.Insert(0, Da);
        Observer.Observe('ins0', Txt(A));
        Da := 0D;
        A.Insert(2, Da);
        Observer.Observe('ins1', Txt(A));
        Da := 99991231D;
        A.Insert(A.Count(), Da);
        Observer.Observe('ins2', Txt(A));
        asserterror A.Insert(A.Count() + 1, Da);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '["2024-02-29",1,2,3]');
        Observer.Expect('ins1', '["2024-02-29",1,"0001-01-01",2,3]');
        Observer.Expect('ins2', '["2024-02-29",1,"0001-01-01",2,3,"9999-12-31"]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Time()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ti: Time;
    begin
        Three(A);
        Ti := 123456T;
        A.Insert(0, Ti);
        Observer.Observe('ins0', Txt(A));
        Ti := 0T;
        A.Insert(2, Ti);
        Observer.Observe('ins1', Txt(A));
        Ti := 235959T;
        A.Insert(A.Count(), Ti);
        Observer.Observe('ins2', Txt(A));
        asserterror A.Insert(A.Count() + 1, Ti);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '["12:34:56",1,2,3]');
        Observer.Expect('ins1', '["12:34:56",1,"00:00:00",2,3]');
        Observer.Expect('ins2', '["12:34:56",1,"00:00:00",2,3,"23:59:59"]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Dt: DateTime;
    begin
        Three(A);
        Dt := CreateDateTime(20240229D, 123456T);
        A.Insert(0, Dt);
        Observer.Observe('ins0', Txt(A));
        Dt := 0DT;
        A.Insert(2, Dt);
        Observer.Observe('ins1', Txt(A));
        asserterror A.Insert(A.Count() + 1, Dt);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '["2024-02-29T12:34:56.0000000Z",1,2,3]');
        Observer.Expect('ins1', '["2024-02-29T12:34:56.0000000Z",1,"0001-01-01T00:00:00.0000000",2,3]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Duration()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Du: Duration;
    begin
        Three(A);
        Du := 1500;
        A.Insert(0, Du);
        Observer.Observe('ins0', Txt(A));
        Du := 0;
        A.Insert(2, Du);
        Observer.Observe('ins1', Txt(A));
        Du := -86400000;
        A.Insert(A.Count(), Du);
        Observer.Observe('ins2', Txt(A));
        asserterror A.Insert(A.Count() + 1, Du);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[1500,1,2,3]');
        Observer.Expect('ins1', '[1500,1,0,2,3]');
        Observer.Expect('ins2', '[1500,1,0,2,3,-86400000]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_Text()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tx: Text;
    begin
        Three(A);
        Tx := '';
        A.Insert(0, Tx);
        Observer.Observe('ins0', Txt(A));
        Tx := 'a"b\c';
        A.Insert(2, Tx);
        Observer.Observe('ins1', Txt(A));
        Tx := 'Café €';
        A.Insert(A.Count(), Tx);
        Observer.Observe('ins2', Txt(A));
        asserterror A.Insert(A.Count() + 1, Tx);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '["",1,2,3]');
        Observer.Expect('ins1', '["",1,"a\"b\\c",2,3]');
        Observer.Expect('ins2', '["",1,"a\"b\\c",2,3,"Café €"]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_JsonToken()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tk: JsonToken;
    begin
        Three(A);
        Tk.ReadFrom('5');
        A.Insert(0, Tk);
        Observer.Observe('ins0', Txt(A));
        Tk.ReadFrom('{"x":1}');
        A.Insert(2, Tk);
        Observer.Observe('ins1', Txt(A));
        Tk.ReadFrom('null');
        A.Insert(A.Count(), Tk);
        Observer.Observe('ins2', Txt(A));
        asserterror A.Insert(A.Count() + 1, Tk);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[5,1,2,3]');
        Observer.Expect('ins1', '[5,1,{"x":1},2,3]');
        Observer.Expect('ins2', '[5,1,{"x":1},2,3,null]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_JsonArray()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ja: JsonArray;
    begin
        Three(A);
        Ja.ReadFrom('[1,2]');
        A.Insert(0, Ja);
        Observer.Observe('ins0', Txt(A));
        Clear(Ja);
        A.Insert(2, Ja);
        Observer.Observe('ins1', Txt(A));
        asserterror A.Insert(A.Count() + 1, Ja);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[[1,2],1,2,3]');
        Observer.Expect('ins1', '[[1,2],1,[],2,3]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_JsonObject()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jo: JsonObject;
    begin
        Three(A);
        Jo.ReadFrom('{"x":1}');
        A.Insert(0, Jo);
        Observer.Observe('ins0', Txt(A));
        Clear(Jo);
        A.Insert(2, Jo);
        Observer.Observe('ins1', Txt(A));
        asserterror A.Insert(A.Count() + 1, Jo);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[{"x":1},1,2,3]');
        Observer.Expect('ins1', '[{"x":1},1,{},2,3]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

    [Test]
    procedure P101_Insert_JsonValue()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jv: JsonValue;
    begin
        Three(A);
        Jv.SetValue(7);
        A.Insert(0, Jv);
        Observer.Observe('ins0', Txt(A));
        Jv.SetValue('s');
        A.Insert(2, Jv);
        Observer.Observe('ins1', Txt(A));
        asserterror A.Insert(A.Count() + 1, Jv);
        Observer.ObserveError('ins_oob');
        Observer.Expect('ins0', '[7,1,2,3]');
        Observer.Expect('ins1', '[7,1,"s",2,3]');
        Observer.Expect('ins_oob|text', 'Index out of bounds.');
        Observer.Expect('ins_oob|code', 'IndexOutOfBounds');
        Observer.Verify();
    end;

}
