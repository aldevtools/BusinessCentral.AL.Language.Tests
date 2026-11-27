// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.streamwriter
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; LT ZB Zip Helper (99022) and tables 99020, 99021
// Probe: written against al-runner issue 7947. System.IO.StreamWriter over a Blob OutStream writes 48 characters 'A'
//        and flushes; then .NET moves BaseStream.Position back or calls BaseStream.SetLength, and writes again.
//        Temporary table, and a stored table with Insert before and Modify + Get + CalcFields after.
// Facts (same on BC 27.5, 28.5, 29.0; local BC on Linux): the Blob OutStream as a .NET stream can seek. After 48
//        'A', Position 48 and Length 48. Position := 0 and 48 'B' gives 48 x 'B' (Length 48); 10 'B' gives 10 x 'B' and
//        38 x 'A' (Length 48, no truncation). BaseStream.SetLength(10) gives 10 x 'A'. A stored record after Modify, Get
//        and CalcFields keeps 48 x 'B'.
// BC versions: 27, 28, 29
codeunit 99025 "LT ZB DotNet Overwrite"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure WriteA48(var BufferOut: OutStream; var Writer: DotNet LtZbStreamWriter)
    begin
        Writer := Writer.StreamWriter(BufferOut);
        Writer.Write(PadStr('', 48, 'A'));
        Writer.Flush();
    end;

    [Test]
    procedure ZB_Overwrite48_AtPosition0()
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
        Observer.Observe('can seek', Format(Base.CanSeek));
        Observer.Observe('position after write', Format(Base.Position));
        Observer.Observe('length after write', Format(Buffer.Content.Length));
        Base.Position := 0;
        Writer.Write(PadStr('', 48, 'B'));
        Writer.Flush();
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('text', Helper.BlobText(Buffer));
        Observer.Expect('can seek', 'Yes');
        Observer.Expect('position after write', '48');
        Observer.Expect('length after write', '48');
        Observer.Expect('length', '48');
        Observer.Expect('text', 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_SetLength10()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Buffer: Record "LT ZB Zip File" temporary;
        Writer: DotNet LtZbStreamWriter;
        BufferOut: OutStream;
    begin
        Buffer.Content.CreateOutStream(BufferOut);
        WriteA48(BufferOut, Writer);
        Writer.BaseStream.SetLength(10);
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('text', Helper.BlobText(Buffer));
        Observer.Expect('length', '10');
        Observer.Expect('text', 'AAAAAAAAAA');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Overwrite10_AtPosition0()
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
        Observer.Observe('length', Format(Buffer.Content.Length));
        Observer.Observe('text', Helper.BlobText(Buffer));
        Observer.Expect('length', '48');
        Observer.Expect('text', 'BBBBBBBBBBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
        Observer.Verify();
    end;

    [Test]
    procedure ZB_Stored_Overwrite48_AtPosition0()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT ZB Zip Helper";
        Stored: Record "LT ZB Stored Zip File";
        Writer: DotNet LtZbStreamWriter;
        Base: DotNet LtZbStream;
        StoredOut: OutStream;
    begin
        Stored.DeleteAll();
        Stored.Init();
        Stored."No." := 1;
        Stored.Insert();
        Stored.Content.CreateOutStream(StoredOut);
        WriteA48(StoredOut, Writer);
        Base := Writer.BaseStream;
        Base.Position := 0;
        Writer.Write(PadStr('', 48, 'B'));
        Writer.Flush();
        Stored.Modify();
        Stored.Get(1);
        Stored.CalcFields(Content);
        Observer.Observe('stored length', Format(Stored.Content.Length));
        Observer.Observe('stored text', Helper.StoredText(Stored));
        Observer.Expect('stored length', '48');
        Observer.Expect('stored text', 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB');
        Observer.Verify();
    end;
}
