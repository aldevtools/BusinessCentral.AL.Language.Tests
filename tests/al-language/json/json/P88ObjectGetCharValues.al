// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74414
// Probe: written against BC 29 (runtime 16); P88; the values are measured later on a local BC 29 service tier.
// Facts: UNSURE the members exist: JsonObject.GetChar, JsonObject.Values
// BC versions: 29

codeunit 74414 "LT P88 Object GetChar Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure Object_GetChar()
    var
        O: JsonObject;
        Ch: Char;
    begin
        Ch := 65;
        O.Add('c', Ch);
        O.Add('t', 'B');
        O.Add('n', 7);
        Observer.Observe('char', Format(O.GetChar('c')));
        Observer.Observe('char_from_text', Format(O.GetChar('t')));
        Observer.Observe('char_from_int', Format(O.GetChar('n')));
        Observer.Observe('char_from_int', 'no error');
        asserterror Observer.Observe('char_missing', Format(O.GetChar('zzz')));
        Observer.ObserveError('char_missing');
        Observer.Expect('char', 'A');
        Observer.Expect('char_from_text', 'B');
        Observer.Expect('char_from_int', '\u0007');
        Observer.Expect('char_from_int', 'no error');
        Observer.Expect('char_missing|text', 'There is no property with the ''zzz'' key on the JSON object.');
        Observer.Expect('char_missing|code', 'JsonPropertyNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Object_Values()
    var
        O: JsonObject;
        L: List of [JsonToken];
        T: JsonToken;
        Txt: Text;
        R: Text;
    begin
        L := O.Values();
        Observer.Observe('values_empty_count', Format(L.Count()));
        O.Add('a', 1);
        O.Add('b', 'two');
        O.Add('c', true);
        L := O.Values();
        Observer.Observe('values_count', Format(L.Count()));
        foreach T in L do begin
            T.WriteTo(Txt);
            R += Txt + ';';
        end;
        Observer.Observe('values', R);
        Observer.Expect('values_empty_count', '0');
        Observer.Expect('values_count', '3');
        Observer.Expect('values', '1;"two";true;');
        Observer.Verify();
    end;
}
