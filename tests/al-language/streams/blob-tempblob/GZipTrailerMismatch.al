// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit-system-data-compression-data-compression
// Scope: in-scope (System Application "Data Compression", GZipDecompress over a Temp Blob OutStream)
// Fixtures used: Probe Observer (69160); own codeunit 75290
// Probe: written against local BC service tiers; every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: FACTS_PLACEHOLDER
// BC versions: VERSIONS_PLACEHOLDER

codeunit 75290 "GZZ GZip Trailer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Compress(Plain: Codeunit "Temp Blob"; var Packed: Codeunit "Temp Blob")
    var
        Compression: Codeunit "Data Compression";
        InS: InStream;
        OutS: OutStream;
    begin
        Plain.CreateInStream(InS);
        Packed.CreateOutStream(OutS);
        Compression.GZipCompress(InS, OutS);
    end;

    local procedure Decompress(Packed: Codeunit "Temp Blob"; var Plain: Codeunit "Temp Blob")
    var
        Compression: Codeunit "Data Compression";
        InS: InStream;
        OutS: OutStream;
    begin
        Packed.CreateInStream(InS);
        Plain.CreateOutStream(OutS);
        Compression.GZipDecompress(InS, OutS);
    end;

    [TryFunction]
    local procedure TryDecompress(Packed: Codeunit "Temp Blob"; var Plain: Codeunit "Temp Blob")
    begin
        Decompress(Packed, Plain);
    end;

    // N bytes of ASCII text: the letters a..z repeated, restarting every 4096 bytes.
    local procedure PatternBlob(N: Integer; var Blob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
        Chunk: TextBuilder;
        ChunkText: Text;
        Alphabet: Text;
        i: Integer;
    begin
        Alphabet := 'abcdefghijklmnopqrstuvwxyz';
        for i := 0 to 4095 do
            Chunk.Append(CopyStr(Alphabet, (i mod 26) + 1, 1));
        ChunkText := Chunk.ToText();
        Blob.CreateOutStream(OutS, TextEncoding::UTF8);
        for i := 1 to N div 4096 do
            OutS.WriteText(ChunkText);
        if N mod 4096 > 0 then
            OutS.WriteText(CopyStr(ChunkText, 1, N mod 4096));
    end;

    // N pseudo-random bytes (a fixed linear congruential sequence of period 65536, longer than the deflate window), which deflate cannot shrink.
    local procedure NoiseBlob(N: Integer; var Blob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
        Seed: Integer;
        B: Byte;
        i: Integer;
    begin
        Seed := 12345;
        Blob.CreateOutStream(OutS);
        for i := 1 to N do begin
            Seed := (Seed * 1105 + 12345) mod 65536;
            B := Seed div 256;
            OutS.Write(B);
        end;
    end;

    local procedure TextBlob(Value: Text; var Blob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        Blob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Value);
    end;

    local procedure BlobOf(Bytes: List of [Integer]; var Blob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
        V: Integer;
        B: Byte;
    begin
        Blob.CreateOutStream(OutS);
        foreach V in Bytes do begin
            B := V;
            OutS.Write(B);
        end;
    end;

    // A copy of Source with the byte at 1-based position Pos replaced by 255 minus it.
    local procedure Flipped(Source: Codeunit "Temp Blob"; Pos: Integer; var Target: Codeunit "Temp Blob")
    var
        InS: InStream;
        OutS: OutStream;
        B: Byte;
    begin
        Source.CreateInStream(InS);
        Target.CreateOutStream(OutS);
        if Pos > 1 then
            CopyStream(OutS, InS, Pos - 1);
        InS.Read(B);
        B := 255 - B;
        OutS.Write(B);
        CopyStream(OutS, InS);
    end;

    // Appends all bytes of Source to OutS.
    local procedure Append(Source: Codeunit "Temp Blob"; var OutS: OutStream)
    var
        InS: InStream;
    begin
        Source.CreateInStream(InS);
        CopyStream(OutS, InS);
    end;

    local procedure AppendByte(V: Integer; var OutS: OutStream)
    var
        B: Byte;
    begin
        B := V;
        OutS.Write(B);
    end;

    // Yes when the first Count bytes of A and B are equal.
    local procedure SamePrefix(A: Codeunit "Temp Blob"; B: Codeunit "Temp Blob"; Count: Integer): Boolean
    var
        InA: InStream;
        InB: InStream;
        X: Byte;
        Y: Byte;
        i: Integer;
    begin
        if (A.Length() < Count) or (B.Length() < Count) then
            exit(false);
        A.CreateInStream(InA);
        B.CreateInStream(InB);
        for i := 1 to Count do begin
            InA.Read(X);
            InB.Read(Y);
            if X <> Y then
                exit(false);
        end;
        exit(true);
    end;

    // ok and the length written, or the error text and code and the length written before the error, and whether those bytes are a
    // prefix of Expected.
    local procedure Outcome(Packed: Codeunit "Temp Blob"; Expected: Codeunit "Temp Blob"): Text
    var
        Back: Codeunit "Temp Blob";
        Ok: Boolean;
        Len: Integer;
    begin
        ClearLastError();
        Ok := TryDecompress(Packed, Back);
        Len := Back.Length();
        if Ok then
            exit('ok len=' + Format(Len) + ' prefix=' + Format(SamePrefix(Back, Expected, Len)));
        exit('error:' + CopyStr(GetLastErrorText(), 1, 250) + '|' + GetLastErrorCode() + ' len=' + Format(Len) + ' prefix=' + Format(SamePrefix(Back, Expected, Len)));
    end;

    // Valid member, first CRC32 byte flipped, low ISIZE byte flipped, for a member of N decoded pattern bytes.
    local procedure TrailerCells(N: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Bad: Codeunit "Temp Blob";
        Len: Integer;
    begin
        PatternBlob(N, Plain);
        Compress(Plain, Packed);
        Len := Packed.Length();
        Observer.Observe(Prefix + 'plain_len', Format(Plain.Length()));
        Observer.Observe(Prefix + 'valid', Outcome(Packed, Plain));
        Flipped(Packed, Len - 7, Bad);
        Observer.Observe(Prefix + 'crc_wrong', Outcome(Bad, Plain));
        Clear(Bad);
        Flipped(Packed, Len - 3, Bad);
        Observer.Observe(Prefix + 'isize_wrong', Outcome(Bad, Plain));
    end;

    // An empty member written by hand: header, an empty final stored block (03 00), then CRC32 and ISIZE.
    local procedure EmptyMember(Crc0: Integer; Size0: Integer; var Blob: Codeunit "Temp Blob")
    var
        Bytes: List of [Integer];
        i: Integer;
    begin
        Bytes.Add(31);
        Bytes.Add(139);
        Bytes.Add(8);
        for i := 1 to 7 do
            Bytes.Add(0);
        Bytes.Add(3);
        Bytes.Add(0);
        Bytes.Add(Crc0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(Size0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        BlobOf(Bytes, Blob);
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size0()
    var
        Observer: Codeunit "Probe Observer";
        Packed: Codeunit "Temp Blob";
        Empty: Codeunit "Temp Blob";
    begin
        EmptyMember(0, 0, Packed);
        Observer.Observe('valid', Outcome(Packed, Empty));
        Clear(Packed);
        EmptyMember(1, 0, Packed);
        Observer.Observe('crc_wrong', Outcome(Packed, Empty));
        Clear(Packed);
        EmptyMember(0, 1, Packed);
        Observer.Observe('isize_wrong', Outcome(Packed, Empty));
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(1, '', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size40()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(40, '', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size83()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(83, '', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size8192()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(8192, '', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size65536()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(65536, '', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size81920()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(81919, 'n81919_', Observer);
        TrailerCells(81920, 'n81920_', Observer);
        TrailerCells(81921, 'n81921_', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size163840()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(163840, 'n163840_', Observer);
        TrailerCells(163841, 'n163841_', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size1MB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(1048576, '', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_Noise1MB_TrailerAndMiddle()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Bad: Codeunit "Temp Blob";
        Len: Integer;
    begin
        NoiseBlob(1048576, Plain);
        Compress(Plain, Packed);
        Len := Packed.Length();
        Observer.Observe('packed_not_smaller', Format(Len >= Plain.Length()));
        Observer.Observe('valid', Outcome(Packed, Plain));
        Flipped(Packed, Len - 7, Bad);
        Observer.Observe('crc_wrong', Outcome(Bad, Plain));
        Clear(Bad);
        Flipped(Packed, Len div 2, Bad);
        Observer.Observe('middle_byte_flipped', Outcome(Bad, Plain));
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_Pattern1MB_MiddleCorrupt()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Bad: Codeunit "Temp Blob";
        Len: Integer;
    begin
        PatternBlob(1048576, Plain);
        Compress(Plain, Packed);
        Len := Packed.Length();
        Flipped(Packed, Len div 2, Bad);
        Observer.Observe('middle_byte_flipped', Outcome(Bad, Plain));
        Clear(Bad);
        Flipped(Packed, 12, Bad);
        Observer.Observe('byte_12_flipped', Outcome(Bad, Plain));
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TwoMembers_SecondCrcWrong()
    var
        Observer: Codeunit "Probe Observer";
        PlainA: Codeunit "Temp Blob";
        PlainB: Codeunit "Temp Blob";
        PlainAB: Codeunit "Temp Blob";
        PackedA: Codeunit "Temp Blob";
        PackedB: Codeunit "Temp Blob";
        BadA: Codeunit "Temp Blob";
        BadB: Codeunit "Temp Blob";
        Joined: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TextBlob('first member;', PlainA);
        TextBlob('second member', PlainB);
        TextBlob('first member;second member', PlainAB);
        Compress(PlainA, PackedA);
        Compress(PlainB, PackedB);
        Flipped(PackedA, PackedA.Length() - 7, BadA);
        Flipped(PackedB, PackedB.Length() - 7, BadB);
        Joined.CreateOutStream(OutS);
        Append(PackedA, OutS);
        Append(BadB, OutS);
        Observer.Observe('good_then_crc_wrong', Outcome(Joined, PlainAB));
        Clear(Joined);
        Joined.CreateOutStream(OutS);
        Append(BadA, OutS);
        Append(PackedB, OutS);
        Observer.Observe('crc_wrong_then_good', Outcome(Joined, PlainAB));
        Clear(BadB);
        Flipped(PackedB, PackedB.Length() - 3, BadB);
        Clear(Joined);
        Joined.CreateOutStream(OutS);
        Append(PackedA, OutS);
        Append(BadB, OutS);
        Observer.Observe('good_then_isize_wrong', Outcome(Joined, PlainAB));
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_TwoMembers_LargeFirst_SecondCrcWrong()
    var
        Observer: Codeunit "Probe Observer";
        PlainA: Codeunit "Temp Blob";
        PlainB: Codeunit "Temp Blob";
        PackedA: Codeunit "Temp Blob";
        PackedB: Codeunit "Temp Blob";
        BadB: Codeunit "Temp Blob";
        Joined: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        PatternBlob(200000, PlainA);
        TextBlob('second member', PlainB);
        Compress(PlainA, PackedA);
        Compress(PlainB, PackedB);
        Flipped(PackedB, PackedB.Length() - 7, BadB);
        Joined.CreateOutStream(OutS);
        Append(PackedA, OutS);
        Append(BadB, OutS);
        Observer.Observe('large_good_then_crc_wrong', Outcome(Joined, PlainA));
        Clear(Joined);
        Joined.CreateOutStream(OutS);
        Append(PackedA, OutS);
        Append(PackedB, OutS);
        Observer.Observe('large_good_then_good_len', Outcome(Joined, PlainA));
        Observer.Finish();
    end;

    // Packed with the flag byte set to Flags and the Extra bytes inserted after the 10 header bytes.
    local procedure WithHeaderField(Packed: Codeunit "Temp Blob"; Flags: Integer; Extra: List of [Integer]; var Target: Codeunit "Temp Blob")
    var
        InS: InStream;
        OutS: OutStream;
        B: Byte;
        V: Integer;
        i: Integer;
    begin
        Packed.CreateInStream(InS);
        Target.CreateOutStream(OutS);
        for i := 1 to 10 do begin
            InS.Read(B);
            if i = 4 then
                B := Flags;
            OutS.Write(B);
        end;
        foreach V in Extra do
            AppendByte(V, OutS);
        CopyStream(OutS, InS);
    end;

    local procedure NameBytes(var Extra: List of [Integer])
    begin
        Extra.Add(97);
        Extra.Add(46);
        Extra.Add(116);
        Extra.Add(120);
        Extra.Add(116);
        Extra.Add(0);
    end;

    [Test]
    procedure GZipDecompress_HeaderFields_Trailer()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        BadCrc: Codeunit "Temp Blob";
        Shaped: Codeunit "Temp Blob";
        Extra: List of [Integer];
    begin
        TextBlob('corrupt me after the header corrupt me after the header corrupt me after the header', Plain);
        Compress(Plain, Packed);
        Flipped(Packed, Packed.Length() - 7, BadCrc);
        NameBytes(Extra);
        WithHeaderField(Packed, 8, Extra, Shaped);
        Observer.Observe('fname_valid', Outcome(Shaped, Plain));
        Clear(Shaped);
        WithHeaderField(BadCrc, 8, Extra, Shaped);
        Observer.Observe('fname_crc_wrong', Outcome(Shaped, Plain));
        Clear(Shaped);
        WithHeaderField(Packed, 16, Extra, Shaped);
        Observer.Observe('fcomment_valid', Outcome(Shaped, Plain));
        Clear(Shaped);
        WithHeaderField(BadCrc, 16, Extra, Shaped);
        Observer.Observe('fcomment_crc_wrong', Outcome(Shaped, Plain));
        Clear(Extra);
        Extra.Add(2);
        Extra.Add(0);
        Extra.Add(65);
        Extra.Add(66);
        Clear(Shaped);
        WithHeaderField(Packed, 4, Extra, Shaped);
        Observer.Observe('fextra_valid', Outcome(Shaped, Plain));
        Clear(Shaped);
        WithHeaderField(BadCrc, 4, Extra, Shaped);
        Observer.Observe('fextra_crc_wrong', Outcome(Shaped, Plain));
        Clear(Extra);
        Extra.Add(0);
        Extra.Add(0);
        Clear(Shaped);
        WithHeaderField(Packed, 2, Extra, Shaped);
        Observer.Observe('fhcrc_zero_valid_trailer', Outcome(Shaped, Plain));
        Observer.Finish();
    end;

    [Test]
    procedure GZipDecompress_ThreeAndFourByteStreams()
    var
        Observer: Codeunit "Probe Observer";
        Packed: Codeunit "Temp Blob";
        Empty: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(31);
        Bytes.Add(139);
        Bytes.Add(8);
        BlobOf(Bytes, Packed);
        Observer.Observe('3_method8', Outcome(Packed, Empty));
        Clear(Packed);
        Bytes.Set(3, 99);
        BlobOf(Bytes, Packed);
        Observer.Observe('3_method99', Outcome(Packed, Empty));
        Clear(Packed);
        Bytes.Set(3, 0);
        BlobOf(Bytes, Packed);
        Observer.Observe('3_method0', Outcome(Packed, Empty));
        Clear(Packed);
        Bytes.Set(3, 8);
        Bytes.Add(0);
        BlobOf(Bytes, Packed);
        Observer.Observe('4_method8_flags0', Outcome(Packed, Empty));
        Clear(Packed);
        Bytes.Set(3, 99);
        BlobOf(Bytes, Packed);
        Observer.Observe('4_method99_flags0', Outcome(Packed, Empty));
        Clear(Packed);
        Bytes.Set(3, 8);
        Bytes.Set(4, 8);
        BlobOf(Bytes, Packed);
        Observer.Observe('4_method8_flags8', Outcome(Packed, Empty));
        Clear(Packed);
        Bytes.Set(4, 224);
        BlobOf(Bytes, Packed);
        Observer.Observe('4_method8_reserved_flags', Outcome(Packed, Empty));
        Observer.Finish();
    end;
}
