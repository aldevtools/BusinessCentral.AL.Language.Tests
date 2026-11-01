// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160); Temp Blob (System Application); own test codeunit 99394 (writer Y51, gap cycle 5 spec G5-25b)
// Probe: an InStream over a Blob assigned to a DotNet System.IO.Stream, read by AL, then the .NET Position set and the stream assigned
//        back to the InStream (the Data Compression IsGZip / IsZip shape, in a callee with a by-value InStream parameter and in one
//        procedure), and Position set out of range. Observed: the .NET Position, EOS and the rest of the InStream read byte by byte.
//        Already pinned nearby: lt-sg-dotnet/SgDotNetStreams.al (SG_InStreamToStream_DescribeAndRead: Length, Position 0, ReadByte).
// Values: every literal asserted is what BC 27.5, 28.5 and 29.0 (Linux CI containers) produced; #if BC29PLUS where 29.0 differs.
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
}
