// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-abs-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the result type of Abs of a Duration seen through an assignment to Integer (compile error or conversion)
// BC versions: 29 (27 and 28 by CI)

codeunit 70003 "LT P146 Abs Dur Int"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P146_Abs_Duration_ToInteger()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        I: Integer;
    begin
        D := -1500;
        I := Abs(D);
        Observer.Observe('integer assign', Format(I));
        Observer.Expect('integer assign', '1500');
        Observer.Verify();
    end;
}
