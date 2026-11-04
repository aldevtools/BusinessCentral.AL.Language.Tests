// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70087
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Streams: Write(Text) of non-ASCII text, Write(Char), Write(Byte) and Write with a length
// Facts: bytes written by OutStream.Write for Text, Char, Byte, Integer, BigInteger, Boolean, Time, DateTime, Duration, Guid and with a length
// BC versions: 29 (27 and 28 by CI)

codeunit 70090 "LT PnA Stream WriteMisc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Rec: Record "LT PnA Blob" temporary;
        OutS: OutStream;

    local procedure HexByte(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    local procedure Dump(var Rec: Record "LT PnA Blob" temporary): Text
    var
        InS: InStream;
        B: Byte;
        R: Text;
    begin
        Rec.Data.CreateInStream(InS);
        while not InS.EOS do begin
            InS.Read(B);
            R += HexByte(B) + ' ';
        end;
        exit(DelChr(R, '>', ' '));
    end;

    [TryFunction]
    local procedure TryOp(Op: Integer)
    var
        T: Text;
        C: Char;
        B: Byte;
        I: Integer;
        BI: BigInteger;
        Bo: Boolean;
        Tm: Time;
        Dt: DateTime;
        Du: Duration;
        G: Guid;
        Cd: Code[10];
        T3: Text[3];
    begin
        Rec.Data.CreateOutStream(OutS);
        case Op of
            1:
                begin
                    T := 'abc';
                    OutS.Write(T);
                end;
            2:
                begin
                    T := '';
                    OutS.Write(T);
                end;
            3:
                begin
                    T := 'é€';
                    OutS.Write(T);
                end;
            4:
                begin
                    T := 'abc';
                    OutS.Write(T, 2);
                end;
            5:
                begin
                    T := 'abc';
                    OutS.Write(T, 5);
                end;
            6:
                begin
                    C := 65;
                    OutS.Write(C);
                end;
            7:
                begin
                    C := 233;
                    OutS.Write(C);
                end;
            8:
                begin
                    B := 255;
                    OutS.Write(B);
                end;
            9:
                begin
                    I := 258;
                    OutS.Write(I);
                end;
            10:
                begin
                    I := 258;
                    OutS.Write(I, 2);
                end;
            11:
                begin
                    I := -1;
                    OutS.Write(I);
                end;
            12:
                begin
                    BI := 5000000000L;
                    OutS.Write(BI);
                end;
            13:
                begin
                    Bo := true;
                    OutS.Write(Bo);
                end;
            14:
                begin
                    Tm := 123456T;
                    OutS.Write(Tm);
                end;
            15:
                begin
                    Dt := CreateDateTime(DMY2Date(1, 1, 2024), 123456T);
                    OutS.Write(Dt);
                end;
            16:
                begin
                    Du := 1500;
                    OutS.Write(Du);
                end;
            17:
                begin
                    Evaluate(G, '{01234567-89AB-CDEF-0123-456789ABCDEF}');
                    OutS.Write(G);
                end;
            18:
                begin
                    Cd := 'ab';
                    OutS.Write(Cd);
                end;
            19:
                begin
                    T3 := 'xyz';
                    OutS.Write(T3);
                end;
        end;
    end;

    [Test]
    procedure Write_Types_A()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 1 to 10 do begin
            Observer.Observe('op' + Format(i), Format(TryOp(i)) + '|' + Dump(Rec));
            Observer.ObserveError('op' + Format(i));
        end;
        Observer.Expect('op1', 'Yes|61 62 63 00');
        Observer.Expect('op1|text', '');
        Observer.Expect('op1|code', '');
        Observer.Expect('op2', 'Yes|00 62 63 00');
        Observer.Expect('op2|text', '');
        Observer.Expect('op2|code', '');
        Observer.Expect('op3', 'Yes|82 B1 00 00');
        Observer.Expect('op3|text', '');
        Observer.Expect('op3|code', '');
        Observer.Expect('op4', 'Yes|61 62 00 00');
        Observer.Expect('op4|text', '');
        Observer.Expect('op4|code', '');
        Observer.Expect('op5', 'Yes|61 62 63 00');
        Observer.Expect('op5|text', '');
        Observer.Expect('op5|code', '');
        Observer.Expect('op6', 'Yes|41 62 63 00');
        Observer.Expect('op6|text', '');
        Observer.Expect('op6|code', '');
        Observer.Expect('op7', 'Yes|82 62 63 00');
        Observer.Expect('op7|text', '');
        Observer.Expect('op7|code', '');
        Observer.Expect('op8', 'Yes|FF 62 63 00');
        Observer.Expect('op8|text', '');
        Observer.Expect('op8|code', '');
        Observer.Expect('op9', 'Yes|02 01 00 00');
        Observer.Expect('op9|text', '');
        Observer.Expect('op9|code', '');
        Observer.Expect('op10', 'No|02 01 00 00');
        Observer.Expect('op10|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('op10|code', 'InvalidStreamLength');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Types_B()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 11 to 19 do begin
            Observer.Observe('op' + Format(i), Format(TryOp(i)) + '|' + Dump(Rec));
            Observer.ObserveError('op' + Format(i));
        end;
        Observer.Expect('op11', 'Yes|FF FF FF FF');
        Observer.Expect('op11|text', '');
        Observer.Expect('op11|code', '');
        Observer.Expect('op12', 'Yes|00 F2 05 2A 01 00 00 00');
        Observer.Expect('op12|text', '');
        Observer.Expect('op12|code', '');
        Observer.Expect('op13', 'Yes|01 00 00 00 01 00 00 00');
        Observer.Expect('op13|text', '');
        Observer.Expect('op13|code', '');
        Observer.Expect('op14', 'Yes|81 29 B3 02 01 00 00 00');
        Observer.Expect('op14|text', '');
        Observer.Expect('op14|code', '');
        Observer.Expect('op15', 'Yes|81 7D 09 34 17 3A 00 00');
        Observer.Expect('op15|text', '');
        Observer.Expect('op15|code', '');
        Observer.Expect('op16', 'Yes|DC 05 00 00 00 00 00 00');
        Observer.Expect('op16|text', '');
        Observer.Expect('op16|code', '');
        Observer.Expect('op17', 'Yes|67 45 23 01 AB 89 EF CD 01 23 45 67 89 AB CD EF');
        Observer.Expect('op17|text', '');
        Observer.Expect('op17|code', '');
        Observer.Expect('op18', 'Yes|41 42 00 01 AB 89 EF CD 01 23 45 67 89 AB CD EF');
        Observer.Expect('op18|text', '');
        Observer.Expect('op18|code', '');
        Observer.Expect('op19', 'Yes|78 79 7A 00 AB 89 EF CD 01 23 45 67 89 AB CD EF');
        Observer.Expect('op19|text', '');
        Observer.Expect('op19|code', '');
        Observer.Verify();
    end;
}
