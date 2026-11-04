// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P102 Rec (71615), LT P102 Helper (71616)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71618 "LT P102 Write DateGuid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P102_Date()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: Date;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := DMY2Date(1,2,2020);
        Observer.Observe('d_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('d_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0D;
        Observer.Observe('undef_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('undef_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := DMY2Date(1,2,2020);
        asserterror Observer.Observe('len2_ret', Format(Out.Write(V, 2)));
        Observer.ObserveError('af36');
        Rec.Modify();
        asserterror Observer.Observe('len2_bytes', Helper.Dump(Rec));
        Observer.ObserveError('af39');
        Observer.Expect('d_ret', '4');
        Observer.Expect('d_bytes', '4:3B841600');
        Observer.Expect('undef_ret', '4');
        Observer.Expect('undef_bytes', '4:00000000');
        Observer.Expect('af36|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('af36|code', 'InvalidStreamLength');
        Observer.Expect('af39|text', 'The LT P102 Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af39|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P102_Time()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: Time;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 123456T;
        Observer.Observe('t_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('t_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0T;
        Observer.Observe('undef_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('undef_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 123456T;
        asserterror Observer.Observe('len2_ret', Format(Out.Write(V, 2)));
        Observer.ObserveError('af67');
        Rec.Modify();
        asserterror Observer.Observe('len2_bytes', Helper.Dump(Rec));
        Observer.ObserveError('af71');
        Observer.Expect('t_ret', '4');
        Observer.Expect('t_bytes', '4:8129B302');
        Observer.Expect('undef_ret', '4');
        Observer.Expect('undef_bytes', '4:00000000');
        Observer.Expect('af67|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('af67|code', 'InvalidStreamLength');
        Observer.Expect('af71|text', 'The LT P102 Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af71|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P102_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: DateTime;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := CreateDateTime(DMY2Date(1,2,2020), 123456T);
        Observer.Observe('dt_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('dt_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0DT;
        Observer.Observe('undef_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('undef_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := CreateDateTime(DMY2Date(1,2,2020), 123456T);
        asserterror Observer.Observe('len4_ret', Format(Out.Write(V, 4)));
        Observer.ObserveError('af98');
        Rec.Modify();
        asserterror Observer.Observe('len4_bytes', Helper.Dump(Rec));
        Observer.ObserveError('af103');
        Observer.Expect('dt_ret', '8');
        Observer.Expect('dt_bytes', '8:8195C36FFA390000');
        Observer.Expect('undef_ret', '8');
        Observer.Expect('undef_bytes', '8:0000000000000000');
        Observer.Expect('af98|text', 'An invalid length 4 was specified in stream function. 8 was expected.');
        Observer.Expect('af98|code', 'InvalidStreamLength');
        Observer.Expect('af103|text', 'The LT P102 Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af103|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P102_Duration()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: Duration;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 90000;
        Observer.Observe('dur_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('dur_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0;
        Observer.Observe('zero_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('zero_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 90000;
        asserterror Observer.Observe('len4_ret', Format(Out.Write(V, 4)));
        Observer.ObserveError('af129');
        Rec.Modify();
        asserterror Observer.Observe('len4_bytes', Helper.Dump(Rec));
        Observer.ObserveError('af135');
        Observer.Expect('dur_ret', '8');
        Observer.Expect('dur_bytes', '8:905F010000000000');
        Observer.Expect('zero_ret', '8');
        Observer.Expect('zero_bytes', '8:0000000000000000');
        Observer.Expect('af129|text', 'An invalid length 4 was specified in stream function. 8 was expected.');
        Observer.Expect('af129|code', 'InvalidStreamLength');
        Observer.Expect('af135|text', 'The LT P102 Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af135|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P102_DateFormula()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        V: DateFormula;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Evaluate(V, '<1D+CM>');
        Observer.Observe('df_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('df_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Clear(V);
        Observer.Observe('empty_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('empty_bytes', Helper.Dump(Rec));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Evaluate(V, '<1D>');
        asserterror Observer.Observe('len2_ret', Format(Out.Write(V, 2)));
        Observer.ObserveError('af160');
        Rec.Modify();
        asserterror Observer.Observe('len2_bytes', Helper.Dump(Rec));
        Observer.ObserveError('af167');
        Observer.Expect('df_ret', '32');
        Observer.Expect('df_bytes', '32:31022B0105000000000000000000000000000000000000000000000000000000');
        Observer.Expect('empty_ret', '32');
        Observer.Expect('empty_bytes', '32:0000000000000000000000000000000000000000000000000000000000000000');
        Observer.Expect('af160|text', 'An invalid length 2 was specified in stream function. 32 was expected.');
        Observer.Expect('af160|code', 'InvalidStreamLength');
        Observer.Expect('af167|text', 'The LT P102 Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af167|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

}
