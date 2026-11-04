// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT OutIn Rec (71751), LT OutIn Helper (71752)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Pins OutStream.Write(Value, Length) and InStream.Read(var Value, Length) for Integer, BigInteger, Boolean, Byte: per case the Write return or error, the bytes in the blob, and a read of the same Length (return or error, value, EOS, position) followed by a second read at the end of the stream.
// BC versions: 29 (27 and 28 by CI)

codeunit 67860 "LT Q Stream Len Int"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure W_Integer(var O: OutStream; V: Integer; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Integer(var I: InStream; var V: Integer; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Integer(var Observer: Codeunit "Probe Observer"; Id: Text; V: Integer; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Integer;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Integer(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Integer(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Integer(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_BigInteger(var O: OutStream; V: BigInteger; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_BigInteger(var I: InStream; var V: BigInteger; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_BigInteger(var Observer: Codeunit "Probe Observer"; Id: Text; V: BigInteger; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: BigInteger;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_BigInteger(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_BigInteger(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_BigInteger(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_Boolean(var O: OutStream; V: Boolean; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Boolean(var I: InStream; var V: Boolean; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Boolean(var Observer: Codeunit "Probe Observer"; Id: Text; V: Boolean; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Boolean;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Boolean(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Boolean(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Boolean(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [TryFunction]
    local procedure W_Byte(var O: OutStream; V: Byte; WL: Integer; var Ret: Integer)
    begin
        if WL < 0 then
            Ret := O.Write(V)
        else
            Ret := O.Write(V, WL);
    end;

    [TryFunction]
    local procedure R_Byte(var I: InStream; var V: Byte; RL: Integer; var Ret: Integer)
    begin
        if RL < 0 then
            Ret := I.Read(V)
        else
            Ret := I.Read(V, RL);
    end;

    local procedure Do_Byte(var Observer: Codeunit "Probe Observer"; Id: Text; V: Byte; WL: Integer; RL: Integer)
    var
        Helper: Codeunit "LT OutIn Helper";
        Rec: Record "LT OutIn Rec";
        Out: OutStream;
        Ins: InStream;
        R: Byte;
        Ret: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        if W_Byte(Out, V, WL, Ret) then
            Observer.Observe(Id + '_wret', Format(Ret))
        else
            Observer.ObserveError(Id + '_w');
        Rec.Modify();
        Observer.Observe(Id + '_bytes', Helper.Dump(Rec));
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        if R_Byte(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else begin
            Observer.ObserveError(Id + '_r');
            Observer.Observe(Id + '_rval', Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()));
        end;
        if R_Byte(Ins, R, RL, Ret) then
            Observer.Observe(Id + '_rd2', Format(Ret) + '/' + Format(R) + '/' + Format(Ins.EOS()) + '/' + Format(Ins.Position()))
        else
            Observer.ObserveError(Id + '_r2');
    end;

    [Test]
    procedure Integer_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 258;
        Do_Integer(Observer, 'n258', V, -1, -1);
        V := 258;
        Do_Integer(Observer, 'w4', V, 4, 4);
        V := 258;
        Do_Integer(Observer, 'w2', V, 2, 2);
        Observer.Expect('n258_wret', '4');
        Observer.Expect('n258_bytes', '4:02010000');
        Observer.Expect('n258_rd', '4/258/Yes/5');
        Observer.Expect('n258_rd2', '0/0/Yes/5');
        Observer.Expect('w4_wret', '4');
        Observer.Expect('w4_bytes', '4:02010000');
        Observer.Expect('w4_rd', '4/258/Yes/5');
        Observer.Expect('w4_rd2', '0/0/Yes/5');
        Observer.Expect('w2_w|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('w2_w|code', 'InvalidStreamLength');
        Observer.Expect('w2_bytes', '0:');
        Observer.Expect('w2_r|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('w2_r|code', 'InvalidStreamLength');
        Observer.Expect('w2_rval', '0/Yes/1');
        Observer.Expect('w2_r2|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('w2_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 258;
        Do_Integer(Observer, 'w1', V, 1, 1);
        V := 258;
        Do_Integer(Observer, 'w0', V, 0, 0);
        V := 258;
        Do_Integer(Observer, 'w8', V, 8, 8);
        Observer.Expect('w1_w|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('w1_w|code', 'InvalidStreamLength');
        Observer.Expect('w1_bytes', '0:');
        Observer.Expect('w1_r|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('w1_r|code', 'InvalidStreamLength');
        Observer.Expect('w1_rval', '0/Yes/1');
        Observer.Expect('w1_r2|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('w1_r2|code', 'InvalidStreamLength');
        Observer.Expect('w0_w|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('w0_w|code', 'InvalidStreamLength');
        Observer.Expect('w0_bytes', '0:');
        Observer.Expect('w0_r|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('w0_r|code', 'InvalidStreamLength');
        Observer.Expect('w0_rval', '0/Yes/1');
        Observer.Expect('w0_r2|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('w0_r2|code', 'InvalidStreamLength');
        Observer.Expect('w8_w|text', 'An invalid length 8 was specified in stream function. 4 was expected.');
        Observer.Expect('w8_w|code', 'InvalidStreamLength');
        Observer.Expect('w8_bytes', '0:');
        Observer.Expect('w8_r|text', 'An invalid length 8 was specified in stream function. 4 was expected.');
        Observer.Expect('w8_r|code', 'InvalidStreamLength');
        Observer.Expect('w8_rval', '0/Yes/1');
        Observer.Expect('w8_r2|text', 'An invalid length 8 was specified in stream function. 4 was expected.');
        Observer.Expect('w8_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_WriteReadLength_3()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := -1;
        Do_Integer(Observer, 'neg4', V, 4, 4);
        V := 258;
        Do_Integer(Observer, 'r2', V, -1, 2);
        V := 258;
        Do_Integer(Observer, 'r8', V, -1, 8);
        Observer.Expect('neg4_wret', '4');
        Observer.Expect('neg4_bytes', '4:FFFFFFFF');
        Observer.Expect('neg4_rd', '4/-1/Yes/5');
        Observer.Expect('neg4_rd2', '0/0/Yes/5');
        Observer.Expect('r2_wret', '4');
        Observer.Expect('r2_bytes', '4:02010000');
        Observer.Expect('r2_r|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('r2_r|code', 'InvalidStreamLength');
        Observer.Expect('r2_rval', '0/No/1');
        Observer.Expect('r2_r2|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('r2_r2|code', 'InvalidStreamLength');
        Observer.Expect('r8_wret', '4');
        Observer.Expect('r8_bytes', '4:02010000');
        Observer.Expect('r8_r|text', 'An invalid length 8 was specified in stream function. 4 was expected.');
        Observer.Expect('r8_r|code', 'InvalidStreamLength');
        Observer.Expect('r8_rval', '0/No/1');
        Observer.Expect('r8_r2|text', 'An invalid length 8 was specified in stream function. 4 was expected.');
        Observer.Expect('r8_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_WriteReadLength_4()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        V := 258;
        Do_Integer(Observer, 'r0', V, -1, 0);
        Observer.Expect('r0_wret', '4');
        Observer.Expect('r0_bytes', '4:02010000');
        Observer.Expect('r0_r|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('r0_r|code', 'InvalidStreamLength');
        Observer.Expect('r0_rval', '0/No/1');
        Observer.Expect('r0_r2|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('r0_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        V := 258;
        Do_BigInteger(Observer, 'n258', V, -1, -1);
        V := 258;
        Do_BigInteger(Observer, 'w8', V, 8, 8);
        V := 258;
        Do_BigInteger(Observer, 'w4', V, 4, 4);
        Observer.Expect('n258_wret', '8');
        Observer.Expect('n258_bytes', '8:0201000000000000');
        Observer.Expect('n258_rd', '8/258/Yes/9');
        Observer.Expect('n258_rd2', '0/0/Yes/9');
        Observer.Expect('w8_wret', '8');
        Observer.Expect('w8_bytes', '8:0201000000000000');
        Observer.Expect('w8_rd', '8/258/Yes/9');
        Observer.Expect('w8_rd2', '0/0/Yes/9');
        Observer.Expect('w4_w|text', 'An invalid length 4 was specified in stream function. 8 was expected.');
        Observer.Expect('w4_w|code', 'InvalidStreamLength');
        Observer.Expect('w4_bytes', '0:');
        Observer.Expect('w4_r|text', 'An invalid length 4 was specified in stream function. 8 was expected.');
        Observer.Expect('w4_r|code', 'InvalidStreamLength');
        Observer.Expect('w4_rval', '0/Yes/1');
        Observer.Expect('w4_r2|text', 'An invalid length 4 was specified in stream function. 8 was expected.');
        Observer.Expect('w4_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        V := 258;
        Do_BigInteger(Observer, 'w0', V, 0, 0);
        V := 258;
        Do_BigInteger(Observer, 'w9', V, 9, 9);
        V := 258;
        Do_BigInteger(Observer, 'r4', V, -1, 4);
        Observer.Expect('w0_w|text', 'An invalid length 0 was specified in stream function. 8 was expected.');
        Observer.Expect('w0_w|code', 'InvalidStreamLength');
        Observer.Expect('w0_bytes', '0:');
        Observer.Expect('w0_r|text', 'An invalid length 0 was specified in stream function. 8 was expected.');
        Observer.Expect('w0_r|code', 'InvalidStreamLength');
        Observer.Expect('w0_rval', '0/Yes/1');
        Observer.Expect('w0_r2|text', 'An invalid length 0 was specified in stream function. 8 was expected.');
        Observer.Expect('w0_r2|code', 'InvalidStreamLength');
        Observer.Expect('w9_w|text', 'An invalid length 9 was specified in stream function. 8 was expected.');
        Observer.Expect('w9_w|code', 'InvalidStreamLength');
        Observer.Expect('w9_bytes', '0:');
        Observer.Expect('w9_r|text', 'An invalid length 9 was specified in stream function. 8 was expected.');
        Observer.Expect('w9_r|code', 'InvalidStreamLength');
        Observer.Expect('w9_rval', '0/Yes/1');
        Observer.Expect('w9_r2|text', 'An invalid length 9 was specified in stream function. 8 was expected.');
        Observer.Expect('w9_r2|code', 'InvalidStreamLength');
        Observer.Expect('r4_wret', '8');
        Observer.Expect('r4_bytes', '8:0201000000000000');
        Observer.Expect('r4_r|text', 'An invalid length 4 was specified in stream function. 8 was expected.');
        Observer.Expect('r4_r|code', 'InvalidStreamLength');
        Observer.Expect('r4_rval', '0/No/1');
        Observer.Expect('r4_r2|text', 'An invalid length 4 was specified in stream function. 8 was expected.');
        Observer.Expect('r4_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_WriteReadLength_3()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        V := 258;
        Do_BigInteger(Observer, 'r0', V, -1, 0);
        Observer.Expect('r0_wret', '8');
        Observer.Expect('r0_bytes', '8:0201000000000000');
        Observer.Expect('r0_r|text', 'An invalid length 0 was specified in stream function. 8 was expected.');
        Observer.Expect('r0_r|code', 'InvalidStreamLength');
        Observer.Expect('r0_rval', '0/No/1');
        Observer.Expect('r0_r2|text', 'An invalid length 0 was specified in stream function. 8 was expected.');
        Observer.Expect('r0_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        V := true;
        Do_Boolean(Observer, 'ntrue', V, -1, -1);
        V := true;
        Do_Boolean(Observer, 'w4', V, 4, 4);
        V := true;
        Do_Boolean(Observer, 'w1', V, 1, 1);
        Observer.Expect('ntrue_wret', '4');
        Observer.Expect('ntrue_bytes', '4:01000000');
        Observer.Expect('ntrue_rd', '4/Yes/Yes/5');
        Observer.Expect('ntrue_rd2', '0/No/Yes/5');
        Observer.Expect('w4_wret', '4');
        Observer.Expect('w4_bytes', '4:01000000');
        Observer.Expect('w4_rd', '4/Yes/Yes/5');
        Observer.Expect('w4_rd2', '0/No/Yes/5');
        Observer.Expect('w1_w|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('w1_w|code', 'InvalidStreamLength');
        Observer.Expect('w1_bytes', '0:');
        Observer.Expect('w1_r|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('w1_r|code', 'InvalidStreamLength');
        Observer.Expect('w1_rval', 'No/Yes/1');
        Observer.Expect('w1_r2|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('w1_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        V := true;
        Do_Boolean(Observer, 'w2', V, 2, 2);
        V := true;
        Do_Boolean(Observer, 'w0', V, 0, 0);
        V := true;
        Do_Boolean(Observer, 'w8', V, 8, 8);
        Observer.Expect('w2_w|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('w2_w|code', 'InvalidStreamLength');
        Observer.Expect('w2_bytes', '0:');
        Observer.Expect('w2_r|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('w2_r|code', 'InvalidStreamLength');
        Observer.Expect('w2_rval', 'No/Yes/1');
        Observer.Expect('w2_r2|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('w2_r2|code', 'InvalidStreamLength');
        Observer.Expect('w0_w|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('w0_w|code', 'InvalidStreamLength');
        Observer.Expect('w0_bytes', '0:');
        Observer.Expect('w0_r|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('w0_r|code', 'InvalidStreamLength');
        Observer.Expect('w0_rval', 'No/Yes/1');
        Observer.Expect('w0_r2|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('w0_r2|code', 'InvalidStreamLength');
        Observer.Expect('w8_w|text', 'An invalid length 8 was specified in stream function. 4 was expected.');
        Observer.Expect('w8_w|code', 'InvalidStreamLength');
        Observer.Expect('w8_bytes', '0:');
        Observer.Expect('w8_r|text', 'An invalid length 8 was specified in stream function. 4 was expected.');
        Observer.Expect('w8_r|code', 'InvalidStreamLength');
        Observer.Expect('w8_rval', 'No/Yes/1');
        Observer.Expect('w8_r2|text', 'An invalid length 8 was specified in stream function. 4 was expected.');
        Observer.Expect('w8_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_WriteReadLength_3()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        V := true;
        Do_Boolean(Observer, 'r1', V, -1, 1);
        V := true;
        Do_Boolean(Observer, 'r0', V, -1, 0);
        Observer.Expect('r1_wret', '4');
        Observer.Expect('r1_bytes', '4:01000000');
        Observer.Expect('r1_r|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('r1_r|code', 'InvalidStreamLength');
        Observer.Expect('r1_rval', 'No/No/1');
        Observer.Expect('r1_r2|text', 'An invalid length 1 was specified in stream function. 4 was expected.');
        Observer.Expect('r1_r2|code', 'InvalidStreamLength');
        Observer.Expect('r0_wret', '4');
        Observer.Expect('r0_bytes', '4:01000000');
        Observer.Expect('r0_r|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('r0_r|code', 'InvalidStreamLength');
        Observer.Expect('r0_rval', 'No/No/1');
        Observer.Expect('r0_r2|text', 'An invalid length 0 was specified in stream function. 4 was expected.');
        Observer.Expect('r0_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_WriteReadLength_1()
    var
        Observer: Codeunit "Probe Observer";
        V: Byte;
    begin
        V := 200;
        Do_Byte(Observer, 'n200', V, -1, -1);
        V := 200;
        Do_Byte(Observer, 'w1', V, 1, 1);
        V := 200;
        Do_Byte(Observer, 'w2', V, 2, 2);
        Observer.Expect('n200_wret', '1');
        Observer.Expect('n200_bytes', '1:C8');
        Observer.Expect('n200_rd', '1/˜/Yes/2');
        Observer.Expect('n200_rd2', '0/\u0000/Yes/2');
        Observer.Expect('w1_wret', '1');
        Observer.Expect('w1_bytes', '1:C8');
        Observer.Expect('w1_rd', '1/˜/Yes/2');
        Observer.Expect('w1_rd2', '0/\u0000/Yes/2');
        Observer.Expect('w2_w|text', 'An invalid length 2 was specified in stream function. 1 was expected.');
        Observer.Expect('w2_w|code', 'InvalidStreamLength');
        Observer.Expect('w2_bytes', '0:');
        Observer.Expect('w2_r|text', 'An invalid length 2 was specified in stream function. 1 was expected.');
        Observer.Expect('w2_r|code', 'InvalidStreamLength');
        Observer.Expect('w2_rval', '\u0000/Yes/1');
        Observer.Expect('w2_r2|text', 'An invalid length 2 was specified in stream function. 1 was expected.');
        Observer.Expect('w2_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Byte_WriteReadLength_2()
    var
        Observer: Codeunit "Probe Observer";
        V: Byte;
    begin
        V := 200;
        Do_Byte(Observer, 'w0', V, 0, 0);
        V := 200;
        Do_Byte(Observer, 'r2', V, -1, 2);
        V := 200;
        Do_Byte(Observer, 'r0', V, -1, 0);
        Observer.Expect('w0_w|text', 'An invalid length 0 was specified in stream function. 1 was expected.');
        Observer.Expect('w0_w|code', 'InvalidStreamLength');
        Observer.Expect('w0_bytes', '0:');
        Observer.Expect('w0_r|text', 'An invalid length 0 was specified in stream function. 1 was expected.');
        Observer.Expect('w0_r|code', 'InvalidStreamLength');
        Observer.Expect('w0_rval', '\u0000/Yes/1');
        Observer.Expect('w0_r2|text', 'An invalid length 0 was specified in stream function. 1 was expected.');
        Observer.Expect('w0_r2|code', 'InvalidStreamLength');
        Observer.Expect('r2_wret', '1');
        Observer.Expect('r2_bytes', '1:C8');
        Observer.Expect('r2_r|text', 'An invalid length 2 was specified in stream function. 1 was expected.');
        Observer.Expect('r2_r|code', 'InvalidStreamLength');
        Observer.Expect('r2_rval', '\u0000/No/1');
        Observer.Expect('r2_r2|text', 'An invalid length 2 was specified in stream function. 1 was expected.');
        Observer.Expect('r2_r2|code', 'InvalidStreamLength');
        Observer.Expect('r0_wret', '1');
        Observer.Expect('r0_bytes', '1:C8');
        Observer.Expect('r0_r|text', 'An invalid length 0 was specified in stream function. 1 was expected.');
        Observer.Expect('r0_r|code', 'InvalidStreamLength');
        Observer.Expect('r0_rval', '\u0000/No/1');
        Observer.Expect('r0_r2|text', 'An invalid length 0 was specified in stream function. 1 was expected.');
        Observer.Expect('r0_r2|code', 'InvalidStreamLength');
        Observer.Verify();
    end;
}
