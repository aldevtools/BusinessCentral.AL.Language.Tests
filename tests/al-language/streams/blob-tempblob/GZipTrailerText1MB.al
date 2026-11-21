// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit-system-data-compression-data-compression
// Scope: in-scope (System Application "Data Compression", GZipDecompress over a Temp Blob OutStream)
// Fixtures used: Probe Observer (69160); own codeunit 75294
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

codeunit 75294 "GZZ GZip Trailer Text 1MB"
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
    procedure GZipDecompress_TrailerWrong_Size65536()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(65536, '', Observer);
        Observer.Expect('plain_len', '65536');
        Observer.Expect('valid', 'ok len=65536 prefix=Yes');
        Observer.Expect('crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size81920()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(81919, 'n81919_', Observer);
        TrailerCells(81920, 'n81920_', Observer);
        TrailerCells(81921, 'n81921_', Observer);
        Observer.Expect('n81919_plain_len', '81919');
        Observer.Expect('n81919_valid', 'ok len=81919 prefix=Yes');
        Observer.Expect('n81919_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n81919_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n81920_plain_len', '81920');
        Observer.Expect('n81920_valid', 'ok len=81920 prefix=Yes');
        Observer.Expect('n81920_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n81920_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n81921_plain_len', '81921');
        Observer.Expect('n81921_valid', 'ok len=81921 prefix=Yes');
        Observer.Expect('n81921_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n81921_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size1MB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(1048576, '', Observer);
        Observer.Expect('plain_len', '1048576');
        Observer.Expect('valid', 'ok len=1048576 prefix=Yes');
        Observer.Expect('crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=917504 prefix=Yes');
        Observer.Expect('isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=917504 prefix=Yes');
        Observer.Verify();
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
        Observer.Expect('middle_byte_flipped', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=917504 prefix=No');
        Observer.Expect('byte_12_flipped', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;
}
