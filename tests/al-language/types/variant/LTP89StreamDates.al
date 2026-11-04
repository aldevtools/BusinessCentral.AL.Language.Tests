// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P89 Rec (74625), LT P89 Helper (74627)
// Probe: written against BC 29 (observation only; facts are measured later). P89
// BC versions: 29

codeunit 74644 "LT P89 Stream DateGuid"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure DumpDate(V: Date): Text
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
    local procedure TryReadDate(var Ins: InStream; var V: Date; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadDate(var Ins: InStream; var V: Date): Text
    var
        N: Integer;
    begin
        if TryReadDate(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Date_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Date;
    begin
        V := 0D;
        Observer.Observe('v1_zero', DumpDate(V));
        V := DMY2Date(29, 2, 2024);
        Observer.Observe('v2_leap', DumpDate(V));
        V := DMY2Date(1, 1, 1753);
        Observer.Observe('v3_min', DumpDate(V));
        V := DMY2Date(31, 12, 9999);
        Observer.Observe('v4_max', DumpDate(V));
        V := DMY2Date(1, 1, 2000);
        Observer.Observe('v5_y2k', DumpDate(V));
        Observer.Expect('v1_zero', '4:00000000');
        Observer.Expect('v2_leap', '4:DD8F1600');
        Observer.Expect('v3_min', '4:1F8A1300');
        Observer.Expect('v4_max', '4:91766F00');
        Observer.Expect('v5_y2k', '4:EB4A1600');
        Observer.Verify();
    end;

    [Test]
    procedure Date_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Date;
        R2: Date;
        R3: Date;
        V: Date;
    begin
        Helper.Fresh(Rec);
        V := DMY2Date(29, 2, 2024);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadDate(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadDate(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadDate(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadDate(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '8');
        Observer.Expect('read1', 'ok n=4');
        Observer.Expect('value1', '02/29/24');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=4');
        Observer.Expect('value2', '02/29/24');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', '');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', '');
        Observer.Verify();
    end;

    local procedure DumpTime(V: Time): Text
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
    local procedure TryReadTime(var Ins: InStream; var V: Time; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadTime(var Ins: InStream; var V: Time): Text
    var
        N: Integer;
    begin
        if TryReadTime(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Time_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Time;
    begin
        V := 0T;
        Observer.Observe('v1_zero', DumpTime(V));
        V := 120000T;
        Observer.Observe('v2_noon', DumpTime(V));
        V := 235959T;
        Observer.Observe('v3_last', DumpTime(V));
        V := 000001T;
        Observer.Observe('v4_one_second', DumpTime(V));
        Observer.Expect('v1_zero', '4:00000000');
        Observer.Expect('v2_noon', '4:012E9302');
        Observer.Expect('v3_last', '4:19582605');
        Observer.Expect('v4_one_second', '4:E9030000');
        Observer.Verify();
    end;

    [Test]
    procedure Time_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Time;
        R2: Time;
        R3: Time;
        V: Time;
    begin
        Helper.Fresh(Rec);
        V := 120000T;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadTime(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadTime(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadTime(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadTime(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '8');
        Observer.Expect('read1', 'ok n=4');
        Observer.Expect('value1', '12:00:00 PM');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=4');
        Observer.Expect('value2', '12:00:00 PM');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', '');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', '');
        Observer.Verify();
    end;

    local procedure DumpDateTime(V: DateTime): Text
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
    local procedure TryReadDateTime(var Ins: InStream; var V: DateTime; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadDateTime(var Ins: InStream; var V: DateTime): Text
    var
        N: Integer;
    begin
        if TryReadDateTime(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DateTime_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
    begin
        V := 0DT;
        Observer.Observe('v1_zero', DumpDateTime(V));
        V := CreateDateTime(DMY2Date(1, 1, 2000), 120000T);
        Observer.Observe('v2_y2k_noon', DumpDateTime(V));
        V := CreateDateTime(DMY2Date(29, 2, 2024), 235959T);
        Observer.Observe('v3_leap_last', DumpDateTime(V));
        V := CreateDateTime(DMY2Date(1, 1, 1753), 0T);
        Observer.Observe('v4_min', DumpDateTime(V));
        Observer.Expect('v1_zero', '8:0000000000000000');
        Observer.Expect('v2_y2k_noon', '8:013A67DC66390000');
        Observer.Expect('v3_leap_last', '8:19E05366183A0000');
        Observer.Expect('v4_min', '8:01640B0E50320000');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: DateTime;
        R2: DateTime;
        R3: DateTime;
        V: DateTime;
    begin
        Helper.Fresh(Rec);
        V := CreateDateTime(DMY2Date(1, 1, 2000), 120000T);
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadDateTime(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadDateTime(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadDateTime(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadDateTime(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '16');
        Observer.Expect('read1', 'ok n=8');
        Observer.Expect('value1', '01/01/00 12:00 PM');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=8');
        Observer.Expect('value2', '01/01/00 12:00 PM');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', '');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', '');
        Observer.Verify();
    end;

    local procedure DumpDuration(V: Duration): Text
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
    local procedure TryReadDuration(var Ins: InStream; var V: Duration; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadDuration(var Ins: InStream; var V: Duration): Text
    var
        N: Integer;
    begin
        if TryReadDuration(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Duration_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Duration;
    begin
        V := 0;
        Observer.Observe('v1_zero', DumpDuration(V));
        V := 1000;
        Observer.Observe('v2_1s', DumpDuration(V));
        V := 86400000;
        Observer.Observe('v3_1d', DumpDuration(V));
        V := -1000;
        Observer.Observe('v4_minus1s', DumpDuration(V));
        V := 1;
        Observer.Observe('v5_1ms', DumpDuration(V));
        Observer.Expect('v1_zero', '8:0000000000000000');
        Observer.Expect('v2_1s', '8:E803000000000000');
        Observer.Expect('v3_1d', '8:005C260500000000');
        Observer.Expect('v4_minus1s', '8:18FCFFFFFFFFFFFF');
        Observer.Expect('v5_1ms', '8:0100000000000000');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Duration;
        R2: Duration;
        R3: Duration;
        V: Duration;
    begin
        Helper.Fresh(Rec);
        V := 1000;
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadDuration(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadDuration(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadDuration(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadDuration(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '16');
        Observer.Expect('read1', 'ok n=8');
        Observer.Expect('value1', '1 second');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=8');
        Observer.Expect('value2', '1 second');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', '');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', '');
        Observer.Verify();
    end;

    local procedure DumpGuid(V: Guid): Text
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
    local procedure TryReadGuid(var Ins: InStream; var V: Guid; var N: Integer)
    begin
        N := Ins.Read(V);
    end;

    local procedure ReadGuid(var Ins: InStream; var V: Guid): Text
    var
        N: Integer;
    begin
        if TryReadGuid(Ins, V, N) then
            exit('ok n=' + Format(N));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Guid_BytesWritten()
    var
        Observer: Codeunit "Probe Observer";
        V: Guid;
    begin
        Clear(V);
        Observer.Observe('v1_null', DumpGuid(V));
        Evaluate(V, '{12345678-9ABC-DEF0-1234-56789ABCDEF0}');
        Observer.Observe('v2_pattern', DumpGuid(V));
        Evaluate(V, '{FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}');
        Observer.Observe('v3_ff', DumpGuid(V));
        Evaluate(V, '{00000001-0000-0000-0000-000000000000}');
        Observer.Observe('v4_low', DumpGuid(V));
        Observer.Expect('v1_null', '16:00000000000000000000000000000000');
        Observer.Expect('v2_pattern', '16:78563412BC9AF0DE123456789ABCDEF0');
        Observer.Expect('v3_ff', '16:FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
        Observer.Expect('v4_low', '16:01000000000000000000000000000000');
        Observer.Verify();
    end;

    [Test]
    procedure Guid_RoundTrip_PastEnd()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P89 Rec";
        Helper: Codeunit "LT P89 Helper";
        Out: OutStream;
        Ins: InStream;
        EmptyIns: InStream;
        R: Guid;
        R2: Guid;
        R3: Guid;
        V: Guid;
    begin
        Helper.Fresh(Rec);
        Evaluate(V, '{12345678-9ABC-DEF0-1234-56789ABCDEF0}');
        Rec.Data.CreateOutStream(Out);
        Out.Write(V);
        Out.Write(V);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        Observer.Observe('length', Format(Rec.Data.Length()));
        Observer.Observe('read1', ReadGuid(Ins, R));
        Observer.Observe('value1', Format(R));
        Observer.Observe('matches', Format(Format(R) = Format(V)));
        Observer.Observe('eos_after1', Format(Ins.EOS()));
        Observer.Observe('read2', ReadGuid(Ins, R2));
        Observer.Observe('value2', Format(R2));
        Observer.Observe('eos_after2', Format(Ins.EOS()));
        Observer.Observe('read_past_end', ReadGuid(Ins, R3));
        Observer.Observe('value_past_end', Format(R3));
        Observer.Observe('eos_past_end', Format(Ins.EOS()));
        Helper.Fresh(Rec);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(EmptyIns);
        Observer.Observe('empty_eos', Format(EmptyIns.EOS()));
        Observer.Observe('read_empty', ReadGuid(EmptyIns, R3));
        Observer.Observe('value_empty', Format(R3));
        Observer.Expect('length', '32');
        Observer.Expect('read1', 'ok n=16');
        Observer.Expect('value1', '{12345678-9ABC-DEF0-1234-56789ABCDEF0}');
        Observer.Expect('matches', 'Yes');
        Observer.Expect('eos_after1', 'No');
        Observer.Expect('read2', 'ok n=16');
        Observer.Expect('value2', '{12345678-9ABC-DEF0-1234-56789ABCDEF0}');
        Observer.Expect('eos_after2', 'Yes');
        Observer.Expect('read_past_end', 'ok n=0');
        Observer.Expect('value_past_end', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('eos_past_end', 'Yes');
        Observer.Expect('empty_eos', 'Yes');
        Observer.Expect('read_empty', 'ok n=0');
        Observer.Expect('value_empty', '{00000000-0000-0000-0000-000000000000}');
        Observer.Verify();
    end;

}
