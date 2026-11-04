// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P102 Rec (71615), LT P102 Helper (71616)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71621 "LT P102 Write Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P102_RecordId()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: RecordId;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := Rec.RecordId();
        asserterror Out.Write(V);
        Observer.ObserveError('recordid');
        Observer.Expect('recordid|text', 'ALStream.ALWrite, invalid stream mode: Stream');
        Observer.Expect('recordid|code', 'InvalidStreamMode');
        Observer.Verify();
    end;

    [Test]
    procedure P102_Record()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Other: Record "LT P102 Rec";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Other.Id := 5;
        asserterror Out.Write(Other);
        Observer.ObserveError('record');
        Observer.Expect('record|text', 'ALStream.ALWrite, invalid stream mode: Stream');
        Observer.Expect('record|code', 'InvalidStreamMode');
        Observer.Verify();
    end;
}
