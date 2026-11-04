// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT OutIn Rec (71751), LT OutIn Helper (71752)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71753 "LT OutIn Write Numbers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P191_BigInteger_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: BigInteger;
        R: BigInteger;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0;
        Observer.Observe('zero_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('zero_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('zero_read_n', Format(Ins.Read(R)));
        Observer.Observe('zero_read_v', Format(R));
        Observer.Observe('zero_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 258;
        Observer.Observe('n258_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('n258_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('n258_read_n', Format(Ins.Read(R)));
        Observer.Observe('n258_read_v', Format(R));
        Observer.Observe('n258_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := -1;
        Observer.Observe('neg1_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('neg1_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('neg1_read_n', Format(Ins.Read(R)));
        Observer.Observe('neg1_read_v', Format(R));
        Observer.Observe('neg1_read_eos', Format(Ins.EOS()));
        Observer.Expect('zero_ret', '8');
        Observer.Expect('zero_bytes', '8:0000000000000000');
        Observer.Expect('zero_read_n', '8');
        Observer.Expect('zero_read_v', '0');
        Observer.Expect('zero_read_eos', 'Yes');
        Observer.Expect('n258_ret', '8');
        Observer.Expect('n258_bytes', '8:0201000000000000');
        Observer.Expect('n258_read_n', '8');
        Observer.Expect('n258_read_v', '258');
        Observer.Expect('n258_read_eos', 'Yes');
        Observer.Expect('neg1_ret', '8');
        Observer.Expect('neg1_bytes', '8:FFFFFFFFFFFFFFFF');
        Observer.Expect('neg1_read_n', '8');
        Observer.Expect('neg1_read_v', '-1');
        Observer.Expect('neg1_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Boolean_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Boolean;
        R: Boolean;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := true;
        Observer.Observe('true_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('true_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('true_read_n', Format(Ins.Read(R)));
        Observer.Observe('true_read_v', Format(R));
        Observer.Observe('true_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := false;
        Observer.Observe('false_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('false_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('false_read_n', Format(Ins.Read(R)));
        Observer.Observe('false_read_v', Format(R));
        Observer.Observe('false_read_eos', Format(Ins.EOS()));
        Observer.Expect('true_ret', '4');
        Observer.Expect('true_bytes', '4:01000000');
        Observer.Expect('true_read_n', '4');
        Observer.Expect('true_read_v', 'Yes');
        Observer.Expect('true_read_eos', 'Yes');
        Observer.Expect('false_ret', '4');
        Observer.Expect('false_bytes', '4:00000000');
        Observer.Expect('false_read_n', '4');
        Observer.Expect('false_read_v', 'No');
        Observer.Expect('false_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Byte_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Byte;
        R: Byte;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0;
        Observer.Observe('zero_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('zero_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('zero_read_n', Format(Ins.Read(R)));
        Observer.Observe('zero_read_v', Format(R));
        Observer.Observe('zero_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 255;
        Observer.Observe('n255_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('n255_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('n255_read_n', Format(Ins.Read(R)));
        Observer.Observe('n255_read_v', Format(R));
        Observer.Observe('n255_read_eos', Format(Ins.EOS()));
        Observer.Expect('zero_ret', '1');
        Observer.Expect('zero_bytes', '1:00');
        Observer.Expect('zero_read_n', '1');
        Observer.Expect('zero_read_v', '\u0000');
        Observer.Expect('zero_read_eos', 'Yes');
        Observer.Expect('n255_ret', '1');
        Observer.Expect('n255_bytes', '1:FF');
        Observer.Expect('n255_read_n', '1');
        Observer.Expect('n255_read_v', ' ');
        Observer.Expect('n255_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Decimal_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Decimal;
        R: Decimal;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0;
        Observer.Observe('zero_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('zero_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('zero_read_n', Format(Ins.Read(R)));
        Observer.Observe('zero_read_v', Format(R));
        Observer.Observe('zero_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 1.5;
        Observer.Observe('p15_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('p15_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('p15_read_n', Format(Ins.Read(R)));
        Observer.Observe('p15_read_v', Format(R));
        Observer.Observe('p15_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := -0.25;
        Observer.Observe('neg025_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('neg025_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('neg025_read_n', Format(Ins.Read(R)));
        Observer.Observe('neg025_read_v', Format(R));
        Observer.Observe('neg025_read_eos', Format(Ins.EOS()));
        Observer.Expect('zero_ret', '12');
        Observer.Expect('zero_bytes', '12:000000000000000000000000');
        Observer.Expect('zero_read_n', '12');
        Observer.Expect('zero_read_v', '0');
        Observer.Expect('zero_read_eos', 'Yes');
        Observer.Expect('p15_ret', '12');
        Observer.Expect('p15_bytes', '12:400000000000000000150000');
        Observer.Expect('p15_read_n', '12');
        Observer.Expect('p15_read_v', '1.5');
        Observer.Expect('p15_read_eos', 'Yes');
        Observer.Expect('neg025_ret', '12');
        Observer.Expect('neg025_bytes', '12:BF0000000000000000250000');
        Observer.Expect('neg025_read_n', '12');
        Observer.Expect('neg025_read_v', '-0.25');
        Observer.Expect('neg025_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Guid_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Guid;
        R: Guid;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Clear(V);
        Observer.Observe('null_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('null_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('null_read_n', Format(Ins.Read(R)));
        Observer.Observe('null_read_v', Format(R));
        Observer.Observe('null_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Evaluate(V, '{01020304-0506-0708-090A-0B0C0D0E0F10}');
        Observer.Observe('val_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('val_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('val_read_n', Format(Ins.Read(R)));
        Observer.Observe('val_read_v', Format(R));
        Observer.Observe('val_read_eos', Format(Ins.EOS()));
        Observer.Expect('null_ret', '16');
        Observer.Expect('null_bytes', '16:00000000000000000000000000000000');
        Observer.Expect('null_read_n', '16');
        Observer.Expect('null_read_v', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('null_read_eos', 'Yes');
        Observer.Expect('val_ret', '16');
        Observer.Expect('val_bytes', '16:0403020106050807090A0B0C0D0E0F10');
        Observer.Expect('val_read_n', '16');
        Observer.Expect('val_read_v', '{01020304-0506-0708-090A-0B0C0D0E0F10}');
        Observer.Expect('val_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Integer_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Integer;
        R: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 0;
        Observer.Observe('zero_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('zero_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('zero_read_n', Format(Ins.Read(R)));
        Observer.Observe('zero_read_v', Format(R));
        Observer.Observe('zero_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 258;
        Observer.Observe('n258_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('n258_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('n258_read_n', Format(Ins.Read(R)));
        Observer.Observe('n258_read_v', Format(R));
        Observer.Observe('n258_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := -1;
        Observer.Observe('neg1_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('neg1_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('neg1_read_n', Format(Ins.Read(R)));
        Observer.Observe('neg1_read_v', Format(R));
        Observer.Observe('neg1_read_eos', Format(Ins.EOS()));
        Observer.Expect('zero_ret', '4');
        Observer.Expect('zero_bytes', '4:00000000');
        Observer.Expect('zero_read_n', '4');
        Observer.Expect('zero_read_v', '0');
        Observer.Expect('zero_read_eos', 'Yes');
        Observer.Expect('n258_ret', '4');
        Observer.Expect('n258_bytes', '4:02010000');
        Observer.Expect('n258_read_n', '4');
        Observer.Expect('n258_read_v', '258');
        Observer.Expect('n258_read_eos', 'Yes');
        Observer.Expect('neg1_ret', '4');
        Observer.Expect('neg1_bytes', '4:FFFFFFFF');
        Observer.Expect('neg1_read_n', '4');
        Observer.Expect('neg1_read_v', '-1');
        Observer.Expect('neg1_read_eos', 'Yes');
        Observer.Verify();
    end;
}
