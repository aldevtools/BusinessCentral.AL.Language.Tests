// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-read-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 67081
// Corpus issue (al-runner, InStream.Read into a Text): one test per byte content (empty, ASCII with and without the zero terminator,
// UTF-8 and Latin-1 bytes, a truncated UTF-8 sequence, CR LF, UTF-16 bytes, byte order marks). Each reads the content with Read(Text), Read(Text, 0)
// and Read(Text, 3) on a stream with the default encoding and with UTF8, UTF16, MSDos and Windows. It records the returned count, the character
// codes, EOS, and what a second Read(Text) returns for the rest. An error is recorded with its text and code.
// Probe: observed on the BC 29 SaaS sandbox through the test runner hub (2026-10-30); every literal asserted below is what it produced. Other majors are checked by the CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 67081 "LT TF Stream Read Matrix"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            if i > 1 then
                Result += ' ';
            Code := Value[i];
            Result += Format(Code);
        end;
        exit(Result);
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
    local procedure TryRead(var InS: InStream; var Result: Text; var Count: Integer; Length: Integer)
    begin
        if Length < 0 then
            Count := InS.Read(Result)
        else
            Count := InS.Read(Result, Length);
    end;

    local procedure Run(Name: Text; var TempBlob: Codeunit "Temp Blob"; Encoding: Integer; Length: Integer)
    var
        InS: InStream;
        Result: Text;
        Rest: Text;
        Count: Integer;
        RestCount: Integer;
        Info: Text;
    begin
        case Encoding of
            0:
                TempBlob.CreateInStream(InS);
            1:
                TempBlob.CreateInStream(InS, TextEncoding::UTF8);
            2:
                TempBlob.CreateInStream(InS, TextEncoding::UTF16);
            3:
                TempBlob.CreateInStream(InS, TextEncoding::MSDos);
            4:
                TempBlob.CreateInStream(InS, TextEncoding::Windows);
        end;
        Result := 'unset';
        if not TryRead(InS, Result, Count, Length) then begin
            Observer.Observe(Name, 'error');
            Observer.ObserveError(Name);
            exit;
        end;
        Info := Format(Count) + ' [' + Codes(Result) + '] eos ' + Format(InS.EOS());
        if not InS.EOS() then begin
            Rest := 'unset';
            if TryRead(InS, Rest, RestCount, -1) then
                Info += ' rest ' + Format(RestCount) + ' [' + Codes(Rest) + ']'
            else
                Info += ' rest error';
        end;
        Observer.Observe(Name, Info);
    end;

    local procedure RunAll(var TempBlob: Codeunit "Temp Blob")
    var
        Enc: Integer;
        Names: List of [Text];
        Lengths: List of [Integer];
        i: Integer;
    begin
        Names.Add('def'); Names.Add('u8'); Names.Add('u16'); Names.Add('dos'); Names.Add('win');
        Lengths.Add(-1); Lengths.Add(0); Lengths.Add(3);
        for Enc := 0 to 4 do
            for i := 1 to Lengths.Count() do
                Run(Names.Get(Enc + 1) + ' len ' + Format(Lengths.Get(i)), TempBlob, Enc, Lengths.Get(i));
    end;

    [Test]
    procedure Matrix_Empty()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '0 [] eos Yes');
        Observer.Expect('def len 0', '0 [] eos Yes');
        Observer.Expect('def len 3', '0 [] eos Yes');
        Observer.Expect('u8 len -1', '1 [] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos Yes');
        Observer.Expect('u8 len 3', '1 [] eos Yes');
        Observer.Expect('u16 len -1', '2 [] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos Yes');
        Observer.Expect('u16 len 3', '2 [] eos Yes');
        Observer.Expect('dos len -1', '0 [] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos Yes');
        Observer.Expect('dos len 3', '0 [] eos Yes');
        Observer.Expect('win len -1', '0 [] eos Yes');
        Observer.Expect('win len 0', '0 [] eos Yes');
        Observer.Expect('win len 3', '0 [] eos Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_Abc()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(97);
        Bytes.Add(98);
        Bytes.Add(99);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '3 [97 98 99] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 3 [97 98 99]');
        Observer.Expect('def len 3', '3 [97 98 99] eos Yes');
        Observer.Expect('u8 len -1', '4 [97 98 99] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos No rest 4 [97 98 99]');
        Observer.Expect('u8 len 3', '4 [97 98 99] eos Yes');
        Observer.Expect('u16 len -1', '4 [25185] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 4 [25185]');
        Observer.Expect('u16 len 3', '4 [25185] eos Yes');
        Observer.Expect('dos len -1', '3 [97 98 99] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 3 [97 98 99]');
        Observer.Expect('dos len 3', '3 [97 98 99] eos Yes');
        Observer.Expect('win len -1', '3 [97 98 99] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 3 [97 98 99]');
        Observer.Expect('win len 3', '3 [97 98 99] eos Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_AbcZero()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(97);
        Bytes.Add(98);
        Bytes.Add(99);
        Bytes.Add(0);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '4 [97 98 99] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 4 [97 98 99]');
        Observer.Expect('def len 3', '4 [97 98 99] eos Yes');
        Observer.Expect('u8 len -1', '4 [97 98 99] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos No rest 4 [97 98 99]');
        Observer.Expect('u8 len 3', '4 [97 98 99] eos No rest 1 []');
        Observer.Expect('u16 len -1', '6 [25185 99] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 6 [25185 99]');
        Observer.Expect('u16 len 3', '6 [25185 99] eos Yes');
        Observer.Expect('dos len -1', '4 [97 98 99] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 4 [97 98 99]');
        Observer.Expect('dos len 3', '4 [97 98 99] eos Yes');
        Observer.Expect('win len -1', '4 [97 98 99] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 4 [97 98 99]');
        Observer.Expect('win len 3', '4 [97 98 99] eos Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_AbcZeroDef()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(97);
        Bytes.Add(98);
        Bytes.Add(99);
        Bytes.Add(0);
        Bytes.Add(100);
        Bytes.Add(101);
        Bytes.Add(102);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '4 [97 98 99] eos No rest 3 [100 101 102]');
        Observer.Expect('def len 0', '0 [] eos No rest 4 [97 98 99]');
        Observer.Expect('def len 3', '4 [97 98 99] eos No rest 3 [100 101 102]');
        Observer.Expect('u8 len -1', '4 [97 98 99] eos No rest 4 [100 101 102]');
        Observer.Expect('u8 len 0', '1 [] eos No rest 4 [97 98 99]');
        Observer.Expect('u8 len 3', '4 [97 98 99] eos No rest 1 []');
        Observer.Expect('u16 len -1', '8 [25185 99 25956] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 8 [25185 99 25956]');
        Observer.Expect('u16 len 3', '8 [25185 99 25956] eos No rest 2 []');
        Observer.Expect('dos len -1', '4 [97 98 99] eos No rest 3 [100 101 102]');
        Observer.Expect('dos len 0', '0 [] eos No rest 4 [97 98 99]');
        Observer.Expect('dos len 3', '4 [97 98 99] eos No rest 3 [100 101 102]');
        Observer.Expect('win len -1', '4 [97 98 99] eos No rest 3 [100 101 102]');
        Observer.Expect('win len 0', '0 [] eos No rest 4 [97 98 99]');
        Observer.Expect('win len 3', '4 [97 98 99] eos No rest 3 [100 101 102]');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_TwoZeros()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(0);
        Bytes.Add(0);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '1 [] eos No rest 1 []');
        Observer.Expect('def len 0', '1 [] eos No rest 1 []');
        Observer.Expect('def len 3', '1 [] eos No rest 1 []');
        Observer.Expect('u8 len -1', '1 [] eos No rest 1 []');
        Observer.Expect('u8 len 0', '1 [] eos No rest 1 []');
        Observer.Expect('u8 len 3', '1 [] eos No rest 1 []');
        Observer.Expect('u16 len -1', '2 [] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 2 []');
        Observer.Expect('u16 len 3', '2 [] eos Yes');
        Observer.Expect('dos len -1', '1 [] eos No rest 1 []');
        Observer.Expect('dos len 0', '1 [] eos No rest 1 []');
        Observer.Expect('dos len 3', '1 [] eos No rest 1 []');
        Observer.Expect('win len -1', '1 [] eos No rest 1 []');
        Observer.Expect('win len 0', '1 [] eos No rest 1 []');
        Observer.Expect('win len 3', '1 [] eos No rest 1 []');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_EacuteUtf8()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(195);
        Bytes.Add(169);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '2 [8220 20] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 2 [8220 20]');
        Observer.Expect('def len 3', '2 [8220 20] eos Yes');
        Observer.Expect('u8 len -1', '3 [233] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos No rest 3 [233]');
        Observer.Expect('u8 len 3', '3 [233] eos Yes');
        Observer.Expect('u16 len -1', '4 [43459] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 4 [43459]');
        Observer.Expect('u16 len 3', '4 [43459] eos Yes');
        Observer.Expect('dos len -1', '2 [8220 20] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 2 [8220 20]');
        Observer.Expect('dos len 3', '2 [8220 20] eos Yes');
        Observer.Expect('win len -1', '2 [195 169] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 2 [195 169]');
        Observer.Expect('win len 3', '2 [195 169] eos Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_EacuteLatin1()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(233);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '1 [210] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 1 [210]');
        Observer.Expect('def len 3', '1 [210] eos Yes');
        Observer.Expect('u8 len -1', '1 [] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos No rest 1 []');
        Observer.Expect('u8 len 3', '1 [] eos Yes');
        Observer.Expect('u16 len -1', '2 [] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 2 []');
        Observer.Expect('u16 len 3', '2 [] eos Yes');
        Observer.Expect('dos len -1', '1 [210] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 1 [210]');
        Observer.Expect('dos len 3', '1 [210] eos Yes');
        Observer.Expect('win len -1', '1 [233] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 1 [233]');
        Observer.Expect('win len 3', '1 [233] eos Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_ByteFF()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(255);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '1 [160] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 1 [160]');
        Observer.Expect('def len 3', '1 [160] eos Yes');
        Observer.Expect('u8 len -1', 'error');
        Observer.Expect('u8 len -1|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('u8 len -1|code', 'InvalidStreamData');
        Observer.Expect('u8 len 0', '1 [] eos No rest error');
        Observer.Expect('u8 len 3', 'error');
        Observer.Expect('u8 len 3|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('u8 len 3|code', 'InvalidStreamData');
        Observer.Expect('u16 len -1', '2 [] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 2 []');
        Observer.Expect('u16 len 3', '2 [] eos Yes');
        Observer.Expect('dos len -1', '1 [160] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 1 [160]');
        Observer.Expect('dos len 3', '1 [160] eos Yes');
        Observer.Expect('win len -1', '1 [255] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 1 [255]');
        Observer.Expect('win len 3', '1 [255] eos Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_TruncatedUtf8()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(97);
        Bytes.Add(195);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '2 [97 8220] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 2 [97 8220]');
        Observer.Expect('def len 3', '2 [97 8220] eos Yes');
        Observer.Expect('u8 len -1', '2 [97] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos No rest 2 [97]');
        Observer.Expect('u8 len 3', '2 [97] eos Yes');
        Observer.Expect('u16 len -1', '4 [50017] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 4 [50017]');
        Observer.Expect('u16 len 3', '4 [50017] eos Yes');
        Observer.Expect('dos len -1', '2 [97 8220] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 2 [97 8220]');
        Observer.Expect('dos len 3', '2 [97 8220] eos Yes');
        Observer.Expect('win len -1', '2 [97 195] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 2 [97 195]');
        Observer.Expect('win len 3', '2 [97 195] eos Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_Crlf()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(97);
        Bytes.Add(13);
        Bytes.Add(10);
        Bytes.Add(98);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '4 [97 13 10 98] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 4 [97 13 10 98]');
        Observer.Expect('def len 3', '3 [97 13 10] eos No rest 1 [98]');
        Observer.Expect('u8 len -1', '5 [97 13 10 98] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos No rest 5 [97 13 10 98]');
        Observer.Expect('u8 len 3', '4 [97 13 10] eos No rest 2 [98]');
        Observer.Expect('u16 len -1', '6 [3425 25098] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 6 [3425 25098]');
        Observer.Expect('u16 len 3', '6 [3425 25098] eos Yes');
        Observer.Expect('dos len -1', '4 [97 13 10 98] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 4 [97 13 10 98]');
        Observer.Expect('dos len 3', '3 [97 13 10] eos No rest 1 [98]');
        Observer.Expect('win len -1', '4 [97 13 10 98] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 4 [97 13 10 98]');
        Observer.Expect('win len 3', '3 [97 13 10] eos No rest 1 [98]');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_Utf16Ab()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(97);
        Bytes.Add(0);
        Bytes.Add(98);
        Bytes.Add(0);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '2 [97] eos No rest 2 [98]');
        Observer.Expect('def len 0', '0 [] eos No rest 2 [97]');
        Observer.Expect('def len 3', '2 [97] eos No rest 2 [98]');
        Observer.Expect('u8 len -1', '2 [97] eos No rest 2 [98]');
        Observer.Expect('u8 len 0', '1 [] eos No rest 2 [97]');
        Observer.Expect('u8 len 3', '2 [97] eos No rest 2 [98]');
        Observer.Expect('u16 len -1', '6 [97 98] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 6 [97 98]');
        Observer.Expect('u16 len 3', '6 [97 98] eos Yes');
        Observer.Expect('dos len -1', '2 [97] eos No rest 2 [98]');
        Observer.Expect('dos len 0', '0 [] eos No rest 2 [97]');
        Observer.Expect('dos len 3', '2 [97] eos No rest 2 [98]');
        Observer.Expect('win len -1', '2 [97] eos No rest 2 [98]');
        Observer.Expect('win len 0', '0 [] eos No rest 2 [97]');
        Observer.Expect('win len 3', '2 [97] eos No rest 2 [98]');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_Utf16Odd()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(97);
        Bytes.Add(0);
        Bytes.Add(98);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '2 [97] eos No rest 1 [98]');
        Observer.Expect('def len 0', '0 [] eos No rest 2 [97]');
        Observer.Expect('def len 3', '2 [97] eos No rest 1 [98]');
        Observer.Expect('u8 len -1', '2 [97] eos No rest 2 [98]');
        Observer.Expect('u8 len 0', '1 [] eos No rest 2 [97]');
        Observer.Expect('u8 len 3', '2 [97] eos No rest 2 [98]');
        Observer.Expect('u16 len -1', '4 [97] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 4 [97]');
        Observer.Expect('u16 len 3', '4 [97] eos Yes');
        Observer.Expect('dos len -1', '2 [97] eos No rest 1 [98]');
        Observer.Expect('dos len 0', '0 [] eos No rest 2 [97]');
        Observer.Expect('dos len 3', '2 [97] eos No rest 1 [98]');
        Observer.Expect('win len -1', '2 [97] eos No rest 1 [98]');
        Observer.Expect('win len 0', '0 [] eos No rest 2 [97]');
        Observer.Expect('win len 3', '2 [97] eos No rest 1 [98]');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_EuroUtf8()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(226);
        Bytes.Add(130);
        Bytes.Add(172);
        Bytes.Add(98);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '4 [203 233 188 98] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 4 [203 233 188 98]');
        Observer.Expect('def len 3', '3 [203 233 188] eos No rest 1 [98]');
        Observer.Expect('u8 len -1', '5 [8364 98] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos No rest 5 [8364 98]');
        Observer.Expect('u8 len 3', '5 [8364 98] eos Yes');
        Observer.Expect('u16 len -1', '6 [33506 25260] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 6 [33506 25260]');
        Observer.Expect('u16 len 3', '6 [33506 25260] eos Yes');
        Observer.Expect('dos len -1', '4 [203 233 188 98] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 4 [203 233 188 98]');
        Observer.Expect('dos len 3', '3 [203 233 188] eos No rest 1 [98]');
        Observer.Expect('win len -1', '4 [226 8218 172 98] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 4 [226 8218 172 98]');
        Observer.Expect('win len 3', '3 [226 8218 172] eos No rest 1 [98]');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_Utf8Bom()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(239);
        Bytes.Add(187);
        Bytes.Add(191);
        Bytes.Add(97);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '4 [217 8249 143 97] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 4 [217 8249 143 97]');
        Observer.Expect('def len 3', '3 [217 8249 143] eos No rest 1 [97]');
        Observer.Expect('u8 len -1', '2 [97] eos Yes');
        Observer.Expect('u8 len 0', '1 [] eos No rest 2 [97]');
        Observer.Expect('u8 len 3', '2 [97] eos Yes');
        Observer.Expect('u16 len -1', '6 [48111 25023] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 6 [48111 25023]');
        Observer.Expect('u16 len 3', '6 [48111 25023] eos Yes');
        Observer.Expect('dos len -1', '4 [217 8249 143 97] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 4 [217 8249 143 97]');
        Observer.Expect('dos len 3', '3 [217 8249 143] eos No rest 1 [97]');
        Observer.Expect('win len -1', '4 [239 187 191 97] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 4 [239 187 191 97]');
        Observer.Expect('win len 3', '3 [239 187 191] eos No rest 1 [97]');
        Observer.Verify();
    end;

    [Test]
    procedure Matrix_Utf16Bom()
    var
        TempBlob: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(255);
        Bytes.Add(254);
        Bytes.Add(97);
        Bytes.Add(0);
        WriteBytes(TempBlob, Bytes);
        RunAll(TempBlob);
        Observer.Expect('def len -1', '4 [160 254 97] eos Yes');
        Observer.Expect('def len 0', '0 [] eos No rest 4 [160 254 97]');
        Observer.Expect('def len 3', '4 [160 254 97] eos Yes');
        Observer.Expect('u8 len -1', 'error');
        Observer.Expect('u8 len -1|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('u8 len -1|code', 'InvalidStreamData');
        Observer.Expect('u8 len 0', '1 [] eos No rest error');
        Observer.Expect('u8 len 3', 'error');
        Observer.Expect('u8 len 3|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('u8 len 3|code', 'InvalidStreamData');
        Observer.Expect('u16 len -1', '4 [97] eos Yes');
        Observer.Expect('u16 len 0', '2 [] eos No rest 4 [97]');
        Observer.Expect('u16 len 3', '4 [97] eos Yes');
        Observer.Expect('dos len -1', '4 [160 254 97] eos Yes');
        Observer.Expect('dos len 0', '0 [] eos No rest 4 [160 254 97]');
        Observer.Expect('dos len 3', '4 [160 254 97] eos Yes');
        Observer.Expect('win len -1', '4 [255 254 97] eos Yes');
        Observer.Expect('win len 0', '0 [] eos No rest 4 [255 254 97]');
        Observer.Expect('win len 3', '4 [255 254 97] eos Yes');
        Observer.Verify();
    end;
}
