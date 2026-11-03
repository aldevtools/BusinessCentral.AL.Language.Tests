// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/json/json-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 71879
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Char typed stores read back (risky: Char conversions)
// BC versions: 29 (27 and 28 by CI)

codeunit 71879 "LT JsonTyped Char Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P192_ArrayAdd_Char_Get0()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        T: JsonToken;
        Ch: Char;
        R: Text;
    begin
        Ch := 65;
        A.Add(Ch);
        A.WriteTo(R);
        Observer.Observe('json', R);
        A.Get(0, T);
        Observer.Observe('text', T.AsValue().AsText());
        Observer.Observe('int', Format(T.AsValue().AsInteger()));
        Observer.Observe('dec', Format(T.AsValue().AsDecimal()));
        Clear(A);
        Ch := 0;
        A.Add(Ch);
        A.WriteTo(R);
        Observer.Observe('zero_json', R);
        A.Get(0, T);
        Observer.Observe('zero_text', T.AsValue().AsText());
        Observer.Observe('zero_int', Format(T.AsValue().AsInteger()));
        Clear(A);
        Ch := 65535;
        A.Add(Ch);
        A.WriteTo(R);
        Observer.Observe('max_json', R);
        A.Get(0, T);
        Observer.Observe('max_text', T.AsValue().AsText());
        Observer.Observe('max_int', Format(T.AsValue().AsInteger()));
        Observer.Expect('json', '[65]');
        Observer.Expect('text', '65');
        Observer.Expect('int', '65');
        Observer.Expect('dec', '65');
        Observer.Expect('zero_json', '[0]');
        Observer.Expect('zero_text', '0');
        Observer.Expect('zero_int', '0');
        Observer.Expect('max_json', '[65535]');
        Observer.Expect('max_text', '65535');
        Observer.Expect('max_int', '65535');
        Observer.Verify();
    end;

    [Test]
    procedure P192_Object_Char_Add_Replace()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        T: JsonToken;
        Ch: Char;
        R: Text;
    begin
        Ch := 66;
        O.Add('c', Ch);
        O.WriteTo(R);
        Observer.Observe('json', R);
        O.Get('c', T);
        Observer.Observe('text', T.AsValue().AsText());
        asserterror O.Add('c', Ch);
        Observer.ObserveError('dup');
        Ch := 67;
        Observer.Observe('rep_existing', Format(O.Replace('c', Ch)));
        asserterror O.Replace('missing', Ch);
        Observer.ObserveError('rep_missing');
        O.WriteTo(R);
        Observer.Observe('after', R);
        Observer.Expect('json', '{"c":66}');
        Observer.Expect('text', '66');
        Observer.Expect('dup|text', 'The JSON object already contains the key ''c''.');
        Observer.Expect('dup|code', 'DuplicateJsonProperty');
        Observer.Expect('rep_existing', 'Yes');
        Observer.Expect('rep_missing|text', 'There is no property with the ''missing'' key on the JSON object.');
        Observer.Expect('rep_missing|code', 'JsonPropertyNotFound');
        Observer.Expect('after', '{"c":67}');
        Observer.Verify();
    end;

    [Test]
    procedure P192_Array_Char_Insert_Set_IndexOf()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Ch: Char;
        Ig: Integer;
        R: Text;
    begin
        A.Add(1);
        A.Add(2);
        Ch := 70;
        A.Insert(0, Ch);
        A.Insert(2, Ch);
        A.Insert(A.Count(), Ch);
        A.WriteTo(R);
        Observer.Observe('arr', R);
        asserterror A.Insert(A.Count() + 1, Ch);
        Observer.ObserveError('insert_bad');
        Ch := 71;
        A.Set(1, Ch);
        A.WriteTo(R);
        Observer.Observe('set', R);
        asserterror A.Set(A.Count(), Ch);
        Observer.ObserveError('set_bad');
        Observer.Observe('idx_71', Format(A.IndexOf(Ch)));
        Ig := 70;
        Observer.Observe('idx_int_70', Format(A.IndexOf(Ig)));
        Ch := 70;
        Observer.Observe('idx_70', Format(A.IndexOf(Ch)));
        Ch := 72;
        Observer.Observe('idx_missing', Format(A.IndexOf(Ch)));
        Observer.Expect('arr', '[70,1,70,2,70]');
        Observer.Expect('insert_bad|text', 'Index out of bounds.');
        Observer.Expect('insert_bad|code', 'IndexOutOfBounds');
        Observer.Expect('set', '[70,71,70,2,70]');
        Observer.Expect('set_bad|text', 'Index out of bounds.');
        Observer.Expect('set_bad|code', 'IndexOutOfBounds');
        Observer.Expect('idx_71', '1');
        Observer.Expect('idx_int_70', '0');
        Observer.Expect('idx_70', '0');
        Observer.Expect('idx_missing', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P192_SetValue_Char_Then_Other()
    var
        Observer: Codeunit "Probe Observer";
        Jv: JsonValue;
        Ch: Char;
        By: Byte;
        R: Text;
    begin
        Ch := 90;
        Jv.SetValue(Ch);
        Jv.WriteTo(R);
        Observer.Observe('json', R);
        Observer.Observe('text', Jv.AsText());
        Observer.Observe('int', Format(Jv.AsInteger()));
        Observer.Observe('dec', Format(Jv.AsDecimal()));
        By := 255;
        Jv.SetValue(By);
        Jv.WriteTo(R);
        Observer.Observe('byte_json', R);
        Observer.Observe('byte_int', Format(Jv.AsInteger()));
        Ch := 0;
        Jv.SetValue(Ch);
        Jv.WriteTo(R);
        Observer.Observe('zero_json', R);
        Observer.Expect('json', '90');
        Observer.Expect('text', '90');
        Observer.Expect('int', '90');
        Observer.Expect('dec', '90');
        Observer.Expect('byte_json', '255');
        Observer.Expect('byte_int', '255');
        Observer.Expect('zero_json', '0');
        Observer.Verify();
    end;
}
