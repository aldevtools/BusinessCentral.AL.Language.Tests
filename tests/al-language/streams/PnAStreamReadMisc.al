// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 70087
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Streams: Read into anything but Integer and Byte, ReadText with a length and Position with an argument
// Facts: InStream.Read into the other types, ReadText with and without length, Position set, UTF16 and MSDos WriteText/ReadText bytes
// BC versions: 29 (27 and 28 by CI)

codeunit 70091 "LT PnA Stream ReadMisc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Rec: Record "LT PnA Blob" temporary;
        Res: Text;

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

    local procedure Fill()
    var
        OutS: OutStream;
        I: Integer;
    begin
        Rec.Data.CreateOutStream(OutS);
        I := 258;
        OutS.Write(I);
        I := 7;
        OutS.Write(I);
        OutS.WriteText('AB');
    end;

    [TryFunction]
    local procedure TryRead(Op: Integer)
    var
        InS: InStream;
        I: Integer;
        B: Byte;
        BI: BigInteger;
        D: Decimal;
        Dt: Date;
        Bo: Boolean;
        C: Char;
        T: Text;
        T2: Text[2];
        Tm: Time;
        Du: Duration;
        G: Guid;
    begin
        Res := '';
        Rec.Data.CreateInStream(InS);
        case Op of
            1:
                begin
                    InS.Read(I);
                    Res := Format(I);
                end;
            2:
                begin
                    InS.Read(B);
                    Res := Format(B);
                end;
            3:
                begin
                    InS.Read(BI);
                    Res := Format(BI);
                end;
            4:
                begin
                    InS.Read(D);
                    Res := Format(D);
                end;
            5:
                begin
                    InS.Read(Dt);
                    Res := Format(Dt);
                end;
            6:
                begin
                    InS.Read(Bo);
                    Res := Format(Bo);
                end;
            7:
                begin
                    InS.Read(C);
                    Res := Format(C);
                end;
            8:
                begin
                    InS.Read(T, 2);
                    Res := T;
                end;
            9:
                begin
                    InS.Read(T2);
                    Res := T2;
                end;
            10:
                begin
                    InS.Read(Tm);
                    Res := Format(Tm);
                end;
            11:
                begin
                    InS.Read(Du);
                    Res := Format(Du);
                end;
            12:
                begin
                    InS.Read(G);
                    Res := Format(G);
                end;
            13:
                begin
                    InS.Read(I, 2);
                    Res := Format(I);
                end;
            14:
                begin
                    InS.Read(I);
                    InS.Read(I);
                    InS.ReadText(T);
                    Res := T;
                end;
            15:
                begin
                    InS.Read(I);
                    InS.Read(I);
                    InS.ReadText(T, 1);
                    Res := T;
                end;
            16:
                begin
                    InS.Position := 5;
                    InS.Read(B);
                    Res := Format(B);
                end;
        end;
    end;

    [Test]
    procedure Read_Types_A()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Fill();
        for i := 1 to 8 do begin
            Observer.Observe('op' + Format(i), Format(TryRead(i)) + '|' + Res);
            Observer.ObserveError('op' + Format(i));
        end;
        Observer.Expect('op1', 'Yes|258');
        Observer.Expect('op1|text', '');
        Observer.Expect('op1|code', '');
        Observer.Expect('op2', 'Yes|\u0002');
        Observer.Expect('op2|text', '');
        Observer.Expect('op2|code', '');
        Observer.Expect('op3', 'Yes|30064771330');
        Observer.Expect('op3|text', '');
        Observer.Expect('op3|code', '');
        Observer.Expect('op4', 'No|');
        Observer.Expect('op4|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('op4|code', 'InvalidStreamData');
        Observer.Expect('op5', 'No|');
        Observer.Expect('op5|text', 'The date is not valid.');
        Observer.Expect('op5|code', 'DateInvalid');
        Observer.Expect('op6', 'Yes|Yes');
        Observer.Expect('op6|text', '');
        Observer.Expect('op6|code', '');
        Observer.Expect('op7', 'Yes|\u0002');
        Observer.Expect('op7|text', '');
        Observer.Expect('op7|code', '');
        Observer.Expect('op8', 'Yes|\u0002\u0001');
        Observer.Expect('op8|text', '');
        Observer.Expect('op8|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Types_B()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Fill();
        for i := 9 to 16 do begin
            Observer.Observe('op' + Format(i), Format(TryRead(i)) + '|' + Res);
            Observer.ObserveError('op' + Format(i));
        end;
        Observer.Expect('op9', 'Yes|\u0002\u0001');
        Observer.Expect('op9|text', '');
        Observer.Expect('op9|code', '');
        Observer.Expect('op10', 'Yes|12:00:00 AM');
        Observer.Expect('op10|text', '');
        Observer.Expect('op10|code', '');
        Observer.Expect('op11', 'Yes|347 days 23 hours 19 minutes 31 seconds 330 milliseconds');
        Observer.Expect('op11|text', '');
        Observer.Expect('op11|code', '');
        Observer.Expect('op12', 'No|');
        Observer.Expect('op12|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('op12|code', 'InvalidStreamData');
        Observer.Expect('op13', 'No|');
        Observer.Expect('op13|text', 'An invalid length 2 was specified in stream function. 4 was expected.');
        Observer.Expect('op13|code', 'InvalidStreamLength');
        Observer.Expect('op14', 'Yes|AB');
        Observer.Expect('op14|text', '');
        Observer.Expect('op14|code', '');
        Observer.Expect('op15', 'Yes|A');
        Observer.Expect('op15|text', '');
        Observer.Expect('op15|code', '');
        Observer.Expect('op16', 'Yes|\u0007');
        Observer.Expect('op16|text', '');
        Observer.Expect('op16|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure WriteText_ReadText_Encodings()
    var
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        L1: Text;
        L2: Text;
        L3: Text;
    begin
        Rec.Data.CreateOutStream(OutS, TextEncoding::UTF16);
        OutS.WriteText('ab');
        OutS.WriteText();
        OutS.WriteText('cd');
        Observer.Observe('utf16-bytes', Dump(Rec));
        Rec.Data.CreateInStream(InS, TextEncoding::UTF16);
        InS.ReadText(L1);
        InS.ReadText(L2);
        InS.ReadText(L3);
        Observer.Observe('utf16-lines', L1 + '|' + L2 + '|' + L3 + '|' + Format(InS.EOS));

        Rec.Data.CreateOutStream(OutS, TextEncoding::MSDos);
        OutS.WriteText('é');
        OutS.WriteText();
        OutS.WriteText('x');
        Observer.Observe('msdos-bytes', Dump(Rec));
        Rec.Data.CreateInStream(InS, TextEncoding::MSDos);
        InS.ReadText(L1);
        InS.ReadText(L2);
        Observer.Observe('msdos-lines', L1 + '|' + L2);

        Rec.Data.CreateOutStream(OutS, TextEncoding::Windows);
        OutS.WriteText('é');
        OutS.WriteText();
        OutS.WriteText('x');
        Observer.Observe('windows-bytes', Dump(Rec));
        Rec.Data.CreateInStream(InS, TextEncoding::Windows);
        InS.ReadText(L1);
        InS.ReadText(L2);
        Observer.Observe('windows-lines', L1 + '|' + L2);

        Rec.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('é');
        OutS.WriteText();
        OutS.WriteText('x');
        Observer.Observe('utf8-bytes', Dump(Rec));
        Rec.Data.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(L1);
        InS.ReadText(L2);
        Observer.Observe('utf8-lines', L1 + '|' + L2);
        Observer.Expect('utf16-bytes', '61 00 62 00 0D 00 0A 00 63 00 64 00');
        Observer.Expect('utf16-lines', 'ab|cd||Yes');
        Observer.Expect('msdos-bytes', '82 0D 0A 78 0D 00 0A 00 63 00 64 00');
        Observer.Expect('msdos-lines', 'é|x');
        Observer.Expect('windows-bytes', 'E9 0D 0A 78 0D 00 0A 00 63 00 64 00');
        Observer.Expect('windows-lines', 'é|x');
        Observer.Expect('utf8-bytes', 'C3 A9 0D 0A 78 00 0A 00 63 00 64 00');
        Observer.Expect('utf8-lines', '꧃਍x|cd');
        Observer.Verify();
    end;
}
