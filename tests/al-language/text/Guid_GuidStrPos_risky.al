// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): a Guid passed where a Text is expected (StrPos_Guid).
// BC versions: 29 (27 and 28 by CI)

codeunit 70353 "LT P98 GuidStrPos"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_StrPos_Guid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        NullGuid: Guid;
        Txt: Text;
        CodeVal: Code[50];
    begin
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('pos', Format(StrPos(G, '1234'))); Observer.Observe('posC', Format(StrPos(G, 'ABC'))); Observer.Observe('padStr', PadStr(G, 40, '-')); Observer.Observe('incStr', IncStr(G));
        Observer.Expect('pos', '2');
        Observer.Expect('posC', '35');
        Observer.Expect('padStr', '{12345678-1234-1234-1234-123456789ABC}--');
        Observer.Expect('incStr', '{12345678-1234-1234-1234-123456790ABC}');
        Observer.Verify();
    end;
}
