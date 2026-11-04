// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit-system-data-compression-data-compression
// Scope: in-scope (System Application "Data Compression")
// Fixtures used: Probe Observer (69160); own codeunit 70912
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GZipDecompress of streams of 1, 2, 5, 9 and 10 bytes, a valid header followed by garbage, two gzip streams joined, a gzip stream followed by trailing garbage, and the header bytes of a compressed stream (method, flags, OS)
// BC versions: 29 (27 and 28 by CI)

codeunit 70912 "LT P170 GZip Edges"
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

    local procedure TextBlob(Value: Text; var Blob: Codeunit "Temp Blob")
    var
        OutS: OutStream;
    begin
        Blob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Value);
    end;

    local procedure ReadAll(Blob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Result: Text;
    begin
        if Blob.Length() = 0 then
            exit('');
        Blob.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Result, Blob.Length());
        exit(Result);
    end;

    local procedure BytesOf(Blob: Codeunit "Temp Blob"; Count: Integer): Text
    var
        InS: InStream;
        B: Byte;
        i: Integer;
        Result: Text;
    begin
        Blob.CreateInStream(InS);
        for i := 1 to Count do
            if not InS.EOS() then begin
                InS.Read(B);
                Result += Format(B) + ',';
            end;
        exit(Result);
    end;

    local procedure AppendBytes(Source: Codeunit "Temp Blob"; var Target: Codeunit "Temp Blob"; var OutS: OutStream)
    var
        InS: InStream;
        B: Byte;
    begin
        Source.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            OutS.Write(B);
        end;
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

    local procedure Outcome(Packed: Codeunit "Temp Blob"): Text
    var
        Back: Codeunit "Temp Blob";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryDecompress(Packed, Back);
        if Ok then
            exit('ok len=' + Format(Back.Length()) + ' text=[' + CopyStr(ReadAll(Back), 1, 200) + ']');
        exit('error:' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode() + ' len=' + Format(Back.Length()));
    end;

    [Test]
    procedure P170_GZip_ShortStreams()
    var
        Observer: Codeunit "Probe Observer";
        Packed: Codeunit "Temp Blob";
        Bytes: List of [Integer];
    begin
        Bytes.Add(31);
        BlobOf(Bytes, Packed);
        Observer.Observe('one_magic_byte', Outcome(Packed));
        Clear(Packed);
        Clear(Bytes);
        Bytes.Add(65);
        BlobOf(Bytes, Packed);
        Observer.Observe('one_other_byte', Outcome(Packed));
        Clear(Packed);
        Clear(Bytes);
        Bytes.Add(31);
        Bytes.Add(139);
        BlobOf(Bytes, Packed);
        Observer.Observe('two_magic_bytes', Outcome(Packed));
        Clear(Packed);
        Clear(Bytes);
        Bytes.Add(31);
        Bytes.Add(139);
        Bytes.Add(8);
        Bytes.Add(0);
        Bytes.Add(0);
        BlobOf(Bytes, Packed);
        Observer.Observe('five_bytes_header_start', Outcome(Packed));
        Clear(Packed);
        Clear(Bytes);
        Bytes.Add(1);
        Bytes.Add(2);
        Bytes.Add(3);
        Bytes.Add(4);
        Bytes.Add(5);
        BlobOf(Bytes, Packed);
        Observer.Observe('five_bytes_other', Outcome(Packed));
        Clear(Packed);
        Clear(Bytes);
        Bytes.Add(31);
        Bytes.Add(139);
        Bytes.Add(8);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        BlobOf(Bytes, Packed);
        Observer.Observe('nine_bytes_header_start', Outcome(Packed));
        Clear(Packed);
        Bytes.Add(3);
        BlobOf(Bytes, Packed);
        Observer.Observe('ten_bytes_header_only', Outcome(Packed));
        Observer.Expect('one_magic_byte', 'ok len=0 text=[]');
        Observer.Expect('one_other_byte', 'ok len=0 text=[]');
        Observer.Expect('two_magic_bytes', 'ok len=0 text=[]');
        Observer.Expect('five_bytes_header_start', 'ok len=0 text=[]');
        Observer.Expect('five_bytes_other', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0');
        Observer.Expect('nine_bytes_header_start', 'ok len=0 text=[]');
        Observer.Expect('ten_bytes_header_only', 'ok len=0 text=[]');
        Observer.Verify();
    end;

    [Test]
    procedure P170_GZip_ValidHeaderThenGarbage()
    var
        Observer: Codeunit "Probe Observer";
        Packed: Codeunit "Temp Blob";
        Bytes: List of [Integer];
        i: Integer;
    begin
        Bytes.Add(31);
        Bytes.Add(139);
        Bytes.Add(8);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(3);
        for i := 1 to 20 do
            Bytes.Add(255);
        BlobOf(Bytes, Packed);
        Observer.Observe('header_then_ff', Outcome(Packed));
        Clear(Packed);
        Clear(Bytes);
        Bytes.Add(31);
        Bytes.Add(139);
        Bytes.Add(8);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(3);
        for i := 1 to 20 do
            Bytes.Add(65);
        BlobOf(Bytes, Packed);
        Observer.Observe('header_then_text', Outcome(Packed));
        Clear(Packed);
        Clear(Bytes);
        Bytes.Add(31);
        Bytes.Add(139);
        Bytes.Add(99);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(0);
        Bytes.Add(3);
        Bytes.Add(1);
        Bytes.Add(2);
        BlobOf(Bytes, Packed);
        Observer.Observe('unknown_method', Outcome(Packed));
        Observer.Expect('header_then_ff', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0');
        Observer.Expect('header_then_text', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0');
        Observer.Expect('unknown_method', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0');
        Observer.Verify();
    end;

    [Test]
    procedure P170_GZip_CorruptAfterValidCompressedData()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Bad: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        B: Byte;
        i: Integer;
        Len: Integer;
    begin
        TextBlob('corrupt me after the header corrupt me after the header corrupt me after the header', Plain);
        Compress(Plain, Packed);
        Len := Packed.Length();
        Observer.Observe('packed_header', BytesOf(Packed, 4));
        Observer.Observe('packed_method_byte_is_8', Format(Len > 3));
        Packed.CreateInStream(InS);
        Bad.CreateOutStream(OutS);
        for i := 1 to Len do begin
            InS.Read(B);
            if i = 14 then
                B := 255 - B;
            OutS.Write(B);
        end;
        Observer.Observe('flip_byte_14', Outcome(Bad));
        Clear(Bad);
        Packed.CreateInStream(InS);
        Bad.CreateOutStream(OutS);
        for i := 1 to Len do begin
            InS.Read(B);
            if i = Len then
                B := 255 - B;
            OutS.Write(B);
        end;
        Observer.Observe('flip_last_crc_byte', Outcome(Bad));
        Observer.Expect('packed_header', '\u001F,ï,\u0008,\u0000,');
        Observer.Expect('packed_method_byte_is_8', 'Yes');
        Observer.Expect('flip_byte_14', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0');
        Observer.Expect('flip_last_crc_byte', 'error:A call to System.IO.Compression.GZipStream.CopyTo failed with this message: The archive entry was compressed using an unsupported compression method.|DotNetInvoke:InvalidData len=0');
        Observer.Verify();
    end;

    [Test]
    procedure P170_GZip_TwoMembersJoined()
    var
        Observer: Codeunit "Probe Observer";
        PlainA: Codeunit "Temp Blob";
        PlainB: Codeunit "Temp Blob";
        PackedA: Codeunit "Temp Blob";
        PackedB: Codeunit "Temp Blob";
        Joined: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TextBlob('first member;', PlainA);
        TextBlob('second member', PlainB);
        Compress(PlainA, PackedA);
        Compress(PlainB, PackedB);
        Joined.CreateOutStream(OutS);
        AppendBytes(PackedA, Joined, OutS);
        AppendBytes(PackedB, Joined, OutS);
        Observer.Observe('lengths_add_up', Format(Joined.Length() = PackedA.Length() + PackedB.Length()));
        Observer.Observe('joined', Outcome(Joined));
        Observer.Observe('first_alone', Outcome(PackedA));
        Observer.Expect('lengths_add_up', 'Yes');
        Observer.Expect('joined', 'ok len=26 text=[first member;second member]');
        Observer.Expect('first_alone', 'ok len=13 text=[first member;]');
        Observer.Verify();
    end;

    [Test]
    procedure P170_GZip_MemberFollowedByGarbage()
    var
        Observer: Codeunit "Probe Observer";
        Plain: Codeunit "Temp Blob";
        Packed: Codeunit "Temp Blob";
        Tail: Codeunit "Temp Blob";
        Joined: Codeunit "Temp Blob";
        OutS: OutStream;
        Bytes: List of [Integer];
    begin
        TextBlob('member then tail', Plain);
        Compress(Plain, Packed);
        Bytes.Add(1);
        Bytes.Add(2);
        Bytes.Add(3);
        BlobOf(Bytes, Tail);
        Joined.CreateOutStream(OutS);
        AppendBytes(Packed, Joined, OutS);
        AppendBytes(Tail, Joined, OutS);
        Observer.Observe('member_then_3_bytes', Outcome(Joined));
        Clear(Joined);
        Clear(Tail);
        Clear(Bytes);
        Bytes.Add(0);
        BlobOf(Bytes, Tail);
        Joined.CreateOutStream(OutS);
        AppendBytes(Packed, Joined, OutS);
        AppendBytes(Tail, Joined, OutS);
        Observer.Observe('member_then_zero_byte', Outcome(Joined));
        Observer.Expect('member_then_3_bytes', 'ok len=16 text=[member then tail]');
        Observer.Expect('member_then_zero_byte', 'ok len=16 text=[member then tail]');
        Observer.Verify();
    end;
}
