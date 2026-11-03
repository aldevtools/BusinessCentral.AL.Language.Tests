// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74411
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: JsonValue.SetValue per value type and how it reads back
// BC versions: 29

codeunit 74411 "LT P88 Value SetValue"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Rec(Name: Text; Ok: Boolean; V: JsonValue)
    var
        Txt: Text;
    begin
        Observer.Observe(Name + '_ok', Format(Ok));
        if not Ok then begin
            Observer.ObserveError(Name);
            exit;
        end;
        V.WriteTo(Txt);
        Observer.Observe(Name + '_json', Txt);
        Observer.Observe(Name + '_astext', V.AsText());
    end;

    [TryFunction]
    local procedure DoBoolean(var V: JsonValue)
    var
        Bo: Boolean;
    begin
        Bo := true;
        V.SetValue(Bo);
    end;

    [TryFunction]
    local procedure DoByte(var V: JsonValue)
    var
        By: Byte;
    begin
        By := 200;
        V.SetValue(By);
    end;

    [TryFunction]
    local procedure DoChar(var V: JsonValue)
    var
        Ch: Char;
    begin
        Ch := 65;
        V.SetValue(Ch);
    end;

    [TryFunction]
    local procedure DoDate(var V: JsonValue)
    var
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        V.SetValue(D);
    end;

    [TryFunction]
    local procedure DoTime(var V: JsonValue)
    var
        Ti: Time;
    begin
        Ti := 143015T;
        V.SetValue(Ti);
    end;

    [TryFunction]
    local procedure DoDateTime(var V: JsonValue)
    var
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(15, 3, 2024), 143015T);
        V.SetValue(DT);
    end;

    [TryFunction]
    local procedure DoDuration(var V: JsonValue)
    var
        Du: Duration;
    begin
        Du := 90061001;
        V.SetValue(Du);
    end;

    [TryFunction]
    local procedure DoDecimal(var V: JsonValue)
    var
        Dc: Decimal;
    begin
        Dc := 12.345;
        V.SetValue(Dc);
    end;

    [TryFunction]
    local procedure DoInteger(var V: JsonValue)
    var
        I: Integer;
    begin
        I := 42;
        V.SetValue(I);
    end;

    [TryFunction]
    local procedure DoBigInteger(var V: JsonValue)
    var
        Bi: BigInteger;
    begin
        Bi := 2147483647; Bi := Bi * 3;
        V.SetValue(Bi);
    end;

    [TryFunction]
    local procedure DoOption(var V: JsonValue)
    var
        Op: Option Alpha,Beta,Gamma;
    begin
        Op := Op::Beta;
        V.SetValue(Op);
    end;

    [TryFunction]
    local procedure DoText(var V: JsonValue)
    var
        Tx: Text;
    begin
        Tx := 'he said "hi" \ / end';
        V.SetValue(Tx);
    end;

    [Test]
    procedure SetValue_Part1()
    var
        V: JsonValue;
        Ok: Boolean;
    begin
        Clear(V);
        Ok := DoBoolean(V);
        Rec('set_Boolean', Ok, V);
        Clear(V);
        Ok := DoByte(V);
        Rec('set_Byte', Ok, V);
        Clear(V);
        Ok := DoChar(V);
        Rec('set_Char', Ok, V);
        Clear(V);
        Ok := DoDate(V);
        Rec('set_Date', Ok, V);
        Clear(V);
        Ok := DoTime(V);
        Rec('set_Time', Ok, V);
        Clear(V);
        Ok := DoDateTime(V);
        Rec('set_DateTime', Ok, V);
        Observer.Expect('set_Boolean_ok', 'Yes');
        Observer.Expect('set_Boolean_json', 'true');
        Observer.Expect('set_Boolean_astext', 'true');
        Observer.Expect('set_Byte_ok', 'Yes');
        Observer.Expect('set_Byte_json', '200');
        Observer.Expect('set_Byte_astext', '200');
        Observer.Expect('set_Char_ok', 'Yes');
        Observer.Expect('set_Char_json', '65');
        Observer.Expect('set_Char_astext', '65');
        Observer.Expect('set_Date_ok', 'Yes');
        Observer.Expect('set_Date_json', '"2024-03-15"');
        Observer.Expect('set_Date_astext', '2024-03-15');
        Observer.Expect('set_Time_ok', 'Yes');
        Observer.Expect('set_Time_json', '"14:30:15"');
        Observer.Expect('set_Time_astext', '14:30:15');
        Observer.Expect('set_DateTime_ok', 'Yes');
        Observer.Expect('set_DateTime_json', '"2024-03-15T14:30:15.0000000Z"');
        Observer.Expect('set_DateTime_astext', '2024-03-15T14:30:15.0000000Z');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_Part2()
    var
        V: JsonValue;
        Ok: Boolean;
    begin
        Clear(V);
        Ok := DoDuration(V);
        Rec('set_Duration', Ok, V);
        Clear(V);
        Ok := DoDecimal(V);
        Rec('set_Decimal', Ok, V);
        Clear(V);
        Ok := DoInteger(V);
        Rec('set_Integer', Ok, V);
        Clear(V);
        Ok := DoBigInteger(V);
        Rec('set_BigInteger', Ok, V);
        Clear(V);
        Ok := DoOption(V);
        Rec('set_Option', Ok, V);
        Clear(V);
        Ok := DoText(V);
        Rec('set_Text', Ok, V);
        Observer.Expect('set_Duration_ok', 'Yes');
        Observer.Expect('set_Duration_json', '90061001');
        Observer.Expect('set_Duration_astext', '90061001');
        Observer.Expect('set_Decimal_ok', 'Yes');
        Observer.Expect('set_Decimal_json', '12.345');
        Observer.Expect('set_Decimal_astext', '12.345');
        Observer.Expect('set_Integer_ok', 'Yes');
        Observer.Expect('set_Integer_json', '42');
        Observer.Expect('set_Integer_astext', '42');
        Observer.Expect('set_BigInteger_ok', 'Yes');
        Observer.Expect('set_BigInteger_json', '6442450941');
        Observer.Expect('set_BigInteger_astext', '6442450941');
        Observer.Expect('set_Option_ok', 'Yes');
        Observer.Expect('set_Option_json', '1');
        Observer.Expect('set_Option_astext', '1');
        Observer.Expect('set_Text_ok', 'Yes');
        Observer.Expect('set_Text_json', '"he said \"hi\" \\ / end"');
        Observer.Expect('set_Text_astext', 'he said "hi" \ / end');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_Overwrite()
    var
        V: JsonValue;
        Txt: Text;
    begin
        V.SetValue(1);
        V.SetValue('now text');
        V.WriteTo(Txt);
        Observer.Observe('int_then_text', Txt);
        V.SetValue(true);
        V.WriteTo(Txt);
        Observer.Observe('then_bool', Txt);
        V.SetValueToNull();
        Observer.Observe('then_null_isnull', Format(V.IsNull()));
        V.SetValue(2);
        Observer.Observe('null_then_int_isnull', Format(V.IsNull()));
        Observer.Observe('null_then_int_asint', Format(V.AsInteger()));
        Observer.Expect('int_then_text', '"now text"');
        Observer.Expect('then_bool', 'true');
        Observer.Expect('then_null_isnull', 'Yes');
        Observer.Expect('null_then_int_isnull', 'No');
        Observer.Expect('null_then_int_asint', '2');
        Observer.Verify();
    end;
}
