// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), LT P89 Helper (74627)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74643 "LT P89 Stream Numbers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpInteger(V: Integer): Text
    var
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Rec.Modify();
        exit(Helper.Dump(Rec));
    end;

    [TryFunction]
    local procedure TryReadInteger(var Ins: InStream; var V: Integer; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadInteger(var Ins: InStream; var V: Integer): Text
    var
        N: Integer;
    begin
        if TryReadInteger(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Integer_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 0;
        Observer.Observe('v1_zero', DumpInteger(V));
        V := 305419896;
        Observer.Observe('v2_0x12345678', DumpInteger(V));
        V := -1;
        Observer.Observe('v3_minus1', DumpInteger(V));
        V := 256;
        Observer.Observe('v4_256', DumpInteger(V));
        V := -2147483647 - 1;
        Observer.Observe('v5_min', DumpInteger(V));
        V := 2147483647;
        Observer.Observe('v6_max', DumpInteger(V));
        Observer.Expect('v1_zero', '4:00000000');
        Observer.Expect('v2_0x12345678', '4:78563412');
        Observer.Expect('v3_minus1', '4:FFFFFFFF');
        Observer.Expect('v4_256', '4:00010000');
        Observer.Expect('v5_min', '4:00000080');
        Observer.Expect('v6_max', '4:FFFFFF7F');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Integer;
        R2: Integer;
        R3: Integer;
        V: Integer;
    begin
        Helper.Fresh(Rec);
        V := 305419896;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadInteger(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadInteger(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadInteger(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadInteger(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '8');
        Observer.Expect('read1', 'ok n=4');
        Observer.Expect('value1', '305419896');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=4');
        Observer.Expect('value2', '305419896');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', '0');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', '0');
        Observer.Verify();
    end;

    local procedure DumpDecimal(V: Decimal): Text
    var
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Rec.Modify();
        exit(Helper.Dump(Rec));
    end;

    [TryFunction]
    local procedure TryReadDecimal(var Ins: InStream; var V: Decimal; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadDecimal(var Ins: InStream; var V: Decimal): Text
    var
        N: Integer;
    begin
        if TryReadDecimal(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Decimal_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Decimal;
    begin
        V := 0;
        Observer.Observe('v1_zero', DumpDecimal(V));
        V := 1.5;
        Observer.Observe('v2_1_5', DumpDecimal(V));
        V := -1.5;
        Observer.Observe('v3_minus1_5', DumpDecimal(V));
        V := 0.00001;
        Observer.Observe('v4_small', DumpDecimal(V));
        V := 123456789.123456789;
        Observer.Observe('v5_big', DumpDecimal(V));
        V := 1;
        Observer.Observe('v6_one', DumpDecimal(V));
        Observer.Expect('v1_zero', '12:000000000000000000000000');
        Observer.Expect('v2_1_5', '12:400000000000000000150000');
        Observer.Expect('v3_minus1_5', '12:C00000000000000000150000');
        Observer.Expect('v4_small', '12:3B0000000000000000100000');
        Observer.Expect('v5_big', '12:488967452391785634120000');
        Observer.Expect('v6_one', '12:400000000000000000100000');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Decimal;
        R2: Decimal;
        R3: Decimal;
        V: Decimal;
    begin
        Helper.Fresh(Rec);
        V := 1.5;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadDecimal(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadDecimal(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadDecimal(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadDecimal(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '24');
        Observer.Expect('read1', 'ok n=12');
        Observer.Expect('value1', '1.5');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=12');
        Observer.Expect('value2', '1.5');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', '0');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', '0');
        Observer.Verify();
    end;

    local procedure DumpBoolean(V: Boolean): Text
    var
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Rec.Modify();
        exit(Helper.Dump(Rec));
    end;

    [TryFunction]
    local procedure TryReadBoolean(var Ins: InStream; var V: Boolean; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadBoolean(var Ins: InStream; var V: Boolean): Text
    var
        N: Integer;
    begin
        if TryReadBoolean(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Boolean_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        V := false;
        Observer.Observe('v1_false', DumpBoolean(V));
        V := true;
        Observer.Observe('v2_true', DumpBoolean(V));
        Observer.Expect('v1_false', '4:00000000');
        Observer.Expect('v2_true', '4:01000000');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Boolean;
        R2: Boolean;
        R3: Boolean;
        V: Boolean;
    begin
        Helper.Fresh(Rec);
        V := true;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadBoolean(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadBoolean(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadBoolean(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadBoolean(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '8');
        Observer.Expect('read1', 'ok n=4');
        Observer.Expect('value1', 'Yes');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=4');
        Observer.Expect('value2', 'Yes');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', 'No');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', 'No');
        Observer.Verify();
    end;

    local procedure DumpBigInteger(V: BigInteger): Text
    var
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Rec.Modify();
        exit(Helper.Dump(Rec));
    end;

    [TryFunction]
    local procedure TryReadBigInteger(var Ins: InStream; var V: BigInteger; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadBigInteger(var Ins: InStream; var V: BigInteger): Text
    var
        N: Integer;
    begin
        if TryReadBigInteger(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure BigInteger_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        V := 0;
        Observer.Observe('v1_zero', DumpBigInteger(V));
        V := 1;
        Observer.Observe('v2_one', DumpBigInteger(V));
        V := -1;
        Observer.Observe('v3_minus1', DumpBigInteger(V));
        Evaluate(V, '3000000000');
        Observer.Observe('v4_3e9', DumpBigInteger(V));
        Evaluate(V, '-9223372036854775808');
        Observer.Observe('v5_min', DumpBigInteger(V));
        Evaluate(V, '9223372036854775807');
        Observer.Observe('v6_max', DumpBigInteger(V));
        Observer.Expect('v1_zero', '8:0000000000000000');
        Observer.Expect('v2_one', '8:0100000000000000');
        Observer.Expect('v3_minus1', '8:FFFFFFFFFFFFFFFF');
        Observer.Expect('v4_3e9', '8:005ED0B200000000');
        Observer.Expect('v5_min', '8:0000000000000080');
        Observer.Expect('v6_max', '8:FFFFFFFFFFFFFF7F');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: BigInteger;
        R2: BigInteger;
        R3: BigInteger;
        V: BigInteger;
    begin
        Helper.Fresh(Rec);
        V := 1;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadBigInteger(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadBigInteger(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadBigInteger(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadBigInteger(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '16');
        Observer.Expect('read1', 'ok n=8');
        Observer.Expect('value1', '1');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=8');
        Observer.Expect('value2', '1');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', '0');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', '0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWriteLen(var Out: OutStream; V: Integer; Len: Integer)
    begin
        Out.Write(V, Len);
    end;

    [Test]
    procedure Integer_WriteWithLength()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Lens: List of [Integer];
        Len: Integer;
        Res: Text;
    begin
        Lens.Add(0);
        Lens.Add(1);
        Lens.Add(2);
        Lens.Add(4);
        Lens.Add(8);
        Lens.Add(-1);
        foreach Len in Lens do begin
            Helper.Fresh(Rec);
            Rec.Data.CreateOutStream(Out);
            if TryWriteLen(Out, 305419896, Len) then
                Res := 'ok'
            else
                Res := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
            Rec.Modify();
            Observer.Observe('len' + Format(Len) + '_result', Res);
            Observer.Observe('len' + Format(Len) + '_bytes', Helper.Dump(Rec));
        end;
        Observer.Expect('len0_result', 'error:An invalid length 0 was specified in stream function. 4 was expected.|InvalidStreamLength');
        Observer.Expect('len0_bytes', '0:');
        Observer.Expect('len1_result', 'error:An invalid length 1 was specified in stream function. 4 was expected.|InvalidStreamLength');
        Observer.Expect('len1_bytes', '0:');
        Observer.Expect('len2_result', 'error:An invalid length 2 was specified in stream function. 4 was expected.|InvalidStreamLength');
        Observer.Expect('len2_bytes', '0:');
        Observer.Expect('len4_result', 'ok');
        Observer.Expect('len4_bytes', '4:78563412');
        Observer.Expect('len8_result', 'error:An invalid length 8 was specified in stream function. 4 was expected.|InvalidStreamLength');
        Observer.Expect('len8_bytes', '0:');
        Observer.Expect('len-1_result', 'error:An invalid length -1 was specified in stream function. 4 was expected.|InvalidStreamLength');
        Observer.Expect('len-1_bytes', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure Mixed_SequenceOfTypes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        I: Integer;
        D: Decimal;
        B: Boolean;
        Bg: BigInteger;
        I2: Integer;
        D2: Decimal;
        B2: Boolean;
        Bg2: BigInteger;
    begin
        Helper.Fresh(Rec);
        I := 7;
        D := 2.25;
        B := true;
        Bg := 99;
        Rec.Data.CreateOutStream(Out);
        Out.Write(I);
        Out.Write(D);
        Out.Write(B);
        Out.Write(Bg);
        Rec.Modify();
        Observer.Observe('bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Ins.Read(I2);
        Ins.Read(D2);
        Ins.Read(B2);
        Ins.Read(Bg2);
        Observer.Observe('int', Format(I2));
        Observer.Observe('dec', Format(D2));
        Observer.Observe('bool', Format(B2));
        Observer.Observe('bigint', Format(Bg2));
        Observer.Observe('eos', Format(Ins.EOS()));
        Observer.Expect('bytes', '28:07000000400000000000000050220000010000006300000000000000');
        Observer.Expect('int', '7');
        Observer.Expect('dec', '2.25');
        Observer.Expect('bool', 'Yes');
        Observer.Expect('bigint', '99');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

}
