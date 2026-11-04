// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-read-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT P102 Rec (71615), LT P102 Helper (71616)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 71622 "LT P102 Read Typed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BigNum(I: Integer): BigInteger
    var
        B: BigInteger;
    begin
        B := I;
        exit(B);
    end;

    local procedure G1(): Guid
    var
        G: Guid;
    begin
        Evaluate(G, '{01020304-0506-0708-090A-0B0C0D0E0F10}');
        exit(G);
    end;

    [Test]
    procedure P102_ReadInteger()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Integer;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(305419896);
        Out.Write(-1);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('r1_n', Format(N));
        Observer.Observe('r1_v', Format(V));
        Observer.Observe('r1_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('r2_n', Format(N));
        Observer.Observe('r2_v', Format(V));
        Observer.Observe('r2_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('pastend_n', Format(N));
        Observer.Observe('pastend_v', Format(V));
        Observer.Observe('pastend_eos', Format(Ins.EOS()));
        Observer.Expect('r1_n', '4');
        Observer.Expect('r1_v', '305419896');
        Observer.Expect('r1_eos', 'No');
        Observer.Expect('r2_n', '4');
        Observer.Expect('r2_v', '-1');
        Observer.Expect('r2_eos', 'Yes');
        Observer.Expect('pastend_n', '0');
        Observer.Expect('pastend_v', '0');
        Observer.Expect('pastend_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: BigInteger;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(BigNum(258));
        Out.Write(BigNum(-1));
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('r1_n', Format(N));
        Observer.Observe('r1_v', Format(V));
        Observer.Observe('r1_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('r2_n', Format(N));
        Observer.Observe('r2_v', Format(V));
        Observer.Observe('r2_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('pastend_n', Format(N));
        Observer.Observe('pastend_v', Format(V));
        Observer.Observe('pastend_eos', Format(Ins.EOS()));
        Observer.Expect('r1_n', '8');
        Observer.Expect('r1_v', '258');
        Observer.Expect('r1_eos', 'No');
        Observer.Expect('r2_n', '8');
        Observer.Expect('r2_v', '-1');
        Observer.Expect('r2_eos', 'Yes');
        Observer.Expect('pastend_n', '0');
        Observer.Expect('pastend_v', '0');
        Observer.Expect('pastend_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadBoolean()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Boolean;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(true);
        Out.Write(false);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('r1_n', Format(N));
        Observer.Observe('r1_v', Format(V));
        Observer.Observe('r1_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('r2_n', Format(N));
        Observer.Observe('r2_v', Format(V));
        Observer.Observe('r2_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('pastend_n', Format(N));
        Observer.Observe('pastend_v', Format(V));
        Observer.Observe('pastend_eos', Format(Ins.EOS()));
        Observer.Expect('r1_n', '4');
        Observer.Expect('r1_v', 'Yes');
        Observer.Expect('r1_eos', 'No');
        Observer.Expect('r2_n', '4');
        Observer.Expect('r2_v', 'No');
        Observer.Expect('r2_eos', 'Yes');
        Observer.Expect('pastend_n', '0');
        Observer.Expect('pastend_v', 'No');
        Observer.Expect('pastend_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadByte()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Byte;
        W: Byte;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        W := 200;
        Out.Write(W);
        W := 1;
        Out.Write(W);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('r1_n', Format(N));
        Observer.Observe('r1_v', Format(V));
        Observer.Observe('r1_eos', Format(Ins.EOS()));
        N := Ins.Read(V, 1);
        Observer.Observe('r2_n', Format(N));
        Observer.Observe('r2_v', Format(V));
        Observer.Observe('r2_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('pastend_n', Format(N));
        Observer.Observe('pastend_v', Format(V));
        Observer.Observe('pastend_eos', Format(Ins.EOS()));
        Observer.Expect('r1_n', '1');
        Observer.Expect('r1_v', '˜');
        Observer.Expect('r1_eos', 'No');
        Observer.Expect('r2_n', '1');
        Observer.Expect('r2_v', '\u0001');
        Observer.Expect('r2_eos', 'Yes');
        Observer.Expect('pastend_n', '0');
        Observer.Expect('pastend_v', '\u0000');
        Observer.Expect('pastend_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadChar()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Char;
        C: Char;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        C := 65;
        Out.Write(C);
        C := 66;
        Out.Write(C);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('r1_n', Format(N));
        Observer.Observe('r1_v', Format(V));
        Observer.Observe('r1_eos', Format(Ins.EOS()));
        N := Ins.Read(V, 1);
        Observer.Observe('r2_n', Format(N));
        Observer.Observe('r2_v', Format(V));
        Observer.Observe('r2_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('pastend_n', Format(N));
        Observer.Observe('pastend_v', Format(V));
        Observer.Observe('pastend_eos', Format(Ins.EOS()));
        Observer.Expect('r1_n', '1');
        Observer.Expect('r1_v', 'A');
        Observer.Expect('r1_eos', 'No');
        Observer.Expect('r2_n', '1');
        Observer.Expect('r2_v', 'B');
        Observer.Expect('r2_eos', 'Yes');
        Observer.Expect('pastend_n', '0');
        Observer.Expect('pastend_v', '\u0000');
        Observer.Expect('pastend_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadDecimal()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Decimal;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(1.5);
        Out.Write(-0.25);
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('r1_n', Format(N));
        Observer.Observe('r1_v', Format(V));
        Observer.Observe('r1_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('r2_n', Format(N));
        Observer.Observe('r2_v', Format(V));
        Observer.Observe('r2_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('pastend_n', Format(N));
        Observer.Observe('pastend_v', Format(V));
        Observer.Observe('pastend_eos', Format(Ins.EOS()));
        Observer.Expect('r1_n', '12');
        Observer.Expect('r1_v', '1.5');
        Observer.Expect('r1_eos', 'No');
        Observer.Expect('r2_n', '12');
        Observer.Expect('r2_v', '-0.25');
        Observer.Expect('r2_eos', 'Yes');
        Observer.Expect('pastend_n', '0');
        Observer.Expect('pastend_v', '0');
        Observer.Expect('pastend_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadGuid()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Guid;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(G1());
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('r1_n', Format(N));
        Observer.Observe('r1_v', Format(V));
        Observer.Observe('r1_eos', Format(Ins.EOS()));
        N := Ins.Read(V);
        Observer.Observe('pastend_n', Format(N));
        Observer.Observe('pastend_v', Format(V));
        Observer.Observe('pastend_eos', Format(Ins.EOS()));
        Observer.Expect('r1_n', '16');
        Observer.Expect('r1_v', '{01020304-0506-0708-090A-0B0C0D0E0F10}');
        Observer.Expect('r1_eos', 'Yes');
        Observer.Expect('pastend_n', '0');
        Observer.Expect('pastend_v', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('pastend_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Text;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('abcdef');
        Out.Write('xyz');
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('noLen_n', Format(N));
        Observer.Observe('noLen_v', Format(V));
        Observer.Observe('noLen_eos', Format(Ins.EOS()));
        V := 'old'; N := Ins.Read(V);
        Observer.Observe('pastend_n', Format(N));
        Observer.Observe('pastend_v', Format(V));
        Observer.Observe('pastend_eos', Format(Ins.EOS()));
        Observer.Expect('noLen_n', '7');
        Observer.Expect('noLen_v', 'abcdef');
        Observer.Expect('noLen_eos', 'No');
        Observer.Expect('pastend_n', '4');
        Observer.Expect('pastend_v', 'xyz');
        Observer.Expect('pastend_eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadTextLen()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Text;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('abcdef');
        Out.Write('xyz');
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V, 2);
        Observer.Observe('len2_n', Format(N));
        Observer.Observe('len2_v', Format(V));
        Observer.Observe('len2_eos', Format(Ins.EOS()));
        N := Ins.Read(V, 3);
        Observer.Observe('len3_n', Format(N));
        Observer.Observe('len3_v', Format(V));
        Observer.Observe('len3_eos', Format(Ins.EOS()));
        V := 'old'; N := Ins.Read(V, 0);
        Observer.Observe('len0_n', Format(N));
        Observer.Observe('len0_v', Format(V));
        Observer.Observe('len0_eos', Format(Ins.EOS()));
        N := Ins.Read(V, 99);
        Observer.Observe('len99_n', Format(N));
        Observer.Observe('len99_v', Format(V));
        Observer.Observe('len99_eos', Format(Ins.EOS()));
        Observer.Expect('len2_n', '2');
        Observer.Expect('len2_v', 'ab');
        Observer.Expect('len2_eos', 'No');
        Observer.Expect('len3_n', '3');
        Observer.Expect('len3_v', 'cde');
        Observer.Expect('len3_eos', 'No');
        Observer.Expect('len0_n', '0');
        Observer.Expect('len0_v', '');
        Observer.Expect('len0_eos', 'No');
        Observer.Expect('len99_n', '2');
        Observer.Expect('len99_v', 'f');
        Observer.Expect('len99_eos', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadCodeVar()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Code[3];
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write('abcdef');
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('noLen_n', Format(N));
        Observer.Observe('noLen_v', Format(V));
        Observer.Observe('noLen_eos', Format(Ins.EOS()));
        Observer.Expect('noLen_n', '3');
        Observer.Expect('noLen_v', 'ABC');
        Observer.Expect('noLen_eos', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P102_ReadTextAfterInt()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P102 Helper";
        Rec: Record "LT P102 Rec";
        Out: OutStream;
        Ins: InStream;
        N: Integer;
        V: Text;
    begin
        Helper.Fresh(Rec);
        Rec.Data.CreateOutStream(Out);
        Out.Write(1);
        Out.Write('hi');
        Rec.Modify();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
        N := Ins.Read(V);
        Observer.Observe('txt_n', Format(N));
        Observer.Observe('txt_v', Format(V));
        Observer.Observe('txt_eos', Format(Ins.EOS()));
        Observer.Expect('txt_n', '2');
        Observer.Expect('txt_v', '\u0001');
        Observer.Expect('txt_eos', 'No');
        Observer.Verify();
    end;

}
