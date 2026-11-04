// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT OutIn Rec (71751), LT OutIn Helper (71752)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71754 "LT OutIn Write Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P191_Option_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Option A,B,C;
        R: Option A,B,C;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := V::A;
        Observer.Observe('a_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('a_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('a_read_n', Format(Ins.Read(R)));
        Observer.Observe('a_read_v', Format(R));
        Observer.Observe('a_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := V::C;
        Observer.Observe('c_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('c_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('c_read_n', Format(Ins.Read(R)));
        Observer.Observe('c_read_v', Format(R));
        Observer.Observe('c_read_eos', Format(Ins.EOS()));
        Observer.Expect('a_ret', '4');
        Observer.Expect('a_bytes', '4:00000000');
        Observer.Expect('a_read_n', '4');
        Observer.Expect('a_read_v', 'A');
        Observer.Expect('a_read_eos', 'Yes');
        Observer.Expect('c_ret', '4');
        Observer.Expect('c_bytes', '4:02000000');
        Observer.Expect('c_read_n', '4');
        Observer.Expect('c_read_v', 'C');
        Observer.Expect('c_read_eos', 'Yes');
        Observer.Verify();
    end;
}
