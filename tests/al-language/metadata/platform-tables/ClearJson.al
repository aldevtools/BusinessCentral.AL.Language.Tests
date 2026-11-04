// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74000
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Clear on JsonObject, JsonArray, JsonToken, JsonValue
// BC versions: 29
// Tag: P95

codeunit 74000 "LT P95 Clear Json"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearJson()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Ar: JsonArray;
        Tk: JsonToken;
        Va: JsonValue;
    begin
        O.Add('a', 1);
        O.Add('b', 'x');
        Ar.Add(1);
        Ar.Add('two');
        Tk := O.AsToken();
        Va.SetValue(5);
        Observer.Observe('before', Format(O.Keys().Count()) + '|' + Format(Ar.Count()) + '|' + Format(Tk.IsObject()) + '|' + Format(Va.AsInteger()));
        Clear(O);
        Clear(Ar);
        Clear(Tk);
        Clear(Va);
        Observer.Observe('object_after', Format(O.Keys().Count()) + '|' + Format(O.Contains('a')));
        Observer.Observe('array_after', Format(Ar.Count()));
        Observer.Observe('token_after', Format(Tk.IsObject()) + '|' + Format(Tk.IsArray()) + '|' + Format(Tk.IsValue()));
        Observer.Observe('value_after', Format(Va.IsNull()) + '|' + Format(Va.IsUndefined()));
        O.Add('c', 3);
        Observer.Observe('object_reuse', Format(O.Keys().Count()));
        Ar.Add(9);
        Observer.Observe('array_reuse', Format(Ar.Count()));
        O.ReadFrom('{"k":1}');
        Observer.Observe('object_readfrom', Format(O.Keys().Count()));
        Clear(O);
        Observer.Observe('text_after_clear', Format(O.AsToken().AsObject().Keys().Count()));

        Observer.Expect('before', '2|2|Yes|5');
        Observer.Expect('object_after', '0|No');
        Observer.Expect('array_after', '0');
        Observer.Expect('token_after', 'No|No|Yes');
        Observer.Expect('value_after', 'Yes|No');
        Observer.Expect('object_reuse', '1');
        Observer.Expect('array_reuse', '1');
        Observer.Expect('object_readfrom', '1');
        Observer.Expect('text_after_clear', '0');
        Observer.Verify();
    end;

}
