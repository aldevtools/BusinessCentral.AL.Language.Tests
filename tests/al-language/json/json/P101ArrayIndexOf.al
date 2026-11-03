// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70853
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonArray.IndexOf per value type (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70853 "LT P101 Array IndexOf"
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
    procedure P101_IndexOf_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Bo: Boolean;
    begin
        Clear(A);
        Bo := true;
        A.Add(Bo);
        Bo := false;
        A.Add(Bo);
        Observer.Observe('arr', Txt(A));
        Bo := true;
        Observer.Observe('idx0', Format(A.IndexOf(Bo)));
        Bo := false;
        Observer.Observe('idx1', Format(A.IndexOf(Bo)));
        Bo := true;
        A.Add(Bo);
        Observer.Observe('dup_first', Format(A.IndexOf(Bo)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Bo)));
        Observer.Expect('arr', '[true,false]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Char()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ch: Char;
    begin
        Clear(A);
        Ch := 65;
        A.Add(Ch);
        Ch := 0;
        A.Add(Ch);
        Ch := 8364;
        A.Add(Ch);
        Observer.Observe('arr', Txt(A));
        Ch := 65;
        Observer.Observe('idx0', Format(A.IndexOf(Ch)));
        Ch := 0;
        Observer.Observe('idx1', Format(A.IndexOf(Ch)));
        Ch := 8364;
        Observer.Observe('idx2', Format(A.IndexOf(Ch)));
        Ch := 65;
        A.Add(Ch);
        Observer.Observe('dup_first', Format(A.IndexOf(Ch)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Ch)));
        Observer.Expect('arr', '[65,0,8364]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Byte()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        By: Byte;
    begin
        Clear(A);
        By := 0;
        A.Add(By);
        By := 255;
        A.Add(By);
        By := 7;
        A.Add(By);
        Observer.Observe('arr', Txt(A));
        By := 0;
        Observer.Observe('idx0', Format(A.IndexOf(By)));
        By := 255;
        Observer.Observe('idx1', Format(A.IndexOf(By)));
        By := 7;
        Observer.Observe('idx2', Format(A.IndexOf(By)));
        By := 0;
        A.Add(By);
        Observer.Observe('dup_first', Format(A.IndexOf(By)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(By)));
        Observer.Expect('arr', '[0,255,7]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Integer()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ig: Integer;
    begin
        Clear(A);
        Ig := 0;
        A.Add(Ig);
        Ig := -1;
        A.Add(Ig);
        Ig := 2147483647;
        A.Add(Ig);
        Ig := -2147483647;
        A.Add(Ig);
        Observer.Observe('arr', Txt(A));
        Ig := 0;
        Observer.Observe('idx0', Format(A.IndexOf(Ig)));
        Ig := -1;
        Observer.Observe('idx1', Format(A.IndexOf(Ig)));
        Ig := 2147483647;
        Observer.Observe('idx2', Format(A.IndexOf(Ig)));
        Ig := -2147483647;
        Observer.Observe('idx3', Format(A.IndexOf(Ig)));
        Ig := 0;
        A.Add(Ig);
        Observer.Observe('dup_first', Format(A.IndexOf(Ig)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Ig)));
        Observer.Expect('arr', '[0,-1,2147483647,-2147483647]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('idx3', '3');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Bi: BigInteger;
    begin
        Clear(A);
        Bi := 0;
        A.Add(Bi);
        Bi := 2147483647;
        A.Add(Bi);
        Bi := Bi * 4 + 3;
        A.Add(Bi);
        Bi := -Bi;
        A.Add(Bi);
        Observer.Observe('arr', Txt(A));
        Bi := 0;
        Observer.Observe('idx0', Format(A.IndexOf(Bi)));
        Bi := 2147483647;
        Observer.Observe('idx1', Format(A.IndexOf(Bi)));
        Bi := Bi * 4 + 3;
        Observer.Observe('idx2', Format(A.IndexOf(Bi)));
        Bi := -Bi;
        Observer.Observe('idx3', Format(A.IndexOf(Bi)));
        Bi := 0;
        A.Add(Bi);
        Observer.Observe('dup_first', Format(A.IndexOf(Bi)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Bi)));
        Observer.Expect('arr', '[0,2147483647,8589934591,-8589934591]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('idx3', '3');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        De: Decimal;
    begin
        Clear(A);
        De := 0;
        A.Add(De);
        De := 0.1;
        A.Add(De);
        De := -1.5;
        A.Add(De);
        De := 123456789.123456;
        A.Add(De);
        Observer.Observe('arr', Txt(A));
        De := 0;
        Observer.Observe('idx0', Format(A.IndexOf(De)));
        De := 0.1;
        Observer.Observe('idx1', Format(A.IndexOf(De)));
        De := -1.5;
        Observer.Observe('idx2', Format(A.IndexOf(De)));
        De := 123456789.123456;
        Observer.Observe('idx3', Format(A.IndexOf(De)));
        De := 0;
        A.Add(De);
        Observer.Observe('dup_first', Format(A.IndexOf(De)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(De)));
        Observer.Expect('arr', '[0.0,0.1,-1.5,123456789.123456]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('idx3', '3');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Option()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Op: Option A,B,C;
    begin
        Clear(A);
        Op := 0;
        A.Add(Op);
        Op := 2;
        A.Add(Op);
        Observer.Observe('arr', Txt(A));
        Op := 0;
        Observer.Observe('idx0', Format(A.IndexOf(Op)));
        Op := 2;
        Observer.Observe('idx1', Format(A.IndexOf(Op)));
        Op := 0;
        A.Add(Op);
        Observer.Observe('dup_first', Format(A.IndexOf(Op)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Op)));
        Observer.Expect('arr', '[0,2]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Date()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Da: Date;
    begin
        Clear(A);
        Da := 20240229D;
        A.Add(Da);
        Da := 0D;
        A.Add(Da);
        Da := 99991231D;
        A.Add(Da);
        Observer.Observe('arr', Txt(A));
        Da := 20240229D;
        Observer.Observe('idx0', Format(A.IndexOf(Da)));
        Da := 0D;
        Observer.Observe('idx1', Format(A.IndexOf(Da)));
        Da := 99991231D;
        Observer.Observe('idx2', Format(A.IndexOf(Da)));
        Da := 20240229D;
        A.Add(Da);
        Observer.Observe('dup_first', Format(A.IndexOf(Da)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Da)));
        Observer.Expect('arr', '["2024-02-29","0001-01-01","9999-12-31"]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Time()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ti: Time;
    begin
        Clear(A);
        Ti := 123456T;
        A.Add(Ti);
        Ti := 0T;
        A.Add(Ti);
        Ti := 235959T;
        A.Add(Ti);
        Observer.Observe('arr', Txt(A));
        Ti := 123456T;
        Observer.Observe('idx0', Format(A.IndexOf(Ti)));
        Ti := 0T;
        Observer.Observe('idx1', Format(A.IndexOf(Ti)));
        Ti := 235959T;
        Observer.Observe('idx2', Format(A.IndexOf(Ti)));
        Ti := 123456T;
        A.Add(Ti);
        Observer.Observe('dup_first', Format(A.IndexOf(Ti)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Ti)));
        Observer.Expect('arr', '["12:34:56","00:00:00","23:59:59"]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Dt: DateTime;
    begin
        Clear(A);
        Dt := CreateDateTime(20240229D, 123456T);
        A.Add(Dt);
        Dt := 0DT;
        A.Add(Dt);
        Observer.Observe('arr', Txt(A));
        Dt := CreateDateTime(20240229D, 123456T);
        Observer.Observe('idx0', Format(A.IndexOf(Dt)));
        Dt := 0DT;
        Observer.Observe('idx1', Format(A.IndexOf(Dt)));
        Dt := CreateDateTime(20240229D, 123456T);
        A.Add(Dt);
        Observer.Observe('dup_first', Format(A.IndexOf(Dt)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Dt)));
        Observer.Expect('arr', '["2024-02-29T12:34:56.0000000Z","0001-01-01T00:00:00.0000000"]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Duration()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Du: Duration;
    begin
        Clear(A);
        Du := 1500;
        A.Add(Du);
        Du := 0;
        A.Add(Du);
        Du := -86400000;
        A.Add(Du);
        Observer.Observe('arr', Txt(A));
        Du := 1500;
        Observer.Observe('idx0', Format(A.IndexOf(Du)));
        Du := 0;
        Observer.Observe('idx1', Format(A.IndexOf(Du)));
        Du := -86400000;
        Observer.Observe('idx2', Format(A.IndexOf(Du)));
        Du := 1500;
        A.Add(Du);
        Observer.Observe('dup_first', Format(A.IndexOf(Du)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Du)));
        Observer.Expect('arr', '[1500,0,-86400000]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_Text()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tx: Text;
    begin
        Clear(A);
        Tx := '';
        A.Add(Tx);
        Tx := 'a"b\c';
        A.Add(Tx);
        Tx := 'Café €';
        A.Add(Tx);
        Observer.Observe('arr', Txt(A));
        Tx := '';
        Observer.Observe('idx0', Format(A.IndexOf(Tx)));
        Tx := 'a"b\c';
        Observer.Observe('idx1', Format(A.IndexOf(Tx)));
        Tx := 'Café €';
        Observer.Observe('idx2', Format(A.IndexOf(Tx)));
        Tx := '';
        A.Add(Tx);
        Observer.Observe('dup_first', Format(A.IndexOf(Tx)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Tx)));
        Observer.Expect('arr', '["","a\"b\\c","Café €"]');
        Observer.Expect('idx0', '0');
        Observer.Expect('idx1', '1');
        Observer.Expect('idx2', '2');
        Observer.Expect('dup_first', '0');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_JsonToken()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tk: JsonToken;
    begin
        Clear(A);
        Tk.ReadFrom('5');
        A.Add(Tk);
        Tk.ReadFrom('{"x":1}');
        A.Add(Tk);
        Tk.ReadFrom('null');
        A.Add(Tk);
        Observer.Observe('arr', Txt(A));
        Tk.ReadFrom('5');
        Observer.Observe('idx0', Format(A.IndexOf(Tk)));
        Tk.ReadFrom('{"x":1}');
        Observer.Observe('idx1', Format(A.IndexOf(Tk)));
        Tk.ReadFrom('null');
        Observer.Observe('idx2', Format(A.IndexOf(Tk)));
        Tk.ReadFrom('5');
        A.Add(Tk);
        Observer.Observe('dup_first', Format(A.IndexOf(Tk)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Tk)));
        Observer.Expect('arr', '[5,{"x":1},null]');
        Observer.Expect('idx0', '-1');
        Observer.Expect('idx1', '-1');
        Observer.Expect('idx2', '-1');
        Observer.Expect('dup_first', '3');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_JsonArray()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ja: JsonArray;
    begin
        Clear(A);
        Ja.ReadFrom('[1,2]');
        A.Add(Ja);
        Clear(Ja);
        A.Add(Ja);
        Observer.Observe('arr', Txt(A));
        Ja.ReadFrom('[1,2]');
        Observer.Observe('idx0', Format(A.IndexOf(Ja)));
        Clear(Ja);
        Observer.Observe('idx1', Format(A.IndexOf(Ja)));
        Ja.ReadFrom('[1,2]');
        A.Add(Ja);
        Observer.Observe('dup_first', Format(A.IndexOf(Ja)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Ja)));
        Observer.Expect('arr', '[[1,2],[]]');
        Observer.Expect('idx0', '-1');
        Observer.Expect('idx1', '-1');
        Observer.Expect('dup_first', '2');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_JsonObject()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jo: JsonObject;
    begin
        Clear(A);
        Jo.ReadFrom('{"x":1}');
        A.Add(Jo);
        Clear(Jo);
        A.Add(Jo);
        Observer.Observe('arr', Txt(A));
        Jo.ReadFrom('{"x":1}');
        Observer.Observe('idx0', Format(A.IndexOf(Jo)));
        Clear(Jo);
        Observer.Observe('idx1', Format(A.IndexOf(Jo)));
        Jo.ReadFrom('{"x":1}');
        A.Add(Jo);
        Observer.Observe('dup_first', Format(A.IndexOf(Jo)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Jo)));
        Observer.Expect('arr', '[{"x":1},{}]');
        Observer.Expect('idx0', '-1');
        Observer.Expect('idx1', '-1');
        Observer.Expect('dup_first', '2');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_JsonValue()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jv: JsonValue;
    begin
        Clear(A);
        Jv.SetValue(7);
        A.Add(Jv);
        Jv.SetValue('s');
        A.Add(Jv);
        Observer.Observe('arr', Txt(A));
        Jv.SetValue(7);
        Observer.Observe('idx0', Format(A.IndexOf(Jv)));
        Jv.SetValue('s');
        Observer.Observe('idx1', Format(A.IndexOf(Jv)));
        Jv.SetValue(7);
        A.Add(Jv);
        Observer.Observe('dup_first', Format(A.IndexOf(Jv)));
        Clear(A);
        Observer.Observe('empty', Format(A.IndexOf(Jv)));
        Observer.Expect('arr', '[7,"s"]');
        Observer.Expect('idx0', '-1');
        Observer.Expect('idx1', '-1');
        Observer.Expect('dup_first', '2');
        Observer.Expect('empty', '-1');
        Observer.Verify();
    end;

    // Writer SN (2026-10-25, runtime hand-off refuse-json-streams "IndexOf of a scalar JsonToken/JsonValue (identity)"):
    // whether Add keeps the variable's own value object (IndexOf right after Add) and what SetValue/ReadFrom on the variable do to it.
    [Test]
    procedure P101_IndexOf_JsonValue_Identity()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Jv: JsonValue;
        Tk: JsonToken;
        Got: JsonValue;
    begin
        Jv.SetValue(7);
        A.Add(Jv);
        Observer.Observe('right_after_add', Format(A.IndexOf(Jv)));
        Jv.SetValue(8);
        Observer.Observe('after_setvalue_arr', Txt(A));
        Observer.Observe('after_setvalue_idx', Format(A.IndexOf(Jv)));
        A.Add(Jv);
        Jv.ReadFrom('9');
        Observer.Observe('after_readfrom_arr', Txt(A));
        Observer.Observe('after_readfrom_idx', Format(A.IndexOf(Jv)));
        A.Get(0, Tk);
        Observer.Observe('got_token_idx', Format(A.IndexOf(Tk)));
        Got := Tk.AsValue();
        Observer.Observe('got_value_idx', Format(A.IndexOf(Got)));
        Got.SetValue(70);
        Observer.Observe('got_setvalue_arr', Txt(A));
        Observer.Observe('got_setvalue_idx', Format(A.IndexOf(Got)));
        Observer.Expect('right_after_add', '0');
        Observer.Expect('after_setvalue_arr', '[7]');
        Observer.Expect('after_setvalue_idx', '-1');
        Observer.Expect('after_readfrom_arr', '[7,8]');
        Observer.Expect('after_readfrom_idx', '-1');
        Observer.Expect('got_token_idx', '0');
        Observer.Expect('got_value_idx', '0');
        Observer.Expect('got_setvalue_arr', '[7,8]');
        Observer.Expect('got_setvalue_idx', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_IndexOf_JsonToken_Identity()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Tk: JsonToken;
        Tk2: JsonToken;
        Jo: JsonObject;
    begin
        Tk.ReadFrom('5');
        A.Add(Tk);
        Observer.Observe('scalar_right_after_add', Format(A.IndexOf(Tk)));
        Tk2 := Tk;
        Observer.Observe('scalar_copy_idx', Format(A.IndexOf(Tk2)));
        Observer.Observe('scalar_asvalue_idx', Format(A.IndexOf(Tk.AsValue())));
        Tk.ReadFrom('{"x":1}');
        A.Add(Tk);
        Observer.Observe('object_right_after_add', Format(A.IndexOf(Tk)));
        Jo := Tk.AsObject();
        Observer.Observe('object_asobject_idx', Format(A.IndexOf(Jo)));
        Jo.Add('y', 2);
        Observer.Observe('object_after_change_arr', Txt(A));
        A.Get(0, Tk2);
        Observer.Observe('get0_idx', Format(A.IndexOf(Tk2)));
        Observer.Observe('get0_value_idx', Format(A.IndexOf(Tk2.AsValue())));
        Observer.Expect('scalar_right_after_add', '0');
        Observer.Expect('scalar_copy_idx', '0');
        Observer.Expect('scalar_asvalue_idx', '0');
        Observer.Expect('object_right_after_add', '1');
        Observer.Expect('object_asobject_idx', '1');
        Observer.Expect('object_after_change_arr', '[5,{"x":1,"y":2}]');
        Observer.Expect('get0_idx', '0');
        Observer.Expect('get0_value_idx', '0');
        Observer.Verify();
    end;
}
