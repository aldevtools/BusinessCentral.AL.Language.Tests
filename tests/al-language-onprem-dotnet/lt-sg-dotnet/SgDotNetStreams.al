// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope (OnPrem DotNet app)
// Fixtures used: Probe Observer (69160); own dotnet aliases LtSg*; test codeunit 99420 (writer SG)
// Probe: an AL OutStream or InStream given to .NET: assigned to a DotNet System.IO.Stream (and System.Object) variable, and passed as the
// argument of a .NET method that takes a Stream (StreamWriter and StreamReader constructors, XmlDocument.Save and Load, GZipStream).
// Questions: what .NET sees (type name, CanRead/CanWrite/CanSeek, Length/Position), whether bytes written on the .NET side reach the
// AL stream and in which order with AL writes, what Flush, Close and Dispose do to the AL stream, and the base application wrapper
// codeunit DotNet_Stream (FromOutStream, WriteByte).
// Facts: both streams reach .NET as Microsoft.Dynamics.Nav.Runtime.NavBLOB+InternalStream (readable, writable, seekable); .NET writes reach the
// blob at once; AL and .NET writes on one OutStream keep separate positions (a later AL write overwrites a .NET byte); assigning an OutStream
// to System.Object fails at run time (NotSupportedType, "The type NavOutStream is unknown."); after Close or Dispose of the .NET stream
// an AL write still succeeds and the blob holds only what it wrote.
// Observed on the corpus CI matrix (27.5, 28.5, 29.0).
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.IO.Stream"; LtSgStream) { }
        type("System.IO.StreamWriter"; LtSgStreamWriter) { }
        type("System.IO.StreamReader"; LtSgStreamReader) { }
        type("System.Text.Encoding"; LtSgEncoding) { }
        type("System.Byte[]"; LtSgBytes) { }
        type("System.Object"; LtSgObject) { }
    }
    assembly("System.Xml")
    {
        type("System.Xml.XmlDocument"; LtSgXmlDocument) { }
    }
    assembly("System")
    {
        type("System.IO.Compression.GZipStream"; LtSgGZipStream) { }
        type("System.IO.Compression.CompressionMode"; LtSgCompressionMode) { }
    }
}

codeunit 99420 "LT SG DotNet Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BlobText(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure BlobBytes(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        B: Byte;
        Code: Integer;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Code := B;
            Result += Format(Code) + ' ';
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryLength(S: DotNet LtSgStream; var Result: Text)
    begin
        Result := Format(S.Length);
    end;

    [TryFunction]
    local procedure TryPosition(S: DotNet LtSgStream; var Result: Text)
    begin
        Result := Format(S.Position);
    end;

    local procedure Describe(var Observer: Codeunit "Probe Observer"; Name: Text; S: DotNet LtSgStream)
    var
        Result: Text;
    begin
        Observer.Observe(Name + ' type', S.GetType().FullName);
        Observer.Observe(Name + ' CanRead', Format(S.CanRead));
        Observer.Observe(Name + ' CanWrite', Format(S.CanWrite));
        Observer.Observe(Name + ' CanSeek', Format(S.CanSeek));
        ClearLastError();
        if TryLength(S, Result) then
            Observer.Observe(Name + ' Length', Result)
        else
            Observer.ObserveError(Name + ' Length');
        ClearLastError();
        if TryPosition(S, Result) then
            Observer.Observe(Name + ' Position', Result)
        else
            Observer.ObserveError(Name + ' Position');
    end;

    [Test]
    procedure SG_OutStreamToStream_Describe()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        S: DotNet LtSgStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('ab');
        S := OutS;
        Describe(Observer, 'out', S);
        Observer.Observe('IsNull', Format(IsNull(S)));
        Observer.Expect('out type', 'Microsoft.Dynamics.Nav.Runtime.NavBLOB+InternalStream');
        Observer.Expect('out CanRead', 'Yes');
        Observer.Expect('out CanWrite', 'Yes');
        Observer.Expect('out CanSeek', 'Yes');
        Observer.Expect('out Length', '2');
        Observer.Expect('out Position', '2');
        Observer.Expect('IsNull', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OutStreamToStream_WriteByteAndWrite()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        S: DotNet LtSgStream;
        Encoding: DotNet LtSgEncoding;
        Bytes: DotNet LtSgBytes;
    begin
        TempBlob.CreateOutStream(OutS);
        S := OutS;
        S.WriteByte(65);
        S.WriteByte(66);
        Bytes := Encoding.UTF8.GetBytes('cde');
        S.Write(Bytes, 0, Bytes.Length);
        S.Write(Bytes, 1, 1);
        Observer.Observe('before flush', BlobText(TempBlob));
        S.Flush();
        Observer.Observe('after flush', BlobText(TempBlob));
        Observer.Expect('before flush', 'ABcded|');
        Observer.Expect('after flush', 'ABcded|');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OutStreamToStream_MixedWithALWrites()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        S: DotNet LtSgStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('a');
        S := OutS;
        S.WriteByte(66);
        OutS.WriteText('c');
        S.WriteByte(68);
        Observer.Observe('order', BlobText(TempBlob));
        Observer.Observe('bytes', BlobBytes(TempBlob));
        Observer.Expect('order', 'acD|');
        Observer.Expect('bytes', '97 99 68 ');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OutStreamToStream_CloseThenALWrite()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        S: DotNet LtSgStream;
    begin
        TempBlob.CreateOutStream(OutS);
        S := OutS;
        S.WriteByte(65);
        S.Close();
        Observer.Observe('after close', BlobText(TempBlob));
        ClearLastError();
        Observer.Observe('AL write after close ok', Format(TryWriteText(OutS, 'z')));
        Observer.ObserveError('AL write after close');
        Observer.Observe('content', BlobText(TempBlob));
        ClearLastError();
        Observer.Observe('stream write after close ok', Format(TryWriteByte(S, 66)));
        Observer.ObserveError('stream write after close');
        Observer.Expect('after close', 'A|');
        Observer.Expect('AL write after close ok', 'Yes');
        Observer.Expect('AL write after close|text', '');
        Observer.Expect('AL write after close|code', '');
        Observer.Expect('content', 'z|');
        Observer.Expect('stream write after close ok', 'Yes');
        Observer.Expect('stream write after close|text', '');
        Observer.Expect('stream write after close|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OutStreamToStream_DisposeThenALWrite()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        S: DotNet LtSgStream;
    begin
        TempBlob.CreateOutStream(OutS);
        S := OutS;
        S.WriteByte(65);
        S.Dispose();
        ClearLastError();
        Observer.Observe('AL write after dispose ok', Format(TryWriteText(OutS, 'z')));
        Observer.ObserveError('AL write after dispose');
        Observer.Observe('content', BlobText(TempBlob));
        Observer.Expect('AL write after dispose ok', 'Yes');
        Observer.Expect('AL write after dispose|text', '');
        Observer.Expect('AL write after dispose|code', '');
        Observer.Expect('content', 'z|');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWriteText(var OutS: OutStream; Value: Text)
    begin
        OutS.WriteText(Value);
    end;

    [TryFunction]
    local procedure TryWriteByte(S: DotNet LtSgStream; Value: Integer)
    begin
        S.WriteByte(Value);
    end;

    [TryFunction]
    local procedure TryOutStreamToObject(var OutS: OutStream; var O: DotNet LtSgObject)
    begin
        O := OutS;
    end;

    [Test]
    procedure SG_OutStreamToObject()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        O: DotNet LtSgObject;
    begin
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        Observer.Observe('assign ok', Format(TryOutStreamToObject(OutS, O)));
        Observer.ObserveError('assign');
        Observer.Observe('IsNull after', Format(IsNull(O)));
        Observer.Expect('assign ok', 'No');
        Observer.Expect('assign|text', 'The type NavOutStream is unknown.');
        Observer.Expect('assign|code', 'NotSupportedType');
        Observer.Expect('IsNull after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OutStreamArgument_StreamWriter()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Writer: DotNet LtSgStreamWriter;
    begin
        TempBlob.CreateOutStream(OutS);
        Writer := Writer.StreamWriter(OutS);
        Writer.Write('abc');
        Observer.Observe('before flush', BlobBytes(TempBlob));
        Writer.Flush();
        Observer.Observe('after flush', BlobBytes(TempBlob));
        Writer.WriteLine('d');
        Writer.Close();
        Observer.Observe('after close', BlobBytes(TempBlob));
        ClearLastError();
        Observer.Observe('AL write after writer close ok', Format(TryWriteText(OutS, 'z')));
        Observer.ObserveError('AL write after writer close');
        Observer.Expect('before flush', '');
        Observer.Expect('after flush', '97 98 99 ');
        Observer.Expect('after close', '97 98 99 100 10 ');
        Observer.Expect('AL write after writer close ok', 'Yes');
        Observer.Expect('AL write after writer close|text', '');
        Observer.Expect('AL write after writer close|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OutStreamArgument_StreamWriterEncoding()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Writer: DotNet LtSgStreamWriter;
        Encoding: DotNet LtSgEncoding;
    begin
        TempBlob.CreateOutStream(OutS);
        Writer := Writer.StreamWriter(OutS, Encoding.UTF8);
        Writer.Write('é');
        Writer.Flush();
        Observer.Observe('utf8 with preamble', BlobBytes(TempBlob));
        Observer.Expect('utf8 with preamble', '239 187 191 195 169 ');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OutStreamArgument_XmlDocumentSave()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Doc: DotNet LtSgXmlDocument;
        Again: DotNet LtSgXmlDocument;
        InS: InStream;
    begin
        Doc := Doc.XmlDocument();
        Doc.LoadXml('<a><b>1</b></a>');
        TempBlob.CreateOutStream(OutS);
        Doc.Save(OutS);
        Observer.Observe('saved', BlobText(TempBlob));
        TempBlob.CreateInStream(InS);
        Again := Again.XmlDocument();
        Again.Load(InS);
        Observer.Observe('loaded back', Again.OuterXml);
        Observer.Expect('saved', '<a>|  <b>1</b>|</a>|');
        Observer.Expect('loaded back', '<a><b>1</b></a>');
        Observer.Verify();
    end;

    [Test]
    procedure SG_OutStreamArgument_GZipRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Packed: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Zip: DotNet LtSgGZipStream;
        Unzip: DotNet LtSgGZipStream;
        Mode: DotNet LtSgCompressionMode;
        Reader: DotNet LtSgStreamReader;
        Encoding: DotNet LtSgEncoding;
        Bytes: DotNet LtSgBytes;
    begin
        Packed.CreateOutStream(OutS);
        Zip := Zip.GZipStream(OutS, Mode.Compress);
        Bytes := Encoding.UTF8.GetBytes('hello hello hello');
        Zip.Write(Bytes, 0, Bytes.Length);
        Zip.Close();
        Observer.Observe('packed has bytes', Format(Packed.Length() > 0));
        Observer.Observe('gzip magic', CopyStr(BlobBytes(Packed), 1, 8));
        Packed.CreateInStream(InS);
        Unzip := Unzip.GZipStream(InS, Mode.Decompress);
        Reader := Reader.StreamReader(Unzip);
        Observer.Observe('unpacked', Reader.ReadToEnd());
        Observer.Expect('packed has bytes', 'Yes');
        Observer.Expect('gzip magic', '31 139 8');
        Observer.Expect('unpacked', 'hello hello hello');
        Observer.Verify();
    end;

    [Test]
    procedure SG_InStreamToStream_DescribeAndRead()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        S: DotNet LtSgStream;
        Rest: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('hello');
        TempBlob.CreateInStream(InS);
        S := InS;
        Describe(Observer, 'in', S);
        Observer.Observe('first byte', Format(S.ReadByte()));
        InS.ReadText(Rest);
        Observer.Observe('AL reads the rest', Rest);
        Observer.Observe('read at end', Format(S.ReadByte()));
        Observer.Expect('in type', 'Microsoft.Dynamics.Nav.Runtime.NavBLOB+InternalStream');
        Observer.Expect('in CanRead', 'Yes');
        Observer.Expect('in CanWrite', 'Yes');
        Observer.Expect('in CanSeek', 'Yes');
        Observer.Expect('in Length', '5');
        Observer.Expect('in Position', '0');
        Observer.Expect('first byte', '104');
        Observer.Expect('AL reads the rest', 'hello');
        Observer.Expect('read at end', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure SG_InStreamArgument_StreamReader()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Reader: DotNet LtSgStreamReader;
        Encoding: DotNet LtSgEncoding;
        First: Text;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('line1');
        OutS.WriteText();
        OutS.WriteText('line2');
        TempBlob.CreateInStream(InS);
        Reader := Reader.StreamReader(InS);
        First := Reader.ReadLine();
        Observer.Observe('first line', First);
        Observer.Observe('rest', Reader.ReadToEnd());
        Observer.Observe('end', Format(Reader.EndOfStream));
        TempBlob.CreateInStream(InS);
        Reader := Reader.StreamReader(InS, Encoding.UTF8);
        Observer.Observe('with encoding', Reader.ReadToEnd());
        Observer.Expect('first line', 'line1');
        Observer.Expect('rest', 'line2');
        Observer.Expect('end', 'Yes');
        Observer.Expect('with encoding', 'line1\r\nline2');
        Observer.Verify();
    end;

    [Test]
    procedure SG_BaseAppDotNetStream_FromOutStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        DotNetStream: Codeunit DotNet_Stream;
    begin
        TempBlob.CreateOutStream(OutS);
        DotNetStream.FromOutStream(OutS);
        DotNetStream.WriteByte(27);
        DotNetStream.WriteByte(64);
        DotNetStream.WriteByte(65);
        Observer.Observe('bytes', BlobBytes(TempBlob));
        Observer.Expect('bytes', '27 64 65 ');
        Observer.Verify();
    end;
}
