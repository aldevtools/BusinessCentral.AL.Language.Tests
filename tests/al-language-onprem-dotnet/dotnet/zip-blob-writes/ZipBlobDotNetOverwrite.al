// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.io.streamwriter
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; LT ZB Zip Helper (99022) and tables 99020, 99021
// Probe: written against al-runner issue 7947. System.IO.StreamWriter over a Blob OutStream writes 48 characters 'A'
//        and flushes; then .NET moves BaseStream.Position back or calls BaseStream.SetLength, and writes again.
//        Temporary table, and a stored table with Insert before and Modify + Get + CalcFields after.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
