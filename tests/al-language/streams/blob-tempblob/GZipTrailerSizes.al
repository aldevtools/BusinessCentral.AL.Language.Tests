// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit-system-data-compression-data-compression
// Scope: in-scope (System Application "Data Compression", GZipDecompress over a Temp Blob OutStream)
// Fixtures used: Probe Observer (69160); own codeunit 75295
// Split: this probe is three codeunits, 75290 (GZipTrailerMismatch.al), 75294 (GZipTrailerText1MB.al) and 75295 (GZipTrailerSizes.al), so each one runs in a short time. The facts below cover all three.
// Probe: written against a local BC 27.5 service tier; every literal asserted below is what BC produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GZipDecompress of members whose trailer is wrong, measured per decoded size: a wrong CRC32 or ISIZE field raises "A call to System.IO.Compression.GZipStream.CopyTo
//   failed with this message: The archive entry was compressed using an unsupported compression method." (DotNetInvoke:InvalidData). The bytes written to the OutStream before the
//   error depend on the size: none for members of 0, 1, 2, 40, 82, 83, 8192, 65536, 65537, 81919..81921 and 131072 bytes; 131072 for 131073, 163840, 163841 and 196608 bytes;
//   larger members as asserted (1 MB of text: 917504). Written bytes are always a prefix of the plain data. Pseudo-random members (stored blocks) as asserted per size.
//   Also: a corrupt byte in the middle of a 1 MB member; CRC32 wrong in the second of two members (the first member's bytes are written) or in the first (nothing written);
//   members with FNAME, FCOMMENT or FEXTRA header fields (valid: ok; wrong CRC32: error, nothing written); FHCRC with a zero header CRC (error); 3- and 4-byte streams that
//   start 1F 8B (ok and empty except method 99 with a fourth byte and reserved flag bits); method 99 on a bare 10-byte header and before a valid member (error); a plain header
//   followed by one byte 255, one byte 7, five bytes 65 or 01 00 00 00 00 (error); a valid member cut after the deflate data with 0, 4 or 7 trailer bytes (ok, all bytes) and
//   with a wrong CRC32 and 4 or 7 trailer bytes (error, nothing written)
// BC versions: 27.5 measured on a local Windows BC 27.5 container (28.5 and 29.0 by the corpus CI matrix on BC on Linux)

codeunit 75295 "GZZ GZip Trailer Sizes"
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

    [Test]
    procedure GZipDecompress_TrailerWrong_Size163840()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(163840, 'n163840_', Observer);
        TrailerCells(163841, 'n163841_', Observer);
        Observer.Expect('n163840_plain_len', '163840');
        Observer.Expect('n163840_valid', 'ok len=163840 prefix=Yes');
        Observer.Expect('n163840_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Expect('n163840_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Expect('n163841_plain_len', '163841');
        Observer.Expect('n163841_valid', 'ok len=163841 prefix=Yes');
        Observer.Expect('n163841_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Expect('n163841_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_MoreSizes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(65537, 'n65537_', Observer);
        TrailerCells(131072, 'n131072_', Observer);
        TrailerCells(131073, 'n131073_', Observer);
        Observer.Expect('n65537_plain_len', '65537');
        Observer.Expect('n65537_valid', 'ok len=65537 prefix=Yes');
        Observer.Expect('n65537_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n65537_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n131072_plain_len', '131072');
        Observer.Expect('n131072_valid', 'ok len=131072 prefix=Yes');
        Observer.Expect('n131072_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n131072_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n131073_plain_len', '131073');
        Observer.Expect('n131073_valid', 'ok len=131073 prefix=Yes');
        Observer.Expect('n131073_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Expect('n131073_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_MoreSizes2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(196608, 'n196608_', Observer);
        TrailerCells(262144, 'n262144_', Observer);
        TrailerCells(524288, 'n524288_', Observer);
        Observer.Expect('n196608_plain_len', '196608');
        Observer.Expect('n196608_valid', 'ok len=196608 prefix=Yes');
        Observer.Expect('n196608_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Expect('n196608_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Expect('n262144_plain_len', '262144');
        Observer.Expect('n262144_valid', 'ok len=262144 prefix=Yes');
        Observer.Expect('n262144_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Expect('n262144_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131072 prefix=Yes');
        Observer.Expect('n524288_plain_len', '524288');
        Observer.Expect('n524288_valid', 'ok len=524288 prefix=Yes');
        Observer.Expect('n524288_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=393216 prefix=Yes');
        Observer.Expect('n524288_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=393216 prefix=Yes');
        Observer.Verify();
    end;

    // Pseudo-random member of N bytes with the first CRC32 byte flipped.
    local procedure NoiseCrcCell(N: Integer; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Bad: Codeunit "Temp Blob";
    begin
        NoiseBlob(N, Plain);
        Compress(Plain, Packed);
        Flipped(Packed, Packed.Length() - 7, Bad);
        Observer.Observe(Prefix + 'crc_wrong', Outcome(Bad, Plain));
    end;

    [Test]
    procedure GZipDecompress_NoiseSizes_CrcWrong()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NoiseCrcCell(1000, 'n1000_', Observer);
        NoiseCrcCell(65536, 'n65536_', Observer);
        NoiseCrcCell(131072, 'n131072_', Observer);
        NoiseCrcCell(200000, 'n200000_', Observer);
        Observer.Expect('n1000_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n65536_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n131072_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131022 prefix=Yes');
        Observer.Expect('n200000_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=131022 prefix=Yes');
        Observer.Verify();
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
        PlainAB: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        PatternBlob(200000, PlainA);
        TextBlob('second member', PlainB);
        PlainAB.CreateOutStream(OutS);
        Append(PlainA, OutS);
        Append(PlainB, OutS);
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
        Observer.Observe('large_good_then_good', Outcome(Joined, PlainAB));
        Observer.Expect('large_good_then_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=200000 prefix=Yes');
        Observer.Expect('large_good_then_good', 'ok len=200013 prefix=Yes');
        Observer.Verify();
    end;
}
