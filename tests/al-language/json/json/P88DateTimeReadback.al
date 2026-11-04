// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74412
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: how Date, Time, DateTime, Duration, BigInteger, Option, Char, Byte read back from JSON as text and as typed values
// BC versions: 29

codeunit 74412 "LT P88 DateTime Readback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure TimeMs(T: Time; Ms: Integer): Time
    begin
        exit(T + Ms);
    end;

    local procedure Fmt(V: Variant): Text
    begin
        exit(Format(V, 0, 9));
    end;

    [TryFunction]
    local procedure TryAsDate(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsDate());
    end;

    [TryFunction]
    local procedure TryAsTime(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsTime());
    end;

    [TryFunction]
    local procedure TryAsDateTime(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsDateTime());
    end;

    [TryFunction]
    local procedure TryAsDuration(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsDuration());
    end;

    [TryFunction]
    local procedure TryAsBigInt(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsBigInteger());
    end;

    local procedure Res(Name: Text; Ok: Boolean; R: Text)
    begin
        if Ok then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure Back(Name: Text; V: JsonValue)
    var
        Txt: Text;
        R: Text;
    begin
        V.WriteTo(Txt);
        Observer.Observe(Name + '_json', Txt);
        Observer.Observe(Name + '_astext', V.AsText());
        Res(Name + '_asdate', TryAsDate(V, R), R);
        Res(Name + '_astime', TryAsTime(V, R), R);
        Res(Name + '_asdatetime', TryAsDateTime(V, R), R);
    end;

    [Test]
    procedure Date_Readback()
    var
        V: JsonValue;
    begin
        V.SetValue(DMY2Date(15, 3, 2024));
        Back('date', V);
        V.SetValue(DMY2Date(1, 1, 1753));
        Back('date_min', V);
        V.SetValue(DMY2Date(31, 12, 9999));
        Back('date_max', V);
        V.SetValue(0D);
        Back('date_blank', V);
        Observer.Expect('date_json', '"2024-03-15"');
        Observer.Expect('date_astext', '2024-03-15');
        Observer.Expect('date_asdate', '2024-03-15');
        Observer.Expect('date_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('date_astime|code', 'Conversion');
        Observer.Expect('date_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('date_asdatetime|code', 'Conversion');
        Observer.Expect('date_min_json', '"1753-01-01"');
        Observer.Expect('date_min_astext', '1753-01-01');
        Observer.Expect('date_min_asdate', '1753-01-01');
        Observer.Expect('date_min_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('date_min_astime|code', 'Conversion');
        Observer.Expect('date_min_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('date_min_asdatetime|code', 'Conversion');
        Observer.Expect('date_max_json', '"9999-12-31"');
        Observer.Expect('date_max_astext', '9999-12-31');
        Observer.Expect('date_max_asdate', '9999-12-31');
        Observer.Expect('date_max_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('date_max_astime|code', 'Conversion');
        Observer.Expect('date_max_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('date_max_asdatetime|code', 'Conversion');
        Observer.Expect('date_blank_json', '"0001-01-01"');
        Observer.Expect('date_blank_astext', '0001-01-01');
        Observer.Expect('date_blank_asdate', '');
        Observer.Expect('date_blank_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('date_blank_astime|code', 'Conversion');
        Observer.Expect('date_blank_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('date_blank_asdatetime|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Readback()
    var
        V: JsonValue;
    begin
        V.SetValue(TimeMs(143015T, 123));
        Back('time', V);
        V.SetValue(0T);
        Back('time_blank', V);
        V.SetValue(000000T);
        Back('time_midnight', V);
        V.SetValue(TimeMs(235959T, 999));
        Back('time_max', V);
        Observer.Expect('time_json', '"14:30:15.123"');
        Observer.Expect('time_astext', '14:30:15.123');
        Observer.Expect('time_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('time_asdate|code', 'Conversion');
        Observer.Expect('time_astime', '14:30:15.123');
        Observer.Expect('time_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('time_asdatetime|code', 'Conversion');
        Observer.Expect('time_blank_json', '"00:00:00"');
        Observer.Expect('time_blank_astext', '00:00:00');
        Observer.Expect('time_blank_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('time_blank_asdate|code', 'Conversion');
        Observer.Expect('time_blank_astime', '00:00:00');
        Observer.Expect('time_blank_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('time_blank_asdatetime|code', 'Conversion');
        Observer.Expect('time_midnight_json', '"00:00:00"');
        Observer.Expect('time_midnight_astext', '00:00:00');
        Observer.Expect('time_midnight_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('time_midnight_asdate|code', 'Conversion');
        Observer.Expect('time_midnight_astime', '00:00:00');
        Observer.Expect('time_midnight_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('time_midnight_asdatetime|code', 'Conversion');
        Observer.Expect('time_max_json', '"23:59:59.999"');
        Observer.Expect('time_max_astext', '23:59:59.999');
        Observer.Expect('time_max_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('time_max_asdate|code', 'Conversion');
        Observer.Expect('time_max_astime', '23:59:59.999');
        Observer.Expect('time_max_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('time_max_asdatetime|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Readback()
    var
        V: JsonValue;
    begin
        V.SetValue(CreateDateTime(DMY2Date(15, 3, 2024), TimeMs(143015T, 123)));
        Back('datetime', V);
        V.SetValue(CreateDateTime(DMY2Date(15, 3, 2024), 0T));
        Back('datetime_midnight', V);
        V.SetValue(0DT);
        Back('datetime_blank', V);
        V.SetValue(CreateDateTime(DMY2Date(1, 1, 1753), 000001T));
        Back('datetime_min', V);
        Observer.Expect('datetime_json', '"2024-03-15T14:30:15.1230000Z"');
        Observer.Expect('datetime_astext', '2024-03-15T14:30:15.1230000Z');
        Observer.Expect('datetime_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('datetime_asdate|code', 'Conversion');
        Observer.Expect('datetime_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('datetime_astime|code', 'Conversion');
        Observer.Expect('datetime_asdatetime', '2024-03-15T14:30:15.123Z');
        Observer.Expect('datetime_midnight_json', '"2024-03-15T00:00:00.0000000Z"');
        Observer.Expect('datetime_midnight_astext', '2024-03-15T00:00:00.0000000Z');
        Observer.Expect('datetime_midnight_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('datetime_midnight_asdate|code', 'Conversion');
        Observer.Expect('datetime_midnight_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('datetime_midnight_astime|code', 'Conversion');
        Observer.Expect('datetime_midnight_asdatetime', '2024-03-15T00:00:00Z');
        Observer.Expect('datetime_blank_json', '"0001-01-01T00:00:00.0000000"');
        Observer.Expect('datetime_blank_astext', '0001-01-01T00:00:00.0000000');
        Observer.Expect('datetime_blank_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('datetime_blank_asdate|code', 'Conversion');
        Observer.Expect('datetime_blank_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('datetime_blank_astime|code', 'Conversion');
        Observer.Expect('datetime_blank_asdatetime', '');
        Observer.Expect('datetime_min_json', '"1753-01-01T00:00:01.0000000Z"');
        Observer.Expect('datetime_min_astext', '1753-01-01T00:00:01.0000000Z');
        Observer.Expect('datetime_min_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('datetime_min_asdate|code', 'Conversion');
        Observer.Expect('datetime_min_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('datetime_min_astime|code', 'Conversion');
        Observer.Expect('datetime_min_asdatetime', '1753-01-01T00:00:01Z');
        Observer.Verify();
    end;





    [Test]
    procedure TextToTyped()
    var
        V: JsonValue;
        R: Text;
    begin
        V.SetValue('2024-03-15');
        Res('text_date_asdate', TryAsDate(V, R), R);
        V.SetValue('2024-03-15T14:30:15Z');
        Res('text_iso_asdatetime', TryAsDateTime(V, R), R);
        Res('text_iso_asdate', TryAsDate(V, R), R);
        V.SetValue('14:30:15');
        Res('text_time_astime', TryAsTime(V, R), R);
        V.SetValue('15.03.2024');
        Res('text_localdate_asdate', TryAsDate(V, R), R);
        V.SetValue('garbage');
        Res('text_garbage_asdate', TryAsDate(V, R), R);
        Res('text_garbage_astime', TryAsTime(V, R), R);
        Res('text_garbage_asdatetime', TryAsDateTime(V, R), R);
        Observer.Expect('text_date_asdate', '2024-03-15');
        Observer.Expect('text_iso_asdatetime', '2024-03-15T14:30:15Z');
        Observer.Expect('text_iso_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('text_iso_asdate|code', 'Conversion');
        Observer.Expect('text_time_astime', '14:30:15');
        Observer.Expect('text_localdate_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('text_localdate_asdate|code', 'Conversion');
        Observer.Expect('text_garbage_asdate|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDate.');
        Observer.Expect('text_garbage_asdate|code', 'Conversion');
        Observer.Expect('text_garbage_astime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavTime.');
        Observer.Expect('text_garbage_astime|code', 'Conversion');
        Observer.Expect('text_garbage_asdatetime|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavDateTime.');
        Observer.Expect('text_garbage_asdatetime|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_BigInteger_Readback()
    var
        V: JsonValue;
        Bi: BigInteger;
        R: Text;
        Txt: Text;
    begin
        V.SetValue(90061001);
        V.WriteTo(Txt);
        Observer.Observe('duration_json', Txt);
        Observer.Observe('duration_astext', V.AsText());
        Res('duration_asduration', TryAsDuration(V, R), R);
        Res('duration_asbigint', TryAsBigInt(V, R), R);
        Bi := 2147483647;
        Bi := Bi * 3;
        V.SetValue(Bi);
        V.WriteTo(Txt);
        Observer.Observe('bigint_json', Txt);
        Observer.Observe('bigint_astext', V.AsText());
        Res('bigint_asbigint', TryAsBigInt(V, R), R);
        Observer.Observe('bigint_asdecimal', Format(V.AsDecimal(), 0, 9));
        Bi := -Bi;
        V.SetValue(Bi);
        Observer.Observe('negbigint_astext', V.AsText());
        Observer.Expect('duration_json', '90061001');
        Observer.Expect('duration_astext', '90061001');
        Observer.Expect('duration_asduration', 'P1DT1H1M1.001S');
        Observer.Expect('duration_asbigint', '90061001');
        Observer.Expect('bigint_json', '6442450941');
        Observer.Expect('bigint_astext', '6442450941');
        Observer.Expect('bigint_asbigint', '6442450941');
        Observer.Expect('bigint_asdecimal', '6442450941');
        Observer.Expect('negbigint_astext', '-6442450941');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Byte_Option_Readback()
    var
        V: JsonValue;
        Ch: Char;
        By: Byte;
        Op: Option Alpha,Beta,Gamma;
        Txt: Text;
    begin
        Ch := 65;
        V.SetValue(Ch);
        V.WriteTo(Txt);
        Observer.Observe('char_json', Txt);
        Observer.Observe('char_astext', V.AsText());
        By := 200;
        V.SetValue(By);
        V.WriteTo(Txt);
        Observer.Observe('byte_json', Txt);
        Observer.Observe('byte_asinteger', Format(V.AsInteger()));
        Op := Op::Gamma;
        V.SetValue(Op);
        V.WriteTo(Txt);
        Observer.Observe('option_json', Txt);
        Observer.Observe('option_astext', V.AsText());
        Observer.Observe('option_asinteger', Format(V.AsInteger()));
        V.SetValue(true);
        Observer.Observe('bool_astext', V.AsText());
        Observer.Observe('bool_asboolean', Format(V.AsBoolean()));
        Observer.Expect('char_json', '65');
        Observer.Expect('char_astext', '65');
        Observer.Expect('byte_json', '200');
        Observer.Expect('byte_asinteger', '200');
        Observer.Expect('option_json', '2');
        Observer.Expect('option_astext', '2');
        Observer.Expect('option_asinteger', '2');
        Observer.Expect('bool_astext', 'true');
        Observer.Expect('bool_asboolean', 'Yes');
        Observer.Verify();
    end;
}
