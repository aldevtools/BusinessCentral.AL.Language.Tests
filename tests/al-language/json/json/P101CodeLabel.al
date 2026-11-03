// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70859
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonToken/JsonObject/JsonArray/JsonValue with Code, Label and Text arguments (exact overloads)
// BC versions: 29 (27 and 28 by CI)

codeunit 70859 "LT P101 Code Label"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LblText: Label 'label text';
        LblJson: Label '{"k":[1,2]}';
        LblKey: Label 'lk';

    [Test]
    procedure P101_TokenReadFromCodeLabel()
    var
        Observer: Codeunit "Probe Observer";
        T: JsonToken;
        Cd: Code[20];
        Tx: Text;
        R: Text;
    begin
        Cd := '123';
        Observer.Observe('code_ok', Format(T.ReadFrom(Cd)));
        T.WriteTo(R);
        Observer.Observe('code_json', R);
        Cd := 'abc';
        asserterror T.ReadFrom(Cd);
        Observer.ObserveError('code_bad');
        Observer.Observe('label_ok', Format(T.ReadFrom(LblJson)));
        T.WriteTo(R);
        Observer.Observe('label_json', R);
        Tx := '[true]';
        Observer.Observe('text_ok', Format(T.ReadFrom(Tx)));
        T.WriteTo(Tx);
        Observer.Observe('writeto_text', Tx);
        Observer.Observe('literal_ok', Format(T.ReadFrom('{"z":0}')));
        Observer.Expect('code_ok', 'Yes');
        Observer.Expect('code_json', '123');
        Observer.Expect('code_bad|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('code_bad|code', 'InvalidJsonData');
        Observer.Expect('label_ok', 'Yes');
        Observer.Expect('label_json', '{"k":[1,2]}');
        Observer.Expect('text_ok', 'Yes');
        Observer.Expect('writeto_text', '[true]');
        Observer.Expect('literal_ok', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P101_ObjectCodeLabelKeys()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        T: JsonToken;
        Cd: Code[20];
        R: Text;
    begin
        Cd := 'ckey';
        O.Add(Cd, 1);
        O.Add(LblKey, 'v');
        O.Add(LblText, true);
        O.WriteTo(R);
        Observer.Observe('keys', R);
        Observer.Observe('contains_code', Format(O.Contains(Cd)));
        Observer.Observe('contains_label', Format(O.Contains(LblKey)));
        Observer.Observe('get_code', Format(O.Get(Cd, T)));
        Observer.Observe('get_label', Format(O.Get(LblKey, T)));
        O.Replace(Cd, LblText);
        O.Replace(LblKey, Cd);
        O.WriteTo(R);
        Observer.Observe('replaced', R);
        Observer.Observe('selecttoken_code', Format(O.SelectToken(Cd, T)));
        Observer.Observe('remove_code', Format(O.Remove(Cd)));
        Observer.Observe('remove_label', Format(O.Remove(LblKey)));
        Observer.Observe('keys_left', Format(O.Keys().Count()));
        Observer.Expect('keys', '{"CKEY":1,"lk":"v","label text":true}');
        Observer.Expect('contains_code', 'Yes');
        Observer.Expect('contains_label', 'Yes');
        Observer.Expect('get_code', 'Yes');
        Observer.Expect('get_label', 'Yes');
        Observer.Expect('replaced', '{"label text":true,"CKEY":"label text","lk":"CKEY"}');
        Observer.Expect('selecttoken_code', 'Yes');
        Observer.Expect('remove_code', 'Yes');
        Observer.Expect('remove_label', 'Yes');
        Observer.Expect('keys_left', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P101_ArrayCodeLabelValues()
    var
        Observer: Codeunit "Probe Observer";
        A: JsonArray;
        Cd: Code[20];
        Tx: Text[10];
        R: Text;
    begin
        Cd := 'abc';
        Tx := 'ten chars!';
        A.Add(Cd);
        A.Add(LblText);
        A.Add(Tx);
        A.Insert(0, Cd);
        A.Insert(1, LblText);
        A.Set(2, Tx);
        A.Set(3, LblText);
        A.WriteTo(R);
        Observer.Observe('array', R);
        Observer.Observe('indexof_code', Format(A.IndexOf(Cd)));
        Observer.Observe('indexof_label', Format(A.IndexOf(LblText)));
        Observer.Observe('indexof_text10', Format(A.IndexOf(Tx)));
        Observer.Expect('array', '["ABC","label text","ten chars!","label text","ten chars!"]');
        Observer.Expect('indexof_code', '0');
        Observer.Expect('indexof_label', '1');
        Observer.Expect('indexof_text10', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P101_ValueCodeLabel()
    var
        Observer: Codeunit "Probe Observer";
        V: JsonValue;
        Cd: Code[20];
        R: Text;
    begin
        Cd := 'abc';
        V.SetValue(Cd);
        V.WriteTo(R);
        Observer.Observe('code', R);
        V.SetValue(LblText);
        V.WriteTo(R);
        Observer.Observe('label', R);
        Observer.Observe('astext', V.AsText());
        Observer.Observe('ascode', V.AsCode());
        Observer.Observe('isstring', Format(V.IsNull()));
        Observer.Expect('code', '"ABC"');
        Observer.Expect('label', '"label text"');
        Observer.Expect('astext', 'label text');
        Observer.Expect('ascode', 'LABEL TEXT');
        Observer.Expect('isstring', 'No');
        Observer.Verify();
    end;
}
