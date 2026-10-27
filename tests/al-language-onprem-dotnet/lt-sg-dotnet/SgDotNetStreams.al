// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope (OnPrem DotNet app)
// Fixtures used: Probe Observer (69160); own dotnet aliases LtSg*; test codeunit 99420 (writer SG)
// Probe: an AL OutStream or InStream given to .NET: assigned to a DotNet System.IO.Stream (and System.Object) variable, and passed as the
// argument of a .NET method that takes a Stream (StreamWriter and StreamReader constructors, XmlDocument.Save and Load, GZipStream).
// Questions: what .NET sees (type name, CanRead/CanWrite/CanSeek, Length/Position), whether bytes written on the .NET side reach the
// AL stream and in which order with AL writes, what Flush, Close and Dispose do to the AL stream, and the base application wrapper
// codeunit DotNet_Stream (FromOutStream, WriteByte).
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
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Result += Format(B) + ' ';
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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

    [Test]
    procedure SG_OutStreamToObject()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        O: DotNet LtSgObject;
        S: DotNet LtSgStream;
    begin
        TempBlob.CreateOutStream(OutS);
        O := OutS;
        Observer.Observe('object type', O.GetType().FullName);
        S := O;
        S.WriteByte(65);
        Observer.Observe('content', BlobText(TempBlob));
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
