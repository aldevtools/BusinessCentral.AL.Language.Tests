// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): a Guid passed where a Text is expected (StrLen_Guid).
// BC versions: 29 (27 and 28 by CI)

codeunit 70351 "LT P98 GuidStrLen"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_StrLen_Guid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        NullGuid: Guid;
        Txt: Text;
        CodeVal: Code[50];
    begin
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('len', Format(StrLen(G))); Observer.Observe('lenFormat', Format(StrLen(Format(G)))); Observer.Observe('lenNull', Format(StrLen(NullGuid)));
        Observer.Expect('len', '38');
        Observer.Expect('lenFormat', '38');
        Observer.Expect('lenNull', '38');
        Observer.Verify();
    end;
}
