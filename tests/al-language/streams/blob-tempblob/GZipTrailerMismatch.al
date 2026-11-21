// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit-system-data-compression-data-compression
// Scope: in-scope (System Application "Data Compression", GZipDecompress over a Temp Blob OutStream)
// Fixtures used: Probe Observer (69160); own codeunit 75290
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
        Observer.Expect('valid', 'ok len=0 prefix=Yes');
        Observer.Expect('crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(1, '', Observer);
        Observer.Expect('plain_len', '1');
        Observer.Expect('valid', 'ok len=1 prefix=Yes');
        Observer.Expect('crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size40()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(40, '', Observer);
        Observer.Expect('plain_len', '40');
        Observer.Expect('valid', 'ok len=40 prefix=Yes');
        Observer.Expect('crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size83()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(83, '', Observer);
        Observer.Expect('plain_len', '83');
        Observer.Expect('valid', 'ok len=83 prefix=Yes');
        Observer.Expect('crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size8192()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(8192, '', Observer);
        Observer.Expect('plain_len', '8192');
        Observer.Expect('valid', 'ok len=8192 prefix=Yes');
        Observer.Expect('crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
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
        Observer.Expect('packed_not_smaller', 'Yes');
        Observer.Expect('valid', 'ok len=1048576 prefix=Yes');
        Observer.Expect('crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=1048246 prefix=Yes');
        Observer.Expect('middle_byte_flipped', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=1048246 prefix=No');
        Observer.Verify();
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
        Observer.Expect('good_then_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=13 prefix=Yes');
        Observer.Expect('crc_wrong_then_good', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('good_then_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=13 prefix=Yes');
        Observer.Verify();
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
        Observer.Expect('fname_valid', 'ok len=83 prefix=Yes');
        Observer.Expect('fname_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('fcomment_valid', 'ok len=83 prefix=Yes');
        Observer.Expect('fcomment_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('fextra_valid', 'ok len=83 prefix=Yes');
        Observer.Expect('fextra_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('fhcrc_zero_valid_trailer', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GZipDecompress_TrailerWrong_Size2And82()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TrailerCells(2, 'n2_', Observer);
        TrailerCells(82, 'n82_', Observer);
        Observer.Expect('n2_plain_len', '2');
        Observer.Expect('n2_valid', 'ok len=2 prefix=Yes');
        Observer.Expect('n2_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n2_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n82_plain_len', '82');
        Observer.Expect('n82_valid', 'ok len=82 prefix=Yes');
        Observer.Expect('n82_crc_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('n82_isize_wrong', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    // The first Count bytes of Source.
    local procedure Truncated(Source: Codeunit "Temp Blob"; Count: Integer; var Target: Codeunit "Temp Blob")
    var
        InS: InStream;
        OutS: OutStream;
    begin
        Source.CreateInStream(InS);
        Target.CreateOutStream(OutS);
        CopyStream(OutS, InS, Count);
    end;

    [Test]
    procedure GZipDecompress_CutInsideTrailer()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        BadCrc: Codeunit "Temp Blob";
        Cut: Codeunit "Temp Blob";
        Len: Integer;
    begin
        TextBlob('corrupt me after the header corrupt me after the header corrupt me after the header', Plain);
        Compress(Plain, Packed);
        Len := Packed.Length();
        Flipped(Packed, Len - 7, BadCrc);
        Truncated(Packed, Len - 8, Cut);
        Observer.Observe('trailer_0_bytes', Outcome(Cut, Plain));
        Clear(Cut);
        Truncated(Packed, Len - 4, Cut);
        Observer.Observe('trailer_4_bytes', Outcome(Cut, Plain));
        Clear(Cut);
        Truncated(Packed, Len - 1, Cut);
        Observer.Observe('trailer_7_bytes', Outcome(Cut, Plain));
        Clear(Cut);
        Truncated(BadCrc, Len - 4, Cut);
        Observer.Observe('crc_wrong_trailer_4_bytes', Outcome(Cut, Plain));
        Clear(Cut);
        Truncated(BadCrc, Len - 1, Cut);
        Observer.Observe('crc_wrong_trailer_7_bytes', Outcome(Cut, Plain));
        Observer.Expect('trailer_0_bytes', 'ok len=83 prefix=Yes');
        Observer.Expect('trailer_4_bytes', 'ok len=83 prefix=Yes');
        Observer.Expect('trailer_7_bytes', 'ok len=83 prefix=Yes');
        Observer.Expect('crc_wrong_trailer_4_bytes', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('crc_wrong_trailer_7_bytes', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    // The 10 header bytes 31 139 Method 0 0 0 0 0 0 Os, then the bytes of Tail.
    local procedure HeaderThen(Method: Integer; Os: Integer; Tail: List of [Integer]; var Blob: Codeunit "Temp Blob")
    var
        Bytes: List of [Integer];
        V: Integer;
        i: Integer;
    begin
        Bytes.Add(31);
        Bytes.Add(139);
        Bytes.Add(Method);
        for i := 1 to 6 do
            Bytes.Add(0);
        Bytes.Add(Os);
        foreach V in Tail do
            Bytes.Add(V);
        BlobOf(Bytes, Blob);
    end;

    [Test]
    procedure GZipDecompress_Method99_HeaderShapes()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Shaped: Codeunit "Temp Blob";
        Empty: Codeunit "Temp Blob";
        Tail: List of [Integer];
    begin
        HeaderThen(99, 3, Tail, Shaped);
        Observer.Observe('m99_header_only', Outcome(Shaped, Empty));
        Clear(Shaped);
        HeaderThen(99, 255, Tail, Shaped);
        Observer.Observe('m99_header_only_os255', Outcome(Shaped, Empty));
        TextBlob('A', Plain);
        Compress(Plain, Packed);
        Clear(Shaped);
        WithMethod(Packed, 99, Shaped);
        Observer.Observe('m99_then_valid_data', Outcome(Shaped, Plain));
        Observer.Expect('m99_header_only', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('m99_header_only_os255', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('m99_then_valid_data', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;

    // Packed with the method byte (third byte) set to Method.
    local procedure WithMethod(Packed: Codeunit "Temp Blob"; Method: Integer; var Target: Codeunit "Temp Blob")
    var
        InS: InStream;
        OutS: OutStream;
        B: Byte;
    begin
        Packed.CreateInStream(InS);
        Target.CreateOutStream(OutS);
        CopyStream(OutS, InS, 2);
        InS.Read(B);
        AppendByte(Method, OutS);
        CopyStream(OutS, InS);
    end;

    [Test]
    procedure GZipDecompress_CorruptFirstBlock_Shapes()
    var
        Observer: Codeunit "Probe Observer";
        Shaped: Codeunit "Temp Blob";
        Empty: Codeunit "Temp Blob";
        Tail: List of [Integer];
        i: Integer;
    begin
        Tail.Add(255);
        HeaderThen(8, 3, Tail, Shaped);
        Observer.Observe('one_byte_255', Outcome(Shaped, Empty));
        Clear(Shaped);
        Clear(Tail);
        Tail.Add(7);
        HeaderThen(8, 3, Tail, Shaped);
        Observer.Observe('one_byte_7', Outcome(Shaped, Empty));
        Clear(Shaped);
        Clear(Tail);
        for i := 1 to 5 do
            Tail.Add(65);
        HeaderThen(8, 3, Tail, Shaped);
        Observer.Observe('five_bytes_65', Outcome(Shaped, Empty));
        Clear(Shaped);
        Clear(Tail);
        Tail.Add(1);
        for i := 1 to 4 do
            Tail.Add(0);
        HeaderThen(8, 3, Tail, Shaped);
        Observer.Observe('stored_len0_nlen0', Outcome(Shaped, Empty));
        Observer.Expect('one_byte_255', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('one_byte_7', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('five_bytes_65', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('stored_len0_nlen0', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
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
        Observer.Expect('3_method8', 'ok len=0 prefix=Yes');
        Observer.Expect('3_method99', 'ok len=0 prefix=Yes');
        Observer.Expect('3_method0', 'ok len=0 prefix=Yes');
        Observer.Expect('4_method8_flags0', 'ok len=0 prefix=Yes');
        Observer.Expect('4_method99_flags0', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Expect('4_method8_flags8', 'ok len=0 prefix=Yes');
        Observer.Expect('4_method8_reserved_flags', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0 prefix=Yes');
        Observer.Verify();
    end;
}
