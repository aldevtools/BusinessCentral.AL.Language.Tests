// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-read-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT OutIn Rec (71751), LT OutIn Helper (71752)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71757 "LT OutIn Read Length"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P191_BigInteger_Read_NoLength_AndSecondReadAtEnd()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: BigInteger;
        R: BigInteger;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 258;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('nolen_n', Format(Ins.Read(R)));
        Observer.Observe('nolen_v', Format(R));
        Observer.Observe('nolen_eos', Format(Ins.EOS()));
        Observer.Observe('nolen_pos', Format(Ins.Position()));
        Observer.Observe('second_n', Format(Ins.Read(R)));
        Observer.Observe('second_v', Format(R));
        Observer.Observe('second_eos', Format(Ins.EOS()));
        Observer.Expect('nolen_n', '8');
        Observer.Expect('nolen_v', '258');
        Observer.Expect('nolen_eos', 'Yes');
        Observer.Expect('nolen_pos', '9');
        Observer.Expect('second_n', '0');
        Observer.Expect('second_v', '0');
        Observer.Expect('second_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_BigInteger_Read_ZeroValue()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: BigInteger;
        R: BigInteger;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 0;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('zero_nolen_n', Format(Ins.Read(R)));
        Observer.Observe('zero_nolen_v', Format(R));
        Observer.Observe('zero_nolen_eos', Format(Ins.EOS()));
        Observer.Observe('zero_nolen_pos', Format(Ins.Position()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 0;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        asserterror Observer.Observe('zero_len1_n', Format(Ins.Read(R, 1)));
        Observer.ObserveError('af147');
        Observer.Observe('zero_len1_v', Format(R));
        Observer.Observe('zero_len1_eos', Format(Ins.EOS()));
        Observer.Observe('zero_len1_pos', Format(Ins.Position()));
        Observer.Expect('zero_nolen_n', '8');
        Observer.Expect('zero_nolen_v', '0');
        Observer.Expect('zero_nolen_eos', 'Yes');
        Observer.Expect('zero_nolen_pos', '9');
        Observer.Expect('af147|text', 'An invalid length 1 was specified in stream function. 8 was expected.');
        Observer.Expect('af147|code', 'InvalidStreamLength');
        Observer.Expect('zero_len1_v', '0');
        Observer.Expect('zero_len1_eos', 'No');
        Observer.Expect('zero_len1_pos', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Boolean_ReadWithLength_FromWrittenBytes()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Boolean;
        R: Boolean;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := true;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        asserterror Observer.Observe('len1_n', Format(Ins.Read(R, 1)));
        Observer.ObserveError('af174');
        Observer.Observe('len1_v', Format(R));
        Observer.Observe('len1_eos', Format(Ins.EOS()));
        Observer.Observe('len1_pos', Format(Ins.Position()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := true;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        asserterror Observer.Observe('len2_n', Format(Ins.Read(R, 2)));
        Observer.ObserveError('af188');
        Observer.Observe('len2_v', Format(R));
        Observer.Observe('len2_eos', Format(Ins.EOS()));
        Observer.Observe('len2_pos', Format(Ins.Position()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := true;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('len4_n', Format(Ins.Read(R, 4)));
        Observer.Observe('len4_v', Format(R));
        Observer.Observe('len4_eos', Format(Ins.EOS()));
        Observer.Observe('len4_pos', Format(Ins.Position()));
        Observer.Expect('af174|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('af174|code', 'InvalidStreamLength');
        Observer.Expect('len1_v', 'No');
        Observer.Expect('len1_eos', 'No');
        Observer.Expect('len1_pos', '1');
        Observer.Expect('af188|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('af188|code', 'InvalidStreamLength');
        Observer.Expect('len2_v', 'No');
        Observer.Expect('len2_eos', 'No');
        Observer.Expect('len2_pos', '1');
        Observer.Expect('len4_n', '4');
        Observer.Expect('len4_v', 'Yes');
        Observer.Expect('len4_eos', 'Yes');
        Observer.Expect('len4_pos', '5');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Boolean_Read_NoLength_AndSecondReadAtEnd()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Boolean;
        R: Boolean;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := true;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('nolen_n', Format(Ins.Read(R)));
        Observer.Observe('nolen_v', Format(R));
        Observer.Observe('nolen_eos', Format(Ins.EOS()));
        Observer.Observe('nolen_pos', Format(Ins.Position()));
        Observer.Observe('second_n', Format(Ins.Read(R)));
        Observer.Observe('second_v', Format(R));
        Observer.Observe('second_eos', Format(Ins.EOS()));
        Observer.Expect('nolen_n', '4');
        Observer.Expect('nolen_v', 'Yes');
        Observer.Expect('nolen_eos', 'Yes');
        Observer.Expect('nolen_pos', '5');
        Observer.Expect('second_n', '0');
        Observer.Expect('second_v', 'No');
        Observer.Expect('second_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Boolean_Read_ZeroValue()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Boolean;
        R: Boolean;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := false;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('zero_nolen_n', Format(Ins.Read(R)));
        Observer.Observe('zero_nolen_v', Format(R));
        Observer.Observe('zero_nolen_eos', Format(Ins.EOS()));
        Observer.Observe('zero_nolen_pos', Format(Ins.Position()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := false;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        asserterror Observer.Observe('zero_len1_n', Format(Ins.Read(R, 1)));
        Observer.ObserveError('af266');
        Observer.Observe('zero_len1_v', Format(R));
        Observer.Observe('zero_len1_eos', Format(Ins.EOS()));
        Observer.Observe('zero_len1_pos', Format(Ins.Position()));
        Observer.Expect('zero_nolen_n', '4');
        Observer.Expect('zero_nolen_v', 'No');
        Observer.Expect('zero_nolen_eos', 'Yes');
        Observer.Expect('zero_nolen_pos', '5');
        Observer.Expect('af266|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('af266|code', 'InvalidStreamLength');
        Observer.Expect('zero_len1_v', 'No');
        Observer.Expect('zero_len1_eos', 'No');
        Observer.Expect('zero_len1_pos', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Decimal_Read_NoLength_AndSecondReadAtEnd()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Decimal;
        R: Decimal;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 1.5;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('nolen_n', Format(Ins.Read(R)));
        Observer.Observe('nolen_v', Format(R));
        Observer.Observe('nolen_eos', Format(Ins.EOS()));
        Observer.Observe('nolen_pos', Format(Ins.Position()));
        Observer.Observe('second_n', Format(Ins.Read(R)));
        Observer.Observe('second_v', Format(R));
        Observer.Observe('second_eos', Format(Ins.EOS()));
        Observer.Expect('nolen_n', '12');
        Observer.Expect('nolen_v', '1.5');
        Observer.Expect('nolen_eos', 'Yes');
        Observer.Expect('nolen_pos', '13');
        Observer.Expect('second_n', '0');
        Observer.Expect('second_v', '0');
        Observer.Expect('second_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Decimal_Read_ZeroValue()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Decimal;
        R: Decimal;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 0;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('zero_nolen_n', Format(Ins.Read(R)));
        Observer.Observe('zero_nolen_v', Format(R));
        Observer.Observe('zero_nolen_eos', Format(Ins.EOS()));
        Observer.Observe('zero_nolen_pos', Format(Ins.Position()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 0;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        asserterror Observer.Observe('zero_len1_n', Format(Ins.Read(R, 1)));
        Observer.ObserveError('af397');
        Observer.Observe('zero_len1_v', Format(R));
        Observer.Observe('zero_len1_eos', Format(Ins.EOS()));
        Observer.Observe('zero_len1_pos', Format(Ins.Position()));
        Observer.Expect('zero_nolen_n', '12');
        Observer.Expect('zero_nolen_v', '0');
        Observer.Expect('zero_nolen_eos', 'Yes');
        Observer.Expect('zero_nolen_pos', '13');
        Observer.Expect('af397|text', 'An invalid length 1 was specified in stream function. 12 was expected.');
        Observer.Expect('af397|code', 'InvalidStreamLength');
        Observer.Expect('zero_len1_v', '0');
        Observer.Expect('zero_len1_eos', 'No');
        Observer.Expect('zero_len1_pos', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Guid_Read_NoLength_AndSecondReadAtEnd()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Guid;
        R: Guid;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Evaluate(W, '{01020304-0506-0708-090A-0B0C0D0E0F10}');
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('nolen_n', Format(Ins.Read(R)));
        Observer.Observe('nolen_v', Format(R));
        Observer.Observe('nolen_eos', Format(Ins.EOS()));
        Observer.Observe('nolen_pos', Format(Ins.Position()));
        Observer.Observe('second_n', Format(Ins.Read(R)));
        Observer.Observe('second_v', Format(R));
        Observer.Observe('second_eos', Format(Ins.EOS()));
        Observer.Expect('nolen_n', '16');
        Observer.Expect('nolen_v', '{01020304-0506-0708-090A-0B0C0D0E0F10}');
        Observer.Expect('nolen_eos', 'Yes');
        Observer.Expect('nolen_pos', '17');
        Observer.Expect('second_n', '0');
        Observer.Expect('second_v', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('second_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Guid_Read_ZeroValue()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Guid;
        R: Guid;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Clear(W);
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('zero_nolen_n', Format(Ins.Read(R)));
        Observer.Observe('zero_nolen_v', Format(R));
        Observer.Observe('zero_nolen_eos', Format(Ins.EOS()));
        Observer.Observe('zero_nolen_pos', Format(Ins.Position()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Clear(W);
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        asserterror Observer.Observe('zero_len1_n', Format(Ins.Read(R, 1)));
        Observer.ObserveError('af540');
        Observer.Observe('zero_len1_v', Format(R));
        Observer.Observe('zero_len1_eos', Format(Ins.EOS()));
        Observer.Observe('zero_len1_pos', Format(Ins.Position()));
        Observer.Expect('zero_nolen_n', '16');
        Observer.Expect('zero_nolen_v', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('zero_nolen_eos', 'Yes');
        Observer.Expect('zero_nolen_pos', '17');
        Observer.Expect('af540|text', 'An invalid length 1 was specified in stream function. 16 was expected.');
        Observer.Expect('af540|code', 'InvalidStreamLength');
        Observer.Expect('zero_len1_v', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('zero_len1_eos', 'No');
        Observer.Expect('zero_len1_pos', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Integer_Read_NoLength_AndSecondReadAtEnd()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Integer;
        R: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 258;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('nolen_n', Format(Ins.Read(R)));
        Observer.Observe('nolen_v', Format(R));
        Observer.Observe('nolen_eos', Format(Ins.EOS()));
        Observer.Observe('nolen_pos', Format(Ins.Position()));
        Observer.Observe('second_n', Format(Ins.Read(R)));
        Observer.Observe('second_v', Format(R));
        Observer.Observe('second_eos', Format(Ins.EOS()));
        Observer.Expect('nolen_n', '4');
        Observer.Expect('nolen_v', '258');
        Observer.Expect('nolen_eos', 'Yes');
        Observer.Expect('nolen_pos', '5');
        Observer.Expect('second_n', '0');
        Observer.Expect('second_v', '0');
        Observer.Expect('second_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Integer_Read_ZeroValue()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
W: Integer;
        R: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 0;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        Observer.Observe('zero_nolen_n', Format(Ins.Read(R)));
        Observer.Observe('zero_nolen_v', Format(R));
        Observer.Observe('zero_nolen_eos', Format(Ins.EOS()));
        Observer.Observe('zero_nolen_pos', Format(Ins.Position()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 0;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Clear(R);
        asserterror Observer.Observe('zero_len1_n', Format(Ins.Read(R, 1)));
        Observer.ObserveError('af683');
        Observer.Observe('zero_len1_v', Format(R));
        Observer.Observe('zero_len1_eos', Format(Ins.EOS()));
        Observer.Observe('zero_len1_pos', Format(Ins.Position()));
        Observer.Expect('zero_nolen_n', '4');
        Observer.Expect('zero_nolen_v', '0');
        Observer.Expect('zero_nolen_eos', 'Yes');
        Observer.Expect('zero_nolen_pos', '5');
        Observer.Expect('af683|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('af683|code', 'InvalidStreamLength');
        Observer.Expect('zero_len1_v', '0');
        Observer.Expect('zero_len1_eos', 'No');
        Observer.Expect('zero_len1_pos', '1');
        Observer.Verify();
    end;
}
