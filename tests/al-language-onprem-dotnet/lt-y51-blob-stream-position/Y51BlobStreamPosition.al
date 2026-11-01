// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160); Temp Blob (System Application); own test codeunit 99394 (writer Y51, gap cycle 5 spec G5-25b)
// Probe: an InStream over a Blob assigned to a DotNet System.IO.Stream, read by AL, then the .NET Position set and the stream assigned
//        back to the InStream (the Data Compression IsGZip / IsZip shape, in a callee with a by-value InStream parameter and in one
//        procedure), and Position set out of range. Observed: the .NET Position, EOS and the rest of the InStream read byte by byte.
//        Already pinned nearby: lt-sg-dotnet/SgDotNetStreams.al (SG_InStreamToStream_DescribeAndRead: Length, Position 0, ReadByte).
// Values: every literal asserted is what BC 27.5, 28.5 and 29.0 (Linux CI containers) produced; #if BC29PLUS where 29.0 differs.
// Writer Y57 (corpus issue 996), BlobStream_Position_*: Position and Length follow every AL write (WriteText 3, Byte 1, Integer 4 bytes)
//   and read (Read Byte, ReadText with a length, Read Text, ReadText of a line: the line end counts); setting Position after the AL
//   InStream reached its end does not restart it (EOS stays Yes, ReadText reads nothing). Measured: Linux CI containers BC 27.5, 28.5, 29.0.
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.IO.Stream"; LtY51DnStream) { }
    }
}

codeunit 99394 "LT Y51 Blob Stream Position"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Fill(var TempBlob: Codeunit "Temp Blob"; Content: Text; var InS: InStream)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS);
    end;

    local procedure FillBytes(var TempBlob: Codeunit "Temp Blob"; var InS: InStream)
    var
        OutS: OutStream;
        B: Byte;
    begin
        TempBlob.CreateOutStream(OutS);
        B := 31;
        OutS.Write(B);
        B := 139;
        OutS.Write(B);
        B := 65;
        OutS.Write(B);
        B := 66;
        OutS.Write(B);
        TempBlob.CreateInStream(InS);
    end;

    // The rest of the stream read byte by byte: the bytes as characters (<n> outside 32..126) and their count.
    local procedure Rest(var InS: InStream): Text
    var
        B: Byte;
        C: Char;
        Result: Text;
        N: Integer;
        Code: Integer;
    begin
        while not InS.EOS() do begin
            InS.Read(B);
            C := B;
            Code := B;
            if (B < 32) or (B > 126) then
                Result += '<' + Format(Code) + '>'
            else
                Result += Format(C);
            N += 1;
        end;
        exit(Result + '|' + Format(N));
    end;

    [Test]
    procedure BlobStream_PositionSet_AfterALRead()
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        S: DotNet LtY51DnStream;
        B1: Byte;
        B2: Byte;
    begin
        Fill(TempBlob, 'abcdef', InS);
        S := InS;
        InS.Read(B1);
        InS.Read(B2);
        Observer.Observe('bytes_read', Format(B1) + ',' + Format(B2));
        Observer.Observe('pos_after_read', Format(S.Position));
        S.Position := 0;
        Observer.Observe('pos_after_set', Format(S.Position));
        Observer.Observe('eos_after_set', Format(InS.EOS()));
        Observer.Observe('rest_after_set', Rest(InS));
        Observer.Expect('bytes_read', 'a,b');
        Observer.Expect('pos_after_read', '2');
        Observer.Expect('pos_after_set', '0');
        Observer.Expect('eos_after_set', 'No');
        Observer.Expect('rest_after_set', 'cdef|4');
        Observer.Verify();
    end;

    local procedure Probe(InputInStream: InStream): Boolean
    var
        OriginalStream: DotNet LtY51DnStream;
        ID: array[2] of Byte;
    begin
        if (InputInStream.Length < 2) then
            exit(false);
        OriginalStream := InputInStream;
        InputInStream.Read(ID[1]);
        InputInStream.Read(ID[2]);
        OriginalStream.Position := 0;
        InputInStream := OriginalStream;
        exit((ID[1] = 31) and (ID[2] = 139));
    end;

    [Test]
    procedure BlobStream_AssignBackToInStream_InCallee()
    var
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        TempBlob3: Codeunit "Temp Blob";
        InS: InStream;
        InS2: InStream;
        InS3: InStream;
    begin
        Fill(TempBlob, 'abcdef', InS);
        Observer.Observe('probe_1', Format(Probe(InS)));
        Observer.Observe('eos_1', Format(InS.EOS()));
        Observer.Observe('rest_1', Rest(InS));

        Fill(TempBlob2, 'abcdef', InS2);
        Observer.Observe('probe_2a', Format(Probe(InS2)));
        Observer.Observe('probe_2b', Format(Probe(InS2)));
        Observer.Observe('eos_2', Format(InS2.EOS()));
        Observer.Observe('rest_2', Rest(InS2));

        FillBytes(TempBlob3, InS3);
        Observer.Observe('probe_gzip', Format(Probe(InS3)));
        Observer.Observe('rest_gzip', Rest(InS3));
        Observer.Expect('probe_1', 'No');
        Observer.Expect('eos_1', 'No');
        Observer.Expect('rest_1', 'abcdef|6');
        Observer.Expect('probe_2a', 'No');
        Observer.Expect('probe_2b', 'No');
        Observer.Expect('eos_2', 'No');
        Observer.Expect('rest_2', 'abcdef|6');
        Observer.Expect('probe_gzip', 'Yes');
        Observer.Expect('rest_gzip', '<31><139>AB|4');
        Observer.Verify();
    end;

    [Test]
    procedure BlobStream_AssignBack_SameProcedure()
    var
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        InS: InStream;
        InS2: InStream;
        S: DotNet LtY51DnStream;
        B1: Byte;
    begin
        Fill(TempBlob, 'abcdef', InS);
        S := InS;
        InS.Read(B1);
        S.Position := 0;
        InS := S;
        Observer.Observe('rest_pos0', Rest(InS));

        Fill(TempBlob2, 'abcdef', InS2);
        S := InS2;
        S.Position := 3;
        InS2 := S;
        Observer.Observe('rest_pos3', Rest(InS2));
        Observer.Expect('rest_pos0', 'abcdef|6');
        Observer.Expect('rest_pos3', 'abcdef|6');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetPosition(S: DotNet LtY51DnStream; P: Integer)
    begin
        S.Position := P;
    end;

    [Test]
    procedure BlobStream_PositionSet_OutOfRange()
    var
        TempBlob: Codeunit "Temp Blob";
        TempBlob2: Codeunit "Temp Blob";
        InS: InStream;
        InS2: InStream;
        S: DotNet LtY51DnStream;
    begin
        Fill(TempBlob, 'abcdef', InS);
        S := InS;
        ClearLastError();
        if TrySetPosition(S, -1) then
            Observer.Observe('set_minus1', 'ok|' + Format(S.Position))
        else
            Observer.ObserveError('set_minus1');
        Observer.Observe('rest_minus1', Rest(InS));

        Fill(TempBlob2, 'abcdef', InS2);
        S := InS2;
        if TrySetPosition(S, 100) then
            Observer.Observe('set_100', 'ok|' + Format(S.Position))
        else
            Observer.ObserveError('set_100');
        Observer.Observe('eos_100', Format(InS2.EOS()));
        Observer.Observe('rest_100', Rest(InS2));
        Observer.Expect('set_minus1', 'ok|-1');
        Observer.Expect('rest_minus1', 'abcdef|6');
        Observer.Expect('set_100', 'ok|100');
        Observer.Expect('eos_100', 'No');
        Observer.Expect('rest_100', 'abcdef|6');
        Observer.Verify();
    end;

    // Writer Y57: the .NET Position and Length of a Blob stream after AL writes (OutStream) and after AL reads of each kind (InStream).
    [Test]
    procedure BlobStream_Position_AfterWrites()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        S: DotNet LtY51DnStream;
        B: Byte;
        I: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        S := OutS;
        Observer.Observe('start', Format(S.Position) + '|' + Format(S.Length));
        OutS.WriteText('abc');
        Observer.Observe('writetext_abc', Format(S.Position) + '|' + Format(S.Length));
        B := 139;
        OutS.Write(B);
        Observer.Observe('write_byte', Format(S.Position) + '|' + Format(S.Length));
        I := 1;
        OutS.Write(I);
        Observer.Observe('write_integer', Format(S.Position) + '|' + Format(S.Length));
        OutS.WriteText('x', 1);
        Observer.Observe('writetext_len1', Format(S.Position) + '|' + Format(S.Length));
        Observer.Observe('bloblength', Format(TempBlob.Length()));
        Observer.Expect('start', '0|0');
        Observer.Expect('writetext_abc', '3|3');
        Observer.Expect('write_byte', '4|4');
        Observer.Expect('write_integer', '8|8');
        Observer.Expect('writetext_len1', '9|9');
        Observer.Expect('bloblength', '9');
        Observer.Verify();
    end;

    [Test]
    procedure BlobStream_Position_AfterReads()
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        S: DotNet LtY51DnStream;
        B: Byte;
        T: Text;
        N: Integer;
    begin
        Fill(TempBlob, 'abcdefghij', InS);
        S := InS;
        Observer.Observe('start', Format(S.Position) + '|' + Format(S.Length));
        InS.Read(B);
        Observer.Observe('read_byte', Format(S.Position));
        N := InS.ReadText(T, 3);
        Observer.Observe('readtext_3', Format(S.Position) + '|' + T + '|' + Format(N));
        N := InS.Read(T, 2);
        Observer.Observe('read_text_2', Format(S.Position) + '|' + T + '|' + Format(N));
        N := InS.ReadText(T);
        Observer.Observe('readtext_rest', Format(S.Position) + '|' + T + '|' + Format(N) + '|' + Format(InS.EOS()));
        S.Position := 2;
        Observer.Observe('set_2', Format(S.Position) + '|' + Format(InS.EOS()));
        N := InS.ReadText(T);
        Observer.Observe('readtext_after_set_2', Format(S.Position) + '|' + T + '|' + Format(N));
        Observer.Expect('start', '0|10');
        Observer.Expect('read_byte', '1');
        Observer.Expect('readtext_3', '4|bcd|3');
        Observer.Expect('read_text_2', '6|ef|2');
        Observer.Expect('readtext_rest', '10|ghij|4|Yes');
        Observer.Expect('set_2', '2|Yes');
        Observer.Expect('readtext_after_set_2', '10||0');
        Observer.Verify();
    end;

    [Test]
    procedure BlobStream_Position_Lines()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        S: DotNet LtY51DnStream;
        T: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('ab');
        OutS.WriteText();
        OutS.WriteText('cd');
        TempBlob.CreateInStream(InS);
        S := InS;
        Observer.Observe('length', Format(S.Length));
        InS.ReadText(T);
        Observer.Observe('line1', Format(S.Position) + '|' + T);
        InS.ReadText(T);
        Observer.Observe('line2', Format(S.Position) + '|' + T + '|' + Format(InS.EOS()));
        Observer.Expect('length', '6');
        Observer.Expect('line1', '4|ab');
        Observer.Expect('line2', '6|cd|Yes');
        Observer.Verify();
    end;
}
