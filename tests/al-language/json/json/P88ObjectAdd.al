// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74404
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonObject.Add(key, value) per value type
// BC versions: 29

codeunit 74404 "LT P88 Object Add"
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
    local procedure DoBoolean(var O: JsonObject)
    var
        Bo: Boolean;
    begin
        Bo := true;
        O.Add('k', Bo);
    end;

    [TryFunction]
    local procedure DoByte(var O: JsonObject)
    var
        By: Byte;
    begin
        By := 200;
        O.Add('k', By);
    end;

    [TryFunction]
    local procedure DoChar(var O: JsonObject)
    var
        Ch: Char;
    begin
        Ch := 65;
        O.Add('k', Ch);
    end;

    [TryFunction]
    local procedure DoDate(var O: JsonObject)
    var
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        O.Add('k', D);
    end;

    [TryFunction]
    local procedure DoTime(var O: JsonObject)
    var
        Ti: Time;
    begin
        Ti := 143015T;
        O.Add('k', Ti);
    end;

    [TryFunction]
    local procedure DoDateTime(var O: JsonObject)
    var
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(15, 3, 2024), 143015T);
        O.Add('k', DT);
    end;

    [TryFunction]
    local procedure DoDuration(var O: JsonObject)
    var
        Du: Duration;
    begin
        Du := 90061001;
        O.Add('k', Du);
    end;

    [TryFunction]
    local procedure DoDecimal(var O: JsonObject)
    var
        Dc: Decimal;
    begin
        Dc := 12.345;
        O.Add('k', Dc);
    end;

    [TryFunction]
    local procedure DoInteger(var O: JsonObject)
    var
        I: Integer;
    begin
        I := 42;
        O.Add('k', I);
    end;

    [TryFunction]
    local procedure DoBigInteger(var O: JsonObject)
    var
        Bi: BigInteger;
    begin
        Bi := 2147483647; Bi := Bi * 3;
        O.Add('k', Bi);
    end;

    [TryFunction]
    local procedure DoOption(var O: JsonObject)
    var
        Op: Option Alpha,Beta,Gamma;
    begin
        Op := Op::Beta;
        O.Add('k', Op);
    end;

    [TryFunction]
    local procedure DoText(var O: JsonObject)
    var
        Tx: Text;
    begin
        Tx := 'he said "hi" \ / end';
        O.Add('k', Tx);
    end;

    [TryFunction]
    local procedure DoJsonToken(var O: JsonObject)
    var
        Tk: JsonToken;
    begin
        Tk.ReadFrom('{"k":[1,2]}');
        O.Add('k', Tk);
    end;

    [TryFunction]
    local procedure DoJsonArray(var O: JsonObject)
    var
        Ja: JsonArray;
    begin
        Ja.ReadFrom('[1,"two"]');
        O.Add('k', Ja);
    end;

    [TryFunction]
    local procedure DoJsonObject(var O: JsonObject)
    var
        Jo: JsonObject;
    begin
        Jo.ReadFrom('{"k":"v"}');
        O.Add('k', Jo);
    end;

    [TryFunction]
    local procedure DoJsonValue(var O: JsonObject)
    var
        Jv: JsonValue;
    begin
        Jv.SetValue(7);
        O.Add('k', Jv);
    end;

    [Test]
    procedure AddO_Part1()
    var
        O: JsonObject;
        Txt: Text;
        Ok: Boolean;
    begin
        Clear(O);
        Ok := DoBoolean(O);
        O.WriteTo(Txt);
        Rec('AddO_Boolean', Ok, Txt);
        Clear(O);
        Ok := DoByte(O);
        O.WriteTo(Txt);
        Rec('AddO_Byte', Ok, Txt);
        Clear(O);
        Ok := DoChar(O);
        O.WriteTo(Txt);
        Rec('AddO_Char', Ok, Txt);
        Clear(O);
        Ok := DoDate(O);
        O.WriteTo(Txt);
        Rec('AddO_Date', Ok, Txt);
        Clear(O);
        Ok := DoTime(O);
        O.WriteTo(Txt);
        Rec('AddO_Time', Ok, Txt);
        Clear(O);
        Ok := DoDateTime(O);
        O.WriteTo(Txt);
        Rec('AddO_DateTime', Ok, Txt);
        Clear(O);
        Ok := DoDuration(O);
        O.WriteTo(Txt);
        Rec('AddO_Duration', Ok, Txt);
        Clear(O);
        Ok := DoDecimal(O);
        O.WriteTo(Txt);
        Rec('AddO_Decimal', Ok, Txt);
        Observer.Expect('AddO_Boolean_ok', 'Yes');
        Observer.Expect('AddO_Boolean_text', '{"k":true}');
        Observer.Expect('AddO_Byte_ok', 'Yes');
        Observer.Expect('AddO_Byte_text', '{"k":200}');
        Observer.Expect('AddO_Char_ok', 'Yes');
        Observer.Expect('AddO_Char_text', '{"k":65}');
        Observer.Expect('AddO_Date_ok', 'Yes');
        Observer.Expect('AddO_Date_text', '{"k":"2024-03-15"}');
        Observer.Expect('AddO_Time_ok', 'Yes');
        Observer.Expect('AddO_Time_text', '{"k":"14:30:15"}');
        Observer.Expect('AddO_DateTime_ok', 'Yes');
        Observer.Expect('AddO_DateTime_text', '{"k":"2024-03-15T14:30:15.0000000Z"}');
        Observer.Expect('AddO_Duration_ok', 'Yes');
        Observer.Expect('AddO_Duration_text', '{"k":90061001}');
        Observer.Expect('AddO_Decimal_ok', 'Yes');
        Observer.Expect('AddO_Decimal_text', '{"k":12.345}');
        Observer.Verify();
    end;

    [Test]
    procedure AddO_Part2()
    var
        O: JsonObject;
        Txt: Text;
        Ok: Boolean;
    begin
        Clear(O);
        Ok := DoInteger(O);
        O.WriteTo(Txt);
        Rec('AddO_Integer', Ok, Txt);
        Clear(O);
        Ok := DoBigInteger(O);
        O.WriteTo(Txt);
        Rec('AddO_BigInteger', Ok, Txt);
        Clear(O);
        Ok := DoOption(O);
        O.WriteTo(Txt);
        Rec('AddO_Option', Ok, Txt);
        Clear(O);
        Ok := DoText(O);
        O.WriteTo(Txt);
        Rec('AddO_Text', Ok, Txt);
        Clear(O);
        Ok := DoJsonToken(O);
        O.WriteTo(Txt);
        Rec('AddO_JsonToken', Ok, Txt);
        Clear(O);
        Ok := DoJsonArray(O);
        O.WriteTo(Txt);
        Rec('AddO_JsonArray', Ok, Txt);
        Clear(O);
        Ok := DoJsonObject(O);
        O.WriteTo(Txt);
        Rec('AddO_JsonObject', Ok, Txt);
        Clear(O);
        Ok := DoJsonValue(O);
        O.WriteTo(Txt);
        Rec('AddO_JsonValue', Ok, Txt);
        Observer.Expect('AddO_Integer_ok', 'Yes');
        Observer.Expect('AddO_Integer_text', '{"k":42}');
        Observer.Expect('AddO_BigInteger_ok', 'Yes');
        Observer.Expect('AddO_BigInteger_text', '{"k":6442450941}');
        Observer.Expect('AddO_Option_ok', 'Yes');
        Observer.Expect('AddO_Option_text', '{"k":1}');
        Observer.Expect('AddO_Text_ok', 'Yes');
        Observer.Expect('AddO_Text_text', '{"k":"he said \"hi\" \\ / end"}');
        Observer.Expect('AddO_JsonToken_ok', 'Yes');
        Observer.Expect('AddO_JsonToken_text', '{"k":{"k":[1,2]}}');
        Observer.Expect('AddO_JsonArray_ok', 'Yes');
        Observer.Expect('AddO_JsonArray_text', '{"k":[1,"two"]}');
        Observer.Expect('AddO_JsonObject_ok', 'Yes');
        Observer.Expect('AddO_JsonObject_text', '{"k":{"k":"v"}}');
        Observer.Expect('AddO_JsonValue_ok', 'Yes');
        Observer.Expect('AddO_JsonValue_text', '{"k":7}');
        Observer.Verify();
    end;
}
