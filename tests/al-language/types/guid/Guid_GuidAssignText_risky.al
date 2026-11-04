// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): a Guid passed where a Text is expected (GuidAsText_Assign).
// BC versions: 29 (27 and 28 by CI)

codeunit 70354 "LT P98 GuidAssignText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_GuidAsText_Assign()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        NullGuid: Guid;
        Txt: Text;
        CodeVal: Code[50];
    begin
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Txt := G; Observer.Observe('text', Txt); Observer.Observe('code', Format(StrLen(CodeVal))); CodeVal := G; Observer.Observe('codeval', CodeVal); Txt := Format(G); Observer.Observe('fmt', Txt); Observer.Observe('concat', 'pre-' + G);
        Observer.Expect('text', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('code', '0');
        Observer.Expect('codeval', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('fmt', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('concat', 'pre-{12345678-1234-1234-1234-123456789ABC}');
        Observer.Verify();
    end;
}
