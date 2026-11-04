// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): a Guid passed where a Text is expected (CopyStr_Guid).
// BC versions: 29 (27 and 28 by CI)

codeunit 70350 "LT P98 GuidCopyStr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_CopyStr_Guid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        NullGuid: Guid;
        Txt: Text;
        CodeVal: Code[50];
    begin
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Observe('copy', CopyStr(G, 1, 50)); Observer.Observe('copy5', CopyStr(G, 1, 5)); Observer.Observe('copyFrom', CopyStr(G, 30)); Observer.Observe('copyMax', CopyStr(G, 1, 10000));
        Observer.Expect('copy', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Expect('copy5', '{1234');
        Observer.Expect('copyFrom', '56789ABC}');
        Observer.Expect('copyMax', '{12345678-1234-1234-1234-123456789ABC}');
        Observer.Verify();
    end;
}
