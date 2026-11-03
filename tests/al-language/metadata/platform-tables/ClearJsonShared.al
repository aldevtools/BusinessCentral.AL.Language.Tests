// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74001
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: Clear of a JsonObject variable does not clear another variable assigned from it
// BC versions: 29
// Tag: P95

codeunit 74001 "LT P95 Clear Json Shared"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearJsonShared()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        O2: JsonObject;
        Ar: JsonArray;
        Ar2: JsonArray;
    begin
        O.Add('a', 1);
        O2 := O;
        Clear(O);
        Observer.Observe('copy_keys', Format(O2.Keys().Count()));
        Observer.Observe('cleared_keys', Format(O.Keys().Count()));
        Ar.Add(1);
        Ar2 := Ar;
        Clear(Ar);
        Observer.Observe('array_copy', Format(Ar2.Count()));
        Observer.Observe('array_cleared', Format(Ar.Count()));
        Ar2.Add(2);
        Observer.Observe('array_copy_after_add', Format(Ar2.Count()));

        Observer.Expect('copy_keys', '1');
        Observer.Expect('cleared_keys', '0');
        Observer.Expect('array_copy', '1');
        Observer.Expect('array_cleared', '0');
        Observer.Expect('array_copy_after_add', '2');
        Observer.Verify();
    end;

}
