// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonarray/jsonarray-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74401
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonArray.Add per value type
// BC versions: 29

codeunit 74401 "LT P88 Array Add"
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
        A.Add(Bo);
    end;

    [TryFunction]
    local procedure DoByte(var A: JsonArray)
    var
        By: Byte;
    begin
        By := 200;
        A.Add(By);
    end;

    [TryFunction]
    local procedure DoChar(var A: JsonArray)
    var
        Ch: Char;
    begin
        Ch := 65;
        A.Add(Ch);
    end;

    [TryFunction]
    local procedure DoDate(var A: JsonArray)
    var
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        A.Add(D);
    end;

    [TryFunction]
    local procedure DoTime(var A: JsonArray)
    var
        Ti: Time;
    begin
        Ti := 143015T;
        A.Add(Ti);
    end;

    [TryFunction]
    local procedure DoDateTime(var A: JsonArray)
    var
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(15, 3, 2024), 143015T);
        A.Add(DT);
    end;

    [TryFunction]
    local procedure DoDuration(var A: JsonArray)
    var
        Du: Duration;
    begin
        Du := 90061001;
        A.Add(Du);
    end;

    [TryFunction]
    local procedure DoDecimal(var A: JsonArray)
    var
        Dc: Decimal;
    begin
        Dc := 12.345;
        A.Add(Dc);
    end;

    [TryFunction]
    local procedure DoInteger(var A: JsonArray)
    var
        I: Integer;
    begin
        I := 42;
        A.Add(I);
    end;

    [TryFunction]
    local procedure DoBigInteger(var A: JsonArray)
    var
        Bi: BigInteger;
    begin
        Bi := 2147483647; Bi := Bi * 3;
        A.Add(Bi);
    end;

    [TryFunction]
    local procedure DoOption(var A: JsonArray)
    var
        Op: Option Alpha,Beta,Gamma;
    begin
        Op := Op::Beta;
        A.Add(Op);
    end;

    [TryFunction]
    local procedure DoText(var A: JsonArray)
    var
        Tx: Text;
    begin
        Tx := 'he said "hi" \ / end';
        A.Add(Tx);
    end;

    [TryFunction]
    local procedure DoJsonToken(var A: JsonArray)
    var
        Tk: JsonToken;
    begin
        Tk.ReadFrom('{"k":[1,2]}');
        A.Add(Tk);
    end;

    [TryFunction]
    local procedure DoJsonArray(var A: JsonArray)
    var
        Ja: JsonArray;
    begin
        Ja.ReadFrom('[1,"two"]');
        A.Add(Ja);
    end;

    [TryFunction]
    local procedure DoJsonObject(var A: JsonArray)
    var
        Jo: JsonObject;
    begin
        Jo.ReadFrom('{"k":"v"}');
        A.Add(Jo);
    end;

    [TryFunction]
    local procedure DoJsonValue(var A: JsonArray)
    var
        Jv: JsonValue;
    begin
        Jv.SetValue(7);
        A.Add(Jv);
    end;

    [Test]
    procedure AddA_Part1()
    var
        A: JsonArray;
        Txt: Text;
        Ok: Boolean;
    begin
        Clear(A);
        Ok := DoBoolean(A);
        A.WriteTo(Txt);
        Rec('AddA_Boolean', Ok, Txt);
        Clear(A);
        Ok := DoByte(A);
        A.WriteTo(Txt);
        Rec('AddA_Byte', Ok, Txt);
        Clear(A);
        Ok := DoChar(A);
        A.WriteTo(Txt);
        Rec('AddA_Char', Ok, Txt);
        Clear(A);
        Ok := DoDate(A);
        A.WriteTo(Txt);
        Rec('AddA_Date', Ok, Txt);
        Clear(A);
        Ok := DoTime(A);
        A.WriteTo(Txt);
        Rec('AddA_Time', Ok, Txt);
        Clear(A);
        Ok := DoDateTime(A);
        A.WriteTo(Txt);
        Rec('AddA_DateTime', Ok, Txt);
        Clear(A);
        Ok := DoDuration(A);
        A.WriteTo(Txt);
        Rec('AddA_Duration', Ok, Txt);
        Clear(A);
        Ok := DoDecimal(A);
        A.WriteTo(Txt);
        Rec('AddA_Decimal', Ok, Txt);
        Observer.Expect('AddA_Boolean_ok', 'Yes');
        Observer.Expect('AddA_Boolean_text', '[true]');
        Observer.Expect('AddA_Byte_ok', 'Yes');
        Observer.Expect('AddA_Byte_text', '[200]');
        Observer.Expect('AddA_Char_ok', 'Yes');
        Observer.Expect('AddA_Char_text', '[65]');
        Observer.Expect('AddA_Date_ok', 'Yes');
        Observer.Expect('AddA_Date_text', '["2024-03-15"]');
        Observer.Expect('AddA_Time_ok', 'Yes');
        Observer.Expect('AddA_Time_text', '["14:30:15"]');
        Observer.Expect('AddA_DateTime_ok', 'Yes');
        Observer.Expect('AddA_DateTime_text', '["2024-03-15T14:30:15.0000000Z"]');
        Observer.Expect('AddA_Duration_ok', 'Yes');
        Observer.Expect('AddA_Duration_text', '[90061001]');
        Observer.Expect('AddA_Decimal_ok', 'Yes');
        Observer.Expect('AddA_Decimal_text', '[12.345]');
        Observer.Verify();
    end;

    [Test]
    procedure AddA_Part2()
    var
        A: JsonArray;
        Txt: Text;
        Ok: Boolean;
    begin
        Clear(A);
        Ok := DoInteger(A);
        A.WriteTo(Txt);
        Rec('AddA_Integer', Ok, Txt);
        Clear(A);
        Ok := DoBigInteger(A);
        A.WriteTo(Txt);
        Rec('AddA_BigInteger', Ok, Txt);
        Clear(A);
        Ok := DoOption(A);
        A.WriteTo(Txt);
        Rec('AddA_Option', Ok, Txt);
        Clear(A);
        Ok := DoText(A);
        A.WriteTo(Txt);
        Rec('AddA_Text', Ok, Txt);
        Clear(A);
        Ok := DoJsonToken(A);
        A.WriteTo(Txt);
        Rec('AddA_JsonToken', Ok, Txt);
        Clear(A);
        Ok := DoJsonArray(A);
        A.WriteTo(Txt);
        Rec('AddA_JsonArray', Ok, Txt);
        Clear(A);
        Ok := DoJsonObject(A);
        A.WriteTo(Txt);
        Rec('AddA_JsonObject', Ok, Txt);
        Clear(A);
        Ok := DoJsonValue(A);
        A.WriteTo(Txt);
        Rec('AddA_JsonValue', Ok, Txt);
        Observer.Expect('AddA_Integer_ok', 'Yes');
        Observer.Expect('AddA_Integer_text', '[42]');
        Observer.Expect('AddA_BigInteger_ok', 'Yes');
        Observer.Expect('AddA_BigInteger_text', '[6442450941]');
        Observer.Expect('AddA_Option_ok', 'Yes');
        Observer.Expect('AddA_Option_text', '[1]');
        Observer.Expect('AddA_Text_ok', 'Yes');
        Observer.Expect('AddA_Text_text', '["he said \"hi\" \\ / end"]');
        Observer.Expect('AddA_JsonToken_ok', 'Yes');
        Observer.Expect('AddA_JsonToken_text', '[{"k":[1,2]}]');
        Observer.Expect('AddA_JsonArray_ok', 'Yes');
        Observer.Expect('AddA_JsonArray_text', '[[1,"two"]]');
        Observer.Expect('AddA_JsonObject_ok', 'Yes');
        Observer.Expect('AddA_JsonObject_text', '[{"k":"v"}]');
        Observer.Expect('AddA_JsonValue_ok', 'Yes');
        Observer.Expect('AddA_JsonValue_text', '[7]');
        Observer.Verify();
    end;
}
