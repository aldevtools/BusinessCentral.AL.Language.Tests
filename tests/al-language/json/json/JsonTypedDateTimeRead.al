// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/json/json-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 71878
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: DateTime typed stores and SetValue readback
// BC versions: 29 (27 and 28 by CI)

codeunit 71878 "LT JsonTyped DateTime Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P192_ArrayAdd_DateTime_Get0()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        T: JsonToken;
        Dt: DateTime;
        R: Text;
    begin
        Dt := CreateDateTime(20240229D, 123456T);
        A.Add(Dt);
        A.WriteTo(R);
        Observer.Observe('json', R);
        A.Get(0, T);
        Observer.Observe('text', T.AsValue().AsText());
        Observer.Observe('dt', Format(T.AsValue().AsDateTime(), 0, 9));
        asserterror Observer.Observe('int', Format(T.AsValue().AsInteger()));
        Observer.ObserveError('int_err');
        asserterror Observer.Observe('dec', Format(T.AsValue().AsDecimal()));
        Observer.ObserveError('dec_err');
        Clear(A);
        Dt := 0DT;
        A.Add(Dt);
        A.WriteTo(R);
        Observer.Observe('zero_json', R);
        A.Get(0, T);
        Observer.Observe('zero_text', T.AsValue().AsText());
        Observer.Observe('zero_dt', Format(T.AsValue().AsDateTime(), 0, 9));
        Observer.Expect('json', '["2024-02-29T12:34:56.0000000Z"]');
        Observer.Expect('text', '2024-02-29T12:34:56.0000000Z');
        Observer.Expect('dt', '2024-02-29T12:34:56Z');
        Observer.Expect('int_err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.');
        Observer.Expect('int_err|code', 'Conversion');
        Observer.Expect('dec_err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.');
        Observer.Expect('dec_err|code', 'Conversion');
        Observer.Expect('zero_json', '["0001-01-01T00:00:00.0000000"]');
        Observer.Expect('zero_text', '0001-01-01T00:00:00.0000000');
        Observer.Expect('zero_dt', '');
        Observer.Verify();
    end;

    [Test]
    procedure P192_DateTime_Largest_Value()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        O: JsonObject;
        T: JsonToken;
        Dt: DateTime;
        R: Text;
    begin
        Dt := CreateDateTime(99991231D, 235959T);
        A.Add(Dt);
        A.WriteTo(R);
        Observer.Observe('json', R);
        A.Get(0, T);
        Observer.Observe('text', T.AsValue().AsText());
        Observer.Observe('dt', Format(T.AsValue().AsDateTime(), 0, 9));
        O.Add('k', Dt);
        O.WriteTo(R);
        Observer.Observe('obj_json', R);
        Observer.Expect('json', '["9999-12-31T23:59:59.0000000Z"]');
        Observer.Expect('text', '9999-12-31T23:59:59.0000000Z');
        Observer.Expect('dt', '9999-12-31T23:59:59Z');
        Observer.Expect('obj_json', '{"k":"9999-12-31T23:59:59.0000000Z"}');
        Observer.Verify();
    end;

    [Test]
    procedure P192_Insert_Set_Replace_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        O: JsonObject;
        Dt: DateTime;
        R: Text;
    begin
        A.Add(1);
        A.Add(2);
        Dt := CreateDateTime(20200101D, 000000T);
        A.Insert(0, Dt);
        A.WriteTo(R);
        Observer.Observe('start', R);
        A.Insert(2, Dt);
        A.WriteTo(R);
        Observer.Observe('middle', R);
        A.Insert(A.Count(), Dt);
        A.WriteTo(R);
        Observer.Observe('end', R);
        asserterror A.Insert(A.Count() + 1, Dt);
        Observer.ObserveError('insert_bad');
        asserterror A.Insert(-1, Dt);
        Observer.ObserveError('insert_neg');
        Dt := CreateDateTime(20210202D, 010203T);
        A.Set(1, Dt);
        A.WriteTo(R);
        Observer.Observe('set', R);
        asserterror A.Set(-1, Dt);
        Observer.ObserveError('set_neg');
        O.Add('k', 1);
        Observer.Observe('rep_existing', Format(O.Replace('k', Dt)));
        asserterror O.Replace('missing', Dt);
        Observer.ObserveError('rep_missing');
        O.WriteTo(R);
        Observer.Observe('obj', R);
        Observer.Expect('start', '["2020-01-01T00:00:00.0000000Z",1,2]');
        Observer.Expect('middle', '["2020-01-01T00:00:00.0000000Z",1,"2020-01-01T00:00:00.0000000Z",2]');
        Observer.Expect('end', '["2020-01-01T00:00:00.0000000Z",1,"2020-01-01T00:00:00.0000000Z",2,"2020-01-01T00:00:00.0000000Z"]');
        Observer.Expect('insert_bad|text', 'Index out of bounds.');
        Observer.Expect('insert_bad|code', 'IndexOutOfBounds');
        Observer.Expect('insert_neg|text', 'Index out of bounds.');
        Observer.Expect('insert_neg|code', 'IndexOutOfBounds');
        Observer.Expect('set', '["2020-01-01T00:00:00.0000000Z","2021-02-02T01:02:03.0000000Z","2020-01-01T00:00:00.0000000Z",2,"2020-01-01T00:00:00.0000000Z"]');
        Observer.Expect('set_neg|text', 'Index out of bounds.');
        Observer.Expect('set_neg|code', 'IndexOutOfBounds');
        Observer.Expect('rep_existing', 'Yes');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('obj', '{"k":"2021-02-02T01:02:03.0000000Z"}');
        Observer.Verify();
    end;

    [Test]
    procedure P192_SetValue_DateTime_Then_Others()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Dt: DateTime;
        Ig: Integer;
        De: Decimal;
        R: Text;
    begin
        Dt := CreateDateTime(20240229D, 123456T);
        Jv.SetValue(Dt);
        Jv.WriteTo(R);
        Observer.Observe('json', R);
        Observer.Observe('text', Jv.AsText());
        Observer.Observe('dt', Format(Jv.AsDateTime(), 0, 9));
        asserterror Observer.Observe('int', Format(Jv.AsInteger()));
        Observer.ObserveError('int_err');
        Ig := 12;
        Jv.SetValue(Ig);
        Jv.WriteTo(R);
        Observer.Observe('after_int_json', R);
        Observer.Observe('after_int_text', Jv.AsText());
        De := 1.25;
        Jv.SetValue(De);
        Jv.WriteTo(R);
        Observer.Observe('after_dec_json', R);
        Observer.Observe('after_dec_text', Jv.AsText());
        Jv.SetValue(Dt);
        Jv.WriteTo(R);
        Observer.Observe('back_json', R);
        Observer.Expect('json', '"2024-02-29T12:34:56.0000000Z"');
        Observer.Expect('text', '2024-02-29T12:34:56.0000000Z');
        Observer.Expect('dt', '2024-02-29T12:34:56Z');
        Observer.Expect('int_err|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.');
        Observer.Expect('int_err|code', 'Conversion');
        Observer.Expect('after_int_json', '12');
        Observer.Expect('after_int_text', '12');
        Observer.Expect('after_dec_json', '1.25');
        Observer.Expect('after_dec_text', '1.25');
        Observer.Expect('back_json', '"2024-02-29T12:34:56.0000000Z"');
        Observer.Verify();
    end;
}
