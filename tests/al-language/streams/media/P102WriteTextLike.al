// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P102 Rec (71615), LT P102 Helper (71616)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71619 "LT P102 Write TextLike"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P102_Text()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: Text;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abc';
        Observer.Observe('abc_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('abc_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := '';
        Observer.Observe('empty_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('empty_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'a' + 'é€';
        Observer.Observe('uni_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('uni_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcd';
        Observer.Observe('len2_ret', Format(Out.Write(V, 2)));
        Rec.Modify();
        Observer.Observe('len2_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcd';
        Observer.Observe('len0_ret', Format(Out.Write(V, 0)));
        Rec.Modify();
        Observer.Observe('len0_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcd';
        Observer.Observe('len9_ret', Format(Out.Write(V, 9)));
        Rec.Modify();
        Observer.Observe('len9_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcd';
        Observer.Observe('lenneg_ret', Format(Out.Write(V, -1)));
        Rec.Modify();
        Observer.Observe('lenneg_bytes', Helper.Dump(Rec));
        Observer.Expect('abc_ret', '4');
        Observer.Expect('abc_bytes', '4:61626300');
        Observer.Expect('empty_ret', '1');
        Observer.Expect('empty_bytes', '1:00');
        Observer.Expect('uni_ret', '4');
        Observer.Expect('uni_bytes', '4:6182B100');
        Observer.Expect('len2_ret', '3');
        Observer.Expect('len2_bytes', '3:616200');
        Observer.Expect('len0_ret', '1');
        Observer.Expect('len0_bytes', '1:00');
        Observer.Expect('len9_ret', '5');
        Observer.Expect('len9_bytes', '5:6162636400');
        Observer.Expect('lenneg_ret', '5');
        Observer.Expect('lenneg_bytes', '5:6162636400');
        Observer.Verify();
    end;

    [Test]
    procedure P102_Code()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: Code[20];
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abc';
        Observer.Observe('abc_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('abc_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := '';
        Observer.Observe('empty_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('empty_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcd';
        Observer.Observe('len2_ret', Format(Out.Write(V, 2)));
        Rec.Modify();
        Observer.Observe('len2_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcd';
        Observer.Observe('len9_ret', Format(Out.Write(V, 9)));
        Rec.Modify();
        Observer.Observe('len9_bytes', Helper.Dump(Rec));
        Observer.Expect('abc_ret', '4');
        Observer.Expect('abc_bytes', '4:41424300');
        Observer.Expect('empty_ret', '1');
        Observer.Expect('empty_bytes', '1:00');
        Observer.Expect('len2_ret', '5');
        Observer.Expect('len2_bytes', '5:4142434400');
        Observer.Expect('len9_ret', '5');
        Observer.Expect('len9_bytes', '5:4142434400');
        Observer.Verify();
    end;

    [Test]
    procedure P102_Label()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: Label 'lab', Locked = true;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Observer.Observe('lab_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('lab_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Observer.Observe('len2_ret', Format(Out.Write(V, 2)));
        Rec.Modify();
        Observer.Observe('len2_bytes', Helper.Dump(Rec));
        Observer.Expect('lab_ret', '4');
        Observer.Expect('lab_bytes', '4:6C616200');
        Observer.Expect('len2_ret', '3');
        Observer.Expect('len2_bytes', '3:6C6100');
        Observer.Verify();
    end;

    [Test]
    procedure P102_TextConst()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: TextConst ENU = 'tc';
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Observer.Observe('tc_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('tc_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Observer.Observe('len1_ret', Format(Out.Write(V, 1)));
        Rec.Modify();
        Observer.Observe('len1_bytes', Helper.Dump(Rec));
        Observer.Expect('tc_ret', '3');
        Observer.Expect('tc_bytes', '3:746300');
        Observer.Expect('len1_ret', '2');
        Observer.Expect('len1_bytes', '2:7400');
        Observer.Verify();
    end;

}
