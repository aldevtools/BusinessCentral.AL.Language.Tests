// Batch 7 probes: InStream.Read into a Text or Code (up to the zero byte of Write(Text), non-ASCII, return value) and Read(Text, Length). Observe only.
codeunit 68554 "W7 Stream Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ch(Code: Integer): Text
    var
        T: Text[1];
    begin
        T[1] := Code;
        exit(T);
    end;

    local procedure WriteBytes(var TempBlob: Codeunit "Temp Blob"; Bytes: List of [Integer])
    var
        OutS: OutStream;
        B: Byte;
        Value: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        foreach Value in Bytes do begin
            B := Value;
            OutS.Write(B);
        end;
    end;

    [TryFunction]
    local procedure TryRead(var InS: InStream; var Result: Text; var Count: Integer)
    begin
        Count := InS.Read(Result);
    end;

    [TryFunction]
    local procedure TryReadLength(var InS: InStream; var Result: Text; Length: Integer; var Count: Integer)
    begin
        Count := InS.Read(Result, Length);
    end;

    local procedure ReadWhole(var Observer: Codeunit "Probe Observer"; Name: Text; var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding)
    var
        Util: Codeunit "W7 Stream Util";
        InS: InStream;
        Result: Text;
        Count: Integer;
    begin
        TempBlob.CreateInStream(InS, Encoding);
        if TryRead(InS, Result, Count) then begin
            Observer.Observe(Name + ' returned', Format(Count));
            Observer.Observe(Name + ' codes', Util.Codes(Result));
            Observer.Observe(Name + ' at end', Format(InS.EOS()));
        end else begin
            Observer.Observe(Name + ' failed', 'true');
            Observer.ObserveError(Name);
        end;
    end;

    [Test]
    procedure ReadText_AfterWriteText_NoTerminator()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('abc');
        ReadWhole(Observer, 'abc', TempBlob, TextEncoding::UTF8);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('abc');
        OutS.WriteText('def');
        ReadWhole(Observer, 'abc then def', TempBlob, TextEncoding::UTF8);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('abc');
        OutS.WriteText();
        OutS.WriteText('def');
        ReadWhole(Observer, 'abc, line break, def', TempBlob, TextEncoding::UTF8);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        ReadWhole(Observer, 'empty stream', TempBlob, TextEncoding::UTF8);
        Observer.Expect('abc returned', '4');
        Observer.Expect('abc codes', '97 98 99');
        Observer.Expect('abc at end', 'Yes');
        Observer.Expect('abc then def returned', '7');
        Observer.Expect('abc then def codes', '97 98 99 100 101 102');
        Observer.Expect('abc then def at end', 'Yes');
        Observer.Expect('abc, line break, def returned', '9');
        Observer.Expect('abc, line break, def codes', '97 98 99 13 10 100 101 102');
        Observer.Expect('abc, line break, def at end', 'Yes');
        Observer.Expect('empty stream returned', '1');
        Observer.Expect('empty stream codes', '');
        Observer.Expect('empty stream at end', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_AfterWriteOfAText_ZeroTerminator()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        First: Text;
        Second: Text;
        Count: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.Write('abc');
        OutS.Write('de');
        Observer.Observe('bytes written', Util.Hex(TempBlob));
        TempBlob.CreateInStream(InS);
        Count := InS.Read(First);
        Observer.Observe('first returned', Format(Count));
        Observer.Observe('first', Util.Codes(First));
        Count := InS.Read(Second);
        Observer.Observe('second returned', Format(Count));
        Observer.Observe('second', Util.Codes(Second));
        Observer.Observe('at end', Format(InS.EOS()));
        Observer.Expect('bytes written', '61 62 63 00 64 65 00');
        Observer.Expect('first returned', '4');
        Observer.Expect('first', '97 98 99');
        Observer.Expect('second returned', '3');
        Observer.Expect('second', '100 101');
        Observer.Expect('at end', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_AfterWriteOfAText_EmptyAndCode()
    var
        Observer: Codeunit "Probe Observer";
        Util: Codeunit "W7 Stream Util";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Result: Text;
        CodeValue: Code[10];
        Count: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.Write('');
        OutS.Write('ab');
        Observer.Observe('bytes written', Util.Hex(TempBlob));
        TempBlob.CreateInStream(InS);
        Count := InS.Read(Result);
        Observer.Observe('empty returned', Format(Count));
        Observer.Observe('empty', Util.Codes(Result));
        Count := InS.Read(CodeValue);
        Observer.Observe('code returned', Format(Count));
        Observer.Observe('code', CodeValue);
        Observer.Expect('bytes written', '00 61 62 00');
        Observer.Expect('empty returned', '1');
        Observer.Expect('empty', '');
        Observer.Expect('code returned', '3');
        Observer.Expect('code', 'AB');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_NonAsciiCharacters()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.Write('a' + Ch(233) + Ch(8364) + 'z');
        ReadWhole(Observer, 'Write(Text) of non-ASCII, UTF8 stream read as UTF8', TempBlob, TextEncoding::UTF8);
        ReadWhole(Observer, 'Write(Text) of non-ASCII, UTF8 stream read as Windows', TempBlob, TextEncoding::Windows);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::Windows);
        OutS.Write('a' + Ch(233) + Ch(8364) + 'z');
        ReadWhole(Observer, 'Write(Text) of non-ASCII, Windows stream read as Windows', TempBlob, TextEncoding::Windows);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('a' + Ch(233) + Ch(8364) + 'z');
        ReadWhole(Observer, 'WriteText of non-ASCII, UTF8 stream read as UTF8', TempBlob, TextEncoding::UTF8);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF16);
        OutS.Write('ab');
        ReadWhole(Observer, 'Write(Text), UTF16 stream read as UTF16', TempBlob, TextEncoding::UTF16);
        Observer.Expect('Write(Text) of non-ASCII, UTF8 stream read as UTF8 returned', '8');
        Observer.Expect('Write(Text) of non-ASCII, UTF8 stream read as UTF8 codes', '97 233 8364 122');
        Observer.Expect('Write(Text) of non-ASCII, UTF8 stream read as UTF8 at end', 'Yes');
        Observer.Expect('Write(Text) of non-ASCII, UTF8 stream read as Windows returned', '8');
        Observer.Expect('Write(Text) of non-ASCII, UTF8 stream read as Windows codes', '97 195 169 226 8218 172 122');
        Observer.Expect('Write(Text) of non-ASCII, UTF8 stream read as Windows at end', 'Yes');
        Observer.Expect('Write(Text) of non-ASCII, Windows stream read as Windows returned', '5');
        Observer.Expect('Write(Text) of non-ASCII, Windows stream read as Windows codes', '97 233 8364 122');
        Observer.Expect('Write(Text) of non-ASCII, Windows stream read as Windows at end', 'Yes');
        Observer.Expect('WriteText of non-ASCII, UTF8 stream read as UTF8 returned', '8');
        Observer.Expect('WriteText of non-ASCII, UTF8 stream read as UTF8 codes', '97 233 8364 122');
        Observer.Expect('WriteText of non-ASCII, UTF8 stream read as UTF8 at end', 'Yes');
        Observer.Expect('Write(Text), UTF16 stream read as UTF16 returned', '6');
        Observer.Expect('Write(Text), UTF16 stream read as UTF16 codes', '97 98');
        Observer.Expect('Write(Text), UTF16 stream read as UTF16 at end', 'Yes');
        Observer.Verify();
    end;

    local procedure ObserveLength(var Observer: Codeunit "Probe Observer"; Name: Text; var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding; Length: Integer)
    var
        Util: Codeunit "W7 Stream Util";
        InS: InStream;
        Result: Text;
        Count: Integer;
    begin
        TempBlob.CreateInStream(InS, Encoding);
        if TryReadLength(InS, Result, Length, Count) then begin
            Observer.Observe(Name + ' returned', Format(Count));
            Observer.Observe(Name + ' codes', Util.Codes(Result));
        end else begin
            Observer.Observe(Name + ' failed', 'true');
            Observer.ObserveError(Name);
        end;
    end;

    [Test]
    procedure ReadTextWithLength_BytesFrom128To159()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(65); Bytes.Add(128); Bytes.Add(142); Bytes.Add(150); Bytes.Add(159); Bytes.Add(160); Bytes.Add(233); Bytes.Add(66);
        WriteBytes(TempBlob, Bytes);
        ObserveLength(Observer, 'Windows 8 bytes', TempBlob, TextEncoding::Windows, 8);
        ObserveLength(Observer, 'MSDos 8 bytes', TempBlob, TextEncoding::MSDos, 8);
        ObserveLength(Observer, 'UTF8 8 bytes', TempBlob, TextEncoding::UTF8, 8);
        ObserveLength(Observer, 'UTF16 8 bytes', TempBlob, TextEncoding::UTF16, 8);
        ObserveLength(Observer, 'Windows 3 bytes', TempBlob, TextEncoding::Windows, 3);
        ObserveLength(Observer, 'Windows 100 bytes', TempBlob, TextEncoding::Windows, 100);
        Observer.Expect('Windows 8 bytes returned', '8');
        Observer.Expect('Windows 8 bytes codes', '65 8364 381 8211 376 160 233 66');
        Observer.Expect('MSDos 8 bytes returned', '8');
        Observer.Expect('MSDos 8 bytes codes', '65 199 196 251 402 225 210 66');
        Observer.Expect('UTF8 8 bytes failed', 'true');
        Observer.Expect('UTF8 8 bytes|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('UTF8 8 bytes|code', 'InvalidStreamData');
        Observer.Expect('UTF16 8 bytes returned', '10');
        Observer.Expect('UTF16 8 bytes codes', '32833 38542 41119 17129');
        Observer.Expect('Windows 3 bytes returned', '3');
        Observer.Expect('Windows 3 bytes codes', '65 8364 381');
        Observer.Expect('Windows 100 bytes returned', '8');
        Observer.Expect('Windows 100 bytes codes', '65 8364 381 8211 376 160 233 66');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextWithLength_Utf8Sequences()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        // a, e-acute (C3 A9), euro (E2 82 AC), b
        Bytes.Add(97); Bytes.Add(195); Bytes.Add(169); Bytes.Add(226); Bytes.Add(130); Bytes.Add(172); Bytes.Add(98);
        WriteBytes(TempBlob, Bytes);
        ObserveLength(Observer, 'UTF8 7 bytes', TempBlob, TextEncoding::UTF8, 7);
        ObserveLength(Observer, 'UTF8 3 bytes', TempBlob, TextEncoding::UTF8, 3);
        ObserveLength(Observer, 'UTF8 2 bytes', TempBlob, TextEncoding::UTF8, 2);
        ObserveLength(Observer, 'UTF8 5 bytes', TempBlob, TextEncoding::UTF8, 5);
        ObserveLength(Observer, 'Windows 7 bytes', TempBlob, TextEncoding::Windows, 7);
        ObserveLength(Observer, 'MSDos 7 bytes', TempBlob, TextEncoding::MSDos, 7);
        Observer.Expect('UTF8 7 bytes returned', '8');
        Observer.Expect('UTF8 7 bytes codes', '97 233 8364 98');
        Observer.Expect('UTF8 3 bytes returned', '7');
        Observer.Expect('UTF8 3 bytes codes', '97 233 8364');
        Observer.Expect('UTF8 2 bytes returned', '4');
        Observer.Expect('UTF8 2 bytes codes', '97 233');
        Observer.Expect('UTF8 5 bytes returned', '8');
        Observer.Expect('UTF8 5 bytes codes', '97 233 8364 98');
        Observer.Expect('Windows 7 bytes returned', '7');
        Observer.Expect('Windows 7 bytes codes', '97 195 169 226 8218 172 98');
        Observer.Expect('MSDos 7 bytes returned', '7');
        Observer.Expect('MSDos 7 bytes codes', '97 8220 20 203 233 188 98');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextWithLength_AsciiAndZeroByte()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(97); Bytes.Add(98); Bytes.Add(0); Bytes.Add(99); Bytes.Add(100);
        WriteBytes(TempBlob, Bytes);
        ObserveLength(Observer, 'UTF8 5 bytes with a zero byte', TempBlob, TextEncoding::UTF8, 5);
        ObserveLength(Observer, 'Windows 5 bytes with a zero byte', TempBlob, TextEncoding::Windows, 5);
        ObserveLength(Observer, 'UTF8 0 bytes', TempBlob, TextEncoding::UTF8, 0);
        ObserveLength(Observer, 'UTF8 2 bytes', TempBlob, TextEncoding::UTF8, 2);
        Observer.Expect('UTF8 5 bytes with a zero byte returned', '3');
        Observer.Expect('UTF8 5 bytes with a zero byte codes', '97 98');
        Observer.Expect('Windows 5 bytes with a zero byte returned', '3');
        Observer.Expect('Windows 5 bytes with a zero byte codes', '97 98');
        Observer.Expect('UTF8 0 bytes returned', '1');
        Observer.Expect('UTF8 0 bytes codes', '');
        Observer.Expect('UTF8 2 bytes returned', '3');
        Observer.Expect('UTF8 2 bytes codes', '97 98');
        Observer.Verify();
    end;

    // Writer SN (2026-10-25, runtime hand-off refuse-json-streams "InStream.Read(Text, Length) results on UTF-8"): ReadTextWithLength_Utf8Sequences
    // pins the returned count and the text; here also what is left in the stream after the read (read with a second Read(Text) and with
    // Read(Byte)), so the bytes one Read(Text, Length) consumes are visible.
    local procedure ObserveLengthAndRest(var Observer: Codeunit "Probe Observer"; Name: Text; var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding; Length: Integer)
    var
        Util: Codeunit "W7 Stream Util";
        InS: InStream;
        Result: Text;
        Rest: Text;
        B: Byte;
        Count: Integer;
    begin
        TempBlob.CreateInStream(InS, Encoding);
        Count := InS.Read(Result, Length);
        Observer.Observe(Name + ' returned', Format(Count) + ' ' + Util.Codes(Result) + ' eos ' + Format(InS.EOS()));
        Count := InS.Read(Rest);
        Observer.Observe(Name + ' rest', Format(Count) + ' ' + Util.Codes(Rest));
        TempBlob.CreateInStream(InS, Encoding);
        InS.Read(Result, Length);
        if InS.EOS() then
            Observer.Observe(Name + ' next byte', 'eos')
        else begin
            InS.Read(B);
            Observer.Observe(Name + ' next byte', Format(B));
        end;
    end;

    [Test]
    procedure ReadTextWithLength_Utf8_WhatIsConsumed()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        // a, e-acute (C3 A9), euro (E2 82 AC), b
        Bytes.Add(97); Bytes.Add(195); Bytes.Add(169); Bytes.Add(226); Bytes.Add(130); Bytes.Add(172); Bytes.Add(98);
        WriteBytes(TempBlob, Bytes);
        ObserveLengthAndRest(Observer, 'n1', TempBlob, TextEncoding::UTF8, 1);
        ObserveLengthAndRest(Observer, 'n2', TempBlob, TextEncoding::UTF8, 2);
        ObserveLengthAndRest(Observer, 'n3', TempBlob, TextEncoding::UTF8, 3);
        ObserveLengthAndRest(Observer, 'n4', TempBlob, TextEncoding::UTF8, 4);
        ObserveLengthAndRest(Observer, 'n5', TempBlob, TextEncoding::UTF8, 5);
        Observer.Expect('n1 returned', '2 97 eos No');
        Observer.Expect('n1 rest', '7 233 8364 98');
        Observer.Expect('n1 next byte', '“');
        Observer.Expect('n2 returned', '4 97 233 eos No');
        Observer.Expect('n2 rest', '5 8364 98');
        Observer.Expect('n2 next byte', 'Ë');
        Observer.Expect('n3 returned', '7 97 233 8364 eos No');
        Observer.Expect('n3 rest', '2 98');
        Observer.Expect('n3 next byte', 'b');
        Observer.Expect('n4 returned', '8 97 233 8364 98 eos Yes');
        Observer.Expect('n4 rest', '1 ');
        Observer.Expect('n4 next byte', 'eos');
        Observer.Expect('n5 returned', '8 97 233 8364 98 eos Yes');
        Observer.Expect('n5 rest', '1 ');
        Observer.Expect('n5 next byte', 'eos');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextWithLength_Utf16_WhatIsConsumed()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        // UTF-16 LE: a (61 00), e-acute (E9 00), euro (AC 20), b (62 00), no terminator
        Bytes.Add(97); Bytes.Add(0); Bytes.Add(233); Bytes.Add(0); Bytes.Add(172); Bytes.Add(32); Bytes.Add(98); Bytes.Add(0);
        WriteBytes(TempBlob, Bytes);
        ObserveLengthAndRest(Observer, 'u1', TempBlob, TextEncoding::UTF16, 1);
        ObserveLengthAndRest(Observer, 'u2', TempBlob, TextEncoding::UTF16, 2);
        ObserveLengthAndRest(Observer, 'u4', TempBlob, TextEncoding::UTF16, 4);
        ObserveLengthAndRest(Observer, 'u6', TempBlob, TextEncoding::UTF16, 6);
        Observer.Expect('u1 returned', '4 97 eos No');
        Observer.Expect('u1 rest', '8 233 8364 98');
        Observer.Expect('u1 next byte', 'Ò');
        Observer.Expect('u2 returned', '6 97 233 eos No');
        Observer.Expect('u2 rest', '6 8364 98');
        Observer.Expect('u2 next byte', '¼');
        Observer.Expect('u4 returned', '10 97 233 8364 98 eos Yes');
        Observer.Expect('u4 rest', '2 ');
        Observer.Expect('u4 next byte', 'eos');
        Observer.Expect('u6 returned', '10 97 233 8364 98 eos Yes');
        Observer.Expect('u6 rest', '2 ');
        Observer.Expect('u6 next byte', 'eos');
        Observer.Verify();
    end;
}
