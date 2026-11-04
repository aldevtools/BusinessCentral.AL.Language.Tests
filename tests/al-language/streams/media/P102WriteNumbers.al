// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P102 Rec (71615), LT P102 Helper (71616)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71617 "LT P102 Write Numbers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P102_Char()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: Char;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 65;
        Observer.Observe('a_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('a_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 8364;
        Observer.Observe('uni_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('uni_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0;
        Observer.Observe('nul_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('nul_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 8364;
        Observer.Observe('len1_ret', Format(Out.Write(V, 1)));
        Rec.Modify();
        Observer.Observe('len1_bytes', Helper.Dump(Rec));
        Observer.Expect('a_ret', '1');
        Observer.Expect('a_bytes', '1:41');
        Observer.Expect('uni_ret', '1');
        Observer.Expect('uni_bytes', '1:B1');
        Observer.Expect('nul_ret', '1');
        Observer.Expect('nul_bytes', '1:00');
        Observer.Expect('len1_ret', '1');
        Observer.Expect('len1_bytes', '1:B1');
        Observer.Verify();
    end;

}
