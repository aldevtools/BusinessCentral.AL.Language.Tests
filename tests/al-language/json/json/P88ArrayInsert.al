// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74402
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonArray.Insert(1, value) per value type
// BC versions: 29

codeunit 74402 "LT P88 Array Insert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Rec(Name: Text; Ok: Boolean; Txt: Text)
    begin
        Observer.Observe(Name + '_ok', Format(Ok));
        if Ok then
            Observer.Observe(Name + '_text', Txt)
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure DoBoolean(var A: JsonArray)
    var
        Bo: Boolean;
    begin
        Bo := true;
        A.Insert(1, Bo);
    end;

    [TryFunction]
    local procedure DoByte(var A: JsonArray)
    var
        By: Byte;
    begin
        By := 200;
        A.Insert(1, By);
    end;

    [TryFunction]
    local procedure DoChar(var A: JsonArray)
    var
        Ch: Char;
    begin
        Ch := 65;
        A.Insert(1, Ch);
    end;

    [TryFunction]
    local procedure DoDate(var A: JsonArray)
    var
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        A.Insert(1, D);
    end;

    [TryFunction]
    local procedure DoTime(var A: JsonArray)
    var
        Ti: Time;
    begin
        Ti := 143015T;
        A.Insert(1, Ti);
    end;

    [TryFunction]
    local procedure DoDateTime(var A: JsonArray)
    var
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(15, 3, 2024), 143015T);
        A.Insert(1, DT);
    end;

    [TryFunction]
    local procedure DoDuration(var A: JsonArray)
    var
        Du: Duration;
    begin
        Du := 90061001;
        A.Insert(1, Du);
    end;

    [TryFunction]
    local procedure DoDecimal(var A: JsonArray)
    var
        Dc: Decimal;
    begin
        Dc := 12.345;
        A.Insert(1, Dc);
    end;

    [TryFunction]
    local procedure DoInteger(var A: JsonArray)
    var
        I: Integer;
    begin
        I := 42;
        A.Insert(1, I);
    end;

    [TryFunction]
    local procedure DoBigInteger(var A: JsonArray)
    var
        Bi: BigInteger;
    begin
        Bi := 2147483647; Bi := Bi * 3;
        A.Insert(1, Bi);
    end;

    [TryFunction]
    local procedure DoOption(var A: JsonArray)
    var
        Op: Option Alpha,Beta,Gamma;
    begin
        Op := Op::Beta;
        A.Insert(1, Op);
    end;

    [TryFunction]
    local procedure DoText(var A: JsonArray)
    var
        Tx: Text;
    begin
        Tx := 'he said "hi" \ / end';
        A.Insert(1, Tx);
    end;

    [TryFunction]
    local procedure DoJsonToken(var A: JsonArray)
    var
        Tk: JsonToken;
    begin
        Tk.ReadFrom('{"k":[1,2]}');
        A.Insert(1, Tk);
    end;

    [TryFunction]
    local procedure DoJsonArray(var A: JsonArray)
    var
        Ja: JsonArray;
    begin
        Ja.ReadFrom('[1,"two"]');
        A.Insert(1, Ja);
    end;

    [TryFunction]
    local procedure DoJsonObject(var A: JsonArray)
    var
        Jo: JsonObject;
    begin
        Jo.ReadFrom('{"k":"v"}');
        A.Insert(1, Jo);
    end;

    [TryFunction]
    local procedure DoJsonValue(var A: JsonArray)
    var
        Jv: JsonValue;
    begin
        Jv.SetValue(7);
        A.Insert(1, Jv);
    end;

    [Test]
    procedure InsertA_Part1()
    var
        A: JsonArray;
        Txt: Text;
        Ok: Boolean;
    begin
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoBoolean(A);
        A.WriteTo(Txt);
        Rec('InsertA_Boolean', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoByte(A);
        A.WriteTo(Txt);
        Rec('InsertA_Byte', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoChar(A);
        A.WriteTo(Txt);
        Rec('InsertA_Char', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoDate(A);
        A.WriteTo(Txt);
        Rec('InsertA_Date', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoTime(A);
        A.WriteTo(Txt);
        Rec('InsertA_Time', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoDateTime(A);
        A.WriteTo(Txt);
        Rec('InsertA_DateTime', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoDuration(A);
        A.WriteTo(Txt);
        Rec('InsertA_Duration', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoDecimal(A);
        A.WriteTo(Txt);
        Rec('InsertA_Decimal', Ok, Txt);
        Observer.Expect('InsertA_Boolean_ok', 'Yes');
        Observer.Expect('InsertA_Boolean_text', '[0,true,9]');
        Observer.Expect('InsertA_Byte_ok', 'Yes');
        Observer.Expect('InsertA_Byte_text', '[0,200,9]');
        Observer.Expect('InsertA_Char_ok', 'Yes');
        Observer.Expect('InsertA_Char_text', '[0,65,9]');
        Observer.Expect('InsertA_Date_ok', 'Yes');
        Observer.Expect('InsertA_Date_text', '[0,"2024-03-15",9]');
        Observer.Expect('InsertA_Time_ok', 'Yes');
        Observer.Expect('InsertA_Time_text', '[0,"14:30:15",9]');
        Observer.Expect('InsertA_DateTime_ok', 'Yes');
        Observer.Expect('InsertA_DateTime_text', '[0,"2024-03-15T14:30:15.0000000Z",9]');
        Observer.Expect('InsertA_Duration_ok', 'Yes');
        Observer.Expect('InsertA_Duration_text', '[0,90061001,9]');
        Observer.Expect('InsertA_Decimal_ok', 'Yes');
        Observer.Expect('InsertA_Decimal_text', '[0,12.345,9]');
        Observer.Verify();
    end;

    [Test]
    procedure InsertA_Part2()
    var
        A: JsonArray;
        Txt: Text;
        Ok: Boolean;
    begin
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoInteger(A);
        A.WriteTo(Txt);
        Rec('InsertA_Integer', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoBigInteger(A);
        A.WriteTo(Txt);
        Rec('InsertA_BigInteger', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoOption(A);
        A.WriteTo(Txt);
        Rec('InsertA_Option', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoText(A);
        A.WriteTo(Txt);
        Rec('InsertA_Text', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoJsonToken(A);
        A.WriteTo(Txt);
        Rec('InsertA_JsonToken', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoJsonArray(A);
        A.WriteTo(Txt);
        Rec('InsertA_JsonArray', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoJsonObject(A);
        A.WriteTo(Txt);
        Rec('InsertA_JsonObject', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoJsonValue(A);
        A.WriteTo(Txt);
        Rec('InsertA_JsonValue', Ok, Txt);
        Observer.Expect('InsertA_Integer_ok', 'Yes');
        Observer.Expect('InsertA_Integer_text', '[0,42,9]');
        Observer.Expect('InsertA_BigInteger_ok', 'Yes');
        Observer.Expect('InsertA_BigInteger_text', '[0,6442450941,9]');
        Observer.Expect('InsertA_Option_ok', 'Yes');
        Observer.Expect('InsertA_Option_text', '[0,1,9]');
        Observer.Expect('InsertA_Text_ok', 'Yes');
        Observer.Expect('InsertA_Text_text', '[0,"he said \"hi\" \\ / end",9]');
        Observer.Expect('InsertA_JsonToken_ok', 'Yes');
        Observer.Expect('InsertA_JsonToken_text', '[0,{"k":[1,2]},9]');
        Observer.Expect('InsertA_JsonArray_ok', 'Yes');
        Observer.Expect('InsertA_JsonArray_text', '[0,[1,"two"],9]');
        Observer.Expect('InsertA_JsonObject_ok', 'Yes');
        Observer.Expect('InsertA_JsonObject_text', '[0,{"k":"v"},9]');
        Observer.Expect('InsertA_JsonValue_ok', 'Yes');
        Observer.Expect('InsertA_JsonValue_text', '[0,7,9]');
        Observer.Verify();
    end;
}
