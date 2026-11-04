// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74403
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonArray.Set(1, value) per value type
// BC versions: 29

codeunit 74403 "LT P88 Array Set"
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
        A.Set(1, Bo);
    end;

    [TryFunction]
    local procedure DoByte(var A: JsonArray)
    var
        By: Byte;
    begin
        By := 200;
        A.Set(1, By);
    end;

    [TryFunction]
    local procedure DoChar(var A: JsonArray)
    var
        Ch: Char;
    begin
        Ch := 65;
        A.Set(1, Ch);
    end;

    [TryFunction]
    local procedure DoDate(var A: JsonArray)
    var
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        A.Set(1, D);
    end;

    [TryFunction]
    local procedure DoTime(var A: JsonArray)
    var
        Ti: Time;
    begin
        Ti := 143015T;
        A.Set(1, Ti);
    end;

    [TryFunction]
    local procedure DoDateTime(var A: JsonArray)
    var
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(15, 3, 2024), 143015T);
        A.Set(1, DT);
    end;

    [TryFunction]
    local procedure DoDuration(var A: JsonArray)
    var
        Du: Duration;
    begin
        Du := 90061001;
        A.Set(1, Du);
    end;

    [TryFunction]
    local procedure DoDecimal(var A: JsonArray)
    var
        Dc: Decimal;
    begin
        Dc := 12.345;
        A.Set(1, Dc);
    end;

    [TryFunction]
    local procedure DoInteger(var A: JsonArray)
    var
        I: Integer;
    begin
        I := 42;
        A.Set(1, I);
    end;

    [TryFunction]
    local procedure DoBigInteger(var A: JsonArray)
    var
        Bi: BigInteger;
    begin
        Bi := 2147483647; Bi := Bi * 3;
        A.Set(1, Bi);
    end;

    [TryFunction]
    local procedure DoOption(var A: JsonArray)
    var
        Op: Option Alpha,Beta,Gamma;
    begin
        Op := Op::Beta;
        A.Set(1, Op);
    end;

    [TryFunction]
    local procedure DoText(var A: JsonArray)
    var
        Tx: Text;
    begin
        Tx := 'he said "hi" \ / end';
        A.Set(1, Tx);
    end;

    [TryFunction]
    local procedure DoJsonToken(var A: JsonArray)
    var
        Tk: JsonToken;
    begin
        Tk.ReadFrom('{"k":[1,2]}');
        A.Set(1, Tk);
    end;

    [TryFunction]
    local procedure DoJsonArray(var A: JsonArray)
    var
        Ja: JsonArray;
    begin
        Ja.ReadFrom('[1,"two"]');
        A.Set(1, Ja);
    end;

    [TryFunction]
    local procedure DoJsonObject(var A: JsonArray)
    var
        Jo: JsonObject;
    begin
        Jo.ReadFrom('{"k":"v"}');
        A.Set(1, Jo);
    end;

    [TryFunction]
    local procedure DoJsonValue(var A: JsonArray)
    var
        Jv: JsonValue;
    begin
        Jv.SetValue(7);
        A.Set(1, Jv);
    end;

    [Test]
    procedure SetA_Part1()
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
        Rec('SetA_Boolean', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoByte(A);
        A.WriteTo(Txt);
        Rec('SetA_Byte', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoChar(A);
        A.WriteTo(Txt);
        Rec('SetA_Char', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoDate(A);
        A.WriteTo(Txt);
        Rec('SetA_Date', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoTime(A);
        A.WriteTo(Txt);
        Rec('SetA_Time', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoDateTime(A);
        A.WriteTo(Txt);
        Rec('SetA_DateTime', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoDuration(A);
        A.WriteTo(Txt);
        Rec('SetA_Duration', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoDecimal(A);
        A.WriteTo(Txt);
        Rec('SetA_Decimal', Ok, Txt);
        Observer.Expect('SetA_Boolean_ok', 'Yes');
        Observer.Expect('SetA_Boolean_text', '[0,true]');
        Observer.Expect('SetA_Byte_ok', 'Yes');
        Observer.Expect('SetA_Byte_text', '[0,200]');
        Observer.Expect('SetA_Char_ok', 'Yes');
        Observer.Expect('SetA_Char_text', '[0,65]');
        Observer.Expect('SetA_Date_ok', 'Yes');
        Observer.Expect('SetA_Date_text', '[0,"2024-03-15"]');
        Observer.Expect('SetA_Time_ok', 'Yes');
        Observer.Expect('SetA_Time_text', '[0,"14:30:15"]');
        Observer.Expect('SetA_DateTime_ok', 'Yes');
        Observer.Expect('SetA_DateTime_text', '[0,"2024-03-15T14:30:15.0000000Z"]');
        Observer.Expect('SetA_Duration_ok', 'Yes');
        Observer.Expect('SetA_Duration_text', '[0,90061001]');
        Observer.Expect('SetA_Decimal_ok', 'Yes');
        Observer.Expect('SetA_Decimal_text', '[0,12.345]');
        Observer.Verify();
    end;

    [Test]
    procedure SetA_Part2()
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
        Rec('SetA_Integer', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoBigInteger(A);
        A.WriteTo(Txt);
        Rec('SetA_BigInteger', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoOption(A);
        A.WriteTo(Txt);
        Rec('SetA_Option', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoText(A);
        A.WriteTo(Txt);
        Rec('SetA_Text', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoJsonToken(A);
        A.WriteTo(Txt);
        Rec('SetA_JsonToken', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoJsonArray(A);
        A.WriteTo(Txt);
        Rec('SetA_JsonArray', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoJsonObject(A);
        A.WriteTo(Txt);
        Rec('SetA_JsonObject', Ok, Txt);
        Clear(A);
        A.Add(0);
        A.Add(9);
        Ok := DoJsonValue(A);
        A.WriteTo(Txt);
        Rec('SetA_JsonValue', Ok, Txt);
        Observer.Expect('SetA_Integer_ok', 'Yes');
        Observer.Expect('SetA_Integer_text', '[0,42]');
        Observer.Expect('SetA_BigInteger_ok', 'Yes');
        Observer.Expect('SetA_BigInteger_text', '[0,6442450941]');
        Observer.Expect('SetA_Option_ok', 'Yes');
        Observer.Expect('SetA_Option_text', '[0,1]');
        Observer.Expect('SetA_Text_ok', 'Yes');
        Observer.Expect('SetA_Text_text', '[0,"he said \"hi\" \\ / end"]');
        Observer.Expect('SetA_JsonToken_ok', 'Yes');
        Observer.Expect('SetA_JsonToken_text', '[0,{"k":[1,2]}]');
        Observer.Expect('SetA_JsonArray_ok', 'Yes');
        Observer.Expect('SetA_JsonArray_text', '[0,[1,"two"]]');
        Observer.Expect('SetA_JsonObject_ok', 'Yes');
        Observer.Expect('SetA_JsonObject_text', '[0,{"k":"v"}]');
        Observer.Expect('SetA_JsonValue_ok', 'Yes');
        Observer.Expect('SetA_JsonValue_text', '[0,7]');
        Observer.Verify();
    end;
}
