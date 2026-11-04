// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/json/json-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 71876
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonArray/JsonObject typed Byte, Integer, Decimal stores read back through JsonValue
// BC versions: 29 (27 and 28 by CI)

codeunit 71876 "LT JsonTyped Numbers ReadBack"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Rd(var Observer: Codeunit "Probe Observer"; Name: Text; Tok: JsonToken)
    var
        Jv: JsonValue;
    begin
        Jv := Tok.AsValue();
        Observer.Observe(Name + '_text', Jv.AsText());
        Observer.Observe(Name + '_int', Format(Jv.AsInteger()));
        Observer.Observe(Name + '_dec', Format(Jv.AsDecimal()));
        Observer.Observe(Name + '_isnum', Format(Jv.IsNull()));
    end;

    [Test]
    procedure P192_ArrayAdd_Byte_Get0()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        T: JsonToken;
        By: Byte;
        R: Text;
    begin
        By := 255;
        A.Add(By);
        A.WriteTo(R);
        Observer.Observe('max_json', R);
        A.Get(0, T);
        Rd(Observer, 'max', T);
        Clear(A);
        By := 0;
        A.Add(By);
        A.WriteTo(R);
        Observer.Observe('zero_json', R);
        A.Get(0, T);
        Rd(Observer, 'zero', T);
        Observer.Expect('max_json', '[255]');
        Observer.Expect('max_text', '255');
        Observer.Expect('max_int', '255');
        Observer.Expect('max_dec', '255');
        Observer.Expect('max_isnum', 'No');
        Observer.Expect('zero_json', '[0]');
        Observer.Expect('zero_text', '0');
        Observer.Expect('zero_int', '0');
        Observer.Expect('zero_dec', '0');
        Observer.Expect('zero_isnum', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P192_ArrayAdd_Integer_Get0()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        T: JsonToken;
        Ig: Integer;
        R: Text;
    begin
        Ig := 2147483647;
        A.Add(Ig);
        A.WriteTo(R);
        Observer.Observe('max_json', R);
        A.Get(0, T);
        Rd(Observer, 'max', T);
        Clear(A);
        Ig := 0;
        A.Add(Ig);
        A.WriteTo(R);
        Observer.Observe('zero_json', R);
        A.Get(0, T);
        Rd(Observer, 'zero', T);
        Clear(A);
        Ig := -2147483647;
        A.Add(Ig);
        A.WriteTo(R);
        Observer.Observe('min_json', R);
        A.Get(0, T);
        Rd(Observer, 'min', T);
        Observer.Expect('max_json', '[2147483647]');
        Observer.Expect('max_text', '2147483647');
        Observer.Expect('max_int', '2147483647');
        Observer.Expect('max_dec', '2,147,483,647');
        Observer.Expect('max_isnum', 'No');
        Observer.Expect('zero_json', '[0]');
        Observer.Expect('zero_text', '0');
        Observer.Expect('zero_int', '0');
        Observer.Expect('zero_dec', '0');
        Observer.Expect('zero_isnum', 'No');
        Observer.Expect('min_json', '[-2147483647]');
        Observer.Expect('min_text', '-2147483647');
        Observer.Expect('min_int', '-2147483647');
        Observer.Expect('min_dec', '-2,147,483,647');
        Observer.Expect('min_isnum', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P192_ArrayAdd_Decimal_Get0()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        T: JsonToken;
        De: Decimal;
        R: Text;
    begin
        De := 0;
        A.Add(De);
        A.WriteTo(R);
        Observer.Observe('zero_json', R);
        A.Get(0, T);
        Rd(Observer, 'zero', T);
        Clear(A);
        De := 1.5;
        A.Add(De);
        A.WriteTo(R);
        Observer.Observe('frac_json', R);
        A.Get(0, T);
        Observer.Observe('frac_text', T.AsValue().AsText());
        Observer.Observe('frac_dec', Format(T.AsValue().AsDecimal()));
        Observer.Observe('frac_int', Format(T.AsValue().AsInteger()));
        Observer.Observe('frac_int_err', 'no error');
        Clear(A);
        De := 123456789012.123456;
        A.Add(De);
        A.WriteTo(R);
        Observer.Observe('big_json', R);
        A.Get(0, T);
        Observer.Observe('big_text', T.AsValue().AsText());
        Observer.Observe('big_dec', Format(T.AsValue().AsDecimal(), 0, 9));
        Observer.Expect('zero_json', '[0.0]');
        Observer.Expect('zero_text', '0');
        Observer.Expect('zero_int', '0');
        Observer.Expect('zero_dec', '0');
        Observer.Expect('zero_isnum', 'No');
        Observer.Expect('frac_json', '[1.5]');
        Observer.Expect('frac_text', '1.5');
        Observer.Expect('frac_dec', '1.5');
        Observer.Expect('frac_int', '2');
        Observer.Expect('frac_int_err', 'no error');
        Observer.Expect('big_json', '[123456789012.123456]');
        Observer.Expect('big_text', '123456789012.123456');
        Observer.Expect('big_dec', '123456789012.123456');
        Observer.Verify();
    end;

    [Test]
    procedure P192_ObjectAdd_Numbers_Get()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        T: JsonToken;
        By: Byte;
        Ig: Integer;
        De: Decimal;
        R: Text;
    begin
        By := 255;
        O.Add('by', By);
        Ig := 2147483647;
        O.Add('ig', Ig);
        De := 0;
        O.Add('de', De);
        O.WriteTo(R);
        Observer.Observe('json', R);
        O.Get('by', T);
        Rd(Observer, 'by', T);
        O.Get('ig', T);
        Rd(Observer, 'ig', T);
        O.Get('de', T);
        Rd(Observer, 'de', T);
        Observer.Expect('json', '{"by":255,"ig":2147483647,"de":0.0}');
        Observer.Expect('by_text', '255');
        Observer.Expect('by_int', '255');
        Observer.Expect('by_dec', '255');
        Observer.Expect('by_isnum', 'No');
        Observer.Expect('ig_text', '2147483647');
        Observer.Expect('ig_int', '2147483647');
        Observer.Expect('ig_dec', '2,147,483,647');
        Observer.Expect('ig_isnum', 'No');
        Observer.Expect('de_text', '0');
        Observer.Expect('de_int', '0');
        Observer.Expect('de_dec', '0');
        Observer.Expect('de_isnum', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P192_Replace_Insert_Set_Get()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        O: JsonObject;
        T: JsonToken;
        By: Byte;
        Ig: Integer;
        De: Decimal;
        R: Text;
    begin
        A.Add('x');
        A.Add('y');
        By := 200;
        A.Insert(1, By);
        Ig := -5;
        A.Set(0, Ig);
        De := 2.25;
        A.Insert(3, De);
        A.WriteTo(R);
        Observer.Observe('arr', R);
        A.Get(0, T);
        Rd(Observer, 'a0', T);
        A.Get(1, T);
        Rd(Observer, 'a1', T);
        A.Get(3, T);
        Observer.Observe('a3_text', T.AsValue().AsText());
        O.Add('k', 'old');
        Ig := 42;
        Observer.Observe('rep_existing', Format(O.Replace('k', Ig)));
        O.WriteTo(R);
        Observer.Observe('obj', R);
        O.Get('k', T);
        Rd(Observer, 'k', T);
        Observer.Expect('arr', '[-5,200,"y",2.25]');
        Observer.Expect('a0_text', '-5');
        Observer.Expect('a0_int', '-5');
        Observer.Expect('a0_dec', '-5');
        Observer.Expect('a0_isnum', 'No');
        Observer.Expect('a1_text', '200');
        Observer.Expect('a1_int', '200');
        Observer.Expect('a1_dec', '200');
        Observer.Expect('a1_isnum', 'No');
        Observer.Expect('a3_text', '2.25');
        Observer.Expect('rep_existing', 'Yes');
        Observer.Expect('obj', '{"k":42}');
        Observer.Expect('k_text', '42');
        Observer.Expect('k_int', '42');
        Observer.Expect('k_dec', '42');
        Observer.Expect('k_isnum', 'No');
        Observer.Verify();
    end;
}
