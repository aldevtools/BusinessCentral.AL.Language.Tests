// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.stream.setlength
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; LT ZB Zip Helper (99022) and table 99020
// Probe: written against al-runner issue 9318. System.IO.StreamWriter over a temporary Blob OutStream writes 48
//        characters 'A' and flushes (as ZipBlobDotNetOverwrite.al). Then: Position := 0, 10 'B', and an AL WriteText('Z')
//        into the same OutStream; BaseStream.SetLength(0); BaseStream.SetLength(47).
// Measured on BC 27.5.54899.59044, 28.5.54976.59048 and 29.0.54011.59052 (W1, BC on Linux, the CI leg setup); all three agree.
// Facts: after Position := 0 and 10 'B' the .NET position is 10, but AL WriteText('Z') writes at offset 0 (the AL
//        OutStream's own position) and leaves the .NET position at 1: text 'Z' + 9 'B' + 38 'A', length 48, no error.
//        SetLength(0) empties the Blob (HasValue No, length 0, text '') and leaves Position at 48. SetLength(47) cuts the
//        last 'A' (47 x 'A') and leaves Position at 48.
// BC versions: 27, 28, 29
codeunit 99027 "LT ZB DotNet Overwrite After"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure WriteA48(var BufferOut: OutStream; var Writer: DotNet LtZbStreamWriter)
    begin
        Writer := Writer.StreamWriter(BufferOut);
        Writer.Write(PadStr('', 48, 'A'));
        Writer.Flush();
    end;

    [TryFunction]
    local procedure TryWriteText(var BufferOut: OutStream; Value: Text)
    begin
        BufferOut.WriteText(Value);
    end;

    [Test]
    procedure ZB_Overwrite10_AtPosition0_ThenALWriteText()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        Writer: DotNet LtZbStreamWriter;
        Base: DotNet LtZbStream;
        BufferOut: OutStream;
    begin
        Buffer.Content.CreateOutStream(BufferOut);
        WriteA48(BufferOut, Writer);
        Base := Writer.BaseStream;
        Base.Position := 0;
        Writer.Write(PadStr('', 10, 'B'));
        Writer.Flush();
        Observer.Observe('position before AL write', Format(Base.Position));
        if TryWriteText(BufferOut, 'Z') then
            Observer.Observe('AL write error', 'none')
        else
            Observer.Observe('AL write error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('position after AL write', Format(Base.Position));
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('text', Helper.BlobText(Buffer));
        Observer.Expect('position before AL write', '10');
        Observer.Expect('AL write error', 'none');
        Observer.Expect('position after AL write', '1');
        Observer.Expect('length', '48');
        Observer.Expect('text', 'ZBBBBBBBBBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_SetLength0()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        Writer: DotNet LtZbStreamWriter;
        Base: DotNet LtZbStream;
        BufferOut: OutStream;
    begin
        Buffer.Content.CreateOutStream(BufferOut);
        WriteA48(BufferOut, Writer);
        Base := Writer.BaseStream;
        Base.SetLength(0);
        Observer.Observe('position', Format(Base.Position));
        Observer.Observe('has value', Format(Buffer.Content.HasValue()));
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('text', Helper.BlobText(Buffer));
        Observer.Expect('position', '48');
        Observer.Expect('has value', 'No');
        Observer.Expect('length', '0');
        Observer.Expect('text', '');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_SetLength47()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        Writer: DotNet LtZbStreamWriter;
        Base: DotNet LtZbStream;
        BufferOut: OutStream;
    begin
        Buffer.Content.CreateOutStream(BufferOut);
        WriteA48(BufferOut, Writer);
        Base := Writer.BaseStream;
        Base.SetLength(47);
        Observer.Observe('position', Format(Base.Position));
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('text', Helper.BlobText(Buffer));
        Observer.Expect('position', '48');
        Observer.Expect('length', '47');
        Observer.Expect('text', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
        Observer.Verify();
    end;
}
