// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testhandlercontext/testhandlercontext-data-type
// Scope: in-scope
// Fixtures used: BiTestHandlerBehavior.al (log 81613, handler enum value "LT BI TFB A"); own object 81621
// Corpus issue (al-runner test framework probes, 2026-10-30): TestHandlerContext.CodeunitName for a test codeunit that is declared in a namespace.
// Probe: observed values; every literal asserted below is what BC 29 produced.
// BC versions: 29
#if BC29PLUS
namespace LtBiTfb.Sub;

codeunit 81621 "LT BI TFB Namespace"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHandlers = "LT BI TFB A";

    [Test]
    procedure BiTfb_T1()
    begin
    end;

    [Test]
    procedure BiTfb_Z_Verify()
    var
        Log: Codeunit "LT BI TFB Log";
    begin
        Log.Check(81621, 'A.bCU(LtBiTfb.Sub.LT BI TFB Namespace);A.bP(BiTfb_T1);A.aP(BiTfb_T1,Yes);A.bP(BiTfb_Z_Verify);');
    end;
}
#endif
