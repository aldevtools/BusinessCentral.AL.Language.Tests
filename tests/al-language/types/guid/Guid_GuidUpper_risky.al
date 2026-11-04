// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): a Guid passed where a Text is expected (UpperCase_Guid).
// BC versions: 29 (27 and 28 by CI)

codeunit 70352 "LT P98 GuidUpper"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_UpperCase_Guid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        NullGuid: Guid;
        Txt: Text;
        CodeVal: Code[50];
    begin
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('upper', UpperCase(G)); Observer.Observe('lower', LowerCase(G)); Observer.Observe('upperNull', UpperCase(NullGuid));
        Observer.Expect('upper', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('lower', '{12345678-1234-1234-1234-123456789abc}');
        Observer.Expect('upperNull', '{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;
}
