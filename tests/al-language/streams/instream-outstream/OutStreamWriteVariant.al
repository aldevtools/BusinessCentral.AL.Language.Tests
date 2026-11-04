// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT OutIn Rec (71751), LT OutIn Helper (71752)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71756 "LT OutIn Write Variant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P191_Variant_Integer_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Variant;
        R: Integer;
    begin
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
        V := 0;
        Observer.Observe('zero_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('zero_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('zero_read_n', Format(Ins.Read(R)));
        Observer.Observe('zero_read_v', Format(R));
        Observer.Observe('zero_read_eos', Format(Ins.EOS()));
        Observer.Expect('n258_ret', '4');
        Observer.Expect('n258_bytes', '4:02010000');
        Observer.Expect('n258_read_n', '4');
        Observer.Expect('n258_read_v', '258');
        Observer.Expect('n258_read_eos', 'Yes');
        Observer.Expect('zero_ret', '4');
        Observer.Expect('zero_bytes', '4:00000000');
        Observer.Expect('zero_read_n', '4');
        Observer.Expect('zero_read_v', '0');
        Observer.Expect('zero_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Variant_Text_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Variant;
        R: Text;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abc';
        Observer.Observe('abc_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('abc_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('abc_read_n', Format(Ins.Read(R)));
        Observer.Observe('abc_read_v', Format(R));
        Observer.Observe('abc_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := '';
        Observer.Observe('empty_ret', Format(Out.Write(V)));
        Rec.Modify();
        Observer.Observe('empty_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('empty_read_n', Format(Ins.Read(R)));
        Observer.Observe('empty_read_v', Format(R));
        Observer.Observe('empty_read_eos', Format(Ins.EOS()));
        Observer.Expect('abc_ret', '4');
        Observer.Expect('abc_bytes', '4:61626300');
        Observer.Expect('abc_read_n', '4');
        Observer.Expect('abc_read_v', 'abc');
        Observer.Expect('abc_read_eos', 'Yes');
        Observer.Expect('empty_ret', '1');
        Observer.Expect('empty_bytes', '1:00');
        Observer.Expect('empty_read_n', '1');
        Observer.Expect('empty_read_v', '');
        Observer.Expect('empty_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Variant_Boolean_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Variant;
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
        Observer.Expect('true_ret', '4');
        Observer.Expect('true_bytes', '4:01000000');
        Observer.Expect('true_read_n', '4');
        Observer.Expect('true_read_v', 'Yes');
        Observer.Expect('true_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Variant_Decimal_Write_NoLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Variant;
        R: Decimal;
    begin
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
        Observer.Expect('p15_ret', '12');
        Observer.Expect('p15_bytes', '12:400000000000000000150000');
        Observer.Expect('p15_read_n', '12');
        Observer.Expect('p15_read_v', '1.5');
        Observer.Expect('p15_read_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P191_Variant_Text_Write_WithLength_BytesAndReadBack()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
V: Variant;
        R: Text;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcdef';
        Observer.Observe('len0_ret', Format(Out.Write(V, 0)));
        Rec.Modify();
        Observer.Observe('len0_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('len0_read_n', Format(Ins.Read(R)));
        Observer.Observe('len0_read_v', Format(R));
        Observer.Observe('len0_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcdef';
        Observer.Observe('len2_ret', Format(Out.Write(V, 2)));
        Rec.Modify();
        Observer.Observe('len2_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('len2_read_n', Format(Ins.Read(R)));
        Observer.Observe('len2_read_v', Format(R));
        Observer.Observe('len2_read_eos', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        V := 'abcdef';
        Observer.Observe('len9_ret', Format(Out.Write(V, 9)));
        Rec.Modify();
        Observer.Observe('len9_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('len9_read_n', Format(Ins.Read(R)));
        Observer.Observe('len9_read_v', Format(R));
        Observer.Observe('len9_read_eos', Format(Ins.EOS()));
        Observer.Expect('len0_ret', '1');
        Observer.Expect('len0_bytes', '1:00');
        Observer.Expect('len0_read_n', '1');
        Observer.Expect('len0_read_v', '');
        Observer.Expect('len0_read_eos', 'Yes');
        Observer.Expect('len2_ret', '3');
        Observer.Expect('len2_bytes', '3:616200');
        Observer.Expect('len2_read_n', '3');
        Observer.Expect('len2_read_v', 'ab');
        Observer.Expect('len2_read_eos', 'Yes');
        Observer.Expect('len9_ret', '7');
        Observer.Expect('len9_bytes', '7:61626364656600');
        Observer.Expect('len9_read_n', '7');
        Observer.Expect('len9_read_v', 'abcdef');
        Observer.Expect('len9_read_eos', 'Yes');
        Observer.Verify();
    end;
}
